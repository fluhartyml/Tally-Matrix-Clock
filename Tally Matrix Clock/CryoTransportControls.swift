//
//  CryoTransportControls.swift
//  Tally Matrix Clock
//
//  Created by Michael Fluharty on 3/31/26.
//

import SwiftUI
import CryoKit

struct CryoTransportControls: View {
    @Bindable var player: MusicPlaybackManager
    let tint: Color
    let dark: Color
    let border: Color
    let glow: Color

    init(
        player: MusicPlaybackManager,
        tint: Color = Color(red: 0.65, green: 0.82, blue: 0.95),
        dark: Color = Color(red: 0.12, green: 0.18, blue: 0.28),
        border: Color = Color(red: 0.35, green: 0.55, blue: 0.75),
        glow: Color = Color(red: 0.4, green: 0.7, blue: 1.0)
    ) {
        self.player = player
        self.tint = tint
        self.dark = dark
        self.border = border
        self.glow = glow
    }

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Transport
            HStack(spacing: 32) {
                Button { player.skipBack() } label: {
                    transportButton(icon: "backward.end.fill", size: 24)
                }

                Button { player.togglePlayPause() } label: {
                    transportButton(
                        icon: player.isPlaying ? "pause.fill" : "play.fill",
                        size: 32,
                        prominent: true
                    )
                }

                Button { player.skipForward() } label: {
                    transportButton(icon: "forward.end.fill", size: 24)
                }

                Button { player.stop() } label: {
                    transportButton(icon: "stop.fill", size: 22)
                }
            }

            // Row 2: Shuffle & Repeat
            HStack(spacing: 16) {
                // Shuffle
                Button { player.toggleShuffle() } label: {
                    modeButton(
                        icon: "shuffle",
                        label: "Shuffle",
                        isActive: player.isShuffleEnabled
                    )
                }
                .frame(maxWidth: .infinity)

                // Repeat All
                Button {
                    player.repeatMode = player.repeatMode == .all ? .none : .all
                } label: {
                    modeButton(
                        icon: "repeat",
                        label: "All",
                        isActive: player.repeatMode == .all
                    )
                }
                .frame(maxWidth: .infinity)

                // Repeat One
                Button {
                    player.repeatMode = player.repeatMode == .one ? .none : .one
                } label: {
                    modeButton(
                        icon: "repeat.1",
                        label: "One",
                        isActive: player.repeatMode == .one
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Button Styles

    private func transportButton(icon: String, size: CGFloat, prominent: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [dark.opacity(0.8), Color(red: 0.08, green: 0.12, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [border.opacity(0.6), border.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: icon)
                .shadow(color: prominent ? glow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(width: prominent ? 64 : 52, height: prominent ? 52 : 44)
    }

    private func modeButton(icon: String, label: String, isActive: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [dark.opacity(0.8), Color(red: 0.08, green: 0.12, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isActive ? tint.opacity(0.8) : border.opacity(0.6),
                                    isActive ? tint.opacity(0.4) : border.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .shadow(color: isActive ? glow.opacity(0.4) : .clear, radius: 3)
        }
        .frame(height: 36)
    }
}
