import Foundation

/// The floating bar as a calm smart pill (G chose it on 26 Oct: `design/prototype/front-door.html`, section 2, "Calm
/// (fewer words)"): icons for buttons, small squares for progress, and words only for the one thing most worth doing
/// right now. What the pill shows is worked out here from plain facts the app hands it, so it can be tested; the app
/// (`App/Toolbar.swift`) only draws it.
public enum Pill {
    // MARK: the middle, on the map (and on Me and the grown-ups' page)

    /// What the middle offers when no lesson is open.
    public enum Offer: Equatable, Sendable {
        /// "Go over · n": today's review, `left` of its problems still to do (it opens Today's review).
        case review(left: Int)
        /// "Go over · n": with today's review done (or none to take yet), the lessons due back for their recheck; the
        /// first opens on its recheck.
        case recheck(String, count: Int)
        /// "Continue →": the page the child was last working on, opened where they left it.
        case resume(String)
        /// Nothing to offer: the grade, plainly ("5th grade"). Tapping it shows the grades.
        case grade

        /// The words the middle says (the grade's name is the app's to give).
        public func words(grade: String) -> String {
            switch self {
            case .review(let n): "Go over · \(n)"
            case .recheck(_, let n): "Go over · \(n)"
            case .resume: "Continue →"
            case .grade: grade
            }
        }
    }

    /// A page the child has worked on: its lesson's (or test's) id, when it was last saved (seconds since 2001), and
    /// whether there's anything left to continue on it (a lesson learned, a test taken to the end: finished).
    public struct Page: Equatable, Sendable {
        public let id: String
        public let date: Double
        public let finished: Bool
        public init(id: String, date: Double, finished: Bool) { self.id = id; self.date = date; self.finished = finished }
    }

    /// The one most useful thing on the map now. A page worked on earlier today and not finished comes first: the child
    /// is mid-flow, so "Continue →". Otherwise what's due comes first (the web's rule, Mastery.upNext): today's review
    /// when it's there to take, else the lessons due back for their recheck; then the page last worked on that isn't
    /// finished (from another day); else nothing but the grade (a child who hasn't started a lesson yet).
    /// `reviewLeft`: today's review's problems still to do (nil: none to take today). `due`: lessons due back, in map
    /// order. `now` and `zone`: what "today" is, where the child is.
    public static func offer(reviewLeft: Int?, due: [String], pages: [Page], now: Double, zone: TimeZone = .current) -> Offer {
        let last = pages.filter { !$0.finished }.max { $0.date < $1.date }
        if let p = last, Review.day(p.date, in: zone) == Review.day(now, in: zone) { return .resume(p.id) }
        if let n = reviewLeft, n > 0 { return .review(left: n) }
        if let first = due.first { return .recheck(first, count: due.count) }
        if let p = last { return .resume(p.id) }
        return .grade
    }

    /// Today's review's problems still to do: none until there's a review to take (`ready`, Review.ready) or once it's
    /// done today; `partway` of them done already.
    public static func reviewLeft(ready: Bool, doneToday: Bool, partway: Int?) -> Int? {
        guard ready, !doneToday else { return nil }
        let n = Review.problems - (partway ?? 0)
        return n > 0 ? n : nil
    }

    // MARK: in a lesson

    /// What the open problem is doing, as the bar needs it.
    public struct Problem: Equatable, Sendable {
        /// A test, a recheck or the daily review (or a result): no help of any kind.
        public var inTest: Bool
        /// The How to playing itself.
        public var auto: Bool
        public var solved: Bool
        /// The step's last try was a miss (what it said is on the paper, red).
        public var missed: Bool
        /// A hand move is under way (a drag, a cut, a hop): the finger is down on the picture.
        public var moving: Bool
        public init(inTest: Bool = false, auto: Bool = false, solved: Bool = false, missed: Bool = false, moving: Bool = false) {
            self.inTest = inTest; self.auto = auto; self.solved = solved; self.missed = missed; self.moving = moving
        }
    }

    /// The buttons a lesson's pill shows beside its middle.
    public struct Tools: Equatable, Sendable {
        public var hint = false
        public var showMe = false
        /// After a miss, Show me is the thing most worth tapping: its icon and its word, ringed in the chapter's colour.
        public var showMeWord = false
        /// Solved: the middle is "Next →" (Hint and Show me fold away).
        public var next = false
        /// A hand move is under way: everything but its readout is dimmed.
        public var dim = false
        public init(hint: Bool = false, showMe: Bool = false, showMeWord: Bool = false, next: Bool = false, dim: Bool = false) {
            self.hint = hint; self.showMe = showMe; self.showMeWord = showMeWord; self.next = next; self.dim = dim
        }
    }

    /// The tools for the problem open now (nil: the page of problems, the How to's page, a result: back and ⋯ only).
    public static func tools(_ p: Problem?) -> Tools {
        guard let p, !p.auto else { return Tools() }
        var t = Tools(dim: p.moving)
        if p.solved { t.next = true; return t }
        // tests, rechecks and the review: no Hint or Show me (as before)
        guard !p.inTest else { return t }
        t.hint = true; t.showMe = true; t.showMeWord = p.missed
        return t
    }

    /// The problem's steps as squares (one per step the child does: a hand move, a number written, a pick), `done` of
    /// them filled. `work`: for each of the run's steps, whether the child does it; `index` the step it's on. Solved, all
    /// are filled.
    public static func steps(work: [Bool], index: Int, solved: Bool) -> (done: Int, of: Int) {
        let of = work.filter { $0 }.count
        if solved { return (of, of) }
        let done = work.prefix(max(0, min(index, work.count))).filter { $0 }.count
        return (min(done, of), of)
    }
    public static func steps(_ run: LessonRun) -> (done: Int, of: Int) {
        steps(work: run.steps.map { $0.task != nil || $0.answer != nil }, index: run.index, solved: run.isLast)
    }

    // MARK: first-use words

    /// For the child's first 3 sessions each icon has its word under it; in the 4th they show and then fade out; after
    /// that, a long press on an icon still shows its word.
    public enum Labels: Equatable, Sendable { case shown, fading, hidden }
    public static let labelSessions = 3
    public static func labels(session: Int) -> Labels {
        session <= labelSessions ? .shown : session == labelSessions + 1 ? .fading : .hidden
    }
    /// A new session: the app opened, or came back after this long away (30 minutes).
    public static let sessionGap: Double = 30 * 60
    public static func isNewSession(lastActive: Double?, now: Double) -> Bool {
        guard let last = lastActive else { return true }
        return now - last >= sessionGap
    }
}
