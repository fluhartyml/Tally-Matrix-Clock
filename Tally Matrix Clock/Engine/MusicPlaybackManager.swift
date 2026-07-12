//
//  MusicPlaybackManager.swift
//  CryoKit
//
//  Created by Michael Fluharty on 3/31/26.
//
//  DIAMOND RULE: You can only ADD to CryoKit. You are NOT allowed to
//  subtract code or features. No removals without express written consent.
//
//  Claude may not remove, subtract, or modify code within CryoKit.
//  Claude may, however, add to it with express written consent from human.
//
//  DATA LAYER ONLY: CryoKit is a data and information relay.
//  It provides playback, station catalog, library access, and weather data.
//  It must NEVER contain font modifiers, text styles, or presentation logic.
//  All aesthetic decisions belong to the consuming app (CryoTunes, Tally Matrix, etc.).
//  This principle applies to CryoKit and all future shared packages.
//

import Foundation
import MusicKit
import MediaPlayer
import Combine

@Observable
public class MusicPlaybackManager {
    public var currentStation: MusicStationOption = .none {
        didSet {
            UserDefaults.standard.set(currentStation.rawValue, forKey: "lastStation")
        }
    }
    public var isPlaying = false
    public var nowPlayingTitle = "" {
        didSet {
            UserDefaults.standard.set(nowPlayingTitle, forKey: "lastNowPlayingTitle")
        }
    }
    public var currentSongTitle = ""
    public var currentArtistName = ""
    public var currentArtworkURL: URL?
    /// The now-playing entry's MusicKit Artwork object. Rendered via `ArtworkImage`
    /// (the Apple-supported path) instead of resolving `.url()` + `AsyncImage`, which
    /// returns a `musickit://` URL that fails to load on the iOS 27 beta.
    public var currentArtwork: Artwork?
    public var sleepTimerEnd: Date?
    public var sleepTimerRemaining = ""
    public var isAuthorized = false
    public var errorMessage = ""
    public var playbackTime: TimeInterval = 0
    public var trackDuration: TimeInterval = 0

    // MARK: - Shuffle & Repeat

    public var isShuffleEnabled = false {
        didSet {
            player.state.shuffleMode = isShuffleEnabled ? .songs : .off
            UserDefaults.standard.set(isShuffleEnabled, forKey: "shuffleEnabled")
        }
    }
    public var repeatMode: CryoRepeatMode = .none {
        didSet {
            switch repeatMode {
            case .none: player.state.repeatMode = MusicPlayer.RepeatMode.none
            case .all: player.state.repeatMode = .all
            case .one: player.state.repeatMode = .one
            }
            UserDefaults.standard.set(repeatMode.rawValue, forKey: "repeatMode")
        }
    }

    private let player = ApplicationMusicPlayer.shared
    private var timerTask: Task<Void, Never>?
    private var nowPlayingTask: Task<Void, Never>?

    public init() {
        // Restore last station without auto-playing
        if let savedStation = UserDefaults.standard.string(forKey: "lastStation"),
           let station = MusicStationOption(rawValue: savedStation),
           station != .none {
            currentStation = station
            nowPlayingTitle = UserDefaults.standard.string(forKey: "lastNowPlayingTitle") ?? station.rawValue
        }

        // Restore shuffle & repeat
        isShuffleEnabled = UserDefaults.standard.bool(forKey: "shuffleEnabled")
        if let savedRepeat = UserDefaults.standard.string(forKey: "repeatMode"),
           let mode = CryoRepeatMode(rawValue: savedRepeat) {
            repeatMode = mode
        }

        startNowPlayingObserver()
    }

    // MARK: - Authorization

    public func requestAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        await MainActor.run { isAuthorized = status == .authorized }
        return status == .authorized
    }

    // MARK: - Playback

    public func play(station: MusicStationOption) async {
        guard station != .none else {
            stop()
            return
        }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        // Apply repeat mode: station's natural repeat OR user's saved preference
        if station.shouldRepeat {
            player.state.repeatMode = .all
        } else {
            switch repeatMode {
            case .none: player.state.repeatMode = MusicPlayer.RepeatMode.none
            case .all: player.state.repeatMode = .all
            case .one: player.state.repeatMode = .one
            }
        }

        // Apply shuffle
        player.state.shuffleMode = isShuffleEnabled ? .songs : .off

        let term = station.searchTerm
        var name = station.rawValue

        do {
            // Personal station — fetch dynamically from user's Apple Music account
            if station == .personalStation {
                if let result = try await playPersonalStation() {
                    name = result
                }
            } else {
                switch station.searchType {
                case .stationByID:
                    if let stationID = station.stationID,
                       let result = try await playStationByID(stationID) {
                        name = result
                    } else if let result = try await searchStation(term: term) {
                        name = result
                    }
                case .stationFirst:
                    if let result = try await searchStation(term: term) {
                        name = result
                    } else if let result = try await searchPlaylist(term: term) {
                        name = result
                    }
                case .stationOnly:
                    if let result = try await searchStation(term: term) {
                        name = result
                    }
                case .playlistFirst:
                    if let result = try await searchPlaylist(term: term) {
                        name = result
                    } else if let result = try await searchStation(term: term) {
                        name = result
                    }
                case .albumFirst:
                    if let result = try await searchAlbum(term: term) {
                        name = result
                    } else if let result = try await searchPlaylist(term: term) {
                        name = result
                    }
                }
            }

            await MainActor.run {
                currentStation = station
                nowPlayingTitle = name
                isPlaying = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Unable to play station. Check your connection."
            }
        }
    }

    private func playStationByID(_ id: String) async throws -> String? {
        let request = MusicCatalogResourceRequest<Station>(matching: \.id, equalTo: MusicItemID(id))
        let response = try await request.response()
        guard let station = response.items.first else { return nil }
        player.queue = [station]
        try await player.prepareToPlay()
        try await player.play()
        return station.name
    }

    /// Fetches and plays the user's personal Apple Music station dynamically.
    /// Returns the station name from Apple's API (e.g. "Michael's Station").
    private func playPersonalStation() async throws -> String? {
        let url = URL(string: "https://api.music.apple.com/v1/me/stations?filter[identity]=personal")!

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response = try await request.response()

        let decoded = try JSONDecoder().decode(PersonalStationResponse.self, from: response.data)
        guard let stationData = decoded.data.first else { return nil }

        // Play by the dynamically fetched station ID
        let stationID = stationData.id
        return try await playStationByID(stationID)
    }

    /// Response model for the personal station API endpoint.
    private struct PersonalStationResponse: Decodable {
        let data: [PersonalStationData]
    }

    private struct PersonalStationData: Decodable {
        let id: String
        let type: String
        let attributes: PersonalStationAttributes?
    }

    private struct PersonalStationAttributes: Decodable {
        let name: String?
    }

    private func searchStation(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Station.self])
        request.limit = 1
        let response = try await request.response()
        guard let station = response.stations.first else { return nil }
        player.queue = [station]
        try await player.prepareToPlay()
        try await player.play()
        return station.name
    }

    private func searchPlaylist(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Playlist.self])
        request.limit = 1
        let response = try await request.response()
        guard let playlist = response.playlists.first else { return nil }
        player.queue = [playlist]
        try await player.prepareToPlay()
        try await player.play()
        return playlist.name
    }

    private func searchAlbum(term: String) async throws -> String? {
        var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
        request.limit = 1
        let response = try await request.response()
        guard let album = response.albums.first else { return nil }
        player.queue = [album]
        try await player.prepareToPlay()
        try await player.play()
        return album.title
    }

    public func stop() {
        player.stop()
        currentStation = MusicStationOption.none
        isPlaying = false
        nowPlayingTitle = ""
        currentSongTitle = ""
        currentArtistName = ""
        currentArtworkURL = nil
        currentArtwork = nil
    }

    public func togglePlayPause() {
        if player.state.playbackStatus == .playing {
            player.pause()
            isPlaying = false
        } else if player.state.playbackStatus == .paused {
            Task {
                try? await player.play()
                await MainActor.run { isPlaying = true }
            }
        } else if currentStation != .none {
            Task {
                await play(station: currentStation)
            }
        }
    }

    public func skipForward() {
        Task {
            try? await player.skipToNextEntry()
        }
    }

    public func skipBack() {
        Task {
            try? await player.skipToPreviousEntry()
        }
    }

    // MARK: - Shuffle & Repeat Controls

    public func toggleShuffle() {
        isShuffleEnabled.toggle()
    }

    public func cycleRepeatMode() {
        switch repeatMode {
        case .none: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .none
        }
    }

    // MARK: - Now Playing Observer

    private func startNowPlayingObserver() {
        nowPlayingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let entry = self.player.queue.currentEntry
                if let entry {
                    self.currentSongTitle = entry.title
                    self.currentArtistName = entry.subtitle ?? ""
                    self.currentArtwork = entry.artwork
                    if let artwork = entry.artwork {
                        self.currentArtworkURL = artwork.url(width: 300, height: 300)
                    }
                }
                self.isPlaying = self.player.state.playbackStatus == .playing
                self.playbackTime = self.player.playbackTime
                if let entry, case let .song(song) = entry.item {
                    self.trackDuration = song.duration ?? 0
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: - Library Playback

    public var libraryPlaylists: [Playlist] = []
    public var libraryAlbums: [Album] = []
    public var libraryArtists: [Artist] = []
    public var librarySongs: [Song] = []

    public func loadLibrary() async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            var playlistRequest = MusicLibraryRequest<Playlist>()
            playlistRequest.sort(by: \.name, ascending: true)
            let playlistResponse = try await playlistRequest.response()

            var albumRequest = MusicLibraryRequest<Album>()
            albumRequest.sort(by: \.title, ascending: true)
            let albumResponse = try await albumRequest.response()

            var artistRequest = MusicLibraryRequest<Artist>()
            artistRequest.sort(by: \.name, ascending: true)
            let artistResponse = try await artistRequest.response()

            await MainActor.run {
                libraryPlaylists = Array(playlistResponse.items)
                libraryAlbums = Array(albumResponse.items)
                libraryArtists = Array(artistResponse.items)
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load library. Check your connection." }
        }
    }

    public func loadSongs(for album: Album) async {
        do {
            let detailedAlbum = try await album.with([.tracks])
            let tracks = detailedAlbum.tracks ?? []
            await MainActor.run {
                librarySongs = tracks.compactMap { track in
                    if case let .song(song) = track { return song }
                    return nil
                }
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load songs. Check your connection." }
        }
    }

    public func loadSongs(for artist: Artist) async {
        do {
            var request = MusicLibraryRequest<Song>()
            request.filter(matching: \.artistName, equalTo: artist.name)
            request.sort(by: \.title, ascending: true)
            let response = try await request.response()
            await MainActor.run {
                librarySongs = Array(response.items)
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to load songs. Check your connection." }
        }
    }

    public func playLibraryItem(_ item: any MusicCatalogSearchable & PlayableMusicItem) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [item]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    public func playPlaylist(_ playlist: Playlist) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [playlist]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = playlist.name
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    public func playAlbum(_ album: Album) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [album]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = album.title
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    public func playSong(_ song: Song) async {
        let authorized = await requestAuthorization()
        guard authorized else { return }

        do {
            player.queue = [song]
            try await player.prepareToPlay()
            try await player.play()
            await MainActor.run {
                currentStation = .none
                nowPlayingTitle = song.title
                isPlaying = true
            }
        } catch {
            await MainActor.run { errorMessage = "Unable to play. Check your connection." }
        }
    }

    // MARK: - Sleep Timer

    public func startSleepTimer(minutes: Int) {
        if minutes == 0 {
            sleepTimerEnd = nil
            sleepTimerRemaining = ""
            timerTask?.cancel()
            return
        }

        sleepTimerEnd = Date().addingTimeInterval(Double(minutes) * 60)
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let end = self.sleepTimerEnd else { return }
                let remaining = end.timeIntervalSinceNow
                if remaining <= 0 {
                    self.stop()
                    self.sleepTimerEnd = nil
                    self.sleepTimerRemaining = ""
                    return
                }
                let mins = Int(remaining) / 60
                let secs = Int(remaining) % 60
                self.sleepTimerRemaining = String(format: "%d:%02d", mins, secs)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

// MARK: - Repeat Mode

public enum CryoRepeatMode: String, CaseIterable, Sendable {
    case none = "off"
    case all = "all"
    case one = "one"

    public var displayName: String {
        switch self {
        case .none: return "Off"
        case .all: return "All"
        case .one: return "One"
        }
    }

    public var systemImage: String {
        switch self {
        case .none: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    public var isActive: Bool {
        self != .none
    }
}
