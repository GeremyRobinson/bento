import XCTest
@testable import ObentoCore

final class DivideByUnitFractionTests: XCTestCase {
    private func fill(_ l: inout LessonRun, _ box: String, _ s: String) {
        l.reset()
        l.active = box
        for ch in s { l.type(String(ch)) }
    }

    /// The cut: how many of the ruler's pieces make a whole, into the box, checked as the Cut block does.
    private func cut(_ l: inout LessonRun, _ pieces: Int) -> LessonRun.Outcome { l.set("x", Double(pieces)); return l.go() }

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
        XCTAssertEqual(l.steps.count, 4, "ask, cut, write, done: the cut does the web's \"one\", the record its \"all\"")
        // the first words never repeat the problem: it's written once, as the picture's names
        XCTAssertEqual(l.words.say, "Look at the piece. How many fit in all the wholes?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture, [:])
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: the ruler to the end of the piece, and the first whole cut into pieces that size
        XCTAssertEqual(l.words.say, "How many fit in one whole? Drag the ruler to the end of the piece, then cut.")
        XCTAssertEqual(l.words.hint, "Cut one whole into fourths.")
        XCTAssertEqual(l.words.action, "Cut")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["ruler": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        // what a cut that isn't the piece's size says, measured against the piece
        XCTAssertEqual(cut(&l, 2), .notYet("A half is longer than the 1/4 piece."))
        XCTAssertEqual(cut(&l, 3), .notYet("A third is longer than the 1/4 piece."), "the web's slip, d − 1, is longer pieces on the paper")
        XCTAssertEqual(l.picture["oldCuts"], 1, "a miss rings the dot under the piece's end")
        XCTAssertEqual(cut(&l, 6), .notYet("A sixth is shorter than the 1/4 piece. 2 sixths are longer."))
        XCTAssertEqual(cut(&l, 8), .notYet("2 eighths make the 1/4 piece."))
        XCTAssertEqual(cut(&l, 24), .notYet("6 twenty-fourths make the 1/4 piece."))
        XCTAssertEqual(l.misses, 5)
        XCTAssertEqual(l.showAnswer(), "4 pieces the size of 1/4 make one whole.")
        l.reset()
        XCTAssertEqual(cut(&l, 4), .moved(2))

        // the record: the product typed, the rest written for the child
        XCTAssertEqual(l.words.say, "How many fourths in all? Write it.")
        XCTAssertEqual(l.words.hint, "Every whole holds 4, so count them all.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.step.answer?.boxes, ["n"])
        XCTAssertEqual(l.picture, ["cut": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        // the web's slips: divided the wrong way ("all"), and the cut lines counted ("one", now over every whole)
        fill(&l, "n", ".75")
        XCTAssertEqual(l.go(), .notYet("The pieces are small, so lots of them fit. The answer is bigger than 3."))
        fill(&l, "n", "9")
        XCTAssertEqual(l.go(), .notYet("Count the pieces, not the cut lines between them."))
        fill(&l, "n", "7")
        XCTAssertEqual(l.go(), .notYet("Not quite. 3 wholes, 4 pieces in each."))
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(l.picture["last"], 1, "a miss rings the last piece counted")
        XCTAssertEqual(l.showAnswer(), "3 wholes, 4 pieces in each. That makes 12.")
        XCTAssertEqual(l.go(), .moved(3))

        // the last words say why
        XCTAssertEqual(l.words.say, "4 pieces in every whole.")
        XCTAssertEqual(l.words.hint, "Dividing by a unit fraction asks how many of those pieces fit.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.picture, ["cut": 1, "done": 1])
        XCTAssertEqual(l.go(), .newProblem)

        // the finished lines: one whole is 4 × 1/4; the record 3 ÷ 1/4 = 3 × 4 = 12
        XCTAssertEqual(l.steps[1].answer?.work, [.num(1), .op("="), .num(4), .op("×"), .frac(.num(1), .num(4))])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(3), .op("÷"), .frac(.num(1), .num(4)), .op("="), .num(3), .op("×"), .num(4), .op("="), .num(12)])
        XCTAssertEqual(l.steps.map(\.picture), [[:], ["ruler": 1], ["cut": 1], ["cut": 1, "done": 1]])
        XCTAssertEqual(l.steps.map(\.onMiss), [[:], ["oldCuts": 1], ["last": 1], [:]])
    }

    /// Every bottom's whole is the family's length, so the 1/d piece is a whole number of squares the ruler can reach; and
    /// Cut at every length the ruler snaps to is right only at the piece's size, and otherwise says what happened.
    func testTheRulerAtEveryLengthForEveryBottom() {
        for d in 2...8 {
            let L = UnlikeFractions.wholeLength(d)
            XCTAssertEqual(L, [2: 48, 3: 48, 4: 48, 5: 40, 6: 48, 7: 42, 8: 48][d], "\(d)")
            XCTAssertEqual(L % d, 0)
            XCTAssertGreaterThanOrEqual(L / d, 6, "a piece holds its number")
            let task = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 3, d: d)).steps[1].answer!
            var right = 0
            // the ruler's lengths: every whole number of squares that divides the whole, 2 to half of it
            for len in 2...(L / 2) where L % len == 0 {
                let k = L / len, said = task.check!(["x": Double(k)])
                guard case .wrong(let why) = said else { XCTAssertEqual(said, .right); XCTAssertEqual(len * d, L); right += 1; continue }
                XCTAssertTrue(why.hasSuffix(k < d ? "is longer than the 1/\(d) piece." : k % d == 0 ? "make the 1/\(d) piece." : "are longer."), why)
                XCTAssertFalse(why.contains("cut lines"), "the ruler counts pieces, so it never says the cut lines were counted")
            }
            XCTAssertEqual(right, 1, "exactly one length is the piece's")
            XCTAssertEqual(task.check!([:]), .soft("Drag the ruler first."))
        }
        // a number that isn't a whole count of pieces (never the ruler's), named plainly
        XCTAssertEqual(DivideByUnitFraction.cutVerdict(2.5, d: 4), .wrong("Those pieces aren’t the size of the 1/4 piece."))
        // "an" where the name needs it (not in this lesson's bottoms, but the words are right)
        XCTAssertEqual(DivideByUnitFraction.cutVerdict(8, d: 12), .wrong("An eighth is longer than the 1/12 piece."))
        XCTAssertEqual(DivideByUnitFraction.cutVerdict(8, d: 3), .wrong("2 eighths are shorter than the 1/3 piece. 3 eighths are longer."))
    }

    /// 2 ÷ 1/2 = 4, the smallest the generator makes: two wholes in halves.
    func testTheSmallestProblem() {
        var l = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 2, d: 2))
        XCTAssertEqual(l.steps.map(\.words.say), ["Look at the piece. How many fit in all the wholes?",
                                                  "How many fit in one whole? Drag the ruler to the end of the piece, then cut.",
                                                  "How many halves in all? Write it.", "2 pieces in every whole."])
        _ = l.go()
        // a third is 16 squares and the half 24: one third falls short of its end, two go past it
        XCTAssertEqual(cut(&l, 3), .notYet("A third is shorter than the 1/2 piece. 2 thirds are longer."))
        XCTAssertEqual(cut(&l, 4), .notYet("2 fourths make the 1/2 piece."))
        XCTAssertEqual(cut(&l, 2), .moved(2))
        fill(&l, "n", "1")
        XCTAssertEqual(l.go(), .notYet("The pieces are small, so lots of them fit. The answer is bigger than 2."))
        // halves: one cut line in each whole, so counting the cut lines gives the wholes
        fill(&l, "n", "2")
        XCTAssertEqual(l.go(), .notYet("Count the pieces, not the cut lines between them."))
        fill(&l, "n", "4")
        XCTAssertEqual(l.go(), .moved(3))
    }

    /// 10 ÷ 1/8 = 80, the biggest the generator makes: ten wholes in eighths.
    func testTheBiggestProblem() {
        var l = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 10, d: 8))
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Cut one whole into eighths.")
        XCTAssertEqual(cut(&l, 6), .notYet("A sixth is longer than the 1/8 piece."))
        XCTAssertEqual(cut(&l, 12), .notYet("A twelfth is shorter than the 1/8 piece. 2 twelfths are longer."))
        XCTAssertEqual(cut(&l, 16), .notYet("2 sixteenths make the 1/8 piece."))
        XCTAssertEqual(cut(&l, 8), .moved(2))
        XCTAssertEqual(l.words.say, "How many eighths in all? Write it.")
        fill(&l, "n", "1.25")
        XCTAssertEqual(l.go(), .notYet("The pieces are small, so lots of them fit. The answer is bigger than 10."))
        fill(&l, "n", "70")
        XCTAssertEqual(l.go(), .notYet("Count the pieces, not the cut lines between them."))
        fill(&l, "n", "80")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "8 pieces in every whole.")
    }

    /// Fifths and sevenths have their own wholes (40 and 42 squares): the messages measure against their pieces.
    func testFifthsAndSevenths() {
        var five = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 4, d: 5))
        _ = five.go()
        // an eighth of 40 is 5 squares, the fifth 8: one falls short, two go past
        XCTAssertEqual(cut(&five, 8), .notYet("An eighth is shorter than the 1/5 piece. 2 eighths are longer."))
        XCTAssertEqual(cut(&five, 4), .notYet("A fourth is longer than the 1/5 piece."))
        XCTAssertEqual(cut(&five, 10), .notYet("2 tenths make the 1/5 piece."))
        XCTAssertEqual(cut(&five, 5), .moved(2))
        var seven = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 6, d: 7))
        _ = seven.go()
        // a sixth of 42 is 7 squares, a seventh 6
        XCTAssertEqual(cut(&seven, 6), .notYet("A sixth is longer than the 1/7 piece."))
        XCTAssertEqual(cut(&seven, 21), .notYet("3 twenty-firsts make the 1/7 piece."))
        XCTAssertEqual(cut(&seven, 7), .moved(2))
        fill(&seven, "n", "42")
        XCTAssertEqual(seven.go(), .moved(3))
    }

    /// Told as its story: "Pick what to do" first (÷), then the same steps on the same picture.
    func testTheStory() {
        var l = LessonRun(DivideByUnitFraction.spec, numbers: DivideByUnitFraction.numbers(W: 5, d: 3), story: true)
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.step.answer?.choices?[3], "÷ Divide")
        XCTAssertEqual(l.step.picture, [:], "the picture as the first step draws it")
        l.choose(0)
        XCTAssertEqual(l.go(), .notYet("Read it again. What happens to the amounts?"))
        l.choose(3)
        XCTAssertEqual(l.go(), .moved(1))
        l.skipAsk()
        XCTAssertEqual(l.index, 2, "on a page the opening question is passed by")
        XCTAssertEqual(cut(&l, 3), .moved(3))
        fill(&l, "n", "15")
        XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.say, "3 pieces in every whole.")
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 9)
        var wholes = Set<Int>(), bottoms = Set<Int>()
        for index in [0, 1, 2, 3, 6] {
            for _ in 0..<300 {
                let p = DivideByUnitFraction.spec.generate(&rng, index)
                let W = Int(p["W"]!), d = Int(p["d"]!)
                if index < 3 { XCTAssertTrue((2...4).contains(W) && (2...4).contains(d)) }
                else { XCTAssertTrue((2...10).contains(W) && (2...8).contains(d)); wholes.insert(W); bottoms.insert(d) }
                // the web's oracle: W · d; the cut is d pieces to a whole
                var l = LessonRun(DivideByUnitFraction.spec, numbers: p)
                XCTAssertEqual(l.steps[1].answer?.expected, ["x": Double(d)])
                XCTAssertEqual(l.steps[2].answer?.expected, ["n": Double(W * d)])
                // the record's slips are never the answer
                XCTAssertFalse(l.steps[2].answer!.known.contains { $0.values["n"] == Double(W * d) })
                for _ in 0..<(l.steps.count - 1) { _ = l.showAnswer(); XCTAssertEqual(l.go(), .moved(l.index)) }
                XCTAssertEqual(l.go(), .newProblem)
            }
        }
        XCTAssertEqual(wholes, Set(2...10), "the web's 2 to 10 wholes all come up")
        XCTAssertEqual(bottoms, Set(2...8))
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
