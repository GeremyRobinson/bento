import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 2: Numbers to 1000 (design/grade2.md, the preview design/prototype/grade2-ch2.html).
final class Numbers2Tests: XCTestCase {
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
        let ch = Curriculum.chapters(2)[1]
        XCTAssertEqual(ch.title, "Numbers to 1000"); XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Spoken.text("Tap <, = or >."), "Tap less than, equals or greater than.")
        XCTAssertEqual(Num2.name(605), "six hundred five"); XCTAssertEqual(Num2.name(462), "four hundred sixty-two")
        XCTAssertEqual(Num2.name(714), "seven hundred fourteen"); XCTAssertEqual(Num2.name(830), "eight hundred thirty")
    }

    func testHundreds() {
        var l = LessonRun(Hundreds2.spec, numbers: Hundreds2.numbers(n: 347))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Put in the hundreds.")
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("That's 400. The 3 means 3 hundreds."))
        XCTAssertEqual(move(&l, ["h": -1]), .notYet("Start with the hundreds."))
        XCTAssertEqual(move(&l, ["h": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Now the tens.")
        XCTAssertEqual(move(&l, ["t": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["o": 6]), .notYet("That's 6. The 7 means 7 ones."))
        XCTAssertEqual(move(&l, ["o": 7]), .moved(3))
        XCTAssertEqual(l.words.say, "Write what each part is worth.")
        XCTAssertEqual(move(&l, ["e0": 3, "e1": 4, "e2": 7]), .notYet("Each digit is worth its place. 3 hundreds is 300, and 4 tens is 40."))
        XCTAssertEqual(move(&l, ["e0": 300, "e1": 4, "e2": 7]), .notYet("The 4 is in the tens place, so it is worth 40."))
        XCTAssertEqual(move(&l, ["e0": 3, "e1": 40, "e2": 7]), .notYet("The 3 is in the hundreds place, so it is worth 300."))
        XCTAssertEqual(move(&l, ["e0": 300, "e1": 40, "e2": 7]), .moved(4))
        XCTAssertEqual(l.words.say, "Where a digit sits tells what it's worth.")

        // told in words: built, then written as a number
        let r = Hundreds2.Parts(Hundreds2.numbers(n: 605, named: 1))
        XCTAssertEqual(r.miss(1, 1), "That's 10. Six hundred five has 0 tens.")
        XCTAssertEqual(r.miss(0, 5), "That's 500. Six hundred means 6 hundreds.")
        var w = LessonRun(Hundreds2.spec, numbers: Hundreds2.numbers(n: 605, named: 1))
        XCTAssertEqual(w.steps.count, 5)
        for (b, v) in [("h", 6.0), ("t", 0), ("o", 5)] { _ = move(&w, [b: v]) }
        XCTAssertEqual(w.words.say, "Write the number.")
        XCTAssertEqual(move(&w, ["x": 650]), .notYet("Six hundred five is 6 hundreds, 0 tens and 5 ones."))
        XCTAssertEqual(move(&w, ["x": 605]), .moved(4))
        XCTAssertEqual(Hundreds2.Parts(Hundreds2.numbers(n: 914, named: 1)).miss(1, 4), "That's 40. Fourteen means 1 ten and 4 ones.")

        // its name with word blocks
        let P = Hundreds2.Parts(Hundreds2.numbers(n: 605, named: 2, mix: 3))
        XCTAssertEqual(Set(P.blocks), ["six", "hundred", "five", "sixty", "fifty"])
        let at = { (w: String) in P.blocks.firstIndex(of: w)! }
        XCTAssertEqual(P.word(-1 - at("five")), "Start with the hundreds: six hundred.")
        XCTAssertEqual(P.word(-1 - at("fifty") - 20), "Fifty is 5 tens. 605 has 0 tens.")
        XCTAssertEqual(P.word(-1 - at("six") - 20), "Six is 6 ones. 605 has 5 ones.")
        XCTAssertEqual(P.word(-1 - at("hundred") - 20), "Next comes five.")
        var n = LessonRun(Hundreds2.spec, numbers: Hundreds2.numbers(n: 605, named: 2, mix: 3))
        XCTAssertEqual(n.steps.count, 6)
        XCTAssertEqual(n.steps[4].words.say, "Write its name: tap the words.")
        XCTAssertEqual(Hundreds2.Parts(Hundreds2.numbers(n: 462, named: 2)).blocks.count, 6)
        XCTAssertEqual(Hundreds2.Parts(Hundreds2.numbers(n: 462, named: 2)).word(-1 - Hundreds2.Parts(Hundreds2.numbers(n: 462, named: 2)).blocks.firstIndex(of: "forty")! - 20), "Forty is 4 tens. 462 has 6 tens.")
        _ = move(&n, ["h": 6])

        for i in 0..<14 {
            each(Hundreds2.spec, i) { x in
                let P = Hundreds2.Parts(x)
                XCTAssertTrue((100...999).contains(P.n))
                if i < 3 { XCTAssertFalse(P.D.contains(0)) }
                if i >= 5 && i % 6 == 5 { XCTAssertEqual(P.n % 100, 0) }
                XCTAssertEqual(P.named, i >= 4 && (i - 4) % 3 == 0 ? ((i - 4) % 6 == 0 ? 1 : 2) : 0)
                if P.named == 2 { XCTAssertTrue(Set(P.need).isSubset(of: Set(P.blocks))); XCTAssertLessThanOrEqual(P.blocks.count, P.need.count + 2) }
            }
        }
        let c = checks(Hundreds2.spec).map(Hundreds2.Parts.init)
        XCTAssertEqual(c[1].D[1], 0); XCTAssertEqual(c[2].D[2], 0)
    }

    func testSkip() {
        var l = LessonRun(Skip2.spec, numbers: Skip2.numbers(start: 15, by: 5))
        XCTAssertEqual(l.steps.count, 8)
        XCTAssertEqual(l.words.say, "Hop from 15 to 20.")
        XCTAssertEqual(move(&l, ["j": 3]), .notYet("That's 3. Go on to 20."))
        XCTAssertEqual(move(&l, ["j": 5]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop on. Write where you land.")
        XCTAssertEqual(move(&l, ["p3": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["b3": 26]), .notYet("Jump by 5, not by 1: 25 + 5."))
        XCTAssertEqual(move(&l, ["b3": 35]), .notYet("The jump is 5, not 10: 25 + 5."))
        XCTAssertEqual(move(&l, ["b3": 20]), .notYet("The numbers are getting bigger, so count up: 25 + 5."))
        XCTAssertEqual(move(&l, ["b3": 31]), .notYet("Add 5 to 25."))
        XCTAssertEqual(move(&l, ["b3": 30]), .moved(3))
        XCTAssertEqual(l.steps.last?.words.say, "Every hop is 5, so each number is 5 more.")

        let f = LessonRun(Skip2.spec, numbers: Skip2.numbers(start: 620, by: 10, back: true))
        XCTAssertEqual(f.steps[3].words.say, "10 tens make a hundred, so the hundreds digit changed too. Hop back. Write where you land.")
        XCTAssertEqual(f.steps[1].words.say, "Hop back. Write where you land.")
        let b = Skip2.Parts(Skip2.numbers(start: 640, by: 10, back: true))
        XCTAssertEqual(b.jump, "Hop back from 640 to 630.")
        XCTAssertEqual(b.slips(3).last?.1, "The numbers are getting smaller, so count back.")
        XCTAssertEqual(b.v(5), 590); XCTAssertTrue(b.crosses); XCTAssertEqual(b.why, Skip2.Parts.hundred)
        XCTAssertEqual(Skip2.Parts(Skip2.numbers(start: 230, by: 100)).why, "Every hop is 100, so only the hundreds digit changes.")
        XCTAssertEqual(Skip2.Parts(Skip2.numbers(start: 13, by: 10)).why, "Every hop is 10, so only the tens digit changes.")
        let one = Skip2.Parts(Skip2.numbers(start: 397, by: 1))
        XCTAssertEqual(one.units, 1); XCTAssertEqual(one.v(3), 400); XCTAssertTrue(one.crossed(3))

        for i in 0..<14 {
            each(Skip2.spec, i) { x in
                let P = Skip2.Parts(x)
                XCTAssertTrue((0...999).contains(P.v(0)) && (0...999).contains(P.v(5)))
                if i < 3 { XCTAssertTrue([2, 5, 10].contains(P.by)); XCTAssertEqual(P.start % P.by, 0) }
                if P.back || P.by == 1 { XCTAssertTrue(i >= 4 && (i - 4) % 3 == 0) }
            }
        }
        let c = checks(Skip2.spec).map(Skip2.Parts.init)
        XCTAssertEqual(c.map(\.by), [2, 5, 10, 100]); XCTAssertNotEqual(c[2].start % 10, 0)
    }

    func testCompare() {
        var l = LessonRun(Compare2.spec, numbers: Compare2.numbers(a: 427, b: 461))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap the hundred they're both in.")
        XCTAssertEqual(move(&l, ["s0": 5]), .notYet("They aren't between 500 and 600."))
        XCTAssertEqual(move(&l, ["s0": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the ten each one is in.")
        XCTAssertEqual(move(&l, ["p": -1 - 4]), .notYet("Neither number is between 440 and 450."))
        XCTAssertEqual(move(&l, ["p": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["g": 2]), .notYet("Look at the tens: 2 and 6. The open side faces the bigger one."))
        XCTAssertEqual(move(&l, ["g": 1]), .notYet("Look at the tens: 2 and 6. They're not the same."))
        XCTAssertEqual(move(&l, ["g": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "Both have 4 hundreds. 6 tens are more than 2 tens.")

        let d = Compare2.Parts(Compare2.numbers(a: 538, b: 461))
        XCTAssertEqual(d.d, 0); XCTAssertEqual(d.splitSay, "Tap the hundred each one is in.")
        XCTAssertEqual(d.why, "5 hundreds are more than 4 hundreds, whatever the tens.")
        XCTAssertTrue(Compare2.Parts(Compare2.numbers(a: 389, b: 412)).trap)
        let e = Compare2.Parts(Compare2.numbers(a: 345, b: 345))
        XCTAssertEqual(e.stages, 3); XCTAssertEqual(e.sameSay(2), "Tap where they both are."); XCTAssertEqual(e.span(2, 4), "344")
        XCTAssertEqual(e.signMiss(0), "Same hundreds, tens and ones. They're equal.")
        XCTAssertEqual(LessonRun(Compare2.spec, numbers: Compare2.numbers(a: 345, b: 345)).steps.count, 5)
        XCTAssertEqual(Compare2.Parts(Compare2.numbers(a: 341, b: 345)).splitSay, "Tap where each one is.")

        for i in 0..<12 {
            each(Compare2.spec, i) { x in
                let P = Compare2.Parts(x)
                if i < 3 { XCTAssertEqual(P.d, 0) }
            }
        }
        let c = checks(Compare2.spec).map(Compare2.Parts.init)
        XCTAssertTrue(c[0].trap); XCTAssertGreaterThanOrEqual(c[1].d, 1); XCTAssertGreaterThanOrEqual(c[2].d, 2)
    }

    func testWithin() {
        var l = LessonRun(Within2.spec, numbers: Within2.numbers(a: 245, b: 132, sub: false))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Hop on 1 hundred.")
        XCTAssertEqual(move(&l, ["h0": 2]), .notYet("That's 2 hundreds. 132 has 1."))
        XCTAssertEqual(move(&l, ["h0": -1]), .notYet("Adding goes up."))
        XCTAssertEqual(move(&l, ["h0": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop on 3 tens.")
        XCTAssertEqual(move(&l, ["h1": 3]), .moved(2))
        XCTAssertEqual(move(&l, ["h2": 2]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 113]), .notYet("This is adding, so the answer is bigger."))
        XCTAssertEqual(move(&l, ["x": 376]), .notYet(Within2.Parts.plain))
        XCTAssertEqual(move(&l, ["x": 377]), .moved(4))
        XCTAssertEqual(l.words.say, "Hundreds, then tens, then ones: one place at a time.")

        let a = Within2.Parts(Within2.numbers(a: 268, b: 153, sub: false))
        XCTAssertEqual(a.untraded, 311); XCTAssertEqual(a.r, 421); XCTAssertTrue(a.crossedH)
        let s = Within2.Parts(Within2.numbers(a: 524, b: 136, sub: true))
        XCTAssertEqual(s.say(0), "Hop back 1 hundred."); XCTAssertEqual(s.r, 388); XCTAssertEqual(s.untraded, 412)
        XCTAssertEqual(s.miss(1, 3), "Taking away goes down.")

        for i in 0..<12 {
            each(Within2.spec, i) { x in
                let P = Within2.Parts(x), A = Num2.digits(P.a), B = Num2.digits(P.b)
                XCTAssertFalse(B.contains(0)); XCTAssertTrue((0...999).contains(P.r))
                let crosses = P.sub ? A[2] < B[2] || A[1] < B[1] : A[2] + B[2] >= 10 || A[1] + B[1] >= 10
                XCTAssertEqual(crosses, i >= 4)
                // the lines hold every hop
                XCTAssertTrue(P.base2 <= min(P.p1, P.p2) && max(P.p1, P.p2) <= P.base2 + 200)
                XCTAssertTrue(P.base3 <= min(P.p2, P.r) && max(P.p2, P.r) <= P.base3 + 20)
            }
        }
        let c = checks(Within2.spec).map(Within2.Parts.init)
        XCTAssertFalse(c[1].sub); XCTAssertTrue(c[2].sub)
    }
}
