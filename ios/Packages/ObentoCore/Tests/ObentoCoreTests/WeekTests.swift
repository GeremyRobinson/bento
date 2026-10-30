import XCTest
@testable import ObentoCore

/// The grown-ups' This week (Core/Week.swift): the day records, active time, and the lessons it picks out.
final class WeekTests: XCTestCase {
    let day = 86_400.0
    let utc = TimeZone(identifier: "UTC")!
    /// Thursday 29 October 2026, 15:00 UTC (seconds since 2001).
    let now: Double = {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = 29; c.hour = 15
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!.timeIntervalSinceReferenceDate
    }()

    // MARK: active time

    func testActiveTimeCountsFromTouchToTouch() {
        var clock = ActiveClock()
        XCTAssertEqual(clock.touch(at: 100), 0, "the first touch only starts the clock")
        XCTAssertEqual(clock.touch(at: 130), 30)
        XCTAssertEqual(clock.touch(at: 250), 120, "two minutes exactly still counts")
        XCTAssertEqual(clock.stop(at: 260), 10, "up to the lesson closing counts")
        XCTAssertNil(clock.last)
        XCTAssertEqual(clock.touch(at: 300), 0, "stopped: the next touch starts again")
    }

    func testAForgottenIPadDoesNotCount() {
        var clock = ActiveClock()
        _ = clock.touch(at: 0)
        XCTAssertEqual(clock.touch(at: 121), 0, "a gap over two minutes isn't counted")
        XCTAssertEqual(clock.touch(at: 141), 20, "but the clock carries on from the touch after it")
        XCTAssertEqual(clock.stop(at: 141 + 3600), 0, "left open an hour, then closed: nothing")
    }

    func testATouchBackInTimeCountsNothing() {
        var clock = ActiveClock()
        _ = clock.touch(at: 100)
        XCTAssertEqual(clock.touch(at: 90), 0)
        XCTAssertEqual(clock.touch(at: 110), 10, "it carries on from the latest touch")
    }

    // MARK: day records

    func testDayKeysAndTheLastSevenDays() {
        let days = Week.lastDays(now: now, in: utc)
        XCTAssertEqual(days, ["2026-10-23", "2026-10-24", "2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-29"])
        XCTAssertEqual(Week.letters(now: now, in: utc), ["F", "S", "S", "M", "T", "W", "T"])
    }

    func testAddingKeepsSixtyDays() {
        var r: [String: DayRecord] = [:]
        r = Week.adding(r, problems: 1, at: now - 70 * day, in: utc)
        r = Week.adding(r, problems: 2, at: now - 59 * day, in: utc)
        r = Week.adding(r, problems: 3, seconds: 40, at: now, in: utc)
        r = Week.adding(r, seconds: 30, at: now + 60, in: utc)
        XCTAssertEqual(r.count, 2, "70 days ago is dropped, 59 kept")
        XCTAssertEqual(r["2026-10-29"], DayRecord(problems: 3, seconds: 70))
        XCTAssertEqual(Week.pruned(r, now: now + 2 * day, in: utc).count, 1)
    }

    func testTheWeekAddsUpAndCountsDaysPractised() {
        var r: [String: DayRecord] = [:]
        r["2026-10-22"] = DayRecord(problems: 50, seconds: 3000)  // 8 days ago: not this week
        r["2026-10-23"] = DayRecord(problems: 10, seconds: 900)
        r["2026-10-26"] = DayRecord(problems: 0, seconds: 30)     // half a minute, no problem: not practised
        r["2026-10-27"] = DayRecord(problems: 0, seconds: 300)    // five minutes on a lesson: practised
        r["2026-10-29"] = DayRecord(problems: 6, seconds: 600)
        XCTAssertEqual(Week.practised(r, now: now, in: utc), [true, false, false, false, true, false, true])
        XCTAssertEqual(Week.daysLine(Week.practised(r, now: now, in: utc)), "3 of the last 7 days")
        XCTAssertEqual(Week.total(r, now: now, in: utc), DayRecord(problems: 16, seconds: 1830))
        XCTAssertEqual(Week.total([:], now: now, in: utc), DayRecord())
    }

    // MARK: words

    func testWords() {
        XCTAssertEqual(Week.headline(name: "Mia", learned: 9, of: 17, grade: 5), "Mia has passed 9 of 17 lessons in 5th grade.")
        XCTAssertEqual(Week.headline(name: "", learned: 9, of: 17, grade: 5), "9 of 17 lessons passed in 5th grade.")
        XCTAssertEqual(Week.problems(1), "1 problem")
        XCTAssertEqual(Week.problems(42), "42 problems")
        XCTAssertEqual(Week.duration(20), "less than a minute")
        XCTAssertEqual(Week.duration(7 * 60 + 10), "about 7 minutes")
        XCTAssertEqual(Week.duration(60), "about 1 minute")
        XCTAssertEqual(Week.duration(23 * 60), "about 25 minutes")
        XCTAssertEqual(Week.duration(60 * 60), "about 1 hour")
        XCTAssertEqual(Week.duration(71 * 60), "about 1 hour 10 minutes")
        XCTAssertEqual(Week.duration(2 * 3600 + 58 * 60), "about 3 hours")
        XCTAssertEqual(Week.empty(name: "Mia"), "Nothing yet this week.")
    }

    func testWhenACheckWas() {
        XCTAssertEqual(Week.when(now - 3600, now: now, in: utc), "today")
        XCTAssertEqual(Week.when(now - day, now: now, in: utc), "yesterday")
        XCTAssertEqual(Week.when(now - 2 * day, now: now, in: utc), "on Tuesday")
        XCTAssertEqual(Week.when(now - 6 * day, now: now, in: utc), "on Friday")
        XCTAssertNil(Week.when(now - 7 * day, now: now, in: utc), "a week ago or more: no day")
    }

    // MARK: the lessons

    func c(last: Int, best: Int? = nil, daysAgo: Double = 1, dueIn: Double = 5, passes: Int = 1) -> CheckRecord {
        CheckRecord(last: last, best: best ?? last, date: now - daysAgo * day, due: now + dueIn * day, passes: passes)
    }

    func testEachLessonsStanding() {
        let checks = ["a": c(last: 4), "b": c(last: 2), "d": c(last: 1, best: 4, passes: 0)]
        XCTAssertEqual(Week.standing("a", checks: checks, started: []), .learned)
        XCTAssertEqual(Week.standing("d", checks: checks, started: []), .learned, "learned once stays learned")
        XCTAssertEqual(Week.standing("b", checks: checks, started: []), .started, "tested, not learned")
        XCTAssertEqual(Week.standing("e", checks: checks, started: ["e"]), .started, "its page begun")
        XCTAssertEqual(Week.standing("f", checks: checks, started: []), .notYet)
    }

    func testChecksComingThisWeek() {
        let checks = ["a": c(last: 4, dueIn: 6.5), "b": c(last: 4, dueIn: -1), "x": c(last: 4, dueIn: 8),
                      "low": c(last: 2, dueIn: 1), "back": c(last: 1, best: 4, dueIn: 0.5, passes: 0)]
        XCTAssertEqual(Week.checksComing(["a", "b", "x", "low", "back"], checks: checks, now: now), ["b", "back", "a"],
                       "due already or within 7 days, soonest first; never learned isn't a check")
    }

    func testGoingWell() {
        let checks = ["a": c(last: 4, daysAgo: 1, passes: 1), "b": c(last: 4, daysAgo: 9, passes: 3), "c": c(last: 3, best: 4, passes: 2),
                      "d": c(last: 4, daysAgo: 2, passes: 1), "e": c(last: 4, daysAgo: 3, passes: 1), "due": c(last: 4, dueIn: -1, passes: 4)]
        let picked = Week.goingWell(["a", "b", "c", "d", "e", "due"], checks: checks, now: now)
        XCTAssertEqual(picked, ["b", "a", "d"], "4 of 4, not due back; most passes, then the latest; three at most")
        XCTAssertEqual(Week.goingWell(["c"], checks: checks, now: now), [])
    }

    func testWorthALook() {
        let checks = ["low": c(last: 1, best: 4, daysAgo: 2, passes: 0), "old": c(last: 2, best: 4, daysAgo: 12, passes: 0),
                      "tried": c(last: 2, daysAgo: 3, passes: 0), "fine": c(last: 4)]
        let looks = Week.worthALook(["fine", "old", "tried", "low", "begun"], checks: checks, started: ["begun", "fine"], now: now, in: utc)
        XCTAssertEqual(looks, [Week.Look(id: "low", why: "missed a check on Tuesday"), Week.Look(id: "old", why: "missed a check"),
                               Week.Look(id: "tried", why: "scored 2 of 4")])
        let more = Week.worthALook(["tried", "begun"], checks: checks, started: ["begun"], now: now, in: utc)
        XCTAssertEqual(more.map(\.why), ["scored 2 of 4", "no test yet"])
        XCTAssertEqual(Week.worthALook(["fine"], checks: checks, started: [], now: now, in: utc), [])
    }

    func testAFreshInstall() {
        XCTAssertTrue(Week.fresh(checks: [:], started: [], records: [:]))
        XCTAssertTrue(Week.fresh(checks: [:], started: [], records: ["2026-10-29": DayRecord()]))
        XCTAssertFalse(Week.fresh(checks: [:], started: ["a"], records: [:]))
        XCTAssertFalse(Week.fresh(checks: [:], started: [], records: ["2026-10-29": DayRecord(problems: 0, seconds: 5)]))
    }
}
