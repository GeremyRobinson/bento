import XCTest
@testable import ObentoCore

final class LongDivisionTests: XCTestCase {
    func run(_ dv: Int, _ qt: Int) -> LessonRun { LessonRun(LongDivision.spec, numbers: LongDivision.numbers(dv: dv, qt: qt)) }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }
    /// The edge let go with the step's box set from it, and Check pressed.
    func edge(_ l: inout LessonRun, _ x: Double) -> LessonRun.Outcome { l.set("x", x); return l.go() }

    /// The web lesson's reference, 864 ÷ 12 (dv 12, qt 72), worked on the paper: the edge dragged out by tens, then on
    /// by ones (each move's box set from where the edge is), the answer typed over the bracket.
    func testWalkThroughTheReference() {
        let spec = LongDivision.spec
        XCTAssertEqual(spec.id, "g5-divide"); XCTAssertEqual(spec.master, "area-model")
        XCTAssertEqual(spec.depends, ["g4-divide", "g3-mult10"])
        var l = run(12, 72)
        XCTAssertEqual(l.display, [.num(864), .op("÷"), .num(12)])
        XCTAssertEqual(spec.idea(l.numbers), "Taking out ten groups at a time gets to the answer faster than going one by one.")
        XCTAssertEqual(spec.story?(l.numbers), "864 marbles are packed equally into 12 jars. How many marbles go in each jar?")
        XCTAssertEqual(l.words, StepWords(say: "How wide is the rectangle?", hint: "It's 12 tall and holds 864 squares.", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // tens first: the edge dragged out ten columns at a time
        XCTAssertEqual(l.words, StepWords(say: "Drag the edge out ten columns at a time, as far as the squares go.", hint: "Ten columns of 12 use 120 squares.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 1])
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(edge(&l, 0), .notYet("Drag the edge out first."))
        XCTAssertEqual(l.misses, 0, "nothing dragged is not a miss")
        XCTAssertEqual(edge(&l, 60), .notYet("12 × 70 still fits, so you can use more tens."))
        XCTAssertEqual(edge(&l, 50), .notYet("That uses 600, and 264 are left: ten more columns fit."))
        XCTAssertEqual(edge(&l, 80), .notYet("12 × 80 = 960, which is more than 864."))
        XCTAssertEqual(edge(&l, 90), .notYet("12 × 90 = 1080, which is more than 864."))
        type(&l, "7"); XCTAssertEqual(l.go(), .notYet("7 tens is written 70."))
        type(&l, "65"); XCTAssertEqual(l.go(), .notYet("Take out whole tens first: 65 isn't a ten."))
        XCTAssertEqual(l.picture["look"], 1)
        XCTAssertEqual(l.step.look, "Look again at the lit-up strip: it's 12 tall.")
        XCTAssertEqual(l.showAnswer(), "Try 12 × 10, 12 × 20, … and stop before you go past 864. That makes 70.")
        XCTAssertEqual(l.go(), .moved(2))

        // the ones: on a column at a time until none are left (the subtraction is written for the child)
        XCTAssertEqual(l.words, StepWords(say: "Now drag it on a column at a time until none are left.", hint: "One column of 12 uses 12 squares.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 2])
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(edge(&l, 3), .notYet("12 × 3 = 36, which is more than 24."))
        XCTAssertEqual(edge(&l, 1), .notYet("One more 12 still fits in 24."))
        XCTAssertEqual(edge(&l, 5), .notYet("12 × 5 = 60, which is more than 24."))
        XCTAssertEqual(l.showAnswer(), "How many 12s make 24? That makes 2.")
        XCTAssertEqual(l.go(), .moved(3))

        // the answer over the bracket, typed
        XCTAssertEqual(l.words, StepWords(say: "How wide is it? Write it over the bracket.", hint: "The tens and the ones together are the answer.", action: "Check"))
        XCTAssertEqual(l.picture, ["at": 3])
        XCTAssertFalse(l.handAnswered)
        type(&l, "9"); XCTAssertEqual(l.go(), .notYet("The first part was 70, not 7."))
        XCTAssertEqual(l.showAnswer(), "70 + 2. That makes 72.")
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words, StepWords(say: "12 rows of 72 make 864.", hint: "Taking out ten groups at a time gets to the answer faster than going one by one.", action: "Next problem"))
        XCTAssertEqual(l.go(), .newProblem)

        // finished lines
        XCTAssertEqual(l.steps[1].answer?.work, [.text("tens"), .op("="), .num(70)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(24), .op("÷"), .num(12), .op("="), .num(2)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(864), .op("÷"), .num(12), .op("="), .num(72)])
    }

    /// The web test's question for 1168 ÷ 16, and slips that the web keeps or drops.
    func testWebAssertionsAndEdgeSlips() {
        XCTAssertEqual(run(16, 73).steps[1].answer?.hint, "Try 16 × 10, 16 × 20, … and stop before you go past 1168.")
        XCTAssertEqual(run(16, 73).steps[4].words.say, "16 rows of 73 make 1168.")
        let l = run(3, 21)  // T = 20, O = 1: the one-too-few slip is 0, still kept
        XCTAssertEqual(l.steps[2].answer!.known.map(\.values), [["x": 2], ["x": 0]])
        let m = run(7, 13)  // T = 10: "1 ten is written 10."
        XCTAssertEqual(m.steps[1].answer!.known[1].message, "1 ten is written 10.")
        XCTAssertEqual(m.steps[1].answer!.known[0].values, ["x": 0])
    }

    func testEveryProblemKeepsTheWebRules() {
        var rng = SeededRandom(seed: 864)
        var small = 0
        for _ in 0..<300 {
            let n = LongDivision.spec.generate(&rng, 3), dv = Int(n["dv"]!), qt = Int(n["qt"]!)
            XCTAssertTrue((3...9).contains(dv) || (11...25).contains(dv))
            XCTAssertTrue((12...99).contains(qt)); XCTAssertNotEqual(qt % 10, 0)
            XCTAssertEqual(n["n"], Double(dv * qt))
            if dv <= 9 { small += 1 }
            let steps = LongDivision.spec.steps(n), T = qt - qt % 10
            XCTAssertEqual(steps.map { $0.answer?.expected["x"] }, [nil, Double(T), Double(qt % 10), Double(qt), nil])
            XCTAssertEqual(steps.map { $0.answer?.byHand }, [nil, true, true, false, nil])
            for s in steps { if let t = s.answer { for k in t.known { XCTAssertNotEqual(k.values, t.expected) } } }
        }
        XCTAssertTrue((90...210).contains(small), "about half the divisors are one digit")
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 9)
        let check = LongDivision.spec.check
        XCTAssertEqual(check.map(\.index), [3, 3, 3, 3]); XCTAssertEqual(check.map(\.story), [false, false, false, true])
        for _ in 0..<300 {
            XCTAssertLessThanOrEqual(check[0].draw(LongDivision.spec, using: &rng)["dv"]!, 9)
            XCTAssertGreaterThanOrEqual(check[1].draw(LongDivision.spec, using: &rng)["dv"]!, 11)
            XCTAssertGreaterThanOrEqual(check[2].draw(LongDivision.spec, using: &rng)["dv"]!, 11)
        }
    }
}
