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
import CryoKit

struct ContentView: View {
    @StateObject private var settings = CloudSettings.shared
    @State private var playerManager = MusicPlaybackManager()
    @State private var currentTime = Date()
    @State private var showSettings = false
    @State private var textTargets: [TextTarget] = []
    @State private var musicAuthorized = false
    @State private var nowPlayingTitle: String = ""
    @State private var sleepTimerEnd: Date? = nil
    @State private var sleepTimerRemaining: String = ""
    @State private var currentSongTitle: String = ""
    @State private var currentArtistName: String = ""
    @State private var currentArtworkURL: URL? = nil
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
                
                HStack(alignment: .top, spacing: 24) {

                    // Right-aligned text info
                    VStack(alignment: .trailing, spacing: 12) {
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
                                Text(isFollower ? "\(MusicStationOption(rawValue: settings.musicStationRaw)?.rawValue ?? "Music") via AirPlay" : (playerManager.nowPlayingTitle.isEmpty ? nowPlayingTitle : playerManager.nowPlayingTitle))
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

                    // Album art + song info
                    if settings.backgroundMusic && currentArtworkURL != nil {
                        VStack(alignment: .leading, spacing: 6) {
                            AsyncImage(url: currentArtworkURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 140, height: 140)
                                        .cornerRadius(10)
                                        .colorMultiply(colorScheme == .crimson ? Color(red: 0.6, green: 0.0, blue: 0.05) : .white)
                                default:
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 140, height: 140)
                                }
                            }

                            if !currentSongTitle.isEmpty {
                                Text(currentSongTitle)
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(textColor)
                                    .lineLimit(2)
                                    .frame(maxWidth: 300, alignment: .leading)
                            }

                            if !currentArtistName.isEmpty {
                                Text(currentArtistName)
                                    .font(.system(size: 30, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.7))
                                    .lineLimit(1)
                                    .frame(maxWidth: 300, alignment: .leading)
                            }
                        }
                    }
                }

                Spacer().frame(height: 60)
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

            // Update now playing metadata for album art display
            updateNowPlayingInfo()
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
        .onChange(of: settings.requestedStation) { _, station in
            // Leader handles station change requests from followers
            if !station.isEmpty && settings.isLeader {
                settings.musicStationRaw = station
                settings.requestedStation = ""
                startBackgroundMusic()
            }
        }
        .onChange(of: settings.requestedSettings) { _, json in
            // Leader handles any setting change requests from followers
            if !json.isEmpty && settings.isLeader {
                settings.applyRequestedSettings()
                // Restart music if station changed via generic request
                startBackgroundMusic()
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
            SettingsView(settings: settings, playerManager: playerManager)
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
        currentSongTitle = ""
        currentArtistName = ""
        currentArtworkURL = nil
    }

    func updateNowPlayingInfo() {
        let player = ApplicationMusicPlayer.shared
        guard player.state.playbackStatus == .playing else {
            if player.state.playbackStatus != .paused {
                currentSongTitle = ""
                currentArtistName = ""
                currentArtworkURL = nil
            }
            return
        }
        if let entry = player.queue.currentEntry {
            let title = entry.title ?? ""
            let artist = entry.subtitle ?? ""
            if title != currentSongTitle || artist != currentArtistName {
                currentSongTitle = title
                currentArtistName = artist
                if let artwork = entry.artwork {
                    currentArtworkURL = artwork.url(width: 240, height: 240)
                } else {
                    currentArtworkURL = nil
                }
            }
        }
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

#Preview {
    ContentView()
}
