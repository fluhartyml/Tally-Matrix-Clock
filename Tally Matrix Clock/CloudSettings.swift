//
//  CloudSettings.swift
//  Tally Matrix Clock
//
//  CloudKit-backed settings sync across all Apple TVs
//  Leader pushes settings → CloudKit record → followers poll every 1s
//

import Foundation
import Combine
import UIKit
import CloudKit

class CloudSettings: ObservableObject {
    static let shared = CloudSettings()

    private let container = CKContainer(identifier: "iCloud.com.fluhartyml.Tally-Matrix-Clock")
    private let local = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var initializing = true
    private let recordID = CKRecord.ID(recordName: "SharedSettings")
    private var pollTimer: Timer?
    @Published var cloudReady: Bool = false
    private var lastPushTime: Date = .distantPast

    // Display settings
    @Published var showBase10: Bool { didSet { syncToCloud() } }
    @Published var use24Hour: Bool { didSet { syncToCloud() } }
    @Published var showDate: Bool { didSet { syncToCloud() } }
    @Published var showWeather: Bool { didSet { syncToCloud() } }
    @Published var showGlyphRain: Bool { didSet { syncToCloud() } }
    @Published var glyphRainSizeRaw: String { didSet { syncToCloud() } }

    // Music settings
    @Published var backgroundMusic: Bool { didSet { syncToCloud() } }
    @Published var playInBackground: Bool { didSet { syncToCloud() } }
    @Published var musicStationRaw: String { didSet { syncToCloud() } }
    @Published var sleepTimerMinutes: Int { didSet { syncToCloud() } }

    // Appearance settings
    @Published var colorSchemeRaw: String { didSet { syncToCloud() } }
    @Published var patternInterval: Double { didSet { syncToCloud() } }

    // Leader/Follower
    @Published var leaderDeviceName: String { didSet { syncToCloud() } }
    @Published var isLeader: Bool = false

    // Remote commands — any device can request, leader executes
    @Published var pauseRequested: Bool { didSet { if !initializing { pushRemoteCommand() } } }
    @Published var skipRequested: Bool { didSet { if !initializing { pushRemoteCommand() } } }

    // Unique per-device ID (persists across launches, unique per Apple TV)
    let deviceID: String = {
        let key = "tallyMatrixDeviceID"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString.prefix(8).lowercased()
        UserDefaults.standard.set(String(new), forKey: key)
        return String(new)
    }()

    // Display name: "Apple TV" + unique suffix so you can tell them apart
    var deviceName: String {
        return "Apple TV (\(deviceID))"
    }

    private init() {
        // Load from local defaults first (instant), then pull from CloudKit (async)
        showBase10 = local.object(forKey: "showBase10") as? Bool ?? true
        use24Hour = local.object(forKey: "use24Hour") as? Bool ?? true
        showDate = local.object(forKey: "showDate") as? Bool ?? false
        showWeather = local.object(forKey: "showWeather") as? Bool ?? false
        showGlyphRain = local.object(forKey: "showGlyphRain") as? Bool ?? false
        glyphRainSizeRaw = local.string(forKey: "glyphRainSizeRaw") ?? GlyphRainSize.medium.rawValue
        backgroundMusic = local.object(forKey: "backgroundMusic") as? Bool ?? false
        playInBackground = local.object(forKey: "playInBackground") as? Bool ?? false
        musicStationRaw = local.string(forKey: "musicStationRaw") ?? MusicStationOption.none.rawValue
        sleepTimerMinutes = local.object(forKey: "sleepTimerMinutes") as? Int ?? 0
        colorSchemeRaw = local.string(forKey: "colorSchemeRaw") ?? ColorSchemeOption.randomRGB.rawValue
        patternInterval = local.object(forKey: "patternInterval") as? Double ?? 60.0
        leaderDeviceName = local.string(forKey: "leaderDeviceName") ?? ""
        pauseRequested = false  // Never persist — always starts fresh
        skipRequested = false

        // Don't trust local cache for leadership — CloudKit is the authority
        // Start as non-leader; pullFromCloud will promote us if we're actually leader
        isLeader = false

        initializing = false

        // Pull from CloudKit to get the real leader state
        pullFromCloud()

        // Poll CloudKit every 1 second for changes
        startPolling()
    }

    // MARK: - CloudKit Push

    private func syncToCloud() {
        guard !initializing else { return }
        saveLocally()

        // Only the leader (or independent devices) push to CloudKit
        guard leaderDeviceName.isEmpty || isLeader else { return }

        lastPushTime = Date()
        let record = CKRecord(recordType: "Settings", recordID: recordID)
        record["showBase10"] = showBase10 as CKRecordValue
        record["use24Hour"] = use24Hour as CKRecordValue
        record["showDate"] = showDate as CKRecordValue
        record["showWeather"] = showWeather as CKRecordValue
        record["showGlyphRain"] = showGlyphRain as CKRecordValue
        record["glyphRainSizeRaw"] = glyphRainSizeRaw as CKRecordValue
        record["backgroundMusic"] = backgroundMusic as CKRecordValue
        record["playInBackground"] = playInBackground as CKRecordValue
        record["musicStationRaw"] = musicStationRaw as CKRecordValue
        record["sleepTimerMinutes"] = sleepTimerMinutes as CKRecordValue
        record["colorSchemeRaw"] = colorSchemeRaw as CKRecordValue
        record["patternInterval"] = patternInterval as CKRecordValue
        record["leaderDeviceName"] = leaderDeviceName as CKRecordValue

        let operation = CKModifyRecordsOperation(recordsToSave: [record])
        operation.savePolicy = .allKeys
        operation.modifyRecordsResultBlock = { result in
            if case .failure(let error) = result {
                print("CloudKit save error: \(error.localizedDescription)")
            } else {
                print("CloudKit: Settings pushed successfully")
            }
        }
        container.publicCloudDatabase.add(operation)
    }

    // MARK: - CloudKit Pull

    func pullFromCloud() {
        container.publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self, let record = record else {
                if let error = error as? CKError, error.code == .unknownItem {
                    print("CloudKit: No settings record yet — toggle leader in settings to create it")
                }
                DispatchQueue.main.async {
                    self?.cloudReady = true
                }
                return
            }

            DispatchQueue.main.async {
                // Don't overwrite local changes if we just pushed — wait for CloudKit to catch up
                if Date().timeIntervalSince(self.lastPushTime) < 3.0 {
                    if !self.cloudReady { self.cloudReady = true }
                    return
                }
                self.applyCloudRecord(record)
                self.cloudReady = true
            }
        }
    }

    private func applyCloudRecord(_ record: CKRecord) {
        initializing = true

        if let v = record["showBase10"] as? Bool { showBase10 = v }
        if let v = record["use24Hour"] as? Bool { use24Hour = v }
        if let v = record["showDate"] as? Bool { showDate = v }
        if let v = record["showWeather"] as? Bool { showWeather = v }
        if let v = record["showGlyphRain"] as? Bool { showGlyphRain = v }
        if let v = record["glyphRainSizeRaw"] as? String { glyphRainSizeRaw = v }
        if let v = record["backgroundMusic"] as? Bool { backgroundMusic = v }
        if let v = record["playInBackground"] as? Bool { playInBackground = v }
        if let v = record["musicStationRaw"] as? String { musicStationRaw = v }
        if let v = record["sleepTimerMinutes"] as? Int { sleepTimerMinutes = v }
        if let v = record["colorSchemeRaw"] as? String {
            if colorSchemeRaw != v {
                print("CloudKit: Color scheme changed from \(colorSchemeRaw) to \(v)")
            }
            colorSchemeRaw = v
        }
        if let v = record["patternInterval"] as? Double { patternInterval = v }
        if let v = record["leaderDeviceName"] as? String {
            if leaderDeviceName != v {
                print("CloudKit: Leader changed from \(leaderDeviceName) to \(v)")
            }
            leaderDeviceName = v
            isLeader = !v.isEmpty && v == deviceName
        }
        if let v = record["pauseRequested"] as? Bool { pauseRequested = v }
        if let v = record["skipRequested"] as? Bool { skipRequested = v }

        initializing = false
        saveLocally()
    }

    private func saveLocally() {
        local.set(showBase10, forKey: "showBase10")
        local.set(use24Hour, forKey: "use24Hour")
        local.set(showDate, forKey: "showDate")
        local.set(showWeather, forKey: "showWeather")
        local.set(showGlyphRain, forKey: "showGlyphRain")
        local.set(glyphRainSizeRaw, forKey: "glyphRainSizeRaw")
        local.set(backgroundMusic, forKey: "backgroundMusic")
        local.set(playInBackground, forKey: "playInBackground")
        local.set(musicStationRaw, forKey: "musicStationRaw")
        local.set(sleepTimerMinutes, forKey: "sleepTimerMinutes")
        local.set(colorSchemeRaw, forKey: "colorSchemeRaw")
        local.set(patternInterval, forKey: "patternInterval")
        local.set(leaderDeviceName, forKey: "leaderDeviceName")
    }

    // MARK: - CloudKit Polling

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pullFromCloud()
        }
    }

    // MARK: - Leader Controls

    // Any device (leader or follower) can push remote commands
    private func pushRemoteCommand() {
        lastPushTime = Date()
        container.publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self, let record = record else { return }
            record["pauseRequested"] = self.pauseRequested as CKRecordValue
            record["skipRequested"] = self.skipRequested as CKRecordValue
            let operation = CKModifyRecordsOperation(recordsToSave: [record])
            operation.savePolicy = .changedKeys
            operation.modifyRecordsResultBlock = { result in
                if case .failure(let error) = result {
                    print("CloudKit remote command error: \(error.localizedDescription)")
                } else {
                    print("CloudKit: Remote command pushed (pause=\(self.pauseRequested), skip=\(self.skipRequested))")
                }
            }
            self.container.publicCloudDatabase.add(operation)
        }
    }

    func setAsLeader() {
        isLeader = true
        leaderDeviceName = deviceName  // didSet → syncToCloud, isLeader is already true so push goes through
    }

    func resignLeader() {
        isLeader = false
        leaderDeviceName = ""  // didSet → syncToCloud pushes empty leader
    }
}
