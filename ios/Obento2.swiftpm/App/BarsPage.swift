import SwiftUI

/// A lesson's page on the paper (G 17 Oct): first the How to, a worked example that plays itself; then all 16 problems
/// draw themselves onto the paper and every one is live right where it is, worked in any order, with nothing to go into.
/// The last row of 4 is the skill check (no hints, no Show me, one try), which decides learned.
/// This is Add with different bottoms' page; its problems are AddFractionsModel.
@MainActor @Observable
final class BarsPage {
    let piece: Piece
    let instant: Bool
    private(set) var howTo: AddFractionsModel
    private(set) var problems: [AddFractionsModel] = []
    /// The How to has played and the problems are on the paper.
    private(set) var showing = false
    /// Asks the camera to frame a part of the page.
    var frame: ((Rect) -> Void)?

    // where things sit, in paper points: the How to at the lesson's place, the problems in rows under it. The paper is
    // graph paper (G 17 Oct): every box starts and ends on the strong lines, 6 blocks wide and 8 tall, with one block
    // between boxes; inside, two cells of margin all round. Big enough for its largest content (a three-line story, the
    // widest bars and the piece waiting past them, the choices, the buttons and its name)
    static let box = (dx: -2 * Paper.cell, dy: -10 * Paper.cell, width: 6 * Paper.unit, height: 8 * Paper.unit), gap = Paper.unit
    static let pitch = Size(box.width + gap, box.height + gap)
    static let problemsTop = box.height + gap

    /// The How to's origin: its box's corner on the strong line at or before the lesson's place on the map.
    static func origin(for p: Piece) -> Point {
        Point(((p.at.x + box.dx) / Paper.unit).rounded(.down) * Paper.unit - box.dx, ((p.at.y + box.dy) / Paper.unit).rounded(.down) * Paper.unit - box.dy)
    }
    private var at: Point { Self.origin(for: piece) }

    /// A problem's box on the paper.
    static func box(of m: AddFractionsModel) -> Rect { Rect(x: m.origin.x + box.dx, y: m.origin.y + box.dy, width: box.width, height: box.height) }

    /// The problem the child is on: outlined in the chapter's colour, and what the camera frames.
    private(set) var current: AddFractionsModel?

    init(piece: Piece, instant: Bool, first: AddFractions.Problem? = nil) {
        self.piece = piece; self.instant = instant
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        let example = first ?? AddFractions.problems.randomElement(using: &rng)!
        howTo = AddFractionsModel(origin: Self.origin(for: piece), chapter: piece.chapter, instant: instant,
                                  run: LessonRun(AddFractions.spec, numbers: example.numbers), label: "How to", auto: true)
        let page = LessonPage.problems(AddFractions.spec, using: &rng)
        var practice = 0, check = 0
        problems = page.enumerated().map { i, p in
            let label = p.isCheck ? "Skill check \(check + 1)" : "Problem \(practice + 1)"
            if p.isCheck { check += 1 } else { practice += 1 }
            let o = Self.origin(for: piece)
            let at = Point(o.x + Double(i % LessonPage.columns) * Self.pitch.width,
                           o.y + Self.problemsTop + Double(i / LessonPage.columns) * Self.pitch.height)
            return AddFractionsModel(origin: at, chapter: piece.chapter, instant: instant, run: LessonPage.run(AddFractions.spec, p), label: label)
        }
        for p in problems {
            p.onSolved = { [weak self] in self?.solvedOne() }
            // the camera frames the problem's whole box, so where you are never shifts inside it
            p.needs = { [weak self, weak p] _ in if let p { self?.frame?(Self.box(of: p)) } }
            p.onTouch = { [weak self, weak p] in
                guard let self, let p, current !== p else { return }
                current = p; frame?(Self.box(of: p))
            }
        }
    }

    var all: [AddFractionsModel] { showing ? [howTo] + problems : [howTo] }
    var animating: Bool { all.contains { $0.animating } || playing }
    /// "3 of 16 done", for the top bar.
    var label: String { showing ? "\(problems.filter(\.solved).count) of \(problems.count) done" : "How to" }

    /// Everything on the page: what the camera shows when the problems arrive.
    var pageFrame: Rect {
        let rows = Double((problems.count + LessonPage.columns - 1) / LessonPage.columns)
        return Rect(x: at.x + Self.box.dx, y: at.y + Self.box.dy, width: Double(LessonPage.columns) * Self.pitch.width - Self.gap,
                    height: Self.problemsTop + rows * Self.pitch.height - Self.gap)
    }

    // MARK: the How to, then the page

    private var playing = false

    /// The How to plays itself: the pieces grow in, each move is made for it, then its answer is written.
    func start() {
        howTo.start()
        current = howTo
        frame?(Self.box(of: howTo))
        play()
    }

    /// Watch the How to again: it starts over and plays, with the problems staying where they are.
    func watchAgain() {
        howTo.replay()
        current = howTo
        frame?(Self.box(of: howTo))
        play()
    }

    private func play() {
        if instant { while !howTo.solved { howTo.demonstrate(); howTo.go() }; showProblems(); return }
        playing = true
        Task {
            func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
            await wait(2.2)                                   // the bars grow in; read the question
            while !howTo.solved {
                howTo.go(); await wait(1.4)                   // the next step's words come in, the See beat plays
                if howTo.solved { break }
                await wait(howTo.demonstrate() + 0.8)         // the move, made for it
            }
            await wait(1.6)                                   // read the answer
            playing = false
            if !showing { showProblems() }
        }
    }

    /// The problems draw themselves onto the paper, one after another, and the camera steps back to the first row.
    private func showProblems() {
        for (i, p) in problems.enumerated() { p.start(after: instant ? 0 : 0.3 + Double(i) * 0.12) }
        showing = true
        current = nil
        frame?(firstRow)
    }

    /// The first row of problems, with their questions: where the child starts.
    var firstRow: Rect {
        Rect(x: at.x + Self.box.dx, y: at.y + Self.problemsTop + Self.box.dy, width: Double(LessonPage.columns) * Self.pitch.width - Self.gap, height: Self.box.height)
    }

    // MARK: what the child does

    /// A tap on the paper goes to the problem it landed in.
    func tap(_ p: Point) {
        for m in all where contains(Self.box(of: m), p) { m.tapPaper(p); return }
    }

    /// The problem a point is in, so the camera can frame it.
    func problem(at p: Point) -> AddFractionsModel? { all.first { contains(Self.box(of: $0), p) } }

    /// A problem was solved: when the whole check row is done, its score decides learned (and when it comes back).
    private func solvedOne() {
        let checks = problems.filter { !$0.lesson.helps }
        if let level = LessonPage.checkLevel(checks.map(\.lesson)), !recorded {
            recorded = true
            Progress.shared.checked(AddFractions.spec.id, level: level)
        }
    }
    private var recorded = false

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}
