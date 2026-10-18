import XCTest
@testable import ObentoCore

final class SnapshotTests: XCTestCase {
    /// A problem stopped halfway comes back exactly as it was left, through saving and loading.
    func testAProblemComesBackAsItWasLeft() throws {
        var rng = SeededRandom(seed: 7)
        let p = LessonPage.problems(AddFractions.spec, using: &rng)[2]
        var run = LessonPage.run(AddFractions.spec, p)
        if run.step.answer?.choices != nil { run.choose(0); _ = run.go(); _ = run.go() }
        let cells = Array((run.step.task?.cells ?? []).sorted().prefix(2))
        for c in cells { run.tap(c) }
        _ = run.go()
        let data = try JSONEncoder().encode(run.snapshot)
        let back = LessonRun(AddFractions.spec, restoring: try JSONDecoder().decode(RunSnapshot.self, from: data))
        XCTAssertEqual(back.snapshot, run.snapshot)
        XCTAssertEqual(back.index, run.index)
        XCTAssertEqual(back.marks, run.marks)
        XCTAssertEqual(back.missedSteps, run.missedSteps)
        XCTAssertEqual(back.words, run.words)
        XCTAssertEqual(back.picture, run.picture)
    }

    /// A check problem keeps its one try and no hints.
    func testACheckProblemStaysACheck() {
        var rng = SeededRandom(seed: 3)
        let p = LessonPage.problems(AddFractions.spec, using: &rng)[14]
        let back = LessonRun(AddFractions.spec, restoring: LessonPage.run(AddFractions.spec, p).snapshot)
        XCTAssertFalse(back.helps); XCTAssertTrue(back.oneTry)
    }
}
