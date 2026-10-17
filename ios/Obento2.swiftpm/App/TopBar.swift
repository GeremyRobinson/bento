import SwiftUI

/// The top bar, as in the v27 prototype: rounded pills floating over the paper.
/// Left: the grade (on the map) or the way back (in a lesson), with how many lessons are learned.
/// Middle: the open lesson's name. Right: zoom, find, and light or dark with the profile.
/// On a narrow screen the zoom pill moves to the bottom, as v27 does on a phone.
struct TopBar: View {
    let model: PaperModel
    let top: CGFloat
    let bottom: CGFloat
    @Environment(\.colorScheme) private var scheme
    @AppStorage("theme") private var theme = ""

    var body: some View {
        let open = model.openPiece, wide = model.screen.width > 760
        ZStack(alignment: .top) {
            HStack(alignment: .top, spacing: 10) {
                grade(open != nil)
                Spacer(minLength: 0)
                if wide { zoom(open) }
                Pill {
                    RoundButton(icon: scheme == .dark ? "sun" : "moon") { theme = scheme == .dark ? "light" : "dark" }
                    RoundButton(icon: "user") {}
                }
            }
            if let p = open, wide {
                Pill {
                    VStack(spacing: 0) {
                        Text(p.name).font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink)
                        Text("\(p.chapter.title) · Lesson \(String(format: "%02d", Map.number(p)))" + (model.sessionLabel.map { " · \($0)" } ?? ""))
                            .font(Typeface.font(12)).foregroundStyle(Ink.ink3)
                    }
                    .padding(.horizontal, 15)
                }
            }
        }
        .padding(.horizontal, 16).padding(.top, top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .bottom) { if !wide { zoom(open).padding(.bottom, bottom) } }
    }

    private func grade(_ inLesson: Bool) -> some View {
        let learned = Map.gradeLessons.filter { Progress.shared.learned.contains($0) }.count
        return Pill {
            if inLesson {
                RoundButton(icon: "arrow-left") { model.close() }
            } else {
                Text(Map.grade.number).font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink)
                    .frame(width: 42, height: 42).overlay(Circle().strokeBorder(Ink.line, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(Map.grade.name).font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink)
                Text("\(learned) of \(Map.gradeLessons.count) learned").font(Typeface.font(13)).foregroundStyle(Ink.ink3)
            }
            .padding(.leading, 5).padding(.trailing, inLesson ? 15 : 0)
            if !inLesson { Icon(name: "caret-down", size: 16).foregroundStyle(Ink.ink3).padding(.trailing, 12) }
        }
    }

    private func zoom(_ open: Piece?) -> some View {
        let pct = model.lesson?.scale ?? model.camera(at: PaperClock.now).zoom
        func by(_ f: Double) { if let l = model.lesson { l.zoom(f) } else { model.zoomButton(f) } }
        return Pill {
            RoundButton(icon: "minus") { by(1 / 1.25) }
            Text("\(Int((pct * 100).rounded()))%").font(Typeface.font(13)).monospacedDigit().foregroundStyle(Ink.ink2).frame(minWidth: 52)
            RoundButton(icon: "plus") { by(1.25) }
            if open == nil || model.lesson == nil {
                Rectangle().fill(Ink.line).frame(width: 1, height: 24).padding(.horizontal, 5)
                if open == nil { RoundButton(icon: "frame-corners") { model.frameGroup() } }
                RoundButton(icon: "crosshair") { if open == nil { model.findNext() } else { model.reframe() } }
            }
        }
    }
}

/// A rounded pill floating over the paper: the surface colour, a thin line, its buttons inside.
struct Pill<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        HStack(spacing: 5) { content() }
            .padding(5).padding(.trailing, 0)
            .frame(height: 52)
            .background(Ink.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Ink.line, lineWidth: 1))
    }
}

/// A round button inside a pill.
struct RoundButton: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) { Icon(name: icon).frame(width: 42, height: 42).contentShape(Circle()) }
            .buttonStyle(.plain).foregroundStyle(Ink.ink)
    }
}
