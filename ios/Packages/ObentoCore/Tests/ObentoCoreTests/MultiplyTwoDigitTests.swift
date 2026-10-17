import XCTest
@testable import ObentoCore

final class MultiplyTwoDigitTests: XCTestCase {
    func run(_ a: Int, _ b: Int) -> LessonRun { LessonRun(MultiplyTwoDigit.spec, numbers: MultiplyTwoDigit.numbers(a: a, b: b)) }
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }

    /// The web lesson's reference, 47 × 36 = 47 × (30 + 6), with the web's (and the current app's) messages.
    func testWalkThroughTheReference() {
        let spec = MultiplyTwoDigit.spec
        XCTAssertEqual(spec.id, "g5-mult2"); XCTAssertEqual(spec.master, "area-model")
        XCTAssertEqual(spec.depends, ["g4-mult2x2", "g3-mult10"])
        var l = run(47, 36)
        XCTAssertEqual(l.display, [.num(47), .op("×"), .num(36)])
        XCTAssertEqual(spec.idea(l.numbers), "Splitting one number into tens and ones turns one hard multiplication into two easy ones, added back together.")
        XCTAssertEqual(spec.story?(l.numbers), "A theater has 47 rows. Each row has 36 seats. How many seats are there?")
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words, StepWords(say: "What is 47 × 36?", hint: "Split 36 into tens and ones.", action: "Let’s find out"))
        XCTAssertEqual(l.picture, ["split": 1, "strip": 0, "found": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // the tens strip
        XCTAssertEqual(l.words, StepWords(say: "Multiply by the tens", hint: "The tens strip is 47 tall and 30 wide.", action: "Check"))
        XCTAssertEqual(l.picture, ["split": 1, "strip": 1, "found": 0])
        type(&l, "141")
        XCTAssertEqual(l.go(), .notYet("That's 47 × 3. The tens digit stands for 30, so add a zero."))
        type(&l, "1411")
        XCTAssertEqual(l.go(), .notYet("Not quite. Do 47 × 3, then add a zero."))
        XCTAssertEqual(l.picture["look"], 1)
        XCTAssertEqual(l.step.look, "Look again at the lit-up strip: it's 30 wide and 47 tall.")
        XCTAssertEqual(l.showAnswer(), "Do 47 × 3, then add a zero. That makes 1410.")
        XCTAssertEqual(l.go(), .moved(2))

        // the ones strip
        XCTAssertEqual(l.words.say, "Multiply by the ones")
        XCTAssertEqual(l.words.hint, "The ones strip is 47 tall and 6 wide.")
        XCTAssertEqual(l.picture, ["split": 1, "strip": 2, "found": 1])
        type(&l, "53")
        XCTAssertEqual(l.go(), .notYet("This part is 47 times 6, not plus."))
        type(&l, "141")
        XCTAssertEqual(l.go(), .notYet("Not quite. 47 × 6."))
        XCTAssertEqual(l.showAnswer(), "47 × 6. That makes 282.")
        XCTAssertEqual(l.go(), .moved(3))

        // the sum: 282 (= 47 × 6, the place-value try) is not named as "left out a part"; 1410 is
        XCTAssertEqual(l.words, StepWords(say: "Add the parts", hint: "Add the strips to fill the whole rectangle.", action: "Check"))
        XCTAssertEqual(l.picture, ["split": 1, "strip": 0, "found": 2, "sum": 1])
        XCTAssertEqual(l.step.answer?.known.map(\.values), [["x": 1410]])
        type(&l, "1410")
        XCTAssertEqual(l.go(), .notYet("Add every part: 1410 + 282."))
        type(&l, "282")
        XCTAssertEqual(l.go(), .notYet("Not quite. Add the two partial products."))
        XCTAssertEqual(l.step.look, "Look again: add both strips in the picture.")
        XCTAssertEqual(l.showAnswer(), "Add the two partial products. That makes 1692.")
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words, StepWords(say: "The two strips make 1692.", hint: "Add the strips to fill the whole rectangle.", action: "Next problem"))
        XCTAssertEqual(l.go(), .newProblem)

        // the finished work lines, as the web's
        XCTAssertEqual(l.steps[1].answer?.work, [.num(47), .op("×"), .num(30), .op("="), .num(1410)])
        XCTAssertEqual(l.steps[2].answer?.work, [.num(47), .op("×"), .num(6), .op("="), .num(282)])
        XCTAssertEqual(l.steps[3].answer?.work, [.num(1410), .op("+"), .num(282), .op("="), .num(1692)])
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
        XCTAssertTrue(l.steps[2].answer!.known.isEmpty)
        // 23 × 41: 943 − 920 = 23 and 943 − 23 = 920; 23 × 4 = 92 and 23 × 1 = 23, so only 920 is named
        XCTAssertEqual(l.steps[3].answer!.known.map(\.values), [["x": 920]])
        let m = run(25, 47)  // 1175 − 1000 = 175, 1175 − 175 = 1000; 25 × 4 = 100, 25 × 7 = 175
        XCTAssertEqual(m.steps[3].answer!.known.map(\.values), [["x": 1000]])
        XCTAssertEqual(m.steps[3].answer!.known.first?.message, "Add every part: 1000 + 175.")
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
                let steps = MultiplyTwoDigit.spec.steps(n)
                XCTAssertEqual(steps.count, ps.count + 3)
                for (i, part) in ps.enumerated() { XCTAssertEqual(steps[i + 1].answer?.expected["x"], Double(a * part)) }
                XCTAssertEqual(steps[ps.count + 1].answer?.expected["x"], Double(a * b))
                // no slip is the right answer
                for s in steps { if let t = s.answer { for k in t.known { XCTAssertNotEqual(k.values, t.expected) } } }
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 5)
        let check = MultiplyTwoDigit.spec.check
        XCTAssertEqual(check.map(\.index), [3, 3, 3, 3]); XCTAssertEqual(check.map(\.story), [false, false, false, true])
        for item in check { for _ in 0..<300 { XCTAssertTrue(item.when?(item.draw(MultiplyTwoDigit.spec, using: &rng)) ?? true) } }
    }
}
