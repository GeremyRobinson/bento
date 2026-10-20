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
