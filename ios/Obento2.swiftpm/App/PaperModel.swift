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
    /// Only lessons built the paper way open (LESSONS.md); the rest wait, locked, for G's OK on their web preview.
    @MainActor var opens: Bool { isTest ? Map.testReady(id) : spec != nil && Map.paperLessons.contains(id) }
    /// A chapter or grade test, not a lesson (G 18 Oct).
    var isTest: Bool { id.hasPrefix("test-") }

    /// Learned, up next (the first lesson in its chapter not learned yet), or not yet.
    @MainActor var state: State {
        if isTest { return (Progress.shared.tests[id] ?? 0) >= Mastery.pass ? .learned : opens ? .now : .notYet }
        if Progress.shared.learned.contains(id) { return .learned }
        let next = Map.pieces.first { $0.chapter == chapter && $0.opens && !Progress.shared.learned.contains($0.id) }
        return next?.id == id ? .now : .notYet
    }

    /// Graph paper (G 17 Oct): 3 blocks by 2, starting and ending on the strong lines; its name and Start block fill
    /// the block under it.
    static let size = Size(3 * Paper.unit, 2 * Paper.unit)
    var frame: Rect { Rect(x: at.x, y: at.y, width: Piece.size.width, height: Piece.size.height) }
    /// The frame, its name and its Start block: what a tap glides to.
    var focus: Rect { Rect(x: at.x - 20, y: at.y - 40, width: Piece.size.width + 40, height: Piece.size.height + 120) }
    /// The chosen lesson's tag on its frame's top-right corner, which says Start (or Keep going): the Up next tab's place.
    var start: Rect { Rect(x: at.x + Piece.size.width - 140, y: at.y - 20, width: 140, height: 20) }

    /// How far a piece has drawn itself in (0...1). They draw outward from `from` (the lesson just left), else from
    /// today's lesson.
    @MainActor static func drawIn(_ p: Piece, time: Double, drawnAt: Double, from: Point? = nil) -> Double {
        let now = from ?? (Map.pieces.first { $0.state == .now } ?? Map.pieces[0]).frame.mid
        let d = hypot(p.frame.mid.x - now.x, p.frame.mid.y - now.y) / 1400
        return ease((time - drawnAt - d) / 0.9)
    }
    static let drawTime = 1.9
    /// How long after the map starts drawing a place draws in: the further from where it draws out from, the later.
    @MainActor static func drawDelay(_ p: Point, from: Point? = nil) -> Double {
        let now = from ?? (Map.pieces.first { $0.state == .now } ?? Map.pieces[0]).frame.mid
        return hypot(p.x - now.x, p.y - now.y) / 1400
    }
}

/// A chapter on the paper: its title, where it sits, and its lessons in order, laid out in rows on the grid.
struct ChapterGroup {
    let chapter: Chapter
    let origin: Point
    let columns: Int
    let lessons: [(id: String, name: String)]
    /// Inside a group, one block between lessons (G 17 Oct): a frame and one block across; a frame and the block with
    /// its name down. Groups are two blocks apart. Start is the frame's tag, not a block under it (G 18 Oct).
    static let pitch = Size(4 * Paper.unit, 3 * Paper.unit)

    var pieces: [Piece] {
        lessons.enumerated().map { i, l in
            Piece(id: l.id, name: l.name, chapter: chapter,
                  at: Point(origin.x + Double(i % columns) * Self.pitch.width, origin.y + Paper.unit + Double(i / columns) * Self.pitch.height))
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
        ChapterGroup(chapter: .decimals, origin: Point(1300, 0), columns: 3, lessons: [
            ("g5-pow10", "Multiply by 10, 100, 1000"), ("g5-round", "Rounding decimals"), ("g5-adddec", "Adding decimals"),
            ("g5-multdec", "Multiplying decimals"), ("g5-divdec", "Dividing by a decimal")]),
        ChapterGroup(chapter: .fractions, origin: Point(0, 900), columns: 3, lessons: [
            ("ad", "Add with different bottoms"), ("add", "Adding fractions"), ("sub", "Subtracting fractions"),
            ("mix", "Adding and subtracting"), ("g5-multfrac", "Multiplying fractions"), ("g5-improper", "Mixed numbers to fractions"),
            ("g5-fracof", "Fraction of a number"), ("g5-unitdiv", "Dividing by a unit fraction")]),
        ChapterGroup(chapter: .measurement, origin: Point(1300, 900), columns: 3, lessons: [
            ("uc", "Unit cubes"), ("g5-volume", "Volume of a box"), ("g5-units", "Converting units")]),
    ]
    static let pieces = groups.flatMap(\.pieces)

    /// Each chapter's test, in the slot after its last lesson, and the grade's test under everything (G 18 Oct).
    static let tests: [Piece] = groups.map { g in
        let i = g.lessons.count
        return Piece(id: "test-\(g.chapter.rawValue)", name: "\(g.chapter.title) test", chapter: g.chapter,
                     at: Point(g.origin.x + Double(i % g.columns) * ChapterGroup.pitch.width, g.origin.y + Paper.unit + Double(i / g.columns) * ChapterGroup.pitch.height))
    } + [Piece(id: "test-grade", name: "\(grade.name) test", chapter: .whole, at: Point(0, 2100))]
    /// Everything drawn on the map.
    static let all = pieces + tests

    /// A chapter's test opens once every lesson there is to do in it is learned; the grade's test once every chapter
    /// test that can be taken has been. Lessons are always open; only tests wait.
    @MainActor static func testReady(_ id: String) -> Bool {
        if id == "test-grade" {
            let ready = tests.filter { $0.id != "test-grade" && chapterHasLessons($0.chapter) }
            return !ready.isEmpty && ready.allSatisfy { Progress.shared.tests[$0.id] != nil }
        }
        guard let t = tests.first(where: { $0.id == id }), chapterHasLessons(t.chapter) else { return false }
        return pieces.filter { $0.chapter == t.chapter && pageLessons.contains($0.id) }.allSatisfy { Progress.shared.learned.contains($0.id) }
    }
    /// A chapter's test draws from lessons built as a page of problems: only Add with different bottoms so far, so only
    /// Fractions has a test to take; the others say Coming soon until their lessons are pages too.
    static let pageLessons: Set<String> = Set(pieces.map(\.id).filter { $0 != "uc" && Lessons.spec($0) != nil })
    /// The lessons a test mixes: its chapter's page lessons, or for the grade's test every one.
    static func testSpecs(_ t: Piece) -> [LessonSpec] {
        pieces.filter { pageLessons.contains($0.id) && (t.id == "test-grade" || $0.chapter == t.chapter) }.compactMap(\.spec)
    }
    static func chapterHasLessons(_ c: Chapter) -> Bool { pieces.contains { $0.chapter == c && pageLessons.contains($0.id) } }
    /// The lessons built the paper way, with G's OK on their preview. The others' maths is ported and tested in Core,
    /// but their screens wait for their previews (LESSONS.md §9).
    static let paperLessons: Set<String> = Set(pieces.map(\.id).filter { Lessons.spec($0) != nil })

    /// Today's pick, by the web's rules (Core/Mastery.swift): what to go over first, then what builds on the lesson just
    /// learned, then the first one ready. Only lessons that open are picked.
    @MainActor static var today: Piece? {
        let open = pieces.filter(\.opens)
        let pick = Mastery.upNext(open.map(\.id), depends: { Lessons.spec($0)?.depends ?? [] },
                                  checks: Progress.shared.checks.filter { !Progress.shared.dueBack($0.key) }, grade: 5)
        return open.first { $0.id == pick?.id }
    }
    /// The grade's own lessons (the specs' 17), for "5 of 17 learned".
    static let gradeLessons = pieces.map(\.id).filter { $0 != "ad" && $0 != "uc" }
    /// A lesson's number within its chapter, in map order.
    static func number(_ p: Piece) -> Int { (pieces.filter { $0.chapter == p.chapter }.firstIndex { $0.id == p.id } ?? 0) + 1 }
    /// Every group, from its title to its last row's name and Start, with a cell to spare: what the overview shows.
    /// Worked out from the layout, so it stays right when groups move.
    static let bounds: Rect = {
        let x0 = groups.map(\.origin.x).min()!, y0 = groups.map(\.origin.y).min()!
        let x1 = all.map { $0.at.x + Piece.size.width }.max()!, y1 = all.map { $0.at.y + Piece.size.height + Paper.unit }.max()!
        let m = Paper.cell
        return Rect(x: x0 - m, y: y0 - m, width: x1 - x0 + 2 * m, height: y1 - y0 + 2 * m)
    }()
}

/// The paper's camera and what's on it. One clock drives every move, so the grid and the paper never come apart.
@MainActor @Observable
final class PaperModel {
    /// When the screen changes shape (rotating), the paper point in the middle stays in the middle,
    /// and an open lesson takes the new size, so its words and its picture still agree.
    var screen = Size(1180, 820) {
        didSet {
            ProblemGrid.screen = screen
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
    var bars: BarsPage?
    /// The piece whose lesson is open: its name goes in the top bar.
    var openPiece: Piece? { lesson != nil || bars != nil ? opened : nil }
    /// Where the child is in the open lesson ("Practice 2 of 6"), for the top bar.
    var sessionLabel: String? { bars?.label ?? lesson?.session.label }
    private var opened: Piece?
    /// When the pieces started drawing themselves.
    var drawnAt: Double = PaperClock.now
    /// When the map started erasing itself, on the way into a lesson (G 17 Oct: the How to's undraw, for every
    /// move from one place to the next).
    private(set) var mapLeftAt: Double?
    /// The map's words are still drawing in or undrawing: the clock keeps running.
    private(set) var mapDrawing = false
    func setMapDrawing(_ b: Bool) { if mapDrawing != b { mapDrawing = b } }
    /// 1 while the map is on the paper, down to 0 as it erases itself: its drawing in, backwards.
    func mapGone(at t: Double) -> Double { mapLeftAt.map { 1 - ease((t - $0) / Self.undraw) } ?? 1 }
    /// How long a place takes to erase itself.
    static let undraw = 0.45
    /// Something is erasing itself: hands off until the next place is there.
    private(set) var leaving = false
    /// Where the drawings draw out from: the lesson just left, after coming out of one.
    var drawFrom: Point?
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

    /// A drag that starts on something the open problem lets the child move goes to the problem (a hand move); any
    /// other drag pans the paper.
    private(set) var handDrag = false
    func dragStart(at s: Point) {
        guard !leaving, let m = bars?.current else { handDrag = false; return }
        handDrag = m.grab(camera(at: PaperClock.now).toPaper(s))
    }
    func dragMove(to s: Point) { bars?.current?.drag(to: camera(at: PaperClock.now).toPaper(s)) }
    func dragEnd() { if handDrag { bars?.current?.release() }; handDrag = false }
    func zoom(by f: Double, at p: Point) { stop(); resting = resting.zoomed(by: f, at: p); pinchedAt = PaperClock.now }
    /// When the paper was last pinched: the bar shows the zoom for a moment.
    var pinchedAt: Double = -100

    func zoomButton(_ f: Double) {
        fly(to: camera(at: PaperClock.now).zoomed(by: f, at: .init(screen.width / 2, screen.height / 2)), duration: CameraTiming.fly)
    }

    /// Room kept clear of the paper's content: a little at the top, and the floating bar at the bottom.
    static let chrome = (top: 24.0, bottom: 120.0)

    /// The whole map's view, clear of the bar.
    var overview: PaperCamera {
        var cam = PaperCamera.framing(Map.bounds, in: Size(screen.width, screen.height - Self.chrome.top - Self.chrome.bottom), maxZoom: 1.4)
        cam.y += Self.chrome.top
        return cam
    }

    /// The overview button: the whole lesson page when one is open, else the whole map.
    func frameAll() {
        if let b = bars { fly(to: framingBelowBar(b.pageFrame, maxZoom: CameraTiming.lessonMax), duration: CameraTiming.fly) }
        else { frameGroup() }
    }

    /// The whole map, framed.
    func frameGroup(duration: Double = CameraTiming.fly) {
        fly(to: overview, duration: duration)
    }

    /// The crosshair: glide to the lesson that's up next.
    func findNext() { if let p = Map.today { select(p) } }

    /// The dial's zoom: straight to `z`, about the middle of the screen.
    func zoomTo(_ z: Double) {
        let now = camera(at: PaperClock.now)
        stop(); resting = now.zoomed(by: z / now.zoom, at: .init(screen.width / 2, screen.height / 2))
    }

    /// The dial's Lessons: a glide to chapter `i`, its title and every lesson in it.
    func frameChapter(_ i: Int) {
        guard Map.groups.indices.contains(i) else { return }
        let g = Map.groups[i], frames = g.pieces.map { Rect(x: $0.at.x, y: $0.at.y, width: Piece.size.width, height: Piece.size.height + Paper.unit) }
        let r = frames.reduce(Rect(x: g.origin.x, y: g.origin.y, width: 1, height: 1)) { $0.union($1) }
        fly(to: framingBelowBar(r, maxZoom: CameraTiming.selectMax), duration: CameraTiming.glide)
    }

    /// A tap on a lesson: a slow, gentle glide that brings it closer, not too close.
    func select(_ p: Piece?) {
        selected = p
        guard let p else { return }
        // a lesson that opens: its first problem is chosen now, and the glide frames the lesson as it will start, at up
        // to the tap's 100% (G 17 Oct)
        if let f = startFrame(p) {
            fly(to: framingBelowBar(f, maxZoom: CameraTiming.selectMax), duration: CameraTiming.glide)
            return
        }
        let now = camera(at: PaperClock.now)
        let z = CameraTiming.selectZoom(current: now.zoom, overview: overview.zoom, fit: PaperCamera.framing(p.focus, in: screen).zoom)
        let c = p.focus.mid
        fly(to: PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z), duration: CameraTiming.glide)
    }

    func tap(at s: Point) {
        guard !leaving else { return }
        let p = camera(at: PaperClock.now).toPaper(s)
        if let b = bars {
            b.tap(p); return
        }
        // the chosen lesson opens from its tag (a little extra all round, for a finger) or a second tap on its frame
        if let sel = selected, sel.opens, contains(Rect(x: sel.start.x - 20, y: sel.start.y - 20, width: sel.start.width + 40, height: sel.start.height + 40), p) || contains(sel.frame, p) {
            open(sel); return
        }
        select(Map.all.first(where: { contains($0.frame, p) || contains($0.start, p) }))
    }

    /// Opening a lesson: the map erases itself, as it drew in, then the lesson opens where it was.
    func open(_ p: Piece) {
        guard !leaving else { return }
        if instant { openNow(p); return }
        leaving = true
        mapLeftAt = PaperClock.now
        Task { [self] in
            try? await Task.sleep(for: .seconds(Self.undraw + 0.05))
            leaving = false
            openNow(p)
            mapLeftAt = nil
        }
    }

    /// Opening Unit cubes: fly the flat paper to the lesson, then hand the same view to the 3D camera.
    private func openNow(_ p: Piece) {
        opened = p
        // the lesson's picture master decides how it opens: flat on the paper, or in 3D
        if p.isTest { openBars(p); return }
        guard let spec = p.spec else { return }
        // Unit cubes and Add with different bottoms are the Paper proof's own lessons; every other lesson is worked in steps
        // every lesson is a page of problems (G 19 Oct), but Unit cubes, which rises into 3D
        if p.id != "uc" { _ = spec; openBars(p); return }
        // Start opens the lesson where it is: the tap already glided to it, so the camera doesn't move again (G 17 Oct).
        // The 3D lesson takes over the camera, so it waits for that glide to land first.
        let origin = UnitCubesModel.origin(for: p)
        let go = { [self] in
            lesson = UnitCubesModel(origin: origin, chapter: p.chapter, view: .matching(camera(at: PaperClock.now), screen: screen), screen: screen, instant: instant,
                                    box: shotBox ?? prepared.flatMap { $0.id == p.id ? UnitCubes.Box($0.numbers) : nil },
                                    session: Progress.shared.dueBack(p.id) ? .recheck : LessonSession())
            lesson?.onPinch = { [weak self] in self?.pinchedAt = PaperClock.now }
            selected = nil
        }
        let landing = flight.map { $0.start + $0.duration - PaperClock.now } ?? 0
        if instant || landing <= 0 { go() } else { Task { try? await Task.sleep(for: .seconds(landing + 0.02)); go() } }
    }

    /// Opening the flat lesson: its page. The How to plays where the lesson is, on the paper's own camera, then the 16
    /// problems draw themselves onto the paper, each live where it sits (BarsPage).
    func openBars(_ p: Piece) {
        let first = (p.id == "ad" ? shotProblem?.numbers : shotNumbers) ?? prepared.flatMap { $0.id == p.id ? $0.numbers : nil }
        let b = BarsPage(piece: p, instant: instant, first: first, saved: instant ? nil : PageStore.load(p.id),
                         test: p.isTest ? (p.id == "test-grade" ? 20 : 12) : nil)
        b.frame = { [weak self] r in self?.frameCurrent(r) }
        bars = b; selected = nil
        b.start()
    }

    /// The crosshair inside a flat lesson: glide back to the whole lesson.
    func reframe() {
        if let b = bars { frameCurrent(b.current.map(BarsPage.box(of:)) ?? (b.showing ? b.firstRow : BarsPage.box(of: b.howTo))) }
    }

    /// Leaving the lesson: it tilts back flat first, then the paper takes the same view back.
    /// A lesson is framed with two cells to spare (LESSONS.md §5).
    static let margin = 2 * Paper.cell

    /// How much of the screen's bottom the iPad's keyboard covers while a number is typed.
    private(set) var keyboard: Double = 0
    func keyboardAppeared(_ h: Double) {
        guard abs(h - keyboard) > 1 else { return }
        keyboard = h
        if bars?.mode == .work { reframe() }
    }

    /// A rect framed clear of the bar (and the keyboard), with two cells to spare, never closer than `maxZoom`.
    func framingBelowBar(_ r: Rect, maxZoom: Double) -> PaperCamera {
        let bottom = max(Self.chrome.bottom, keyboard + 16)
        var cam = PaperCamera.framing(r, in: Size(screen.width, screen.height - Self.chrome.top - bottom), pad: screen.width > 760 ? Self.margin : 8, maxZoom: maxZoom)
        cam.y += Self.chrome.top
        return cam
    }

    /// The first problem of the lesson last tapped, chosen at the tap so its start can be framed exactly.
    private var prepared: (id: String, numbers: Numbers)?
    private var prepRng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))

    /// What a lesson that opens needs in view as it starts (question, picture, buttons), in paper points; nil to frame
    /// the tapped lesson on the map as usual. Its first problem is chosen here either way.
    func startFrame(_ p: Piece) -> Rect? {
        guard p.opens else { return nil }
        switch p.id {
        case "uc":
            let b = shotBox ?? UnitCubes.generate(using: &prepRng)
            prepared = (p.id, b.numbers)
            return UnitCubesModel.startFrame(origin: UnitCubesModel.origin(for: p), box: b)
        case "ad":
            let s = shotProblem ?? AddFractions.problems.randomElement(using: &prepRng)!
            prepared = (p.id, s.numbers)
            // a lesson page frames its own How to when it opens: the tap frames the lesson on the map like any other
            return nil
        default: return nil
        }
    }

    /// Each step, the camera frames what the lesson shows right now: zoomed to fit it (in or out, up to 125%) and
    /// centred on it (G 17 Oct). A move too small to notice is skipped, so the camera doesn't twitch.
    func frameCurrent(_ r: Rect) {
        let now = camera(at: PaperClock.now), to = framingBelowBar(r, maxZoom: CameraTiming.lessonMax)
        let c0 = now.toPaper(Point(screen.width / 2, screen.height / 2)), c1 = to.toPaper(Point(screen.width / 2, screen.height / 2))
        if abs(to.zoom / now.zoom - 1) < 0.02, hypot(c1.x - c0.x, c1.y - c0.y) * now.zoom < 12 { return }
        fly(to: to, duration: CameraTiming.fly)
    }

    /// Leaving a lesson: a 3D one tilts back flat first; then the paper glides back out to the lesson's piece
    /// (LESSONS.md §5), which shows in colour once it's learned.
    func close() {
        guard !leaving else { return }
        let piece = opened
        // a lesson's page erases itself first, as it drew in, then the map draws itself back in
        if let b = bars, !instant {
            leaving = true
            b.leave()
            Task { [self] in
                try? await Task.sleep(for: .seconds(Self.undraw + 0.05))
                leaving = false
                bars = nil; redraw(from: piece); glideOut(to: piece)
            }
            return
        }
        if bars != nil { bars = nil; redraw(from: piece); glideOut(to: piece); return }
        guard let l = lesson else { return }
        l.flatten { [self] view in
            stop(); resting = view.paperCamera(screen: screen); lesson = nil
            redraw(from: piece)
            glideOut(to: piece)
        }
    }

    /// Coming back to the map, the drawings draw themselves in again as they do when the app opens, outward from the
    /// lesson just left (G 17 Oct). Reduce Motion skips it.
    private func redraw(from p: Piece?) {
        guard !instant else { return }
        drawFrom = p?.frame.mid
        drawnAt = PaperClock.now
    }

    /// The gentle glide back to a piece on the map, its frame, name and Start block in view, without choosing it.
    private func glideOut(to p: Piece?) {
        guard let p else { return }
        let z = CameraTiming.selectZoom(current: camera(at: PaperClock.now).zoom, overview: overview.zoom,
                                        fit: PaperCamera.framing(p.focus, in: screen).zoom)
        let c = p.focus.mid
        fly(to: PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z), duration: CameraTiming.glide)
    }

    /// Reduce Motion (LESSONS.md §4): cut straight to every state, with no glide, tilt or draw-in.
    func reduceMotion(_ on: Bool) {
        guard !Shots.active else { return }
        instant = on
        if on { drawnAt = PaperClock.now - 100 }
    }

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

enum PaperClock { static var now: Double { Date().timeIntervalSinceReferenceDate } }
