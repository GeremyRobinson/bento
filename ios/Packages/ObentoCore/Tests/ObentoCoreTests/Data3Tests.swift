import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 7: Data (design/grade3.md, the preview design/prototype/grade3-ch7.html).
final class Data3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 200, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testShared() {
        XCTAssertEqual(Data3.picWords(9), "4 pictures and a half")
        XCTAssertEqual(Data3.picWords(1), "half a picture")
        XCTAssertEqual(Data3.picWords(2), "1 picture")
        XCTAssertEqual(Data3.lineWords(halves: 7), "3 and a half lines")
        XCTAssertEqual(Data3.lineWords(halves: 2), "1 line")
        XCTAssertEqual(Data3.grain(0, 2), 1); XCTAssertEqual(Data3.grain(0, 5), 5); XCTAssertEqual(Data3.grain(1, 10), 5); XCTAssertEqual(Data3.grain(1, 5), 5)
        XCTAssertEqual(Data3.most(0, 2), 18); XCTAssertEqual(Data3.most(1, 10), 80)
        let pets = Data3.themes[2], cookies = Data3.themes[3], books = Data3.themes[0]
        XCTAssertEqual(pets.unit(0, 35), "dogs"); XCTAssertEqual(pets.unit(0, 1), "dog"); XCTAssertEqual(pets.unit(2, 1), "fish"); XCTAssertEqual(books.unit(1, 1), "book")
        XCTAssertEqual(cookies.ask("Mon"), "How many cookies on Monday?")
        XCTAssertEqual(cookies.more("Mon", "Tue"), "How many more cookies on Monday than on Tuesday?")
        XCTAssertEqual(cookies.fewer("Mon", "Tue"), "How many fewer cookies on Tuesday than on Monday?")
        XCTAssertEqual(cookies.two("Mon", "Tue", "Wed"), "How many fewer cookies on Wednesday than on Monday and Tuesday together?")
        XCTAssertEqual(books.two("Ana", "Ben", "Dev"), "How many fewer books did Dev read than Ana and Ben together?")
        XCTAssertEqual(Data3.themes[1].two("Apples", "Pears", "Kiwis"), "How many fewer votes for Kiwis than for Apples and Pears together?")
        XCTAssertEqual(pets.two("Dogs", "Cats", "Fish"), "How many fewer fish than dogs and cats together?")
    }

    func testPictureGraph() {
        var l = LessonRun(Graphs3.spec, numbers: Graphs3.numbers(type: 0, scale: 2, theme: 1, counts: [7, 4, 10, 5], ask: 0, x: 0, y: 1))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap the key.")
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("A picture can stand for more than 1. Tap the key to see how many."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Drag along the Apples row.")
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 1, 8))]), .notYet("That's the Pears row."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 8))]), .notYet("The last picture is only half. Count the whole ones."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 9))]), .notYet("That's past the end of the Apples row."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 5))]), .notYet("That's 2 pictures and a half. The Apples row goes on."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 7))]), .moved(2))
        XCTAssertEqual(l.words.say, "How many votes for Apples?")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Each picture is 2, so 3 pictures is 3 × 2."))
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("Don't forget the half picture: half of 2 is 1."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("Not quite. Each picture is 2."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(3))
        XCTAssertEqual(l.words.say, "Each apple is 2, half an apple is 1: 7 votes.")

        let t = LessonRun(Graphs3.spec, numbers: Graphs3.numbers(type: 0, scale: 5, theme: 0, counts: [20, 10, 35, 5], ask: 2, x: 2, y: 1))
        XCTAssertEqual(t.steps.count, 7)
        let P = Graphs3.Parts(t.numbers)
        XCTAssertEqual(P.sayOp, "How many for Cleo and Ben together?")
        XCTAssertEqual(P.why, "Together means add.")
        XCTAssertEqual(P.opSlips.map { $0.0 }, [25])
        XCTAssertEqual(Graphs3.Parts(Graphs3.numbers(type: 0, scale: 5, theme: 0, counts: [20, 10, 35, 5], ask: 0, x: 0, y: 1)).why, "Each star is 5: 20 books.")
    }

    func testBarGraph() {
        var l = LessonRun(Graphs3.spec, numbers: Graphs3.numbers(type: 1, scale: 10, theme: 2, counts: [35, 20, 50, 15], ask: 1, x: 0, y: 1))
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Tap the scale.")
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("Tap the numbers along the bottom to see what each line is."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Drag the line from the end of the Dogs bar to the scale.")
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.notDown)]), .notYet("Drag the line all the way down to the scale."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 1, 4))]), .notYet("That's the Cats bar."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 8))]), .notYet("That's 40. The Dogs bar stops before 40."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 6))]), .notYet("That's 30. The Dogs bar goes past 30."))
        XCTAssertEqual(move(&l, ["dx": Double(Graphs3.code(row: 0, 7))]), .moved(2))
        XCTAssertEqual(l.words.say, "How many dogs?")
        XCTAssertEqual(move(&l, ["x": 30]), .notYet("The bar ends halfway between 30 and 40. Halfway is 35."))
        XCTAssertEqual(move(&l, ["x": 20]), .notYet("That's the Cats bar."))
        XCTAssertEqual(move(&l, ["x": 33]), .notYet("Not quite. Follow the end of the Dogs bar down to the scale."))
        XCTAssertEqual(move(&l, ["x": 35]), .moved(3))
        XCTAssertEqual(l.words.say, "Drag the line from the end of the Cats bar to the scale.")
        XCTAssertEqual(move(&l, ["dy": Double(Graphs3.code(row: 1, 4))]), .moved(4))
        XCTAssertEqual(l.words.say, "How many cats?")
        XCTAssertEqual(move(&l, ["y": 2]), .notYet("Each line is 10, so count by 10s."))
        XCTAssertEqual(move(&l, ["y": 20]), .moved(5))
        XCTAssertEqual(l.words.say, "How many more for Dogs than Cats?")
        XCTAssertEqual(move(&l, ["op": 55]), .notYet("How many more means the difference. Subtract."))
        XCTAssertEqual(move(&l, ["op": 10]), .notYet("Not quite. Subtract the smaller from the bigger."))
        XCTAssertEqual(move(&l, ["op": 15]), .moved(6))
        XCTAssertEqual(l.words.say, "How many more means subtract.")
        let P = Graphs3.Parts(l.numbers)
        XCTAssertEqual(P.hs, 1); XCTAssertEqual(P.halves(0), 7); XCTAssertEqual(P.halves(1), 4)
        XCTAssertEqual(Graphs3.Parts(Graphs3.numbers(type: 1, scale: 5, theme: 2, counts: [35, 20, 10, 15], ask: 0, x: 0, y: 1)).why, "Each line is 5: the bar ends at 35.")
        XCTAssertEqual(Graphs3.Parts(Graphs3.numbers(type: 1, scale: 10, theme: 2, counts: [35, 20, 10, 15], ask: 0, x: 0, y: 1)).why, "Halfway between 30 and 40 is 35.")
        XCTAssertEqual(Graphs3.Parts(Graphs3.numbers(type: 1, scale: 5, theme: 2, counts: [35, 20, 10, 15], ask: 0, x: 0, y: 1)).hs, 2)

        for i in 0..<12 {
            each(Graphs3.spec, i) { x in
                let P = Graphs3.Parts(x), g = Data3.grain(P.type, P.s)
                XCTAssertEqual(Set(P.c).count, 4); XCTAssertNotEqual(P.x, P.y)
                XCTAssertTrue(P.c.allSatisfy { $0 % g == 0 && $0 <= Data3.most(P.type, P.s) && $0 >= g })
                if i < 3 { XCTAssertEqual(P.type, 0); XCTAssertTrue([2, 5].contains(P.s)); XCTAssertEqual(P.ask, 0) }
                else {
                    XCTAssertEqual(P.type, i % 2); XCTAssertEqual(P.ask, i % 3)
                    if P.type == 1 { XCTAssertEqual(P.s, Data3.scales[(i >> 1) % 3]) }
                }
                if P.ask == 1 { XCTAssertTrue(P.a > P.b) }
            }
        }
        let c = checks(Graphs3.spec).map(Graphs3.Parts.init)
        XCTAssertEqual(c.map { $0.type }, [0, 1, 1, 0]); XCTAssertEqual(c.map { $0.ask }, [1, 2, 1, 2])
        XCTAssertEqual(c[1].s, 10); XCTAssertEqual(c[2].s, 2); XCTAssertTrue(c[2].half(c[2].x) || c[2].half(c[2].y))
        XCTAssertEqual(c[3].s, 2); XCTAssertTrue(c[3].half(c[3].x))
    }

    func testDrawBars() {
        var l = LessonRun(DrawGraph3.spec, numbers: DrawGraph3.numbers(type: 1, scale: 10, theme: 2, counts: [35, 20, 50, 15], ask: 1, x: 0, y: 1))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Drag each bar to its number.")
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(0, 40))]), .notYet("That's 40. Dogs is 35. Back half a line."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(0, 30))]), .notYet("That's 30. Dogs is 35. On half a line."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(1, 30))]), .notYet("That's 30. Cats is 20. Back a line."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(2, 40))]), .notYet("That's 40. Fish is 50. On a line."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(0, 60))]), .notYet("That's 60. Dogs is 35. Each line is 10."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.dragCode(3, 150))]), .notYet("That's 150. Each line is 10, so 15 is 1 and a half lines."))
        XCTAssertEqual(move(&l, ["r": 100]), .moved(1))
        XCTAssertEqual(l.words.say, "How many more dogs than cats?")
        XCTAssertEqual(move(&l, ["op": 55]), .notYet("How many more means the difference. Subtract."))
        XCTAssertEqual(move(&l, ["op": 15]), .moved(2))
        XCTAssertEqual(l.words.say, "How many more means subtract.")
        let P = DrawGraph3.Parts(l.numbers)
        XCTAssertEqual(P.unit, 3); XCTAssertEqual(P.units(0), 7); XCTAssertEqual(P.value(7), 35); XCTAssertEqual(P.readout(0, 7), "35 dogs")
        XCTAssertEqual(P.why, "How many more means subtract.")
        let five = DrawGraph3.Parts(DrawGraph3.numbers(type: 1, scale: 5, theme: 2, counts: [35, 20, 10, 15], ask: 0, x: 0, y: 1))
        XCTAssertEqual(five.unit, 6); XCTAssertEqual(five.units(0), 7); XCTAssertEqual(five.value(7), 35)
        XCTAssertEqual(five.why, "Each line is 5, so 35 is 7 lines.")
        XCTAssertEqual(DrawGraph3.Parts(DrawGraph3.numbers(type: 1, scale: 10, theme: 2, counts: [30, 20, 50, 10], ask: 0, x: 0, y: 1)).why, "Each line is 10, so 30 is 3 lines.")
        XCTAssertEqual(DrawGraph3.Parts(DrawGraph3.numbers(type: 1, scale: 10, theme: 2, counts: [35, 20, 50, 10], ask: 0, x: 0, y: 1)).why, "Each line is 10, so 35 ends half a line past 30.")
        XCTAssertEqual(DrawGraph3.Parts(DrawGraph3.numbers(type: 1, scale: 2, theme: 2, counts: [7, 4, 10, 5], ask: 0, x: 0, y: 1)).readout(1, 4), "4 cats")

        let f = LessonRun(DrawGraph3.spec, numbers: DrawGraph3.numbers(type: 1, scale: 10, theme: 1, counts: [35, 20, 50, 15], ask: 1, x: 0, y: 1, fewer: true))
        XCTAssertEqual(f.steps[1].words.say, "How many fewer votes for Pears than Apples?")
        XCTAssertEqual(DrawGraph3.Parts(f.numbers).why, "How many fewer means subtract.")
        XCTAssertEqual(DrawGraph3.Parts(f.numbers).opSlips.first?.1, "How many fewer means the difference. Subtract.")
    }

    func testDrawPicturesAndTwoSteps() {
        var l = LessonRun(DrawGraph3.spec, numbers: DrawGraph3.numbers(type: 0, scale: 2, theme: 0, counts: [7, 4, 10, 5], ask: 0, x: 0, y: 1))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Tap to add pictures.")
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.tapCode(0, 8))]), .notYet("That's 8. Ana is 7. Tap the last one to make it a half."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.tapCode(0, 9))]), .notYet("That's 9. Ana is 7. Tap the last one to take it away."))
        XCTAssertEqual(move(&l, ["r": Double(DrawGraph3.tapCode(1, 6))]), .notYet("That's 6. Ben is 4. Tap the last one twice to take it away."))
        XCTAssertEqual(move(&l, ["r": 100]), .moved(1))
        XCTAssertEqual(l.words.say, "Each picture is 2, so 7 is 3 pictures and a half.")
        let P = DrawGraph3.Parts(l.numbers)
        XCTAssertEqual(P.unit, 2); XCTAssertEqual(P.units(0), 7); XCTAssertEqual(P.value(7), 7); XCTAssertEqual(P.readout(0, 9), "4 pictures and a half · 9")
        let five = DrawGraph3.Parts(DrawGraph3.numbers(type: 0, scale: 5, theme: 0, counts: [35, 20, 10, 15], ask: 0, x: 0, y: 1))
        XCTAssertEqual(five.rowMiss(DrawGraph3.tapCode(0, 40)), "That's 40. Ana is 35. Tap the last one to take it away.")
        XCTAssertEqual(five.readout(0, 14), "7 pictures · 35")

        var t = LessonRun(DrawGraph3.spec, numbers: DrawGraph3.numbers(type: 1, scale: 5, theme: 3, counts: [35, 20, 15, 40], ask: 2, x: 0, y: 1, z: 2))
        XCTAssertEqual(t.steps.count, 4)
        XCTAssertEqual(move(&t, ["r": 100]), .moved(1))
        XCTAssertEqual(t.words.say, "How many fewer cookies on Wednesday than on Monday and Tuesday together?")
        XCTAssertEqual(move(&t, ["sum": 15]), .notYet("Together means add."))
        XCTAssertEqual(move(&t, ["sum": 55]), .moved(2))
        XCTAssertEqual(t.words.say, "How many fewer cookies on Wednesday than on Monday and Tuesday together?")
        XCTAssertEqual(move(&t, ["diff": 70]), .notYet("How many fewer means the difference. Subtract."))
        XCTAssertEqual(move(&t, ["diff": 20]), .notYet("First put Mon and Tue together."))
        XCTAssertEqual(move(&t, ["diff": 41]), .notYet("Not quite. Subtract 15 from 55."))
        XCTAssertEqual(move(&t, ["diff": 40]), .moved(3))
        XCTAssertEqual(t.words.say, "Add the two, then subtract.")

        for i in 0..<12 {
            each(DrawGraph3.spec, i) { x in
                let P = DrawGraph3.Parts(x), g = Data3.grain(P.type, P.s)
                XCTAssertEqual(Set(P.c).count, 4); XCTAssertNotEqual(P.x, P.y)
                XCTAssertTrue(P.c.allSatisfy { $0 % g == 0 && $0 <= Data3.most(P.type, P.s) && $0 >= g })
                if i < 3 { XCTAssertEqual(P.type, 1); XCTAssertTrue([5, 10].contains(P.s)); XCTAssertEqual(P.ask, 0); XCTAssertTrue(P.c.allSatisfy { $0 % P.s == 0 }) }
                if i == 3 { XCTAssertEqual(P.type, 1); XCTAssertEqual(P.s, 2); XCTAssertEqual(P.ask, 1); XCTAssertTrue(P.c.contains { $0 % 2 == 1 }) }
                if i == 4 { XCTAssertEqual(P.type, 0); XCTAssertEqual(P.ask, 0) }
                if i == 5 { XCTAssertEqual(P.type, 1); XCTAssertEqual(P.ask, 1); XCTAssertEqual(P.s, 10) }
                if i == 6 { XCTAssertEqual(P.type, 1); XCTAssertEqual(P.ask, 2); XCTAssertEqual(P.s, 2) }
                if i == 7 { XCTAssertEqual(P.type, 0); XCTAssertEqual(P.ask, 1) }
                if P.ask >= 1 { XCTAssertTrue(P.a > P.b) }
                if P.ask == 2 { XCTAssertTrue(P.cz < P.a + P.b); XCTAssertNotEqual(P.z, P.x); XCTAssertNotEqual(P.z, P.y) }
                if P.ask != 1 { XCTAssertFalse(P.fewer) }
            }
        }
        let c = checks(DrawGraph3.spec).map(DrawGraph3.Parts.init)
        XCTAssertEqual(c.map { $0.ask }, [1, 0, 1, 2]); XCTAssertEqual(c.map { $0.type }, [1, 0, 1, 1]); XCTAssertEqual(c[0].s, 2)
    }

    func testMeasure() {
        XCTAssertEqual(LinePlot3.said(4), "1"); XCTAssertEqual(LinePlot3.said(9), "2 1/4"); XCTAssertEqual(LinePlot3.said(10), "2 1/2")
        XCTAssertEqual(LinePlot3.said(11), "2 3/4"); XCTAssertEqual(LinePlot3.said(1), "1/4"); XCTAssertEqual(LinePlot3.said(2), "1/2")
        XCTAssertEqual(LinePlot3.inchWord(4), "inch"); XCTAssertEqual(LinePlot3.inchWord(10), "inches")
        XCTAssertEqual(LinePlot3.fraction(10).top, 1); XCTAssertEqual(LinePlot3.fraction(10).bottom, 2); XCTAssertEqual(LinePlot3.fraction(8).bottom, 1)
        var l = LessonRun(LinePlot3.spec, numbers: LinePlot3.measure(whole: 2, quarters: 3, to: 4))
        XCTAssertEqual(l.steps.count, 4)
        let P = LinePlot3.Parts(l.numbers)
        XCTAssertEqual(P.fourths, 11); XCTAssertEqual(P.inches, 4); XCTAssertEqual(P.extra, 3); XCTAssertEqual(P.hopRoom, 8)
        XCTAssertEqual(l.words.say, "Tap the last whole inch it passes.")
        XCTAssertEqual(move(&l, ["i": 3]), .notYet("It hasn't reached 3 yet."))
        XCTAssertEqual(move(&l, ["i": 1]), .notYet("It passes 1, and 2 too."))
        XCTAssertEqual(move(&l, ["i": 2]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop the fourths to its end.")
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("That's past the end."))
        XCTAssertEqual(move(&l, ["h": 2]), .notYet("Hop all the way to its end."))
        XCTAssertEqual(move(&l, ["h": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how long it is.")
        XCTAssertEqual(move(&l, ["w": 2, "n": 3, "d": 2]), .notYet("The pieces are fourths, so the bottom number is 4."))
        XCTAssertEqual(move(&l, ["w": 3, "n": 3, "d": 4]), .notYet("Not quite. Whole inches go in front. Bottom: pieces in one inch. Top: pieces past the whole inches."))
        XCTAssertEqual(move(&l, ["w": 2, "n": 3, "d": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "2 whole inches and 3 fourths more.")

        var h = LessonRun(LinePlot3.spec, numbers: LinePlot3.measure(whole: 1, quarters: 2, to: 2))
        let Q = LinePlot3.Parts(h.numbers)
        XCTAssertEqual(Q.extra, 1); XCTAssertEqual(Q.inches, 4); XCTAssertEqual(Q.hopRoom, 6)
        XCTAssertEqual(move(&h, ["i": 1]), .moved(1))
        XCTAssertEqual(h.words.say, "Hop the halves to its end.")
        XCTAssertEqual(move(&h, ["h": 1]), .moved(2))
        XCTAssertEqual(move(&h, ["w": 1, "n": 1, "d": 4]), .notYet("The pieces are halves, so the bottom number is 2."))
        XCTAssertEqual(move(&h, ["w": 1, "n": 1, "d": 2]), .moved(3))
        XCTAssertEqual(h.words.say, "1 whole inch and 1 half more.")
        XCTAssertEqual(LinePlot3.Parts(LinePlot3.measure(whole: 5, quarters: 1, to: 4)).inches, 6)
    }

    func testPlot() {
        var l = LessonRun(LinePlot3.spec, numbers: LinePlot3.plot(thing: 2, lo: 4, data: [9, 10, 10, 11, 9, 12, 10, 8], ask: 0, v: 10))
        XCTAssertEqual(l.steps.count, 4)
        let P = LinePlot3.Parts(l.numbers)
        XCTAssertEqual(P.n, 3); XCTAssertEqual(P.mode, 10); XCTAssertEqual(P.stackMax, 3); XCTAssertEqual(P.toPlace, 3)
        XCTAssertEqual(l.words.say, "Tap where its X goes.")
        XCTAssertEqual(move(&l, ["p": 8]), .notYet("That's 2. Its end is at 2 1/4."))
        XCTAssertEqual(move(&l, ["p": 112]), .notYet("That's 3. Its end is at 2 1/2."))
        XCTAssertEqual(move(&l, ["p": 999]), .moved(1))
        XCTAssertEqual(l.words.say, "How many crayons are 2 1/2 inches? Tap the stack.")
        XCTAssertEqual(move(&l, ["t": 9]), .notYet("That's the stack at 2 1/4. Find 2 1/2 on the line."))
        XCTAssertEqual(move(&l, ["t": 13]), .notYet("There's no X at 3 1/4. Find 2 1/2 on the line."))
        XCTAssertEqual(move(&l, ["t": 10]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many crayons.")
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("That's the stack at 2 1/4. Each space is one fourth: count the marks from 2."))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That's the stack at 2 3/4. Each space is one fourth: count the marks from 2."))
        XCTAssertEqual(move(&l, ["c": 8]), .notYet("That's all the X's on the plot. Count only the stack above 2 1/2."))
        XCTAssertEqual(move(&l, ["c": 4]), .notYet("One too many. Touch each X above 2 1/2 once."))
        XCTAssertEqual(move(&l, ["c": 6]), .notYet("Not quite. Find 2 1/2 on the line, then count the X's above it."))
        XCTAssertEqual(move(&l, ["c": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Each X is one crayon.")

        var m = LessonRun(LinePlot3.spec, numbers: LinePlot3.plot(thing: 0, lo: 8, data: [9, 10, 10, 11, 9, 12, 10, 8, 16], ask: 1, v: 10))
        XCTAssertEqual(m.steps.count, 3)
        XCTAssertEqual(move(&m, ["p": 999]), .moved(1))
        XCTAssertEqual(m.words.say, "Which length came up most? Tap its stack.")
        XCTAssertEqual(move(&m, ["m": 9]), .notYet("That stack has 2 X's. Find the tallest stack."))
        XCTAssertEqual(move(&m, ["m": 12]), .notYet("That stack has 1 X. Find the tallest stack."))
        XCTAssertEqual(move(&m, ["m": 10]), .moved(2))
        XCTAssertEqual(m.words.say, "Each X is one shell: the tallest stack came up most.")
        XCTAssertEqual(LinePlot3.Parts(m.numbers).data.count, 9)

        for i in 0..<12 {
            each(LinePlot3.spec, i) { x in
                let P = LinePlot3.Parts(x)
                if i < 2 { XCTAssertTrue(P.measure); XCTAssertEqual(P.to, 2); XCTAssertEqual(P.quarters, 2) }
                else if i % 2 == 0 { XCTAssertTrue(P.measure); if P.to == 4 { XCTAssertTrue([1, 3].contains(P.quarters)) } else { XCTAssertEqual(P.quarters, 2) } }
                else {
                    XCTAssertFalse(P.measure); XCTAssertTrue([4, 8].contains(P.lo)); XCTAssertTrue(P.data.count >= 8 && P.data.count <= 12)
                    XCTAssertTrue(P.data.allSatisfy { $0 >= P.lo && $0 <= P.lo + 8 }); XCTAssertEqual(LinePlot3.modes(P.data).count, 1)
                    XCTAssertTrue(P.data.contains(P.v)); XCTAssertEqual(P.ask, (i >> 1) % 2)
                }
                if P.measure { XCTAssertTrue(P.whole >= 1 && P.whole <= 5) }
            }
        }
        let c = checks(LinePlot3.spec).map(LinePlot3.Parts.init)
        XCTAssertEqual(c.map { $0.measure }, [true, true, false, false]); XCTAssertEqual(c[0].to, 2); XCTAssertEqual(c[1].to, 4)
        XCTAssertEqual(c[2].ask, 1); XCTAssertEqual(c[3].ask, 0)
    }
}
