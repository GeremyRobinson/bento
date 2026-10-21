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
            // a tall line (a fraction's boxes) pushes Check down, a square under it (the layout already allows for the
            // tallest line, so this only matters when it doesn't)
            let under = l.lineY + Double(MathLineView.layout(a.prompt, typed: m.lesson.typed, size: 28).h) * Paper.cell * WorkProblem.lineCell + Paper.cell
            y = max(y, (under / Paper.cell).rounded(.up) * Paper.cell)
        }
        return y
    }

    /// A problem answered in its work (G 19 Oct): its box where the number goes, its choices and Check under the work.
    static func inlineBlocks(_ m: WorkProblem) -> [Block] {
        let l = m.lesson, L = m.layout, k = L.scale, o = m.origin
        func A(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: o.x + x, y: o.y + y, width: w, height: h) }
        // a block with a word and its arrow as wide as they need, in whole squares, never narrower than `least`
        func width(_ word: String, _ least: Double) -> Double {
            let w = PaperText.width(word, PaperText.font(Sketch.Words.block.size * k, .medium)) + 60 * k
            return max(least * k, (w / Paper.cell).rounded(.up) * Paper.cell)
        }
        var out: [Block] = []
        var y = L.checkAt.y
        if let choices = l.step.answer?.choices {
            let n = Double(choices.count), w = ((600 * k + 1.5 * (n - 1)) / n).rounded()
            for i in choices.indices { out.append(Block(kind: .choice(i), rect: A(L.checkAt.x + Double(i) * (w - 1.5), y, w, 40 * k))) }
            y += 60 * k
        }
        if let a = l.step.answer, a.choices == nil {
            for b in L.boxes {
                guard let id = b.id ?? a.boxes.first, a.boxes.contains(id) else { continue }
                // half a cell past the column's edge, room for the cursor so it touches nothing
                out.append(Block(kind: .field(id), rect: b.rect(for: l.typed[id] ?? "").offsetBy(dx: o.x, dy: o.y)))
            }
        }
        if !m.auto && !m.solved { out.append(Block(kind: .main, rect: A(L.checkAt.x, y, width(l.words.action, 120), 40 * k))) }
        if !m.auto && m.solved { out.append(Block(kind: .nextProblem, rect: A(L.checkAt.x, y, width("Next problem", 180), 40 * k))) }
        for kind in m.howToButtons {
            switch kind {
            case .next, .practise: out.append(Block(kind: kind, rect: A(L.checkAt.x, y, width(kind == .next ? "Next step" : "Practice", 180), 40 * k)))
            case .again, .skip: out.append(Block(kind: kind, rect: A(L.checkAt.x + 200 * k, y, 160 * k, 40 * k)))
            default: break
            }
        }
        return out
    }

    /// A paper lesson's blocks (G 20 Oct), on their row two squares under what's drawn: its own blocks ("Cut"), a
    /// story's choices (Check on the row under them), Check for a number written in the record, Next problem, the How
    /// to's; and the record's boxes, where they are, to tap into.
    static func stackedBlocks(_ m: WorkProblem) -> [Block] {
        let L = m.layout, o = m.origin, sq = Paper.cell, run = m.ghost?.run ?? m.lesson
        guard let st = L.stack else { return [] }
        // a big problem's blocks are drawn bigger, as its words are (StackPlan.k)
        let k = st.plan.k, left = st.blocksLeft * sq
        func width(_ word: String, _ least: Double) -> Double {
            let w = PaperText.width(word, PaperText.font(Sketch.Words.block.size * k, .medium)) + 60 * k
            return max(least * k, (w / sq).rounded(.up) * sq)
        }
        var out: [Block] = []
        var x = left, y = st.blocksTop * sq
        func add(_ kind: Kind, _ w: Double) { out.append(Block(kind: kind, rect: CGRect(x: o.x + x, y: o.y + y, width: w, height: 2 * sq * k))); x += w + sq * k }
        for a in L.lessonBlocks { add(.action(a), width(a, 120)) }
        if let choices = run.step.answer?.choices {
            let f = PaperText.font(Sketch.wordSize * k, .medium)
            for (i, c) in choices.enumerated() {
                add(.choice(i), max(140 * k, ((PaperText.width(c, f) + 40 * k) / sq).rounded(.up) * sq))
                // beside a tall picture, in the record's column: one under another
                if st.plan.beside { x = left; y += 3 * sq * k }
            }
            if !st.plan.beside { y += 3 * sq * k }
            x = left
        }
        if let a = run.step.answer, a.choices == nil, !a.byHand {
            for b in L.boxes {
                guard let id = b.id ?? a.boxes.first, a.boxes.contains(id) else { continue }
                out.append(Block(kind: .field(id), rect: b.rect(for: run.typed[id] ?? "").offsetBy(dx: o.x, dy: o.y)))
            }
        }
        if !m.auto, !run.isLast, let a = run.step.answer, !a.byHand { add(.main, width(run.words.action, 120)) }
        if !m.auto, run.isLast { add(.nextProblem, width("Next problem", 180)) }
        for kind in m.howToButtons {
            switch kind {
            case .next, .practise: add(kind, width(kind == .next ? "Next step" : "Practice", 180))
            case .again, .skip: add(kind, width(kind == .again ? "Watch again" : "Skip", 120))
            default: break
            }
        }
        return out
    }

    /// Where the blinking cursor goes in the box being typed into: after the last digit, in a gap of its own.
    static func cursor(_ m: WorkProblem) -> CGRect? {
        let l = m.lesson
        // none while Show me's ghost writes (its faint number is in the box)
        guard !m.auto, !m.solved, m.verdict == nil, m.ghost == nil, let a = l.step.answer, a.choices == nil, let id = l.active ?? a.boxes.first,
              let r = blocks(m).first(where: { $0.kind == .field(id) })?.rect else { return nil }
        let L = m.layout, count = Double((l.typed[id] ?? "").count), b = L.box(for: id, first: a.boxes.first)
        let cell = b?.cell ?? Paper.cell * WorkProblem.lineCell * L.scale
        // a centred box: just after its number, which is written centred as one word in the box as it is now
        // (as big as a big problem writes it)
        func after(_ b: WorkBox) -> Double {
            b.rect(typed: Int(count)).midX + PaperText.width(l.typed[id] ?? "", PaperText.font(Sketch.maths * (L.stack?.plan.k ?? L.scale), .medium, digits: true)) / 2 + 0.1 * b.cell
        }
        let x = L.inline ? m.origin.x + (b.map { $0.pointCursor(l.typed[id] ?? "") ?? ($0.centred ? after($0) : $0.right + 0.22 * cell) } ?? 0)
            : r.minX + cell + count * cell + 0.15 * cell
        return CGRect(x: x, y: r.midY - 0.4 * cell, width: 0, height: 0.8 * cell)
    }

    /// `action`: a paper lesson's own block ("Cut"), running the lesson's code (Hands.actions).
    enum Kind: Equatable { case main, nextProblem, showMe, reset, choice(Int), next, practise, again, skip, field(String), key(String), action(String) }
    struct Block { let kind: Kind; let rect: CGRect }

    /// The blocks a problem shows now, in paper points: its choices, and Check (Show me and Start over are in the bar).
    /// The How to plays itself and has none; a solved problem has none.
    static func blocks(_ m: any PageProblem) -> [Block] {
        if let c = m as? CubesProblem { return c.blocks }
        if let wp = m as? WorkProblem, wp.stacked { return stackedBlocks(wp) }
        if let wp = m as? WorkProblem, wp.layout.inline { return inlineBlocks(wp) }
        let l = m.lesson, wp = m as? WorkProblem
        let o = wp?.contentOrigin ?? m.origin, k = wp?.scale ?? 1, sx = wp?.layout.stepX ?? 0
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double = 40) -> CGRect { CGRect(x: o.x + (sx + x) * k, y: o.y + y * k, width: w * k, height: h * k) }
        var out: [Block] = []
        if let choices = l.step.answer?.choices {
            let n = Double(choices.count), w = (min(column(m), 720) + 1.5 * (n - 1)) / n
            let y = m.underStep
            for i in choices.indices { out.append(Block(kind: .choice(i), rect: R(Double(i) * (w - 1.5), y, w, 40))) }
        }
        // a typed step's answer boxes, where its line is written (MathLineView's cells)
        if let a = l.step.answer, a.choices == nil, m is WorkProblem {
            let lay = MathLineView.layout(a.prompt, typed: l.typed, size: 28), c = Paper.cell
            for it in lay.items { if case .box(let id) = it.kind {
                let c = c * WorkProblem.lineCell
                out.append(Block(kind: .field(id), rect: R(Double(it.col) * c, (wp?.layout.lineY ?? 0) + Double(it.row) * c, Double(it.w) * c, Double(it.h) * c)))
            } }
        }
        // the keypad, once an answer box was tapped: the keys in the order a keypad has them
        // (the drawn keypad is put away for now: the iPad's own keyboard types, G 19 Oct)
        if let wp, wp.keypadOpen, !m.solved, let a = l.step.answer, a.choices == nil, WorkProblem.drawnKeys {
            let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "del"], size = 60.0, lay = wp.layout
            // clear of the line being worked: on the first block line past its end (it's written big, and grows)
            let lineEnd = sx + Double(MathLineView.layout(a.prompt, typed: l.typed, size: 28).w) * Paper.cell * WorkProblem.lineCell
            let kx = max(lay.keypadX, ((lineEnd + Paper.cell) / Paper.unit).rounded(.up) * Paper.unit)
            for (i, key) in keys.enumerated() {
                out.append(Block(kind: .key(key), rect: R(kx - sx + Double(i % 3) * size, lay.keypadY + Double(i / 3) * size, size, size)))
            }
        }
        let actions = actions(m), column = column(m)
        if !m.auto && !m.solved { out.append(Block(kind: .main, rect: R(0, actions, 120, 40))) }
        if !m.auto && m.solved { out.append(Block(kind: .nextProblem, rect: R(0, actions, 180, 40))) }
        // the How to: its main block where Check sits, the other on the column's right
        for k in m.howToButtons {
            switch k {
            case .next, .practise: out.append(Block(kind: k, rect: R(0, actions, 180, 40)))
            case .again, .skip: out.append(Block(kind: k, rect: R(column - 160, actions, 160, 40)))
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
        s.text("sum:\(p.sum)", p.sum, at: P(0, sumY), size: Sketch.maths, anchor: UnitPoint(x: 0, y: 0.5))
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
        s.label("whole", "1 whole · \(p.wholeCells) cells", Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2), at: P(W / 2, AddFractionsModel.wholeY - 12), anchor: UnitPoint(x: 0.5, y: 1))
        s.label("row1", AddFractions.plural(p.a), Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), at: P(0, r1 - 8))
        s.label("row2", AddFractions.plural(p.b), Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), at: P(0, r2 - 8))

        // the piece waiting to be added, the match once the rows line up, and the guide after a miss
        if l.picture["waiting"] == 1 && l.marked.isEmpty { s.label("waiting", "+ \(p.q)/\(p.b)", Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), at: P(W + 20, r2 + h + 20), anchor: UnitPoint(x: 0, y: 0)) }
        if l.picture["match"] == 1 { s.label("match", "\(p.p)/\(p.a) = \(p.covered)/\(p.b)", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: chapter), at: P(e + 24, r2 - 12)) }
        if l.picture["guide"] == 1, let look = l.step.look { s.label("guide", look, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2), at: P(e + 10, r1 - 24)) }

        // the step, under the picture: what to do now, and its hint (a story's step asks only "Pick what to do")
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let said = s.words("say\(l.index)", say, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink), x: o.x, top: P(0, AddFractionsModel.stepY).y, width: col, max: 3)
        if m.intro == nil && !storyStep { s.words("hint\(l.index)", words.hint, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2), x: o.x, top: P(0, AddFractionsModel.stepY + Double(said) * Sketch.row).y, width: col) }

        // under the bars: the count as the child taps, or what a miss says; for a pick-one step the message goes under
        // the choices
        let under = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
        if l.step.answer?.choices != nil {
            if let msg = m.message { s.words("msg", msg.text, under.colour(msg.ok ? .ink2 : red), x: o.x, top: P(0, AddFractionsModel.underStep + 52).y, width: col, max: 3) }
        } else if let count = l.countLine {
            let (text, c): (String, Sketch.Colour) = m.message.map { ($0.text, $0.ok ? right : red) } ?? (count, .ink2)
            s.words("count", text, under.colour(c), x: o.x, top: P(0, AddFractionsModel.underStep).y, width: col, max: 3)
        }
        if l.picture["total"] == 1 { s.label("total", "\(p.sum) = \(p.total)/\(p.b)", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: chapter), at: P(0, r2 + h + 32), anchor: UnitPoint(x: 0, y: 0)) }

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
            case .choice(let n): s.block(id, r, l.typed["c"] == String(n) ? .picked : .plain, centred: l.step.answer?.choices?[n], size: Sketch.wordSize)
            case .field, .key, .action: break
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
        if part, lay.inline {
            // answered in the work: the problem is written once, in the work; only a story is told over it
            if l.story, let story = l.spec.story?(l.numbers) {
                s.words("story", story, .story, x: o.x, top: o.y - Sketch.row * k * 2, width: max(600, lay.total * k), max: 2, k: k)
            }
            return s
        }
        if part {
            // its name, then the sum starting on the same left edge, and the story beside it when it's told as one
            let width = s.sum("sum", l.spec.display(l.numbers), at: P(0, WorkProblem.problemY), k: k)
            if l.story, let story = l.spec.story?(l.numbers) {
                let x = P(0, 0).x + width + 2 * row * k
                s.words("story", story, .story, x: x, top: P(0, WorkProblem.problemY).y, width: max(400, o.x + lay.total * k - x), max: 2, k: k)
            }
            return s
        }

        // the solving area draws in quickly (G 19 Oct): the picture is the calm part
        s.pace = 0.4
        let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E), green = Sketch.Colour.hex(0x178A57, 0x3CCF8E)
        // the step: what to do now (a story's step asks only "Pick what to do"), and the hint under it; answered in the
        // work, what to do sits beside the box
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let sayX = lay.inline ? o.x + lay.sayAt.x : P(sx, 0).x, sayTop = lay.inline ? o.y + lay.sayAt.y : P(0, lay.stepY).y
        let said = s.words("say\(l.index)", say, .say, x: sayX, top: sayTop, width: lay.inline ? max(lay.sayWidth, 300) : col, max: m.intro != nil ? 5 : 2, k: k)
        // the hint: always when done together; on their own only after a miss; on a step missed before, what they
        // were told then, in the chapter's colour; never in a test
        if m.intro == nil, !storyStep, l.step.answer?.choices == nil {
            // only after a miss (G 19 Oct: no text that isn't needed); the picture lights what to look at
            // said once (G 20 Oct): not again when what a miss says (or the hint) already has it; grey, as colour is the maths'
            let (text, c): (String?, Sketch.Colour) = m.onFocus ? (m.focus?.said, .ink2) : (l.helps && l.misses > 0) ? (words.hint, .ink2) : (nil, .ink2)
            if let text, !text.isEmpty, !(m.message?.text.contains(text) ?? false) { s.words("hint\(l.index)", text, Sketch.Words.hint.colour(c), x: sayX, top: sayTop + Double(said) * row * k, width: lay.inline ? max(lay.sayWidth, 300) : col, k: k) }
        }
        // the line being worked, a digit to a square, its boxes drawn as blocks
        if let a = l.step.answer, a.choices == nil, m.intro == nil, !lay.inline {
            s.mathLine("line\(l.index)", a.prompt, at: P(sx, lay.lineY), typed: l.typed, size: Sketch.maths * k, cell: Paper.cell * WorkProblem.lineCell * k)
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
            case .choice(let n): s.block(id, r, l.typed["c"] == String(n) ? .picked : .plain, centred: l.step.answer?.choices?[n], size: Sketch.wordSize, k: k)
            case .field(let f):
                // right: green for a moment; wrong: red until they type again; the box being typed into has a cursor
                // after what's in it (steady: no looping animations); Show me's number written faintly, then gone
                let shown = m.ghost?.run ?? l, faint = m.ghost?.mode == .preview
                let typed = shown.typed[f]?.replacingOccurrences(of: "-", with: "−")
                var style: Sketch.Block = m.verdict.map { $0.right ? Sketch.Block(stroke: green, text: green) : Sketch.Block(stroke: red, text: red) }
                    ?? (l.active == f ? .main : lay.inline ? Sketch.Block(stroke: .ink3) : .plain)
                if faint { style.text = .ink3 }
                s.block(id + "\(m.verdict.map { $0.right } as Bool?)", r, style, k: k, grows: true)
                // what's typed, and the cursor, show at once, as any text box does
                s.pace = 0
                // a digit to a square, from a square in: the same square of space each side however many are typed,
                // and what's typed stays put as the box widens to the right
                let wb = lay.box(for: f, first: l.step.answer?.boxes.first)
                let cell = wb?.cell ?? Paper.cell * WorkProblem.lineCell * k, chars = Array(typed ?? "")
                // in the work, digits fill the cells from the right, so their places line up with the rows above
                let left = lay.inline ? (wb?.right ?? r.maxX) + m.origin.x - Double(chars.count) * cell : r.minX + cell
                let tag = "\(m.verdict.map { $0.right } as Bool?)\(faint)"
                if let wb, wb.centred, let typed, !typed.isEmpty {
                    s.text("\(id)typed\(typed)\(tag)", typed, at: CGPoint(x: wb.right - Double(wb.cells) * cell / 2 + m.origin.x, y: r.midY), size: Sketch.maths * k, weight: .medium, style.text)
                }
                for (j, ch) in chars.enumerated() where wb?.centred != true {
                    s.text("\(id)typed\(j)\(ch)\(tag)", String(ch), at: CGPoint(x: left + (Double(j) + 0.5) * cell, y: r.midY), size: Sketch.maths * k, weight: .medium, style.text)
                }
                s.pace = 0.4
            case .key(let key): s.block(id, r, .plain, centred: key == "del" ? nil : key, icon: key == "del" ? "backspace" : nil, k: k)
            case .action(let name): s.block(id, r, .main, word: name, arrow: true, k: k)
            }
        }

        // what a miss (or Show me) says: beside Check on its row, or under it
        if let msg = m.message {
            let ay = ProblemLayout.actions(m)
            var (x, y, width) = lay.messageBelow ? (sx, ay + 4 * Paper.cell, col) : (sx + 280, ay, col - 280 * k)
            if lay.inline { x = lay.checkAt.x / k; y = (lay.checkAt.y + 60 * k) / k; width = 600 * k }
            s.words("msg", msg.text, Sketch.Words.message.colour(msg.ok ? .ink2 : red), x: P(x, 0).x, top: P(0, y).y, width: width, max: 3, k: k)
        }
        return s
    }

}

extension Rig {
    /// A paper lesson's still drawing (G 20 Oct, design/README.md): the story told once, what to do, what a miss says or
    /// the hint, the picture, the record, and the blocks with the record's boxes and what's typed in them. It's rebuilt
    /// when any of that changes, never as a hand moves (its live parts are stackedLive's).
    func stackedStill(_ m: WorkProblem) -> Sketch {
        var s = Sketch()
        guard let paper = m.paper, let st = m.layout.stack else { return s }
        let o = m.origin, sq = Paper.cell, plan = st.plan, width = plan.width * sq, l = m.lesson, k = plan.k
        let view = m.state(), d = paper.draw(view)
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x * sq, y: o.y + y * sq) }
        // the words draw in quickly (the solving area), the picture calmly
        s.pace = 0.4
        if l.story, let story = l.spec.story?(l.numbers) {
            s.words("story", story, .tell, x: o.x, top: o.y, width: width, max: max(1, plan.storyRows), k: k)
        }
        // what to do (a story's pick asks only "Pick what to do"; the How to says its own)
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? l.words.hint : l.words.say)
        s.words("say\(l.index)", say, .say, x: o.x, top: o.y + plan.sayTop * sq, width: width, max: max(plan.sayRows, m.intro != nil ? 3 : 1), k: k)
        // rows 3–4: what a miss says, or the hint
        if let w = m.rowsWords {
            s.words("note", w.text, Sketch.Words.note.colour(w.colour), x: o.x, top: o.y + plan.msgTop * sq, width: width, max: plan.msgRows, k: k)
        }
        s.append(d.picture.transformed(to: P(0, plan.pictureTop), scale: 1))
        s.append(d.record.transformed(to: P(plan.recordLeft, plan.recordTop), scale: 1))
        let green = Sketch.Colour.hex(0x178A57, 0x3CCF8E), red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
        for b in ProblemLayout.blocks(m) {
            let r = b.rect, id = "\(b.kind)"
            switch b.kind {
            case .action(let name): s.block(id, r, .main, word: name, arrow: true, k: k)
            case .next: s.block(id, r, .main, word: "Next step", arrow: true, k: k)
            case .practise: s.block(id, r, .main, word: "Practice", arrow: true, k: k)
            case .nextProblem: s.block(id, r, .main, word: "Next problem", arrow: true, k: k)
            case .main: s.block(id, r, .main, word: view.run.words.action, arrow: true, k: k)
            case .again: s.block(id, r, .plain, word: "Watch again", k: k)
            case .skip: s.block(id, r, .plain, word: "Skip", k: k)
            case .choice(let n): s.block(id, r, view.run.typed["c"] == String(n) ? .picked : .plain, centred: view.run.step.answer?.choices?[n], size: Sketch.wordSize, k: k)
            case .field(let f):
                // right: green for a moment; wrong: red until they type again; the box being typed into is outlined
                // in ink; the ghost's number written faintly (Show me), and gone again when it's over
                let style: Sketch.Block = view.verdict.map { $0 ? Sketch.Block(stroke: green, text: green) : Sketch.Block(stroke: red, text: red) }
                    ?? (view.active == f ? .main : Sketch.Block(stroke: .ink3))
                s.block(id + "\(view.verdict as Bool?)", r, style, k: k, grows: true)
                // what the child types shows at once, as in any box; the ghost's number (Show me) writes itself in
                // faintly and fades when it's over
                s.pace = view.faint ? 0.6 : 0
                let typed = view.typed[f]?.replacingOccurrences(of: "-", with: "−") ?? ""
                let wb = m.layout.box(for: f, first: view.step.answer?.boxes.first), cell = wb?.cell ?? 2 * sq
                let colour: Sketch.Colour = view.faint ? .ink3 : style.text, tag = "\(view.verdict as Bool?)\(view.faint)"
                if let wb, wb.point != nil {
                    // a sum in columns: lined up on the point, which is written on its line as the record's points are
                    for (j, c) in wb.placed(typed).enumerated() {
                        let at = CGPoint(x: o.x + c.x, y: r.midY)
                        if c.ch == "." { s.text("\(id)typed\(j).\(tag)", ".", at: at, size: Sketch.maths * k, weight: .bold, colour, anchor: UnitPoint(x: 0.5, y: 0.49)) }
                        else { s.text("\(id)typed\(j)\(c.ch)\(tag)", String(c.ch), at: at, size: Sketch.maths * k, weight: .medium, colour) }
                    }
                } else if let wb, wb.centred {
                    // in the middle of the box as it is now (one that keeps its left edge has grown to the right)
                    if !typed.isEmpty { s.text("\(id)typed\(typed)\(tag)", typed, at: CGPoint(x: r.midX, y: r.midY), size: Sketch.maths * k, weight: .medium, colour) }
                } else {
                    // a digit to a cell, from the right, so places line up with the record's
                    let chars = Array(typed), left = (wb?.right ?? r.maxX - o.x) + o.x - Double(chars.count) * cell
                    for (j, ch) in chars.enumerated() {
                        s.text("\(id)typed\(j)\(ch)\(tag)", String(ch), at: CGPoint(x: left + (Double(j) + 0.5) * cell, y: r.midY), size: Sketch.maths * k, weight: .medium, colour)
                    }
                }
                s.pace = 0.4
            case .showMe, .reset, .key: break
            }
        }
        return s
    }

    /// A paper lesson's live parts (G 20 Oct): what follows the hand (a point, the ruler and the cuts it would make,
    /// pieces being slid) and the ghost finger, drawn at once as they move (their drawer neither draws in nor glides).
    func stackedLive(_ m: WorkProblem, at t: Double) -> Sketch {
        var s = Sketch()
        guard let paper = m.paper, let st = m.layout.stack, m.instant || t >= m.openedAt + 0.9 else { return s }
        // the finger first, so what it moves shows over it (as big as a big problem's words, so it shows as far back)
        if let f = m.ghostFinger(at: t) { s.ghostFinger("ghost", at: f.at, down: f.down, trail: f.trail, shows: f.shows, size: st.plan.k) }
        let d = paper.draw(m.state(at: t))
        s.append(d.live.transformed(to: CGPoint(x: m.origin.x, y: m.origin.y + st.plan.pictureTop * Paper.cell), scale: 1))
        return s
    }

    /// What the still drawing reads: when it changes, it's rebuilt (only what's new drawing in).
    func stackedStillKey(_ m: WorkProblem, _ page: BarsPage, dark: Bool) -> String {
        let s = m.state(), l = m.lesson
        return ["\(l.numbers)", "\(l.story)", "\(l.index)", "\(s.index)", "\(l.isLast)",
                s.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined(), m.stillHand(s.hand),
                s.typed.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ","), "\(s.faint)", s.active ?? "",
                "\(s.verdict as Bool?)", m.rowsWords.map { "\($0.text)\($0.colour)" } ?? "", m.intro ?? "", "\(m.howToButtons)",
                "\(l.helps)", "\(dark)", "\(page.current === m)"].joined(separator: "|")
    }

    /// What the live parts read: the hand, the step, and the ghost finger where it is now.
    func stackedLiveKey(_ m: WorkProblem, at t: Double, dark: Bool) -> String {
        let s = m.state(at: t), early = !m.instant && t < m.openedAt + 0.9
        let finger = m.ghostFinger(at: t).map { "\(Int($0.at.x)),\(Int($0.at.y)) \($0.down) \($0.trail.map { "\(Int($0.x)),\(Int($0.y))" }) \(Int($0.shows * 20))" } ?? ""
        return ["\(early)", "\(s.index)", s.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined(),
                s.hand.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined(), finger, "\(dark)"].joined(separator: "|")
    }
}
