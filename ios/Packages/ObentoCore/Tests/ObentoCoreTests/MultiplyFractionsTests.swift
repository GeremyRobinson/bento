import XCTest
@testable import ObentoCore

private func put(_ l: inout LessonRun, _ box: String, _ s: String) {
    l.active = box
    for _ in 0..<8 { l.type("del") }
    for ch in s { l.type(String(ch)) }
}

final class MultiplyFractionsTests: XCTestCase {
    /// The web lesson's reference: 2/3 × 3/4 = 6/12 = 1/2.
    func testWalkThroughTheReference() {
        let n = MultiplyFractions.numbers(a: 2, b: 3, c: 3, d: 4)
        let spec = MultiplyFractions.spec
        XCTAssertEqual(spec.id, "g5-multfrac"); XCTAssertEqual(spec.master, "frac-grid")
        XCTAssertEqual(spec.display(n), [.frac(.num(2), .num(3)), .op("×"), .frac(.num(3), .num(4))])
        XCTAssertEqual(spec.idea(n), "Taking part of a part makes smaller pieces: half of a third is a sixth.")
        XCTAssertEqual(spec.story?(n), "3/4 of a garden is vegetables. 2/3 of the vegetable part is carrots. What part of the whole garden is carrots?")
        XCTAssertEqual(spec.depends, ["g5-fracof", "g4-equiv"])

        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "What is 2/3 × 3/4?")
        XCTAssertEqual(l.words.hint, "That’s 3/4 of 2/3. Look at the grid.")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Multiply straight across.")
        XCTAssertEqual(l.words.hint, "The squares shaded twice are the answer.")
        XCTAssertEqual(l.picture, ["at": 0, "ask": 3])
        XCTAssertEqual(l.step.answer?.boxes, ["n", "d"])
        put(&l, "n", "6")
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        XCTAssertEqual(l.misses, 0)
        put(&l, "n", "8"); put(&l, "d", "9")
        XCTAssertEqual(l.go(), .notYet("Flipping is only for dividing. To multiply, go straight across."))
        put(&l, "n", "5"); put(&l, "d", "7")
        XCTAssertEqual(l.go(), .notYet("Multiply top × top and bottom × bottom."))
        put(&l, "n", "1"); put(&l, "d", "2")
        XCTAssertEqual(l.go(), .notYet("Not quite. Top times top counts the squares in the overlap. Bottom times bottom counts all the squares."),
                       "this step wants the straight-across 6/12, as the web's does")
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(l.showAnswer(), "2 × 3 = 6 on top and 3 × 4 = 12 on the bottom: 6/12.")
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Simplify.")
        XCTAssertEqual(l.words.hint, "Divide the top and the bottom by 6.")
        XCTAssertEqual(l.picture, ["at": 3, "ask": 4])
        XCTAssertEqual(l.step.answer?.hint, "Both 6 and 12 can be divided by 6.")
        put(&l, "n", "1"); put(&l, "d", "0")
        XCTAssertEqual(l.go(), .notYet("The bottom can’t be 0."))
        XCTAssertEqual(l.misses, 0)
        put(&l, "n", "2"); put(&l, "d", "3")
        XCTAssertEqual(l.go(), .notYet("That’s not equal to 6/12. Divide the top and the bottom by the same number."))
        put(&l, "n", "3"); put(&l, "d", "6")
        XCTAssertEqual(l.go(), .notYet("Same amount. 3/6 can still be simplified. Both 3 and 6 divide by 3."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "Divide top and bottom by 6.")
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "2/3 × 3/4 = 1/2.")
        XCTAssertEqual(l.words.hint, "Taking part of a part makes smaller pieces: half of a third is a sixth.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["at": 4])
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[1].answer?.work, [.frac(.num(2), .num(3)), .op("×"), .frac(.num(3), .num(4)), .op("="), .frac(.num(6), .num(12))])
        XCTAssertEqual(l.steps[2].answer?.work, [.frac(.num(6), .num(12)), .op("="), .frac(.num(1), .num(2))])
    }

    func testChecks() {
        let s = MultiplyFractions.spec.steps(MultiplyFractions.numbers(a: 2, b: 3, c: 3, d: 4))
        let across = s[1].answer!.check!, simp = s[2].answer!.check!
        XCTAssertEqual(across(["n": 6, "d": 12]), .right)
        XCTAssertEqual(across(["n": 12, "d": 6]), .wrong("Not quite. Top times top counts the squares in the overlap. Bottom times bottom counts all the squares."))
        XCTAssertEqual(simp(["n": 1, "d": 2]), .right)
        XCTAssertEqual(simp(["n": 2, "d": 4]), .wrong("Same amount. 2/4 can still be simplified. Both 2 and 4 divide by 2."))
        XCTAssertEqual(simp(["n": 6, "d": 12]), .wrong("Same amount. 6/12 can still be simplified. Both 6 and 12 divide by 6."))
        XCTAssertEqual(simp(["n": 2, "d": 1]), .wrong("That’s not equal to 6/12. Divide the top and the bottom by the same number."))
        XCTAssertEqual(simp(["n": 1, "d": 0]), .soft("The bottom can’t be 0."))
    }

    /// The web's area test: 3/4 × 1/4 = 3/16, already simplest.
    func testAlreadySimplest() {
        var l = LessonRun(MultiplyFractions.spec, numbers: MultiplyFractions.numbers(a: 3, b: 4, c: 1, d: 4))
        XCTAssertEqual(l.words.hint, "That’s 1/4 of 3/4. Look at the grid.")
        _ = l.go(); _ = l.showAnswer(); _ = l.go()
        XCTAssertEqual(l.words.hint, "It can’t be made simpler.")
        XCTAssertEqual(l.step.answer?.hint, "No number (other than 1) divides both 3 and 16. It’s already simplest.")
        XCTAssertEqual(l.step.answer?.expected, ["n": 3, "d": 16])
        put(&l, "n", "3"); put(&l, "d", "16")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "3/4 × 1/4 = 3/16.")
        XCTAssertEqual(l.steps[2].answer?.explain, "It was already as simple as it gets.")
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
                XCTAssertEqual(l.steps[2].answer?.expected, ["n": Double(a * c / g), "d": Double(b * d / g)])
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
