import SwiftUI
import ObentoCore

/// Unit cubes on the paper, in 3D. The lesson logic lives in ObentoCore; this keeps the timing:
/// when each square appeared, when each layer started rising, and where the camera is going.
@MainActor @Observable
final class UnitCubesModel {
    static let beat = 1.1

    /// The box's back-left corner, in world units (one unit = one big square), on the paper's strong lines.
    let origin: Vec3
    let chapter: Chapter
    var screen: Size
    let instant: Bool
    private(set) var lesson: UnitCubes
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

    init(origin: Vec3, chapter: Chapter, view: PaperView3D, screen: Size, instant: Bool, box: UnitCubes.Box? = nil) {
        self.origin = origin; self.chapter = chapter; self.resting = view; self.screen = screen; self.instant = instant
        var r = SeededRandom(seed: UInt64(Date().timeIntervalSince1970))
        lesson = box.map { UnitCubes(box: $0) } ?? UnitCubes.generate(using: &r)
        rng = r
    }

    /// The lesson sits on strong lines just inside the lesson's picture frame.
    static func origin(for p: Piece) -> Vec3 {
        Vec3(((p.at.x + 10) / Paper.unit).rounded(), 0, ((p.at.y + 40) / Paper.unit).rounded())
    }

    var box: UnitCubes.Box { lesson.box }
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

    func go() {
        let before = lesson.layers
        switch lesson.go() {
        case .moved(.stack(layers: 1)) where before == 0: lift()
        case .moved: if before > 0, lesson.layers > before { layerAt[lesson.layers - 1] = time(0) }
        case .notYet(let empty): message = (UnitCubes.notYetLine(empty), false); return
        case .newProblem: restart(); return
        }
        message = nil; wordsAt = PaperClock.now
    }

    func tap(_ c: UnitCubes.Cell) {
        guard lesson.tap(c) else { return }
        squares[c] = (lesson.covered.contains(c), time(0)); message = nil
    }

    func showMe() {
        for (i, c) in lesson.showMe().enumerated() { squares[c] = (true, time(0.06 * Double(i))) }
        message = nil
    }

    func reset() {
        let was = lesson.covered; lesson.reset()
        for c in was { squares[c] = (false, time(0)) }
        message = nil
    }

    func zoom(_ f: Double) {
        var v = view(at: PaperClock.now); v.scale = min(250, max(25, v.scale * f)); move(to: v, duration: 0.4)
    }

    func pan(_ dx: Double, _ dy: Double) {
        var v = view(at: PaperClock.now); flight = nil
        let (_, r, u) = v.axes
        v.target = v.target + r * (-dx / v.scale) + u * (dy / v.scale); resting = v
    }

    func tapScreen(_ p: ObentoCore.Point) {
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
        flatten { [self] v in
            lesson = UnitCubes.generate(using: &rng)
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
        guard let s = squares[c] else { return 0 }
        var k = ease((t - s.at) / 0.26); if !s.on { k = 1 - k }
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
        guard lesson.step == .done, let a = layerAt[box.height - 1] else { return 0 }
        return ease((t - a - 0.5) / 0.4)
    }
}
