import XCTest

/// Real touches on the places around the lessons (G 20 Oct): the bar's Me, a card on Me opening its lesson and the bar's
/// Me coming back to Me, the daily review opened from Me and closed the same way, a shelf too long for the screen opened
/// and put away, the grown-ups' square held down for its 3 seconds, a tap on the map still choosing a lesson.
/// Screenshots are attached at each moment. Positions on the paper are worked out from where each page is framed.
final class PlacesTests: XCTestCase {
    /// Me for a child some way in (`-seed-me`: Shots.seedMe, kept in memory only): Rounding decimals, the first card on
    /// its Go over shelf, opened by a tap; the bar's way back says Me and goes back to Me; then the daily review, from its
    /// card beside Today's pick, opened and closed the same way.
    func testMeOpensItsLessonAndTheReview() throws {
        let app = launch("-seed-me")
        // the seeded child's longest shelf, Getting stronger, has 5
        let me = Framed(app, height: Me.top + Double(min(5, Me.rows(app))) * Me.u + 20)

        tapMe(app)
        attach(app, "1 me")
        onMe(app, "Me from the bar")

        // Rounding decimals: Go over's first card, a block under the shelf's name, its middle 1.5 blocks in
        me.tap(Me.x + 1.5 * Me.u, Me.top + 0.5 * Me.u)
        sleep(4)
        attach(app, "2 a lesson from Me")
        inPage(app, "Rounding decimals")
        let back = app.buttons["Me"]
        XCTAssertFalse(back.isSelected, "it's a way back, not a place")
        back.tap()
        sleep(4)
        attach(app, "3 back on Me")
        onMe(app, "back from the lesson")

        // the daily review: the card beside Today's pick, its middle 5.5 blocks across and 2 down
        me.tap(Me.x + 5.5 * Me.u, 2 * Me.u)
        sleep(4)
        attach(app, "4 the review from Me")
        inPage(app, "Daily review")
        app.buttons["Me"].tap()
        sleep(4)
        attach(app, "5 back on Me again")
        onMe(app, "back from the review")
    }

    /// A shelf too long for the screen (`-seed-me-full`: every lesson learned, 15 of them getting stronger): its last
    /// card, "and 11 more", opens it; a card in its third column (Adding and subtracting, the eleventh soonest check)
    /// opens that lesson, and the bar's Me comes back to the shelf still open; Back to Me puts it away, and Today's pick
    /// is where it was.
    func testALongShelfOpensAndComesBack() throws {
        let app = launch("-seed-me-full")
        let rows = Me.rows(app), whole = Framed(app, height: Me.top + Double(rows) * Me.u + 20)
        // opened: its name on Me's top row, its 15 cards in three columns of 5, Back to Me a square under them
        let open = Framed(app, height: 6 * Me.u + 4 * 20)

        tapMe(app)
        attach(app, "1 me, a long shelf")
        // "and 11 more": Getting stronger's last place, its rows-th
        whole.tap(Me.x + 5.5 * Me.u, Me.top + (Double(rows) - 0.5) * Me.u)
        sleep(3)
        attach(app, "2 the shelf open")
        onMe(app, "the shelf open")

        open.tap(Me.x + 9.5 * Me.u, 1.5 * Me.u)
        sleep(4)
        attach(app, "3 a lesson from the open shelf")
        inPage(app, "Adding and subtracting")
        app.buttons["Me"].tap()
        sleep(4)
        attach(app, "4 back on the open shelf")
        onMe(app, "back from the lesson")

        // Back to Me: a square under the cards' fifth row, on the left
        open.tap(Me.x + 90, Me.u + 5 * Me.u + 2 * 20)
        sleep(3)
        attach(app, "5 the whole of Me")
        onMe(app, "Back to Me")
        // Today's pick (Rounding decimals, checked the longest ago) is drawn again where it was: it opens
        whole.tap(Me.x + 1.5 * Me.u, 2 * Me.u)
        sleep(4)
        attach(app, "6 today's pick")
        inPage(app, "Rounding decimals")
        app.buttons["Me"].tap()
        sleep(4)
        onMe(app, "back from today's pick")
    }

    // MARK: Me on the screen

    /// Me on the paper (MePage): its top-left at (-1600, 0), 11 blocks of 100 points wide; Today's cards on its second
    /// block row, the shelves' from its sixth (`top`), as many rows as fit with all of Me at 75% (never fewer than 2).
    private enum Me {
        static let x = -1600.0, u = 100.0, width = 11 * u, top = 5 * u
        static func rows(_ app: XCUIApplication) -> Int {
            let room = app.windows.firstMatch.frame.size.height - Framed.top - Framed.bar - 2 * Framed.pad
            return max(2, Int((room / 0.75 - top - 20) / u))
        }
    }

    /// Me framed whole (PaperModel.framingBelowBar): at up to 100%, two squares to spare, centred in the room above the
    /// bar. `height`: how tall Me is drawn now.
    private struct Framed {
        static let top = 24.0, bar = 120.0, pad = 40.0
        let window: XCUIElement, size: CGSize, height: Double
        init(_ app: XCUIApplication, height: Double) { window = app.windows.firstMatch; size = window.frame.size; self.height = height }
        /// A tap on a point of Me's paper, where it is on the screen.
        func tap(_ x: Double, _ y: Double) {
            let room = size.height - Self.top - Self.bar
            let z = min(1, (size.width - 2 * Self.pad) / Me.width, (room - 2 * Self.pad) / height)
            let sx = size.width / 2 + (x - (Me.x + Me.width / 2)) * z, sy = Self.top + room / 2 + (y - height / 2) * z
            window.coordinate(withNormalizedOffset: CGVector(dx: sx / size.width, dy: sy / size.height)).tap()
        }
    }

    private func launch(_ seed: String) -> XCUIApplication {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", seed]
        app.launch()
        sleep(6)
        return app
    }
    private func tapMe(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Me"].waitForExistence(timeout: 5))
        app.buttons["Me"].tap()
        sleep(3)
    }
    /// On Me: the bar has Lessons, and its Me is lit.
    private func onMe(_ app: XCUIApplication, _ why: String) {
        XCTAssertTrue(app.buttons["Lessons"].waitForExistence(timeout: 5), "\(why): the bar is Me's, with Lessons")
        XCTAssertTrue(app.buttons["Me"].isSelected, "\(why): Me is lit in the bar")
    }
    /// A page opened from Me: the bar names it, has no Lessons, and its way back says Me.
    private func inPage(_ app: XCUIApplication, _ name: String) {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "the bar names \(name)")
        XCTAssertFalse(app.buttons["Lessons"].exists, "in \(name) the bar has no Lessons")
        XCTAssertTrue(app.buttons["Me"].exists, "the bar's way back from \(name) says Me")
    }

    func testMeTheGrownUpsHoldAndTheMap() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-set-up"]
        app.launch()
        sleep(6)
        attach(app, "1 map")
        let window = app.windows.firstMatch
        let size = window.frame.size
        /// A point on the screen, in points from its top-left.
        func at(_ x: Double, _ y: Double) -> XCUICoordinate { window.coordinate(withNormalizedOffset: CGVector(dx: x / size.width, dy: y / size.height)) }
        /// The middle of the room the paper is framed in (clear of the bar), where a framed page's middle lands.
        let mid = (x: size.width / 2, y: 24 + (size.height - 24 - 120) / 2)

        // Me, from the bar: a page on the paper
        let me = app.buttons["Me"]
        XCTAssertTrue(me.waitForExistence(timeout: 5))
        me.tap()
        sleep(3)
        attach(app, "2 me")

        // the grown-ups' page, from More, shut behind its square: held for 3.6 seconds, it opens
        app.buttons["More"].tap()
        sleep(1)
        let grownUps = app.buttons["For grown-ups"]
        XCTAssertTrue(grownUps.waitForExistence(timeout: 3))
        grownUps.tap()
        sleep(3)
        attach(app, "3 gate")
        // the gate is framed at 100%: its frame (6 blocks by 23 squares) centred; the square's middle is 2 blocks left of
        // that and 3.5 squares down
        at(mid.x - 200, mid.y + 70).press(forDuration: 1.2)
        sleep(1)
        attach(app, "4 let go too soon")
        at(mid.x - 200, mid.y + 70).press(forDuration: 3.6)
        sleep(2)
        attach(app, "5 grown-ups open")
        // the paper's colours, from the page (framed at 82%: its Colours blocks are 107 points under the screen's middle,
        // Dark 428 to the right of it, Match the iPad 198): dark, then as the iPad is set again
        at(mid.x + 428, mid.y + 107).tap()
        sleep(2)
        attach(app, "5b dark from the page")
        at(mid.x + 198, mid.y + 107).tap()
        sleep(2)
        attach(app, "5c as the iPad is set")

        // back to the map from the bar; a tap on a lesson there chooses it
        app.buttons["Lessons"].tap()
        sleep(3)
        attach(app, "6 map again")
        // the map frames today's chapter (Whole numbers, nothing learned) at 100% from its title down: Long division, its
        // second lesson, is the middle of the screen across and 264 points down
        at(size.width / 2, 264).tap()
        sleep(2)
        attach(app, "7 tapped on the map")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
