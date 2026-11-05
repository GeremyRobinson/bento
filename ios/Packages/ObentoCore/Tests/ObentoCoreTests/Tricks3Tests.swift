import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 2: Times-table tricks (design/grade3.md, the preview design/prototype/grade3-ch2.html).
final class Tricks3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(91 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[1]
        XCTAssertEqual(ch.title, "Times-table tricks")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testSplit() {
        var l = LessonRun(Split3.spec, numbers: Split3.numbers(a: 7, b: 8))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Cut after 5.")
        XCTAssertEqual(move(&l, ["k": 4]), .notYet("4 | 4. Cut after 5: 5s are easy."))
        XCTAssertEqual(move(&l, ["k": 5]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 7 × 5.")
        XCTAssertEqual(move(&l, ["f": 12]), .notYet("× means 7 groups of 5, not 7 + 5."))
        XCTAssertEqual(move(&l, ["f": 30]), .notYet("Not quite. Count by 5s, 7 times."))
        XCTAssertEqual(move(&l, ["f": 35]), .moved(2))
        XCTAssertEqual(l.words.say, "Write 7 × 3.")
        XCTAssertEqual(move(&l, ["r": 10]), .notYet("× means 7 groups of 3."))
        XCTAssertEqual(move(&l, ["r": 20]), .notYet("Not quite. 7 groups of 3."))
        XCTAssertEqual(move(&l, ["r": 21]), .moved(3))
        XCTAssertEqual(l.words.say, "Put them back together: write 35 + 21.")
        XCTAssertEqual(move(&l, ["s": 35]), .notYet("That's only the first part. Add the 7 rows of 3 too."))
        XCTAssertEqual(move(&l, ["s": 21]), .notYet("That's only the second part. Add the 7 rows of 5 too."))
        XCTAssertEqual(move(&l, ["s": 63]), .notYet("Check each part again: 7 rows of 3 is 21."))
        XCTAssertEqual(move(&l, ["s": 55]), .notYet("Not quite. 8 is 5 + 3, so add the two answers."))
        XCTAssertEqual(move(&l, ["s": 56]), .moved(4))
        XCTAssertEqual(l.words.say, "7 rows of 5 and 7 rows of 3 make 7 rows of 8.")
        for i in 0..<8 {
            each(Split3.spec, i) { x in
                let P = Split3.Parts(x)
                if i < 3 { XCTAssertTrue((2...5).contains(P.a) && (6...7).contains(P.b)) } else { XCTAssertTrue((3...9).contains(P.a) && (6...9).contains(P.b)) }
                XCTAssertLessThanOrEqual(P.c * max(P.a, P.b), 30)
                XCTAssertEqual(P.f5 + P.fr, P.P)
            }
        }
        let c = checks(Split3.spec).map(Split3.Parts.init)
        XCTAssertGreaterThanOrEqual(c[0].b, 8); XCTAssertGreaterThanOrEqual(c[1].a, 6)
    }

    func testThree() {
        // b × c first
        var l = LessonRun(Three3.spec, numbers: Three3.numbers(a: 3, b: 5, c: 2))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap the two to do first.")
        XCTAssertEqual(move(&l, ["w": 1]), .moved(1))
        l.keep("pick", 1)
        let P = Three3.Parts(l.numbers)
        XCTAssertEqual(P.say(1, true), "Write 5 × 2.")
        XCTAssertEqual(move(&l, ["p": 7]), .notYet("5 + 2 adds them. 5 groups of 2 is 5 × 2."))
        XCTAssertEqual(move(&l, ["p": 9]), .notYet("Not quite. Count the dots in one row."))
        XCTAssertEqual(move(&l, ["p": 10]), .moved(2))
        XCTAssertEqual(P.say(2, true), "Write 3 × 10.")
        XCTAssertEqual(move(&l, ["t": 10]), .notYet("3 + 5 + 2 adds them. Multiply all three."))
        XCTAssertEqual(move(&l, ["t": 6]), .notYet("That's 3 × 2. Each row has 10, not 2."))
        XCTAssertEqual(move(&l, ["t": 29]), .notYet("Not quite. Count by 10s, 3 times."))
        XCTAssertEqual(move(&l, ["t": 30]), .moved(3))
        XCTAssertEqual(l.words.say, "Either two first: 30 both ways.")
        // a × b first
        var m = LessonRun(Three3.spec, numbers: Three3.numbers(a: 3, b: 5, c: 2))
        XCTAssertEqual(move(&m, ["w": 2]), .moved(1))
        m.keep("pick", 2)
        XCTAssertEqual(P.say(1, false), "Write 3 × 5.")
        XCTAssertEqual(m.wanted(m.step.answer!), ["p": 15])
        XCTAssertEqual(move(&m, ["p": 10]), .notYet("Not quite. Count the groups."))
        XCTAssertEqual(move(&m, ["p": 8]), .notYet("3 + 5 adds them. 3 rows of 5 groups is 3 × 5."))
        XCTAssertEqual(move(&m, ["p": 15]), .moved(2))
        XCTAssertEqual(P.say(2, false), "Write 15 × 2.")
        XCTAssertEqual(move(&m, ["t": 15]), .notYet("15 is how many groups. Each group has 2."))
        XCTAssertEqual(move(&m, ["t": 30]), .moved(3))
        for i in 0..<8 {
            each(Three3.spec, i) { x in
                let P = Three3.Parts(x)
                if i < 3 { XCTAssertEqual(Set([P.b, P.c]), [2, 5]); XCTAssertTrue((2...4).contains(P.a)) }
                XCTAssertLessThanOrEqual(P.T, 60); XCTAssertLessThanOrEqual(P.bc, 15)
                XCTAssertLessThanOrEqual(P.bc * P.cell, 60)
            }
        }
        let c = checks(Three3.spec).map(Three3.Parts.init)
        XCTAssertEqual(c[0].bc, 10); XCTAssertEqual(c[1].ab, 10); XCTAssertGreaterThanOrEqual(c[2].T, 40)
    }

    func testDouble() {
        var l = LessonRun(Double3.spec, numbers: Double3.numbers(h: 2, n: 7))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Cut it into two equal halves.")
        XCTAssertEqual(move(&l, ["k": 3]), .notYet("21 and 7 aren't equal. Find the middle."))
        XCTAssertEqual(move(&l, ["k": 2]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 2 × 7.")
        XCTAssertEqual(move(&l, ["h": 9]), .notYet("2 + 7 adds them. 2 rows of 7 is 2 × 7."))
        XCTAssertEqual(move(&l, ["h": 28]), .notYet("That's all 4 rows. Write one half: 2 rows of 7."))
        XCTAssertEqual(move(&l, ["h": 14]), .moved(2))
        XCTAssertEqual(l.words.say, "Write 14 + 14.")
        XCTAssertEqual(move(&l, ["d": 14]), .notYet("14 is one half. Add the other half too."))
        XCTAssertEqual(move(&l, ["d": 18]), .notYet("14 + 14: add the tens, then the ones."))
        XCTAssertEqual(move(&l, ["d": 27]), .notYet("Not quite. Count on 14 from 14."))
        XCTAssertEqual(move(&l, ["d": 28]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap Even or Odd.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Two equal halves and no dot left over: even."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(4))
        XCTAssertEqual(l.words.say, "Two equal halves: every 4s fact is even.")
        XCTAssertEqual(Double3.Parts(Double3.numbers(h: 2, n: 7)).table, [4, 8, 12, 16, 20, 24, 28, 32, 36, 40])
        for i in 0..<8 {
            each(Double3.spec, i) { x in
                let P = Double3.Parts(x)
                if i < 3 { XCTAssertEqual(P.h, 2); XCTAssertTrue((2...5).contains(P.n)) } else { XCTAssertTrue((2...4).contains(P.h) && (3...9).contains(P.n)) }
                XCTAssertEqual(P.P % 2, 0)
                XCTAssertLessThanOrEqual(P.c * max(P.rows, P.n), 36)
            }
        }
        let c = checks(Double3.spec).map(Double3.Parts.init)
        XCTAssertEqual(c.map(\.h).prefix(3), [2, 3, 4]); XCTAssertEqual(c[3].n % 2, 1)
    }

    func testTens() {
        var l = LessonRun(Tens3.spec, numbers: Tens3.numbers(a: 4, t: 30))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Drag down to make 4 rows of 3 tens.")
        XCTAssertEqual(move(&l, ["r": 5]), .notYet("That's 5 rows. 4 × 30 is 4 rows of 3 tens."))
        XCTAssertEqual(move(&l, ["r": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 4 × 3: how many tens?")
        XCTAssertEqual(move(&l, ["f": 7]), .notYet("× means groups: 4 groups of 3, not 4 + 3."))
        XCTAssertEqual(move(&l, ["f": 12]), .moved(2))
        XCTAssertEqual(l.words.say, "Ten tens make a hundred. Write 4 × 30.")
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("12 is how many tens. Each ten is 10, so 12 tens is 120."))
        XCTAssertEqual(move(&l, ["x": 1200]), .notYet("12 tens is 12 × 10, which is 120. You wrote 12 hundreds."))
        XCTAssertEqual(move(&l, ["x": 34]), .notYet("4 groups of 30 is much more than 4 + 30."))
        XCTAssertEqual(move(&l, ["x": 120]), .moved(3))
        XCTAssertEqual(l.words.say, "12 tens is 120: tens count like ones.")
        XCTAssertEqual(Tens3.Parts(Tens3.numbers(a: 4, t: 30)).folded, "1 hundred and 2 tens")
        XCTAssertEqual(Tens3.Parts(Tens3.numbers(a: 5, t: 40)).folded, "2 hundreds")
        XCTAssertEqual(LessonRun(Tens3.spec, numbers: Tens3.numbers(a: 2, t: 30)).steps[2].words.say, "Write 2 × 30.")
        for i in 0..<8 {
            each(Tens3.spec, i) { x in
                let P = Tens3.Parts(x), hi = i < 3 ? 5 : 9
                XCTAssertTrue((2...hi).contains(P.a) && (2...hi).contains(P.m))
                XCTAssertEqual(P.P, P.f * 10)
            }
        }
        let c = checks(Tens3.spec).map(Tens3.Parts.init)
        XCTAssertLessThan(c[0].f, 10); XCTAssertGreaterThanOrEqual(c[1].f, 10); XCTAssertEqual(c[2].f % 10, 0)
    }
}
