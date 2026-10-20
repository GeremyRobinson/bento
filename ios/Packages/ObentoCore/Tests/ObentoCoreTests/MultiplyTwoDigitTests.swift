import XCTest
@testable import ObentoCore

final class MultiplyTwoDigitTests: XCTestCase {
    func run(_ a: Int, _ b: Int) -> LessonRun { LessonRun(MultiplyTwoDigit.spec, numbers: MultiplyTwoDigit.numbers(a: a, b: b)) }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }
    /// The cut, as the hand makes it: where it is goes in the box, checked at once (Cut).
    func cut(_ l: inout LessonRun, _ x: Double) -> LessonRun.Outcome { l.set("x", x); return l.go() }

    /// The web lesson's reference, 47 × 36 = 47 × (30 + 6), on the paper: the cut where the tens end (by hand), then
    /// each strip's squares and the total written in the record, with the web's slips and messages for them.
    func testWalkThroughTheReference() {
        let spec = MultiplyTwoDigit.spec
        XCTAssertEqual(spec.id, "g5-mult2"); XCTAssertEqual(spec.master, "area-model")
        XCTAssertEqual(spec.depends, ["g4-mult2x2", "g3-mult10"])
        var l = run(47, 36)
        XCTAssertEqual(l.display, [.num(47), .op("×"), .num(36)])
        XCTAssertEqual(spec.idea(l.numbers), "Splitting one number into tens and ones turns one hard multiplication into two easy ones, added back together.")
        XCTAssertEqual(spec.story?(l.numbers), "A theater has 47 rows. Each row has 36 seats. How many seats are there?")
        XCTAssertEqual(l.steps.count, 6)
        // the problem is the rectangle's own names: the first words ask about the picture, not the sum again
        XCTAssertEqual(l.words, StepWords(say: "How many squares in the rectangle?", hint: "Split 36 into tens and ones.", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // the cut, by hand: where the tens end
        XCTAssertEqual(l.words, StepWords(say: "Drag the cut to where the tens end.", hint: "The bold lines are the tens. Cut at the last one.", action: "Cut"))
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture, ["at": 1])
        XCTAssertEqual(l.step.answer?.hint, "Cut at the last bold line: 36 is 3 tens and 6.")
        // not dragged in yet (the handle starts at the right end): a notice, not a miss
        XCTAssertEqual(cut(&l, 36), .notYet("Drag the cut to where the tens end first."))
        XCTAssertEqual(cut(&l, 0), .notYet("Drag the cut to where the tens end first."))
        XCTAssertEqual(l.misses, 0)
        // a ten left in the ones, and a part that isn't all tens, said as the cut makes them
        XCTAssertEqual(cut(&l, 20), .notYet("16 still has a ten in it. Cut where the tens end."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.picture["tens"], 1, "a miss counts the tens across the top")
        XCTAssertEqual(cut(&l, 33), .notYet("33 has 3 ones in it. Cut on a bold line."))
        XCTAssertEqual(cut(&l, 31), .notYet("31 has 1 one in it. Cut on a bold line."))
        XCTAssertEqual(cut(&l, 25), .notYet("25 has 5 ones in it. Cut on a bold line."))
        XCTAssertEqual(l.slips.last?.said, "25 has 5 ones in it. Cut on a bold line.")
        XCTAssertEqual(cut(&l, 30), .moved(2))

        // the tens strip, written in the record
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.words, StepWords(say: "How many squares in the tens strip? Write it.", hint: "The tens strip is 47 tall and 30 wide.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 2])
        type(&l, "141")
        XCTAssertEqual(l.go(), .notYet("That's 47 × 3. The tens digit stands for 30, so add a zero."))
        type(&l, "1411")
        XCTAssertEqual(l.go(), .notYet("Not quite. Do 47 × 3, then add a zero."))
        XCTAssertEqual(l.picture["look"], 1)
        XCTAssertEqual(l.step.look, "Look again at the lit-up strip: it's 30 wide and 47 tall.")
        XCTAssertEqual(l.showAnswer(), "Do 47 × 3, then add a zero. That makes 1410.")
        XCTAssertEqual(l.go(), .moved(3))

        // the ones strip
        XCTAssertEqual(l.words, StepWords(say: "How many squares in the ones strip? Write it.", hint: "The ones strip is 47 tall and 6 wide.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 3])
        type(&l, "53")
        XCTAssertEqual(l.go(), .notYet("This part is 47 times 6, not plus."))
        type(&l, "141")
        XCTAssertEqual(l.go(), .notYet("Not quite. 47 × 6."))
        XCTAssertEqual(l.showAnswer(), "47 × 6. That makes 282.")
        XCTAssertEqual(l.go(), .moved(4))

        // the total: 282 (= 47 × 6, the place-value try) is not named as "left out a part"; 1410 is
        XCTAssertEqual(l.words, StepWords(say: "How many squares in all? Write it.", hint: "Add the strips to fill the whole rectangle.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 4])
        XCTAssertEqual(l.step.answer?.known.map(\.values), [["x": 1410]])
        type(&l, "1410")
        XCTAssertEqual(l.go(), .notYet("Add every part: 1410 + 282."))
        type(&l, "282")
        XCTAssertEqual(l.go(), .notYet("Not quite. Add the two partial products."))
        XCTAssertEqual(l.step.look, "Look again: add both strips in the picture.")
        XCTAssertEqual(l.showAnswer(), "Add the two partial products. That makes 1692.")
        XCTAssertEqual(l.go(), .moved(5))

        // the last words say why, never the sum again
        XCTAssertEqual(l.words, StepWords(say: "The two strips make the whole rectangle.", hint: "Add the strips to fill the whole rectangle.", action: "Next problem"))
        XCTAssertEqual(l.picture, ["at": 5])
        XCTAssertEqual(l.go(), .newProblem)

        // the finished work lines: the split the cut made, then the web's
        XCTAssertEqual(l.steps[1].answer?.work, [.num(36), .op("="), .num(30), .op("+"), .num(6)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(47), .op("×"), .num(30), .op("="), .num(1410)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(47), .op("×"), .num(6), .op("="), .num(282)])
        XCTAssertEqual(l.steps[4].answer?.work, [.num(1410), .op("+"), .num(282), .op("="), .num(1692)])
    }

    /// The cut's words at the edges of the generator's numbers: one ten (12–19), and one one (…1).
    func testTheCutAtTheEdges() {
        var teen = run(23, 19)
        _ = teen.go()
        XCTAssertEqual(teen.step.answer?.hint, "Cut at the last bold line: 19 is 1 ten and 9.")
        XCTAssertEqual(cut(&teen, 11), .notYet("11 has 1 one in it. Cut on a bold line."))
        XCTAssertEqual(cut(&teen, 18), .notYet("18 has 8 ones in it. Cut on a bold line."))
        XCTAssertEqual(cut(&teen, 10), .moved(2))
        var one = run(98, 91)
        _ = one.go()
        XCTAssertEqual(cut(&one, 80), .notYet("11 still has a ten in it. Cut where the tens end."))
        XCTAssertEqual(cut(&one, 90), .moved(2))
        // the biggest the generator makes: 98 × 98
        var big = run(98, 98)
        _ = big.go(); XCTAssertEqual(cut(&big, 90), .moved(2))
        type(&big, "8820"); XCTAssertEqual(big.go(), .moved(3))
        type(&big, "784"); XCTAssertEqual(big.go(), .moved(4))
        type(&big, "9604"); XCTAssertEqual(big.go(), .moved(5))
    }

    /// A second factor with one part (the generator never makes one): no cut, its one strip is the whole rectangle.
    func testOnePartHasNoCut() {
        var l = run(47, 30)
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.words.say, "How many squares in all? Write it.")
        XCTAssertEqual(l.picture, ["at": 2])
        type(&l, "1410"); XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "47 × 30 = 1410.")
        XCTAssertEqual(run(47, 7).steps.count, 3)
    }

    func testSplitAndPlaceNames() {
        XCTAssertEqual(MultiplyTwoDigit.parts(36), [30, 6])
        XCTAssertEqual(MultiplyTwoDigit.parts(305), [300, 5])
        XCTAssertEqual(MultiplyTwoDigit.placeName(30), "tens"); XCTAssertEqual(MultiplyTwoDigit.placeName(6), "ones")
        XCTAssertEqual(MultiplyTwoDigit.placeName(300), "hundreds")
    }

    /// A ones part of 1 has no adding slip; a part left out is named when it isn't the place-value try.
    func testOnesOfOneAndLeftOutParts() {
        let l = run(23, 41)
        XCTAssertTrue(l.steps[3].answer!.known.isEmpty)
        // 23 × 41: 943 − 920 = 23 and 943 − 23 = 920; 23 × 4 = 92 and 23 × 1 = 23, so only 920 is named
        XCTAssertEqual(l.steps[4].answer!.known.map(\.values), [["x": 920]])
        let m = run(25, 47)  // 1175 − 1000 = 175, 1175 − 175 = 1000; 25 × 4 = 100, 25 × 7 = 175
        XCTAssertEqual(m.steps[4].answer!.known.map(\.values), [["x": 1000]])
        XCTAssertEqual(m.steps[4].answer!.known.first?.message, "Add every part: 1000 + 175.")
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 47)
        for index in [0, 3] {
            for _ in 0..<300 {
                let n = MultiplyTwoDigit.spec.generate(&rng, index), a = Int(n["a"]!), b = Int(n["b"]!)
                let early = index < 3
                XCTAssertTrue((12...(early ? 39 : 98)).contains(a)); XCTAssertTrue((12...(early ? 29 : 98)).contains(b))
                XCTAssertNotEqual(b % 10, 0)
                let ps = MultiplyTwoDigit.parts(b)
                XCTAssertEqual(ps.reduce(0, +), b)
                XCTAssertEqual(ps.count, 2, "tens and ones, every time: the cut has somewhere to go")
                let steps = MultiplyTwoDigit.spec.steps(n)
                // the question, the cut, a strip each, the total, the why
                XCTAssertEqual(steps.count, ps.count + 4)
                XCTAssertEqual(steps[1].answer?.byHand, true)
                XCTAssertEqual(steps[1].answer?.expected["x"], Double(b - b % 10))
                for (i, part) in ps.enumerated() { XCTAssertEqual(steps[i + 2].answer?.expected["x"], Double(a * part)); XCTAssertEqual(steps[i + 2].answer?.byHand, false) }
                XCTAssertEqual(steps[ps.count + 2].answer?.expected["x"], Double(a * b))
                // no slip is the right answer, and a cut where the tens end is always right
                for s in steps { if let t = s.answer { for k in t.known { XCTAssertNotEqual(k.values, t.expected) } } }
                XCTAssertEqual(steps[1].answer?.check?(["x": Double(b - b % 10)]), .right)
                // the stages follow on, the picture's "at" one per step
                XCTAssertEqual(steps.map { $0.picture["at"] ?? -1 }, [0, 1, 2, 3, 4, 5])
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 5)
        let check = MultiplyTwoDigit.spec.check
        XCTAssertEqual(check.map(\.index), [3, 3, 3, 3]); XCTAssertEqual(check.map(\.story), [false, false, false, true])
        for item in check { for _ in 0..<300 { XCTAssertTrue(item.when?(item.draw(MultiplyTwoDigit.spec, using: &rng)) ?? true) } }
    }

    /// Told as its story: the operation first, then the same paper steps.
    func testTheStory() {
        var l = LessonRun(MultiplyTwoDigit.spec, numbers: MultiplyTwoDigit.numbers(a: 47, b: 36), story: true)
        // on its page, as every problem there is
        l.skipAsk()
        XCTAssertEqual(l.index, 0)
        XCTAssertEqual(l.words.say, "A theater has 47 rows. Each row has 36 seats. How many seats are there?")
        XCTAssertEqual(l.words.hint, "Pick what to do.")
        l.choose(2)
        XCTAssertEqual(l.go(), .moved(2), "× picked, the question passed by: straight to the cut")
        XCTAssertEqual(l.words.say, "Drag the cut to where the tens end.")
    }
}
