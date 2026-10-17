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

    // where things sit, in paper points: the How to at the lesson's place, the problems in rows under it
    static let pitch = Size(560, 680), problemsTop: Double = 760

    init(piece: Piece, instant: Bool, first: AddFractions.Problem? = nil) {
        self.piece = piece; self.instant = instant
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        let example = first ?? AddFractions.problems.randomElement(using: &rng)!
        howTo = AddFractionsModel(origin: piece.at, chapter: piece.chapter, instant: instant,
                                  run: LessonRun(AddFractions.spec, numbers: example.numbers), label: "How to", auto: true)
        let page = LessonPage.problems(AddFractions.spec, using: &rng)
        var practice = 0, check = 0
        problems = page.enumerated().map { i, p in
            let label = p.isCheck ? "Skill check \(check + 1)" : "Problem \(practice + 1)"
            if p.isCheck { check += 1 } else { practice += 1 }
            let at = Point(piece.at.x + Double(i % LessonPage.columns) * Self.pitch.width,
                           piece.at.y + Self.problemsTop + Double(i / LessonPage.columns) * Self.pitch.height)
            return AddFractionsModel(origin: at, chapter: piece.chapter, instant: instant, run: LessonPage.run(AddFractions.spec, p), label: label)
        }
        for p in problems {
            p.onSolved = { [weak self] in self?.solvedOne() }
            p.needs = { [weak self] r in self?.frame?(r) }
        }
    }

    var all: [AddFractionsModel] { showing ? [howTo] + problems : [howTo] }
    var animating: Bool { all.contains { $0.animating } || playing }
    /// "3 of 16 done", for the top bar.
    var label: String { showing ? "\(problems.filter(\.solved).count) of \(problems.count) done" : "How to" }

    /// Everything on the page: what the camera shows when the problems arrive.
    var pageFrame: Rect {
        let rows = (problems.count + LessonPage.columns - 1) / LessonPage.columns
        return Rect(x: piece.at.x - 20, y: piece.at.y - 160, width: Double(LessonPage.columns) * Self.pitch.width,
                    height: Self.problemsTop + Double(rows) * Self.pitch.height)
    }

    // MARK: the How to, then the page

    private var playing = false

    /// The How to plays itself: the pieces grow in, each move is made for it, then its answer is written.
    func start() {
        howTo.start()
        frame?(howTo.contentFrame)
        play()
    }

    /// Watch the How to again: it starts over and plays, with the problems staying where they are.
    func watchAgain() {
        howTo.replay()
        frame?(howTo.contentFrame)
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
        frame?(firstRow)
    }

    /// The first row of problems, with their questions: where the child starts.
    var firstRow: Rect {
        Rect(x: piece.at.x - 20, y: piece.at.y + Self.problemsTop - 160, width: Double(LessonPage.columns) * Self.pitch.width, height: Self.pitch.height)
    }

    // MARK: what the child does

    /// A tap on the paper goes to the problem it landed in.
    func tap(_ p: Point) {
        for m in all where contains(m.contentFrame, p) { m.tapPaper(p); return }
    }

    /// The problem a point is in, so the camera can frame it.
    func problem(at p: Point) -> AddFractionsModel? { all.first { contains($0.contentFrame, p) } }

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
