//
//  CloudSettings.swift
//  Tally Matrix Clock
//
//  iCloud-backed settings sync across all Apple TVs
//

import Foundation
import Combine
import UIKit

class CloudSettings: ObservableObject {
    static let shared = CloudSettings()

    private let cloud = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // Display settings
    @Published var showBase10: Bool { didSet { sync("showBase10", showBase10) } }
    @Published var use24Hour: Bool { didSet { sync("use24Hour", use24Hour) } }
    @Published var showDate: Bool { didSet { sync("showDate", showDate) } }
    @Published var showWeather: Bool { didSet { sync("showWeather", showWeather) } }
    @Published var showGlyphRain: Bool { didSet { sync("showGlyphRain", showGlyphRain) } }
    @Published var glyphRainSizeRaw: String { didSet { sync("glyphRainSizeRaw", glyphRainSizeRaw) } }

    // Music settings
    @Published var backgroundMusic: Bool { didSet { sync("backgroundMusic", backgroundMusic) } }
    @Published var playInBackground: Bool { didSet { sync("playInBackground", playInBackground) } }
    @Published var musicStationRaw: String { didSet { sync("musicStationRaw", musicStationRaw) } }

    // Appearance settings
    @Published var colorSchemeRaw: String { didSet { sync("colorSchemeRaw", colorSchemeRaw) } }
    @Published var patternInterval: Double { didSet { sync("patternInterval", patternInterval) } }

    // Leader/Follower
    @Published var leaderDeviceName: String { didSet { sync("leaderDeviceName", leaderDeviceName) } }
    @Published var isLeader: Bool = false

    var deviceName: String {
        #if os(tvOS)
        return UIDevice.current.name
        #else
        return Host.current().localizedName ?? "Unknown"
        #endif
    }

    private init() {
        // Load from iCloud first, fall back to local defaults
        showBase10 = cloud.object(forKey: "showBase10") as? Bool ?? local.object(forKey: "showBase10") as? Bool ?? true
        use24Hour = cloud.object(forKey: "use24Hour") as? Bool ?? local.object(forKey: "use24Hour") as? Bool ?? true
        showDate = cloud.object(forKey: "showDate") as? Bool ?? local.object(forKey: "showDate") as? Bool ?? false
        showWeather = cloud.object(forKey: "showWeather") as? Bool ?? local.object(forKey: "showWeather") as? Bool ?? false
        showGlyphRain = cloud.object(forKey: "showGlyphRain") as? Bool ?? local.object(forKey: "showGlyphRain") as? Bool ?? false
        glyphRainSizeRaw = cloud.string(forKey: "glyphRainSizeRaw") ?? local.string(forKey: "glyphRainSizeRaw") ?? GlyphRainSize.medium.rawValue
        backgroundMusic = cloud.object(forKey: "backgroundMusic") as? Bool ?? local.object(forKey: "backgroundMusic") as? Bool ?? false
        playInBackground = cloud.object(forKey: "playInBackground") as? Bool ?? local.object(forKey: "playInBackground") as? Bool ?? false
        musicStationRaw = cloud.string(forKey: "musicStationRaw") ?? local.string(forKey: "musicStationRaw") ?? MusicStationOption.none.rawValue
        colorSchemeRaw = cloud.string(forKey: "colorSchemeRaw") ?? local.string(forKey: "colorSchemeRaw") ?? ColorSchemeOption.randomRGB.rawValue
        patternInterval = cloud.object(forKey: "patternInterval") as? Double ?? local.object(forKey: "patternInterval") as? Double ?? 60.0
        leaderDeviceName = cloud.string(forKey: "leaderDeviceName") ?? ""

        // Determine if this device is the leader
        isLeader = !leaderDeviceName.isEmpty && leaderDeviceName == deviceName

        // Listen for iCloud changes from other devices
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudUpdate(notification)
            }
            .store(in: &cancellables)

        // Force initial sync
        cloud.synchronize()
    }

    private func sync(_ key: String, _ value: Any) {
        cloud.set(value, forKey: key)
        local.set(value, forKey: key)
    }

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

    private func handleCloudUpdate(_ notification: Notification) {
        guard let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }

        for key in keys {
            switch key {
            case "showBase10": showBase10 = cloud.bool(forKey: key)
            case "use24Hour": use24Hour = cloud.bool(forKey: key)
            case "showDate": showDate = cloud.bool(forKey: key)
            case "showWeather": showWeather = cloud.bool(forKey: key)
            case "showGlyphRain": showGlyphRain = cloud.bool(forKey: key)
            case "glyphRainSizeRaw": glyphRainSizeRaw = cloud.string(forKey: key) ?? GlyphRainSize.medium.rawValue
            case "backgroundMusic": backgroundMusic = cloud.bool(forKey: key)
            case "playInBackground": playInBackground = cloud.bool(forKey: key)
            case "musicStationRaw": musicStationRaw = cloud.string(forKey: key) ?? MusicStationOption.none.rawValue
            case "colorSchemeRaw": colorSchemeRaw = cloud.string(forKey: key) ?? ColorSchemeOption.randomRGB.rawValue
            case "patternInterval": patternInterval = cloud.double(forKey: key)
            case "leaderDeviceName":
                leaderDeviceName = cloud.string(forKey: key) ?? ""
                // Auto-determine leader/follower status
                isLeader = !leaderDeviceName.isEmpty && leaderDeviceName == deviceName
            default: break
            }
        }
    }
}
