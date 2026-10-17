import SwiftUI

/// A lesson worked in steps, on the flat paper: the words, the problem, the finished work, the line being worked
/// with its answer boxes, the keypad and the buttons. Pinned to the paper with the paper's camera.
/// The picture is in the paper's scene (PaperScene), drawn by the lesson's master; its words are added here.
struct StepsLessonView: View {
    let model: StepsModel
    let camera: PaperCamera
    let time: Double

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

            MathLineView(line: l.display, size: 30).opacity(shown).pinned(at(0, 20), .topLeading, k)

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
                .pinned(at(0, model.workY(row)), .topLeading, k)
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

            if let a = l.step.answer {
                Group {
                    if let choices = a.choices {
                        // a pick-one step: the choices are cell blocks where the keypad would be
                        VStack(alignment: .leading, spacing: -1.5) {
                            ForEach(Array(choices.enumerated()), id: \.offset) { i, c in
                                CellButton(width: 180, main: l.typed["c"] == String(i), action: { model.choose(i) }) {
                                    Text(c).font(Typeface.button).frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 16)
                                }
                            }
                        }
                    } else {
                        Keypad(type: model.type)
                    }
                }
                .pinned(at(StepsModel.keypadX, StepsModel.workTop), .topLeading, k)
            }

        }
    }
}

/// What the answer boxes in a line hold, and which one the keypad types into.
struct BoxState {
    let typed: [String: String]
    let active: String?
    let select: (String) -> Void
}

/// A line of math written on the paper's cells, like on graph paper: each digit in its own cell, a sign in a cell with
/// an empty cell either side, an answer box two cells tall and whole cells wide, and a fraction's bar on a grid line.
/// Pinned at a grid point, so everything lands on the grid.
struct MathLineView: View {
    let line: MathLine
    /// Type size; a digit at this size fits one cell.
    var size: CGFloat = 28
    var boxes: BoxState?

    struct Item: Identifiable {
        enum Kind { case char(String, ink: Bool), point, word(String), box(String), bar }
        let id: Int
        let kind: Kind
        /// Position and size, in cells.
        let col: Int, row: Int, w: Int, h: Int
    }

    static let cell = Paper.cell

    /// Lays the line out in cells: its pieces, and its width and height (two cells, or four with a fraction in it).
    static func layout(_ line: MathLine, typed: [String: String] = [:], size: CGFloat) -> (items: [Item], w: Int, h: Int) {
        var items: [Item] = [], col = 0
        let tall = line.contains { if case .frac = $0 { true } else { false } }
        let h = tall ? 4 : 2, mid = tall ? 1 : 0
        func add(_ k: Item.Kind, _ c: Int, _ r: Int, _ w: Int, _ hh: Int) { items.append(Item(id: items.count, kind: k, col: c, row: r, w: w, h: hh)) }
        /// One piece at (col, row); returns its width in cells.
        func place(_ m: Math, _ c: Int, _ r: Int) -> Int {
            switch m {
            case .num(let x):
                // a digit to a cell; the point sits on the line between two digits, as on graph paper
                var i = 0
                for ch in fmt(x) {
                    if ch == "." { add(.point, c + i, r, 0, 2) } else { add(.char(String(ch), ink: true), c + i, r, 1, 2); i += 1 }
                }
                return i
            case .op(let o): add(.char(o, ink: true), c, r, 1, 2); return 1
            case .text(let t):
                let w = cells(t)
                add(.word(t), c, r, w, 2); return w
            case .box(let id):
                let w = max(3, (typed[id] ?? "").count + 2)
                add(.box(id), c, r, w, 2); return w
            case .frac(let a, let b):
                let wa = measure(a), wb = measure(b), w = max(wa, wb)
                _ = place(a, c + (w - wa) / 2, r - 1); _ = place(b, c + (w - wb) / 2, r + 1)
                add(.bar, c, r + 1, w, 0)
                return w
            }
        }
        func measure(_ m: Math) -> Int {
            switch m {
            case .num(let x): fmt(x).filter { $0 != "." }.count
            case .op: 1
            case .text(let t): cells(t)
            case .box(let id): max(3, (typed[id] ?? "").count + 2)
            case .frac(let a, let b): max(measure(a), measure(b))
            }
        }
        func cells(_ t: String) -> Int { Int(((width(t, size * 0.7) + 2) / cell).rounded(.up)) }
        for (i, m) in line.enumerated() {
            if i > 0 { col += 1 }  // an empty cell between pieces
            col += place(m, col, tall ? (isFrac(m) ? 1 : mid) : 0)
        }
        return (items, col, h)
    }

    static func isFrac(_ m: Math) -> Bool { if case .frac = m { true } else { false } }

    static func width(_ t: String, _ size: CGFloat) -> CGFloat {
        var f = UIFont.systemFont(ofSize: size)
        if let d = f.fontDescriptor.withDesign(.rounded) { f = UIFont(descriptor: d, size: size) }
        return (t as NSString).size(withAttributes: [.font: f]).width
    }

    var body: some View {
        let (items, w, h) = Self.layout(line, typed: boxes?.typed ?? [:], size: size), c = Self.cell
        ZStack(alignment: .topLeading) {
            ForEach(items) { it in
                view(it)
                    .frame(width: it.w == 0 && it.h > 0 ? c : CGFloat(it.w) * c, height: max(1.5, CGFloat(it.h) * c))
                    .offset(x: it.w == 0 && it.h > 0 ? -c / 2 : 0)
                    .offset(x: CGFloat(it.col) * c, y: CGFloat(it.row) * c - (it.h == 0 ? 0.75 : 0))
            }
        }
        .frame(width: CGFloat(w) * c, height: CGFloat(h) * c, alignment: .topLeading)
    }

    @ViewBuilder private func view(_ it: Item) -> some View {
        switch it.kind {
        case .char(let ch, _): Text(ch).font(Typeface.font(size, .medium)).monospacedDigit().foregroundStyle(Ink.ink)
        case .point: Text(".").font(Typeface.font(size, .bold)).foregroundStyle(Ink.ink)
        case .word(let t): Text(t).font(Typeface.font(size * 0.7)).foregroundStyle(Ink.ink2).fixedSize()
        case .bar: Rectangle().fill(Ink.ink)
        case .box(let id):
            let text = boxes?.typed[id] ?? "", on = boxes?.active == id
            Button { boxes?.select(id) } label: {
                Text(text.replacingOccurrences(of: "-", with: "−")).font(Typeface.font(size, .medium)).monospacedDigit().foregroundStyle(Ink.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Ink.surface)
                    .overlay(Rectangle().strokeBorder(on ? Ink.ink : Ink.lineStrong, lineWidth: on ? 2 : 1.5))
            }
            .buttonStyle(.plain)
        }
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
