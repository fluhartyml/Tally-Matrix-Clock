//
//  TallyTime.swift
//  Tally Matrix Clock
//
//  The clock's digit math, pulled out of ContentView so it can be tested (roadmap 014,
//  locked with Michael 2026 NOV 23).
//

import Foundation
import AVFoundation

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

// REM 2026 NOV 24 — his word: "say time with center button long press". The clock speaks the time
// itself, no VoiceOver needed (Apple lets no app switch VoiceOver on, so this is the one-stop-shop
// answer inside Tally). Play/Pause stays on the music; holding the center (click) button speaks.
// Background music is turned down (ducked) while it speaks, then comes back.
final class TimeSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TimeSpeaker()
    private let synth = AVSpeechSynthesizer()

    override init() {
        super.init()
        synth.delegate = self
    }

    // REM 11-24 — his "it should be the apple tv default voice" / "i want it to use the system voice".
    // Apple lets no app switch VoiceOver on or off, so: with VoiceOver on, the TV's VoiceOver voice
    // speaks (prefersAssistiveTechnologySettings); with it off, the best-quality voice downloaded on
    // that TV for its language. Apps can't read which voice VoiceOver uses, so this is the closest.
    static let whisperVolume: Float = 0.25

    static func bestVoice(from voices: [AVSpeechSynthesisVoice], language: String) -> AVSpeechSynthesisVoice? {
        voices.filter { $0.language == language }
              .max { $0.quality.rawValue < $1.quality.rawValue }
    }

    func say(_ time: TallyTime, whisper: Bool = false) {
        synth.stopSpeaking(at: .immediate)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        let utterance = AVSpeechUtterance(string: "It's \(time.spokenTime)")
        utterance.prefersAssistiveTechnologySettings = true
        utterance.voice = Self.bestVoice(from: AVSpeechSynthesisVoice.speechVoices(),
                                         language: AVSpeechSynthesisVoice.currentLanguageCode())
        // REM 11-24 — his "whisper during sleep mode toggle": quieter while Night Mode is showing.
        if whisper { utterance.volume = Self.whisperVolume }
        synth.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// REM 2026 NOV 24 — his ask: "can it be announce on the quater half or hour and or the center button
// long press?" → his "yes please" to two separate settings: Say Time Automatically (Off / Every Hour /
// Every Half Hour / Every Quarter Hour) and the long-press switch. Either, both or neither. Per TV.
enum SayTimeEvery: Int, CaseIterable {
    case off = 0, hour = 60, halfHour = 30, quarterHour = 15

    var label: String {
        switch self {
        case .off: "Off"
        case .hour: "Every Hour"
        case .halfHour: "Every Half Hour"
        case .quarterHour: "Every Quarter Hour"
        }
    }

    /// True when this minute of the day is one to announce.
    func announces(minute: Int) -> Bool {
        self != .off && minute % rawValue == 0
    }
}
