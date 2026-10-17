import SwiftUI

/// A lesson worked in steps, on the flat paper: the words, the problem, the finished work, the line being worked
/// with its answer boxes, the keypad and the buttons. Pinned to the paper with the paper's camera.
/// The picture is in the paper's scene (PaperScene), drawn by the lesson's master; its words are added here.
struct StepsLessonView: View {
    let model: StepsModel
    let camera: PaperCamera
    let time: Double
    let top: CGFloat
    let onBack: () -> Void

    var body: some View {
        let k = camera.zoom, l = model.lesson, o = model.origin
        let at = { (x: Double, y: Double) -> CGPoint in let p = camera.toScreen(Point(o.x + x, o.y + y)); return CGPoint(x: p.x, y: p.y) }
        let fresh = ease((time - model.wordsAt) / 0.5), shown = model.grow(at: time)

        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(l.words.say).font(Typeface.question).foregroundStyle(Ink.ink).frame(height: 40, alignment: .leading)
                Text(l.words.hint).font(Typeface.hint).foregroundStyle(Ink.ink2).frame(height: 20, alignment: .leading)
            }
            .frame(width: 640, alignment: .leading)
            .opacity(fresh).offset(y: (1 - fresh) * 8)
            .pinned(at(0, 0), .bottomLeading, k)

            MathLineView(line: l.display, size: 40).opacity(shown).pinned(at(0, 60), .bottomLeading, k)

            if l.spec.master == "shift" { ShiftWords(model: model, time: time, at: at, k: k) }

            // the work so far, one line per step, and the line being worked with its boxes
            ForEach(Array(model.workSteps.enumerated()), id: \.element) { row, i in
                let a = l.steps[i].answer!
                Group {
                    if i == l.index {
                        MathLineView(line: a.prompt, size: 28, boxes: BoxState(typed: l.typed, active: l.active, select: model.select))
                    } else {
                        MathLineView(line: a.work, size: 28)
                    }
                }
                .frame(height: 40)
                .pinned(at(0, StepsModel.workTop + Double(row) * StepsModel.row), .topLeading, k)
            }

            if let m = model.message {
                Text(m.text).font(Typeface.font(17, .medium)).foregroundStyle(m.kind == .wrong ? model.chapter.color : Ink.ink).fixedSize()
                    .pinned(at(0, model.toolsY - 40), .topLeading, k)
            }

            HStack(spacing: -1.5) {
                if l.step.answer != nil {
                    CellButton(action: model.showMe) { Icon(name: "play") }
                    CellButton(action: model.reset) { Icon(name: "arrow-counter-clockwise") }
                    Color.clear.frame(width: 40, height: 40)
                }
                MainCellButton(title: l.words.action, action: model.go)
            }
            .opacity(shown)
            .pinned(at(0, model.toolsY), .topLeading, k)

            if l.step.answer != nil {
                Keypad(type: model.type).pinned(at(StepsModel.keypadX, StepsModel.workTop), .topLeading, k)
            }

            LessonHeader(title: l.spec.title, subtitle: "\(model.chapter.title) · Lesson \(String(format: "%02d", model.number))", top: top, onBack: onBack)
        }
    }
}

/// What the answer boxes in a line hold, and which one the keypad types into.
struct BoxState {
    let typed: [String: String]
    let active: String?
    let select: (String) -> Void
}

/// A line of math written on the paper. Answer boxes are cell blocks; a fraction is stacked over its bar.
struct MathLineView: View {
    let line: MathLine
    let size: CGFloat
    var boxes: BoxState?

    var body: some View {
        HStack(alignment: .center, spacing: size * 0.3) { ForEach(Array(line.enumerated()), id: \.offset) { piece($0.element) } }
            .fixedSize()
    }

    private func piece(_ m: Math) -> AnyView {
        switch m {
        case .num(let x): return AnyView(Text(fmt(x)).font(Typeface.font(size, .medium)).monospacedDigit().foregroundStyle(Ink.ink))
        case .op(let o): return AnyView(Text(o).font(Typeface.font(size, .regular)).foregroundStyle(Ink.ink))
        case .text(let t): return AnyView(Text(t).font(Typeface.font(size * 0.7)).foregroundStyle(Ink.ink2))
        case .box(let id): return AnyView(box(id))
        case .frac(let a, let b):
            return AnyView(VStack(spacing: 2) {
                MathLineView(line: [a], size: size * 0.8, boxes: boxes)
                Rectangle().fill(Ink.ink).frame(height: 1.5)
                MathLineView(line: [b], size: size * 0.8, boxes: boxes)
            }.fixedSize())
        }
    }

    /// A box is two cells tall, and wide enough for what's typed in whole cells, never under four.
    private func box(_ id: String) -> some View {
        let text = boxes?.typed[id] ?? "", on = boxes?.active == id
        let w = max(80, ((CGFloat(text.count) * size * 0.62 + 24) / 20).rounded(.up) * 20)
        return Button { boxes?.select(id) } label: {
            Text(text.replacingOccurrences(of: "-", with: "−")).font(Typeface.font(size, .medium)).monospacedDigit().foregroundStyle(Ink.ink)
                .frame(width: w, height: 40)
                .background(Ink.surface)
                .overlay(Rectangle().strokeBorder(on ? Ink.ink : Ink.lineStrong, lineWidth: on ? 2 : 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// The keypad: twelve cell blocks on the paper. Typing a number goes into the box that's selected.
struct Keypad: View {
    let type: (String) -> Void
    var body: some View {
        VStack(spacing: -1.5) {
            ForEach([["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], [".", "0", "del"]], id: \.self) { row in
                HStack(spacing: -1.5) {
                    ForEach(row, id: \.self) { key in
                        CellButton(action: { type(key) }) {
                            if key == "del" { Icon(name: "backspace") }
                            else { Text(key).font(Typeface.font(20, .medium)) }
                        }
                    }
                }
            }
        }
    }
}
