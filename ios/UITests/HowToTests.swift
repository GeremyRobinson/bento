import XCTest

/// The How to stays on the lesson's page (G 1 Nov: "it's kind of important"): its card plays it again, taught a tap at a
/// time, and Practice brings the page back with the card still there. Real clicks, found by what VoiceOver reads
/// (PaperAccess); a screenshot at each moment.
final class HowToTests: XCTestCase {
    func testTheHowToCardPlaysItAgain() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-seed-page", "g5-round"]
        app.launch()

        let card = app.buttons["How to"]
        XCTAssertTrue(card.waitForExistence(timeout: 15), "the How to's card is on the page")
        sleep(2)
        attach(app, "1 the page, the How to's card top right")
        card.tap()

        let next = app.buttons["Next step"], practise = app.buttons["Practice"]
        XCTAssertTrue(next.waitForExistence(timeout: 10), "the How to plays again, waiting for Next step")
        attach(app, "2 the How to playing again")
        var taps = 0
        for _ in 0..<30 where !practise.exists {
            if next.waitForExistence(timeout: 8) {
                next.tap(); taps += 1
                sleep(2)
                if taps == 2 { attach(app, "3 a step of it") }
            }
        }
        XCTAssertTrue(practise.waitForExistence(timeout: 15), "it ends on Practice")
        attach(app, "4 the end, Practice or Watch again")
        practise.tap()
        sleep(3)
        XCTAssertTrue(app.buttons["How to"].waitForExistence(timeout: 10), "back on the page, the card still there")
        sleep(2)
        attach(app, "5 back on the page")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
