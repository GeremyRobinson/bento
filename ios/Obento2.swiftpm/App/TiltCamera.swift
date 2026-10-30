import SwiftUI

/// The paper's camera while a lesson stands up off it (LESSONS.md §6; Unit cubes): the same camera that shows the
/// flat paper from straight above (with perspective, PaperView3D), turned to look at it from the side. It starts exactly where the flat
/// camera is, moves in one ease (angles straight, zoom in log space), and comes back down onto the flat camera, so
/// neither hand-over moves a single line. While it's tilted, a drag pans it and a pinch zooms it.
@MainActor @Observable
final class TiltCamera {
    /// The paper tilting into 3D and back (snappier, G 17 Oct: was 1.1 s).
    static let beat = 0.9
    /// Lying flat again on the way out of a problem: quick, so the paper is flat by the time what comes next draws
    /// in (the page's cards start 0.35 s after Problems, the next problem 0.4 s after Next problem).
    static let away = 0.35

    let instant: Bool
    private(set) var resting: PaperView3D
    struct Flight { let from: PaperView3D, to: PaperView3D, start: Double, duration: Double, done: ((PaperView3D) -> Void)? }
    private(set) var flight: Flight?
    /// Told on a pinch, so the bar can show the zoom.
    var onPinch: (() -> Void)?

    init(_ view: PaperView3D, instant: Bool) { resting = view; self.instant = instant }

    func view(at t: Double) -> PaperView3D {
        guard let f = flight else { return resting }
        return .between(f.from, f.to, (t - f.start) / f.duration)
    }
    /// A move is under way (one whose end nothing waits on is over once its time is up).
    var moving: Bool { flight.map { $0.done != nil || PaperClock.now < $0.start + $0.duration } ?? false }
    /// When the move under way ends.
    var lands: Double { flight.map { $0.start + $0.duration } ?? 0 }

    /// A finished move comes to rest where it was going (and says so).
    func settle(at t: Double) {
        guard let f = flight, t - f.start >= f.duration else { return }
        resting = f.to; flight = nil; f.done?(f.to)
    }

    /// Moves from where it is now (or at `start`, when the move is planned to begin then) to `v`.
    func move(to v: PaperView3D, duration: Double, start: Double? = nil, done: ((PaperView3D) -> Void)? = nil) {
        let at = start ?? PaperClock.now, from = view(at: at)
        if instant || duration == 0 { flight = nil; resting = v; done?(v); return }
        resting = from; flight = Flight(from: from, to: v, start: at, duration: duration, done: done)
    }

    /// Starts a move from a given view (the flat camera's, as the paper starts to tilt) at a given moment.
    func start(from: PaperView3D, to v: PaperView3D, at: Double, duration: Double) {
        if instant || duration == 0 { flight = nil; resting = v; return }
        resting = from; flight = Flight(from: from, to: v, start: at, duration: duration, done: nil)
    }

    func zoom(_ f: Double) {
        var v = view(at: PaperClock.now); v.scale = min(250, max(25, v.scale * f)); move(to: v, duration: 0.3)
    }

    /// Pinch follows the fingers directly.
    func pinch(_ f: Double) {
        guard flight?.done == nil else { return }
        onPinch?()
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

    /// The same view looking straight down, its middle slid down its line of sight onto the paper: flat again, nothing
    /// moved but the tilt.
    static func flat(_ v: PaperView3D) -> PaperView3D {
        let (dir, _, _) = v.axes
        return PaperView3D(scale: v.scale, target: v.target - dir * (v.target.y / dir.y))
    }

    /// The tilted view (PaperView3D.tilted: 52° up, turned 28°) that shows everything in `extent`, zoomed to fit the free part of
    /// the screen (in or out, up to `maxZoom`) and centred in it, with two cells to spare. `extent` is measured on the
    /// screen through `probe`: a tilted view at 100% (one block = 100 points), whose target is anywhere near the
    /// picture. Words are paper-sized, so the whole of it grows and shrinks together with the zoom.
    static func fit(_ extent: CGRect, probe: PaperView3D, screen: Size, top: Double, bottom: Double, maxZoom: Double = CameraTiming.lessonMax) -> PaperView3D {
        let m = screen.width > 760 ? 2 * Paper.cell : 8
        let w = screen.width - 2 * m, h = max(80, screen.height - top - bottom - 2 * m)
        let f = max(Paper.minZoom, min(maxZoom * Paper.unit / probe.scale, w / max(1, extent.width), h / max(1, extent.height)))
        var v = probe
        let (_, r, u) = v.axes
        // the extent's middle, a point on the view's plane through the probe's target
        let mid = probe.target + r * ((extent.midX - screen.width / 2) / probe.scale) + u * ((screen.height / 2 - extent.midY) / probe.scale)
        v.scale = probe.scale * f
        // it sits in the middle of the free space between the top and the bar (or the keyboard)
        let free = top + m + h / 2
        v.target = mid - u * ((screen.height / 2 - free) / v.scale)
        return v
    }

    /// A tilted view at 100% looking at `p`, to measure a picture's extent on the screen before fitting it.
    static func probe(_ p: Vec3) -> PaperView3D {
        PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth, scale: Paper.unit, target: p)
    }

    // MARK: the problem that holds the camera

    /// The problem the paper is seen through while it stands tilted, until it lies flat again. Held strongly, so a
    /// page that closes while the paper flattens doesn't cut the move short.
    static var owner: (any TiltOwner)?
    /// The screen, and the room kept clear at its top and bottom (the floating bar, or the keyboard while a number is
    /// typed), as the flat camera keeps them.
    static var screen = Size(1180, 820), top = 24.0, bottom = 120.0
    /// The flat camera's view at the last frame: where a tilt starts from.
    static var flatNow = PaperView3D()

    /// The view the paper is seen through (PaperModel.view): the problem's while it holds the camera, else the flat
    /// paper's. It only reads, as a frame being drawn may: what changes happens in `settle`.
    static func view(at t: Double, flat: PaperView3D) -> PaperView3D { owner?.view(at: t, flat: flat) ?? flat }

    /// Each frame, between frames (PaperModel.settle, never while one is drawn): where a tilt starts from and what it
    /// fits into (the flat view, the screen, the room the bar or the keyboard takes); a problem no longer on the page (its
    /// How to played straight through, the lesson closed) lies flat again; the problem holding the camera settles its
    /// view; once the paper lies flat, nobody holds it.
    static func settle(at t: Double, flat: PaperView3D, screen: Size, top: Double, bottom: Double, onPage: (any TiltOwner) -> Bool) {
        flatNow = flat; self.screen = screen; self.top = top; self.bottom = bottom
        guard let o = owner else { return }
        if !onPage(o) { o.lieFlat() }
        o.settle(at: t, flat: flat)
        if !o.holdsCamera { owner = nil }
    }

    /// Where a point on the screen lands on the paper while the paper stands tilted (a tap on a block or on the box, the
    /// paper under a dragging finger); nil while it's flat.
    static func paperPoint(_ s: Point, tap: Bool) -> Point? { owner.flatMap { tap ? $0.tapPoint(s) : $0.dragPoint(s) } }
    /// A drag that isn't a hand move, and a pinch, move the tilted view; false while the paper is flat (its own camera's).
    static func pan(_ dx: Double, _ dy: Double) -> Bool { owner?.pan(dx, dy) ?? false }
    static func pinch(_ f: Double) -> Bool { owner?.pinch(f) ?? false }
}

/// A problem on a lesson's page that tilts the paper (Volume of a box). While it holds the camera, the paper is seen
/// through its view, and the paper's taps and drags are worked out through it.
@MainActor
protocol TiltOwner: AnyObject {
    /// The view while the paper stands tilted (or is tilting, or lying flat again); nil once it lies flat, when the
    /// flat camera shows the paper again. `flat` is the flat camera's view now: where a tilt starts and a flattening ends.
    /// Only reads: it's asked while a frame is drawn.
    func view(at t: Double, flat: PaperView3D) -> PaperView3D?
    /// Between frames: the tilt anchored to the flat view on its first frame, the view framed again when the room for it
    /// changed.
    func settle(at t: Double, flat: PaperView3D)
    /// Where a tap on the screen lands while tilted, in paper points: a block's place, the box, or nowhere.
    func tapPoint(_ s: Point) -> Point?
    /// The paper point under a finger that drags, while tilted.
    func dragPoint(_ s: Point) -> Point?
    /// A drag that isn't a hand move, and a pinch: they move the tilted view. False when it's flat (the paper's own).
    func pan(_ dx: Double, _ dy: Double) -> Bool
    func pinch(_ f: Double) -> Bool
    /// It isn't on the page any more: it lies flat again.
    func lieFlat()
    /// The paper stands tilted through it (or is still lying flat again).
    var holdsCamera: Bool { get }
    /// While it lies flat again: when the paper is flat.
    var flatEnds: Double? { get }
}
