import Foundation

/// What the child has learned, kept on the device (Core/Mastery.swift, the web app's rules): each lesson's last skill
/// check and when it comes back, and each chapter or grade test's last result.
/// - Learned: a lesson test (or recheck) passed at some time. It stays learned when its recheck comes due: the count
///   never falls and the piece stays coloured; the map marks it Go over (G 20 Oct).
/// - Go over: due back for its recheck, or its last check came back low.
@MainActor @Observable
final class Progress {
    static let shared = Progress()
    private(set) var checks: [String: CheckRecord]
    /// Each chapter or grade test's last result: problems right of how many, and its score (10 of 12 passes).
    private(set) var tests: [String: TestRecord]
    /// Screenshots set a fixed state and don't save it.
    var saving = true
    private static let checksKey = "checks", testsKey = "test-results"

    init() {
        let d = UserDefaults.standard
        checks = d.data(forKey: Self.checksKey).flatMap { try? JSONDecoder().decode([String: CheckRecord].self, from: $0) } ?? [:]
        if let t = d.data(forKey: Self.testsKey).flatMap({ try? JSONDecoder().decode([String: TestRecord].self, from: $0) }) {
            tests = t
        } else {
            // before 20 Oct a test kept its level and, apart, how many were right: brought over once
            let levels = d.dictionary(forKey: "tests") as? [String: Int] ?? [:], right = d.dictionary(forKey: "testRight") as? [String: [Int]] ?? [:]
            tests = levels.reduce(into: [:]) { out, kv in
                let r = right[kv.key] ?? []
                out[kv.key] = TestRecord(level: kv.value, right: r.first ?? 0, of: r.count > 1 ? r[1] : LessonPlan.test, date: 0)
            }
        }
    }

    var now: Double { PaperClock.now }
    /// The lessons learned (at some time): what the map colours in and the bar counts.
    var learned: Set<String> { Set(checks.keys.filter { Mastery.learnedEver(checks, $0) }) }
    /// Learned, its time to come back has come: it opens on its recheck.
    func dueBack(_ id: String) -> Bool { Mastery.dueBack(checks, id, now: now) }
    /// Marked Go over on the map: due back, or its last check came back low.
    func goOver(_ id: String) -> Bool { Mastery.goOver(checks, id, now: now) }

    /// A lesson test or recheck is over: its score, and when the lesson comes back.
    func checked(_ id: String, level: Int) {
        checks[id] = Mastery.record(checks[id], level: level, now: now)
        save()
    }

    /// A chapter or grade test is over: how many of its problems came out right.
    func tested(_ id: String, right: Int, of total: Int) {
        tests[id] = TestRecord(right: right, of: total, date: now)
        save()
    }
    /// The test was passed (10 of 12 or better), the last time it was taken.
    func passed(_ id: String) -> Bool { tests[id]?.passed ?? false }

    private func save() {
        guard saving else { return }
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(checks) { d.set(data, forKey: Self.checksKey) }
        if let data = try? JSONEncoder().encode(tests) { d.set(data, forKey: Self.testsKey) }
    }

    // MARK: screenshots (never saved)

    /// These lessons learned today with a 4, these due back for their recheck, and these tests' results; nothing else.
    func reset(to ids: Set<String>, due: Set<String> = [], tests results: [String: Int] = [:]) {
        checks = Dictionary(uniqueKeysWithValues: ids.map { ($0, Mastery.record(nil, level: 4, now: now)) })
        for id in due { makeDue(id) }
        tests = results.mapValues { TestRecord(right: $0, of: LessonPlan.test, date: now) }
    }
    /// A learned lesson whose time to come back has come.
    func makeDue(_ id: String) {
        checks[id] = CheckRecord(last: 4, best: 4, date: now - 4 * 86_400, due: now - 60, passes: 1)
    }
}
