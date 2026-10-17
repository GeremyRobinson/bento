import XCTest
@testable import ObentoCore

final class LongDivisionTests: XCTestCase {
    func run(_ dv: Int, _ qt: Int) -> LessonRun { LessonRun(LongDivision.spec, numbers: LongDivision.numbers(dv: dv, qt: qt)) }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }

    /// The web lesson's reference, 864 ÷ 12 (dv 12, qt 72).
    func testWalkThroughTheReference() {
        let spec = LongDivision.spec
        XCTAssertEqual(spec.id, "g5-divide"); XCTAssertEqual(spec.master, "area-model")
        XCTAssertEqual(spec.depends, ["g4-divide", "g3-mult10"])
        var l = run(12, 72)
        XCTAssertEqual(l.display, [.num(864), .op("÷"), .num(12)])
        XCTAssertEqual(spec.idea(l.numbers), "Taking out ten groups at a time gets to the answer faster than going one by one.")
        XCTAssertEqual(spec.story?(l.numbers), "864 marbles are packed equally into 12 jars. How many marbles go in each jar?")
        XCTAssertEqual(l.words, StepWords(say: "What is 864 ÷ 12?", hint: "The strip is 12 tall. How wide is it?", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["strip": 0, "found": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // tens first
        XCTAssertEqual(l.words, StepWords(say: "Take out as many tens of 12 as fit in 864. How many is that?", hint: "Take out as many tens of 12 as fit.", action: "Check"))
        XCTAssertEqual(l.picture, ["strip": 1, "found": 0])
        type(&l, "60"); XCTAssertEqual(l.go(), .notYet("12 × 70 still fits, so you can use more tens."))
        type(&l, "7"); XCTAssertEqual(l.go(), .notYet("7 tens is written 70."))
        type(&l, "80"); XCTAssertEqual(l.go(), .notYet("12 × 80 = 960, which is more than 864."))
        type(&l, "75"); XCTAssertEqual(l.go(), .notYet("Not quite. Try 12 × 10, 12 × 20, … and stop before you go past 864."))
        XCTAssertEqual(l.picture["look"], 1)
        XCTAssertEqual(l.step.look, "Look again at the lit-up strip: it's 12 tall.")
        XCTAssertEqual(l.showAnswer(), "Try 12 × 10, 12 × 20, … and stop before you go past 864. That makes 70.")
        XCTAssertEqual(l.go(), .moved(2))

        // subtract
        XCTAssertEqual(l.words, StepWords(say: "Subtract", hint: "Take those away to see what's left.", action: "Check"))
        XCTAssertEqual(l.picture, ["strip": 2, "found": 1, "left": 0])
        type(&l, "1704"); XCTAssertEqual(l.go(), .notYet("Those 840 have been shared out, so take them away from 864."))
        XCTAssertEqual(l.showAnswer(), "12 × 70 = 840. Take that away from 864. That makes 24.")
        XCTAssertEqual(l.go(), .moved(3))

        // divide what's left
        XCTAssertEqual(l.words, StepWords(say: "Divide what's left", hint: "Now count how many 12s fit in what's left.", action: "Check"))
        XCTAssertEqual(l.picture, ["strip": 2, "found": 1, "left": 1])
        type(&l, "3"); XCTAssertEqual(l.go(), .notYet("12 × 3 = 36, which is more than 24."))
        type(&l, "1"); XCTAssertEqual(l.go(), .notYet("One more 12 still fits in 24."))
        XCTAssertEqual(l.showAnswer(), "How many 12s make 24? That makes 2.")
        XCTAssertEqual(l.go(), .moved(4))

        // add the parts
        XCTAssertEqual(l.words, StepWords(say: "Add the parts", hint: "The tens and the ones together are the answer.", action: "Check"))
        XCTAssertEqual(l.picture, ["strip": 0, "found": 2, "sum": 1])
        type(&l, "9"); XCTAssertEqual(l.go(), .notYet("The first part was 70, not 7."))
        XCTAssertEqual(l.showAnswer(), "70 + 2. That makes 72.")
        XCTAssertEqual(l.go(), .moved(5))

        XCTAssertEqual(l.words, StepWords(say: "The tens and the ones make 72.", hint: "Taking out ten groups at a time gets to the answer faster than going one by one.", action: "Next problem"))
        XCTAssertEqual(l.go(), .newProblem)

        // finished lines (the tens line is its prompt filled in; the web writes 12 × 70 ≤ 864 there, see the file)
        XCTAssertEqual(l.steps[1].answer?.work, [.text("tens"), .op("="), .num(70)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(864), .op("−"), .num(840), .op("="), .num(24)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(24), .op("÷"), .num(12), .op("="), .num(2)])
        XCTAssertEqual(l.steps[4].answer?.work, [.num(864), .op("÷"), .num(12), .op("="), .num(72)])
    }

    /// The web test's question for 1168 ÷ 16, and slips that the web keeps or drops.
    func testWebAssertionsAndEdgeSlips() {
        XCTAssertEqual(run(16, 73).steps[1].words.say, "Take out as many tens of 16 as fit in 1168. How many is that?")
        let l = run(3, 21)  // T = 20, O = 1: the one-too-few slip is 0, still kept
        XCTAssertEqual(l.steps[3].answer!.known.map(\.values), [["x": 2], ["x": 0]])
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
            XCTAssertEqual(steps.map { $0.answer?.expected["x"] }, [nil, Double(T), Double(dv * qt - dv * T), Double(qt % 10), Double(qt), nil])
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
