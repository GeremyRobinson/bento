import XCTest
@testable import ObentoCore

/// 6th grade, chapter 6: Equations (design/grade6.md, the preview design/prototype/grade6-ch6.html).
final class EquationsG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(71 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 13)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[5]
        XCTAssertEqual(ch.title, "Equations")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Curriculum.grade(of: "g6-depend"), 6)
    }

    // MARK: One-step equations

    func testOneStepAdd() {
        var l = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 0, a: 7, xc: 8))
        XCTAssertEqual(l.display, [.text("x"), .op("+"), .num(7), .op("="), .num(15)])
        XCTAssertEqual(l.words.say, "Take 7 off both sides. Slide it off the end.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["u": -1]), .notYet("Take it off both sides."))
        XCTAssertEqual(move(&l, ["u": 4]), .notYet("Take it off both sides."))
        XCTAssertEqual(move(&l, ["u": 7]), .moved(2))
        XCTAssertEqual(l.words.say, "Write what x is. x lines up with what’s left.")
        XCTAssertEqual(typeAll(&l, [("x", "22")]), .notYet("Do the opposite to undo it."))
        XCTAssertEqual(typeAll(&l, [("x", "9")]), .notYet("Count the cells under x."))
        XCTAssertEqual(typeAll(&l, [("x", "8")]), .moved(3))
        XCTAssertEqual(l.words.say, "Check it. Put 8 back in for x.")
        XCTAssertEqual(typeAll(&l, [("q", "8")]), .notYet("That’s x again. Work out 8 + 7."))
        XCTAssertEqual(typeAll(&l, [("q", "16")]), .notYet("Work out 8 + 7."))
        XCTAssertEqual(typeAll(&l, [("q", "15")]), .moved(4))
        XCTAssertEqual(l.words.say, "Take 7 off both sides and they still balance: x is 8.")
        XCTAssertTrue(l.isLast)
    }

    func testOneStepSubMulDiv() {
        var s = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 1, a: 7, xc: 15))
        XCTAssertEqual(s.display, [.text("x"), .op("−"), .num(7), .op("="), .num(8)])
        _ = s.go()
        XCTAssertEqual(s.words.say, "Put 7 back on both sides. Slide them onto the ends.")
        XCTAssertEqual(move(&s, ["u": -1]), .notYet("Do the opposite to undo it."))
        XCTAssertEqual(move(&s, ["u": 0]), .notYet("Slide them onto the ends."))
        XCTAssertEqual(move(&s, ["u": 7]), .moved(2))
        XCTAssertEqual(typeAll(&s, [("x", "1")]), .notYet("Do the opposite to undo it."))
        XCTAssertEqual(typeAll(&s, [("x", "15")]), .moved(3))
        XCTAssertEqual(typeAll(&s, [("q", "8")]), .moved(4))

        var m = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 2, a: 3, xc: 9))
        XCTAssertEqual(m.display, [.text("3x"), .op("="), .num(27)])
        _ = m.go()
        XCTAssertEqual(m.words.say, "Share 27 into 3 rows. Drag the right edge.")
        XCTAssertEqual(move(&m, ["u": 6]), .notYet("9 are left: another column fits."))
        XCTAssertEqual(move(&m, ["u": 10]), .notYet("3 rows of 10 is 30. There are only 27."))
        XCTAssertEqual(move(&m, ["u": 9]), .moved(2))
        XCTAssertEqual(typeAll(&m, [("x", "81")]), .notYet("Do the opposite to undo it."))
        XCTAssertEqual(typeAll(&m, [("x", "27")]), .notYet("One row is one x: count its cells."))
        XCTAssertEqual(typeAll(&m, [("x", "9")]), .moved(3))
        XCTAssertEqual(typeAll(&m, [("q", "27")]), .moved(4))
        XCTAssertEqual(m.words.say, "Share 27 into 3 rows: one row is x, so x is 9.")

        var d = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 3, a: 3, xc: 4))
        XCTAssertEqual(d.display, [.text("x"), .op("÷"), .num(3), .op("="), .num(4)])
        _ = d.go()
        XCTAssertEqual(d.words.say, "Make all 3 rows. Drag the bottom edge down.")
        XCTAssertEqual(move(&d, ["u": 2]), .notYet("That’s 2 rows. x has 3."))
        XCTAssertEqual(move(&d, ["u": 3]), .moved(2))
        XCTAssertEqual(typeAll(&d, [("x", "1")]), .notYet("x is all 3 rows: count their cells."))
        XCTAssertEqual(typeAll(&d, [("x", "12")]), .moved(3))
        XCTAssertEqual(typeAll(&d, [("q", "12")]), .notYet("That’s x again. Work out 12 ÷ 3."))
        XCTAssertEqual(typeAll(&d, [("q", "4")]), .moved(4))
    }

    func testOneStepExtra() {
        // x + 1.5 = 4.25: a cell is a quarter
        var q = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 0, a: 6, xc: 11, cv: 0.25))
        XCTAssertEqual(q.display, [.text("x"), .op("+"), .num(1.5), .op("="), .num(4.25)])
        _ = q.go(); _ = move(&q, ["u": 6])
        XCTAssertEqual(typeAll(&q, [("x", "3")]), .notYet("Count the cells under x, each 1/4."))
        XCTAssertEqual(typeAll(&q, [("x", "2.75")]), .moved(3))
        XCTAssertEqual(q.words.say, "Check it. Put 2.75 back in for x.")
        XCTAssertEqual(typeAll(&q, [("q", "4.25")]), .moved(4))
        // x + 3/4 = 2: quarters as fractions; x = 1 1/4 written as a whole and a fraction, any equal fraction
        var f = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 0, a: 3, xc: 5, cv: 0.25, fr: true))
        XCTAssertEqual(f.display, [.text("x"), .op("+"), .frac(.num(3), .num(4)), .op("="), .num(2)])
        _ = f.go(); _ = move(&f, ["u": 3])
        XCTAssertEqual(f.step.answer?.boxes, ["w", "n", "d"])
        XCTAssertEqual(typeAll(&f, [("w", "1")]), .notYet("Write the whole number and the fraction."))
        XCTAssertEqual(typeAll(&f, [("w", "1"), ("n", "2"), ("d", "8")]), .moved(3))
        XCTAssertEqual(f.words.say, "Check it. Put 1 1/4 back in for x.")
        // less than 1: the fraction alone
        let small = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 0, a: 1, xc: 3, cv: 0.25, fr: true))
        XCTAssertEqual(small.steps[2].answer?.boxes, ["n", "d"])
        // 3x = 4.5: a cell is a half
        var h = LessonRun(OneStep6.spec, numbers: OneStep6.numbers(kind: 2, a: 3, xc: 3, cv: 0.5))
        XCTAssertEqual(h.display, [.text("3x"), .op("="), .num(4.5)])
        _ = h.go()
        XCTAssertEqual(move(&h, ["u": 2]), .notYet("1.5 are left: another column fits."))
        XCTAssertEqual(move(&h, ["u": 3]), .moved(2))
        XCTAssertEqual(typeAll(&h, [("x", "1.5")]), .moved(3))
    }

    func testOneStepGenerator() {
        for i in 0..<4 { each(OneStep6.spec, i) { x in XCTAssertEqual(OneStep6.Parts(x).kind, i); XCTAssertEqual(OneStep6.Parts(x).cv, 1) } }
        for i in 0..<16 {
            each(OneStep6.spec, i) { x in
                let s = OneStep6.Parts(x)
                XCTAssertTrue(s.xv > 0 && s.qv > 0)
                if s.cv == 1 {
                    XCTAssertTrue((2...9).contains(s.a))
                    let r = [s.xc, s.Q, s.xc, s.xc][s.kind]
                    XCTAssertTrue((2...12).contains(r))
                }
                // the picture stays on the paper: + and − at most 21 cells across, × at most 12 columns
                if s.bars { XCTAssertTrue(max(s.X, s.Q) <= 21) } else { XCTAssertTrue(s.kind == 3 || s.X <= 12) }
                if i < 8 { XCTAssertEqual(s.cv, 1) }
            }
        }
        var extra = 0
        each(OneStep6.spec, 9) { x in if OneStep6.Parts(x).cv != 1 { extra += 1 } }
        XCTAssertEqual(extra, 300)
        // each kind once in the check
        XCTAssertEqual(checks(OneStep6.spec).map { OneStep6.Parts($0).kind }, [0, 1, 2, 3])
    }

    // MARK: Inequalities

    func testIneqOlder() {
        var l = LessonRun(Ineq6.spec, numbers: Ineq6.numbers(sign: 0, n: 8, age: true, tests: [5, 8, 9.5, 12]))
        let s = Ineq6.Parts(l.numbers)
        XCTAssertEqual(s.story, "You must be older than 8.")
        XCTAssertEqual(l.words.say, "Put the circle on 8. Tap it to fill it in or leave it open.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["c": 6]), .notYet("That’s 6. Put it on 8."))
        XCTAssertEqual(move(&l, ["c": 8]), .moved(2))
        XCTAssertEqual(l.words.say, "Shade every age that works. Drag the arrow out of the circle along the line.")
        XCTAssertEqual(move(&l, ["r": 2]), .notYet("Older than 8 means bigger: to the right."))
        XCTAssertEqual(move(&l, ["r": 3]), .notYet("Every age past 8 works: take it off the end."))
        XCTAssertEqual(move(&l, ["r": 4]), .notYet("8 isn’t older than 8: leave it open."))
        XCTAssertEqual(move(&l, ["r": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap the ones that work.")
        XCTAssertEqual(move(&l, ["t": -2]), .notYet("8 isn’t older than 8."))
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("5 is less than 8."))
        XCTAssertEqual(move(&l, ["t": 1]), .notYet("Tap the ones that work."))
        XCTAssertEqual(move(&l, ["t": 2]), .moved(4))
        XCTAssertEqual(l.step.answer?.choices, [">", "<", "≥", "≤"])
        l.choose(1); XCTAssertEqual(l.go(), .notYet("x < 8 says less than 8: the ray goes the other way."))
        l.choose(2); XCTAssertEqual(l.go(), .notYet("x ≥ 8 counts 8 too, but the circle is open."))
        l.choose(0); XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(typeAll(&l, [("x", "9")]), .notYet("The circle is on 8."))
        XCTAssertEqual(typeAll(&l, [("x", "8")]), .moved(6))
        XCTAssertEqual(l.words.say, "Every number past 8 works, far too many to list.")
        XCTAssertEqual(s.hs(9.5), "9 1/2")
    }

    func testIneqAtMostNegative() {
        var l = LessonRun(Ineq6.spec, numbers: Ineq6.numbers(sign: 3, n: -4, age: false, tests: [-4, 0, -6, -12.5], dec: true))
        let s = Ineq6.Parts(l.numbers)
        XCTAssertEqual(s.story, "It must be at most −4 degrees.")
        XCTAssertEqual(s.working, [0, 1, 2])
        XCTAssertEqual(s.hs(-12.5), "−12.5")
        _ = l.go(); _ = move(&l, ["c": -4])
        XCTAssertEqual(move(&l, ["r": 2]), .notYet("At most −4 means −4 or smaller: to the left."))
        XCTAssertEqual(move(&l, ["r": 5]), .notYet("−4 is at most −4: fill it in."))
        XCTAssertEqual(move(&l, ["r": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["t": -4]), .notYet("0 is more than −4."))
        XCTAssertEqual(move(&l, ["t": 3]), .moved(4))
        l.choose(1); XCTAssertEqual(l.go(), .notYet("x < −4 leaves −4 out, but the circle is filled."))
        l.choose(3); XCTAssertEqual(l.go(), .moved(5))
        XCTAssertEqual(typeAll(&l, [("x", "-4")]), .moved(6))
        XCTAssertEqual(l.words.say, "−4 and every number under it work, far too many to list.")
    }

    func testIneqGenerator() {
        for i in 0..<14 {
            each(Ineq6.spec, i) { x in
                let s = Ineq6.Parts(x)
                if i < 3 { XCTAssertTrue(s.sign < 2) } else if i < 6 { XCTAssertTrue(s.sign >= 2) }
                if i < 6 { XCTAssertTrue(s.n >= 2) }
                XCTAssertTrue(s.n >= -10 && s.n <= 20)
                XCTAssertTrue(s.tests.contains(s.n))
                XCTAssertEqual(s.working.count, s.strict ? 2 : 3)
                XCTAssertEqual(Set(s.tests).count, 4)
                for t in s.tests { XCTAssertTrue(t >= s.lo && t <= s.hi) }
                if s.age { XCTAssertTrue(s.big && s.n >= 5) }
            }
        }
        let c = checks(Ineq6.spec).map(Ineq6.Parts.init)
        XCTAssertEqual(c[0].sign, 0); XCTAssertEqual(c[1].sign, 1); XCTAssertEqual(c[2].sign, 2); XCTAssertTrue(c[3].n < 0)
    }

    // MARK: Two quantities

    func testDependTimes() {
        var l = LessonRun(Depend6.spec, numbers: Depend6.numbers(kind: 0, st: 0, k: 3))
        let s = Depend6.Parts(l.numbers)
        XCTAssertEqual(l.words.say, "Drag the hours to 2, 4 and 6. The table writes each stop.")
        XCTAssertEqual(s.read(2), "2 hours · 6 miles")
        XCTAssertEqual(s.read(1), "1 hour · 3 miles")
        _ = l.go()
        XCTAssertEqual(move(&l, ["h": 3]), .notYet("That’s 3 hours. Stop on 2, 4 and 6."))
        XCTAssertEqual(move(&l, ["h": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["h": 6]), .moved(3))
        XCTAssertEqual(move(&l, ["h": 4]), .moved(4))
        XCTAssertEqual(l.words.say, "Write the rule. Use the table.")
        XCTAssertEqual(typeAll(&l, [("r", "4")]), .notYet("m = h + 4 works at 2 hours, but at 4 hours it gives 8, not 12."))
        XCTAssertEqual(typeAll(&l, [("r", "2")]), .notYet("m = 2 × h makes 4 miles at 2 hours. The table says 6."))
        XCTAssertEqual(typeAll(&l, [("r", "3")]), .moved(5))
        XCTAssertEqual(l.words.say, "Use the rule past the paper.")
        XCTAssertEqual(typeAll(&l, [("p", "23")]), .notYet("Use the rule: m = 3 × 20."))
        XCTAssertEqual(typeAll(&l, [("p", "60")]), .moved(6))
        XCTAssertEqual(l.words.say, "You change the hours; the miles depend on them: m = 3 × h.")
    }

    func testDependPlusBackwards() {
        var l = LessonRun(Depend6.spec, numbers: Depend6.numbers(kind: 1, st: 0, c: 5, back: true, xs: 14))
        let s = Depend6.Parts(l.numbers)
        XCTAssertEqual(s.read(2), "sister’s age 2 · Ali’s age 7")
        _ = l.go(); _ = move(&l, ["h": 2]); _ = move(&l, ["h": 4]); _ = move(&l, ["h": 6])
        XCTAssertEqual(typeAll(&l, [("r", "3")]), .notYet("a = s + 3 makes 5 at s = 2. The table says 7."))
        XCTAssertEqual(typeAll(&l, [("r", "5")]), .moved(5))
        XCTAssertEqual(l.words.say, "Which s makes a = 19?")
        XCTAssertEqual(typeAll(&l, [("p", "24")]), .notYet("That’s a when s is 19. Here a is 19."))
        XCTAssertEqual(typeAll(&l, [("p", "13")]), .notYet("s + 5 = 19: which s?"))
        XCTAssertEqual(typeAll(&l, [("p", "14")]), .moved(6))
        XCTAssertEqual(l.words.say, "You change the sister’s age; Ali’s age depends on it: a = s + 5.")
    }

    func testDependGenerator() {
        for i in 0..<14 {
            each(Depend6.spec, i) { x in
                let s = Depend6.Parts(x)
                if i < 3 { XCTAssertTrue(s.times && s.k <= 3) } else if i < 6 { XCTAssertFalse(s.times) }
                if i < 6 { XCTAssertFalse(s.back) }
                // the line fits the paper: 10 across is at most 30 squares up
                XCTAssertTrue(s.f(10) <= 30 * s.ys)
                XCTAssertTrue(s.times ? s.S.ks.contains(s.k) : (1...20).contains(s.c))
                if s.back { XCTAssertTrue((12...20).contains(s.xs)) } else { XCTAssertEqual(s.xs, 20) }
            }
        }
        let c = checks(Depend6.spec).map(Depend6.Parts.init)
        XCTAssertTrue(c[0].times); XCTAssertFalse(c[1].times); XCTAssertFalse(c[2].back); XCTAssertTrue(c[3].back)
    }
}
