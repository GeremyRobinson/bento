import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 1: Multiply and divide (design/grade3.md, the preview design/prototype/grade3-ch1.html).
final class MultDiv3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[0]
        XCTAssertEqual(ch.title, "Multiply and divide")
        XCTAssertEqual(Curriculum.chapters(3).count, 7)
        XCTAssertEqual(Curriculum.chapters(3).flatMap(\.lessons).count, 28)
        XCTAssertTrue(Curriculum.isLive(3))
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testCells() {
        XCTAssertEqual(G3.cell(5), 5); XCTAssertEqual(G3.cell(7), 4); XCTAssertEqual(G3.cell(8), 3)
        XCTAssertEqual(G3.cap(4, 5), 6); XCTAssertEqual(G3.cap(10, 3), 10); XCTAssertEqual(G3.cap(7, 4), 9); for m in 2...10 { XCTAssertLessThanOrEqual(G3.cell(m) * m, 30) }
    }

    func testFacts() {
        var l = LessonRun(Facts3.spec, numbers: Facts3.numbers(a: 4, b: 6))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Drag down to make 4 rows of 6.")
        XCTAssertEqual(move(&l, ["r": 5]), .notYet("That's 5 rows. 4 × 6 is 4 rows of 6."))
        XCTAssertEqual(move(&l, ["r": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Count by 6s.")
        XCTAssertEqual(move(&l, ["n": 19]), .notYet("Each jump is 6, not 1. 18 + 6 = 24."))
        XCTAssertEqual(move(&l, ["n": 18]), .notYet("That's only 3 jumps of 6. Make 4 jumps."))
        XCTAssertEqual(move(&l, ["n": 30]), .notYet("That's 5 jumps of 6. Stop after 4 jumps."))
        XCTAssertEqual(move(&l, ["n": 10]), .notYet("4 + 6 puts them together once. You need 4 groups of 6."))
        XCTAssertEqual(move(&l, ["n": 23]), .notYet("Not quite. Add 6 to the last number you see."))
        XCTAssertEqual(move(&l, ["n": 24]), .moved(2))
        XCTAssertEqual(l.words.say, "Turn it.")
        XCTAssertEqual(move(&l, ["q": 2]), .notYet("That's a half turn: still 4 rows of 6. Stop at a quarter turn."))
        XCTAssertEqual(move(&l, ["q": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Now write 6 × 4.")
        XCTAssertEqual(move(&l, ["t": 10]), .notYet("× means groups. 6 groups of 4 is 24, not 10."))
        XCTAssertEqual(move(&l, ["t": 36]), .notYet("That's 6 × 6. Here it is 6 groups of 4."))
        XCTAssertEqual(move(&l, ["t": 24]), .moved(4))
        XCTAssertEqual(l.words.say, "Same dots, turned: 4 × 6 = 6 × 4.")

        var sq = LessonRun(Facts3.spec, numbers: Facts3.numbers(a: 6, b: 6))
        XCTAssertEqual(sq.steps.count, 3)
        _ = move(&sq, ["r": 6]); XCTAssertEqual(move(&sq, ["n": 36]), .moved(2))
        XCTAssertEqual(sq.words.say, "6 rows of 6 make 36.")

        let long = Facts3.Parts(Facts3.numbers(a: 7, b: 3))
        XCTAssertEqual(long.shown, [3, 6, nil, 15, 18])
        XCTAssertEqual(Facts3.Parts(Facts3.numbers(a: 4, b: 6)).shown, [6, 12, 18])
        for i in 0..<8 {
            each(Facts3.spec, i) { x in
                let P = Facts3.Parts(x)
                if i < 3 { XCTAssertTrue([2, 5, 10].contains(P.b)); XCTAssertTrue(P.b == 5 ? [3, 4, 6].contains(P.a) : (3...6).contains(P.a)) }
                else { XCTAssertTrue((2...10).contains(P.a) && (3...9).contains(P.b)) }
                XCTAssertLessThanOrEqual(P.c * max(P.a, P.b), 30)
            }
        }
        let c = checks(Facts3.spec).map(Facts3.Parts.init)
        XCTAssertTrue(c.allSatisfy { !$0.square }); XCTAssertTrue(c[1].a >= 6 && c[1].b >= 6)
    }

    func testDivFacts() {
        var l = LessonRun(DivFacts3.spec, numbers: DivFacts3.numbers(b: 4, q: 6))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Drag across to share 24 into 4 rows.")
        XCTAssertEqual(move(&l, ["k": 5]), .notYet("4 × 5 = 20. 4 are left. Keep going."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["k": 7]), .notYet("4 × 7 = 28. That's more than 24."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(move(&l, ["k": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Now write 24 ÷ 4.")
        XCTAssertEqual(move(&l, ["d": 4]), .notYet("4 is how many groups there are. How many are in each group?"))
        XCTAssertEqual(move(&l, ["d": 96]), .notYet("Dividing shares 24 out, so the answer is smaller than 24."))
        XCTAssertEqual(move(&l, ["d": 5]), .notYet("Not quite. It's the missing number from 4 × ? = 24."))
        XCTAssertEqual(move(&l, ["d": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "4 rows of 6 make 24, so 24 ÷ 4 = 6.")
        for i in 0..<8 {
            each(DivFacts3.spec, i) { x in
                let P = DivFacts3.Parts(x)
                if i < 3 { XCTAssertTrue([2, 5, 10].contains(P.b) && (2...6).contains(P.q)) } else { XCTAssertTrue((3...9).contains(P.b) && (2...10).contains(P.q)) }
            }
        }
        let c = checks(DivFacts3.spec).map(DivFacts3.Parts.init)
        XCTAssertTrue(c[0].b >= 6); XCTAssertTrue(c[1].q >= 6)
    }

    func testUnknown() {
        var l = LessonRun(Unknown3.spec, numbers: Unknown3.numbers(a: 8, b: 6, form: 0))
        XCTAssertEqual(l.words.say, "Drag the side until it holds 48.")
        XCTAssertEqual(move(&l, ["e": 7]), .notYet("8 rows of 7 is 56. That's more than 48."))
        XCTAssertEqual(move(&l, ["e": 5]), .notYet("8 rows of 5 is 40. That's less than 48."))
        XCTAssertEqual(move(&l, ["e": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Write the missing number.")
        XCTAssertEqual(move(&l, ["u": 40]), .notYet("Taking 8 away once leaves 40. You want 8 rows that make 48."))
        XCTAssertEqual(move(&l, ["u": 48]), .notYet("48 is all the dots together. How many in each row?"))
        XCTAssertEqual(move(&l, ["u": 7]), .notYet("8 rows of 7 is 56. That's more than 48."))
        XCTAssertEqual(move(&l, ["u": 3]), .notYet("Not quite. Count the dots in one row."))
        XCTAssertEqual(move(&l, ["u": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "8 rows of 6 make 48.")

        var t = LessonRun(Unknown3.spec, numbers: Unknown3.numbers(a: 3, b: 5, form: 3))
        XCTAssertEqual(t.words.say, "Drag down to make 3 rows of 5.")
        XCTAssertEqual(move(&t, ["e": 4]), .notYet("That's 4 rows. Make 3 rows of 5."))
        XCTAssertEqual(move(&t, ["e": 3]), .moved(1))
        XCTAssertEqual(move(&t, ["u": 8]), .notYet("3 + 5 puts them together once. 3 rows of 5 is 3 × 5."))
        XCTAssertEqual(move(&t, ["u": 15]), .moved(2))
        XCTAssertEqual(t.words.say, "÷ is a times fact backwards.")

        var d = LessonRun(Unknown3.spec, numbers: Unknown3.numbers(a: 8, b: 6, form: 2, flip: true))
        XCTAssertEqual(move(&d, ["e": 8]), .moved(1))
        XCTAssertEqual(move(&d, ["u": 6]), .notYet("6 is how many in each row. How many rows?"))
        XCTAssertEqual(move(&d, ["u": 8]), .moved(2))
        for i in 0..<8 {
            each(Unknown3.spec, i) { x in
                let P = Unknown3.Parts(x)
                if i < 3 {
                    XCTAssertTrue(P.form == 0 || P.form == 3); XCTAssertFalse(P.flip)
                    XCTAssertTrue([2, 5, 10].contains(P.form == 0 ? P.a : P.b))
                }
                XCTAssertGreaterThanOrEqual(P.cap, P.want)
            }
        }
        let c = checks(Unknown3.spec).map(Unknown3.Parts.init)
        XCTAssertEqual(c[0].form, 0); XCTAssertEqual(c[1].form, 2); XCTAssertEqual(c[2].form, 3); XCTAssertTrue(c[3].flip)
    }

    func testTwoStep() {
        var l = LessonRun(TwoStep3.spec, numbers: TwoStep3.numbers(kind: 0, a: 4, b: 6, c: 5, who: 0))
        let P = TwoStep3.Parts(l.numbers)
        XCTAssertEqual(P.lines, ["Mia has 4 packs of 6 stickers.", "She gives 5 stickers away.", "How many stickers does Mia have left?"])
        XCTAssertEqual(l.words.say, "Drag down to make 4 packs of 6.")
        XCTAssertEqual(move(&l, ["p": 3]), .notYet("That's 3 packs. Mia has 4 packs of 6."))
        XCTAssertEqual(move(&l, ["p": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many stickers.")
        XCTAssertEqual(move(&l, ["g": 10]), .notYet("4 packs of 6 is 4 equal groups. Multiply: 4 × 6."))
        XCTAssertEqual(move(&l, ["g": 24]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide 5 away.")
        XCTAssertEqual(move(&l, ["s": 3]), .notYet("That covers 3. Slide all 5 over the last ones."))
        XCTAssertEqual(move(&l, ["s": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "Write how many are left.")
        XCTAssertEqual(move(&l, ["h": 29]), .notYet("Giving stickers away leaves fewer. Subtract 5."))
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("She gave away 5 in all, not 5 from each pack."))
        XCTAssertEqual(move(&l, ["h": 19]), .moved(4))
        XCTAssertEqual(l.words.say, "The first answer starts the second step.")

        var m = LessonRun(TwoStep3.spec, numbers: TwoStep3.numbers(kind: 1, a: 3, b: 5, c: 4, who: 3))
        _ = move(&m, ["p": 3]); _ = move(&m, ["g": 15])
        XCTAssertEqual(m.words.say, "Slide 4 in.")
        XCTAssertEqual(move(&m, ["s": 2]), .notYet("That's 2 in. Slide all 4 in after the last one."))
        _ = move(&m, ["s": 0])
        XCTAssertEqual(move(&m, ["h": 27]), .notYet("The 4 extra cookies are added once, not to each tray."))
        XCTAssertEqual(move(&m, ["h": 19]), .moved(4))

        var s = LessonRun(TwoStep3.spec, numbers: TwoStep3.share(b: 3, q: 9, c: 5, who: 1))
        let S = TwoStep3.Parts(s.numbers)
        XCTAssertEqual(S.a, 32)
        XCTAssertEqual(S.story, "Leo has 32 crayons. He loses 5. He shares the rest equally into 3 boxes. How many crayons go in each box?")
        XCTAssertEqual(s.words.say, "Slide 5 away.")
        XCTAssertEqual(move(&s, ["s": 0]), .moved(1))
        XCTAssertEqual(move(&s, ["g": 37]), .notYet("5 crayons are gone, so there are fewer. Subtract."))
        XCTAssertEqual(move(&s, ["g": 27]), .moved(2))
        XCTAssertEqual(s.words.say, "Drag across to share them into 3 boxes.")
        XCTAssertEqual(move(&s, ["k": 8]), .notYet("3 × 8 = 24. 3 are left. Keep going."))
        XCTAssertEqual(move(&s, ["k": 10]), .notYet("3 × 10 = 30. That's more than 27."))
        XCTAssertEqual(move(&s, ["k": 9]), .moved(3))
        XCTAssertEqual(s.words.say, "Write how many go in each box.")
        XCTAssertEqual(move(&s, ["h": 3]), .notYet("3 is how many boxes. How many go in each one?"))
        XCTAssertEqual(move(&s, ["h": 9]), .moved(4))
        for i in 0..<8 {
            each(TwoStep3.spec, i) { x in
                let P = TwoStep3.Parts(x)
                if P.kind == 0 { XCTAssertLessThan(P.cc, P.a * P.b) }
                if i < 3 && P.kind < 2 { XCTAssertTrue([2, 5, 10].contains(P.b) && P.a <= 5 && P.cc <= 9) }
                if i < 3 && P.kind == 2 { XCTAssertTrue([2, 5].contains(P.b) && P.q <= 5 && P.cc <= 9) }
                XCTAssertLessThanOrEqual(P.kind == 2 ? P.a : P.a * P.b + P.cc, 110)
            }
        }
        XCTAssertEqual(checks(TwoStep3.spec).map { TwoStep3.Parts($0).kind }, [0, 1, 2, 2])
    }
}
