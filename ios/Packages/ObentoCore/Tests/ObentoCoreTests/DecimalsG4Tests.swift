import XCTest
@testable import ObentoCore

/// 4th grade, chapter 6: Decimals (design/grade4.md, the preview design/prototype/grade4-ch6.html).
final class DecimalsG4Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(61 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 11)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[5]
        XCTAssertEqual(ch.title, "Decimals")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Dec4.text(55), "0.55")
        XCTAssertEqual(Dec4.text(60), "0.6")
        XCTAssertEqual(Dec4.text(5), "0.05")
        XCTAssertEqual(Dec4.text(145), "1.45")
        XCTAssertEqual(Dec4.text(100), "1")
        XCTAssertEqual(Dec4.written(0, 50, 1), "0.5")
        XCTAssertEqual(Dec4.written(3, 50, 2), "3.50")
        XCTAssertEqual(Dec4.written(1, 7, 2), "1.07")
    }

    // MARK: Tenths and hundredths

    func testTenthsHundredths() {
        var l = LessonRun(TenthsHundredths.spec, numbers: TenthsHundredths.numbers(a: 3, b: 25))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Cut every tenth into 10 hundredths. Tap a shaded tenth.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("That part is empty. Tap a shaded tenth."))
        XCTAssertEqual(move(&l, ["t": -2]), .notYet("Those are hundredths already. Tap a shaded tenth."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Same-size pieces now, so add the tops. Slide the striped hundredths into the first whole.")
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Slide them into the first whole."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Write it as a decimal. Type it with its point.")
        XCTAssertEqual(move(&l, ["x": 5.5]), .notYet("Hundredths need two places after the decimal point."))
        XCTAssertEqual(move(&l, ["x": 55]), .notYet("Hundredths need two places after the decimal point."))
        XCTAssertEqual(move(&l, ["x": 0.28]), .notYet("Tenths are bigger pieces. Use the 30 hundredths from the step before."))
        XCTAssertEqual(move(&l, ["x": 0.5]), .notYet("There are 55 hundredths. Hundredths go two places after the point."))
        XCTAssertEqual(move(&l, ["x": 0.55]), .moved(4))
        XCTAssertEqual(l.words.say, "A tenth is ten hundredths, so they add as hundredths.")
    }

    func testTenthsHundredthsPastAWhole() {
        var l = LessonRun(TenthsHundredths.spec, numbers: TenthsHundredths.numbers(a: 8, b: 45))
        _ = l.go(); _ = move(&l, ["t": 1]); _ = move(&l, ["s": 1])
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("There are 125 hundredths. Hundredths go two places after the point. 100 hundredths make 1 whole."))
        XCTAssertEqual(move(&l, ["x": 1.25]), .moved(4))
        XCTAssertEqual(TenthsHundredths.Parts(TenthsHundredths.numbers(a: 8, b: 45)).text, "1.25")
    }

    func testTenthsHundredthsGenerator() {
        for i in 0..<6 {
            each(TenthsHundredths.spec, i) { x in
                let s = TenthsHundredths.Parts(x)
                XCTAssertTrue((1...9).contains(s.a)); XCTAssertTrue((1...99).contains(s.b))
                XCTAssertEqual(s.S, 10 * s.a + s.b)
            }
        }
        let c = checks(TenthsHundredths.spec).map(TenthsHundredths.Parts.init)
        XCTAssertLessThan(c[0].S, 100); XCTAssertGreaterThanOrEqual(c[1].S, 100); XCTAssertLessThan(c[2].b, 10)
    }

    // MARK: Decimals on a number line

    func testLinePlain() {
        var l = LessonRun(DecimalLine.spec, numbers: DecimalLine.numbers(w: 0, h: 62))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Each block is a tenth. Tap the tenth the number is in.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["b": 2]), .notYet("0.62 is between 0.6 and 0.7."))
        XCTAssertEqual(move(&l, ["b": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Each block is a hundredth now. Drag the point to the number.")
        XCTAssertEqual(move(&l, ["p": 4]), .notYet("That’s 0.64. 0.62 is 2 hundredths past 0.6."))
        XCTAssertEqual(move(&l, ["p": 2]), .moved(3))
        XCTAssertEqual(l.words.say, "Write it as a fraction. Fill in the top and the bottom.")
        XCTAssertEqual(move(&l, ["T": 6, "B": 10]), .notYet("That’s the tenths only."))
        XCTAssertEqual(move(&l, ["T": 62, "B": 10]), .notYet("62 hundredths: the bottom is 100."))
        XCTAssertEqual(move(&l, ["T": 26, "B": 100]), .notYet("Count the hundredths: a tenth is 10 of them."))
        XCTAssertEqual(move(&l, ["T": 62, "B": 100]), .moved(4))
        XCTAssertEqual(l.words.say, "6 tenths and 2 hundredths make 62 hundredths.")
    }

    func testLineKinds() {
        // a tenths decimal: placed on line 1, as tenths or hundredths
        var t = LessonRun(DecimalLine.spec, numbers: DecimalLine.numbers(w: 0, h: 70))
        XCTAssertEqual(t.steps.count, 4)
        XCTAssertEqual(t.words.say, "Each block is a tenth. Drag the point to the number.")
        _ = t.go()
        XCTAssertEqual(move(&t, ["p": 6]), .notYet("That’s 0.6. 0.7 is 7 tenths past 0."))
        XCTAssertEqual(move(&t, ["p": 7]), .moved(2))
        XCTAssertEqual(move(&t, ["T": 7, "B": 100]), .notYet("7 hundredths is 0.07. 0.7 is 7 tenths."))
        XCTAssertEqual(move(&t, ["T": 7, "B": 10]), .moved(3))
        XCTAssertEqual(t.words.say, "7 tenths is the same as 70 hundredths.")
        var t2 = LessonRun(DecimalLine.spec, numbers: DecimalLine.numbers(w: 0, h: 70))
        _ = t2.go(); _ = move(&t2, ["p": 7])
        XCTAssertEqual(move(&t2, ["T": 70, "B": 100]), .moved(3))
        // under a tenth
        var u = LessonRun(DecimalLine.spec, numbers: DecimalLine.numbers(w: 0, h: 5))
        _ = u.go(); _ = move(&u, ["b": 0]); _ = move(&u, ["p": 5])
        XCTAssertEqual(move(&u, ["T": 5, "B": 10]), .notYet("That’s 5 tenths. 0.05 is 5 hundredths: the bottom is 100."))
        XCTAssertEqual(move(&u, ["T": 50, "B": 100]), .notYet("That’s 50 hundredths. 0.05 is 5 hundredths."))
        XCTAssertEqual(move(&u, ["T": 5, "B": 100]), .moved(4))
        XCTAssertEqual(u.words.say, "No tenths, so 0.05 is just 5 hundredths.")
        // a whole number in front, told as a length
        var w = LessonRun(DecimalLine.spec, numbers: DecimalLine.numbers(w: 1, h: 45, story: 1, thing: 1))
        XCTAssertEqual(w.words.say, "A rope is 1.45 m long. Tap the tenth the number is in.")
        _ = w.go()
        XCTAssertEqual(move(&w, ["b": 3]), .notYet("1.45 is between 1.4 and 1.5."))
        _ = move(&w, ["b": 4])
        XCTAssertEqual(move(&w, ["p": 0]), .notYet("That’s 1.4. 1.45 is 5 hundredths past 1.4."))
        _ = move(&w, ["p": 5])
        XCTAssertEqual(move(&w, ["T": 45, "B": 100]), .notYet("That’s only the part after the point. 1 whole is 100 hundredths more."))
        XCTAssertEqual(move(&w, ["T": 14, "B": 10]), .notYet("That’s the tenths only."))
        XCTAssertEqual(move(&w, ["T": 145, "B": 100]), .moved(4))
        XCTAssertEqual(w.words.say, "1 whole, 4 tenths and 5 hundredths make 145 hundredths.")
    }

    func testLineGenerator() {
        for i in 0..<12 {
            each(DecimalLine.spec, i, 100) { x in
                let s = DecimalLine.Parts(x)
                switch i < 3 ? DecimalLine.Kind.plain : [DecimalLine.Kind.under, .tenths, .plain, .whole][(i - 3) % 4] {
                case .plain: XCTAssertEqual(s.kind, .plain); XCTAssertTrue(s.t > 0 && s.u > 0)
                case .under: XCTAssertEqual(s.kind, .under)
                case .tenths: XCTAssertEqual(s.kind, .tenths)
                case .whole: XCTAssertEqual(s.kind, .whole); XCTAssertTrue((1...9).contains(s.w)); XCTAssertTrue(s.u > 0)
                }
                XCTAssertEqual(s.story, i % 3 == 2)
            }
        }
        let c = checks(DecimalLine.spec).map(DecimalLine.Parts.init)
        XCTAssertEqual(c[1].kind, .under); XCTAssertEqual(c[2].kind, .tenths); XCTAssertEqual(c[3].kind, .whole)
    }

    // MARK: Comparing decimals

    func testCompareTrap() {
        var l = LessonRun(CompareDec4.spec, numbers: CompareDec4.numbers(w: 0, a: 50, b: 45, pa: 1, pb: 2))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Each grid is one whole: a column is a tenth, a square a hundredth. Drag across the first grid.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["n": 5]), .notYet("0.5 is 5 tenths: 5 full columns."))
        XCTAssertEqual(move(&l, ["n": 40]), .notYet("That’s 40 hundredths. 0.5 is 5 tenths, and 5 tenths is 50 hundredths."))
        XCTAssertEqual(move(&l, ["n": 50]), .moved(2))
        XCTAssertEqual(l.words.say, "Now the second. Drag across the second grid.")
        XCTAssertEqual(move(&l, ["n": 4]), .notYet("That’s only the tenths. 0.45 has 4 tenths and 5 hundredths, which is 45 hundredths."))
        XCTAssertEqual(move(&l, ["n": 44]), .notYet("That’s 44 hundredths. The two digits after the point, 45, make 45 hundredths."))
        XCTAssertEqual(move(&l, ["n": 45]), .moved(3))
        XCTAssertEqual(l.words.say, "Which is more? Tap <, = or >.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("45 and 5 aren’t the amounts. 0.5 has 50 hundredths."))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("They’d be equal only with the same number of hundredths. 50 and 45 are not the same."))
        XCTAssertEqual(move(&l, ["c": 2]), .moved(4))
        XCTAssertEqual(l.words.say, "50 hundredths is more than 45.")
    }

    func testCompareOthers() {
        // equal, with a whole number in front
        var e = LessonRun(CompareDec4.spec, numbers: CompareDec4.numbers(w: 3, a: 70, b: 70, pa: 1, pb: 2))
        XCTAssertEqual(e.words.say, "Both have 3 wholes. Shade what’s after the point. Drag across the first grid.")
        _ = e.go(); _ = move(&e, ["n": 70]); _ = move(&e, ["n": 70])
        XCTAssertEqual(move(&e, ["c": 2]), .notYet("3.7 and 3.70 both have 70 hundredths after the point. A zero on the end doesn’t change the amount."))
        XCTAssertEqual(move(&e, ["c": 1]), .moved(4))
        XCTAssertEqual(e.words.say, "The same number of hundredths, so they are equal.")
        // hundredths read as tenths; turned round
        var h = LessonRun(CompareDec4.spec, numbers: CompareDec4.numbers(w: 0, a: 7, b: 12, pa: 2, pb: 2))
        _ = h.go()
        XCTAssertEqual(move(&h, ["n": 70]), .notYet("The 7 is in the hundredths place, two after the point. So it’s only 7 hundredths."))
        _ = move(&h, ["n": 7]); _ = move(&h, ["n": 12])
        XCTAssertEqual(move(&h, ["c": 2]), .notYet("7 hundredths is less than 12 hundredths, so 0.07 < 0.12."))
        XCTAssertEqual(move(&h, ["c": 0]), .moved(4))
        XCTAssertEqual(h.words.say, "7 hundredths is less than 12.")
    }

    func testCompareGenerator() {
        for i in 0..<8 {
            each(CompareDec4.spec, i) { x in
                let s = CompareDec4.Parts(x)
                if i < 4 { XCTAssertEqual(s.w, 0) }
                XCTAssertFalse(s.a == s.b && s.pa == s.pb)
                if s.pa == 1 { XCTAssertEqual(s.a % 10, 0) }
                if s.pb == 1 { XCTAssertEqual(s.b % 10, 0) }
            }
        }
        let c = checks(CompareDec4.spec).map(CompareDec4.Parts.init)
        XCTAssertTrue(c[0].pa != c[0].pb && c[0].naive != c[0].k)
        XCTAssertEqual(c[1].a / 10, c[1].b / 10)
        XCTAssertEqual(c[2].a, c[2].b)
        XCTAssertTrue(c[3].w > 0 && c[3].pa != c[3].pb)
    }
}
