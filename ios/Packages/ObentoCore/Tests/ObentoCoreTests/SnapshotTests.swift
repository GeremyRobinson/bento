import XCTest
@testable import ObentoCore

final class SnapshotTests: XCTestCase {
    /// A problem stopped halfway comes back exactly as it was left, through saving and loading.
    func testAProblemComesBackAsItWasLeft() throws {
        var rng = SeededRandom(seed: 7)
        var run = LessonRun(AddFractions.spec, numbers: AddFractions.spec.generate(&rng, 2), story: true); run.skipAsk()
        if run.step.answer?.choices != nil { run.choose(0); _ = run.go(); _ = run.go() }
        let cells = Array((run.step.task?.cells ?? []).sorted().prefix(2))
        for c in cells { run.tap(c) }
        _ = run.go()
        let data = try JSONEncoder().encode(run.snapshot)
        let saved = try JSONDecoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(saved.spec, "ad"); XCTAssertEqual(saved.stepCount, run.steps.count)
        let back = try XCTUnwrap(LessonRun.restored(AddFractions.spec, saved))
        XCTAssertEqual(back.snapshot, run.snapshot)
        XCTAssertEqual(back.index, run.index)
        XCTAssertEqual(back.marks, run.marks)
        XCTAssertEqual(back.missedSteps, run.missedSteps)
        XCTAssertEqual(back.words, run.words)
        XCTAssertEqual(back.picture, run.picture)
    }

    /// A test's problem keeps its one try and no hints.
    func testATestProblemStaysATest() throws {
        var rng = SeededRandom(seed: 3)
        let q = LessonPlan.testRuns(AddFractions.spec, using: &rng)[2]
        let back = try XCTUnwrap(LessonRun.restored(AddFractions.spec, q.snapshot))
        XCTAssertFalse(back.helps); XCTAssertTrue(back.oneTry)
    }

    /// A typed lesson worked partway comes back with what was typed in its box.
    func testTypedWorkComesBack() throws {
        var rng = SeededRandom(seed: 11)
        var run = LessonPlan(MultiplyTwoDigit.spec, using: &rng).run(MultiplyTwoDigit.spec, 4)
        let box = try XCTUnwrap(run.step.answer?.boxes.first)
        run.type("4"); run.type("2")
        let back = try XCTUnwrap(LessonRun.restored(MultiplyTwoDigit.spec, run.snapshot))
        XCTAssertEqual(back.typed[box], "42")
        XCTAssertEqual(back.index, run.index)
        XCTAssertEqual(back.hintCap, 1); XCTAssertFalse(back.guided)
    }

    /// A save that no longer fits its lesson (the lesson changed since) isn't brought back: the page starts that
    /// problem fresh instead of misreading it or stopping on a missing number.
    func testASaveThatNoLongerFitsStartsFresh() throws {
        var rng = SeededRandom(seed: 12)
        var run = LessonPlan(MultiplyTwoDigit.spec, using: &rng).run(MultiplyTwoDigit.spec, 3)
        run.type("7")
        let good = run.snapshot
        XCTAssertNotNil(LessonRun.restored(MultiplyTwoDigit.spec, good))

        var missing = good; missing.numbers["b"] = nil
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, missing), "a number the lesson reads is gone")
        var past = good; past.index = 40
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, past), "on a step the lesson doesn't have")
        var before = good; before.index = -1
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, before))
        var steps = good; steps.stepCount = run.steps.count + 2
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, steps), "the lesson's steps changed")
        var typed = good; typed.typed = ["nowhere": "3"]
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, typed), "typed into a box that isn't there")
        var marked = good; marked.marks = [5: 0]
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, marked), "a mark on a step with nothing to mark")
        var missedLater = good; missedLater.missedSteps = [99]
        XCTAssertNil(LessonRun.restored(MultiplyTwoDigit.spec, missedLater))
        XCTAssertNil(LessonRun.restored(RoundDecimals.spec, good), "brought back by its lesson, never by its place")
    }

    /// An older save, from before saves said their lesson and steps, still comes back when it fits.
    func testAnOlderSaveStillComesBackWhenItFits() throws {
        var rng = SeededRandom(seed: 13)
        let run = LessonPlan(MultiplyTwoDigit.spec, using: &rng).run(MultiplyTwoDigit.spec, 0)
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: JSONEncoder().encode(run.snapshot)) as? [String: Any])
        json["spec"] = nil; json["stepCount"] = nil
        let old = try JSONDecoder().decode(RunSnapshot.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.spec); XCTAssertNil(old.stepCount)
        XCTAssertEqual(LessonRun.restored(MultiplyTwoDigit.spec, old)?.index, run.index)
    }

    /// The numbers a lesson always has, which a save must have to come back.
    func testRequiredKeys() {
        XCTAssertEqual(MultiplyTwoDigit.spec.requiredKeys, ["a", "b"])
        XCTAssertTrue(VolumeOfBox.spec.requiredKeys.isSuperset(of: ["length", "width", "height"]))
    }
}
