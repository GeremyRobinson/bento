import XCTest
@testable import ObentoCore

/// 1st grade, chapter 3: Numbers to 120 (design/grade1.md, the preview design/prototype/grade1-ch3.html).
final class Numbers1Tests: XCTestCase {
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
        let ch = Curriculum.chapters(1)[2]
        XCTAssertEqual(ch.title, "Numbers to 120")
        XCTAssertEqual(ch.colour, "decimals")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
    }

    // MARK: Count to 120

    func testCountOn() {
        let P = Count120.Parts(Count120.numbers(on: 97, more: 6))
        XCTAssertEqual(P.boxed, [100, 101])
        XCTAssertEqual(P.r0, 8); XCTAssertEqual(P.rows, 4)
        var l = LessonRun(Count120.spec, numbers: Count120.numbers(on: 97, more: 6))
        XCTAssertEqual(l.words.say, "Drag along the empty places to count on.")
        XCTAssertEqual(move(&l, ["k": -1]), .notYet("You skipped one. Touch each place."))
        XCTAssertEqual(move(&l, ["k": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Write the number that goes in the box.")
        XCTAssertEqual(move(&l, ["x0": 1000]), .notYet("100 is 10 tens: 1, 0, 0."))
        XCTAssertEqual(move(&l, ["x0": 910]), .notYet("After 99 comes a new ten: 100."))
        XCTAssertEqual(move(&l, ["x0": 99]), .notYet("Touch each place once."))
        XCTAssertEqual(move(&l, ["x0": 7]), .notYet("Count on from 97 to the box."))
        XCTAssertEqual(move(&l, ["x0": 100]), .moved(2))
        XCTAssertEqual(move(&l, ["x1": 1001]), .notYet("101 is 100 and 1 more: 1, 0, 1."))
        XCTAssertEqual(move(&l, ["x1": 101]), .moved(3))
        XCTAssertEqual(l.words.say, "Ten tens is 100, and counting goes on.")
        let Q = Count120.Parts(Count120.numbers(on: 37, more: 5))
        XCTAssertEqual(Q.boxed, [40, 42])
        XCTAssertEqual(Q.slips(40).first?.0, 310)
        XCTAssertEqual(Q.why, "After 9 ones comes a new ten.")
        XCTAssertEqual(Count120.Parts(Count120.numbers(on: 105, more: 6)).slips(110).first?.0, 10010)
    }

    func testHowMany() {
        var l = LessonRun(Count120.spec, numbers: Count120.numbers(many: 113))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap each full row to count by tens.")
        XCTAssertEqual(move(&l, ["r": -2]), .notYet("That row has only 3. Tap the full rows first."))
        XCTAssertEqual(move(&l, ["r": -1]), .notYet("Count the rows in order, from the top."))
        XCTAssertEqual(move(&l, ["r": 11]), .moved(1))
        XCTAssertEqual(l.words.say, "Now drag along the rest to count on.")
        XCTAssertEqual(move(&l, ["k": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many are shaded.")
        XCTAssertEqual(move(&l, ["x": 1103]), .notYet("113 is 11 tens and 3: 1, 1, 3."))
        XCTAssertEqual(move(&l, ["x": 110]), .notYet("That's only the full rows. Count on the rest too."))
        XCTAssertEqual(move(&l, ["x": 50]), .notYet("Count the full rows by tens, then the rest by ones."))
        XCTAssertEqual(move(&l, ["x": 113]), .moved(3))
        XCTAssertEqual(l.words.say, "Ten tens is 100, and counting goes on.")
        XCTAssertEqual(LessonRun(Count120.spec, numbers: Count120.numbers(many: 40)).steps.count, 3)
        XCTAssertEqual(Count120.Parts.window(0), 0); XCTAssertEqual(Count120.Parts.window(4), 3); XCTAssertEqual(Count120.Parts.window(11), 8)
    }

    func testCountGenerator() {
        for i in 0..<12 {
            each(Count120.spec, i) { x in
                let P = Count120.Parts(x)
                if i >= 6 && (i - 6) % 3 == 0 { XCTAssertTrue(P.many); XCTAssertTrue((21...120).contains(P.n)); return }
                XCTAssertFalse(P.many); XCTAssertLessThanOrEqual(P.last, 120); XCTAssertLessThanOrEqual(P.rows, 4)
                XCTAssertEqual(Set(P.boxed).count, 2); XCTAssertTrue(P.boxed.allSatisfy { P.places.contains($0) })
                if i < 3 { XCTAssertEqual(P.m, 5); XCTAssertTrue(P.places.contains { $0 % 10 == 0 }); XCTAssertLessThan(P.last, 100) }
                else if i < 6 { XCTAssertTrue(P.places.contains(101)); XCTAssertTrue(P.boxed.contains(101)) }
            }
        }
        let c = checks(Count120.spec).map(Count120.Parts.init)
        XCTAssertTrue(c[0].places.contains(100)); XCTAssertTrue(c[2].many && c[2].n > 100)
    }

    // MARK: Tens and ones

    func testTensOnes() {
        var l = LessonRun(TensOnes1.spec, numbers: TensOnes1.numbers(n: 34))
        XCTAssertEqual(l.words.say, "Tap each full row to make a ten.")
        XCTAssertEqual(move(&l, ["g": -1]), .notYet("That's only 4. A ten needs 10."))
        XCTAssertEqual(move(&l, ["g": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Now count the ones.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That's a ten. Count the ones on their own."))
        XCTAssertEqual(move(&l, ["c": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Each ten is worth 10, not 1. 3 tens is 30."))
        XCTAssertEqual(move(&l, ["x": 43]), .notYet("The tens come first. Write 3, then 4."))
        XCTAssertEqual(move(&l, ["x": 30]), .notYet("That's only the tens. Add the 4 ones too."))
        XCTAssertEqual(move(&l, ["x": 34]), .moved(3))
        XCTAssertEqual(l.words.say, "The first digit counts tens; the second counts ones.")
        let z = LessonRun(TensOnes1.spec, numbers: TensOnes1.numbers(n: 50))
        XCTAssertEqual(z.steps.count, 3)
        XCTAssertEqual(z.steps[1].words.say, "No ones on their own. Write the number that goes in the box.")
        for i in 0..<12 { each(TensOnes1.spec, i) { XCTAssertTrue((11...(i < 3 ? 39 : 99)).contains(TensOnes1.Parts($0).n)) } }
        let c = checks(TensOnes1.spec).map(TensOnes1.Parts.init)
        XCTAssertGreaterThanOrEqual(c[0].t, 4); XCTAssertEqual(c[1].o, 0); XCTAssertGreaterThan(c[2].o, c[2].t)
    }

    // MARK: Compare

    func testCompare() {
        var l = LessonRun(Compare1.spec, numbers: Compare1.numbers(a: 52, b: 39))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Tap the number with more tens.")
        XCTAssertEqual(move(&l, ["p": 1]), .notYet("52 has 5 tens and 39 has 3. 5 tens is more."))
        XCTAssertEqual(move(&l, ["p": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the sign that goes between them.")
        XCTAssertEqual(move(&l, ["g": 0]), .notYet("The open side faces the bigger number, 52."))
        XCTAssertEqual(move(&l, ["g": 1]), .notYet("52 and 39 are not the same number."))
        XCTAssertEqual(move(&l, ["g": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "More tens is bigger; with the same tens, more ones is bigger.")

        var s = LessonRun(Compare1.spec, numbers: Compare1.numbers(a: 43, b: 47))
        XCTAssertEqual(s.steps.count, 4)
        XCTAssertEqual(move(&s, ["p": 0]), .moved(1))
        XCTAssertEqual(s.words.say, "Same tens: 4 and 4. Look at the ones. Tap the number with more ones.")
        XCTAssertEqual(move(&s, ["p": 0]), .notYet("47 has 7 ones and 43 has 3. 7 ones is more."))
        XCTAssertEqual(move(&s, ["p": 1]), .moved(2))
        XCTAssertEqual(move(&s, ["g": 0]), .moved(3))

        var e = LessonRun(Compare1.spec, numbers: Compare1.numbers(a: 61, b: 61))
        XCTAssertEqual(move(&e, ["p": 1]), .moved(1))
        XCTAssertEqual(move(&e, ["p": 1]), .moved(2))
        XCTAssertEqual(e.words.say, "Same tens, same ones. Tap the sign that goes between them.")
        XCTAssertEqual(move(&e, ["g": 0]), .notYet("Same tens and same ones, so the numbers are equal."))
        XCTAssertEqual(move(&e, ["g": 1]), .moved(3))

        for i in 0..<3 { each(Compare1.spec, i) { XCTAssertFalse(Compare1.Parts($0).same) } }
        let c = checks(Compare1.spec).map(Compare1.Parts.init)
        XCTAssertGreaterThan(Num1.ones(c[0].sn), Num1.ones(c[0].bn)); XCTAssertTrue(c[2].same && c[2].a > c[2].b); XCTAssertTrue(c[3].same && c[3].a < c[3].b)
    }

    // MARK: 10 more, 10 less

    func testTenMore() {
        var l = LessonRun(TenMore1.spec, numbers: TenMore1.numbers(n: 34, more: true))
        XCTAssertEqual(l.words.say, "Drag the ring to 10 more.")
        XCTAssertEqual(move(&l, ["d": -10]), .notYet("That's 10 less. Go down for 10 more."))
        XCTAssertEqual(move(&l, ["d": 1]), .notYet("That's 1 more. 10 more is one row down."))
        XCTAssertEqual(move(&l, ["d": 10]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 35]), .notYet("That's 1 more. For 10 more, change the tens and keep the 4 ones."))
        XCTAssertEqual(move(&l, ["x": 24]), .notYet("That's 10 less. You want 10 more."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That's only the tens. Put the 4 ones back on the end."))
        XCTAssertEqual(move(&l, ["x": 54]), .notYet("4 tens and 4 ones."))
        XCTAssertEqual(move(&l, ["x": 44]), .moved(2))
        XCTAssertEqual(l.words.say, "One row down is one more ten; the ones stay.")

        var d = LessonRun(TenMore1.spec, numbers: TenMore1.numbers(n: 60, more: false))
        XCTAssertEqual(move(&d, ["d": 2]), .notYet("That's 2 more. 10 less is one row up."))
        XCTAssertEqual(move(&d, ["d": -10]), .moved(1))
        XCTAssertEqual(move(&d, ["x": 5]), .notYet("That's only the tens. Put the 0 back in the ones place."))
        XCTAssertEqual(move(&d, ["x": 50]), .moved(2))
        XCTAssertEqual(d.words.say, "One row up is one ten less; the ones stay.")

        for i in 0..<12 {
            each(TenMore1.spec, i) { x in
                let P = TenMore1.Parts(x)
                if i < 2 { XCTAssertTrue(P.more) }
                if i < 3 { XCTAssertLessThanOrEqual(P.n, 49) }
                if i < 4 { XCTAssertNotEqual(P.o, 0) }
                XCTAssertTrue((10...99).contains(P.res))
            }
        }
        let c = checks(TenMore1.spec).map(TenMore1.Parts.init)
        XCTAssertTrue(c[0].more); XCTAssertFalse(c[1].more); XCTAssertEqual(c[2].o, 0); XCTAssertTrue(!c[3].more && c[3].n >= 50)
    }
}
