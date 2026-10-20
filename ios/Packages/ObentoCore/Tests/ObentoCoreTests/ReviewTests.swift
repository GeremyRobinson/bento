import XCTest
@testable import ObentoCore

/// The daily review (Core/Review.swift): 8 problems from the lessons already checked, weighted to the weak and the old.
final class ReviewTests: XCTestCase {
    let day = 86_400.0

    /// A check taken `daysAgo` days before `now`, scoring `last` (best `best`), coming back in `dueIn` days.
    func check(last: Int, best: Int? = nil, daysAgo: Double, dueIn: Double = 3, now: Double) -> CheckRecord {
        CheckRecord(last: last, best: best ?? last, date: now - daysAgo * day, due: now + dueIn * day, passes: last >= 3 ? 1 : 0)
    }

    func testNoReviewUntilTwoLessonsHaveHadACheck() {
        var rng = SeededRandom(seed: 1)
        let now = 1000 * day
        XCTAssertEqual(Review.pick(["a", "b"], checks: [:], now: now, using: &rng), [])
        let one = ["a": check(last: 4, daysAgo: 1, now: now)]
        XCTAssertFalse(Review.ready(["a", "b"], checks: one))
        XCTAssertEqual(Review.pick(["a", "b"], checks: one, now: now, using: &rng), [])
        var two = one; two["b"] = check(last: 2, daysAgo: 1, now: now)
        XCTAssertTrue(Review.ready(["a", "b"], checks: two))
        XCTAssertEqual(Review.pick(["a", "b"], checks: two, now: now, using: &rng).count, Review.problems)
    }

    func testEightProblemsAtMostTwoFromALesson() {
        let now = 1000 * day
        let ids = ["a", "b", "c", "d", "e", "f"]
        let checks = Dictionary(uniqueKeysWithValues: ids.enumerated().map { i, id in (id, check(last: i % 5, daysAgo: Double(i), now: now)) })
        for seed in 0..<200 {
            var rng = SeededRandom(seed: UInt64(seed))
            let pick = Review.pick(ids, checks: checks, now: now, using: &rng)
            XCTAssertEqual(pick.count, 8)
            for id in ids { XCTAssertLessThanOrEqual(pick.filter { $0 == id }.count, 2, "at most 2 from one lesson") }
            for (x, y) in zip(pick, pick.dropFirst()) { XCTAssertNotEqual(x, y, "never the same lesson twice in a row") }
        }
    }

    func testWithFewLessonsUpToFourFromEach() {
        let now = 1000 * day
        let checks = ["a": check(last: 4, daysAgo: 1, now: now), "b": check(last: 4, daysAgo: 1, now: now)]
        var rng = SeededRandom(seed: 9)
        let pick = Review.pick(["a", "b"], checks: checks, now: now, using: &rng)
        XCTAssertEqual(pick.filter { $0 == "a" }.count, 4)
        XCTAssertEqual(pick.filter { $0 == "b" }.count, 4)
        for (x, y) in zip(pick, pick.dropFirst()) { XCTAssertNotEqual(x, y) }
    }

    func testWeakAndOldLessonsComeMost() {
        let now = 1000 * day
        // a strong lesson checked yesterday weighs least; a weak one, an old one and one due back weigh more
        let strong = check(last: 4, daysAgo: 1, now: now), weak = check(last: 1, daysAgo: 1, now: now)
        let old = check(last: 4, daysAgo: 30, now: now), due = check(last: 4, daysAgo: 7, dueIn: -1, now: now)
        XCTAssertGreaterThan(Review.weight(weak, now: now), Review.weight(strong, now: now))
        XCTAssertGreaterThan(Review.weight(old, now: now), Review.weight(strong, now: now))
        XCTAssertEqual(Review.weight(due, now: now), 3 * Review.weight(check(last: 4, daysAgo: 7, dueIn: 1, now: now), now: now), accuracy: 1e-9, "due back: three times over")
        // drawn many times, the weak lesson comes up more than the strong one
        let ids = ["strong", "weak", "x", "y", "z"]
        let checks = ["strong": strong, "weak": weak, "x": strong, "y": strong, "z": strong]
        var counts: [String: Int] = [:]
        for seed in 0..<300 {
            var rng = SeededRandom(seed: UInt64(seed))
            for id in Review.pick(ids, checks: checks, now: now, using: &rng) { counts[id, default: 0] += 1 }
        }
        XCTAssertGreaterThan(counts["weak"] ?? 0, counts["strong"] ?? 0)
    }

    func testTheSameSeedMakesTheSameReview() {
        let now = 1000 * day
        let checks = ["a": check(last: 2, daysAgo: 3, now: now), "b": check(last: 4, daysAgo: 9, now: now), "c": check(last: 3, daysAgo: 1, now: now)]
        var r1 = SeededRandom(seed: 42), r2 = SeededRandom(seed: 42)
        XCTAssertEqual(Review.pick(["a", "b", "c"], checks: checks, now: now, using: &r1), Review.pick(["a", "b", "c"], checks: checks, now: now, using: &r2))
    }

    func testSpreadKeepsEveryLessonAndAvoidsRepeats() {
        var rng = SeededRandom(seed: 5)
        let ids = ["a", "a", "a", "a", "b", "b", "b", "b"]
        let out = Review.spread(ids, using: &rng)
        XCTAssertEqual(out.sorted(), ids.sorted())
        for (x, y) in zip(out, out.dropFirst()) { XCTAssertNotEqual(x, y) }
        // when it can't be helped (one lesson only), it still keeps them all
        XCTAssertEqual(Review.spread(["a", "a", "b"], using: &rng).sorted(), ["a", "a", "b"])
    }

    func testTheProblemsAreOneTryWithNoHelpFromEachLessonsRecipe() {
        var rng = SeededRandom(seed: 3)
        let specs = [RoundDecimals.spec, AddingFractions.spec, RoundDecimals.spec]
        let runs = Review.runs(specs, using: &rng)
        XCTAssertEqual(runs.map(\.spec.id), specs.map(\.id))
        for r in runs { XCTAssertFalse(r.helps); XCTAssertTrue(r.oneTry); XCTAssertFalse(r.isLast) }
    }

    func testADayIsTheChildsOwnDay() {
        let utc = TimeZone(identifier: "UTC")!
        // 2001-01-01 00:00 UTC is 0
        XCTAssertEqual(Review.day(0, in: utc), "2001-01-01")
        XCTAssertEqual(Review.day(day - 1, in: utc), "2001-01-01")
        XCTAssertEqual(Review.day(day, in: utc), "2001-01-02")
        XCTAssertEqual(Review.day(0, in: TimeZone(identifier: "America/New_York")!), "2000-12-31")
    }
}
