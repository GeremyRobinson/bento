import XCTest
@testable import ObentoCore

/// Setting up (Core/Setup.swift): the saved profile, the grades' words, the reminder's times, and what a fresh map
/// shows.
final class SetupTests: XCTestCase {
    func testAFreshInstallIsNotSetUp() {
        let p = Profile.fresh
        XCTAssertEqual(p.name, "")
        XCTAssertEqual(p.grade, 5)
        XCTAssertFalse(p.setUp)
        XCTAssertEqual(p.reminder, .off)
        // nothing saved reads as a fresh install, and so does anything unreadable
        XCTAssertEqual(Profile.read(nil), .fresh)
        XCTAssertEqual(Profile.read(Data("not json".utf8)), .fresh)
    }

    func testTheProfileIsSavedAndReadBack() {
        let p = Profile(name: "Mia", grade: 5, setUp: true, reminder: .tea)
        XCTAssertEqual(Profile.read(p.data), p)
        let skipped = Profile(name: "", grade: 5, setUp: true, reminder: .off)
        XCTAssertEqual(Profile.read(skipped.data), skipped)
    }

    func testAnOlderOrOddSaveStillReads() {
        // a save without some fields takes their defaults; a grade out of range is 5th; a name is cleaned
        XCTAssertEqual(Profile.read(Data(#"{"name":"Leo"}"#.utf8)), Profile(name: "Leo"))
        XCTAssertEqual(Profile.read(Data(#"{"grade":40,"setUp":true}"#.utf8)), Profile(grade: 5, setUp: true))
        XCTAssertEqual(Profile.read(Data(#"{"name":"  Ana  Lu 7!","reminder":"nope"}"#.utf8)), Profile(name: "Ana Lu"))
    }

    func testNamesAreALetterToASquare() {
        XCTAssertEqual(Setup.cleanName("  mia "), "mia")
        XCTAssertEqual(Setup.cleanName("Anne-Marie"), "Anne-Marie")
        XCTAssertEqual(Setup.cleanName("O'Neil"), "O'Neil")
        XCTAssertEqual(Setup.cleanName("Zoë"), "Zoë")
        XCTAssertEqual(Setup.cleanName("Mia  Rose"), "Mia Rose")
        XCTAssertEqual(Setup.cleanName("R2D2"), "RD")
        XCTAssertEqual(Setup.cleanName("Bartholomew the Great"), "Bartholomew")
        XCTAssertEqual(Setup.cleanName("Abcdefghijklmnop").count, Setup.nameLength)
        XCTAssertEqual(Setup.cleanName(""), "")
    }

    func testTheWordsUseTheNameOnlyWhenThereIsOne() {
        XCTAssertEqual(Setup.startHere("Mia"), "Start here, Mia.")
        XCTAssertEqual(Setup.startHere(""), "Start here.")
        XCTAssertEqual(Setup.whichGrade("Mia"), "Which grade, Mia?")
        XCTAssertEqual(Setup.whichGrade(""), "Which grade?")
        XCTAssertEqual(Setup.title("Mia"), "Mia")
        XCTAssertEqual(Setup.title(""), "Me")
    }

    func testGrades() {
        XCTAssertEqual(Grades.all.count, 13)
        XCTAssertEqual(Grades.all.map(Grades.short), ["K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"])
        XCTAssertEqual(Grades.all.filter(Grades.isLive), [5])
        XCTAssertEqual(Grades.name(0), "Kindergarten")
        XCTAssertEqual(Grades.name(1), "1st grade")
        XCTAssertEqual(Grades.name(2), "2nd grade")
        XCTAssertEqual(Grades.name(3), "3rd grade")
        XCTAssertEqual(Grades.name(4), "4th grade")
        XCTAssertEqual(Grades.name(11), "11th grade")
        XCTAssertEqual(Grades.name(12), "12th grade")
        XCTAssertEqual(Grades.picked(5), "5th grade it is.")
        XCTAssertEqual(Grades.picked(3), "3rd grade: coming soon.")
        XCTAssertEqual(Grades.picked(0), "Kindergarten: coming soon.")
        XCTAssertEqual(Grades.onMe(5), "5th grade.")
        XCTAssertEqual(Grades.onMe(8), "8th grade is coming soon.")
    }

    func testReminderTimes() {
        XCTAssertEqual(Reminder.allCases.map(\.words), ["3:30 pm", "4:00 pm", "6:00 pm", "Off"])
        XCTAssertEqual(Reminder.afterSchool.time?.hour, 15)
        XCTAssertEqual(Reminder.afterSchool.time?.minute, 30)
        XCTAssertEqual(Reminder.tea.time?.hour, 16)
        XCTAssertEqual(Reminder.evening.time?.hour, 18)
        XCTAssertNil(Reminder.off.time)
    }

    func testAFreshMapShowsNothingStarted() {
        let checks: [String: CheckRecord] = [:], tests: [String: TestRecord] = [:]
        let untouched = Fresh.untouched(checks: checks, tests: tests, pagesSaved: false)
        XCTAssertTrue(untouched)
        XCTAssertFalse(Fresh.showsTabs(untouched: untouched))
        XCTAssertFalse(Fresh.showsCount(learned: 0))
        XCTAssertFalse(Fresh.showsChapterTest(learnedInChapter: 0, started: false))
        XCTAssertFalse(Fresh.showsGradeTest(chapterTestsOpen: 0, started: false))
        // "Start here" waits for setting up to be done
        XCTAssertFalse(Fresh.showsStartHere(setUp: false, untouched: untouched))
        XCTAssertTrue(Fresh.showsStartHere(setUp: true, untouched: untouched))
    }

    func testThingsAppearOnceThereIsSomethingToCountOrUnlock() {
        // a page started: no longer untouched, so the tabs come and "Start here" goes
        let started = Fresh.untouched(checks: [:], tests: [:], pagesSaved: true)
        XCTAssertFalse(started)
        XCTAssertTrue(Fresh.showsTabs(untouched: started))
        XCTAssertFalse(Fresh.showsStartHere(setUp: true, untouched: started))
        // a check or a test result is something started too
        let checked = ["add": CheckRecord(last: 4, best: 4, date: 0, due: 1, passes: 1)]
        XCTAssertFalse(Fresh.untouched(checks: checked, tests: [:], pagesSaved: false))
        XCTAssertFalse(Fresh.untouched(checks: [:], tests: ["test-whole": TestRecord(right: 3, of: 12, date: 0)], pagesSaved: false))
        // counts and tests
        XCTAssertTrue(Fresh.showsCount(learned: 1))
        XCTAssertTrue(Fresh.showsChapterTest(learnedInChapter: 1, started: false))
        XCTAssertTrue(Fresh.showsChapterTest(learnedInChapter: 0, started: true))
        XCTAssertTrue(Fresh.showsGradeTest(chapterTestsOpen: 1, started: false))
        XCTAssertTrue(Fresh.showsGradeTest(chapterTestsOpen: 0, started: true))
    }
}
