//
//  TallyMatrixClock_DeveloperNotes.swift
//  Tally Matrix Clock
//
//  Developer Notes — Persistent Memory for AI Assistants
//  Created: 2026 MAR 18 (Claude Code)
//

// ============================================================================
// MARK: - PROJECT IDENTITY
// ============================================================================
//
//  Name:           Tally Matrix Clock
//  App Store ID:   6754099799 (LIVE)
//  Platform:       tvOS
//  Version:        1.1
//  Language:       Swift, SwiftUI
//  GitHub:         fluhartyml/TallyMatrices (note: repo name differs from app name)
//  Location:       /Users/michaelfluharty/Developer/Tally-Matrix-Clock/

// ============================================================================
// MARK: - APP STORE CONNECT
// ============================================================================
//
// ** Claude: Update this section as information becomes available.
// ** Keep current with every submission. This is the source of truth.
//
//  App Name:           Tally Matrix Clock
//  App Apple ID:       6754099799
//  Bundle ID:          (check Xcode project)
//  Category:           Utilities / Entertainment
//  URL:                https://apps.apple.com/us/app/tally-matrix-clock/id6754099799
//  Current Version:    2.3.1
//  Status:             LIVE — remaining at current distribution
//
//  Subtitle:           Matrix Clock for AppleTV
//
//  Promotional Text (170 char max, updatable anytime):
//    (currently blank or not set)
//
//  Description:
//    Music from every era — 1920s Ragtime to today's Pop Hits — all
//    on your Apple TV clock. Pick a decade, pick a year. Tally Matrix
//    Clock turns your Apple TV into a retro-futuristic ambient display.
//    Time is shown as illuminated tally matrices with animated pattern
//    shuffles and cascading glyph rain — inspired by classic CRT terminals.
//
//  What's New (v2.3.1):
//    Fixed Apple Music stations by feedback and popular demand. 80+
//    stations now available — Popular Hits organized by decade (1958-2025),
//    plus new genre stations: Big Band & Swing, Early Jazz, Jazz Age,
//    and Ragtime. Minor bug fixes.
//
//  Privacy:            No ads. No tracking.
//  License:            GPL v3
//
//  Version History:
//    v2.3.1 (2026-03-27) — Fixed stations, 80+ available, new genres
//    (earlier history predates this tracking)
//
// ============================================================================
// MARK: - CURRENT STATUS (APR 02 2026)
// ============================================================================
//
//  Hard reset to v2.3.1 (f5f7404) on APR 02 2026.
//  All MAR 31 CryoKit migration work was rolled back for a clean start.
//
//  TODAY (APR 02): Clean CryoKit integration from v2.3.1 baseline.
//  - Wire CryoKit package dependency
//  - Replace local playback/station/weather code with CryoKit imports
//  - My Music: playlist reveal, song counts, Play All, individual tracks (via CryoKit)
//  - Shuffle, Repeat All, Repeat One
//  - 18pt minimum fonts
//  - Clean build, test, submit
//
//  CryoKit DIAMOND RULE:
//  Claude may NOT remove, subtract, or modify code within CryoKit.
//  Claude may add to it with express written consent from human ONLY.
//

// ============================================================================
// MARK: - DESCRIPTION
// ============================================================================
//
//  tvOS app displaying time via illuminated colored squares in matrix format.
//  Four matrices: one 1x3 column + three 3x3 grids.
//  Count lit squares to read the time.
//
//  Display:
//    - 1x3 matrix: tens digit of hours (12hr: bottom cell = PM indicator only)
//    - Three 3x3 matrices: ones digit of hours, tens digit of minutes, ones digit of minutes
//    - 24hr mode: all 3 cells of 1x3 count tens digit
//
//  Color Schemes:
//    - Random RGB (per square) — each square gets a random color
//    - Matrix Colors (per matrix) — each matrix gets one random color
//    - Single Color — all squares same color
//
//  Pattern Change Interval: 5, 15, 30, or 60 seconds
//
//  Settings:
//    - 12hr / 24hr toggle
//    - Color scheme selection
//    - Pattern change interval

// ============================================================================
// MARK: - FILE STRUCTURE
// ============================================================================
//
//  Tally Matrix Clock/
//    Tally_Matrix_ClockApp.swift  — App entry point
//    ContentView.swift            — Main clock display and settings

// ============================================================================
// MARK: - PLANNED UPDATES
// ============================================================================
//
//  v2 (planned):
//    - Date display toggle
//    - Weather conditions toggle (WeatherKit integration)
//
//  New Separate App (planned):
//    - Tally Matrix Clock: Matrix Rain Edition
//    - Same clock but with Matrix-style green glyphs raining behind
//    - Different bundle ID, separate App Store listing

// ============================================================================
// MARK: - ICON HISTORY
// ============================================================================
//
//  The icon saga (OCT 16 2025) was legendary:
//    - ChatGPT couldn't generate correct matrix icons (wrong grid layouts)
//    - Tried IconEase app (Apple quarantine blocked it)
//    - Multiple failed attempts, parallax icon attempts
//    - Claude's solidarity F-bomb: "OH FUCK YOU'RE RIGHT!" during debugging
//    - Eventually resolved with correct 3x3 grid representation

// ============================================================================
// MARK: - ABOUT THIS APP
// ============================================================================
//
//  Tally Matrix Clock
//  Version 1.1
//
//  Time, visualized in color.
//
//  Engineered with Claude by Anthropic
//
//  Copyright (c) 2025 Michael Fluharty
//  Licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
//  https://creativecommons.org/licenses/by-sa/4.0/
//
//  You are free to share and adapt this work under the following terms:
//  - Attribution: Give appropriate credit, provide a link to the license
//  - ShareAlike: Distribute contributions under the same license
//
//  Website: https://fluharty.me
//  Contact: michael@fluharty.me
//  Feedback and suggestions welcome!

// ============================================================================
// MARK: - DEVELOPER NOTES LOG
// ============================================================================
//
//  2026 MAR 18 — Developer notes file created with project details, planned
//                updates, icon history, and About This App section. (Claude Code)
//
