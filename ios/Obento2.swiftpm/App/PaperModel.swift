import SwiftUI

/// One lesson drawn on the paper as a small picture of its own maths.
struct Piece: Identifiable, Equatable {
    enum State { case learned, now, notYet }
    let id: String
    let name: String
    let chapter: Chapter
    let state: State
    /// Top-left of the picture frame, on grid lines.
    let at: Point
    /// Only Unit cubes opens in the Paper proof.
    var opens: Bool { id == "uc" }

    static let size = Size(240, 180)
    var frame: Rect { Rect(x: at.x, y: at.y, width: Piece.size.width, height: Piece.size.height) }
    /// The frame, its name and its Start block: what a tap glides to.
    var focus: Rect { Rect(x: at.x - 20, y: at.y - 20, width: Piece.size.width + 40, height: Piece.size.height + 140) }
    var start: Rect { Rect(x: at.x, y: at.y + Piece.size.height + 40, width: 160, height: 40) }

    /// How far a piece has drawn itself in (0...1). They draw outward from today's lesson.
    static func drawIn(_ p: Piece, time: Double, drawnAt: Double) -> Double {
        let now = Volume.pieces.first { $0.state == .now }!.frame.mid
        let d = hypot(p.frame.mid.x - now.x, p.frame.mid.y - now.y) / 900
        return ease((time - drawnAt - d) / 0.9)
    }
    static let drawTime = 1.6
}

/// The Volume chapter, laid out on the 20 pt grid.
enum Volume {
    static let title = "Volume"
    static let origin = Point(0, 0)
    static let pieces: [Piece] = [
        Piece(id: "sq", name: "Squares on a floor", chapter: .volume, state: .learned, at: .init(0, 80)),
        Piece(id: "uc", name: "Unit cubes", chapter: .volume, state: .now, at: .init(300, 80)),
        Piece(id: "ly", name: "Layers of cubes", chapter: .volume, state: .notYet, at: .init(0, 380)),
        Piece(id: "lwh", name: "Length × width × height", chapter: .volume, state: .notYet, at: .init(300, 380)),
    ]
    static var bounds: Rect { Rect(x: -20, y: -20, width: 580, height: 640) }
}

/// The paper's camera and what's on it. One clock drives every move, so the grid and the paper never come apart.
@MainActor @Observable
final class PaperModel {
    var screen = Size(1180, 820)
    private(set) var resting = PaperCamera()
    private(set) var flight: CameraFlight?
    var selected: Piece?
    var lesson: UnitCubesModel?
    /// When the pieces started drawing themselves.
    var drawnAt: Double = PaperClock.now
    var instant = false
    /// A fixed box, for screenshots.
    var shotBox: UnitCubes.Box?

    func camera(at t: Double) -> PaperCamera { flight?.camera(at: t, screen: screen) ?? resting }
    /// The one camera the paper's scene is seen through: the open lesson's, or the flat paper's from straight above.
    func view(at t: Double) -> PaperView3D { lesson?.view(at: t) ?? .matching(camera(at: t), screen: screen) }
    var moving: Bool { flight != nil }

    func settle(at t: Double) { if let f = flight, f.done(at: t) { resting = f.to; flight = nil } }

    func fly(to cam: PaperCamera, duration: Double) {
        let now = PaperClock.now
        let from = camera(at: now)
        flight = instant ? nil : CameraFlight(from: from, to: cam, start: now, duration: duration)
        if instant { resting = cam } else { resting = from }
    }

    func stop() { let c = camera(at: PaperClock.now); flight = nil; resting = c }

    func pan(_ dx: Double, _ dy: Double) { stop(); resting = resting.panned(by: dx, dy) }
    func zoom(by f: Double, at p: Point) { stop(); resting = resting.zoomed(by: f, at: p) }

    func zoomButton(_ f: Double) {
        fly(to: camera(at: PaperClock.now).zoomed(by: f, at: .init(screen.width / 2, screen.height / 2)), duration: CameraTiming.fly)
    }

    /// The whole lesson group, framed.
    func frameGroup(duration: Double = CameraTiming.fly) {
        fly(to: .framing(Volume.bounds, in: screen, maxZoom: 1.4), duration: duration)
    }

    /// The crosshair: glide to the lesson that's up next.
    func findNext() { if let p = Volume.pieces.first(where: { $0.state == .now }) { select(p) } }

    /// A tap on a lesson: a slow, gentle glide that brings it closer, not too close.
    func select(_ p: Piece?) {
        selected = p
        guard let p else { return }
        let now = camera(at: PaperClock.now)
        let fit = PaperCamera.framing(p.focus, in: screen)
        let z = min(fit.zoom, max(now.zoom, min(now.zoom * CameraTiming.glideZoom, 1.6)))
        let c = p.focus.mid
        fly(to: PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z), duration: CameraTiming.glide)
    }

    func tap(at s: Point) {
        let p = camera(at: PaperClock.now).toPaper(s)
        if let sel = selected, sel.opens, contains(sel.start, p) { open(sel); return }
        select(Volume.pieces.first(where: { contains($0.frame, p) || contains(Rect(x: $0.at.x, y: $0.at.y + 180, width: 240, height: 40), p) }))
    }

    /// Opening Unit cubes: fly the flat paper to the lesson, then hand the same view to the 3D camera.
    func open(_ p: Piece) {
        let origin = UnitCubesModel.origin(for: p)
        let wide = screen.width > 760
        let frame = Rect(x: origin.x * Paper.unit - 40, y: origin.z * Paper.unit - 200, width: 480, height: 640)
        fly(to: .framing(frame, in: screen, pad: wide ? 30 : 8, maxZoom: 1), duration: CameraTiming.fly)
        let target = resting
        let go = { [self] in
            let cam = flight?.to ?? target
            lesson = UnitCubesModel(origin: origin, chapter: p.chapter, view: .matching(cam, screen: screen), screen: screen, instant: instant, box: shotBox)
            selected = nil
        }
        if instant { go() } else { Task { try? await Task.sleep(for: .seconds(CameraTiming.fly + 0.04)); go() } }
    }

    /// Leaving the lesson: it tilts back flat first, then the paper takes the same view back.
    func close() {
        guard let l = lesson else { return }
        l.flatten { [self] view in
            stop(); resting = view.paperCamera(screen: screen); lesson = nil
        }
    }

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

enum PaperClock { static var now: Double { Date().timeIntervalSinceReferenceDate } }
