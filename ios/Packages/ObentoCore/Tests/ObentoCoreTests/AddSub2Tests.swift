import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 1: Adding and subtracting to 100 (design/grade2.md, the preview design/prototype/grade2-ch1.html).
final class AddSub2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(57 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        XCTAssertTrue(Grades.isLive(2))
        let g2 = Curriculum.chapters(2)
        XCTAssertEqual(g2.count, 7); XCTAssertEqual(g2.flatMap(\.lessons).count, 27)
        let ch = g2[0]
        XCTAssertEqual(ch.title, "Adding and subtracting to 100"); XCTAssertEqual(ch.colour, "whole")
        XCTAssertTrue(Curriculum.built(ch)); XCTAssertFalse(Curriculum.built(g2[3]))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)); XCTAssertEqual(Curriculum.grade(of: l.id), 2) }
        XCTAssertEqual(Curriculum.gradeTest(2), "test-grade-2")
        XCTAssertEqual(Spoken.text("Put the ? on what we don't know."), "Put the question mark on what we don't know.")
        XCTAssertEqual(Spoken.text("The ? is a part. How many are left?"), "The question mark is a part. How many are left?")
    }

    // MARK: Facts to 20

    func testFacts() {
        var l = LessonRun(Facts2.spec, numbers: Facts2.numbers(a: 8, b: 5))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Make a ten, or just write it.")
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("8 and 2 make 10, then 3 more."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That's taking away."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("Make a ten first: 8 and 2."))
        XCTAssertEqual(move(&l, ["x": 13]), .moved(1))
        XCTAssertEqual(l.words.say, "Make a ten, and the rest is easy.")
        XCTAssertEqual(Facts2.Parts(Facts2.numbers(a: 8, b: 5)).way, ["10", "+", "3"])
        XCTAssertEqual(Facts2.Parts(Facts2.numbers(a: 8, b: 7)).kind, .pairs)

        var p = LessonRun(Facts2.spec, numbers: Facts2.numbers(a: 6, b: 7))
        XCTAssertEqual(p.words.say, "Pair them up, or just write it.")
        XCTAssertEqual(move(&p, ["x": 12]), .notYet("That's double 6. 7 is one more."))
        XCTAssertEqual(move(&p, ["x": 14]), .notYet("That's double 7. 6 is one less."))
        XCTAssertEqual(move(&p, ["x": 13]), .moved(1))
        XCTAssertEqual(p.words.say, "A double and one more.")
        XCTAssertEqual(Facts2.Parts(Facts2.numbers(a: 6, b: 7)).way, ["6", "+", "6", "+", "1"])

        var d = LessonRun(Facts2.spec, numbers: Facts2.numbers(a: 7, b: 7))
        XCTAssertEqual(move(&d, ["x": 7]), .notYet("That's one 7. Double 7 is 7 and 7."))
        XCTAssertEqual(move(&d, ["x": 14]), .moved(1))
        XCTAssertEqual(d.words.say, "The same number twice.")

        var b = LessonRun(Facts2.spec, numbers: Facts2.numbers(a: 15, b: 8, back: true))
        XCTAssertEqual(b.words.say, "Take 8 away, or just write it.")
        XCTAssertEqual(move(&b, ["x": 23]), .notYet("That's adding."))
        XCTAssertEqual(move(&b, ["x": 8]), .notYet("8 is what you take. What's left?"))
        XCTAssertEqual(move(&b, ["x": 6]), .notYet("Back to 10 takes 5. Then 3 more."))
        XCTAssertEqual(move(&b, ["x": 7]), .moved(1))
        XCTAssertEqual(b.words.say, "Back to 10 first, then the rest.")

        for i in 0..<12 {
            each(Facts2.spec, i) { x in
                let P = Facts2.Parts(x)
                if P.kind == .back { XCTAssertTrue((11...18).contains(P.a)); XCTAssertTrue(i >= 5 && (i - 5) % 3 == 0) }
                else { XCTAssertGreaterThanOrEqual(P.ans, 11); XCTAssertLessThanOrEqual(P.ans, 18) }
                if i == 0 { XCTAssertEqual(P.kind, .ten); XCTAssertTrue((8...9).contains(P.a)) }
                if i == 2 { XCTAssertTrue(P.double) }
            }
        }
        let c = checks(Facts2.spec).map(Facts2.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].ans, 15); XCTAssertEqual(c[2].kind, .back); XCTAssertEqual(c[3].kind, .pairs); XCTAssertNotEqual(c[3].a, c[3].b)
    }

    // MARK: Adding with regrouping

    func testRegroup() {
        var l = LessonRun(Regroup2.spec, numbers: Regroup2.numbers(a: 47, b: 38))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Slide the ones together.")
        XCTAssertEqual(move(&l, ["o": -2]), .notYet("Start with the ones."))
        XCTAssertEqual(move(&l, ["o": -1]), .notYet("Ones go with the ones."))
        XCTAssertEqual(move(&l, ["o": 15]), .moved(1))
        XCTAssertEqual(l.words.say, "Make a ten: tap the full row.")
        XCTAssertEqual(move(&l, ["g": -1]), .notYet("That's 5. A ten needs 10."))
        XCTAssertEqual(move(&l, ["g": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Tens go with the tens."))
        XCTAssertEqual(move(&l, ["t": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Write the answer.")
        XCTAssertEqual(move(&l, ["x": 75]), .notYet("The new ten goes with the tens too: 8 tens, not 7."))
        XCTAssertEqual(move(&l, ["x": 84]), .notYet("Count the tens, then the ones."))
        XCTAssertEqual(move(&l, ["x": 85]), .moved(4))
        XCTAssertEqual(l.words.say, "10 ones make 1 ten, so it joins the tens.")

        var s = LessonRun(Regroup2.spec, numbers: Regroup2.numbers(a: 47, b: 38, story: true))
        XCTAssertEqual(s.steps.count, 6); XCTAssertEqual(s.step.answer?.choices, ["+ Add", "− Take away"])
        XCTAssertEqual(move(&s, ["c": 1]), .notYet("They read books in both months. Put them together."))
        XCTAssertEqual(move(&s, ["c": 0]), .moved(1))
        for i in 0..<12 {
            each(Regroup2.spec, i) { x in
                let P = Regroup2.Parts(x)
                XCTAssertGreaterThanOrEqual(P.O, 10); XCTAssertLessThanOrEqual(P.sum, 99); XCTAssertEqual(P.story, i % 4 == 3)
                if i < 3 { XCTAssertLessThanOrEqual(P.O, 12); XCTAssertLessThanOrEqual(P.at + P.bt, 6); XCTAssertLessThanOrEqual(max(P.a, P.b), 49) }
            }
        }
        let c = checks(Regroup2.spec).map(Regroup2.Parts.init)
        XCTAssertEqual(c[1].left, 0); XCTAssertTrue(c[3].story); XCTAssertFalse(c[2].story)
    }

    // MARK: Subtracting with regrouping

    func testSubRegroup() {
        var l = LessonRun(SubRegroup2.spec, numbers: SubRegroup2.numbers(a: 52, b: 27))
        XCTAssertEqual(l.words.say, "Not enough ones. Open a ten.")
        XCTAssertEqual(move(&l, ["k": -1]), .notYet("Tap a ten to open it."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Take 7 ones.")
        XCTAssertEqual(move(&l, ["o": -2]), .notYet("Start with the ones."))
        XCTAssertEqual(move(&l, ["o": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Take 2 tens.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Tens go over tens."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 35]), .notYet("You did 7 − 2 in the ones. You can't take 7 from 2, so trade a ten first."))
        XCTAssertEqual(move(&l, ["x": 52]), .notYet("Tens go on the left: 2 tens and 5 ones."))
        XCTAssertEqual(move(&l, ["x": 25]), .moved(4))
        XCTAssertEqual(l.words.say, "A ten is 10 ones, so now there are enough.")
        // the traded ten forgotten: 63 − 28 gives 45
        var f = LessonRun(SubRegroup2.spec, numbers: SubRegroup2.numbers(a: 63, b: 28))
        for (k, v) in [("k", 1.0), ("o", 1), ("t", 1)] { _ = move(&f, [k: v]) }
        XCTAssertEqual(move(&f, ["x": 45]), .notYet("You did 8 − 3 in the ones. You can't take 8 from 3, so trade a ten first."))
        XCTAssertEqual(SubRegroup2.Parts(SubRegroup2.numbers(a: 50, b: 27)).open, "No ones. Open a ten.")
        var s = LessonRun(SubRegroup2.spec, numbers: SubRegroup2.numbers(a: 52, b: 27, story: true))
        XCTAssertEqual(move(&s, ["c": 0]), .notYet("Maya used some. Take them away."))
        for i in 0..<12 {
            each(SubRegroup2.spec, i) { x in
                let P = SubRegroup2.Parts(x)
                XCTAssertLessThan(P.ao, P.bo); XCTAssertGreaterThanOrEqual(P.bt, 1); XCTAssertLessThan(P.bt, P.at)
                if i < 3 { XCTAssertGreaterThanOrEqual(P.tensLeft, 1) }
                XCTAssertEqual(P.a, Int(x["a"]!)); XCTAssertEqual(P.b, Int(x["b"]!))
            }
        }
        let c = checks(SubRegroup2.spec).map(SubRegroup2.Parts.init)
        XCTAssertEqual(c[0].ao, 0); XCTAssertLessThan(c[1].diff, 10); XCTAssertTrue(c[3].story)
    }

    // MARK: Add up to four numbers

    func testAddFour() {
        var l = LessonRun(AddFour2.spec, numbers: AddFour2.numbers([27, 34, 16]))
        XCTAssertEqual(l.words.say, "Slide all the ones over.")
        XCTAssertEqual(move(&l, ["o": -2]), .notYet("Start with the ones."))
        XCTAssertEqual(move(&l, ["o": 17]), .moved(1))
        XCTAssertEqual(l.words.say, "Make a ten: tap the full row.")
        XCTAssertEqual(move(&l, ["g": -8]), .notYet("That's 7. A ten needs 10."))
        XCTAssertEqual(move(&l, ["g": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["t": 2]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 67]), .notYet("The new ten goes with the tens."))
        XCTAssertEqual(move(&l, ["x": 61]), .notYet("Add every number. There are 3."))
        XCTAssertEqual(move(&l, ["x": 77]), .moved(4))
        XCTAssertEqual(l.words.say, "Ones with ones, tens with tens, in any order.")
        var t2 = LessonRun(AddFour2.spec, numbers: AddFour2.numbers([18, 29, 17, 15]))
        XCTAssertEqual(t2.steps[1].words.say, "Tap each full row.")
        for (k, v) in [("o", 29.0), ("g", 2), ("t", 3)] { _ = move(&t2, [k: v]) }
        XCTAssertEqual(move(&t2, ["x": 69]), .notYet("The ones made 2 tens."))
        for i in 0..<12 {
            each(AddFour2.spec, i) { x in
                let P = AddFour2.Parts(x)
                XCTAssertGreaterThanOrEqual(P.O, 10); XCTAssertTrue((30...99).contains(P.sum)); XCTAssertLessThanOrEqual(P.O, 29)
                XCTAssertEqual(P.n, i < 3 ? 3 : i % 2 == 0 ? 4 : 3)
                if i < 3 { XCTAssertLessThanOrEqual(P.O, 19); XCTAssertLessThanOrEqual(P.t.reduce(0, +), 6) }
            }
        }
        let c = checks(AddFour2.spec).map(AddFour2.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].O, 20)
    }

    // MARK: Story problems to 100

    func testStory() {
        let x = Story2.numbers(kind: .joinChange, W: 59, p1: 34, who: 0, other: 3, th: 0)
        var l = LessonRun(Story2.spec, numbers: x)
        let P = Story2.Parts(x)
        XCTAssertEqual(P.lines, ["Maya had 34 stickers.", "She got some more. Now she has 59.", "How many did she get?"])
        XCTAssertEqual(l.words.say, "Put the ? on what we don't know.")
        XCTAssertEqual(move(&l, ["u": -2]), .notYet("We know that one: 34."))
        XCTAssertEqual(move(&l, ["u": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("The ? is a part. Take the other part away."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 93]), .notYet("The ? is a part, so it's less than 59."))
        XCTAssertEqual(move(&l, ["x": 25]), .moved(3))
        XCTAssertEqual(l.words.say, "The ? is a part, so take the known part away.")
        XCTAssertFalse(P.same); XCTAssertEqual(P.line.0, 59); XCTAssertEqual(P.U, 2)
        var t = LessonRun(Story2.spec, numbers: Story2.numbers(kind: .takeEnd, W: 62, p1: 28))
        XCTAssertEqual(Story2.Parts(t.numbers).line.2, 34)
        _ = move(&t, ["u": 1]); _ = move(&t, ["c": 1])
        XCTAssertEqual(move(&t, ["x": 32]), .notYet("You can't take 4 from 2. Trade a ten first."))
        XCTAssertEqual(move(&t, ["x": 38]), .notYet("You traded a ten: 5 tens, not 6."))
        let w = Story2.Parts(Story2.numbers(kind: .joinEnd, W: 45, p1: 27))
        XCTAssertTrue(w.same); XCTAssertEqual(w.why, "The ? is the whole, so put the parts together.")
        XCTAssertEqual(Story2.Parts(Story2.numbers(kind: .cmpBig, W: 59, p1: 34, more: false, who: 2, other: 3)).lines.first, "Sam has 25 fewer stickers than Ana.")
        for i in 0..<12 {
            each(Story2.spec, i) { x in
                let P = Story2.Parts(x)
                XCTAssertNotEqual(P.N, P.M); XCTAssertGreaterThanOrEqual(P.p1, 5); XCTAssertGreaterThanOrEqual(P.p2, 5)
                if P.W > 50 { XCTAssertEqual(P.W % 2, 0); XCTAssertEqual(P.p1 % 2, 0) }
                if i < 6 { XCTAssertLessThanOrEqual(P.W, 50); XCTAssertLessThan(P.p1 % 10 + P.p2 % 10, 10) } else { XCTAssertLessThanOrEqual(P.W, 99) }
                if i < 3 { XCTAssertEqual(P.kind, [.joinEnd, .takeEnd, .partWhole][i]) }
                if i == 5 { XCTAssertEqual(P.kind, .cmpDiff); XCTAssertTrue(P.more) }
                XCTAssertEqual(P.W, Int(x["W"]!))
            }
        }
        let c = checks(Story2.spec).map(Story2.Parts.init)
        XCTAssertTrue(c[2].startUnknown); XCTAssertTrue(c[3].mixedUp)
    }

    // MARK: Two-step story problems

    func testTwoStep() {
        let x = TwoStep2.numbers(s: 45, c1: 18, plus1: true, c2: 27, plus2: false, who: 1)
        var l = LessonRun(TwoStep2.spec, numbers: x)
        XCTAssertEqual(TwoStep2.Parts(x).lines, ["Leo had 45 stickers. He got 18 more.", "Then he gave 27 away. How many does he have now?"])
        XCTAssertEqual(l.words.say, "Slide the 18 in.")
        XCTAssertEqual(move(&l, ["m1": -1]), .notYet("He got more. Put them after the end."))
        XCTAssertEqual(move(&l, ["m1": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["x1": 27]), .notYet("He got 18 more, so add."))
        XCTAssertEqual(move(&l, ["x1": 63]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide the 27 in.")
        XCTAssertEqual(move(&l, ["m2": -1]), .notYet("He gave some away. Slide them over the end."))
        XCTAssertEqual(move(&l, ["m2": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["x2": 63]), .notYet("That's after one step. Now the 27."))
        XCTAssertEqual(move(&l, ["x2": 18]), .notYet("Start from 63, the first answer."))
        XCTAssertEqual(move(&l, ["x2": 90]), .notYet("He gave 27 away, so take away."))
        XCTAssertEqual(move(&l, ["x2": 36]), .moved(4))
        XCTAssertEqual(l.words.say, "The first answer is where the second step starts.")

        var m = LessonRun(TwoStep2.spec, numbers: TwoStep2.more(s: 34, d: 15))
        XCTAssertEqual(m.words.say, "Ana has 15 more.")
        XCTAssertEqual(move(&m, ["m1": 12]), .notYet("That's 12 more. Ana has 15 more."))
        XCTAssertEqual(move(&m, ["m1": 15]), .moved(1))
        XCTAssertEqual(move(&m, ["x1": 49]), .moved(2))
        XCTAssertEqual(m.words.say, "Put them together.")
        XCTAssertEqual(move(&m, ["m2": 1]), .moved(3))
        XCTAssertEqual(move(&m, ["x2": 49]), .notYet("That's after one step. Now the 49."))
        XCTAssertEqual(move(&m, ["x2": 83]), .moved(4))
        for i in 0..<12 {
            each(TwoStep2.spec, i) { x in
                let P = TwoStep2.Parts(x)
                XCTAssertEqual(P.more, i >= 6 && i % 3 == 0)
                for st in P.steps { XCTAssertTrue((1...99).contains(st.ans)) }
                if P.U == 2 { XCTAssertEqual(P.s % 2, 0); if P.more { XCTAssertEqual(P.d % 2, 0) } else { XCTAssertEqual(P.c[0] % 2, 0); XCTAssertEqual(P.c[1] % 2, 0) } }
                if i < 3 { XCTAssertEqual(P.plus, [true, false]); XCTAssertFalse(P.trades(0) || P.trades(1)); XCTAssertLessThanOrEqual(P.maxEnd, 50) }
            }
        }
        let c = checks(TwoStep2.spec).map(TwoStep2.Parts.init)
        XCTAssertEqual(c[1].plus, [false, true]); XCTAssertTrue(c[2].trades(0) || c[2].trades(1)); XCTAssertTrue(c[3].more)
    }
}
