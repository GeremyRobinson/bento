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
