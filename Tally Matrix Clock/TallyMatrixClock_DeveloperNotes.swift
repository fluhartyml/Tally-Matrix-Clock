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
