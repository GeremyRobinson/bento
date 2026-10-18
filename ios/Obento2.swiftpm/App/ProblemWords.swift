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

    enum Kind: Equatable { case main, showMe, reset, choice(Int) }
    struct Block { let kind: Kind; let rect: CGRect }

    /// The blocks a problem shows now, in paper points: its choices, and Check (Show me and Start over are in the bar).
    /// The How to plays itself and has none; a solved problem has none.
    static func blocks(_ m: AddFractionsModel) -> [Block] {
        let o = m.origin, l = m.lesson
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double = 40) -> CGRect { CGRect(x: o.x + x, y: o.y + y, width: w, height: h) }
        var out: [Block] = []
        if let choices = l.step.answer?.choices {
            let n = Double(choices.count), w = (column + 1.5 * (n - 1)) / n
            let y = AddFractionsModel.row2 + AddFractionsModel.barHeight + 20
            for i in choices.indices { out.append(Block(kind: .choice(i), rect: R(Double(i) * (w - 1.5), y, w))) }
        }
        if !m.auto && !m.solved { out.append(Block(kind: .main, rect: R(0, actions, 180))) }
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
    let question = Entity(), shown = Entity(), still = Entity(), guide = Entity(), total = Entity(), blocks = Entity()
    var key = ""
    /// Nothing is fading: skipped each frame until something changes.
    var idle = false
    private var faded: [ObjectIdentifier: Double] = [:]

    init() { for e in [question, shown, still, guide, total, blocks] { root.addChild(e) } }

    func fade(_ e: Entity, _ k: Double) {
        let q = snapped(k, 40), id = ObjectIdentifier(e)
        guard faded[id] != q else { return }
        faded[id] = q
        e.isEnabled = q > 0
        if q >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(q))) }
    }

    func clear() { for e in [question, shown, still, guide, total, blocks] { for c in Array(e.children) { c.removeFromParent() } }; faded = [:] }
}

extension Rig {
    /// Every problem's words on the lesson's page (G 17 Oct). Only the problem being worked, or one still animating,
    /// does anything each frame; the rest are still.
    func drawProblemWords(_ page: BarsPage, _ shown: [AddFractionsModel], waiting: [AddFractionsModel], at t: Double) {
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
            w.idle = !m.animating && !m.busy && t - m.wordsAt > 1
        }
        for (id, w) in problemWords where !page.all.contains(where: { $0.id == id }) && !page.problems.contains(where: { $0.id == id }) {
            w.root.removeFromParent(); problemWords[id] = nil
        }
    }

    /// Everything a problem's words show: when it changes, they're made again.
    private func wordsKey(_ m: AddFractionsModel, _ page: BarsPage, dark: Bool) -> String {
        let l = m.lesson
        return [m.label, m.intro ?? "", l.words.say, l.words.hint, l.words.action, "\(l.index)", "\(l.marks.count)", l.typed["c"] ?? "",
                m.message.map { "\($0.text)\($0.ok)" } ?? "", "\(m.solved)", "\(page.current === m)", "\(l.helps)", "\(dark)",
                l.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }.joined()].joined(separator: "|")
    }

    private func build(_ w: ProblemWords, _ m: AddFractionsModel, current: Bool, dark: Bool) {
        w.clear()
        let s = m.problem, l = m.lesson, words = l.words, o = m.origin
        let W = m.wholeWidth, e = m.coverEnd, r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        let ink = colours.ink, ink2 = colours.ink2, ink3 = UIColor(hex: dark ? 0x878177 : 0x8C867D), chapter = UIColor(hex: m.chapter.hex)
        let right = UIColor(hex: dark ? 0x3CCF8E : 0x178A57)
        func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: o.x + x, y: o.y + y) }
        let col = ProblemLayout.column

        // the question, a story running onto more lines upward, and its hint under it
        let q = PaperText.font(28, .medium), hint = PaperText.font(18)
        PaperText.block(m.intro ?? words.say, q, ink, width: col, bottomLeft: P(0, -23), maxLines: 4).forEach { w.question.addChild($0) }
        w.question.addChild(PaperText.label(m.intro != nil ? "Why it works" : words.hint, hint, ink2, at: P(0, -10), anchor: UnitPoint(x: 0, y: 0.5)))

        // what comes in with the picture: the sum, the whole's length, the rows' names; the box's name and its tab
        w.shown.addChild(PaperText.label(s.sum, PaperText.font(40, .medium, digits: true), ink, at: P(0, 60)))
        w.shown.addChild(PaperText.label("1 whole · \(s.wholeCells) cells", PaperText.font(16), ink2, at: P(W / 2, 88), anchor: .bottom))
        w.shown.addChild(PaperText.label(AddFractions.plural(s.a), PaperText.font(17, .medium), ink2, at: P(0, r1 - 8)))
        w.shown.addChild(PaperText.label(AddFractions.plural(s.b), PaperText.font(17, .medium), ink2, at: P(0, r2 - 8)))
        w.shown.addChild(PaperText.label(m.label, PaperText.font(17, .medium), ink3, at: P(0, BarsPage.box.dy + 40), anchor: .topLeading))
        // the map's tab on the box's top-right corner: Now on the problem being worked, Done once it's solved
        if let tag = m.solved && !m.auto ? "Done" : current ? "Now" : nil {
            let r = CGRect(origin: P(BarsPage.box.dx + BarsPage.box.width - 80, BarsPage.box.dy - 20), size: CGSize(width: 80, height: 20))
            if let mesh = Self.fills([r]) { let f = ModelEntity(mesh: mesh, materials: [flat(chapter)]); f.position.y = 0.002; w.shown.addChild(f) }
            w.shown.addChild(PaperText.label(tag, PaperText.font(14, .semibold), .white, at: CGPoint(x: r.midX, y: r.midY), anchor: .center))
        }

        // the piece waiting to be added, and the match once the rows line up
        let mid = PaperText.font(19, .medium), digits = PaperText.font(19, .medium, digits: true), big = PaperText.font(22, .medium, digits: true)
        if l.picture["waiting"] == 1 && l.marked.isEmpty { w.still.addChild(PaperText.label("+ \(s.q)/\(s.b)", digits, ink2, at: P(W + 20, r2 + h + 20), anchor: .topLeading)) }
        if l.picture["match"] == 1 { w.still.addChild(PaperText.label("\(s.p)/\(s.a) = \(s.covered)/\(s.b)", big, chapter, at: P(e + 24, r2 - 12))) }
        if l.picture["guide"] == 1, let look = l.step.look { w.guide.addChild(PaperText.label(look, PaperText.font(16), ink2, at: P(e + 10, r1 - 24))) }

        // under the bars: the count as the child taps, or what a miss says; for a pick-one step the message goes under the choices
        if l.step.answer?.choices != nil {
            if let msg = m.message { PaperText.block(msg.text, mid, chapter, width: col, topLeft: P(0, r2 + h + 80)).forEach { w.still.addChild($0) } }
        } else if let count = l.countLine {
            let (text, c) = m.message.map { ($0.text, $0.ok ? right : chapter) } ?? (count, ink2)
            PaperText.block(text, mid, c, width: col, topLeft: P(0, r2 + h + 20)).forEach { w.still.addChild($0) }
        }
        if l.picture["total"] == 1 { w.total.addChild(PaperText.label("\(s.sum) = \(s.total)/\(s.b)", big, chapter, at: P(0, r2 + h + 40), anchor: .topLeading)) }

        // the blocks: cell blocks on the paper, the main one outlined in ink, a picked choice in the chapter's colour
        let surface = dark ? 0x1B1B1A as UInt32 : 0xFBFBFA, line = UIColor(hex: dark ? 0x3A3A37 : 0xCFCCC5), button = PaperText.font(17, .medium)
        for b in ProblemLayout.blocks(m) {
            var stroke = line, fill = UIColor(hex: surface), text = ink, lift: Float = 0
            switch b.kind {
            case .main: stroke = ink
            case .showMe: if l.picture["showMe"] == 1 { stroke = ink }
            case .choice(let i):
                if l.typed["c"] == String(i) { stroke = chapter; text = chapter; fill = UIColor(hex: Ink.mix(surface, m.chapter.hex, 0.12)); lift = 0.0002 }
            case .reset: break
            }
            cellBlock(b.rect, fill: fill, stroke: stroke, lift: lift).forEach { w.blocks.addChild($0) }
            switch b.kind {
            case .main:
                w.blocks.addChild(PaperText.label(words.action, button, ink, at: CGPoint(x: b.rect.minX + 16, y: b.rect.midY), anchor: UnitPoint(x: 0, y: 0.5)))
                if let a = PaperText.icon("arrow-right", ink, in: CGRect(x: b.rect.maxX - 30, y: b.rect.midY - 10, width: 20, height: 20)) { w.blocks.addChild(a) }
            case .showMe, .reset:
                let r = CGRect(x: b.rect.midX - 10, y: b.rect.midY - 10, width: 20, height: 20)
                if let a = PaperText.icon(b.kind == .showMe ? "play" : "arrow-counter-clockwise", ink, in: r) { w.blocks.addChild(a) }
            case .choice(let i):
                if let c = l.step.answer?.choices?[i] { w.blocks.addChild(PaperText.label(c, button, text, at: CGPoint(x: b.rect.midX, y: b.rect.midY), anchor: .center)) }
            }
        }
    }

    /// A cell block: filled, with its border drawn inside its edge.
    private func cellBlock(_ r: CGRect, fill: UIColor, stroke: UIColor, lift: Float) -> [ModelEntity] {
        let u = Paper.unit
        var out: [ModelEntity] = []
        if let m = Self.fills([r]) { let f = ModelEntity(mesh: m, materials: [flat(fill)]); f.position.y = 0.002 + lift; out.append(f) }
        let i = r.insetBy(dx: 0.75, dy: 0.75)
        let c = [CGPoint(x: i.minX, y: i.minY), CGPoint(x: i.maxX, y: i.minY), CGPoint(x: i.maxX, y: i.maxY), CGPoint(x: i.minX, y: i.maxY), CGPoint(x: i.minX, y: i.minY)]
        let segs = zip(c, c.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) }
        if let m = Self.lines(segs, width: Float(1.5 / u)) { let l = ModelEntity(mesh: m, materials: [flat(stroke)]); l.position.y = 0.0022 + lift; out.append(l) }
        return out
    }
}
