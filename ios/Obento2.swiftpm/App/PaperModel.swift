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
    /// Every lesson with a spec opens (the Paper proof's two as well, for their screenshots); a test once it's ready.
    @MainActor var opens: Bool { isTest ? Map.testReady(id) : spec != nil && (Map.paperLessons.contains(id) || Map.proof.contains { $0.id == id }) }
    /// A chapter or grade test, not a lesson (G 18 Oct).
    var isTest: Bool { id.hasPrefix("test-") }

    /// Learned (coloured in: a lesson learned at some time, a test passed), up next (the first lesson in its chapter not
    /// learned yet, its test to take again included: lit, with a tab), or not yet.
    @MainActor var state: State {
        if isTest { return Progress.shared.passed(id) ? .learned : opens ? .now : .notYet }
        if Progress.shared.learned.contains(id) { return .learned }
        let next = Map.pieces.first { $0.chapter == chapter && $0.opens && !Progress.shared.learned.contains($0.id) }
        return next?.id == id ? .now : .notYet
    }
    /// Marked Go over on the map (G 20 Oct): a lesson learned at some time that's due back for its recheck (it opens on
    /// it), or whose recheck came back low (it opens on its page, with fresh problems to go over). It stays coloured and
    /// counted; the tab says Go over instead of Up next. A lesson never learned is never Go over.
    @MainActor var goOver: Bool { !isTest && Progress.shared.goOver(id) }

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

/// 5th grade on the paper: the 17 lessons of specs/k12/grade5.md in four chapters, laid out two by two as v27 does.
enum Map {
    static let grade = (number: "5", name: "5th grade")
    static let groups: [ChapterGroup] = [
        ChapterGroup(chapter: .whole, origin: Point(0, 0), columns: 3, lessons: [
            ("g5-mult2", "Multiply two-digit numbers"), ("g5-divide", "Long division"), ("g5-order", "Order of operations")]),
        ChapterGroup(chapter: .decimals, origin: Point(1300, 0), columns: 3, lessons: [
            ("g5-pow10", "Multiply by 10, 100, 1000"), ("g5-round", "Rounding decimals"), ("g5-adddec", "Adding decimals"),
            ("g5-multdec", "Multiplying decimals"), ("g5-divdec", "Dividing by a decimal")]),
        ChapterGroup(chapter: .fractions, origin: Point(0, 900), columns: 3, lessons: [
            ("add", "Adding fractions"), ("sub", "Subtracting fractions"), ("mix", "Adding and subtracting"),
            ("g5-multfrac", "Multiplying fractions"), ("g5-improper", "Mixed numbers to fractions"),
            ("g5-fracof", "Fraction of a number"), ("g5-unitdiv", "Dividing by a unit fraction")]),
        ChapterGroup(chapter: .measurement, origin: Point(1300, 900), columns: 3, lessons: [
            ("g5-volume", "Volume of a box"), ("g5-units", "Converting units")]),
    ]
    static let pieces = groups.flatMap(\.pieces)

    /// The Paper proof's two lessons, off the map since 20 Oct: their teaching lives in Adding fractions and Volume of
    /// a box now. Not drawn, counted or tested; kept (each where it used to sit) so their screenshots still open them,
    /// and as the models the bars and the 3D cubes build from.
    static let proof: [Piece] = [
        Piece(id: "ad", name: "Add with different bottoms", chapter: .fractions, at: Point(0, 1000)),
        Piece(id: "uc", name: "Unit cubes", chapter: .measurement, at: Point(1300, 1000)),
    ]
    /// Any piece by its id: a lesson, a test, or one of the proof's two.
    static func piece(_ id: String) -> Piece? { (all + proof).first { $0.id == id } }

    /// Each chapter's test, in the slot after its last lesson, and the grade's test under everything (G 18 Oct).
    static let tests: [Piece] = groups.map { g in
        let i = g.lessons.count
        return Piece(id: "test-\(g.chapter.rawValue)", name: "\(g.chapter.title) test", chapter: g.chapter,
                     at: Point(g.origin.x + Double(i % g.columns) * ChapterGroup.pitch.width, g.origin.y + Paper.unit + Double(i / g.columns) * ChapterGroup.pitch.height))
    } + [Piece(id: "test-grade", name: "\(grade.name) test", chapter: .whole, at: Point(0, 2100))]
    /// Everything drawn on the map.
    static let all = pieces + tests

    /// A chapter's test opens once every lesson in it has been learned (G 18 Oct); the grade's test once every chapter
    /// test is passed (G 20 Oct). Once taken, or started, a test stays open: it can be taken again. Lessons are always
    /// open; only tests wait.
    @MainActor static func testReady(_ id: String) -> Bool {
        if Progress.shared.tests[id] != nil || PageStore.load(id) != nil { return true }
        if id == "test-grade" { return tests.filter { $0.id != "test-grade" }.allSatisfy { Progress.shared.passed($0.id) } }
        guard let t = tests.first(where: { $0.id == id }) else { return false }
        let lessons = pieces.filter { $0.chapter == t.chapter }
        return !lessons.isEmpty && lessons.allSatisfy { Progress.shared.learned.contains($0.id) }
    }
    /// The lessons a test asks from, in the order it takes them, one question each in turn: a chapter's test its
    /// lessons in map order; the grade's test the chapters in turn, each chapter's lessons in a fresh order, so its 12
    /// questions reach every chapter and, taken again, other lessons.
    @MainActor static func testSpecs(_ t: Piece, using rng: inout SeededRandom) -> [LessonSpec] {
        // the daily review: a lesson for each of its problems, weighted to the weak and the old (Core/Review.swift)
        if t.id == review.id {
            return Review.pick(gradeLessons, checks: Progress.shared.checks, now: Progress.shared.now, using: &rng).compactMap { Lessons.spec($0) }
        }
        guard t.id == "test-grade" else { return pieces.filter { $0.chapter == t.chapter }.compactMap(\.spec) }
        let chapters = groups.map { $0.lessons.compactMap { Lessons.spec($0.id) }.shuffled(using: &rng) }.filter { !$0.isEmpty }
        let rounds = (LessonPlan.test + chapters.count - 1) / max(1, chapters.count)
        return (0..<rounds).flatMap { k in chapters.map { $0[k % $0.count] } }
    }
    /// The daily review's page (G's plan, step 7): a page of problems like a test, where Me is on the paper (it opens from
    /// Me, so it draws in where Me was). Not on the map, not counted, never a lesson.
    static let review = Piece(id: "review", name: "Daily review", chapter: .whole, at: MePage.corner)
    /// The chapter a lesson is in, for a page that mixes them (the review gives each problem its own lesson's colour).
    static func chapter(of id: String) -> Chapter? { pieces.first { $0.id == id }?.chapter }
    /// The lessons that open: every one with a spec (all 17).
    static let paperLessons: Set<String> = Set(pieces.map(\.id).filter { Lessons.spec($0) != nil })

    /// Today's pick, by the web's rules (Core/Mastery.swift): a lesson due back for its recheck first, then what to go
    /// over, then what builds on the lesson just learned, then the first one ready. Only lessons that open are picked.
    @MainActor static var today: Piece? {
        let open = pieces.filter(\.opens)
        let pick = Mastery.upNext(open.map(\.id), depends: { Lessons.spec($0)?.depends ?? [] },
                                  checks: Progress.shared.checks, grade: 5, now: Progress.shared.now)
        return open.first { $0.id == pick?.id }
    }
    /// The grade's lessons (the specs' 17), for "5 of 17 learned": the same lessons the chapters count.
    static let gradeLessons = pieces.map(\.id)
    /// Every group, from its title to its last row's name and Start, with a cell to spare: what the overview shows.
    /// Worked out from the layout, so it stays right when groups move.
    static let bounds: Rect = {
        let x0 = groups.map(\.origin.x).min()!, y0 = groups.map(\.origin.y).min()!
        let x1 = all.map { $0.at.x + Piece.size.width }.max()!, y1 = all.map { $0.at.y + Piece.size.height + Paper.unit }.max()!
        let m = Paper.cell
        return Rect(x: x0 - m, y: y0 - m, width: x1 - x0 + 2 * m, height: y1 - y0 + 2 * m)
    }()
}

/// A page of its own on the paper instead of the map (G 20 Oct): Me (the child's own page, MePage) or the grown-ups'
/// page (GrownUpPage). Each has its place on the sheet, left of the map.
enum Place: Equatable { case me, grownUp }

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
            // a place is framed to read on the screen it's on (Me shows as many cards as fit it): framed again, at once
            if let place, bars == nil, lesson == nil { resting = placeCamera(place) }
        }
    }
    private(set) var resting = PaperCamera()
    private(set) var flight: CameraFlight?
    var selected: Piece?
    var lesson: UnitCubesModel?
    /// The flat lesson, when one is open. It uses the paper's own camera.
    var bars: BarsPage?
    /// A page of its own on the paper instead of the map: Me, or the grown-ups' page (nil on the map and in a lesson).
    private(set) var place: Place?
    /// When the place started drawing in, and when it started erasing itself on the way somewhere else.
    private(set) var placeAt: Double = -100
    private(set) var placeLeftAt: Double?
    /// The place a lesson's page (or the daily review) was opened from: closing it comes back there, and the bar's back
    /// button says so.
    private(set) var cameFrom: Place?
    /// A long shelf on Me opened to all its cards (from its "and 6 more"), nil for the whole of Me. It stays open while a
    /// lesson opened from it is open, so closing the lesson comes back to it; Back to Me, the bar's Me, or going
    /// anywhere else puts it back.
    private(set) var meShelf: Int?
    /// How many cards a shelf on Me shows on this screen, so all of Me is in view (MePage.rows).
    var meRows: Int { MePage.rows(screenHeight: screen.height, pad: screen.width > 760 ? Self.margin : 8) }
    /// Me as it stands, on this screen.
    func meSheet(now: Double) -> MePage.Sheet { MePage.sheet(now: now, rows: meRows, open: meShelf) }
    /// A shelf on Me opened (nil: the whole of Me again): Me draws itself as it now is, and the camera frames it.
    func openShelf(_ k: Int?) {
        guard place == .me, meShelf != k else { return }
        meShelf = k
        reframePlace()
    }
    /// The place's words are still drawing in or undrawing: the clock keeps running.
    private(set) var placeDrawing = false
    func setPlaceDrawing(_ b: Bool) { if placeDrawing != b { placeDrawing = b } }
    /// The grown-ups' page: shut behind its hold until a grown-up opens it, and what it's asking to confirm.
    let grownUp = GrownUpPage()
    /// The very first launch's ghost tap on the first lesson up next (StartHere), from when it starts until another
    /// lesson is chosen, or one opens.
    private(set) var startHere: StartHere?

    /// The very first launch (G 20 Oct): once the map has drawn in, a ghost finger taps the first lesson up next and
    /// "Start here." is written beside it. Only for a child with nothing done yet; remembered at once (never in a
    /// screenshot), so it never plays again. `frozen`: screenshots, held at that moment of it.
    func beginStartHere(force: Bool = false, frozen: Double? = nil) {
        let fresh = !StartHere.shown && Progress.shared.checks.isEmpty && !UserDefaults.standard.dictionaryRepresentation().keys.contains { $0.hasPrefix("lesson-") }
        guard force || fresh, let p = Map.today ?? Map.pieces.first(where: { $0.state == .now }) else { return }
        startHere = StartHere(piece: p, start: drawnAt + Piece.drawTime + 0.2, frozen: frozen)
        if !Shots.active { UserDefaults.standard.set(true, forKey: StartHere.key) }
        // Reduce Motion (no finger moving, nothing to wait for), or a screenshot held past the tap: chosen at once
        if instant || (frozen ?? -1) >= StartHere.tapTime { startHere?.tapped = true; select(p) }
    }
    /// The piece whose lesson is open: its name goes in the top bar.
    var openPiece: Piece? { lesson != nil || bars != nil ? opened : nil }
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
    /// Reduce Motion (LESSONS.md §4): cut straight to every state instead of gliding or drawing in. A child with it on
    /// still has their work saved and brought back, and still sees the How to.
    private(set) var reduceMotion = false
    /// A screenshot (Shots): every moment finished at once, the How to skipped, nothing saved.
    var shotMode = false
    /// Everything cuts: Reduce Motion, or a screenshot. Screenshots set it (it's `shotMode`).
    var instant: Bool {
        get { reduceMotion || shotMode }
        set { shotMode = newValue }
    }
    /// A fixed box, for screenshots.
    var shotBox: UnitCubes.Box?
    var shotProblem: AddFractions.Problem?
    var shotNumbers: Numbers?

    func camera(at t: Double) -> PaperCamera { flight?.camera(at: t, screen: screen) ?? resting }
    /// The one camera the paper's scene is seen through: the open 3D lesson's (Unit cubes), a problem's on a lesson's
    /// page while it stands tilted (Volume of a box, TiltCamera), or the flat paper's from straight above. Only reads.
    func view(at t: Double) -> PaperView3D { lesson?.view(at: t) ?? TiltCamera.view(at: t, flat: .matching(camera(at: t), screen: screen)) }

    /// Where a point on the screen lands on the paper: through the tilted problem's view while the paper stands tilted
    /// (a tap on one of its blocks or on its box; the paper under a dragging finger), else through the flat camera.
    private func paperPoint(_ s: Point, tap: Bool = false) -> Point {
        (lesson == nil ? TiltCamera.paperPoint(s, tap: tap) : nil) ?? camera(at: PaperClock.now).toPaper(s)
    }
    var moving: Bool { flight != nil }

    func settle(at t: Double) {
        if let f = flight, f.done(at: t) { resting = f.to; flight = nil }
        // the first launch's finger presses the lesson: it's chosen, as a tap chooses it
        if let sh = startHere, sh.tapDue(at: t), place == nil, bars == nil, lesson == nil { startHere?.tapped = true; select(sh.piece) }
        // the grown-ups' square held for 3 seconds: its page opens, and the camera frames it
        if place == .grownUp, grownUp.settle(at: t) {
            Sounds.shared.play(.done)
            fly(to: placeCamera(.grownUp), duration: CameraTiming.fly)
        }
        // the tilted problem's camera, between frames (TiltCamera.settle): what a tilt starts from and fits into (the
        // room the bar or the keyboard takes), and a problem no longer on the page lying flat again
        if lesson == nil {
            TiltCamera.settle(at: t, flat: .matching(camera(at: t), screen: screen), screen: screen, top: Self.chrome.top,
                              bottom: max(Self.chrome.bottom, keyboard + 16)) { [bars] o in bars?.all.contains { $0 === o } ?? false }
        }
    }

    func fly(to cam: PaperCamera, duration: Double) {
        let now = PaperClock.now
        let from = camera(at: now)
        flight = instant ? nil : CameraFlight(from: from, to: cam, start: now, duration: duration)
        if instant { resting = cam } else { resting = from }
    }

    func stop() { let c = camera(at: PaperClock.now); flight = nil; resting = c }

    func pan(_ dx: Double, _ dy: Double) {
        // tilted, a drag turns the tilted view, not the flat paper under it
        if lesson == nil, TiltCamera.pan(dx, dy) { return }
        stop(); resting = resting.panned(by: dx, dy)
    }

    /// A drag that starts on something the open problem lets the child move goes to the problem (a hand move, G 20
    /// Oct); any other drag pans the paper. Only the problem being worked takes hands (not the How to, not the page).
    private(set) var handDrag = false
    /// A finger is down on the paper (from the moment it touches, before it's a tap, a drag or a hold).
    private var pressing = false
    /// A finger down at screen point `s`, or moving: on the grown-ups' gate, a hold on its square starts, and lets go
    /// when the finger leaves it.
    func press(at s: Point) {
        let p = camera(at: PaperClock.now).toPaper(s), now = PaperClock.now
        if !pressing {
            pressing = true
            if place == .grownUp, !leaving { grownUp.press(p, at: now) }
            return
        }
        if grownUp.holding { grownUp.moved(p, at: now) }
    }
    /// The finger lifted: a hold let go too soon empties its ring.
    func pressEnded() {
        pressing = false
        if grownUp.holding { grownUp.letGo(at: PaperClock.now) }
    }

    /// The camera was on its way to frame the step when the hand took hold (it held still under the finger).
    private var framingHeld = false
    func dragStart(at s: Point) {
        // a finger holding the grown-ups' square keeps the paper still
        if place == .grownUp, grownUp.holding { handDrag = true; return }
        guard !leaving, let b = bars, b.mode == .work, let m = b.current else { handDrag = false; return }
        handDrag = m.grab(paperPoint(s))
        // the camera holds still under the finger while it drags
        if handDrag { framingHeld = moving; stop() }
    }
    func dragMove(to s: Point) { guard handDrag else { return }; bars?.current?.drag(to: paperPoint(s)) }
    func dragEnd() {
        guard handDrag else { return }
        bars?.current?.release()
        handDrag = false
        // let go: a framing the hand stopped partway finishes (a new step frames itself, Rig.frameContent; a camera the
        // child pinched or panned stays where they left it, LESSONS.md §5)
        if framingHeld, let w = bars?.current as? WorkProblem, let r = w.stageFrame { frameCurrent(r) }
        framingHeld = false
    }
    func zoom(by f: Double, at p: Point) {
        if lesson == nil, TiltCamera.pinch(f) { pinchedAt = PaperClock.now; return }
        stop(); resting = resting.zoomed(by: f, at: p); pinchedAt = PaperClock.now
    }
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

    /// The overview button (Lessons): the whole lesson page when one is open, else the whole map.
    func frameAll() {
        if let b = bars { fly(to: framingBelowBar(b.pageFrame, maxZoom: CameraTiming.lessonMax), duration: CameraTiming.fly) }
        else { fly(to: overview, duration: CameraTiming.fly) }
    }

    /// The map as it opens (G 20 Oct): today's chapter, at 100% so its names and lines read at 20 on the screen (the whole
    /// map is the Lessons button's, its words too small to read). The other chapters are a pan or a pinch away.
    func frameGroup(duration: Double = CameraTiming.fly) {
        guard let today = Map.today ?? Map.pieces.first(where: { $0.state == .now }),
              let i = Map.groups.firstIndex(where: { $0.chapter == today.chapter }) else { fly(to: overview, duration: duration); return }
        fly(to: chapterView(i, showing: today), duration: duration)
    }

    /// The crosshair: glide to the lesson that's up next.
    func findNext() { if let p = Map.today { select(p) } }

    /// A glide to chapter `i`: its title, every lesson in it and its test, read at 100%.
    func frameChapter(_ i: Int) {
        guard Map.groups.indices.contains(i) else { return }
        fly(to: chapterView(i), duration: CameraTiming.glide)
    }
    /// Chapter `i` framed to read, as a page is read: its title at the top, its lessons and test across the screen at up
    /// to 100% (a little less where its three columns are wider than the screen, as in portrait, so no lesson is cut off
    /// at the sides), the next chapter coming in under it. A chapter too tall for the room above the bar shows from its
    /// title down, or, when `piece` is further down, down to it; the rest is a scroll away.
    func chapterView(_ i: Int, showing piece: Piece? = nil) -> PaperCamera {
        let g = Map.groups[i], all = g.pieces + Map.tests.filter { $0.chapter == g.chapter && $0.id != "test-grade" }
        let r = all.map { Rect(x: $0.at.x, y: $0.at.y, width: Piece.size.width, height: Piece.size.height + Paper.unit) }
            .reduce(Rect(x: g.origin.x, y: g.origin.y, width: 1, height: 1)) { $0.union($1) }
        let pad = screen.width > 760 ? Self.margin : 8
        let top = Self.chrome.top + pad, bottom = screen.height - max(Self.chrome.bottom, keyboard + 16) - pad
        let z = min(CameraTiming.selectMax, (screen.width - 2 * pad) / r.width), x = screen.width / 2 - r.mid.x * z
        var y0 = r.y
        if let p = piece, (p.focus.y + p.focus.height - y0) * z > bottom - top { y0 = p.focus.y + p.focus.height - (bottom - top) / z }
        return PaperCamera(x: x, y: top - y0 * z, zoom: z)
    }

    /// A tap on a lesson: a slow, gentle glide that brings it closer, not too close.
    func select(_ p: Piece?) {
        // another lesson chosen: the first launch's "Start here." goes
        if p?.id != startHere?.piece.id { startHere = nil }
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
        let p = paperPoint(s, tap: true)
        if let b = bars {
            b.tap(p); return
        }
        if let place { tapPlace(place, at: p); return }
        // the chosen lesson opens from its tag (a little extra all round, for a finger) or a second tap on its frame
        if let sel = selected, sel.opens, contains(Rect(x: sel.start.x - 20, y: sel.start.y - 20, width: sel.start.width + 40, height: sel.start.height + 40), p) || contains(sel.frame, p) {
            open(sel); return
        }
        select(Map.all.first(where: { contains($0.frame, p) || contains($0.start, p) }))
    }

    /// Opening a lesson: the map erases itself, as it drew in, then the lesson opens where it was.
    func open(_ p: Piece) {
        guard !leaving else { return }
        startHere = nil
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
        if p.isTest || p.id == Map.review.id { openBars(p); return }
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

    /// Opening the flat lesson: its page (BarsPage). The How to plays where the lesson is, on the paper's own camera,
    /// then its problems' cards draw in. A lesson learned at some time that's due back opens on its recheck (G 20 Oct;
    /// one that came back low, the next day); a chapter or grade test finished before starts afresh. A screenshot's
    /// page has the same numbers every time it's taken.
    func openBars(_ p: Piece) {
        // another page was open: its tasks end now
        bars?.stop()
        let first = (p.id == "ad" ? shotProblem?.numbers : shotNumbers) ?? prepared.flatMap { $0.id == p.id ? $0.numbers : nil }
        // a screenshot's page is one it set up itself, or fresh
        var saved = shotMode ? PageStore.cached(p.id) : PageStore.load(p.id)
        if p.isTest, saved?.recorded == true { saved = nil }
        // the daily review is the day's own: one left from another day starts afresh
        let review = p.id == Map.review.id
        if review, let s = saved, Review.day(s.date.timeIntervalSinceReferenceDate) != Review.day(PaperClock.now) { saved = nil; PageStore.clear(p.id) }
        let b = BarsPage(piece: p, reduceMotion: reduceMotion, shotMode: shotMode, first: first, saved: saved,
                         test: p.isTest ? LessonPlan.test : review ? Review.problems : nil, recheck: !p.isTest && !review && Progress.shared.dueBack(p.id),
                         seed: Shots.seed(p.id))
        b.frame = { [weak self] r in self?.frameCurrent(r) }
        b.close = { [weak self] in self?.close() }
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
        // the page's own tasks (the How to waiting for a tap, a problem's next step) end now, and its work is saved
        bars?.stop()
        // a lesson's page erases itself first, as it drew in, then the map draws itself back in
        if let b = bars, !instant {
            leaving = true
            b.leave()
            Task { [self] in
                try? await Task.sleep(for: .seconds(Self.undraw + 0.05))
                leaving = false
                bars = nil; back(from: piece)
            }
            return
        }
        if bars != nil { bars = nil; back(from: piece); return }
        guard let l = lesson else { return }
        l.flatten { [self] view in
            stop(); resting = view.paperCamera(screen: screen); lesson = nil
            redraw(from: piece)
            glideOut(to: piece)
        }
    }

    /// Out of a lesson's page: back to the place it was opened from (Me), else to the map, gliding out to the lesson.
    private func back(from piece: Piece?) {
        if let from = cameFrom { cameFrom = nil; arrive(at: from); return }
        redraw(from: piece); glideOut(to: piece)
    }

    // MARK: places (Me, the grown-ups' page)

    /// Goes to a place on the paper, or back to the map (nil): what's on the paper now erases itself first, as it drew
    /// in (G 17 Oct), then the camera flies there and it draws itself in. Already there, the map shows all of itself (the
    /// Lessons button, as before) and a place frames itself again. `then` runs once it's there.
    func go(to target: Place?, then: (() -> Void)? = nil) {
        guard !leaving, lesson == nil else { return }
        startHere = nil
        if bars == nil, place == target {
            // the bar's Me on Me, with a shelf open: back to the whole of Me
            if target == .me { meShelf = nil }
            if let target { fly(to: placeCamera(target), duration: CameraTiming.fly) } else { frameAll() }
            then?(); return
        }
        erase { [self] in arrive(at: target); then?() }
    }

    /// A lesson (or the daily review) chosen on a place: the place erases itself, and the lesson's page opens where the
    /// lesson lives; closing it comes back to the place.
    func open(_ p: Piece, from origin: Place) {
        guard !leaving, lesson == nil else { return }
        erase { [self] in
            place = nil; placeLeftAt = nil; cameFrom = origin
            openNow(p)
        }
    }

    /// What's on the paper erases itself, as it drew in: the map, a place, or a lesson's page (stopped first, so its work
    /// is saved); then `next`. Hands off until the next thing is there.
    private func erase(_ next: @escaping () -> Void) {
        bars?.stop()
        if instant { bars = nil; cameFrom = nil; next(); return }
        leaving = true
        let now = PaperClock.now
        if let b = bars { b.leave() } else if place != nil { placeLeftAt = now } else { mapLeftAt = now }
        Task { [self] in
            try? await Task.sleep(for: .seconds(Self.undraw + 0.05))
            leaving = false
            bars = nil; cameFrom = nil
            next()
        }
    }

    /// Arrived: a place draws itself in as the camera flies to it; the map (nil) draws itself back in, framed on today's
    /// chapter as when the app opens.
    private func arrive(at target: Place?) {
        place = target; placeLeftAt = nil; mapLeftAt = nil; selected = nil
        // an open shelf is kept only for coming back to Me from a lesson opened on it
        if target != .me { meShelf = nil }
        guard let target else { redraw(from: nil); frameGroup(); return }
        placeAt = instant ? PaperClock.now - 100 : PaperClock.now + 0.05
        if target == .grownUp { grownUp.shut() }
        fly(to: placeCamera(target), duration: CameraTiming.fly)
    }

    /// The place frames itself again (it grew or shrank: a question asked on the paper, or put away).
    func reframePlace() {
        guard let place, bars == nil, !leaving else { return }
        let to = placeCamera(place), now = camera(at: PaperClock.now)
        if abs(to.zoom / now.zoom - 1) < 0.02, abs(to.x - now.x) < 12, abs(to.y - now.y) < 12 { return }
        fly(to: to, duration: CameraTiming.fly)
    }

    /// A tap on a place: the card it lands on opens (Me), or the grown-ups' page takes it.
    private func tapPlace(_ place: Place, at p: Point) {
        switch place {
        case .me:
            let q = CGPoint(x: p.x, y: p.y)
            switch meSheet(now: PaperClock.now).taps.first(where: { $0.rect.contains(q) })?.action {
            case .lesson(let id)?: if let piece = Map.piece(id) { open(piece, from: .me) }
            case .review?: open(Map.review, from: .me)
            case .shelf(let k)?: openShelf(k)
            case .back?: openShelf(nil)
            case nil: break
            }
        case .grownUp: grownUp.tap(p, model: self)
        }
    }

    /// A place framed to read (G 20 Oct): all of it at up to 100%, centred clear of the bar. Me always fits (its shelves
    /// show as many cards as fit at 75%, the rest a tap away: MePage.rows); the grown-ups' page, too tall for that at 75%
    /// (its words still big enough to read), shows from its top down at 75%, the rest a pan away.
    func placeCamera(_ place: Place) -> PaperCamera {
        if place == .me { return framingBelowBar(meSheet(now: PaperClock.now).frame, maxZoom: CameraTiming.selectMax) }
        let r = grownUp.frame
        let cam = framingBelowBar(r, maxZoom: CameraTiming.selectMax)
        guard cam.zoom < 0.75 else { return cam }
        let z = 0.75, pad = screen.width > 760 ? Self.margin : 8
        return PaperCamera(x: screen.width / 2 - r.mid.x * z, y: Self.chrome.top + pad - r.y * z, zoom: z)
    }

    /// Screenshots only: today's review partway, this many done.
    static var shotPartway: Int?
    /// Today's review, started and not finished: how many of its problems are done (nil when none is partway).
    static func reviewPartway(now: Double) -> Int? {
        if let n = shotPartway { return n }
        guard let s = PageStore.load(Map.review.id), !s.recorded, Review.day(s.date.timeIntervalSinceReferenceDate) == Review.day(now) else { return nil }
        let done = s.problems.filter(\.finished).count
        return done > 0 ? done : nil
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

    /// Reduce Motion (LESSONS.md §4): cut straight to every state, with no glide, tilt or draw-in. Screenshots keep it
    /// off, unless the moment asks for it (`-reduce-motion`).
    func setReduceMotion(_ on: Bool) {
        let on = Shots.active ? Shots.reduceMotion : on
        reduceMotion = on
        if on { drawnAt = PaperClock.now - 100 }
    }

    private func contains(_ r: Rect, _ p: Point) -> Bool { p.x >= r.x && p.y >= r.y && p.x <= r.x + r.width && p.y <= r.y + r.height }
}

enum PaperClock {
    static var now: Double { frozen ?? Date().timeIntervalSinceReferenceDate }
    /// Screenshots only (`-freeze`): the paper held still at this moment, so a slow screenshot still catches it.
    static var frozen: Double?
}
