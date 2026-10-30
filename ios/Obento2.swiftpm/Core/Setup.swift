import Foundation

/// The child's own details, from setting up the first time the app opens (G 26 Oct, the front door): one child per
/// iPad, no profiles. Kept on the device (AppSettings saves it), read back however old the save is: a field it doesn't
/// have yet takes its plain default.
public struct Profile: Codable, Equatable, Sendable {
    /// The child's name, or "" when it was skipped (the paper then says "Me" and "Start here.").
    public var name: String
    /// Their grade: 0 is Kindergarten, 1 to 12 the grades. Only `Grades.live` has lessons yet.
    public var grade: Int
    /// Setting up is done: it never shows again (until a grown-up starts over).
    public var setUp: Bool
    /// The daily reminder a grown-up picked (Off unless they picked a time).
    public var reminder: Reminder

    public init(name: String = "", grade: Int = Grades.live, setUp: Bool = false, reminder: Reminder = .off) {
        self.name = name; self.grade = grade; self.setUp = setUp; self.reminder = reminder
    }

    /// As a brand-new install has it: nothing set up yet.
    public static let fresh = Profile()

    enum CodingKeys: String, CodingKey { case name, grade, setUp, reminder }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        name = Setup.cleanName((try? c.decode(String.self, forKey: .name)) ?? "")
        let g = (try? c.decode(Int.self, forKey: .grade)) ?? Grades.live
        grade = Grades.all.contains(g) ? g : Grades.live
        setUp = (try? c.decode(Bool.self, forKey: .setUp)) ?? false
        reminder = (try? c.decode(Reminder.self, forKey: .reminder)) ?? .off
    }

    /// Saved as a little JSON, and read back; anything unreadable is a fresh install.
    public var data: Data? { try? JSONEncoder().encode(self) }
    public static func read(_ data: Data?) -> Profile {
        guard let data, let p = try? JSONDecoder().decode(Profile.self, from: data) else { return .fresh }
        return p
    }
}

/// The daily reminder's times (G 26 Oct): after school, at tea, in the evening, or none.
public enum Reminder: String, Codable, CaseIterable, Sendable {
    case afterSchool = "15:30", tea = "16:00", evening = "18:00", off

    /// As the paper writes it.
    public var words: String {
        switch self { case .afterSchool: "3:30 pm"; case .tea: "4:00 pm"; case .evening: "6:00 pm"; case .off: "Off" }
    }
    /// Its time of day (24-hour), nil for Off.
    public var time: (hour: Int, minute: Int)? {
        guard self != .off else { return nil }
        let parts = rawValue.split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? (parts[0], parts[1]) : nil
    }
}

/// Kindergarten to 12th grade, as the grade blocks name them. Only 5th grade has lessons; the others are dead blocks
/// that say they're coming soon (no maps for them yet).
public enum Grades {
    public static let all = Array(0...12)
    /// The one grade with lessons.
    public static let live = 5
    public static func isLive(_ g: Int) -> Bool { g == live }

    /// On its block: K, 1, 2 … 12.
    public static func short(_ g: Int) -> String { g == 0 ? "K" : "\(g)" }
    /// In words: Kindergarten, 1st grade, 2nd grade, 3rd grade, 4th grade … 11th grade, 12th grade.
    public static func name(_ g: Int) -> String {
        guard g > 0 else { return "Kindergarten" }
        let teen = (11...13).contains(g % 100)
        let end = teen ? "th" : [1: "st", 2: "nd", 3: "rd"][g % 10] ?? "th"
        return "\(g)\(end) grade"
    }
    /// What the paper says when a grade block is tapped while setting up: "5th grade" or "3rd grade is coming soon".
    public static func picked(_ g: Int) -> String { onMe(g) }
    /// The same on Me and in Settings.
    public static func onMe(_ g: Int) -> String { isLive(g) ? name(g) : "\(name(g)) is coming soon" }
}

/// Setting up, the first time the app opens (G 26 Oct, front-door.html section 1): a welcome, the child's name (it can
/// be skipped), their grade, a grown-up's reminder and sound, then the map with "Start here" in their name.
public enum Setup {
    public enum Step: Int, CaseIterable, Sendable { case welcome, name, grade, grownUp }

    /// A name is a letter to a square on a line of this many squares.
    public static let nameLength = 12

    /// A typed name as it's kept: letters (any alphabet), spaces between words, hyphens and apostrophes; no space at
    /// either end or twice in a row; at most `nameLength` characters.
    public static func cleanName(_ s: String) -> String {
        var out = ""
        for ch in s {
            if ch.isLetter || ch == "-" || ch == "'" || ch == "’" { out.append(ch) }
            else if ch.isWhitespace, !out.isEmpty, out.last != " " { out.append(" ") }
            if out.count == nameLength { break }
        }
        while out.last == " " { out.removeLast() }
        return out
    }

    /// The note beside the first lesson on a fresh map: "Start here, Mia." or, with no name, "Start here."
    public static func startHere(_ name: String) -> String { name.isEmpty ? "Start here." : "Start here, \(name)." }
    /// The grade step's question: "Which grade, Mia?" or "Which grade?"
    public static func whichGrade(_ name: String) -> String { name.isEmpty ? "Which grade?" : "Which grade, \(name)?" }
    /// Me's title: the child's name, or "Me".
    public static func title(_ name: String) -> String { name.isEmpty ? "Me" : name }
}

/// A brand-new install looks untouched (G 26 Oct): nothing on the map looks started until the child starts. No count
/// that would say "0 of 3", no Up next tab, no test waiting in a dashed frame; each appears once there's something to
/// count or unlock.
public enum Fresh {
    /// Nothing started anywhere: no lesson checked, no test taken, no page of problems saved.
    public static func untouched(checks: [String: CheckRecord], tests: [String: TestRecord], pagesSaved: Bool) -> Bool {
        checks.isEmpty && tests.isEmpty && !pagesSaved
    }
    /// A chapter's "2 of 3" beside its title: once one of its lessons is learned.
    public static func showsCount(learned: Int) -> Bool { learned > 0 }
    /// A chapter's test on the map: once one of its lessons is learned (something to unlock), or once it's been started
    /// or taken.
    public static func showsChapterTest(learnedInChapter: Int, started: Bool) -> Bool { learnedInChapter > 0 || started }
    /// The grade's test: once a chapter test can be taken or has been, or once it's been started itself.
    public static func showsGradeTest(chapterTestsOpen: Int, started: Bool) -> Bool { chapterTestsOpen > 0 || started }
    /// The Up next tabs: once the child has started something.
    public static func showsTabs(untouched: Bool) -> Bool { !untouched }
    /// "Start here, Mia." beside the first lesson: once set up, until the child starts something.
    public static func showsStartHere(setUp: Bool, untouched: Bool) -> Bool { setUp && untouched }
}
