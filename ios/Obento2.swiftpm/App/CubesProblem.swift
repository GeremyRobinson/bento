import SwiftUI

/// One problem of Volume of a box on its lesson's page (BarsPage), built on Unit cubes (G 20 Oct: anything 3D builds on
/// Unit cubes; design/grade5.md). One cube is one block of the paper, 1 cm each way.
///
/// It opens flat: the box's floor outlined on the paper's strong lines, its length and width beside it. The child covers
/// the floor (a tap covers a square, a drag sweeps a rectangle of them), the squares counting up. Then the paper tilts
/// and the floor rises into the first layer, Unit cubes' way; the child drags up (or taps) to stack the layers, each
/// one's own count written on its front (the same on every layer), the box's full height dashed where the box is still
/// empty. The record stands facing the child beside the box (under it on a screen held upright), and its last number,
/// how many in all, is the child's to work out and type. The paper lies flat again before the next problem, the page or
/// the map. Show me plays the hand move with a ghost finger and puts everything back; the How to plays it and keeps it.
@MainActor @Observable
final class CubesProblem: Identifiable, PageProblem, CubesPicture, TiltOwner {
    let id = UUID()
    var label: String
    let auto: Bool
    /// The page's corner for its problems (BarsPage.origin): the floor's left edge is on it, a block under the words.
    let origin: Point
    let chapter: Chapter
    /// Cut straight to every state (Reduce Motion; screenshots).
    var instant: Bool
    private(set) var lesson: LessonRun
    var message: (text: String, ok: Bool)? { didSet { wordsAt = PaperClock.now } }
    var intro: String? { didSet { if intro != oldValue { wordsAt = PaperClock.now } } }
    var howToButtons: [ProblemLayout.Kind] = [] { didSet { wordsAt = PaperClock.now } }
    var onSolved: (() -> Void)?
    var onTouch: (() -> Void)?
    var onChange: (() -> Void)?
    var needs: ((Rect) -> Void)?
    /// A problem aimed at a step the child slipped on before (LessonPlan): that step starts with what to keep in mind
    /// there (the step's own hint in this problem's numbers: what the child was told was about other numbers) and its
    /// part of the picture lit; the same slip twice, its answer is shown first and taken away again (the app's
    /// teaching, not the child's Show me).
    var focus: LessonPlan.Focus?
    /// The step being worked is the one aimed at.
    var onFocus: Bool { focus.map { $0.step == lesson.index - lesson.lead } ?? false }

    init(origin: Point, chapter: Chapter, instant: Bool, run: LessonRun, label: String, auto: Bool = false) {
        self.origin = origin; self.chapter = chapter; self.instant = instant; self.label = label; self.auto = auto
        lesson = run
        let opened = instant ? PaperClock.now - 100 : PaperClock.now + 1000
        openedAt = opened; wordsAt = opened
    }

    // MARK: where it is

    var box: UnitCubes.Box { UnitCubes.Box(lesson.numbers) }
    /// The floor's back-left corner: on the page's left edge, five rows (a block) under the top of its box, where the
    /// words are.
    var corner: Vec3 { Vec3(origin.x / Paper.unit, 0, (origin.y + BarsPage.box.dy) / Paper.unit + 1) }
    /// The floor, in paper points.
    var floorRect: CGRect {
        let c = corner, b = box
        return CGRect(x: c.x * Paper.unit, y: c.z * Paper.unit, width: Double(b.length) * Paper.unit, height: Double(b.width) * Paper.unit)
    }
    var solved: Bool { lesson.isLast }
    var busy: Bool { PaperClock.now < busyUntil }
    var underStep: Double { 0 }
    /// Its box on the paper, flat (BarsPage.box): the words over the floor, the floor with its labels, the count and
    /// the blocks under it, in whole blocks.
    var boxSize: Size {
        let f = floorRect, b = BarsPage.box
        let left = origin.x + b.dx, top = origin.y + b.dy
        // flat, under the floor are its length, the count of squares and the How to's block (a block's room in all):
        // the camera frames just that, so a big floor is as big as it can be
        let right = max(f.maxX + Paper.unit, origin.x + Self.wordsWidth), bottom = f.maxY + 2 * Paper.unit
        return Size(((right - left) / Paper.unit).rounded(.up) * Paper.unit, ((bottom - top) / Paper.unit).rounded(.up) * Paper.unit)
    }
    /// How wide what to do may run before it wraps.
    static let wordsWidth = 680.0
    /// The rect the flat camera frames while the problem lies flat.
    var frameRect: Rect { BarsPage.box(of: self) }

    // MARK: when things happen

    private(set) var openedAt: Double
    private(set) var wordsAt: Double
    private(set) var leftAt: Double?
    private(set) var busyUntil: Double = 0
    /// Each floor square: when the child last covered or uncovered it (or when the How to's hand reaches it).
    private(set) var squares: [Int: (on: Bool, at: Double)] = [:]
    /// The paper starts to tilt; the floor starts rising into the first layer, cube by cube.
    private(set) var liftAt: Double?
    private(set) var riseAt: Double?
    /// The layers stacked on the first (1 ..< height): rising (up) or sinking, since when.
    private(set) var built: [Int: (up: Bool, at: Double)] = [:]
    /// The box's full height, dashed, draws in from then (while it's being built).
    private(set) var wireAt: Double?
    /// The cubes sinking back into the paper, leaving.
    private(set) var sinkAt: Double?
    /// The paper lying flat again: since when, for how long, from which view.
    private(set) var flatAt: Double?
    @ObservationIgnored private var flatFrom: PaperView3D?
    @ObservationIgnored private var flatTime = TiltCamera.away
    /// The tilted camera, from the moment the paper tilts until it lies flat again.
    private(set) var camera: TiltCamera?
    /// What the tilted view was last fitted to (the room under it, the screen): a keyboard coming up fits it again.
    @ObservationIgnored private var fitted: (bottom: Double, screen: Size)?
    /// The record's answer box: right (green) for a moment, wrong (red) until the child types again.
    private(set) var verdict: (right: Bool, at: Double)?
    /// One try: the child's own number, shown red while the answer they were given waits to be written.
    private(set) var wrongTyped: String?
    @ObservationIgnored private(set) var typedAt: Double = 0
    /// Show me (a preview, put back after) or the How to's hand (kept).
    private(set) var preview: Preview?
    /// The ghost finger making the hand move, on the paper.
    private(set) var finger: Finger?

    struct Preview {
        enum Kind { case cover, build, answer }
        let kind: Kind
        let at: Double, end: Double
        /// When each square's (or layer's) preview starts.
        var cells: [Int: Double] = [:]
        var layers: [Int: Double] = [:]
        static let hold = 0.9, fade = 0.4
    }
    struct Finger {
        let from: Vec3, to: Vec3, start: Double, duration: Double
        func at(_ t: Double) -> Vec3 { from.lerp(to, max(0, min(1, (t - start) / duration))) }
        /// How much of it shows: it comes down onto the paper, makes the move, and lifts off.
        func shown(_ t: Double) -> Double { min(ease((t - start + 0.25) / 0.25), 1 - ease((t - start - duration - 0.05) / 0.3)) }
        /// Pressing: while it drags.
        func down(_ t: Double) -> Bool { t >= start && t <= start + duration }
        var end: Double { start + duration + 0.4 }
    }

    /// Hands off until then; and everything moving has stopped then.
    private var until: Double {
        var u = max(busyUntil, wordsAt + 2.0, openedAt + 1.8)
        if riseAt != nil { u = max(u, rose) }
        for b in built.values { u = max(u, b.at + 0.5) }
        for s in squares.values { u = max(u, s.at + 0.35) }
        if let p = preview { u = max(u, p.end) }
        if let f = finger { u = max(u, f.end) }
        if let w = wireAt { u = max(u, w + 0.7) }
        if let s = sinkAt { u = max(u, s + 0.5) }
        if let f = flatAt { u = max(u, f + flatTime) }
        if let l = leftAt { u = max(u, l + 0.7) }
        if let v = verdict { u = max(u, v.at + 0.7) }
        if let c = camera, c.moving { u = max(u, c.lands) }
        return u
    }
    var animating: Bool { PaperClock.now < until + 0.1 }
    /// The record's box wants a number and the cursor blinks in it (CubesWords): the clock wakes only for its blink.
    var cursorSince: Double? { wantsTyping && preview == nil && verdict == nil ? typedAt : nil }

    /// The record's box wants a number (the iPad's number keys come up; the cursor blinks). The keys stay up while Show
    /// me plays the number into the box, so the paper doesn't jump as they go down and come back.
    var wantsTyping: Bool { !auto && !solved && leftAt == nil && lesson.step.answer != nil }
    /// Laid out the paper lessons' way (what to do over the picture, the record by it): the number pad comes up in the
    /// screen's bottom-right corner, clear of the box and the record (NumberEntry.anchor).
    var stacked: Bool { true }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }
    private func touched() { wordsAt = PaperClock.now }

    // MARK: on the paper, and off it

    func start(after delay: Double) {
        // the problem before it still lying flat again (Next problem from one that stood tilted): it draws in once the
        // paper is flat
        var delay = delay
        if let o = TiltCamera.owner, o !== self, let e = o.flatEnds { delay = max(delay, e - PaperClock.now + 0.05) }
        // reopened after it lay flat again: it rises again from its covered floor
        if flatAt != nil || leftAt != nil { settleFlat() }
        openedAt = time(delay); wordsAt = openedAt; leftAt = nil; message = nil; verdict = nil
        // the squares the child covered before come back as the floor draws in, not at once over the page of cards
        // still leaving (G 29 Oct)
        // (those still kept from before it left too: they grow in again)
        for i in lesson.marks.keys where i < box.floor && (squares[i] == nil || squares[i]?.on == true) { squares[i] = (true, instant ? openedAt - 100 : openedAt + 0.35) }
        if lesson.step.camera == .tilted && liftAt == nil { lift(at: openedAt + 0.9, again: true) }
        // the camera comes in to it once the cards have gone, not while they're still leaving
        if instant || delay <= 0 { needs?(frameRect) } else {
            let k = openedAt
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard let self, self.openedAt == k, self.leftAt == nil else { return }
                self.needs?(self.frameRect)
            }
        }
        teachIfDue(after: delay + 1.2)
    }

    /// It's on the paper again as the child left it, at once.
    func restore() { for i in lesson.marks.keys where i < box.floor { squares[i] = (true, PaperClock.now - 100) } }

    /// Leaving: the cubes sink back into the paper, the paper lies flat again, the words undraw.
    func leave() {
        leftAt = time(0)
        preview = nil; finger = nil
        lieFlat()
    }
    func gone(at t: Double) -> Double { leftAt.map { 1 - ease((t - $0) / 0.5) } ?? 1 }
    func words(at t: Double) -> Double { ease((t - openedAt - 0.3) / 0.4) * gone(at: t) }
    func guide(at t: Double) -> Double { 1 }

    /// Off the page (its How to played straight through, the page closed): it lies flat again; a tilt that hasn't
    /// started yet doesn't.
    func lieFlat() {
        guard camera != nil, flatAt == nil else { return }
        if anchored { flatten(TiltCamera.away) } else { settleFlat() }
    }

    /// The paper stands tilted (or is still lying flat again): its view is the paper's.
    var holdsCamera: Bool { camera != nil && (flatAt.map { PaperClock.now - $0 < flatTime } ?? true) }
    var flatEnds: Double? { flatAt.map { $0 + flatTime }.flatMap { camera != nil && $0 > PaperClock.now ? $0 : nil } }

    private func flatten(_ duration: Double) {
        let now = PaperClock.now
        flatFrom = camera?.view(at: now); flatTime = instant ? 0.0001 : duration * Self.slow
        flatAt = now; sinkAt = sinkAt ?? now
    }

    /// Flat again, and nothing standing: ready to rise again from the floor.
    private func settleFlat() {
        if TiltCamera.owner === self { TiltCamera.owner = nil }
        camera = nil; anchored = false; before = nil; flatAt = nil; flatFrom = nil; liftAt = nil; riseAt = nil; built = [:]; wireAt = nil; sinkAt = nil; fitted = nil
    }

    /// The How to again (its own Watch again, or Watch again from the menu): the cubes sink, the paper lies flat, and it
    /// starts over on a bare floor, on the paper again: from the menu it comes after the How to drew itself out, so it
    /// draws itself in again (a How to still drawn out would be blank, and its moves wait for it).
    func replay() {
        var r = LessonRun(lesson.spec, numbers: lesson.numbers); r.helps = lesson.helps; r.oneTry = lesson.oneTry
        lesson = r
        message = nil; verdict = nil; preview = nil; finger = nil; busyUntil = 0
        hinting = false; wrongTyped = nil; typedAt = 0; pending += 1; sweep = nil; lifting = nil
        let tilted = holdsCamera
        lieFlat()
        squares = [:]
        leftAt = nil
        openedAt = time(tilted ? 0.55 : 0); wordsAt = openedAt
        guard tilted, !instant else { settleFlat(); return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.55))
            guard let self, self.flatAt != nil else { return }
            self.settleFlat()
        }
    }

    // MARK: the camera, while the paper stands tilted

    /// The tilt has started from the flat camera's view (on the first frame of it, so it starts exactly where the
    /// paper is then).
    @ObservationIgnored private var anchored = false
    /// The problem the paper was seen through before this one, while it finishes lying flat again.
    @ObservationIgnored private var before: (any TiltOwner)?

    /// Only reads (it's asked while a frame is drawn): what changes the camera happens in `settle`, between frames.
    func view(at t: Double, flat: PaperView3D) -> PaperView3D? {
        // the problem before it is still lying flat again (Next problem onto one that stood tilted): its view until then
        if let b = before, b.holdsCamera, let v = b.view(at: t, flat: flat) { return v }
        if let f = flatAt {
            let u = (t - f) / flatTime
            guard u < 1 else { return nil }
            return .between(flatFrom ?? flat, flat, u)
        }
        guard let c = camera, let at = liftAt, t >= at else { return nil }
        // the tilt's first frame: it starts exactly where the flat paper is (settle starts the move from there)
        return anchored ? c.view(at: t) : flat
    }

    /// Between frames (TiltCamera.settle): the tilt starts from the flat camera's view on its first frame, so it starts
    /// exactly where the paper is then; a keyboard coming up (or the screen turning) frames the box again in what's left
    /// of the screen; the problem before it lets go once it lies flat.
    func settle(at t: Double, flat: PaperView3D) {
        if let b = before, !b.holdsCamera { before = nil }
        guard flatAt == nil, let c = camera, let at = liftAt, t >= at else { return }
        if !anchored {
            anchored = true
            c.start(from: flat, to: fitView(), at: at, duration: TiltCamera.beat * Self.slow)
            fitted = (TiltCamera.bottom, TiltCamera.screen)
        } else if let was = fitted, abs(was.bottom - TiltCamera.bottom) > 1 || was.screen != TiltCamera.screen, !c.moving {
            refit()
        }
        c.settle(at: t)
    }

    func tapPoint(_ s: Point) -> Point? {
        guard let v = tiltedView else { return nil }
        let pl = places(v, screen: TiltCamera.screen)
        // a block takes a tap anywhere a finger's width round it, however small the zoom draws it
        if let b = pl.blocks.first(where: { Self.touchable($0.rect).contains(CGPoint(x: s.x, y: s.y)) }), let f = footprint(b.kind) { return Point(f.midX, f.midY) }
        // a tap on the box (or the space it fills, dashed): its floor's middle
        if pl.bounds.insetBy(dx: -10, dy: -10).contains(CGPoint(x: s.x, y: s.y)) { let f = floorRect; return Point(f.midX, f.midY) }
        // anywhere else on the tilted paper is nothing to the page
        return Point(-1e7, -1e7)
    }

    func dragPoint(_ s: Point) -> Point? {
        guard let v = tiltedView else { return nil }
        let p = v.unproject(s, screen: TiltCamera.screen)
        return Point(p.x * Paper.unit, p.z * Paper.unit)
    }

    func pan(_ dx: Double, _ dy: Double) -> Bool {
        guard let c = camera, anchored, flatAt == nil else { return false }
        c.pan(dx, dy); return true
    }
    func pinch(_ f: Double) -> Bool {
        guard let c = camera, anchored, flatAt == nil else { return false }
        c.pinch(f); return true
    }

    /// The tilted view now, while it holds the camera (nil while the paper lies flat).
    var tiltedView: PaperView3D? {
        guard let c = camera, anchored else { return nil }
        if let f = flatAt { return PaperClock.now - f < flatTime ? .between(flatFrom ?? c.view(at: f), TiltCamera.flatNow, (PaperClock.now - f) / flatTime) : nil }
        return c.view(at: PaperClock.now)
    }

    /// Screenshots of a moment mid-move (`-slow`): the tilt and the hand's moves this many times slower.
    static var slow = 1.0

    /// The paper tilts and the floor rises into the first layer (Unit cubes' timings): the tilt takes a beat, the
    /// cubes start rising halfway through it, and the squares under them fade as they rise. `again`: coming back to a
    /// problem that had risen: the layers built on it rise too, one after another.
    private func lift(at start: Double, again: Bool = false) {
        let at = instant ? PaperClock.now - 100 : start
        liftAt = at
        camera = TiltCamera(TiltCamera.flatNow, instant: instant)
        anchored = false; flatAt = nil; sinkAt = nil
        // the paper is seen through this problem from now on; one still lying flat again finishes first (its tilt starts
        // after that has ended: a problem opens 0.4 s after the last one leaves, and its paper tilts 0.7 s after that)
        if let o = TiltCamera.owner, o !== self, o.holdsCamera { before = o }
        TiltCamera.owner = self
        riseSlow = Self.slow
        // cutting straight to it (Reduce Motion): the view is tilted now, without waiting for a frame to start from
        if instant, let c = camera { anchored = true; c.start(from: TiltCamera.flatNow, to: fitView(), at: at, duration: 0); fitted = (TiltCamera.bottom, TiltCamera.screen) }
        let rise = at + TiltCamera.beat * 0.55 * riseSlow
        riseAt = rise
        let risen = rose
        wireAt = lesson.step.task != nil ? risen - 0.2 : nil
        built = [:]
        if again {
            // the layers already stacked (or the whole box, once it's built), one after another
            let n = lesson.step.task != nil ? lesson.marked.count : box.height - 1
            for k in 1..<max(1, n + 1) where k < box.height { built[k] = (true, risen + 0.12 * Double(k - 1)) }
        }
        busyUntil = instant ? 0 : risen + (again ? 0.12 * Double(built.count) : 0)
    }

    /// When the floor has risen into its layer: its last cube stands.
    private var rose: Double { riseAt.map { $0 + (CubesTiming.end($0, floor: box.floor) - $0) * riseSlow } ?? 0 }
    /// Screenshots' slow motion as it was when the floor started rising (a later change doesn't move a rise that's done).
    @ObservationIgnored private var riseSlow = 1.0

    /// The tilted view that shows the box at its full height with its words: what to do over it, its labels, and the
    /// record under it, fitted between the top and the bar (or the keyboard).
    private func fitView() -> PaperView3D {
        let b = box, c = corner
        let probe = TiltCamera.probe(Vec3(c.x + Double(b.length) / 2, Double(b.height) / 2, c.z + Double(b.width) / 2))
        let pl = places(probe, screen: TiltCamera.screen, tilted: true)
        return TiltCamera.fit(pl.extent, probe: probe, screen: TiltCamera.screen, top: TiltCamera.top, bottom: TiltCamera.bottom)
    }

    /// The camera frames what's drawn now (the record came in, the keyboard came up).
    private func refit() {
        guard let c = camera, anchored, flatAt == nil else { return }
        fitted = (TiltCamera.bottom, TiltCamera.screen)
        c.move(to: fitView(), duration: CameraTiming.fly)
    }

    // MARK: what the child does

    func go() {
        guard !busy, leftAt == nil else { return }
        onTouch?()
        if let t = lesson.step.task {
            // a hand move moves on by itself once it's done; before then, Check (or the How to) only says what's left
            guard lesson.marked.count >= t.want else {
                if !auto { message = (t.mistakes.first?.message(lesson.marked.count, t.want) ?? "Not yet.", true) }
                return
            }
            advance(); return
        }
        guard lesson.step.answer != nil else { return }
        let misses = lesson.missedSteps.count + lesson.misses, typedBefore = lesson.typed["x"] ?? ""
        var trial = lesson
        let out = trial.go()
        // right: the box goes green, and a moment later the record is written
        if case .moved = out, !instant, !auto {
            verdict = (true, PaperClock.now); message = nil
            busyUntil = PaperClock.now + 0.6
            onChange?()
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                guard let self else { return }
                self.verdict = nil
                self.lesson = trial
                self.moved()
            }
            return
        }
        lesson = trial
        let wrong = lesson.missedSteps.count + lesson.misses > misses
        switch out {
        case .moved: moved()
        case .notYet(let line):
            message = (line, !wrong); verdict = wrong ? (false, PaperClock.now) : nil
            // one try (a test): the child's number stays red a moment, then the record is written with the answer and
            // the problem moves on
            if lesson.oneTry, wrong {
                wrongTyped = typedBefore
                busyUntil = time(1.2)
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(self?.instant == true ? 0 : 1.2))
                    guard let self else { return }
                    self.verdict = nil; self.wrongTyped = nil
                    if case .moved = self.lesson.go() { self.moved() }
                    self.onChange?()
                }
            }
            onChange?()
        case .newProblem: break
        }
    }

    /// A hand-move step is done: the lesson checks it and moves on.
    private func advance() {
        let before = lesson.step.camera
        guard case .moved = lesson.go() else { return }
        if before == .flat, lesson.step.camera == .tilted { message = nil; touched(); lift(at: time(0)); onChange?(); return }
        moved()
    }

    /// The step moved on: new words, and the camera frames what's there now.
    private func moved() {
        message = nil; hinting = false; touched()
        if lesson.step.task == nil { wireAt = nil }
        if lesson.step.answer != nil || lesson.isLast { busyUntil = time(0.3); refit() }
        if lesson.isLast { onSolved?() }
        teachIfDue(after: 0.9)
        onChange?()
    }

    /// The second time a step is slipped on, a problem aimed at it shows that step first (LessonPlan.Focus.teach): the
    /// record's number counted up and shown in the box, then taken away for the child to work out. It's the app's
    /// teaching, not the child's Show me: nothing counts as shown.
    @ObservationIgnored private var taught = false
    private func teachIfDue(after delay: Double) {
        guard onFocus, focus?.teach == true, !taught, !instant, !auto, !solved, lesson.step.answer != nil else { return }
        taught = true
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            // once the hands are free (the box has risen again, the record's in)
            while let self, self.busy { try? await Task.sleep(for: .seconds(0.1)) }
            guard let self, self.onFocus, self.leftAt == nil, self.preview == nil, (self.lesson.typed["x"] ?? "").isEmpty else { return }
            self.previewAnswer()
        }
    }

    /// Checks itself a moment after the hands finish, unless they change it again first.
    @ObservationIgnored private var pending = 0
    private func finished(after delay: Double) {
        guard let t = lesson.step.task, lesson.marked.count >= t.want, !auto else { return }
        pending += 1
        let mine = pending
        if instant { advance(); return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.pending == mine, self.leftAt == nil, let t = self.lesson.step.task, self.lesson.marked.count >= t.want else { return }
            self.busyUntil = 0
            self.advance()
        }
    }

    /// A tap on the paper (through the tilted view when the paper is tilted): a floor square covered or uncovered; on
    /// the box, one more layer.
    func tapPaper(_ p: Point) {
        guard !busy, !auto, leftAt == nil, preview == nil else { return }
        if isCover, let c = cell(at: p) {
            onTouch?()
            toggle(c, on: lesson.marks[c] == nil)
            message = nil
            finished(after: 0.35)
            onChange?()
        } else if isBuild, floorRect.insetBy(dx: -1, dy: -1).contains(CGPoint(x: p.x, y: p.y)) {
            onTouch?()
            setLayers(layersStanding + 1)
            if layersStanding >= box.height { finished(after: 0.45) } else { message = nil }
            onChange?()
        }
    }

    private var isCover: Bool { lesson.step.task != nil && lesson.step.camera == .flat }
    private var isBuild: Bool { lesson.step.task != nil && lesson.step.camera == .tilted }
    /// The layers standing now, the floor's included.
    var layersStanding: Int { 1 + (1..<max(1, box.height)).filter { lesson.marks[VolumeOfBox.layerCell($0, box)] != nil }.count }

    /// The floor square under a paper point.
    private func cell(at p: Point, clamped: Bool = false) -> Int? {
        let f = floorRect, b = box
        var x = Int(floor((p.x - f.minX) / Paper.unit)), z = Int(floor((p.y - f.minY) / Paper.unit))
        if clamped { x = min(b.length - 1, max(0, x)); z = min(b.width - 1, max(0, z)) }
        return UnitCubes.cell(UnitCubes.Cell(x, z), in: b)
    }

    /// Covers or uncovers floor square `c`; whether it changed.
    @discardableResult
    private func toggle(_ c: Int, on: Bool) -> Bool {
        guard (lesson.marks[c] != nil) != on, lesson.tap(c) else { return false }
        squares[c] = (on, PaperClock.now)
        return true
    }

    // the drag: a rectangle of squares from where it started, or the layers going up and down
    @ObservationIgnored private var sweep: (anchor: UnitCubes.Cell, paint: Bool, before: Set<Int>)?
    @ObservationIgnored private var lifting: (y: Double, layers: Int)?

    /// A sweep across the floor or the layers being lifted (the calm pill's readout, G 26 Oct).
    var handMoving: Bool { sweep != nil || lifting != nil }
    /// The squares covered as the finger sweeps ("12 squares"), or the layers standing as it lifts ("3 layers").
    var liveReadout: String? {
        if sweep != nil { let n = (0..<box.floor).filter { squares[$0]?.on == true }.count; return n == 1 ? "1 square" : "\(n) squares" }
        if lifting != nil { let n = layersStanding; return n == 1 ? "1 layer" : "\(n) layers" }
        return nil
    }

    func grab(_ p: Point) -> Bool {
        guard !busy, !auto, leftAt == nil, preview == nil else { return false }
        if isCover, let c = cell(at: p) {
            onTouch?()
            // a check waiting from the last move waits for this one
            pending += 1
            sweep = (UnitCubes.cell(c, in: box), lesson.marks[c] == nil, Set(lesson.marked))
            drag(to: p)
            return true
        }
        if isBuild, let v = tiltedView {
            let s = v.project(Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: TiltCamera.screen)
            guard places(v, screen: TiltCamera.screen).bounds.insetBy(dx: -10, dy: -10).contains(CGPoint(x: s.x, y: s.y)) else { return false }
            onTouch?()
            pending += 1
            lifting = (s.y, layersStanding); message = nil
            return true
        }
        return false
    }

    func drag(to p: Point) {
        if let sw = sweep, let c = cell(at: p, clamped: true) {
            let to = UnitCubes.cell(c, in: box)
            let xs = min(sw.anchor.x, to.x)...max(sw.anchor.x, to.x), zs = min(sw.anchor.z, to.z)...max(sw.anchor.z, to.z)
            var rect: Set<Int> = []
            for z in zs { for x in xs { if let i = UnitCubes.cell(UnitCubes.Cell(x, z), in: box) { rect.insert(i) } } }
            let want = sw.paint ? sw.before.union(rect) : sw.before.subtracting(rect)
            var changed = false
            for i in 0..<box.floor where toggle(i, on: want.contains(i)) { changed = true }
            // the page is saved when a square changes, not on every move of the finger
            if changed { onChange?() }
        } else if let l = lifting, let v = tiltedView {
            // a layer for every cube's height the finger moves up, as the cubes stand on the screen
            let s = v.project(Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: TiltCamera.screen)
            let per = Self.cubeTall(v, at: Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: TiltCamera.screen)
            if setLayers(l.layers + Int(((l.y - s.y) / per).rounded())) { onChange?() }
        }
    }

    func release() {
        if sweep != nil { sweep = nil; finished(after: 0.35) }
        if lifting != nil {
            lifting = nil
            if layersStanding >= box.height { finished(after: 0.45) }
            else { message = (lesson.step.task?.mistakes.first?.message(0, 0) ?? "Keep going.", true) }
        }
    }

    /// The layers standing: those above it sink, those up to it rise, one after another. Whether any changed.
    @discardableResult
    private func setLayers(_ n: Int) -> Bool {
        let n = min(box.height, max(1, n)), now = PaperClock.now
        var k = 0
        for y in 1..<max(1, box.height) {
            let cell = VolumeOfBox.layerCell(y, box), want = y < n
            guard (lesson.marks[cell] != nil) != want, lesson.tap(cell) else { continue }
            built[y] = (want, now + 0.06 * Double(k)); k += 1
        }
        return k > 0
    }

    func choose(_ i: Int) {}
    func usedHint() { lesson.usedHint(); onChange?() }

    /// A key from the iPad's keyboard (or a hardware one) into the record's box.
    func type(_ key: String) {
        guard !busy, wantsTyping else { return }
        typedAt = PaperClock.now
        onTouch?()
        lesson.type(key == "-" ? "del" : key)
        if message?.ok == false { message = nil }
        if verdict?.right == false { verdict = nil }
        touched()
        onChange?()
    }

    /// Start this step over: the squares come off the floor, the layers sink back to the first.
    func reset() {
        guard !busy, lesson.step.task != nil else { return }
        onTouch?()
        if isCover { for i in lesson.marked { squares[i] = (false, PaperClock.now) } }
        if isBuild { setLayers(1) }
        lesson.reset(); message = nil
        onChange?()
    }

    // MARK: Show me, and the How to's hand

    /// Show me is a preview, never the child's work (G 17 Oct): a ghost finger makes the move, what it does shows
    /// lightly over the child's own, holds, and goes back.
    func showMe() {
        guard lesson.helps, !busy, leftAt == nil, !solved else { return }
        onTouch?()
        message = nil
        noteShown()
        let now = PaperClock.now + 0.2
        if isCover {
            let (times, f) = sweepPlan(from: now)
            var cells: [Int: Double] = [:]
            for (i, at) in times where lesson.marks[i] == nil { cells[i] = at }
            preview = Preview(kind: .cover, at: now, end: f.start + f.duration + 0.26 + Preview.hold * Self.slow + Preview.fade, cells: cells)
            finger = f
        } else if isBuild {
            let have = layersStanding
            let (times, f) = liftPlan(from: now, have: have)
            preview = Preview(kind: .build, at: now, end: f.start + f.duration + 0.35 + Preview.hold * Self.slow + Preview.fade, layers: times)
            finger = f
        } else if lesson.step.answer != nil {
            previewAnswer(); return
        }
        played()
    }

    /// The record's number previewed: the layers counted up on their fronts, one after another (12, 24…), and the
    /// number they make shown in the box, lightly; then it all goes back.
    private func previewAnswer() {
        let now = PaperClock.now + 0.2
        preview = Preview(kind: .answer, at: now, end: now + 0.45 * Double(box.height) + 0.4 + Preview.hold * Self.slow + Preview.fade)
        played()
    }

    /// Hands off while a preview plays; then it goes, leaving everything as the child had it.
    private func played() {
        busyUntil = instant ? 0 : preview?.end ?? 0
        touched()
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, (self?.preview?.end ?? 0) - PaperClock.now) + 0.05))
            guard let self, let p = self.preview, PaperClock.now >= p.end else { return }
            self.preview = nil; self.finger = nil; self.touched()
        }
    }

    /// Show me is help all the same: the step counts as shown (so it isn't right on the child's own), and nothing of the
    /// child's changes. The run only records that by showing the step, so it shows it and the child's own marks and
    /// typing go straight back.
    private func noteShown() {
        let marks = lesson.marked, typed = lesson.typed["x"] ?? ""
        if lesson.step.task != nil { _ = lesson.showMe() } else if lesson.step.answer != nil { _ = lesson.showAnswer() } else { return }
        lesson.reset()
        for c in marks { lesson.tap(c) }
        for ch in typed { lesson.type(String(ch)) }
        onChange?()
    }

    /// The bar's Hint, on the paper (LESSONS.md §7: a hint is a small drawing step, never a pop-up): the step's hint
    /// written under what to do, and its part of the picture lit: the floor's empty squares outlined, or each layer's
    /// count.
    private(set) var hinting = false { didSet { if hinting != oldValue { wordsAt = PaperClock.now } } }
    func showHint() {
        guard !solved, leftAt == nil, lesson.step.task != nil || lesson.step.answer != nil else { return }
        lesson.usedHint()
        hinting = true
        if message?.ok == false { message = nil }
        onChange?()
    }
    /// The hint's words: the typed step's own hint, else the step's; on a step aimed at a slip, from the start.
    var hintText: String? { hinting || onFocus ? (lesson.step.answer?.hint ?? lesson.words.hint) : nil }
    /// Each layer's count lit on its front: a hint after a miss on the record, the bar's Hint, or a problem aimed at it.
    var countsLit: Bool { lesson.picture["counts"] == 1 || ((hinting || onFocus) && lesson.step.answer != nil) }

    /// The How to's move, made for it and kept: the hand sweeps the floor, stacks the layers, writes the number.
    @discardableResult
    func demonstrate() -> Double {
        let now = PaperClock.now
        if isCover {
            let (times, f) = sweepPlan(from: time(0.1))
            for (i, at) in times where lesson.marks[i] == nil { lesson.tap(i); squares[i] = (true, instant ? now - 100 : at) }
            finger = instant ? nil : f
            touched()
            return instant ? 0 : f.duration + 0.6
        }
        if isBuild {
            // after the floor has risen
            let ready = max(now, riseAt == nil ? now : rose) + 0.15
            let have = layersStanding
            let (times, f) = liftPlan(from: instant ? now : ready, have: have)
            for (y, at) in times { if lesson.tap(VolumeOfBox.layerCell(y, box)) { built[y] = (true, instant ? now - 100 : at) } }
            finger = instant ? nil : f
            touched()
            return instant ? 0 : ready - now + f.duration + 0.5
        }
        if lesson.step.answer != nil { _ = lesson.showAnswer(); typedAt = now; touched(); return instant ? 0 : 0.8 }
        return 0
    }

    /// The finger dragging across the squares still empty, from the back-left one to the front-right one (the whole
    /// floor when it's bare), as a child's drag does: the rectangle it sweeps grows with it, and each square fills as
    /// the rectangle reaches it.
    private func sweepPlan(from start: Double) -> ([Int: Double], Finger) {
        let b = box, c = corner
        let empty = (0..<b.floor).filter { lesson.marks[$0] == nil }.map { UnitCubes.cell($0, in: b) }
        let x0 = empty.map(\.x).min() ?? 0, x1 = empty.map(\.x).max() ?? b.length - 1
        let z0 = empty.map(\.z).min() ?? 0, z1 = empty.map(\.z).max() ?? b.width - 1
        let d = (0.5 + 0.09 * Double(max(x1 - x0, z1 - z0) + 1)) * Self.slow
        var times: [Int: Double] = [:]
        for i in 0..<b.floor {
            let s = UnitCubes.cell(i, in: b)
            guard (x0...x1).contains(s.x), (z0...z1).contains(s.z) else { continue }
            let f = max(x1 > x0 ? Double(s.x - x0) / Double(x1 - x0) : 0, z1 > z0 ? Double(s.z - z0) / Double(z1 - z0) : 0)
            times[i] = start + f * d
        }
        let finger = Finger(from: Vec3(c.x + Double(x0) + 0.5, 0, c.z + Double(z0) + 0.5), to: Vec3(c.x + Double(x1) + 0.5, 0, c.z + Double(z1) + 0.5), start: start, duration: d)
        return (times, finger)
    }

    /// The finger dragging up the front of the box from the layers standing to the top: when each layer rises.
    private func liftPlan(from start: Double, have: Int) -> ([Int: Double], Finger) {
        let b = box, c = corner, H = b.height, d = (0.3 * Double(max(1, H - have)) + 0.2) * Self.slow
        var times: [Int: Double] = [:]
        for y in have..<H { times[y] = start + d * Double(y - have) / Double(max(1, H - have)) }
        let x = c.x + Double(b.length) / 2, z = c.z + Double(b.width)
        let finger = Finger(from: Vec3(x, Double(have) - 0.5, z), to: Vec3(x, Double(H) - 0.5, z), start: start, duration: d)
        return (times, finger)
    }

    func howToBeats() -> [(words: String, run: () -> Void)] { [] }

    /// Screenshots only: these numbers instead of the generated ones.
    func use(_ n: Numbers) {
        var r = LessonRun(lesson.spec, numbers: n); r.helps = lesson.helps; r.oneTry = lesson.oneTry; r.guided = lesson.guided; r.hintCap = lesson.hintCap
        r.skipAsk()
        lesson = r; squares = [:]
    }

    // MARK: the picture, at a moment (CubesPicture)

    func outline(at t: Double) -> Double {
        if let r = riseAt, t >= r { return 0 }
        return ease((t - openedAt - 0.1) / 0.6) * gone(at: t)
    }

    func square(_ i: Int, at t: Double) -> (fill: Double, ghost: Double) {
        var fill = 0.0
        if let s = squares[i] { fill = ease((t - s.at) / 0.26); if !s.on { fill = 1 - fill } }
        // each square goes as its own cube rises over it (a big floor's last squares wait for theirs), and undraws
        // leaving
        let away = (riseAt.map { 1 - ease(((t - $0) / riseSlow - Double(i) * CubesTiming.stagger(floor: box.floor)) / 0.5) } ?? 1) * gone(at: t)
        var ghost = 0.0
        if let p = preview, p.kind == .cover, let at = p.cells[i] {
            ghost = ease((t - at) / 0.26) * (1 - ease((t - (p.end - Preview.fade)) / Preview.fade))
        }
        return (fill * away, ghost * away)
    }

    func layer(_ y: Int, at t: Double) -> CubesLayer {
        let sink = sinkAt.map { 1 - ease((t - $0) / 0.4) } ?? 1
        if y == 0 {
            guard let r = riseAt, t >= r else { return .none }
            if sinkAt == nil, t < rose { return .cubes }
            return .whole(sink)
        }
        if let p = preview, p.kind == .build, let at = p.layers[y] {
            return .ghost(ease((t - at) / 0.35) * (1 - ease((t - (p.end - Preview.fade)) / Preview.fade)))
        }
        guard let b = built[y] else { return .none }
        let k = b.up ? ease((t - b.at) / 0.35) : 1 - ease((t - b.at) / 0.3)
        return .whole(k * sink)
    }

    func cube(x: Int, y: Int, z: Int, at t: Double) -> Double {
        guard y == 0, let r = riseAt else { return 0 }
        let i = Double(z * box.length + x)
        return ease(((t - r) / riseSlow - i * CubesTiming.stagger(floor: box.floor)) / CubesTiming.rise)
    }

    var hints: (outline: Bool, tint: Bool, empty: [Int]) {
        guard isCover, leftAt == nil else { return (false, false, []) }
        let p = lesson.picture
        return (p["empty"] == 1 || hinting || onFocus, p["tint"] == 1, (0..<box.floor).filter { lesson.marks[$0] == nil })
    }

    func wire(at t: Double) -> Double {
        guard let w = wireAt, isBuild, sinkAt == nil else { return 0 }
        return ease((t - w) / 0.6)
    }

    /// The box's height is written once it stands up to its full height: dashed while it's built, then in cubes.
    func heightShown(at t: Double) -> Bool {
        guard camera != nil, flatAt == nil, sinkAt == nil else { return false }
        if let w = wireAt { return t >= w }
        return riseAt != nil && t >= rose
    }

    // MARK: where the words and blocks go

    /// Each block's place on the paper (its footprint): where it's drawn while the paper is flat, and what a tap on it
    /// is turned into while the paper is tilted, so the page knows which block it was.
    func footprint(_ kind: ProblemLayout.Kind) -> CGRect? {
        let f = floorRect, y = f.maxY + 5 * Paper.cell
        switch kind {
        case .main: return CGRect(x: f.minX, y: y, width: Self.blockWidth("Check", 120), height: 40)
        case .nextProblem: return CGRect(x: f.minX, y: y, width: Self.blockWidth("Next problem", 180), height: 40)
        case .next: return CGRect(x: f.minX, y: y, width: Self.blockWidth("Next step", 180), height: 40)
        case .practise: return CGRect(x: f.minX, y: y, width: Self.blockWidth("Practice", 180), height: 40)
        case .again, .skip: return CGRect(x: f.minX + 200, y: y, width: 160, height: 40)
        default: return nil
        }
    }

    /// A block as wide as its word and arrow need, in whole squares, never narrower than `least`.
    static func blockWidth(_ word: String, _ least: Double) -> Double {
        let w = measure(word, Sketch.Words.block.size) + 60
        return max(least, (w / Paper.cell).rounded(.up) * Paper.cell)
    }

    /// Words measured once: where everything goes is worked out every frame the paper moves.
    private static var widths: [String: Double] = [:], wrapped: [String: [String]] = [:]
    static func measure(_ s: String, _ size: CGFloat, digits: Bool = false) -> Double {
        let key = "\(size) \(digits) \(s)"
        if let w = widths[key] { return w }
        let w = PaperText.width(s, PaperText.font(size, .medium, digits: digits))
        widths[key] = w
        return w
    }
    /// What to do, in the lines it wraps to (two at most).
    static func lines(_ s: String) -> [String] {
        if let l = wrapped[s] { return l }
        let l = Array(PaperText.wrap(s, PaperText.font(Sketch.wordSize, .medium), width: wordsWidth).prefix(2))
        wrapped[s] = l
        return l
    }
    /// The box's labels (its sides in cm, each layer's count): the picture's own names, at the words' size, as every
    /// picture's labels are (Sketch: words are what to do, messages, buttons and picture labels).
    static let labelSize = Sketch.wordSize
    /// The labels' capitals' height, which a label's distance from what it labels is measured from.
    static let capHeight = Double(PaperText.font(labelSize, .medium, digits: true).capHeight)

    /// The blocks it shows now: Check while a number is wanted, Next problem once it's solved, the How to's own.
    var blockKinds: [ProblemLayout.Kind] {
        var out: [ProblemLayout.Kind] = []
        if !auto, !solved, lesson.step.answer != nil { out.append(.main) }
        if !auto, solved { out.append(.nextProblem) }
        return out + howToButtons.filter { [.next, .practise, .again, .skip].contains($0) }
    }

    /// The blocks, by their places on the paper (ProblemLayout.blocks), for the page's taps: each takes a tap a finger's
    /// width round it on the screen (44 points at least), however far out the paper is zoomed.
    var blocks: [ProblemLayout.Block] {
        let z = max(0.01, TiltCamera.flatNow.scale / Paper.unit)
        return blockKinds.compactMap { k in
            footprint(k).map { r in
                let least = Self.finger / z
                return ProblemLayout.Block(kind: k, rect: r.insetBy(dx: min(0, (r.width - least) / 2), dy: min(0, (r.height - least) / 2)))
            }
        }
    }
    /// The least a block takes a tap over on the screen (Apple's 44 points), and a block's rect grown to it.
    static let finger = 44.0
    /// How tall one cube stands on the screen at a point on the paper, through view `v` (with its perspective).
    static func cubeTall(_ v: PaperView3D, at p: Vec3, screen: Size) -> Double {
        max(1, v.project(p, screen: screen).y - v.project(p + Vec3(0, 1, 0), screen: screen).y)
    }

    /// The box's short side (its width) faces the eye on the right when the tilted view is turned that way (azimuth
    /// above 0, G 29 Oct), on the left when turned the other: its width is labelled on that side, its height on the other.
    nonisolated static var widthOnRight: Bool { PaperView3D.tilted.azimuth > 0 }

    static func touchable(_ r: CGRect) -> CGRect { r.insetBy(dx: min(0, (r.width - finger) / 2), dy: min(0, (r.height - finger) / 2)) }

    /// Where everything goes on the screen through view `v`: what to do over the box, its labels, each layer's count
    /// on its front, the count of squares under the floor, the record and its blocks; and all of it, for the camera.
    /// Flat, the box is its floor, and every place falls on the paper's grid; tilted, it's the box at its full height,
    /// and on a screen wider than tall the record stands beside it, level with its top, so the box alone sets how big
    /// the paper can be (a box of 8 × 8 × 6 stands 12 blocks tall on the screen: the record under it as well made
    /// everything half size).
    func places(_ v: PaperView3D, screen: Size, tilted: Bool? = nil) -> CubesPlaces {
        let k = v.scale / Paper.unit, b = box, c = corner
        let L = Double(b.length), W = Double(b.width), H = Double(b.height)
        let up = tilted ?? (camera != nil)
        let high = up ? H : 0
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { let p = v.project(Vec3(c.x + x, y, c.z + z), screen: screen); return CGPoint(x: p.x, y: p.y) }
        var bounds = CGRect.null
        for x in [0, L] { for y in [0, high] { for z in [0, W] { bounds = bounds.union(CGRect(origin: P(x, y, z), size: .zero)) } } }
        // the box's twelve edges on the screen: words over the box keep clear of the highest of them
        var edges: [(CGPoint, CGPoint)] = []
        for y in [0, high] { edges += [(P(0, y, 0), P(L, y, 0)), (P(0, y, W), P(L, y, W)), (P(0, y, 0), P(0, y, W)), (P(L, y, 0), P(L, y, W))] }
        for x in [0, L] { for z in [0, W] { edges.append((P(x, 0, z), P(x, high, z))) } }
        var pl = CubesPlaces(k: k, bounds: bounds)
        let cap = Self.capHeight
        // the length under the floor's front edge, the width beside the side that shows (its right edge, or its left), the
        // height beside the front's other upright edge
        let lw = Self.measure("\(b.length) cm", Self.labelSize, digits: true) * k, ww = Self.measure("\(b.width) cm", Self.labelSize, digits: true) * k
        let hw = Self.measure("\(b.height) cm", Self.labelSize, digits: true) * k
        let a = P(L / 2, 0, W), e = P(L, 0, W), slope = abs(e.y - a.y) / max(1, abs(e.x - a.x))
        pl.length = CGPoint(x: a.x, y: a.y + (10 + cap / 2) * k + slope * lw / 2)
        let right = Self.widthOnRight
        let wm = P(right ? L : 0, 0, W / 2)
        pl.width = CGPoint(x: wm.x + (right ? 10 : -10) * k, y: wm.y)
        let hm = P(right ? 0 : L, H / 2, W)
        pl.height = CGPoint(x: hm.x + (right ? -10 : 10) * k, y: hm.y)
        // each layer's count in the middle of a cube's face, not across the line between two (the middle cube, or the
        // one just right of the middle)
        let cx = b.length % 2 == 1 ? L / 2 : L / 2 + 0.5
        pl.counts = (0..<b.height).map { P(cx, Double($0) + 0.5, W) }
        var extent = bounds
        extent = extent.union(CGRect(x: pl.length.x - lw / 2, y: pl.length.y - cap * k / 2, width: lw, height: cap * k))
        extent = extent.union(CGRect(x: right ? pl.width.x : pl.width.x - ww, y: pl.width.y - cap * k / 2, width: ww, height: cap * k))
        if up { extent = extent.union(CGRect(x: right ? pl.height.x - hw : pl.height.x, y: pl.height.y - cap * k / 2, width: hw, height: cap * k)) }

        // the record (the school working): beside the box on a screen wider than tall, once it stands up; else under it
        let beside = up && screen.width > screen.height
        let lenBottom = pl.length.y + cap * k / 2
        pl.record = beside ? CGPoint(x: max(bounds.maxX, right ? pl.width.x + ww : pl.height.x + hw) + 2 * Paper.cell * k, y: bounds.minY)
                           : CGPoint(x: bounds.minX, y: max(bounds.maxY + 40 * k, lenBottom + 12 * k))
        let lines = recordLines, pitch = Self.recordPitch * k
        for (i, line) in lines.enumerated() {
            extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y + Double(i) * pitch, width: CubesRecord.width(line.line, cells: answerCells) * k, height: Sketch.row * k))
        }
        // once it stands up, room for the whole record as it ends (its three lines and Next problem), so the camera
        // holds still while it's written
        if up {
            for (i, line) in finalRecord.enumerated() {
                extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y + Double(i) * pitch, width: CubesRecord.width(line, cells: 3) * k, height: Sketch.row * k))
            }
            extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y + Double(finalRecord.count) * pitch, width: Self.blockWidth("Next problem", 180) * k, height: 40 * k))
        }
        if isCover { extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y, width: 200 * k, height: 40 * k)) }
        let blocksTop = pl.record.y + Double(max(1, lines.count)) * pitch
        for kind in blockKinds {
            guard let f = footprint(kind) else { continue }
            let r = CGRect(x: pl.record.x + (f.minX - floorRect.minX) * k, y: blocksTop, width: f.width * k, height: f.height * k)
            pl.blocks.append(ProblemLayout.Block(kind: kind, rect: r))
            extent = extent.union(r)
        }
        // room for the blocks that come later, so the camera doesn't step back again for them
        if blockKinds.isEmpty { extent = extent.union(CGRect(x: pl.record.x, y: blocksTop, width: 180 * k, height: 40 * k)) }

        // what to do over the box, a row of two squares a line, and what a miss says (or the hint) in the row under it,
        // kept while the box stands up so a miss doesn't move anything
        let sayLines = Self.lines(sayText)
        let under = message?.text ?? hintText
        let rows = Double(sayLines.count) + (under != nil || (up && !solved) ? 1 : 0)
        let sayWidth = max(sayLines.map { Self.measure($0, Sketch.wordSize) }.max() ?? 0, under.map { Self.measure($0, Sketch.small) } ?? 0) * k
        let sayHeight = rows * Sketch.row * k
        if up {
            // as low as it can sit and still clear the box by a square: the box's top rises to its right, so short words
            // tuck in over its left; over the record too, where they reach it
            var floorOfWords = Self.highest(edges, from: bounds.minX, to: bounds.minX + sayWidth) ?? bounds.minY
            if beside, bounds.minX + sayWidth > pl.record.x - Paper.cell * k { floorOfWords = min(floorOfWords, pl.record.y) }
            pl.say = CGPoint(x: bounds.minX, y: floorOfWords - Paper.cell * k - sayHeight)
        } else {
            pl.say = CGPoint(x: bounds.minX, y: bounds.minY - max(100, rows * Sketch.row + 20) * k)
        }
        extent = extent.union(CGRect(x: pl.say.x, y: pl.say.y, width: sayWidth, height: sayHeight))
        pl.extent = extent
        return pl
    }

    /// How far apart the record's lines are: a line is two squares tall, with a square between.
    static let recordPitch = 3 * Paper.cell

    /// The highest point (smallest y) of the segments where they run between x0 and x1 on the screen (nil: none do).
    static func highest(_ segments: [(CGPoint, CGPoint)], from x0: Double, to x1: Double) -> Double? {
        var top: Double?
        for (p, q) in segments {
            let lo = max(x0, min(p.x, q.x)), hi = min(x1, max(p.x, q.x))
            guard lo <= hi else { continue }
            for x in [lo, hi] {
                let y = abs(q.x - p.x) < 1e-6 ? min(p.y, q.y) : p.y + (q.y - p.y) * (x - p.x) / (q.x - p.x)
                top = min(top ?? y, y)
            }
        }
        return top
    }

    /// What to do now: the How to's words while it explains, else the step's. (A problem aimed at a slip shows that
    /// step's hint under it from the start: hintText.)
    var sayText: String { intro ?? lesson.words.say }

    /// The record's lines (the school working, as 5th grade writes it): the layer (once the floor has risen into it), then
    /// the layers with the box to type how many in all, then the volume in the chapter's colour.
    var recordLines: [(line: MathLine, chapter: Bool)] {
        let b = box
        if lesson.isLast { return finalRecord.enumerated().map { ($1, $0 == 2) } }
        if lesson.step.answer != nil { return [(VolumeOfBox.layerRecord(b), false), (VolumeOfBox.layersRecord(b), false)] }
        if isBuild { return [(VolumeOfBox.layerRecord(b), false)] }
        return []
    }
    /// The record as it ends.
    var finalRecord: [MathLine] { let b = box; return [VolumeOfBox.layerRecord(b), VolumeOfBox.layersDoneRecord(b), VolumeOfBox.volumeRecord(b)] }
    /// The record as it's written by now: building, its first line comes once the floor has risen into a layer.
    func recordLines(at t: Double) -> [(line: MathLine, chapter: Bool)] {
        isBuild && !(riseAt != nil && t >= rose) ? [] : recordLines
    }
    /// The answer box's width in cells of two squares: three, or one more than what's typed.
    var answerCells: Int { max(3, (lesson.typed["x"] ?? "").count + 1) }
}

/// Where a CubesProblem's words and blocks go on the screen (CubesProblem.places).
struct CubesPlaces {
    var k: Double
    /// The box on the screen (its floor, flat).
    var bounds: CGRect
    var say = CGPoint.zero, record = CGPoint.zero
    /// The labels: the length's middle, the width's right end, the height's left end (each centred up and down).
    var length = CGPoint.zero, width = CGPoint.zero, height = CGPoint.zero
    /// Each layer's front, at its middle.
    var counts: [CGPoint] = []
    var blocks: [ProblemLayout.Block] = []
    var extent = CGRect.null
}

/// Typing from the iPad's keyboard into a problem's box (NumberEntry): a typed step's problem, or Volume of a box's
/// record. The page's typing gate asks the problem (wantsTyping), and the pad comes up where the problem's layout keeps
/// clear (stacked: the bottom-right corner, as the paper lessons have it; else the top-right).
@MainActor
protocol NumberTyping: AnyObject {
    var id: UUID { get }
    var lesson: LessonRun { get }
    /// A number is wanted now: the iPad's number keys come up by themselves (no tap needed).
    var wantsTyping: Bool { get }
    /// Laid out stacked, a paper lesson's way: the number pad comes up in the screen's bottom-right corner.
    var stacked: Bool { get }
    func type(_ key: String)
    func go()
}
extension NumberTyping where Self: PageProblem {
    /// A typed step (not a pick-one step) of a problem being worked, until it's solved.
    var wantsTyping: Bool { !auto && !solved && lesson.step.answer.map { $0.choices == nil } == true }
}
extension NumberTyping {
    /// A lesson not laid out the paper way yet: its words beside the box, Check under it.
    var stacked: Bool { false }
}
extension WorkProblem: NumberTyping {}
extension CubesProblem: NumberTyping {}

/// A line of the record as it's written (design/README.md rule 1: the record is maths, 36): its numbers, signs and words
/// all at the maths size, a space (half a square) between them, a number's digits together as they're written (standing
/// up off the paper there are no squares behind them, and digits two squares apart read as separate numbers), and the
/// box to type in, two squares a digit, its digits the line's own size. In points from the line's left; a line is two
/// squares tall. The same layout measures it (the camera), draws it, and puts the box and the typed digits in it.
@MainActor
enum CubesRecord {
    enum Kind: Equatable { case run(String, digits: Bool), box }
    struct Piece: Equatable { let kind: Kind; let x: Double; let width: Double }
    /// A space at the maths size: half a square.
    static let gap = Paper.cell / 2

    static func layout(_ line: MathLine, cells: Int) -> (pieces: [Piece], width: Double) {
        var out: [Piece] = [], x = 0.0
        func run(_ s: String, digits: Bool) {
            let w = CubesProblem.measure(s, Sketch.maths, digits: digits)
            out.append(Piece(kind: .run(s, digits: digits), x: x, width: w)); x += w
        }
        for m in line {
            if !out.isEmpty { x += gap }
            switch m {
            case .num(let v): run(fmt(v), digits: true)
            case .op(let o): run(o, digits: true)
            case .text(let t): run(t, digits: false)
            case .box: let w = Double(cells) * Sketch.row; out.append(Piece(kind: .box, x: x, width: w)); x += w
            case .frac: break
            }
        }
        return (out, x)
    }
    /// How wide a line is, in points.
    static func width(_ line: MathLine, cells: Int) -> Double { layout(line, cells: cells).width }
    /// Where its box is, in points from the line's top-left.
    static func box(_ line: MathLine, cells: Int) -> CGRect? {
        layout(line, cells: cells).pieces.first { $0.kind == .box }.map { CGRect(x: $0.x, y: 0, width: $0.width, height: Sketch.row) }
    }
    /// The line's words and numbers into a sketch, from its top-left (its box is the record's own: it changes as the
    /// child types).
    static func draw(_ s: inout Sketch, _ id: String, _ line: MathLine, cells: Int, _ colour: Sketch.Colour) {
        for (i, p) in layout(line, cells: cells).pieces.enumerated() {
            guard case .run(let t, let digits) = p.kind else { continue }
            s.text("\(id)\(i):\(t)", t, at: CGPoint(x: p.x, y: Sketch.row / 2), size: Sketch.maths, weight: .medium, colour, anchor: UnitPoint(x: 0, y: 0.5), digits: digits)
        }
    }
    /// The digits typed into a box, as the line writes a number: together, from half a square in; and where the
    /// cursor goes after them.
    static func typed(_ s: String, in box: CGRect) -> (at: CGPoint, cursor: Double) {
        (CGPoint(x: box.minX + gap, y: box.midY), box.minX + gap + CubesProblem.measure(s, Sketch.maths, digits: true) + 4)
    }
}

extension Shots {
    /// `page-g5-volume[@n]-<stage>`, with `-numbers length=4,width=3,height=2`: Volume of a box worked to a stage by
    /// the hands, as a child does it (drags and taps on the screen, through the tilted view once it tilts). 0: flat,
    /// nothing covered (`-partway`: a drag has covered all but the last row); 1: the floor covered, the paper tilted and
    /// the first layer risen (`-tilting`: caught as it tilts; `-partway`: half the layers stacked by a drag); 2: the box
    /// built, the record to write (`-typed 24`: typed; `-wrong`: a wrong number checked); 3: done, Check pressed.
    /// `-showme`: Show me playing on that stage. `-slow N`: the moves N times slower, to catch them mid-way.
    static func cubes(_ m: PaperModel, _ page: BarsPage, _ c: CubesProblem, stage k: Int, args: [String]) async {
        await cubesMoves(m, page, c, stage: k, args: args)
        await marked(args)
    }

    /// The moment has been reached (Show me just pressed, the drag just let go), or `-at S` seconds after it: written
    /// to the device's log, so a screenshot can be taken right then (the app's own start takes a varying few seconds).
    /// `-freeze`: the paper holds still from then on, so a screenshot that takes a while still catches that moment.
    static func marked(_ args: [String]) async {
        if let s = args.firstIndex(of: "-at").flatMap({ $0 + 1 < args.count ? Double(args[$0 + 1]) : nil }) { try? await Task.sleep(for: .seconds(s)) }
        if args.contains("-freeze") { PaperClock.frozen = PaperClock.now }
        mark()
    }
    /// Written to the device's log, and as a file in the app's Documents (`shot-mark`), which a script on the Mac can
    /// watch for without reading the device's log.
    static func mark() {
        NSLog("OBENTO-SHOT-MARK")
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? "\(Date().timeIntervalSince1970)".write(to: docs.appendingPathComponent("shot-mark"), atomically: true, encoding: .utf8)
        }
    }

    static func cubesMoves(_ m: PaperModel, _ page: BarsPage, _ c: CubesProblem, stage k: Int, args: [String]) async {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        func arg(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        if let list = arg("-numbers") {
            var n: Numbers = [:]
            for pair in list.split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { n[String(kv[0])] = v } }
            c.use(n)
        }
        // `-focus`: a problem aimed at the record's slip (LessonPlan.Focus); `-teach`: the same slip twice, shown first
        if args.contains("-focus") || args.contains("-teach") { c.focus = LessonPlan.Focus(step: 2, said: "That adds the height to the layer.", teach: args.contains("-teach")) }
        m.instant = false; c.instant = false
        page.open(c)
        await wait(1.6)
        let b = c.box, f = c.floorRect, now = { PaperClock.now }
        /// A paper point on the screen while the paper is flat.
        func flat(_ x: Double, _ z: Double) -> Point { m.camera(at: now()).toScreen(Point(f.minX + x * Paper.unit, f.minY + z * Paper.unit)) }
        /// A drag along these screen points, a finger's speed.
        func drag(_ pts: [Point]) async {
            guard let first = pts.first else { return }
            m.dragStart(at: first)
            guard m.handDrag else { return }
            for (a, e) in zip(pts, pts.dropFirst()) { for i in 1...8 { let u = Double(i) / 8; m.dragMove(to: Point(a.x + (e.x - a.x) * u, a.y + (e.y - a.y) * u)); await wait(0.016) } }
            m.dragEnd()
        }
        let slow = arg("-slow").flatMap(Double.init)
        let showMe = args.contains("-showme"), partway = args.contains("-partway")
        if k == 0 {
            if partway { await drag([flat(0.5, 0.5), flat(Double(b.length) - 0.5, Double(max(1, b.width - 1)) - 0.5)]) }
            if showMe { await wait(0.6); CubesProblem.slow = slow ?? 1; c.showMe() }
            return
        }
        // the whole floor, corner to corner, and it rises
        if args.contains("-tilting") { CubesProblem.slow = slow ?? 6 }
        await drag([flat(0.5, 0.5), flat(Double(b.length) - 0.5, Double(b.width) - 0.5)])
        if args.contains("-tilting") { return }
        await wait(3.2)
        guard let v = c.tiltedView else { return }
        let o = c.corner, per = CubesProblem.cubeTall(v, at: Vec3(o.x + Double(b.length) / 2, 0, o.z + Double(b.width)), screen: m.screen)
        let front = v.project(Vec3(o.x + Double(b.length) / 2, 0.5, o.z + Double(b.width)), screen: m.screen)
        if k == 1 {
            if partway, b.height > 2 { await drag([front, Point(front.x, front.y - per * Double(b.height / 2 - 1))]) }
            else if partway { await drag([front, Point(front.x, front.y - per * 0.3)]) }
            if showMe { await wait(0.8); CubesProblem.slow = slow ?? 1; c.showMe() }
            return
        }
        // up to the top, a layer a cube's height of the finger
        await drag([front, Point(front.x, front.y - per * Double(b.height - 1))])
        await wait(1.8)
        if let typed = arg("-typed") ?? (args.contains("-wrong") ? "\(b.floor + b.height)" : k >= 3 ? "\(b.volume)" : nil) {
            for ch in typed { c.type(String(ch)); await wait(0.25) }
        }
        if k == 2, showMe { await wait(0.5); CubesProblem.slow = slow ?? 1; c.showMe(); return }
        if k >= 3 || args.contains("-wrong") {
            await wait(0.3)
            // Check, pressed where it shows on the screen
            if let v = c.tiltedView, let r = c.places(v, screen: m.screen).blocks.first(where: { $0.kind == .main })?.rect { m.tap(at: Point(r.midX, r.midY)) }
        }
        // `-next`: Next problem pressed where it shows; `-back`: the bar's Problems; `-leave`: the bar's Lessons. The
        // paper lies flat again on the way (`-slow N` to catch it lying down)
        guard k >= 3, args.contains("-next") || args.contains("-back") || args.contains("-leave") else { return }
        await wait(1.8)
        CubesProblem.slow = slow ?? 1
        // the page's other problems draw in at their own pace from here, as they do for a child (screenshots open the
        // page all at once)
        for q in page.problems { (q as? CubesProblem)?.instant = false }
        if args.contains("-next"), let v = c.tiltedView, let r = c.places(v, screen: m.screen).blocks.first(where: { $0.kind == .nextProblem })?.rect {
            m.tap(at: Point(r.midX, r.midY))
        } else if args.contains("-back") { page.backToProblems() }
        else if args.contains("-leave") { m.close() }
    }

    /// `page-<id>` with `-howto N`: the lesson opened as a child opens it, its How to taught a tap at a time: its block
    /// pressed N times, each once it shows (`-again M`: then Watch the How to again, and M more). `-numbers` sets the How
    /// to's box; `-slow N` slows the hand's moves.
    static func howToTaps(_ m: PaperModel, _ p: Piece, args: [String]) async {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        func arg(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        PageStore.clear(p.id)
        if let list = arg("-numbers") {
            var n: Numbers = [:]
            for pair in list.split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { n[String(kv[0])] = v } }
            m.shotNumbers = n
        }
        CubesProblem.slow = arg("-slow").flatMap(Double.init) ?? 1
        m.instant = false
        m.select(p); await wait(1); m.open(p)
        func taps(_ n: Int) async {
            for _ in 0..<n {
                var waited = 0.0
                while (m.bars?.howTo.howToButtons.isEmpty ?? true) && waited < 30 { await wait(0.1); waited += 0.1 }
                await wait(0.4)
                m.bars?.skipHowTo()
                await wait(0.5)
            }
        }
        await taps(Int(arg("-howto") ?? "") ?? 0)
        // `-again N`: then Watch the How to again (the ⋯ menu's), on the page it came back to, and its block pressed N times
        if let n = arg("-again").flatMap(Int.init) {
            await wait(1.5)
            m.bars?.watchAgain()
            await wait(1.0)
            await taps(n)
        }
        await marked(args)
    }
}
