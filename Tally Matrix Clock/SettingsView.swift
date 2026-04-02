//
//  SettingsView.swift
//  Tally Matrix Clock
//

import SwiftUI
import MusicKit
import AVKit
import CryoKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: CloudSettings
    @Bindable var playerManager: MusicPlaybackManager

    private var colorScheme: ColorSchemeOption {
        ColorSchemeOption(rawValue: settings.colorSchemeRaw) ?? .randomRGB
    }

    private var musicStation: MusicStationOption {
        MusicStationOption(rawValue: settings.musicStationRaw) ?? .none
    }

    private var isFollower: Bool {
        !settings.leaderDeviceName.isEmpty && !settings.isLeader
    }

    /// Creates a binding that routes through requestSettingChange for followers
    private func followerBinding(for keyPath: ReferenceWritableKeyPath<CloudSettings, Bool>, key: String) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                if isFollower {
                    settings.requestSettingChange(key: key, value: newValue)
                } else {
                    settings[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func followerDoubleBinding(for keyPath: ReferenceWritableKeyPath<CloudSettings, Double>, key: String) -> Binding<Double> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                if isFollower {
                    settings.requestSettingChange(key: key, value: newValue)
                } else {
                    settings[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private var isCrimson: Bool {
        colorScheme == .crimson
    }

    private var tint: Color {
        isCrimson ? Color(red: 0.6, green: 0.0, blue: 0.05) : .white
    }

    private var accentTint: Color {
        isCrimson ? Color(red: 0.6, green: 0.0, blue: 0.05) : .blue
    }

    private var subtleTint: Color {
        isCrimson ? Color(red: 0.6, green: 0.0, blue: 0.05).opacity(0.3) : Color.white.opacity(0.3)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Settings")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(tint)
                    .padding(.top, 40)

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HStack {
                            Text("Show Base-10 Time")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.showBase10, key: "showBase10"))
                                .labelsHidden()
                        }

                        HStack {
                            Text("24-Hour Clock")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.use24Hour, key: "use24Hour"))
                                .labelsHidden()
                        }

                        HStack {
                            Text("Show Date")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.showDate, key: "showDate"))
                                .labelsHidden()
                        }

                        HStack {
                            Text("Show Weather")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.showWeather, key: "showWeather"))
                                .labelsHidden()
                        }

                        HStack {
                            Text("Glyph Rain")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.showGlyphRain, key: "showGlyphRain"))
                                .labelsHidden()
                        }

                        if settings.showGlyphRain {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Rain Size")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)

                                HStack(spacing: 20) {
                                    ForEach(GlyphRainSize.allCases, id: \.self) { size in
                                        Button {
                                            if isFollower {
                                                settings.requestSettingChange(key: "glyphRainSizeRaw", value: size.rawValue)
                                            } else {
                                                settings.glyphRainSizeRaw = size.rawValue
                                            }
                                        } label: {
                                            Text(size.rawValue)
                                                .font(.system(size: 32))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(settings.glyphRainSizeRaw == size.rawValue ? accentTint : Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(SettingsFocusButtonStyle())
                                    }
                                }
                            }
                        }

                        Divider().background(subtleTint)

                        HStack {
                            Text("Background Music")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: followerBinding(for: \.backgroundMusic, key: "backgroundMusic"))
                                .labelsHidden()
                        }

                        if settings.backgroundMusic {
                            // Shuffle / Repeat
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Playback")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)

                                HStack(spacing: 20) {
                                    Button {
                                        playerManager.isShuffleEnabled.toggle()
                                    } label: {
                                        HStack {
                                            Image(systemName: "shuffle")
                                                .font(.system(size: 28))
                                            Text("Shuffle")
                                                .font(.system(size: 30))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(playerManager.isShuffleEnabled ? accentTint : Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(SettingsFocusButtonStyle())

                                    Button {
                                        playerManager.cycleRepeatMode()
                                    } label: {
                                        HStack {
                                            Image(systemName: playerManager.repeatMode == .one ? "repeat.1" : "repeat")
                                                .font(.system(size: 28))
                                            Text(playerManager.repeatMode.displayName)
                                                .font(.system(size: 30))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(playerManager.repeatMode != .none ? accentTint : Color.gray.opacity(0.3))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(SettingsFocusButtonStyle())
                                }
                            }

                            // Sleep / Session Timer
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Timer")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)

                                HStack(spacing: 20) {
                                    ForEach(SleepTimerOption.allCases, id: \.self) { option in
                                        Button {
                                            if isFollower {
                                                settings.requestSettingChange(key: "sleepTimerMinutes", value: option.rawValue)
                                            } else {
                                                settings.sleepTimerMinutes = option.rawValue
                                            }
                                        } label: {
                                            Text(option.displayName)
                                                .font(.system(size: 32))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(settings.sleepTimerMinutes == option.rawValue ? accentTint : Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(SettingsFocusButtonStyle())
                                    }
                                }
                            }

                            HStack {
                                Text("Play in Background")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)
                                Spacer()
                                Toggle("", isOn: followerBinding(for: \.playInBackground, key: "playInBackground"))
                                    .labelsHidden()
                            }

                            // Off option
                            Button {
                                if isFollower {
                                    settings.requestedStation = MusicStationOption.none.rawValue
                                } else {
                                    settings.musicStationRaw = MusicStationOption.none.rawValue
                                }
                            } label: {
                                HStack {
                                    Image(systemName: musicStation == .none ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 28))
                                    Text("Off")
                                        .font(.system(size: 30))
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(SettingsFocusButtonStyle())

                            // CryoKit station picker — scaled up for tvOS
                            CryoStationPicker(
                                player: playerManager,
                                tint: tint,
                                accent: accentTint,
                                border: tint.opacity(0.3)
                            )
                            .scaleEffect(1.8, anchor: .topLeading)
                            .frame(height: nil)
                        }

                        Divider().background(subtleTint)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Color Scheme")
                                .font(.system(size: 36))
                                .foregroundColor(tint)

                            ForEach(ColorSchemeOption.allCases, id: \.self) { opt in
                                Button {
                                    if isFollower {
                                        settings.requestSettingChange(key: "colorSchemeRaw", value: opt.rawValue)
                                    } else {
                                        settings.colorSchemeRaw = opt.rawValue
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: colorScheme == opt ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 28))
                                        Text(opt.rawValue)
                                            .font(.system(size: 30))
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(SettingsFocusButtonStyle())
                            }
                        }

                        Divider().background(subtleTint)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Pattern Change Interval")
                                .font(.system(size: 36))
                                .foregroundColor(tint)

                            HStack(spacing: 20) {
                                IntervalButton(interval: 5.0, currentInterval: followerDoubleBinding(for: \.patternInterval, key: "patternInterval"), tint: accentTint)
                                IntervalButton(interval: 15.0, currentInterval: followerDoubleBinding(for: \.patternInterval, key: "patternInterval"), tint: accentTint)
                                IntervalButton(interval: 30.0, currentInterval: followerDoubleBinding(for: \.patternInterval, key: "patternInterval"), tint: accentTint)
                                IntervalButton(interval: 60.0, currentInterval: followerDoubleBinding(for: \.patternInterval, key: "patternInterval"), tint: accentTint)
                            }
                        }

                        Divider().background(subtleTint)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Multi-TV Sync")
                                .font(.system(size: 36))
                                .foregroundColor(tint)

                            Button {
                                if settings.isLeader {
                                    settings.resignLeader()
                                } else {
                                    settings.setAsLeader()
                                }
                            } label: {
                                HStack {
                                    Text("Set as Leader")
                                        .font(.system(size: 36))
                                    Spacer()
                                    Text(settings.isLeader ? "On" : "Off")
                                        .font(.system(size: 30))
                                        .foregroundColor(settings.isLeader ? (isCrimson ? tint : .green) : .gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(SettingsFocusButtonStyle())

                            Text(settings.isLeader ? "This TV controls settings for all TVs" : settings.leaderDeviceName.isEmpty ? "No leader set — all TVs independent" : "Following: \(settings.leaderDeviceName)")
                                .font(.system(size: 28))
                                .foregroundColor(tint.opacity(0.6))

                            if settings.isLeader {
                                Divider().background(subtleTint)

                                Text("AirPlay Speakers")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)

                                Text("Select other TVs to stream audio from this leader")
                                    .font(.system(size: 28))
                                    .foregroundColor(tint.opacity(0.6))

                                AirPlayPickerView()
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 30)
                }

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(isCrimson ? .black : .white)
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(accentTint)
                .cornerRadius(12)
                .buttonStyle(SettingsFocusButtonStyle())
                .padding(.bottom, 40)
            }
        }
    }
}

struct AirPlayPickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .systemBlue
        picker.tintColor = .white
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

struct IntervalButton: View {
    let interval: Double
    @Binding var currentInterval: Double
    var tint: Color = .blue

    var body: some View {
        Button {
            currentInterval = interval
        } label: {
            Text("\(Int(interval))s")
                .font(.system(size: 32))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(currentInterval == interval ? tint : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .buttonStyle(SettingsFocusButtonStyle())
    }
}
