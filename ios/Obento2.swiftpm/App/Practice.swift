import Foundation

/// What the grown-ups' This week reads that wasn't saved before (Core/Week.swift): each day's problems finished and
/// active time, kept on this iPad only (UserDefaults, as Progress is), the last 60 days.
/// Active time runs while a lesson, the review or a test is open in the foreground, from touch to touch (a finger on the
/// paper, a button in the bar, a number typed); a gap of more than two minutes without a touch isn't counted
/// (ActiveClock), so an iPad left open on a lesson doesn't count.
@MainActor @Observable
final class Practice {
    static let shared = Practice()
    private(set) var days: [String: DayRecord]
    /// Bumped by each change, so a page drawing it knows to draw again.
    private(set) var version = 0
    /// Screenshots set a fixed state and don't save it.
    var saving = true
    private static let key = "practice-days"

    @ObservationIgnored private var clock = ActiveClock()
    /// A lesson, the review or a test is open, and the app is in the foreground.
    @ObservationIgnored private var lessonOpen = false
    @ObservationIgnored private var foreground = true
    /// Seconds counted and not saved yet (saved every half minute or so, and whenever a lesson closes).
    @ObservationIgnored private var pending = 0.0

    init() {
        days = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([String: DayRecord].self, from: $0) } ?? [:]
    }

    var now: Double { PaperClock.now }

    /// A lesson's page (or the review, or a test) opened: the clock starts.
    func opened() {
        lessonOpen = true
        if foreground { _ = clock.stop(at: now); _ = clock.touch(at: now) }
    }
    /// It closed: up to now counts, and the clock stops.
    func closed() {
        guard lessonOpen else { return }
        lessonOpen = false
        pending += clock.stop(at: now)
        flush()
    }
    /// The app went into the background (or came back): the clock stops, and starts again with a lesson still open.
    func setForeground(_ on: Bool) {
        guard on != foreground else { return }
        foreground = on
        if on { if lessonOpen { _ = clock.touch(at: now) } } else { pending += clock.stop(at: now); flush() }
    }
    /// A touch while a lesson is open.
    func touched() {
        guard lessonOpen, foreground else { return }
        pending += clock.touch(at: now)
        if pending >= 30 { flush() }
    }
    /// A problem finished (a lesson's, the review's or a test's).
    func problemDone() {
        touched()
        days = Week.adding(days, problems: 1, seconds: pending, at: now)
        pending = 0
        save()
    }

    /// Start over: every day forgotten.
    func forgetAll() {
        days = [:]; pending = 0; clock = ActiveClock()
        save()
    }

    private func flush() {
        guard pending > 0 else { return }
        days = Week.adding(days, seconds: pending, at: now)
        pending = 0
        save()
    }
    private func save() {
        version += 1
        guard saving, let data = try? JSONEncoder().encode(days) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }

    // MARK: screenshots (never saved)

    /// The last days as a screenshot wants them: `problems[i]` and `minutes[i]` on the day `i` days ago.
    func setForShots(problems: [Int], minutes: [Double]) {
        days = [:]
        for (i, n) in problems.enumerated() {
            let t = now - Double(i) * 86_400
            days[Review.day(t)] = DayRecord(problems: n, seconds: (i < minutes.count ? minutes[i] : 0) * 60)
        }
        version += 1
    }
}
