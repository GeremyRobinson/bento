import Foundation

/// The grown-ups' This week (G's preview, design/prototype/grown-ups.html): what the child did lately, read in ten
/// seconds. Two things are recorded for it, on the iPad only, a day at a time: problems finished, and active time (the
/// app open on a lesson, the review or a test, with a finger on it now and then). The rest is worked out from what's
/// saved already (each lesson's checks, and which lessons were started). Everything here is plain rules, no drawing.

/// One day's practice: problems finished, and seconds of active time.
public struct DayRecord: Codable, Equatable, Sendable {
    public var problems: Int
    public var seconds: Double
    public init(problems: Int = 0, seconds: Double = 0) { self.problems = problems; self.seconds = seconds }
    /// Practised that day: a problem finished, or at least a minute spent on a lesson.
    public var practised: Bool { problems > 0 || seconds >= Week.minute }
}

/// Active time, counted from touch to touch while a lesson, the review or a test is open in the foreground. A gap
/// longer than two minutes without a touch isn't counted, so an iPad left open on a lesson doesn't run up the clock.
public struct ActiveClock: Equatable, Sendable {
    /// The longest gap between two touches that still counts.
    public static let gap = 120.0
    /// The last touch counted from (nil: stopped).
    public private(set) var last: Double?
    public init() {}

    /// A touch at `t`: the seconds since the last touch to count (0 for the first, or after a gap too long).
    public mutating func touch(at t: Double) -> Double {
        defer { last = max(t, last ?? t) }
        guard let l = last else { return 0 }
        let d = t - l
        return d > 0 && d <= Self.gap ? d : 0
    }
    /// The lesson closed or the app went into the background at `t`: up to then counts (if it's not too long since the
    /// last touch), and the clock stops until the next lesson.
    public mutating func stop(at t: Double) -> Double {
        let s = touch(at: t)
        last = nil
        return s
    }
}

public enum Week {
    static let day = 86_400.0
    public static let minute = 60.0
    /// How many days of records are kept (as reviews are).
    public static let keep = 60
    /// The days This week looks back over, today included.
    public static let days = 7

    // MARK: the day records

    /// The records with `problems` and `seconds` added to the day `t` falls on, and anything older than `keep` days
    /// dropped.
    public static func adding(_ records: [String: DayRecord], problems: Int = 0, seconds: Double = 0, at t: Double,
                              in zone: TimeZone = .current) -> [String: DayRecord] {
        var out = records
        let key = Review.day(t, in: zone)
        out[key, default: DayRecord()].problems += problems
        out[key, default: DayRecord()].seconds += seconds
        return pruned(out, now: t, in: zone)
    }
    /// Only the last `keep` days (today included).
    public static func pruned(_ records: [String: DayRecord], now: Double, in zone: TimeZone = .current) -> [String: DayRecord] {
        let kept = Set(lastDays(now: now, count: keep, in: zone))
        return records.filter { kept.contains($0.key) }
    }

    /// The last `count` days, oldest first, ending today: their keys (Review.day).
    public static func lastDays(now: Double, count: Int = days, in zone: TimeZone = .current) -> [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let today = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: now))
        return (0..<count).reversed().map { back in
            // noon of each day, so a clock change never lands two keys on one day
            let d = cal.date(byAdding: .day, value: -back, to: today)!.addingTimeInterval(12 * 3600)
            return Review.day(d.timeIntervalSinceReferenceDate, in: zone)
        }
    }
    /// The last 7 days' first letters, oldest first, ending today: "T W T F S S M".
    public static func letters(now: Double, in zone: TimeZone = .current) -> [String] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        cal.locale = Locale(identifier: "en_US")
        let today = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: now))
        return (0..<days).reversed().map { back in
            let d = cal.date(byAdding: .day, value: -back, to: today)!.addingTimeInterval(12 * 3600)
            return cal.veryShortStandaloneWeekdaySymbols[cal.component(.weekday, from: d) - 1]
        }
    }
    /// Which of the last 7 days were practised, oldest first.
    public static func practised(_ records: [String: DayRecord], now: Double, in zone: TimeZone = .current) -> [Bool] {
        lastDays(now: now, in: zone).map { records[$0]?.practised ?? false }
    }
    /// The last 7 days added up.
    public static func total(_ records: [String: DayRecord], now: Double, in zone: TimeZone = .current) -> DayRecord {
        lastDays(now: now, in: zone).reduce(into: DayRecord()) { sum, key in
            if let r = records[key] { sum.problems += r.problems; sum.seconds += r.seconds }
        }
    }

    // MARK: words

    /// "Mia has learned 9 of 17 lessons in 5th grade." or, with no name, "9 of 17 lessons learned in 5th grade."
    public static func headline(name: String, learned: Int, of total: Int, grade: Int) -> String {
        let g = Grades.name(grade)
        return name.isEmpty ? "\(learned) of \(total) lessons learned in \(g)." : "\(name) has learned \(learned) of \(total) lessons in \(g)."
    }
    /// "1 problem", "42 problems".
    public static func problems(_ n: Int) -> String { n == 1 ? "1 problem" : "\(n) problems" }
    /// About how long, in plain words: "less than a minute", "about 7 minutes", "about 1 hour 10 minutes" (to the
    /// nearest minute under 10 minutes, then to the nearest 5).
    public static func duration(_ seconds: Double) -> String {
        let m = Int((max(0, seconds) / minute).rounded())
        guard m >= 1 else { return "less than a minute" }
        let r = m < 10 ? m : Int((Double(m) / 5).rounded()) * 5
        let h = r / 60, mm = r % 60
        func mins(_ n: Int) -> String { n == 1 ? "1 minute" : "\(n) minutes" }
        if h == 0 { return "about \(mins(mm))" }
        let hours = h == 1 ? "1 hour" : "\(h) hours"
        return mm == 0 ? "about \(hours)" : "about \(hours) \(mins(mm))"
    }
    /// "4 of the last 7 days"
    public static func daysLine(_ practised: [Bool]) -> String { "\(practised.filter { $0 }.count) of the last \(practised.count) days" }
    /// When a check was, as a grown-up says it: "today", "yesterday", "on Tuesday" (this past week), else nil.
    public static func when(_ t: Double, now: Double, in zone: TimeZone = .current) -> String? {
        let ago = -Today.days(until: t, from: now, in: zone)
        if ago == 0 { return "today" }
        if ago == 1 { return "yesterday" }
        guard ago > 1, ago < days else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        cal.locale = Locale(identifier: "en_US")
        return "on " + cal.standaloneWeekdaySymbols[cal.component(.weekday, from: Date(timeIntervalSinceReferenceDate: t)) - 1]
    }

    // MARK: the lessons

    /// Where a lesson stands for its square: learned (at some time), started (a check, or its page begun), or not yet.
    public enum Standing: Equatable, Sendable { case learned, started, notYet }
    public static func standing(_ id: String, checks: [String: CheckRecord], started: Set<String>) -> Standing {
        if Mastery.learnedEver(checks, id) { return .learned }
        return checks[id] != nil || started.contains(id) ? .started : .notYet
    }

    /// Learned lessons whose check is due back within the next 7 days (or already), soonest first.
    public static func checksComing(_ lessons: [String], checks: [String: CheckRecord], now: Double) -> [String] {
        lessons.filter { id in Mastery.learnedEver(checks, id) && (checks[id]?.due ?? .infinity) <= now + Double(days) * day }
            .sorted { (checks[$0]?.due ?? 0) < (checks[$1]?.due ?? 0) }
    }

    /// Going well: lessons whose best and last checks are both 4 of 4 and that aren't due back, the most checks passed
    /// in a row first (then the latest), up to `most`.
    public static func goingWell(_ lessons: [String], checks: [String: CheckRecord], now: Double, most: Int = 3) -> [String] {
        let order = Dictionary(uniqueKeysWithValues: lessons.enumerated().map { ($1, $0) })
        return lessons.filter { id in
            guard let c = checks[id] else { return false }
            return c.last == 4 && c.best == 4 && !Mastery.dueBack(checks, id, now: now)
        }
        .sorted { a, b in
            let x = checks[a]!, y = checks[b]!
            if x.passes != y.passes { return x.passes > y.passes }
            if x.date != y.date { return x.date > y.date }
            return order[a]! < order[b]!
        }
        .prefix(most).map { $0 }
    }

    /// A lesson worth a grown-up's look, and why in a few words.
    public struct Look: Equatable, Sendable {
        public let id: String
        public let why: String
        public init(id: String, why: String) { self.id = id; self.why = why }
    }
    /// Worth a look: learned lessons whose last check came back low ("came back low on Tuesday"), then lessons tested
    /// and not learned yet ("started, 2 of 4 so far"), then lessons started and never tested ("started, no test yet");
    /// the latest first in each, up to `most`.
    public static func worthALook(_ lessons: [String], checks: [String: CheckRecord], started: Set<String>, now: Double,
                                  in zone: TimeZone = .current, most: Int = 3) -> [Look] {
        let latest: (String, String) -> Bool = { (checks[$0]?.date ?? 0) > (checks[$1]?.date ?? 0) }
        let low = lessons.filter { Mastery.learnedEver(checks, $0) && Mastery.toGoOver(checks, $0) }.sorted(by: latest)
            .map { id in Look(id: id, why: "came back low" + (when(checks[id]!.date, now: now, in: zone).map { " " + $0 } ?? "")) }
        let tested = lessons.filter { checks[$0] != nil && !Mastery.learnedEver(checks, $0) }.sorted(by: latest)
            .map { Look(id: $0, why: "started, \(checks[$0]!.last) of 4 so far") }
        let begun = lessons.filter { checks[$0] == nil && started.contains($0) }
            .map { Look(id: $0, why: "started, no test yet") }
        return Array((low + tested + begun).prefix(most))
    }

    /// Nothing at all to show yet: no lesson started or checked, and no practice recorded.
    public static func fresh(checks: [String: CheckRecord], started: Set<String>, records: [String: DayRecord]) -> Bool {
        checks.isEmpty && started.isEmpty && !records.values.contains { $0.problems > 0 || $0.seconds > 0 }
    }
    /// What This week says when there's nothing yet: "Nothing yet this week. Once Mia starts a lesson, it shows here."
    public static func empty(name: String) -> String {
        "Nothing yet this week. " + (name.isEmpty ? "Once a lesson is started, it shows here." : "Once \(name) starts a lesson, it shows here.")
    }
}
