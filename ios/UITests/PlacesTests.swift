import XCTest

/// Real touches on the places around the lessons (G 20 Oct): the bar's Me, a card on Me opening its lesson and the bar's
/// Me coming back to Me, the daily review opened from Me and closed the same way, a shelf too long for the screen opened
/// and put away, the grown-ups' hold in the island held for its 3 seconds and its tabs, a tap on the map still
/// choosing a lesson.
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

        // the daily review: the card beside Today's pick, its middle 5.5 blocks across and 2 down under the name's block
        me.tap(Me.x + 5.5 * Me.u, Me.band + 2 * Me.u)
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
        whole.tap(Me.x + 1.5 * Me.u, Me.band + 2 * Me.u)
        sleep(4)
        attach(app, "6 today's pick")
        inPage(app, "Rounding decimals")
        app.buttons["Me"].tap()
        sleep(4)
        onMe(app, "back from today's pick")
    }

    // MARK: Me on the screen

    /// Me on the paper (MePage): its top-left at (-1600, 0), 11 blocks of 100 points wide; the child's name and grade on
    /// its first block row (`band`), Today's cards on its third, the shelves' from its seventh (`top`), as many rows as
    /// fit with all of Me at 75% (never fewer than 2).
    private enum Me {
        static let x = -1600.0, u = 100.0, width = 11 * u, band = u, top = 6 * u
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

        // Me, from the bar: a page on the paper
        let me = app.buttons["Me"]
        XCTAssertTrue(me.waitForExistence(timeout: 5))
        me.tap()
        sleep(3)
        attach(app, "2 me")

        // the grown-ups' page, from More: the hold grows out of the pill (the child's paper still behind it); let go too
        // soon, it stays shut; held for 3.6 seconds, the paper goes to the grown-ups' page and the island grows into its
        // tabs (G's island.html)
        app.buttons["More"].tap()
        sleep(1)
        let grownUps = app.buttons["For grown-ups"]
        XCTAssertTrue(grownUps.waitForExistence(timeout: 3))
        grownUps.tap()
        sleep(2)
        attach(app, "3 the hold in the island")
        let hold = app.buttons["Hold for 3 seconds"]
        XCTAssertTrue(hold.waitForExistence(timeout: 3), "the hold is in the island")
        hold.press(forDuration: 1.2)
        sleep(1)
        attach(app, "4 let go too soon")
        XCTAssertFalse(app.buttons["Privacy"].exists, "let go too soon, it stays shut")
        hold.press(forDuration: 3.6)
        sleep(3)
        attach(app, "5 grown-ups open, Settings in the island")
        XCTAssertTrue(app.buttons["Privacy"].waitForExistence(timeout: 3), "the island's tabs are there")
        XCTAssertTrue(app.buttons["Settings"].isSelected, "it opens on Settings")
        // the paper's colours, from the island: dark, then as the iPad is set again
        app.buttons["Dark"].tap()
        sleep(2)
        attach(app, "5b dark from the island")
        app.buttons["Match iPad"].tap()
        sleep(2)
        attach(app, "5c as the iPad is set")
        // the other tabs, then × shrinks the island back into the pill
        app.buttons["Privacy"].tap()
        sleep(1)
        attach(app, "5d privacy")
        XCTAssertTrue(app.buttons["Privacy"].isSelected)
        app.buttons["Help"].tap()
        sleep(1)
        attach(app, "5e help")
        app.buttons["Close"].tap()
        sleep(2)
        attach(app, "5f the island shut, the grown-ups' paper")
        XCTAssertFalse(app.buttons["Privacy"].exists, "the island shrank back into the pill")

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

    /// Setting up, the first time the app opens (`-setup-fresh`: a new install, kept in memory only), tapped through on
    /// the paper: Start, a name typed with the keyboard (return goes on), the grade's Next, the grown-up's Done. There's
    /// no bar until it's done; then the map, with the bar's Lessons. Each step is framed whole in the screen (no bar) at
    /// up to 100%, so a block's place is worked out from the step's frame (SetupPage, in squares of 20 points).
    func testSettingUp() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-setup-fresh"]
        app.launch()
        sleep(6)
        let window = app.windows.firstMatch, size = window.frame.size
        /// A tap on the step framed `w` by `h` squares, at (x, y) squares from its top-left.
        func tap(_ x: Double, _ y: Double, frame w: Double, _ h: Double) {
            let c = 20.0, room = size.height - 48
            let z = min(1, (size.width - 80) / (w * c), (room - 80) / (h * c))
            let sx = size.width / 2 + (x - w / 2) * c * z, sy = 24 + room / 2 + (y - h / 2) * c * z
            window.coordinate(withNormalizedOffset: CGVector(dx: sx / size.width, dy: sy / size.height)).tap()
        }
        attach(app, "1 welcome")
        XCTAssertFalse(app.buttons["Lessons"].exists, "no bar while setting up")
        // Start: 10 squares wide, under the 30 by 20 rectangle and its words, the welcome 27 squares tall
        tap(15, 26, frame: 30, 27)
        sleep(3)
        attach(app, "2 name")
        app.typeText("Mia")
        sleep(1)
        attach(app, "3 name typed")
        app.typeText("\n")
        sleep(3)
        attach(app, "4 grade")
        // a dead grade (3rd: its block 15 squares in), then Next under the row; the step is 64 by 17 squares
        tap(17, 7, frame: 64, 17)
        sleep(1)
        attach(app, "5 a grade coming soon")
        tap(3.5, 16, frame: 64, 17)
        sleep(3)
        attach(app, "6 for a grown-up")
        // Done, under the reminder and sound; the step is 42 by 22 squares
        tap(3.5, 21, frame: 42, 22)
        sleep(4)
        attach(app, "7 the map")
        XCTAssertTrue(app.buttons["Lessons"].waitForExistence(timeout: 5), "the map, with the bar, once it's done")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
