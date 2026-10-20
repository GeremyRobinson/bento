import XCTest
@testable import ObentoCore

final class UnlikeFractionsTests: XCTestCase {
    /// Clears the step, then types each box's value in turn.
    private func fill(_ l: inout LessonRun, _ values: [(String, String)]) {
        l.reset()
        for (box, s) in values { l.active = box; for ch in s { l.type(String(ch)) } }
    }

    /// The cut: the ruler's piece count into the bottom's box, checked as the Cut block does.
    private func cut(_ l: inout LessonRun, _ pieces: Int) -> LessonRun.Outcome { l.set("x", Double(pieces)); return l.go() }
    /// What the cut answers after the bottom: each rewrite's top, set from the cut (the bars counted).
    private func rewrites(_ l: inout LessonRun) {
        while l.handAnswered, l.step.answer?.boxes == ["x"], let v = l.step.answer?.expected["x"] { l.set("x", v); _ = l.go() }
    }
    /// The slide: dropped in the top bar.
    private func slide(_ l: inout LessonRun) -> LessonRun.Outcome { l.set("s", 1); return l.go() }

    func testAddWalkThroughTheTestPage() {
        // the test page's: 1/4 + 1/6 = 3/12 + 2/12 = 5/12
        let n = UnlikeFractions.numbers(a: 1, b: 4, c: 1, d: 6, minus: false)
        XCTAssertEqual(n["L"], 12); XCTAssertEqual(n["A"], 3); XCTAssertEqual(n["C"], 2); XCTAssertEqual(n["S"], 5)
        XCTAssertEqual(UnlikeFractions.wholeLength(12), 48, "the test page's whole: 48 squares, every piece a whole number of them")
        var l = LessonRun(AddingFractions.spec, numbers: n)
        XCTAssertEqual(l.display, [.frac(.num(1), .num(4)), .op("+"), .frac(.num(1), .num(6))])
        XCTAssertEqual(l.steps.count, 7, "ask, cut, both rewrites, slide, write, done: 5/12 is already simplest")
        XCTAssertEqual(l.words.say, "Look at the bars. Are the pieces the same size?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: a ruler size that doesn't fit, one that fits but is too small, then the right one
        XCTAssertEqual(l.words.say, "Drag the ruler to cut both bars into the same size pieces.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["ruler"], 1)
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        XCTAssertEqual(cut(&l, 9), .notYet("Some old cuts have no new cut on them."))
        XCTAssertEqual(cut(&l, 6), .notYet("Some old cuts have no new cut on them."))
        XCTAssertEqual(cut(&l, 18), .notYet("Some old cuts have no new cut on them."))
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(l.showAnswer(), "Counting by 6s, the first number 4 also goes into is 12: twelfths fit both bars.")
        l.reset()
        // 24ths fit too, but bigger pieces do
        XCTAssertEqual(cut(&l, 24), .notYet("Those fit both bars. Bigger pieces fit too."))
        XCTAssertEqual(cut(&l, 12), .moved(2))

        // the rewrites are answered by the cut: the bars counted
        XCTAssertEqual(l.words.say, "How many twelfths is one fourth?")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["cut"], 1)
        rewrites(&l)
        XCTAssertEqual(l.index, 4)

        // the slide: dropped elsewhere is a notice, not a miss
        XCTAssertEqual(l.words.say, "Slide the striped twelfths into the top bar.")
        XCTAssertEqual(l.picture["slide"], 1)
        l.set("s", 0)
        XCTAssertEqual(l.go(), .notYet("They went back. Drop them on the top bar."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(slide(&l), .moved(5))

        // the record, typed: the answer's bottom is given, only the top is written
        XCTAssertEqual(l.words.say, "How many twelfths in all? Write it.")
        XCTAssertEqual(l.words.hint, "Count the twelfths in the top bar.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["n"])
        XCTAssertEqual(l.picture["slid"], 1)
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        fill(&l, [("n", "2")])
        XCTAssertEqual(l.go(), .notYet("That adds the old tops. Count the twelfths in the top bar."))
        fill(&l, [("n", "1")])
        XCTAssertEqual(l.go(), .notYet("You subtracted. Look at the sign: this one is a plus."))
        fill(&l, [("n", "4")])
        XCTAssertEqual(l.go(), .notYet("Check the top: 3 + 2 = ?"))
        XCTAssertEqual(l.showAnswer(), "3 + 2 = 5, and the bottom stays 12.")
        XCTAssertEqual(l.go(), .moved(6))

        XCTAssertEqual(l.words.say, "Same-size pieces, so the tops add.")
        XCTAssertEqual(l.words.hint, "The bottom is the size of the pieces, and only same-size pieces can be added.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["cut": 1, "slid": 1, "sum": 1, "answer": 0])
        XCTAssertEqual(l.go(), .newProblem)

        // the finished lines (the record writes them)
        XCTAssertEqual(l.steps[2].answer?.work, [.frac(.num(1), .num(4)), .op("="), .frac(.num(3), .num(12))])
        XCTAssertEqual(l.steps[3].answer?.work, [.frac(.num(1), .num(6)), .op("="), .frac(.num(2), .num(12))])
        XCTAssertEqual(l.steps[5].answer?.work, [.frac(.num(3), .num(12)), .op("+"), .frac(.num(2), .num(12)), .op("="), .frac(.num(5), .num(12))])
        XCTAssertEqual(l.steps.map(\.picture), [
            [:], ["ruler": 1], ["cut": 1], ["cut": 1], ["cut": 1, "slide": 1], ["cut": 1, "slid": 1],
            ["cut": 1, "slid": 1, "sum": 1, "answer": 0],
        ])
        XCTAssertEqual(AddingFractions.spec.story?(n), "You walked 1/4 of a mile to the park and then 1/6 of a mile to the store. How far did you walk in all?")
        XCTAssertEqual(AddingFractions.spec.idea(n), "The bottom is the size of the pieces, and only same-size pieces can be added.")
        XCTAssertEqual(AddingFractions.spec.master, "tape")
    }

    func testTheRewritesKeepTheirSlips() {
        // set from the cut they're always right, but Core still knows a typed rewrite's slips
        var l = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 1, b: 2, c: 1, d: 3, minus: false))
        _ = l.go(); _ = cut(&l, 6)
        XCTAssertEqual(l.words.say, "How many sixths is one half?")
        XCTAssertEqual(l.words.hint, "Each half is 3 sixths.")
        fill(&l, [("x", "1")])
        XCTAssertEqual(l.go(), .notYet("You changed the bottom from 2 to 6, but kept the top as 1. Whatever you multiply the bottom by, multiply the top by the same number."))
        fill(&l, [("x", "5")])
        XCTAssertEqual(l.go(), .notYet("You added 4 to the top because the bottom went up by 4. A fraction stays the same only when you multiply top and bottom by the same number. What times 2 makes 6?"))
        fill(&l, [("x", "2")])
        XCTAssertEqual(l.go(), .notYet("2 × ? = 6. Then multiply the top, 1, by that number."))
        XCTAssertEqual(l.showAnswer(), "2 × 3 = 6, so 1 × 3 = 3.")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "How many sixths is one third?")
        XCTAssertEqual(l.step.answer?.hint, "3 × ? = 6. Whatever you multiply the bottom by, do the same to the top.")
    }

    func testSubWalkThroughTheReference() {
        // 1/2 − 1/6 = 3/6 − 1/6 = 2/6 = 1/3: the second fraction is already over 6, so only the first is rewritten
        let n = UnlikeFractions.numbers(a: 1, b: 2, c: 1, d: 6, minus: true)
        XCTAssertEqual(UnlikeFractions.wholeLength(6), 48)
        var l = LessonRun(SubtractingFractions.spec, numbers: n)
        XCTAssertEqual(l.display, [.frac(.num(1), .num(2)), .op("−"), .frac(.num(1), .num(6))])
        XCTAssertEqual(l.steps.map(\.words.say), ["Look at the bars. Are the pieces the same size?", "Drag the ruler to cut both bars into the same size pieces.",
                                                  "How many sixths is one half?", "Slide the striped sixths over the shaded ones.",
                                                  "How many sixths are left? Write it.", "Write it as simply as you can.", "Same-size pieces, so the tops are taken away."])
        _ = l.go()
        XCTAssertEqual(cut(&l, 12), .notYet("Those fit both bars. Bigger pieces fit too."))
        XCTAssertEqual(cut(&l, 6), .moved(2)); rewrites(&l)
        XCTAssertEqual(l.words.hint, "Drag the striped pieces up onto the shaded pieces.")
        XCTAssertEqual(slide(&l), .moved(4))
        XCTAssertEqual(l.words.hint, "Count the shaded sixths that aren’t crossed out.")
        fill(&l, [("n", "4")])
        XCTAssertEqual(l.go(), .notYet("You added 3 + 1. Look at the sign: this one is a minus."))
        XCTAssertEqual(l.step.answer?.hint, "The pieces are the same size now, so only the tops get taken away. Does the size of a piece change?")
        XCTAssertEqual(l.showAnswer(), "3 − 1 = 2, and the bottom stays 6.")
        XCTAssertEqual(l.go(), .moved(5))
        // simplify: the slips the web has
        XCTAssertEqual(l.words.hint, "Divide the top and the bottom by 2.")
        XCTAssertEqual(l.step.answer?.hint, "Both 2 and 6 can be divided by 2.")
        XCTAssertEqual(l.step.answer?.explain, "Divide top and bottom by 2.")
        XCTAssertEqual(l.step.answer?.expected, ["n": 1, "d": 3])
        fill(&l, [("n", "2"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("Same amount. 2/6 can still be simplified. Both 2 and 6 divide by 2."))
        fill(&l, [("n", "4"), ("d", "6")])
        XCTAssertEqual(l.go(), .notYet("That’s not equal to 2/6. Divide the top and the bottom by the same number."))
        fill(&l, [("n", "1"), ("d", "3")])
        XCTAssertEqual(l.go(), .moved(6))
        XCTAssertEqual(l.words.say, "Same-size pieces, so the tops are taken away.")
        XCTAssertEqual(l.words.hint, "Only same-size pieces can be taken away, so the bottoms have to match first.")
        XCTAssertEqual(l.picture["answer"], 1)
        XCTAssertEqual(SubtractingFractions.spec.story?(n), "There was 1/2 of a cake left. The family ate 1/6 of a cake. How much cake is left now?")
    }

    func testMixWalkThroughTheReference() {
        // 2/3 + 1/4 = 8/12 + 3/12 = 11/12, then a take-away: the slide's words name what to do
        let n = UnlikeFractions.numbers(a: 2, b: 3, c: 1, d: 4, minus: false)
        var l = LessonRun(AddAndSubtract.spec, numbers: n)
        XCTAssertEqual(l.words.say, "Look at the bars. Are the pieces the same size?")
        _ = l.go()
        XCTAssertEqual(cut(&l, 24), .notYet("Those fit both bars. Bigger pieces fit too."))
        XCTAssertEqual(cut(&l, 6), .notYet("Some old cuts have no new cut on them."))
        XCTAssertEqual(cut(&l, 12), .moved(2)); rewrites(&l)
        XCTAssertEqual(l.words.say, "Slide the striped twelfths in to add.")
        _ = slide(&l)
        fill(&l, [("n", "5")])
        XCTAssertEqual(l.go(), .notYet("You subtracted. Look at the sign: this one is a plus."))
        fill(&l, [("n", "11")]); _ = l.go()
        XCTAssertEqual(l.words.say, "Same-size pieces, so the tops add.")
        XCTAssertEqual(l.words.hint, "Adding and taking away both need same-size pieces, so the first steps never change.")
        let m = LessonRun(AddAndSubtract.spec, numbers: UnlikeFractions.numbers(a: 2, b: 3, c: 1, d: 4, minus: true))
        XCTAssertEqual(m.steps[4].words.say, "Slide the striped twelfths over to take away.")
        XCTAssertEqual(AddAndSubtract.spec.story?(n), "A plant grew 2/3 inch in May and 1/4 inch in June. How much did it grow in all?")
        XCTAssertEqual(AddAndSubtract.spec.story?(UnlikeFractions.numbers(a: 2, b: 3, c: 1, d: 4, minus: true)),
                       "A jug had 2/3 gallon of water. You poured out 1/4 gallon. How much is left?")
    }

    func testSimplifyMixedAndReducible() {
        // 3/4 + 5/6 = 9/12 + 10/12 = 19/12 = 1 7/12: more than a whole spills into a second bar
        var m = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 3, b: 4, c: 5, d: 6, minus: false))
        _ = m.go(); _ = cut(&m, 12); rewrites(&m); _ = slide(&m)
        XCTAssertEqual(m.words.hint, "Count the twelfths in both bars.")
        fill(&m, [("n", "8")])
        XCTAssertEqual(m.go(), .notYet("That adds the old tops. Count the twelfths in both bars."))
        fill(&m, [("n", "19")]); _ = m.go()
        let s = m.step
        XCTAssertEqual(s.words.hint, "Every 12 pieces make one whole.")
        XCTAssertEqual(s.answer?.boxes, ["w", "n", "d"])
        XCTAssertEqual(s.answer?.hint, "19 ÷ 12 = 1 remainder 7. The remainder goes on top.")
        XCTAssertEqual(s.answer?.explain, "19 ÷ 12 = 1 remainder 7, then simplify.")
        XCTAssertEqual(s.answer?.work, [.frac(.num(19), .num(12)), .op("="), .num(1), .frac(.num(7), .num(12))])
        XCTAssertEqual(s.picture, ["cut": 1, "slid": 1, "sum": 1])
        let check = s.answer!.check!
        XCTAssertEqual(check(["w": 1, "n": 7, "d": 12]), .right)
        XCTAssertEqual(check(["w": 0, "n": 19, "d": 12]), .soft("That’s the right amount. Now write it as a mixed number. How many whole 12s fit into 19?"))
        XCTAssertEqual(check(["w": 1, "n": 14, "d": 24]), .wrong("Same amount. 14/24 can still be simplified. Both 14 and 24 divide by 2."))
        XCTAssertEqual(check(["w": 1, "n": 5, "d": 12]), .wrong("That’s not equal to 19/12. How many whole 12s fit into 19? That’s the whole number. What’s left over goes on top."))
        XCTAssertEqual(check(["w": 1, "n": 7, "d": 0]), .soft("The bottom can’t be 0."))
        XCTAssertEqual(check(["w": 1, "n": 7]), .soft("Fill in the bottom number too."))
        XCTAssertEqual(m.steps.last?.words.say, "Same-size pieces, so the tops add.")
        XCTAssertEqual(m.steps.last?.picture["answer"], 1)

        // the first fraction already over L: 3/8 + 1/2 asks only for the cut, the second rewrite, the slide and the sum
        let e = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 3, b: 8, c: 1, d: 2, minus: false))
        XCTAssertEqual(e.steps.map(\.words.say), ["Look at the bars. Are the pieces the same size?", "Drag the ruler to cut both bars into the same size pieces.",
                                                  "How many eighths is one half?", "Slide the striped eighths into the top bar.",
                                                  "How many eighths in all? Write it.", "Same-size pieces, so the tops add."])
        XCTAssertEqual(UnlikeFractions.wholeLength(8), 48)
        // simplifies: 1/6 + 1/3 = 1/6 + 2/6 = 3/6 = 1/2
        let f = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 1, b: 6, c: 1, d: 3, minus: false))
        XCTAssertEqual(f.steps.count, 7, "ask, cut, one rewrite, slide, write, simplify, done")
        XCTAssertEqual(f.steps[5].answer?.expected, ["n": 1, "d": 2])
    }

    func testEveryWholeFitsItsPieces() {
        // every bottom a problem can have divides its whole, and every piece is at least 2 squares
        for b in 2...12 { for d in 2...12 where b != d {
            let L = b * d / gcd(b, d)
            guard L <= 24 else { continue }
            let W = UnlikeFractions.wholeLength(L)
            XCTAssertTrue([36, 40, 42, 44, 45, 48].contains(W), "\(b), \(d)")
            XCTAssertEqual(W % L, 0, "\(b), \(d)")
            XCTAssertGreaterThanOrEqual(W / L, 2, "\(b), \(d)")
        } }
        XCTAssertEqual(UnlikeFractions.wholeLength(24), 48)
        XCTAssertEqual(UnlikeFractions.wholeLength(12), 48)
        XCTAssertEqual(UnlikeFractions.wholeLength(18), 36)
        XCTAssertEqual(UnlikeFractions.wholeLength(20), 40)
        XCTAssertEqual(UnlikeFractions.wholeLength(10), 40)
        XCTAssertEqual(UnlikeFractions.wholeLength(14), 42)
        XCTAssertEqual(UnlikeFractions.wholeLength(15), 45)
        XCTAssertEqual(UnlikeFractions.wholeLength(22), 44)
    }

    func testWebPictureNumbers() {
        // the web's tape test: 3/4 − 1/6 has L 12, A 9, C 2, S 7
        let n = UnlikeFractions.numbers(a: 3, b: 4, c: 1, d: 6, minus: true)
        XCTAssertEqual(n["L"], 12); XCTAssertEqual(n["A"], 9); XCTAssertEqual(n["C"], 2); XCTAssertEqual(n["S"], 7)
        XCTAssertEqual(UnlikeFractions.mixedLabel(19, 12), "1 7/12")
        XCTAssertEqual(UnlikeFractions.mixedLabel(4, 6), "2/3")
        XCTAssertEqual(UnlikeFractions.pieceName(22), "twenty-seconds")
        XCTAssertEqual(UnlikeFractions.pieceName(21, false), "twenty-first")
    }

    private func checkInvariants(_ n: Numbers, index: Int, minus: Bool) {
        let a = Int(n["a"]!), b = Int(n["b"]!), c = Int(n["c"]!), d = Int(n["d"]!)
        let L = Int(n["L"]!), A = Int(n["A"]!), C = Int(n["C"]!), S = Int(n["S"]!)
        XCTAssertTrue((2...12).contains(b) && (2...12).contains(d) && b != d)
        XCTAssertTrue(L <= 24 && L % b == 0 && L % d == 0 && L == b * d / gcd(b, d))
        XCTAssertTrue(a >= 1 && a < b && c >= 1 && c < d && gcd(a, b) == 1 && gcd(c, d) == 1)
        XCTAssertEqual(A, a * L / b); XCTAssertEqual(C, c * L / d)
        XCTAssertEqual(n["minus"], minus ? 1 : 0)
        XCTAssertEqual(S, minus ? A - C : A + C)
        XCTAssertGreaterThan(S, 0)
        if index == 0 { XCTAssertTrue(b % d == 0 || d % b == 0, "the first problem is the easy kind") }
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 17)
        for index in 0...5 {
            for _ in 0..<300 {
                checkInvariants(AddingFractions.spec.generate(&rng, index), index: index, minus: false)
                checkInvariants(SubtractingFractions.spec.generate(&rng, index), index: index, minus: true)
                checkInvariants(AddAndSubtract.spec.generate(&rng, index), index: index, minus: index % 2 == 1)
            }
        }
        // every generated problem walks through with Show me on each step
        for index in 0...5 {
            for spec in [AddingFractions.spec, SubtractingFractions.spec, AddAndSubtract.spec] {
                var l = LessonRun.fresh(spec, using: &rng, index: index)
                var outcome = l.go()
                while outcome != .newProblem {
                    _ = l.showAnswer()
                    outcome = l.go()
                    if case .notYet(let why) = outcome { XCTFail("\(spec.id) \(l.numbers): \(why)"); break }
                }
            }
        }
    }

    func testEachHandStepLightsAHintOnTheBars() {
        // a miss (or the bar's Hint) lights a drawing on the bars, not just words: the old cuts ringed on the cut, where
        // the pieces go on the slide, the last piece counted on the sum, the bigger pieces on the simplify
        let l = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 1, b: 6, c: 1, d: 3, minus: false))
        let byWords = Dictionary(l.steps.map { ($0.words.say, $0.onMiss) }, uniquingKeysWith: { a, _ in a })
        XCTAssertEqual(byWords["Drag the ruler to cut both bars into the same size pieces."], ["oldCuts": 1])
        XCTAssertEqual(byWords["Slide the striped sixths into the top bar."], ["target": 1])
        XCTAssertEqual(byWords["How many sixths in all? Write it."], ["last": 1])
        XCTAssertEqual(byWords["Write it as simply as you can."], ["simple": 1])
        var r = LessonRun(AddingFractions.spec, numbers: UnlikeFractions.numbers(a: 1, b: 6, c: 1, d: 3, minus: false))
        _ = r.go()
        XCTAssertNil(r.picture["oldCuts"], "nothing lit before a miss")
        r.set("x", 3); _ = r.go()
        XCTAssertEqual(r.picture["oldCuts"], 1, "lit after a miss")
    }

    func testSkillChecksDrawWhatTheyAskFor() {
        var rng = SeededRandom(seed: 23)
        for spec in [AddingFractions.spec, SubtractingFractions.spec, AddAndSubtract.spec] {
            XCTAssertEqual(spec.check.count, 4)
            for (k, item) in spec.check.enumerated() {
                // like the web (check-kit: up to 50 redraws, then the last draw stands), a rare item can miss its
                // condition; "the answer simplifies" holds for only about 1 problem in 10, so allow a few in 300
                var misses = 0
                for _ in 0..<300 where !(item.when?(item.draw(spec, using: &rng)) ?? true) { misses += 1 }
                XCTAssertLessThanOrEqual(misses, 6, "\(spec.id) item \(k) (i\(item.index)) missed \(misses) of 300")
            }
        }
        XCTAssertEqual(AddingFractions.spec.check.map(\.index), [1, 3, 3, 4])
        XCTAssertEqual(AddingFractions.spec.check.map(\.story), [false, false, false, true])
        XCTAssertEqual(SubtractingFractions.spec.check.map(\.story), [false, false, false, true])
        XCTAssertEqual(AddAndSubtract.spec.check.map(\.index), [2, 3, 4, 5])
        XCTAssertEqual(AddingFractions.spec.depends, ["g4-equiv", "g4-likefrac", "g4-factors"])
        XCTAssertEqual(SubtractingFractions.spec.depends, ["add"])
        XCTAssertEqual(AddAndSubtract.spec.depends, ["add", "sub"])
    }
}
