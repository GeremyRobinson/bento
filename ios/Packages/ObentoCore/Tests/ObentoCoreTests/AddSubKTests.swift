import XCTest
@testable import ObentoCore

/// Kindergarten, chapter 4: Add and take away (design/gradeK.md, the preview design/prototype/gradeK-ch4.html).
final class AddSubKTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
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
        let ch = Curriculum.chapters(0)[3]
        XCTAssertEqual(ch.title, "Add and take away")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Lessons.spec("k-make10")?.depends, ["k-bonds"])
        XCTAssertEqual(Lessons.spec("gk-five")?.depends, ["k-add", "k-sub"])
    }

    // MARK: Adding within 10

    func testAdd() {
        // the preview's How to: 3 + 4
        var l = LessonRun(AddK.spec, numbers: AddK.numbers(a: 3, b: 4))
        XCTAssertEqual(l.words.say, "Slide them on.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["l": 2]), .notYet("Put them right after the 3."))
        XCTAssertEqual(move(&l, ["l": -1]), .notYet("Put them right after the 3."))
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Count on.")
        XCTAssertEqual(move(&l, ["n": -1]), .notYet("Start after the 3: tap the striped cubes."))
        XCTAssertEqual(move(&l, ["n": -2]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["n": -3]), .notYet("Count them in order, from the 3."))
        XCTAssertEqual(move(&l, ["n": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many in all.")
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("One too many. Start after 3: say 4 for the first new cube."))
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("One short. Count every new cube once."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That’s 2. Start at 3 and count on 4."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(3))
        XCTAssertEqual(l.words.say, "Start at 3 and count on, one number for each new cube.")
        XCTAssertTrue(l.isLast)
    }

    func testAddGenerator() {
        for i in 0..<3 { each(AddK.spec, i) { x in let P = AddK.Parts(x); XCTAssertTrue((1...3).contains(P.a) && (1...2).contains(P.b)) } }
        for i in 3..<10 { each(AddK.spec, i) { x in let P = AddK.Parts(x); XCTAssertTrue((1...5).contains(P.a) && (1...5).contains(P.b) && P.sum <= 10) } }
        let c = checks(AddK.spec).map(AddK.Parts.init)
        XCTAssertGreaterThanOrEqual(c[0].b, 3); XCTAssertLessThan(c[1].a, c[1].b); XCTAssertGreaterThanOrEqual(c[2].sum, 7)
        // a sum of 10: one too many isn't on the row, so it isn't named
        XCTAssertEqual(AddK.Parts(AddK.numbers(a: 5, b: 5)).wrote(9), "One short. Count every new cube once.")
    }

    // MARK: Taking away within 10

    func testSub() {
        var l = LessonRun(TakeAwayK.spec, numbers: TakeAwayK.numbers(a: 7, b: 3))
        XCTAssertEqual(l.words.say, "Take 3 away.")
        XCTAssertEqual(move(&l, ["t": 4]), .notYet("That’s 4 away. Take 3."))
        XCTAssertEqual(move(&l, ["t": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Count what's left.")
        XCTAssertEqual(move(&l, ["n": -1]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["n": -2]), .notYet("That one is taken away."))
        XCTAssertEqual(move(&l, ["n": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many are left.")
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("That’s 7 and 3 put together. Taking away leaves fewer than 7."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("3 is how many you took away. Count the cubes still on the track."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That’s how many you started with."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("One too many. Skip the crossed-out cubes when you count."))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("That’s 1. Count the cubes still on the track."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "Taking away leaves fewer: count only what's still there.")
    }

    func testSubNoneLeft() {
        var l = LessonRun(TakeAwayK.spec, numbers: TakeAwayK.numbers(a: 5, b: 5))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(move(&l, ["t": 5]), .moved(1))
        XCTAssertEqual(l.words.say, "None left. Write how many are left.")
        // 5 is both what was taken and the start: what was taken is said first
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("5 is how many you took away. Count the cubes still on the track."))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("One too many. Skip the crossed-out cubes when you count."))
        XCTAssertEqual(move(&l, ["x": 0]), .moved(2))
    }

    func testSubGenerator() {
        for i in 0..<3 { each(TakeAwayK.spec, i) { x in let P = TakeAwayK.Parts(x); XCTAssertTrue((2...5).contains(P.a) && P.left >= 1) } }
        var none = 0
        for i in 3..<10 { each(TakeAwayK.spec, i) { x in let P = TakeAwayK.Parts(x); XCTAssertTrue((4...10).contains(P.a) && P.b >= 1); if P.left == 0 { none += 1 } } }
        XCTAssertGreaterThan(none, 0)
        let c = checks(TakeAwayK.spec).map(TakeAwayK.Parts.init)
        XCTAssertGreaterThanOrEqual(c[0].b, 4); XCTAssertTrue((1...2).contains(c[1].left)); XCTAssertEqual(c[2].left, 0)
    }

    // MARK: Story problems within 10

    func testStoryTake() {
        // the preview's How to: Mia has 5 apples and gives 2 away
        var l = LessonRun(StoryK.spec, numbers: StoryK.numbers(a: 5, b: 2, take: true, who: 0, what: 0, tale: 0))
        let P = StoryK.Parts(l.numbers)
        XCTAssertEqual(P.lines, ["Mia has 5 apples.", "Mia gives 2 away.", "How many apples are left?"])
        XCTAssertEqual(P.choices, ["More than 5", "Fewer than 5"])
        XCTAssertEqual(l.words.say, "Mia has 5 apples. Mia gives 2 away.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Some apples go away, so there will be fewer than 5."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Mia gives 2 away.")
        XCTAssertEqual(move(&l, ["t": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "How many apples are left?")
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Some go away, so the answer is fewer than 5. Take away 2."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That’s how many go away. Start at 5 and count back 2."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("5 is the start. Now count back 2."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("One too many. Count back exactly 2."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("That’s 9. Count the apples on the track."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Some go away, so take away.")
    }

    func testStoryAddAndTogether() {
        var l = LessonRun(StoryK.spec, numbers: StoryK.numbers(a: 4, b: 3, take: false, who: 4, what: 1, tale: 1))
        XCTAssertEqual(StoryK.Parts(l.numbers).lines, ["4 crayons are on the table.", "Zoe puts on 3 more.", "How many crayons now?"])
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("More crayons come, so there will be more than 4."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(1))
        XCTAssertEqual(move(&l, ["l": 1]), .notYet("Put them right after the 4."))
        XCTAssertEqual(move(&l, ["l": 0]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("More come, so the answer is more than 4. Add 3."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That’s how many come. Start at 4 and count on 3."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(3))
        XCTAssertEqual(l.words.say, "More come, so add.")

        var t = LessonRun(StoryK.spec, numbers: StoryK.numbers(a: 3, b: 2, take: false, who: 0, what: 0, tale: 2))
        XCTAssertEqual(StoryK.Parts(t.numbers).lines, ["Mia has 3 apples.", "Leo has 2 apples.", "How many apples in all?"])
        XCTAssertEqual(move(&t, ["c": 1]), .notYet("Leo’s apples join Mia’s, so there will be more than 3."))
        XCTAssertEqual(move(&t, ["c": 0]), .moved(1))
        XCTAssertEqual(move(&t, ["l": 0]), .moved(2))
        XCTAssertEqual(move(&t, ["x": 2]), .notYet("That’s how many Leo has. Start at 3 and count on 2."))
        XCTAssertEqual(move(&t, ["x": 3]), .notYet("3 is how many Mia has. Now count on 2."))
        XCTAssertEqual(move(&t, ["x": 1]), .notYet("Put together, the answer is more than 3. Add 2."))
        XCTAssertEqual(move(&t, ["x": 5]), .moved(3))
        XCTAssertEqual(t.words.say, "Put together, so add.")
        // one of a thing
        XCTAssertEqual(StoryK.Parts(StoryK.numbers(a: 1, b: 1, take: false, what: 5, tale: 2)).lines[1], "Leo has 1 cookie.")
    }

    func testStoryGenerator() {
        for i in 0..<3 { each(StoryK.spec, i) { x in let P = StoryK.Parts(x); XCTAssertTrue(P.a <= 6 && P.end <= 6 && P.b <= 3 && P.tale < 2) } }
        var together = 0, adding = 0
        for i in 3..<10 { each(StoryK.spec, i) { x in
            let P = StoryK.Parts(x)
            XCTAssertTrue((0...10).contains(P.end) && P.b >= 1)
            if P.take { XCTAssertGreaterThanOrEqual(P.end, 1) } else { adding += 1; if P.tale == 2 { together += 1 } }
        } }
        XCTAssertTrue(together > adding / 5 && together < adding / 2)
        let c = checks(StoryK.spec).map(StoryK.Parts.init)
        XCTAssertTrue(!c[0].take && c[0].tale == 2); XCTAssertTrue(c[1].take); XCTAssertTrue(c[2].take && c[2].b >= 3); XCTAssertTrue(!c[3].take && c[3].tale == 1)
    }

    // MARK: Number bonds

    func testBonds() {
        // the preview's How to: 5 is 2 and 3
        var l = LessonRun(BondsK.spec, numbers: BondsK.numbers(whole: 5, part: 2))
        XCTAssertEqual(l.words.say, "Cut after 2.")
        XCTAssertEqual(move(&l, ["k": 3]), .notYet("That’s 3. Cut after 2."))
        XCTAssertEqual(move(&l, ["k": 2]), .moved(1))
        XCTAssertEqual(l.words.say, "Write the other part.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That’s the first group again. Count the other group."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s the whole. The other group is smaller."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("The parts are smaller than the whole. Count only the other group."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s 4. Count only the striped cubes."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Find another way.")
        XCTAssertEqual(move(&l, ["k2": 2]), .notYet("That’s 2 and 3 again. Try another place."))
        XCTAssertEqual(move(&l, ["k2": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "Cut it anywhere: the two parts make 5 again.")
        // a part of 0: the cut goes on the start line
        var z = LessonRun(BondsK.spec, numbers: BondsK.numbers(whole: 6, part: 0))
        XCTAssertEqual(z.words.say, "Cut at the start.")
        XCTAssertEqual(move(&z, ["k": 1]), .notYet("That’s 1. Cut at the start."))
        XCTAssertEqual(move(&z, ["k": 0]), .moved(1))
        XCTAssertEqual(move(&z, ["x": 6]), .moved(2))
        XCTAssertEqual(move(&z, ["k2": 6]), .moved(3))
    }

    func testBondsGenerator() {
        for i in 0..<3 { each(BondsK.spec, i) { x in let P = BondsK.Parts(x); XCTAssertTrue((3...5).contains(P.whole) && (1..<P.whole).contains(P.part)) } }
        var zero = 0
        for i in 3..<10 { each(BondsK.spec, i) { x in
            let P = BondsK.Parts(x)
            XCTAssertTrue((4...10).contains(P.whole) && P.part < P.whole)
            if P.part == 0 { zero += 1; XCTAssertGreaterThanOrEqual(i, 6) }
        } }
        XCTAssertGreaterThan(zero, 0)
        let c = checks(BondsK.spec).map(BondsK.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].whole, 7); XCTAssertGreaterThanOrEqual(c[2].whole, 7); XCTAssertGreaterThan(c[3].part, c[3].rest)
    }

    // MARK: Make 10

    func testMakeTen() {
        var l = LessonRun(MakeTenK.spec, numbers: MakeTenK.numbers(have: 7))
        XCTAssertEqual(l.words.say, "Count the dots.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That box is empty. Count the dots."))
        XCTAssertEqual(move(&l, ["c": -2]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["c": 7]), .moved(1))
        XCTAssertEqual(l.words.say, "Fill the frame.")
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("That box has a dot."))
        XCTAssertEqual(move(&l, ["f": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many more.")
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("10 is the full frame. How many more dots does it need?"))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That’s the dots already there. Count the empty boxes."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Touch every empty box."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("Touch each empty box only once."))
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("That’s 0. Count the striped dots."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "The frame holds 10, so the empty boxes are how many more.")
    }

    func testMakeTenGenerator() {
        for i in 0..<3 { each(MakeTenK.spec, i) { x in XCTAssertTrue((6...9).contains(MakeTenK.Parts(x).have)) } }
        for i in 3..<10 { each(MakeTenK.spec, i) { x in XCTAssertTrue((1...9).contains(MakeTenK.Parts(x).have)) } }
        let c = checks(MakeTenK.spec).map(MakeTenK.Parts.init)
        XCTAssertLessThanOrEqual(c[0].have, 4); XCTAssertTrue((5...7).contains(c[1].have)); XCTAssertGreaterThanOrEqual(c[2].have, 8)
    }

    // MARK: Facts to 5

    func testFiveHand() {
        var l = LessonRun(FactsToFive.spec, numbers: FactsToFive.numbers(a: 3, b: 2, plus: true, mode: 0))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Raise 2.")
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("That finger is already up."))
        XCTAssertEqual(move(&l, ["f": 3]), .notYet("That’s 3 more. Raise 2."))
        XCTAssertEqual(move(&l, ["f": 2]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many are up.")
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("That’s 3 take away 2. + means more fingers go up."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("2 is how many went up. Count every finger that’s up."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That’s how many were up to start."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("Count the fingers that are up: one number for each."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Every finger is up: a whole hand, every time.")
        XCTAssertEqual(FactsToFive.Parts(l.numbers).moves, [3, 4])
    }

    func testFiveWriteFirst() {
        var l = LessonRun(FactsToFive.spec, numbers: FactsToFive.numbers(a: 4, b: 1, plus: false, mode: 1))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Write the answer.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 4 and 1 more. − means a finger folds down."))
        XCTAssertEqual(move(&l, ["x": 1]), .notYet("1 is how many folded. Count the fingers still up."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s how many were up to start."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Watch the hand. Fingers fold down, so take away: the same every time.")
        XCTAssertEqual(FactsToFive.Parts(l.numbers).moves, [3])
        let fold = FactsToFive.Parts(FactsToFive.numbers(a: 5, b: 2, plus: false))
        XCTAssertEqual(fold.tapSay, "Fold 2.")
        XCTAssertEqual(fold.tapped(3), "That’s 3 folded. Fold 2.")
        XCTAssertEqual(fold.wrote(7), "That’s 5 and 2 more. − means fingers fold down.")
        XCTAssertEqual(fold.wrote(4), "Count the fingers that are up: one number for each.")
        XCTAssertEqual(FactsToFive.Parts(FactsToFive.numbers(a: 2, b: 2, plus: true)).why, "Fingers go up, so add: the same every time.")
    }

    func testFiveGenerator() {
        for i in 0..<3 { each(FactsToFive.spec, i) { x in
            let P = FactsToFive.Parts(x)
            XCTAssertTrue(P.plus && P.a >= 1 && P.b >= 1 && P.c <= 4 && P.mode == 0)
        } }
        var minus = 0
        for i in 3..<6 { each(FactsToFive.spec, i) { x in
            let P = FactsToFive.Parts(x)
            XCTAssertTrue(P.a >= 1 && P.b >= 1 && P.c >= 1 && P.c <= 5 && P.mode == 1); if !P.plus { minus += 1 }
        } }
        XCTAssertGreaterThan(minus, 100)
        var zeros = 0
        each(FactsToFive.spec, 6, 600) { x in
            let P = FactsToFive.Parts(x)
            XCTAssertTrue((0...5).contains(P.c) && P.mode == 2); if P.a == 0 || P.b == 0 || P.c == 0 { zeros += 1 }
        }
        XCTAssertTrue(zeros > 30 && zeros < 300)
        let c = checks(FactsToFive.spec).map(FactsToFive.Parts.init)
        XCTAssertFalse(c[0].plus); XCTAssertEqual(c[1].c, 5); XCTAssertTrue(c[2].a == 0 || c[2].b == 0 || c[2].c == 0)
    }
}
