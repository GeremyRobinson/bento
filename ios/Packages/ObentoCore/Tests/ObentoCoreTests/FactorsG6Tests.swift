import XCTest
@testable import ObentoCore

/// 6th grade, chapter 2: Factors and fractions (design/grade6.md, the preview design/prototype/grade6-ch2.html).
final class FactorsG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, Int)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in String(x) { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(71 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[1]
        XCTAssertEqual(ch.title, "Factors and fractions")
        XCTAssertEqual(ch.test, "test-g6-factors")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Curriculum.grade(of: "g6-divide"), 6)
    }

    // MARK: Least common multiple

    func testLcm() {
        var l = LessonRun(Lcm6.spec, numbers: Lcm6.numbers(a: 4, b: 6))
        XCTAssertEqual(l.words.say, "Hop by 6s to the end.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        let s = Lcm6.Parts(l.numbers)
        XCTAssertEqual(s.N, 24); XCTAssertEqual(s.U, 2); XCTAssertEqual(s.hops, 4); XCTAssertEqual(s.L, 12)
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Keep hopping to the end."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the first 6 that 4 goes into.")
        XCTAssertEqual(move(&l, ["x": 18]), .notYet("4s go 16, 20: they jump over 18."))
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("4s go 4, 8: they jump over 6."))
        XCTAssertEqual(move(&l, ["x": 24]), .notYet("24 works, but 12 comes first."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(3))
        XCTAssertEqual(l.words.say, "Write how many 4s make 12.")
        XCTAssertEqual(typeAll(&l, [("x", 2)]), .notYet("Check with 4, the smaller number: does it go in evenly?"))
        XCTAssertEqual(typeAll(&l, [("x", 4)]), .notYet("Count the hops under the line."))
        XCTAssertEqual(typeAll(&l, [("x", 3)]), .moved(4))
        XCTAssertEqual(l.words.say, "12 is the first number both counts land on.")
    }

    func testLcmLine() {
        // no common factor: a × b, at most 60; a big pair with a factor: the line stops at 60 or under and still holds the LCM
        XCTAssertEqual(Lcm6.Parts(Lcm6.numbers(a: 5, b: 12)).N, 60)
        let big = Lcm6.Parts(Lcm6.numbers(a: 10, b: 12))
        XCTAssertEqual(big.N, 60); XCTAssertEqual(big.L, 60); XCTAssertEqual(big.U, 1)
        for i in [0, 5] {
            each(Lcm6.spec, i) { n in
                let s = Lcm6.Parts(n)
                XCTAssertTrue(2 <= s.a && s.a < s.b && s.b <= 12)
                XCTAssertLessThanOrEqual(s.N * s.U, 60)
                XCTAssertEqual(s.N % s.b, 0)
                XCTAssertLessThanOrEqual(s.L, s.N)
                if s.L == s.a * s.b { XCTAssertLessThanOrEqual(s.a * s.b, 60) }
            }
        }
        let c = checks(Lcm6.spec).map(Lcm6.Parts.init)
        XCTAssertEqual(c[1].L, c[1].a * c[1].b)
        XCTAssertEqual(c[2].b % c[2].a, 0)
        XCTAssertGreaterThan(Fact6.gcd(c[0].a, c[0].b), 1); XCTAssertNotEqual(c[0].b % c[0].a, 0)
    }

    // MARK: Factor out the GCF

    func testGcf() {
        var l = LessonRun(Gcf6.spec, numbers: Gcf6.numbers(g: 6, m: 3, n: 5))
        XCTAssertEqual(l.words.say, "Cut both bars into the biggest pieces that fit both.")
        _ = l.go()
        let s = Gcf6.Parts(l.numbers)
        XCTAssertEqual(s.A, 18); XCTAssertEqual(s.B, 30); XCTAssertEqual(s.U, 1)
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("18 has 2 over."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("30 has 3 over."))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("Pieces of 1 always fit. Find bigger ones."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Those fit. Bigger pieces fit too."))
        XCTAssertEqual(move(&l, ["x": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many 6s are in each bar.")
        XCTAssertEqual(typeAll(&l, [("m", 18), ("n", 30)]), .notYet("Divide each number by 6. The answers go inside the parentheses."))
        XCTAssertEqual(typeAll(&l, [("m", 12), ("n", 24)]), .notYet("Factoring out 6 divides by it: 18 ÷ 6 and 30 ÷ 6."))
        XCTAssertEqual(typeAll(&l, [("m", 5), ("n", 3)]), .notYet("Count the pieces in each bar."))
        XCTAssertEqual(typeAll(&l, [("m", 3), ("n", 5)]), .moved(3))
        XCTAssertEqual(l.words.say, "Both bars are made of 6s, so the 6 is written once.")
    }

    func testGcfGenerator() {
        for i in 0..<6 {
            each(Gcf6.spec, i) { n in
                let s = Gcf6.Parts(n), top = i < 3 ? 5 : 9
                XCTAssertTrue((2...top).contains(s.g)); XCTAssertTrue((1...top).contains(s.m)); XCTAssertTrue((1...top).contains(s.n))
                XCTAssertNotEqual(s.m, s.n); XCTAssertEqual(Fact6.gcd(s.m, s.n), 1)
                XCTAssertEqual(Fact6.gcd(s.A, s.B), s.g)
                XCTAssertLessThanOrEqual(s.long * s.U, 72)
            }
        }
        let c = checks(Gcf6.spec).map(Gcf6.Parts.init)
        XCTAssertTrue([4, 6, 8, 9].contains(c[0].g)); XCTAssertTrue(c[1].m == 1 || c[1].n == 1)
    }

    // MARK: Dividing fractions

    func testDivide() {
        var l = LessonRun(DivideFrac6.spec, numbers: DivideFrac6.numbers(a: 2, b: 3, c: 1, d: 4))
        let s = DivideFrac6.Parts(l.numbers)
        XCTAssertEqual(s.W, 48); XCTAssertEqual(s.Al, 32); XCTAssertEqual(s.Cl, 12); XCTAssertEqual(s.P, 4)
        XCTAssertEqual(s.S1, 8); XCTAssertEqual(s.L1, 3); XCTAssertEqual(s.copies, 3); XCTAssertEqual(s.covered, 2)
        XCTAssertEqual(l.words.say, "Pick how many 1/4s fit in 2/3.")
        _ = l.go()
        l.choose(1)
        XCTAssertEqual(l.go(), .notYet("1/4 is 12 squares, 2/3 is 32: more than one fits."))
        l.choose(0)
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "Lay 1/4s along the 2/3.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s past 2/3."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Cut both bars into the same small pieces.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("2/3 has 2 squares over."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("1/4 has 4 squares over."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That works. Can the pieces be bigger?"))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(4))
        XCTAssertEqual(l.words.say, "Flip 1/4 and multiply.")
        XCTAssertEqual(typeAll(&l, [("fn", 1), ("fd", 4)]), .notYet("That’s the same fraction. Swap the top and the bottom."))
        XCTAssertEqual(typeAll(&l, [("fn", 3), ("fd", 2)]), .notYet("Keep the first fraction. Flip the second one."))
        XCTAssertEqual(typeAll(&l, [("fn", 4), ("fd", 1)]), .moved(5))
        XCTAssertEqual(l.words.say, "Multiply the tops and the bottoms.")
        XCTAssertEqual(typeAll(&l, [("mn", 2), ("md", 12)]), .notYet("Multiply by the flipped fraction, 4/1."))
        XCTAssertEqual(typeAll(&l, [("mn", 8), ("md", 4)]), .notYet("Top: 2 × 4. Bottom: 3 × 1."))
        XCTAssertEqual(typeAll(&l, [("mn", 8), ("md", 3)]), .moved(6))
        XCTAssertEqual(l.words.say, "Write it as simply as you can.")
        XCTAssertEqual(l.step.answer?.boxes, ["w", "sn", "sd"])
        XCTAssertEqual(typeAll(&l, [("w", 2), ("sn", 1), ("sd", 3)]), .notYet("That’s not the same amount as 8/3."))
        XCTAssertEqual(typeAll(&l, [("w", 1), ("sn", 5), ("sd", 3)]), .notYet("Same amount. Take the whole 3s out of 5 first."))
        XCTAssertEqual(typeAll(&l, [("w", 2), ("sn", 2), ("sd", 3)]), .moved(7))
        XCTAssertEqual(l.words.say, "2 whole 1/4s fit, and 2/3 of another.")
    }

    func testDivideForms() {
        // already simplest: no simplest step
        let a = DivideFrac6.Parts(DivideFrac6.numbers(a: 1, b: 3, c: 1, d: 2))
        XCTAssertTrue(a.simplest); XCTAssertFalse(a.more)
        XCTAssertEqual(LessonRun(DivideFrac6.spec, numbers: DivideFrac6.numbers(a: 1, b: 3, c: 1, d: 2)).steps.count, 7)
        XCTAssertEqual(a.why, "2/3 of a 1/2 fits.")
        // a whole number: only its box
        let w = DivideFrac6.Parts(DivideFrac6.numbers(a: 1, b: 2, c: 1, d: 4))
        XCTAssertEqual(w.simpleBoxes, ["w"]); XCTAssertEqual(w.why, "2 whole 1/4s fit.")
        // a fraction not in lowest terms: both divide
        var l = LessonRun(DivideFrac6.spec, numbers: DivideFrac6.numbers(a: 1, b: 4, c: 5, d: 6))
        let p = DivideFrac6.Parts(l.numbers)
        XCTAssertEqual(p.S, 6); XCTAssertEqual(p.L, 20); XCTAssertEqual(p.simpleBoxes, ["sn", "sd"])
        while l.step.answer?.boxes != ["sn", "sd"] { l.reset(); for (k, v) in l.step.answer?.expected ?? [:] { l.active = k; for ch in fmt(v) { l.type(String(ch)) } }; _ = l.go() }
        XCTAssertEqual(typeAll(&l, [("sn", 6), ("sd", 20)]), .notYet("Same amount. Both 6 and 20 still divide by 2."))
        XCTAssertEqual(typeAll(&l, [("sn", 3), ("sd", 10)]), .moved(7))
        XCTAssertEqual(l.words.say, "3/10 of a 5/6 fits.")
        // the cut finds bigger pieces than the flip writes (1/4 ÷ 1/6: 3 pieces ÷ 2)
        let c = DivideFrac6.Parts(DivideFrac6.numbers(a: 1, b: 4, c: 1, d: 6))
        XCTAssertEqual(c.S1, 3); XCTAssertEqual(c.L1, 2); XCTAssertEqual(c.S, 6); XCTAssertEqual(c.L, 4)
        // the story is the ribbon, in the pick's words
        let st = DivideFrac6.Parts(DivideFrac6.numbers(a: 2, b: 3, c: 1, d: 8, story: true))
        XCTAssertEqual(st.pickSay, "You have 2/3 yard of ribbon. How many times does a 1/8-yard piece fit in it?")
        XCTAssertEqual(DivideFrac6.Parts(DivideFrac6.numbers(a: 7, b: 9, c: 8, d: 9, story: true)).pickSay,
                       "You have 7/9 yard of ribbon. How many times does an 8/9-yard piece fit in it?")
    }

    func testDivideGenerator() {
        for i in 0..<9 {
            each(DivideFrac6.spec, i) { n in
                let s = DivideFrac6.Parts(n)
                XCTAssertTrue((2...9).contains(s.b) && (2...9).contains(s.d))
                XCTAssertTrue(s.a < s.b && s.c < s.d && s.a > 0 && s.c > 0)
                XCTAssertEqual(Fact6.gcd(s.a, s.b), 1); XCTAssertEqual(Fact6.gcd(s.c, s.d), 1)
                XCTAssertNotEqual(s.a * s.d, s.b * s.c)
                if i < 3 { XCTAssertEqual(s.c, 1); XCTAssertTrue(s.more) }
                XCTAssertEqual(s.story, i >= 3 && i % 3 == 2)
                XCTAssertEqual(s.W % s.b, 0); XCTAssertEqual(s.W % s.d, 0)
                XCTAssertLessThanOrEqual(s.W, 72)
                XCTAssertEqual(s.Al % s.P, 0); XCTAssertEqual(s.Cl % s.P, 0)
            }
        }
        let c = checks(DivideFrac6.spec).map(DivideFrac6.Parts.init)
        XCTAssertTrue(c[1].c > 1 && c[1].more); XCTAssertFalse(c[2].more); XCTAssertTrue(c[3].story && c[3].more)
    }
}
