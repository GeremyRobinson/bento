import SwiftUI

/// One problem of a lesson worked in typed steps, live where it sits on its page (BarsPage). Top to bottom in its box:
/// the problem (a story, then the sum written as school writes it), the picture (a Sketch the lesson draws: the work
/// laid out as at school beside the picture that explains it), then the step: its words, the line being worked with
/// its boxes, what a miss says, and Check. The keypad types into the box that's chosen.
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

    // where things sit, in paper points from `origin`, inside the box (BarsPage.box): the problem above the origin, the
    // picture from the origin down, then the step
    /// The sum's row starts on the block line one block above the picture.
    static let problemY: Double = -100
    /// The line being worked is written big for kids (G 19 Oct): two squares to a digit, like the sum at the top.
    static let lineCell: Double = 2
    /// Obento²'s own keypad drawn on the paper; off while the iPad's keyboard types (G 19 Oct).
    static let drawnKeys = false

    /// Where things sit in an open problem, in points from its origin before `scale`. An open problem is its own space
    /// on the grid, with no frame, filling the screen (G 19 Oct): 13 blocks by 9, its picture drawn 1.6 times its size
    /// across the top, the step under it, Check and what a miss says on the bottom row. A lesson can lay itself out
    /// (LessonPictures.layout); when its maths is too big for the screen, everything but its true-size picture is
    /// drawn `scale` times bigger, and the camera steps back to see it all.
    struct Layout {
        var scale = 1.0
        var width = 13.0, height = 10.0
        // every part starts on a block line: the picture at the top, the step five blocks down, its line and Check a
        // block apart, the keypad's corner on a block too
        var pictureTop = 0.0, pictureScale = 1.6
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
    }
    /// Laid out once for its numbers and the screen's shape (ProblemGrid).
    @ObservationIgnored private var laidOut: (key: String, layout: Layout)?
    var layout: Layout {
        let key = "\(lesson.numbers) \(ProblemGrid.screen)"
        if let c = laidOut, c.key == key { return c.layout }
        let l = ProblemGrid.layout(self)
        laidOut = (key, l)
        return l
    }
    var scale: Double { layout.scale }
    var underStep: Double { layout.lineY }
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
        lesson = run
        openedAt = instant ? PaperClock.now - 100 : PaperClock.now + 1000
    }

    var solved: Bool { lesson.isLast }
    var busy: Bool { PaperClock.now < busyUntil }
    /// What the picture shows now: the step's picture, its hints after misses, and the How to's beats.
    var picture: Numbers {
        var p = lesson.picture.merging(extra) { $1 }
        if onFocus { p.merge(lesson.step.onMiss) { $1 } }
        return p
    }

    var animating: Bool {
        let now = PaperClock.now
        return now - openedAt < 1.8 || now - wordsAt < 0.8 || now - pictureAt < 1.6 || now - keypadAt < 0.9 || now < busyUntil + 0.1 || (leftAt.map { now - $0 < 0.6 } ?? false)
    }

    func start(after delay: Double) { openedAt = time(delay); wordsAt = openedAt; pictureAt = openedAt; leftAt = nil; teachIfDue(after: delay + 1.2) }

    /// The second time a step is slipped on, a problem aimed at it shows that step's answer first, then takes it away
    /// for the child to do (Show me is a preview, G 17 Oct).
    private var taught = false
    private func teachIfDue(after delay: Double) {
        guard onFocus, focus?.teach == true, !taught, !instant, !solved else { return }
        taught = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.onFocus else { return }
            if let e = self.lesson.showAnswer() { self.message = (e, true) }
            self.pictureAt = self.time(0); self.onChange?()
            try? await Task.sleep(for: .seconds(2.4))
            self.lesson.reset(); self.message = nil; self.wordsAt = PaperClock.now; self.onChange?()
        }
    }
    func leave() { leftAt = time(0) }
    func gone(at t: Double) -> Double { leftAt.map { 1 - ease((t - $0) / 0.5) } ?? 1 }
    func words(at t: Double) -> Double { ease((t - openedAt - 0.3) / 0.4) * gone(at: t) }
    func guide(at t: Double) -> Double { 1 }
    /// How far the picture's newest parts have drawn in.
    func fresh(at t: Double) -> Double { ease((t - pictureAt) / 0.6) }
    /// The picture growing in when the problem arrives.
    func grow(at t: Double) -> Double { ease((t - openedAt - 0.2) / 0.6) * gone(at: t) }
    func restore() { pictureAt = PaperClock.now - 100 }

    // MARK: what the child does

    /// Right or wrong, shown on the answer box (G 19 Oct; green and red mean only these): right for a moment before
    /// the next step comes in, wrong until the child types again.
    private(set) var verdict: (right: Bool, at: Double)?

    func go() {
        guard !busy else { return }
        onTouch?()
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
            // one try (a check or test): the answer is shown, and the problem moves on
            if lesson.oneTry, lesson.step.answer != nil {
                busyUntil = time(1.2)
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(self?.instant == true ? 0 : 1.2))
                    guard let self else { return }
                    if case .moved = self.lesson.go() { self.wordsAt = PaperClock.now; self.pictureAt = self.time(0) }
                    if self.lesson.isLast { self.onSolved?() }
                    self.onChange?()
                }
            }
        case .newProblem: break
        }
        onChange?()
    }

    /// The How to's moves: each step's answer written in for it. Returns how long it takes.
    @discardableResult
    func demonstrate() -> Double {
        if let a = lesson.step.answer {
            if a.choices != nil { lesson.choose(Int(a.expected["c"] ?? 0)) } else { _ = lesson.showAnswer() }
            return 0.8
        }
        return 0
    }

    func choose(_ i: Int) { guard !busy else { return }; onTouch?(); lesson.choose(i); message = nil; onChange?() }
    /// A key on the keypad: a digit, ".", "-", or "del", into the chosen box.
    func type(_ key: String) {
        guard !busy, !solved else { return }
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
        onChange?()
    }

    /// Show me: the step's answer written in, with why.
    func showMe() {
        guard lesson.helps, !busy, lesson.step.answer != nil else { return }
        onTouch?()
        if let e = lesson.showAnswer() { message = (e, true) }
        onChange?()
    }
    func reset() { guard !busy else { return }; onTouch?(); lesson.reset(); message = nil; onChange?() }
    func usedHint() { lesson.usedHint(); onChange?() }
    func tapPaper(_ p: Point) {}

    func replay() {
        var r = LessonRun(lesson.spec, numbers: lesson.numbers); r.helps = lesson.helps; r.oneTry = lesson.oneTry
        lesson = r
        message = nil; busyUntil = 0; extra = [:]
        openedAt = time(0); wordsAt = openedAt; pictureAt = openedAt
    }

    /// The lesson's own explaining beats (LessonPictures), each turning on part of the picture.
    func howToBeats() -> [(words: String, run: () -> Void)] {
        LessonPictures.beats(lesson.spec.id, lesson.numbers).map { beat in
            (beat.words, { [weak self] in guard let self else { return }; self.extra = beat.picture; self.pictureAt = self.time(0) })
        }
    }
    /// The beats are over: the steps draw the picture from here.
    func endBeats() { extra = [:] }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }
}
