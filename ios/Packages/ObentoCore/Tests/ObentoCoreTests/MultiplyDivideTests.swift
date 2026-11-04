import XCTest
@testable import ObentoCore

/// 4th grade, chapter 2: Multiplying and dividing (design/grade4.md, the preview design/prototype/grade4-ch2.html).
final class MultiplyDivideTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ x: Int, box: String? = nil) -> LessonRun.Outcome {
        l.reset(); if let box { l.active = box }; for ch in String(x) { l.type(String(ch)) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [String: Int]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in String(x) { l.type(String(ch)) } }
        return l.go()
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
        let ch = Curriculum.chapters(4)[1]
        XCTAssertEqual(ch.title, "Multiplying and dividing")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
    }

    // MARK: Times as many

    func testTimesBig() {
        var l = LessonRun(TimesAsMany.spec, numbers: TimesAsMany.numbers(kind: 0, r: 4, m: 3))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make Blue 3 times as long as Red. Drag out copies of Red.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That’s 2 times as long. Blue needs 3 copies of Red."))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("That’s as long as Red. Blue needs 3 copies of Red."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write Blue’s length.")
        XCTAssertEqual(type(&l, 7), .notYet("That’s 3 + 4. 3 times as long makes 3 copies of 4."))
        XCTAssertEqual(type(&l, 8), .notYet("That’s 2 copies. Blue is 3 copies of 4."))
        XCTAssertEqual(type(&l, 16), .notYet("That’s 4 copies. Blue is 3 copies of 4."))
        XCTAssertEqual(type(&l, 13), .notYet("Count Blue’s squares: 3 copies of 4."))
        XCTAssertEqual(type(&l, 12), .moved(3))
        XCTAssertEqual(l.words.say, "3 copies of Red make Blue.")
    }

    func testTimesSmallAndHops() {
        var l = LessonRun(TimesAsMany.spec, numbers: TimesAsMany.numbers(kind: 1, r: 4, m: 3))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Blue is 3 times as long as Red. Find Red. Drag the ruler to cut Blue into equal parts.")
        XCTAssertEqual(TimesAsMany.Parts(l.numbers).divisors, [1, 2, 3, 4, 6])
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s 4 parts. Blue is 3 times Red: 3 parts."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write Red’s length. Red is one part.")
        XCTAssertEqual(type(&l, 9), .notYet("That’s 12 − 3. Blue is 3 equal parts: divide."))
        XCTAssertEqual(type(&l, 3), .notYet("That’s how many parts. Write one part’s length."))
        XCTAssertEqual(type(&l, 5), .notYet("Red is one of the 3 parts. Count its squares."))
        XCTAssertEqual(type(&l, 4), .moved(3))
        XCTAssertEqual(l.words.say, "Blue is 3 Reds, so Red is a third of it.")

        var h = LessonRun(TimesAsMany.spec, numbers: TimesAsMany.numbers(kind: 2, r: 4, m: 3))
        _ = h.go()
        XCTAssertEqual(h.words.say, "How many times as long as Red is Blue? Hop Red along Blue.")
        XCTAssertEqual(move(&h, ["x": 4]), .notYet("That’s past 12."))
        XCTAssertEqual(move(&h, ["x": 2]), .notYet("4 left on Blue: hop on to its end."))
        XCTAssertEqual(move(&h, ["x": 3]), .moved(2))
        XCTAssertEqual(type(&h, 8), .notYet("That’s 12 − 4. Count the hops."))
        XCTAssertEqual(type(&h, 12), .notYet("That’s Blue’s length. Write how many hops."))
        XCTAssertEqual(type(&h, 3), .moved(3))
        XCTAssertEqual(h.words.say, "Red fits in Blue 3 times.")
    }

    func testTimesLonger() {
        var l = LessonRun(TimesAsMany.spec, numbers: TimesAsMany.numbers(kind: 3, r: 4, m: 0, k: 7, longer: true))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make Blue 7 cm longer than Red. Drag Blue’s end a square at a time.")
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("That’s 2 times Red. 7 longer adds 7 squares."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("That’s Red + 5. 7 longer adds 7 squares."))
        XCTAssertEqual(move(&l, ["x": 11]), .moved(2))
        XCTAssertEqual(type(&l, 28), .notYet("That’s 7 times 4. 7 longer adds 7."))
        XCTAssertEqual(type(&l, 11), .moved(3))
        XCTAssertEqual(l.words.say, "Longer adds on; times makes copies.")

        var t = LessonRun(TimesAsMany.spec, numbers: TimesAsMany.numbers(kind: 3, r: 4, m: 3))
        _ = t.go()
        XCTAssertEqual(move(&t, ["x": 8]), .notYet("That’s 2 times Red. 3 times as long makes 3 copies."))
        XCTAssertEqual(move(&t, ["x": 7]), .notYet("3 times as long makes 3 copies."))
        XCTAssertEqual(move(&t, ["x": 12]), .moved(2))
    }

    func testTimesGenerator() {
        for i in 0..<9 {
            each(TimesAsMany.spec, i) { n in
                let s = TimesAsMany.Parts(n)
                XCTAssertEqual(s.kind, i < 3 ? i : i % 4)
                XCTAssertTrue((2...9).contains(s.r))
                if s.lg { XCTAssertTrue((3...12).contains(s.k)); XCTAssertNotEqual(s.k % s.r, 0) }
                else {
                    XCTAssertTrue((2...(i < 3 ? 6 : 9)).contains(s.m))
                    XCTAssertLessThanOrEqual(s.B, i < 3 ? 30 : 60)
                }
            }
        }
        XCTAssertEqual(checks(TimesAsMany.spec).map { TimesAsMany.Parts($0).kind }, [0, 1, 2, 3])
    }

    // MARK: Multiply big numbers

    func testPartial() {
        var l = LessonRun(MultiplyBig.spec, numbers: MultiplyBig.numbers(n: 346, m: 7))
        XCTAssertEqual(l.steps.count, 7)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make 7 rows. Drag the handle down. Each row is one copy.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 5 rows. 346 × 7 needs 7."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the hundreds. 7 rows of 3 hundreds.")
        XCTAssertEqual(l.step.answer?.prompt, [.num(300), .op("×"), .num(7), .op("="), .box("x")])
        XCTAssertEqual(type(&l, 21), .notYet("That’s 3 × 7. The 3 stands for 300, so put two zeros on the end."))
        XCTAssertEqual(type(&l, 210), .notYet("21 hundreds is written 2,100."))
        XCTAssertEqual(type(&l, 2100), .moved(3))
        XCTAssertEqual(type(&l, 28), .notYet("That’s 4 × 7. The 4 stands for 40, so put a zero on the end."))
        XCTAssertEqual(type(&l, 280), .moved(4))
        XCTAssertEqual(l.words.say, "Write the ones. 7 rows of 6 ones.")
        XCTAssertEqual(type(&l, 13), .notYet("This one is times, not plus."))
        XCTAssertEqual(type(&l, 42), .moved(5))
        XCTAssertEqual(type(&l, 2380), .notYet("Add all three parts."))
        XCTAssertEqual(type(&l, 2421), .notYet("Line them up by place and add."))
        XCTAssertEqual(type(&l, 2422), .moved(6))
        XCTAssertEqual(l.words.say, "7 rows of every place make 2,422.")
        // a 0 in the tens: that part is 0
        var z = LessonRun(MultiplyBig.spec, numbers: MultiplyBig.numbers(n: 305, m: 4))
        _ = z.go(); _ = move(&z, ["x": 4]); _ = type(&z, 1200)
        XCTAssertEqual(z.words.say, "Write the tens. There are no tens, so this part is 0.")
        XCTAssertEqual(type(&z, 4), .notYet("There are no tens, so this part is 0."))
        XCTAssertEqual(type(&z, 0), .moved(4))
        // four digits: a thousands step first
        let f = LessonRun(MultiplyBig.spec, numbers: MultiplyBig.numbers(n: 4325, m: 7))
        XCTAssertEqual(f.steps[2].answer?.expected["x"], 28000)
        XCTAssertEqual(f.steps.count, 8)
        XCTAssertEqual(MultiplyBig.spec.story?(f.numbers), "A box holds 4,325 crayons. How many crayons are in 7 boxes?")
    }

    func testPartialGenerator() {
        for i in 0..<9 {
            each(MultiplyBig.spec, i) { n in
                let s = MultiplyBig.Parts(n)
                XCTAssertNotEqual(s.n % 100, 0)
                if s.n >= 1000 { XCTAssertGreaterThanOrEqual(i, 6); XCTAssertTrue((3...9).contains(s.m)) }
                else if i < 3 { XCTAssertTrue((112...399).contains(s.n)); XCTAssertTrue((2...5).contains(s.m)) }
                else { XCTAssertTrue((112...989).contains(s.n)); XCTAssertTrue((3...9).contains(s.m)) }
            }
        }
        let c = checks(MultiplyBig.spec).map(MultiplyBig.Parts.init)
        XCTAssertGreaterThanOrEqual(c[0].n, 1000); XCTAssertEqual(c[1].digit(1), 0); XCTAssertGreaterThanOrEqual(c[2].m, 6)
        XCTAssertTrue(MultiplyBig.spec.check[3].story)
    }

    // MARK: Two-digit times two-digit

    func testTwoByTwo() {
        var l = LessonRun(TwoByTwo.spec, numbers: TwoByTwo.numbers(a: 34, b: 26))
        XCTAssertEqual(l.steps.count, 9)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Cut down where the tens end. Drag the handle along the top.")
        XCTAssertEqual(move(&l, ["x": 20]), .notYet("Cut where the tens end."))
        XCTAssertEqual(move(&l, ["x": 30]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("Cut across where the tens end."))
        XCTAssertEqual(move(&l, ["x": 20]), .moved(3))
        XCTAssertEqual(l.words.say, "Write each part. Each bold square is a hundred.")
        XCTAssertEqual(type(&l, 60), .notYet("Tens times tens makes hundreds: 3 × 2 = 6, so 600."))
        XCTAssertEqual(type(&l, 6), .notYet("That’s 3 × 2. Both are tens, so put two zeros on it."))
        XCTAssertEqual(type(&l, 500), .notYet("Count the part: 6 hundreds."))
        XCTAssertEqual(type(&l, 600), .moved(4))
        XCTAssertEqual(type(&l, 18), .notYet("30 is 3 tens. 3 tens × 6 is 18 tens: 180."))
        XCTAssertEqual(type(&l, 180), .moved(5))
        XCTAssertEqual(type(&l, 8), .notYet("20 is 2 tens. 4 × 2 tens is 8 tens: 80."))
        XCTAssertEqual(type(&l, 80), .moved(6))
        XCTAssertEqual(l.words.say, "Write the last part. Count its squares.")
        XCTAssertEqual(type(&l, 10), .notYet("This one is times, not plus."))
        XCTAssertEqual(type(&l, 23), .notYet("You’re 1 away. Skip-count by 6s, 4 times."))
        XCTAssertEqual(type(&l, 20), .notYet("That’s 4 × 5. Skip-count by 6s, 4 times."))
        XCTAssertEqual(type(&l, 28), .notYet("That’s 4 × 7. Skip-count by 6s, 4 times."))
        XCTAssertEqual(type(&l, 24), .moved(7))
        XCTAssertEqual(type(&l, 624), .notYet("That’s only the two corners. Add the middle parts too."))
        XCTAssertEqual(type(&l, 704), .notYet("Four parts, four numbers to add. Did you add the tens × ones part, 180?"))
        XCTAssertEqual(type(&l, 883), .notYet("Line them up by place and add all four."))
        XCTAssertEqual(type(&l, 884), .moved(8))
        XCTAssertEqual(l.words.say, "Four parts fill the rectangle: 884.")
        XCTAssertEqual(TwoByTwo.spec.story?(l.numbers), "A theater has 26 rows of 34 seats. How many seats are there?")
    }

    func testTwoByTwoGenerator() {
        for i in [0, 2, 3, 6] {
            each(TwoByTwo.spec, i) { n in
                let s = TwoByTwo.Parts(n)
                XCTAssertGreaterThanOrEqual(s.a, s.b)
                XCTAssertNotEqual(s.a % 10, 0); XCTAssertNotEqual(s.b % 10, 0)
                if i < 3 { XCTAssertTrue((11...29).contains(s.a)); XCTAssertTrue((11...19).contains(s.b)) }
                else { XCTAssertTrue((12...99).contains(s.a)); XCTAssertTrue((12...49).contains(s.b)) }
                XCTAssertGreaterThanOrEqual(TwoByTwo.shown(a: s.a, b: s.b), 0.55)
            }
        }
        let c = checks(TwoByTwo.spec).map(TwoByTwo.Parts.init)
        XCTAssertTrue(c[2].u >= 5 && c[2].v >= 5)
    }

    // MARK: Dividing with remainders

    func testDealPlan() {
        // 75 ÷ 4: deal the tens (1 each, 3 left), open them, deal the ones (8 each, 3 left)
        let p = Deal.Plan(n: 75, dv: 4, zeros: false)
        XCTAssertEqual(p.phases, [.deal(1), .open(1, cant: false), .deal(0)])
        XCTAssertEqual(p.before, [[5, 7], [5, 3], [35, 0], [3, 0]])
        XCTAssertEqual(p.shares, [8, 1])
        XCTAssertEqual(p.log, [Deal.Entry(p: 1, s: 1, part: 7), Deal.Entry(p: 0, s: 8, part: 35)])
        // 4,325 ÷ 5: the thousands open first
        let b = Deal.Plan(n: 4325, dv: 5, zeros: true)
        XCTAssertEqual(b.phases, [.open(3, cant: true), .deal(2), .open(2, cant: false), .deal(1), .open(1, cant: false), .deal(0)])
        XCTAssertEqual(b.shares, [5, 6, 8, 0])
        // 832 ÷ 4: the tens can't go round in the middle (a 0 in the share)
        let z = Deal.Plan(n: 832, dv: 4, zeros: true)
        XCTAssertEqual(z.phases, [.deal(2), .open(1, cant: true), .deal(0)])
        XCTAssertEqual(z.log.map(\.s), [2, 0, 8])
        XCTAssertEqual(Deal.cantDeal(z, 1), "3 tens can’t go to 4 rows: that’s 0 tens each. Open them.")
        XCTAssertEqual(Deal.cantDeal(b, 0), "4 thousands can’t go to 5 rows. Open them.")
        XCTAssertEqual(Deal.cantDeal(p, 1), "Only 3 tens left: not enough for 4 rows. Open them.")
    }

    func testDivide() {
        var l = LessonRun(DivideRemainders.spec, numbers: DivideRemainders.numbers(dv: 4, q: 18, r: 3))
        XCTAssertEqual(l.display, [.num(75), .op("÷"), .num(4)])
        XCTAssertEqual(l.steps.count, 6)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Share them into 4 rows. Drag the tens down: one to each row, round after round.")
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("There are enough tens for every row. Drag them down."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Open the tens left. Tap each: it opens into ten ones.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Only 3 tens left: not enough for 4 rows. Open them."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Deal the ones. Drag the ones down: one to each row, round after round.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("11 ones left: enough for another round."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(4))
        XCTAssertEqual(l.words.say, "Write the answer and what’s left. Read across one row. What’s left stays on top.")
        XCTAssertEqual(typeAll(&l, ["Q": 9, "R": 3]), .notYet("Each row has a ten and 8 ones: 18."))
        XCTAssertEqual(typeAll(&l, ["Q": 17, "R": 3]), .notYet("Read across one row: its tens and its ones."))
        XCTAssertEqual(typeAll(&l, ["Q": 18, "R": 7]), .notYet("7 left is enough for another round of 4."))
        XCTAssertEqual(typeAll(&l, ["Q": 18, "R": 2]), .notYet("Count the ones left on top."))
        XCTAssertEqual(typeAll(&l, ["Q": 18, "R": 3]), .moved(5))
        XCTAssertEqual(l.words.say, "3 is less than 4, so 3 are left over.")
        // the hundreds open first when there are some
        let h = LessonRun(DivideRemainders.spec, numbers: DivideRemainders.numbers(dv: 4, q: 86, r: 1))
        XCTAssertEqual(h.steps[1].words.say, "Share them into 4 rows. 3 hundreds can’t go round. Tap each: it opens into ten tens.")
    }

    func testDivideStories() {
        let base = (dv: 4, q: 18, r: 3)
        func run(_ sk: Int) -> LessonRun {
            var l = LessonRun(DivideRemainders.spec, numbers: DivideRemainders.numbers(dv: base.dv, q: base.q, r: base.r, story: sk))
            _ = l.go(); _ = move(&l, ["x": 1]); _ = move(&l, ["x": 1]); _ = move(&l, ["x": 8]); _ = typeAll(&l, ["Q": 18, "R": 3])
            return l
        }
        var n = run(4)
        XCTAssertEqual(n.steps[1].words.say.prefix(40), "75 apples are packed in bags of 4. How m")
        XCTAssertEqual(n.words.say, "How many bags are needed for all of them? Write the story’s answer.")
        XCTAssertEqual(n.step.answer?.prompt, [.box("S"), .text("bags")])
        XCTAssertEqual(type(&n, 18, box: "S"), .notYet("18 bags hold 72. The 3 left need a bag too."))
        XCTAssertEqual(type(&n, 19, box: "S"), .moved(6))
        var s = run(1)
        XCTAssertEqual(type(&s, 19, box: "S"), .notYet("Each friend gets 18. The 3 left aren’t shared."))
        var lo = run(2)
        XCTAssertEqual(type(&lo, 18, box: "S"), .notYet("That’s each friend’s share. The ones left over are on top."))
        XCTAssertEqual(type(&lo, 3, box: "S"), .moved(6))
        var f = run(3)
        XCTAssertEqual(type(&f, 19, box: "S"), .notYet("The 3 left don’t fill a bag."))
        XCTAssertEqual(type(&f, 5, box: "S"), .notYet("Read the story again: what does it ask?"))
    }

    func testDivideGenerator() {
        for i in 0..<12 {
            each(DivideRemainders.spec, i) { n in
                let s = DivideRemainders.Parts(n)
                XCTAssertTrue((3...9).contains(s.dv)); XCTAssertTrue((12...99).contains(s.q)); XCTAssertNotEqual(s.q % 10, 0)
                XCTAssertTrue((0..<s.dv).contains(s.r))
                XCTAssertEqual(s.sk > 0, i >= 3 && i % 2 == 1)
                if s.sk == 2 || s.sk == 4 { XCTAssertGreaterThan(s.r, 0) }
                // the hundreds never go round
                XCTAssertLessThan(BigNumbers.digit(s.n, 2), s.dv)
            }
        }
        let c = checks(DivideRemainders.spec).map(DivideRemainders.Parts.init)
        XCTAssertEqual(c[0].r, 0); XCTAssertTrue(c[1].r > 0 && c[1].q >= 20); XCTAssertGreaterThan(c[2].r, 0); XCTAssertGreaterThan(c[3].sk, 0)
    }

    // MARK: Dividing big numbers

    func testShare() {
        var l = LessonRun(DivideBig.spec, numbers: DivideBig.numbers(dv: 5, q: 865, r: 0))
        XCTAssertEqual(l.display, [.text("4,325"), .op("÷"), .num(5)])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Share them into 5 rows. 4 thousands can’t go round. Tap each: it opens into ten hundreds.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("4 thousands can’t go to 5 rows. Open them."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("8 hundreds left: enough for another round."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(3))
        for x in [1, 6, 1, 5] { _ = move(&l, ["x": Double(x)]) }
        XCTAssertEqual(l.words.say, "Write the answer. Read across one row.")
        XCTAssertEqual(l.step.answer?.boxes, ["Q"])
        XCTAssertEqual(type(&l, 865, box: "Q"), .moved(8))
        XCTAssertEqual(l.words.say, "Share the biggest place first, then open what’s left.")
        // a 0 left out of the share, the opened disks forgotten
        let z = DivideBig.Parts(DivideBig.numbers(dv: 4, q: 208, r: 0))
        XCTAssertEqual(z.wrongQ(28), "4 can’t go into 3 tens: write 0 tens.")
        let o = DivideBig.Parts(DivideBig.numbers(dv: 5, q: 865, r: 0))
        XCTAssertEqual(o.wrongQ(65), "Read across one row, from the biggest place.")
        let lf = DivideBig.Parts(DivideBig.numbers(dv: 4, q: 189, r: 1))   // 757: 7 hundreds deal 1, 3 left
        XCTAssertEqual(lf.wrongQ(111), "The 3 hundreds left are 30 tens more.")
        var r = LessonRun(DivideBig.spec, numbers: DivideBig.numbers(dv: 4, q: 189, r: 1))
        _ = r.go()
        while r.step.answer?.byHand == true { _ = move(&r, ["x": r.step.answer!.expected["x"]!]) }
        XCTAssertEqual(r.step.answer?.boxes, ["Q", "R"])
        XCTAssertEqual(typeAll(&r, ["Q": 189, "R": 5]), .notYet("5 left is enough for another round of 4."))
    }

    func testShareGenerator() {
        for i in 0..<9 {
            each(DivideBig.spec, i) { n in
                let s = DivideBig.Parts(n)
                XCTAssertTrue((3...9).contains(s.dv)); XCTAssertTrue((100...999).contains(s.q)); XCTAssertTrue((0..<s.dv).contains(s.r))
                if i < 3 { XCTAssertLessThanOrEqual(s.n, 999); XCTAssertGreaterThanOrEqual(BigNumbers.digit(s.n, 2), s.dv); XCTAssertFalse(String(s.q).contains("0")) }
                else { XCTAssertTrue((1000...9999).contains(s.n)); XCTAssertLessThan(BigNumbers.digit(s.n, 3), s.dv) }
                XCTAssertEqual(s.story, i >= 6 && i % 2 == 1)
                // every plan ends with the ones; each place's share is the share's digit
                let p = s.plan
                XCTAssertEqual((0..<p.D).reduce(0) { $0 + p.shares[$1] * BigNumbers.pow10($1) }, s.q)
                XCTAssertEqual(p.before.last?[0], s.r)
            }
        }
        let c = checks(DivideBig.spec).map(DivideBig.Parts.init)
        XCTAssertTrue(String(c[1].q).contains("0")); XCTAssertGreaterThanOrEqual(c[2].n, 1000); XCTAssertTrue(c[3].story)
    }

    // MARK: Story problems in steps

    func testStorySteps() {
        var l = LessonRun(StorySteps.spec, numbers: StorySteps.numbers(kind: 0, a: 4, b: 125, c: 186))
        let s = StorySteps.Parts(l.numbers)
        XCTAssertEqual(s.est, 330); XCTAssertEqual(s.n, 314)
        _ = l.go()
        XCTAssertEqual(l.words.say, "A store has 4 crates of 125 apples. It sells 186. How many apples are left? Drag each bar’s end to the nearest ten.")
        XCTAssertEqual(move(&l, ["x": 2018]), .notYet("186 is nearer 190 than 180."))
        XCTAssertEqual(move(&l, ["x": 1012]), .notYet("125 is halfway: halfway rounds up to 130."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the first step. The picture is the estimate.")
        XCTAssertEqual(type(&l, 129), .notYet("That’s 4 + 125. 4 groups of 125: multiply."))
        XCTAssertEqual(type(&l, 520), .notYet("Check it: about 520."))
        XCTAssertEqual(type(&l, 500), .moved(3))
        XCTAssertEqual(type(&l, 686), .notYet("The 186 are taken away. Subtract."))
        XCTAssertEqual(type(&l, 315), .notYet("Check it against the estimate, about 330."))
        XCTAssertEqual(type(&l, 314), .moved(4))
        XCTAssertEqual(l.words.say, "314 is close to 330, so it makes sense.")
        // sharing
        var sh = LessonRun(StorySteps.spec, numbers: StorySteps.numbers(kind: 2, a: 347, b: 6, c: 107))
        XCTAssertEqual(StorySteps.Parts(sh.numbers).est, 40)
        _ = sh.go(); _ = move(&sh, ["x": 1])
        XCTAssertEqual(sh.words.say, "Write the first step. The ruler cut the rest into 6 parts of about 40.")
        XCTAssertEqual(type(&sh, 454), .notYet("107 are taken off first. Subtract."))
        XCTAssertEqual(type(&sh, 240), .moved(3))
        XCTAssertEqual(type(&sh, 234), .notYet("Share it into 6 equal parts: divide."))
        XCTAssertEqual(type(&sh, 1440), .notYet("That’s 6 times as many. Share it: divide."))
        XCTAssertEqual(type(&sh, 40), .moved(4))
        // joined on
        var ad = LessonRun(StorySteps.spec, numbers: StorySteps.numbers(kind: 1, a: 3, b: 47, c: 28))
        _ = ad.go(); _ = move(&ad, ["x": 1]); _ = type(&ad, 141)
        XCTAssertEqual(type(&ad, 113), .notYet("The 28 are joined on. Add."))
    }

    func testStoryStepsGenerator() {
        for i in 0..<9 {
            each(StorySteps.spec, i) { n in
                let s = StorySteps.Parts(n)
                XCTAssertEqual(s.kind, i < 3 ? i % 2 : i % 3)
                XCTAssertNotEqual(s.c % 10, 0); XCTAssertNotEqual(s.first % 10, 0)
                switch s.kind {
                case 2:
                    XCTAssertTrue((200...600).contains(s.a)); XCTAssertEqual((s.a - s.c) % s.b, 0); XCTAssertGreaterThanOrEqual(s.n, 12)
                    // the rounded rest's parts are whole squares
                    XCTAssertEqual(((StorySteps.round10(s.a) - StorySteps.round10(s.c)) / 10) % s.b, 0)
                default:
                    if i < 3 { XCTAssertTrue((3...5).contains(s.a)); XCTAssertTrue((12...95).contains(s.b)); XCTAssertTrue((15...95).contains(s.c)) }
                    else { XCTAssertTrue((105...195).contains(s.b)); XCTAssertLessThanOrEqual(s.a * s.b, 600) }
                    if s.kind == 1 { XCTAssertLessThanOrEqual(s.n, 600) } else { XCTAssertGreaterThanOrEqual(s.n, 20) }
                }
                // the bars fit 62 squares
                XCTAssertLessThanOrEqual(s.share ? StorySteps.round10(s.a) / 10 : s.a * StorySteps.round10(s.b) / 10 + (s.kind == 1 ? StorySteps.round10(s.c) / 10 : 0), 62)
            }
        }
        XCTAssertEqual(checks(StorySteps.spec).map { StorySteps.Parts($0).kind }, [0, 1, 2, 0])
    }
}
