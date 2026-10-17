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
        XCTAssertEqual(l.picture, [:], "nothing extra after a miss here")
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
        XCTAssertEqual(l.words.say, "1/4 is how many eighths?")
        l.tap(5)
        XCTAssertEqual(l.go(), .notYet("Not yet. Some of the fourth is still uncovered."))
        XCTAssertEqual(l.picture["guide"], 1, "a miss shows where the fourth ends")
        XCTAssertEqual(l.step.look, "The fourth ends here")
        l.tap(6); l.tap(7)
        XCTAssertEqual(l.go(), .notYet("Too many. Some eighths go past the fourth."))
        l.tap(7)
        // two eighths cover the fourth, and they line up under it
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.marked(on: 1), [0, 1])
        XCTAssertNil(l.picture["guide"])
        XCTAssertFalse(l.tap(0), "shaded pieces stay put while adding")
        XCTAssertEqual(l.go(), .notYet("Add the extra eighth first."))
        l.tap(2)
        XCTAssertEqual(l.countLine, "3 of 8 shaded")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "Three eighths.")
        XCTAssertEqual(l.words.hint, "A fourth covers two eighths. Add one more and you have three.")
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
        XCTAssertEqual(l.words.say, "Five sixths.")
        XCTAssertEqual(l.words.hint, "2 thirds cover four sixths. Add one more and you have five.")
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

final class PowersOfTenTests: XCTestCase {
    func testWalkThroughTheLesson() {
        var l = LessonRun(PowersOfTen.spec, numbers: PowersOfTen.numbers(x: 3.47, k: 2))
        XCTAssertEqual(l.words.say, "What is 3.47 × 100?")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        l.type("3")
        XCTAssertEqual(l.go(), .notYet("The 1 isn’t a zero. Count only the 0s in 100."))
        l.type("del"); l.type("2")
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "Move the point 2 places to the right.")
        for k in ["3", "4", ".", "7"] { l.type(k) }
        XCTAssertEqual(l.go(), .notYet("Move it one place for each zero."))
        l.reset()
        for k in ["0", ".", "0", "3", "4", "7"] { l.type(k) }
        XCTAssertEqual(l.go(), .notYet("Multiplying by 100 makes the number bigger, so the point moves right."))
        XCTAssertEqual(l.misses, 2)
        XCTAssertEqual(l.showAnswer(), "Each zero moves the point one place to the right. That makes 347.")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "3.47 × 100 = 347.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(3.47), .op("×"), .num(100), .op("="), .num(347)])
    }

    func testTypingRules() {
        var l = LessonRun(PowersOfTen.spec, numbers: PowersOfTen.numbers(x: 1.5, k: 3)); _ = l.go(); _ = l.go()
        l.reset(); l.type("."); l.type("5"); l.type(".")
        XCTAssertEqual(l.typed["x"], "0.5", "a lone point gets its 0, and only one point")
        XCTAssertEqual(PowersOfTen.digits(4.06).digits, "406")
        XCTAssertEqual(fmt(3.40), "3.4"); XCTAssertEqual(fmt(-2), "−2"); XCTAssertEqual(fmt(1500), "1500")
    }

    func testEveryProblemIsInRange() {
        var rng = SeededRandom(seed: 11)
        for _ in 0..<300 {
            let n = PowersOfTen.spec.generate(&rng, 5), x = n["x"]!, k = Int(n["k"]!)
            XCTAssertTrue((1.01...99.99).contains(x) && (1...3).contains(k))
            XCTAssertEqual(x * 100, (x * 100).rounded(), accuracy: 1e-9)
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
