import XCTest
@testable import ObentoCore

/// 6th grade, chapter 8: Data (design/grade6.md, the preview design/prototype/grade6-ch8.html).
final class DataG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(91 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 13)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[7]
        XCTAssertEqual(ch.title, "Data")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        // every 6th grade chapter is built: the grade's test can open once its chapter tests are passed
        XCTAssertTrue(Curriculum.chapters(6).allSatisfy(Curriculum.built))
        XCTAssertEqual(Curriculum.grade(of: "g6-boxplot"), 6)
        XCTAssertEqual(Curriculum.grade(of: Curriculum.gradeTest(6)), 6)
    }

    // MARK: Dot plots

    func testDotPlotSteps() {
        let data = [4, 2, 4, 3, 4, 6, 1, 4]
        var l = LessonRun(DotPlot6.spec, numbers: DotPlot6.numbers(q: 1, data: data, feat: .far, pick: true, po: 0))
        XCTAssertEqual(l.display, [.text("How many minutes do the kids in Mia’s class read a day?")])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Pick the question with many answers.")
        XCTAssertEqual(l.step.answer?.choices, ["How many minutes did Mia read today?", "How many minutes do the kids in Mia’s class read a day?"])
        l.choose(0); XCTAssertEqual(l.go(), .notYet("Everyone gives the same answer to that one."))
        l.choose(1); XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "Put each answer on the line. Tap its number on the line, or drag the card there.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["c": 1, "u": 3]), .notYet("That card says 2."))
        XCTAssertEqual(move(&l, ["c": -1, "u": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "Write how many answers.")
        XCTAssertEqual(typeAll(&l, [("n", "7")]), .notYet("One is missed: count every dot."))
        XCTAssertEqual(typeAll(&l, [("n", "4")]), .notYet("Count the dots: one dot is one answer."))
        XCTAssertEqual(typeAll(&l, [("n", "8")]), .moved(4))
        XCTAssertEqual(l.words.say, "Tap where most answers are.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That stack has 1. Find the tallest."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("No dots there. Find the tallest stack."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(5))
        XCTAssertEqual(l.words.say, "From least to most: drag a bracket from the least answer to the greatest.")
        XCTAssertEqual(move(&l, ["a": 2, "b": 6]), .notYet("The dot at 1 is left out."))
        XCTAssertEqual(move(&l, ["a": 0, "b": 6]), .notYet("No one answered 0."))
        XCTAssertEqual(move(&l, ["a": 6, "b": 1]), .moved(6))
        XCTAssertEqual(l.words.say, "Most read 4 minutes, and the answers spread from 1 to 6.")
        XCTAssertTrue(l.isLast)
    }

    func testDotPlotLeftOutStack() {
        let p = DotPlot6.Parts(DotPlot6.numbers(q: 0, data: [3, 3, 5, 5, 5, 6, 8, 8]))
        XCTAssertEqual(p.spread(5, 8), "The dots at 3 are left out.")
        XCTAssertEqual(p.spread(3, 9), "No one answered 9.")
        XCTAssertEqual(p.why, "Most are 5 years old, and the answers spread from 3 to 8.")
        // no pick after the first problems: the steps start with the stack
        let l = LessonRun(DotPlot6.spec, numbers: DotPlot6.numbers(q: 2, data: [3, 3, 5, 5, 5, 6, 8, 8]))
        XCTAssertEqual(l.steps[1].picture["at"], 2)
        XCTAssertEqual(l.steps.count, 6)
    }

    func testDotPlotGenerator() {
        for i in 0..<9 {
            each(DotPlot6.spec, i, 150) { x in
                let p = DotPlot6.Parts(x)
                XCTAssertEqual(p.pick, i < 3)
                XCTAssertTrue(i < 3 ? p.n == 8 : (10...15).contains(p.n))
                XCTAssertTrue(p.data.allSatisfy { (0...(i < 3 ? 6 : 10)).contains($0) })
                XCTAssertTrue((3...6).contains(p.tallest))
                XCTAssertEqual(p.counts.filter { $0 == p.tallest }.count, 1)
                if i < 3 { XCTAssertEqual(p.feat, [DotPlot6.Feature.cluster, .gap, .far][i]) }
            }
        }
        XCTAssertEqual(checks(DotPlot6.spec).map { DotPlot6.Parts($0).pick }, [true, false, false, false])
    }

    // MARK: Histograms

    func testHistogramSteps() {
        let data = [12, 25, 21, 33, 8, 27, 19, 24, 31, 15, 22, 44]
        var l = LessonRun(Histogram6.spec, numbers: Histogram6.numbers(q: 0, data: data, ask: .more, t: 30))
        XCTAssertEqual(Histogram6.Parts(l.numbers).counts, [1, 3, 5, 2, 1])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Put each answer in its stretch. Tap the stretch, or drag the card in.")
        XCTAssertEqual(move(&l, ["c": 3, "u": 2]), .notYet("33 goes in 30–39."))
        XCTAssertEqual(move(&l, ["c": -1, "u": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "How many read 30 minutes or more? Tap the stretches it asks for.")
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("40–49 is 30 or more too."))
        XCTAssertEqual(move(&l, ["x": 28]), .notYet("20–29 is less than 30."))
        XCTAssertEqual(move(&l, ["x": 24]), .moved(3))
        XCTAssertEqual(l.words.say, "How many read 30 minutes or more? Write how many.")
        XCTAssertEqual(l.step.answer?.prompt, [.num(2), .op("+"), .num(1), .op("="), .box("a"), .text("kids")])
        XCTAssertEqual(typeAll(&l, [("a", "2")]), .notYet("Count the heights, not the bars."))
        XCTAssertEqual(typeAll(&l, [("a", "4")]), .notYet("Add the heights: 2 + 1."))
        XCTAssertEqual(typeAll(&l, [("a", "3")]), .moved(4))
        XCTAssertEqual(l.words.say, "A histogram counts how many land in each equal stretch.")
    }

    func testHistogramAsks() {
        let data = [12, 25, 21, 33, 8, 27, 19, 24, 31, 15, 22, 44]
        let one = Histogram6.Parts(Histogram6.numbers(q: 2, data: data, ask: .one, s1: 1))
        XCTAssertEqual(one.askSay, "In how many games did they score 10 to 19 points? Tap the stretches it asks for.")
        XCTAssertEqual(one.lit(1 << 2), "The question asks for 10–19.")
        XCTAssertEqual(one.lit(0), "Tap the stretch it asks for.")
        XCTAssertEqual(one.written(1), "Read the bar’s height up the side.")
        let fewer = Histogram6.Parts(Histogram6.numbers(q: 1, data: data, ask: .fewer, t: 20))
        XCTAssertEqual(fewer.asked, "How many walk fewer than 20 minutes?")
        XCTAssertEqual(fewer.lit(1), "10–19 is fewer than 20 too.")
        XCTAssertEqual(fewer.lit(7), "20–29 is not fewer than 20.")
        XCTAssertEqual(fewer.answer, 4)
        let tall = Histogram6.Parts(Histogram6.numbers(q: 0, data: data, ask: .tallest))
        XCTAssertEqual(tall.asked, "How many kids are in the tallest stretch?")
        XCTAssertEqual(tall.lit(2), "10–19 has 3. Find the tallest.")
        XCTAssertNil(tall.lit(4))
        XCTAssertEqual(tall.answer, 5)
    }

    func testHistogramGenerator() {
        for i in 0..<8 {
            each(Histogram6.spec, i, 150) { x in
                let p = Histogram6.Parts(x)
                XCTAssertTrue((10...15).contains(p.n))
                XCTAssertTrue(p.data.allSatisfy { (0...49).contains($0) })
                XCTAssertLessThanOrEqual(p.tallest, 6)
                XCTAssertTrue(p.want.allSatisfy { p.counts[$0] > 0 })
                if i < 4 { XCTAssertEqual(p.ask, [Histogram6.Ask.one, .more, .fewer, .tallest][i]) }
            }
        }
    }

    // MARK: Find the mean

    func testMeanSteps() {
        var l = LessonRun(Mean6.spec, numbers: Mean6.numbers([3, 5, 7, 9]))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Level the bars. Drag squares from a tall bar onto a short one.")
        XCTAssertEqual(move(&l, ["m": -1]), .notYet("Too tall: put them on a short bar."))
        XCTAssertEqual(move(&l, ["m": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Write it down. Add them up and count them.")
        XCTAssertEqual(typeAll(&l, [("T", "15")]), .notYet("Add every number in the list, the last one too."))
        XCTAssertEqual(typeAll(&l, [("T", "20")]), .notYet("Add all the numbers."))
        XCTAssertEqual(typeAll(&l, [("T", "24")]), .moved(3))
        XCTAssertEqual(typeAll(&l, [("c", "24")]), .notYet("Count how many numbers there are, not what they add up to."))
        XCTAssertEqual(typeAll(&l, [("c", "3")]), .notYet("Count every number in the list."))
        XCTAssertEqual(typeAll(&l, [("c", "4")]), .moved(4))
        XCTAssertEqual(l.words.say, "Shared out equally, every bar is 6: the mean is 6.")
    }

    func testMeanGenerator() {
        for i in [0, 3, 8] {
            each(Mean6.spec, i) { x in
                let p = Mean6.Parts(x)
                XCTAssertTrue((4...6).contains(p.n))
                XCTAssertTrue(p.v.allSatisfy { (1...20).contains($0) })
                XCTAssertEqual(p.total % p.n, 0)
                XCTAssertGreaterThan(Set(p.v).count, 1)
            }
        }
        XCTAssertEqual(checks(Mean6.spec).prefix(3).map { Mean6.Parts($0).n }, [4, 5, 6])
    }

    // MARK: Mean absolute deviation

    func testMadSteps() {
        var l = LessonRun(Mad6.spec, numbers: Mad6.numbers([2, 4, 6, 8, 10, 6], l0: 8))
        let p = Mad6.Parts(l.numbers)
        XCTAssertEqual(p.mean, 6); XCTAssertEqual(p.d, [4, 2, 0, 2, 4, 0]); XCTAssertEqual(p.mad, 2)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Find where they balance. Drag the line.")
        XCTAssertEqual(move(&l, ["l": 8]), .notYet("2 above, 14 below: move it down."))
        XCTAssertEqual(move(&l, ["l": 4]), .notYet("14 above, 2 below: move it up."))
        XCTAssertEqual(move(&l, ["l": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap each bar to measure it from the line.")
        XCTAssertEqual(move(&l, ["t": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "Now share the distances out equally. Add them, then share them out.")
        XCTAssertEqual(typeAll(&l, [("T", "0")]), .notYet("4 below is 4 away."))
        XCTAssertEqual(typeAll(&l, [("T", "9")]), .notYet("Add every distance."))
        XCTAssertEqual(typeAll(&l, [("T", "12")]), .moved(4))
        XCTAssertEqual(typeAll(&l, [("A", "12")]), .notYet("Share 12 out equally: 12 ÷ 6."))
        XCTAssertEqual(typeAll(&l, [("A", "2")]), .moved(5))
    }

    func testMadGenerator() {
        for i in [0, 1, 2, 5, 9] {
            each(Mad6.spec, i, 200) { x in
                let p = Mad6.Parts(x)
                XCTAssertTrue(i < 3 ? (4...5).contains(p.n) : (4...8).contains(p.n))
                XCTAssertEqual(p.v.reduce(0, +) % p.n, 0)
                XCTAssertEqual(p.dTotal % p.n, 0)
                XCTAssertGreaterThan(p.dTotal, 0)
                XCTAssertNotEqual(p.l0, p.mean)
                XCTAssertTrue((1...p.tallest).contains(p.l0))
                if i < 3 { XCTAssertLessThanOrEqual((p.v.max() ?? 0) - (p.v.min() ?? 0), 8) }
            }
        }
    }

    func testMadWhole() {
        var l = LessonRun(Mad6.spec, numbers: Mad6.numbers([4, 6, 8, 6], l0: 9))
        _ = l.go(); _ = move(&l, ["l": 6]); _ = move(&l, ["t": 4])
        XCTAssertEqual(typeAll(&l, [("T", "4")]), .moved(4))
        XCTAssertEqual(typeAll(&l, [("A", "1")]), .moved(5))
        XCTAssertEqual(l.words.say, "On average each answer is 1 from the mean.")
    }

    // MARK: Find the median

    func testMedianOdd() {
        var l = LessonRun(Median6.spec, numbers: Median6.numbers([7, 2, 9, 4, 5, 13, 1]))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Put them in order. Drag a bar to its place.")
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Cross them off from both ends. Tap the shortest and the tallest left.")
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("Cross off the shortest and the tallest left."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Write the middle spot and the median.")
        XCTAssertEqual(typeAll(&l, [("s", "3.5")]), .notYet("Add 1 before halving: (7 + 1) ÷ 2."))
        XCTAssertEqual(typeAll(&l, [("s", "3")]), .notYet("The middle spot has as many before it as after."))
        XCTAssertEqual(typeAll(&l, [("s", "4")]), .moved(4))
        XCTAssertEqual(typeAll(&l, [("m", "4")]), .notYet("The median is the bar left standing."))
        XCTAssertEqual(typeAll(&l, [("m", "5")]), .moved(5))
        XCTAssertEqual(l.words.say, "Make the tallest taller. Drag its top up.")
        XCTAssertEqual(move(&l, ["g": 1]), .notYet("Drag it higher."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["g": 3]), .moved(6))
        XCTAssertEqual(l.words.say, "The middle stays when the tallest grows. The mean moves.")
    }

    func testMedianEven() {
        var l = LessonRun(Median6.spec, numbers: Median6.numbers([15, 3, 12, 20, 8, 27]))
        XCTAssertEqual(Median6.Parts(l.numbers).median, 13.5)
        _ = l.go(); _ = move(&l, ["s": 1]); _ = move(&l, ["x": 1])
        XCTAssertEqual(l.words.say, "Write the halfway between the middle two.")
        XCTAssertEqual(l.step.picture["at"], 4)
        XCTAssertEqual(typeAll(&l, [("m", "27")]), .notYet("Halve it: (12 + 15) ÷ 2."))
        XCTAssertEqual(typeAll(&l, [("m", "13")]), .notYet("Halfway between 12 and 15."))
        XCTAssertEqual(typeAll(&l, [("m", "13.5")]), .moved(4))
    }

    func testMedianGenerator() {
        for i in 0..<9 {
            each(Median6.spec, i, 150) { x in
                let p = Median6.Parts(x)
                XCTAssertTrue(i < 3 ? p.n == 5 : i < 6 ? [5, 7].contains(p.n) : [6, 8].contains(p.n))
                XCTAssertNotEqual(p.v, p.sorted)
                XCTAssertTrue(p.v.allSatisfy { (1...Median6.most).contains($0) })
            }
        }
        let c = checks(Median6.spec).map(Median6.Parts.init)
        XCTAssertEqual(c[1].n, 7); XCTAssertNotEqual(c[1].v[3], c[1].sorted[3])
        XCTAssertLessThan(Set(c[2].v).count, c[2].n)
        XCTAssertEqual(c[3].n % 2, 0)
    }

    // MARK: Box plots

    func testBoxPlotOdd() {
        let data = [4, 5, 6, 6, 7, 8, 9, 10, 11, 12, 14]
        var l = LessonRun(BoxPlot6.spec, numbers: BoxPlot6.numbers(q: 0, data: data.reversed()))
        let p = BoxPlot6.Parts(l.numbers)
        XCTAssertEqual(p.median, 8); XCTAssertEqual(p.q1, 6); XCTAssertEqual(p.q3, 11); XCTAssertEqual(p.iqr, 5)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Tap the middle answer. As many answers below it as above.")
        XCTAssertEqual(move(&l, ["k": 4]), .notYet("That one has 4 below and 6 above."))
        XCTAssertEqual(move(&l, ["k": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Now the middle of each half. Tap the middle of the lower half and of the upper half.")
        XCTAssertEqual(move(&l, ["k": 5]), .notYet("That’s the middle of them all. Find the middle of each half."))
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("That one has 0 below and 4 above in its half."))
        XCTAssertEqual(p.half(2).side, 0)
        XCTAssertEqual(p.half(3).side, 0)
        XCTAssertEqual(p.half(8).side, 1)
        XCTAssertEqual(move(&l, ["k": -1]), .moved(3))
        XCTAssertEqual(l.words.say, "The box goes from one middle to the other. Write how wide it is.")
        XCTAssertEqual(typeAll(&l, [("A", "10")]), .notYet("That’s from the least to the greatest. The box holds the middle half."))
        XCTAssertEqual(typeAll(&l, [("A", "4")]), .notYet("The box runs from 6 to 11."))
        XCTAssertEqual(typeAll(&l, [("A", "5")]), .moved(4))
        XCTAssertEqual(l.words.say, "The box holds the middle half of the answers: 5 wide.")
    }

    func testBoxPlotMedianInHalf() {
        // 11 answers: a half's middle counted with the middle answer in the half is a slip
        let p = BoxPlot6.Parts(BoxPlot6.numbers(q: 1, data: [2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 15]))
        XCTAssertEqual(p.q1, 5); XCTAssertEqual(p.q3, 12)
        XCTAssertEqual(p.half(3).miss, "Leave the middle answer out of both halves.")
        XCTAssertEqual(p.half(2).side, 0)
        XCTAssertEqual(p.half(7).miss, "Leave the middle answer out of both halves.")
        XCTAssertEqual(p.half(8).side, 1)
        XCTAssertEqual(p.half(9).miss, "That one has 3 below and 1 above in its half.")
        // 13 answers: each half has two middles, either one is right
        let e = BoxPlot6.Parts(BoxPlot6.numbers(q: 1, data: [2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 15, 16, 18]))
        XCTAssertEqual(e.q1, 5.5); XCTAssertEqual(e.half(2).side, 0); XCTAssertEqual(e.half(3).side, 0)
    }

    func testBoxPlotGenerator() {
        for i in 0..<9 {
            each(BoxPlot6.spec, i, 120) { x in
                let p = BoxPlot6.Parts(x)
                XCTAssertTrue(i < 3 ? [11, 15].contains(p.n) : (12...14).contains(p.n))
                XCTAssertTrue(p.data.allSatisfy { (0...20).contains($0) })
                XCTAssertLessThanOrEqual(p.counts.max() ?? 0, 4)
                XCTAssertNotEqual(p.q1, p.median); XCTAssertNotEqual(p.q3, p.median)
                if i == 4 { XCTAssertTrue(p.far) }
            }
        }
    }

    // Every problem's steps can be worked to the end with the answers the lesson expects.
    func testEveryLessonWorks() {
        for spec in [DotPlot6.spec, Histogram6.spec, Mean6.spec, Mad6.spec, Median6.spec, BoxPlot6.spec] {
            for i in 0..<9 {
                each(spec, i, 30) { x in
                    var l = LessonRun(spec, numbers: x)
                    var guard_ = 0
                    while !l.isLast && guard_ < 20 {
                        guard_ += 1
                        if let a = l.step.answer {
                            if a.choices != nil { l.choose(Int(a.expected["c"] ?? 0)) }
                            else { for (b, v) in a.expected { l.set(b, v) } }
                        }
                        let at = l.index
                        XCTAssertEqual(l.go(), .moved(at + 1), "\(spec.id) \(x)")
                    }
                    XCTAssertTrue(l.isLast)
                }
            }
        }
    }
}
