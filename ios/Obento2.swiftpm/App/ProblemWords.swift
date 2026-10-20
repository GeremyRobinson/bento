import SwiftUI
import RealityKit

/// Where a problem's words and blocks sit, in paper points from its origin. Drawing and tapping both read this, so what
/// the child sees is exactly what they can press.
@MainActor
enum ProblemLayout {
    /// Everything in a problem lines up in one column, two cells in from each side of its box.
    static let column = BarsPage.box.width - 80
    /// The action row: two cells above the box's bottom.
    static let actions = BarsPage.box.dy + BarsPage.box.height - 80
    /// A problem's own column and action row, from its box (an open problem fills the screen, G 19 Oct).
    /// A problem's own column and action row (before its scale), from its layout.
    static func column(_ m: any PageProblem) -> Double { (m as? WorkProblem)?.layout.column ?? column }
    static func actions(_ m: any PageProblem) -> Double {
        guard let w = m as? WorkProblem else { return actions }
        let l = w.layout
        // under the line being worked when it's tall (a fraction's boxes), else the bottom row
        var y = l.actions ?? (l.lineY + Paper.unit)
        if let a = m.lesson.step.answer, a.choices == nil {
            // a tall line (a fraction's boxes) pushes Check down, to the next block line
            let under = l.lineY + Double(MathLineView.layout(a.prompt, typed: m.lesson.typed, size: 28).h) * Paper.cell + Paper.cell
            y = max(y, (under / Paper.unit).rounded(.up) * Paper.unit)
        }
        return y
    }

    enum Kind: Equatable { case main, nextProblem, showMe, reset, choice(Int), next, practise, again, skip, field(String), key(String) }
    struct Block { let kind: Kind; let rect: CGRect }

    /// The blocks a problem shows now, in paper points: its choices, and Check (Show me and Start over are in the bar).
    /// The How to plays itself and has none; a solved problem has none.
    static func blocks(_ m: any PageProblem) -> [Block] {
        let l = m.lesson, wp = m as? WorkProblem
        let o = wp?.contentOrigin ?? m.origin, k = wp?.scale ?? 1, sx = wp?.layout.stepX ?? 0
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double = 40) -> CGRect { CGRect(x: o.x + (sx + x) * k, y: o.y + y * k, width: w * k, height: h * k) }
        var out: [Block] = []
        if let choices = l.step.answer?.choices {
            let n = Double(choices.count), w = (min(column(m), 720) + 1.5 * (n - 1)) / n
            let y = m.underStep
            for i in choices.indices { out.append(Block(kind: .choice(i), rect: R(Double(i) * (w - 1.5), y, w))) }
        }
        // a typed step's answer boxes, where its line is written (MathLineView's cells)
        if let a = l.step.answer, a.choices == nil, m is WorkProblem {
            let lay = MathLineView.layout(a.prompt, typed: l.typed, size: 28), c = Paper.cell
            for it in lay.items { if case .box(let id) = it.kind {
                out.append(Block(kind: .field(id), rect: R(Double(it.col) * c, (wp?.layout.lineY ?? 0) + Double(it.row) * c, Double(it.w) * c, Double(it.h) * c)))
            } }
        }
        // the keypad, once an answer box was tapped: the keys in the order a keypad has them
        if let wp, wp.keypadOpen, !m.solved, let a = l.step.answer, a.choices == nil {
            let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "del"], size = 60.0, lay = wp.layout
            for (i, key) in keys.enumerated() {
                out.append(Block(kind: .key(key), rect: R(lay.keypadX - sx + Double(i % 3) * size, lay.keypadY + Double(i / 3) * size, size, size)))
            }
        }
        let actions = actions(m), column = column(m)
        if !m.auto && !m.solved { out.append(Block(kind: .main, rect: R(0, actions, 180))) }
        if !m.auto && m.solved { out.append(Block(kind: .nextProblem, rect: R(0, actions, 220))) }
        // the How to: its main block where Check sits, the other on the column's right
        for k in m.howToButtons {
            switch k {
            case .next, .practise: out.append(Block(kind: k, rect: R(0, actions, 220)))
            case .again, .skip: out.append(Block(kind: k, rect: R(column - 180, actions, 180)))
            default: break
            }
        }
        return out
    }
}

extension Rig {
    /// The words and blocks of Add with different bottoms' problems (its bars are BarsDrawer's), drawn from the master
    /// components like every other problem's: rebuilt as a Sketch when what they say changes, only what's new drawing
    /// in, and all of it undrawing as the problem leaves. (A WorkProblem's words are drawn with its picture, drawWork.)
    func drawProblemWords(_ page: BarsPage, _ shown: [any PageProblem], waiting: [any PageProblem], at t: Double) {
        let isDark = dark ?? false
        var moving = false
        for case let m as AddFractionsModel in shown {
            let d = problemWords[m.id] ?? { let d = SketchDrawer(); pageWords.addChild(d.root); problemWords[m.id] = d; return d }()
            if m.leftAt == nil, d.leftAt != nil { d.revive() }
            let key = wordsKey(m, page, dark: isDark)
            // only the problem being worked (or the How to) may draw; anything else undraws
            let wanted = page.mode == .work ? page.current === m : (page.mode == .howTo && m === page.howTo)
            if !wanted { d.undrawAll(at: m.leftAt ?? t) }
            if key != d.key, m.leftAt == nil, wanted {
                d.key = key
                d.build(barsSketch(m), rig: self, chapter: m.chapter.hex, dark: isDark, origin: .zero, from: d.isEmpty ? m.openedAt + 0.4 : max(t, m.wordsAt), now: t)
            }
            if let left = m.leftAt { d.undrawAll(at: left) }
            if d.update(at: t) { moving = true }
        }
        if moving { pageBuilding = true }
        for (id, d) in problemWords where !page.all.contains(where: { $0.id == id }) {
            d.root.removeFromParent(); problemWords[id] = nil
        }
    }

    func wordsKey(_ m: any PageProblem, _ page: BarsPage, dark: Bool) -> String {
        let l = m.lesson
        return [l.typed.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ","), l.active ?? "", m.label, m.intro ?? "", "\(m.howToButtons)", l.words.say, l.words.hint, l.words.action, "\(l.index)", "\(l.marks.count)", l.typed["c"] ?? "",
                m.message.map { "\($0.text)\($0.ok)" } ?? "", "\(m.solved)", "\((m as? WorkProblem)?.keypadOpen ?? false)", "\(((m as? WorkProblem)?.verdict).map { $0.right } as Bool?)", "\(page.current === m)", "\(l.helps)", "\(dark)",
                l.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()].joined(separator: "|")
    }

    /// Add with different bottoms' words and blocks as a Sketch, from the master components: its name, the sum (with
    /// the How to's why beside it), the bars' labels, the step and its hint, the count or what a miss says, the total,
    /// and its blocks.
    func barsSketch(_ m: AddFractionsModel) -> Sketch {
        var s = Sketch()
        let p = m.problem, l = m.lesson, words = l.words, o = m.origin
        let W = m.wholeWidth, e = m.coverEnd, r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        let col = ProblemLayout.column, chapter = Sketch.Colour.chapter, right = Sketch.Colour.hex(0x178A57, 0x3CCF8E), red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
        s.words("name", m.label, .name, x: o.x, top: P(0, BarsPage.box.dy).y, width: col)

        // the problem, at the top: the sum, and the story beside it when it's told as one (as every problem has it)
        let sumFont = PaperText.font(40, .medium, digits: true), sumY = -100 + Sketch.row
        s.text("sum:\(p.sum)", p.sum, at: P(0, sumY), size: 40, anchor: UnitPoint(x: 0, y: 0.5))
        if l.story, let storyText = l.spec.story?(l.numbers) {
            let x = ((PaperText.width(p.sum, sumFont) + 2 * Sketch.row) / Paper.cell).rounded(.up) * Paper.cell
            s.words("story", storyText, .story, x: o.x + x, top: P(0, -100).y, width: col - x, max: 2)
        }
        // the How to writes why the numbers change (G 18 Oct): 3/4 = (3 × 2)/(4 × 2) = 6/8, the × 2 in the cut's colour
        if m.auto, l.picture["match"] == 1 {
            let f = PaperText.font(22, .medium, digits: true), k = p.b / p.a, lh = Double(f.lineHeight)
            var x = PaperText.width(p.sum, sumFont) + 36
            func put(_ id: String, _ text: String) { s.text("why\(id)", text, at: P(x, sumY), size: 22, anchor: UnitPoint(x: 0, y: 0.5)); x += PaperText.width(text, f) }
            func stack(_ id: String, _ top: [(String, Sketch.Colour)], _ bottom: [(String, Sketch.Colour)]) {
                let tw = top.reduce(0) { $0 + PaperText.width($1.0, f) }, bw = bottom.reduce(0) { $0 + PaperText.width($1.0, f) }, wd = max(tw, bw)
                var tx = x + (wd - tw) / 2
                for (j, (t, c)) in top.enumerated() { s.text("why\(id)t\(j)", t, at: P(tx, sumY - lh / 2 - 1), size: 22, c, anchor: UnitPoint(x: 0, y: 0.5)); tx += PaperText.width(t, f) }
                var bx = x + (wd - bw) / 2
                for (j, (t, c)) in bottom.enumerated() { s.text("why\(id)b\(j)", t, at: P(bx, sumY + lh / 2 + 1), size: 22, c, anchor: UnitPoint(x: 0, y: 0.5)); bx += PaperText.width(t, f) }
                s.line("why\(id)bar", [P(x, sumY), P(x + wd, sumY)], .ink, width: 1.5)
                x += wd
            }
            stack("1", [("\(p.p)", .ink)], [("\(p.a)", .ink)]); put("e1", " = ")
            stack("2", [("\(p.p)", .ink), (" × \(k)", chapter)], [("\(p.a)", .ink), (" × \(k)", chapter)]); put("e2", " = ")
            stack("3", [("\(p.covered)", .ink)], [("\(p.b)", .ink)])
        }
        s.label("whole", "1 whole · \(p.wholeCells) cells", Sketch.Words(size: 16, weight: .regular, colour: .ink2), at: P(W / 2, AddFractionsModel.wholeY - 12), anchor: UnitPoint(x: 0.5, y: 1))
        s.label("row1", AddFractions.plural(p.a), Sketch.Words(size: 17, weight: .medium, colour: .ink2), at: P(0, r1 - 8))
        s.label("row2", AddFractions.plural(p.b), Sketch.Words(size: 17, weight: .medium, colour: .ink2), at: P(0, r2 - 8))

        // the piece waiting to be added, the match once the rows line up, and the guide after a miss
        if l.picture["waiting"] == 1 && l.marked.isEmpty { s.label("waiting", "+ \(p.q)/\(p.b)", Sketch.Words(size: 19, weight: .medium, colour: .ink2), at: P(W + 20, r2 + h + 20), anchor: UnitPoint(x: 0, y: 0)) }
        if l.picture["match"] == 1 { s.label("match", "\(p.p)/\(p.a) = \(p.covered)/\(p.b)", Sketch.Words(size: 22, weight: .medium, colour: chapter), at: P(e + 24, r2 - 12)) }
        if l.picture["guide"] == 1, let look = l.step.look { s.label("guide", look, Sketch.Words(size: 16, weight: .regular, colour: .ink2), at: P(e + 10, r1 - 24)) }

        // the step, under the picture: what to do now, and its hint (a story's step asks only "Pick what to do")
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let said = s.words("say\(l.index)", say, Sketch.Words(size: 24, weight: .medium, colour: .ink), x: o.x, top: P(0, AddFractionsModel.stepY).y, width: col, max: 3)
        if m.intro == nil && !storyStep { s.words("hint\(l.index)", words.hint, Sketch.Words(size: 18, weight: .regular, colour: .ink2), x: o.x, top: P(0, AddFractionsModel.stepY + Double(said) * Sketch.row).y, width: col) }

        // under the bars: the count as the child taps, or what a miss says; for a pick-one step the message goes under
        // the choices
        let under = Sketch.Words(size: 19, weight: .medium, colour: .ink2)
        if l.step.answer?.choices != nil {
            if let msg = m.message { s.words("msg", msg.text, under.colour(msg.ok ? .ink2 : red), x: o.x, top: P(0, AddFractionsModel.underStep + 52).y, width: col, max: 3) }
        } else if let count = l.countLine {
            let (text, c): (String, Sketch.Colour) = m.message.map { ($0.text, $0.ok ? right : red) } ?? (count, .ink2)
            s.words("count", text, under.colour(c), x: o.x, top: P(0, AddFractionsModel.underStep).y, width: col, max: 3)
        }
        if l.picture["total"] == 1 { s.label("total", "\(p.sum) = \(p.total)/\(p.b)", Sketch.Words(size: 22, weight: .medium, colour: chapter), at: P(0, r2 + h + 32), anchor: UnitPoint(x: 0, y: 0)) }

        // the blocks
        for b in ProblemLayout.blocks(m) {
            let r = b.rect, id = "\(b.kind)"
            switch b.kind {
            case .next: s.block(id, r, .main, word: "Next step", arrow: true)
            case .practise: s.block(id, r, .main, word: "Practice", arrow: true)
            case .nextProblem: s.block(id, r, .main, word: "Next problem", arrow: true)
            case .main: s.block(id, r, .main, word: words.action, arrow: true)
            case .again: s.block(id, r, .plain, word: "Watch again")
            case .skip: s.block(id, r, .plain, word: "Skip")
            case .showMe, .reset: s.block(id, r, l.picture["showMe"] == 1 && b.kind == .showMe ? .main : .plain, icon: b.kind == .showMe ? "play" : "arrow-counter-clockwise")
            case .choice(let n): s.block(id, r, l.typed["c"] == String(n) ? .picked : .plain, centred: l.step.answer?.choices?[n], size: 17)
            case .field, .key: break
            }
        }
        return s
    }

    /// A WorkProblem's words and blocks as a Sketch, in paper points, on the grid: its name, the sum a digit to every
    /// two squares (the story beside it), the step's words in rows of squares, the line being worked a digit to a
    /// square, what a miss says, and every block (Check, the answer boxes, the keys) as an outline, a fill and its word.
    /// `top`: just its name, the sum and the story (drawn before the picture); else the rest (drawn after it).
    func workSketch(_ m: WorkProblem, top part: Bool) -> Sketch {
        var s = Sketch()
        let l = m.lesson, words = l.words, o = m.contentOrigin, lay = m.layout, k = lay.scale, col = lay.column * k
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x * k, y: o.y + y * k) }
        let row = Sketch.row, sx = lay.stepX
        if part {
            // its name, then the sum starting on the same left edge, and the story beside it when it's told as one
            s.words("name", m.label, .name, x: P(0, 0).x, top: P(0, BarsPage.box.dy).y, width: col, k: k)
            let width = s.sum("sum", l.spec.display(l.numbers), at: P(0, WorkProblem.problemY), k: k)
            if l.story, let story = l.spec.story?(l.numbers) {
                let x = P(0, 0).x + width + 2 * row * k
                s.words("story", story, .story, x: x, top: P(0, WorkProblem.problemY).y, width: o.x + lay.width * Paper.unit * k - 80 * k - x, max: 2, k: k)
            }
            return s
        }

        // the solving area draws in quickly (G 19 Oct): the picture is the calm part
        s.pace = 0.4
        let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E), green = Sketch.Colour.hex(0x178A57, 0x3CCF8E)
        // the step: what to do now (a story's step asks only "Pick what to do"), and the hint under it
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let said = s.words("say\(l.index)", say, .say, x: P(sx, 0).x, top: P(0, lay.stepY).y, width: col, max: m.intro != nil ? 5 : 2, k: k)
        // the hint: always when done together; on their own only after a miss; on a step missed before, what they
        // were told then, in the chapter's colour; never in a test
        if m.intro == nil, !storyStep, l.step.answer?.choices == nil {
            let (text, c): (String?, Sketch.Colour) = m.onFocus ? (m.focus?.said, .chapter) : (l.guided || (l.helps && l.misses > 0)) ? (words.hint, .ink2) : (nil, .ink2)
            if let text { s.words("hint\(l.index)", text, Sketch.Words.hint.colour(c), x: P(sx, 0).x, top: P(0, lay.stepY + Double(said) * row).y, width: col, k: k) }
        }
        // the line being worked, a digit to a square, its boxes drawn as blocks
        if let a = l.step.answer, a.choices == nil, m.intro == nil {
            s.mathLine("line\(l.index)", a.prompt, at: P(sx, lay.lineY), typed: l.typed, size: 28 * k, cell: Paper.cell * k)
        }

        // the blocks
        for b in ProblemLayout.blocks(m) {
            let r = b.rect, id = "\(b.kind)"
            switch b.kind {
            case .next: s.block(id, r, .main, word: "Next step", arrow: true, k: k)
            case .practise: s.block(id, r, .main, word: "Practice", arrow: true, k: k)
            case .nextProblem: s.block(id, r, .main, word: "Next problem", arrow: true, k: k)
            case .main: s.block(id, r, .main, word: words.action, arrow: true, k: k)
            case .again: s.block(id, r, .plain, word: "Watch again", k: k)
            case .skip: s.block(id, r, .plain, word: "Skip", k: k)
            case .showMe, .reset: s.block(id, r, l.picture["showMe"] == 1 && b.kind == .showMe ? .main : .plain, icon: b.kind == .showMe ? "play" : "arrow-counter-clockwise", k: k)
            case .choice(let n): s.block(id, r, l.typed["c"] == String(n) ? .picked : .plain, centred: l.step.answer?.choices?[n], size: 17, k: k)
            case .field(let f):
                // right: green for a moment; wrong: red until they type again; the box being typed into has a cursor
                // after what's in it (steady: no looping animations)
                let typed = l.typed[f]?.replacingOccurrences(of: "-", with: "−")
                let style: Sketch.Block = m.verdict.map { $0.right ? Sketch.Block(stroke: green, text: green) : Sketch.Block(stroke: red, text: red) }
                    ?? (l.active == f ? .main : .plain)
                s.block(id + "\(m.verdict.map { $0.right } as Bool?)", r, style, k: k, grows: true)
                // what's typed, and the cursor, show at once, as any text box does
                s.pace = 0
                // a digit to a square, from a square in: the same square of space each side however many are typed,
                // and what's typed stays put as the box widens to the right
                let left = r.minX + Paper.cell * k, cell = Paper.cell * k, chars = Array(typed ?? "")
                let tag = "\(m.verdict.map { $0.right } as Bool?)"
                for (j, ch) in chars.enumerated() {
                    s.text("\(id)typed\(j)\(ch)\(tag)", String(ch), at: CGPoint(x: left + (Double(j) + 0.5) * cell, y: r.midY), size: 26 * k, weight: .medium, style.text)
                }
                if l.active == f, m.verdict == nil, !m.auto {
                    let x = left + Double(chars.count) * cell
                    s.line("cursor\(typed ?? "")", [CGPoint(x: x, y: r.midY - 12 * k), CGPoint(x: x, y: r.midY + 12 * k)], .ink, width: 2 * k)
                }
                s.pace = 0.4
            case .key(let key): s.block(id, r, .plain, centred: key == "del" ? nil : key, icon: key == "del" ? "backspace" : nil, k: k)
            }
        }

        // what a miss (or Show me) says: beside Check on its row, or under it
        if let msg = m.message {
            let ay = ProblemLayout.actions(m)
            let (x, y, width) = lay.messageBelow ? (sx, ay + row + Paper.cell, col) : (sx + 240, ay, col - 240 * k)
            s.words("msg", msg.text, Sketch.Words.message.colour(msg.ok ? .ink2 : red), x: P(x, 0).x, top: P(0, y).y, width: width, max: 3, k: k)
        }
        return s
    }

}
