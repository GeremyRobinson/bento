import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 5: Data (design/grade2.md, the preview design/prototype/grade2-ch5.html).
final class Data2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(55 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }
    private func hop(_ a: Int, _ b: Int) -> Double { Double(Len2.code(a, b)) }

    func testOnTheMap() {
        let ch = Curriculum.chapters(2)[4]
        XCTAssertEqual(ch.title, "Data"); XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Spoken.text("That's 3 in. Hop to the X farthest right."), "That's 3 inches. Hop to the X farthest right.")
    }

    func testMakeGraph() {
        var l = LessonRun(MakeGraph2.spec, numbers: MakeGraph2.numbers(kind: 0, theme: 0, counts: [7, 4, 6, 3]))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Tap to add the pictures.")
        XCTAssertEqual(move(&l, ["r": Double(MakeGraph2.code(row: 0, shown: 8))]), .notYet("That's 8. The tally says 7."))
        XCTAssertEqual(move(&l, ["r": Double(MakeGraph2.code(row: 1, shown: 3))]), .notYet("That's 3. The tally says 4."))
        XCTAssertEqual(move(&l, ["r": 100]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many in all.")
        XCTAssertEqual(move(&l, ["x": 13]), .notYet("That leaves out the apples row. Add all four."))
        XCTAssertEqual(move(&l, ["x": 17]), .notYet("That leaves out the pears row. Add all four."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("Add the four rows again."))
        XCTAssertEqual(move(&l, ["x": 20]), .moved(2))
        XCTAssertEqual(l.words.say, "One picture for each vote, so each row is as long as its tally.")

        let b = LessonRun(MakeGraph2.spec, numbers: MakeGraph2.numbers(kind: 1, theme: 1, counts: [2, 5, 1, 3]))
        XCTAssertEqual(b.words.say, "Drag each bar to its tally.")

        var m = LessonRun(MakeGraph2.spec, numbers: MakeGraph2.numbers(kind: 2, theme: 0, counts: [7, 4, 6, 3], mx: 3))
        XCTAssertEqual(m.words.say, "20 children voted. Drag the pears bar.")
        XCTAssertEqual(move(&m, ["r": 1]), .notYet("That's 18 in all. 20 children voted."))
        XCTAssertEqual(move(&m, ["r": 3]), .moved(1))
        XCTAssertEqual(m.words.say, "20 children voted. Write how many pears.")
        XCTAssertEqual(move(&m, ["x": 20]), .notYet("That's everyone. Write how many pears."))
        XCTAssertEqual(move(&m, ["x": 17]), .notYet("That's the other rows. Take them from 20."))
        XCTAssertEqual(move(&m, ["x": 3]), .moved(2))
        XCTAssertEqual(m.words.say, "20 children voted. The rows make 20, so pears get what's left.")
        let w = LessonRun(MakeGraph2.spec, numbers: MakeGraph2.numbers(kind: 2, theme: 2, counts: [7, 4, 6, 3], mx: 1))
        XCTAssertEqual(w.words.say, "We counted 20 days. Drag the rainy bar.")
        XCTAssertEqual(MakeGraph2.Parts(w.numbers).why, "We counted 20 days. The rows make 20, so rainy gets what's left.")

        for i in 0..<10 {
            each(MakeGraph2.spec, i) { x in
                let P = MakeGraph2.Parts(x)
                if i < 3 { XCTAssertEqual(Set(P.c).count, 4); XCTAssertTrue(P.c.allSatisfy { $0 <= 6 }); XCTAssertEqual(P.kind.rawValue, [0, 1, 0][i]) }
                else { XCTAssertEqual(P.kind.rawValue, [0, 1, 2][(i - 3) % 3]) }
                if P.theme == 2 { XCTAssertTrue(P.total <= 31) }
            }
        }
        let c = checks(MakeGraph2.spec).map(MakeGraph2.Parts.init)
        XCTAssertEqual(c.map { $0.kind.rawValue }, [0, 1, 2, 0])
    }

    func testBarGraph() {
        var l = LessonRun(BarGraph2.spec, numbers: BarGraph2.numbers(theme: 0, values: [7, 4, 5, 2], x: 0, y: 1, more: true))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Read the apples bar.")
        XCTAssertEqual(BarGraph2.Parts(l.numbers).question, "How many more children picked apples than bananas?")
        XCTAssertEqual(move(&l, ["a": Double(BarGraph2.drop(1, 4))]), .notYet("That's the bananas bar. Find apples."))
        XCTAssertEqual(move(&l, ["a": Double(BarGraph2.drop(0, 8))]), .notYet("That's 8. The apples bar stops before 8."))
        XCTAssertEqual(move(&l, ["a": Double(BarGraph2.drop(0, 6))]), .notYet("That's 6. The apples bar goes past 6."))
        XCTAssertEqual(move(&l, ["a": Double(BarGraph2.drop(0, 7))]), .moved(1))
        XCTAssertEqual(l.words.say, "Read the bananas bar.")
        XCTAssertEqual(move(&l, ["b": Double(BarGraph2.drop(1, 4))]), .moved(2))
        XCTAssertEqual(l.words.say, "Hop the part sticking out.")
        XCTAssertEqual(move(&l, ["h": hop(0, 7)]), .notYet("Start where the bananas bar stops."))
        XCTAssertEqual(move(&l, ["h": hop(4, 6)]), .notYet("That's 2. Hop to the end of the apples bar."))
        XCTAssertEqual(move(&l, ["h": hop(4, 7)]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("\"How many more\" means compare. Take 4 away from 7."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("7 is all of the apples. How many more is that than 4?"))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "The part sticking out is how many more.")

        var t = LessonRun(BarGraph2.spec, numbers: BarGraph2.numbers(theme: 1, values: [7, 4, 5, 2], x: 0, y: 1, more: false))
        XCTAssertEqual(BarGraph2.Parts(t.numbers).question, "How many dogs and cats are there in all?")
        _ = move(&t, ["a": Double(BarGraph2.drop(0, 7))]); _ = move(&t, ["b": Double(BarGraph2.drop(1, 4))])
        XCTAssertEqual(t.words.say, "Count on from 7.")
        XCTAssertEqual(move(&t, ["k": 52]), .notYet("That's the fish bar. Count on along cats."))
        XCTAssertEqual(move(&t, ["k": 4]), .moved(3))
        XCTAssertEqual(move(&t, ["x": 3]), .notYet("\"In all\" means put them together. Add 7 and 4."))
        XCTAssertEqual(move(&t, ["x": 11]), .moved(4))
        XCTAssertEqual(t.words.say, "Counting on puts the two bars together.")

        for i in 0..<8 {
            each(BarGraph2.spec, i) { x in
                let P = BarGraph2.Parts(x)
                XCTAssertNotEqual(P.x, P.y)
                if i < 3 { XCTAssertEqual(Set(P.v).count, 4); XCTAssertTrue(P.v.allSatisfy { $0 <= 8 }) }
                if P.more { XCTAssertTrue(P.a > P.b) }
            }
        }
        let c = checks(BarGraph2.spec).map(BarGraph2.Parts.init)
        XCTAssertEqual(c.map(\.more), [c[0].more, true, false, true])
    }

    func testLinePlot() {
        let data = [4, 5, 5, 6, 6, 6, 7, 8]
        var l = LessonRun(LinePlot2.spec, numbers: LinePlot2.numbers(thing: 0, lo: 4, data: data, ask: 0, v: 6))
        let P = LinePlot2.Parts(l.numbers)
        XCTAssertEqual(P.question, "Add a pencil that is 6 inches long. Then how many pencils are 6 inches long?")
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Put its X above its length.")
        XCTAssertEqual(move(&l, ["p": 5]), .notYet("That's above 5. The new pencil is 6 inches."))
        XCTAssertEqual(move(&l, ["p": 999]), .moved(1))
        XCTAssertEqual(l.words.say, "Count the X's over 6.")
        XCTAssertEqual(move(&l, ["k": 105]), .notYet("That's the stack over 5. Count over 6."))
        XCTAssertEqual(move(&l, ["k": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Count the new pencil too: its X is on top of the stack."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That's the stack above 5. Find 6 on the line first."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("That's every pencil. Count only the X's above 6."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "Each X is one pencil, above its length.")

        var t = LessonRun(LinePlot2.spec, numbers: LinePlot2.numbers(thing: 1, lo: 4, data: data, ask: 1))
        XCTAssertEqual(t.words.say, "Tap the tallest stack.")
        XCTAssertEqual(move(&t, ["t": 5]), .notYet("That stack has 2. Find a taller one."))
        XCTAssertEqual(move(&t, ["t": 6]), .moved(1))
        XCTAssertEqual(move(&t, ["x": 3]), .notYet("That's how many X's. Write the length under the stack."))
        XCTAssertEqual(move(&t, ["x": 7]), .notYet("That number is next to the tallest stack. Read the number right under it."))
        XCTAssertEqual(move(&t, ["x": 6]), .moved(2))

        var g = LessonRun(LinePlot2.spec, numbers: LinePlot2.numbers(thing: 2, lo: 4, data: data, ask: 2, v: 6))
        XCTAssertEqual(g.words.say, "Tap each X right of 6.")
        XCTAssertEqual(move(&g, ["k": 106]), .notYet("Longer than 6 doesn't count 6."))
        XCTAssertEqual(move(&g, ["k": 105]), .notYet("That one is shorter than 6."))
        XCTAssertEqual(move(&g, ["k": 2]), .moved(1))
        XCTAssertEqual(move(&g, ["x": 5]), .notYet("Longer than 6 doesn't count 6."))
        XCTAssertEqual(move(&g, ["x": 2]), .moved(2))

        var h = LessonRun(LinePlot2.spec, numbers: LinePlot2.numbers(thing: 3, lo: 4, data: data, ask: 3))
        XCTAssertEqual(h.words.say, "Hop from the shortest to the longest.")
        XCTAssertEqual(move(&h, ["h": hop(5, 8)]), .notYet("Start at the shortest, the X farthest left."))
        XCTAssertEqual(move(&h, ["h": hop(4, 7)]), .notYet("That's 3 in. Hop to the X farthest right."))
        XCTAssertEqual(move(&h, ["h": hop(4, 8)]), .moved(1))
        XCTAssertEqual(move(&h, ["x": 12]), .notYet("How much longer means the difference. Subtract."))
        XCTAssertEqual(move(&h, ["x": 5]), .notYet("Count the hops, not the marks."))
        XCTAssertEqual(move(&h, ["x": 4]), .moved(2))

        var f = LessonRun(LinePlot2.spec, numbers: LinePlot2.fold(thing: 0, lo: 3, data: [3, 5, 5, 7, 8], past: [false, true, false, false, true]))
        XCTAssertEqual(f.words.say, "Put each X above its length.")
        XCTAssertEqual(move(&f, ["p": 106]), .notYet("It's nearest 5."))
        XCTAssertEqual(move(&f, ["p": 4]), .notYet("That's above 4. The pencil ends near 3."))
        XCTAssertEqual(move(&f, ["p": 999]), .moved(1))
        XCTAssertEqual(f.words.say, "Tap the tallest stack.")
        XCTAssertEqual(move(&f, ["t": 5]), .moved(2))
        XCTAssertEqual(move(&f, ["x": 5]), .moved(3))

        for i in 0..<15 {
            each(LinePlot2.spec, i, 150) { x in
                let P = LinePlot2.Parts(x)
                XCTAssertEqual(P.fold, LinePlot2.isFold(i))
                XCTAssertEqual(LinePlot2.modes(P.data).count, 1)
                if P.fold { XCTAssertEqual(P.data.count, 5); XCTAssertTrue(P.hi <= 10); XCTAssertTrue(LinePlot2.howMany(P.data, P.mode) <= 3) }
                else {
                    XCTAssertEqual(P.ask, i < 3 ? i % 2 : i % 4)
                    XCTAssertTrue(P.data.count >= 8 && P.data.count <= 12)
                    if P.ask == 2 { XCTAssertTrue(P.counted >= 1) }
                }
            }
        }
        let c = checks(LinePlot2.spec).map(LinePlot2.Parts.init)
        XCTAssertEqual(c.map(\.ask), [0, 1, 2, 3])
    }
}
