//
//  CloudSettings.swift
//  Tally Matrix Clock
//
//  CloudKit-backed settings sync across all Apple TVs
//  Leader pushes settings → CloudKit record → silent push → followers pull
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
    private let subscriptionID = "settings-changes"

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

    // Appearance settings
    @Published var colorSchemeRaw: String { didSet { syncToCloud() } }
    @Published var patternInterval: Double { didSet { syncToCloud() } }

    // Leader/Follower
    @Published var leaderDeviceName: String { didSet { syncToCloud() } }
    @Published var isLeader: Bool = false

    var deviceName: String {
        #if os(tvOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Unknown"
        #endif
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
        colorSchemeRaw = local.string(forKey: "colorSchemeRaw") ?? ColorSchemeOption.randomRGB.rawValue
        patternInterval = local.object(forKey: "patternInterval") as? Double ?? 60.0
        leaderDeviceName = local.string(forKey: "leaderDeviceName") ?? ""

        isLeader = !leaderDeviceName.isEmpty && leaderDeviceName == deviceName

        initializing = false

        // Pull latest from CloudKit
        pullFromCloud()

        // Subscribe to changes so we get silent push notifications
        subscribeToChanges()
    }

    // MARK: - CloudKit Push

    private func syncToCloud() {
        guard !initializing else { return }
        saveLocally()

        // Only the leader (or independent devices) push to CloudKit
        guard leaderDeviceName.isEmpty || isLeader else { return }

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
        record["colorSchemeRaw"] = colorSchemeRaw as CKRecordValue
        record["patternInterval"] = patternInterval as CKRecordValue
        record["leaderDeviceName"] = leaderDeviceName as CKRecordValue

        let operation = CKModifyRecordsOperation(recordsToSave: [record])
        operation.savePolicy = .changedKeys
        operation.modifyRecordsResultBlock = { result in
            if case .failure(let error) = result {
                print("CloudKit save error: \(error.localizedDescription)")
            }
        }
        container.publicCloudDatabase.add(operation)
    }

    // MARK: - CloudKit Pull

    func pullFromCloud() {
        container.publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] record, error in
            guard let self = self, let record = record else {
                if let error = error as? CKError, error.code == .unknownItem {
                    // No record yet — leader will create it on first settings change
                    print("CloudKit: No settings record yet")
                }
                return
            }

            DispatchQueue.main.async {
                self.applyCloudRecord(record)
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
        if let v = record["colorSchemeRaw"] as? String { colorSchemeRaw = v }
        if let v = record["patternInterval"] as? Double { patternInterval = v }
        if let v = record["leaderDeviceName"] as? String {
            leaderDeviceName = v
            isLeader = !v.isEmpty && v == deviceName
        }

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
        local.set(colorSchemeRaw, forKey: "colorSchemeRaw")
        local.set(patternInterval, forKey: "patternInterval")
        local.set(leaderDeviceName, forKey: "leaderDeviceName")
    }

    // MARK: - CloudKit Subscription

    private func subscribeToChanges() {
        // Check if subscription already exists
        container.publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { [weak self] subscription, error in
            if subscription != nil { return } // Already subscribed

            guard let self = self else { return }

            let subscription = CKQuerySubscription(
                recordType: "Settings",
                predicate: NSPredicate(value: true),
                subscriptionID: self.subscriptionID,
                options: [.firesOnRecordUpdate, .firesOnRecordCreation]
            )

            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true // Silent push
            subscription.notificationInfo = info

            self.container.publicCloudDatabase.save(subscription) { _, error in
                if let error = error {
                    print("CloudKit subscription error: \(error.localizedDescription)")
                }
            }
        }
    }

    // Called from AppDelegate when silent push arrives
    func handleRemoteNotification() {
        pullFromCloud()
    }

    // MARK: - Leader Controls

    func setAsLeader() {
        leaderDeviceName = deviceName
        isLeader = true
    }

    func resignLeader() {
        if isLeader {
            leaderDeviceName = ""
            isLeader = false
        }
    }
}
