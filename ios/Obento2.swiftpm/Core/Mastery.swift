import Foundation

/// What the child has shown they know, ported from the web app (engine/mastery/skills.ts, app/today.ts, screens/Me.tsx).
/// Finishing a lesson only means they got through it with help; the skill check (4 problems, no hints, one try per step)
/// says "learned". A learned lesson comes back for a quick check after 3, 7, 21 and then 60 days, each pass pushing it
/// further out; a miss brings it back tomorrow. Plain rules a parent could follow, all worked out from what's saved.

/// A lesson's last skill check, and when it comes back.
public struct CheckRecord: Codable, Equatable, Sendable {
    /// 0 to 4: Not yet, Beginning, Approaching, Proficient, Advanced.
    public var last: Int
    public var best: Int
    /// When the check was done, and when the lesson should come back (seconds since 2001).
    public var date: Double
    public var due: Double
    /// Checks passed in a row: picks the next gap.
    public var passes: Int
    public init(last: Int, best: Int, date: Double, due: Double, passes: Int) {
        self.last = last; self.best = best; self.date = date; self.due = due; self.passes = passes
    }
}

public enum Mastery {
    public static let levels = ["Not yet", "Beginning", "Approaching", "Proficient", "Advanced"]
    /// A check of 3 or 4 means learned.
    public static let pass = 3
    /// Days until a passed lesson comes back, by how many passes in a row.
    public static let reviewDays = [3, 7, 21, 60]
    static let day = 86_400.0

    /// 4 at 90% of step points, 3 at 75%, 2 at 50%, 1 at 25%.
    public static func level(_ pct: Double) -> Int { pct >= 0.9 ? 4 : pct >= 0.75 ? 3 : pct >= 0.5 ? 2 : pct >= 0.25 ? 1 : 0 }

    /// A check's result, and when the lesson comes back.
    public static func record(_ old: CheckRecord?, level: Int, now: Double) -> CheckRecord {
        let passed = level >= pass, passes = passed ? (old?.passes ?? 0) + 1 : 0
        let days = passed ? reviewDays[min(passes, reviewDays.count) - 1] : 1
        return CheckRecord(last: level, best: max(level, old?.best ?? 0), date: now, due: now + Double(days) * day, passes: passes)
    }

    /// Learned: the last check was 3 or 4. Practice alone never counts.
    public static func learned(_ checks: [String: CheckRecord], _ id: String) -> Bool { (checks[id]?.last ?? -1) >= pass }
    /// Learned at some time (a check of 3 or 4, ever): what the map colours in and counts (G 20 Oct). A lesson that
    /// comes due, or whose recheck came back low, stays counted; the map marks it Go over instead of taking it away.
    public static func learnedEver(_ checks: [String: CheckRecord], _ id: String) -> Bool { (checks[id]?.best ?? -1) >= pass }
    /// Learned at some time, and its time to come back has come: 3, 7, 21 or 60 days after a pass, the day after a miss
    /// (a recheck that came back low comes back the next day, as a recheck). It opens on its recheck.
    public static func dueBack(_ checks: [String: CheckRecord], _ id: String, now: Double) -> Bool {
        guard let c = checks[id] else { return false }
        return c.best >= pass && c.due <= now
    }
    /// Learned as the child sees it: the last check was 3 or 4 and it isn't slipping (not due back yet).
    public static func learnedNow(_ checks: [String: CheckRecord], _ id: String, now: Double) -> Bool {
        learned(checks, id) && !dueBack(checks, id, now: now)
    }
    /// The last check came back low: the lesson is to go over.
    public static func toGoOver(_ checks: [String: CheckRecord], _ id: String) -> Bool { checks[id].map { $0.last < pass } ?? false }
    /// Go over (Me's shelf, the map's tab, G 20 Oct): a lesson learned at some time that's due back for its recheck, or
    /// whose last check (its recheck, or its test taken again) came back low. A lesson never learned isn't to go over,
    /// even after a test that came back low: its test is there to take again.
    public static func goOver(_ checks: [String: CheckRecord], _ id: String, now: Double) -> Bool {
        learnedEver(checks, id) && (dueBack(checks, id, now: now) || toGoOver(checks, id))
    }

    /// The grade a lesson belongs to: "g4-equiv" is 4th grade; ids without a grade are this grade's.
    public static func grade(of id: String, current: Int) -> Int {
        guard id.hasPrefix("g"), let dash = id.firstIndex(of: "-"), let g = Int(id.dropFirst().prefix(upTo: dash)) else { return current }
        return g
    }

    /// Ready to start: every lesson underneath is learned. A lesson from an earlier grade counts as learned until one of
    /// its checks comes back low, so a child who starts in 5th grade isn't sent back to 4th.
    public static func ready(_ id: String, depends: [String], checks: [String: CheckRecord], grade g: Int) -> Bool {
        depends.allSatisfy { d in grade(of: d, current: g) < g ? !toGoOver(checks, d) : learned(checks, d) }
    }

    /// Step back: after a check of 0 or 1, the main lesson underneath when it isn't learned, else any lesson underneath
    /// whose own check came back low.
    public static func stepBack(_ id: String, depends: [String], checks: [String: CheckRecord]) -> String? {
        guard let c = checks[id], c.last <= 1 else { return nil }
        if let main = depends.first, !learned(checks, main) { return main }
        return depends.dropFirst().first { toGoOver(checks, $0) }
    }

    /// The child's own page (Me): Go over (due back, or its last check came back low), Getting stronger (learned, on its
    /// way through the four checks), Know it (passed all four). A lesson moves right as its checks pass. Only lessons
    /// learned at some time are on a shelf, so the shelves add up to the learned count (G 20 Oct).
    public struct Shelves: Equatable, Sendable {
        public var goOver: [String] = [], gettingStronger: [String] = [], knowIt: [String] = []
    }
    public static func shelves(_ lessons: [String], checks: [String: CheckRecord], now: Double) -> Shelves {
        var s = Shelves()
        for id in lessons where learnedEver(checks, id) {
            if goOver(checks, id, now: now) { s.goOver.append(id) }
            else if (checks[id]?.passes ?? 0) < reviewDays.count { s.gettingStronger.append(id) } else { s.knowIt.append(id) }
        }
        return s
    }

    public enum Why: Sendable, Equatable { case goOver, stepBack, next, oldest }

    /// The lesson Today suggests, first match wins: (0) given `now`, a learned lesson due back for its recheck, the one
    /// due longest first; (1) to go over, the oldest first, or after a 0 or 1 the lesson underneath when it isn't
    /// solid; (2) next: a lesson that builds on the one learned last, when it's ready, else the first lesson in order
    /// not yet learned whose lessons underneath are, else the first not learned; (3) all learned: the one checked
    /// longest ago. `lessons` are the ready-to-open lessons in map order.
    public static func upNext(_ lessons: [String], depends: (String) -> [String], checks: [String: CheckRecord], grade g: Int, now: Double? = nil) -> (id: String, why: Why)? {
        if let now, let due = lessons.filter({ dueBack(checks, $0, now: now) }).min(by: { (checks[$0]?.due ?? 0) < (checks[$1]?.due ?? 0) }) {
            return (due, .goOver)
        }
        if let over = lessons.filter({ toGoOver(checks, $0) }).min(by: { (checks[$0]?.date ?? 0) < (checks[$1]?.date ?? 0) }) {
            if let back = stepBack(over, depends: depends(over), checks: checks), lessons.contains(back) { return (back, .stepBack) }
            return (over, .goOver)
        }
        let open = lessons.filter { !learned(checks, $0) }
        let latest = lessons.filter { learned(checks, $0) }.max { (checks[$0]?.date ?? 0) < (checks[$1]?.date ?? 0) }
        if let latest, let builds = open.first(where: { depends($0).contains(latest) }), ready(builds, depends: depends(builds), checks: checks, grade: g) {
            return (builds, .next)
        }
        if let fresh = open.first(where: { ready($0, depends: depends($0), checks: checks, grade: g) }) ?? open.first { return (fresh, .next) }
        return lessons.min { (checks[$0]?.date ?? 0) < (checks[$1]?.date ?? 0) }.map { ($0, .oldest) }
    }
}

/// A chapter's or the grade's test, as it last came out (G 20 Oct): problems right of how many, its score 0–4 (10 of 12
/// passes), and when. Taken again, the new result replaces it.
public struct TestRecord: Codable, Equatable, Sendable {
    public var level: Int
    public var right: Int
    public var of: Int
    /// Seconds since 2001.
    public var date: Double
    public var passed: Bool { level >= Mastery.pass }
    public init(level: Int, right: Int, of: Int, date: Double) { self.level = level; self.right = right; self.of = of; self.date = date }
    /// A finished test of `of` problems with `right` right, scored the one way every test is (LessonPlan.level).
    public init(right: Int, of: Int, date: Double) { self.init(level: LessonPlan.level(right, of: of), right: right, of: of, date: date) }
}
