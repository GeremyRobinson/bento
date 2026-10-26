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

    /// What a hand move left on the picture (the rows the child shaded) is kept across steps and comes back with a
    /// save; an older save without it comes back with nothing kept.
    func testWhatTheHandsLeftIsKept() throws {
        var run = LessonRun(MultiplyFractions.spec, numbers: MultiplyFractions.numbers(a: 2, b: 5, c: 1, d: 3)); run.skipAsk()
        run.set("x", 5); XCTAssertEqual(run.go(), .moved(run.index))
        // rows 1 and 3 tapped and shaded
        run.set("t", 2); run.keep("rowsR", 0b1010)
        let at = run.index
        XCTAssertEqual(run.go(), .moved(at + 1))
        XCTAssertEqual(run.kept["rowsR"], 10)
        let saved = try JSONDecoder().decode(RunSnapshot.self, from: JSONEncoder().encode(run.snapshot))
        let back = try XCTUnwrap(LessonRun.restored(MultiplyFractions.spec, saved))
        XCTAssertEqual(back.kept, ["rowsR": 10])
        var old = run.snapshot; old.kept = nil
        XCTAssertEqual(try XCTUnwrap(LessonRun.restored(MultiplyFractions.spec, old)).kept, [:])
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
        // the cut made by hand first: the tens strip's squares are what's typed
        let b = Int(run.numbers["b"] ?? 0)
        run.set("x", Double(b - b % 10)); XCTAssertEqual(run.go(), .moved(2))
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

    /// A lesson that has no steps for a save's numbers any more doesn't take the page down: that problem starts fresh.
    func testALessonWithNoStepsForASaveStartsFresh() {
        let spec = LessonSpec(id: "t-empty", title: "Empty", master: "test", generate: { _, _ in ["x": 2] }) { n in
            n["x"] == 1 ? [] : [LessonStep(StepWords(say: "Ask", hint: "", action: "Let’s find out")),
                                LessonStep(StepWords(say: "Done", hint: "", action: "Next problem"))]
        }
        var save = LessonRun(spec, numbers: ["x": 2]).snapshot
        XCTAssertNotNil(LessonRun.restored(spec, save))
        save.numbers = ["x": 1]; save.stepCount = nil
        XCTAssertNil(LessonRun.restored(spec, save))
    }

    /// The numbers a lesson always has, which a save must have to come back.
    func testRequiredKeys() {
        XCTAssertEqual(MultiplyTwoDigit.spec.requiredKeys, ["a", "b"])
        XCTAssertTrue(VolumeOfBox.spec.requiredKeys.isSuperset(of: ["length", "width", "height"]))
    }
}
