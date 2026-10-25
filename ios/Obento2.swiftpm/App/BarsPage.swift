import SwiftUI

/// A lesson's page on the paper (G 19 Oct). First the How to, a worked example taught a tap at a time. Then the page of
/// problems to choose from, drawn as cards: 3 done together, 6 on their own (a miss brings a fresh one aimed at it), and
/// the lesson's test (LessonPlan). Choosing one draws the page out and that problem in, alone and as big as its maths
/// needs; the bar's "Problems" draws it out and the page back in. A chapter or grade test's page is its questions.
/// A learned lesson that's due back opens on its recheck first (G 20 Oct): 4 questions, one try each and no help, then
/// the lesson's page. A finished test or recheck shows its result on the paper before going on.
/// Its problems are AddFractionsModel (Add with different bottoms) or WorkProblem (every other lesson).
@MainActor @Observable
final class BarsPage {
    enum Mode { case howTo, choose, work, result }

    let piece: Piece
    /// Everything shows at once: Reduce Motion (cuts instead of glides; the work is still saved and brought back, and
    /// the How to still plays), or a screenshot.
    let instant: Bool
    /// A screenshot: the How to is skipped and nothing is saved.
    let shotMode: Bool
    private(set) var howTo: any PageProblem
    /// The lesson's problems in the plan's order (together, then own), or a chapter test's questions.
    private(set) var problems: [any PageProblem] = []
    /// The lesson test being taken (12), if one is started.
    private(set) var testProblems: [any PageProblem] = []
    /// A due lesson's recheck (4), while the page is on it.
    private(set) var recheckProblems: [any PageProblem] = []
    /// The page opened on its recheck and hasn't gone on to the lesson's own page yet.
    private(set) var rechecking = false
    private(set) var plan: LessonPlan?
    private(set) var mode: Mode = .howTo
    /// The page of problems is up (or a problem from it is open, or a result): the How to is over.
    var showing: Bool { mode != .howTo }
    /// Asks the camera to frame a part of the page.
    var frame: ((Rect) -> Void)?
    /// Asks to go back to the map: a chapter or grade test's result goes on there.
    var close: (() -> Void)?

    // graph paper (G 17 Oct): every box starts and ends on the strong lines, with whole blocks between. The How to and
    // the problem being worked sit at the lesson's place, a square 8 blocks each way, or bigger when its maths needs it
    // everything starts on a block (G 19 Oct): a problem's left edge is the block line one block in from its box
    static let box = (dx: -Paper.unit, dy: -2 * Paper.unit, width: 8 * Paper.unit, height: 8 * Paper.unit), gap = Paper.unit
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
    /// When the cards (or a result) last drew in, and when they started drawing out.
    private(set) var cardsAt: Double = 0
    private(set) var cardsGoneAt: Double?

    /// The page as the child left it, if they stopped partway (nil for a fresh page).
    let saved: PageStore.Saved?

    /// A chapter or grade test: this many questions, every one no help and one try, and no How to.
    let test: Int?
    /// The daily review (G's plan, step 7): a test's page of problems, each from its own lesson, scored for the review
    /// only (it never changes what's learned), its result on the paper.
    var review: Bool { piece.id == Map.review.id }

    /// The lesson this page teaches (a test's first lesson, for its How to that it never plays).
    let spec: LessonSpec
    private let specs: [LessonSpec]
    private var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))

    /// The page's hints for its own problems (G 20 Oct): one budget for the page, saved with it.
    private(set) var hintsLeft = LessonPlan.hints
    /// Back soon after stopping: the problem the child was on, opened straight away.
    private var resumeAt: PageStore.Spot?

    /// `seed`: the page's numbers from this seed (a screenshot's are the same every time it's taken), else fresh.
    init(piece: Piece, reduceMotion: Bool = false, shotMode: Bool = false, first: Numbers? = nil, saved: PageStore.Saved? = nil, test: Int? = nil, recheck: Bool = false,
         seed: UInt64? = nil) {
        self.piece = piece; self.shotMode = shotMode; instant = reduceMotion || shotMode
        self.saved = saved; self.test = test
        var rng = SeededRandom(seed: seed ?? UInt64(Date().timeIntervalSince1970 * 1000))
        // a test mixes its chapter's lessons (the grade's test, every chapter's)
        let specs = test != nil ? Map.testSpecs(piece, using: &rng) : [Lessons.spec(piece.id) ?? AddFractions.spec]
        let spec = specs.first ?? AddFractions.spec
        self.spec = spec; self.specs = specs
        let o = Self.origin(for: piece), chapter = piece.chapter, instant = reduceMotion || shotMode
        let shown = first ?? spec.generate(&rng, 0)
        howTo = Self.make(spec, origin: o, chapter: chapter, instant: instant,
                          run: LessonRun(spec, numbers: shown), label: "How to", auto: true)
        /// Saved questions that had to be asked afresh.
        var afresh = 0
        /// A test's question `i` as it was saved, brought back by its own lesson (never by its place: the grade's test
        /// picks its lessons afresh each time it opens, from any of the grade's), or asked afresh when that lesson isn't
        /// the test's or has changed since.
        func question(_ i: Int, _ s: RunSnapshot?, from specs: [LessonSpec]) -> LessonRun? {
            let id = s?.spec ?? spec.id
            let own = specs.first { $0.id == id } ?? (piece.id == "test-grade" && Map.gradeLessons.contains(id) ? Lessons.spec(id) : nil)
            if let s, let own, let r = LessonRun.restored(own, s) { return r }
            if s != nil { afresh += 1 }
            return LessonPlan.testRun(specs, i, using: &rng)
        }
        /// The lesson test's result stands, unless one of its questions had to be asked afresh: then it's scored again
        /// when that one is answered.
        var resultStands = true
        if let n = test, piece.id == Map.review.id {
            // the daily review: as it was left today, or fresh, each problem from its own lesson's check recipe, drawn in
            // its own lesson's colour
            let kept = saved?.problems ?? []
            let back = kept.compactMap { k in k.spec.flatMap { Lessons.spec($0) }.flatMap { LessonRun.restored($0, k) } }
            // asked afresh: from today's pick of lessons, or, when a grown-up's reset left too few to pick from (a review
            // started today still opens to be finished), from the lessons it was started with
            let again = specs.isEmpty ? kept.compactMap { k in k.spec.flatMap { Lessons.spec($0) } } : specs
            let runs = kept.count == n && back.count == n ? back : Review.runs(again, using: &rng)
            // each card named by its own lesson, so the child sees the review is made of their lessons (the bar still
            // counts them: "Problem 3 of 8")
            problems = runs.map { r in
                Self.make(r.spec, origin: o, chapter: Map.chapter(of: r.spec.id) ?? chapter, instant: instant, run: r, label: Map.piece(r.spec.id)?.name ?? r.spec.title)
            }
        } else if let n = test {
            let kept = saved?.problems ?? []
            let runs = (0..<n).compactMap { i in question(i, kept.indices.contains(i) ? kept[i] : nil, from: specs) }
            problems = runs.enumerated().map { i, r in Self.make(r.spec, origin: o, chapter: chapter, instant: instant, run: r, label: "Problem \(i + 1)") }
        } else {
            // the page as it was left: a problem whose save no longer fits the lesson (it changed since) starts fresh
            var plan: LessonPlan, runs: [LessonRun] = []
            if let s = saved, let p = s.plan, s.problems.count == p.items.count {
                plan = p
                for i in plan.items.indices {
                    if let r = LessonRun.restored(spec, s.problems[i]) { runs.append(r) } else { plan.renew(i, spec, using: &rng); runs.append(plan.run(spec, i)) }
                }
            } else {
                // a fresh page: no problem twice on it, and the first not the How to's again
                plan = LessonPlan(spec, after: [shown], using: &rng)
                runs = plan.items.indices.map { plan.run(spec, $0) }
            }
            let kept = saved?.test ?? []
            let tests = kept.indices.compactMap { question($0, kept[$0], from: [spec]) }
            resultStands = afresh == 0
            // a due lesson's recheck: as it was left partway, or fresh (one taken to the end before is never brought back)
            let checks = saved?.recheck ?? []
            let recheckRuns: [LessonRun] = !recheck ? []
                : checks.count == LessonPlan.recheck && !checks.allSatisfy(\.finished) ? checks.indices.compactMap { question($0, checks[$0], from: [spec]) }
                : LessonPlan.recheckRuns(spec, using: &rng)
            self.plan = plan
            problems = runs.indices.map { make(practice: $0, run: runs[$0], plan: plan) }
            testProblems = tests.enumerated().map { i, r in Self.make(spec, origin: o, chapter: chapter, instant: instant, run: r, label: "Test problem \(i + 1)") }
            recheckProblems = recheckRuns.enumerated().map { i, r in Self.make(spec, origin: o, chapter: chapter, instant: instant, run: r, label: "Problem \(i + 1)") }
            rechecking = recheck
        }
        self.rng = rng
        recorded = (saved?.recorded ?? false) && resultStands
        hintsLeft = saved?.hintsLeft ?? LessonPlan.hints
        if let s = saved, Self.backSoon(s) { resumeAt = s.spot }
        for p in problems + testProblems + recheckProblems { wire(p) }
        if saved != nil { for p in problems + testProblems + recheckProblems { p.restore() } }
    }

    /// Back within 12 hours of stopping (G 20 Oct: "the same day"): no How to, straight back to where they were.
    static func backSoon(_ s: PageStore.Saved) -> Bool { Date().timeIntervalSince(s.date) < 12 * 3600 }

    /// Problem `i` of the lesson, its label from its part of the plan.
    private func make(practice i: Int, run: LessonRun, plan: LessonPlan) -> any PageProblem {
        let it = plan.items[i]
        let k = plan.items[...i].filter { $0.part == it.part }.count
        let label = it.part == .together ? "Together \(k)" : "On your own \(k)"
        let m = Self.make(spec, origin: at, chapter: piece.chapter, instant: instant, run: run, label: label)
        (m as? WorkProblem)?.focus = it.focus
        (m as? CubesProblem)?.focus = it.focus
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
        switch spec.master {
        case "bars": return AddFractionsModel(origin: origin, chapter: chapter, instant: instant, run: run, label: label, auto: auto)
        // Volume of a box: Unit cubes' box, covered, risen and stacked (G 20 Oct: anything 3D builds on Unit cubes)
        case "cubes": return CubesProblem(origin: origin, chapter: chapter, instant: instant, run: run, label: label, auto: auto)
        default: return WorkProblem(origin: origin, chapter: chapter, instant: instant, run: run, label: label, auto: auto)
        }
    }

    /// The How to has played and erased itself.
    private(set) var howToGone = false
    /// What's drawn on the paper now: the How to, the open problem, and one drawing itself out.
    var all: [any PageProblem] {
        if !howToGone { return [howTo] }
        return [current, leaving].compactMap { $0 }
    }
    /// When a problem last finished leaving: the clock runs a moment more, so the scene takes its drawing away.
    private var leftClearedAt: Double = -100
    /// A number is wanted and the cursor blinks in its box: when its last key was pressed. The clock doesn't run every
    /// frame for it, only at the blink's changes (PaperScreen).
    var cursorSince: Double? { mode == .work ? current?.cursorSince : nil }
    var animating: Bool { all.contains { $0.animating } || playing || building || PaperClock.now - leftClearedAt < 0.5 || PaperClock.now - cardsAt < 1.2 || cardsGoneAt.map { PaperClock.now - $0 < 0.8 } ?? false }
    /// The scene still has problems' bars or words to make, a few a frame: the clock keeps running until they're all
    /// made. Set by the scene, only when it changes, so the clock (which watches it) starts and stops with it.
    private(set) var building = false
    func setBuilding(_ b: Bool) { if building != b { building = b } }

    /// The list a problem is in: the lesson's own, its test's, or its recheck's.
    private func siblings(of m: any PageProblem) -> [any PageProblem] {
        if testProblems.contains(where: { $0 === m }) { return testProblems }
        if recheckProblems.contains(where: { $0 === m }) { return recheckProblems }
        return problems
    }

    /// For the bar: where the page stands (the goal that opens the test, G 20 Oct), the problem's place while one is open.
    var label: String {
        switch mode {
        case .howTo: return "How to"
        case .result:
            // a chapter or grade test's name is the bar's own title already
            guard let r = result else { return "" }
            return r.kind == .test || r.kind == .review ? "\(r.right) of \(r.of) right" : "\(r.title) · \(r.right) of \(r.of) right"
        case .work:
            if let c = current {
                if let i = testProblems.firstIndex(where: { $0 === c }) { return "Test \(i + 1) of \(testProblems.count)" }
                if let i = recheckProblems.firstIndex(where: { $0 === c }) { return "Go over \(i + 1) of \(recheckProblems.count)" }
                if test != nil, let i = problems.firstIndex(where: { $0 === c }) { return "Problem \(i + 1) of \(problems.count)" }
                return c.label
            }
            return standing.words
        case .choose: return standing.words
        }
    }
    var progress: Double { standing.done }
    /// Where the page stands: a test's or a recheck's problems done of how many (they never grow); a lesson's page the
    /// goal that opens its test (LessonPlan.standing), so fresh problems added for a miss never move it.
    private var standing: LessonPlan.Standing {
        if test != nil || rechecking {
            let list = rechecking ? recheckProblems : problems, done = list.filter(\.solved).count
            return .init(words: "\(rechecking ? "Go over · " : "")\(done) of \(list.count) done", done: list.isEmpty ? 0 : Double(done) / Double(list.count))
        }
        guard let plan else { return .init(words: "", done: 0) }
        return plan.standing(solved: problems.map(\.solved), clean: problems.indices.map { plan.clean($0, problems[$0].lesson) },
                             test: testProblems.map { $0.solved ? !$0.lesson.missedAny : nil })
    }
    /// "Fractions test" or the lesson's name, for the bar.
    var title: String { piece.name }
    /// A test, a recheck or one of their questions is up: no help of any kind (Read it aloud, the How to).
    var inTest: Bool { test != nil || rechecking || mode == .result || current.map { c in testProblems.contains { $0 === c } } ?? false }

    // MARK: hints

    /// The open problem's part of the plan: nil for a test's or a recheck's question.
    private var part: LessonPlan.Part? {
        guard mode == .work, let c = current, let plan, let i = problems.firstIndex(where: { $0 === c }), plan.items.indices.contains(i) else { return nil }
        return plan.items[i].part
    }
    /// What the bar's Hint does now (G 20 Oct): together problems' are free up to their cap; on their own, one of the
    /// page's, once the step has had a miss; none in tests and rechecks.
    var hintUse: LessonPlan.HintUse {
        guard mode == .work, let c = current, !c.solved else { return .off }
        return LessonPlan.hint(c.lesson, part: part, left: hintsLeft)
    }
    /// The hints the bar shows as left, for the open problem: the page's, on their own once the step has had a miss.
    var hintCount: Int? {
        guard mode == .work, let c = current else { return nil }
        return LessonPlan.hintsLeft(c.lesson, part: part, left: hintsLeft)
    }
    /// The bar's Hint: the problem shows its step's hint on the paper; an own problem's comes out of the page's hints.
    /// When there's none to give, the paper says why where a miss is said (G 20 Oct: "Have a go first. A hint comes
    /// after a miss."), never over what a miss says.
    func hint() {
        guard mode == .work, let m = current, !m.busy else { return }
        let use = hintUse
        guard use != .off else {
            if let why = LessonPlan.noHint(m.lesson, part: part, left: hintsLeft), let w = m as? WorkProblem, w.message?.ok != false { w.message = (why, true) }
            return
        }
        let at = m.lesson.index
        // the problem draws its hint on the paper and counts it (LessonRun.hinted); one that can't draw one yet has its
        // words written where a miss is said, as a notice
        m.showHint()
        if !m.lesson.hinted.contains(at), let w = m as? WorkProblem, let words = Self.hintWords(m.lesson) {
            w.usedHint(); w.message = (words, true)
        }
        // nothing shown, nothing spent
        guard m.lesson.hinted.contains(at) else { return }
        if use == .spend { hintsLeft -= 1 }
        save()
    }
    /// A step's hint in words: its answer's, its words', or what its picture's hint says.
    static func hintWords(_ l: LessonRun) -> String? {
        [l.step.answer?.hint, l.words.hint, l.step.look].compactMap { $0 }.first { !$0.isEmpty }
    }

    // MARK: the page of problems

    struct Card {
        enum State { case open, now, done, missed, locked }
        /// What the card opens: one of the lesson's problems (or a test's questions), the lesson's test, or a question
        /// of the recheck.
        enum Opens: Equatable { case problem(Int), test, recheck(Int) }
        let opens: Opens
        let rect: Rect
        let title: String
        let display: MathLine?
        let line: String
        let state: State
        /// Drawn in its own lesson's colour, not the page's (the daily review mixes them).
        var pen: Pen? = nil
        /// Its parts' names on the paper.
        var id: String {
            switch opens { case .problem(let i): "card\(i)"; case .test: "card-1"; case .recheck(let i): "recheck\(i)" }
        }
    }

    /// The lesson's test is open once 6 own problems are right on their own.
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
        func part(_ heading: String, _ items: [(Card.Opens, any PageProblem)], columns: Int) {
            heads.append((Point(x0, y - Paper.unit / 2), heading))
            for (k, (opens, m)) in items.enumerated() {
                let r = Rect(x: x0 + Double(k % columns) * (w + g), y: y + Double(k / columns) * (h + Paper.unit), width: w, height: h)
                out.append(card(opens, m, r))
            }
            y += Double((items.count + columns - 1) / columns) * (h + Paper.unit) + g
        }
        // one word for them, problems, everywhere (G 20 Oct), and what passes
        if let n = test {
            // the review passes nobody: it only says how it went
            part(review ? "\(n) problems, one try each" : "\(n) problems, one try each · \(LessonPlan.passMark(n)) right passes",
                 problems.indices.map { (.problem($0), problems[$0]) }, columns: 4)
            return (out, heads)
        }
        // a due lesson's recheck: its 4 problems, before the lesson's page, two by two so they read big
        if rechecking {
            part("Go over: \(recheckProblems.count) problems, one try each · \(Mastery.pass) right keeps it learned",
                 recheckProblems.indices.map { (.recheck($0), recheckProblems[$0]) }, columns: 2)
            return (out, heads)
        }
        guard let plan else { return (out, []) }
        let top = y
        part("Together", plan.items.indices.filter { plan.items[$0].part == .together }.map { (.problem($0), problems[$0]) }, columns: Self.columns)
        part("On your own · \(plan.ownRight(problems.map(\.lesson))) of \(LessonPlan.own) right",
             plan.items.indices.filter { plan.items[$0].part == .own }.map { (.problem($0), problems[$0]) }, columns: Self.columns)
        let tx = x0 + Double(Self.columns) * (w + g) + g
        heads.append((Point(tx, top - Paper.unit / 2), "Test"))
        let started = testProblems.contains { $0.lesson.index > 0 || $0.solved }
        let (line, state): (String, Card.State) = {
            if let res = testResult {
                return res.level >= Mastery.pass ? ("Passed · \(res.right) of \(LessonPlan.test)", .done) : ("\(res.right) of \(LessonPlan.test) · Take it again", .missed)
            }
            if !testOpen { return ("Get 6 right on your own first", .locked) }
            if started { return ("\(testProblems.filter(\.solved).count) of \(LessonPlan.test) done", .now) }
            return ("\(LessonPlan.test) problems, no help", .open)
        }()
        out.append(Card(opens: .test, rect: Rect(x: tx, y: top, width: w, height: h), title: "Lesson test", display: nil, line: line, state: state))
        return (out, heads)
    }

    /// A problem's card: how it stands, and the line under its name.
    private func card(_ opens: Card.Opens, _ m: any PageProblem, _ r: Rect) -> Card {
        let l = m.lesson, oneTry = l.oneTry || !l.helps
        let state: Card.State, line: String
        if m.solved {
            // a test's problem was right or missed; a practice problem is done (a miss or Show me said so: the page's
            // own showing of a part it taught again isn't Show me)
            let showMe: Bool = { if case .problem(let i) = opens, let plan { return plan.usedShowMe(i, l.shown, lead: l.lead) }; return !l.shown.isEmpty }()
            state = oneTry && l.missedAny ? .missed : .done
            line = oneTry ? (l.missedAny ? "Missed" : "Right") : l.missedAny ? "Done, with a miss" : showMe ? "Done, with Show me" : "Done"
        } else {
            state = m === lastWorked ? .now : .open
            let done = l.steps.indices.filter { $0 < l.index && (l.steps[$0].answer != nil || l.steps[$0].task != nil) }.count
            line = done > 0 ? "\(done) of \(l.workSteps) steps" : focusLine(m)
        }
        return Card(opens: opens, rect: r, title: m.label, display: l.display, line: line, state: state, pen: review ? .chapter(m.chapter) : nil)
    }

    /// The problem worked last, marked Now on its card.
    private var lastWorked: (any PageProblem)?

    private func focusLine(_ m: any PageProblem) -> String {
        ((m as? WorkProblem)?.focus ?? (m as? CubesProblem)?.focus) != nil ? "Practice the part you missed" : "Not started"
    }

    /// The page of problems, all of it (or the result on it): what the camera shows.
    var pageFrame: Rect {
        if mode == .result { return resultFrame }
        let cs = cards
        guard let first = cs.first else { return Self.box(of: howTo) }
        var minX = first.rect.x, minY = corner.y, maxX = 0.0, maxY = 0.0
        for c in cs { minX = min(minX, c.rect.x); maxX = max(maxX, c.rect.x + c.rect.width); maxY = max(maxY, c.rect.y + c.rect.height) }
        // the names under the last row too
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY + Paper.unit - minY)
    }
    var firstRow: Rect { pageFrame }

    // MARK: a finished test's result

    /// A finished test or recheck, shown on the paper before going on (G 20 Oct): its score, what it means, and why
    /// (the last words say why); then what to do: go on, or take it again.
    struct Result: Equatable {
        enum Kind: Equatable { case lessonTest, recheck, test, review }
        let kind: Kind
        /// Its heading: "Lesson test", "Go over", "Fractions test".
        let title: String
        let right: Int, of: Int
        let passed: Bool
        /// The review: the lessons it had a miss in, in the order they came.
        var missed: [String] = []
        /// What it means: learned (still learned, passed), or what to do now; the review, that it's done for the day.
        var verdict: String {
            switch kind {
            case .lessonTest: passed ? "Learned" : "Take it again"
            case .recheck: passed ? "Still learned" : "Go over it again"
            case .test: passed ? "Passed" : "Take it again"
            case .review: "Done for today"
            }
        }
        /// Why, always: what passes, what keeps it learned, or after a recheck that came back low, what comes next; the
        /// review, every lesson it had a miss in. It says "Missed", never "Go over": the review changes nothing that's
        /// learned, and on Me Go over means only a learned lesson that's due back or whose check came back low.
        var why: String { whyPieces.joined(separator: " ") }
        /// The review's lessons with a miss, by name, each once, in the order they came.
        var missedNames: [String] {
            var names: [String] = []
            for id in missed { if let n = Map.piece(id)?.name, !names.contains(n) { names.append(n) } }
            return names
        }
        /// Why in pieces that stay whole on the paper: the review's "Missed:", then each lesson's name with its comma
        /// (the last with "and" and the full stop), so a name is never split across two rows; anything else, a word each.
        private var whyPieces: [String] {
            switch kind {
            case .recheck: return words(passed ? "\(Mastery.pass) of \(of) keeps it learned." : "New problems are on your page. The check comes back tomorrow.")
            case .review:
                let names = missedNames
                guard !names.isEmpty else { return words("Every one right. A new review comes tomorrow.") }
                return ["Missed:"] + names.enumerated().map { i, n in
                    i == names.count - 1 ? (names.count > 1 ? "and " : "") + n + "." : i == names.count - 2 ? n : n + ","
                }
            default: return words("\(LessonPlan.passMark(of)) of \(of) passes.")
            }
        }
        private func words(_ s: String) -> [String] { s.split(separator: " ").map(String.init) }
        /// Why as the paper writes it, in rows `width` wide (20, regular): as many rows as it takes, so the struggling
        /// child's whole list is there.
        @MainActor func whyRows(width: Double) -> [String] {
            let font = PaperText.font(Sketch.small, .regular)
            var rows: [String] = [], row = ""
            for piece in whyPieces {
                let longer = row.isEmpty ? piece : row + " " + piece
                if row.isEmpty || PaperText.width(longer, font) <= width { row = longer } else { rows.append(row); row = piece }
            }
            if !row.isEmpty { rows.append(row) }
            return rows
        }
        /// Its blocks: the main one (Continue; or, not passed, Take it again), and a quieter one beside it then.
        var main: String { passed || kind == .recheck ? "Continue" : "Take it again" }
        var other: String? { passed || kind == .recheck ? nil : kind == .test ? "Back to the map" : "Back to problems" }
    }
    /// The result on the paper now.
    private(set) var result: Result?
    /// A test just finished: its result shows when the child goes on from its last problem.
    private var pending: Result?

    /// Where the result's parts sit, on the page's grid: its heading where the cards' first heading goes; a frame 4
    /// blocks by 2 with the score in it; what it means in the row under it, why in the rows under that (`whyRows`: as
    /// many as it takes); its blocks on the second block line under the frame, or the next one down that leaves a square
    /// under why's last row, the main one on the frame's left edge and the quieter one two squares after it, each as long
    /// as its word needs in whole squares.
    var resultLayout: (heading: Point, frame: Rect, verdict: Point, why: Point, whyRows: [String], main: Rect, other: Rect?) {
        let x0 = corner.x, top = corner.y + Paper.unit, c = Paper.cell, u = Paper.unit
        let frame = Rect(x: x0, y: top, width: 4 * u, height: 2 * u), bottom = frame.y + frame.height
        let rows = result?.whyRows(width: resultWidth) ?? []
        // why's rows start three squares under the frame; the blocks a square clear of the last
        let clear = 3 * c + Double(max(1, rows.count)) * Sketch.row + c
        let main = Rect(x: x0, y: bottom + max(2, (clear / u).rounded(.up)) * u, width: Self.resultBlock(result?.main ?? "Continue"), height: 2 * c)
        let other = result?.other.map { Rect(x: main.x + main.width + 2 * c, y: main.y, width: Self.resultBlock($0), height: 2 * c) }
        return (Point(x0, top - u / 2), frame, Point(x0, bottom + 2 * c), Point(x0, bottom + 4 * c), rows, main, other)
    }
    /// A result's block: as long as its word (and the main one's arrow) needs, in whole squares, never less than 9.
    private static func resultBlock(_ word: String) -> Double {
        let c = Paper.cell
        return max(9 * c, ((PaperText.width(word, PaperText.font(Sketch.Words.block.size, .medium)) + 70) / c).rounded(.up) * c)
    }
    /// How wide the result's words may run: the frame's width, or the blocks' when they're wider, and never less than 6
    /// blocks.
    var resultWidth: Double {
        let main = Self.resultBlock(result?.main ?? "Continue"), other = result?.other.map { 2 * Paper.cell + Self.resultBlock($0) } ?? 0
        return max(6 * Paper.unit, 4 * Paper.unit, main + other)
    }
    var resultFrame: Rect {
        let l = resultLayout
        return Rect(x: corner.x, y: corner.y, width: resultWidth, height: l.main.y + l.main.height - corner.y)
    }

    /// Screenshots only: a result on the paper as it would come out (the longest the review can say).
    func showResultForShots(_ r: Result) { howToGone = true; showResult(r) }

    private func showResult(_ r: Result) {
        pending = nil
        result = r
        if let c = current { c.leave(); leaving = c; clearLeaving(c) }
        current = nil; framed = nil
        mode = .result
        cardsAt = instant ? PaperClock.now - 100 : PaperClock.now + 0.35; cardsGoneAt = nil
        frame?(resultFrame)
        save()
    }

    /// The result's main block: Continue (a lesson test back to its page, a recheck on to the lesson's page, a chapter or
    /// grade test back to the map), or, not passed, Take it again: a fresh test, straight into its first problem.
    func continueFromResult() {
        guard mode == .result, let r = result else { return }
        if !r.passed && r.kind != .recheck { takeAgain(); return }
        leaveResult()
    }
    /// The result's quieter block: back to the page (or the map), not taking it again now.
    func leaveResult() {
        guard mode == .result, let r = result else { return }
        if r.kind == .test || r.kind == .review { close?(); return }
        if r.kind == .recheck { rechecking = false; recheckProblems = [] }
        result = nil
        showPage(after: 0.05)
        save()
    }
    /// A test taken again from its result: fresh problems, the first of them opened.
    private func takeAgain() {
        guard let r = result else { return }
        result = nil
        if r.kind == .lessonTest { openTest(); return }
        // a chapter or grade test: its problems asked afresh, from the same lessons in turn
        problems = LessonPlan.testRuns(specs, count: problems.count, using: &rng).enumerated().map { i, run in
            Self.make(run.spec, origin: at, chapter: piece.chapter, instant: instant, run: run, label: "Problem \(i + 1)")
        }
        problems.forEach(wire)
        recorded = false
        if let m = problems.first { open(m) }
    }

    // MARK: the How to, then the page

    private var playing = false

    /// The page opens: a test or a recheck on its questions, back soon on the problem the child was on, else the How to
    /// plays itself (taught a tap at a time, or as a reminder after a while).
    func start() {
        // today's review, done: its result, on the paper
        if review, recorded, let r = Progress.shared.todaysReview {
            howToGone = true
            showResult(Result(kind: .review, title: piece.name, right: r.right, of: r.of, passed: true, missed: r.missed))
            return
        }
        // a chapter or grade test has no How to; nor does a recheck (G 20 Oct)
        if test != nil || rechecking { howToGone = true; showProblems(); return }
        // back soon: straight to the problem they were on, no How to
        if let s = saved, Self.backSoon(s), !shotMode {
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
        guard howToGone, !playing, !inTest else { return }
        if mode == .work, let c = current { c.leave(); leaving = c }
        cardsGoneAt = PaperClock.now
        playing = true
        run { [self] in
            guard await wait(0.55) else { return }
            leaving = nil
            howTo.replay(); howToGone = false; mode = .howTo
            current = howTo; frame?(Self.box(of: howTo))
            if shotMode { play() } else { teach() }
        }
    }

    /// A tap while the How to plays: the next step when it's being taught, the end of it when it's a reminder.
    func skipHowTo() {
        guard playing, !howToGone else { return }
        if reminding { skipping = true } else { press(howTo.howToButtons.first ?? .next) }
    }
    /// Coming back after a while: the How to replays on its own, and a tap skips it.
    private var reminding: Bool { saved.map { !Self.backSoon($0) } ?? false }
    private var skipping = false

    /// The How to waiting for the child to press one of its blocks: their tap ends the wait (nothing polls).
    @ObservationIgnored private var waiting: CheckedContinuation<ProblemLayout.Kind?, Never>?
    private func press(_ k: ProblemLayout.Kind?) {
        guard let c = waiting else { return }
        waiting = nil
        c.resume(returning: k)
    }
    /// Shows these blocks and waits for one to be pressed; nil when the page stops first.
    private func ask(_ blocks: [ProblemLayout.Kind]) async -> ProblemLayout.Kind? {
        guard !Task.isCancelled else { return nil }
        press(nil)
        howTo.howToButtons = blocks
        let k = await withTaskCancellationHandler {
            await withCheckedContinuation { (c: CheckedContinuation<ProblemLayout.Kind?, Never>) in waiting = c }
        } onCancel: {
            Task { @MainActor [weak self] in self?.press(nil) }
        }
        howTo.howToButtons = []
        return k
    }

    /// The How to taught a tap at a time (G 18 Oct): why it works, then each step's words and its move, waiting for the
    /// child before going on.
    private func teach() {
        run { [self] in
            while true {
                howTo.intro = spec.idea(howTo.lesson.numbers)
                // the picture grows in; what to do
                guard await wait(1.2), await ask([.next]) != nil else { return }
                // the lesson's own explaining beats: why the numbers do what they do
                for beat in howTo.howToBeats() {
                    howTo.intro = beat.words; beat.run()
                    guard await wait(1.0), await ask([.next]) != nil else { return }
                }
                (howTo as? WorkProblem)?.endBeats()
                howTo.intro = nil
                while !howTo.solved {
                    howTo.go()                                          // the next step's words
                    if howTo.solved { break }
                    guard await wait(1.0) else { return }
                    guard await wait(howTo.demonstrate() + 0.4) else { return }     // its move, made for it
                    guard await ask([.next]) != nil else { return }
                }
                // the answer stays until the child chooses: practise, or watch it all again
                guard await wait(0.6), let k = await ask([.practise, .again]) else { return }
                if k == .practise { break }
                howTo.replay()
                guard await wait(0.4) else { return }
            }
            howTo.leave()
            guard await wait(0.6) else { return }
            howToGone = true
            playing = false
            showProblems()
        }
    }

    private func play() {
        // a screenshot: the How to done at once
        if shotMode { while !howTo.solved { howTo.demonstrate(); howTo.go() }; howToGone = true; showProblems(); return }
        playing = true
        // the first time it's taught a tap at a time, idea first; coming back it plays itself as a reminder
        if !reminding { teach(); return }
        howTo.howToButtons = [.skip]
        skipping = false
        run { [self] in
            /// Waits `s` seconds, or less when Skip is pressed; false once the page has stopped.
            @MainActor func pause(_ s: Double) async -> Bool {
                var t = 0.0
                while t < s, !skipping { guard await wait(0.1) else { return false }; t += 0.1 }
                return true
            }
            guard await pause(2.2) else { return }                    // the bars grow in; read the question
            while !howTo.solved && !skipping {
                howTo.go()                                            // the next step's words come in, the See beat plays
                guard await pause(1.4) else { return }
                if howTo.solved || skipping { break }
                guard await pause(howTo.demonstrate() + 0.8) else { return }   // the move, made for it
            }
            if !skipping { guard await pause(1.6) else { return } }   // read the answer
            howTo.howToButtons = []
            howTo.leave()                                             // it erases itself, as it drew itself in
            guard await wait(0.6) else { return }
            howToGone = true
            playing = false
            showProblems()
        }
    }

    /// After the How to (or straight away): the page of problems draws itself in; or, back soon, the problem the child
    /// was on.
    private func showProblems() {
        if let spot = resumeAt {
            resumeAt = nil
            if let m = problem(for: spot), !m.solved { open(m); return }
        }
        showPage(after: 0.05)
    }

    /// The page of problems (the recheck's, while it's on) draws in.
    private func showPage(after delay: Double) {
        current = nil; framed = nil
        mode = .choose
        cardsAt = instant ? PaperClock.now - 100 : PaperClock.now + delay; cardsGoneAt = nil
        frame?(pageFrame)
    }

    /// The problem at a saved place, if it's still on the page.
    private func problem(for spot: PageStore.Spot) -> (any PageProblem)? {
        switch spot {
        case .problem(let i): return !rechecking && problems.indices.contains(i) ? problems[i] : nil
        case .test(let i): return !rechecking && testProblems.indices.contains(i) ? testProblems[i] : nil
        case .recheck(let i): return rechecking && recheckProblems.indices.contains(i) ? recheckProblems[i] : nil
        }
    }

    // MARK: what the child does

    /// Leaving the lesson: what's on the paper erases itself, as it drew in.
    func leave() { for m in all { m.leave() }; if mode == .choose || mode == .result { cardsGoneAt = PaperClock.now } }

    /// A problem opens: the page draws out, and it draws in alone where the How to was. The camera frames what it
    /// draws (contentChanged).
    func open(_ m: any PageProblem) {
        if mode == .work, let c = current, c !== m { c.leave(); leaving = c; clearLeaving(c) }
        // the cards go, whether they were up or not (coming back opens the problem straight away)
        if cardsGoneAt == nil { cardsGoneAt = PaperClock.now }
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

    /// The bar's "Problems": the problem draws out and the page draws back in (a test just finished: its result).
    func backToProblems() {
        guard mode == .work, let c = current else { return }
        if let r = pending { pending = nil; showResult(r); return }
        c.leave(); leaving = c; clearLeaving(c)
        showPage(after: 0.35)
        save()
    }

    private func clearLeaving(_ c: any PageProblem) {
        run { [self] in
            guard await wait(0.6), leaving === c else { return }
            leaving = nil; leftClearedAt = PaperClock.now
        }
    }

    /// "Next problem" on a solved one: the next one not done yet, in order; when there's none, back to the page. A test
    /// or recheck just finished shows its result first.
    func goNext() {
        guard let c = current else { return }
        if let r = pending { pending = nil; showResult(r); return }
        let list = siblings(of: c)
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
                Self.make(spec, origin: at, chapter: piece.chapter, instant: instant, run: r, label: "Test problem \(i + 1)")
            }
            testProblems.forEach(wire)
            recorded = false
            // a result still waiting belonged to the test before
            pending = nil
        }
        if let m = testProblems.first(where: { !$0.solved }) { open(m) }
    }

    /// A tap on the paper: on the page, the card it lands on opens; in a problem, the block it lands on; on a result,
    /// Continue.
    func tap(_ p: Point) {
        // while the How to plays, only its blocks do anything
        if playing && !howToGone {
            if let b = ProblemLayout.blocks(howTo).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
                switch b.kind { case .skip: skipping = true; case .next, .practise, .again: press(b.kind); default: break }
            }
            return
        }
        if mode == .result {
            let l = resultLayout
            if contains(l.main, p) { continueFromResult() } else if let o = l.other, contains(o, p) { leaveResult() }
            return
        }
        if mode == .choose {
            guard let c = cards.first(where: { contains($0.rect, p) }) else { return }
            switch c.opens {
            case .problem(let i): open(problems[i])
            case .test: openTest()
            case .recheck(let i): open(recheckProblems[i])
            }
            return
        }
        guard let m = current, contains(Self.box(of: m), p) else { return }
        if let b = ProblemLayout.blocks(m).first(where: { $0.rect.contains(CGPoint(x: p.x, y: p.y)) }) {
            switch b.kind {
            case .next, .practise, .again: press(b.kind)
            case .skip: skipping = true
            case .main: m.go()
            case .nextProblem: goNext()
            case .showMe: m.showMe()
            case .reset: m.reset()
            case .choice(let i): m.choose(i)
            case .field(let id): (m as? WorkProblem)?.select(id)
            case .key(let key): (m as? WorkProblem)?.type(key)
            case .action(let name): (m as? WorkProblem)?.act(name)
            }
            return
        }
        m.tapPaper(p)
    }

    /// A problem was solved: the plan adds what it needs (another together problem, a fresh one aimed at a miss); a
    /// finished test or recheck is scored, the one way every test is (LessonPlan), and its result shows when the child
    /// goes on from its last problem, or at once when they've gone back to the page already. A page that has stopped
    /// (closed, or another opened) takes nothing more: what it saved as it stopped is what comes back. A problem counts
    /// once: Check pressed again as its last step moves on mustn't add a second fresh problem for the same miss.
    private func solved(_ m: any PageProblem) {
        guard !stopped, counted.insert(m.id).inserted else { return }
        if test != nil, review {
            // the daily review: scored for itself only, never for what's learned
            if let r = LessonPlan.testScore(problems.map(\.lesson)), !recorded {
                recorded = true
                let missed = problems.filter { $0.lesson.missedAny }.map(\.lesson.spec.id)
                Progress.shared.reviewed(right: r.right, of: problems.count, missed: missed)
                finished(Result(kind: .review, title: piece.name, right: r.right, of: problems.count, passed: true, missed: missed), m)
            }
            save(); return
        }
        if test != nil {
            if let r = LessonPlan.testScore(problems.map(\.lesson)), !recorded {
                recorded = true
                Progress.shared.tested(piece.id, right: r.right, of: problems.count)
                finished(Result(kind: .test, title: piece.name, right: r.right, of: problems.count, passed: r.level >= Mastery.pass), m)
            }
            save(); return
        }
        if recheckProblems.contains(where: { $0 === m }) {
            if let r = LessonPlan.recheckScore(recheckProblems.map(\.lesson)), pending == nil, result == nil {
                Progress.shared.checked(spec.id, level: r.level)
                let passed = r.level >= Mastery.pass
                // came back low: a fresh problem on the page for each one missed, aimed at its slip
                if !passed, var plan {
                    let added = plan.goOver(recheckProblems.map(\.lesson), spec, using: &rng)
                    self.plan = plan
                    for k in added.sorted() { let p = make(practice: k, run: plan.run(spec, k), plan: plan); wire(p); problems.insert(p, at: k) }
                }
                finished(Result(kind: .recheck, title: "Go over", right: r.right, of: recheckProblems.count, passed: passed), m)
            }
            save(); return
        }
        if testProblems.contains(where: { $0 === m }) {
            if let r = testResult, !recorded {
                recorded = true
                Progress.shared.checked(spec.id, level: r.level)
                finished(Result(kind: .lessonTest, title: "Lesson test", right: r.right, of: testProblems.count, passed: r.level >= Mastery.pass), m)
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

    /// A test or recheck just finished with problem `m`: its result waits for the child to go on from it, or, when
    /// they've gone back to the page already (the bar's Problems pressed as it was checked), shows now.
    private func finished(_ r: Result, _ m: any PageProblem) {
        if mode == .work, current === m { pending = r } else { showResult(r) }
    }

    private func relabel() {
        guard let plan else { return }
        problems = problems.indices.map { i in
            let m = problems[i], it = plan.items[i]
            let k = plan.items[...i].filter { $0.part == it.part }.count
            (m as? WorkProblem)?.label = it.part == .together ? "Together \(k)" : "On your own \(k)"
            (m as? AddFractionsModel)?.label = it.part == .together ? "Together \(k)" : "On your own \(k)"
            (m as? CubesProblem)?.label = it.part == .together ? "Together \(k)" : "On your own \(k)"
            return m
        }
    }

    /// The page is saved after every change (a screenshot saves nothing); once it has stopped, the save it made as it
    /// stopped stands (a problem's step finishing a moment later doesn't write over it).
    private func save() {
        guard !shotMode, howToGone, !stopped else { return }
        let spot: PageStore.Spot? = current.flatMap { c in
            if let i = problems.firstIndex(where: { $0 === c }) { return .problem(i) }
            if let i = testProblems.firstIndex(where: { $0 === c }) { return .test(i) }
            return recheckProblems.firstIndex { $0 === c }.map { .recheck($0) }
        }
        // a recheck is kept while it's being taken; one taken to the end is scored, and isn't brought back
        let recheck = rechecking && LessonPlan.recheckScore(recheckProblems.map(\.lesson)) == nil ? recheckProblems.map(\.lesson.snapshot) : []
        PageStore.save(piece.id, .init(date: Date(), plan: plan, problems: problems.map(\.lesson.snapshot), test: testProblems.map(\.lesson.snapshot),
                                       recheck: recheck, spot: spot, recorded: recorded,
                                       solved: problems.filter(\.solved).count, hintsLeft: hintsLeft))
    }
    private var recorded = false
    /// The problems solved while the page is open, each counted once.
    @ObservationIgnored private var counted: Set<UUID> = []

    // MARK: its tasks

    @ObservationIgnored private var tasks: [Int: Task<Void, Never>] = [:]
    @ObservationIgnored private var taskCount = 0
    /// The page has stopped: closed, or another page opened.
    private(set) var stopped = false

    /// Runs `body` as one of the page's tasks (the How to, a problem drawing out): every one ends when the page stops.
    private func run(_ body: @escaping @MainActor () async -> Void) {
        guard !stopped else { return }
        taskCount += 1
        let k = taskCount
        tasks[k] = Task { @MainActor [weak self] in
            await body()
            self?.tasks[k] = nil
        }
    }
    /// Waits `s` seconds; false once the page has stopped (its task is cancelled): stop there.
    private func wait(_ s: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(s))
        return !Task.isCancelled
    }

    /// The page closes, or another opens: its work is saved, and everything it started ends now, whatever it was waiting
    /// for (the How to waiting for a tap), so nothing keeps running or keeps the page.
    func stop() {
        guard !stopped else { return }
        save()
        stopped = true
        pending = nil
        for t in tasks.values { t.cancel() }
        tasks = [:]
        press(nil)
    }

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

/// Each lesson page's work, saved on the device as the child goes (G 18 Oct): stop anywhere and come back to it.
/// Versioned (G 20 Oct): a save in an older shape starts that page fresh, so does a page whose lesson's steps have been
/// numbered differently since, and a problem whose save no longer fits its lesson starts fresh (LessonRun.restored),
/// instead of being misread.
@MainActor
enum PageStore {
    /// The saves' shape: bumped whenever `Saved` changes, or a lesson's steps are numbered differently.
    nonisolated static let schema = 3
    /// The oldest save that still fits a lesson's page. `Saved` has had this shape since 2; a lesson whose steps have been
    /// numbered differently since needs a save made after that, as its plan names steps by number (a problem aimed at a
    /// slip: the step, what it says there, the slips counted). Multiply two-digit numbers: the cut came in as its
    /// second step (20 Oct).
    nonisolated static let oldest: [String: Int] = ["g5-mult2": 3]
    private static func fits(_ saved: Int?, _ id: String) -> Bool { (saved ?? 0) >= (oldest[id] ?? 2) && (saved ?? 0) <= schema }

    /// Where the child was: one of the lesson's problems (or a test's questions), the lesson test's, or the recheck's.
    enum Spot: Codable, Equatable { case problem(Int), test(Int), recheck(Int) }

    struct Saved: Codable {
        var schema = PageStore.schema
        var date: Date
        var plan: LessonPlan?
        var problems: [RunSnapshot]
        var test: [RunSnapshot]
        /// A due lesson's recheck, while it's being taken.
        var recheck: [RunSnapshot]
        var spot: Spot?
        /// The test taken to the end has been scored (a chapter or grade test: it's finished).
        var recorded: Bool
        /// Problems solved, for the map's "5 of 9 done".
        var solved: Int
        /// The page's hints left for its own problems.
        var hintsLeft: Int
    }
    /// Bumped on every save, so the map's words know to change.
    private(set) static var version = 0
    /// Screenshots keep what they set here only.
    static var saving = true
    private static func key(_ id: String) -> String { "lesson-\(id)" }
    /// What's been read or saved, so the map doesn't decode every page each time it draws.
    private static var cache: [String: Saved?] = [:]

    private struct Shape: Decodable { var schema: Int? }

    static func load(_ id: String) -> Saved? {
        if let c = cache[id] { return c }
        var out: Saved?
        // an older shape, a lesson renumbered since (or a save that can't be read) starts the page fresh; its next save
        // takes its place
        if let d = UserDefaults.standard.data(forKey: key(id)), fits((try? JSONDecoder().decode(Shape.self, from: d))?.schema, id) {
            out = try? JSONDecoder().decode(Saved.self, from: d)
        }
        cache[id] = .some(out)
        return out
    }
    /// Only what's been saved since the app opened (a screenshot's own pages, never one left on the device).
    static func cached(_ id: String) -> Saved? { cache[id] ?? nil }
    static func save(_ id: String, _ s: Saved) {
        cache[id] = .some(s); version += 1
        guard saving, let d = try? JSONEncoder().encode(s) else { return }
        UserDefaults.standard.set(d, forKey: key(id))
    }
    static func clear(_ id: String) {
        cache[id] = .some(nil); version += 1
        if saving { UserDefaults.standard.removeObject(forKey: key(id)) }
    }
}
