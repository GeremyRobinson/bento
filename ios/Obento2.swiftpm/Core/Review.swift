import Foundation

/// The daily review (G's plan of 18 Oct, step 7; the web app's rules, engine/session/practice.ts): a few problems a
/// day from the lessons already checked, weighted to the weak and the old, one try each and no help, played as a page
/// of problems like a test. It's scored for the review only: it never changes what's learned, or when a lesson comes
/// back for its recheck (Mastery).
public enum Review {
    /// The problems in a review.
    public static let problems = 8
    /// A review draws from at least this many lessons.
    public static let fewest = 2
    /// At most this many problems from one lesson: 2, or 4 while there are only 2 or 3 lessons to draw from.
    public static func most(_ lessons: Int) -> Int { lessons >= 4 ? 2 : 4 }

    /// The lessons a review draws from, in the order given: every one that has had a check (a lesson test or a
    /// recheck), learned or not.
    public static func pool(_ lessons: [String], checks: [String: CheckRecord]) -> [String] { lessons.filter { checks[$0] != nil } }
    /// There's a review to take: at least 2 lessons have had a check.
    public static func ready(_ lessons: [String], checks: [String: CheckRecord]) -> Bool { pool(lessons, checks: checks).count >= fewest }

    /// How much a review wants a lesson: a weak last check counts most (5 less its score: 1 for a 4, 5 for a 0), growing
    /// by a third for every day since it was checked; a learned lesson that's due back for its recheck counts three
    /// times over.
    public static func weight(_ c: CheckRecord, now: Double) -> Double {
        let days = max(0, (now - c.date) / Mastery.day), due = c.best >= Mastery.pass && c.due <= now
        return Double(5 - min(4, max(0, c.last))) * (1 + days / 3) * (due ? 3 : 1)
    }

    /// A review's lessons, one for each problem: drawn by weight, at most `most` from one lesson, then spread so the
    /// same lesson never comes twice in a row when that can be helped. Empty when there's no review to take.
    public static func pick(_ lessons: [String], checks: [String: CheckRecord], now: Double, using rng: inout SeededRandom) -> [String] {
        let pool = pool(lessons, checks: checks)
        guard pool.count >= fewest else { return [] }
        let cap = most(pool.count)
        var taken: [String: Int] = [:], out: [String] = []
        while out.count < problems {
            let live = pool.filter { (taken[$0] ?? 0) < cap }
            guard !live.isEmpty else { break }
            let weights = live.map { weight(checks[$0]!, now: now) }
            var r = Double.random(in: 0..<weights.reduce(0, +), using: &rng), k = 0
            while k < live.count - 1, r >= weights[k] { r -= weights[k]; k += 1 }
            taken[live[k], default: 0] += 1
            out.append(live[k])
        }
        return spread(out, using: &rng)
    }

    /// The same lessons in an order where no lesson comes straight after itself, when that can be helped: each place
    /// takes the lesson with the most problems left that isn't the one just before (ties broken at random).
    public static func spread(_ ids: [String], using rng: inout SeededRandom) -> [String] {
        var left: [String: Int] = [:]
        for id in ids { left[id, default: 0] += 1 }
        let order = left.keys.sorted().shuffled(using: &rng)
        var out: [String] = []
        while out.count < ids.count {
            var best: String?
            for id in order where (left[id] ?? 0) > 0 && id != out.last {
                if best == nil || (left[id] ?? 0) > (left[best!] ?? 0) { best = id }
            }
            // only the lesson just used has problems left: it has to come again
            let next = best ?? order.first { (left[$0] ?? 0) > 0 }!
            left[next, default: 0] -= 1
            out.append(next)
        }
        return out
    }

    /// The review's problems, from its lessons: each a fresh problem from its lesson's check recipe, a lesson's second
    /// problem from the recipe's next item, no help and one try (as a test's are).
    public static func runs(_ specs: [LessonSpec], using rng: inout SeededRandom) -> [LessonRun] {
        var seen: [String: Int] = [:]
        return specs.compactMap { spec in
            let k = seen[spec.id, default: 0]
            seen[spec.id] = k + 1
            return LessonPlan.testRun([spec], k, using: &rng)
        }
    }

    /// The day a moment falls on, where the child is (a review is one a day): "2026-10-20".
    public static func day(_ t: Double, in zone: TimeZone = .current) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let c = cal.dateComponents([.year, .month, .day], from: Date(timeIntervalSinceReferenceDate: t))
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// A day's review as it came out: problems right of how many, when it was finished, and the lessons with a problem
/// missed (in the order they came). It's the review's own record: what's learned never reads it.
public struct ReviewRecord: Codable, Equatable, Sendable {
    public var right: Int
    public var of: Int
    /// Seconds since 2001.
    public var date: Double
    public var missed: [String]
    public init(right: Int, of: Int, date: Double, missed: [String]) { self.right = right; self.of = of; self.date = date; self.missed = missed }
}
