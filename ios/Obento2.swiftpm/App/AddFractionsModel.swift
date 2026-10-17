import SwiftUI

/// Add with different bottoms, flat on the paper. The lesson logic lives in Core/AddFractions.swift; this keeps the timing:
/// when the pieces grew in and when each one was shaded. It never tilts, so the paper's own camera shows it.
@MainActor @Observable
final class AddFractionsModel {
    /// The picture's top-left, in paper points, on grid lines. Rows and labels are placed from here.
    let origin: Point
    let chapter: Chapter
    let instant: Bool
    private(set) var lesson: AddFractions
    private var rng: SeededRandom

    /// When the pieces started growing in.
    private(set) var openedAt: Double
    /// Each piece of the bottom row: how strongly it is filled (0 empty, 0.5 added, 1 shaded), the last value and when it changed.
    private(set) var fills: [Int: (from: Double, to: Double, at: Double)] = [:]
    private(set) var wordsAt: Double = PaperClock.now
    /// The dashed line showing where p/a ends, after a wrong count.
    private(set) var guideAt: Double?
    var message: (text: String, ok: Bool)?

    // where things sit, in paper points from `origin`
    static let row1: Double = 160, row2: Double = 280, barHeight: Double = 60

    init(origin: Point, chapter: Chapter, instant: Bool, problem: AddFractions.Problem? = nil) {
        self.origin = origin; self.chapter = chapter; self.instant = instant
        var r = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        lesson = problem.map { AddFractions(problem: $0) } ?? AddFractions.generate(using: &r)
        rng = r
        openedAt = instant ? PaperClock.now - 100 : PaperClock.now
    }

    /// The pieces grow in now (called when the glide to the lesson ends).
    func start() { openedAt = time(0); wordsAt = PaperClock.now }

    /// The lesson sits just inside its picture frame on the map.
    static func origin(for p: Piece) -> Point { Point(p.at.x, p.at.y) }

    var problem: AddFractions.Problem { lesson.problem }
    /// One piece of the bottom row, in points.
    var pieceWidth: Double { Double(problem.wholeCells) * Paper.cell / Double(problem.b) }
    var wholeWidth: Double { Double(problem.wholeCells) * Paper.cell }
    /// Where p/a ends along the rows.
    var coverEnd: Double { Double(problem.covered) * pieceWidth }
    /// The whole picture with its words and buttons: what opening the lesson frames.
    var frame: Rect { Rect(x: origin.x - 40, y: origin.y - 120, width: max(480, wholeWidth + 80), height: 660) }

    var animating: Bool {
        let now = PaperClock.now
        return now - openedAt < 2.2 || now - wordsAt < 0.8 || fills.values.contains { now - $0.at < 0.35 }
            || (guideAt.map { now - $0 < 0.6 } ?? false)
    }

    // MARK: what the child does

    func go() {
        switch lesson.go() {
        case .moved:
            guideAt = nil; message = nil; wordsAt = PaperClock.now
            syncFills()
        case .notYet(let line):
            message = (line, false)
            if lesson.step == .cover, guideAt == nil { guideAt = time(0) }
        case .newProblem: restart()
        }
    }

    func tap(_ i: Int) {
        guard lesson.tap(i) else { return }
        message = nil; syncFills()
    }

    /// A tap on the paper: which piece of the bottom row it landed on.
    func tapPaper(_ p: Point) {
        let x = p.x - origin.x, y = p.y - origin.y
        guard y >= Self.row2, y <= Self.row2 + Self.barHeight, x >= 0, x < wholeWidth else { return }
        tap(Int(x / pieceWidth))
    }

    func showMe() {
        let before = lesson.step == .cover ? lesson.shaded : lesson.added
        let filled = lesson.showMe()
        message = nil
        // what was there clears at once; the right pieces then fill one by one
        for i in before where !filled.contains(i) { setFill(i, 0, at: time(0)) }
        for (n, i) in filled.enumerated() { setFill(i, target(i), at: time(0.35 * Double(n + 1)), from: 0) }
    }

    func reset() { lesson.reset(); message = nil; guideAt = nil; syncFills() }

    private func restart() {
        lesson = AddFractions.generate(using: &rng)
        fills = [:]; guideAt = nil; message = nil
        openedAt = time(0); wordsAt = PaperClock.now
    }

    private func target(_ i: Int) -> Double { lesson.shaded.contains(i) ? 1 : lesson.added.contains(i) ? 0.5 : 0 }

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
