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
//  Version:        3.0 (minimum tvOS 27)
//  Build:          = git rev-list --count HEAD, stamped by Scripts/stamp-build.sh via the
//                  post-commit hook (Scripts/install-hooks.sh). Never hand-stamp.
//  Language:       Swift, SwiftUI
//  GitHub:         fluhartyml/Tally-Matrix-Clock
//  Location:       ~/Developer.complex/Tally-Matrix-Clock/
//  Roadmap:        CLI Claude.Apartment/Workshop/Tally-Matrix-Clock-Roadmap.md (locked 2026 NOV 23)

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
//  Current Version:    3.0 (in the project; build 64 committed 2026 OCT 31)
//  Status:             ⚠️ verify — App Store status of 3.0 not confirmed here.
//                      Apple's public lookup read 2.4.1 on 2026 NOV 15 (Card-Catalog).
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
//    v3.0 (2026-09-14) — tvOS 27 minimum. Since 2.4.1: CryoKit retired, its 3 files
//      inlined into the app + now-playing artwork fixed (07-12); build number = commit
//      count via post-commit hook (09-04, 09-08); no non-exempt encryption declared so
//      TestFlight stops asking export compliance (10-31).
//    v2.4 (2026-04-02) — CryoKit data layer, shuffle/repeat, playlist reveal,
//      heartbeat, focus highlight, normalized codebase, CryoTunes placeholder art
//    v2.3.1 (2026-03-27) — Fixed stations, 80+ available, new genres
//    (earlier history predates this tracking)
//
// ============================================================================
// MARK: - CURRENT STATUS (NOV 23 2026)
// ============================================================================
//
//  Roadmap locked with Michael 2026 NOV 23 (Grok's survey, reviewed line by line).
//  Build order: commit build + these notes → silent-update permission → real tests →
//  one weather path + one sleep-timer path → private iCloud (privacy page edited in
//  the same work) → sync tests → Focus test on a real Apple TV → Auto Night Mode
//  (default theme Crimson) → OLED burn-in shift → remote left/right cycles themes.
//
//  ⛔ LOCKED (his word: "be explicit so it doesnt get reverted on accident in the
//  future"): the leader's 30-second check-in lives in its OWN CloudKit record, never in
//  the settings record, and never gets a silent-push subscription.
//
//  Today (before the roadmap): settings live in ONE shared PUBLIC CloudKit record
//  (CloudSettings.swift) that every household reads every 1 s — a privacy problem.
//
//  CryoKit was retired 2026 JUL 12 (files inlined); the APR 02 notes below are history.
//
//  ---- APR 02 2026 status (history) ----
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
//  App version displayed on clock face next to Apple TV device name.
//  Uses Bundle.main CFBundleShortVersionString at runtime.
//  Useful for confirming which build is running on each TV.
//
//  CryoKit has NO aesthetic control:
//  All font modifiers stripped from CryoKit views.
//  Apps control their own fonts, sizes, and button styles.
//  CryoKit only accepts tint/accent/border colors from the app.
//  tvOS app sets its own fonts via parent view modifiers or button styles.
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
//  Tally Matrix Clock/            (as of 2026 NOV 23)
//    Tally_Matrix_ClockApp.swift  — App entry point
//    ContentView.swift            — Main clock display, remote commands, weather fetch
//    SettingsView.swift           — Settings screen
//    CloudSettings.swift          — CloudKit settings sync, leader/follower, remote requests
//    Models.swift                 — Color schemes and option enums
//    TallyMatrixViews.swift       — The tally matrices
//    GlyphRainView.swift          — Falling glyphs
//    ClaudeStarburstView.swift    — Opening animation
//    TallyTime.swift              — Digit math (tested in Tally Matrix ClockTests)
//    LocationManager.swift        — Location for the ONE weather path (ContentView.fetchWeather)
//    CryoStationPicker.swift, CryoTransportControls.swift
//    Engine/                      — MusicStationCatalog, MusicPlaybackManager
//    (Removed 2026 NOV 23, roadmap 013: unused CryoSleepTimerPicker + Engine/WeatherManager.
//     The sleep timer lives only in ContentView, driven by CloudSettings.sleepTimerMinutes.)

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
//  Contact: michael@fluharty.com   (aligned 2026 NOV 23 with the support site — roadmap 015)
//  Feedback and suggestions welcome!

// ============================================================================
// MARK: - DEVELOPER NOTES LOG
// ============================================================================
//
//  2026 MAR 18 — Developer notes file created with project details, planned
//                updates, icon history, and About This App section. (Claude Code)
//  2026 NOV 23 — Brought to v3.0: identity, repo name, path, build-number hook,
//                version history, current status + locked roadmap, file list. (Claude Code)
//
