import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 6: Time and measuring (design/grade3.md, the preview design/prototype/grade3-ch6.html).
final class Measure3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 200, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(57 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[5]
        XCTAssertEqual(ch.title, "Time and measuring")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testHelpers() {
        XCTAssertEqual(Ms3.clk(9 * 60 + 5), "9:05")
        XCTAssertEqual(Ms3.clk(13 * 60), "1:00")
        XCTAssertEqual(Ms3.clk(12 * 60 + 30), "12:30")
        XCTAssertEqual(Ms3.ampm(12 * 60), "p.m.")
        XCTAssertEqual(Ms3.wc(2000), "2,000")
        XCTAssertEqual(Ms3.wc(130), "130")
    }

    func testClockRead() {
        var l = LessonRun(Clock3.spec, numbers: Clock3.numbers(h: 9, m: 47))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap the hour.")
        XCTAssertEqual(move(&l, ["h": 10]), .notYet("The short hand hasn't reached 10 yet."))
        XCTAssertEqual(move(&l, ["h": 3]), .notYet("Find the short hand. Which number has it just passed?"))
        XCTAssertEqual(move(&l, ["h": 9]), .moved(1))
        XCTAssertEqual(l.words.say, "Drag to the long hand.")
        XCTAssertEqual(move(&l, ["n": 45]), .notYet("That's 45. The hand is 2 marks further."))
        XCTAssertEqual(move(&l, ["n": 48]), .notYet("That's 48. The hand is 1 mark back."))
        XCTAssertEqual(move(&l, ["n": 47]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 9, "y": 9]), .notYet("Each number is 5 minutes. Count by 5s, then 1s."))
        XCTAssertEqual(move(&l, ["x": 10, "y": 47]), .notYet("The short hand hasn't reached 10 yet, so the hour is 9."))
        XCTAssertEqual(move(&l, ["x": 9, "y": 46]), .notYet("That's one mark off. Count the marks again."))
        XCTAssertEqual(move(&l, ["x": 8, "y": 30]), .notYet(Clock3.Parts.plain))
        XCTAssertEqual(move(&l, ["x": 9, "y": 47]), .moved(3))
        XCTAssertEqual(l.words.say, "Past 9, and 47 minutes.")
        // the long hand on the hour's own number: that slip isn't said
        XCTAssertTrue(Clock3.Parts(Clock3.numbers(h: 3, m: 16)).slips.allSatisfy { $0.2 != "That's where the long hand points. The short hand gives the hour." })
    }

    func testClockSet() {
        var l = LessonRun(Clock3.spec, numbers: Clock3.numbers(set: true, h: 4, m: 23))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Turn the long hand to 4:23.")
        XCTAssertEqual(move(&l, ["t": 28]), .notYet("That's 4:28. Back 5 minutes."))
        XCTAssertEqual(move(&l, ["t": 22]), .notYet("That's 4:22. 1 more minute."))
        XCTAssertEqual(move(&l, ["t": 23]), .moved(1))
        XCTAssertEqual(l.words.say, "As the minutes go by, the short hand creeps toward 5.")
    }

    func testClockGenerator() {
        each(Clock3.spec, 0) { n in let P = Clock3.Parts(n); XCTAssertFalse(P.setting); XCTAssertTrue([1, 2].contains(P.M % 5)) }
        each(Clock3.spec, 3) { n in XCTAssertTrue(Clock3.Parts(n).setting) }
        each(Clock3.spec, 4) { n in let P = Clock3.Parts(n); XCTAssertFalse(P.setting); XCTAssertNotEqual(P.M % 5, 0) }
        each(Clock3.spec, 6) { n in XCTAssertGreaterThanOrEqual(Clock3.Parts(n).M, 45) }
    }

    func testElapsed() {
        let P = Elapsed3.Parts(Elapsed3.numbers(start: 9 * 60 + 40, end: 11 * 60 + 15))
        XCTAssertEqual([P.m1, P.h, P.m3, P.th, P.tm, P.W], [20, 1, 15, 1, 35, 36])
        var l = LessonRun(Elapsed3.spec, numbers: Elapsed3.numbers(start: 9 * 60 + 40, end: 11 * 60 + 15))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(move(&l, ["a": 15]), .notYet("That's 9:55. Hop to 10:00."))
        XCTAssertEqual(move(&l, ["a": 20]), .moved(1))
        XCTAssertEqual(move(&l, ["b": 2]), .notYet("That's past 11:15."))
        XCTAssertEqual(move(&l, ["b": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["c": 10]), .notYet("That's 11:10. Hop to 11:15."))
        XCTAssertEqual(move(&l, ["c": 15]), .moved(3))
        XCTAssertEqual(l.words.say, "Write the time in all.")
        XCTAssertEqual(move(&l, ["h": 1, "m": 5]), .notYet("Add the minutes before and after: 20 + 15."))
        XCTAssertEqual(move(&l, ["h": 1, "m": 35]), .moved(4))
        XCTAssertEqual(l.words.say, "To the o'clock, the whole hours, then the minutes.")
        // two minute hops of 60 or more trade for an hour
        var t = LessonRun(Elapsed3.spec, numbers: Elapsed3.numbers(start: 8 * 60 + 15, end: 10 * 60 + 50))
        _ = move(&t, ["a": 45]); _ = move(&t, ["b": 1]); _ = move(&t, ["c": 50])
        XCTAssertEqual(t.words.say, "60 minutes make 1 hour. Write the time in all.")
        XCTAssertEqual(move(&t, ["h": 1, "m": 95]), .notYet("95 minutes is more than an hour. Trade 60 of them for 1 more hour."))
        XCTAssertEqual(move(&t, ["h": 1, "m": 35]), .notYet("You traded 60 minutes for an hour. Add that hour to the 1 hour."))
        XCTAssertEqual(move(&t, ["h": 2, "m": 35]), .moved(4))
    }

    func testElapsedEnds() {
        let x = Elapsed3.ends(start: 15 * 60 + 45, len: 50, ev: 0), P = Elapsed3.Parts(x)
        XCTAssertEqual(P.story, "Practice starts at 3:45 p.m. It lasts 50 minutes. When does it end?")
        var l = LessonRun(Elapsed3.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(move(&l, ["a": 15]), .moved(1))
        XCTAssertEqual(move(&l, ["c": 30]), .notYet("That's 45 minutes in all. It lasts 50."))
        XCTAssertEqual(move(&l, ["c": 35]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 3, "y": 95]), .notYet("There are only 60 minutes in an hour. Go past 4:00."))
        XCTAssertEqual(move(&l, ["x": 3, "y": 35]), .notYet("It ends after 4:00, so the hour is 4."))
        XCTAssertEqual(move(&l, ["x": 4, "y": 35]), .moved(3))
    }

    func testElapsedGenerator() {
        for i in [0, 1, 2, 4, 5, 7] {
            each(Elapsed3.spec, i) { n in
                let P = Elapsed3.Parts(n)
                XCTAssertFalse(P.ends); XCTAssertGreaterThanOrEqual(P.h, 1); XCTAssertLessThanOrEqual(P.W, 60)
                XCTAssertGreaterThan(P.m1, 0); XCTAssertGreaterThan(P.m3, 0)
                if i < 3 { XCTAssertFalse(P.trade); XCTAssertTrue([15, 30, 45].contains(P.m1)) }
            }
        }
        each(Elapsed3.spec, 3) { n in
            let P = Elapsed3.Parts(n)
            XCTAssertTrue(P.ends); XCTAssertGreaterThan(P.start % 60 + P.len, 60); XCTAssertNotEqual(P.end % 60, 0); XCTAssertLessThanOrEqual(P.W, 60)
        }
    }

    func testMassUnit() {
        // a key (index 4): 20 g, 2,000 g, 20 kg
        let P = Mass3.Parts(Mass3.unit(thing: 4))
        XCTAssertEqual(P.order.map { P.labels[$0] }, ["20 g", "2,000 g", "20 kg"])
        XCTAssertEqual(P.rightTag, 0)
        var l = LessonRun(Mass3.spec, numbers: Mass3.unit(thing: 4))
        XCTAssertEqual(l.words.say, "Drag the key onto the scale that fits.")
        XCTAssertEqual(move(&l, ["s": 1]), .notYet("A kilogram is as heavy as a big bottle of water. A key is much lighter: grams."))
        XCTAssertEqual(move(&l, ["s": 0]), .moved(1))
        XCTAssertEqual(move(&l, ["g": 1]), .notYet("2,000 g is about as heavy as a big book. A key is much lighter than that."))
        XCTAssertEqual(move(&l, ["g": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "A key is light: grams.")
        // a dog: 30 kg, 300 g (too light), 3,000 kg
        let D = Mass3.Parts(Mass3.unit(thing: 5))
        XCTAssertEqual(D.order.map { D.labels[$0] }, ["300 g", "30 kg", "3,000 kg"])
        XCTAssertEqual(D.guessed(0), "300 g is about as light as a few apples. A dog is much heavier than that.")
        XCTAssertEqual(D.guessed(2), "3,000 kg is far too heavy for a dog. A dog is much lighter than that.")
    }

    func testMassScale() {
        var l = LessonRun(Mass3.spec, numbers: Mass3.scale(step: 10, value: 130))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(move(&l, ["f": 3]), .notYet("Hop all the way to 50."))
        XCTAssertEqual(move(&l, ["f": 5]), .moved(1))
        XCTAssertEqual(move(&l, ["s": 50]), .notYet("50 is the label. There are 5 small spaces from 0 to 50."))
        XCTAssertEqual(move(&l, ["s": 10]), .moved(2))
        XCTAssertEqual(l.words.say, "Hop from 100 to the needle.")
        XCTAssertEqual(move(&l, ["p": 4]), .notYet("That's past the needle."))
        XCTAssertEqual(move(&l, ["p": 3]), .moved(3))
        XCTAssertEqual(move(&l, ["v": 103]), .notYet("Each mark is 10 g. Count on by 10 from 100."))
        XCTAssertEqual(move(&l, ["v": 130]), .moved(4))
        XCTAssertEqual(l.words.say, "100, then 3 marks of 10.")
        XCTAssertEqual(LessonRun(Mass3.spec, numbers: Mass3.scale(step: 1, value: 15)).steps.count, 4)
    }

    func testMassStory() {
        var l = LessonRun(Mass3.spec, numbers: Mass3.story(op: 0, a: 230, b: 150, kg: false))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Pick what to do. 1 cell is 10 g.")
        XCTAssertEqual(move(&l, ["o": 1]), .notYet(MStory3.opSlip[1]))
        XCTAssertEqual(move(&l, ["o": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Slide 150 g in. 1 cell is 10 g.")
        XCTAssertEqual(move(&l, ["s": 3]), .notYet("That's 30 g in. Slide all 150 g in after the last one."))
        XCTAssertEqual(move(&l, ["s": Double(MStory3.landed)]), .moved(2))
        XCTAssertEqual(move(&l, ["v": 80]), .notYet("The story puts amounts together. Add."))
        XCTAssertEqual(move(&l, ["v": 230]), .notYet("230 g is where the story starts. Add 150 to finish."))
        XCTAssertEqual(move(&l, ["v": 380]), .moved(3))
        XCTAssertEqual(l.words.say, "Two amounts together: add.")
        var d = LessonRun(Mass3.spec, numbers: Mass3.story(op: 3, a: 24, b: 4, kg: true))
        _ = move(&d, ["o": 3])
        XCTAssertEqual(move(&d, ["k": 2]), .notYet("4 × 2 = 8. 16 kg left. Keep going."))
        XCTAssertEqual(move(&d, ["k": 7]), .notYet("4 × 7 = 28. That's more than 24 kg."))
        XCTAssertEqual(move(&d, ["k": 6]), .moved(2))
        XCTAssertEqual(move(&d, ["v": 96]), .notYet("The amount is shared out, so it gets smaller. Divide."))
    }

    func testMassGenerator() {
        each(Mass3.spec, 0) { n in XCTAssertEqual(Mass3.Parts(n).kind, 0) }
        each(Mass3.spec, 1) { n in let P = Mass3.Parts(n); XCTAssertEqual(P.kind, 1); XCTAssertTrue(P.onLabel); XCTAssertTrue([1, 10].contains(P.step)); XCTAssertLessThanOrEqual(P.marks, 20) }
        each(Mass3.spec, 4) { n in let P = Mass3.Parts(n); XCTAssertEqual(P.kind, 1); XCTAssertFalse(P.onLabel) }
        each(Mass3.spec, 5) { n in
            let P = Mass3.Parts(n), S = P.story
            XCTAssertEqual(P.kind, 2); XCTAssertGreaterThan(S.ans, 0)
            if S.op > 0 { XCTAssertTrue(P.kg) }
            XCTAssertLessThanOrEqual(S.op == 0 ? S.A + S.B : S.A, 100)
            if S.op == 3 { XCTAssertEqual(S.a % S.b, 0) }
        }
    }

    func testLitersJug() {
        let P = Liters3.Parts(Liters3.jug(cap: 10, step: 2, value: 8))
        XCTAssertEqual([P.n, P.every, P.marks, P.per], [5, 1, 4, 3])
        var l = LessonRun(Liters3.spec, numbers: Liters3.jug(cap: 10, step: 2, value: 8))
        XCTAssertEqual(l.words.say, "Hop up from 0 to the first label. 1 liter is 3 squares tall here.")
        XCTAssertEqual(move(&l, ["f": 2]), .notYet("That's past the first label."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["s": 1]), .notYet("The marks jump by 2 each, not 1. Look at the labels."))
        XCTAssertEqual(move(&l, ["s": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["u": 3]), .notYet("Hop all the way to the top of the water."))
        XCTAssertEqual(move(&l, ["u": 4]), .moved(3))
        XCTAssertEqual(move(&l, ["v": 4]), .notYet("Each mark is 2 L. Count by 2s."))
        XCTAssertEqual(move(&l, ["v": 10]), .notYet("That's the top of the jug. Read where the water is."))
        XCTAssertEqual(move(&l, ["v": 8]), .moved(4))
        XCTAssertEqual(l.words.say, "4 marks of 2 L.")
        XCTAssertEqual(Liters3.Parts(Liters3.jug(cap: 20, step: 1, value: 13)).every, 2)
    }

    func testLitersAboutAndStory() {
        let P = Liters3.Parts(Liters3.about(t: 1, p: 1))
        XCTAssertEqual(P.vals, [1, 10, 100])
        var l = LessonRun(Liters3.spec, numbers: Liters3.about(t: 1, p: 1))
        XCTAssertEqual(l.words.say, "Tap about how much the bucket holds.")
        XCTAssertEqual(move(&l, ["g": 2]), .notYet("100 L is about half a bathtub. A bucket holds less."))
        XCTAssertEqual(move(&l, ["g": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "About 10 big bottles of water.")
        var s = LessonRun(Liters3.spec, numbers: Liters3.story(op: 2, a: 4, b: 3))
        XCTAssertEqual(s.words.say, "Pick what to do. 1 cell is 1 L.")
        _ = move(&s, ["o": 2])
        XCTAssertEqual(s.words.say, "Drag down to make 4 bottles of 3 L. 1 cell is 1 L.")
        XCTAssertEqual(move(&s, ["e": 3]), .notYet("That's 3 bottles. There are 4."))
        XCTAssertEqual(move(&s, ["e": 4]), .moved(2))
        XCTAssertEqual(move(&s, ["v": 7]), .notYet("Equal groups: multiply, don't add."))
        XCTAssertEqual(move(&s, ["v": 12]), .moved(3))
    }

    func testLitersGenerator() {
        each(Liters3.spec, 0) { n in let P = Liters3.Parts(n); XCTAssertEqual(P.kind, 0); XCTAssertEqual(P.step, 1); XCTAssertTrue([5, 10].contains(P.cap)) }
        each(Liters3.spec, 1) { n in let P = Liters3.Parts(n); XCTAssertEqual(P.cap, 10); XCTAssertEqual(P.step, 2); XCTAssertLessThan(P.value, 10) }
        each(Liters3.spec, 3) { n in XCTAssertEqual(Liters3.Parts(n).kind, 1) }
        each(Liters3.spec, 6) { n in let P = Liters3.Parts(n); XCTAssertEqual(P.kind, 2); XCTAssertTrue(P.vals.contains(P.th.v)); XCTAssertLessThanOrEqual(P.vals[2], 2000) }
        each(Liters3.spec, 4) { n in let P = Liters3.Parts(n); XCTAssertEqual(P.kind, 0); XCTAssertEqual(P.cap % P.step, 0); XCTAssertLessThan(P.value, P.cap) }
    }
}
