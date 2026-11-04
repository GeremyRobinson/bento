import XCTest
@testable import ObentoCore

/// 6th grade, chapter 3: Long division and decimals (design/grade6.md, the preview design/prototype/grade6-ch3.html).
final class DecimalsG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(53 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[2]
        XCTAssertEqual(ch.title, "Long division and decimals")
        XCTAssertEqual(ch.test, "test-g6-decimals")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
    }

    func testDec() {
        XCTAssertEqual(Dec6(864, 2).s, "8.64"); XCTAssertEqual(Dec6(5, 2).s, "0.05"); XCTAssertEqual(Dec6(4500, 2).s, "45")
        XCTAssertEqual(Dec6(975, 1).times10(1).s, "975"); XCTAssertEqual(Dec6(15, 0).times10(-1).s, "1.5")
        XCTAssertEqual(Dec6(12375, 3).digit(1), 1); XCTAssertEqual(Dec6(12375, 3).digit(-3), 5); XCTAssertEqual(Dec6(124, 1).digit(-2), 0)
        XCTAssertEqual(Dec6(96, 2).intDigits, 1)
    }

    // MARK: Long division

    func testLongDivision() {
        var l = LessonRun(LongDivision6.spec, numbers: LongDivision6.numbers(d: 23, q: 324))
        let plan = LongDivision6.Parts(l.numbers).plan
        XCTAssertEqual(plan.j0, 1); XCTAssertEqual(plan.places.map(\.qd), [3, 2, 4]); XCTAssertEqual(plan.places.map(\.A), [74, 55, 92])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Start where 23 goes in.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("23 doesn’t go into 7. Take one more digit."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Fewer digits: 23 already goes into 74."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Drag down a row of 23 at a time.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("4 rows is 92. There are only 74."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("28 are left: another row fits."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Write what’s left.")
        XCTAssertEqual(typeAll(&l, [("l", "4")]), .notYet("74 − 69: count the squares not filled in."))
        XCTAssertEqual(typeAll(&l, [("l", "5")]), .moved(4))
        XCTAssertEqual(l.words.say, "5 hundreds left = 50 tens, and 5 more: 55 tens. Drag down a row of 23 at a time.")
        XCTAssertEqual(move(&l, ["x": 2]), .moved(5)); XCTAssertEqual(typeAll(&l, [("l", "9")]), .moved(6))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(7)); XCTAssertEqual(typeAll(&l, [("l", "0")]), .moved(8))
        XCTAssertEqual(l.words.say, "3 hundreds, 2 tens and 4 ones: 324 rows of 23 make 7452.")
    }

    func testLongDivisionZeroAndRemainder() {
        // a 0 in the quotient: not one row fits, released at 0 rows
        var l = LessonRun(LongDivision6.spec, numbers: LongDivision6.numbers(d: 23, q: 304, r: 9))
        _ = l.go(); _ = move(&l, ["x": 2]); _ = move(&l, ["x": 3]); _ = typeAll(&l, [("l", "1")])
        XCTAssertEqual(l.words.say, "1 hundred left = 10 tens, and 0 more: 10 tens. Not one row of 23 fits: tap to write 0.")
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("1 row is 23. There are only 10."))
        XCTAssertEqual(move(&l, ["x": 0]), .moved(5))
        _ = typeAll(&l, [("l", "10")]); _ = move(&l, ["x": 4]); _ = typeAll(&l, [("l", "9")])
        XCTAssertEqual(l.words.say, "3 hundreds, 0 tens and 4 ones: 304 rows of 23 and 9 more make 7001.")
    }

    func testLongDivisionGenerator() {
        for i in [0, 3, 6, 9] {
            each(LongDivision6.spec, i) { n in
                let s = LongDivision6.Parts(n), plan = s.plan
                if i < 3 { XCTAssertTrue((12...19).contains(s.d)); XCTAssertLessThanOrEqual(s.n, 999); XCTAssertEqual(s.r, 0) }
                else { XCTAssertTrue((12...39).contains(s.d)); XCTAssertTrue((1000...99999).contains(s.n)) }
                if i >= 6 { XCTAssertGreaterThan(s.r, 0) } else { XCTAssertEqual(s.r, 0) }
                XCTAssertEqual(plan.r, s.r)
                XCTAssertEqual(Int(plan.places.map { String($0.qd) }.joined()), s.q)
                XCTAssertLessThanOrEqual(plan.mostRows, 10)
            }
        }
        let c = checks(LongDivision6.spec).map(LongDivision6.Parts.init)
        XCTAssertTrue(String(c[0].q).contains("0")); XCTAssertGreaterThanOrEqual(c[1].n, 10000); XCTAssertGreaterThan(c[2].r, 0)
    }

    // MARK: Dividing decimals

    func testDividingDecimals() {
        // 18 ÷ 4: the 2 ones left break into tenths
        var l = LessonRun(DivideDec6.spec, numbers: DivideDec6.numbers(d: 4, q100: 450))
        let plan = DivideDec6.Parts(l.numbers).plan
        XCTAssertEqual(plan.places.map(\.qd), [4, 5]); XCTAssertEqual(plan.places.map(\.app), [false, true])
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2)); XCTAssertEqual(move(&l, ["x": 4]), .moved(3)); XCTAssertEqual(typeAll(&l, [("l", "2")]), .moved(4))
        XCTAssertEqual(l.words.say, "2 ones left. Break them into tenths: tap them.")
        XCTAssertEqual(move(&l, ["x": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "2 ones = 20 tenths. Drag down a row of 4 at a time.")
        _ = move(&l, ["x": 5]); _ = typeAll(&l, [("l", "0")])
        XCTAssertEqual(l.words.say, "The 2 ones left are 20 tenths, so the sharing goes on past the point.")
        // 9.75 ÷ 1.5: both × 10 first
        var m = LessonRun(DivideDec6.spec, numbers: DivideDec6.numbers(d: 15, q100: 650, s: 1))
        let s = DivideDec6.Parts(m.numbers)
        XCTAssertEqual(s.n.s, "9.75"); XCTAssertEqual(s.V.s, "1.5"); XCTAssertEqual(s.N.s, "97.5")
        _ = m.go()
        XCTAssertEqual(m.words.say, "Make the divisor whole.")
        XCTAssertEqual(move(&m, ["x": 2]), .notYet("15 is already whole."))
        XCTAssertEqual(move(&m, ["x": 1]), .moved(2))
        XCTAssertEqual(m.words.say, "Start where 15 goes in.")
        // 8.64 ÷ 12: tenths share into tenths
        let t = DivideDec6.Parts(DivideDec6.numbers(d: 12, q100: 72))
        XCTAssertEqual(t.plan.j0, 1); XCTAssertEqual(t.plan.places.map(\.qd), [7, 2])
        XCTAssertEqual(t.why, "Tenths share into tenths, so the point goes straight up: 8.64 ÷ 12 = 0.72.")
    }

    func testDividingDecimalsGenerator() {
        for i in [0, 3, 6, 8] {
            each(DivideDec6.spec, i) { n in
                let s = DivideDec6.Parts(n), plan = s.plan
                XCTAssertEqual(s.N.m * 100, s.d * s.q100 * Dec6.pow10(s.N.p))
                if i < 3 { XCTAssertEqual(s.n.p, 0); XCTAssertTrue((2...9).contains(s.d)) }
                else if i < 6 { XCTAssertEqual(s.s, 0); XCTAssertGreaterThan(s.n.p, 0) }
                else { XCTAssertGreaterThan(s.s, 0); XCTAssertLessThanOrEqual(s.s, s.kmax); XCTAssertLessThanOrEqual(s.n.intDigits + s.s, 3) }
                XCTAssertTrue((2...25).contains(s.d))
                // the sharing ends by the hundredths, with nothing left
                XCTAssertEqual(plan.r, 0)
                XCTAssertLessThanOrEqual(plan.mostRows, 10)
                XCTAssertLessThanOrEqual(plan.places.count, 4)
            }
        }
    }

    // MARK: Adding and subtracting decimals

    func testAdding() {
        var l = LessonRun(DecAddSub6.spec, numbers: DecAddSub6.numbers(a: Dec6(124, 1), b: Dec6(375, 2), add: true))
        let s = DecAddSub6.Parts(l.numbers)
        XCTAssertEqual(s.phases.list, [.slide, .close]); XCTAssertEqual(s.needA, 1); XCTAssertEqual(s.needB, 0)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Fill the empty places.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("No 0 in front: 12.4 starts at the tens."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide them in.")
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap ten tenths: they close into a one.")
        XCTAssertEqual(move(&l, ["x": Double(1000 + 100 * 3 + 5)]), .notYet("Only 5 ones: it takes ten to close."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Write the total under the line.")
        XCTAssertEqual(typeAll(&l, [("t", "15.15")]), .notYet("Each ten you closed is one more in the next place."))
        XCTAssertEqual(typeAll(&l, [("t", "16.15")]), .moved(5))
        XCTAssertEqual(l.words.say, "Points under points, so tenths add to tenths.")
        XCTAssertTrue(s.carriesOverPoint)
    }

    func testSubtracting() {
        // 12.4 − 3.875: a 0 to write in a's hundredths and thousandths, breaks across
        let s = DecAddSub6.Parts(DecAddSub6.numbers(a: Dec6(124, 1), b: Dec6(3875, 3), add: false))
        XCTAssertEqual(s.R, 8525)
        let ph = s.phases
        XCTAssertEqual(ph.list.first, .slide); XCTAssertEqual(ph.list.last, .slide)
        XCTAssertEqual(ph.end.live(0), 8); XCTAssertEqual(ph.end.live(-1), 5); XCTAssertEqual(ph.end.live(-3), 5)
        XCTAssertNil(ph.end.needy)
        let first = ph.before[ph.list.firstIndex(of: .breaks)!]
        XCTAssertEqual(first.needy, -3)
        XCTAssertEqual(DecAddSub6.Parts.breakSay(first), "Only 0 thousandths, and no hundredths: break a tenth into ten first.")
        var l = LessonRun(DecAddSub6.spec, numbers: DecAddSub6.numbers(a: Dec6(124, 1), b: Dec6(3875, 3), add: false))
        _ = l.go()
        while l.step.answer?.byHand == true { _ = move(&l, ["x": 1]) }
        XCTAssertEqual(l.words.say, "Write what’s left under the line.")
        XCTAssertEqual(typeAll(&l, [("t", "9.525")]), .notYet("A broken place has one less now."))
        let at = l.index
        XCTAssertEqual(typeAll(&l, [("t", "8.525")]), .moved(at + 1))
        XCTAssertEqual(DecAddSub6.Parts.broken(2), .wrong("Break one from the place to its left."))
    }

    func testAddSubGenerator() {
        for i in 0..<10 {
            each(DecAddSub6.spec, i, 120) { n in
                let s = DecAddSub6.Parts(n), end = s.phases.end
                XCTAssertGreaterThan(s.R, 0); XCTAssertLessThan(s.R, 100 * Dec6.pow10(s.P))
                XCTAssertGreaterThan(s.needA + s.needB, 0)
                if i < 3 { XCTAssertTrue(s.add); XCTAssertEqual(s.a.p, 1); XCTAssertEqual(s.b.p, 2) }
                if (3..<6).contains(i) { XCTAssertFalse(s.add) }
                // the hands' end is the answer, every column under ten
                let made = DecAddSub6.places.reduce(0) { $0 + end.live($1) * Dec6.pow10($1 + s.P) }
                XCTAssertEqual(made, s.R)
                for e in DecAddSub6.places { XCTAssertLessThan(end.live(e), 10); XCTAssertEqual(end.waiting[e] ?? 0, 0); XCTAssertLessThanOrEqual(end.items[e]?.count ?? 0, 20) }
            }
        }
        let c = checks(DecAddSub6.spec).map(DecAddSub6.Parts.init)
        XCTAssertTrue(c[0].carriesOverPoint); XCTAssertFalse(c[1].add); XCTAssertEqual(c[3].a.p, 0)
    }

    // MARK: Multiplying decimals

    func testMultiplying() {
        var l = LessonRun(DecMult6.spec, numbers: DecMult6.numbers(a: Dec6(425, 2), b: Dec6(36, 1), typed: true))
        let s = DecMult6.Parts(l.numbers)
        XCTAssertEqual(s.W, 15300); XCTAssertEqual(s.K, 3); XCTAssertEqual(s.product.s, "15.3"); XCTAssertEqual(s.zeros, [])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make both whole: drag 4.25’s digits left.")
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("42.5 still has a point."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("425 is already whole."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Make both whole: now drag 3.6’s digits left.")
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Multiply 425 × 36 the school way: write each row, then add them.")
        XCTAssertEqual(typeAll(&l, [("p1", "2550"), ("p2", "1275"), ("t", "3825")]), .notYet("The 3 is 3 tens: 425 × 30 ends in 0."))
        XCTAssertEqual(typeAll(&l, [("p1", "2550"), ("p2", "12750"), ("t", "15200")]), .notYet("Add the two rows."))
        XCTAssertEqual(typeAll(&l, [("p1", "2550"), ("p2", "12750"), ("t", "15300")]), .moved(4))
        XCTAssertEqual(l.words.say, "Undo both: drag the product’s digits right.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("× 100 and × 10 is × 1000, so ÷ 1000."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(5))
        XCTAssertEqual(l.words.say, "× 100 and × 10 made it 1000 times bigger, so the point goes back 3 places.")
        XCTAssertEqual(s.estimate, "4 × 4 = 16: 15.3 is near 16.")
        // a factor under 1: 0.24 × 0.4 = 0.096, its 0s tapped in
        let u = DecMult6.Parts(DecMult6.numbers(a: Dec6(24, 2), b: Dec6(4, 1), typed: true))
        XCTAssertEqual(u.product.s, "0.096"); XCTAssertEqual(u.zeros, [0, -1])
        XCTAssertEqual(u.estimate, "0.2 × 0.4 = 0.08: 0.096 is near 0.08.")
    }

    func testMultiplyingGenerator() {
        for i in [0, 3, 6, 9] {
            each(DecMult6.spec, i) { n in
                let s = DecMult6.Parts(n)
                XCTAssertGreaterThan(s.a.p, 0); XCTAssertLessThanOrEqual(String(s.W).count, 6)
                XCTAssertEqual(s.product.double, s.a.double * s.b.double, accuracy: 1e-9)
                if i < 3 { XCTAssertEqual(s.a.p, 1); XCTAssertEqual(s.b.p, 0); XCTAssertFalse(s.typed) }
                if i >= 6 { XCTAssertEqual(s.a.p, 2); XCTAssertEqual(s.b.p, 1); XCTAssertTrue(s.typed) }
                XCTAssertLessThanOrEqual(s.topE, 5)
            }
        }
    }
}
