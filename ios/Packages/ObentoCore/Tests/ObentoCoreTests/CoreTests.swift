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
}

final class UnitCubesTests: XCTestCase {
    func testWalkThroughTheLesson() {
        var l = UnitCubes(box: .init(length: 4, width: 3, height: 2))
        XCTAssertEqual(l.words.hint, "It is 4 long, 3 wide and 2 tall.")
        XCTAssertEqual(l.go(), .moved(.coverFloor))
        XCTAssertTrue(l.tap(.init(0, 0)))
        XCTAssertFalse(l.tap(.init(4, 0)), "outside the box")
        XCTAssertEqual(l.go(), .notYet(empty: 11))
        XCTAssertEqual(UnitCubes.notYetLine(11), "Not yet. 11 squares are still empty.")
        XCTAssertEqual(l.showMe().count, 11)
        XCTAssertEqual(l.countLine, "12 of 12 squares")
        XCTAssertEqual(l.go(), .moved(.stack(layers: 1)))
        XCTAssertEqual(l.words.say, "One layer: 12 cubes.")
        XCTAssertEqual(l.go(), .moved(.done))
        XCTAssertEqual(l.words.hint, "Volume = 4 × 3 × 2 = 24 cubes.")
        XCTAssertEqual(l.go(), .newProblem)
    }

    func testTapTwiceUncovers() {
        var l = UnitCubes(box: .init(length: 3, width: 2, height: 2)); _ = l.go()
        l.tap(.init(1, 1)); l.tap(.init(1, 1))
        XCTAssertTrue(l.covered.isEmpty)
    }

    func testTallBoxStacksEveryLayer() {
        var l = UnitCubes(box: .init(length: 3, width: 2, height: 3)); _ = l.go(); _ = l.showMe(); _ = l.go()
        XCTAssertEqual(l.go(), .moved(.stack(layers: 2)))
        XCTAssertEqual(l.words.say, "2 layers of 6 is 12.")
        XCTAssertEqual(l.go(), .moved(.done))
        XCTAssertEqual(l.layers, 3)
    }

    /// Every generated box is a real, readable problem and the answer always matches the cubes.
    func testGeneratorAlwaysMakesAReadableBox() {
        var rng = SeededRandom(seed: 7)
        for _ in 0..<500 {
            let b = UnitCubes.generate(using: &rng).box
            XCTAssertTrue((2...5).contains(b.length) && (2...4).contains(b.width) && (2...3).contains(b.height))
            XCTAssertGreaterThan(b.length, b.width)
            XCTAssertEqual(b.volume, b.length * b.width * b.height)
        }
    }
}
