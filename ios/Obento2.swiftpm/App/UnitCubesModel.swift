import SwiftUI

/// Unit cubes on the paper, in 3D. The lesson logic lives in Core/UnitCubes.swift; this keeps the timing:
/// when each square appeared, when each layer started rising, and where the camera is going.
@MainActor @Observable
final class UnitCubesModel {
    /// The paper tilting into 3D and back (snappier, G 17 Oct: was 1.1 s).
    static let beat = 0.9

    /// The box's back-left corner, in world units (one unit = one big square), on the paper's strong lines.
    let origin: Vec3
    let chapter: Chapter
    var screen: Size
    let instant: Bool
    private(set) var lesson: LessonRun
    private var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970))

    private(set) var resting: PaperView3D
    private var flight: (from: PaperView3D, to: PaperView3D, start: Double, duration: Double, done: ((PaperView3D) -> Void)?)?
    /// Squares: when each was last turned on or off.
    private(set) var squares: [UnitCubes.Cell: (on: Bool, at: Double)] = [:]
    /// When the squares faded as the cubes rose.
    private(set) var squaresGoneAt: Double?
    /// When each layer started rising.
    private(set) var layerAt: [Int: Double] = [:]
    /// When the paper started to tilt (nil while flat).
    private(set) var tiltAt: Double?
    private(set) var untiltAt: Double?
    private(set) var wordsAt: Double = PaperClock.now
    var message: (text: String, ok: Bool)?

    init(origin: Vec3, chapter: Chapter, view: PaperView3D, screen: Size, instant: Bool, box: UnitCubes.Box? = nil, session: LessonSession = LessonSession()) {
        self.origin = origin; self.chapter = chapter; self.resting = view; self.screen = screen; self.instant = instant; self.session = session
        var r = SeededRandom(seed: UInt64(Date().timeIntervalSince1970))
        var run = box.map { LessonRun(UnitCubes.spec, numbers: $0.numbers) } ?? session.makeRun(UnitCubes.spec, using: &r)
        run.helps = session.helps; run.oneTry = session.oneTry
        lesson = run
        rng = r
    }

    /// The lesson sits on strong lines just inside the lesson's picture frame.
    static func origin(for p: Piece) -> Vec3 {
        Vec3(((p.at.x + 10) / Paper.unit).rounded(), 0, ((p.at.y + 40) / Paper.unit).rounded())
    }

    var box: UnitCubes.Box { UnitCubes.Box(lesson.numbers) }
    /// How many layers of cubes the picture shows at this step.
    var layers: Int { Int(lesson.picture["layers"] ?? 0) }
    var scale: Double { view(at: PaperClock.now).scale / Paper.unit }

    func view(at t: Double) -> PaperView3D {
        guard let f = flight else { return resting }
        return .between(f.from, f.to, (t - f.start) / f.duration)
    }

    var animating: Bool {
        let now = PaperClock.now
        return flight != nil || now - wordsAt < 0.8 || (layerAt.values.max().map { now - $0 < 2.6 } ?? false)
            || squares.values.contains { now - $0.at < 0.4 } || (squaresGoneAt.map { now - $0 < 1.2 } ?? false)
            || (tiltAt.map { now - $0 < Self.beat + 0.1 } ?? false) || (untiltAt.map { now - $0 < Self.beat + 0.1 } ?? false)
            || now < busyUntil + 0.1 || (preview.map { now < $0.end + 0.1 } ?? false)
    }

    func settle(at t: Double) {
        guard let f = flight, t - f.start >= f.duration else { return }
        resting = f.to; flight = nil; f.done?(f.to)
    }

    private func move(to v: PaperView3D, duration: Double, done: ((PaperView3D) -> Void)? = nil) {
        let now = PaperClock.now, from = view(at: now)
        if instant || duration == 0 { flight = nil; resting = v; done?(v); return }
        resting = from; flight = (from, v, now, duration, done)
    }

    // MARK: what the child does

    /// Where the child is: the first problem, practice, or the skill check (LESSONS.md §7).
    private(set) var session: LessonSession
    /// Hands off until then: a See beat is playing (LESSONS.md §4).
    private(set) var busyUntil: Double = 0
    var busy: Bool { PaperClock.now < busyUntil }

    func go() {
        guard !busy else { return }
        let before = lesson.step, had = layers
        switch lesson.go() {
        // the paper tilts when the step's camera does; each new layer rises
        case .moved where before.camera == .flat && lesson.step.camera == .tilted:
            lift()
            busyUntil = time(Self.beat * 0.55 + 0.7 + 0.04 * Double(box.floor))
        case .moved:
            if had > 0, layers > had { layerAt[layers - 1] = time(0); busyUntil = time(0.7 + 0.035 * Double(box.floor)) }
        case .notYet(let line):
            message = (line, false)
            // one try (the skill check): the squares it needed are shown filling
            if lesson.oneTry { for i in lesson.marked { let c = UnitCubes.cell(i, in: box); if squares[c]?.on != true { squares[c] = (true, time(0)) } }; busyUntil = time(0.3) }
            return
        case .newProblem: restart(); return
        }
        message = nil; wordsAt = PaperClock.now
        if lesson.isLast {
            session.finished(lesson)
            // the skill check is over: its score decides learned, and when the lesson comes back
            if case .done = session.phase, let level = session.level { Progress.shared.checked(lesson.spec.id, level: level) }
        }
    }

    func tap(_ c: UnitCubes.Cell) {
        guard !busy, let i = UnitCubes.cell(c, in: box), lesson.tap(i) else { return }
        squares[c] = (lesson.marks[i] != nil, time(0)); message = nil
    }

    /// Show me: a preview of the step. Every floor square fills in turn over the child's own, holds, and fades back.
    private(set) var preview: ShowMePreview?

    func showMe() {
        guard lesson.helps, !busy, let t = lesson.step.task else { return }
        let p = ShowMePreview(cells: t.showMe, at: time(0.2), step: 0.08)
        preview = p
        busyUntil = instant ? 0 : p.end
        message = nil
    }

    func reset() {
        guard !busy else { return }
        let was = lesson.marked; lesson.reset()
        for i in was { squares[UnitCubes.cell(i, in: box)] = (false, time(0)) }
        message = nil
    }

    func zoom(_ f: Double) {
        var v = view(at: PaperClock.now); v.scale = min(250, max(25, v.scale * f)); move(to: v, duration: 0.3)
    }

    /// Pinch follows the fingers directly; the buttons glide.
    func pinch(_ f: Double) {
        guard flight?.done == nil else { return }
        var v = view(at: PaperClock.now); flight = nil
        v.scale = min(250, max(25, v.scale * f)); resting = v
    }

    func pan(_ dx: Double, _ dy: Double) {
        // never cut short a move that has something to do when it ends (tilting flat before leaving)
        guard flight?.done == nil else { return }
        var v = view(at: PaperClock.now); flight = nil
        let (_, r, u) = v.axes
        v.target = v.target + r * (-dx / v.scale) + u * (dy / v.scale); resting = v
    }

    func tapScreen(_ p: Point) {
        let hit = view(at: PaperClock.now).unproject(p, screen: screen)
        tap(.init(Int(floor(hit.x - origin.x)), Int(floor(hit.z - origin.z))))
    }

    /// The paper tilts; the squares rise into the first layer of cubes. On a narrow screen the view
    /// steps back a little and centres on the box so the whole box fits.
    private func lift() {
        let now = view(at: PaperClock.now)
        var to = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth, scale: now.scale, target: now.target)
        let w = to.width(of: corners) / to.scale
        let fit = (screen.width - 72) / w
        if fit < to.scale { to.scale = fit; to.target = Vec3(origin.x + Double(box.length) / 2, Double(box.height) / 2, origin.z + Double(box.width) / 2) }
        move(to: to, duration: Self.beat)
        tiltAt = time(0); untiltAt = nil
        layerAt[0] = time(Self.beat * 0.55)
        squaresGoneAt = time(Self.beat * 0.55)
    }

    /// Before leaving, the paper tilts back flat, so the hand-over to the flat paper moves nothing.
    func flatten(then done: @escaping (PaperView3D) -> Void) {
        let now = view(at: PaperClock.now)
        guard tiltAt != nil else { done(now); return }
        let (dir, _, _) = now.axes
        let t = now.target - dir * (now.target.y / dir.y)
        untiltAt = time(0); tiltAt = nil
        move(to: PaperView3D(scale: now.scale, target: t), duration: Self.beat, done: done)
    }

    private func restart() {
        busyUntil = time(Self.beat + 0.1)
        flatten { [self] v in
            lesson = session.makeRun(UnitCubes.spec, using: &rng)
            squares = [:]; squaresGoneAt = nil; layerAt = [:]; message = nil; wordsAt = PaperClock.now
            resting = v
        }
    }

    private func time(_ delay: Double) -> Double { instant ? PaperClock.now - 100 : PaperClock.now + delay }

    var corners: [Vec3] {
        var out: [Vec3] = []
        for x in [0, box.length] { for y in [0, box.height] { for z in [0, box.width] {
            out.append(Vec3(origin.x + Double(x), Double(y), origin.z + Double(z)))
        } } }
        return out
    }

    // MARK: read at a moment in time, for drawing

    /// 0 = flat, 1 = tilted. Moves the question up out of the cubes' way.
    func tilt(at t: Double) -> Double {
        if let a = tiltAt { return ease((t - a) / Self.beat) }
        if let a = untiltAt { return 1 - ease((t - a) / Self.beat) }
        return 0
    }

    /// How far a square has grown in (0...1).
    func square(_ c: UnitCubes.Cell, at t: Double) -> Double {
        let ahead = preview.flatMap { p in UnitCubes.cell(c, in: box).map { p.level($0, at: t) } } ?? 0
        guard let s = squares[c] else { return ahead }
        var k = ease((t - s.at) / 0.26); if !s.on { k = 1 - k }
        k = max(k, ahead)
        if let g = squaresGoneAt { k *= 1 - ease((t - g) / 0.5) }
        return k
    }

    /// How tall a cube is (0...1); cubes in a layer rise one after another.
    func cube(x: Int, y: Int, z: Int, at t: Double) -> Double {
        guard let a = layerAt[y] else { return 0 }
        let i = Double(z * box.length + x)
        return ease((t - a - i * (y == 0 ? 0.04 : 0.035)) / 0.7)
    }

    func heightLabel(at t: Double) -> Double {
        guard lesson.picture["height"] == 1, let a = layerAt[box.height - 1] else { return 0 }
        return ease((t - a - 0.5) / 0.4)
    }
}
