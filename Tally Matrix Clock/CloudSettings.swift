//
//  CloudSettings.swift
//  Tally Matrix Clock
//
//  CloudKit-backed settings sync across the Apple TVs in ONE household.
//
//  REM — roadmap 001–010, locked with Michael 2026 NOV 23 (Grok's survey, reviewed line by line):
//  - Settings live in each household's PRIVATE iCloud (the Apple TV's iCloud account), in the
//    zone "TallySettings". Before this, every household shared ONE public record and every
//    Apple TV polled it every second — a privacy problem and tens of thousands of checks a day.
//  - The old public record is NEVER read or copied (it could hold another household's
//    settings). Each Apple TV seeds from its own locally saved settings (line 005).
//  - Changes arrive by SILENT PUSH (CKRecordZoneSubscription on "TallySettings"), plus a
//    quiet backstop fetch every 5 minutes and on wake, in case a push is missed.
//  - Offline or signed out of iCloud: runs on local settings as an independent clock (006).
//  - Only the fields that changed are written, and a conflict is retried on the fresh
//    record instead of overwriting the whole set (009).
//  - When iCloud asks us to slow down, we wait the time it gives before retrying (010).
//
//  ⛔ LOCKED (Michael: "be explicit so it doesnt get reverted on accident in the future"):
//  the leader's 30-second check-in lives in its OWN record in its OWN zone ("TallyCheckIn"),
//  NEVER in the settings record, and that zone NEVER gets a silent-push subscription.
//  Otherwise every check-in would push to every Apple TV every 30 seconds. Followers read
//  the check-in about once a minute; silence for 2 minutes = take over (007, 008).
//

import Foundation
import Combine
import UIKit
import CloudKit

class CloudSettings: ObservableObject {
    static let shared = CloudSettings()

    // REM: under a test run, never talk to CloudKit (roadmap 014).
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    // MARK: - Where things live

    private let container = CKContainer(identifier: "iCloud.com.fluhartyml.Tally-Matrix-Clock")
    private var database: CKDatabase { container.privateCloudDatabase }
    private let local = UserDefaults.standard

    static let settingsZoneID = CKRecordZone.ID(zoneName: "TallySettings", ownerName: CKCurrentUserDefaultName)
    static let checkInZoneID = CKRecordZone.ID(zoneName: "TallyCheckIn", ownerName: CKCurrentUserDefaultName)
    static let settingsSubscriptionID = "tally-settings-changes"
    private let settingsRecordID = CKRecord.ID(recordName: "HouseholdSettings", zoneID: CloudSettings.settingsZoneID)
    private let checkInRecordID = CKRecord.ID(recordName: "LeaderCheckIn", zoneID: CloudSettings.checkInZoneID)

    private static let zonesReadyKey = "tally.privateZonesReady.v1"
    private static let subscriptionReadyKey = "tally.settingsSubscriptionReady.v1"

    // MARK: - State

    /// True while loading or applying values from iCloud, so didSet doesn't write them back.
    private var initializing = true
    @Published var cloudReady: Bool = false
    private var cloudAvailable = false
    private var cachedRecord: CKRecord?
    private var pending = Set<String>()
    private var saveScheduled = false
    private var seeding = false
    private var backoffUntil: Date = .distantPast
    private var heartbeatTimer: Timer?
    private var followerTimer: Timer?
    private var followerTicks = 0
    private var lastLoggedError = ""
    private var observers: [NSObjectProtocol] = []

    // Display settings
    @Published var showBase10: Bool { didSet { syncToCloud("showBase10") } }
    @Published var use24Hour: Bool { didSet { syncToCloud("use24Hour") } }
    @Published var showDate: Bool { didSet { syncToCloud("showDate") } }
    @Published var showWeather: Bool { didSet { syncToCloud("showWeather") } }
    @Published var showGlyphRain: Bool { didSet { syncToCloud("showGlyphRain") } }
    @Published var glyphRainSizeRaw: String { didSet { syncToCloud("glyphRainSizeRaw") } }

    // Music settings
    @Published var backgroundMusic: Bool { didSet { syncToCloud("backgroundMusic") } }
    @Published var playInBackground: Bool { didSet { syncToCloud("playInBackground") } }
    @Published var musicStationRaw: String { didSet { syncToCloud("musicStationRaw") } }
    @Published var sleepTimerMinutes: Int { didSet { syncToCloud("sleepTimerMinutes") } }

    // Appearance settings
    @Published var colorSchemeRaw: String { didSet { syncToCloud("colorSchemeRaw") } }
    @Published var patternInterval: Double { didSet { syncToCloud("patternInterval") } }

    // Leader/Follower
    @Published var leaderDeviceName: String { didSet { syncToCloud("leaderDeviceName") } }
    @Published var isLeader: Bool = false
    @Published var leaderLastSeen: Date = .distantPast
    private let leaderTimeout: TimeInterval = 120 // 2 minutes
    private let heartbeatInterval: TimeInterval = 30
    private let followerCheckInterval: TimeInterval = 60
    private let backstopEveryTicks = 5 // × 60 s = settings re-read every 5 minutes

    // Remote commands — any device can request, leader executes
    @Published var pauseRequested: Bool { didSet { if !initializing { pushRemoteCommand("pauseRequested") } } }
    @Published var skipRequested: Bool { didSet { if !initializing { pushRemoteCommand("skipRequested") } } }
    @Published var requestedStation: String { didSet { if !initializing { pushRemoteCommand("requestedStation") } } }
    @Published var requestedSettings: String { didSet { if !initializing { pushRemoteCommand("requestedSettings") } } }

    static let settingKeys = ["showBase10", "use24Hour", "showDate", "showWeather", "showGlyphRain",
                              "glyphRainSizeRaw", "backgroundMusic", "playInBackground", "musicStationRaw",
                              "sleepTimerMinutes", "colorSchemeRaw", "patternInterval", "leaderDeviceName"]
    static let commandKeys = ["pauseRequested", "skipRequested", "requestedStation", "requestedSettings"]

    // MARK: - Setting requests (pure, tested)

    // REM: the request wire format is two pure functions so it can be tested without
    // touching CloudKit (roadmap 014). Tests must never write to iCloud.
    /// Encodes a follower's setting request. The timestamp makes a repeat of the same value still register.
    static func encodeSettingRequest(key: String, value: Any, timestamp: TimeInterval = Date().timeIntervalSince1970) -> String? {
        let dict: [String: Any] = ["key": key, "value": value, "ts": timestamp]
        guard JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Decodes a setting request; nil when it is empty or malformed.
    static func decodeSettingRequest(_ json: String) -> (key: String, value: Any?)? {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let key = dict["key"] as? String else { return nil }
        return (key, dict["value"])
    }

    /// Followers call this to request any setting change from the leader
    func requestSettingChange(key: String, value: Any) {
        if let json = Self.encodeSettingRequest(key: key, value: value) {
            requestedSettings = json
        }
    }

    /// Leader applies a requested setting change
    func applyRequestedSettings() {
        guard !requestedSettings.isEmpty else { return }
        guard let request = Self.decodeSettingRequest(requestedSettings) else {
            requestedSettings = ""
            return
        }
        let value = request.value

        switch request.key {
        case "colorSchemeRaw":
            if let v = value as? String { colorSchemeRaw = v }
        case "showBase10":
            if let v = value as? Bool { showBase10 = v }
        case "use24Hour":
            if let v = value as? Bool { use24Hour = v }
        case "showDate":
            if let v = value as? Bool { showDate = v }
        case "showWeather":
            if let v = value as? Bool { showWeather = v }
        case "showGlyphRain":
            if let v = value as? Bool { showGlyphRain = v }
        case "glyphRainSizeRaw":
            if let v = value as? String { glyphRainSizeRaw = v }
        case "backgroundMusic":
            if let v = value as? Bool { backgroundMusic = v }
        case "playInBackground":
            if let v = value as? Bool { playInBackground = v }
        case "musicStationRaw":
            if let v = value as? String { musicStationRaw = v }
        case "sleepTimerMinutes":
            if let v = value as? Int { sleepTimerMinutes = v }
        case "patternInterval":
            if let v = value as? Double { patternInterval = v }
        default:
            break
        }

        requestedSettings = ""
    }

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

    // MARK: - Start

    private init() {
        // REM (005): start from THIS Apple TV's locally saved settings — never the old public record.
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
        requestedStation = ""
        requestedSettings = ""

        // Don't trust local cache for leadership — iCloud is the authority
        isLeader = false

        initializing = false

        if Self.isRunningTests {
            cloudReady = true
            return
        }

        observers.append(NotificationCenter.default.addObserver(forName: .CKAccountChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.startCloud() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.fetchSettings() }
        })

        startCloud()
        startTimers()
    }

    /// Checks the iCloud account, makes sure the zones exist, then reads the household settings.
    private func startCloud() {
        container.accountStatus { [weak self] status, _ in
            Task { @MainActor in
                guard let self else { return }
                if status == .available {
                    self.cloudAvailable = true
                    self.ensureZones { [weak self] in
                        self?.fetchSettings()
                    }
                } else {
                    self.goLocalOnly()
                }
            }
        }
    }

    /// REM (006): no iCloud → run as an independent clock on local settings, quietly.
    private func goLocalOnly() {
        cloudAvailable = false
        initializing = true
        leaderDeviceName = ""   // independent: plays its own music, no leader to wait on
        isLeader = false
        initializing = false
        cloudReady = true
        logOnce("iCloud unavailable — running on local settings")
    }

    // MARK: - Zones and the silent-push subscription (once per account)

    private func ensureZones(then next: @escaping () -> Void) {
        if local.bool(forKey: Self.zonesReadyKey) {
            ensureSubscription()
            next()
            return
        }
        // Saving a zone that already exists is harmless — no duplicates (029).
        let zones = [CKRecordZone(zoneID: Self.settingsZoneID), CKRecordZone(zoneID: Self.checkInZoneID)]
        let op = CKModifyRecordZonesOperation(recordZonesToSave: zones, recordZoneIDsToDelete: nil)
        op.modifyRecordZonesResultBlock = { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success:
                    self.local.set(true, forKey: Self.zonesReadyKey)
                    self.ensureSubscription()
                    next()
                case .failure(let error):
                    self.handle(error) { [weak self] in self?.ensureZones(then: next) }
                    self.cloudReady = true
                }
            }
        }
        database.add(op)
    }

    private func ensureSubscription() {
        guard !local.bool(forKey: Self.subscriptionReadyKey) else { return }
        // ⛔ Subscribe to the SETTINGS zone only. Never to TallyCheckIn (roadmap 008).
        let subscription = CKRecordZoneSubscription(zoneID: Self.settingsZoneID, subscriptionID: Self.settingsSubscriptionID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true   // silent: no banner, no sound
        subscription.notificationInfo = info
        // A fixed subscription ID means saving it again replaces it — never a duplicate (029).
        let op = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        op.modifySubscriptionsResultBlock = { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success: self.local.set(true, forKey: Self.subscriptionReadyKey)
                case .failure(let error): self.handle(error) { [weak self] in self?.ensureSubscription() }
                }
            }
        }
        database.add(op)
    }

    private func zonesWentMissing() {
        local.set(false, forKey: Self.zonesReadyKey)
        local.set(false, forKey: Self.subscriptionReadyKey)
        cachedRecord = nil
    }

    // MARK: - Read the household settings

    /// Called on a silent push, on wake, at start, and every 5 minutes as a backstop.
    func fetchSettings(completion: ((Bool) -> Void)? = nil) {
        guard cloudAvailable, !Self.isRunningTests, Date() >= backoffUntil else {
            completion?(false)
            return
        }
        database.fetch(withRecordID: settingsRecordID) { [weak self] record, error in
            Task { @MainActor in
                guard let self else { completion?(false); return }
                if let record {
                    self.cachedRecord = record
                    self.applyCloudRecord(record, skipping: self.pending)
                    self.cloudReady = true
                    completion?(true)
                    return
                }
                let code = (error as? CKError)?.code
                if code == .unknownItem {
                    // First Apple TV on this account: seed the household from OUR local settings (005).
                    self.seeding = true
                    self.pending.formUnion(Self.settingKeys)
                    self.savePending()
                    self.cloudReady = true
                    completion?(true)
                } else if code == .zoneNotFound || code == .userDeletedZone {
                    self.zonesWentMissing()
                    self.ensureZones { [weak self] in self?.fetchSettings(completion: completion) }
                } else {
                    if let error { self.handle(error) { [weak self] in self?.fetchSettings() } }
                    self.cloudReady = true
                    completion?(false)
                }
            }
        }
    }

    private func applyCloudRecord(_ record: CKRecord, skipping: Set<String> = []) {
        initializing = true
        func take(_ key: String) -> Bool { !skipping.contains(key) }

        if take("showBase10"), let v = record["showBase10"] as? Bool { showBase10 = v }
        if take("use24Hour"), let v = record["use24Hour"] as? Bool { use24Hour = v }
        if take("showDate"), let v = record["showDate"] as? Bool { showDate = v }
        if take("showWeather"), let v = record["showWeather"] as? Bool { showWeather = v }
        if take("showGlyphRain"), let v = record["showGlyphRain"] as? Bool { showGlyphRain = v }
        if take("glyphRainSizeRaw"), let v = record["glyphRainSizeRaw"] as? String { glyphRainSizeRaw = v }
        if take("backgroundMusic"), let v = record["backgroundMusic"] as? Bool { backgroundMusic = v }
        if take("playInBackground"), let v = record["playInBackground"] as? Bool { playInBackground = v }
        if take("musicStationRaw"), let v = record["musicStationRaw"] as? String { musicStationRaw = v }
        if take("sleepTimerMinutes"), let v = record["sleepTimerMinutes"] as? Int { sleepTimerMinutes = v }
        if take("colorSchemeRaw"), let v = record["colorSchemeRaw"] as? String { colorSchemeRaw = v }
        if take("patternInterval"), let v = record["patternInterval"] as? Double { patternInterval = v }
        if take("leaderDeviceName"), let v = record["leaderDeviceName"] as? String {
            leaderDeviceName = v
            isLeader = !v.isEmpty && v == deviceName
        }
        if take("pauseRequested"), let v = record["pauseRequested"] as? Bool { pauseRequested = v }
        if take("skipRequested"), let v = record["skipRequested"] as? Bool { skipRequested = v }
        if take("requestedStation"), let v = record["requestedStation"] as? String { requestedStation = v }
        if take("requestedSettings"), let v = record["requestedSettings"] as? String { requestedSettings = v }

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

    // MARK: - Write only what changed (009)

    private func syncToCloud(_ key: String) {
        guard !initializing else { return }
        saveLocally()
        guard !Self.isRunningTests else { return }
        // Only the leader (or an independent device) writes settings; followers send requests.
        guard leaderDeviceName.isEmpty || isLeader else { return }
        pending.insert(key)
        scheduleSave()
    }

    // Any device (leader or follower) can send remote commands
    private func pushRemoteCommand(_ key: String) {
        guard !Self.isRunningTests else { return }
        pending.insert(key)
        scheduleSave()
    }

    /// Gathers changes made in the same moment into one small write.
    private func scheduleSave() {
        guard !saveScheduled else { return }
        saveScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            Task { @MainActor in
                self?.saveScheduled = false
                self?.savePending()
            }
        }
    }

    private func value(for key: String) -> CKRecordValue? {
        switch key {
        case "showBase10": return showBase10 as CKRecordValue
        case "use24Hour": return use24Hour as CKRecordValue
        case "showDate": return showDate as CKRecordValue
        case "showWeather": return showWeather as CKRecordValue
        case "showGlyphRain": return showGlyphRain as CKRecordValue
        case "glyphRainSizeRaw": return glyphRainSizeRaw as CKRecordValue
        case "backgroundMusic": return backgroundMusic as CKRecordValue
        case "playInBackground": return playInBackground as CKRecordValue
        case "musicStationRaw": return musicStationRaw as CKRecordValue
        case "sleepTimerMinutes": return sleepTimerMinutes as CKRecordValue
        case "colorSchemeRaw": return colorSchemeRaw as CKRecordValue
        case "patternInterval": return patternInterval as CKRecordValue
        case "leaderDeviceName": return leaderDeviceName as CKRecordValue
        case "pauseRequested": return pauseRequested as CKRecordValue
        case "skipRequested": return skipRequested as CKRecordValue
        case "requestedStation": return requestedStation as CKRecordValue
        case "requestedSettings": return requestedSettings as CKRecordValue
        default: return nil
        }
    }

    private func savePending(attempt: Int = 0) {
        guard cloudAvailable, !pending.isEmpty, Date() >= backoffUntil else { return }
        let keys = pending
        pending.removeAll()

        let record = stamp(keys, onto: cachedRecord ?? CKRecord(recordType: "Settings", recordID: settingsRecordID))

        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        // Only the keys set above are sent; the server rejects us if someone else wrote first.
        op.savePolicy = .ifServerRecordUnchanged
        op.perRecordSaveBlock = { [weak self] _, result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let saved):
                    self.cachedRecord = saved
                    self.seeding = false
                case .failure(let error):
                    self.saveFailed(error, keys: keys, attempt: attempt)
                }
            }
        }
        database.add(op)
    }

    /// Writes only the given keys onto the record (line 009: save only what changed).
    private func stamp(_ keys: Set<String>, onto record: CKRecord) -> CKRecord {
        for key in keys { record[key] = value(for: key) }
        return record
    }

    /// REM 009/026: another Apple TV saved first. Take every field it wrote, keep only OUR changed
    /// keys on top, and return the record the retry will send. Internal (not private) so the
    /// two-changes-at-once test can drive it without CloudKit — two remotes in two rooms is not a test.
    func resolveConflict(server: CKRecord, ourKeys: Set<String>) -> CKRecord {
        cachedRecord = server
        pending.formUnion(ourKeys)
        applyCloudRecord(server, skipping: pending)
        return stamp(pending, onto: server)
    }

    private func saveFailed(_ error: Error, keys: Set<String>, attempt: Int) {
        let ck = error as? CKError
        if ck?.code == .serverRecordChanged, let server = ck?.serverRecord {
            cachedRecord = server
            if seeding {
                // Another Apple TV seeded first: theirs is the household's. Adopt it.
                seeding = false
                applyCloudRecord(server, skipping: pending)
            } else {
                // Two changes at once: keep the other room's fields, re-apply ours, try again.
                _ = resolveConflict(server: server, ourKeys: keys)
                if attempt < 3 { savePending(attempt: attempt + 1) }
            }
        } else if ck?.code == .zoneNotFound || ck?.code == .userDeletedZone {
            pending.formUnion(keys)
            zonesWentMissing()
            ensureZones { [weak self] in self?.savePending() }
        } else {
            pending.formUnion(keys)
            handle(error) { [weak self] in
                guard attempt < 3 else { return }
                self?.savePending(attempt: attempt + 1)
            }
        }
    }

    // MARK: - Leader check-in (its own record and zone — see the ⛔ REM at the top)

    private func startTimers() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isLeader else { return }
                self.writeCheckIn()
            }
        }
        followerTimer = Timer.scheduledTimer(withTimeInterval: followerCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.readCheckIn()
                self.followerTicks += 1
                if self.followerTicks % self.backstopEveryTicks == 0 {
                    self.fetchSettings()   // backstop in case a silent push was missed
                }
            }
        }
    }

    private func writeCheckIn() {
        guard cloudAvailable, isLeader, Date() >= backoffUntil else { return }
        let record = CKRecord(recordType: "CheckIn", recordID: checkInRecordID)
        record["leaderDeviceName"] = deviceName as CKRecordValue
        record["leaderLastSeen"] = Date() as CKRecordValue
        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = .allKeys   // only the leader writes this record
        op.perRecordSaveBlock = { [weak self] _, result in
            Task { @MainActor in
                guard let self, case .failure(let error) = result else { return }
                let code = (error as? CKError)?.code
                if code == .zoneNotFound || code == .userDeletedZone {
                    self.zonesWentMissing()
                    self.ensureZones { }
                } else {
                    self.handle(error, retry: nil)   // the next 30 s tick tries again
                }
            }
        }
        database.add(op)
    }

    private func readCheckIn() {
        guard cloudAvailable, !isLeader, !leaderDeviceName.isEmpty, Date() >= backoffUntil else { return }
        database.fetch(withRecordID: checkInRecordID) { [weak self] record, error in
            Task { @MainActor in
                guard let self else { return }
                if record == nil, let code = (error as? CKError)?.code, code != .unknownItem {
                    if let error { self.handle(error, retry: nil) }
                    return   // couldn't read it: never take over on a failed read
                }
                let seen = record?["leaderLastSeen"] as? Date ?? .distantPast
                self.leaderLastSeen = seen
                let elapsed = Date().timeIntervalSince(seen)
                if elapsed > self.leaderTimeout, !self.isLeader, !self.leaderDeviceName.isEmpty {
                    print("CloudKit: no check-in from the leader for \(Int(min(elapsed, 99999)))s — taking over")
                    self.setAsLeader()
                }
            }
        }
    }

    // MARK: - Errors, quietly (006, 010)

    /// Waits as long as iCloud asks before retrying; logs each kind of failure once, not as a stream.
    private func handle(_ error: Error, retry: (() -> Void)?) {
        let ck = error as? CKError
        logOnce("CloudKit: \(ck.map { "\($0.code.rawValue)" } ?? "?") \(error.localizedDescription)")
        if ck?.code == .notAuthenticated {
            goLocalOnly()
            return
        }
        if let wait = ck?.retryAfterSeconds {
            // REM (010): requestRateLimited / zoneBusy / serviceUnavailable carry a wait time.
            backoffUntil = Date().addingTimeInterval(wait)
            if let retry {
                DispatchQueue.main.asyncAfter(deadline: .now() + wait + 0.1) {
                    Task { @MainActor in retry() }
                }
            }
        }
        // Network trouble: no retry loop — the timers and the next push pick it up.
    }

    private func logOnce(_ message: String) {
        guard message != lastLoggedError else { return }
        lastLoggedError = message
        print(message)
    }

    // MARK: - Leader Controls

    func setAsLeader() {
        isLeader = true
        leaderDeviceName = deviceName  // didSet → syncToCloud, isLeader is already true so it is written
        writeCheckIn()
    }

    func resignLeader() {
        isLeader = false
        leaderDeviceName = ""  // didSet → syncToCloud writes the empty leader
    }
}
