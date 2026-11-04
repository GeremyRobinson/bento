import XCTest
@testable import ObentoCore

/// The call of 3 Nov 2026: a hint after a miss doesn't hand over the answer. A first miss shows its line and at most
/// rings the general area; the exact spot ("spot") is drawn only after a second miss on the same step (or by Show me).
final class HintSpotTests: XCTestCase {
    /// Every hinted step of 4th grade's chapters 1 to 7 keeps the exact spot for a second miss.
    func testFirstMissNeverShowsTheSpot() {
        var rng = SeededRandom(seed: 3)
        for chapter in Curriculum.chapters(4).prefix(7) {
            for l in chapter.lessons {
                guard let spec = Lessons.spec(l.id) else { continue }
                for i in 0..<8 {
                    for step in spec.steps(spec.generate(&rng, i)) where !step.onMiss.isEmpty {
                        XCTAssertNil(step.onMiss["spot"], l.id)
                        XCTAssertEqual(step.hint2["spot"], 1, l.id)
                    }
                }
            }
        }
    }

    /// Converting measurements: the ruler let go short of the bar's end once rings the bar; twice, its end.
    func testSecondMissShowsTheSpot() {
        var r = LessonRun(Convert4.spec, numbers: Convert4.numbers(k: 0, n: 3))
        r.skipAsk()
        XCTAssertEqual(r.step.answer?.byHand, true)
        r.set("c", 10)
        _ = r.go()
        XCTAssertEqual(r.picture["ring"], 1)
        XCTAssertNil(r.picture["spot"])
        r.set("c", 10)
        _ = r.go()
        XCTAssertEqual(r.picture["spot"], 1)
    }
}
