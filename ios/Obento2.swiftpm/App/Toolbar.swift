import SwiftUI
import AVFoundation

/// The one floating bar at the bottom (G 17 Oct), as the calm smart pill G chose on 26 Oct
/// (`design/prototype/front-door.html`, section 2, "Calm (fewer words)"): icons for buttons, small squares for progress,
/// and words only for the one thing most worth doing right now, in its middle. It's fixed to the screen, never to the
/// paper, so it can't jiggle as the paper moves.
/// - On the map (and Me, and the grown-ups' page): Lessons · Me | what to do now ("Continue →", "Go over · 2", or the
///   grade, which opens the grades) | ⋯.
/// - In a lesson: ← back | one square per step of the problem (the page's squares on the page) | Hint · Show me | ⋯.
///   After a miss Show me has its word, ringed in the chapter's colour; solved, the middle is "Next →" and Hint and
///   Show me fold away; tests have neither. While a hand move is under way its live readout is said big in the middle,
///   the rest dimmed.
/// - While the paper is pinched, the middle shows the zoom at 22 pt (the size G likes).
/// - ⋯ More and the grades grow up out of the pill itself (no pop-up over the paper).
/// - Icons only, no words under them (G 26 Oct: "it looks bad with the words"); a long press on an icon shows its word.
/// What it shows is decided in Core (`Pill`); this draws it.
struct Toolbar: View {
    let model: PaperModel
    let time: Double
    let bottom: CGFloat
    @Environment(\.colorScheme) private var scheme
    @AppStorage("theme") private var theme = ""
    private var ui: BarUI { BarUI.shared }

    var body: some View {
        let inLesson = model.openPiece != nil
        ZStack(alignment: .bottom) {
            // the island's tabs (the grown-ups' settings, privacy, help, plan) quiet the paper behind them; a tap on the
            // paper shrinks the island back into the pill
            if ui.open == .grownUps {
                Ink.paper.opacity(0.55).ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { ui.open = nil }
                    .transition(.opacity)
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                pill(inLesson)
            }
            .padding(.bottom, bottom)
            .frame(maxWidth: .infinity)
        }
        .animation(ui.slow ? .smooth(duration: 3) : Motion.close, value: ui.open == .grownUps)
        .onChange(of: inLesson) { _, _ in ui.open = nil }
        // leaving the grown-ups' page shuts its island (the island's hold takes the paper there, so arriving keeps it)
        .onChange(of: model.place) { _, place in
            if place != .grownUp, ui.open == .grownUps { ui.open = nil }
        }
    }

    // MARK: the pill

    /// The pill: what's open grows up out of it, above its row, inside the same shape, like a drawer (G 26 Oct): the
    /// pill's size is set outright from what's in it (the row's width; the panel's measured size), so width and height
    /// move together in one spring, and the panel's words sit at the top of a frame that grows from nothing behind the row
    /// (they rise with the pill's top edge, and sink back behind the row as it shuts). Nothing draws outside its shape.
    private func pill(_ inLesson: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 32, style: .continuous)
        let panel = ui.open ?? ui.closing, isOpen = ui.open != nil
        let size = panel.flatMap { ui.sizes[$0] } ?? .zero
        let rowW = ui.rowWidth
        // open: as wide as the panel or the row, whichever is wider; its height the panel, a gap, its line, a gap
        let w = isOpen ? max(rowW, size.width) : rowW
        let h = isOpen && size.height > 0 ? size.height + 13 : 0
        let drawer = ZStack(alignment: .top) {
            if let panel {
                panelView(panel, inLesson)
                    .fixedSize()
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { s in
                        if abs((ui.sizes[panel]?.width ?? 0) - s.width) > 0.5 || abs((ui.sizes[panel]?.height ?? 0) - s.height) > 0.5 { ui.sizes[panel] = s }
                    }
                    .id(panel)
                    // one panel to the next (the hold to the tabs): the old goes at once, the new comes just after, so
                    // the two never show over each other
                    .transition(.asymmetric(insertion: .opacity.animation(ui.slow ? .smooth(duration: 1.5).delay(0.8) : Motion.snap.delay(0.08)),
                                            removal: .opacity.animation(ui.slow ? .smooth(duration: 0.8) : .spring(duration: 0.1))))
            }
            // the line between the panel and the row, at the panel's foot
            Rectangle().fill(Ink.line).frame(width: max(0, w - 20), height: 1)
                .padding(.top, size.height + 6)
                .opacity(panel == nil ? 0 : 1)
        }
        // the row stays in front; its backing as wide as the pill, so nothing sliding shows beside it
        let front = row(inLesson).fixedSize()
            .onGeometryChange(for: Double.self) { $0.size.width } action: { if abs(ui.rowWidth - $0) > 0.5 { ui.rowWidth = $0 } }
        return PillBody(width: rowW > 0 ? w : -1, height: h, drawer: drawer, row: front)
        // the same gap all round, so a lit button sits evenly inside the bar's curve
        .padding(6)
        // nothing in it draws outside the pill's shape, even while it grows or shrinks
        .clipShape(shape)
        // the shadow belongs to the pill's shape only: on the whole pill, SwiftUI shadowed every button and word in it
        .background(shape.fill(Ink.surface).shadow(color: .black.opacity(ui.open == .grownUps ? 0.14 : 0.08), radius: ui.open == .grownUps ? 20 : 12, y: 6))
        // the island's tabs, each measured unseen ahead, so they're all one height and a switch never resizes it
        .background { if !inLesson, ui.open != nil, ui.open != .grade { IslandMeasure(model: model, width: islandWidth, key: islandKey) } }
        .overlay(shape.strokeBorder(Ink.line, lineWidth: 1))
        // one spring for its width and height together, never a jump under the finger
        // opening: a soft landing with a touch of give; closing or settling: no give, so it never shrinks past its row
        .animation(ui.slow ? .smooth(duration: 3.5) : ui.open == nil ? Motion.close : Motion.open, value: animationKey(inLesson))
    }

    /// What grows out of the pill.
    @ViewBuilder private func panelView(_ p: BarUI.Panel, _ inLesson: Bool) -> some View {
        switch p {
        case .more: if inLesson { lessonMenu } else { mapMenu }
        case .grade: gradeRow
        case .gate: IslandGate { grownUpsOpened() }
        case .grownUps: IslandTabs(model: model, room: islandRoom, width: islandWidth)
        }
    }

    /// Everything that changes the pill's shape: a change in any of it is animated.
    private func animationKey(_ inLesson: Bool) -> String {
        let t = tools
        return "\(inLesson) \(model.place.map { "\($0)" } ?? "map") \(String(describing: ui.open)) \(Int(ui.rowWidth)) \(ui.sizes.map { "\($0.key)\(Int($0.value.width))x\(Int($0.value.height))" }.sorted()) \(zooming) \(middleKey) \(t.hint) \(t.showMe) \(t.showMeWord) \(t.next) \(t.dim) \(ui.gradeSaid ?? "") \(islandKey) \(heightsKey) \(Int(islandRoom))"
    }

    // MARK: the island

    /// The island's width, and the most room its tab's words have: the screen above the pill, less its row, its tabs
    /// and a margin at the top.
    private var islandWidth: Double { Island.width(screen: model.screen.width) }
    private var islandRoom: Double { max(160, model.screen.height - bottom - 40 - 52 - 12 - 6 - 1 - 50 - 1) }
    /// What can change the island's tab's height (it's measured again, and the island eases to it).
    private var islandKey: String { "\(ui.askStartOver) \(ui.settingsVersion) \(ui.said.count) \(ui.islandGrade ?? "")" }
    private var heightsKey: String { Island.Tab.allCases.map { "\(Int(ui.heights[$0] ?? 0))" }.joined(separator: ",") }

    /// The hold passed in the island: the paper glides to the grown-ups' page (open, no hold on the paper) and the
    /// island grows into its tabs.
    private func grownUpsOpened() {
        Sounds.shared.play(.done)
        ui.tab = .settings; ui.askStartOver = false; ui.said = [:]; ui.islandGrade = nil
        ui.open = .grownUps
        if model.place == .grownUp { model.grownUp.openNow(); model.reframePlace() }
        else { model.grownUp.pass = true; model.go(to: .grownUp) }
    }

    @ViewBuilder private func row(_ inLesson: Bool) -> some View {
        HStack(spacing: 2) {
            if inLesson { lessonRow } else { mapRow }
        }
    }

    // MARK: on the map

    @ViewBuilder private var mapRow: some View {
        // the map (already on it, all of it), and Me: each a place on the paper, the one you're at lit
        PillButton(icon: .lessons, word: "Lessons", lit: model.place == nil) { ui.open = nil; model.go(to: nil) }
        PillButton(icon: .me, word: "Me", lit: model.place == .me) { ui.open = nil; model.go(to: .me) }
        divider
        mapMiddle
        divider
        moreButton
    }

    /// The map's middle: the zoom while pinched, else the one thing to do now, else the grade.
    @ViewBuilder private var mapMiddle: some View {
        if zooming { zoomReadout } else {
            let offer = self.offer
            switch offer {
            case .grade:
                MiddleWords(text: gradeName, lit: ui.open == .grade, tint: nil,
                            accessibility: gradeName + (Fresh.showsCount(learned: learned) ? ", \(learned) of \(Map.gradeLessons.count) passed" : "")) {
                    toggle(.grade)
                }
            default:
                MiddleWords(text: offer.words(grade: gradeName), lit: true, tint: nil, accessibility: offerAccessibility(offer)) {
                    ui.open = nil; take(offer)
                }
            }
        }
    }

    // MARK: in a lesson

    @ViewBuilder private var lessonRow: some View {
        let t = tools, dim = t.dim
        if let b = model.bars, b.mode == .work {
            PillButton(icon: .back, word: "Problems", dim: dim) { ui.open = nil; b.backToProblems() }
        } else {
            PillButton(icon: .back, word: model.cameFrom == .me ? "Me" : "Lessons", dim: dim) { ui.open = nil; model.close() }
        }
        divider.opacity(dim ? 0.35 : 1)
        lessonMiddle(t)
        if t.hint || t.showMe {
            divider.opacity(dim ? 0.35 : 1)
            // the hint is drawn on the paper (G 20 Oct): no card opens for it. Dim when there's none to give, but still
            // there to tap: the paper then says why ("Have a go first. A hint comes after a miss.")
            if t.hint {
                PillButton(icon: .hint, word: "Hint", count: hintCount, dim: dim || !canHint) { ui.open = nil; model.bars?.hint() }
            }
            if t.showMe {
                // after a miss: the one thing most worth tapping, with its word, ringed in the chapter's colour
                PillButton(icon: .show, word: "Show me", ring: t.showMeWord ? chapterInk : nil, enabled: canShowMe, dim: dim) {
                    ui.open = nil; showMe()
                }
            }
        }
        divider.opacity(dim ? 0.35 : 1)
        moreButton.opacity(dim ? 0.35 : 1)
    }

    /// The lesson's middle: the zoom while pinched; a hand move's readout while the finger is down; the problem's
    /// squares (and "Next →" once it's solved); on the page, the page's squares.
    @ViewBuilder private func lessonMiddle(_ t: Pill.Tools) -> some View {
        if zooming { zoomReadout }
        else if t.dim, let r = readout {
            Text(r).font(Typeface.font(22, .bold)).monospacedDigit().foregroundStyle(chapterInk)
                .contentTransition(.numericText())
                .lineLimit(1).padding(.horizontal, 18).frame(minWidth: 150, minHeight: 52)
                .accessibilityLabel(r)
        } else {
            let s = squares
            HStack(spacing: 0) {
                if s.of > 0 {
                    StepSquares(done: s.done, of: s.of, ink: chapterInk)
                        .padding(.horizontal, 16).frame(minHeight: 52)
                        // VoiceOver (and the real-touch tests) read where this is and how far along
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(model.bars?.title ?? model.openPiece?.name ?? "")
                        .accessibilityValue(squaresWords(s))
                        .accessibilityAddTraits(.isStaticText)
                } else {
                    Color.clear.frame(width: 24, height: 52)
                        .accessibilityElement().accessibilityLabel(model.bars?.title ?? model.openPiece?.name ?? "").accessibilityAddTraits(.isStaticText)
                }
                if t.next {
                    MiddleWords(text: "Next →", lit: true, tint: chapterInk, accessibility: "Next problem") { ui.open = nil; model.bars?.goNext() }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .opacity(t.dim ? 0.35 : 1)
        }
    }

    // MARK: shared pieces

    private var divider: some View { Rectangle().fill(Ink.line).frame(width: 1, height: 32).padding(.horizontal, 4) }

    /// ⋯ More, or × while something's grown out of the pill (the menu, the hold, the grown-ups' tabs): it shrinks back.
    private var moreButton: some View {
        let island = ui.open == .gate || ui.open == .grownUps
        return PillButton(icon: ui.open == .more || island ? .close : .more, word: ui.open == .more || island ? "Close" : "More", lit: ui.open == .more || island) {
            if island { ui.open = nil } else { toggle(.more) }
        }
    }

    /// The zoom, for a moment after a pinch, at 22 pt (G 17 Oct).
    private var zoomReadout: some View {
        Text("\(Int((zoom * 100).rounded()))%").font(Typeface.font(22, .semibold)).monospacedDigit().foregroundStyle(Ink.ink)
            .padding(.horizontal, 18).frame(minWidth: 120, minHeight: 52)
    }

    private var zooming: Bool { time - model.pinchedAt < 1.2 }

    /// What the middle is showing, for the animation's key (the readout's words too, so the pill eases as they change).
    private var middleKey: String {
        if zooming { return "zoom" }
        if model.openPiece == nil { return offer.words(grade: gradeName) }
        if tools.dim, let r = readout { return "readout \(r)" }
        let s = squares
        return "squares \(s.done) \(s.of)"
    }

    // MARK: what grows out of the pill

    private var mapMenu: some View {
        VStack(spacing: 0) {
            zoomRow
            MenuRow(icon: .find, label: "Up next") {
                ui.open = nil
                // from a place, back to the map first
                if model.place == nil { model.findNext() } else { model.go(to: nil) { model.findNext() } }
            }
            MenuRow(icon: .dark, label: scheme == .dark ? "Light" : "Dark") { theme = scheme == .dark ? "light" : "dark" }
            // the grown-ups' page, shut behind its hold (in the island); on the open page, straight to the island's tabs
            MenuRow(icon: .lock, label: "For grown-ups") {
                if model.place == .grownUp, model.grownUp.open { ui.tab = .settings; ui.askStartOver = false; ui.said = [:]; ui.open = .grownUps }
                else { ui.open = .gate }
            }
        }
        .frame(width: 300)
    }

    private var lessonMenu: some View {
        VStack(spacing: 0) {
            if hasTools {
                MenuRow(icon: .restart, label: "Start over", enabled: canReset) { ui.open = nil; reset() }
            }
            // off in tests (G 20 Oct)
            MenuRow(icon: .read, label: "Read aloud", enabled: canRead) { ui.open = nil; readAloud() }
            if let b = model.bars, b.howToGone, !b.inTest { MenuRow(icon: .show, label: "Watch the How to") { ui.open = nil; b.watchAgain() } }
            MenuRow(icon: .dark, label: scheme == .dark ? "Light" : "Dark") { theme = scheme == .dark ? "light" : "dark" }
            zoomRow
        }
        .frame(width: 300)
    }

    /// The grades, K to 12, as blocks: 5th live, the others dead for now (no maps for them yet). A dead one only says
    /// it's coming.
    private var gradeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(Grades.all, id: \.self) { g in
                    GradeBlock(grade: g) {
                        if Grades.isLive(g) { ui.open = nil; ui.gradeSaid = nil } else { ui.gradeSaid = Grades.picked(g) }
                    }
                }
            }
            Text(ui.gradeSaid ?? "Other grades are coming soon.").font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink2)
                .contentTransition(.opacity).padding(.horizontal, 4)
        }
        // clear of the pill's round corners
        .padding(.horizontal, 16).padding(.top, 12)
    }

    private var zoomRow: some View {
        HStack {
            Text("Zoom").font(Typeface.font(18)).foregroundStyle(Ink.ink)
            Spacer()
            SmallButton(text: "−") { zoomBy(1 / 1.25) }
            Text("\(Int((zoom * 100).rounded()))%").font(Typeface.font(16)).monospacedDigit().foregroundStyle(Ink.ink2).frame(width: 56)
            SmallButton(text: "+") { zoomBy(1.25) }
        }
        .padding(.horizontal, 12).frame(height: 52)
    }

    // MARK: what the middle offers on the map

    /// Today's review, the lessons due back, the page last worked on, or the grade (Pill.offer).
    private var offer: Pill.Offer {
        let p = Progress.shared, now = PaperClock.now
        let partway = PaperModel.reviewPartway(now: now)
        let left = Pill.reviewLeft(ready: Review.ready(Map.openLessons, checks: p.checks) || partway != nil, doneToday: p.todaysReview != nil, partway: partway)
        let due = Map.pieces.filter { $0.opens && p.dueBack($0.id) }.map(\.id)
        let learned = p.learned
        // a locked lesson's page isn't offered (its work stays saved for when the plan comes back)
        let pages = (Map.pieces + Map.tests).filter { !$0.locked }.compactMap { piece -> Pill.Page? in
            // a screenshot reads only the pages it made itself
            guard let s = Shots.active ? PageStore.cached(piece.id) : PageStore.load(piece.id) else { return nil }
            let finished = piece.isTest ? s.recorded : learned.contains(piece.id) && s.recheck.isEmpty
            return Pill.Page(id: piece.id, date: s.date.timeIntervalSinceReferenceDate, finished: finished)
        }
        return Pill.offer(reviewLeft: left, due: due, pages: pages, now: now)
    }

    private func take(_ offer: Pill.Offer) {
        switch offer {
        case .review:
            // Today's review lives on Me: it opens where Me is, and closing it comes back to Me
            model.open(Map.review, from: .me)
        case .recheck(let id, _), .resume(let id):
            guard let p = Map.piece(id) else { return }
            if let place = model.place { model.open(p, from: place) } else { model.open(p) }
        case .grade: toggle(.grade)
        }
    }

    private func offerAccessibility(_ o: Pill.Offer) -> String {
        switch o {
        case .review(let n): "Go over: today's review, \(n) to do"
        case .recheck(let id, let n): "Go over: \(Map.piece(id)?.name ?? "") and \(n - 1) more"
        case .resume(let id): "Continue \(Map.piece(id)?.name ?? "")"
        case .grade: gradeName
        }
    }

    // MARK: what the buttons do

    private func toggle(_ p: BarUI.Panel) {
        if ui.open != p { ui.gradeSaid = nil }
        ui.open = ui.open == p ? nil : p
    }

    /// The child's grade in words, as Me says it ("5th grade").
    private var gradeName: String { Grades.name(AppSettings.profile.grade) }

    private var zoom: Double { model.camera(at: PaperClock.now).zoom }
    private func zoomBy(_ f: Double) { model.zoomButton(f) }
    private var learned: Int { Map.gradeLessons.filter { Progress.shared.learned.contains($0) }.count }

    /// The problem being worked on a lesson's page, if any.
    private var problem: (any PageProblem)? { model.bars.flatMap { $0.mode == .work ? $0.current : nil } }
    private var hasTools: Bool { problem != nil }
    private var helps: Bool { problem?.lesson.helps ?? false }

    /// What the pill shows beside its middle in a lesson (Pill.tools): Hint and Show me while a problem is worked (not
    /// in tests), Show me's word after a miss, "Next →" once it's solved, everything dimmed during a hand move.
    private var tools: Pill.Tools {
        guard model.openPiece != nil, let p = problem else { return Pill.tools(nil) }
        let missed = p.message.map { !$0.ok } ?? false
        return Pill.tools(Pill.Problem(inTest: inTest, auto: p.auto, solved: p.solved, missed: missed, moving: p.handMoving))
    }
    /// The hand move's live readout, as its lesson draws it.
    private var readout: String? { problem?.liveReadout }

    /// One square per step of the open problem; the How to's steps while it plays; else the page's squares.
    private var squares: (done: Int, of: Int) {
        guard let b = model.bars else { return (0, 0) }
        if let p = problem { return Pill.steps(p.lesson) }
        if b.mode == .howTo, !b.howToGone { return Pill.steps(b.howTo.lesson) }
        return b.squares
    }
    private func squaresWords(_ s: (done: Int, of: Int)) -> String {
        problem != nil ? (s.done >= s.of ? "Solved" : "Step \(s.done + 1) of \(s.of)") : "\(s.done) of \(s.of) done"
    }

    /// The chapter's colour, lifted a little on the dark paper as the lessons have it.
    private var chapterInk: Color {
        let c = problem?.chapter ?? model.bars?.piece.chapter ?? model.openPiece?.chapter ?? .whole
        return Ink.dynamic(c.hex, Ink.mix(c.hex, 0xECEBE7, 0.25))
    }

    /// Hints (G 20 Oct): the page decides, with its budget saved with it: free in together problems up to their cap (not
    /// counted), on their own one of the page's once the step had a miss (then the count shows), none in tests.
    private var hintCount: Int? { model.bars?.hintCount }
    private var canHint: Bool { (model.bars?.hintUse ?? .off) != .off }
    /// A test or a recheck (or its result): no help of any kind, so no Hint or Show me in the bar.
    private var inTest: Bool { model.bars?.inTest ?? false }
    private var canShowMe: Bool { helps && (step?.task != nil || step?.answer != nil) && problem?.solved != true }
    private var canReset: Bool { step?.task != nil }
    private var step: LessonStep? { problem?.lesson.step }
    private var canRead: Bool { problem != nil && !(model.bars?.inTest ?? false) }

    private func showMe() { problem?.showMe() }
    private func reset() { problem?.reset() }

    /// The instruction only, never the hint (G 20 Oct): that's the Hint button's, and counted.
    private func readAloud() {
        guard canRead, let s = problem?.lesson.words else { return }
        Speech.shared.say(problem?.intro ?? s.say)
    }
}

/// The pill's own state, kept across the frames the bar is drawn in: what's grown out of it, and what a grade's block said.
@MainActor @Observable
final class BarUI {
    static let shared = BarUI()
    enum Panel: Equatable { case more, grade, gate, grownUps }

    /// What's grown up out of the pill: ⋯ More, the grades, or the island (the grown-ups' hold, then their tabs). Shut, the
    /// last one stays drawn (`closing`) while the pill shrinks round it, so its words slide down behind the row with the
    /// pill's top edge instead of vanishing.
    var open: Panel? {
        get { panel }
        set {
            if newValue == nil, let p = panel {
                closing = p; closeCount += 1
                let n = closeCount, wait = slow ? 4.0 : 0.6
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(wait))
                    if let self, self.closeCount == n, self.panel == nil { self.closing = nil }
                }
            }
            if newValue != nil { closing = nil }
            panel = newValue
        }
    }
    private(set) var panel: Panel?
    /// The panel still drawn while the pill shuts round it.
    private(set) var closing: Panel?
    @ObservationIgnored private var closeCount = 0
    /// Each panel's own size, measured as it's drawn, and the row's width: the pill's size is worked out from them, so
    /// its width and height move together in one spring (G 29 Oct: "super smooth").
    var sizes: [Panel: CGSize] = [:]
    var rowWidth: Double = 0
    /// The island's tab shown, each tab's height (measured ahead), and what's been said or asked in it.
    var tab = Island.Tab.settings
    /// The way the island's pages slide on the next switch: to a tab further right, or back.
    var tabForward = true
    /// A finger holds a switch or a slider in the island: the touch is the control's, so the pages don't swipe under it.
    @ObservationIgnored var controlHeld = false
    var heights: [Island.Tab: Double] = [:]
    var askStartOver = false
    var said: [Island.Tab: String] = [:]
    var islandGrade: String?
    /// Bumped by each setting changed in the island, so it draws again.
    var settingsVersion = 0
    /// Screenshots only: the hold's ring this full, and kept there.
    var shotFill: CGFloat?
    /// What the last grade tapped said ("7th grade: coming soon.").
    var gradeSaid: String?
    /// Screenshots only (`-panel-demo`): the pill's changes run ten times slower.
    private(set) var slow = false

    private init() {
        let args = ProcessInfo.processInfo.arguments
        // `-panel=more` / `-panel=grade`: a screenshot opens that; the island: `-panel=gate` (the hold, its ring 60%
        // full), or a tab of the grown-ups' (`-panel=settings`, `privacy`, `help`, `plan`; `startover`: Start over asked)
        if let a = args.first(where: { $0.hasPrefix("-panel=") }) {
            let p = String(a.dropFirst(7))
            open = ["more": Panel.more, "grade": .grade, "gate": .gate][p] ?? (Island.Tab(rawValue: p.capitalized) != nil || p == "startover" ? .grownUps : nil)
            if p == "gate" { shotFill = 0.6 }
            if let t = Island.Tab(rawValue: p.capitalized) { tab = t }
            if p == "startover" { askStartOver = true }
        }
        // `-panel-demo`: ⋯ More opens at 4 s and shuts at 10 s, ten times slower, so stills can catch the drawer moving.
        // `-panel-demo=island`: the grown-ups' island grows out of the pill at 4 s, switches to Privacy at 12 s, and
        // shrinks back at 20 s, ten times slower
        slow = args.contains { $0.hasPrefix("-panel-demo") }
        if args.contains("-panel-demo=island") {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(4)); self?.open = .grownUps
                try? await Task.sleep(for: .seconds(8)); self?.tab = .privacy
                try? await Task.sleep(for: .seconds(8)); self?.open = nil
            }
        } else if slow {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(4)); self?.open = .more
                try? await Task.sleep(for: .seconds(6)); self?.open = nil
            }
        }
    }
}

/// Reads words aloud.
@MainActor
final class Speech {
    static let shared = Speech()
    private let synth = AVSpeechSynthesizer()
    func say(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text.replacingOccurrences(of: "/", with: " over "))
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        synth.speak(u)
    }
}

/// A button in the pill: Obento²'s own icon, its word under it only while it's held, lit when
/// it's where you are or what's open. `ring`: its word beside the icon, ringed in that colour (Show me after a miss).
/// `dim`: drawn as if off, but still tapped (what it does then is say why it's off).
struct PillButton: View {
    let icon: ObentoIcon
    let word: String
    var count: Int? = nil
    var lit = false
    var ring: Color? = nil
    var enabled = true
    var dim = false
    let action: () -> Void
    /// A long press shows the word for a moment, and the tap it ends with does nothing.
    @State private var held = false
    @State private var longPressed = false

    var body: some View {
        let under = held && ring == nil
        Button {
            if longPressed { longPressed = false; return }
            Practice.shared.touched()
            action()
        } label: {
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    ObentoIconView(icon, size: 24)
                        .overlay(alignment: .topTrailing) {
                            if let count {
                                Text("\(count)").font(Typeface.font(11, .bold)).monospacedDigit()
                                    .frame(minWidth: 16, minHeight: 16).padding(.horizontal, count > 9 ? 3 : 0)
                                    .background(Ink.sunk, in: Capsule()).offset(x: 10, y: -8)
                            }
                        }
                    if under {
                        Text(word).font(Typeface.font(11, .semibold)).lineLimit(1).fixedSize()
                            .transition(.opacity.combined(with: .offset(y: -3)))
                    }
                }
                if let ring {
                    Text(word).font(Typeface.font(17, .semibold)).foregroundStyle(ring).fixedSize()
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, ring != nil ? 14 : (under ? 8 : 0))
            .frame(minWidth: 52, minHeight: 52)
            .background(lit ? Ink.litFill : .clear, in: Capsule())
            .overlay { if let ring { Capsule().strokeBorder(ring, lineWidth: 1.5) } }
            .foregroundStyle(ring ?? (lit ? Ink.lit : Ink.ink))
            .contentShape(Capsule())
        }
        .buttonStyle(Press())
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
            longPressed = true
            withAnimation(Motion.snap) { held = true }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(Motion.close) { held = false }
                // a long press that never ended in a tap (the finger slid off) mustn't eat the next tap
                longPressed = false
            }
        })
        .disabled(!enabled).opacity(enabled && !dim ? 1 : 0.35)
        .accessibilityLabel(word)
        // lit is where you are (Lessons or Me): VoiceOver says so, and the real-touch tests can see it
        .accessibilityAddTraits(lit ? .isSelected : [])
        .animation(Motion.open, value: under)
    }
}

/// The middle's words, the one thing to do now: tinted when it's an action ("Continue →", "Go over · 2", "Next →"),
/// plain for the grade (lit while the grades are open).
struct MiddleWords: View {
    let text: String
    var lit = false
    /// The action's colour (the chapter's, in a lesson); nil: the bar's own lit colour.
    var tint: Color?
    var accessibility: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(Typeface.font(18, .semibold)).monospacedDigit().lineLimit(1).fixedSize()
                .contentTransition(.numericText())
                .padding(.horizontal, 18).frame(minHeight: 52)
                .background(lit ? (tint.map { $0.opacity(0.14) } ?? Ink.litFill) : .clear, in: Capsule())
                .foregroundStyle(lit ? (tint ?? Ink.lit) : Ink.ink)
                .contentShape(Capsule())
        }
        .buttonStyle(Press())
        .accessibilityLabel(accessibility)
    }
}

/// A problem's steps (or a page's problems) as small squares, filled in the chapter's colour as they're done.
struct StepSquares: View {
    let done: Int
    let of: Int
    let ink: Color
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<of, id: \.self) { i in
                Rectangle().fill(i < done ? ink : .clear)
                    .frame(width: 11, height: 11)
                    .overlay(Rectangle().strokeBorder(i < done ? ink : Ink.ink3, lineWidth: 1.5))
            }
        }
        .animation(Motion.snap, value: done)
    }
}

/// A grade's block in the grade row: the live grade lit, the others dashed (dead, "coming soon").
struct GradeBlock: View {
    let grade: Int
    let action: () -> Void
    var body: some View {
        let live = Grades.isLive(grade)
        Button(action: action) {
            Text(Grades.short(grade)).font(Typeface.font(15, live ? .bold : .medium)).monospacedDigit()
                .frame(width: 36, height: 36)
                .background(live ? Ink.litFill : .clear)
                .overlay(Rectangle().strokeBorder(live ? Ink.lit : Ink.ink3, style: StrokeStyle(lineWidth: 1.5, dash: live ? [] : [4, 3])))
                .foregroundStyle(live ? Ink.lit : Ink.ink3)
                .contentShape(Rectangle())
        }
        .buttonStyle(Press())
        .accessibilityLabel(Grades.name(grade))
        .accessibilityValue(live ? "" : "Coming soon")
        .accessibilityAddTraits(live ? .isSelected : [])
    }
}

/// A row in a menu: icon and words.
struct MenuRow: View {
    let icon: ObentoIcon
    let label: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ObentoIconView(icon, size: 24)
                Text(label).font(Typeface.font(18))
                Spacer()
            }
            .padding(.horizontal, 12).frame(height: 52)
            .foregroundStyle(Ink.ink).contentShape(Rectangle())
        }
        .buttonStyle(Press(scale: 0.98)).disabled(!enabled).opacity(enabled ? 1 : 0.35)
    }
}

struct SmallButton: View {
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text).font(Typeface.font(18)).foregroundStyle(Ink.ink)
                .frame(width: 34, height: 34).background(Ink.sunk, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(Press())
    }
}

/// The pill's size, moved as one: its width and the drawer's height are animated values here, so every frame lays the
/// pill out at that size, the drawer's words pinned to its top edge (they rise with it, never drawn where the pill
/// will end up before it gets there) and the row at its foot (G 29 Oct: "super smooth", tested frame by frame).
private struct PillBody<Drawer: View, Row: View>: View, Animatable {
    /// The pill's width (negative: as wide as the row, not yet measured), and the drawer's height above the row.
    var width: Double
    var height: Double
    let drawer: Drawer
    let row: Row
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(width, height) }
        set { width = newValue.first; height = newValue.second }
    }
    var body: some View {
        VStack(spacing: 0) {
            drawer
                .frame(width: width > 0 ? width : nil, height: max(0, height), alignment: .top)
                .clipped()
            row
                .frame(width: width > 0 ? width : nil)
                .background(Ink.surface.padding(-6))
                .zIndex(1)
        }
    }
}
