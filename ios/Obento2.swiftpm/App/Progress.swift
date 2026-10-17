import Foundation

/// What the child has learned, kept on the device: each lesson's last skill check and when it comes back
/// (Core/Mastery.swift, the web app's rules). Learned = the last check scored 3 or 4 and it isn't due back yet.
@MainActor @Observable
final class Progress {
    static let shared = Progress()
    private(set) var checks: [String: CheckRecord]
    /// Screenshots set a fixed state and don't save it.
    var saving = true
    private static let key = "checks"

    init() {
        checks = (UserDefaults.standard.data(forKey: Self.key)).flatMap { try? JSONDecoder().decode([String: CheckRecord].self, from: $0) } ?? [:]
    }

    var now: Double { PaperClock.now }
    /// The lessons learned right now.
    var learned: Set<String> { Set(checks.keys.filter { Mastery.learnedNow(checks, $0, now: now) }) }
    func dueBack(_ id: String) -> Bool { Mastery.dueBack(checks, id, now: now) }

    /// A skill check (or recheck) is over: its score, and when the lesson comes back.
    func checked(_ id: String, level: Int) {
        checks[id] = Mastery.record(checks[id], level: level, now: now)
        if saving, let data = try? JSONEncoder().encode(checks) { UserDefaults.standard.set(data, forKey: Self.key) }
    }

    /// For screenshots: a learned lesson whose time to come back has come.
    func makeDue(_ id: String) {
        checks[id] = CheckRecord(last: 4, best: 4, date: now - 4 * 86_400, due: now - 60, passes: 1)
    }

    /// For screenshots: these lessons learned today with a 4.
    func reset(to ids: Set<String>) {
        checks = Dictionary(uniqueKeysWithValues: ids.map { ($0, Mastery.record(nil, level: 4, now: now)) })
    }
}
