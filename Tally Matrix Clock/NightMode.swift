//
//  NightMode.swift
//  Tally Matrix Clock
//
//  Auto Night Mode — roadmap 017–022, locked with Michael 2026 NOV 23.
//
//  REM (017): works with ANY theme. The default night theme is Crimson (Sleep) — his correction
//  11-23: "chrimson should be default and blue is chosen by the user". Night Mode is OFF until the
//  user turns it on — never forced. Brightness is 25 / 50 / 75 / 100% (100% = no dimming). It dims
//  the clock face and the glyph rain, never the opening animation.
//  REM (018): it turns on by a bedtime schedule (10 PM–7 AM suggested) or by sunset/sunrise.
//  REM (019): with weather off, sun times are fetched once at launch and once a day — not every
//  15 minutes. They come through ContentView.fetchWeather, the ONE weather path (013).
//  REM (020): fallback order — today's sun times → last saved sun times → bedtime schedule →
//  daytime look. A failed fetch never leaves the clock stuck in the wrong look.
//  REM (021): the night theme is its OWN saved setting. Night Mode never overwrites the day theme.
//  REM (022): the settings sync like every other setting (followers go through the leader).
//
//  Everything here is pure so it can be tested without a clock, a location or WeatherKit.
//

import Foundation

enum NightTrigger: String, CaseIterable {
    case schedule = "Bedtime Schedule"
    case sun = "Sunset to Sunrise"
}

enum NightMode {
    /// Brightness choices, in percent. 100 = no dimming.
    static let brightnessChoices = [25, 50, 75, 100]

    // REM: the hour buttons offered in Settings (minutes after midnight). Defaults are 10 PM and 7 AM.
    static let startChoices = [20 * 60, 21 * 60, 22 * 60, 23 * 60, 0]
    static let endChoices = [5 * 60, 6 * 60, 7 * 60, 8 * 60, 9 * 60]
    static let defaultStart = 22 * 60
    static let defaultEnd = 7 * 60
    static let defaultBrightness = 50

    /// Minutes after midnight for a date, in the given calendar's time zone.
    static func minuteOfDay(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// True when `minute` falls in the window from `start` up to (not including) `end`.
    /// A window that crosses midnight (10 PM → 7 AM) wraps. start == end is an empty window.
    static func window(start: Int, end: Int, contains minute: Int) -> Bool {
        if start == end { return false }
        if start < end { return minute >= start && minute < end }
        return minute >= start || minute < end
    }

    /// Which rule decided the look — shown in Settings so the user can see a fallback is in use.
    enum Source: Equatable {
        case off, schedule, todaysSun, savedSun, scheduleFallback
    }

    /// REM (020): the whole decision, fallbacks included. `sun` is the saved sun times, if any.
    static func evaluate(enabled: Bool, trigger: NightTrigger, now: Date,
                         startMinutes: Int, endMinutes: Int,
                         sun: SunTimes?, calendar: Calendar = .current) -> (isNight: Bool, source: Source) {
        guard enabled else { return (false, .off) }
        let minute = minuteOfDay(now, calendar: calendar)
        if trigger == .sun, let sun, sun.isUsable {
            let night = window(start: sun.sunsetMinutes, end: sun.sunriseMinutes, contains: minute)
            return (night, sun.isFrom(now, calendar: calendar) ? .todaysSun : .savedSun)
        }
        // Schedule picked, or sun picked with no sun times yet → the bedtime schedule.
        // An empty schedule (start == end) means the daytime look — the last fallback.
        let night = window(start: startMinutes, end: endMinutes, contains: minute)
        return (night, trigger == .sun ? .scheduleFallback : .schedule)
    }

    static func timeLabel(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if minutes == 0 { return "Midnight" }
        if minutes == 12 * 60 { return "Noon" }
        let hour12 = h % 12 == 0 ? 12 : h % 12
        let suffix = h < 12 ? "AM" : "PM"
        return m == 0 ? "\(hour12) \(suffix)" : String(format: "%d:%02d %@", hour12, m, suffix)
    }
}

/// Sunrise and sunset as minutes after midnight, plus the day they were fetched for.
/// Saved on this Apple TV only (each TV knows its own location); never synced.
struct SunTimes: Equatable {
    var sunriseMinutes: Int
    var sunsetMinutes: Int
    var day: Date   // start of the day these times are for

    /// Sunrise must come before sunset (polar days/nights give no usable window → fall back).
    var isUsable: Bool { sunriseMinutes < sunsetMinutes }

    func isFrom(_ now: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(day, inSameDayAs: now)
    }

    // MARK: Saved locally

    private static let riseKey = "tally.night.sunriseMinutes"
    private static let setKey = "tally.night.sunsetMinutes"
    private static let dayKey = "tally.night.sunDay"

    static func load(from defaults: UserDefaults = .standard) -> SunTimes? {
        guard let day = defaults.object(forKey: dayKey) as? Date,
              let rise = defaults.object(forKey: riseKey) as? Int,
              let set = defaults.object(forKey: setKey) as? Int else { return nil }
        return SunTimes(sunriseMinutes: rise, sunsetMinutes: set, day: day)
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(sunriseMinutes, forKey: Self.riseKey)
        defaults.set(sunsetMinutes, forKey: Self.setKey)
        defaults.set(day, forKey: Self.dayKey)
    }
}
