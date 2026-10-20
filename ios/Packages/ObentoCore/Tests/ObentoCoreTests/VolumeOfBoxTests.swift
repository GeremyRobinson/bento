import XCTest
@testable import ObentoCore

final class VolumeOfBoxTests: XCTestCase {
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for c in s { l.type(String(c)) } }
    func run(_ l: Int, _ w: Int, _ h: Int) -> LessonRun { LessonRun(VolumeOfBox.spec, numbers: VolumeOfBox.numbers(length: l, width: w, height: h)) }

    /// Unit cubes' own box, 4 × 3 × 2, step by step: cover the floor, build the layers, write it.
    func testWalkThroughTheLesson() {
        var l = run(4, 3, 2)
        let b = UnitCubes.Box(length: 4, width: 3, height: 2)
        XCTAssertEqual(l.display, [.num(4), .op("×"), .num(3), .op("×"), .num(2), .op("="), .text("?")])
        XCTAssertEqual(l.steps.count, 4, "cover, build, volume, done")
        XCTAssertNil(l.askIndex, "the floor is the first step: nothing to pass by")

        // cover: the floor's 12 squares, flat
        XCTAssertEqual(l.words.say, "Drag across the floor to cover it.")
        XCTAssertEqual(l.step.camera, .flat)
        XCTAssertEqual(l.picture, ["floor": 1])
        XCTAssertEqual(l.step.task?.cells, Set(0..<12))
        XCTAssertFalse(l.tap(12), "a layer's cell isn't on the floor")
        for c in 0..<9 { XCTAssertTrue(l.tap(c)) }
        XCTAssertEqual(l.countLine, "9 of 12 squares")
        XCTAssertEqual(l.go(), .notYet("Not yet. 3 squares are still empty."))
        XCTAssertEqual(l.picture, ["floor": 1, "empty": 1], "a miss outlines the squares still empty")
        for c in 9..<12 { l.tap(c) }
        XCTAssertEqual(l.go(), .moved(1))

        // build: the floor has risen into the first layer; the layers above it stack up
        XCTAssertEqual(l.words.say, "Drag up to stack the layers.")
        XCTAssertEqual(l.step.camera, .tilted, "the paper tilts as the floor rises")
        XCTAssertEqual(l.picture, ["layers": 1, "box": 1])
        XCTAssertEqual(l.step.task?.cells, [13])
        XCTAssertEqual(l.step.task?.want, 1)
        XCTAssertEqual(l.countLine, "1 of 2 layers")
        XCTAssertEqual(l.go(), .notYet("Keep going. The box is 2 cm tall."))
        XCTAssertFalse(l.tap(3), "the floor's squares are done")
        XCTAssertTrue(l.tap(VolumeOfBox.layerCell(1, b)))
        XCTAssertEqual(l.countLine, "2 of 2 layers")
        XCTAssertEqual(l.go(), .moved(2))

        // volume: the record, typed
        XCTAssertEqual(l.words.say, "How many cubes fill the box? Write it.")
        XCTAssertEqual(l.step.camera, .tilted)
        XCTAssertEqual(l.picture, ["layers": 2, "record": 1])
        XCTAssertEqual(VolumeOfBox.layerLine(b), "4 × 3 = 12 cubes in a layer")
        XCTAssertEqual(VolumeOfBox.layersLine(b), "2 layers of 12 =")
        XCTAssertEqual(l.step.answer?.prompt, [.num(2), .text("layers of"), .num(12), .op("="), .box("x")])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        type(&l, "14")
        XCTAssertEqual(l.go(), .notYet("That adds 2 to 12. There are 2 layers of 12."))
        XCTAssertEqual(l.picture["counts"], 1, "a miss lights each layer's count")
        type(&l, "9")
        XCTAssertEqual(l.go(), .notYet("That adds the sides. There are 2 layers of 12."))
        type(&l, "12")
        XCTAssertEqual(l.go(), .notYet("That's one layer. There are 2."))
        type(&l, "25")
        XCTAssertEqual(l.go(), .notYet("Not quite. Each layer has 12 cubes."))
        XCTAssertEqual(l.steps[2].answer?.work, [.num(2), .text("layers of"), .num(12), .op("="), .num(24)])
        type(&l, "24")
        XCTAssertEqual(l.go(), .moved(3))

        // done: the last words say it, and the record ends with the volume
        XCTAssertEqual(l.words.say, "2 layers of 12 is 24.")
        XCTAssertEqual(l.words.hint, "Volume = 4 × 3 × 2 = 24 cubic cm")
        XCTAssertEqual(VolumeOfBox.layersDone(b), "2 layers of 12 = 24 cubes")
        XCTAssertEqual(l.picture, ["layers": 2, "record": 2])
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertTrue(l.isLast)
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// The smallest box: 2 × 2 × 2. Its slips land on the same numbers (2 + 2 + 2 = 4 + 2), and the first one says it.
    func testTheSmallestBox() {
        var l = run(2, 2, 2)
        let b = UnitCubes.Box(length: 2, width: 2, height: 2)
        XCTAssertEqual(l.step.task?.want, 4)
        XCTAssertEqual(l.countLine, "0 of 4 squares")
        _ = l.showMe()
        XCTAssertEqual(l.countLine, "4 of 4 squares")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.step.task?.cells, [VolumeOfBox.layerCell(1, b)])
        XCTAssertEqual(VolumeOfBox.layerCell(1, b), 5)
        XCTAssertEqual(l.step.task?.showMe, [5])
        _ = l.showMe(); XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(VolumeOfBox.layerLine(b), "2 × 2 = 4 cubes in a layer")
        type(&l, "6")
        XCTAssertEqual(l.go(), .notYet("That adds 2 to 4. There are 2 layers of 4."))
        type(&l, "4")
        XCTAssertEqual(l.go(), .notYet("That's one layer. There are 2."))
        type(&l, "8")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "2 layers of 4 is 8.")
        XCTAssertEqual(l.words.hint, "Volume = 2 × 2 × 2 = 8 cubic cm")
        XCTAssertEqual((0..<2).map { VolumeOfBox.count($0, b) }, ["4", "8"])
    }

    /// The biggest box the lesson draws: 8 × 8 × 6, 6 layers of 64. Every layer is built, and counted on its front.
    func testTheBiggestBox() {
        var l = run(8, 8, 6)
        let b = UnitCubes.Box(length: 8, width: 8, height: 6)
        XCTAssertEqual(l.step.task?.cells.count, 64)
        for c in 0..<64 { l.tap(c) }
        XCTAssertEqual(l.countLine, "64 of 64 squares")
        XCTAssertEqual(l.go(), .moved(1))
        XCTAssertEqual(l.step.task?.cells, Set(65..<70), "layers 1 to 5 stand on the floor's layer")
        XCTAssertEqual(l.step.task?.want, 5)
        XCTAssertEqual(l.countLine, "1 of 6 layers")
        for k in 1..<4 { XCTAssertTrue(l.tap(VolumeOfBox.layerCell(k, b))) }
        XCTAssertEqual(l.countLine, "4 of 6 layers")
        XCTAssertEqual(l.go(), .notYet("Keep going. The box is 6 cm tall."))
        // dragging back down takes a layer off again
        XCTAssertTrue(l.tap(VolumeOfBox.layerCell(3, b)))
        XCTAssertEqual(l.countLine, "3 of 6 layers")
        for k in 3..<6 { l.tap(VolumeOfBox.layerCell(k, b)) }
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(VolumeOfBox.layerLine(b), "8 × 8 = 64 cubes in a layer")
        XCTAssertEqual(VolumeOfBox.layersLine(b), "6 layers of 64 =")
        XCTAssertEqual((0..<6).map { VolumeOfBox.count($0, b) }, ["64", "128", "192", "256", "320", "384"])
        type(&l, "70")
        XCTAssertEqual(l.go(), .notYet("That adds 6 to 64. There are 6 layers of 64."))
        type(&l, "22")
        XCTAssertEqual(l.go(), .notYet("That adds the sides. There are 6 layers of 64."))
        type(&l, "384")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "6 layers of 64 is 384.")
        XCTAssertEqual(VolumeOfBox.volumeLine(b), "Volume = 8 × 8 × 6 = 384 cubic cm")
        XCTAssertEqual(VolumeOfBox.layersDone(b), "6 layers of 64 = 384 cubes")
    }

    /// On the page the child goes straight to the floor, and a test problem (one try) shows the answer after a miss.
    func testOnThePageAndInATest() {
        var rng = SeededRandom(seed: 3)
        let plan = LessonPlan(VolumeOfBox.spec, using: &rng)
        let r = plan.run(VolumeOfBox.spec, 0)
        XCTAssertEqual(r.index, 0)
        XCTAssertEqual(r.words.say, "Drag across the floor to cover it.")
        var t = LessonPlan.testRuns(VolumeOfBox.spec, using: &rng)[0]
        XCTAssertTrue(t.oneTry)
        _ = t.showMe(); _ = t.go(); _ = t.showMe(); _ = t.go()
        type(&t, "1")
        let v = UnitCubes.Box(t.numbers).volume
        XCTAssertEqual(t.go(), .notYet("Not quite. Each layer has \(UnitCubes.Box(t.numbers).floor) cubes."))
        XCTAssertEqual(t.typed["x"], String(v), "one try: the answer is written in")
        XCTAssertTrue(t.missedAny)
    }

    func testSpecData() {
        let s = VolumeOfBox.spec
        XCTAssertEqual(s.id, "g5-volume"); XCTAssertEqual(s.master, "cubes")
        XCTAssertEqual(s.depends, ["g4-area", "g4-partial"])
        XCTAssertEqual(s.check.map(\.index), [3, 3, VolumeOfBox.tallestCheck, 3])
        XCTAssertNil(s.story)
    }

    /// The web's ranges (fixes-02 A3): the first three boxes 2–5 on every side, then 2–8 by 2–8 by 2–6.
    func testGeneratorKeepsTheWebRanges() {
        var rng = SeededRandom(seed: 5)
        for index in [0, 1, 2, 3, 6] {
            for _ in 0..<300 {
                let n = VolumeOfBox.spec.generate(&rng, index)
                let top: [Double] = index < 3 ? [5, 5, 5] : [8, 8, 6]
                for (k, name) in ["length", "width", "height"].enumerated() {
                    let v = n[name]!
                    XCTAssertTrue(v >= 2 && v <= top[k] && v == v.rounded(), "\(index) \(n)")
                }
                let run = LessonRun(VolumeOfBox.spec, numbers: n), b = UnitCubes.Box(n)
                XCTAssertEqual(run.steps[0].task?.want, b.floor)
                XCTAssertEqual(run.steps[1].task?.want, b.height - 1)
                XCTAssertEqual(run.steps[2].answer?.expected["x"], n["length"]! * n["width"]! * n["height"]!)
            }
        }
    }

    /// Every check item's draw satisfies its `when`; the tallest item has the height as its biggest side.
    func testCheckDrawsFit() {
        var rng = SeededRandom(seed: 21)
        for item in VolumeOfBox.spec.check {
            for _ in 0..<300 {
                let n = item.draw(VolumeOfBox.spec, using: &rng)
                XCTAssertTrue(item.when?(n) ?? true, "\(item.index) \(n)")
                XCTAssertEqual(LessonRun(VolumeOfBox.spec, numbers: n).steps.count, 4)
            }
        }
        // the tallest item fits on its first draw, as the web's draw-then-fix does
        for _ in 0..<300 {
            let n = VolumeOfBox.spec.generate(&rng, VolumeOfBox.tallestCheck)
            XCTAssertTrue(n["height"]! >= n["length"]! && n["height"]! >= n["width"]!, "\(n)")
            XCTAssertTrue([n["length"]!, n["width"]!, n["height"]!].allSatisfy { (2...8).contains($0) })
        }
    }

    /// A problem stopped partway comes back as it was: the floor covered, two layers built.
    func testItComesBackAsItWasLeft() throws {
        var l = run(5, 4, 3)
        let b = UnitCubes.Box(l.numbers)
        _ = l.showMe(); _ = l.go()
        l.tap(VolumeOfBox.layerCell(1, b))
        let back = LessonRun(VolumeOfBox.spec, restoring: try JSONDecoder().decode(RunSnapshot.self, from: JSONEncoder().encode(l.snapshot)))
        XCTAssertEqual(back.index, 1)
        XCTAssertEqual(back.marks, l.marks)
        XCTAssertEqual(back.countLine, "2 of 3 layers")
    }
}
