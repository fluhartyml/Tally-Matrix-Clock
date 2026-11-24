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
