import XCTest
@testable import ObentoCore

private func put(_ l: inout LessonRun, _ box: String, _ s: String) {
    l.active = box
    for _ in 0..<8 { l.type("del") }
    for ch in s { l.type(String(ch)) }
}

final class FractionOfTests: XCTestCase {
    /// The web lesson's reference: 3/4 of 20 = 15.
    func testWalkThroughTheReference() {
        let n = FractionOf.numbers(n: 3, d: 4, W: 20)
        let spec = FractionOf.spec
        XCTAssertEqual(spec.id, "g5-fracof"); XCTAssertEqual(spec.master, "tape")
        XCTAssertEqual(spec.display(n), [.frac(.num(3), .num(4)), .text("of"), .num(20)])
        XCTAssertEqual(spec.idea(n), "The bottom says how many equal groups to make, and the top says how many to take.")
        XCTAssertEqual(spec.story?(n), "There are 20 marbles in a bag. 3/4 of them are blue. How many marbles are blue?")
        XCTAssertEqual(spec.depends, ["g3-divfacts", "g4-fracwhole"])

        var l = LessonRun(spec, numbers: n)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "What is 3/4 of 20?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Split into equal groups.")
        XCTAssertEqual(l.words.hint, "The bottom says 4 equal groups.")
        XCTAssertEqual(l.picture, ["at": 0, "ask": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        put(&l, "x", "80")
        XCTAssertEqual(l.go(), .notYet("Split 20 into 4 equal groups: divide."))
        put(&l, "x", "6")
        XCTAssertEqual(l.go(), .notYet("Not quite. The bottom number tells how many equal groups: 4."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "The bottom number tells how many equal groups: 4. That makes 5.")
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Take that many groups.")
        XCTAssertEqual(l.words.hint, "The top says take 3 of them.")
        XCTAssertEqual(l.picture, ["at": 1, "ask": 2])
        put(&l, "x", "8")
        XCTAssertEqual(l.go(), .notYet("Take 3 groups of 5: that’s multiplying."))
        put(&l, "x", "5")
        XCTAssertEqual(l.go(), .notYet("That’s the groups left over. The top says to take 3 groups."))
        XCTAssertEqual(l.showAnswer(), "The top number tells how many groups to take: 3. That makes 15.")
        put(&l, "x", "15")
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "3/4 of 20 is 15.")
        XCTAssertEqual(l.words.hint, "The bottom says how many equal groups to make, and the top says how many to take.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["at": 2])
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[1].answer?.work, [.num(20), .op("÷"), .num(4), .op("="), .num(5)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(5), .op("×"), .num(3), .op("="), .num(15)])
    }

    func testOneGroupReadsRight() {
        let l = LessonRun(FractionOf.spec, numbers: FractionOf.numbers(n: 1, d: 3, W: 12))
        XCTAssertEqual(l.steps[2].answer?.known.map(\.message), ["Take 1 group of 4: that’s multiplying.", "That’s the groups left over. The top says to take 1 group."])
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 5)
        for index in [0, 1, 2, 3, 7] {
            for _ in 0..<300 {
                let p = FractionOf.spec.generate(&rng, index)
                let n = Int(p["n"]!), d = Int(p["d"]!), W = Int(p["W"]!)
                XCTAssertEqual(W % d, 0)
                if index < 3 {
                    XCTAssertEqual(n, 1); XCTAssertTrue((2...5).contains(d)); XCTAssertTrue((2...6).contains(W / d))
                } else {
                    XCTAssertTrue((2...9).contains(d)); XCTAssertTrue((1..<d).contains(n)); XCTAssertEqual(gcd(n, d), 1)
                    XCTAssertTrue((2...12).contains(W / d))
                }
                // the answer is the web oracle's, and Show me on every step gets through the lesson
                var l = LessonRun(FractionOf.spec, numbers: p)
                XCTAssertEqual(l.steps[2].answer?.expected["x"], Double(W * n / d))
                for _ in 0..<(l.steps.count - 1) { _ = l.showAnswer(); XCTAssertEqual(l.go(), .moved(l.index)) }
                XCTAssertEqual(l.go(), .newProblem)
            }
        }
    }

    func testSkillCheckDrawsKeepTheirRecipe() {
        let spec = FractionOf.spec
        XCTAssertEqual(spec.check.map(\.index), [3, 3, 3, 3])
        XCTAssertEqual(spec.check.map(\.story), [false, false, false, true])
        var rng = SeededRandom(seed: 21)
        for item in spec.check {
            for _ in 0..<300 {
                let p = item.draw(spec, using: &rng)
                XCTAssertTrue(item.when?(p) ?? true)
            }
        }
    }
}
