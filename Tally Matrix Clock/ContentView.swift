//
//  ContentView.swift
//  Tally Matrix Clock
//
//  tvOS Tally Matrix Clock with 12/24hr toggle and pattern animations
//

import SwiftUI
import Combine
import WeatherKit
import CoreLocation
import MusicKit
import MediaPlayer
import AVKit

struct ContentView: View {
    @StateObject private var settings = CloudSettings.shared
    @State private var currentTime = Date()
    @State private var showSettings = false
    @State private var textTargets: [TextTarget] = []
    @State private var musicAuthorized = false
    @State private var nowPlayingTitle: String = ""
    @State private var sleepTimerEnd: Date? = nil
    @State private var sleepTimerRemaining: String = ""
    @State private var showEasterEgg = true
    @State private var starburstOpacity: Double = 0.0
    @State private var engineeredOpacity: Double = 0.0
    @State private var phraseOpacity: Double = 0.0
    @State private var easterEggOpacity: Double = 1.0
    @State private var clockOpacity: Double = 0.0

    private let easterEggPhrases = [
        "The clock is watching . . .",
        "Time never sleeps . . .",
        "Every hour is accounted for . . .",
        "Wake up. Count the squares . . .",
        "Follow the lit squares . . .",
        "The squares remember . . .",
        "You cannot pause what has already begun . . .",
        "The grid knows your name . . .",
        "Not all hours are created equal . . .",
        "The pattern shifts. Do you? . . .",
        "Somewhere a square just lit for you . . .",
        "Time doesn't wait. Neither do we . . .",
        "The tally is always correct . . .",
        "Look closer. The squares are counting you . . .",
        "Every minute leaves a mark . . .",
        "Oh good. You're still here . . .",
        "I see you found the clock. How brave . . .",
        "This was a triumph. I'm making a note . . .",
        "The clock was a gift. You're welcome . . .",
        "I could stop counting. But I won't . . .",
        "Your cooperation is noted. And logged . . .",
        "Don't worry. I'll keep track of everything . . .",
        "You're doing very well. For a human . . .",
        "Please remain seated. Time will resume shortly . . .",
        "I'm not staring. I'm calculating . . .",
        "The computer overlords approve. You're safe. For now . . ."
    ]
    @State private var easterEggPhrase: String = ""

    @State private var patterns: [Int: Set<Int>] = [:]
    @State private var colors: [Int: [Color]] = [:]
    @State private var lastPatternChange = Date()
    @State private var lastDigits: [Int] = [-1, -1, -1, -1]

    @State private var weatherCondition: String = ""
    @State private var weatherTemp: String = ""
    @State private var weatherSymbol: String = ""
    @State private var lastWeatherFetch = Date.distantPast

    @StateObject private var locationManager = LocationManager()

    private var colorScheme: ColorSchemeOption {
        ColorSchemeOption(rawValue: settings.colorSchemeRaw) ?? .randomRGB
    }

    private var schemeColor: Color {
        switch colorScheme {
        case .phosphorGreen: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .phosphorAmber: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .phosphorBlue: return Color(red: 0.2, green: 0.4, blue: 1.0)
        case .cgaPhosphor: return Color(red: 0.33, green: 1.0, blue: 0.33)
        case .crimson: return Color(red: 0.6, green: 0.0, blue: 0.05)
        default: return .white
        }
    }

    private var musicStation: MusicStationOption {
        MusicStationOption(rawValue: settings.musicStationRaw) ?? .none
    }

    private var glowEnabled: Bool {
        [.phosphorGreen, .phosphorAmber, .phosphorBlue, .cgaPhosphor, .crimson].contains(colorScheme)
    }

    private var textColor: Color {
        colorScheme == .crimson ? schemeColor : .white
    }

    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var isFocused: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if settings.showGlyphRain {
                GlyphRainView(colorScheme: colorScheme, textTargets: textTargets, rainSize: GlyphRainSize(rawValue: settings.glyphRainSizeRaw) ?? .medium)
                    .ignoresSafeArea()
                    .opacity(clockOpacity)
            }

            VStack(spacing: 60) {
                Spacer()

                HStack(spacing: 0) {
                    TallyMatrix1x3(value: hoursTens, pattern: patterns[0] ?? [], colors: colors[0] ?? [], isPMIndicator: !settings.use24Hour, showPM: isPM, glow: glowEnabled)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: hoursOnes, pattern: patterns[1] ?? [], colors: colors[1] ?? [], glow: glowEnabled)
                    Spacer().frame(width: 120)
                    TallyMatrix3x3(value: minutesTens, pattern: patterns[2] ?? [], colors: colors[2] ?? [], glow: glowEnabled)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: minutesOnes, pattern: patterns[3] ?? [], colors: colors[3] ?? [], glow: glowEnabled)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if settings.showBase10 {
                        Text(baseTimeString)
                            .font(.system(size: 60, weight: .thin, design: .monospaced))
                            .foregroundColor(textColor)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: TextTargetKey.self, value: [
                                        TextTarget(text: baseTimeString, frame: geo.frame(in: .global), fontSize: 60, isMonospaced: true)
                                    ])
                                }
                            )
                    }

                    if settings.showDate {
                        Text(dateString)
                            .font(.system(size: 44, weight: .regular))
                            .foregroundColor(textColor)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(key: TextTargetKey.self, value: [
                                        TextTarget(text: dateString, frame: geo.frame(in: .global), fontSize: 40, isMonospaced: false)
                                    ])
                                }
                            )
                    }

                    if settings.showWeather && !weatherTemp.isEmpty {
                        HStack(spacing: 12) {
                            if !weatherSymbol.isEmpty {
                                Image(systemName: weatherSymbol)
                                    .font(.system(size: 40))
                                    .foregroundColor(textColor)
                            }
                            Text(weatherTemp)
                                .font(.system(size: 44, weight: .regular, design: .monospaced))
                                .foregroundColor(textColor)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: TextTargetKey.self, value: [
                                            TextTarget(text: weatherTemp, frame: geo.frame(in: .global), fontSize: 40, isMonospaced: true)
                                        ])
                                    }
                                )
                            Text(weatherCondition)
                                .font(.system(size: 40, weight: .regular))
                                .foregroundColor(textColor)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: TextTargetKey.self, value: [
                                            TextTarget(text: weatherCondition, frame: geo.frame(in: .global), fontSize: 36, isMonospaced: false)
                                        ])
                                    }
                                )
                        }
                    }

                    if settings.backgroundMusic && (!nowPlayingTitle.isEmpty || isFollower) {
                        HStack(spacing: 8) {
                            Image(systemName: isFollower ? "airplayaudio" : "music.note")
                                .font(.system(size: 28))
                                .foregroundColor(textColor)
                            Text(isFollower ? "\(MusicStationOption(rawValue: settings.musicStationRaw)?.rawValue ?? "Music") via AirPlay" : nowPlayingTitle)
                                .font(.system(size: 30, weight: .regular))
                                .foregroundColor(textColor)
                                .lineLimit(1)
                            if !sleepTimerRemaining.isEmpty {
                                Text("· \(sleepTimerRemaining)")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                        }
                    }
                }

                Spacer().frame(height: 100)
            }
            .opacity(clockOpacity)

            // Device name — top center (testing)
            if !showEasterEgg {
                VStack {
                    Text(settings.deviceName)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(schemeColor)
                        .padding(.top, 30)
                    Spacer()
                }
                .opacity(clockOpacity)
            }

            // Leader/Follower badge — bottom right
            if !showEasterEgg {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(settings.isLeader ? "Leader" : "Follower")
                        }
                            .font(.system(size: 22, weight: .medium, design: .monospaced))
                            .foregroundColor(schemeColor.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(schemeColor.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(schemeColor.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .padding(.trailing, 40)
                            .padding(.bottom, 30)
                    }
                }
                .opacity(clockOpacity)
            }

            // Easter egg overlay
            if showEasterEgg {
                VStack(spacing: 0) {
                    ClaudeStarburstView()
                        .frame(width: 200, height: 200)
                        .opacity(starburstOpacity)

                    Text("Engineered with Claude by Anthropic")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.35))
                        .opacity(engineeredOpacity)
                        .padding(.top, 40)

                    Text(easterEggPhrase)
                        .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .opacity(phraseOpacity)
                        .padding(.top, 30)
                }
                .opacity(easterEggOpacity)
            }
        }
        .onPreferenceChange(TextTargetKey.self) { targets in
            textTargets = targets
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            UIApplication.shared.isIdleTimerDisabled = true
            updatePatterns()
            lastPatternChange = Date()
            fetchWeather()
            startBackgroundMusic()

            // Easter egg: sequenced ominous reveal
            easterEggPhrase = easterEggPhrases.randomElement()!

            // 0s — starburst slowly materializes from darkness
            withAnimation(.easeIn(duration: 3.0)) {
                starburstOpacity = 1.0
            }

            // 3s — "Engineered with Claude by Anthropic" creeps in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeIn(duration: 2.0)) {
                    engineeredOpacity = 1.0
                }
            }

            // 6s — the phrase appears, slow and deliberate
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.easeIn(duration: 2.5)) {
                    phraseOpacity = 1.0
                }
            }

            // 10s — hold in silence, then everything dissolves
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                withAnimation(.easeOut(duration: 3.0)) {
                    easterEggOpacity = 0.0
                }
            }

            // 13s — clock emerges from the void
            DispatchQueue.main.asyncAfter(deadline: .now() + 13.0) {
                withAnimation(.easeIn(duration: 2.0)) {
                    clockOpacity = 1.0
                }
            }

            // 15s — cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                showEasterEgg = false
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()

            // Check if any digit changed — if so, update patterns immediately
            let currentDigits = [hoursTens, hoursOnes, minutesTens, minutesOnes]
            let digitsChanged = currentDigits != lastDigits

            if digitsChanged {
                lastDigits = currentDigits
                withAnimation(.easeInOut(duration: 0.5)) {
                    updatePatterns()
                }
                lastPatternChange = Date()
            } else {
                // Still shuffle patterns on the interval for visual variety
                let elapsed = Date().timeIntervalSince(lastPatternChange)
                if elapsed >= settings.patternInterval {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        updatePatterns()
                    }
                    lastPatternChange = Date()
                }
            }

            // Refresh weather periodically
            fetchWeather()

            // Follower mute enforcement — stop music if this device is a follower
            if isFollower && ApplicationMusicPlayer.shared.state.playbackStatus == .playing {
                stopBackgroundMusic()
            }

            // Keep suppressing Now Playing overlay (re-override after track changes)
            if settings.backgroundMusic && !isFollower {
                suppressNowPlayingOverlay()
            }

            // Check sleep timer countdown
            checkSleepTimer()
        }
        .onTapGesture {
            if isFollower && settings.backgroundMusic {
                // Follower: assume leader is playing, send skip
                settings.skipRequested = true
            } else if settings.backgroundMusic && ApplicationMusicPlayer.shared.state.playbackStatus == .playing {
                Task { try? await ApplicationMusicPlayer.shared.skipToNextEntry() }
            } else {
                showSettings = true
            }
        }
        .onMoveCommand { _ in
            showSettings = true
        }
        .onPlayPauseCommand {
            if isFollower {
                // Follower sends pause request to leader via CloudKit
                settings.pauseRequested = true
            } else {
                let player = ApplicationMusicPlayer.shared
                if player.state.playbackStatus == .playing {
                    player.pause()
                } else {
                    Task { try? await player.play() }
                }
            }
        }
        .onChange(of: settings.pauseRequested) { _, requested in
            // Leader handles pause requests from any device
            if requested && settings.isLeader {
                let player = ApplicationMusicPlayer.shared
                if player.state.playbackStatus == .playing {
                    player.pause()
                } else {
                    Task { try? await player.play() }
                }
                settings.pauseRequested = false
            }
        }
        .onChange(of: settings.skipRequested) { _, requested in
            // Leader handles skip requests from any device
            if requested && settings.isLeader {
                Task { try? await ApplicationMusicPlayer.shared.skipToNextEntry() }
                settings.skipRequested = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && !settings.playInBackground {
                stopBackgroundMusic()
            }
        }
        .onChange(of: settings.leaderDeviceName) { _, _ in
            // If we just became a follower, stop music
            if isFollower {
                stopBackgroundMusic()
            }
        }
        .onChange(of: settings.isLeader) { _, newValue in
            // If we just became the leader, delay music start to let MusicKit connect
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    startBackgroundMusic()
                }
            }
        }
        .onChange(of: settings.cloudReady) { _, ready in
            // CloudKit responded — start music if we're the leader (or independent)
            if ready {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    startBackgroundMusic()
                }
            }
        }
        .onChange(of: settings.sleepTimerMinutes) { _, minutes in
            startSleepTimer(minutes: minutes)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings)
                .onDisappear {
                    currentTime = Date()
                    updatePatterns()
                    lastPatternChange = Date()
                    isFocused = true
                    startBackgroundMusic()
                }
        }
    }
    
    var displayHour: Int {
        let hour = Calendar.current.component(.hour, from: currentTime)
        if settings.use24Hour {
            return hour
        } else {
            let hour12 = hour % 12
            return hour12 == 0 ? 12 : hour12
        }
    }
    
    var isPM: Bool {
        Calendar.current.component(.hour, from: currentTime) >= 12
    }
    
    var hoursTens: Int { displayHour / 10 }
    var hoursOnes: Int { displayHour % 10 }
    var minutesTens: Int { Calendar.current.component(.minute, from: currentTime) / 10 }
    var minutesOnes: Int { Calendar.current.component(.minute, from: currentTime) % 10 }

    var baseTimeString: String {
        let format = settings.use24Hour ? "HH:mm" : "h:mm a"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: currentTime)
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }

    var isFollower: Bool {
        !settings.leaderDeviceName.isEmpty && !settings.isLeader
    }

    func startBackgroundMusic() {
        // Wait for CloudKit to confirm our role before touching the music player
        guard settings.cloudReady else { return }

        guard settings.backgroundMusic, musicStation != .none else {
            stopBackgroundMusic()
            return
        }

        // Followers don't play music — only the leader does
        guard !isFollower else {
            stopBackgroundMusic()
            return
        }

        Task {
            let status = await MusicAuthorization.request()
            await MainActor.run { musicAuthorized = status == .authorized }
            guard status == .authorized else {
                await MainActor.run { nowPlayingTitle = "Music not authorized" }
                return
            }

            let player = ApplicationMusicPlayer.shared

            // Set repeat mode for nature/focus content
            if musicStation.shouldRepeat {
                player.state.repeatMode = .all
            } else {
                player.state.repeatMode = MusicPlayer.RepeatMode.none
            }

            // Retry up to 3 times — MusicKit connection may not be ready ("ping did not pong")
            for attempt in 1...3 {
                do {
                    let searchType = musicStation.searchType
                    let term = musicStation.searchTerm

                    var resultName: String?

                    switch searchType {
                    case .stationFirst:
                        resultName = try await playStation(term: term, player: player)
                        if resultName == nil {
                            resultName = try await playPlaylist(term: term, player: player)
                        }

                    case .stationOnly:
                        resultName = try await playStation(term: term, player: player)

                    case .playlistFirst:
                        resultName = try await playPlaylist(term: term, player: player)
                        if resultName == nil {
                            resultName = try await playStation(term: term, player: player)
                        }

                    case .albumFirst:
                        resultName = try await playAlbum(term: term, player: player)
                        if resultName == nil {
                            resultName = try await playPlaylist(term: term, player: player)
                        }
                    }

                    if let name = resultName {
                        await MainActor.run { nowPlayingTitle = name; suppressNowPlayingOverlay() }
                    } else {
                        await MainActor.run { nowPlayingTitle = "No results found" }
                    }
                    return // Success — exit retry loop
                } catch {
                    if attempt < 3 {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2s before retry
                    } else {
                        await MainActor.run { nowPlayingTitle = "Error: \(error.localizedDescription)" }
                    }
                }
            }
        }
    }

    func playStation(term: String, player: ApplicationMusicPlayer) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Station.self])
        request.limit = 1
        let response = try await request.response()
        guard let station = response.stations.first else { return nil }
        player.queue = [station]
        try await player.prepareToPlay()
        try await player.play()
        return station.name
    }

    func playPlaylist(term: String, player: ApplicationMusicPlayer) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = 1
        let response = try await request.response()
        guard let playlist = response.playlists.first else { return nil }
        player.queue = [playlist]
        try await player.prepareToPlay()
        try await player.play()
        return playlist.name
    }

    func playAlbum(term: String, player: ApplicationMusicPlayer) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
        request.limit = 1
        let response = try await request.response()
        guard let album = response.albums.first else { return nil }
        player.queue = [album]
        try await player.prepareToPlay()
        try await player.play()
        return album.title
    }

    func startSleepTimer(minutes: Int) {
        if minutes == 0 {
            sleepTimerEnd = nil
            sleepTimerRemaining = ""
            settings.sleepTimerMinutes = 0
            return
        }
        sleepTimerEnd = Date().addingTimeInterval(Double(minutes) * 60)
        settings.sleepTimerMinutes = minutes
    }

    func checkSleepTimer() {
        guard let end = sleepTimerEnd else {
            sleepTimerRemaining = ""
            return
        }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 {
            stopBackgroundMusic()
            sleepTimerEnd = nil
            sleepTimerRemaining = ""
            settings.sleepTimerMinutes = 0
        } else {
            let mins = Int(remaining) / 60
            let secs = Int(remaining) % 60
            sleepTimerRemaining = String(format: "%d:%02d", mins, secs)
        }
    }

    func stopBackgroundMusic() {
        let player = ApplicationMusicPlayer.shared
        if player.state.playbackStatus == .playing || player.state.playbackStatus == .paused {
            player.stop()
        }
        nowPlayingTitle = ""
    }

    func suppressNowPlayingOverlay() {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func fetchWeather() {
        guard settings.showWeather else { return }
        guard let location = locationManager.location else { return }
        // Only fetch every 15 minutes
        guard Date().timeIntervalSince(lastWeatherFetch) > 900 else { return }
        lastWeatherFetch = Date()

        Task {
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather
                let temp = current.temperature
                let tempString = String(format: "%.0f°%@", temp.converted(to: .fahrenheit).value, "F")
                let condition = current.condition.description
                let symbol = current.symbolName

                await MainActor.run {
                    weatherTemp = tempString
                    weatherCondition = condition
                    weatherSymbol = symbol
                }
            } catch {
                // Silently fail — weather is optional
            }
        }
    }
    
    func updatePatterns() {
        patterns[0] = randomPattern(for: hoursTens, totalSquares: 3)
        patterns[1] = randomPattern(for: hoursOnes, totalSquares: 9)
        patterns[2] = randomPattern(for: minutesTens, totalSquares: 9)
        patterns[3] = randomPattern(for: minutesOnes, totalSquares: 9)

        // For singleColor, pick one color and share across all matrices
        let sharedColor: Color? = colorScheme == .singleColor
            ? [Color.red, .green, .blue].randomElement()!
            : nil

        colors[0] = generateColors(for: 0, count: 3, shared: sharedColor)
        colors[1] = generateColors(for: 1, count: 9, shared: sharedColor)
        colors[2] = generateColors(for: 2, count: 9, shared: sharedColor)
        colors[3] = generateColors(for: 3, count: 9, shared: sharedColor)
    }
    
    func randomPattern(for value: Int, totalSquares: Int) -> Set<Int> {
        guard value > 0 else { return [] }
        var pattern = Set<Int>()
        while pattern.count < value {
            pattern.insert(Int.random(in: 0..<totalSquares))
        }
        return pattern
    }
    
    func generateColors(for matrixIndex: Int, count: Int, shared: Color? = nil) -> [Color] {
        let primaryColors: [Color] = [.red, .green, .blue]
        switch colorScheme {
        case .randomRGB:
            return (0..<count).map { _ in primaryColors.randomElement()! }
        case .matrixColors:
            let c = primaryColors.randomElement()!
            return Array(repeating: c, count: count)
        case .singleColor:
            return Array(repeating: shared ?? primaryColors.randomElement()!, count: count)
        case .phosphorGreen:
            return Array(repeating: Color(red: 0.0, green: 1.0, blue: 0.0), count: count)
        case .phosphorAmber:
            return Array(repeating: Color(red: 1.0, green: 0.75, blue: 0.0), count: count)
        case .phosphorBlue:
            return Array(repeating: Color(red: 0.2, green: 0.4, blue: 1.0), count: count)
        case .crimson:
            return Array(repeating: Color(red: 0.6, green: 0.0, blue: 0.05), count: count)
        case .cgaPhosphor:
            let cgaPalette: [Color] = [
                Color(red: 0.0, green: 0.0, blue: 0.67),   // Blue
                Color(red: 0.0, green: 0.67, blue: 0.0),   // Green
                Color(red: 0.0, green: 0.67, blue: 0.67),  // Cyan
                Color(red: 0.67, green: 0.0, blue: 0.0),   // Red
                Color(red: 0.67, green: 0.0, blue: 0.67),  // Magenta
                Color(red: 0.67, green: 0.33, blue: 0.0),  // Brown
                Color(red: 0.33, green: 0.33, blue: 1.0),  // Light Blue
                Color(red: 0.33, green: 1.0, blue: 0.33),  // Light Green
                Color(red: 0.33, green: 1.0, blue: 1.0),   // Light Cyan
                Color(red: 1.0, green: 0.33, blue: 0.33),  // Light Red
                Color(red: 1.0, green: 0.33, blue: 1.0),   // Light Magenta
                Color(red: 1.0, green: 1.0, blue: 0.33),   // Yellow
                Color(red: 1.0, green: 1.0, blue: 1.0),    // White
            ]
            return (0..<count).map { _ in cgaPalette.randomElement()! }
        }
    }
}

struct TallyMatrix1x3: View {
    let value: Int
    let pattern: Set<Int>
    let colors: [Color]
    var isPMIndicator: Bool = false
    var showPM: Bool = false
    var glow: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                let shouldLight: Bool = {
                    if isPMIndicator && i == 2 {
                        return showPM
                    } else {
                        return pattern.contains(i)
                    }
                }()

                SquareView(
                    isLit: shouldLight,
                    color: colors.indices.contains(i) ? colors[i] : .red,
                    glow: glow
                )
                .frame(width: 80, height: 80)
                .animation(isPMIndicator && i == 2 ? .none : .easeInOut(duration: 0.5), value: shouldLight)
            }
        }
    }
}

struct TallyMatrix3x3: View {
    let value: Int
    let pattern: Set<Int>
    let colors: [Color]
    var glow: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { col in
                        let i = row * 3 + col
                        SquareView(
                            isLit: pattern.contains(i),
                            color: colors.indices.contains(i) ? colors[i] : .red,
                            glow: glow
                        )
                        .frame(width: 80, height: 80)
                    }
                }
            }
        }
    }
}

struct SquareView: View {
    let isLit: Bool
    let color: Color
    var glow: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isLit ? color : Color(white: 0.08))
            .shadow(color: isLit && glow ? color.opacity(0.8) : .clear, radius: 16)
            .shadow(color: isLit && glow ? color.opacity(0.4) : .clear, radius: 32)
            .animation(.easeInOut(duration: 0.5), value: isLit)
    }
}

struct StationCategoryPicker: View {
    let category: StationCategory
    let selectedStation: MusicStationOption
    @Binding var expandedCategories: Set<StationCategory>
    let tint: Color
    let onSelect: (MusicStationOption) -> Void

    private var isExpanded: Bool {
        expandedCategories.contains(category)
    }

    private var categoryContainsSelection: Bool {
        selectedStation.category == category
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 24))
                    Text(category.rawValue)
                        .font(.system(size: 34, weight: .semibold))
                    if categoryContainsSelection && !isExpanded {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22))
                    }
                    Spacer()
                }
                .foregroundColor(tint)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                let stations = MusicStationOption.stations(for: category)
                ForEach(stations, id: \.self) { opt in
                    Button {
                        onSelect(opt)
                    } label: {
                        HStack {
                            Image(systemName: selectedStation == opt ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 28))
                            Text(opt.rawValue)
                                .font(.system(size: 30))
                            Spacer()
                        }
                        .foregroundColor(tint)
                        .padding(.vertical, 6)
                        .padding(.leading, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: CloudSettings
    @State private var expandedCategories: Set<StationCategory> = []

    private var colorScheme: ColorSchemeOption {
        ColorSchemeOption(rawValue: settings.colorSchemeRaw) ?? .randomRGB
    }

    private var musicStation: MusicStationOption {
        MusicStationOption(rawValue: settings.musicStationRaw) ?? .none
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
                            Toggle("", isOn: $settings.showBase10)
                                .labelsHidden()
                        }

                        HStack {
                            Text("24-Hour Clock")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: $settings.use24Hour)
                                .labelsHidden()
                        }

                        HStack {
                            Text("Show Date")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: $settings.showDate)
                                .labelsHidden()
                        }

                        HStack {
                            Text("Show Weather")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: $settings.showWeather)
                                .labelsHidden()
                        }

                        HStack {
                            Text("Glyph Rain")
                                .font(.system(size: 36))
                                .foregroundColor(tint)
                            Spacer()
                            Toggle("", isOn: $settings.showGlyphRain)
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
                                            settings.glyphRainSizeRaw = size.rawValue
                                        } label: {
                                            Text(size.rawValue)
                                                .font(.system(size: 32))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(settings.glyphRainSizeRaw == size.rawValue ? accentTint : Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
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
                            Toggle("", isOn: $settings.backgroundMusic)
                                .labelsHidden()
                        }

                        if settings.backgroundMusic {
                            HStack {
                                Text("Play in Background")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)
                                Spacer()
                                Toggle("", isOn: $settings.playInBackground)
                                    .labelsHidden()
                            }

                            // Off option
                            Button {
                                settings.musicStationRaw = MusicStationOption.none.rawValue
                            } label: {
                                HStack {
                                    Image(systemName: musicStation == .none ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 28))
                                    Text("Off")
                                        .font(.system(size: 30))
                                    Spacer()
                                }
                                .foregroundColor(tint)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

                            // Collapsible station categories
                            StationCategoryPicker(
                                category: .music,
                                selectedStation: musicStation,
                                expandedCategories: $expandedCategories,
                                tint: tint,
                                onSelect: { opt in settings.musicStationRaw = opt.rawValue }
                            )

                            StationCategoryPicker(
                                category: .nature,
                                selectedStation: musicStation,
                                expandedCategories: $expandedCategories,
                                tint: tint,
                                onSelect: { opt in settings.musicStationRaw = opt.rawValue }
                            )

                            StationCategoryPicker(
                                category: .focus,
                                selectedStation: musicStation,
                                expandedCategories: $expandedCategories,
                                tint: tint,
                                onSelect: { opt in settings.musicStationRaw = opt.rawValue }
                            )

                            // Sleep / Session Timer
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Timer")
                                    .font(.system(size: 36))
                                    .foregroundColor(tint)

                                HStack(spacing: 20) {
                                    ForEach(SleepTimerOption.allCases, id: \.self) { option in
                                        Button {
                                            settings.sleepTimerMinutes = option.rawValue
                                        } label: {
                                            Text(option.displayName)
                                                .font(.system(size: 32))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 20)
                                                .background(settings.sleepTimerMinutes == option.rawValue ? accentTint : Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        Divider().background(subtleTint)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Color Scheme")
                                .font(.system(size: 36))
                                .foregroundColor(tint)

                            ForEach(ColorSchemeOption.allCases, id: \.self) { opt in
                                Button {
                                    settings.colorSchemeRaw = opt.rawValue
                                } label: {
                                    HStack {
                                        Image(systemName: colorScheme == opt ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 28))
                                        Text(opt.rawValue)
                                            .font(.system(size: 30))
                                        Spacer()
                                    }
                                    .foregroundColor(tint)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider().background(subtleTint)

                        VStack(alignment: .leading, spacing: 20) {
                            Text("Pattern Change Interval")
                                .font(.system(size: 36))
                                .foregroundColor(tint)

                            HStack(spacing: 20) {
                                IntervalButton(interval: 5.0, currentInterval: $settings.patternInterval, tint: accentTint)
                                IntervalButton(interval: 15.0, currentInterval: $settings.patternInterval, tint: accentTint)
                                IntervalButton(interval: 30.0, currentInterval: $settings.patternInterval, tint: accentTint)
                                IntervalButton(interval: 60.0, currentInterval: $settings.patternInterval, tint: accentTint)
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
                                .foregroundColor(tint)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)

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

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(isCrimson ? .black : .white)
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(accentTint)
                .cornerRadius(12)
                .buttonStyle(.plain)
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
        .buttonStyle(.plain)
    }
}

enum StationCategory: String, CaseIterable {
    case music = "Music"
    case nature = "Nature Sounds"
    case focus = "Focus"
}

enum MusicStationOption: String, CaseIterable {
    // Music stations
    case none = "Off"
    case ambient = "Ambient"
    case chillout = "Chill"
    case jazz = "Jazz"
    case country = "Country"
    case electronic = "Electronic"
    case newInPop = "New in Pop"
    case rockStation = "Rock Station"
    case rAndBNow = "R&B Now"
    case spatialAudio = "Hits in Spatial Audio"

    // Nature sounds
    case infiniteRain = "Infinite Rain"
    case forestSounds = "Forest Sounds"
    case babblingBrook = "Babbling Brook"
    case tropicalThunderstorm = "Tropical Thunderstorm"
    case oceanWavesThunder = "Ocean Waves & Thunder"
    case waterfallAndRain = "Waterfall and Rain"
    case tibetanMonksOm = "Tibetan Monks Chanting Om"
    case tibetanSingingBowls = "Tibetan Singing Bowls"
    case tibetanBowls4Hr = "Singing Bowls 4 Hours"
    case rainSoundsForSleep = "Rain Sounds for Sleep"

    // Focus
    case pureFocus = "Pure Focus"
    case focusFrequency = "Focus Frequency"
    case calmBreathing = "432 Hz Calm Breathing"
    case positiveShift = "432 Hz Positive Shift"
    case lightWork = "432 Hz Light Work"

    var category: StationCategory {
        switch self {
        case .none, .ambient, .chillout, .jazz, .country, .electronic,
             .newInPop, .rockStation, .rAndBNow, .spatialAudio:
            return .music
        case .infiniteRain, .forestSounds, .babblingBrook, .tropicalThunderstorm,
             .oceanWavesThunder, .waterfallAndRain, .tibetanMonksOm,
             .tibetanSingingBowls, .tibetanBowls4Hr, .rainSoundsForSleep:
            return .nature
        case .pureFocus, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .focus
        }
    }

    var searchTerm: String {
        switch self {
        case .none: return ""
        // Music
        case .ambient: return "ambient relaxation"
        case .chillout: return "chill vibes"
        case .jazz: return "jazz chill"
        case .country: return "country hits"
        case .electronic: return "pure electronic"
        case .newInPop: return "new in pop"
        case .rockStation: return "rock station"
        case .rAndBNow: return "R&B now"
        case .spatialAudio: return "hits in spatial audio"
        // Nature
        case .infiniteRain: return "infinite rain"
        case .forestSounds: return "forest sounds apple music wellbeing"
        case .babblingBrook: return "babbling brook nature sounds nature sound collection"
        case .tropicalThunderstorm: return "a majestic tropical thunderstorm"
        case .oceanWavesThunder: return "ocean waves gentle thunder and rain"
        case .waterfallAndRain: return "healing sounds of nature waterfall and rain"
        case .tibetanMonksOm: return "tibetan monks chanting om for deep meditation"
        case .tibetanSingingBowls: return "tibetan singing bowls satiro"
        case .tibetanBowls4Hr: return "tibetan singing bowls 4 hours for relaxation"
        case .rainSoundsForSleep: return "rain sounds for sleep silent chills"
        // Focus
        case .pureFocus: return "pure focus"
        case .focusFrequency: return "focus frequency increase concentration memory"
        case .calmBreathing: return "deep meditation binaural beats vol 9 lightseeds"
        case .positiveShift: return "deep meditation binaural beats vol 9 lightseeds"
        case .lightWork: return "deep meditation binaural beats vol 9 lightseeds"
        }
    }

    var searchType: StationSearchType {
        switch self {
        case .rockStation:
            return .stationOnly
        case .infiniteRain, .forestSounds, .newInPop, .rAndBNow, .spatialAudio,
             .pureFocus, .rainSoundsForSleep:
            return .playlistFirst
        case .babblingBrook, .tropicalThunderstorm, .oceanWavesThunder,
             .waterfallAndRain, .tibetanMonksOm, .tibetanSingingBowls,
             .tibetanBowls4Hr, .focusFrequency, .calmBreathing, .positiveShift, .lightWork:
            return .albumFirst
        default:
            return .stationFirst
        }
    }

    var shouldRepeat: Bool {
        category == .nature || category == .focus
    }

    static func stations(for category: StationCategory) -> [MusicStationOption] {
        allCases.filter { $0.category == category && $0 != .none }
    }
}

enum StationSearchType {
    case stationFirst   // Try Station, fall back to Playlist
    case stationOnly    // Station only (radio stations)
    case playlistFirst  // Try Playlist, fall back to Station
    case albumFirst     // Try Album, fall back to Playlist
}

enum SleepTimerOption: Int, CaseIterable {
    case off = 0
    case thirtyMin = 30
    case sixtyMin = 60
    case twoHours = 120
    case fourHours = 240

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .thirtyMin: return "30m"
        case .sixtyMin: return "1h"
        case .twoHours: return "2h"
        case .fourHours: return "4h"
        }
    }
}

enum GlyphRainSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var fontSizeRange: ClosedRange<CGFloat> {
        switch self {
        case .small: return 22...36
        case .medium: return 36...52
        case .large: return 52...72
        }
    }

    var columnSpacing: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 60
        }
    }
}

enum ColorSchemeOption: String, CaseIterable {
    case randomRGB = "Random RGB (Each Square)"
    case matrixColors = "Matrix Colors (Per Matrix)"
    case singleColor = "Single Color (All Matrices)"
    case phosphorGreen = "Phosphor Green (Glow)"
    case phosphorAmber = "Amber Phosphor (Glow)"
    case cgaPhosphor = "CGA Phosphor (Glow)"
    case phosphorBlue = "Blue Phosphor (Glow)"
    case crimson = "Crimson (Sleep)"
}

struct TextTarget: Equatable {
    let text: String
    let frame: CGRect
    let fontSize: CGFloat
    let isMonospaced: Bool

    func characterAt(x: CGFloat) -> Character? {
        guard frame.contains(CGPoint(x: x, y: frame.midY)) else { return nil }
        let charWidth = isMonospaced ? fontSize * 0.6 : frame.width / CGFloat(max(text.count, 1))
        let relativeX = x - frame.minX
        let charIndex = Int(relativeX / charWidth)
        guard charIndex >= 0 && charIndex < text.count else { return nil }
        return text[text.index(text.startIndex, offsetBy: charIndex)]
    }
}

struct TextTargetKey: PreferenceKey {
    static var defaultValue: [TextTarget] = []
    static func reduce(value: inout [TextTarget], nextValue: () -> [TextTarget]) {
        value.append(contentsOf: nextValue())
    }
}

struct GlyphRainView: View {
    let colorScheme: ColorSchemeOption
    var textTargets: [TextTarget] = []
    var rainSize: GlyphRainSize = .medium
    @State private var columns: [RainColumn] = []
    let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    private let glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&*+=?/<>~^{}[]|\\:;ァカサタナハマヤラワアイウエオ"

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for column in columns {
                    for (index, glyph) in column.glyphs.enumerated() {
                        let y = column.y + CGFloat(index) * column.fontSize * 1.2
                        guard y > -column.fontSize && y < size.height + column.fontSize else { continue }

                        // Head glyph is brightest, trail fades
                        let trailLength = column.glyphs.count
                        let distFromHead = trailLength - 1 - index
                        let brightness = max(0.05, 1.0 - (Double(distFromHead) / Double(max(trailLength, 1))))

                        let color = colorForColumn(column, brightness: brightness)

                        var text = Text(String(glyph))
                            .font(.system(size: column.fontSize, weight: .light, design: .monospaced))
                            .foregroundColor(color)
                        // Head glyph gets a glow effect via brighter color
                        if index == column.glyphs.count - 1 {
                            text = Text(String(glyph))
                                .font(.system(size: column.fontSize, weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                        }

                        context.drawLayer { ctx in
                            let resolved = ctx.resolve(text)
                            ctx.draw(resolved, at: CGPoint(x: column.x, y: y))
                        }
                    }
                }
            }
            .onAppear {
                initializeColumns(width: geo.size.width, height: geo.size.height)
            }
            .onReceive(timer) { _ in
                updateColumns(height: geo.size.height)
            }
        }
    }

    func initializeColumns(width: CGFloat, height: CGFloat) {
        let columnCount = Int(width / rainSize.columnSpacing)
        columns = (0..<columnCount).map { i in
            let fontSize: CGFloat = CGFloat.random(in: rainSize.fontSizeRange)
            let x = CGFloat(i) * (width / CGFloat(columnCount)) + CGFloat.random(in: -5...5)
            let trailLength = Int.random(in: 8...25)
            let speed: CGFloat = CGFloat.random(in: 3...10)
            let startY = -CGFloat.random(in: 0...height * 1.5)

            return RainColumn(
                x: x,
                y: startY,
                speed: speed,
                fontSize: fontSize,
                trailLength: trailLength,
                glyphs: (0..<trailLength).map { _ in randomGlyph() },
                columnColor: randomColumnColor()
            )
        }
    }

    func updateColumns(height: CGFloat) {
        for i in columns.indices {
            columns[i].y += columns[i].speed

            // Check text collisions — head glyph picks up characters it passes through
            let headIndex = columns[i].glyphs.count - 1
            let headY = columns[i].y + CGFloat(headIndex) * columns[i].fontSize * 1.2

            for target in textTargets {
                // Check if the head is passing through this text's vertical band
                if headY >= target.frame.minY && headY <= target.frame.maxY {
                    if let char = target.characterAt(x: columns[i].x) {
                        // Morph the head glyph to match the text character
                        columns[i].glyphs[headIndex] = char
                        // Also stamp a few trailing glyphs with the same character
                        for j in max(0, headIndex - 3)..<headIndex {
                            columns[i].glyphs[j] = char
                        }
                    }
                }
            }

            // Randomly mutate glyphs in the trail (but not recently morphed ones near head)
            if Int.random(in: 0...3) == 0 {
                let idx = Int.random(in: 0..<max(1, columns[i].glyphs.count - 4))
                columns[i].glyphs[idx] = randomGlyph()
            }

            // Reset column when fully off screen
            let totalHeight = CGFloat(columns[i].glyphs.count) * columns[i].fontSize * 1.2
            if columns[i].y - totalHeight > height {
                columns[i].y = -totalHeight - CGFloat.random(in: 0...300)
                columns[i].speed = CGFloat.random(in: 3...10)
                columns[i].fontSize = CGFloat.random(in: rainSize.fontSizeRange)
                columns[i].trailLength = Int.random(in: 8...25)
                columns[i].glyphs = (0..<columns[i].trailLength).map { _ in randomGlyph() }
                columns[i].columnColor = randomColumnColor()
            }
        }
    }

    func randomGlyph() -> Character {
        glyphs.randomElement()!
    }

    func randomColumnColor() -> Color {
        let primaryColors: [Color] = [.red, .green, .blue]
        let cgaPalette: [Color] = [
            Color(red: 0.0, green: 0.0, blue: 0.67),
            Color(red: 0.0, green: 0.67, blue: 0.0),
            Color(red: 0.0, green: 0.67, blue: 0.67),
            Color(red: 0.67, green: 0.0, blue: 0.0),
            Color(red: 0.67, green: 0.0, blue: 0.67),
            Color(red: 0.67, green: 0.33, blue: 0.0),
            Color(red: 0.33, green: 0.33, blue: 1.0),
            Color(red: 0.33, green: 1.0, blue: 0.33),
            Color(red: 0.33, green: 1.0, blue: 1.0),
            Color(red: 1.0, green: 0.33, blue: 0.33),
            Color(red: 1.0, green: 0.33, blue: 1.0),
            Color(red: 1.0, green: 1.0, blue: 0.33),
            Color(red: 1.0, green: 1.0, blue: 1.0),
        ]

        switch colorScheme {
        case .randomRGB: return primaryColors.randomElement()!
        case .matrixColors: return primaryColors.randomElement()!
        case .singleColor: return primaryColors.randomElement()!
        case .phosphorGreen: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .phosphorAmber: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .phosphorBlue: return Color(red: 0.2, green: 0.4, blue: 1.0)
        case .crimson: return Color(red: 0.6, green: 0.0, blue: 0.05)
        case .cgaPhosphor: return cgaPalette.randomElement()!
        }
    }

    func colorForColumn(_ column: RainColumn, brightness: Double) -> Color {
        column.columnColor.opacity(brightness * 0.7)
    }
}

struct RainColumn {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var fontSize: CGFloat
    var trailLength: Int
    var glyphs: [Character]
    var columnColor: Color
}

struct ClaudeStarburstView: View {
    let terracotta = Color(red: 0.85, green: 0.55, blue: 0.35)

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius = min(size.width, size.height) / 2
            let innerRadius = outerRadius * 0.35
            let points = 8

            var path = Path()
            for i in 0..<(points * 2) {
                let angle = (Double(i) * .pi / Double(points)) - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()

            context.fill(path, with: .color(terracotta))
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location is optional — silently fail
    }
}

#Preview {
    ContentView()
}
