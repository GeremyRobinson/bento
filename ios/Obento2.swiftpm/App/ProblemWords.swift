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
        var y = l.actions ?? (BarsPage.box.dy + l.height * Paper.unit - 100)
        if let a = m.lesson.step.answer, a.choices == nil {
            // a tall line (a fraction's boxes) pushes Check down, a whole row at a time
            let under = l.lineY + Double(MathLineView.layout(a.prompt, typed: m.lesson.typed, size: 28).h) * Paper.cell + 2 * Paper.cell
            y = max(y, (under / (2 * Paper.cell)).rounded(.up) * 2 * Paper.cell)
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

/// One problem's words and blocks in the paper's scene. Rebuilt only when what it says changes; each frame only the
/// fades move, and a problem with nothing moving costs nothing.
@MainActor
final class ProblemWords {
    let root = Entity()
    /// The question and its hint (they fade and rise in with each new step), the words that come in with the picture,
    /// the guide's note, the total, and the blocks.
    let question = Entity(), shown = Entity(), still = Entity(), guide = Entity(), total = Entity(), blocks = Entity(), keys = Entity()
    var key = ""
    /// Nothing is fading: skipped each frame until something changes.
    var idle = false
    private var faded: [ObjectIdentifier: Double] = [:]

    init() { for e in [question, shown, still, guide, total, blocks, keys] { root.addChild(e) } }

    func fade(_ e: Entity, _ k: Double) {
        let q = snapped(k, 40), id = ObjectIdentifier(e)
        guard faded[id] != q else { return }
        faded[id] = q
        e.isEnabled = q > 0
        if q >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(q))) }
    }

    func clear() { for e in [question, shown, still, guide, total, blocks, keys] { for c in Array(e.children) { c.removeFromParent() } }; faded = [:] }
}

extension Rig {
    /// Every problem's words on the lesson's page (G 17 Oct). Only the problem being worked, or one still animating,
    /// does anything each frame; the rest are still.
    func drawProblemWords(_ page: BarsPage, _ shown: [any PageProblem], waiting: [any PageProblem], at t: Double) {
        let isDark = dark ?? false
        // the problems still to come have their words made one a frame while the How to plays, kept hidden
        if let m = waiting.first(where: { problemWords[$0.id] == nil }) {
            let w = ProblemWords(); pageWords.addChild(w.root); problemWords[m.id] = w
            w.root.isEnabled = false
            w.key = wordsKey(m, page, dark: isDark); build(w, m, current: false, dark: isDark)
        }
        // a page that opens makes its problems' words two at a time, a frame apart, so opening doesn't stall:
        // the problems draw themselves in one after another anyway
        var made = 0, pending = false
        defer { if pending || waiting.contains(where: { problemWords[$0.id] == nil }) { pageBuilding = true } }
        for m in shown {
            let w = problemWords[m.id] ?? { let w = ProblemWords(); pageWords.addChild(w.root); problemWords[m.id] = w; return w }()
            w.root.isEnabled = true
            let key = wordsKey(m, page, dark: isDark)
            if key != w.key {
                if w.key.isEmpty && made >= 2 { pending = true; continue }
                made += 1
                w.key = key; w.idle = false; build(w, m, current: page.current === m, dark: isDark)
            }
            if w.idle && !m.animating && !m.busy { continue }
            let s = m.words(at: t), gone = m.gone(at: t), fresh = ease((t - m.wordsAt) / 0.5) * gone
            w.fade(w.question, fresh)
            w.question.position.z = Float((1 - fresh) * 8 / Paper.unit)
            w.fade(w.shown, s)
            w.fade(w.still, s)
            w.fade(w.guide, m.guide(at: t) * gone)
            w.fade(w.total, ease((t - m.wordsAt - 0.5) / 0.4) * gone)
            w.fade(w.blocks, m.busy ? 0.35 * s : s)
            if let wp = m as? WorkProblem {
                for (i, e) in w.keys.children.enumerated() { w.fade(e, ease((t - wp.keypadAt - Double(i) * 0.03) / 0.3) * gone) }
            }
            w.idle = !m.animating && !m.busy && t - m.wordsAt > 1
        }
        for (id, w) in problemWords where !page.all.contains(where: { $0.id == id }) && !page.problems.contains(where: { $0.id == id }) {
            w.root.removeFromParent(); problemWords[id] = nil
        }
    }

    /// Everything a problem's words show: when it changes, they're made again.
    private func wordsKey(_ m: any PageProblem, _ page: BarsPage, dark: Bool) -> String {
        let l = m.lesson
        return [l.typed.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: ","), l.active ?? "", m.label, m.intro ?? "", "\(m.howToButtons)", l.words.say, l.words.hint, l.words.action, "\(l.index)", "\(l.marks.count)", l.typed["c"] ?? "",
                m.message.map { "\($0.text)\($0.ok)" } ?? "", "\(m.solved)", "\((m as? WorkProblem)?.keypadOpen ?? false)", "\(page.current === m)", "\(l.helps)", "\(dark)",
                l.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()].joined(separator: "|")
    }

    private func build(_ w: ProblemWords, _ m: any PageProblem, current: Bool, dark: Bool) {
        w.clear()
        if let a = m as? AddFractionsModel { buildBars(w, a, current: current, dark: dark) }
        if let wp = m as? WorkProblem { buildWork(w, wp, current: current, dark: dark) }
        addTag(w, m, current: current)
        addBlocks(w, m, dark: dark)
    }

    /// The box's name at its top, and the map's tab on its top-right corner: Now on the problem being worked, Done once
    /// it's solved.
    /// The problem's name over it. The open problem has no frame and no tab (G 19 Oct): Done and Now live on its card.
    private func addTag(_ w: ProblemWords, _ m: any PageProblem, current: Bool) {
        let (o, k) = (m as? WorkProblem).map { ($0.contentOrigin, $0.scale) } ?? (m.origin, 1)
        w.shown.addChild(PaperText.label(m.label, PaperText.font(17 * k, .medium), UIColor(hex: (dark ?? false) ? 0x878177 : 0x8C867D),
                                         at: CGPoint(x: o.x, y: o.y + (BarsPage.box.dy + 40) * k), anchor: .topLeading))
    }

    private func buildBars(_ w: ProblemWords, _ m: AddFractionsModel, current: Bool, dark: Bool) {
        let s = m.problem, l = m.lesson, words = l.words, o = m.origin
        let W = m.wholeWidth, e = m.coverEnd, r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        let ink = colours.ink, ink2 = colours.ink2, ink3 = UIColor(hex: dark ? 0x878177 : 0x8C867D), chapter = UIColor(hex: m.chapter.hex)
        let right = UIColor(hex: dark ? 0x3CCF8E : 0x178A57)
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        let col = ProblemLayout.column

        // the step, under the picture: what to do now, and its hint. A story's step is the question about it ("Which
        // operation solves it?"), since the story itself is the problem, at the top
        let storyStep = l.story && l.step.answer?.choices != nil
        let q = PaperText.font(24, .medium), hint = PaperText.font(18), sy = AddFractionsModel.stepY
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let sayLines = PaperText.block(say, q, ink, width: col, topLeft: P(0, sy), maxLines: 3)
        sayLines.forEach { w.question.addChild($0) }
        let hintText = m.intro != nil || storyStep ? "" : words.hint
        w.question.addChild(PaperText.label(hintText, hint, ink2, at: P(0, sy + Double(sayLines.count) * Double(q.lineHeight) + 4), anchor: .topLeading))

        // the problem, at the top: the story when it's told as one, then the sum
        let storyText = l.story ? l.spec.story?(l.numbers) : nil
        var sumBottom = -40.0
        if let storyText {
            let sf = PaperText.font(20), lines = PaperText.wrap(storyText, sf, width: col).prefix(4)
            let top = -124.0
            for (i, line) in lines.enumerated() { w.shown.addChild(PaperText.label(line, sf, ink, at: P(0, top + Double(i) * Double(sf.lineHeight)), anchor: .topLeading)) }
            sumBottom = max(-40, top + Double(lines.count) * Double(sf.lineHeight) + 50)
        }
        let sumFont = PaperText.font(40, .medium, digits: true), sumY = storyText == nil ? -60 : sumBottom
        w.shown.addChild(PaperText.label(s.sum, sumFont, ink, at: P(0, sumY)))
        // the How to writes why the numbers change (G 18 Oct): 3/4 = (3 × 2)/(4 × 2) = 6/8, the × 2 in the cut's colour
        if m.auto, l.picture["match"] == 1 {
            // beside the sum, on its line
            let f = PaperText.font(22, .medium, digits: true), k = s.b / s.a, cy = sumY - Double(sumFont.lineHeight) / 2 + 2, lh = Double(f.lineHeight)
            var x = PaperText.width(s.sum, sumFont) + 36
            func put(_ text: String, _ c: UIColor, _ y: Double) -> Double {
                w.still.addChild(PaperText.label(text, f, c, at: P(x, y), anchor: UnitPoint(x: 0, y: 0.5))); return PaperText.width(text, f)
            }
            func stack(_ top: [(String, UIColor)], _ bottom: [(String, UIColor)]) {
                let tw = top.reduce(0) { $0 + PaperText.width($1.0, f) }, bw = bottom.reduce(0) { $0 + PaperText.width($1.0, f) }, wd = max(tw, bw)
                var tx = x + (wd - tw) / 2; for (t, c) in top { w.still.addChild(PaperText.label(t, f, c, at: P(tx, cy - lh / 2 - 1), anchor: UnitPoint(x: 0, y: 0.5))); tx += PaperText.width(t, f) }
                var bx = x + (wd - bw) / 2; for (t, c) in bottom { w.still.addChild(PaperText.label(t, f, c, at: P(bx, cy + lh / 2 + 1), anchor: UnitPoint(x: 0, y: 0.5))); bx += PaperText.width(t, f) }
                let bar = CGRect(origin: P(x, cy - 0.75), size: CGSize(width: wd, height: 1.5))
                if let mesh = Self.fills([bar]) { let e = ModelEntity(mesh: mesh, materials: [flat(ink)]); e.position.y = 0.0025; w.still.addChild(e) }
                x += wd
            }
            stack([("\(s.p)", ink)], [("\(s.a)", ink)]); x += put(" = ", ink, cy)
            stack([("\(s.p)", ink), (" × \(k)", chapter)], [("\(s.a)", ink), (" × \(k)", chapter)]); x += put(" = ", ink, cy)
            stack([("\(s.covered)", ink)], [("\(s.b)", ink)])
        }
        w.shown.addChild(PaperText.label("1 whole · \(s.wholeCells) cells", PaperText.font(16), ink2, at: P(W / 2, AddFractionsModel.wholeY - 12), anchor: .bottom))
        w.shown.addChild(PaperText.label(AddFractions.plural(s.a), PaperText.font(17, .medium), ink2, at: P(0, r1 - 8)))
        w.shown.addChild(PaperText.label(AddFractions.plural(s.b), PaperText.font(17, .medium), ink2, at: P(0, r2 - 8)))

        // the piece waiting to be added, and the match once the rows line up
        let mid = PaperText.font(19, .medium), digits = PaperText.font(19, .medium, digits: true), big = PaperText.font(22, .medium, digits: true)
        if l.picture["waiting"] == 1 && l.marked.isEmpty { w.still.addChild(PaperText.label("+ \(s.q)/\(s.b)", digits, ink2, at: P(W + 20, r2 + h + 20), anchor: .topLeading)) }
        if l.picture["match"] == 1 { w.still.addChild(PaperText.label("\(s.p)/\(s.a) = \(s.covered)/\(s.b)", big, chapter, at: P(e + 24, r2 - 12))) }
        if l.picture["guide"] == 1, let look = l.step.look { w.guide.addChild(PaperText.label(look, PaperText.font(16), ink2, at: P(e + 10, r1 - 24))) }

        // under the bars: the count as the child taps, or what a miss says; for a pick-one step the message goes under the choices
        if l.step.answer?.choices != nil {
            if let msg = m.message { PaperText.block(msg.text, mid, chapter, width: col, topLeft: P(0, AddFractionsModel.underStep + 52)).forEach { w.still.addChild($0) } }
        } else if let count = l.countLine {
            let (text, c) = m.message.map { ($0.text, $0.ok ? right : chapter) } ?? (count, ink2)
            PaperText.block(text, mid, c, width: col, topLeft: P(0, AddFractionsModel.underStep)).forEach { w.still.addChild($0) }
        }
        if l.picture["total"] == 1 { w.total.addChild(PaperText.label("\(s.sum) = \(s.total)/\(s.b)", big, chapter, at: P(0, r2 + h + 32), anchor: .topLeading)) }

    }

    /// The blocks: cell blocks on the paper, the main one outlined in ink, a picked choice in the chapter's colour,
    /// an answer box with what's typed in it (outlined in ink when it's the one the keypad types into).
    private func addBlocks(_ w: ProblemWords, _ m: any PageProblem, dark: Bool) {
        let l = m.lesson, words = l.words, ink = colours.ink, chapter = UIColor(hex: m.chapter.hex)
        let k = (m as? WorkProblem)?.scale ?? 1
        let surface = dark ? 0x1B1B1A as UInt32 : 0xFBFBFA, line = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5), button = PaperText.font(17 * k, .medium)
        for b in ProblemLayout.blocks(m) {
            var stroke = line, fill = UIColor(hex: surface), text = ink, lift: Float = 0
            switch b.kind {
            case .main, .next, .practise, .nextProblem: stroke = ink
            case .again, .skip: break
            case .showMe: if l.picture["showMe"] == 1 { stroke = ink }
            case .choice(let i):
                if l.typed["c"] == String(i) { stroke = chapter; text = chapter; fill = UIColor(hex: Ink.mix(surface, m.chapter.hex, 0.12)); lift = 0.0002 }
            case .reset: break
            case .field(let id): if l.active == id { stroke = ink }
            case .key: break
            }
            if case .key(let key) = b.kind {
                // each key is its own entity, so the keypad draws in a key at a time
                let e = Entity()
                cellBlock(b.rect, fill: fill, stroke: stroke, lift: lift, width: 1.5 * k).forEach { e.addChild($0) }
                if key == "del" {
                    if let a = PaperText.icon("backspace", ink, in: CGRect(x: b.rect.midX - 13 * k, y: b.rect.midY - 13 * k, width: 26 * k, height: 26 * k)) { e.addChild(a) }
                } else {
                    e.addChild(PaperText.label(key, PaperText.font(30 * k, .medium, digits: true), ink, at: CGPoint(x: b.rect.midX, y: b.rect.midY), anchor: .center))
                }
                w.keys.addChild(e)
                continue
            }
            cellBlock(b.rect, fill: fill, stroke: stroke, lift: lift, width: 1.5 * k).forEach { w.blocks.addChild($0) }
            switch b.kind {
            case .next, .practise, .again, .skip, .nextProblem:
                let word = b.kind == .nextProblem ? "Next problem" : b.kind == .next ? "Next step" : b.kind == .practise ? "Practice" : b.kind == .again ? "Watch again" : "Skip"
                w.blocks.addChild(PaperText.label(word, button, ink, at: CGPoint(x: b.rect.minX + 16 * k, y: b.rect.midY), anchor: UnitPoint(x: 0, y: 0.5)))
                if b.kind == .next || b.kind == .practise || b.kind == .nextProblem, let a = PaperText.icon("arrow-right", ink, in: CGRect(x: b.rect.maxX - 30 * k, y: b.rect.midY - 10 * k, width: 20 * k, height: 20 * k)) { w.blocks.addChild(a) }
            case .main:
                w.blocks.addChild(PaperText.label(words.action, button, ink, at: CGPoint(x: b.rect.minX + 16 * k, y: b.rect.midY), anchor: UnitPoint(x: 0, y: 0.5)))
                if let a = PaperText.icon("arrow-right", ink, in: CGRect(x: b.rect.maxX - 30 * k, y: b.rect.midY - 10 * k, width: 20 * k, height: 20 * k)) { w.blocks.addChild(a) }
            case .showMe, .reset:
                let r = CGRect(x: b.rect.midX - 10 * k, y: b.rect.midY - 10 * k, width: 20 * k, height: 20 * k)
                if let a = PaperText.icon(b.kind == .showMe ? "play" : "arrow-counter-clockwise", ink, in: r) { w.blocks.addChild(a) }
            case .choice(let i):
                if let c = l.step.answer?.choices?[i] { w.blocks.addChild(PaperText.label(c, button, text, at: CGPoint(x: b.rect.midX, y: b.rect.midY), anchor: .center)) }
            case .field(let id):
                if let t = l.typed[id] {
                    w.blocks.addChild(PaperText.label(t.replacingOccurrences(of: "-", with: "−"), PaperText.font(26 * k, .medium, digits: true), ink,
                                                      at: CGPoint(x: b.rect.midX, y: b.rect.midY), anchor: .center, y: 0.0026))
                }
            case .key: break
            }
        }
    }

    /// A lesson worked in typed steps (WorkProblem): the problem at the top (a story, then the sum), the step under
    /// the picture (its words and hint), the line being worked (its boxes are blocks), and what a miss says.
    private func buildWork(_ w: ProblemWords, _ m: WorkProblem, current: Bool, dark: Bool) {
        // on the grid (G 19 Oct): every line of words fills whole rows of squares (two squares tall), every number one
        // square per digit; positions are whole squares from the origin, and a big problem is drawn a whole k times bigger
        let l = m.lesson, words = l.words, o = m.contentOrigin, lay = m.layout, k = lay.scale, col = lay.column * k
        let ink = colours.ink, ink2 = colours.ink2, chapter = UIColor(hex: m.chapter.hex)
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x * k, y: o.y + y * k) }
        func F(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont { PaperText.font(size * k, weight) }
        let row = 2 * Paper.cell, sx = lay.stepX
        /// Words in rows of squares from `top`, each line centred in its row; returns how many rows.
        @discardableResult func rows(_ text: String, _ f: UIFont, _ c: UIColor, x: Double, top: Double, width: Double, max: Int, into e: Entity) -> Int {
            let lines = Array(PaperText.wrap(text, f, width: width).prefix(max))
            for (i, line) in lines.enumerated() { e.addChild(PaperText.label(line, f, c, at: P(x, top + (Double(i) + 0.5) * row), anchor: UnitPoint(x: 0, y: 0.5))) }
            return lines.count
        }

        // the problem: the sum, a digit to every two squares, and the story beside it when it's told as one
        let display = l.spec.display(l.numbers), top = WorkProblem.problemY
        mathLine(display, at: P(0, top), typed: [:], into: w.shown, size: 40 * k, cell: 2 * Paper.cell * k)
        if l.story, let story = l.spec.story?(l.numbers) {
            let x = Double(MathLineView.layout(display, size: 28).w) * 2 * Paper.cell + 2 * row
            rows(story, F(20), ink, x: x, top: top, width: (lay.width * Paper.unit - 80 - x) * k, max: 2, into: w.shown)
        }

        // the step: what to do now (a story's step asks only "Pick what to do"), and the hint under it
        let storyStep = l.story && l.step.answer?.choices != nil
        let say = m.intro ?? (storyStep ? words.hint : words.say)
        let said = rows(say, F(28, .medium), ink, x: sx, top: lay.stepY, width: col, max: m.intro != nil ? 5 : 2, into: w.question)
        // the hint: always when done together; on their own only after a miss; on a step missed before, what they
        // were told then, in the chapter's colour; never in a test
        if m.intro == nil, !storyStep, l.step.answer?.choices == nil {
            let (text, c): (String?, UIColor) = m.onFocus ? (m.focus?.said, chapter) : (l.guided || (l.helps && l.misses > 0)) ? (words.hint, ink2) : (nil, ink2)
            if let text { rows(text, F(20), c, x: sx, top: lay.stepY + Double(said) * row, width: col, max: 1, into: w.question) }
        }

        // the line being worked, a digit to a square, its boxes drawn as blocks
        if let a = l.step.answer, a.choices == nil, m.intro == nil {
            mathLine(a.prompt, at: P(sx, lay.lineY), typed: l.typed, into: w.still, size: 28 * k)
        }
        // what a miss (or Show me) says: beside Check on its row, or under it
        if let msg = m.message {
            let ay = ProblemLayout.actions(m)
            let (x, y, width) = lay.messageBelow ? (sx, ay + row + Paper.cell, col) : (sx + 240, ay, col - 240 * k)
            rows(msg.text, F(20, .medium), msg.ok ? ink2 : chapter, x: x, top: y, width: width, max: 3, into: w.still)
        }
    }

    /// A line of math written on the paper's cells (MathLineView's layout), its boxes left to the blocks.
    func mathLine(_ line: MathLine, at p: CGPoint, typed: [String: String], into e: Entity, size: CGFloat, cell: Double? = nil) {
        // a digit to a square: `cell` is the square's size (the paper's own, unless written bigger)
        let lay = MathLineView.layout(line, typed: typed, size: 28), c = Paper.cell, ink = colours.ink, ink2 = colours.ink2
        let k = (cell ?? Double(size) / 28 * c) / c
        for it in lay.items {
            let x = p.x + Double(it.col) * c * k, y = p.y + Double(it.row) * c * k
            switch it.kind {
            case .char(let ch, _):
                e.addChild(PaperText.label(ch, PaperText.font(size, .medium, digits: true), ink, at: CGPoint(x: x + c * k / 2, y: y + c * k), anchor: .center))
            case .point:
                e.addChild(PaperText.label(".", PaperText.font(size, .bold), ink, at: CGPoint(x: x, y: y + c * k), anchor: .center))
            case .word(let t):
                e.addChild(PaperText.label(t, PaperText.font(size * 0.7), ink2, at: CGPoint(x: x, y: y + c * k), anchor: UnitPoint(x: 0, y: 0.5)))
            case .bar:
                if let m = Self.fills([CGRect(x: x, y: y - 0.75, width: Double(it.w) * c * k, height: 1.5)]) {
                    let b = ModelEntity(mesh: m, materials: [flat(ink)]); b.position.y = 0.0024; e.addChild(b)
                }
            case .box: break
            }
        }
    }

    /// A cell block: filled, with its border drawn inside its edge.
    private func cellBlock(_ r: CGRect, fill: UIColor, stroke: UIColor, lift: Float, width: Double = 1.5) -> [ModelEntity] {
        let u = Paper.unit
        var out: [ModelEntity] = []
        if let m = Self.fills([r]) { let f = ModelEntity(mesh: m, materials: [flat(fill)]); f.position.y = 0.002 + lift; out.append(f) }
        let i = r.insetBy(dx: width / 2, dy: width / 2)
        let c = [CGPoint(x: i.minX, y: i.minY), CGPoint(x: i.maxX, y: i.minY), CGPoint(x: i.maxX, y: i.maxY), CGPoint(x: i.minX, y: i.maxY), CGPoint(x: i.minX, y: i.minY)]
        let segs = zip(c, c.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) }
        if let m = Self.lines(segs, width: Float(width / u)) { let l = ModelEntity(mesh: m, materials: [flat(stroke)]); l.position.y = 0.0022 + lift; out.append(l) }
        return out
    }
}
