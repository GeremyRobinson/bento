import XCTest
@testable import ObentoCore

/// 1st grade, chapter 1: Add and take away to 20 (design/grade1.md, the preview design/prototype/grade1-ch1.html).
final class AddSub1Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(17 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        XCTAssertTrue(Curriculum.isLive(1))
        XCTAssertEqual(Curriculum.chapters(1).count, 6)
        XCTAssertEqual(Curriculum.chapters(1).flatMap(\.lessons).count, 26)
        let ch = Curriculum.chapters(1)[0]
        XCTAssertEqual(ch.title, "Add and take away to 20")
        XCTAssertTrue(Curriculum.built(ch))
        XCTAssertTrue(Curriculum.built(Curriculum.chapters(1)[2])); XCTAssertFalse(Curriculum.built(Curriculum.chapters(1)[3]))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)); XCTAssertEqual(Curriculum.grade(of: l.id), 1) }
        XCTAssertEqual(Curriculum.gradeTest(1), "test-grade-1")
    }

    // MARK: Add within 20

    func testAdd20() {
        // the turn-around: 3 + 9
        var l = LessonRun(Add20.spec, numbers: Add20.numbers(a: 3, b: 9))
        XCTAssertEqual(l.words.say, "Drag the bigger row down to the line.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["r": 1]), .notYet("That works, but it's a long count. Start at 9, then count on only 3."))
        XCTAssertEqual(move(&l, ["r": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop on: one hop for each counter.")
        XCTAssertEqual(move(&l, ["h": -1]), .notYet("Hop forward to add."))
        XCTAssertEqual(move(&l, ["h": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the number that goes in the box.")
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("One short. Don't count 9 again: your first hop lands on 10."))
        XCTAssertEqual(move(&l, ["x": 13]), .notYet("One too many. Make exactly 3 hops: 10, 11, 12."))
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("That's taking away. Adding makes the number bigger."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Not quite. Say 9, then count 3 more: one number for each."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(3))
        XCTAssertEqual(l.words.say, "Start big, so there are fewer hops.")
        XCTAssertTrue(Add20.Parts(l.numbers).swapped)
    }

    func testAdd20Generator() {
        for i in 0..<12 {
            each(Add20.spec, i) { x in
                let P = Add20.Parts(x)
                XCTAssertTrue((2...(i < 3 ? 3 : 5)).contains(P.small)); XCTAssertGreaterThan(P.big, P.small)
                XCTAssertTrue((11...20).contains(P.sum))
            }
        }
        let c = checks(Add20.spec).map(Add20.Parts.init)
        XCTAssertLessThan(c[0].a, c[0].b); XCTAssertLessThan(c[1].a, c[1].b); XCTAssertGreaterThan(c[2].a, c[2].b); XCTAssertGreaterThanOrEqual(c[3].small, 4)
    }

    // MARK: Make a ten to add

    func testTen() {
        var l = LessonRun(MakeTen1.spec, numbers: MakeTen1.numbers(a: 8, b: 5))
        XCTAssertEqual(l.words.say, "Slide counters up to fill the top row.")
        XCTAssertEqual(move(&l, ["f": 2]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That's only the ones left over. The full row is 10 more."))
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("Not quite. 10 plus 3 is ten and 3 more."))
        XCTAssertEqual(move(&l, ["x": 13]), .moved(2))
        XCTAssertEqual(l.words.say, "A full ten makes the rest easy to add.")
    }

    func testTenGenerator() {
        for i in 0..<12 {
            each(MakeTen1.spec, i) { x in
                let P = MakeTen1.Parts(x)
                XCTAssertTrue((i < 3 ? 8...9 : 6...9).contains(P.a)); XCTAssertGreaterThan(P.sum, 10); XCTAssertLessThanOrEqual(P.b, i < 3 ? 6 : 9)
                XCTAssertEqual(MakeTen1.Parts(MakeTen1.numbers(a: P.a, b: P.b)).sum, P.sum)
            }
        }
        let c = checks(MakeTen1.spec).map(MakeTen1.Parts.init)
        XCTAssertEqual(c[0].a, 9); XCTAssertTrue((6...7).contains(c[1].a)); XCTAssertGreaterThanOrEqual(c[2].b, 7)
    }

    // MARK: Doubles and near doubles

    func testDouble() {
        var l = LessonRun(Doubles1.spec, numbers: Doubles1.numbers(a: 5, b: 5))
        XCTAssertEqual(l.words.say, "Slide the bottom row to the start line.")
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the number that goes in the box.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That's one 5. Double 5 is 5 and 5."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("A double is the same number twice: 5 and 5 more."))
        XCTAssertEqual(move(&l, ["x": 10]), .moved(2))
        XCTAssertEqual(l.words.say, "The same number twice.")
    }

    func testNearDouble() {
        var l = LessonRun(Doubles1.spec, numbers: Doubles1.numbers(a: 6, b: 7))
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the numbers that go in the boxes.")
        XCTAssertEqual(move(&l, ["d": 6]), .notYet("That's one 6. Double 6 is 6 and 6."))
        XCTAssertEqual(move(&l, ["d": 12]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("That's the double. Add the extra one."))
        XCTAssertEqual(move(&l, ["x": 14]), .notYet("14 is double 7. Double 6 is 12, then 1 more."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("Not quite. Double 6 is 12, then 1 more."))
        XCTAssertEqual(move(&l, ["x": 13]), .moved(3))
        XCTAssertEqual(l.words.say, "6 + 7 is double 6 and 1 more.")
    }

    func testDoublesGenerator() {
        for i in 0..<12 {
            each(Doubles1.spec, i) { x in
                let P = Doubles1.Parts(x)
                if i < 3 { XCTAssertTrue(P.dbl && (1...5).contains(P.d)) }
                else if i < 6 { XCTAssertTrue(!P.dbl && (2...5).contains(P.d)) }
                else { XCTAssertTrue((2...9).contains(P.d)) }
                XCTAssertLessThanOrEqual(abs(P.a - P.b), 1); XCTAssertLessThanOrEqual(P.sum, 19)
            }
        }
        let c = checks(Doubles1.spec).map(Doubles1.Parts.init)
        XCTAssertTrue(c[2].dbl && c[2].d >= 6); XCTAssertTrue(!c[3].dbl && c[3].a > c[3].b)
    }

    // MARK: Add three numbers

    func testThreePick() {
        // 7 + 5 + 3: 7 and 3 make 10, the only friendly pair, so the child picks it
        let x = Three1.numbers(7, 5, 3)
        let P = Three1.Parts(x)
        XCTAssertTrue(P.choose); XCTAssertEqual(P.why, .ten); XCTAssertEqual(P.pairCode, Three1.code(0, 2))
        var l = LessonRun(Three1.spec, numbers: x)
        XCTAssertEqual(l.words.say, "Tap two that make 10.")
        XCTAssertEqual(move(&l, ["p": Double(Three1.code(0, 1))]), .notYet("7 and 5 make 12. Look for two that make 10."))
        XCTAssertEqual(move(&l, ["p": Double(Three1.code(0, 2))]), .moved(1))
        XCTAssertEqual(l.words.say, "Slide the two into the top row.")
        XCTAssertEqual(move(&l, ["s": -1]), .notYet("Slide in the two that make 10 first."))
        XCTAssertEqual(move(&l, ["s": Double(Three1.code(0, 2))]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide the last group in.")
        XCTAssertEqual(move(&l, ["z": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("That's only two of the numbers. Add the 5 too."))
        XCTAssertEqual(move(&l, ["x": 14]), .notYet("Count on from 10: 11, 12, 13, 14, 15."))
        XCTAssertEqual(move(&l, ["x": 20]), .notYet("You added the 5 twice."))
        XCTAssertEqual(move(&l, ["x": 18]), .notYet("You added the 3 twice."))
        XCTAssertEqual(move(&l, ["x": 15]), .moved(4))
        XCTAssertEqual(l.words.say, "Any order works, so make 10 first.")
    }

    func testThreeLitAndStory() {
        // 2 + 3 + 4: no ten, no double: the first two are lit and named
        var l = LessonRun(Three1.spec, numbers: Three1.numbers(2, 3, 4, story: true))
        let P = Three1.Parts(l.numbers)
        XCTAssertFalse(P.choose)
        XCTAssertEqual(l.words.say, "Ana has 2 plain, 3 striped and 4 spotted beads. How many beads in all? No ten and no double, so add the first two. Slide these two into the top row.")
        XCTAssertEqual(move(&l, ["s": -1]), .notYet("Slide in the first two first."))
        XCTAssertEqual(move(&l, ["s": Double(Three1.code(0, 1))]), .moved(1))
        // the first two slid in, though the lit pair was another: the web accepts both, and the slips count from them
        let q = Three1.Parts(Three1.numbers(4, 3, 6))
        XCTAssertEqual(q.allowed, [Three1.code(0, 1), Three1.code(0, 2)])
        XCTAssertEqual(q.wrote(7, pair: Three1.code(0, 1)), "That's only two of the numbers. Add the 6 too.")
        XCTAssertEqual(q.wrote(10, pair: Three1.code(0, 2)), "That's only two of the numbers. Add the 3 too.")
    }

    func testThreeGenerator() {
        for i in 0..<12 {
            each(Three1.spec, i) { x in
                let P = Three1.Parts(x)
                XCTAssertTrue(P.v.allSatisfy { (1...9).contains($0) }); XCTAssertLessThanOrEqual(P.sum, i < 3 ? 12 : 20)
                XCTAssertEqual(P.story, i % 3 == 2)
                XCTAssertNotEqual(P.v[0] + P.v[1], 10)
            }
        }
        let c = checks(Three1.spec).map(Three1.Parts.init)
        XCTAssertTrue(c[0].choose && c[0].why == .ten); XCTAssertTrue(c[1].choose && c[1].why == .double); XCTAssertTrue(c[2].choose); XCTAssertTrue(c[3].story)
        for p in c { XCTAssertEqual(LessonRun(Three1.spec, numbers: Three1.numbers(p.v[0], p.v[1], p.v[2])).steps.count, p.choose ? 5 : 4) }
    }

    // MARK: Subtract within 20

    func testSub20() {
        var l = LessonRun(Sub20.spec, numbers: Sub20.numbers(a: 14, b: 6))
        XCTAssertEqual(l.words.say, "Hop back to 10.")
        XCTAssertEqual(move(&l, ["t": 12]), .notYet("Hop all the way back to 10. 14 is 10 and 4 more."))
        XCTAssertEqual(move(&l, ["t": 9]), .notYet("Stop at 10 first."))
        XCTAssertEqual(move(&l, ["t": 10]), .moved(1))
        XCTAssertEqual(l.words.say, "Now hop back the rest.")
        XCTAssertEqual(move(&l, ["r": 7]), .notYet("That takes 7. Take 6."))
        XCTAssertEqual(move(&l, ["r": 6]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("This is taking away, so the answer is less than 10. Count back 2 from 10."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("Count back one for each: start at 9, not 10."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Count back exactly 2."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(3))
        XCTAssertEqual(l.words.say, "Back to 10 first, because taking from 10 is easy.")
    }

    func testSub20Generator() {
        for i in 0..<12 {
            each(Sub20.spec, i) { x in
                let P = Sub20.Parts(x)
                XCTAssertTrue((11...(i < 3 ? 14 : 18)).contains(P.a)); XCTAssertGreaterThan(P.rest, 0); XCTAssertLessThan(P.left, 10)
            }
        }
        let c = checks(Sub20.spec).map(Sub20.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].a, 15); XCTAssertGreaterThanOrEqual(c[2].rest, 4); XCTAssertEqual(c[3].b, 9)
    }

    func testSpoken() {
        XCTAssertEqual(Spoken.text("6 + 7 is double 6 and 1 more."), "6 plus 7 is double 6 and 1 more.")
    }
}
