import Foundation

/// Today on Me (G's plan of 18 Oct, step 7): today's pick (Mastery.upNext) and why it was picked, so the paper can say
/// it in plain words.
public enum Today {
    /// Why today's pick was picked, with the lesson it's about where there is one.
    public enum Reason: Equatable, Sendable {
        /// Learned, and its time to come back for a check has come.
        case due
        /// Its last check came back low.
        case low
        /// A check of 0 or 1 on that lesson: this one, underneath it, comes first.
        case helps(String)
        /// It builds on that lesson, the one learned last.
        case buildsOn(String)
        /// Nothing is learned yet: the first lesson that's ready.
        case first
        /// The next lesson that's ready, in order.
        case next
        /// Everything is learned: the one checked longest ago.
        case oldest
    }

    /// How many days from `now` to `t`, as the child counts them on a calendar: 0 today, 1 tomorrow (a check due at 4pm
    /// three days on is "in 3 days" whatever the time now). Less than 0 when `t` has passed.
    public static func days(until t: Double, from now: Double, in zone: TimeZone = .current) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = zone
        let a = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: now)), b = cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: t))
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// The reason for a pick made by Mastery.upNext, worked out the same way it was picked.
    public static func reason(_ pick: (id: String, why: Mastery.Why), lessons: [String], depends: (String) -> [String],
                              checks: [String: CheckRecord], now: Double) -> Reason {
        switch pick.why {
        case .goOver: return Mastery.dueBack(checks, pick.id, now: now) ? .due : .low
        case .stepBack:
            // the lesson that came back low, which this one is underneath
            let over = lessons.filter { Mastery.toGoOver(checks, $0) && depends($0).contains(pick.id) }
                .min { (checks[$0]?.date ?? 0) < (checks[$1]?.date ?? 0) }
            return over.map { .helps($0) } ?? .low
        case .next:
            let learned = lessons.filter { Mastery.learned(checks, $0) }
            guard let latest = learned.max(by: { (checks[$0]?.date ?? 0) < (checks[$1]?.date ?? 0) }) else { return .first }
            return depends(pick.id).contains(latest) ? .buildsOn(latest) : .next
        case .oldest: return .oldest
        }
    }
}
