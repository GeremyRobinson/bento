import SwiftUI
import AVFoundation

/// The one floating bar at the bottom (G 17 Oct): a pill with a few big buttons, where you are and how far along in the
/// middle, and everything else in ⋯ More. On the map: Lessons, Me (Today will live in Me, G 17 Oct). In a lesson: back to Lessons, the lesson and
/// its progress, Hint and Show me. It's fixed to the screen, never to the paper, so it can't jiggle as the paper moves.
/// While the paper is pinched, the middle shows the zoom for a moment instead.
struct Toolbar: View {
    let model: PaperModel
    let time: Double
    let bottom: CGFloat
    @Environment(\.colorScheme) private var scheme
    @AppStorage("theme") private var theme = ""
    @State private var open: Panel? = Toolbar.shotPanel
    /// `-panel=more|me|hint`: a screenshot opens that panel.
    private static var shotPanel: Panel? {
        guard let a = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("-panel=") }) else { return nil }
        return ["more": Panel.more, "me": .me, "hint": .hint][String(a.dropFirst(7))]
    }
    @State private var hintsUsed = 0

    enum Panel { case more, me, hint }

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
                BarButton(icon: .back, label: "Lessons") { open = nil; model.close() }
                divider
                info(title: model.openPiece?.name ?? "", detail: lessonDetail, progress: lessonProgress, wide: true)
                if hasTools {
                    divider
                    BarButton(icon: .hint, label: "Hint", count: hintsLeft, lit: open == .hint, enabled: canHint) { toggle(.hint) }
                    BarButton(icon: .show, label: "Show me", enabled: canShowMe) { open = nil; showMe() }
                }
            } else {
                BarButton(icon: .lessons, label: "Lessons", lit: open != .me) { open = nil; model.frameAll() }
                BarButton(icon: .me, label: "Me", lit: open == .me) { toggle(.me) }
                divider
                info(title: Map.grade.name, detail: "\(learned) of \(Map.gradeLessons.count) learned", progress: Double(learned) / Double(Map.gradeLessons.count))
            }
            divider
            BarButton(icon: .more, label: nil, lit: open == .more) { toggle(.more) }
        }
        // the same gap all round, so a lit button sits evenly inside the bar's curve
        .padding(6)
        // the shadow belongs to the bar's shape only: on the whole bar, SwiftUI shadowed every button and word in it
        .background(Capsule().fill(Ink.surface).shadow(color: .black.opacity(0.10), radius: 15, y: 8))
        .overlay(Capsule().strokeBorder(Ink.line, lineWidth: 1))
    }

    private var divider: some View { Rectangle().fill(Ink.line).frame(width: 1, height: 40).padding(.horizontal, 4) }

    /// Where you are and how far along, or for a moment after a pinch, the zoom.
    private func info(title: String, detail: String, progress: Double, wide: Bool = false) -> some View {
        let zooming = time - model.pinchedAt < 1.2
        return VStack(alignment: .leading, spacing: 6) {
            if zooming {
                Text("\(Int((zoom * 100).rounded()))%").font(Typeface.font(22, .semibold)).monospacedDigit().foregroundStyle(Ink.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title).font(Typeface.font(20, .semibold)).foregroundStyle(Ink.ink).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(detail).font(Typeface.font(17)).foregroundStyle(Ink.ink2).lineLimit(1)
                }
                Capsule().fill(Ink.sunk).frame(height: 6)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in Capsule().fill(Ink.lit).frame(width: max(6, g.size.width * min(1, progress))) }
                    }
            }
        }
        .padding(.horizontal, 12)
        .frame(width: model.screen.width > 900 ? (wide ? 360 : 300) : 230, height: 64)
    }

    // MARK: what opens above it

    @ViewBuilder private func panel(_ inLesson: Bool) -> some View {
        switch open {
        case .more?: Card(width: 300) { inLesson ? AnyView(lessonMenu) : AnyView(mapMenu) }
        case .me?: Card(width: 320) { meCard }
        case .hint?: Card(width: 380) { hintCard }
        case nil: EmptyView()
        }
    }

    private var mapMenu: some View {
        VStack(spacing: 0) {
            zoomRow
            MenuRow(icon: .find, label: "Find what's next") { open = nil; model.findNext() }
            MenuRow(icon: .dark, label: scheme == .dark ? "Light" : "Dark") { theme = scheme == .dark ? "light" : "dark" }
        }
    }

    private var lessonMenu: some View {
        VStack(spacing: 0) {
            if hasTools {
                MenuRow(icon: .restart, label: "Start this problem over", enabled: canReset) { open = nil; reset() }
            }
            MenuRow(icon: .read, label: "Read it aloud") { open = nil; readAloud() }
            if let b = model.bars, b.howToGone { MenuRow(icon: .show, label: "Watch the How to again") { open = nil; b.watchAgain() } }
            if let b = model.bars, b.canSkipToCheck { MenuRow(icon: .find, label: "Go to the skill check") { open = nil; b.skipToCheck() } }
            if model.bars?.showing == true { MenuRow(icon: .every, label: "See every problem") { open = nil; model.frameAll() } }
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

    /// Me: the three shelves of the child's own page, counted (the page itself comes with its preview).
    private var meCard: some View {
        let s = Mastery.shelves(Map.pieces.map(\.id), checks: Progress.shared.checks, now: Date().timeIntervalSinceReferenceDate)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Me").font(Typeface.font(20, .semibold)).foregroundStyle(Ink.ink)
            ForEach([("Go over", s.goOver.count), ("Getting stronger", s.gettingStronger.count), ("Stuck for good", s.stuck.count)], id: \.0) { row in
                HStack {
                    Text(row.0).font(Typeface.font(18)).foregroundStyle(Ink.ink)
                    Spacer()
                    Text("\(row.1)").font(Typeface.font(18, .semibold)).monospacedDigit().foregroundStyle(Ink.ink)
                }
            }
        }
        .padding(8)
    }

    private var hintCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hintsLeft.map { "Hint · \($0) left in this lesson" } ?? "Hint").font(Typeface.font(16, .semibold)).foregroundStyle(Ink.ink2)
            Text(hintText).font(Typeface.font(18)).foregroundStyle(Ink.ink).fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: what the buttons do

    private func toggle(_ p: Panel) {
        if p == .hint, open != .hint, canHint { hintsUsed += 1; problem?.usedHint() }
        open = open == p ? nil : p
    }

    private var zoom: Double { model.lesson?.scale ?? model.camera(at: PaperClock.now).zoom }
    private func zoomBy(_ f: Double) { if let l = model.lesson { l.zoom(f) } else { model.zoomButton(f) } }
    private var learned: Int { Map.gradeLessons.filter { Progress.shared.learned.contains($0) }.count }

    /// The problem being worked on a lesson's page, if any.
    private var problem: AddFractionsModel? { model.bars?.current.flatMap { $0.auto ? nil : $0 } }
    private var hasTools: Bool { problem != nil || model.lesson != nil }
    private var helps: Bool { problem?.lesson.helps ?? model.lesson?.lesson.helps ?? false }

    /// Hints: about one for every two problems on a page (the web's rule), none in the skill check.
    private var hintsLeft: Int? {
        guard model.bars != nil else { return nil }
        return max(0, LessonPage.count / 2 - hintsUsed)
    }
    private var canHint: Bool { helps && (open == .hint || (hintsLeft ?? 1) > 0) && step?.task != nil }
    private var canShowMe: Bool { helps && step?.task != nil }
    private var canReset: Bool { step?.task != nil }
    private var step: LessonStep? { problem?.lesson.step ?? model.lesson?.lesson.step }
    private var hintText: String { step.map { $0.look ?? $0.words.hint } ?? "" }

    private func showMe() { if let p = problem { p.showMe() } else { model.lesson?.showMe() } }
    private func reset() { if let p = problem { p.reset() } else { model.lesson?.reset() } }

    private var lessonDetail: String {
        if let b = model.bars { return b.showing ? "\(b.problems.filter(\.solved).count) of \(b.problems.count)" : "How to" }
        return model.lesson?.session.label ?? ""
    }
    private var lessonProgress: Double {
        if let b = model.bars, b.showing { return Double(b.problems.filter(\.solved).count) / Double(b.problems.count) }
        return 0
    }

    private func readAloud() {
        guard let s = problem?.lesson.words ?? model.lesson?.lesson.words else { return }
        Speech.shared.say(s.say + ". " + s.hint)
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
struct BarButton: View {
    let icon: ObentoIcon
    let label: String?
    var count: Int? = nil
    var lit = false
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ObentoIconView(icon, size: 32)
                if let label { Text(label).font(Typeface.font(20, .semibold)) }
                if let count {
                    Text("\(count)").font(Typeface.font(17, .bold)).monospacedDigit()
                        .frame(minWidth: 28, minHeight: 28).padding(.horizontal, count > 9 ? 4 : 0)
                        .background(Ink.sunk, in: Capsule())
                }
            }
            .padding(.leading, label == nil ? 0 : 14).padding(.trailing, label == nil ? 0 : 16)
            .frame(minWidth: 64, minHeight: 64)
            .background(lit ? Ink.litFill : .clear, in: Capsule())
            .foregroundStyle(lit ? Ink.lit : Ink.ink)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled).opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label ?? "More")
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
