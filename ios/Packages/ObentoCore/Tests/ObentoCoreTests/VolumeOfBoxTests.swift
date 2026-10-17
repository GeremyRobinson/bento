import XCTest
@testable import ObentoCore

final class VolumeOfBoxTests: XCTestCase {
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for c in s { l.type(String(c)) } }

    /// The web lesson's reference box, 4 × 3 × 2, step by step.
    func testWalkThroughTheLesson() {
        var l = LessonRun(VolumeOfBox.spec, numbers: VolumeOfBox.numbers(length: 4, width: 3, height: 2))
        XCTAssertEqual(l.display, [.num(4), .op("×"), .num(3), .op("×"), .num(2), .op("="), .text("?")])
        XCTAssertEqual(l.words.say, "A box is 4 cm long, 3 cm wide and 2 cm tall. How many 1 cm cubes fill it?")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.step.camera, .flat)
        XCTAssertEqual(l.picture, ["outline": 1])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Area of the base")
        XCTAssertEqual(l.words.hint, "The bottom layer is 4 by 3.")
        XCTAssertEqual(l.step.camera, .flat)
        XCTAssertEqual(l.picture, ["floor": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        type(&l, "7")
        XCTAssertEqual(l.go(), .notYet("Area means length × width."))
        type(&l, "11")
        XCTAssertEqual(l.go(), .notYet("Not quite. Length times width."))
        XCTAssertEqual(l.showAnswer(), "Length times width. That makes 12.")
        XCTAssertEqual(l.steps[1].answer?.work, [.num(4), .op("×"), .num(3), .op("="), .num(12)])
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Times the height")
        XCTAssertEqual(l.words.hint, "Stack 2 layers to fill the box, in cubic cm.")
        XCTAssertEqual(l.step.camera, .tilted, "the box rises off the paper")
        XCTAssertEqual(l.picture, ["layers": 2, "height": 1])
        type(&l, "14")
        XCTAssertEqual(l.go(), .notYet("Each layer is the base. Multiply by the number of layers."))
        XCTAssertEqual(l.showAnswer(), "Stack the base layer up the height. That makes 24.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(12), .op("×"), .num(2), .op("="), .num(24)])
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "24 cubes fill the box.")
        XCTAssertEqual(l.words.hint, "Every layer of cubes is the same, so the layers stack up to fill the box.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.go(), .newProblem)
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
                let run = LessonRun(VolumeOfBox.spec, numbers: n)
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
}
