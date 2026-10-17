import XCTest
@testable import ObentoCore

final class AddDecimalsTests: XCTestCase {
    private func run(_ a: Double, _ b: Double) -> LessonRun { LessonRun(AddDecimals.spec, numbers: AddDecimals.numbers(a: a, b: b)) }
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }

    /// The web lesson's reference: 12.5 + 3.75 = 16.25.
    func testWalkThroughTheReference() {
        var l = run(12.5, 3.75)
        XCTAssertEqual(AddDecimals.spec.master, "columns")
        XCTAssertEqual(l.display, [.num(12.5), .op("+"), .num(3.75)])
        XCTAssertEqual(l.words.say, "What is 12.5 + 3.75?")
        XCTAssertEqual(l.words.hint, "Write 12.5 as 12.50 so both numbers have hundredths.")
        XCTAssertEqual(l.picture, ["lineUp": 1, "lit": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Add the whole numbers.")
        XCTAssertEqual(answer(&l, "9"), .notYet("This step adds the whole parts."))
        XCTAssertEqual(l.showAnswer(), "Add the parts before the decimal points. That makes 15.")
        XCTAssertEqual(l.steps[1].answer?.work, [.num(12), .op("+"), .num(3), .op("="), .num(15)])
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Add the decimal parts.")
        XCTAssertEqual(l.words.hint, "Add the parts after the point. That’s more than 1 whole.")
        XCTAssertEqual(answer(&l, "0.8"), .notYet("0.5 means 5 tenths, which is 50 hundredths. Line up the points."))
        XCTAssertEqual(answer(&l, "1.2"), .notYet("Not quite. Line up the points: 0.5 is the same as 0.50."))
        XCTAssertEqual(l.showAnswer(), "Line up the points: 0.5 is the same as 0.50. That makes 1.25.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(0.5), .op("+"), .num(0.75), .op("="), .num(1.25)])
        XCTAssertEqual(l.picture["whole"], 1)
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "Put them together.")
        XCTAssertEqual(l.words.hint, "Put the two answers together.")
        XCTAssertEqual(l.picture["carry"], 1)
        XCTAssertEqual(answer(&l, "15.25"), .notYet("1.25 is more than 1 whole: that 1 goes with the whole numbers."))
        XCTAssertEqual(l.showAnswer(), "15 + 1.25. That makes 16.25.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(12.5), .op("+"), .num(3.75), .op("="), .num(16.25)])
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words.say, "12.5 + 3.75 = 16.25.")
        XCTAssertEqual(l.words.hint, "Line up the points so tenths add to tenths and hundredths to hundredths.")
        XCTAssertEqual(l.picture["total"], 1)
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(AddDecimals.spec.story?(l.numbers), "Maya biked 12.5 km on Saturday and 3.75 km on Sunday. How far did she bike in all?")
        XCTAssertEqual(AddDecimals.spec.idea(l.numbers), "Line up the points so tenths add to tenths and hundredths to hundredths.")
        XCTAssertEqual(AddDecimals.spec.depends, ["g4-dec", "g4-addsub"])
    }

    func testCarryAndShortParts() {
        // the ones make less than 10: the slip is subtracting
        let l = run(12.2, 5.31)
        XCTAssertEqual(l.steps[1].answer?.known.map(\.message), ["This step adds the whole parts."])
        XCTAssertEqual(l.steps[1].answer?.known.first?.values["x"], 7)
        // the ones carry; the decimal parts make less than 1
        let l2 = run(18.2, 5.31)
        XCTAssertEqual(l2.steps[1].answer?.known.map(\.message), ["The ones make 13: carry the 1 ten."])
        XCTAssertEqual(l2.steps[1].answer?.known.first?.values["x"], 13)
        XCTAssertEqual(l2.steps[2].words.hint, "Add the parts after the point.")
        XCTAssertEqual(l2.steps[3].answer?.known.map(\.message), ["Keep the 0.51 after the point."])
        XCTAssertEqual(l2.steps[3].answer?.known.first?.values["x"], 23)
        XCTAssertEqual(l2.steps[3].picture["carry"], 0)
        // both short of hundredths, and one tenth said once
        XCTAssertEqual(run(2, 1.1).words.hint, "Write 2 as 2.00 and 1.1 as 1.10 so both numbers have hundredths.")
        XCTAssertEqual(run(4.1, 2.35).steps[2].answer?.known.first?.message, "0.1 means 1 tenth, which is 10 hundredths. Line up the points.")
        XCTAssertEqual(run(4.1, 2.35).steps[0].words.hint, "Write 4.1 as 4.10 so both numbers have hundredths.")
        XCTAssertEqual(run(4.15, 2.35).steps[0].words.hint, "Both already have hundredths, so the points line up.")
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in [0, 3] {
            for _ in 0..<300 {
                let n = AddDecimals.spec.generate(&rng, index), a = n["a"]!, b = n["b"]!
                XCTAssertEqual(a * 10, (a * 10).rounded(), accuracy: 1e-9); XCTAssertEqual(b * 100, (b * 100).rounded(), accuracy: 1e-9)
                XCTAssertTrue((1.1...99.9).contains(a) && (1.01...99.99).contains(b), "\(n)")
                if index < 3 { XCTAssertLessThan(a, 10); XCTAssertLessThan(b, 10) }
                let s = AddDecimals.Parts(n)
                XCTAssertEqual(Double(s.W) + s.D, s.sum, accuracy: 1e-9)
                XCTAssertEqual(LessonRun(AddDecimals.spec, numbers: n).steps[3].answer!.expected["x"]!, ((a + b) * 100).rounded() / 100, accuracy: 1e-9)
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = AddDecimals.spec.check
        XCTAssertEqual(items.map(\.index), [3, 3, 3, 3]); XCTAssertEqual(items.map(\.story), [false, false, false, true])
        for item in items { for _ in 0..<300 {
            let n = item.draw(AddDecimals.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true, "\(n)")
        } }
    }
}
