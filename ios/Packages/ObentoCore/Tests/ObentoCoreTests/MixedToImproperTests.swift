import XCTest
@testable import ObentoCore

final class MixedToImproperTests: XCTestCase {
    private func fill(_ l: inout LessonRun, _ values: [(String, String)]) {
        l.reset()
        for (box, s) in values { l.active = box; for ch in s { l.type(String(ch)) } }
    }

    func testWalkThroughTheReference() {
        // the web's reference: 2 3/4 = 11/4
        let n = MixedToImproper.numbers(w: 2, n: 3, d: 4)
        var l = LessonRun(MixedToImproper.spec, numbers: n)
        XCTAssertEqual(l.display, [.num(2), .frac(.num(3), .num(4))])
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "What is 2 3/4 as one fraction?")
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Wholes into pieces")
        XCTAssertEqual(l.words.hint, "Each whole is 4 fourths.")
        fill(&l, [("x", "6")])
        XCTAssertEqual(l.go(), .notYet("2 wholes with 4 pieces each: multiply."))
        fill(&l, [("x", "7")])
        XCTAssertEqual(l.go(), .notYet("Not quite. How many pieces are in one whole? Then in all 2 wholes?"))
        XCTAssertEqual(l.showAnswer(), "How many pieces are in one whole? Then in all 2 wholes? That makes 8.")
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Add the extra pieces")
        XCTAssertEqual(l.words.hint, "Add the 3 extra pieces.")
        fill(&l, [("x", "5")])
        XCTAssertEqual(l.go(), .notYet("Use the 8 pieces the wholes make, not the 2."))
        XCTAssertEqual(l.showAnswer(), "Add the 3 extra pieces. That makes 11.")
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "Write the fraction")
        XCTAssertEqual(l.words.hint, "The pieces are still fourths, so the bottom stays 4.")
        fill(&l, [("n", "11")])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        fill(&l, [("n", "11"), ("d", "8")])
        XCTAssertEqual(l.go(), .notYet("The piece size doesn’t change: the bottom stays 4."))
        fill(&l, [("n", "10"), ("d", "4")])
        XCTAssertEqual(l.go(), .notYet("Not quite. The top counts every piece. The bottom says how big each piece is."))
        XCTAssertEqual(l.showAnswer(), "11 pieces, each a 1/4: 11/4.")
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words.say, "2 3/4 = 11/4.")
        XCTAssertEqual(l.words.hint, "Cut every whole into the same pieces, then count all the pieces.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.go(), .newProblem)

        XCTAssertEqual(l.steps[1].answer?.work, [.num(2), .op("×"), .num(4), .op("="), .num(8)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(8), .op("+"), .num(3), .op("="), .num(11)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(2), .frac(.num(3), .num(4)), .op("="), .frac(.num(11), .num(4))])
        XCTAssertEqual(l.steps.map(\.picture), [
            [:], ["focus": 1], ["wholes": 2, "focus": 2], ["wholes": 2, "extra": 1, "focus": 3], ["wholes": 2, "extra": 1, "fraction": 1],
        ])
        XCTAssertEqual(MixedToImproper.spec.idea(n), "Cut every whole into the same pieces, then count all the pieces.")
        XCTAssertEqual(MixedToImproper.spec.master, "tape")
        XCTAssertEqual(MixedToImproper.spec.depends, ["g4-mixed"])
    }

    func testOneWholeAndOneExtraPiece() {
        // 1 1/2: "of it", "1 whole", "1 extra piece", "each a half"
        let l = LessonRun(MixedToImproper.spec, numbers: MixedToImproper.numbers(w: 1, n: 1, d: 2))
        XCTAssertEqual(l.steps[1].answer?.hint, "How many pieces are in one whole? Then in all of it?")
        XCTAssertEqual(l.steps[1].answer?.known.first?.message, "1 whole with 2 pieces each: multiply.")
        XCTAssertEqual(l.steps[2].words.hint, "Add the 1 extra piece.")
        XCTAssertEqual(l.steps[2].answer?.hint, "Add the 1 extra piece.")
        XCTAssertEqual(l.steps[3].answer?.explain, "3 pieces, each a half: 3/2.")
        XCTAssertEqual(l.steps[1].words.hint, "Each whole is 2 halves.")
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 31)
        for index in 0...5 {
            for _ in 0..<300 {
                let n = MixedToImproper.spec.generate(&rng, index), w = Int(n["w"]!), top = Int(n["n"]!), d = Int(n["d"]!)
                let early = index < 3
                XCTAssertTrue((2...(early ? 5 : 9)).contains(d))
                XCTAssertTrue((1...(early ? 2 : 6)).contains(w))
                XCTAssertTrue(top >= 1 && top < d && gcd(top, d) == 1)
                // the web's oracle: the answer is (w·d + n)/d
                let l = LessonRun(MixedToImproper.spec, numbers: n)
                XCTAssertEqual(l.steps[3].answer?.expected, ["n": Double(w * d + top), "d": Double(d)])
            }
        }
    }

    func testSkillCheckDrawsWhatItAsksFor() {
        var rng = SeededRandom(seed: 37)
        let spec = MixedToImproper.spec
        XCTAssertEqual(spec.check.map(\.index), [3, 3, 3, 3])
        for item in spec.check {
            for _ in 0..<300 {
                let n = item.draw(spec, using: &rng)
                XCTAssertTrue(item.when?(n) ?? true)
            }
        }
    }
}
