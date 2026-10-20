import SwiftUI

/// One problem of Volume of a box on its lesson's page (BarsPage), built on Unit cubes (G 20 Oct: anything 3D builds on
/// Unit cubes; design/grade5.md). One cube is one block of the paper, 1 cm each way.
///
/// It opens flat: the box's floor outlined on the paper's strong lines, its length and width beside it. The child covers
/// the floor (a tap covers a square, a drag sweeps a rectangle of them), the squares counting. Then the paper tilts and
/// the floor rises into the first layer, Unit cubes' way; the child drags up (or taps) to stack the layers, each one's
/// running count written on its front, the box's full height dashed. The record is written under the box, standing up
/// facing the child, and the last number is typed. The paper lies flat again before the next problem, the page or the
/// map. Show me plays the hand move with a ghost finger and puts everything back; the How to plays it and keeps it.
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
    var animating: Bool { PaperClock.now < until + 0.1 || wantsNumber }

    /// The record's box wants a number (the iPad's number keys come up; the cursor blinks).
    var wantsNumber: Bool { !auto && !solved && leftAt == nil && lesson.step.answer != nil && preview?.kind != .answer }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }
    private func touched() { wordsAt = PaperClock.now }

    // MARK: on the paper, and off it

    func start(after delay: Double) {
        // reopened after it lay flat again: it rises again from its covered floor
        if flatAt != nil || leftAt != nil { settleFlat() }
        openedAt = time(delay); wordsAt = openedAt; leftAt = nil; message = nil; verdict = nil
        for i in lesson.marks.keys where i < box.floor && squares[i] == nil { squares[i] = (true, openedAt - 100) }
        if lesson.step.camera == .tilted && liftAt == nil { lift(at: openedAt + 0.7, again: true) }
        needs?(frameRect)
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

    private func flatten(_ duration: Double) {
        let now = PaperClock.now
        flatFrom = camera?.view(at: now); flatTime = instant ? 0.0001 : duration * Self.slow
        flatAt = now; sinkAt = sinkAt ?? now
    }

    /// Flat again, and nothing standing: ready to rise again from the floor.
    private func settleFlat() {
        if TiltCamera.owner === self { TiltCamera.owner = nil }
        camera = nil; anchored = false; flatAt = nil; flatFrom = nil; liftAt = nil; riseAt = nil; built = [:]; wireAt = nil; sinkAt = nil; fitted = nil
    }

    /// The How to again (Watch again): the cubes sink, the paper lies flat, and it starts over on a bare floor.
    func replay() {
        var r = LessonRun(lesson.spec, numbers: lesson.numbers); r.helps = lesson.helps; r.oneTry = lesson.oneTry
        lesson = r
        message = nil; verdict = nil; preview = nil; finger = nil; busyUntil = 0
        let tilted = holdsCamera
        lieFlat()
        squares = [:]
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

    func view(at t: Double, flat: PaperView3D) -> PaperView3D? {
        if let f = flatAt {
            let u = (t - f) / flatTime
            guard u < 1 else { return nil }
            return .between(flatFrom ?? flat, flat, u)
        }
        guard let c = camera, let at = liftAt, t >= at else { return nil }
        if !anchored {
            anchored = true
            c.start(from: flat, to: fitView(), at: at, duration: TiltCamera.beat * Self.slow)
            fitted = (TiltCamera.bottom, TiltCamera.screen)
        }
        // a keyboard coming up (or the screen turning) frames the box again in what's left of the screen
        if let was = fitted, abs(was.bottom - TiltCamera.bottom) > 1 || was.screen != TiltCamera.screen, !c.moving { refit() }
        return c.view(at: t)
    }

    func tapPoint(_ s: Point) -> Point? {
        guard let v = tiltedView else { return nil }
        let pl = places(v, screen: TiltCamera.screen)
        if let b = pl.blocks.first(where: { $0.rect.contains(CGPoint(x: s.x, y: s.y)) }), let f = footprint(b.kind) { return Point(f.midX, f.midY) }
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
        TiltCamera.owner = self
        let rise = at + TiltCamera.beat * 0.55 * Self.slow
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
    private var rose: Double { riseAt.map { $0 + (CubesTiming.end($0, floor: box.floor) - $0) * Self.slow } ?? 0 }

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
        onChange?()
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

    private func toggle(_ c: Int, on: Bool) {
        guard (lesson.marks[c] != nil) != on, lesson.tap(c) else { return }
        squares[c] = (on, PaperClock.now)
    }

    // the drag: a rectangle of squares from where it started, or the layers going up and down
    @ObservationIgnored private var sweep: (anchor: UnitCubes.Cell, paint: Bool, before: Set<Int>)?
    @ObservationIgnored private var lifting: (y: Double, layers: Int)?

    func grab(_ p: Point) -> Bool {
        guard !busy, !auto, leftAt == nil, preview == nil else { return false }
        if isCover, let c = cell(at: p) {
            onTouch?()
            sweep = (UnitCubes.cell(c, in: box), lesson.marks[c] == nil, Set(lesson.marked))
            drag(to: p)
            return true
        }
        if isBuild, let v = tiltedView {
            let s = v.project(Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: TiltCamera.screen)
            guard places(v, screen: TiltCamera.screen).bounds.insetBy(dx: -10, dy: -10).contains(CGPoint(x: s.x, y: s.y)) else { return false }
            onTouch?()
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
            for i in 0..<box.floor { toggle(i, on: want.contains(i)) }
            pending += 1
            onChange?()
        } else if let l = lifting, let v = tiltedView {
            // a layer for every cube's height the finger moves up, as the cubes stand on the screen
            let s = v.project(Vec3(p.x / Paper.unit, 0, p.y / Paper.unit), screen: TiltCamera.screen)
            let per = v.scale * v.axes.up.y
            setLayers(l.layers + Int(((l.y - s.y) / per).rounded()))
            pending += 1
            onChange?()
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

    /// The layers standing: those above it sink, those up to it rise, one after another.
    private func setLayers(_ n: Int) {
        let n = min(box.height, max(1, n)), now = PaperClock.now
        var k = 0
        for y in 1..<max(1, box.height) {
            let cell = VolumeOfBox.layerCell(y, box), want = y < n
            guard (lesson.marks[cell] != nil) != want, lesson.tap(cell) else { continue }
            built[y] = (want, now + 0.06 * Double(k)); k += 1
        }
    }

    func choose(_ i: Int) {}
    func usedHint() { lesson.usedHint(); onChange?() }

    /// A key from the iPad's keyboard (or a hardware one) into the record's box.
    func type(_ key: String) {
        guard !busy, wantsNumber else { return }
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
            // the layers counted up, one after another, and the number they make shown in the box
            preview = Preview(kind: .answer, at: now, end: now + 0.45 * Double(box.height) + 0.4 + Preview.hold * Self.slow + Preview.fade)
        }
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
    /// The hint's words: the typed step's own hint, else the step's.
    var hintText: String? { hinting ? (lesson.step.answer?.hint ?? lesson.words.hint) : nil }

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
        let away = (riseAt.map { 1 - ease(((t - $0) / Self.slow - Double(i) * CubesTiming.stagger(floor: box.floor)) / 0.5) } ?? 1) * gone(at: t)
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
        return ease(((t - r) / Self.slow - i * CubesTiming.stagger(floor: box.floor)) / CubesTiming.rise)
    }

    var hints: (outline: Bool, tint: Bool, empty: [Int]) {
        guard isCover, leftAt == nil else { return (false, false, []) }
        let p = lesson.picture
        return (p["empty"] == 1 || hinting, p["tint"] == 1, (0..<box.floor).filter { lesson.marks[$0] == nil })
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
        let w = PaperText.width(word, PaperText.font(Sketch.Words.block.size, .medium)) + 60
        return max(least, (w / Paper.cell).rounded(.up) * Paper.cell)
    }

    /// The blocks it shows now: Check while a number is wanted, Next problem once it's solved, the How to's own.
    var blockKinds: [ProblemLayout.Kind] {
        var out: [ProblemLayout.Kind] = []
        if !auto, !solved, lesson.step.answer != nil { out.append(.main) }
        if !auto, solved { out.append(.nextProblem) }
        return out + howToButtons.filter { [.next, .practise, .again, .skip].contains($0) }
    }

    /// The blocks, by their places on the paper (ProblemLayout.blocks), for the page's taps.
    var blocks: [ProblemLayout.Block] { blockKinds.compactMap { k in footprint(k).map { ProblemLayout.Block(kind: k, rect: $0) } } }

    /// Where everything goes on the screen through view `v`: what to do over the box, its labels, each layer's count
    /// on its front, the count or the record under it, the blocks under that; and all of it, for the camera.
    /// Flat, the box is its floor, and every place falls on the paper's grid; tilted, it's the box at its full height.
    func places(_ v: PaperView3D, screen: Size, tilted: Bool? = nil) -> CubesPlaces {
        let k = v.scale / Paper.unit, b = box, c = corner
        let L = Double(b.length), W = Double(b.width), H = Double(b.height)
        let high = (tilted ?? (camera != nil)) ? H : 0
        func P(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { let p = v.project(Vec3(c.x + x, y, c.z + z), screen: screen); return CGPoint(x: p.x, y: p.y) }
        var bounds = CGRect.null
        for x in [0, L] { for y in [0, high] { for z in [0, W] { bounds = bounds.union(CGRect(origin: P(x, y, z), size: .zero)) } } }
        var pl = CubesPlaces(k: k, bounds: bounds)
        let small = PaperText.font(Sketch.small, .medium, digits: true), cap = Double(small.capHeight)
        // the length under the floor's front edge, the width left of its left edge, the height right of the front-right edge
        let lenText = "\(b.length) cm", widText = "\(b.width) cm", hiText = "\(b.height) cm"
        let lw = PaperText.width(lenText, small) * k, ww = PaperText.width(widText, small) * k, hw = PaperText.width(hiText, small) * k
        let a = P(L / 2, 0, W), e = P(L, 0, W), slope = abs(e.y - a.y) / max(1, abs(e.x - a.x))
        pl.length = CGPoint(x: a.x, y: a.y + (10 + cap / 2) * k + slope * lw / 2)
        let wm = P(0, 0, W / 2)
        pl.width = CGPoint(x: wm.x - 10 * k, y: wm.y)
        let hm = P(L, H / 2, W)
        pl.height = CGPoint(x: hm.x + 10 * k, y: hm.y)
        // each layer's count in the middle of a cube's face, not across the line between two (the middle cube, or the
        // one just right of the middle)
        let cx = b.length % 2 == 1 ? L / 2 : L / 2 + 0.5
        pl.counts = (0..<b.height).map { P(cx, Double($0) + 0.5, W) }
        var extent = bounds
        extent = extent.union(CGRect(x: pl.length.x - lw / 2, y: pl.length.y - cap * k / 2, width: lw, height: cap * k))
        extent = extent.union(CGRect(x: pl.width.x - ww, y: pl.width.y - cap * k / 2, width: ww, height: cap * k))
        if high > 0 { extent = extent.union(CGRect(x: pl.height.x, y: pl.height.y - cap * k / 2, width: hw, height: cap * k)) }

        // what to do over the box, a row of two squares a line, and what a miss says (or the hint) under it: five rows
        // over the box, or more when they need more, so they never reach it
        let sayFont = PaperText.font(Sketch.wordSize, .medium)
        let sayLines = PaperText.wrap(sayText, sayFont, width: Self.wordsWidth).prefix(2)
        let under = message?.text ?? hintText, rows = Double(sayLines.count + (under == nil ? 0 : 1))
        pl.say = CGPoint(x: bounds.minX, y: bounds.minY - max(100, rows * Sketch.row + 20) * k)
        let sayWidth = sayLines.map { PaperText.width($0, sayFont) }.max() ?? 0
        extent = extent.union(CGRect(x: pl.say.x, y: pl.say.y, width: sayWidth * k, height: Double(sayLines.count) * Sketch.row * k))
        if let m = under {
            extent = extent.union(CGRect(x: pl.say.x, y: pl.say.y + Double(sayLines.count) * Sketch.row * k, width: PaperText.width(m, PaperText.font(Sketch.small, .medium)) * k, height: Sketch.row * k))
        }

        // under the box: the count while the floor is covered, the record once it has risen; then the blocks
        let lenBottom = pl.length.y + cap * k / 2
        pl.record = CGPoint(x: bounds.minX, y: max(bounds.maxY + 40 * k, lenBottom + 12 * k))
        let lines = recordLines
        let recordFont = PaperText.font(Sketch.wordSize, .medium)
        for (i, line) in lines.enumerated() {
            var w = PaperText.width(line.text, recordFont) * k
            if line.box { w += (20 + 40 * Double(answerCells)) * k + 20 * k }
            extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y + Double(i) * 60 * k, width: w, height: 40 * k))
        }
        if isCover { extent = extent.union(CGRect(x: pl.record.x, y: pl.record.y, width: 200 * k, height: 40 * k)) }
        let blocksTop = pl.record.y + Double(max(1, lines.count)) * 60 * k
        for kind in blockKinds {
            guard let f = footprint(kind) else { continue }
            let r = CGRect(x: pl.record.x + (f.minX - floorRect.minX) * k, y: blocksTop, width: f.width * k, height: f.height * k)
            pl.blocks.append(ProblemLayout.Block(kind: kind, rect: r))
            extent = extent.union(r)
        }
        // room for the blocks that come later, so the camera doesn't step back again for them
        if blockKinds.isEmpty { extent = extent.union(CGRect(x: pl.record.x, y: blocksTop, width: 180 * k, height: 40 * k)) }
        pl.extent = extent
        return pl
    }

    /// What to do now: the How to's words while it explains, else the step's (a problem aimed at a slip starts its
    /// step with what the child was told).
    var sayText: String { intro ?? lesson.words.say }

    /// The record's lines under the box: the layer (once the floor has risen into it), then the layers with the box
    /// to type in, then the volume. The camera makes room for them from the moment the paper tilts.
    var recordLines: [(text: String, box: Bool, chapter: Bool)] {
        let b = box
        if lesson.isLast {
            return [(VolumeOfBox.layerLine(b), false, false), (VolumeOfBox.layersDone(b), false, false), (VolumeOfBox.volumeLine(b), false, true)]
        }
        if lesson.step.answer != nil { return [(VolumeOfBox.layerLine(b), false, false), (VolumeOfBox.layersLine(b), true, false)] }
        if isBuild { return [(VolumeOfBox.layerLine(b), false, false)] }
        return []
    }
    /// The record as it's written by now: building, its first line comes once the floor has risen into a layer.
    func recordLines(at t: Double) -> [(text: String, box: Bool, chapter: Bool)] {
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
/// record.
@MainActor
protocol NumberTyping: AnyObject {
    var id: UUID { get }
    var lesson: LessonRun { get }
    func type(_ key: String)
    func go()
}
extension WorkProblem: NumberTyping {}
extension CubesProblem: NumberTyping {}

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
    static func marked(_ args: [String]) async {
        if let s = args.firstIndex(of: "-at").flatMap({ $0 + 1 < args.count ? Double(args[$0 + 1]) : nil }) { try? await Task.sleep(for: .seconds(s)) }
        mark()
    }
    static func mark() { NSLog("OBENTO-SHOT-MARK") }

    private static func cubesMoves(_ m: PaperModel, _ page: BarsPage, _ c: CubesProblem, stage k: Int, args: [String]) async {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        func arg(_ name: String) -> String? { args.firstIndex(of: name).flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } }
        if let list = arg("-numbers") {
            var n: Numbers = [:]
            for pair in list.split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { n[String(kv[0])] = v } }
            c.use(n)
        }
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
        let o = c.corner, per = v.scale * v.axes.up.y
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
        if args.contains("-next"), let v = c.tiltedView, let r = c.places(v, screen: m.screen).blocks.first(where: { $0.kind == .nextProblem })?.rect {
            m.tap(at: Point(r.midX, r.midY))
        } else if args.contains("-back") { page.backToProblems() }
        else if args.contains("-leave") { m.close() }
    }

    /// `page-<id>` with `-howto N`: the lesson opened as a child opens it, its How to taught a tap at a time: its block
    /// pressed N times, each once it shows. `-numbers` sets the How to's box; `-slow N` slows the hand's moves.
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
        for _ in 0..<(Int(arg("-howto") ?? "") ?? 0) {
            var waited = 0.0
            while (m.bars?.howTo.howToButtons.isEmpty ?? true) && waited < 30 { await wait(0.1); waited += 0.1 }
            await wait(0.4)
            m.bars?.skipHowTo()
            await wait(0.5)
        }
        await marked(args)
    }
}
