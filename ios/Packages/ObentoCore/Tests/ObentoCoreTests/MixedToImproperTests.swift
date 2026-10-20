import XCTest
@testable import ObentoCore

final class MixedToImproperTests: XCTestCase {
    private func fill(_ l: inout LessonRun, _ values: [(String, String)]) {
        l.reset()
        for (box, s) in values { l.active = box; for ch in s { l.type(String(ch)) } }
    }

    /// The cut: how many pieces of the ruler's length make a whole, into the box, checked as the Cut block does.
    private func cut(_ l: inout LessonRun, _ pieces: Int) -> LessonRun.Outcome { l.set("x", Double(pieces)); return l.go() }

    func testWalkThroughTheReference() {
        // the web's reference: 2 3/4 = 11/4
        let n = MixedToImproper.numbers(w: 2, n: 3, d: 4)
        var l = LessonRun(MixedToImproper.spec, numbers: n)
        XCTAssertEqual(l.display, [.num(2), .frac(.num(3), .num(4))])
        XCTAssertEqual(l.steps.count, 4, "ask, cut, write, done: the cut and the count do the web's w × d and + n")
        // the first words never repeat the problem: it's written once, as the bars' names
        XCTAssertEqual(l.words.say, "Look at the bars. How many fourths in all?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: the ruler's pieces into each whole, checked against the extra bar's cuts
        XCTAssertEqual(l.words.say, "Drag the ruler to cut each whole into fourths.")
        XCTAssertEqual(l.words.hint, "Every cut in the 3/4 bar needs a new cut on it.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["ruler"], 1)
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        XCTAssertEqual(cut(&l, 2), .notYet("Some cuts in the 3/4 bar have no new cut on them."))
        XCTAssertEqual(cut(&l, 3), .notYet("Some cuts in the 3/4 bar have no new cut on them."))
        XCTAssertEqual(l.picture["oldCuts"], 1, "a miss rings the old cuts")
        XCTAssertEqual(cut(&l, 8), .notYet("Those fit. Bigger pieces fit too."))
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(l.showAnswer(), "Each whole is 4 fourths, the size of the 3/4 bar’s pieces.")
        l.reset()
        XCTAssertEqual(cut(&l, 4), .moved(2))

        // the record: the top typed, the bottom written for the child
        XCTAssertEqual(l.words.say, "How many fourths in all? Write it.")
        XCTAssertEqual(l.words.hint, "Count the fourths in all the bars.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["n"])
        XCTAssertEqual(l.picture, ["cut": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        // the web's slips, made writing the top: adding the wholes and the bottom, adding the wholes instead of their pieces
        fill(&l, [("n", "9")])
        XCTAssertEqual(l.go(), .notYet("2 wholes with 4 pieces each: multiply."))
        fill(&l, [("n", "5")])
        XCTAssertEqual(l.go(), .notYet("Use the 8 pieces the wholes make, not the 2."))
        fill(&l, [("n", "10")])
        XCTAssertEqual(l.go(), .notYet("Not quite. The top counts every piece. The bottom says how big each piece is."))
        XCTAssertEqual(l.picture["last"], 1, "a miss rings the last piece counted")
        XCTAssertEqual(l.showAnswer(), "11 pieces, each a 1/4: 11/4.")
        XCTAssertEqual(l.go(), .moved(3))

        // the last words say why
        XCTAssertEqual(l.words.say, "Each whole is 4 fourths.")
        XCTAssertEqual(l.words.hint, "Cut every whole into the same pieces, then count all the pieces.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["cut": 1, "done": 1])
        XCTAssertEqual(l.go(), .newProblem)

        // the finished lines: one whole is 4/4; the record 2 3/4 = (2 × 4 + 3)/4 = 11/4
        XCTAssertEqual(l.steps[1].answer?.work, [.num(1), .op("="), .frac(.num(4), .num(4))])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(2), .frac(.num(3), .num(4)), .op("="), .frac(.text("2 × 4 + 3"), .num(4)), .op("="), .frac(.num(11), .num(4))])
        XCTAssertEqual(l.steps.map(\.picture), [[:], ["ruler": 1], ["cut": 1], ["cut": 1, "done": 1]])
        XCTAssertEqual(l.steps.map(\.onMiss), [[:], ["oldCuts": 1], ["last": 1], [:]])
        XCTAssertEqual(MixedToImproper.spec.idea(n), "Cut every whole into the same pieces, then count all the pieces.")
        XCTAssertEqual(MixedToImproper.spec.master, "tape")
        XCTAssertEqual(MixedToImproper.spec.depends, ["g4-mixed"])
        XCTAssertNil(MixedToImproper.spec.story, "the web tells it with no story")
    }

    func testOneWholeAndOneExtraPiece() {
        // 1 1/2, the smallest the generator makes: "1 whole", "halves", "each a half"
        var l = LessonRun(MixedToImproper.spec, numbers: MixedToImproper.numbers(w: 1, n: 1, d: 2))
        XCTAssertEqual(l.steps.map(\.words.say), ["Look at the bars. How many halves in all?", "Drag the ruler to cut each whole into halves.",
                                                  "How many halves in all? Write it.", "Each whole is 2 halves."])
        XCTAssertEqual(l.steps[1].words.hint, "Every cut in the 1/2 bar needs a new cut on it.")
        _ = l.go()
        // halves cut a whole at its middle, the 1/2 bar's one cut; quarters land on it too, but halves fit
        XCTAssertEqual(cut(&l, 3), .notYet("Some cuts in the 1/2 bar have no new cut on them."))
        XCTAssertEqual(cut(&l, 4), .notYet("Those fit. Bigger pieces fit too."))
        XCTAssertEqual(cut(&l, 2), .moved(2))
        fill(&l, [("n", "4")])
        XCTAssertEqual(l.go(), .notYet("1 whole with 2 pieces each: multiply."))
        fill(&l, [("n", "2")])
        XCTAssertEqual(l.go(), .notYet("Use the 2 pieces the wholes make, not the 1."))
        XCTAssertEqual(l.step.answer?.explain, "3 pieces, each a half: 3/2.")
        fill(&l, [("n", "3")])
        XCTAssertEqual(l.go(), .moved(3))
    }

    func testTwoAndAHalfAddsUpLikeItMultiplies() {
        // 2 1/2: 2 + 2 + 1 is 5, and so is 2 × 2 + 1: the right answer is right, never "multiply"
        var l = LessonRun(MixedToImproper.spec, numbers: MixedToImproper.numbers(w: 2, n: 1, d: 2))
        _ = l.go(); _ = cut(&l, 2)
        fill(&l, [("n", "5")])
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "Each whole is 2 halves.")
    }

    func testTheBiggestProblem() {
        // 3 8/9, the most the generator makes: 4 bars, 35 ninths, the whole 45 squares (a ninth is 5)
        XCTAssertEqual(MixedToImproper.maxWholes, 3)
        var l = LessonRun(MixedToImproper.spec, numbers: MixedToImproper.numbers(w: 3, n: 8, d: 9))
        XCTAssertEqual(UnlikeFractions.wholeLength(9), 45)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Drag the ruler to cut each whole into ninths.")
        XCTAssertEqual(cut(&l, 3), .notYet("Some cuts in the 8/9 bar have no new cut on them."))
        XCTAssertEqual(cut(&l, 9), .moved(2))
        fill(&l, [("n", "20")])
        XCTAssertEqual(l.go(), .notYet("3 wholes with 9 pieces each: multiply."))
        fill(&l, [("n", "11")])
        XCTAssertEqual(l.go(), .notYet("Use the 27 pieces the wholes make, not the 3."))
        fill(&l, [("n", "35")])
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "Each whole is 9 ninths.")
    }

    func testTheRulerFitsEveryBottom() {
        // every bottom the lesson has divides its whole (48 for halves, thirds, fourths, sixths, eighths; 40 for fifths;
        // 42 for sevenths; 45 for ninths), each piece a whole number of squares; and Cut at any length the ruler snaps to
        // is right only at the extra bar's pieces, "fits" when its cuts land on every old cut, else a miss
        for d in 2...9 {
            let W = UnlikeFractions.wholeLength(d)
            XCTAssertEqual(W, [2: 48, 3: 48, 4: 48, 5: 40, 6: 48, 7: 42, 8: 48, 9: 45][d], "\(d)")
            XCTAssertEqual(W % d, 0)
            XCTAssertGreaterThanOrEqual(W / d, 5, "a piece holds its number")
            let n = (1..<d).first { gcd($0, d) == 1 }!
            let task = LessonRun(MixedToImproper.spec, numbers: MixedToImproper.numbers(w: 3, n: n, d: d)).steps[1].answer!
            for len in (2...(W / 2)) where W % len == 0 {
                let k = W / len, said = task.check!(["x": Double(k)])
                if k == d { XCTAssertEqual(said, .right) }
                else if k % d == 0 { XCTAssertEqual(said, .wrong("Those fit. Bigger pieces fit too.")) }
                else { XCTAssertEqual(said, .wrong("Some cuts in the \(n)/\(d) bar have no new cut on them.")) }
            }
            XCTAssertEqual(task.check!([:]), .soft("Drag the ruler first."))
        }
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 31)
        var wholes = Set<Int>()
        for index in 0...5 {
            for _ in 0..<300 {
                let n = MixedToImproper.spec.generate(&rng, index), w = Int(n["w"]!), top = Int(n["n"]!), d = Int(n["d"]!)
                let early = index < 3
                XCTAssertTrue((2...(early ? 5 : 9)).contains(d))
                // the web's 1–6 wholes, capped at 3 so every problem's bars fit the screen at full size
                XCTAssertTrue((1...(early ? 2 : 3)).contains(w))
                if !early { wholes.insert(w) }
                XCTAssertTrue(top >= 1 && top < d && gcd(top, d) == 1)
                // the web's oracle: the answer is (w·d + n)/d; the cut is d pieces to a whole
                let l = LessonRun(MixedToImproper.spec, numbers: n)
                XCTAssertEqual(l.steps[1].answer?.expected, ["x": Double(d)])
                XCTAssertEqual(l.steps[2].answer?.expected, ["n": Double(w * d + top)])
            }
        }
        XCTAssertEqual(wholes, [1, 2, 3], "every number of wholes up to the most comes up")
        // every generated problem walks through with Show me on each step
        for index in 0...5 {
            var l = LessonRun.fresh(MixedToImproper.spec, using: &rng, index: index)
            var outcome = l.go()
            while outcome != .newProblem {
                _ = l.showAnswer()
                outcome = l.go()
                if case .notYet(let why) = outcome { XCTFail("\(l.numbers): \(why)"); break }
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
        // the web's item with many wholes (4 or more there) asks for the most the paper draws
        for _ in 0..<100 { XCTAssertEqual(spec.check[2].draw(spec, using: &rng)["w"], 3) }
        for _ in 0..<100 { XCTAssertGreaterThanOrEqual(spec.check[1].draw(spec, using: &rng)["d"] ?? 0, 6) }
    }
}
