import SwiftUI

/// A lesson's page on the paper (G 19 Oct). First the How to, a worked example taught a tap at a time. Then the page of
/// problems to choose from, drawn as cards: 3 done together, 6 on their own (a miss brings a fresh one aimed at it), and
/// the lesson's test (LessonPlan). Choosing one draws the page out and that problem in, alone and as big as its maths
/// needs; the bar's "Problems" draws it out and the page back in. A chapter or grade test's page is its questions.
/// Its problems are AddFractionsModel (Add with different bottoms) or WorkProblem (every other lesson).
@MainActor @Observable
final class BarsPage {
    enum Mode { case howTo, choose, work }

    let piece: Piece
    let instant: Bool
    private(set) var howTo: any PageProblem
    /// The lesson's problems in the plan's order (together, then own), or a chapter test's questions.
    private(set) var problems: [any PageProblem] = []
    /// The lesson test being taken (12), if one is started.
    private(set) var testProblems: [any PageProblem] = []
    private(set) var plan: LessonPlan?
    private(set) var mode: Mode = .howTo
    /// The page of problems is up (or a problem from it is open): the How to is over.
    var showing: Bool { mode != .howTo }
    /// Asks the camera to frame a part of the page.
    var frame: ((Rect) -> Void)?

    // graph paper (G 17 Oct): every box starts and ends on the strong lines, with whole blocks between. The How to and
    // the problem being worked sit at the lesson's place, a square 8 blocks each way, or bigger when its maths needs it
    static let box = (dx: -2 * Paper.cell, dy: -10 * Paper.cell, width: 8 * Paper.unit, height: 8 * Paper.unit), gap = Paper.unit
    /// The cards on the page of problems, the lesson thumbnails' size (G 19 Oct): a frame 3 blocks by 2 with its name
    /// in the block under it, a block apart, 3 to a row.
    static let card = Size(3 * Paper.unit, 2 * Paper.unit), columns = 3

    /// The How to's origin: its box's corner on the lesson's frame corner on the map, on the strong lines.
    static func origin(for p: Piece) -> Point {
        Point((p.at.x / Paper.unit).rounded() * Paper.unit - box.dx, (p.at.y / Paper.unit).rounded() * Paper.unit - box.dy)
    }
    private var at: Point { Self.origin(for: piece) }
    /// The page's corner, where the How to's box, the cards and the open problem's box all start.
    private var corner: Point { Point(at.x + Self.box.dx, at.y + Self.box.dy) }

    /// A problem's box on the paper: as big as it needs.
    static func box(of m: any PageProblem) -> Rect {
        let s = m.boxSize
        return Rect(x: m.origin.x + box.dx, y: m.origin.y + box.dy, width: s.width, height: s.height)
    }

    /// The problem being worked (or the How to while it plays).
    private(set) var current: (any PageProblem)?
    /// A problem drawing itself out as the page comes back.
    private var leaving: (any PageProblem)?
    /// When the cards last drew in, and when they started drawing out.
    private(set) var cardsAt: Double = 0
    private(set) var cardsGoneAt: Double?

    /// The page as the child left it, if they stopped partway (nil for a fresh page).
    let saved: PageStore.Saved?

    /// A chapter or grade test: this many questions, every one no help and one try, and no How to.
    let test: Int?

    /// The lesson this page teaches (a test's first lesson, for its How to that it never plays).
    let spec: LessonSpec
    private let specs: [LessonSpec]
    private var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))

    init(piece: Piece, instant: Bool, first: Numbers? = nil, saved: PageStore.Saved? = nil, test: Int? = nil) {
        self.piece = piece; self.instant = instant; self.saved = saved; self.test = test
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        // a test mixes every lesson of its chapter that's built as a page (the grade's test, every chapter's)
        let specs = test != nil ? Map.testSpecs(piece) : [Lessons.spec(piece.id) ?? AddFractions.spec]
        let spec = specs.first ?? AddFractions.spec
        self.spec = spec; self.specs = specs
        let o = Self.origin(for: piece)
        howTo = Self.make(spec, origin: o, chapter: piece.chapter, instant: instant,
                          run: LessonRun(spec, numbers: first ?? spec.generate(&rng, 0)), label: "How to", auto: true)
        if let n = test {
            // a test draws from the lessons' own check recipes, in turn
            let runs: [LessonRun] = saved.map { s in s.problems.enumerated().map { i, r in LessonRun(specs[i % specs.count], restoring: r) } } ?? (0..<n).map { i in
                let sp = specs[i % specs.count], k = i / specs.count
                let item = sp.check.isEmpty ? CheckItem(3) : sp.check[k % sp.check.count]
                return LessonPage.run(sp, LessonPage.Problem(numbers: item.draw(sp, using: &rng), story: item.story && sp.story != nil, isCheck: true))
            }
            problems = runs.enumerated().map { i, r in Self.make(r.spec, origin: o, chapter: piece.chapter, instant: instant, run: r, label: "Question \(i + 1)") }
        } else {
            let plan = saved?.plan ?? LessonPlan(spec, using: &rng)
            let runs = saved.map { s in s.problems.map { LessonRun(spec, restoring: $0) } } ?? plan.items.indices.map { plan.run(spec, $0) }
            problems = runs.indices.map { make(practice: $0, run: runs[$0], plan: plan) }
            testProblems = (saved?.test ?? []).enumerated().map { i, r in
                Self.make(spec, origin: o, chapter: piece.chapter, instant: instant, run: LessonRun(spec, restoring: r), label: "Test question \(i + 1)")
            }
            self.plan = plan
        }
        self.rng = rng
        recorded = saved?.recorded ?? false
        for p in problems + testProblems { wire(p) }
        if saved != nil { for p in problems + testProblems { p.restore() } }
    }

    /// Problem `i` of the lesson, its label from its part of the plan.
    private func make(practice i: Int, run: LessonRun, plan: LessonPlan) -> any PageProblem {
        let it = plan.items[i]
        let k = plan.items[...i].filter { $0.part == it.part }.count
        let label = it.part == .together ? "Together \(k)" : "On your own \(k)"
        let m = Self.make(spec, origin: at, chapter: piece.chapter, instant: instant, run: run, label: label)
        (m as? WorkProblem)?.focus = it.focus
        return m
    }

    private func wire(_ p: any PageProblem) {
        p.onChange = { [weak self] in self?.save() }
        p.onSolved = { [weak self, weak p] in if let p { self?.solved(p) } }
        // the camera frames the problem's whole box, so where you are never shifts inside it
        p.needs = { [weak self, weak p] _ in if let p { self?.frame?(Self.box(of: p)) } }
        p.onTouch = {}
    }

    /// The problem a lesson's page holds: the fraction bars for Add with different bottoms, else typed steps with
    /// the lesson's picture.
    static func make(_ spec: LessonSpec, origin: Point, chapter: Chapter, instant: Bool, run: LessonRun, label: String, auto: Bool = false) -> any PageProblem {
        spec.master == "bars"
            ? AddFractionsModel(origin: origin, chapter: chapter, instant: instant, run: run, label: label, auto: auto)
            : WorkProblem(origin: origin, chapter: chapter, instant: instant, run: run, label: label, auto: auto)
    }

    /// The How to has played and erased itself.
    private(set) var howToGone = false
    /// What's drawn on the paper now: the How to, the open problem, and one drawing itself out.
    var all: [any PageProblem] {
        if !howToGone { return [howTo] }
        return [current, leaving].compactMap { $0 }
    }
    var animating: Bool { all.contains { $0.animating } || playing || building || PaperClock.now - cardsAt < 1.2 || cardsGoneAt.map { PaperClock.now - $0 < 0.8 } ?? false }
    /// The scene still has problems' bars or words to make, a few a frame: the clock keeps running until they're all
    /// made. Set by the scene, only when it changes, so the clock (which watches it) starts and stops with it.
    private(set) var building = false
    func setBuilding(_ b: Bool) { if building != b { building = b } }

    /// For the bar: "4 of 9" on the page, the problem's place while one is open.
    var label: String {
        guard showing else { return "How to" }
        if let c = current, mode == .work {
            if let i = testProblems.firstIndex(where: { $0 === c }) { return "Test \(i + 1) of \(testProblems.count)" }
            return c.label
        }
        return "\(problems.filter(\.solved).count) of \(problems.count) done"
    }
    var progress: Double {
        let list = mode == .work && testProblems.contains(where: { $0 === current }) ? testProblems : problems
        return list.isEmpty ? 0 : Double(list.filter(\.solved).count) / Double(list.count)
    }
    /// "Fractions test" or the lesson's name, for the bar.
    var title: String { piece.name }

    // MARK: the page of problems

    struct Card {
        enum State { case open, now, done, missed, locked }
        /// The problem it opens: an index into `problems`, or nil for the lesson's test.
        let index: Int?
        let rect: Rect
        let title: String
        let display: MathLine?
        let line: String
        let state: State
    }

    /// The lesson's test is open once 6 own problems are right.
    var testOpen: Bool { plan?.testOpen(problems.map(\.lesson)) ?? false }
    /// The test's result, once all 12 are done.
    var testResult: (right: Int, level: Int)? { LessonPlan.testScore(testProblems.map(\.lesson)) }

    /// The cards: a heading row for each part, the cards under it.
    var cards: [Card] { layout().cards }
    /// The words over each part of the page.
    var headings: [(Point, String)] { layout().headings }

    private func layout() -> (cards: [Card], headings: [(Point, String)]) {
        // the problems in a grid of 3 columns (G 19 Oct), each part under its heading and stacked under the one before:
        // Together's 3 in a row, then On your own in rows of 3; the Test off to the side, at the top
        var out: [Card] = [], heads: [(Point, String)] = []
        let w = Self.card.width, h = Self.card.height, g = Self.gap, x0 = corner.x
        var y = corner.y + Paper.unit
        func part(_ heading: String, _ items: [Int], columns: Int = Self.columns) {
            heads.append((Point(x0, y - Paper.unit / 2), heading))
            for (k, i) in items.enumerated() {
                let r = Rect(x: x0 + Double(k % columns) * (w + g), y: y + Double(k / columns) * (h + Paper.unit), width: w, height: h)
                let m = problems[i], l = m.lesson
                let state: Card.State = m.solved ? (l.missedAny && !l.helps ? .missed : .done) : m === lastWorked ? .now : .open
                let done = l.steps.indices.filter { $0 < l.index && (l.steps[$0].answer != nil || l.steps[$0].task != nil) }.count
                let line = m.solved ? (l.missedAny ? (l.helps ? "Done, with a miss" : "Missed") : "Done") : done > 0 ? "\(done) of \(l.workSteps) steps" : focusLine(m)
                out.append(Card(index: i, rect: r, title: m.label, display: l.display, line: line, state: state))
            }
            y += Double((items.count + columns - 1) / columns) * (h + Paper.unit) + g
        }
        if let n = test {
            part("\(n) questions, one try each", Array(problems.indices), columns: 4)
            return (out, heads)
        }
        guard let plan else { return (out, []) }
        let top = y
        part("Together", plan.items.indices.filter { plan.items[$0].part == .together })
        part("On your own · \(plan.ownRight(problems.map(\.lesson))) of \(LessonPlan.own) right", plan.items.indices.filter { plan.items[$0].part == .own })
        let tx = x0 + Double(Self.columns) * (w + g) + g
        heads.append((Point(tx, top - Paper.unit / 2), "Test"))
        let started = testProblems.contains { $0.lesson.index > 0 || $0.solved }
        let (line, state): (String, Card.State) = {
            if let res = testResult { return res.right >= LessonPlan.pass ? ("Passed · \(res.right) of 12. Take it again", .done) : ("\(res.right) of 12. Take it again", .missed) }
            if !testOpen { return ("Get 6 right on your own first", .locked) }
            if started { return ("\(testProblems.filter(\.solved).count) of 12 done", .now) }
            return ("12 problems, no help", .open)
        }()
        out.append(Card(index: nil, rect: Rect(x: tx, y: top, width: w, height: h), title: "Lesson test", display: nil, line: line, state: state))
        return (out, heads)
    }

    /// The problem worked last, marked Now on its card.
    private var lastWorked: (any PageProblem)?

    private func focusLine(_ m: any PageProblem) -> String {
        (m as? WorkProblem)?.focus != nil ? "Practice the part you missed" : "Not started"
    }

    /// The page of problems, all of it: what the camera shows.
    var pageFrame: Rect {
        let cs = cards
        guard let first = cs.first else { return Self.box(of: howTo) }
        var minX = first.rect.x, minY = corner.y, maxX = 0.0, maxY = 0.0
        for c in cs { minX = min(minX, c.rect.x); maxX = max(maxX, c.rect.x + c.rect.width); maxY = max(maxY, c.rect.y + c.rect.height) }
        // the names under the last row too
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY + Paper.unit - minY)
    }
    var firstRow: Rect { pageFrame }

    /// How far the cards have drawn in.
    func cardsShown(at t: Double) -> Double {
        guard showing else { return 0 }
        let inK = ease((t - cardsAt) / 0.5)
        let out = cardsGoneAt.map { 1 - ease((t - $0) / 0.4) } ?? 1
        return min(inK, out)
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
        howTo.start(after: 0)
        current = howTo
        frame?(Self.box(of: howTo))
        play()
    }

    /// Watch the How to again (in More): the page steps aside, it plays where it was, and the page comes back.
    func watchAgain() {
        guard howToGone, !playing else { return }
        if mode == .work, let c = current { c.leave(); leaving = c }
        cardsGoneAt = PaperClock.now
        playing = true
        Task {
            try? await Task.sleep(for: .seconds(0.55))
            leaving = nil
            howTo.replay(); howToGone = false; mode = .howTo
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
                howTo.intro = spec.idea(howTo.lesson.numbers)
                await wait(1.2); _ = await ask([.next])                 // the picture grows in; what to do
                // the lesson's own explaining beats: why the numbers do what they do
                for beat in howTo.howToBeats() {
                    howTo.intro = beat.words; beat.run()
                    await wait(1.0); _ = await ask([.next])
                }
                (howTo as? WorkProblem)?.endBeats()
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

    /// After the How to: the page of problems draws itself in, or, back the same day, the problem they were on.
    private func showProblems() {
        if let i = saved?.current, saved?.inTest == false, problems.indices.contains(i), !problems[i].solved, Calendar.current.isDateInToday(saved!.date), current == nil {
            open(problems[i]); return
        }
        current = nil
        mode = .choose
        cardsAt = instant ? PaperClock.now - 100 : PaperClock.now + 0.05; cardsGoneAt = nil
        frame?(pageFrame)
    }

    // MARK: what the child does

    /// Leaving the lesson: what's on the paper erases itself, as it drew in.
    func leave() { for m in all { m.leave() }; if mode == .choose { cardsGoneAt = PaperClock.now } }

    /// A problem opens: the page draws out, and it draws in alone where the How to was. The camera frames what it
    /// draws (contentChanged).
    func open(_ m: any PageProblem) {
        if mode == .work, let c = current, c !== m { c.leave(); leaving = c; clearLeaving(c) }
        if mode == .choose { cardsGoneAt = PaperClock.now }
        mode = .work
        if leaving === m { leaving = nil }
        current = m; lastWorked = m; framed = nil
        m.start(after: instant ? 0 : 0.4)
        save()
    }

    /// What the scene says the open problem (or the How to) has on the paper now: the camera eases to fit it when it
    /// grows or shrinks by more than a square or so.
    func contentChanged(_ r: Rect) {
        // only while a problem is open or the How to plays: a late word from either mustn't pull the camera off the page
        guard mode == .work || (mode == .howTo && !howToGone) else { return }
        if let f = framed, abs(f.x - r.x) < 30, abs(f.y - r.y) < 30, abs(f.width - r.width) < 30, abs(f.height - r.height) < 30 { return }
        framed = r
        frame?(r)
    }
    private var framed: Rect?

    /// The bar's "Problems": the problem draws out and the page draws back in.
    func backToProblems() {
        guard mode == .work, let c = current else { return }
        c.leave(); leaving = c; clearLeaving(c)
        current = nil; framed = nil
        mode = .choose
        cardsAt = instant ? PaperClock.now - 100 : PaperClock.now + 0.35; cardsGoneAt = nil
        frame?(pageFrame)
        save()
    }

    private func clearLeaving(_ c: any PageProblem) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.6))
            if let self, self.leaving === c { self.leaving = nil }
        }
    }

    /// "Next problem" on a solved one: the next one not done yet, in order; when there's none, back to the page.
    func goNext() {
        guard let c = current else { return }
        let list = testProblems.contains(where: { $0 === c }) ? testProblems : problems
        let i = list.firstIndex { $0 === c } ?? 0
        let next = (list[(i + 1)...] + list[..<i]).first { !$0.solved }
        // a lesson's own problems stop at the test: that's chosen from the page
        if let n = next { open(n) } else { backToProblems() }
    }

    /// The test's card: a fresh test (or the next question of the one started).
    func openTest() {
        guard testOpen else { return }
        if testProblems.isEmpty || testResult != nil {
            testProblems = LessonPlan.testRuns(spec, using: &rng).enumerated().map { i, r in
                Self.make(spec, origin: at, chapter: piece.chapter, instant: instant, run: r, label: "Test question \(i + 1)")
            }
            testProblems.forEach(wire)
            recorded = false
        }
        if let m = testProblems.first(where: { !$0.solved }) { open(m) }
    }

    /// A tap on the paper: on the page, the card it lands on opens; in a problem, the block it lands on.
    func tap(_ p: Point) {
        // while the How to plays, only its blocks do anything
        if playing && !howToGone {
            if let b = ProblemLayout.blocks(howTo).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
                switch b.kind { case .skip: skipping = true; case .next, .practise, .again: pressed = b.kind; default: break }
            }
            return
        }
        if mode == .choose {
            guard let c = cards.first(where: { contains($0.rect, p) }) else { return }
            if let i = c.index { open(problems[i]) } else { openTest() }
            return
        }
        guard let m = current, contains(Self.box(of: m), p) else { return }
        if let b = ProblemLayout.blocks(m).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
            switch b.kind {
            case .next, .practise: pressed = b.kind
            case .again: pressed = .again
            case .skip: skipping = true
            case .main: m.go()
            case .nextProblem: goNext()
            case .showMe: m.showMe()
            case .reset: m.reset()
            case .choice(let i): m.choose(i)
            case .field(let id): (m as? WorkProblem)?.select(id)
            case .key(let key): (m as? WorkProblem)?.type(key)
            }
            return
        }
        m.tapPaper(p)
    }

    /// The problem a point is in, so the camera can frame it.
    func problem(at p: Point) -> (any PageProblem)? { all.first { contains(Self.box(of: $0), p) } }

    /// A problem was solved: the plan adds what it needs (another together problem, a fresh one aimed at a miss); a
    /// finished test decides learned.
    private func solved(_ m: any PageProblem) {
        if test != nil {
            if let level = LessonPage.testLevel(problems.map(\.lesson)), !recorded {
                recorded = true
                Progress.shared.tested(piece.id, level: level, right: problems.filter { !$0.lesson.missedAny }.count, of: problems.count)
            }
            save(); return
        }
        if testProblems.contains(where: { $0 === m }) {
            if let r = testResult, !recorded {
                recorded = true
                Progress.shared.checked(spec.id, level: r.level)
            }
            save(); return
        }
        if var plan, let i = problems.firstIndex(where: { $0 === m }) {
            let added = plan.solved(i, m.lesson, spec, using: &rng)
            self.plan = plan
            for k in added.sorted() {
                let p = make(practice: k, run: plan.run(spec, k), plan: plan)
                wire(p)
                problems.insert(p, at: k)
            }
            // labels follow the plan's order again (a together problem slots in before the own ones)
            if !added.isEmpty { relabel() }
        }
        save()
    }

    private func relabel() {
        guard let plan else { return }
        problems = problems.indices.map { i in
            let m = problems[i], it = plan.items[i]
            let k = plan.items[...i].filter { $0.part == it.part }.count
            (m as? WorkProblem)?.label = it.part == .together ? "Together \(k)" : "On your own \(k)"
            (m as? AddFractionsModel)?.label = it.part == .together ? "Together \(k)" : "On your own \(k)"
            return m
        }
    }

    /// The page is saved after every change.
    private func save() {
        guard !instant, howToGone else { return }
        let cur = current.flatMap { c in problems.firstIndex { $0 === c } ?? testProblems.firstIndex { $0 === c } }
        PageStore.save(piece.id, .init(date: Date(), plan: plan, problems: problems.map(\.lesson.snapshot), test: testProblems.map(\.lesson.snapshot),
                                       current: cur, inTest: current.map { c in testProblems.contains { $0 === c } } ?? false,
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
        var plan: LessonPlan?
        var problems: [RunSnapshot]
        var test: [RunSnapshot]
        var current: Int?
        var inTest: Bool
        var recorded: Bool
        /// Problems solved, for the map's "5 of 9 done".
        var solved: Int
    }
    /// Bumped on every save, so the map's words know to change.
    private(set) static var version = 0
    private static func key(_ id: String) -> String { "lesson-\(id)" }

    static func load(_ id: String) -> Saved? {
        guard let d = UserDefaults.standard.data(forKey: key(id)) else { return nil }
        return try? JSONDecoder().decode(Saved.self, from: d)
    }
    static func save(_ id: String, _ s: Saved) {
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key(id)); version += 1 }
    }
    static func clear(_ id: String) { UserDefaults.standard.removeObject(forKey: key(id)); version += 1 }
}
