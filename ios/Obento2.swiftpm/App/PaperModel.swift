import SwiftUI

/// One lesson drawn on the paper as a small picture of its own maths.
struct Piece: Identifiable, Equatable {
    enum State { case learned, now, notYet }
    let id: String
    let name: String
    let chapter: Chapter
    /// Top-left of the picture frame, on grid lines.
    let at: Point
    /// The lesson behind this piece, if one has been written.
    var spec: LessonSpec? { Lessons.spec(id) }
    var opens: Bool { spec != nil }

    /// Learned, up next (the first lesson in its chapter not learned yet), or not yet.
    @MainActor var state: State {
        if Progress.shared.learned.contains(id) { return .learned }
        let next = Map.pieces.first { $0.chapter == chapter && $0.opens && !Progress.shared.learned.contains($0.id) }
        return next?.id == id ? .now : .notYet
    }

    static let size = Size(240, 180)
    var frame: Rect { Rect(x: at.x, y: at.y, width: Piece.size.width, height: Piece.size.height) }
    /// The frame, its name and its Start block: what a tap glides to.
    var focus: Rect { Rect(x: at.x - 20, y: at.y - 20, width: Piece.size.width + 40, height: Piece.size.height + 140) }
    var start: Rect { Rect(x: at.x, y: at.y + Piece.size.height + 40, width: 160, height: 40) }

    /// How far a piece has drawn itself in (0...1). They draw outward from today's lesson.
    @MainActor static func drawIn(_ p: Piece, time: Double, drawnAt: Double) -> Double {
        let now = (Map.pieces.first { $0.state == .now } ?? Map.pieces[0]).frame.mid
        let d = hypot(p.frame.mid.x - now.x, p.frame.mid.y - now.y) / 1400
        return ease((time - drawnAt - d) / 0.9)
    }
    static let drawTime = 1.9
}

/// A chapter on the paper: its title, where it sits, and its lessons in order, laid out in rows on the grid.
struct ChapterGroup {
    let chapter: Chapter
    let origin: Point
    let columns: Int
    let lessons: [(id: String, name: String)]
    static let pitch = Size(300, 300)

    var pieces: [Piece] {
        lessons.enumerated().map { i, l in
            Piece(id: l.id, name: l.name, chapter: chapter,
                  at: Point(origin.x + Double(i % columns) * Self.pitch.width, origin.y + 80 + Double(i / columns) * Self.pitch.height))
        }
    }
}

/// 5th grade on the paper: the 17 lessons of specs/k12/grade5.md in four chapters, laid out two by two as v27 does,
/// with the Paper proof's two lessons (Unit cubes, Add with different bottoms) in their chapters.
enum Map {
    static let grade = (number: "5", name: "5th grade")
    static let groups: [ChapterGroup] = [
        ChapterGroup(chapter: .whole, origin: Point(0, 0), columns: 3, lessons: [
            ("g5-mult2", "Multiply two-digit numbers"), ("g5-divide", "Long division"), ("g5-order", "Order of operations")]),
        ChapterGroup(chapter: .decimals, origin: Point(1000, 0), columns: 3, lessons: [
            ("g5-pow10", "Multiply by 10, 100, 1000"), ("g5-round", "Rounding decimals"), ("g5-adddec", "Adding decimals"),
            ("g5-multdec", "Multiplying decimals"), ("g5-divdec", "Dividing by a decimal")]),
        ChapterGroup(chapter: .fractions, origin: Point(0, 440), columns: 3, lessons: [
            ("ad", "Add with different bottoms"), ("add", "Adding fractions"), ("sub", "Subtracting fractions"),
            ("mix", "Adding and subtracting"), ("g5-multfrac", "Multiplying fractions"), ("g5-improper", "Mixed numbers to fractions"),
            ("g5-fracof", "Fraction of a number"), ("g5-unitdiv", "Dividing by a unit fraction")]),
        ChapterGroup(chapter: .measurement, origin: Point(1000, 740), columns: 3, lessons: [
            ("uc", "Unit cubes"), ("g5-volume", "Volume of a box"), ("g5-units", "Converting units")]),
    ]
    static let pieces = groups.flatMap(\.pieces)
    /// The grade's own lessons (the specs' 17), for "5 of 17 learned".
    static let gradeLessons = pieces.map(\.id).filter { $0 != "ad" && $0 != "uc" }
    /// A lesson's number within its chapter, in map order.
    static func number(_ p: Piece) -> Int { (pieces.filter { $0.chapter == p.chapter }.firstIndex { $0.id == p.id } ?? 0) + 1 }
    static var bounds: Rect { Rect(x: -20, y: -20, width: 1940, height: 1460) }
}

/// The paper's camera and what's on it. One clock drives every move, so the grid and the paper never come apart.
@MainActor @Observable
final class PaperModel {
    /// When the screen changes shape (rotating), the paper point in the middle stays in the middle,
    /// and an open lesson takes the new size, so its words and its picture still agree.
    var screen = Size(1180, 820) {
        didSet {
            guard screen != oldValue else { return }
            let was = flight?.camera(at: PaperClock.now, screen: oldValue) ?? resting
            let c = was.toPaper(Point(oldValue.width / 2, oldValue.height / 2))
            flight = nil
            resting = PaperCamera(x: screen.width / 2 - c.x * was.zoom, y: screen.height / 2 - c.y * was.zoom, zoom: was.zoom)
            lesson?.screen = screen
        }
    }
    private(set) var resting = PaperCamera()
    private(set) var flight: CameraFlight?
    var selected: Piece?
    var lesson: UnitCubesModel?
    /// The flat lesson, when one is open. It uses the paper's own camera.
    var bars: AddFractionsModel?
    /// A lesson worked in steps, when one is open. It uses the paper's own camera too.
    var steps: StepsModel?
    /// The piece whose lesson is open: its name goes in the top bar.
    var openPiece: Piece? { lesson != nil || bars != nil || steps != nil ? opened : nil }
    private var opened: Piece?
    /// When the pieces started drawing themselves.
    var drawnAt: Double = PaperClock.now
    var instant = false
    /// A fixed box, for screenshots.
    var shotBox: UnitCubes.Box?
    var shotProblem: AddFractions.Problem?
    var shotNumbers: Numbers?

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

    /// The whole map, framed, with room for the top bar above it.
    func frameGroup(duration: Double = CameraTiming.fly) {
        let b = Map.bounds, bar = 72.0
        var cam = PaperCamera.framing(b, in: Size(screen.width, screen.height - bar), maxZoom: 1.4)
        cam.y += bar
        fly(to: cam, duration: duration)
    }

    /// The crosshair: glide to the lesson that's up next.
    func findNext() { if let p = Map.pieces.first(where: { $0.state == .now }) { select(p) } }

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
        if let b = bars { b.tapPaper(p); return }
        if steps != nil { return }
        if let sel = selected, sel.opens, contains(sel.start, p) { open(sel); return }
        select(Map.pieces.first(where: { contains($0.frame, p) || contains(Rect(x: $0.at.x, y: $0.at.y + 180, width: 240, height: 40), p) }))
    }

    /// Opening Unit cubes: fly the flat paper to the lesson, then hand the same view to the 3D camera.
    func open(_ p: Piece) {
        opened = p
        // the lesson's picture master decides how it opens: flat on the paper, or in 3D
        guard let spec = p.spec else { return }
        // Unit cubes and Add with different bottoms are the Paper proof's own lessons; every other lesson is worked in steps
        if p.id == "ad" { openBars(p); return }
        if p.id != "uc" { openSteps(p, spec); return }
        let origin = UnitCubesModel.origin(for: p)
        let wide = screen.width > 760
        let frame = Rect(x: origin.x * Paper.unit - 40, y: origin.z * Paper.unit - 200, width: 480, height: 640)
        fly(to: .framing(frame, in: screen, pad: wide ? 30 : 8, maxZoom: 1), duration: CameraTiming.fly)
        let go = { [self] in
            let cam = flight?.to ?? camera(at: PaperClock.now)
            lesson = UnitCubesModel(origin: origin, chapter: p.chapter, view: .matching(cam, screen: screen), screen: screen, instant: instant, box: shotBox)
            selected = nil
        }
        if instant { go() } else { Task { try? await Task.sleep(for: .seconds(CameraTiming.fly + 0.04)); go() } }
    }

    /// Opening the flat lesson: glide to it, then the pieces grow in. It never tilts, so the paper's camera stays in charge.
    func openBars(_ p: Piece) {
        let b = AddFractionsModel(origin: AddFractionsModel.origin(for: p), chapter: p.chapter, instant: instant, problem: shotProblem)
        fly(to: .framing(b.frame, in: screen, pad: screen.width > 760 ? 30 : 8, maxZoom: 1), duration: CameraTiming.fly)
        let go = { [self] in b.start(); bars = b; selected = nil }
        if instant { go() } else { Task { try? await Task.sleep(for: .seconds(CameraTiming.fly + 0.04)); go() } }
    }

    /// Opening a lesson worked in steps: glide to it, then its picture grows in. Flat, on the paper's camera.
    func openSteps(_ p: Piece, _ spec: LessonSpec) {
        let s = StepsModel(spec: spec, origin: p.at, chapter: p.chapter, number: Map.number(p), instant: instant, numbers: shotNumbers)
        fly(to: .framing(s.frame, in: screen, pad: screen.width > 760 ? 30 : 8, maxZoom: 1), duration: CameraTiming.fly)
        let go = { [self] in s.start(); steps = s; selected = nil }
        if instant { go() } else { Task { try? await Task.sleep(for: .seconds(CameraTiming.fly + 0.04)); go() } }
    }

    /// The crosshair inside a flat lesson: glide back to the whole lesson.
    func reframe() {
        let pad = screen.width > 760 ? 30.0 : 8
        if let b = bars { fly(to: .framing(b.frame, in: screen, pad: pad, maxZoom: 1), duration: CameraTiming.fly) }
        if let s = steps { fly(to: .framing(s.frame, in: screen, pad: pad, maxZoom: 1), duration: CameraTiming.fly) }
    }

    /// Leaving the lesson: it tilts back flat first, then the paper takes the same view back.
    func close() {
        if bars != nil { bars = nil; return }
        if steps != nil { steps = nil; return }
        guard let l = lesson else { return }
        l.flatten { [self] view in
            stop(); resting = view.paperCamera(screen: screen); lesson = nil
        }
    }

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

enum PaperClock { static var now: Double { Date().timeIntervalSinceReferenceDate } }
