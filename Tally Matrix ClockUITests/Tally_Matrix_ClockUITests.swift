//
//  Tally_Matrix_ClockUITests.swift
//  Tally Matrix ClockUITests
//
//  Created by Michael Fluharty on 10/16/25.
//
//  REM: 2026 NOV 24 — his ask: "does your bots check the apple tvs accessability ... the apple tv
//  os probably where accesssability is more important". These tests drive the app the way a
//  person does on Apple TV — with Siri Remote presses — and check what VoiceOver can find,
//  by its spoken name, never by screen position.
//

import XCTest

final class Tally_Matrix_ClockUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func element(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.descendants(matching: .any)[name]
    }

    /// The clock face reads as one element named "Time" whose value is the time itself.
    @MainActor
    func testClockFaceSpeaksTheTime() throws {
        let app = XCUIApplication()
        app.launch()
        let face = element(app, "tallyFace")
        XCTAssertTrue(face.waitForExistence(timeout: 30), "clock face not found")
        XCTAssertEqual(face.label, "Time")
        let value = face.value as? String ?? ""
        XCTAssertTrue(value.contains(":"), "face should speak a time, got \(value)")
    }

    /// Up on the remote opens Settings; every switch is found by its spoken name, not a blank.
    @MainActor
    func testSettingsControlsHaveSpokenNames() throws {
        // REM 2026 NOV 24: OFF for now, said so to him. In the tvOS Simulator neither Up nor click
        // reaches the clock's .focusable root from XCUIRemote (tree after each press: clock only,
        // no Settings) — on his real TVs Up opens Settings. Turn back on once remote focus is solved.
        throw XCTSkip("Simulator remote presses don't reach the clock's focus root; Up works on real Apple TV.")

        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(element(app, "tallyFace").waitForExistence(timeout: 30))

        // REM: the launch credits ("Engineered with Claude by Anthropic") run ~15 s; a press made
        // while they play never reached Settings (11-24 run: tree showed the clock, no Settings).
        // Wait for the credits to leave, the way a person waits, then press Up.
        let credits = element(app, "Engineered with Claude by Anthropic")
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: credits)
        _ = XCTWaiter.wait(for: [gone], timeout: 25)
        XCUIRemote.shared.press(.up)
        if !element(app, "Show Base-10 Time").waitForExistence(timeout: 5) {
            // Click (select) also opens Settings when no music is playing — same as on his TVs.
            XCUIRemote.shared.press(.select)
        }
        sleep(2)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree-after-up"; tree.lifetime = .keepAlways; add(tree)
        print("TREE-START\n\(app.debugDescription)\nTREE-END")

        for name in ["Show Base-10 Time", "24-Hour Clock", "Show Date", "Show Weather",
                     "Glyph Rain", "Background Music", "Night Mode"] {
            XCTAssertTrue(element(app, name).waitForExistence(timeout: 10), "no control named \(name)")
        }
        XCTAssertTrue(element(app, "Back").exists, "no Back button")
    }
}
