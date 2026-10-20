import SwiftUI

/// One problem of a lesson, live where it sits on its page (BarsPage). A lesson moved onto the paper (PaperLessons:
/// Rounding decimals, the Adding fractions family) is laid out stacked (G 20 Oct, design/README.md): what to do on the
/// top rows, what a miss says (or the hint) under it, the picture, the record a few rows under the picture, and the
/// blocks under the record; each step is a hand move on the picture or a number written in the record. The other
/// lessons keep their picture and their work side by side, a step's words and line beside them (LessonPictures).
@MainActor @Observable
final class WorkProblem: Identifiable, PageProblem {
    let id = UUID()
    var label: String
    let auto: Bool
    let origin: Point
    let chapter: Chapter
    let instant: Bool
    private(set) var lesson: LessonRun
    var message: (text: String, ok: Bool)?
    var intro: String?
    var howToButtons: [ProblemLayout.Kind] = []
    var onSolved: (() -> Void)?
    var onTouch: (() -> Void)?
    var onChange: (() -> Void)?
    var needs: ((Rect) -> Void)?

    /// The lesson on the paper that draws and plays this problem, once it's been moved there (PaperLessons).
    let paper: (any PaperLesson)?
    /// Laid out stacked, the paper lessons' way.
    var stacked: Bool { paper != nil }

    private(set) var openedAt: Double
    private(set) var wordsAt: Double = PaperClock.now
    /// When the picture last changed: what's new in it draws in from then.
    private(set) var pictureAt: Double = PaperClock.now
    /// The keypad, drawn on the paper beside the line, comes up when an answer box is tapped (G 19 Oct).
    private(set) var keypadOpen = false
    private(set) var keypadAt: Double = -100
    private(set) var leftAt: Double?
    private(set) var busyUntil: Double = 0
    /// Extra picture keys the How to's explaining beats turn on (merged over the step's).
    private(set) var extra: Numbers = [:]

    /// The hand's state on this step (LESSONS.md §3, G 20 Oct): what's held and where it is (the ruler's length, the
    /// point's place, the pieces being slid). It lives only while its step does: a new step starts with empty hands.
    var hand: Numbers = [:]
    /// When the hand last moved: the clock runs while it does.
    var handAt: Double = -100
    /// A drag is under way on the picture (LessonHands): the camera holds still until it's let go.
    var dragging = false
    /// The step's hint is shown: written on rows 3–4 and its part of the picture lit (Hint in the bar).
    private(set) var hinting = false
    /// Show me (a preview) or the How to, playing the step's moves with a ghost finger.
    private(set) var ghost: GhostPlay?

    // where things sit, in paper points from `origin`, inside the box (BarsPage.box): the problem above the origin, the
    // picture from the origin down, then the step
    /// The sum's row starts on the block line one block above the picture.
    static let problemY: Double = -100
    /// The line being worked is written big for kids (G 19 Oct): two squares to a digit, like the sum at the top.
    static let lineCell: Double = 2
    /// Obento²'s own keypad drawn on the paper; off while the iPad's keyboard types (G 19 Oct).
    static let drawnKeys = false

    /// Where things sit in an open problem, in points from its origin before `scale`. An open problem is its own space
    /// on the grid, with no frame, filling the screen (G 19 Oct). When its maths is too big for the screen, everything
    /// but its true-size picture is drawn `scale` times bigger, and the camera steps back to see it all.
    struct Layout {
        var scale = 1.0
        var width = 13.0, height = 10.0
        // every part starts on a block line: the step five blocks down, its line and Check a block apart, the keypad's
        // corner on a block too
        var stepX = 0.0, stepY = 500.0, lineY = 600.0, column = 1100.0
        /// The keypad's corner: 3 keys by 4, each 3 squares.
        var keypadX = 1000.0, keypadY = 500.0
        /// Check's row (else the bottom row, or under a tall line), and what a miss says under Check instead of beside it.
        var actions: Double? = nil
        var messageBelow = false
        /// Where the picture and the work are moved to, in paper points from the origin (ProblemGrid).
        var pictureOffset = CGPoint.zero, workOffset = CGPoint.zero
        /// The whole problem's width, in its points before scale.
        var total = 1200.0
        /// Each section's box in paper points from the origin, outlined while testing (ProblemGrid.showSections).
        var sections: [CGRect] = []
        /// Answered in the work (G 19 Oct): the answer box sits in the work where the number goes, what to do beside
        /// it, Check under the work. All in paper points from the origin.
        var inline = false
        var boxes: [WorkBox] = []
        /// The box the answer's box `id` is typed into (a box with no name is the step's first).
        func box(for id: String, first: String?) -> WorkBox? { boxes.first { ($0.id ?? first) == id } }
        var sayAt = CGPoint.zero, checkAt = CGPoint.zero, sayWidth = 400.0
        /// Stacked (a lesson on the paper, G 20 Oct): where its rows are, and the lesson's own blocks shown now.
        var stack: ProblemGrid.Stack?
        var lessonBlocks: [String] = []
    }
    /// Laid out once for its numbers and the screen's shape (ProblemGrid).
    @ObservationIgnored private var laidOut: (key: String, layout: Layout)?
    var layout: Layout {
        if stacked {
            // the plan is kept for the problem; the step's own parts (its blocks' row, its frame) are worked out from it
            let s = state()
            let key = "\(lesson.numbers) \(lesson.story) \(s.index) \(s.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(stillHand(s.hand)) \(s.run.typed.sorted { $0.key < $1.key }) \(auto) \(howToButtons)"
            if let c = laidOut, c.key == key { return c.layout }
            let l = ProblemGrid.stackedLayout(self, s)
            laidOut = (key, l)
            return l
        }
        let key = "\(lesson.numbers) \(lesson.index) \(ProblemGrid.screen) \(picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" })"
        if let c = laidOut, c.key == key { return c.layout }
        let l = ProblemGrid.layout(self)
        laidOut = (key, l)
        return l
    }
    /// A stacked problem's plan, made once (ProblemGrid.stackPlan).
    @ObservationIgnored var plan: ProblemGrid.StackPlan?

    var scale: Double { layout.scale }
    var underStep: Double { layout.lineY }
    /// The picture keys the drawing reads now: the step's, and whether its answer box is in the work.
    /// `pick`: the step is a pick-one (a story's "Pick what to do"), so the work doesn't give its answer away.
    /// `typed.<box>`: what's in each of the step's boxes.
    var drawingKeys: Numbers {
        var k = picture.merging(["box": lesson.step.answer.map { $0.choices == nil ? 1 : 0 } ?? 0, "pick": lesson.step.answer?.choices != nil ? 1 : 0]) { $1 }
        for (box, t) in lesson.typed { if let v = Double(t) { k["typed." + box] = v } }
        return k
    }
    var boxSize: Size { let l = layout; return Size((l.width * l.scale).rounded(.up) * Paper.unit, (l.height * l.scale).rounded(.up) * Paper.unit) }
    /// The box's corner stays on the strong lines; everything in it is drawn `scale` times bigger from there.
    var contentOrigin: Point { origin }
    /// A problem aimed at a step the child slipped on before (LessonPlan): that step starts with what they were told,
    /// its part of the picture lit, and, the second time, its answer shown first and taken away again.
    var focus: LessonPlan.Focus?
    /// The focus step is this step.
    var onFocus: Bool { focus.map { $0.step == lesson.index - lesson.lead } ?? false }

    init(origin: Point, chapter: Chapter, instant: Bool, run: LessonRun, label: String, auto: Bool = false) {
        self.origin = origin; self.chapter = chapter; self.instant = instant; self.label = label; self.auto = auto
        paper = PaperLessons.lesson(run.spec.id)
        lesson = run
        openedAt = instant ? PaperClock.now - 100 : PaperClock.now + 1000
        answerAhead()
    }

    var solved: Bool { lesson.isLast }
    /// Hands off while the picture proves a step (a See beat), and while the ghost finger plays.
    var busy: Bool { PaperClock.now < busyUntil || ghost != nil }
    /// What the picture shows now: the step's picture, its hints after misses, and the How to's beats.
    var picture: Numbers {
        var p = lesson.picture.merging(extra) { $1 }
        if onFocus || hinting { p.merge(lesson.step.onMiss) { $1 } }
        return p
    }

    var animating: Bool {
        let now = PaperClock.now
        return now - openedAt < 1.8 || now - wordsAt < 0.8 || now - pictureAt < 1.6 || now - keypadAt < 0.9 || now < busyUntil + 0.1
            || now - handAt < 0.4 || ghost != nil || (leftAt.map { now - $0 < 0.6 } ?? false)
    }

    func start(after delay: Double) { openedAt = time(delay); wordsAt = openedAt; pictureAt = openedAt; leftAt = nil; answerAhead(); teachIfDue(after: delay + 1.2) }

    /// The second time a step is slipped on, a problem aimed at it shows that step first (the ghost finger plays it), then
    /// gives it back for the child to do (Show me is a preview, G 17 Oct).
    private var taught = false
    private func teachIfDue(after delay: Double) {
        guard onFocus, focus?.teach == true, !taught, !instant, !solved else { return }
        taught = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.onFocus, self.ghost == nil else { return }
            self.lesson.markShown()
            self.play(.preview)
            self.onChange?()
        }
    }
    func leave() { leftAt = time(0); ghost = nil; dragging = false }
    func gone(at t: Double) -> Double { leftAt.map { 1 - ease((t - $0) / 0.5) } ?? 1 }
    func words(at t: Double) -> Double { ease((t - openedAt - 0.3) / 0.4) * gone(at: t) }
    func guide(at t: Double) -> Double { 1 }
    /// How far the picture's newest parts have drawn in.
    func fresh(at t: Double) -> Double { ease((t - pictureAt) / 0.6) }
    /// The picture growing in when the problem arrives.
    func grow(at t: Double) -> Double { ease((t - openedAt - 0.2) / 0.6) * gone(at: t) }
    func restore() { pictureAt = PaperClock.now - 100; answerAhead() }

    // MARK: what the child does

    /// Right or wrong, shown on the answer box (G 19 Oct; green and red mean only these): right for a moment before
    /// the next step comes in, wrong until the child types again.
    private(set) var verdict: (right: Bool, at: Double)?

    func go() {
        guard !busy else { return }
        if demoAnswered { demoAnswered = false; return }
        onTouch?()
        if lesson.handAnswered { goByHand(); return }
        let misses = lesson.missedSteps.count + lesson.misses
        var trial = lesson
        let out = trial.go()
        // right: the box goes green, and a moment later the next step comes in
        if case .moved = out, lesson.step.answer != nil, !instant, !auto {
            verdict = (true, PaperClock.now); message = nil
            busyUntil = PaperClock.now + 0.6
            onChange?()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                guard let self else { return }
                self.verdict = nil
                self.lesson = trial
                self.stepChanged()
                self.message = nil; self.wordsAt = PaperClock.now; self.pictureAt = self.time(0)
                self.busyUntil = self.time(0.3)
                self.teachIfDue(after: 0.8)
                if self.lesson.isLast { self.onSolved?() }
                self.onChange?()
            }
            return
        }
        lesson = trial
        // a miss is wrong (red); "Fill in every box" is only a notice (grey)
        let wrong = lesson.missedSteps.count + lesson.misses > misses
        if case .notYet = out { verdict = wrong ? (false, PaperClock.now) : nil }
        switch out {
        case .moved:
            stepChanged()
            message = nil; wordsAt = PaperClock.now; pictureAt = time(0)
            busyUntil = time(0.4)
            teachIfDue(after: 0.8)
            if lesson.isLast { onSolved?() }
        case .notYet(let line) where lesson.finalOnly && !lesson.oneTry && wrong:
            // final answer only, missed: the steps come back for this problem
            var r = LessonRun(lesson.spec, numbers: lesson.numbers, story: lesson.story)
            r.helps = lesson.helps; r.oneTry = lesson.oneTry; r.hintCap = lesson.hintCap; r.skipAsk()
            lesson = r
            message = (line, false); wordsAt = PaperClock.now; pictureAt = time(0)
        case .notYet(let line):
            message = (line, !wrong); pictureAt = time(0)
            if wrong { hinting = false }
            moveOnAfterOneTry(wrong)
        case .newProblem: break
        }
        onChange?()
    }

    /// A step answered by a hand move, checked as it's let go (G 20 Oct): right, the picture proves it (hands off a
    /// moment); wrong, what happened is said on rows 3–4, measured on the grid, and the thing goes back.
    private func goByHand() {
        let misses = lesson.missedSteps.count + lesson.misses
        var trial = lesson
        let out = trial.go()
        lesson = trial
        let wrong = lesson.missedSteps.count + lesson.misses > misses
        switch out {
        case .moved:
            stepChanged()
            message = nil; verdict = nil
            wordsAt = PaperClock.now; pictureAt = time(0)
            busyUntil = time(0.5)
            teachIfDue(after: 0.8)
            if lesson.isLast { onSolved?() }
        case .notYet(let line):
            message = (line, !wrong); pictureAt = time(0)
            if wrong { hinting = false }
            moveOnAfterOneTry(wrong)
        case .newProblem: break
        }
        onChange?()
    }

    /// One try (a check or a test): after a miss the answer is shown, and the problem moves on by itself.
    private func moveOnAfterOneTry(_ wrong: Bool) {
        guard lesson.oneTry, wrong, lesson.step.answer != nil else { return }
        busyUntil = time(1.2)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.instant == true ? 0 : 1.2))
            guard let self else { return }
            if case .moved = self.lesson.go() { self.stepChanged(); self.wordsAt = PaperClock.now; self.pictureAt = self.time(0) }
            if self.lesson.isLast { self.onSolved?() }
            self.onChange?()
        }
    }

    /// A new step: empty hands, its own hint not shown yet, and any step an earlier move already answered passed.
    private func stepChanged() {
        hand = [:]; hinting = false; dragging = false
        answerAhead()
    }

    /// Steps an earlier move already answered (the cut answers the fractions' rewrites): set and checked, so the child
    /// goes straight on.
    private func answerAhead() { Self.answerAhead(&lesson, paper) }
    static func answerAhead(_ run: inout LessonRun, _ paper: (any PaperLesson)?) {
        guard let paper else { return }
        for _ in 0..<8 {
            guard !run.isLast, let v = paper.autoAnswer(PaperState(run: run, index: run.index, picture: run.picture)) else { return }
            for (b, x) in v { run.set(b, x) }
            guard case .moved = run.go() else { return }
        }
    }

    /// The How to's moves: each step played for it by the ghost finger, and kept (the How to does the step). Returns how
    /// long it takes.
    @discardableResult
    func demonstrate() -> Double {
        guard lesson.step.answer != nil else { return 0 }
        return play(.howTo)
    }

    func choose(_ i: Int) { guard !busy else { return }; onTouch?(); lesson.choose(i); message = nil; onChange?() }
    /// A key on the keypad: a digit, ".", "-", or "del", into the chosen box.
    /// When a key was last pressed: the cursor holds still a moment after, then blinks.
    @ObservationIgnored private(set) var typedAt: Double = 0
    func type(_ key: String) {
        guard !busy, !solved, !lesson.handAnswered else { return }
        typedAt = PaperClock.now
        onTouch?()
        if key == "-" { lesson.type("del"); return }
        lesson.type(key)
        if message?.ok == false { message = nil }
        if verdict?.right == false { verdict = nil }
        onChange?()
    }
    func select(_ box: String) {
        onTouch?(); lesson.active = box
        if !keypadOpen { keypadOpen = true; keypadAt = time(0) }
        boxTapped += 1
        onChange?()
    }
    /// How many times a box has been tapped: each tap brings the iPad's number keys back up (NumberEntry), even after
    /// the child put them away.
    private(set) var boxTapped = 0

    /// Show me (G 17 Oct, 20 Oct): a preview, never the child's work. The ghost finger plays the step's moves on a copy
    /// of the problem, the picture following it, holds, and everything goes back as the child left it; the step only
    /// counts as shown.
    func showMe() {
        guard lesson.helps, !busy, !solved, lesson.step.answer != nil else { return }
        onTouch?()
        lesson.markShown()
        play(.preview)
        onChange?()
    }

    /// The hint (the bar's Hint): the step's hint written on rows 3–4, its part of the picture lit.
    func showHint() {
        // only a lesson on the paper draws its hint (rows 3–4 and its part of the picture), and counts it; the others'
        // hint is the page's to write (nothing drawn here, nothing counted)
        guard stacked, !solved, lesson.step.answer != nil || lesson.step.task != nil else { return }
        lesson.usedHint()
        hinting = true
        if message?.ok == false { message = nil }
        pictureAt = time(0)
        onChange?()
    }

    /// A hand move's result (LessonHands): the hand state after it, the boxes it sets, and, when it answers the step, the
    /// check, as Check would. A miss (or a notice) puts the hand back where the lesson says.
    func apply(_ mv: HandMove) {
        onTouch?()
        if let h = mv.hand { hand = h }
        for (box, v) in mv.set { lesson.set(box, v) }
        for cell in mv.marks { lesson.tap(cell) }
        if message?.ok == false { message = nil }
        if verdict?.right == false { verdict = nil }
        handAt = PaperClock.now
        guard mv.check else { onChange?(); return }
        let at = lesson.index
        go()
        if lesson.index == at, !solved, let back = mv.missHand { hand = back }
    }

    /// Screenshots only: the step answered as a child would (a hand step by its moves, a typed one typed, a pick
    /// picked), then checked; or, `wrong`, a slip.
    func answerForShots(wrong: Bool = false) {
        guard let a = lesson.step.answer else { go(); return }
        if wrong {
            if a.byHand, let paper, let mv = paper.wrongMove(state()) { apply(mv) }
            else if a.choices != nil { choose((Int(a.expected["c"] ?? 0) + 1) % (a.choices?.count ?? 1)); go() }
            else { type("1"); go() }
            return
        }
        if a.choices != nil { choose(Int(a.expected["c"] ?? 0)); go(); return }
        // the ghost's moves made at once and kept, then checked as Check would
        ghost = GhostPlay(mode: .keep, start: PaperClock.now, run: lesson, hand: hand, moves: ghostMoves(state()))
        fireGhost(upTo: .infinity)
        if let g = ghost { lesson = g.run; hand = g.hand }
        ghost = nil
        // anything the moves didn't fill (a lesson with no demo for a step) is answered with what's expected
        for (b, v) in a.expected where (lesson.typed[b] ?? "").isEmpty { lesson.set(b, v) }
        go()
    }

    func reset() { guard !busy else { return }; onTouch?(); lesson.reset(); hand = [:]; message = nil; verdict = nil; onChange?() }
    func usedHint() { lesson.usedHint(); onChange?() }
    func tapPaper(_ p: Point) { _ = handTap(p) }

    /// Screenshots only: these numbers instead of the generated ones (and a story, when asked).
    func use(_ n: Numbers, story: Bool = false) {
        var r = LessonRun(lesson.spec, numbers: n, story: story)
        r.helps = lesson.helps; r.oneTry = lesson.oneTry; r.guided = lesson.guided; r.hintCap = lesson.hintCap
        if lesson.skipsAsk { r.skipAsk() }
        lesson = r; hand = [:]; ghost = nil; plan = nil; laidOut = nil
    }

    func replay() {
        var r = LessonRun(lesson.spec, numbers: lesson.numbers); r.helps = lesson.helps; r.oneTry = lesson.oneTry
        lesson = r
        message = nil; busyUntil = 0; extra = [:]; hand = [:]; ghost = nil; hinting = false; demoAnswered = false
        openedAt = time(0); wordsAt = openedAt; pictureAt = openedAt
    }

    /// The lesson's own explaining beats (LessonPictures, for the lessons not on the paper yet), each turning on part of
    /// the picture.
    func howToBeats() -> [(words: String, run: () -> Void)] {
        guard !stacked else { return [] }
        return LessonPictures.beats(lesson.spec.id, lesson.numbers).map { beat in
            (beat.words, { [weak self] in guard let self else { return }; self.extra = beat.picture; self.pictureAt = self.time(0) })
        }
    }
    /// The beats are over: the steps draw the picture from here.
    func endBeats() { extra = [:] }

    // MARK: what's drawn

    /// What the lesson draws from now: the ghost's problem while it plays, else the child's. `t`: the moment, for the
    /// hand as the ghost drags it.
    func state(at t: Double? = nil) -> PaperState {
        let run = ghost?.run ?? lesson
        var s = PaperState(run: run, index: run.index)
        var pic = run.picture.merging(extra) { $1 }
        if (onFocus || hinting) && run.index == lesson.index { pic.merge(run.step.onMiss) { $1 } }
        s.picture = pic
        s.typed = run.typed
        s.faint = ghost?.mode == .preview
        s.verdict = ghost == nil ? verdict?.right : nil
        s.active = run.active
        s.hand = ghost?.hand ?? hand
        // the ghost finger dragging: the hand where the finger is now, as the lesson's drag would have it (the live
        // parts follow the finger)
        if let t, let g = ghost, let base = g.held, let p = g.dragPoint(at: g.time(t)), let paper {
            var held = s; held.hand = base
            if let d = paper.hands(held)?.drag { s.hand = d(p, base) }
        }
        return s
    }
    /// The hand state the still picture reads (the lesson's live keys left out).
    func stillHand(_ h: Numbers) -> String {
        let live = paper?.liveKeys ?? []
        return h.filter { !live.contains($0.key) }.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined(separator: ",")
    }

    /// Rows 3–4 (G 20 Oct): what a miss says (red; a notice grey), or the hint (grey), or, on a step slipped on before,
    /// what the child was told then.
    var rowsWords: (text: String, colour: Sketch.Colour)? {
        let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
        if let m = message { return (m.text, m.ok ? .ink2 : red) }
        if hinting, !lesson.words.hint.isEmpty { return (lesson.words.hint, .ink2) }
        if onFocus, let said = focus?.said { return (said, .ink2) }
        return nil
    }

    /// A record box the drawing shows is the step's to fill: the iPad's keyboard comes up for it, and only for it.
    var wantsTyping: Bool {
        guard !auto, !solved, let a = lesson.step.answer, a.choices == nil, !a.byHand else { return false }
        guard stacked else { return true }
        return layout.boxes.contains { b in a.boxes.contains(b.id ?? "") }
    }

    /// A stacked problem's frame for the step it's on (the plan's rectangle for it), in paper points: what the camera
    /// shows, never past 125%. Nil for the side-by-side layout (the camera frames what's drawn).
    var stageFrame: Rect? {
        // Show me is a preview: the camera holds still while it plays, even when its copy moves on a stage
        if ghost?.mode == .preview, let held = heldFrame { return held }
        guard let st = layout.stack else { return nil }
        var r = st.frame
        // a docked keyboard up for the record's box: the record and its blocks, framed in the paper above it (beside a
        // tall picture, the record's column, down to its blocks)
        if Self.keyboard > 0, wantsTyping {
            let top = (st.plan.recordTop - 1) * Paper.cell
            if st.plan.beside {
                let left = (st.plan.recordLeft - 2) * Paper.cell, bottom = (st.blocksTop + 2 * st.plan.k) * Paper.cell
                r = CGRect(x: left, y: top, width: max(2 * Paper.cell, r.maxX - left), height: max(2 * Paper.cell, bottom - top))
            } else {
                r = CGRect(x: r.minX, y: top, width: r.width, height: max(2 * Paper.cell, r.maxY - top))
            }
        }
        let f = Rect(x: origin.x + r.minX, y: origin.y + r.minY, width: r.width, height: r.height)
        heldFrame = f
        return f
    }
    @ObservationIgnored private var heldFrame: Rect?
    /// How much of the screen's bottom a docked keyboard covers (PaperScreen sets it; iPadOS's floating number pad
    /// covers only its corner and counts as none).
    static var keyboard: Double = 0

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }

    // MARK: the ghost finger

    /// The step's moves for the ghost: the lesson's own for a hand step; a pick tapped; a typed step's answer written.
    func ghostMoves(_ s: PaperState) -> [GhostMove] {
        guard let a = s.step.answer else { return [] }
        if a.choices != nil { return [.tap(.choice(Int(a.expected["c"] ?? 0)))] }
        if a.byHand { return paper?.demo(s) ?? [] }
        return a.boxes.compactMap { b in a.expected[b].map { .write(box: b, text: fmt($0).replacingOccurrences(of: "−", with: "-")) } }
    }

    /// Plays the step's moves with the ghost finger: a preview (Show me) on a copy that goes back at the end, or the
    /// How to, kept. `frozen`: screenshots, stopped at that moment. Returns how long it plays.
    @discardableResult
    func play(_ mode: GhostPlay.Mode, frozen: Double? = nil) -> Double {
        let moves = ghostMoves(state())
        guard !moves.isEmpty else { return 0 }
        var g = GhostPlay(mode: mode, start: PaperClock.now, run: lesson, hand: hand, moves: moves)
        g.frozen = frozen
        ghost = g
        spotsSeen = []
        // where its blocks are as it starts (it may press one that goes as its move answers the step)
        for mv in moves { if case .tap(let spot) = mv { _ = point(of: spot) } }
        message = nil
        if instant && frozen == nil {
            // Reduce Motion: straight to the step done, no finger moving; Show me holds it a moment, then puts it back
            fireGhost(upTo: .infinity)
            guard mode == .preview, var held = ghost else { endGhost(); return 0 }
            held.frozen = held.end
            ghost = held
            let id = held.id
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.6))
                guard let self, self.ghost?.id == id else { return }
                self.endGhost()
            }
            return 0
        }
        if let frozen { fireGhost(upTo: frozen); return 0 }
        let id = g.id
        Task { [weak self] in
            while let self, let g = self.ghost, g.id == id {
                let t = g.time(PaperClock.now)
                self.fireGhost(upTo: t)
                guard let now = self.ghost, now.id == id else { return }
                let end = now.mode == .howTo ? now.done + GhostPlay.fade : now.end
                if t >= end { self.endGhost(); return }
                try? await Task.sleep(for: .seconds(0.03))
            }
        }
        return (mode == .howTo ? g.done + GhostPlay.fade : g.end)
    }

    /// The moves made so far, in order: on the ghost's copy (a preview checks each one, so it shows what the step
    /// does), or the How to's own (kept for the How to's Next to check).
    private func fireGhost(upTo t: Double) {
        guard var g = ghost else { return }
        while g.fired < g.events.count, g.events[g.fired].t <= t {
            let e = g.events[g.fired]
            g.fired += 1
            switch (g.moves[e.move], e.what) {
            case (.tap(let spot), .tap): ghostTap(spot, &g)
            case (.drag(let from, _), .grab):
                if let paper, let held = paper.hands(ghostState(g))?.grab?(from) { g.held = held; g.hand = held }
            case (.drag(_, let to), .release):
                if let paper, let base = g.held {
                    var s = ghostState(g); s.hand = base
                    if let h = paper.hands(s) {
                        let at = h.drag?(to, base) ?? base
                        if let r = h.release { ghostApply(r(at), &g) }
                    }
                }
                g.held = nil
            case (.write(let box, let text), .write):
                g.run.set(box, nil); g.run.active = box
                for ch in text { g.run.type(String(ch)) }
            default: break
            }
        }
        ghost = g
    }

    private func ghostState(_ g: GhostPlay) -> PaperState {
        var s = PaperState(run: g.run, index: g.run.index, hand: g.hand, picture: g.run.picture)
        s.typed = g.run.typed
        return s
    }

    private func ghostTap(_ spot: GhostSpot, _ g: inout GhostPlay) {
        switch spot {
        case .picture(let p): if let paper, let mv = paper.hands(ghostState(g))?.tap?(p) { ghostApply(mv, &g) }
        case .action(let name): if let paper, let act = paper.hands(ghostState(g))?.actions[name] { ghostApply(act(), &g) }
        case .choice(let i):
            g.run.choose(i)
            if g.mode == .preview, case .moved = g.run.go() { g.hand = [:]; Self.answerAhead(&g.run, paper) }
        case .check:
            if g.mode == .preview, case .moved = g.run.go() { g.hand = [:]; Self.answerAhead(&g.run, paper) }
        case .box(let id): g.run.active = id
        case .beside: break
        }
    }

    private func ghostApply(_ mv: HandMove, _ g: inout GhostPlay) {
        if let h = mv.hand { g.hand = h }
        for (b, v) in mv.set { g.run.set(b, v) }
        for cell in mv.marks { g.run.tap(cell) }
        // a move that answers its step does it, as the child's would: Show me's copy shows it, the How to keeps it
        guard mv.check, g.mode != .keep else { return }
        let i = g.run.index
        if case .moved = g.run.go() { g.hand = [:]; Self.answerAhead(&g.run, paper) }
        else if g.run.index == i, let mh = mv.missHand { g.hand = mh }
    }

    /// The How to's move already answered its step (its Cut cut, its point hopped): the How to's Next only goes on.
    private var demoAnswered = false

    /// The ghost is done: Show me's copy is dropped (everything as the child left it); the How to keeps its moves.
    private func endGhost() {
        guard let g = ghost else { return }
        ghost = nil
        if g.mode != .preview {
            let moved = g.run.index != lesson.index
            lesson = g.run; hand = g.hand
            if moved { demoAnswered = true; stepChanged(); wordsAt = PaperClock.now }
        }
        pictureAt = time(0)
        onChange?()
    }

    /// Where a ghost spot is on the paper now, in paper points. A block the finger pressed can go as its move answers
    /// the step (the Cut block once it's cut): the finger then lifts away from where it was.
    func point(of spot: GhostSpot) -> CGPoint? {
        let l = layout, o = contentOrigin
        let found: CGPoint?
        switch spot {
        case .picture(let p): found = CGPoint(x: o.x + l.pictureOffset.x + p.x * Paper.cell, y: o.y + l.pictureOffset.y + p.y * Paper.cell)
        case .action(let name): found = ProblemLayout.blocks(self).first { $0.kind == .action(name) }.map { CGPoint(x: $0.rect.midX, y: $0.rect.midY) }
        case .check: found = ProblemLayout.blocks(self).first { $0.kind == .main }.map { CGPoint(x: $0.rect.midX, y: $0.rect.midY) }
        case .choice(let i): found = ProblemLayout.blocks(self).first { $0.kind == .choice(i) }.map { CGPoint(x: $0.rect.midX, y: $0.rect.midY) }
        case .box(let id): found = ProblemLayout.blocks(self).first { $0.kind == .field(id) }.map { CGPoint(x: $0.rect.midX, y: $0.rect.midY) }
        case .beside(let id): found = ProblemLayout.blocks(self).first { $0.kind == .field(id) }.map { CGPoint(x: $0.rect.maxX + Paper.cell, y: $0.rect.maxY + Paper.cell) }
        }
        if let found { spotsSeen.removeAll { $0.spot == spot }; spotsSeen.append((spot, found)); return found }
        return spotsSeen.last { $0.spot == spot }?.at
    }
    /// Where the ghost's spots last were (for a block that's gone since).
    @ObservationIgnored private var spotsSeen: [(spot: GhostSpot, at: CGPoint)] = []

    /// The ghost finger as it is at `t`: where (paper points), pressing or not, the trail behind it, how much shows.
    func ghostFinger(at t: Double) -> (at: CGPoint, down: Bool, trail: [CGPoint], shows: Double)? {
        guard let g = ghost else { return nil }
        let now = g.time(t)
        func place(_ time: Double) -> (CGPoint, Bool, Double)? {
            guard let f = g.finger(at: time), let a = point(of: f.from) ?? point(of: f.to) else { return nil }
            let b = point(of: f.to) ?? a
            return (CGPoint(x: a.x + (b.x - a.x) * f.k, y: a.y + (b.y - a.y) * f.k), f.down, f.shows)
        }
        guard let p = place(now) else { return nil }
        var trail: [CGPoint] = []
        for k in 1...3 { if let q = place(now - 0.05 * Double(k))?.0, hypot(q.x - p.0.x, q.y - p.0.y) > 3 { trail.append(q) } }
        // where it first comes in from: a little below and to the right of its first place
        if now < 0.25, trail.isEmpty { return (CGPoint(x: p.0.x + 24 * (1 - now / 0.25), y: p.0.y + 24 * (1 - now / 0.25)), false, [], p.2) }
        return (p.0, p.1, trail, p.2)
    }
}
