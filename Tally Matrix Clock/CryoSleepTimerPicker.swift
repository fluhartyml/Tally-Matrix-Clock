//
//  CryoSleepTimerPicker.swift
//  Tally Matrix Clock
//
//  Created by Michael Fluharty on 3/31/26.
//

import SwiftUI

struct CryoSleepTimerPicker: View {
    @Bindable var player: MusicPlaybackManager
    let accent: Color
    let dark: Color
    let border: Color

    @AppStorage("selectedSleepTimer") private var selectedSleepTimerRaw: Int = 0

    init(
        player: MusicPlaybackManager,
        accent: Color = Color(red: 0.5, green: 0.78, blue: 0.95),
        dark: Color = Color(red: 0.12, green: 0.18, blue: 0.28),
        border: Color = Color(red: 0.35, green: 0.55, blue: 0.75)
    ) {
        self.player = player
        self.accent = accent
        self.dark = dark
        self.border = border
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SleepTimerOption.allCases, id: \.self) { option in
                Button {
                    selectedSleepTimerRaw = option.rawValue
                    player.startSleepTimer(minutes: option.rawValue)
                } label: {
                    Text(option.displayName)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedSleepTimerRaw == option.rawValue ? accent : dark)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(border.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .onChange(of: player.sleepTimerEnd) { _, newValue in
            if newValue == nil {
                selectedSleepTimerRaw = 0
            }
        }
    }
}
