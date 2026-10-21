import XCTest
@testable import ObentoCore

/// Why today's pick was picked (Core/Today.swift), for Me's plain words.
final class TodayTests: XCTestCase {
    let day = 86_400.0
    let deps: (String) -> [String] = { ["add": ["g4-equiv"], "sub": ["add"], "mix": ["add", "sub"]][$0] ?? [] }
    let lessons = ["add", "sub", "mix"]

    func reason(_ checks: [String: CheckRecord], now: Double = 0) -> (String, Today.Reason)? {
        guard let pick = Mastery.upNext(lessons, depends: deps, checks: checks, grade: 5, now: now) else { return nil }
        return (pick.id, Today.reason(pick, lessons: lessons, depends: deps, checks: checks, now: now))
    }

    func testNothingLearnedIsTheFirstLesson() {
        XCTAssertEqual(reason([:])?.0, "add")
        XCTAssertEqual(reason([:])?.1, .first)
    }

    func testTheNextOneBuildsOnTheLessonLearnedLast() {
        let checks = ["add": CheckRecord(last: 4, best: 4, date: 1, due: 1e9, passes: 1)]
        XCTAssertEqual(reason(checks)?.0, "sub")
        XCTAssertEqual(reason(checks)?.1, .buildsOn("add"))
    }

    func testDueBackAndCameBackLow() {
        let now = 30 * day
        let due = ["add": CheckRecord(last: 4, best: 4, date: now - 4 * day, due: now - day, passes: 1)]
        XCTAssertEqual(reason(due, now: now)?.1, .due)
        let low = ["add": CheckRecord(last: 2, best: 4, date: now - day, due: now + day, passes: 0)]
        XCTAssertEqual(reason(low, now: now)?.1, .low)
    }

    func testAZeroOrOneSendsTheChildToTheLessonUnderneath() {
        let now = 30 * day
        let checks = ["sub": CheckRecord(last: 1, best: 1, date: now - day, due: now + day, passes: 0),
                      "add": CheckRecord(last: 2, best: 4, date: now - 2 * day, due: now + day, passes: 0)]
        // add came back low too, and longer ago: it's picked to go over first
        XCTAssertEqual(reason(checks, now: now)?.0, "add")
        let stepped = ["sub": CheckRecord(last: 1, best: 1, date: now - day, due: now + day, passes: 0)]
        let pick = Mastery.upNext(lessons, depends: deps, checks: stepped, grade: 5, now: now)
        XCTAssertEqual(pick?.id, "add"); XCTAssertEqual(pick?.why, .stepBack)
        XCTAssertEqual(reason(stepped, now: now)?.1, .helps("sub"))
    }

    /// Me's tab on today's pick says Go over only for what Me's Go over shelf holds (Mastery.goOver), never for a lesson
    /// picked to help with one that came back low, or a test to take again on a lesson never learned: those are up next.
    func testTheTabSaysGoOverOnlyForWhatIsOnTheGoOverShelf() {
        let now = 30 * day
        func tab(_ checks: [String: CheckRecord]) -> (id: String, reason: Today.Reason, goOver: Bool, onShelf: Bool)? {
            guard let (id, why) = reason(checks, now: now) else { return nil }
            return (id, why, Mastery.goOver(checks, id, now: now), Mastery.shelves(lessons, checks: checks, now: now).goOver.contains(id))
        }
        // a 1 on Subtracting fractions, Adding fractions never opened: Adding fractions helps, and it's up next
        let helps = tab(["sub": CheckRecord(last: 1, best: 1, date: now - day, due: now + day, passes: 0)])
        XCTAssertEqual(helps?.id, "add"); XCTAssertEqual(helps?.reason, .helps("sub"))
        XCTAssertEqual(helps?.goOver, false); XCTAssertEqual(helps?.onShelf, false)
        // a lesson test that came back low on a lesson never learned: picked to take again, up next, on no shelf
        let low = tab(["add": CheckRecord(last: 2, best: 2, date: now - day, due: now - 1, passes: 0)])
        XCTAssertEqual(low?.id, "add"); XCTAssertEqual(low?.reason, .low)
        XCTAssertEqual(low?.goOver, false); XCTAssertEqual(low?.onShelf, false)
        // learned, its recheck came back low: Go over, as its shelf says
        let lowLearned = tab(["add": CheckRecord(last: 2, best: 4, date: now - day, due: now + day, passes: 0)])
        XCTAssertEqual(lowLearned?.reason, .low); XCTAssertEqual(lowLearned?.goOver, true); XCTAssertEqual(lowLearned?.onShelf, true)
        // learned and due back for its check: Go over
        let due = tab(["add": CheckRecord(last: 4, best: 4, date: now - 4 * day, due: now - day, passes: 1)])
        XCTAssertEqual(due?.reason, .due); XCTAssertEqual(due?.goOver, true); XCTAssertEqual(due?.onShelf, true)
        // a 1 on Adding and subtracting, and Subtracting fractions under it learned but its recheck came back low: it
        // helps, and it's on the Go over shelf, so its tab says Go over
        let helpsLearned = tab(["mix": CheckRecord(last: 1, best: 1, date: now - 3 * day, due: now + day, passes: 0),
                                "add": CheckRecord(last: 4, best: 4, date: now - 10 * day, due: now + 5 * day, passes: 1),
                                "sub": CheckRecord(last: 2, best: 4, date: now - day, due: now + day, passes: 0)])
        XCTAssertEqual(helpsLearned?.id, "sub"); XCTAssertEqual(helpsLearned?.reason, .helps("mix"))
        XCTAssertEqual(helpsLearned?.goOver, true); XCTAssertEqual(helpsLearned?.onShelf, true)
    }

    func testEverythingLearnedIsTheOldest() {
        let checks = Dictionary(uniqueKeysWithValues: lessons.enumerated().map { i, id in
            (id, CheckRecord(last: 4, best: 4, date: Double(i + 1), due: 1e9, passes: 1))
        })
        XCTAssertEqual(reason(checks)?.0, "add")
        XCTAssertEqual(reason(checks)?.1, .oldest)
    }
}

/// Days as a child counts them on a calendar, for "Check in 3 days".
final class CalendarDaysTests: XCTestCase {
    func testDaysAreCalendarDays() {
        let utc = TimeZone(identifier: "UTC")!, day = 86_400.0, h = 3600.0
        // 10pm on day 0
        let now = 22 * h
        XCTAssertEqual(Today.days(until: now + 3 * h, from: now, in: utc), 1, "three hours later, past midnight, is tomorrow")
        XCTAssertEqual(Today.days(until: 23.5 * h, from: now, in: utc), 0, "later today")
        XCTAssertEqual(Today.days(until: 3 * day + 16 * h, from: now, in: utc), 3)
        XCTAssertEqual(Today.days(until: 3 * day + 16 * h, from: 3 * day + 9 * h, in: utc), 0, "due later today")
        XCTAssertEqual(Today.days(until: now - day, from: now, in: utc), -1)
    }
}
