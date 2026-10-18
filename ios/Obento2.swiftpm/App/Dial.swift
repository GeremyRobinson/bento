import SwiftUI
import AVFoundation

/// The dial (G 17 Oct): the app's one control, instead of a toolbar. It rises from the bottom edge like the face of a
/// camera's mode dial. The outer ring picks a mode; the inner ring tunes its value, and the paper changes as it turns:
/// the zoom, light or dark, the chapter the camera glides to, the problem being worked. Its ticks are drawn like the
/// grid, a thin one for each step and a strong one every so often. At rest only its face shows, with the readout;
/// a tap raises the whole wheel, and a tap on the paper lowers it again.
struct Dial: View {
    let model: PaperModel
    let time: Double
    @AppStorage("theme") private var theme = ""
    @AppStorage("sound") private var sound = 0
    @State private var open = ProcessInfo.processInfo.arguments.contains("-dial=open")
    @State private var modeIndex = Int(ProcessInfo.processInfo.arguments.first { $0.hasPrefix("-dialmode=") }?.dropFirst(10) ?? "") ?? 0
    @State private var values: [String: Int] = [:]
    /// The rings' turn while a finger drags them, in degrees.
    @State private var modeTurn: Double?
    @State private var valueTurn: Double?
    @State private var drag: (start: Double, from: Double, outer: Bool, moved: Double, last: Int)?
    @State private var hint: String?
    @State private var hintsUsed = 0

    // the wheel's sizes, as the mockup G approved
    static let face = 262.0, valueLabels = 288.0, valueTicks = 322.0, modeLabels = 385.0, outerTicks = 418.0, side = 900.0
    static let modeStep = 24.0

    var body: some View {
        GeometryReader { g in
            let s = min(1, g.size.width / 1180)
            let centre = CGPoint(x: g.size.width / 2, y: g.size.height + (open ? 160 : 192) * s)
            ZStack {
                if open {
                    // the paper behind: a tap there lowers the dial
                    Color.black.opacity(0.001).onTapGesture { close() }
                }
                if let hint, open || inLesson {
                    hintCard(hint).position(x: g.size.width / 2, y: centre.y - (open ? 470 : 300) * s)
                }
                wheel
                    .frame(width: Self.side, height: Self.side)
                    .scaleEffect(s)
                    .position(centre)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: open)
        }
        .onChange(of: inLesson) { _, _ in
            values = [:]; hint = nil
            if !ProcessInfo.processInfo.arguments.contains("-dial=open") { modeIndex = 0; open = false }
        }
    }

    // MARK: the wheel

    private var wheel: some View {
        let modes = self.modes, mode = modes[min(modeIndex, modes.count - 1)]
        let mTurn = modeTurn ?? -Double(modeIndex) * Self.modeStep
        let index = value(of: mode), vTurn = valueTurn ?? -Double(index) * mode.step
        return ZStack {
            // the outer ticks and the mode names
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for a in stride(from: -76.0, through: 76.0, by: 2) {
                    tick(&ctx, c, a, Self.outerTicks, a.truncatingRemainder(dividingBy: 10) == 0 ? 14 : 8, 1.5, Ink.ink, 0.25 + 0.5 * fade(a))
                }
            }
            .opacity(open ? 1 : 0)
            ForEach(Array(modes.enumerated()), id: \.offset) { i, m in
                let a = Double(i) * Self.modeStep + mTurn
                Text(m.name).font(Typeface.font(18, .semibold))
                    .foregroundStyle(i == modeIndex ? Ink.ink : Ink.ink3)
                    .rotationEffect(.degrees(a)).position(point(a, Self.modeLabels))
                    .opacity(open ? min(1, fade(a) * 1.4) : 0)
            }
            // the face
            Circle().fill(Ink.surface).overlay(Circle().strokeBorder(Ink.lineStrong, lineWidth: 1.5))
                .frame(width: Self.face * 2, height: Self.face * 2)
            // the value ticks and their labels
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for j in mode.stops.indices {
                    let a = Double(j) * mode.step + vTurn
                    let major = j % mode.labelEvery == 0
                    if abs(a) < 80 { tick(&ctx, c, a, Self.valueTicks, major ? 22 : 12, 2, mode.colour?(j) ?? Ink.ink, 0.3 + 0.7 * fade(a)) }
                    if j < mode.stops.count - 1 {
                        for k in 1..<mode.sub {
                            let b = a + mode.step * Double(k) / Double(mode.sub)
                            if abs(b) < 80 { tick(&ctx, c, b, Self.valueTicks + 4, 6, 1.5, Ink.ink, 0.2 + 0.5 * fade(b)) }
                        }
                    }
                }
            }
            .opacity(open ? 1 : 0)
            ForEach(mode.stops.indices.filter { $0 % mode.labelEvery == 0 }, id: \.self) { j in
                let a = Double(j) * mode.step + vTurn
                if abs(a) < 80 {
                    Text(mode.short(j)).font(Typeface.font(16, .semibold)).monospacedDigit().foregroundStyle(j == index ? Ink.ink : Ink.ink2)
                        .rotationEffect(.degrees(a)).position(point(a, Self.valueLabels)).opacity(open ? fade(a) : 0)
                }
            }
            // the marker, through both rings, as the mockup
            Capsule().fill(Chapter.fractions.color).frame(width: 3, height: 150)
                .position(x: Self.side / 2, y: Self.side / 2 - 371).opacity(open ? 1 : 0)
            // the readout: the mode small, its value big (the zoom's size, G 17 Oct)
            // a pinch on the paper shows the zoom here for a moment
            let pinching = time - model.pinchedAt < 1.2
            VStack(spacing: 4) {
                Text(pinching ? "Zoom" : mode.name).font(Typeface.font(15, .semibold)).foregroundStyle(Ink.ink3)
                Text(pinching ? "\(Int((zoomNow * 100).rounded()))%" : readout(mode, live: liveIndex(mode, vTurn))).font(Typeface.font(22, .semibold)).monospacedDigit()
                    .foregroundStyle(Ink.ink).lineLimit(1)
            }
            .frame(width: 340)
            .position(x: Self.side / 2, y: Self.side / 2 - 222)
        }
        .contentShape(Circle().inset(by: (Self.side - 2 * (open ? Self.outerTicks + 20 : Self.face)) / 2))
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { v in dragged(v, mode: mode, mTurn: mTurn, vTurn: vTurn) }
            .onEnded { v in ended(v, mode: mode) })
        .accessibilityElement()
        .accessibilityLabel("Dial, \(mode.name): \(readout(mode, live: index))")
        .accessibilityAdjustableAction { dir in
            let j = max(0, min(mode.stops.count - 1, index + (dir == .increment ? 1 : -1))); choose(mode, j)
        }
    }

    // MARK: turning it

    private func angle(_ p: CGPoint) -> (a: Double, d: Double) {
        let dx = p.x - Self.side / 2, dy = p.y - Self.side / 2
        return (atan2(dx, -dy) * 180 / .pi, hypot(dx, dy))
    }

    private func dragged(_ v: DragGesture.Value, mode: Mode, mTurn: Double, vTurn: Double) {
        let p = angle(v.location)
        if drag == nil {
            if !open { return }
            let outer = p.d > Self.modeLabels - 30
            drag = (p.a, outer ? mTurn : vTurn, outer, 0, value(of: mode))
        }
        guard var d = drag else { return }
        d.moved = max(d.moved, hypot(v.translation.width, v.translation.height))
        let turn = d.from + (p.a - d.start)
        if d.outer { modeTurn = turn } else {
            valueTurn = turn
            // the zoom changes the paper live as the ring turns
            let j = max(0, min(mode.stops.count - 1, Int((-turn / mode.step).rounded())))
            if j != d.last { d.last = j; Detent.tick(); if mode.live { choose(mode, j) } }
        }
        drag = d
    }

    private func ended(_ v: DragGesture.Value, mode: Mode) {
        guard open else { open = true; return }
        guard let d = drag else { return }
        drag = nil
        var turn = d.outer ? (modeTurn ?? d.from) : (valueTurn ?? d.from)
        if d.moved < 4 {
            // a tap: on the readout, the help shown is done again; on a ring, that stop comes to the marker
            let p = angle(v.location)
            if p.d < Self.face - 20 { if mode.id == "help" { choose(mode, value(of: mode)) }; return }
            turn = d.from - p.a
        }
        if d.outer {
            let i = max(0, min(modes.count - 1, Int((-turn / Self.modeStep).rounded())))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { modeIndex = i; modeTurn = nil; valueTurn = nil }
            if i != modeIndexBefore(d) { Detent.tick() }
        } else {
            let j = max(0, min(mode.stops.count - 1, Int((-turn / mode.step).rounded())))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { valueTurn = nil }
            choose(mode, j)
        }
    }
    private func modeIndexBefore(_ d: (start: Double, from: Double, outer: Bool, moved: Double, last: Int)) -> Int { Int((-d.from / Self.modeStep).rounded()) }

    private func close() { open = false; hint = nil }

    // MARK: the modes

    struct Mode {
        let id: String, name: String, step: Double, stops: [String]
        var labelEvery = 1, sub = 4
        /// Its value changes the paper while the ring turns, not only when it settles (the zoom).
        var live = false
        var colour: ((Int) -> Color)? = nil
        var labels: [String]? = nil
        func short(_ j: Int) -> String { labels?[j] ?? stops[j] }
    }

    private var inLesson: Bool { model.openPiece != nil }

    private var modes: [Mode] {
        let zoom = Mode(id: "zoom", name: "Zoom", step: 2.5, stops: (0..<46).map { "\(25 + $0 * 5)%" }, labelEvery: 5, sub: 1, live: true)
        let look = Mode(id: "look", name: "Look", step: 24, stops: ["Light", "Dark", "Auto"])
        let sound = Mode(id: "sound", name: "Sound", step: 24, stops: ["Off", "Sounds", "Read aloud"])
        if inLesson {
            var out: [Mode] = []
            if let b = model.bars, b.showing {
                out.append(Mode(id: "problems", name: "Problems", step: 9, stops: b.problems.map(\.label),
                                colour: { j in b.problems[j].solved ? Chapter.fractions.color : Ink.ink },
                                labels: b.problems.indices.map { $0 < 12 ? "\($0 + 1)" : "C\($0 - 11)" }))
            }
            out.append(Mode(id: "help", name: "Help", step: 22, stops: ["Hint", "Show me", "Start over", "Read aloud"]))
            out += [zoom, look, sound]
            out.append(Mode(id: "leave", name: "Lessons", step: 24, stops: ["Stay here", "Back to the map"]))
            return out
        }
        let s = shelves
        return [
            Mode(id: "lessons", name: "Lessons", step: 20, stops: Map.groups.map(\.chapter.title), colour: { Map.groups[$0].chapter.color }),
            Mode(id: "me", name: "Me", step: 22, stops: ["Go over · \(s.goOver.count)", "Getting stronger · \(s.gettingStronger.count)", "Stuck for good · \(s.stuck.count)"],
                 labels: ["Go over", "Getting stronger", "Stuck"]),
            Mode(id: "grade", name: "Grade", step: 9, stops: ["K", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th"]),
            zoom, look, sound
        ]
    }

    private var shelves: Mastery.Shelves {
        Mastery.shelves(Map.pieces.map(\.id), checks: Progress.shared.checks, now: Date().timeIntervalSinceReferenceDate)
    }

    /// Where a mode's ring sits now: what the paper is showing.
    private func value(of m: Mode) -> Int {
        if let v = values[m.id] { return v }
        switch m.id {
        case "zoom": return max(0, min(45, Int(((zoomNow * 100 - 25) / 5).rounded())))
        case "look": return theme == "light" ? 0 : theme == "dark" ? 1 : 2
        case "sound": return sound
        case "grade": return 5
        case "problems": return model.bars?.current.flatMap { c in model.bars?.problems.firstIndex { $0 === c } } ?? 0
        case "lessons": return Map.groups.firstIndex { $0.chapter == Map.today?.chapter } ?? 0
        default: return 0
        }
    }

    private func liveIndex(_ m: Mode, _ turn: Double) -> Int { max(0, min(m.stops.count - 1, Int((-turn / m.step).rounded()))) }

    private func readout(_ m: Mode, live j: Int) -> String {
        switch m.id {
        case "grade": j == 5 ? "5th grade" : (j == 0 ? "Kindergarten" : m.stops[j] + " grade") + " · soon"
        case "problems": m.stops[j]
        default: m.stops[j]
        }
    }

    private var zoomNow: Double { model.lesson?.scale ?? model.camera(at: PaperClock.now).zoom }

    /// The ring settled on stop `j`: the paper changes to match.
    private func choose(_ m: Mode, _ j: Int) {
        switch m.id {
        case "zoom":
            values[m.id] = j
            let z = Double(25 + j * 5) / 100
            if let l = model.lesson { l.zoom(z / l.scale) } else { model.zoomTo(z) }
        case "look": values[m.id] = j; theme = ["light", "dark", ""][j]
        case "sound": values[m.id] = j; sound = j
        case "grade": values[m.id] = j == 5 ? 5 : nil   // only 5th grade is on the paper so far: the ring goes back
        case "lessons": values[m.id] = j; model.frameChapter(j)
        case "me":
            values[m.id] = j
            let s = shelves, ids = [s.goOver, s.gettingStronger, s.stuck][j]
            if let id = ids.first, let p = Map.pieces.first(where: { $0.id == id }) { model.select(p) }
        case "problems":
            values[m.id] = j
            if let b = model.bars, j < b.problems.count { b.activate(b.problems[j]) }
        case "help":
            values[m.id] = j
            help(j)
        case "leave":
            if j == 1 { values[m.id] = 0; close(); model.close() }
        default: break
        }
    }

    // MARK: help in a lesson

    private var problem: AddFractionsModel? { model.bars?.current.flatMap { $0.auto ? nil : $0 } }
    private var step: LessonStep? { problem?.lesson.step ?? model.lesson?.lesson.step }
    private var helps: Bool { problem?.lesson.helps ?? model.lesson?.lesson.helps ?? false }

    private func help(_ j: Int) {
        switch j {
        case 0:
            guard helps, let s = step, s.task != nil else { hint = "No hints in the skill check. You can do it."; return }
            let left = LessonPage.count / 2 - hintsUsed
            guard left > 0 || model.bars == nil else { hint = "No hints left in this lesson."; return }
            if model.bars != nil { hintsUsed += 1 }
            hint = (s.look ?? s.words.hint) + (model.bars != nil ? "\n\(left - 1) hints left" : "")
        case 1: hint = nil; if helps { if let p = problem { p.showMe() } else { model.lesson?.showMe() } }
        case 2: hint = nil; if let p = problem { p.reset() } else { model.lesson?.reset() }
        case 3:
            hint = nil
            if let w = problem?.lesson.words ?? model.lesson?.lesson.words { Speech.shared.say(w.say + ". " + w.hint) }
        default: break
        }
    }

    private func hintCard(_ text: String) -> some View {
        Text(text).font(Typeface.font(18)).foregroundStyle(Ink.ink).multilineTextAlignment(.leading)
            .padding(18).frame(width: 380, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Ink.surface).shadow(color: .black.opacity(0.12), radius: 16, y: 8))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Ink.line, lineWidth: 1))
            .onTapGesture { hint = nil }
    }

    // MARK: drawing

    private func point(_ a: Double, _ r: Double) -> CGPoint {
        CGPoint(x: Self.side / 2 + r * sin(a * .pi / 180), y: Self.side / 2 - r * cos(a * .pi / 180))
    }
    private func fade(_ a: Double) -> Double { max(0, 1 - abs(a) / 72) }
    private func tick(_ ctx: inout GraphicsContext, _ c: CGPoint, _ a: Double, _ r: Double, _ len: Double, _ w: Double, _ colour: Color, _ op: Double) {
        let t = a * .pi / 180, dx = sin(t), dy = -cos(t)
        var p = Path()
        p.move(to: CGPoint(x: c.x + (r - len / 2) * dx, y: c.y + (r - len / 2) * dy))
        p.addLine(to: CGPoint(x: c.x + (r + len / 2) * dx, y: c.y + (r + len / 2) * dy))
        var g = ctx; g.opacity = op
        g.stroke(p, with: .color(colour), style: StrokeStyle(lineWidth: w, lineCap: .round))
    }
}

/// A detent's feel: a selection tick on devices that can.
@MainActor
enum Detent {
    private static let feedback = UISelectionFeedbackGenerator()
    static func tick() { feedback.selectionChanged() }
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
