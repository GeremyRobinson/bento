import XCTest
@testable import ObentoCore

/// 4th grade, chapter 7: Measurement (design/grade4.md, the preview design/prototype/grade4-ch7.html).
final class MeasurementG4Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(71 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 11)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }
    /// Every problem plays through: each step's expected answer is right.
    private func playsThrough(_ spec: LessonSpec, _ x: Numbers, file: StaticString = #filePath, line: UInt = #line) {
        var l = LessonRun(spec, numbers: x)
        for _ in 0..<12 where !l.isLast {
            if let a = l.step.answer { l.reset(); for (k, v) in a.expected { l.set(k, v) } }
            guard case .moved = l.go() else { XCTFail("stuck at step \(l.index) of \(x)", file: file, line: line); return }
        }
        XCTAssertTrue(l.isLast, file: file, line: line)
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[6]
        XCTAssertEqual(ch.title, "Measurement")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Meas4.clock(3 * 60 + 5), "3:05")
        XCTAssertEqual(Meas4.clock(12 * 60 + 40), "12:40")
        XCTAssertEqual(Meas4.dur(80), "1 h 20 min")
        XCTAssertEqual(Meas4.dur(60), "1 h")
        XCTAssertEqual(Meas4.dur(45), "45 min")
        XCTAssertEqual(Meas4.usd(275), "$2.75")
        XCTAssertEqual(Meas4.usd(1000), "$10")
        XCTAssertEqual(Meas4.usd(5), "$0.05")
    }

    // MARK: Converting measurements

    func testConvertFeetWithExtra() {
        var l = LessonRun(Convert4.spec, numbers: Convert4.numbers(k: 0, n: 3, m: 5))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Change it to inches. Drag the ruler along the first foot.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["c": 10]), .notYet("A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."))
        XCTAssertEqual(move(&l, ["c": 3]), .notYet("3 is the feet in a yard. A foot is 12 inches."))
        XCTAssertEqual(move(&l, ["c": 7]), .notYet("That’s 7 inches. Cut all the way along the foot."))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That’s 1 inch. Cut all the way along the foot."))
        XCTAssertEqual(move(&l, ["c": 12]), .moved(2))
        XCTAssertEqual(l.words.say, "How many inches in 3 feet? Type the number.")
        XCTAssertEqual(move(&l, ["R": 30]), .notYet("That’s 3 × 10. Each foot is 12 inches, so multiply by 12."))
        XCTAssertEqual(move(&l, ["R": 15]), .notYet("There are 3 feet, each 12 inches. That’s 3 groups of 12: multiply."))
        XCTAssertEqual(move(&l, ["R": 35]), .notYet("Count on 12 for each foot."))
        XCTAssertEqual(move(&l, ["R": 36]), .moved(3))
        XCTAssertEqual(l.words.say, "Add on the 5 extra inches. Type the number.")
        XCTAssertEqual(move(&l, ["R": 36]), .notYet("3 feet 5 inches has 5 more inches. Add them on."))
        XCTAssertEqual(move(&l, ["R": 96]), .notYet("The 5 inches are already small units. Add them on."))
        XCTAssertEqual(move(&l, ["R": 40]), .notYet("Count on 5 from 36."))
        XCTAssertEqual(move(&l, ["R": 41]), .moved(4))
        XCTAssertEqual(l.words.say, "Every foot is 12 inches.")
    }

    func testConvertOtherUnits() {
        var l = LessonRun(Convert4.spec, numbers: Convert4.numbers(k: 4, n: 2, m: 0, story: true))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "A race is this long. How many meters is that? Drag the ruler along the first kilometer.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["c": 500]), .notYet("Kilo means a thousand."))
        XCTAssertEqual(move(&l, ["c": 1000]), .moved(2))
        XCTAssertEqual(move(&l, ["R": 2000]), .moved(3))
        var h = LessonRun(Convert4.spec, numbers: Convert4.numbers(k: 2, n: 2, m: 15))
        _ = h.go()
        XCTAssertEqual(move(&h, ["c": 30]), .notYet("That’s 30 minutes. Cut all the way along the hour."))
        XCTAssertEqual(move(&h, ["c": 60]), .moved(2))
        let m = Convert4.Parts(Convert4.numbers(k: 1, n: 4, m: 35))
        XCTAssertEqual(m.cutMiss(10), "A meter is 100 centimeters. “Centi” means a hundredth.")
        XCTAssertEqual(m.pS, 4); XCTAssertEqual(m.np, 10); XCTAssertEqual(m.nx, 7); XCTAssertEqual(m.xS, 2); XCTAssertEqual(m.xW, 14)
        XCTAssertEqual(m.tot, 435)
        // every bar's pieces and the extras' are whole squares
        for u in Convert4.units {
            XCTAssertEqual(u.pv * u.W % u.per, 0, u.one); XCTAssertEqual(u.by * u.W % u.per, 0, u.one); XCTAssertEqual(u.per % u.pv, 0, u.one)
        }
    }

    func testConvertGenerator() {
        for i in 0..<9 {
            each(Convert4.spec, i) { x in
                let s = Convert4.Parts(x)
                XCTAssertTrue((2...(i < 3 ? 5 : 9)).contains(s.n))
                if i < 6 { XCTAssertLessThan(s.k, 4) }
                XCTAssertEqual(s.m % s.u.by, 0); XCTAssertTrue(s.m == 0 || (s.u.lo...s.u.hi).contains(s.m))
                XCTAssertEqual(s.story, i % 3 == 2)
                playsThrough(Convert4.spec, x)
            }
        }
        let c = checks(Convert4.spec).map(Convert4.Parts.init)
        XCTAssertEqual(c[0].m, 0)
        XCTAssertTrue(c[1].m > 0 && [0, 3].contains(c[1].k))
        XCTAssertTrue(c[2].m > 0 && [1, 2].contains(c[2].k))
        XCTAssertTrue(c[3].story)
    }

    // MARK: Measurement story problems

    func testMeasureTime() {
        let x = MeasureStory.numbers(kind: 0, sub: .end1, s: 3 * 60 + 45, L0: 180, hops: [80])
        var l = LessonRun(MeasureStory.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "A game starts at 3:45 and lasts 1 h 20 min. When does it end? Drag a hop out from where you are, one for each part.")
        _ = l.go()
        let s = MeasureStory.Parts(x)
        XCTAssertEqual(s.sx, 9)
        XCTAssertEqual(move(&l, ["x": 9, "h": 20]), .notYet("That hop is 1 h 40 min. The game lasts 1 h 20 min."))
        XCTAssertEqual(move(&l, ["x": 9, "h": -4]), .notYet("That hop takes away. This part is added: hop on."))
        XCTAssertEqual(move(&l, ["x": 9, "h": 16]), .moved(2))
        XCTAssertEqual(l.words.say, "A game starts at 3:45 and lasts 1 h 20 min. When does it end? Type the time.")
        XCTAssertEqual(move(&l, ["H": 5, "M": 65]), .notYet("An hour is 60 minutes."))
        XCTAssertEqual(move(&l, ["H": 4, "M": 5]), .notYet("Read where you land on the line."))
        XCTAssertEqual(move(&l, ["H": 5, "M": 5]), .moved(3))
        XCTAssertEqual(l.words.say, "Hop each part, then read where you land.")
        XCTAssertEqual(s.lead, "3:45 + 1 h 20 min")
    }

    func testMeasureHowLong() {
        let x = MeasureStory.numbers(kind: 0, sub: .len, s: 2 * 60 + 10, t: 3 * 60 + 35, L0: 120)
        var l = LessonRun(MeasureStory.spec, numbers: x)
        XCTAssertEqual(l.words.say, "A movie starts at 2:10 and ends at 3:35. How long is it? Hop from the ring to the end, counting up.")
        _ = l.go()
        let s = MeasureStory.Parts(x)
        XCTAssertEqual(s.hop(x: 2, h: 10), .soft("Hop on to the end."))
        XCTAssertEqual(move(&l, ["x": 12, "h": -3]), .notYet("Count up: hop to the right."))
        XCTAssertEqual(move(&l, ["x": 12, "h": 9]), .notYet("That goes past 3:35."))
        XCTAssertEqual(move(&l, ["x": 12, "h": 7]), .moved(2))
        XCTAssertEqual(s.boxes, ["H", "M"])
        XCTAssertEqual(move(&l, ["H": 1, "M": 15]), .notYet("Add up your hops: a square is 5 minutes."))
        XCTAssertEqual(move(&l, ["H": 1, "M": 25]), .moved(3))
    }

    func testMeasureMoney() {
        let x = MeasureStory.numbers(kind: 1, sub: .change, s: 425, t: 1000)
        var l = LessonRun(MeasureStory.spec, numbers: x)
        XCTAssertEqual(l.words.say, "A book costs $4.25. You pay with a $10 bill. How much change do you get? Hop from the ring to the end, counting up.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 17, "h": 23]), .moved(2))
        XCTAssertEqual(l.words.say, "A book costs $4.25. You pay with a $10 bill. How much change do you get? Type it in dollars.")
        XCTAssertEqual(move(&l, ["R": 14.25]), .notYet("That’s adding. Change is what’s left: take it away."))
        XCTAssertEqual(move(&l, ["R": 575]), .notYet("That’s cents. Write dollars with a point: $5.75."))
        XCTAssertEqual(move(&l, ["R": 5.5]), .notYet("Add up your hops: a square is 25¢."))
        XCTAssertEqual(move(&l, ["R": 5.75]), .moved(3))
    }

    func testMeasureLiquidChangeOfUnit() {
        let x = MeasureStory.numbers(kind: 2, sub: .rep, s: 2000, hops: [-300, -300, -300], B: 2)
        var l = LessonRun(MeasureStory.spec, numbers: x)
        let s = MeasureStory.Parts(x)
        XCTAssertEqual(s.story, "A jug has 2 L of juice. You pour 3 glasses of 300 mL. How much juice is left?")
        XCTAssertEqual(s.lead, "2 L − 3 × 300 mL")
        XCTAssertEqual(s.unitRows.map(\.big), ["2 L"])
        XCTAssertEqual(s.starts, [20, 17, 14])
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 20, "h": 3]), .notYet("That hop adds. This part is taken away: hop back."))
        XCTAssertEqual(move(&l, ["x": 20, "h": -2]), .notYet("That hop is 200 mL. Each glass is 300 mL."))
        XCTAssertEqual(s.hop(x: 20, h: -3), .soft("Now the next part."))
        XCTAssertEqual(move(&l, ["x": 14, "h": -3]), .moved(2))
        XCTAssertEqual(move(&l, ["R": 1.1]), .notYet("2 L is 2,000 mL."))
        XCTAssertEqual(move(&l, ["R": 2900]), .notYet("That’s adding. The story takes it away."))
        XCTAssertEqual(move(&l, ["R": 1100]), .moved(3))
        // a half: 1/2 L is 500 mL
        let h = MeasureStory.Parts(MeasureStory.numbers(kind: 2, sub: .two, s: 0, hops: [500, 400], half: true))
        XCTAssertEqual(h.story, "A bucket gets 1/2 L of rain on Monday and 400 mL on Tuesday. How much rain is that?")
        XCTAssertEqual(h.why[0], "1/2 L is 5 squares: 500 mL.")
        XCTAssertEqual(h.unitRows.map(\.big), ["1/2 L"])
        XCTAssertEqual(h.end, 900)
    }

    func testMeasureGenerator() {
        for i in 0..<9 {
            each(MeasureStory.spec, i, 200) { x in
                let s = MeasureStory.Parts(x)
                if i < 5 { XCTAssertEqual(s.kind, i) }
                if i < 3 { XCTAssertTrue(s.counts || s.hops.count == 1, "one hop early") }
                // everything lands on the line, a square at a time
                let pts = [s.s, s.end] + (s.counts ? [s.t] : [])
                for p in pts { XCTAssertEqual((p - s.L0) % s.per, 0); XCTAssertTrue((0...s.LW).contains(s.x(p)), "\(x)") }
                var at = s.s
                for h in s.hops { XCTAssertEqual(h % s.per, 0); at += h; XCTAssertTrue((0...s.LW).contains(s.x(at)), "\(x)") }
                XCTAssertFalse(s.story.isEmpty)
                playsThrough(MeasureStory.spec, x)
            }
        }
        let c = checks(MeasureStory.spec).map(MeasureStory.Parts.init)
        XCTAssertEqual(c[0].kind, 0); XCTAssertEqual(c[1].kind, 1)
        XCTAssertTrue(c[2].kind == 2 && !c[2].unitRows.isEmpty)
        XCTAssertTrue(c[3].kind == 3 && c[3].hops.count == 2)
    }

    // MARK: Area and perimeter

    func testArea() {
        var l = LessonRun(AreaPerim.spec, numbers: AreaPerim.numbers(l: 5, w: 3))
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Drag the corner out to make the rectangle. A block is a square meter.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["a": 4, "b": 3]), .notYet("That’s 4 m by 3 m. Make it 5 m by 3 m."))
        XCTAssertEqual(move(&l, ["a": 5, "b": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "How many blocks inside? Type the area.")
        XCTAssertEqual(move(&l, ["A": 16]), .notYet("That’s the distance around. Area is length × width."))
        XCTAssertEqual(move(&l, ["A": 8]), .notYet("Area is length × width."))
        XCTAssertEqual(move(&l, ["A": 14]), .notYet("Count the blocks: 3 rows of 5."))
        XCTAssertEqual(move(&l, ["A": 15]), .moved(3))
        XCTAssertEqual(l.words.say, "Now the edge. Trace one long side and one short side.")
        XCTAssertEqual(move(&l, ["t": 5]), .notYet("That’s 5 m. Trace one long side and one short side."))
        XCTAssertEqual(move(&l, ["t": 10]), .notYet("That’s 5 m + 3 m + 2 m = 10 m. Trace one long side and one short side."))
        XCTAssertEqual(move(&l, ["t": 8]), .moved(4))
        XCTAssertEqual(move(&l, ["H": 15]), .notYet("This step goes along the edge: one long side plus one short side."))
        XCTAssertEqual(move(&l, ["H": 8]), .moved(5))
        XCTAssertEqual(l.words.say, "All the way round is that twice. Type the perimeter.")
        XCTAssertEqual(move(&l, ["Q": 15]), .notYet("Perimeter goes around the edge: add all four sides."))
        XCTAssertEqual(move(&l, ["Q": 12]), .notYet("Both halves go round: 2 × 8."))
        XCTAssertEqual(move(&l, ["Q": 16]), .moved(6))
        XCTAssertEqual(l.words.say, "Area counts the square meters inside; perimeter goes round the edge.")
    }

    func testAreaBigAndFolds() {
        let big = AreaPerim.Parts(AreaPerim.numbers(l: 15, w: 10))
        XCTAssertEqual(big.U, 2)
        var l = LessonRun(AreaPerim.spec, numbers: AreaPerim.numbers(l: 15, w: 10))
        XCTAssertEqual(l.words.say, "Drag the corner out to make the rectangle. 2 squares are 1 m.")
        _ = l.go(); _ = move(&l, ["a": 15, "b": 10])
        XCTAssertEqual(l.words.say, "How many square meters inside? Type the area.")
        // the area is both 16 and the perimeter 16 for a 4 by 4: no perimeter slip then
        var sq = LessonRun(AreaPerim.spec, numbers: AreaPerim.numbers(l: 4, w: 4))
        _ = sq.go(); _ = move(&sq, ["a": 4, "b": 4])
        XCTAssertEqual(move(&sq, ["A": 16]), .moved(3))
        // the area given
        var a = LessonRun(AreaPerim.spec, numbers: AreaPerim.numbers(l: 6, w: 4, fold: 1))
        XCTAssertEqual(a.steps.count, 4)
        XCTAssertEqual(a.words.say, "Drag the side out until the blocks make the area.")
        _ = a.go()
        XCTAssertEqual(move(&a, ["a": 5]), .notYet("4 × 5 = 20. The area is 24 m²."))
        XCTAssertEqual(move(&a, ["a": 6]), .moved(2))
        XCTAssertEqual(a.words.say, "How long is the top? Type it.")
        XCTAssertEqual(move(&a, ["R": 5]), .notYet("What times 4 makes 24? Count the blocks along the top."))
        XCTAssertEqual(move(&a, ["R": 6]), .moved(3))
        // the perimeter given
        var p = LessonRun(AreaPerim.spec, numbers: AreaPerim.numbers(l: 7, w: 3, fold: 2))
        XCTAssertEqual(p.words.say, "Half the way round is one long side and one short side. Trace along the top and down the side.")
        _ = p.go()
        XCTAssertEqual(move(&p, ["t": 7]), .notYet("That’s 7 m. Go along the top, then down the side."))
        XCTAssertEqual(move(&p, ["t": 9]), .notYet("That’s 7 m + 2 m = 9 m. Half of 20 m is 10 m."))
        XCTAssertEqual(move(&p, ["t": 10]), .moved(2))
        XCTAssertEqual(move(&p, ["R": 10]), .notYet("10 is both sides. Take away the 7 m top."))
        XCTAssertEqual(move(&p, ["R": 13]), .notYet("Half of 20 is 10: take 7 from that."))
        XCTAssertEqual(move(&p, ["R": 4]), .notYet("7 and what make 10?"))
        XCTAssertEqual(move(&p, ["R": 3]), .moved(3))
    }

    func testAreaGenerator() {
        for i in 0..<9 {
            each(AreaPerim.spec, i) { x in
                let s = AreaPerim.Parts(x)
                if i < 6 { XCTAssertEqual(s.fold, 0) }
                if s.fold == 0 { XCTAssertTrue((3...15).contains(s.l) && (2...10).contains(s.w)) }
                if s.fold == 1 { XCTAssertLessThanOrEqual(s.A, 150) }
                playsThrough(AreaPerim.spec, x)
            }
        }
        let c = checks(AreaPerim.spec).map(AreaPerim.Parts.init)
        XCTAssertLessThanOrEqual(c[0].l, 10); XCTAssertGreaterThanOrEqual(c[1].l, 11); XCTAssertNotEqual(c[3].fold, 0)
    }

    // MARK: Line plots with fractions

    func testLinePlotDifference() {
        let data = [3, 5, 6, 6, 6, 7, 2, 5]
        let x = LinePlot4.numbers(d: 4, thing: 0, lo: 0, ask: 0, v: 6, data: data, make: true)
        var l = LessonRun(LinePlot4.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Each X is one ribbon. Place the first three. Tap the line where the card’s length is.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["k": 0, "u": 2]), .notYet("That’s 1/2. This ribbon is 3/4."))
        XCTAssertEqual(move(&l, ["k": 1, "u": 5]), .notYet("Now the next card."))
        XCTAssertEqual(move(&l, ["k": 2, "u": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "How much longer is the longest ribbon than the shortest? Tap the longest.")
        XCTAssertEqual(move(&l, ["u": 6]), .notYet("That’s 1 1/2. The longest is the X farthest to the right."))
        XCTAssertEqual(move(&l, ["u": 7]), .moved(3))
        XCTAssertEqual(move(&l, ["u": 3]), .notYet("That’s 3/4. The shortest is the X farthest to the left."))
        XCTAssertEqual(move(&l, ["u": 2]), .moved(4))
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("That lands on 1 1/2. Hop to the longest X."))
        XCTAssertEqual(move(&l, ["h": 5]), .moved(5))
        XCTAssertEqual(l.words.say, "How much longer is the longest ribbon than the shortest? Type the difference.")
        XCTAssertEqual(LinePlot4.Parts(x).boxes, ["W", "N", "D"])
        XCTAssertEqual(move(&l, ["W": 2, "N": 1, "D": 4]), .notYet("How much longer means subtract."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 2, "D": 4]), .notYet("Count the jumps between the two X’s, not the marks."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 3, "D": 4]), .notYet("1 3/4 − 1/2. Count the spaces between them on the line."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 1, "D": 0]), .notYet("The bottom number can’t be 0."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 2, "D": 8]), .moved(6))
        XCTAssertEqual(l.words.say, "Each X is one ribbon, over its length.")
    }

    func testLinePlotTotalAndLonger() {
        let data = [5, 5, 5, 5, 6, 7, 3, 4, 6]
        var t = LessonRun(LinePlot4.spec, numbers: LinePlot4.numbers(d: 4, thing: 1, lo: 0, ask: 1, v: 5, data: data))
        XCTAssertEqual(t.steps.count, 4)
        XCTAssertEqual(t.words.say, "Laid end to end, how long are the pencils at 1 1/4 in? Tap the pencils at 1 1/4.")
        _ = t.go()
        XCTAssertEqual(move(&t, ["u": 6]), .notYet("That’s the stack above 1 1/2. Find 1 1/4 first."))
        XCTAssertEqual(move(&t, ["u": 5]), .moved(2))
        XCTAssertEqual(move(&t, ["W": 4, "N": 0, "D": 1]), .notYet("That’s how many. Each one is 1 1/4 long: add 1 1/4 4 times."))
        XCTAssertEqual(move(&t, ["W": 3, "N": 3, "D": 4]), .notYet("There are 4 of them: add 1 1/4 4 times."))
        XCTAssertEqual(move(&t, ["W": 5, "N": 1, "D": 4]), .notYet("Add 1 1/4 once for each pencil."))
        XCTAssertEqual(move(&t, ["W": 5, "N": 0, "D": 4]), .moved(3))
        var g = LessonRun(LinePlot4.spec, numbers: LinePlot4.numbers(d: 4, thing: 2, lo: 0, ask: 2, v: 5, data: data))
        XCTAssertEqual(g.steps.count, 3)
        XCTAssertEqual(g.words.say, "How many sprouts are taller than 1 1/4 in? Tap each X taller than 1 1/4, or None.")
        _ = g.go()
        XCTAssertEqual(move(&g, ["x": 5]), .notYet("1 1/4 isn’t taller than 1 1/4."))
        XCTAssertEqual(move(&g, ["x": 3]), .notYet("That’s 3/4: shorter than 1 1/4."))
        XCTAssertEqual(move(&g, ["x": -1]), .notYet("Look again: some X’s are past 1 1/4."))
        XCTAssertEqual(move(&g, ["x": LinePlot4.allLit]), .moved(2))
        // nothing longer: None is right
        var n = LessonRun(LinePlot4.spec, numbers: LinePlot4.numbers(d: 4, ask: 2, v: 7, data: data))
        _ = n.go()
        XCTAssertEqual(move(&n, ["x": -1]), .moved(2))
    }

    func testLinePlotGenerator() {
        for i in 0..<9 {
            each(LinePlot4.spec, i, 150) { x in
                let s = LinePlot4.Parts(x)
                XCTAssertEqual(s.make, i < 3)
                if i < 3 { XCTAssertEqual(s.d, 4); XCTAssertEqual(s.ask, 0) } else { XCTAssertEqual(s.ask, i % 3) }
                XCTAssertTrue((8...12).contains(s.data.count))
                XCTAssertTrue(s.data.allSatisfy { $0 > s.lo && $0 <= s.top }, "\(s.data)")
                if s.ask < 2 { XCTAssertNotEqual(s.fin % s.d, 0) }
                playsThrough(LinePlot4.spec, x)
            }
        }
        let c = checks(LinePlot4.spec).map(LinePlot4.Parts.init)
        XCTAssertEqual(c.map(\.ask).prefix(3), [0, 1, 2]); XCTAssertEqual(c[3].d, 8)
        XCTAssertEqual(LinePlot4.said(7, 4), "1 3/4"); XCTAssertEqual(LinePlot4.said(6, 8), "3/4"); XCTAssertEqual(LinePlot4.said(8, 4), "2")
    }
}
