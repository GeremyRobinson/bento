import XCTest
@testable import ObentoCore

private func put(_ l: inout LessonRun, _ box: String, _ s: String) {
    l.active = box
    for _ in 0..<8 { l.type("del") }
    for ch in s { l.type(String(ch)) }
}

final class DivideByUnitFractionTests: XCTestCase {
    /// The web lesson's reference: 3 ÷ 1/4 = 12.
    func testWalkThroughTheReference() {
        let n = DivideByUnitFraction.numbers(W: 3, d: 4)
        let spec = DivideByUnitFraction.spec
        XCTAssertEqual(spec.id, "g5-unitdiv"); XCTAssertEqual(spec.master, "tape")
        XCTAssertEqual(spec.display(n), [.num(3), .op("÷"), .frac(.num(1), .num(4))])
        XCTAssertEqual(spec.idea(n), "Dividing by a unit fraction asks how many of those pieces fit.")
        XCTAssertEqual(spec.story?(n), "You have 3 cups of flour. Each batch of cookies uses 1/4 cup. How many batches can you make?")
        XCTAssertEqual(spec.depends, ["g3-unitfrac", "g3-facts"])

        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "What is 3 ÷ 1/4?")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "How many 1/4 pieces make 1 whole?")
        XCTAssertEqual(l.words.hint, "Cut one whole into fourths.")
        XCTAssertEqual(l.picture, ["at": 0, "ask": 1])
        XCTAssertEqual(l.step.answer?.prompt, [.box("x")])
        put(&l, "x", "3")
        XCTAssertEqual(l.go(), .notYet("Count the pieces, not the cut lines between them."))
        put(&l, "x", "5")
        XCTAssertEqual(l.go(), .notYet("Not quite. Look at one whole bar and count the pieces in it."))
        XCTAssertEqual(l.showAnswer(), "Look at one whole bar and count the pieces in it. That makes 4.")
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Pieces in all.")
        XCTAssertEqual(l.words.hint, "Every whole holds 4, so count them all.")
        XCTAssertEqual(l.picture, ["at": 1, "ask": 3])
        put(&l, "x", ".75")
        XCTAssertEqual(l.go(), .notYet("The pieces are small, so lots of them fit. The answer is bigger than 3."))
        put(&l, "x", "7")
        XCTAssertEqual(l.go(), .notYet("Not quite. 3 wholes, 4 pieces in each."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "3 wholes, 4 pieces in each. That makes 12.")
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "3 ÷ 1/4 = 12.")
        XCTAssertEqual(l.words.hint, "Dividing by a unit fraction asks how many of those pieces fit.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["at": 3])
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[1].answer?.work, [.num(4)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(3), .op("×"), .num(4), .op("="), .num(12)])
    }

    /// The web's tape test: the last count lands on beat min(W, 3), and the answer step is on it.
    func testTheAnswerStepIsOnTheLastBeat() {
        for (W, d, last) in [(2, 3, 2), (3, 4, 3), (5, 2, 3), (10, 8, 3)] {
            let s = DivideByUnitFraction.spec.steps(DivideByUnitFraction.numbers(W: W, d: d))
            XCTAssertEqual(s[2].picture["ask"], Double(last))
            XCTAssertEqual(s[3].picture["at"], Double(last))
            XCTAssertEqual(s[2].answer?.expected["x"], Double(W * d))
        }
        XCTAssertEqual(DivideByUnitFraction.pieceName(2), "halves")
        XCTAssertEqual(DivideByUnitFraction.pieceName(8), "eighths")
        XCTAssertEqual(DivideByUnitFraction.pieceName(22), "22nds")
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 9)
        for index in [0, 1, 2, 3, 6] {
            for _ in 0..<300 {
                let p = DivideByUnitFraction.spec.generate(&rng, index)
                let W = Int(p["W"]!), d = Int(p["d"]!)
                if index < 3 { XCTAssertTrue((2...4).contains(W) && (2...4).contains(d)) }
                else { XCTAssertTrue((2...10).contains(W) && (2...8).contains(d)) }
                var l = LessonRun(DivideByUnitFraction.spec, numbers: p)
                XCTAssertEqual(l.steps[2].answer?.expected["x"], Double(W * d))
                for _ in 0..<(l.steps.count - 1) { _ = l.showAnswer(); XCTAssertEqual(l.go(), .moved(l.index)) }
                XCTAssertEqual(l.go(), .newProblem)
            }
        }
    }

    func testSkillCheckDrawsKeepTheirRecipe() {
        let spec = DivideByUnitFraction.spec
        XCTAssertEqual(spec.check.map(\.index), [3, 3, 3, 3])
        XCTAssertEqual(spec.check.map(\.story), [false, false, false, true])
        var rng = SeededRandom(seed: 23)
        for item in spec.check {
            for _ in 0..<300 { XCTAssertTrue(item.when?(item.draw(spec, using: &rng)) ?? true) }
        }
    }
}
