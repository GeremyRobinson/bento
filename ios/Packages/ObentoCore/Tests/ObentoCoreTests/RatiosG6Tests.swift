import XCTest
@testable import ObentoCore

/// 6th grade, chapter 1: Ratios and percents (design/grade6.md, the preview design/prototype/grade6-ch1.html).
final class RatiosG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ x: Int, box: String? = nil) -> LessonRun.Outcome {
        l.reset(); if let box { l.active = box }; for ch in String(x) { l.type(String(ch)) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, Int)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in String(x) { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(61 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        XCTAssertTrue(Grades.isLive(6))
        let chapters = Curriculum.chapters(6)
        XCTAssertEqual(chapters.count, 8)
        XCTAssertEqual(chapters.flatMap(\.lessons).count, 36)
        let ch = chapters[0]
        XCTAssertEqual(ch.title, "Ratios and percents")
        XCTAssertEqual(ch.test, "test-g6-ratios")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        // every chapter is built (the last, Data, on 4 Nov)
        XCTAssertTrue(chapters.allSatisfy(Curriculum.built))
        XCTAssertEqual(Curriculum.grade(of: "g6-ratiotable"), 6)
        XCTAssertEqual(Curriculum.gradeTest(6), "test-grade-6")
        // every 6th grade id is its own
        let ids = chapters.flatMap(\.lessons).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for g in [4, 5] { XCTAssertTrue(Set(Curriculum.chapters(g).flatMap(\.lessons).map(\.id)).isDisjoint(with: ids)) }
    }

    // MARK: Equivalent ratios

    func testRatio() {
        var l = LessonRun(EquivRatio.spec, numbers: EquivRatio.numbers(a: 2, b: 3, k: 4))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Drag down until the right side is 12.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("9 so far. Another row."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("6 so far. More rows."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 15, past 12."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the left side.")
        XCTAssertEqual(type(&l, 11), .notYet("Multiply both numbers by the same number. 4 rows of 2 on the left."))
        XCTAssertEqual(type(&l, 6), .notYet("4 rows of 2 on the left."))
        XCTAssertEqual(type(&l, 8), .moved(3))
        XCTAssertEqual(l.words.say, "4 rows of 2 : 3 make 8 : 12. Both sides grew 4 times.")
    }

    func testRatioGenerator() {
        for i in 0..<8 {
            each(EquivRatio.spec, i) { n in
                let s = EquivRatio.Parts(n), top = i < 3 ? 5 : 9
                XCTAssertTrue((1...top).contains(s.a)); XCTAssertTrue((2...top).contains(s.b))
                XCTAssertNotEqual(s.a, s.b); XCTAssertEqual(Ratio6.gcd(s.a, s.b), 1)
                XCTAssertTrue((2...(i < 3 ? 3 : 9)).contains(s.k))
                XCTAssertLessThanOrEqual(s.a + s.b, 17)
            }
        }
        let c = checks(EquivRatio.spec).map(EquivRatio.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].k, 5); XCTAssertGreaterThan(c[2].a, c[2].b)
    }

    // MARK: Ratio tables

    func testRatioTableOneGap() {
        var l = LessonRun(RatioTable.spec, numbers: RatioTable.numbers(a: 2, b: 3, tL: 3, tP: 7))
        l.skipAsk()
        XCTAssertEqual(l.words.say, "Put a point for each of the first two columns.")
        // a point is its squares: across × 100 + up (two squares a unit)
        XCTAssertEqual(move(&l, ["x": Double(4 * 100 + 6), "m": 0]), .notYet("That’s (2, 3). Minutes go across."))
        XCTAssertEqual(move(&l, ["x": Double(10 * 100 + 4), "m": 0]), .notYet("2 laps take 3 minutes."))
        XCTAssertEqual(move(&l, ["x": Double(10 * 100 + 4), "m": 1]), .notYet("4 laps take 6 minutes."))
        XCTAssertEqual(move(&l, ["x": Double(6 * 100 + 4), "m": 0]), .notYet("Put a point for the other column."))
        XCTAssertEqual(move(&l, ["x": Double(12 * 100 + 8), "m": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide along the line to 6 laps.")
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("That’s 8 laps. This column has 6."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 5 laps. This column has 6."))
        XCTAssertEqual(move(&l, ["x": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "Write the column past the paper.")
        // 14 laps: 2 laps take 3 minutes; adding 12 to both makes 15
        XCTAssertEqual(type(&l, 15), .notYet("Adding 12 to both isn’t the same ratio. 14 laps is 7 × 2 laps."))
        XCTAssertEqual(type(&l, 9), .notYet("That’s the minutes for 6 laps."))
        XCTAssertEqual(type(&l, 20), .notYet("14 laps is 7 × 2 laps."))
        XCTAssertEqual(type(&l, 21), .moved(4))
        XCTAssertEqual(l.words.say, "Slide to 1 lap.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That’s 2 laps. Slide to 1 lap."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "Write how long 1 lap takes.")
        XCTAssertEqual(typeAll(&l, [("w", 1)]), .notYet("Fill in every box."))
        XCTAssertEqual(typeAll(&l, [("w", 1), ("n", 2), ("d", 3)]), .notYet("2 laps take 3 minutes, so 1 lap takes 3 ÷ 2 minutes."))
        XCTAssertEqual(typeAll(&l, [("w", 1), ("n", 2), ("d", 4)]), .moved(6))
        XCTAssertEqual(l.words.say, "Equal ratios sit on one straight line through 0.")
    }

    func testRatioTableBothWaysAndThirds() {
        var l = LessonRun(RatioTable.spec, numbers: RatioTable.numbers(a: 3, b: 5, tL: 3, tM: 4, tP: 6, story: 1))
        l.skipAsk()
        XCTAssertEqual(move(&l, ["x": Double(20 * 100 + 12), "m": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide along the line to 9 pages.")
        XCTAssertEqual(move(&l, ["x": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "Slide along the line to 20 minutes.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("That’s 15 minutes. This column has 20."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(4))
        XCTAssertEqual(type(&l, 30), .moved(5))
        // a is 3: 1 page isn't a grid point, so it's only written
        XCTAssertEqual(l.words.say, "Write how long 1 page takes.")
        XCTAssertEqual(typeAll(&l, [("w", 1), ("n", 2), ("d", 3)]), .moved(6))
        var w = LessonRun(RatioTable.spec, numbers: RatioTable.numbers(a: 1, b: 4, tL: 3, tP: 8))
        w.skipAsk()
        _ = move(&w, ["x": Double(16 * 100 + 4), "m": 1]); _ = move(&w, ["x": 6])
        XCTAssertEqual(type(&w, 32), .moved(4))
        XCTAssertEqual(move(&w, ["x": 2]), .moved(5))
        XCTAssertEqual(type(&w, 3, box: "w"), .notYet("Look at the first column."))
        XCTAssertEqual(type(&w, 4, box: "w"), .moved(6))
    }

    func testRatioTableCompare() {
        // Ana 1 lap in 2 minutes, Ben 1 lap in 3: at 12 minutes, 6 laps to 4
        var l = LessonRun(RatioTable.spec, numbers: RatioTable.compare(X: 12, a1: 1, b1: 2, a2: 1, b2: 3))
        l.skipAsk()
        XCTAssertEqual(l.words.say, "Put a point for each table’s first column.")
        XCTAssertEqual(move(&l, ["x": Double(2 * 100 + 4), "m": 0]), .notYet("That’s (1, 2). Minutes go across."))
        XCTAssertEqual(move(&l, ["x": Double(10 * 100 + 10), "m": 0]), .notYet("Ana: 1 lap takes 2 minutes."))
        XCTAssertEqual(move(&l, ["x": Double(10 * 100 + 10), "m": 1]), .notYet("Ben: 1 lap takes 3 minutes."))
        XCTAssertEqual(move(&l, ["x": Double(6 * 100 + 2), "m": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Drag up the line at 12 minutes.")
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("Keep going up to both lines."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(3))
        XCTAssertEqual(l.words.say, "Who runs more laps in 12 minutes? Tap a name.")
        XCTAssertEqual(l.step.answer?.choices, ["Ana", "Ben"])
        l.choose(1)
        XCTAssertEqual(l.go(), .notYet("Ben runs 4 laps. Ana runs 6."))
        l.choose(0)
        XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.words.say, "Ana runs more: 6 laps to 4. Equal ratios sit on one straight line through 0.")
    }

    func testRatioTableGenerator() {
        for i in 0..<9 {
            each(RatioTable.spec, i) { n in
                let s = RatioTable.Parts(n)
                if i >= 6 {
                    XCTAssertTrue(s.compares)
                    XCTAssertNotEqual(s.A.name, s.B.name)
                    XCTAssertFalse(s.A.a == s.B.a && s.A.b == s.B.b)
                    XCTAssertEqual(s.X % s.A.b, 0); XCTAssertEqual(s.X % s.B.b, 0)
                    XCTAssertLessThanOrEqual(s.X, 24); XCTAssertLessThanOrEqual(s.top, 12)
                    XCTAssertNotEqual(s.at(s.A), s.at(s.B))
                    return
                }
                XCTAssertEqual(s.kind, i >= 3 ? 1 : 0)
                XCTAssertTrue(s.a < s.b && s.a <= 3 && s.b <= 6)
                let tmax = min(24 / s.b, 12 / s.a)
                // the gaps are on the paper, the column past it isn't
                for t in [s.tL] + (s.tM > 0 ? [s.tM] : []) { XCTAssertTrue((3...tmax).contains(t)) }
                if s.kind == 1 { XCTAssertNotEqual(s.tL, s.tM) }
                XCTAssertTrue(s.b * s.tP > 24 || s.a * s.tP > 12)
                XCTAssertTrue(((tmax + 1)...(tmax + 4)).contains(s.tP))
                XCTAssertEqual(s.cols.count, i >= 3 ? 5 : 4)
            }
        }
        let c = checks(RatioTable.spec).map(RatioTable.Parts.init)
        XCTAssertEqual(c.map(\.kind), [0, 1, 1, 2])
        XCTAssertEqual(c[2].a, 3)
    }

    // MARK: Unit rates

    func testRateCost() {
        var l = LessonRun(UnitRate.spec, numbers: UnitRate.numbers(u: 3, n: 4, m: 7, item: 1))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Share $12 over the 4 apples.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("$4 is still left."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s $16. There’s only $12."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Make 7 apples.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 5 apples. Make 7."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(3))
        XCTAssertEqual(l.words.say, "Write how much in all.")
        XCTAssertEqual(type(&l, 84), .notYet("Use the cost of one, $3, not $12."))
        XCTAssertEqual(type(&l, 10), .notYet("7 of them, $3 each: that’s 7 groups of $3."))
        XCTAssertEqual(type(&l, 24), .notYet("Count the squares: 7 rows of 3."))
        XCTAssertEqual(type(&l, 21), .moved(4))
        XCTAssertEqual(l.words.say, "Every apple costs $3, so 7 cost 7 × $3.")
        let s = UnitRate.Parts(l.numbers)
        XCTAssertEqual(s.used(9, 3), "$9 used, $3 left")
        XCTAssertEqual(s.rows(1), "1 apple")
    }

    func testRateSpeedAndUnits() {
        var l = LessonRun(UnitRate.spec, numbers: UnitRate.numbers(u: 12, n: 3, m: 5, kind: .speed))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Share 36 miles over the 3 hours.")
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("3 miles are still left."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(2))
        XCTAssertEqual(l.words.say, "Make 5 hours.")
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("That’s 1 hour. Make 5."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(3))
        XCTAssertEqual(type(&l, 180), .notYet("Use one hour’s 12 miles, not 36."))
        XCTAssertEqual(type(&l, 60), .moved(4))
        XCTAssertEqual(l.words.say, "Every hour goes 12 miles, so 5 hours go 5 × 12.")

        var u = LessonRun(UnitRate.spec, numbers: UnitRate.numbers(u: 12, n: 3, m: 7, kind: .units))
        _ = u.go()
        XCTAssertEqual(u.words.say, "Share 36 inches over the 3 feet.")
        XCTAssertEqual(move(&u, ["x": 13]), .notYet("That’s 39 inches. There are only 36."))
        XCTAssertEqual(move(&u, ["x": 12]), .moved(2))
        XCTAssertEqual(u.words.say, "Make 7 feet.")
        XCTAssertEqual(move(&u, ["x": 7]), .moved(3))
        XCTAssertEqual(type(&u, 19), .notYet("7 feet, 12 inches each: that’s 7 groups of 12."))
        XCTAssertEqual(type(&u, 84), .moved(4))
        XCTAssertEqual(u.words.say, "Every foot is 12 inches, so 7 feet are 7 × 12.")
        let s = UnitRate.Parts(u.numbers)
        XCTAssertEqual(s.perRow, "12 in"); XCTAssertEqual(s.smallUnit, "in"); XCTAssertEqual(s.bigUnit, "ft")
    }

    func testRateGenerator() {
        for i in 0..<8 {
            each(UnitRate.spec, i) { n in
                let s = UnitRate.Parts(n)
                if s.kind == .units { XCTAssertTrue((i < 3 ? [3, 4] : [12, 3, 4, 7, 10]).contains(s.u)) }
                else { XCTAssertTrue((2...(i < 3 ? 5 : 15)).contains(s.u)) }
                XCTAssertTrue((2...(i < 3 ? 4 : 9)).contains(s.n))
                XCTAssertTrue((2...(i < 3 ? 6 : 12)).contains(s.m))
            }
        }
        let c = checks(UnitRate.spec).map(UnitRate.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].n, 5); XCTAssertLessThan(c[2].m, c[2].n); XCTAssertGreaterThanOrEqual(c[3].u, 10)
    }

    // MARK: Percent of a number

    func testPercentOf() {
        var l = LessonRun(PercentOf.spec, numbers: PercentOf.numbers(p: 30, W: 80))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Cut 80 into blocks that make 30%.")
        XCTAssertEqual(move(&l, ["x": 40]), .notYet("Drag the ruler to cut 80."))
        XCTAssertFalse(l.missed)
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("30% isn’t a whole number of quarters."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write one block.")
        XCTAssertEqual(type(&l, 800), .notYet("10% is a part of 80, so it’s smaller than 80."))
        XCTAssertEqual(type(&l, 4), .notYet("10% is one tenth: 80 ÷ 10."))
        XCTAssertEqual(type(&l, 8), .moved(3))
        XCTAssertEqual(l.words.say, "Shade 30%.")
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("Tap blocks to shade them."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That’s the part not taken."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s 40%."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "Write 30%.")
        XCTAssertEqual(type(&l, 240), .notYet("30% is 3 blocks of 10%. Multiply 8 by 3, not 30."))
        XCTAssertEqual(type(&l, 56), .notYet("That’s the part not taken. 30% is the shaded part."))
        XCTAssertEqual(type(&l, 25), .notYet("30% is 3 blocks of 10%."))
        XCTAssertEqual(type(&l, 24), .moved(5))
        XCTAssertEqual(l.words.say, "Each 10% is 8, so 30% is 3 of them.")
    }

    func testPercentQuartersAndHalf() {
        var q = LessonRun(PercentOf.spec, numbers: PercentOf.numbers(p: 75, W: 200))
        q.skipAsk()
        XCTAssertEqual(move(&q, ["x": 4]), .notYet("75% isn’t a whole number of tenths."))
        XCTAssertEqual(move(&q, ["x": 10]), .moved(2))
        XCTAssertEqual(type(&q, 50), .moved(3))
        XCTAssertEqual(move(&q, ["x": 1]), .notYet("That’s the part not taken."))
        XCTAssertEqual(move(&q, ["x": 3]), .moved(4))
        XCTAssertEqual(type(&q, 150), .moved(5))
        XCTAssertEqual(q.words.say, "Each 25% is 50, so 75% is 3 of them.")
        var h = LessonRun(PercentOf.spec, numbers: PercentOf.numbers(p: 50, W: 60))
        h.skipAsk()
        XCTAssertEqual(move(&h, ["x": 10]), .notYet("Those fit. Cut tenths: 50% is 5 blocks of 10%."))
        XCTAssertFalse(h.missed)
        var t = LessonRun(PercentOf.spec, numbers: PercentOf.numbers(p: 10, W: 60))
        t.skipAsk()
        _ = move(&t, ["x": 4]); _ = type(&t, 6); _ = move(&t, ["x": 1])
        XCTAssertEqual(type(&t, 6), .moved(5))
        XCTAssertEqual(t.words.say, "Each 10% is 6.")
    }

    func testPercentOfGenerator() {
        each(PercentOf.spec, 0) { n in
            let s = PercentOf.Parts(n)
            XCTAssertTrue(PercentOf.percents.contains(s.p)); XCTAssertEqual(s.W % 20, 0); XCTAssertTrue((20...400).contains(s.W))
            XCTAssertEqual(s.W * s.base % 100, 0); XCTAssertEqual(s.R, s.blocks * s.part)
        }
        let c = checks(PercentOf.spec).map(PercentOf.Parts.init)
        XCTAssertEqual(c[0].p, 75); XCTAssertTrue([20, 30, 40].contains(c[1].p)); XCTAssertTrue([60, 70, 80, 90].contains(c[2].p))
        XCTAssertFalse([10, 25].contains(c[3].p))
    }

    // MARK: Find the whole

    func testPercentWhole() {
        var l = LessonRun(PercentWhole.spec, numbers: PercentWhole.numbers(p: 25, P: 15))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Lay 25% blocks to 100%.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That’s 75%."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s past 100%."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the whole.")
        XCTAssertEqual(type(&l, 45), .notYet("The whole is 4 of those parts."))
        XCTAssertEqual(type(&l, 60), .moved(3))
        XCTAssertEqual(l.words.say, "4 blocks of 25% make 100%, so the whole is 4 × 15.")
        var t = LessonRun(PercentWhole.spec, numbers: PercentWhole.numbers(p: 50, P: 8))
        t.skipAsk()
        _ = move(&t, ["x": 2])
        XCTAssertEqual(type(&t, 4), .notYet("You want the whole, so it’s bigger than 8."))
        XCTAssertEqual(PercentWhole.Parts(t.numbers).width, 20)
    }

    func testPercentWholeGenerator() {
        for i in 0..<6 {
            each(PercentWhole.spec, i) { n in
                let s = PercentWhole.Parts(n)
                XCTAssertTrue((i < 3 ? [10, 50] : [10, 20, 25, 50]).contains(s.p))
                XCTAssertTrue((2...(i < 3 ? 10 : 30)).contains(s.P))
                XCTAssertGreaterThan(s.most, s.k)
            }
        }
        XCTAssertEqual(checks(PercentWhole.spec).map { PercentWhole.Parts($0).p }, [10, 20, 25, 50])
    }

    /// The hint rule (call of 3 Nov): every hinted step keeps the exact spot for a second miss.
    func testHintsKeepTheSpot() {
        var rng = SeededRandom(seed: 3)
        for l in Curriculum.chapters(6)[0].lessons {
            let spec = Lessons.spec(l.id)!
            for i in 0..<8 {
                for step in spec.steps(spec.generate(&rng, i)) where !step.onMiss.isEmpty {
                    XCTAssertNil(step.onMiss["spot"], l.id)
                    XCTAssertEqual(step.hint2["spot"], 1, l.id)
                }
            }
        }
    }
}
