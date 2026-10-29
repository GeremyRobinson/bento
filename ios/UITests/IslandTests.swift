import XCTest

/// The grown-ups' island used as a person uses it (G 29 Oct: "test it as a person using it to see any animation errors"):
/// opened from More, held open, every tab tapped, the pages swiped, a switch flipped, a slider dragged and tapped, shut,
/// opened again and shut. Each moment is marked in the log with the time, so a screen recording of the run can be cut
/// into frames around each one.
final class IslandTests: XCTestCase {
    func testTheIslandLikeAPerson() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-set-up"]
        app.launch()
        sleep(6)
        func mark(_ s: String) { print("ISLAND-MARK \(Date().timeIntervalSince1970) \(s)") }
        func pause() { usleep(1_400_000) }

        mark("more"); app.buttons["More"].tap(); pause()
        mark("for-grown-ups"); app.buttons["For grown-ups"].tap(); pause()
        let hold = app.buttons["Hold for 3 seconds"]
        XCTAssertTrue(hold.waitForExistence(timeout: 3))
        mark("hold"); hold.press(forDuration: 3.6); sleep(3)
        XCTAssertTrue(app.buttons["Privacy"].waitForExistence(timeout: 3))

        for t in ["Privacy", "Help", "Plan", "Settings"] { mark("tab-\(t)"); app.buttons[t].tap(); pause() }

        // the pages swiped with a finger: left twice, right once
        let page = app.buttons["Privacy"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 8))
        let left = page.withOffset(CGVector(dx: -220, dy: 0)), right = page.withOffset(CGVector(dx: 220, dy: 0))
        mark("swipe-left-1"); right.press(forDuration: 0.05, thenDragTo: left); pause()
        mark("swipe-left-2"); right.press(forDuration: 0.05, thenDragTo: left); pause()
        mark("swipe-right"); left.press(forDuration: 0.05, thenDragTo: right); pause()
        mark("tab-Settings-2"); app.buttons["Settings"].tap(); pause()

        // a switch flipped and back; a slider dragged along and tapped
        let sound = app.descendants(matching: .any).matching(identifier: "switch-Sound").firstMatch
        XCTAssertTrue(sound.waitForExistence(timeout: 3))
        mark("sound-off"); sound.tap(); pause()
        mark("sound-on"); sound.tap(); pause()
        let reminder = app.descendants(matching: .any).matching(identifier: "slider-Daily reminder").firstMatch
        let r0 = reminder.coordinate(withNormalizedOffset: CGVector(dx: 1.0 / 8, dy: 0.5)), r3 = reminder.coordinate(withNormalizedOffset: CGVector(dx: 7.0 / 8, dy: 0.5))
        mark("reminder-drag"); r0.press(forDuration: 0.2, thenDragTo: r3, withVelocity: 300, thenHoldForDuration: 0.3); pause()
        let paper = app.descendants(matching: .any).matching(identifier: "slider-Paper").firstMatch
        mark("paper-dark"); paper.coordinate(withNormalizedOffset: CGVector(dx: 5.0 / 6, dy: 0.5)).tap(); sleep(2)
        mark("paper-match"); paper.coordinate(withNormalizedOffset: CGVector(dx: 1.0 / 6, dy: 0.5)).tap(); sleep(2)

        // shut, opened again (straight to the tabs on the grown-ups' page), shut
        mark("close"); app.buttons["Close"].tap(); pause()
        mark("reopen-more"); app.buttons["More"].tap(); pause()
        mark("reopen"); app.buttons["For grown-ups"].tap(); pause()
        mark("close-2"); app.buttons["Close"].tap(); pause()
        mark("end")
    }
}
