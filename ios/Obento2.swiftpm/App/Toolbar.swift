import SwiftUI
import AVFoundation

/// The one floating bar at the bottom (G 17 Oct; lighter, words first, after the paper prototype G liked, 20 Oct): a
/// pill with a few buttons, where you are and how far along in the
/// middle, and everything else in ⋯ More. On the map: Lessons, Me (Me is a page on the paper, with Today in it, G 20
/// Oct). In a lesson: back to Lessons (or to Me, when it was opened there), the lesson and its progress, Hint and Show
/// me. It's fixed to the screen, never to the paper, so it can't jiggle as the paper moves. While the paper is pinched,
/// the middle shows the zoom for a moment instead.
struct Toolbar: View {
    let model: PaperModel
    let time: Double
    let bottom: CGFloat
    @Environment(\.colorScheme) private var scheme
    @AppStorage("theme") private var theme = ""
    @State private var open: Panel? = Toolbar.shotPanel
    /// `-panel=more`: a screenshot opens that panel.
    private static var shotPanel: Panel? {
        guard let a = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("-panel=") }) else { return nil }
        return ["more": Panel.more][String(a.dropFirst(7))]
    }

    enum Panel { case more }

    var body: some View {
        let inLesson = model.openPiece != nil
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            panel(inLesson)
            bar(inLesson)
        }
        .padding(.bottom, bottom)
        .frame(maxWidth: .infinity)
        .onChange(of: inLesson) { _, _ in open = nil }
    }

    // MARK: the bar

    private func bar(_ inLesson: Bool) -> some View {
        HStack(spacing: 6) {
            if inLesson {
                if let b = model.bars, b.mode == .work {
                    BarButton(icon: .back, label: "Problems") { open = nil; b.backToProblems() }
                } else {
                    BarButton(icon: .back, label: model.cameFrom == .me ? "Me" : "Lessons") { open = nil; model.close() }
                }
                divider
                info(title: model.openPiece?.name ?? "", detail: lessonDetail, progress: lessonProgress, wide: true)
                if hasTools && !inTest {
                    divider
                    // the hint is drawn on the paper (G 20 Oct): no card opens for it. Dim when there's none to give, but
                    // still there to tap: the paper then says why ("Have a go first. A hint comes after a miss.")
                    BarButton(icon: .hint, label: "Hint", count: hintCount, dim: !canHint) { open = nil; model.bars?.hint() }
                    BarButton(icon: .show, label: "Show me", enabled: canShowMe) { open = nil; showMe() }
                }
            } else {
                // the map (already on it, all of it), and Me: each a place on the paper, the one you're at lit
                BarButton(icon: .lessons, label: "Lessons", lit: model.place == nil) { open = nil; model.go(to: nil) }
                BarButton(icon: .me, label: "Me", lit: model.place == .me) { open = nil; model.go(to: .me) }
                divider
                info(title: Map.grade.name, detail: "\(learned) of \(Map.gradeLessons.count) learned", progress: Double(learned) / Double(Map.gradeLessons.count))
            }
            divider
            BarButton(icon: .more, label: nil, lit: open == .more) { toggle(.more) }
        }
        // the same gap all round, so a lit button sits evenly inside the bar's curve
        .padding(6)
        // the shadow belongs to the bar's shape only: on the whole bar, SwiftUI shadowed every button and word in it
        .background(Capsule().fill(Ink.surface).shadow(color: .black.opacity(0.08), radius: 12, y: 6))
        .overlay(Capsule().strokeBorder(Ink.line, lineWidth: 1))
    }

    private var divider: some View { Rectangle().fill(Ink.line).frame(width: 1, height: 32).padding(.horizontal, 4) }

    /// Where you are and how far along, or for a moment after a pinch, the zoom.
    private func info(title: String, detail: String, progress: Double, wide: Bool = false) -> some View {
        let zooming = time - model.pinchedAt < 1.2
        return VStack(alignment: .leading, spacing: 3) {
            if zooming {
                Text("\(Int((zoom * 100).rounded()))%").font(Typeface.font(22, .semibold)).monospacedDigit().foregroundStyle(Ink.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // the name, then where you are on its own line, so it's never cut short
                Text(title).font(Typeface.font(18, .semibold)).foregroundStyle(Ink.ink).lineLimit(1)
                // a count that changes rolls over like a clock's digits (G 19 Oct)
                Text(detail).font(Typeface.font(14, .medium)).monospacedDigit().foregroundStyle(Ink.ink2).lineLimit(1)
                    .contentTransition(.numericText()).animation(.snappy(duration: 0.32), value: detail)
                Capsule().fill(Ink.sunk).frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in Capsule().fill(Ink.lit).frame(width: max(6, g.size.width * min(1, progress))) }
                    }
            }
        }
        .padding(.horizontal, 12)
        .frame(width: model.screen.width > 900 ? (wide ? 340 : 280) : 220, height: 52)
    }

    // MARK: what opens above it

    @ViewBuilder private func panel(_ inLesson: Bool) -> some View {
        switch open {
        case .more?: Card(width: 300) { inLesson ? AnyView(lessonMenu) : AnyView(mapMenu) }
        case nil: EmptyView()
        }
    }

    private var mapMenu: some View {
        VStack(spacing: 0) {
            zoomRow
            MenuRow(icon: .find, label: "Find what's next") {
                open = nil
                // from a place, back to the map first
                if model.place == nil { model.findNext() } else { model.go(to: nil) { model.findNext() } }
            }
            MenuRow(icon: .dark, label: scheme == .dark ? "Light" : "Dark") { theme = scheme == .dark ? "light" : "dark" }
            // the grown-ups' page, shut behind its hold
            MenuRow(icon: .lock, label: "For grown-ups") { open = nil; model.go(to: .grownUp) }
        }
    }

    private var lessonMenu: some View {
        VStack(spacing: 0) {
            if hasTools {
                MenuRow(icon: .restart, label: "Start this problem over", enabled: canReset) { open = nil; reset() }
            }
            // off in tests (G 20 Oct)
            MenuRow(icon: .read, label: "Read it aloud", enabled: canRead) { open = nil; readAloud() }
            if let b = model.bars, b.howToGone, !b.inTest { MenuRow(icon: .show, label: "Watch the How to again") { open = nil; b.watchAgain() } }
            MenuRow(icon: .dark, label: scheme == .dark ? "Light" : "Dark") { theme = scheme == .dark ? "light" : "dark" }
            zoomRow
        }
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

    // MARK: what the buttons do

    private func toggle(_ p: Panel) { open = open == p ? nil : p }

    private var zoom: Double { model.camera(at: PaperClock.now).zoom }
    private func zoomBy(_ f: Double) { model.zoomButton(f) }
    private var learned: Int { Map.gradeLessons.filter { Progress.shared.learned.contains($0) }.count }

    /// The problem being worked on a lesson's page, if any.
    private var problem: (any PageProblem)? { model.bars.flatMap { $0.mode == .work ? $0.current : nil } }
    private var hasTools: Bool { problem != nil }
    private var helps: Bool { problem?.lesson.helps ?? false }

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

    /// In a problem: which one and its step ("Together 1 · Step 2 of 4"), the bar filling as its steps are done (as the
    /// paper prototype G liked, 20 Oct); on the page: how far through the page.
    private var lessonDetail: String {
        if let p = problem, let s = problemSteps { return "\(model.bars?.label ?? p.label) · Step \(s.at) of \(s.of)" }
        return model.bars?.label ?? ""
    }
    private var lessonProgress: Double {
        if let s = problemSteps { return Double(s.at - 1) / Double(max(1, s.of - 1)) }
        if let b = model.bars, b.showing { return b.progress }
        return 0
    }
    /// The open problem's steps as the child meets them, from its first question (a story's "Pick what to do") to its
    /// answer: the opening question a page's problem goes straight past isn't one, so the first step is Step 1.
    private var problemSteps: (at: Int, of: Int)? {
        guard let l = problem?.lesson else { return nil }
        let seen = l.steps.indices.filter { !(l.skipsAsk && $0 == l.askIndex) }
        return ((seen.firstIndex(of: l.index) ?? 0) + 1, max(1, seen.count))
    }

    /// The instruction only, never the hint (G 20 Oct): that's the Hint button's, and counted.
    private func readAloud() {
        guard canRead, let s = problem?.lesson.words else { return }
        Speech.shared.say(problem?.intro ?? s.say)
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

/// A big button in the bar: an icon and, for the main ones, its word. Lit when it's where you are or what's open.
/// `dim`: drawn as if off, but still tapped (what it does then is say why it's off).
struct BarButton: View {
    let icon: ObentoIcon
    let label: String?
    var count: Int? = nil
    var lit = false
    var enabled = true
    var dim = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ObentoIconView(icon, size: 24)
                if let label { Text(label).font(Typeface.font(18, .semibold)) }
                if let count {
                    Text("\(count)").font(Typeface.font(15, .bold)).monospacedDigit()
                        .frame(minWidth: 24, minHeight: 24).padding(.horizontal, count > 9 ? 4 : 0)
                        .background(Ink.sunk, in: Capsule())
                }
            }
            .padding(.leading, label == nil ? 0 : 12).padding(.trailing, label == nil ? 0 : 14)
            .frame(minWidth: 52, minHeight: 52)
            .background(lit ? Ink.litFill : .clear, in: Capsule())
            .foregroundStyle(lit ? Ink.lit : Ink.ink)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled).opacity(enabled && !dim ? 1 : 0.35)
        .accessibilityLabel(label ?? "More")
        // lit is where you are (Lessons or Me): VoiceOver says so, and the real-touch tests can see it
        .accessibilityAddTraits(lit ? .isSelected : [])
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
        .buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.35)
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
        .buttonStyle(.plain)
    }
}

/// What opens above the bar: the surface colour, a thin line, rounded, a soft shadow.
struct Card<Content: View>: View {
    let width: CGFloat
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(8)
            .frame(width: width)
            .background(RoundedRectangle(cornerRadius: 24).fill(Ink.surface).shadow(color: .black.opacity(0.12), radius: 18, y: 10))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Ink.line, lineWidth: 1))
            .transition(.opacity.combined(with: .offset(y: 8)))
    }
}
