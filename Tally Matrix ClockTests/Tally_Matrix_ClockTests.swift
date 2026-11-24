//
//  Tally_Matrix_ClockTests.swift
//  Tally Matrix ClockTests
//
//  Created by Michael Fluharty on 10/16/25.
//  Real tests replace the empty placeholder — roadmap 014, locked with Michael 2026 NOV 23.
//  REM: these run BEFORE any iCloud change (roadmap 012) so they catch what the move breaks.
//  REM: no test may touch CloudKit — CloudSettings skips it under a test run.
//

import Foundation
import CloudKit
import Testing
@testable import Tally_Matrix_Clock

// MARK: - 12-hour tally digits

struct TwelveHourDigits {

    @Test("Midnight reads 12, not 0, with no PM dot")
    func midnight() {
        let t = TallyTime(hour24: 0, minute: 0, use24Hour: false)
        #expect(t.displayHour == 12)
        #expect(t.digits == [1, 2, 0, 0])
        #expect(t.isPM == false)
    }

    @Test("Noon reads 12 with the PM dot")
    func noon() {
        let t = TallyTime(hour24: 12, minute: 0, use24Hour: false)
        #expect(t.digits == [1, 2, 0, 0])
        #expect(t.isPM == true)
    }

    @Test("PM dot is off for every morning hour and on for every afternoon hour")
    func pmDotEveryHour() {
        for h in 0..<24 {
            #expect(TallyTime(hour24: h, minute: 30, use24Hour: false).isPM == (h >= 12), "hour \(h)")
        }
    }

    @Test("1 PM reads 1, 11 PM reads 11")
    func afternoon() {
        #expect(TallyTime(hour24: 13, minute: 5, use24Hour: false).digits == [0, 1, 0, 5])
        #expect(TallyTime(hour24: 23, minute: 59, use24Hour: false).digits == [1, 1, 5, 9])
    }

    @Test("9:09 lights nine squares in two matrices")
    func nines() {
        #expect(TallyTime(hour24: 9, minute: 9, use24Hour: false).digits == [0, 9, 0, 9])
    }

    @Test("Hour tens never uses the PM-dot square in 12-hour mode")
    func tensAvoidsPMSquare() {
        let t = TallyTime(hour24: 10, minute: 15, use24Hour: false)
        #expect(t.hoursTensSquares == 2)
        for _ in 0..<500 {
            let p = TallyTime.randomPattern(for: t.hoursTens, totalSquares: t.hoursTensSquares)
            #expect(p.count == 1)
            #expect(!p.contains(2))
        }
    }
}

// MARK: - 24-hour tally digits

struct TwentyFourHourDigits {

    @Test("Midnight reads 00:00")
    func midnight() {
        #expect(TallyTime(hour24: 0, minute: 0, use24Hour: true).digits == [0, 0, 0, 0])
    }

    @Test("23:59 reads 2-3-5-9")
    func lastMinute() {
        #expect(TallyTime(hour24: 23, minute: 59, use24Hour: true).digits == [2, 3, 5, 9])
    }

    @Test("19:09 has two nines")
    func nines() {
        #expect(TallyTime(hour24: 19, minute: 9, use24Hour: true).digits == [1, 9, 0, 9])
    }

    @Test("All three left squares can count the hours' tens")
    func tensUsesAllThree() {
        #expect(TallyTime(hour24: 20, minute: 0, use24Hour: true).hoursTensSquares == 3)
    }

    @Test("Every minute of the day splits back to the same time")
    func everyMinuteRoundTrips() {
        for h in 0..<24 {
            for m in 0..<60 {
                let d = TallyTime(hour24: h, minute: m, use24Hour: true).digits
                #expect(d[0] * 10 + d[1] == h)
                #expect(d[2] * 10 + d[3] == m)
            }
        }
    }
}

// MARK: - Lit-square patterns

struct Patterns {

    @Test("Zero lights nothing")
    func zero() {
        #expect(TallyTime.randomPattern(for: 0, totalSquares: 9).isEmpty)
    }

    @Test("Nine lights all nine squares")
    func nine() {
        #expect(TallyTime.randomPattern(for: 9, totalSquares: 9) == Set(0..<9))
    }

    @Test("Every value lights exactly that many distinct squares, all on the grid")
    func exactCount() {
        for value in 0...9 {
            for _ in 0..<50 {
                let p = TallyTime.randomPattern(for: value, totalSquares: 9)
                #expect(p.count == value)
                #expect(p.allSatisfy { (0..<9).contains($0) })
            }
        }
    }

    @Test("An out-of-range value never hangs or overflows the grid")
    func outOfRange() {
        #expect(TallyTime.randomPattern(for: 12, totalSquares: 9).count == 9)
        #expect(TallyTime.randomPattern(for: -1, totalSquares: 9).isEmpty)
    }
}

// MARK: - Remote commands from another Apple TV

struct RemoteCommands {

    private func roundTrip(_ key: String, _ value: Any) -> (key: String, value: Any?)? {
        guard let json = CloudSettings.encodeSettingRequest(key: key, value: value, timestamp: 1000) else { return nil }
        return CloudSettings.decodeSettingRequest(json)
    }

    @Test("A color theme request arrives as the same string")
    func colorTheme() {
        let r = roundTrip("colorSchemeRaw", "Crimson (Sleep)")
        #expect(r?.key == "colorSchemeRaw")
        #expect(r?.value as? String == "Crimson (Sleep)")
    }

    @Test("On/off requests arrive as Bool")
    func toggles() {
        for key in ["use24Hour", "showDate", "showWeather", "showGlyphRain", "backgroundMusic", "playInBackground", "showBase10"] {
            #expect(roundTrip(key, true)?.value as? Bool == true, "\(key)")
            #expect(roundTrip(key, false)?.value as? Bool == false, "\(key)")
        }
    }

    @Test("Sleep timer minutes arrive as Int, pattern interval as Double")
    func numbers() {
        #expect(roundTrip("sleepTimerMinutes", 45)?.value as? Int == 45)
        #expect(roundTrip("patternInterval", 15.0)?.value as? Double == 15.0)
    }

    @Test("Two requests for the same value differ, so a repeat still registers")
    func repeatsDiffer() {
        let a = CloudSettings.encodeSettingRequest(key: "use24Hour", value: true, timestamp: 1)
        let b = CloudSettings.encodeSettingRequest(key: "use24Hour", value: true, timestamp: 2)
        #expect(a != nil && b != nil && a != b)
    }

    @Test("Empty or garbled requests are ignored, not crashed on")
    func malformed() {
        #expect(CloudSettings.decodeSettingRequest("") == nil)
        #expect(CloudSettings.decodeSettingRequest("not json") == nil)
        #expect(CloudSettings.decodeSettingRequest("{\"value\":true}") == nil)
    }

    @Test("Tests never talk to CloudKit")
    func cloudKitIsOffUnderTests() {
        #expect(CloudSettings.isRunningTests)
    }
}

// MARK: - Two Apple TVs change settings at the same moment (roadmap 026 / line 009)

// REM: Living Room changes the color while Office changes the rain size. Office's save lands
// first, so Living Room's save is rejected with Office's record. Both changes must survive.
// .serialized because both tests use the one shared CloudSettings.
@Suite(.serialized)
struct SimultaneousChanges {

    private func officeRecord(glyphSize: String, color: String) -> CKRecord {
        let id = CKRecord.ID(recordName: "HouseholdSettings", zoneID: CloudSettings.settingsZoneID)
        let record = CKRecord(recordType: "Settings", recordID: id)
        record["glyphRainSizeRaw"] = glyphSize as CKRecordValue
        record["colorSchemeRaw"] = color as CKRecordValue
        return record
    }

    @Test("Both changes land: Office's rain size and Living Room's color")
    func bothChangesLand() {
        let s = CloudSettings.shared
        s.glyphRainSizeRaw = GlyphRainSize.small.rawValue
        s.colorSchemeRaw = ColorSchemeOption.crimson.rawValue      // Living Room's change

        let office = officeRecord(glyphSize: GlyphRainSize.large.rawValue,
                                  color: ColorSchemeOption.randomRGB.rawValue)
        let retry = s.resolveConflict(server: office, ourKeys: ["colorSchemeRaw"])

        // On this TV: Office's size arrived, our color stayed.
        #expect(s.glyphRainSizeRaw == GlyphRainSize.large.rawValue)
        #expect(s.colorSchemeRaw == ColorSchemeOption.crimson.rawValue)
        // The retry sends both, so every TV ends up with both.
        #expect(retry["glyphRainSizeRaw"] as? String == GlyphRainSize.large.rawValue)
        #expect(retry["colorSchemeRaw"] as? String == ColorSchemeOption.crimson.rawValue)
    }

    @Test("The retry rewrites only the key we changed")
    func retryTouchesOnlyOurKey() {
        let s = CloudSettings.shared
        s.colorSchemeRaw = ColorSchemeOption.crimson.rawValue
        let office = officeRecord(glyphSize: GlyphRainSize.medium.rawValue,
                                  color: ColorSchemeOption.randomRGB.rawValue)
        let retry = s.resolveConflict(server: office, ourKeys: ["colorSchemeRaw"])
        // Settings neither TV touched are not rewritten from this TV's copy.
        #expect(retry["use24Hour"] == nil)
        #expect(retry["showWeather"] == nil)
        #expect(retry["glyphRainSizeRaw"] as? String == GlyphRainSize.medium.rawValue)
    }
}

// MARK: - Night Mode (roadmap 017–022, test 028)
// REM: pure decisions only — no clock, location or WeatherKit. A fixed UTC calendar keeps
// the minutes exact whatever time zone the test Mac is in.

struct NightModeRules {
    var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    func at(_ hour: Int, _ minute: Int = 0, day: Int = 24) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func evaluate(_ now: Date, enabled: Bool = true, trigger: NightTrigger = .schedule,
                  start: Int = NightMode.defaultStart, end: Int = NightMode.defaultEnd, sun: SunTimes? = nil) -> (isNight: Bool, source: NightMode.Source) {
        NightMode.evaluate(enabled: enabled, trigger: trigger, now: now, startMinutes: start, endMinutes: end, sun: sun, calendar: utc)
    }

    @Test("Off by default means never night — Night Mode is never forced")
    func offIsNeverNight() {
        #expect(evaluate(at(23), enabled: false) == (false, .off))
    }

    @Test("Bedtime 10 PM–7 AM wraps past midnight and returns to the day look at 7")
    func scheduleWraps() {
        #expect(evaluate(at(21, 59)).isNight == false)
        #expect(evaluate(at(22, 0)).isNight == true)
        #expect(evaluate(at(0, 0)).isNight == true)
        #expect(evaluate(at(6, 59)).isNight == true)
        #expect(evaluate(at(7, 0)).isNight == false)
        #expect(evaluate(at(12, 0)).isNight == false)
    }

    @Test("A window that does not cross midnight works too")
    func sameDayWindow() {
        #expect(NightMode.window(start: 60, end: 300, contains: 120))
        #expect(!NightMode.window(start: 60, end: 300, contains: 300))
    }

    @Test("Sunset to sunrise uses today's sun times")
    func followsTodaysSun() {
        let sun = SunTimes(sunriseMinutes: 7 * 60 + 5, sunsetMinutes: 17 * 60 + 30, day: utc.startOfDay(for: at(12)))
        #expect(evaluate(at(17, 29), trigger: .sun, sun: sun).isNight == false)
        #expect(evaluate(at(17, 30), trigger: .sun, sun: sun) == (true, .todaysSun))
        #expect(evaluate(at(7, 5), trigger: .sun, sun: sun).isNight == false)
    }

    @Test("020: weather unreachable today → last saved sun times stand in")
    func fallsBackToSavedSun() {
        let yesterday = SunTimes(sunriseMinutes: 7 * 60, sunsetMinutes: 17 * 60 + 30, day: utc.startOfDay(for: at(12, day: 23)))
        #expect(evaluate(at(18), trigger: .sun, sun: yesterday) == (true, .savedSun))
    }

    @Test("020: no sun times ever → the bedtime schedule")
    func fallsBackToSchedule() {
        #expect(evaluate(at(18), trigger: .sun, sun: nil) == (false, .scheduleFallback))
        #expect(evaluate(at(23), trigger: .sun, sun: nil) == (true, .scheduleFallback))
    }

    @Test("020: unusable sun times (polar) skip to the schedule; an empty schedule is the day look")
    func lastFallbacks() {
        let polar = SunTimes(sunriseMinutes: 0, sunsetMinutes: 0, day: utc.startOfDay(for: at(12)))
        #expect(evaluate(at(23), trigger: .sun, sun: polar) == (true, .scheduleFallback))
        #expect(evaluate(at(23), start: 0, end: 0).isNight == false)
    }

    @Test("Sun times save and load on this Apple TV")
    func sunRoundTrip() {
        let defaults = UserDefaults(suiteName: "tally.tests.night")!
        defaults.removePersistentDomain(forName: "tally.tests.night")
        let sun = SunTimes(sunriseMinutes: 425, sunsetMinutes: 1050, day: utc.startOfDay(for: at(12)))
        sun.save(to: defaults)
        #expect(SunTimes.load(from: defaults) == sun)
    }

    @Test("Hour labels read like a clock")
    func labels() {
        #expect(NightMode.timeLabel(0) == "Midnight")
        #expect(NightMode.timeLabel(22 * 60) == "10 PM")
        #expect(NightMode.timeLabel(7 * 60) == "7 AM")
    }

    @Test("021 + 017: Night Mode defaults — Crimson night theme, off, day theme untouched")
    func defaults() {
        let s = CloudSettings.shared
        #expect(ColorSchemeOption(rawValue: s.nightColorSchemeRaw) != nil)
        #expect(NightMode.brightnessChoices == [25, 50, 75, 100])
        #expect(CloudSettings.settingKeys.contains("nightColorSchemeRaw"))
        #expect(CloudSettings.settingKeys.contains("colorSchemeRaw"))
    }

    @Test("022: a follower's Night Mode request is applied by the leader")
    func followerRequest() {
        let s = CloudSettings.shared
        let before = s.nightBrightness
        let target = before == 25 ? 75 : 25
        s.requestSettingChange(key: "nightBrightness", value: target)
        s.applyRequestedSettings()
        #expect(s.nightBrightness == target)
        s.nightBrightness = before
    }
}

// MARK: - Remote left/right themes (roadmap 024)

struct RemoteThemeStepping {
    @Test("Right steps forward, left steps back, both wrap around")
    func wraps() {
        let all = ColorSchemeOption.allCases
        #expect(ContentView.theme(after: all[0], by: 1) == all[1])
        #expect(ContentView.theme(after: all[0], by: -1) == all.last)
        #expect(ContentView.theme(after: all.last!, by: 1) == all[0])
    }

    @Test("Stepping all the way round visits every theme once")
    func visitsAll() {
        var t = ColorSchemeOption.allCases[0]
        var seen: [ColorSchemeOption] = []
        for _ in ColorSchemeOption.allCases { seen.append(t); t = ContentView.theme(after: t, by: 1) }
        #expect(Set(seen.map(\.rawValue)).count == ColorSchemeOption.allCases.count)
    }
}

@Suite("Night Mode time steppers (his 11-24: any time, not five presets)")
struct NightModeStepperTests {
    @Test("Steps 15 minutes and wraps around midnight both ways")
    func steps() {
        #expect(NightMode.stepped(22 * 60, by: 1) == 22 * 60 + 15)
        #expect(NightMode.stepped(23 * 60 + 45, by: 1) == 0)
        #expect(NightMode.stepped(0, by: -1) == 23 * 60 + 45)
        #expect(NightMode.timeLabel(NightMode.stepped(7 * 60, by: 2)) == "7:30 AM")
        // A click jumps one hour (his 11-24): 11 PM + click → Midnight.
        #expect(NightMode.stepped(23 * 60, by: 60 / NightMode.timeStep) == 0)
    }
}
