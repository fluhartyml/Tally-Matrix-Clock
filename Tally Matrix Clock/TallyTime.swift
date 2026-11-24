//
//  TallyTime.swift
//  Tally Matrix Clock
//
//  The clock's digit math, pulled out of ContentView so it can be tested (roadmap 014,
//  locked with Michael 2026 NOV 23).
//

import Foundation

struct TallyTime: Equatable {
    let hour24: Int      // 0...23
    let minute: Int      // 0...59
    let use24Hour: Bool

    init(date: Date, use24Hour: Bool, calendar: Calendar = .current) {
        self.hour24 = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
        self.use24Hour = use24Hour
    }

    init(hour24: Int, minute: Int, use24Hour: Bool) {
        self.hour24 = hour24
        self.minute = minute
        self.use24Hour = use24Hour
    }

    /// 0–23 in 24-hour mode; 1–12 in 12-hour mode (midnight and noon read 12).
    var displayHour: Int {
        if use24Hour { return hour24 }
        let hour12 = hour24 % 12
        return hour12 == 0 ? 12 : hour12
    }

    var isPM: Bool { hour24 >= 12 }

    /// REM: what VoiceOver reads for the tally face (his 11-24 accessibility ask). The squares mean
    /// nothing read aloud, so the face is one element whose value is the time, in the clock's own
    /// mode: "8:45 AM" in 12-hour, "20:45" in 24-hour.
    var spokenTime: String {
        NightMode.timeLabel(hour24 * 60 + minute, use24Hour: use24Hour)
    }

    var hoursTens: Int { displayHour / 10 }
    var hoursOnes: Int { displayHour % 10 }
    var minutesTens: Int { minute / 10 }
    var minutesOnes: Int { minute % 10 }

    var digits: [Int] { [hoursTens, hoursOnes, minutesTens, minutesOnes] }

    /// How many squares of the 1x3 column may count the hours' tens digit.
    // REM: In 12-hour mode the bottom square (index 2) is the PM dot and is drawn from
    // isPM, not from the pattern. Before 2026 NOV 23 the tens pattern was drawn from all
    // 3 squares, so at 10, 11 and 12 o'clock it sometimes landed on index 2 and the "1"
    // vanished (10:15 read as 0:15). The tens digit may only use squares 0 and 1 then.
    var hoursTensSquares: Int { use24Hour ? 3 : 2 }

    /// Exactly `value` distinct lit squares, chosen at random from 0..<totalSquares.
    static func randomPattern(for value: Int, totalSquares: Int) -> Set<Int> {
        let count = min(max(value, 0), totalSquares)
        return Set((0..<totalSquares).shuffled().prefix(count))
    }
}
