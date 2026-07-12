//
//  CryoStationPicker.swift
//  Tally Matrix Clock
//
//  Created by Michael Fluharty on 3/31/26.
//

import SwiftUI
import MusicKit

struct CryoStationPicker: View {
    @Bindable var player: MusicPlaybackManager
    @ObservedObject var settings: CloudSettings

    @State private var expandedCategories: Set<StationCategory> = []
    @State private var expandedDecades: Set<BillboardDecade> = []
    @State private var asmrExpanded = false
    @State private var myMusicExpanded = false
    @State private var playlistsExpanded = false
    @State private var albumsExpanded = false
    @State private var artistsExpanded = false
    @State private var libraryLoaded = false
    @State private var expandedPlaylistID: MusicItemID?
    @State private var revealedSongs: [Song] = []
    @State private var playlistTrackCounts: [MusicItemID: Int] = [:]

    init(
        player: MusicPlaybackManager,
        settings: CloudSettings
    ) {
        self.player = player
        self.settings = settings
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(StationCategory.allCases, id: \.self) { category in
                if category == .billboard {
                    billboardCategoryPicker
                } else {
                    stationCategoryPicker(category: category)
                }
            }

            myMusicPicker
        }
    }

    // MARK: - Station Category

    private func stationCategoryPicker(category: StationCategory) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(category) {
                        expandedCategories.remove(category)
                    } else {
                        expandedCategories.insert(category)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Text(category.rawValue)

                    Spacer()

                    if !expandedCategories.contains(category) &&
                        player.currentStation.category == category {
                        Image(systemName: "checkmark")
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if expandedCategories.contains(category) {
                ForEach(MusicStationOption.stations(for: category), id: \.self) { station in
                    stationRow(station: station)
                }

                if category == .nature {
                    asmrSubSection
                }
            }
        }
    }

    // MARK: - ASMR

    private var asmrSubSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    asmrExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: asmrExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Text("ASMR")

                    Spacer()

                    if !asmrExpanded &&
                        MusicStationOption.asmrStations.contains(player.currentStation) {
                        Image(systemName: "checkmark")
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if asmrExpanded {
                ForEach(MusicStationOption.asmrStations, id: \.self) { station in
                    stationRow(station: station, indent: true)
                }
            }
        }
    }

    // MARK: - Billboard / Popular Hits

    private var billboardCategoryPicker: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedCategories.contains(.billboard) {
                        expandedCategories.remove(.billboard)
                    } else {
                        expandedCategories.insert(.billboard)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedCategories.contains(.billboard) ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Text("Popular Hits")

                    Spacer()

                    if !expandedCategories.contains(.billboard) &&
                        player.currentStation.category == .billboard {
                        Image(systemName: "checkmark")
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if expandedCategories.contains(.billboard) {
                stationRow(station: .top100USA)

                ForEach(BillboardDecade.allCases, id: \.self) { decade in
                    decadePicker(decade: decade)
                }
            }
        }
    }

    private func decadePicker(decade: BillboardDecade) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedDecades.contains(decade) {
                        expandedDecades.remove(decade)
                    } else {
                        expandedDecades.insert(decade)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedDecades.contains(decade) ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Text(decade.rawValue)

                    Spacer()

                    if !expandedDecades.contains(decade) &&
                        player.currentStation.decade == decade {
                        Image(systemName: "checkmark")
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if expandedDecades.contains(decade) {
                ForEach(MusicStationOption.stations(for: decade), id: \.self) { station in
                    stationRow(station: station, indent: true)
                }
            }
        }
    }

    // MARK: - Station Row

    private func stationRow(station: MusicStationOption, indent: Bool = false) -> some View {
        Button {
            Task {
                await player.play(station: station)
            }
        } label: {
            HStack {
                Image(systemName: player.currentStation == station ? "checkmark.circle.fill" : "circle")

                Text(station.rawValue)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.leading, indent ? 48 : 28)
            .padding(.trailing, 8)
        }
        .buttonStyle(SettingsFocusButtonStyle())
    }

    // MARK: - My Music

    private var myMusicPicker: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    myMusicExpanded.toggle()
                    if myMusicExpanded && !libraryLoaded {
                        libraryLoaded = true
                        Task { await player.loadLibrary() }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: myMusicExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Image(systemName: "music.note.house.fill")

                    Text("My Music")

                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if myMusicExpanded {
                // Playlists
                librarySubSection(
                    title: "Playlists",
                    count: player.libraryPlaylists.count,
                    isExpanded: $playlistsExpanded
                ) {
                    ForEach(player.libraryPlaylists, id: \.id) { playlist in
                        playlistRevealRow(playlist: playlist)
                    }
                    .onAppear { loadAllPlaylistCounts() }
                }

                // Albums
                librarySubSection(
                    title: "Albums",
                    count: player.libraryAlbums.count,
                    isExpanded: $albumsExpanded
                ) {
                    ForEach(player.libraryAlbums, id: \.id) { album in
                        Button {
                            settings.musicStationRaw = MusicStationOption.none.rawValue
                            Task { await player.playAlbum(album) }
                        } label: {
                            HStack {
                                Image(systemName: "square.stack")

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(album.title)
                                        .lineLimit(1)
                                    Text(album.artistName)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.leading, 48)
                            .padding(.trailing, 8)
                        }
                        .buttonStyle(SettingsFocusButtonStyle())
                    }
                }

                // Artists
                librarySubSection(
                    title: "Artists",
                    count: player.libraryArtists.count,
                    isExpanded: $artistsExpanded
                ) {
                    ForEach(player.libraryArtists, id: \.id) { artist in
                        Button {
                            settings.musicStationRaw = MusicStationOption.none.rawValue
                            Task { await player.loadSongs(for: artist) }
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")

                                Text(artist.name)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.leading, 48)
                            .padding(.trailing, 8)
                        }
                        .buttonStyle(SettingsFocusButtonStyle())
                    }
                }
            }
        }
    }

    private func librarySubSection<Content: View>(
        title: String,
        count: Int,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .frame(width: 20)

                    Text(title)

                    Spacer()

                    Text("\(count)")
                }
                .padding(.vertical, 8)
                .padding(.leading, 28)
                .padding(.trailing, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            if isExpanded.wrappedValue {
                content()
            }
        }
    }

    // MARK: - Playlist Track Count Loader

    private func loadAllPlaylistCounts() {
        for playlist in player.libraryPlaylists {
            guard playlistTrackCounts[playlist.id] == nil else { continue }
            Task {
                let detailed = try? await playlist.with([.tracks])
                let count = detailed?.tracks?.count ?? 0
                await MainActor.run {
                    playlistTrackCounts[playlist.id] = count
                }
            }
        }
    }

    // MARK: - Playlist Reveal Row

    private func playlistRevealRow(playlist: Playlist) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedPlaylistID == playlist.id {
                        expandedPlaylistID = nil
                        revealedSongs = []
                    } else {
                        expandedPlaylistID = playlist.id
                        Task {
                            let detailed = try? await playlist.with([.tracks])
                            let tracks = detailed?.tracks ?? []
                            revealedSongs = tracks.compactMap { track in
                                if case let .song(song) = track { return song }
                                return nil
                            }
                            playlistTrackCounts[playlist.id] = revealedSongs.count
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedPlaylistID == playlist.id ? "chevron.down" : "music.note.list")

                    Text(playlist.name)
                        .lineLimit(1)

                    Spacer()

                    if expandedPlaylistID == playlist.id {
                        Text("\(revealedSongs.count) tracks")
                    } else if let count = playlistTrackCounts[playlist.id] {
                        Text("\(count)")
                    }
                }
                .padding(.vertical, 6)
                .padding(.leading, 48)
                .padding(.trailing, 8)
            }
            .buttonStyle(SettingsFocusButtonStyle())

            // Revealed track list
            if expandedPlaylistID == playlist.id {
                // Play All
                Button {
                    settings.musicStationRaw = MusicStationOption.none.rawValue
                    Task { await player.playPlaylist(playlist) }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")

                        Text("Play All (\(revealedSongs.count) tracks)")

                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 62)
                    .padding(.trailing, 8)
                }
                .buttonStyle(SettingsFocusButtonStyle())

                // Individual songs
                ForEach(revealedSongs, id: \.id) { song in
                    Button {
                        settings.musicStationRaw = MusicStationOption.none.rawValue
                        Task { await player.playSong(song) }
                    } label: {
                        HStack {
                            Text(song.title)
                                .lineLimit(1)

                            Spacer()

                            Text(song.artistName)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .padding(.leading, 62)
                        .padding(.trailing, 8)
                    }
                    .buttonStyle(SettingsFocusButtonStyle())
                }
            }
        }
    }
}
