import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 3: Place value (design/grade3.md, the preview design/prototype/grade3-ch3.html).
final class Place3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(53 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[2]
        XCTAssertEqual(ch.title, "Place value")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testRoundToTen() {
        var l = LessonRun(Round3.spec, numbers: Round3.numbers(n: 347, to: 10))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Round 347 to the nearest ten. Tap the block it's in.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("347 is between 340 and 350."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Drag 347 to the end it's closer to.")
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("That end is 7 away. The other end is 3."))
        XCTAssertEqual(move(&l, ["x": 10]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the end it's closer to.")
        XCTAssertEqual(move(&l, ["R": 340]), .notYet("347 is past the halfway mark 345, so it is closer to 350."))
        XCTAssertEqual(move(&l, ["R": 360]), .notYet("Not quite. 347 is at or past halfway (345), so it rounds up."))
        XCTAssertEqual(move(&l, ["R": 350]), .moved(3))
        XCTAssertEqual(l.words.say, "3 to 350, 7 to 340. 350 is closer.")
        XCTAssertEqual(Round3.Parts(Round3.numbers(n: 347, to: 10)).rule, "7 is 5 or more: round up")
    }

    func testRoundToHundred() {
        var l = LessonRun(Round3.spec, numbers: Round3.numbers(n: 347, to: 100))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("That end is 53 away. The other end is 47."))
        XCTAssertEqual(move(&l, ["x": 0]), .moved(2))
        XCTAssertEqual(move(&l, ["R": 350]), .notYet("That's the nearest ten. Round to the nearest hundred: 300 or 400."))
        XCTAssertEqual(move(&l, ["R": 400]), .notYet("347 is less than the halfway mark 350, so it is closer to 300."))
        XCTAssertEqual(move(&l, ["R": 300]), .moved(3))
        XCTAssertEqual(l.words.say, "47 to 300, 53 to 400. 300 is closer.")
        XCTAssertEqual(Round3.Parts(Round3.numbers(n: 347, to: 100)).rule, "4 is less than 5: round down")
        // exactly halfway
        var h = LessonRun(Round3.spec, numbers: Round3.numbers(n: 350, to: 100))
        XCTAssertEqual(move(&h, ["x": 3]), .moved(1))
        XCTAssertEqual(move(&h, ["x": 0]), .notYet("Exactly halfway rounds up."))
        XCTAssertEqual(move(&h, ["x": 10]), .moved(2))
        XCTAssertEqual(move(&h, ["R": 400]), .moved(3))
        XCTAssertEqual(h.words.say, "50 to 400, 50 to 300. Exactly halfway rounds up.")
    }

    func testRoundGenerator() {
        for i in 0..<8 {
            each(Round3.spec, i) { x in
                let P = Round3.Parts(x)
                if i < 3 { XCTAssertEqual(P.to, 10); XCTAssertTrue((11...99).contains(P.n)) } else { XCTAssertTrue((100...999).contains(P.n)) }
                XCTAssertNotEqual(P.n % P.to, 0)
                XCTAssertTrue((0...9).contains(P.block))
                XCTAssertLessThanOrEqual(abs(P.R - P.n), P.to / 2)
            }
        }
        let c = checks(Round3.spec).map(Round3.Parts.init)
        XCTAssertTrue(c[0].to == 10 && c[0].up); XCTAssertTrue(c[1].to == 100 && !c[1].up)
        XCTAssertTrue(c[2].to == 100 && c[2].up); XCTAssertTrue(c[3].half)
    }

    func testAdd() {
        var l = LessonRun(AddSub3.spec, numbers: AddSub3.numbers(a: 458, b: 275, s: 1))
        XCTAssertEqual(l.steps.count, 9)
        XCTAssertEqual(l.words.say, "Slide in the hundreds.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Slide in the hundreds first."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Hundreds go with hundreds."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 458 + 200.")
        XCTAssertEqual(move(&l, ["w0": 460]), .notYet("The 2 in 275 means 2 hundreds, so add 200."))
        XCTAssertEqual(move(&l, ["w0": 658]), .moved(2))
        XCTAssertEqual(l.words.say, "Slide in the tens.")
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap the full ten.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("10 tens make a hundred. Tap the full ten."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Write 658 + 70.")
        XCTAssertEqual(move(&l, ["w1": 665]), .notYet("The 7 in 275 means 7 tens, so add 70."))
        XCTAssertEqual(move(&l, ["w1": 588]), .notYet("This is adding, so the number gets bigger."))
        XCTAssertEqual(move(&l, ["w1": 628]), .notYet("5 tens + 7 tens is 12 tens. That makes a new hundred, so the next place goes up by 1."))
        XCTAssertEqual(move(&l, ["w1": 700]), .notYet("Not quite. Count on 7 tens from 658."))
        XCTAssertEqual(move(&l, ["w1": 728]), .moved(5))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(6))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(7))
        XCTAssertEqual(l.words.say, "Write 728 + 5.")
        XCTAssertEqual(move(&l, ["w2": 733]), .moved(8))
        XCTAssertEqual(l.words.say, "Ten of one place make one of the next.")
        // a cascade: the ones' ten closes, then the tens'
        let P = AddSub3.Parts(AddSub3.numbers(a: 431, b: 69, s: 1))
        XCTAssertEqual(P.plan.map(\.closes), [[], [2, 1]])
        XCTAssertEqual(AddSub3.Parts(AddSub3.numbers(a: 123, b: 45, s: 1)).why, "Hundreds, tens and ones, each on its own.")
    }

    func testTakeAway() {
        var l = LessonRun(AddSub3.spec, numbers: AddSub3.numbers(a: 503, b: 7, s: -1, story: true))
        XCTAssertEqual(l.words.say, "A farm has 503 apples. It sells 7 of them. How many apples are left? Pick what to do.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("It sells some, so there are fewer. Take away."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Slide the ones up to take them away.")
        let P = AddSub3.Parts(l.numbers)
        XCTAssertEqual(P.plan[0].opens, [0, 1])
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("There are only 3 ones and no tens. Open a hundred."))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("Open a ten."))
        XCTAssertEqual(move(&l, ["x": 14]), .notYet("There are only 3 ones. Open a ten."))
        XCTAssertEqual(P.slideSay(0, need: true, opened: 1), "Open a ten: tap one.")
        XCTAssertEqual(P.counts(0, opened: 2), [4, 9, 13])
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Write 503 − 7.")
        XCTAssertEqual(move(&l, ["w0": 510]), .notYet("This is taking away, so the number gets smaller."))
        XCTAssertEqual(move(&l, ["w0": 504]), .notYet("There are only 3 ones in 503, fewer than 7. So taking away 7 goes past 500. Taking 3 from 7 goes the wrong way."))
        XCTAssertEqual(move(&l, ["w0": 506]), .notYet("When you trade 1 ten for 10 ones, the next place goes down by 1."))
        XCTAssertEqual(move(&l, ["w0": 496]), .moved(3))
        XCTAssertEqual(l.words.say, "Ten of one place make one of the next.")
    }

    func testAddSubGenerator() {
        for i in 0..<8 {
            each(AddSub3.spec, i) { x in
                let P = AddSub3.Parts(x)
                XCTAssertTrue((1...999).contains(P.R)); XCTAssertTrue((100...999).contains(P.a))
                if i < 3 { XCTAssertTrue((11...99).contains(P.b)) } else { XCTAssertTrue((111...699).contains(P.b)) }
                XCTAssertFalse(String(P.b).contains("0"))
                XCTAssertEqual(P.story, i % 4 == 3)
                // the chart's counts after every jump are the answer's digits, and no column holds more than two frames
                if let last = P.plan.last, let j = P.jumps.last {
                    var n = P.counts(P.jumps.count - 1, opened: last.opens.count)
                    n[j.c] += P.s * j.d
                    var k = j.c
                    while k > 0 && n[k] >= 10 { n[k] -= 10; n[k - 1] += 1; k -= 1 }
                    XCTAssertEqual(n, [P.R / 100, P.R / 10 % 10, P.R % 10])
                }
                for (k, p) in P.plan.enumerated() { for c in 0..<3 { XCTAssertLessThanOrEqual(P.counts(k, opened: p.opens.count)[c] + (P.sub ? 0 : P.b / [100, 10, 1][c] % 10), 20) } }
            }
        }
        let c = checks(AddSub3.spec).map(AddSub3.Parts.init)
        XCTAssertTrue(!c[0].sub && c[0].regroups); XCTAssertTrue(c[1].sub && c[1].regroups); XCTAssertTrue(c[2].sub); XCTAssertTrue(c[3].story)
    }

    func testEstimate() {
        var l = LessonRun(Estimate3.spec, numbers: Estimate3.numbers(a: 458, b: 275, s: 1, f: 633, who: 0))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Leo says 458 + 275 = 633. Drag each number to its nearest hundred.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("458 is 42 from 500 and 58 from 400."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("275 is 25 from 300 and 75 from 200."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop 300 on from 500.")
        XCTAssertEqual(move(&l, ["k": 2]), .notYet("That's 200. Hop 300 on."))
        XCTAssertEqual(move(&l, ["k": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write 500 + 300.")
        XCTAssertEqual(move(&l, ["E": 200]), .notYet("This is adding, so the number gets bigger."))
        XCTAssertEqual(move(&l, ["E": 700]), .notYet("Not quite. Count on 3 hundreds from 500."))
        XCTAssertEqual(move(&l, ["E": 800]), .moved(3))
        XCTAssertEqual(l.words.say, "Leo says 458 + 275 = 633. Tap Yes or No: could Leo be right?")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("633 is 167 from 800. That's outside."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "About 800, so 633 can't be right.")
        let y = Estimate3.Parts(Estimate3.numbers(a: 458, b: 275, s: 1, f: 733, who: 1))
        XCTAssertTrue(y.yes); XCTAssertEqual(y.judged, "733 is only 67 from 800. It could be right.")
        XCTAssertEqual(Estimate3.Parts(Estimate3.numbers(a: 350, b: 120, s: -1, f: 230, who: 0)).far(350, low: true), "Exactly halfway rounds up.")
    }

    func testEstimateGenerator() {
        for i in 0..<8 {
            each(Estimate3.spec, i) { x in
                let P = Estimate3.Parts(x), r = P.a + P.s * P.b
                XCTAssertTrue((111...699).contains(P.b))
                XCTAssertLessThanOrEqual(abs(r - P.E), 100)
                if P.f != r { XCTAssertGreaterThanOrEqual(P.gap, i < 3 ? 300 : 150); XCTAssertFalse(P.yes) } else { XCTAssertTrue(P.yes) }
                XCTAssertTrue((0...1000).contains(P.E))
            }
        }
        let c = checks(Estimate3.spec).map(Estimate3.Parts.init)
        XCTAssertTrue(c[0].yes); XCTAssertFalse(c[1].yes); XCTAssertEqual(c[2].s, -1); XCTAssertTrue(c[3].s == -1 && !c[3].yes)
    }
}
