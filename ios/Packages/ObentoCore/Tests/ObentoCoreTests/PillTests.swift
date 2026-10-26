import XCTest
@testable import ObentoCore

/// The calm smart pill (Core/Pill.swift): what its middle offers, which tools show, its step squares, its first-use
/// words and the grades.
final class PillTests: XCTestCase {
    // MARK: the map's middle

    func testNothingStartedOffersTheGrade() {
        XCTAssertEqual(Pill.offer(reviewLeft: nil, due: [], pages: []), .grade)
        XCTAssertEqual(Pill.Offer.grade.words(grade: "5th grade"), "5th grade")
    }

    func testContinueIsThePageLastWorkedOnThatIsNotFinished() {
        let pages = [Pill.Page(id: "add", date: 10, finished: false), Pill.Page(id: "g5-round", date: 30, finished: true),
                     Pill.Page(id: "g5-divide", date: 20, finished: false)]
        XCTAssertEqual(Pill.offer(reviewLeft: nil, due: [], pages: pages), .resume("g5-divide"))
        XCTAssertEqual(Pill.Offer.resume("g5-divide").words(grade: "5th grade"), "Continue →")
        // every page finished: nothing to continue
        XCTAssertEqual(Pill.offer(reviewLeft: nil, due: [], pages: [Pill.Page(id: "add", date: 1, finished: true)]), .grade)
    }

    func testWhatsDueComesFirst() {
        let pages = [Pill.Page(id: "add", date: 10, finished: false)]
        XCTAssertEqual(Pill.offer(reviewLeft: 8, due: ["g5-round"], pages: pages), .review(left: 8))
        XCTAssertEqual(Pill.Offer.review(left: 5).words(grade: ""), "Go over · 5")
        // today's review done: the rechecks due, the first opening
        XCTAssertEqual(Pill.offer(reviewLeft: nil, due: ["g5-round", "sub"], pages: pages), .recheck("g5-round", count: 2))
        XCTAssertEqual(Pill.Offer.recheck("g5-round", count: 2).words(grade: ""), "Go over · 2")
    }

    func testReviewLeft() {
        XCTAssertNil(Pill.reviewLeft(ready: false, doneToday: false, partway: nil), "no review until two lessons are checked")
        XCTAssertNil(Pill.reviewLeft(ready: true, doneToday: true, partway: nil), "done today")
        XCTAssertEqual(Pill.reviewLeft(ready: true, doneToday: false, partway: nil), Review.problems)
        XCTAssertEqual(Pill.reviewLeft(ready: true, doneToday: false, partway: 3), Review.problems - 3)
        // started before a grown-up's reset: what's left still shows, while it's partway
        XCTAssertNil(Pill.reviewLeft(ready: true, doneToday: false, partway: Review.problems))
    }

    // MARK: in a lesson

    func testThePageHasNoTools() {
        XCTAssertEqual(Pill.tools(nil), Pill.Tools())
        XCTAssertEqual(Pill.tools(Pill.Problem(auto: true)), Pill.Tools(), "the How to plays itself")
    }

    func testWorkingHasHintAndShowMe() {
        XCTAssertEqual(Pill.tools(Pill.Problem()), Pill.Tools(hint: true, showMe: true))
    }

    func testAfterAMissShowMeHasItsWord() {
        XCTAssertEqual(Pill.tools(Pill.Problem(missed: true)), Pill.Tools(hint: true, showMe: true, showMeWord: true))
    }

    func testSolvedFoldsTheToolsAwayForNext() {
        XCTAssertEqual(Pill.tools(Pill.Problem(solved: true, missed: true)), Pill.Tools(next: true))
        XCTAssertEqual(Pill.tools(Pill.Problem(inTest: true, solved: true)), Pill.Tools(next: true))
    }

    func testTestsHaveNoHelp() {
        XCTAssertEqual(Pill.tools(Pill.Problem(inTest: true, missed: true)), Pill.Tools())
    }

    func testAHandMoveDimsTheRest() {
        XCTAssertEqual(Pill.tools(Pill.Problem(moving: true)), Pill.Tools(hint: true, showMe: true, dim: true))
    }

    func testStepSquares() {
        // an opening question the problem goes past, then three steps the child does, then the last words
        let work = [false, true, true, true, false]
        XCTAssertEqual(Pill.steps(work: work, index: 1, solved: false).done, 0)
        XCTAssertEqual(Pill.steps(work: work, index: 1, solved: false).of, 3)
        XCTAssertEqual(Pill.steps(work: work, index: 3, solved: false).done, 2)
        XCTAssertEqual(Pill.steps(work: work, index: 4, solved: true).done, 3)
        XCTAssertEqual(Pill.steps(work: [], index: 0, solved: false).of, 0)
    }

    func testStepSquaresOfARealProblem() throws {
        let spec = try XCTUnwrap(Lessons.spec("g5-round"))
        var rng = SeededRandom(seed: 4)
        let run = LessonRun(spec, numbers: spec.generate(&rng, 0))
        let s = Pill.steps(run)
        XCTAssertEqual(s.of, run.workSteps)
        XCTAssertGreaterThan(s.of, 0)
        XCTAssertEqual(s.done, 0)
    }

    // MARK: first-use words

    func testWordsForTheFirstThreeSessionsThenTheyFade() {
        XCTAssertEqual(Pill.labels(session: 1), .shown)
        XCTAssertEqual(Pill.labels(session: 3), .shown)
        XCTAssertEqual(Pill.labels(session: 4), .fading)
        XCTAssertEqual(Pill.labels(session: 5), .hidden)
    }

    func testANewSession() {
        XCTAssertTrue(Pill.isNewSession(lastActive: nil, now: 100))
        XCTAssertFalse(Pill.isNewSession(lastActive: 100, now: 100 + 60))
        XCTAssertTrue(Pill.isNewSession(lastActive: 100, now: 100 + Pill.sessionGap))
    }

    // MARK: the grades

    func testGrades() {
        XCTAssertEqual(Pill.grades.count, 13)
        XCTAssertEqual(Pill.grades.first, "K")
        XCTAssertEqual(Pill.grades.last, "12")
        XCTAssertEqual(Pill.gradeName("K"), "Kindergarten")
        XCTAssertEqual(Pill.gradeName("1"), "1st grade")
        XCTAssertEqual(Pill.gradeName("2"), "2nd grade")
        XCTAssertEqual(Pill.gradeName("3"), "3rd grade")
        XCTAssertEqual(Pill.gradeName("5"), "5th grade")
        XCTAssertEqual(Pill.gradeName("11"), "11th grade")
        XCTAssertEqual(Pill.gradeName("12"), "12th grade")
        XCTAssertEqual(Pill.gradeTapped("5", live: "5"), "5th grade it is.")
        XCTAssertEqual(Pill.gradeTapped("7", live: "5"), "7th grade: coming soon.")
    }
}
