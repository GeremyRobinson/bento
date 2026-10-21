import XCTest
@testable import ObentoCore

private func put(_ l: inout LessonRun, _ box: String, _ s: String) {
    l.active = box
    for _ in 0..<8 { l.type("del") }
    for ch in s { l.type(String(ch)) }
}

final class MultiplyFractionsTests: XCTestCase {
    /// A hand move: its box set, checked as Cut or Shade does.
    private func move(_ l: inout LessonRun, _ box: String, _ v: Int) -> LessonRun.Outcome { l.set(box, Double(v)); return l.go() }

    /// The web lesson's reference: 2/3 × 3/4 = 6/12 = 1/2.
    func testWalkThroughTheReference() {
        let n = MultiplyFractions.numbers(a: 2, b: 3, c: 3, d: 4)
        let spec = MultiplyFractions.spec
        XCTAssertEqual(spec.id, "g5-multfrac"); XCTAssertEqual(spec.master, "frac-grid")
        XCTAssertEqual(spec.display(n), [.frac(.num(2), .num(3)), .op("×"), .frac(.num(3), .num(4))])
        XCTAssertEqual(spec.idea(n), "Taking part of a part makes smaller pieces: half of a third is a sixth.")
        XCTAssertEqual(spec.story?(n), "3/4 of a garden is vegetables. 2/3 of the vegetable part is carrots. What part of the whole garden is carrots?")
        XCTAssertEqual(spec.depends, ["g5-fracof", "g4-equiv"])
        XCTAssertEqual(MultiplyFractions.side(b: 3, d: 4), 24)

        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 8, "ask, rows cut, rows shaded, columns cut, columns shaded, across, simplify, done")
        // the first words never repeat the problem: it's written once, as the picture's names
        XCTAssertEqual(l.words.say, "The square is one whole. Take part of it, then part of that part.")
        XCTAssertEqual(l.words.hint, "That’s 3/4 of 2/3. Look at the square.")
        XCTAssertEqual(l.picture, [:])
        XCTAssertEqual(l.go(), .moved(1))

        // the rows: the ruler's cut sets the box
        XCTAssertEqual(l.words.say, "Drag the ruler to cut the square into 3 rows, then cut.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["rulerR": 1])
        XCTAssertEqual(move(&l, "x", 4), .notYet("That makes 4 rows. The bottom says 3."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(move(&l, "x", 3), .moved(2))

        XCTAssertEqual(l.words.say, "Tap 2 rows to shade them.")
        XCTAssertEqual(l.words.action, "Shade")
        XCTAssertEqual(l.picture, ["rows": 1, "tapR": 1])
        XCTAssertEqual(move(&l, "t", 0), .notYet("Tap a row to shade it."))
        XCTAssertEqual(move(&l, "t", 1), .notYet("That’s 1 row. The top says shade 2."))
        XCTAssertEqual(move(&l, "t", 2), .moved(3))

        XCTAssertEqual(l.words.say, "Now drag the ruler to cut it into 4 columns, then cut.")
        XCTAssertEqual(l.picture, ["rows": 1, "shR": 1, "rulerC": 1])
        XCTAssertEqual(move(&l, "x", 6), .notYet("That makes 6 columns. The bottom says 4."))
        XCTAssertEqual(move(&l, "x", 4), .moved(4))

        XCTAssertEqual(l.words.say, "Tap 3 columns to shade them.")
        XCTAssertEqual(move(&l, "t", 4), .notYet("That’s 4 columns. The top says shade 3."))
        XCTAssertEqual(move(&l, "t", 3), .moved(5))

        // the record: typed, with the web's slips
        XCTAssertEqual(l.words.say, "Count the pieces shaded twice, and all the pieces. Write them.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.picture, ["rows": 1, "shR": 1, "cols": 1, "shC": 1])
        XCTAssertEqual(l.step.answer?.boxes, ["n", "d"])
        put(&l, "n", "6")
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        let misses = l.misses
        put(&l, "n", "8"); put(&l, "d", "9")
        XCTAssertEqual(l.go(), .notYet("Flipping is only for dividing. To multiply, go straight across."))
        put(&l, "n", "5"); put(&l, "d", "7")
        XCTAssertEqual(l.go(), .notYet("Multiply top × top and bottom × bottom."))
        put(&l, "n", "1"); put(&l, "d", "2")
        XCTAssertEqual(l.go(), .notYet("Not quite. Top times top counts the pieces shaded twice. Bottom times bottom counts all the pieces."),
                       "this step wants the straight-across 6/12, as the web's does")
        XCTAssertEqual(l.misses, misses + 3)
        XCTAssertEqual(l.showAnswer(), "2 × 3 = 6 on top and 3 × 4 = 12 on the bottom: 6/12.")
        XCTAssertEqual(l.go(), .moved(6))

        XCTAssertEqual(l.words.say, "Write it as simply as you can.")
        XCTAssertEqual(l.words.hint, "Divide the top and the bottom by 6.")
        XCTAssertEqual(l.picture["simp"], 1)
        XCTAssertEqual(l.step.answer?.hint, "Both 6 and 12 can be divided by 6.")
        put(&l, "n", "1"); put(&l, "d", "0")
        XCTAssertEqual(l.go(), .notYet("The bottom can’t be 0."))
        put(&l, "n", "2"); put(&l, "d", "3")
        XCTAssertEqual(l.go(), .notYet("That’s not equal to 6/12. Divide the top and the bottom by the same number."))
        put(&l, "n", "3"); put(&l, "d", "6")
        XCTAssertEqual(l.go(), .notYet("Same amount. 3/6 can still be simplified. Both 3 and 6 divide by 3."))
        XCTAssertEqual(l.showAnswer(), "Divide top and bottom by 6.")
        XCTAssertEqual(l.go(), .moved(7))

        // the last words say why
        XCTAssertEqual(l.words.say, "6 of the 12 pieces are shaded twice.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture["done"], 1)
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[5].answer?.work, [.frac(.num(2), .num(3)), .op("×"), .frac(.num(3), .num(4)), .op("="), .frac(.num(6), .num(12))])
        XCTAssertEqual(l.steps[6].answer?.work, [.frac(.num(6), .num(12)), .op("="), .frac(.num(1), .num(2))])
    }

    /// Pointless steps are dropped: a top of 1 is shaded with its cut, and a fraction already simplest isn't simplified.
    func testPointlessStepsDropped() {
        // 1/2 × 1/3 = 1/6: no shading taps, no simplify
        var l = LessonRun(MultiplyFractions.spec, numbers: MultiplyFractions.numbers(a: 1, b: 2, c: 1, d: 3))
        XCTAssertEqual(l.steps.count, 5, "ask, rows cut, columns cut, across, done")
        XCTAssertEqual(l.steps[2].picture, ["rows": 1, "shR": 1, "rulerC": 1])
        _ = l.go(); _ = l.showAnswer(); _ = l.go(); _ = l.showAnswer(); _ = l.go()
        XCTAssertEqual(l.step.answer?.expected, ["n": 1, "d": 6])
        put(&l, "n", "1"); put(&l, "d", "6")
        XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.say, "1 of the 6 pieces is shaded twice.")
        XCTAssertEqual(l.picture["simp"], nil)
    }

    /// The square: a multiple of both bottoms, at least 24 squares a side.
    func testSide() {
        for b in 2...9 { for d in 2...9 {
            let s = MultiplyFractions.side(b: b, d: d)
            XCTAssertEqual(s % b, 0); XCTAssertEqual(s % d, 0); XCTAssertGreaterThanOrEqual(s, 24)
            XCTAssertLessThan(s - UnlikeFractions.lcm(b, d), 24)
        } }
        XCTAssertEqual(MultiplyFractions.side(b: 8, d: 9), 72)
        XCTAssertEqual(MultiplyFractions.side(b: 5, d: 2), 30)
    }

    func testChecks() {
        let s = MultiplyFractions.spec.steps(MultiplyFractions.numbers(a: 2, b: 3, c: 3, d: 4))
        let across = s[5].answer!.check!, simp = s[6].answer!.check!
        XCTAssertEqual(across(["n": 6, "d": 12]), .right)
        XCTAssertEqual(across(["n": 12, "d": 6]), .wrong("Not quite. Top times top counts the pieces shaded twice. Bottom times bottom counts all the pieces."))
        XCTAssertEqual(simp(["n": 1, "d": 2]), .right)
        XCTAssertEqual(simp(["n": 2, "d": 4]), .wrong("Same amount. 2/4 can still be simplified. Both 2 and 4 divide by 2."))
        XCTAssertEqual(simp(["n": 6, "d": 12]), .wrong("Same amount. 6/12 can still be simplified. Both 6 and 12 divide by 6."))
        XCTAssertEqual(simp(["n": 2, "d": 1]), .wrong("That’s not equal to 6/12. Divide the top and the bottom by the same number."))
        XCTAssertEqual(simp(["n": 1, "d": 0]), .soft("The bottom can’t be 0."))
    }

    /// The web's area test: 3/4 × 1/4 = 3/16, already simplest, so it isn't simplified.
    func testAlreadySimplest() {
        var l = LessonRun(MultiplyFractions.spec, numbers: MultiplyFractions.numbers(a: 3, b: 4, c: 1, d: 4))
        XCTAssertEqual(l.words.hint, "That’s 1/4 of 3/4. Look at the square.")
        XCTAssertEqual(l.steps.count, 6, "ask, rows cut, rows shaded, columns cut, across, done")
        for _ in 0..<4 { _ = l.showAnswer(); _ = l.go() }
        XCTAssertEqual(l.step.answer?.expected, ["n": 3, "d": 16])
        put(&l, "n", "3"); put(&l, "d", "16")
        XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(l.words.say, "3 of the 16 pieces are shaded twice.")
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 8)
        for index in [0, 1, 2, 3, 6] {
            for _ in 0..<300 {
                let p = MultiplyFractions.spec.generate(&rng, index)
                let a = Int(p["a"]!), b = Int(p["b"]!), c = Int(p["c"]!), d = Int(p["d"]!)
                let most = index < 3 ? 5 : 9
                XCTAssertTrue((2...most).contains(b) && (2...most).contains(d))
                XCTAssertTrue((1..<b).contains(a) && (1..<d).contains(c))
                XCTAssertEqual(gcd(a, b), 1); XCTAssertEqual(gcd(c, d), 1)
                // the web oracle: a·c over b·d in lowest terms (never whole, since both are below 1)
                let g = gcd(a * c, b * d)
                var l = LessonRun(MultiplyFractions.spec, numbers: p)
                // the last typed step wants the simplest form; it's simplified only when it can be
                XCTAssertEqual(l.steps[l.steps.count - 2].answer?.expected, ["n": Double(a * c / g), "d": Double(b * d / g)])
                XCTAssertEqual(l.steps.count, 5 + (a > 1 ? 1 : 0) + (c > 1 ? 1 : 0) + (g > 1 ? 1 : 0))
                XCTAssertLessThan(a * c, b * d)
                for _ in 0..<(l.steps.count - 1) { _ = l.showAnswer(); XCTAssertEqual(l.go(), .moved(l.index)) }
                XCTAssertEqual(l.go(), .newProblem)
            }
        }
    }

    func testSkillCheckDrawsKeepTheirRecipe() {
        let spec = MultiplyFractions.spec
        XCTAssertEqual(spec.check.map(\.index), [3, 3, 3, 3])
        XCTAssertEqual(spec.check.map(\.story), [false, false, false, true])
        var rng = SeededRandom(seed: 22)
        for item in spec.check {
            for _ in 0..<300 {
                let p = item.draw(spec, using: &rng)
                XCTAssertTrue(item.when?(p) ?? true)
            }
        }
        // the first simplifies, the second doesn't
        let p0 = MultiplyFractions.numbers(a: 2, b: 3, c: 3, d: 4), p1 = MultiplyFractions.numbers(a: 3, b: 4, c: 1, d: 4)
        XCTAssertEqual([spec.check[0].when!(p0), spec.check[0].when!(p1), spec.check[1].when!(p0), spec.check[1].when!(p1)], [true, false, false, true])
    }
}
