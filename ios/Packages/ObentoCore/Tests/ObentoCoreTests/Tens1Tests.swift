import XCTest
@testable import ObentoCore

/// 1st grade, chapter 4: Adding and taking away tens (design/grade1.md, the preview design/prototype/grade1-ch4.html).
final class Tens1Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(41 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(1)[3]
        XCTAssertEqual(ch.title, "Adding and taking away tens")
        XCTAssertEqual(ch.colour, "whole")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
    }

    // MARK: Add tens to a number

    func testAddTens() {
        var l = LessonRun(AddTens1.spec, numbers: AddTens1.numbers(a: 23, b: 30))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Slide the new tens onto the tens.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Tens go with the tens."))
        XCTAssertEqual(move(&l, ["t": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Write the number that goes in the box.")
        XCTAssertEqual(move(&l, ["x": 26]), .notYet("You added 3 ones. 30 is 3 tens, so the tens go up by 3."))
        XCTAssertEqual(move(&l, ["x": 50]), .notYet("Don't forget the 3 ones from 23."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("5 tens is 50. Then the 3 ones."))
        XCTAssertEqual(move(&l, ["x": 63]), .notYet("5 tens and 3 ones."))
        XCTAssertEqual(move(&l, ["x": 53]), .moved(2))
        XCTAssertEqual(l.words.say, "Tens join the tens, so the ones stay the same.")
        XCTAssertEqual(AddTens1.Parts(AddTens1.numbers(a: 23, b: 30), tensOnly: true).summary, "2 tens and 3 tens: 5 tens")
        for i in 0..<12 {
            each(AddTens1.spec, i) { x in
                let P = AddTens1.Parts(x, tensOnly: true)
                XCTAssertEqual(P.b % 10, 0); XCTAssertNotEqual(P.ao, 0); XCTAssertLessThanOrEqual(P.sum, 99)
                if i < 3 { XCTAssertLessThanOrEqual(P.ta, 4); XCTAssertTrue((2...3).contains(P.tb)) }
                XCTAssertEqual(P.a, x["a"].map { Int($0) }); XCTAssertEqual(P.b, x["b"].map { Int($0) })
            }
        }
        let c = checks(AddTens1.spec).map { AddTens1.Parts($0, tensOnly: true) }
        XCTAssertGreaterThanOrEqual(c[2].ta, 5); XCTAssertEqual(c[3].tb, 1)
    }

    // MARK: Add within 100

    func testAdd100() {
        var l = LessonRun(AddTens1.spec100, numbers: AddTens1.numbers(a: 36, b: 7))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Slide the ones onto the ones.")
        XCTAssertEqual(move(&l, ["o": -1]), .notYet("Ones go with the ones."))
        XCTAssertEqual(move(&l, ["o": 7]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 33]), .notYet("The 6 and 7 ones made a new ten."))
        XCTAssertEqual(move(&l, ["x": 106]), .notYet("7 is ones. It goes with the 6 ones."))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("Each ten is worth 10, not 1."))
        XCTAssertEqual(move(&l, ["x": 42]), .notYet("Count on again."))
        XCTAssertEqual(move(&l, ["x": 43]), .moved(2))
        XCTAssertEqual(l.words.say, "Ones go with ones, and ten ones make a new ten.")
        let P = AddTens1.Parts(AddTens1.numbers(a: 36, b: 7), tensOnly: false)
        XCTAssertEqual(P.summary, "36 + 4 = 40, then 3 more"); XCTAssertTrue(P.split)
        XCTAssertEqual(AddTens1.Parts(AddTens1.numbers(a: 36, b: 4), tensOnly: false).summary, "36 + 4 = 40: a new ten")
        XCTAssertFalse(AddTens1.Parts(AddTens1.numbers(a: 36, b: 4), tensOnly: false).split)

        var t = LessonRun(AddTens1.spec100, numbers: AddTens1.numbers(a: 24, b: 35))
        XCTAssertEqual(t.steps.count, 4)
        XCTAssertEqual(t.words.say, "Slide the tens onto the tens.")
        XCTAssertEqual(move(&t, ["t": -2]), .notYet("Tens first: slide the tens onto the tens."))
        XCTAssertEqual(move(&t, ["t": 3]), .moved(1))
        XCTAssertEqual(move(&t, ["o": 5]), .moved(2))
        XCTAssertEqual(move(&t, ["x": 77]), .notYet("Tens go with tens: 2 tens and 3 tens."))
        XCTAssertEqual(move(&t, ["x": 14]), .notYet("Each ten is worth 10, not 1."))
        XCTAssertEqual(move(&t, ["x": 59]), .moved(3))
        XCTAssertEqual(t.words.say, "Ones go with ones, and tens go with tens.")
        XCTAssertEqual(AddTens1.Parts(AddTens1.numbers(a: 24, b: 35), tensOnly: false).summary, "5 tens and 9 ones")

        for i in 0..<12 {
            each(AddTens1.spec100, i) { x in
                let P = AddTens1.Parts(x, tensOnly: false)
                XCTAssertLessThanOrEqual(P.sum, 99)
                if i < 3 { XCTAssertFalse(P.newTen); XCTAssertEqual(P.tb, 0) }
                if (3..<6).contains(i) { XCTAssertTrue(P.newTen); XCTAssertEqual(P.tb, 0) }
                if i >= 6 && (i - 6) % 3 == 0 { XCTAssertGreaterThan(P.tb, 0); XCTAssertFalse(P.newTen) }
                if P.tb > 0 { XCTAssertFalse(P.newTen) }
                XCTAssertEqual(P.a, x["a"].map { Int($0) }); XCTAssertEqual(P.b, x["b"].map { Int($0) })
            }
        }
        let c = checks(AddTens1.spec100).map { AddTens1.Parts($0, tensOnly: false) }
        XCTAssertFalse(c[0].newTen); XCTAssertTrue(c[1].newTen); XCTAssertEqual(c[2].left, 0); XCTAssertGreaterThan(c[3].tb, 0)
    }

    // MARK: Take away tens

    func testSubTens() {
        var l = LessonRun(SubTens1.spec, numbers: SubTens1.numbers(a: 70, b: 30))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Slide the tens away, one at a time.")
        XCTAssertEqual(move(&l, ["k": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the tens that are left.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That's 4 tens. Take 3."))
        XCTAssertEqual(move(&l, ["c": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That's 4 tens. 4 tens is written 40."))
        XCTAssertEqual(move(&l, ["x": 67]), .notYet("30 is 3 tens, not 3 ones."))
        XCTAssertEqual(move(&l, ["x": 100]), .notYet("That's adding."))
        XCTAssertEqual(move(&l, ["x": 30]), .notYet("Count the tens that are left."))
        XCTAssertEqual(move(&l, ["x": 40]), .moved(3))
        XCTAssertEqual(l.words.say, "It's 7 − 3, but in tens.")
        var z = LessonRun(SubTens1.spec, numbers: SubTens1.numbers(a: 50, b: 50))
        XCTAssertEqual(z.steps.count, 3)
        XCTAssertEqual(move(&z, ["k": 5]), .moved(1))
        XCTAssertEqual(move(&z, ["x": 0]), .moved(2))
        for i in 0..<12 {
            each(SubTens1.spec, i) { x in
                let P = SubTens1.Parts(x)
                XCTAssertGreaterThanOrEqual(P.res, 0)
                if i < 3 { XCTAssertTrue((40...90).contains(P.a)); XCTAssertTrue((10...30).contains(P.b)) }
                XCTAssertEqual(P.a, x["a"].map { Int($0) }); XCTAssertEqual(P.b, x["b"].map { Int($0) })
            }
        }
        let c = checks(SubTens1.spec).map(SubTens1.Parts.init)
        XCTAssertEqual(c[1].L, 0); XCTAssertEqual(c[2].L, 1)
    }
}
