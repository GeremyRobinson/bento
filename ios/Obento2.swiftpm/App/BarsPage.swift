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
    // graph paper (G 17 Oct): every box starts and ends on the strong lines, 6 blocks wide and 9 tall, with one block
    // between boxes; inside, two cells of margin all round. Big enough for its largest content (a three-line story, the
    // widest bars and the piece waiting past them, the choices, the buttons and its name)
    static let box = (dx: -2 * Paper.cell, dy: -10 * Paper.cell, width: 6 * Paper.unit, height: 8 * Paper.unit), gap = Paper.unit
    static let pitch = Size(box.width + gap, box.height + gap)
    /// The problems take the How to's place once it has erased itself (G 17 Oct).
    static let problemsTop = 0.0

    /// The How to's origin: its box's corner on the lesson's frame corner on the map, on the strong lines.
    static func origin(for p: Piece) -> Point {
        Point((p.at.x / Paper.unit).rounded() * Paper.unit - box.dx, (p.at.y / Paper.unit).rounded() * Paper.unit - box.dy)
    }
    private var at: Point { Self.origin(for: piece) }

    /// A problem's box on the paper.
    static func box(of m: AddFractionsModel) -> Rect { Rect(x: m.origin.x + box.dx, y: m.origin.y + box.dy, width: box.width, height: box.height) }

    /// The problem the child is on: outlined in the chapter's colour, and what the camera frames.
    private(set) var current: AddFractionsModel?

    /// The page as the child left it, if they stopped partway (nil for a fresh page).
    let saved: PageStore.Saved?

    /// A chapter or grade test: this many problems, every one a check (no hints, one try), and no How to.
    let test: Int?

    init(piece: Piece, instant: Bool, first: AddFractions.Problem? = nil, saved: PageStore.Saved? = nil, test: Int? = nil) {
        self.piece = piece; self.instant = instant; self.saved = saved; self.test = test
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        let example = first ?? AddFractions.problems.randomElement(using: &rng)!
        // coming back after a day or more, the How to is a quick reminder the child can skip
        let remind = saved.map { !Calendar.current.isDateInToday($0.date) } ?? false
        howTo = AddFractionsModel(origin: Self.origin(for: piece), chapter: piece.chapter, instant: instant,
                                  run: LessonRun(AddFractions.spec, numbers: example.numbers), label: "How to", auto: true)
        let spec = AddFractions.spec
        let fresh: [LessonRun] = test.map { n in
            // a test draws from the lessons' own check recipes, mixed (only Add with different bottoms is built so far)
            (0..<n).map { i in
                let item = spec.check.isEmpty ? CheckItem(3) : spec.check[i % spec.check.count]
                return LessonPage.run(spec, LessonPage.Problem(numbers: item.draw(spec, using: &rng), story: item.story && spec.story != nil, isCheck: true))
            }
        } ?? LessonPage.problems(spec, using: &rng).enumerated().map { i, p in Self.run(p, row: i / LessonPage.columns, i: i, piece: piece) }
        let runs: [LessonRun] = saved?.problems.map { LessonRun(spec, restoring: $0) } ?? fresh
        var practice = 0, check = 0
        problems = runs.enumerated().map { i, run in
            let label = test != nil ? "Question \(i + 1)" : run.oneTry ? "Skill check \(check + 1)" : run.guided ? "Problem \(practice + 1) · together" : "Problem \(practice + 1)"
            if run.oneTry { check += 1 } else { practice += 1 }
            let o = Self.origin(for: piece)
            let at = Point(o.x + Double(i % LessonPage.columns) * Self.pitch.width,
                           o.y + Self.problemsTop + Double(i / LessonPage.columns) * Self.pitch.height)
            let m = AddFractionsModel(origin: at, chapter: piece.chapter, instant: instant, run: run, label: label)
            if saved != nil { m.restoreFills() }
            return m
        }
        recorded = saved?.recorded ?? false
        for p in problems {
            p.onChange = { [weak self] in self?.save() }
            p.onSolved = { [weak self] in self?.solvedOne() }
            // the camera frames the problem's whole box, so where you are never shifts inside it
            p.needs = { [weak self, weak p] _ in if let p { self?.frame?(Self.box(of: p)) } }
            p.onTouch = { [weak self, weak p] in if let p { self?.activate(p) } }
        }
    }

    /// Help fades across the page (G 18 Oct): row 1 is done together for its first two problems, then every step
    /// named with hints; row 2 hints stop at the first one; row 3 asks for the final answer only (a miss brings the
    /// steps back); row 4 is the skill check. A lesson already learned starts without the together problems.
    static func run(_ p: LessonPage.Problem, row: Int, i: Int, piece: Piece) -> LessonRun {
        if p.isCheck { return LessonPage.run(AddFractions.spec, p) }
        var r = LessonRun(AddFractions.spec, numbers: p.numbers, story: p.story, finalOnly: row == 2)
        r.guided = i < 2 && !Progress.shared.learned.contains(piece.id)
        r.hintCap = row == 0 ? 3 : 1
        r.skipAsk()
        return r
    }

    /// Clean work on the practice so far: four problems solved with no miss can go straight to the skill check.
    var canSkipToCheck: Bool {
        !problems.prefix(12).contains { $0.lesson.oneTry } && problems.prefix(12).filter { $0.solved && !$0.lesson.missedAny }.count >= 4
            && problems.suffix(4).contains { !$0.solved }
    }
    func skipToCheck() { if let m = problems.suffix(4).first(where: { !$0.solved }) { activate(m) } }

    /// The How to has played and erased itself.
    private(set) var howToGone = false
    var all: [AddFractionsModel] { howToGone ? problems : [howTo] }
    var animating: Bool { all.contains { $0.animating } || playing || building }
    /// The scene still has problems' bars or words to make, a few a frame: the clock keeps running until they're all
    /// made (stopped, a page that arrived without moving, or a switch to dark, left some boxes empty or the old colour).
    /// Set by the scene, only when it changes, so the clock (which watches it) starts and stops with it.
    private(set) var building = false
    func setBuilding(_ b: Bool) { if building != b { building = b } }
    /// "3 of 16 done", for the top bar.
    var label: String { showing ? "\(problems.filter(\.solved).count) of \(problems.count) done" : "How to" }
    /// "Fractions test" or the lesson's name, for the bar.
    var title: String { piece.name }

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
        // a test has no How to
        if test != nil { howToGone = true; showProblems(); return }
        // back the same day: straight to the problem they were on, no How to
        if let s = saved, Calendar.current.isDateInToday(s.date) {
            howToGone = true
            showProblems()
            return
        }
        howTo.start()
        current = howTo
        frame?(Self.box(of: howTo))
        play()
    }

    /// Watch the How to again (in More): the problems step aside, it plays where they were, and they come back.
    func watchAgain() {
        guard howToGone, !playing else { return }
        resumeAt = current.flatMap { c in problems.firstIndex { $0 === c } }
        for p in problems { p.leave() }
        playing = true
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            howTo.replay(); howToGone = false; showing = false
            current = howTo; frame?(Self.box(of: howTo))
            play()
        }
    }

    /// A tap while the How to plays: the next step when it's being taught, the end of it when it's a reminder.
    func skipHowTo() {
        guard playing, !howToGone else { return }
        if reminding { skipping = true } else { pressed = howTo.howToButtons.first ?? .next }
    }
    /// The How to's block the child pressed, while it waits for one.
    private var pressed: ProblemLayout.Kind?
    /// Coming back after a day or more: the How to replays on its own, and a tap skips it.
    private var reminding: Bool { saved.map { !Calendar.current.isDateInToday($0.date) } ?? false }

    /// The How to taught a tap at a time (G 18 Oct): why it works, then each step's words and its move, waiting for the
    /// child before going on.
    private func teach() {
        Task {
            @MainActor func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
            /// Shows these blocks and waits for one to be pressed.
            @MainActor func ask(_ blocks: [ProblemLayout.Kind]) async -> ProblemLayout.Kind {
                pressed = nil; howTo.howToButtons = blocks
                while pressed == nil { await wait(0.1) }
                howTo.howToButtons = []
                defer { pressed = nil }
                return pressed!
            }
            while true {
                howTo.intro = AddFractions.spec.idea(howTo.lesson.numbers)
                await wait(1.2); _ = await ask([.next])                 // the bars grow in; read why
                howTo.intro = nil
                while !howTo.solved {
                    howTo.go()                                          // the next step's words
                    if howTo.solved { break }
                    await wait(1.0)
                    await wait(howTo.demonstrate() + 0.4)               // its move, made for it
                    _ = await ask([.next])
                }
                // the answer stays until the child chooses: practise, or watch it all again
                await wait(0.6)
                if await ask([.practise, .again]) == .practise { break }
                howTo.replay(); await wait(0.4)
            }
            howTo.leave(); await wait(0.6)
            howToGone = true
            playing = false
            showProblems()
        }
    }
    private var skipping = false
    /// The problem to come back to after the How to.
    private var resumeAt: Int?

    private func play() {
        if instant { while !howTo.solved { howTo.demonstrate(); howTo.go() }; howToGone = true; showProblems(); return }
        playing = true
        // the first time it's taught a tap at a time, idea first; coming back it plays itself as a reminder
        if !reminding { teach(); return }
        howTo.howToButtons = [.skip]
        Task {
            func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
            skipping = false
            @MainActor func pause(_ s: Double) async { var t = 0.0; while t < s, !skipping { await wait(0.1); t += 0.1 } }
            await pause(2.2)                                  // the bars grow in; read the question
            while !howTo.solved && !skipping {
                howTo.go(); await pause(1.4)                  // the next step's words come in, the See beat plays
                if howTo.solved || skipping { break }
                await pause(howTo.demonstrate() + 0.8)        // the move, made for it
            }
            if !skipping { await pause(1.6) }                 // read the answer
            howTo.howToButtons = []
            howTo.leave(); await wait(0.6)                    // it erases itself, as it drew itself in
            howToGone = true
            playing = false
            showProblems()
        }
    }

    /// The problems draw themselves onto the paper where the How to was, one after another, and the camera steps back
    /// to the first row.
    private func showProblems() {
        for (i, p) in problems.enumerated() { p.start(after: instant ? 0 : 0.05 + Double(i) * 0.12) }
        showing = true
        // where they were: the problem they were on when they left, or before watching the How to again
        let back = resumeAt ?? saved?.current
        resumeAt = nil
        if let i = back, problems.indices.contains(i) {
            current = problems[i]; frame?(Self.box(of: problems[i]))
        } else {
            current = nil
            frame?(firstRow)
        }
    }

    /// The first row of problems, with their questions: where the child starts.
    var firstRow: Rect {
        Rect(x: at.x + Self.box.dx, y: at.y + Self.problemsTop + Self.box.dy, width: Double(LessonPage.columns) * Self.pitch.width - Self.gap, height: Self.box.height)
    }

    // MARK: what the child does

    /// Leaving the lesson: every problem erases itself, as it drew in.
    func leave() { for m in all { m.leave() } }

    /// The problem being worked: outlined in the chapter's colour with its Now tab, and framed by the camera.
    func activate(_ m: AddFractionsModel) {
        guard current !== m else { return }
        current = m; frame?(Self.box(of: m))
        save()
    }

    /// A tap on the paper goes to the problem it landed in, anywhere in its box, which becomes the one being worked;
    /// on one of its blocks (ProblemLayout) or its bars, it does that too.
    func tap(_ p: Point) {
        // while the How to plays, only its blocks do anything
        if playing && !howToGone {
            if let b = ProblemLayout.blocks(howTo).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
                switch b.kind { case .skip: skipping = true; case .next, .practise, .again: pressed = b.kind; default: break }
            }
            return
        }
        guard let m = all.first(where: { contains(Self.box(of: $0), p) }) else { return }
        if !m.auto { activate(m) }
        if let b = ProblemLayout.blocks(m).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
            switch b.kind {
            case .next, .practise: pressed = b.kind
            case .again: pressed = .again
            case .skip: skipping = true
            case .main: m.go()
            case .showMe: m.showMe()
            case .reset: m.reset()
            case .choice(let i): m.choose(i)
            }
            return
        }
        m.tapPaper(p)
    }

    /// The problem a point is in, so the camera can frame it.
    func problem(at p: Point) -> AddFractionsModel? { all.first { contains(Self.box(of: $0), p) } }

    /// A problem was solved: when the whole check row is done, its score decides learned (and when it comes back).
    private func solvedOne() {
        if test != nil {
            if let level = LessonPage.testLevel(problems.map(\.lesson)), !recorded {
                recorded = true
                Progress.shared.tested(piece.id, level: level, right: problems.filter { !$0.lesson.missedAny }.count, of: problems.count)
            }
            save(); return
        }
        let checks = problems.filter { !$0.lesson.helps }
        if let level = LessonPage.checkLevel(checks.map(\.lesson)), !recorded {
            recorded = true
            Progress.shared.checked(AddFractions.spec.id, level: level)
        }
        save()
    }

    /// The page is saved after every change; a page with every problem solved is done, and the next visit is fresh.
    private func save() {
        guard !instant, howToGone else { return }
        if problems.allSatisfy(\.solved) { PageStore.clear(piece.id); return }
        PageStore.save(piece.id, .init(date: Date(), problems: problems.map(\.lesson.snapshot),
                                       current: current.flatMap { c in problems.firstIndex { $0 === c } },
                                       recorded: recorded, solved: problems.filter(\.solved).count))
    }
    private var recorded = false

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

/// Each lesson page's work, saved on the device as the child goes (G 18 Oct): stop anywhere and come back to it.
@MainActor
enum PageStore {
    struct Saved: Codable {
        var date: Date
        var problems: [RunSnapshot]
        var current: Int?
        var recorded: Bool
        /// Problems solved, for the map's "Not finished · 5 of 16".
        var solved: Int
    }
    /// Bumped on every save, so the map's words know to change.
    private(set) static var version = 0
    private static func key(_ id: String) -> String { "page-\(id)" }

    static func load(_ id: String) -> Saved? {
        guard let d = UserDefaults.standard.data(forKey: key(id)) else { return nil }
        return try? JSONDecoder().decode(Saved.self, from: d)
    }
    static func save(_ id: String, _ s: Saved) {
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key(id)); version += 1 }
    }
    static func clear(_ id: String) { UserDefaults.standard.removeObject(forKey: key(id)); version += 1 }
}
