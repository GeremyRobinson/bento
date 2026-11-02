import XCTest
@testable import ObentoCore

final class PointsOnGridTests: XCTestCase {
    private func run(_ a: Int, _ b: Int, read: Bool, name: Int = 0) -> LessonRun {
        LessonRun(PointsOnGrid.spec, numbers: PointsOnGrid.numbers(a: a, b: b, read: read, name: name))
    }
    private func move(_ l: inout LessonRun, _ box: String, _ v: Double) -> LessonRun.Outcome { l.set(box, v); return l.go() }
    private func write(_ l: inout LessonRun, _ x: String, _ y: String) -> LessonRun.Outcome {
        l.reset()
        l.active = "x"; for c in x { l.type(String(c)) }
        l.active = "y"; for c in y { l.type(String(c)) }
        return l.go()
    }

    /// Plot A (5, 3), as in the preview: along the bottom, then up.
    func testPlot() {
        var l = run(5, 3, read: false)
        XCTAssertEqual(PointsOnGrid.spec.master, "grid")
        XCTAssertEqual(l.display, [.text("A"), .text("("), .num(5), .text(","), .num(3), .text(")")])
        XCTAssertEqual(l.words.say, "Put A at (5, 3).")
        XCTAssertEqual(l.picture["at"], 0)
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Put A at (5, 3). Drag the dot along the bottom. The first number is how far across.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, "x", 0), .notYet("Drag the dot along the bottom."))
        XCTAssertEqual(l.misses, 0, "let go at 0: nothing happened, not a miss")
        XCTAssertEqual(move(&l, "x", 4), .notYet("That’s 4 across. Count 5 along the bottom."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings the number to reach")
        XCTAssertEqual(move(&l, "x", 3), .notYet("That’s 3 across. The first number, 5, is how far across."))
        XCTAssertEqual(move(&l, "x", 5), .moved(2))

        XCTAssertEqual(l.words.say, "Now drag it up. The second number is how far up.")
        XCTAssertEqual(move(&l, "y", 2), .notYet("That’s 2 up. Count 3 up."))
        XCTAssertEqual(move(&l, "y", 5), .notYet("That’s 5 up. The second number, 3, is how far up."))
        XCTAssertEqual(move(&l, "y", 3), .moved(3))

        XCTAssertEqual(l.words.say, "5 across, then 3 up. Across always comes first.")
        XCTAssertEqual(l.picture["at"], 3)
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(l.slips.map(\.said), ["That’s 4 across. Count 5 along the bottom.", "That’s 3 across. The first number, 5, is how far across.",
                                             "That’s 2 up. Count 3 up.", "That’s 5 up. The second number, 3, is how far up."])
    }

    /// Read a point: down to the bottom, across to the side, then the pair written.
    func testRead() {
        var l = run(7, 2, read: true, name: 2)
        XCTAssertEqual(l.display, [.text("Where is C?")], "a point to read never gives its answer away on its card")
        XCTAssertEqual(l.words.say, "Where is C?")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.words.say, "Where is C? Drag C straight down to the numbers.")
        XCTAssertEqual(move(&l, "x", 1), .notYet("Drag it all the way down to the numbers."))
        XCTAssertEqual(l.misses, 0, "not all the way: a notice")
        XCTAssertEqual(move(&l, "x", 0), .moved(2))
        XCTAssertEqual(l.words.say, "Now drag C across to the side.")
        XCTAssertEqual(move(&l, "x", 3), .notYet("Drag it all the way across to the numbers."))
        XCTAssertEqual(move(&l, "x", 0), .moved(3))

        XCTAssertEqual(l.words.say, "Write where it is. Across first, then up.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["x", "y"])
        l.active = "x"; l.type("7")
        XCTAssertEqual(l.go(), .notYet("Fill in both boxes."))
        XCTAssertEqual(write(&l, "2", "7"), .notYet("Across comes first: the number under it, then the one beside it."))
        XCTAssertEqual(write(&l, "6", "2"), .notYet("C is above 7 on the bottom line."))
        XCTAssertEqual(write(&l, "7", "3"), .notYet("C is level with 2 on the side."))
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(l.steps[3].answer?.work, [.text("C"), .text("("), .num(7), .text(","), .num(2), .text(")")])
        XCTAssertEqual(write(&l, "7", "2"), .moved(4))
        XCTAssertEqual(l.words.say, "C is 7 across and 2 up. Across always comes first.")
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// The preview's ranges: a in 1–10, b in 1–7, never the same; the kinds take turns, plot first.
    func testGenerator() {
        var rng = SeededRandom(seed: 5)
        var seen: Set<String> = []
        for index in 0..<10 {
            for _ in 0..<300 {
                let n = PointsOnGrid.spec.generate(&rng, index), p = PointsOnGrid.Parts(n)
                XCTAssertTrue((1...10).contains(p.a) && (1...7).contains(p.b), "\(n)")
                XCTAssertNotEqual(p.a, p.b, "a swap is always caught: \(n)")
                XCTAssertEqual(p.read, index % 2 == 1)
                XCTAssertEqual(LessonRun(PointsOnGrid.spec, numbers: n).steps.count, p.read ? 5 : 4)
                seen.insert(p.name)
            }
        }
        XCTAssertEqual(seen.count, PointsOnGrid.letters.count, "every letter names a point sometimes")
        XCTAssertFalse(PointsOnGrid.letters.contains("O") || PointsOnGrid.letters.contains("I"))
        XCTAssertEqual(PointsOnGrid.spec.requiredKeys, ["a", "b", "kind", "name"])
    }

    func testSkillCheckDrawsBothKinds() {
        var rng = SeededRandom(seed: 9)
        let items = PointsOnGrid.spec.check
        XCTAssertEqual(items.count, 4)
        var kinds: [Bool] = []
        for item in items {
            let n = item.draw(PointsOnGrid.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true)
            kinds.append(PointsOnGrid.Parts(n).read)
        }
        XCTAssertEqual(kinds, [false, true, false, true])
        // a test asks both kinds, one try each
        let runs = LessonPlan.testRuns(PointsOnGrid.spec, using: &rng)
        XCTAssertEqual(runs.count, LessonPlan.test)
        XCTAssertTrue(runs.contains { PointsOnGrid.Parts($0.numbers).read } && runs.contains { !PointsOnGrid.Parts($0.numbers).read })
    }

    /// A test's one try shows the answer after a miss; Show me is a preview.
    func testOneTryAndShowMe() {
        var t = run(5, 3, read: false); t.oneTry = true; t.helps = false; t.skipAsk()
        XCTAssertEqual(move(&t, "x", 3), .notYet("That’s 3 across. The first number, 5, is how far across."))
        XCTAssertEqual(t.typed["x"], "5")
        var m = run(5, 3, read: true); m.skipAsk()
        m.markShown()
        XCTAssertEqual(m.shown, [1]); XCTAssertTrue(m.typed.isEmpty)
        // saved and brought back on the step it was on
        _ = move(&m, "x", 0)
        let back = LessonRun.restored(PointsOnGrid.spec, m.snapshot)
        XCTAssertEqual(back?.index, 2)
    }
}
