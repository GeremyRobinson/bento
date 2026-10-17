import SwiftUI

/// One problem of Add with different bottoms, flat on the paper, live where it sits on the lesson's page (BarsPage).
/// The lesson logic lives in Core/AddFractions.swift; this keeps the timing: when the pieces grew in and when each one
/// was shaded. It never tilts, so the paper's own camera shows it.
@MainActor @Observable
final class AddFractionsModel: Identifiable {
    let id = UUID()
    /// What the page calls it: "How to", "Problem 3", "Skill check 1".
    let label: String
    /// The How to plays itself: no buttons, and its moves are made for it.
    let auto: Bool
    /// Told when the problem is solved.
    var onSolved: (() -> Void)?
    /// The picture's top-left, in paper points, on grid lines. Rows and labels are placed from here.
    let origin: Point
    let chapter: Chapter
    let instant: Bool
    private(set) var lesson: LessonRun

    /// When the pieces started growing in.
    private(set) var openedAt: Double
    /// Each piece of the bottom row: how strongly it is filled (0 empty, 0.5 added, 1 shaded), the last value and when it changed.
    private(set) var fills: [Int: (from: Double, to: Double, at: Double)] = [:]
    private(set) var wordsAt: Double = PaperClock.now
    /// The dashed line showing where p/a ends, after a wrong count.
    private(set) var guideAt: Double?
    var message: (text: String, ok: Bool)?
    /// Hands off until then: a See beat is playing (LESSONS.md §4).
    private(set) var busyUntil: Double = 0
    var busy: Bool { PaperClock.now < busyUntil }
    /// One See beat (m-beat).
    static let seeBeat = 0.75

    // where things sit, in paper points from `origin`
    static let row1: Double = 160, row2: Double = 280, barHeight: Double = 60

    init(origin: Point, chapter: Chapter, instant: Bool, run: LessonRun, label: String, auto: Bool = false) {
        self.origin = origin; self.chapter = chapter; self.instant = instant; self.label = label; self.auto = auto
        lesson = run
        openedAt = instant ? PaperClock.now - 100 : PaperClock.now + 1000
    }

    /// The pieces grow in, after `delay` (the page draws its problems in one after another).
    func start(after delay: Double = 0) { openedAt = time(delay); wordsAt = openedAt }
    var solved: Bool { lesson.isLast }

    /// The lesson sits just inside its picture frame on the map.
    static func origin(for p: Piece) -> Point { Point(p.at.x, p.at.y) }

    var problem: AddFractions.Problem { AddFractions.Problem(lesson.numbers) }
    /// One piece of the bottom row, in points.
    var pieceWidth: Double { Double(problem.wholeCells) * Paper.cell / Double(problem.b) }
    var wholeWidth: Double { Double(problem.wholeCells) * Paper.cell }
    /// Where p/a ends along the rows.
    var coverEnd: Double { Double(problem.covered) * pieceWidth }
    /// The whole picture with its words and buttons: what opening the lesson frames.
    var frame: Rect { contentFrame }

    /// What the lesson shows right now: the question (a story runs to more lines), the bars, the piece waiting to be added
    /// while it waits, and the buttons. The camera frames this at every step.
    var contentFrame: Rect {
        Self.contentFrame(origin: origin, problem: problem, storyLines: lesson.step.answer?.choices != nil ? 2 : 0,
                          waiting: lesson.picture["waiting"] == 1)
    }
    static func contentFrame(origin o: Point, problem s: AddFractions.Problem, storyLines: Int, waiting: Bool = false) -> Rect {
        let whole = Double(s.wholeCells) * Paper.cell, piece = whole / Double(s.b)
        // the question's line is about 480 points long; the bars as long as the whole, and the waiting piece past it
        let right = max(440, whole + (waiting ? 20 + piece : 0)), top = -70 - Double(storyLines) * 40
        return Rect(x: o.x - 10, y: o.y + top, width: right + 20, height: 490 - top)
    }
    /// Told when the lesson needs more room in view.
    var needs: ((Rect) -> Void)?

    var animating: Bool {
        let now = PaperClock.now
        return now - openedAt < 2.2 || now - wordsAt < 0.8 || fills.values.contains { now - $0.at < 0.35 } || now < busyUntil + 0.1 || (preview.map { now < $0.end + 0.1 } ?? false)
            || (guideAt.map { now - $0 < 0.6 } ?? false)
    }

    // MARK: what the child does

    func go() {
        guard !busy else { return }
        switch lesson.go() {
        case .moved:
            guideAt = nil; message = nil; wordsAt = PaperClock.now
            syncFills()
            // See: the pieces line up and the matching lines draw; hands off while they do
            busyUntil = time(Self.seeBeat)
            needs?(contentFrame)
            if lesson.isLast { onSolved?() }
        case .notYet(let line):
            message = (line, false)
            if lesson.hintLevel >= 1, guideAt == nil { guideAt = time(0) }
            // one try (the skill check): the right pieces are shown, so watch them fill
            if lesson.oneTry { syncFills(); busyUntil = time(Self.seeBeat) }
        case .newProblem: break  // a solved problem stays on the page, solved
        }
    }

    /// The How to's moves, made for it: the pieces the step needs fill one by one. Returns how long that takes.
    @discardableResult
    func demonstrate() -> Double {
        guard lesson.step.task != nil else { return 0 }
        let filled = lesson.showMe()
        for (n, i) in filled.enumerated() { setFill(i, target(i), at: time(0.35 * Double(n)), from: 0) }
        if lesson.step.answer?.choices != nil { lesson.choose(0) }
        return 0.35 * Double(filled.count) + 0.3
    }

    /// A pick-one step (the story's "Which operation solves it?"): the child taps choice i.
    func choose(_ i: Int) { guard !busy else { return }; lesson.choose(i); message = nil }

    func tap(_ i: Int) {
        guard !busy, lesson.tap(i) else { return }
        message = nil; syncFills()
    }

    /// A tap on the paper: which piece of the bottom row it landed on.
    func tapPaper(_ p: Point) {
        let x = p.x - origin.x, y = p.y - origin.y
        guard y >= Self.row2, y <= Self.row2 + Self.barHeight, x >= 0, x < wholeWidth else { return }
        tap(Int(x / pieceWidth))
    }

    /// Show me: a preview of the step. The right pieces fill one by one over the child's own, hold, and fade back.
    private(set) var preview: ShowMePreview?

    func showMe() {
        guard lesson.helps, !busy, let t = lesson.step.task else { return }
        let p = ShowMePreview(cells: t.showMe, at: time(0.2), step: 0.35)
        preview = p; previewStyle = t.style
        busyUntil = instant ? 0 : p.end
        message = nil
    }
    private var previewStyle = 1

    /// How a piece is filled with the preview over it: the stronger of the child's fill and the preview's.
    func shown(_ i: Int, at t: Double) -> Double {
        max(fill(i, at: t), (preview?.level(i, at: t) ?? 0) * (previewStyle == 2 ? 0.5 : 1))
    }

    func reset() { guard !busy else { return }; lesson.reset(); message = nil; guideAt = nil; syncFills() }

    /// Starts the problem over with the same numbers (the How to's Watch again).
    func replay() {
        var r = LessonRun(lesson.spec, numbers: lesson.numbers); r.helps = lesson.helps; r.oneTry = lesson.oneTry
        lesson = r
        fills = [:]; guideAt = nil; message = nil; preview = nil; busyUntil = 0
        openedAt = time(0); wordsAt = openedAt
    }

    /// Full for a piece shaded to cover p/a, lighter for one added on: each step says how strongly it marks.
    private func target(_ i: Int) -> Double {
        guard let by = lesson.marks[i] else { return 0 }
        return lesson.steps[by].task?.style == 2 ? 0.5 : 1
    }

    /// Every piece moves toward what the lesson says it is now.
    private func syncFills() {
        for i in 0..<problem.b where fill(i, at: PaperClock.now + 10) != target(i) { setFill(i, target(i), at: time(0)) }
    }

    private func setFill(_ i: Int, _ v: Double, at t: Double, from: Double? = nil) {
        fills[i] = (from ?? fill(i, at: PaperClock.now), v, t)
    }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }

    // MARK: read at a moment in time, for drawing

    /// How filled a piece of the bottom row is.
    func fill(_ i: Int, at t: Double) -> Double {
        guard let f = fills[i] else { return 0 }
        return f.from + (f.to - f.from) * ease((t - f.at) / 0.25)
    }

    /// How far a piece has grown in (0...1). Rows grow in left to right, the top row first.
    func grow(row: Int, _ i: Int, at t: Double) -> Double {
        ease((t - openedAt - (row == 0 ? 0.5 + Double(i) * 0.06 : 0.8 + Double(i) * 0.04)) / 0.4)
    }

    /// The "1 whole" line drawing itself in.
    func wholeLine(at t: Double) -> Double { ease((t - openedAt - 0.3) / 0.5) }

    func words(at t: Double) -> Double { ease((t - openedAt - 0.4) / 0.4) }

    func guide(at t: Double) -> Double { guideAt.map { ease((t - $0) / 0.4) } ?? 0 }
}
