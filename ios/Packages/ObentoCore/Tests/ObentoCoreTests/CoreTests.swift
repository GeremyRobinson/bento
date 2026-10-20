import XCTest
@testable import ObentoCore

final class PaperCameraTests: XCTestCase {
    let screen = Size(1180, 820)

    func testZoomKeepsThePointUnderTheFingers() {
        let cam = PaperCamera(x: 30, y: -40, zoom: 1)
        let at = Point(400, 300), before = cam.toPaper(at)
        let after = cam.zoomed(by: 1.7, at: at).toPaper(at)
        XCTAssertEqual(before.x, after.x, accuracy: 1e-9)
        XCTAssertEqual(before.y, after.y, accuracy: 1e-9)
    }

    func testZoomStaysInRange() {
        XCTAssertEqual(PaperCamera().zoomed(by: 100, at: Point(0, 0)).zoom, Paper.maxZoom)
        XCTAssertEqual(PaperCamera().zoomed(by: 0.001, at: Point(0, 0)).zoom, Paper.minZoom)
    }

    func testFramingCentresTheRect() {
        let r = Rect(x: 200, y: 100, width: 400, height: 300)
        let cam = PaperCamera.framing(r, in: screen)
        let c = cam.toScreen(r.mid)
        XCTAssertEqual(c.x, screen.width / 2, accuracy: 1e-9)
        XCTAssertEqual(c.y, screen.height / 2, accuracy: 1e-9)
    }

    func testFlightEndsExactlyOnTarget() {
        let a = PaperCamera(x: 0, y: 0, zoom: 0.5), b = PaperCamera(x: -300, y: 120, zoom: 1.3)
        XCTAssertEqual(PaperCamera.between(a, b, 0, screen: screen), a)
        let end = PaperCamera.between(a, b, 1, screen: screen)
        XCTAssertEqual(end.x, b.x, accuracy: 1e-9); XCTAssertEqual(end.y, b.y, accuracy: 1e-9); XCTAssertEqual(end.zoom, b.zoom, accuracy: 1e-12)
    }
}

final class PaperView3DTests: XCTestCase {
    let screen = Size(1180, 820)

    /// Straight above, a paper point lands where the flat camera puts it, so switching to 3D moves nothing.
    func testFlatViewMatchesThePaper() {
        let cam = PaperCamera(x: 137, y: -64, zoom: 1.25)
        let v = PaperView3D.matching(cam, screen: screen)
        for p in [Point(0, 0), Point(300, 200), Point(-140, 560)] {
            let flat = cam.toScreen(p), deep = v.project(Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: screen)
            XCTAssertEqual(flat.x, deep.x, accuracy: 0.5); XCTAssertEqual(flat.y, deep.y, accuracy: 0.5)
        }
    }

    func testHandBackIsTheSameCamera() {
        let cam = PaperCamera(x: 137, y: -64, zoom: 1.25)
        let back = PaperView3D.matching(cam, screen: screen).paperCamera(screen: screen)
        XCTAssertEqual(back.x, cam.x, accuracy: 0.5); XCTAssertEqual(back.y, cam.y, accuracy: 0.5); XCTAssertEqual(back.zoom, cam.zoom, accuracy: 1e-9)
    }

    /// A tap on the tilted paper finds the paper point under it.
    func testTapFindsThePaperPoint() {
        let v = PaperView3D(elevation: 52, azimuth: -28, scale: 90, target: Vec3(3, 1, 2))
        let p = Vec3(4.25, 0, 1.5)
        let hit = v.unproject(v.project(p, screen: screen), screen: screen)
        XCTAssertEqual(hit.x, p.x, accuracy: 1e-9); XCTAssertEqual(hit.y, 0, accuracy: 1e-9); XCTAssertEqual(hit.z, p.z, accuracy: 1e-9)
    }

    /// The paper point at the middle of the screen, which the grid is centred on, tilted or not.
    func testFloorTargetIsUnderTheScreenCentre() {
        let v = PaperView3D(elevation: 52, azimuth: -28, scale: 90, target: Vec3(3, 1.5, 2))
        let f = v.floorTarget, c = v.project(f, screen: screen)
        XCTAssertEqual(f.y, 0, accuracy: 1e-9)
        XCTAssertEqual(c.x, screen.width / 2, accuracy: 1e-6); XCTAssertEqual(c.y, screen.height / 2, accuracy: 1e-6)
    }
}

final class UnitCubesTests: XCTestCase {
    func run(_ l: Int, _ w: Int, _ h: Int) -> LessonRun { LessonRun(UnitCubes.spec, numbers: UnitCubes.Box(length: l, width: w, height: h).numbers) }

    func testWalkThroughTheLesson() {
        var l = run(4, 3, 2)
        XCTAssertEqual(l.words.hint, "It is 4 long, 3 wide and 2 tall.")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertTrue(l.tap(0))
        XCTAssertFalse(l.tap(12), "outside the box")
        XCTAssertEqual(l.go(), .notYet("Not yet. 11 squares are still empty."))
        XCTAssertEqual(l.picture, ["empty": 1], "a miss outlines the empty squares")
        XCTAssertEqual(l.showMe().count, 11)
        XCTAssertEqual(l.countLine, "12 of 12 squares")
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "One layer: 12 cubes.")
        XCTAssertEqual(l.step.camera, .tilted)
        XCTAssertEqual(l.picture["layers"], 1)
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.hint, "Volume = 4 × 3 × 2 = 24 cubes.")
        XCTAssertEqual(l.go(), .newProblem)
    }

    func testOneSquareLeftIsSingular() {
        var l = run(3, 2, 2); _ = l.go()
        for c in 0..<5 { l.tap(c) }
        XCTAssertEqual(l.go(), .notYet("Not yet. 1 square is still empty."))
    }

    func testTapTwiceUncovers() {
        var l = run(3, 2, 2); _ = l.go()
        l.tap(4); l.tap(4)
        XCTAssertTrue(l.marked.isEmpty)
    }

    func testTallBoxStacksEveryLayer() {
        var l = run(3, 2, 3); _ = l.go(); _ = l.showMe(); _ = l.go()
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "2 layers of 6 is 12.")
        XCTAssertEqual(l.go(), .moved(4))
        XCTAssertEqual(l.picture["layers"], 3)
        XCTAssertTrue(l.isLast)
    }

    /// Every generated box is a real, readable problem and the answer always matches the cubes.
    func testGeneratorAlwaysMakesAReadableBox() {
        var rng = SeededRandom(seed: 7)
        for _ in 0..<500 {
            let b = UnitCubes.Box(LessonRun.fresh(UnitCubes.spec, using: &rng).numbers)
            XCTAssertTrue((2...5).contains(b.length) && (2...4).contains(b.width) && (2...3).contains(b.height))
            XCTAssertGreaterThan(b.length, b.width)
            XCTAssertEqual(b.volume, b.length * b.width * b.height)
        }
    }
}

final class AddFractionsTests: XCTestCase {
    let quarterAndEighth = AddFractions.Problem(a: 4, p: 1, b: 8, q: 1)
    func run(_ s: AddFractions.Problem) -> LessonRun { LessonRun(AddFractions.spec, numbers: s.numbers) }

    func testWalkThroughTheLesson() {
        var l = run(quarterAndEighth)
        XCTAssertEqual(l.words.say, "A fourth and an eighth.")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.words.say, "Shade eighths to match 1/4.")
        l.tap(5)
        XCTAssertEqual(l.go(), .notYet("Not yet. Shade more."))
        XCTAssertEqual(l.picture["guide"], 1, "a miss shows where the fourth ends")
        XCTAssertEqual(l.step.look, "1/4 ends here")
        l.tap(6); l.tap(7)
        XCTAssertEqual(l.go(), .notYet("Too many. Stop where the blue ends."))
        l.tap(7)
        // two eighths cover the fourth, and they line up under it
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.marked(on: 1), [0, 1])
        XCTAssertNil(l.picture["guide"])
        XCTAssertFalse(l.tap(0), "shaded pieces stay put while adding")
        XCTAssertEqual(l.go(), .notYet("Shade 1 more first."))
        l.tap(2)
        XCTAssertEqual(l.countLine, "3 of 8 shaded")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "The answer is 3/8.")
        XCTAssertEqual(l.words.hint, "2/8 + 1/8 = 3/8")
        XCTAssertEqual(l.go(), .newProblem)
    }

    func testShowMeFillsTheRightPieces() {
        var l = run(.init(a: 3, p: 2, b: 6, q: 1))
        _ = l.go()
        l.tap(5)
        XCTAssertEqual(l.showMe(), [0, 1, 2, 3])
        XCTAssertEqual(l.marked, [0, 1, 2, 3], "the wrong piece is cleared")
        _ = l.go()
        XCTAssertEqual(l.showMe(), [4])
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "The answer is 5/6.")
        XCTAssertEqual(l.words.hint, "4/6 + 1/6 = 5/6")
    }

    /// Every problem fits on the grid and is in lowest terms, the answer too.
    func testEveryProblemIsFairAndOnTheGrid() {
        XCTAssertTrue(AddFractions.problems.contains(quarterAndEighth))
        XCTAssertGreaterThan(AddFractions.problems.count, 8)
        for s in AddFractions.problems {
            XCTAssertEqual(s.b % s.a, 0); XCTAssertEqual(s.wholeCells % s.b, 0)
            XCTAssertEqual(gcd(s.p, s.a), 1); XCTAssertEqual(gcd(s.q, s.b), 1); XCTAssertEqual(gcd(s.total, s.b), 1)
            XCTAssertLessThan(s.total, s.b)
        }
    }
}

final class ChoiceStepTests: XCTestCase {
    func testPickOneStep() {
        let spec = LessonSpec(id: "t", title: "t", master: "x", generate: { _, _ in [:] }) { _ in
            [LessonStep(StepWords(say: "More or fewer?", hint: "", action: "Check"),
                        answer: AnswerTask(prompt: [.num(3), .text("feet is")], expected: ["c": 0],
                                           known: [(["c": 1], "Inches are smaller, so it takes more of them.")], hint: "", choices: ["More", "Fewer"])),
             LessonStep(StepWords(say: "", hint: "", action: "Next"))]
        }
        var l = LessonRun(spec, numbers: [:])
        XCTAssertEqual(l.step.answer?.boxes, ["c"])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        l.choose(1)
        XCTAssertEqual(l.go(), .notYet("Inches are smaller, so it takes more of them."))
        l.choose(0)
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.steps[0].answer?.work, [.num(3), .text("feet is"), .text("More")])
    }
}

final class PaperWayTests: XCTestCase {
    func testBeatsOfALesson() {
        var l = LessonRun(UnitCubes.spec, numbers: UnitCubes.Box(length: 4, width: 3, height: 2).numbers)
        XCTAssertEqual(l.beat, .ask); _ = l.go()
        XCTAssertEqual(l.beat, .do); _ = l.showMe(); _ = l.go()
        XCTAssertEqual(l.beat, .see); _ = l.go()
        XCTAssertEqual(l.beat, .say)
    }

    func testHintsBuildUpWithMisses() {
        var l = LessonRun(AddFractions.spec, numbers: AddFractions.Problem(a: 4, p: 1, b: 8, q: 1).numbers); _ = l.go()
        _ = l.go(); XCTAssertEqual(l.hintLevel, 1); XCTAssertEqual(l.picture["guide"], 1)
        _ = l.go(); XCTAssertEqual(l.hintLevel, 2)
        _ = l.go(); XCTAssertEqual(l.picture["showMe"], 1)
        l.helps = false
        XCTAssertEqual(l.hintLevel, 0); XCTAssertNil(l.picture["guide"])
    }

    func testOneTryShowsTheAnswerAndCountsTheMiss() {
        var l = LessonRun(AddFractions.spec, numbers: AddFractions.Problem(a: 4, p: 1, b: 8, q: 1).numbers); _ = l.go()
        l.oneTry = true; l.tap(5)
        XCTAssertEqual(l.go(), .notYet("Not yet. Shade more."))
        XCTAssertEqual(l.marked, [0, 1], "the right pieces are shown")
        XCTAssertTrue(l.missedAny)
        XCTAssertEqual(l.go(), .moved(2))
    }

    func testSessionPracticeThenCheck() {
        var s = LessonSession()
        XCTAssertNil(s.label)
        XCTAssertEqual(s.finished(worked(right: true)), .practice(1))
        XCTAssertEqual(s.label, "Practice 1 of 6")
        for _ in 1..<6 { s.finished(worked(right: false)) }
        XCTAssertEqual(s.finished(worked(right: true)), .check(1, right: 0))
        XCTAssertFalse(s.helps); XCTAssertTrue(s.oneTry)
        s.finished(worked(right: true)); s.finished(worked(right: false)); s.finished(worked(right: true))
        XCTAssertEqual(s.finished(worked(right: true)), .done(learned: true))
        var t = LessonSession(phase: .check(1, right: 0))
        for _ in 0..<3 { t.finished(worked(right: false)) }
        XCTAssertEqual(t.finished(worked(right: true)), .done(learned: false))
        XCTAssertEqual(t.finished(worked(right: true)), .practice(1), "not learned: back to practice")
    }
}

/// A Unit cubes problem worked to the end: right, or with a miss on covering the floor first.
func worked(right: Bool) -> LessonRun {
    var l = LessonRun(UnitCubes.spec, numbers: UnitCubes.Box(length: 2, width: 2, height: 1).numbers)
    while !l.isLast {
        if l.step.task != nil {
            if !right && l.missedSteps.isEmpty { _ = l.go() }
            _ = l.showMe()
        }
        _ = l.go()
    }
    return l
}

final class StoryStepTests: XCTestCase {
    func testAStoryProblemAsksForTheOperationFirst() {
        var l = LessonRun(AddingFractions.spec, numbers: AddingFractions.spec.generate(&rngForTests, 1), story: true)
        XCTAssertEqual(l.words.hint, "Pick what to do.")
        XCTAssertTrue(l.words.say.hasPrefix("You walked"))
        XCTAssertEqual(l.step.answer?.choices, ["+ Add", "− Subtract", "× Multiply", "÷ Divide"])
        l.choose(2)
        XCTAssertEqual(l.go(), .notYet("Read it again. What happens to the amounts?"))
        l.choose(0)
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.steps.count, AddingFractions.spec.steps(l.numbers).count + 1)
    }

    func testEveryThirdPracticeProblemIsAStory() {
        var rng = SeededRandom(seed: 9)
        var s = LessonSession(phase: .practice(1))
        XCTAssertNotEqual(s.makeRun(LongDivision.spec, using: &rng).words.hint, "Which operation solves it?")
        s.finished(worked(right: true))
        XCTAssertEqual(s.makeRun(LongDivision.spec, using: &rng).words.hint, "Pick what to do.")
        XCTAssertEqual(s.makeRun(LongDivision.spec, using: &rng).step.answer?.expected["c"], 3, "dividing")
        XCTAssertNotEqual(s.makeRun(UnitCubes.spec, using: &rng).words.hint, "Which operation solves it?", "no story, no step")
    }

    func testTheCheckUsesTheLessonsRecipe() {
        var rng = SeededRandom(seed: 2)
        let s = LessonSession(phase: .check(4, right: 2))
        let r = s.makeRun(MultiplyTwoDigit.spec, using: &rng)
        XCTAssertEqual(r.words.hint, "Pick what to do.", "the recipe's fourth item is the story")
        XCTAssertFalse(r.helps); XCTAssertTrue(r.oneTry)
    }
}

nonisolated(unsafe) var rngForTests = SeededRandom(seed: 5)

final class MasteryTests: XCTestCase {
    let day = 86_400.0

    func testRechecksComeBackAfter3_7_21_60Days() {
        var c = Mastery.record(nil, level: 4, now: 0)
        XCTAssertEqual(c.due, 3 * day); XCTAssertEqual(c.passes, 1)
        c = Mastery.record(c, level: 3, now: c.due); XCTAssertEqual(c.due - c.date, 7 * day)
        c = Mastery.record(c, level: 4, now: c.due); XCTAssertEqual(c.due - c.date, 21 * day)
        c = Mastery.record(c, level: 4, now: c.due); XCTAssertEqual(c.due - c.date, 60 * day)
        c = Mastery.record(c, level: 4, now: c.due); XCTAssertEqual(c.due - c.date, 60 * day, "60 days from then on")
        c = Mastery.record(c, level: 2, now: c.due)
        XCTAssertEqual(c.due - c.date, day, "a miss comes back tomorrow"); XCTAssertEqual(c.passes, 0); XCTAssertEqual(c.best, 4)
    }

    func testLevelsFromTheShareOfStepsRight() {
        XCTAssertEqual(Mastery.level(0.9), 4); XCTAssertEqual(Mastery.level(0.8), 3); XCTAssertEqual(Mastery.level(0.5), 2)
        XCTAssertEqual(Mastery.level(0.3), 1); XCTAssertEqual(Mastery.level(0.1), 0)
    }

    func testShelvesOfMe() {
        let now = 100 * day
        let checks: [String: CheckRecord] = [
            "a": .init(last: 4, best: 4, date: now - day, due: now + 2 * day, passes: 1),      // getting stronger
            "b": .init(last: 4, best: 4, date: now - 9 * day, due: now - day, passes: 2),      // due back: go over
            "c": .init(last: 2, best: 3, date: now - day, due: now, passes: 0),                // scored low: go over
            "d": .init(last: 4, best: 4, date: now - day, due: now + 59 * day, passes: 4),     // know it
        ]
        let s = Mastery.shelves(["a", "b", "c", "d", "e"], checks: checks, now: now)
        XCTAssertEqual(s.goOver, ["b", "c"]); XCTAssertEqual(s.gettingStronger, ["a"]); XCTAssertEqual(s.knowIt, ["d"])
        XCTAssertTrue(Mastery.learnedNow(checks, "a", now: now)); XCTAssertFalse(Mastery.learnedNow(checks, "b", now: now))
    }

    func testTodaysPick() {
        let deps: (String) -> [String] = { ["add": ["g4-equiv"], "sub": ["add"], "mix": ["add", "sub"]][$0] ?? [] }
        let lessons = ["add", "sub", "mix"]
        XCTAssertEqual(Mastery.upNext(lessons, depends: deps, checks: [:], grade: 5)?.id, "add", "4th grade counts as learned")
        var checks = ["add": CheckRecord(last: 4, best: 4, date: 1, due: 1e9, passes: 1)]
        XCTAssertEqual(Mastery.upNext(lessons, depends: deps, checks: checks, grade: 5)?.id, "sub", "builds on the one just learned")
        checks["sub"] = .init(last: 1, best: 1, date: 2, due: 3, passes: 0)
        checks["add"] = .init(last: 2, best: 4, date: 0.5, due: 3, passes: 0)
        let pick = Mastery.upNext(lessons, depends: deps, checks: checks, grade: 5)
        XCTAssertEqual(pick?.id, "add"); XCTAssertEqual(pick?.why, .goOver, "the oldest to go over first")
        XCTAssertEqual(Mastery.stepBack("sub", depends: ["add"], checks: checks), "add")
        XCTAssertFalse(Mastery.ready("mix", depends: ["add", "sub"], checks: checks, grade: 5))
    }

    /// A learned lesson that comes due stays learned on the map and in the count (G 20 Oct); it's marked Go over.
    func testALearnedLessonStaysLearnedWhenItComesDue() {
        var c = Mastery.record(nil, level: 3, now: 0)
        var checks = ["x": c]
        XCTAssertTrue(Mastery.learnedEver(checks, "x")); XCTAssertFalse(Mastery.goOver(checks, "x", now: day))
        let later = 4 * day
        XCTAssertTrue(Mastery.dueBack(checks, "x", now: later)); XCTAssertFalse(Mastery.learnedNow(checks, "x", now: later))
        XCTAssertTrue(Mastery.learnedEver(checks, "x"), "still counted")
        XCTAssertTrue(Mastery.goOver(checks, "x", now: later))
        // the recheck comes back low: still counted as learned once, to go over
        c = Mastery.record(c, level: 2, now: later); checks["x"] = c
        XCTAssertTrue(Mastery.learnedEver(checks, "x")); XCTAssertTrue(Mastery.goOver(checks, "x", now: later + 1))
        XCTAssertFalse(Mastery.learnedEver(["y": Mastery.record(nil, level: 2, now: 0)], "y"), "a test never passed")
    }

    /// A recheck that comes back low (G 20 Oct, CLAUDE.md "a miss: tomorrow"): not due again today, marked Go over, and
    /// the next day it opens on its recheck again; passed then, it's on its way again.
    func testARecheckThatComesBackLowComesBackTomorrowAsARecheck() {
        var c = Mastery.record(nil, level: 4, now: 0)
        let recheck = c.due
        XCTAssertTrue(Mastery.dueBack(["x": c], "x", now: recheck))
        c = Mastery.record(c, level: 2, now: recheck)
        var checks = ["x": c]
        XCTAssertFalse(Mastery.dueBack(checks, "x", now: recheck + 60), "not again today")
        XCTAssertTrue(Mastery.goOver(checks, "x", now: recheck + 60))
        XCTAssertTrue(Mastery.dueBack(checks, "x", now: recheck + day), "the next day it opens on its recheck")
        XCTAssertEqual(Mastery.upNext(["x"], depends: { _ in [] }, checks: checks, grade: 5, now: recheck + day)?.why, .goOver)
        c = Mastery.record(c, level: 3, now: recheck + day); checks["x"] = c
        XCTAssertFalse(Mastery.goOver(checks, "x", now: recheck + day + 60))
        XCTAssertEqual(c.due - c.date, 3 * day, "passed again: three days, as after a first pass")
    }

    /// A lesson never learned isn't Go over (G 20 Oct): a lesson test that came back low is to take again, and the
    /// shelves of Me add up to the learned count.
    func testATestThatCameBackLowIsntGoOver() {
        let now = 10 * day
        let checks = ["never": Mastery.record(nil, level: 1, now: now - day),
                      "learned": Mastery.record(nil, level: 4, now: now - day),
                      "due": Mastery.record(nil, level: 4, now: now - 4 * day),
                      "slipped": Mastery.record(Mastery.record(nil, level: 4, now: now - 5 * day), level: 1, now: now - 60)]
        XCTAssertFalse(Mastery.goOver(checks, "never", now: now)); XCTAssertFalse(Mastery.dueBack(checks, "never", now: now + 9 * day))
        XCTAssertTrue(Mastery.toGoOver(checks, "never"), "Today's pick still sends the child back to it")
        XCTAssertTrue(Mastery.goOver(checks, "due", now: now)); XCTAssertTrue(Mastery.goOver(checks, "slipped", now: now))
        let s = Mastery.shelves(["never", "learned", "due", "slipped"], checks: checks, now: now)
        XCTAssertEqual(s.goOver, ["due", "slipped"]); XCTAssertEqual(s.gettingStronger, ["learned"]); XCTAssertEqual(s.knowIt, [])
        let learned = checks.keys.filter { Mastery.learnedEver(checks, $0) }.count
        XCTAssertEqual(s.goOver.count + s.gettingStronger.count + s.knowIt.count, learned)
    }

    /// Today's pick: a lesson due back for its recheck comes first.
    func testTodayPicksTheLessonDueBackFirst() {
        let deps: (String) -> [String] = { _ in [] }
        let checks = ["add": CheckRecord(last: 4, best: 4, date: 0, due: 3 * day, passes: 1),
                      "sub": CheckRecord(last: 4, best: 4, date: day, due: 5 * day, passes: 1)]
        XCTAssertEqual(Mastery.upNext(["add", "sub", "mix"], depends: deps, checks: checks, grade: 5, now: 2 * day)?.id, "mix")
        let pick = Mastery.upNext(["add", "sub", "mix"], depends: deps, checks: checks, grade: 5, now: 6 * day)
        XCTAssertEqual(pick?.id, "add"); XCTAssertEqual(pick?.why, .goOver)
    }

    func testTheCheckScoresSteps() {
        var s = LessonSession(phase: .check(1, right: 0))
        var rng = SeededRandom(seed: 4)
        for k in 0..<4 {
            var r = s.makeRun(AddFractions.spec, using: &rng)
            while !r.isLast {
                if k == 0, r.step.task != nil, r.missedSteps.isEmpty { _ = r.go() }   // one miss in the first problem
                if r.step.task != nil { _ = r.showMe() }
                _ = r.go()
            }
            s.finished(r)
        }
        // 4 problems × 2 marking steps, one missed: 7 of 8 = 0.875 → 3
        XCTAssertEqual(s.level, 3); XCTAssertEqual(s.phase, .done(learned: true))
    }
}

final class SelectZoomTests: XCTestCase {
    /// Tapping lessons one after another always glides to 100%, unless the lesson wouldn't fit.
    func testTappingLessonsHasALimit() {
        var z = 0.6
        for _ in 0..<5 { z = CameraTiming.selectZoom(current: z, overview: 0.6, fit: 2.5) }
        XCTAssertEqual(z, 1.0, accuracy: 1e-9)
        XCTAssertEqual(CameraTiming.selectZoom(current: 1.8, overview: 0.6, fit: 2.5), 1.0, "closer than that: back to 100%")
        XCTAssertEqual(CameraTiming.selectZoom(current: 0.6, overview: 0.6, fit: 0.7), 0.7, "the lesson always fits")
        XCTAssertEqual(CameraTiming.lessonMax, 1.25, "a lesson's own steps can still come closer")
    }
}

final class RectTests: XCTestCase {
    func testUnion() {
        XCTAssertEqual(Rect(x: 0, y: 0, width: 10, height: 10).union(Rect(x: 5, y: -5, width: 20, height: 5)), Rect(x: 0, y: -5, width: 25, height: 15))
    }
}

final class StraightIntoSolvingTests: XCTestCase {
    func testPageProblemsStartOnTheirFirstStep() {
        var plain = LessonRun(AddFractions.spec, numbers: AddFractions.Problem(a: 4, p: 1, b: 8, q: 1).numbers); plain.skipAsk()
        XCTAssertEqual(plain.words.say, "Shade eighths to match 1/4.", "no Let’s find out first")
        var story = LessonRun(AddFractions.spec, numbers: AddFractions.Problem(a: 4, p: 1, b: 8, q: 1).numbers, story: true); story.skipAsk()
        XCTAssertEqual(story.words.hint, "Pick what to do.")
        story.choose(0)
        _ = story.go()
        XCTAssertEqual(story.words.say, "Shade eighths to match 1/4.", "after the story's operation, straight into the problem")
        var cubes = LessonRun(UnitCubes.spec, numbers: UnitCubes.Box(length: 4, width: 3, height: 2).numbers); cubes.skipAsk()
        XCTAssertEqual(cubes.words.say, "Cover the floor with squares.")
        _ = cubes.showMe(); _ = cubes.go()
        XCTAssertEqual(cubes.words.say, "One layer: 12 cubes.", "the layers aren't skipped")
    }
}
