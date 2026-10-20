import SwiftUI
import RealityKit

/// A lesson's picture as plain parts on the paper: lines, filled shapes and words, in points from the picture's
/// top-left (a WorkProblem's origin, its picture's top). Each part has an id: when the picture changes, the parts that
/// are new draw in and the rest stay. Everything sits on the grid's cells, so a lesson builds it in cells (`c`).
@MainActor
struct Sketch {
    /// `hex` is a colour for light and for dark paper.
    enum Colour: Hashable { case ink, ink2, ink3, chapter, tint(Double), paper, line, hex(UInt32, UInt32) }
    enum Kind {
        case line([CGPoint], width: Double, dashed: Bool)
        case fill([CGPoint])
        case text(String, CGPoint, size: CGFloat, weight: UIFont.Weight, anchor: UnitPoint, digits: Bool)
        case icon(String, CGRect)
        /// Many straight lines as one part, stroked on one after another (a grid's lines, with no turns to show).
        case segments([(CGPoint, CGPoint)], width: Double)
        /// A fill that sits over the lines (a label's plate).
        case plate([CGPoint])
        /// A line over plates (a seal's ring or tick).
        case overLine([CGPoint], width: Double)
    }
    struct Item { let id: String; let kind: Kind; let colour: Colour; var at: Double? = nil }
    private(set) var items: [Item] = []
    /// When the parts added from now on start drawing in (a map piece's words with its frame), instead of one after
    /// another from the drawing's start.
    var startAt: Double?
    static let c = Paper.cell

    mutating func line(_ id: String, _ pts: [CGPoint], _ colour: Colour = .ink, width: Double = 2, dashed: Bool = false) {
        add(Item(id: id, kind: .line(pts, width: width, dashed: dashed), colour: colour))
    }
    /// A rectangle's outline.
    mutating func box(_ id: String, _ r: CGRect, _ colour: Colour = .ink, width: Double = 2, dashed: Bool = false) {
        line(id, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)], colour, width: width, dashed: dashed)
    }
    mutating func fill(_ id: String, _ r: CGRect, _ colour: Colour) {
        add(Item(id: id, kind: .fill([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]), colour: colour))
    }
    mutating func polygon(_ id: String, _ pts: [CGPoint], _ colour: Colour) { add(Item(id: id, kind: .fill(pts), colour: colour)) }
    mutating func text(_ id: String, _ s: String, at p: CGPoint, size: CGFloat = 20, weight: UIFont.Weight = .medium, _ colour: Colour = .ink,
                       anchor: UnitPoint = .center, digits: Bool = true) {
        add(Item(id: id, kind: .text(s, p, size: size, weight: weight, anchor: anchor, digits: digits), colour: colour))
    }
    mutating func icon(_ id: String, _ name: String, in r: CGRect, _ colour: Colour = .ink) { add(Item(id: id, kind: .icon(name, r), colour: colour)) }
    mutating func segments(_ id: String, _ segs: [(CGPoint, CGPoint)], _ colour: Colour, width: Double) {
        if !segs.isEmpty { add(Item(id: id, kind: .segments(segs, width: width), colour: colour)) }
    }
    mutating func plate(_ id: String, _ r: CGRect, _ colour: Colour) {
        add(Item(id: id, kind: .plate([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]), colour: colour))
    }
    mutating func overLine(_ id: String, _ pts: [CGPoint], _ colour: Colour = .ink, width: Double = 2) { add(Item(id: id, kind: .overLine(pts, width: width), colour: colour)) }
    /// A shape that sits over the lines (a test's seal on its frame's corner).
    mutating func plate(_ id: String, _ pts: [CGPoint], _ colour: Colour) { add(Item(id: id, kind: .plate(pts), colour: colour)) }
    mutating func append(_ other: Sketch) { items += other.items }
    private mutating func add(_ item: Item) { var it = item; it.at = startAt; items.append(it) }
    /// The same sketch in paper points: moved to `o` and drawn `k` times bigger.
    func transformed(to o: CGPoint, scale k: Double) -> Sketch {
        func P(_ p: CGPoint) -> CGPoint { CGPoint(x: o.x + p.x * k, y: o.y + p.y * k) }
        var out = Sketch()
        out.items = items.map { it in
            let kind: Kind
            switch it.kind {
            case .line(let pts, let w, let d): kind = .line(pts.map(P), width: w * k, dashed: d)
            case .fill(let pts): kind = .fill(pts.map(P))
            case .plate(let pts): kind = .plate(pts.map(P))
            case .overLine(let pts, let w): kind = .overLine(pts.map(P), width: w * k)
            case .text(let s, let p, let size, let weight, let anchor, let digits): kind = .text(s, P(p), size: size * k, weight: weight, anchor: anchor, digits: digits)
            case .icon(let n, let r): kind = .icon(n, CGRect(origin: P(r.origin), size: CGSize(width: r.width * k, height: r.height * k)))
            case .segments(let segs, let w): kind = .segments(segs.map { (P($0.0), P($0.1)) }, width: w * k)
            }
            return Item(id: it.id, kind: kind, colour: it.colour, at: it.at)
        }
        return out
    }
    /// A fraction written on the paper: top over bottom with its bar, centred on `p`.
    mutating func fraction(_ id: String, _ top: String, _ bottom: String, at p: CGPoint, size: CGFloat = 22, _ colour: Colour = .ink) {
        let w = max(PaperText.width(top, PaperText.font(size, .medium, digits: true)), PaperText.width(bottom, PaperText.font(size, .medium, digits: true))) + 6
        text(id + "t", top, at: CGPoint(x: p.x, y: p.y - size * 0.62), size: size, colour)
        text(id + "b", bottom, at: CGPoint(x: p.x, y: p.y + size * 0.62), size: size, colour)
        line(id + "l", [CGPoint(x: p.x - w / 2, y: p.y), CGPoint(x: p.x + w / 2, y: p.y)], colour, width: 2)
    }
    /// Digits written in a row of cells, right-aligned so their places line up (as school writes a sum in columns):
    /// `right` is the x of the right edge of the ones cell; a "." sits on the line between two cells.
    mutating func digits(_ id: String, _ s: String, right: Double, y: Double, size: CGFloat = 24, _ colour: Colour = .ink, cell: Double = Sketch.c * 1.5) {
        var col = 0
        for (i, ch) in Array(s).enumerated().reversed() {
            if ch == "." { text("\(id).", ".", at: CGPoint(x: right - Double(col) * cell + 0.5, y: y), size: size, weight: .bold, colour); continue }
            text("\(id)\(i)", String(ch), at: CGPoint(x: right - (Double(col) + 0.5) * cell, y: y), size: size, colour)
            col += 1
        }
    }
    /// A line of math on the paper's squares (MathLineView's layout), a digit to a square of `cell` points, its answer
    /// boxes left to the blocks.
    mutating func mathLine(_ id: String, _ math: MathLine, at p: CGPoint, typed: [String: String] = [:], size: CGFloat, cell: Double) {
        let lay = MathLineView.layout(math, typed: typed, size: 28)
        for it in lay.items {
            let x = p.x + Double(it.col) * cell, y = p.y + Double(it.row) * cell
            switch it.kind {
            case .char(let ch, _): text("\(id)c\(it.id)\(ch)", ch, at: CGPoint(x: x + cell / 2, y: y + cell), size: size)
            case .point: text("\(id)p\(it.id)", ".", at: CGPoint(x: x, y: y + cell), size: size, weight: .bold)
            case .word(let t): text("\(id)w\(it.id)\(t)", t, at: CGPoint(x: x, y: y + cell), size: size * 0.7, weight: .regular, .ink2, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
            case .bar: line("\(id)b\(it.id)", [CGPoint(x: x, y: y), CGPoint(x: x + Double(it.w) * cell, y: y)], .ink, width: 1.5)
            case .box: break
            }
        }
    }
}

extension Rig {
    /// A WorkProblem's picture, rebuilt when what it shows changes; its new parts draw themselves in (G 19 Oct):
    /// lines stroke on, fills and words fade in, one after another.
    /// A WorkProblem, all of it in one drawing (G 19 Oct): its name and sum, then its picture, then the step, its
    /// line and its blocks, so it draws in in that order, calmly; rebuilt when what it shows or says changes, only
    /// what's new drawing in. Returns true while some of it is still drawing in or undrawing.
    @discardableResult
    func drawWork(_ m: WorkProblem, _ page: BarsPage, into d: SketchDrawer, at t: Double) -> Bool {
        let dark = self.dark ?? false
        // opened again while it was still undrawing: it draws itself back in
        if m.leftAt == nil, d.leftAt != nil { d.revive() }
        let key = "\(m.lesson.numbers) \(m.lesson.index) \(m.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(m.lesson.missedSteps.count) \(m.scale) " + wordsKey(m, page, dark: dark)
        // leaving, it only undraws: a rebuild now (it stopped being the current one) would draw it all back in
        if key != d.key, m.leftAt == nil {
            d.key = key
            let l = m.layout, o = m.contentOrigin
            var s = workSketch(m, top: true)
            s.append(LessonPictures.sketch(m).transformed(to: CGPoint(x: o.x, y: o.y + l.pictureTop * l.scale), scale: l.pictureScale * l.scale))
            s.append(workSketch(m, top: false))
            // the first time, everything draws in as the problem opens; after that, only what's new, as the step moves
            d.build(s, rig: self, chapter: m.chapter.hex, dark: dark, origin: .zero, from: d.isEmpty ? m.openedAt + 0.15 : max(m.pictureAt, t), now: t)
        }
        if let left = m.leftAt { d.undrawAll(at: left) }
        return d.update(at: t)
    }
}

/// Draws a Sketch into the scene, and keeps it: what stays the same stays; what's new draws itself in, a moment after
/// the part before (a line strokes on from its start, words write on a letter at a time, a fill or icon fades in); what
/// goes undraws, in reverse (G 19 Oct). Leaving, all of it undraws.
@MainActor
final class SketchDrawer {
    let root = Entity()
    var key = ""
    var isEmpty: Bool { nodes.isEmpty }

    private final class Node {
        let id: String, sig: String
        let parts: [ModelEntity]
        let line: (pts: [[CGPoint]], width: Double, dashed: Bool)?
        var start: Double, length: Double
        var undrawing = false
        var shown = -1.0
        init(id: String, sig: String, parts: [ModelEntity], line: (pts: [[CGPoint]], width: Double, dashed: Bool)?, start: Double, length: Double) {
            self.id = id; self.sig = sig; self.parts = parts; self.line = line; self.start = start; self.length = length
        }
    }
    private var nodes: [String: Node] = [:]
    /// Parts undrawing after they left the sketch (or changed), until they're gone.
    private var going: [Node] = []
    private(set) var leftAt: Double?
    // calm, not rushed (G 19 Oct): each part a moment after the last, the whole thing about two seconds
    static let each = 0.07, length = 0.55, most = 1.8, letter = 0.03
    static let undraw = 0.28, undrawMost = 0.25

    func build(_ s: Sketch, rig: Rig, chapter: UInt32, dark: Bool, origin o: CGPoint, scale k: Double = 1, from start: Double, now: Double = PaperClock.now) {
        let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF
        func colour(_ c: Sketch.Colour) -> UIColor {
            switch c {
            case .ink: rig.colours.ink
            case .ink2: rig.colours.ink2
            case .ink3: UIColor(hex: dark ? 0x878177 : 0x8C867D)
            case .chapter: UIColor(hex: chapter)
            case .tint(let f): UIColor(hex: Ink.mix(paper, chapter, f))
            case .paper: UIColor(hex: paper)
            case .line: rig.colours.lineStrong
            case .hex(let l, let d): UIColor(hex: dark ? d : l)
            }
        }
        func P(_ p: CGPoint) -> CGPoint { CGPoint(x: o.x + p.x * k, y: o.y + p.y * k) }
        let sigs = s.items.map { "\($0.kind) \($0.colour) \(o) \(k)" }
        let fresh = s.items.indices.filter { nodes[s.items[$0].id]?.sig != sigs[$0] }
        // the whole drawing-in takes at most `most` seconds, however many parts are new
        let gap = fresh.count > 1 ? min(Self.each, Self.most / Double(fresh.count)) : 0
        // what left, or changed, undraws
        let keep = Set(s.items.indices.filter { !fresh.contains($0) }.map { s.items[$0].id })
        let leaving = nodes.values.filter { !keep.contains($0.id) }
        undraw(leaving, at: now)
        for n in leaving { nodes[n.id] = nil }
        var order = 0
        for i in fresh {
            let item = s.items[i]
            // fills under lines under words, whatever order they draw in; later parts a hair above earlier ones
            let lift = Float(i) * 0.0000002
            var parts: [ModelEntity] = [], line: (pts: [[CGPoint]], width: Double, dashed: Bool)?, length = Self.length
            switch item.kind {
            case .fill(let pts), .plate(let pts):
                let base: Float = { if case .plate = item.kind { 0.0021 } else { 0.0016 } }()
                if let m = Rig.polygons([pts.map(P)]) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = base + lift; parts = [e] }
                length = 0.6
            case .line(let pts, let w, let dashed):
                let mapped = [pts.map(P)]
                if let m = Self.mesh(mapped, width: w * k, dashed: dashed, upTo: 1) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = 0.0018 + lift; parts = [e] }
                line = (mapped, w * k, dashed)
            case .overLine(let pts, let w):
                let mapped = [pts.map(P)]
                if let m = Self.mesh(mapped, width: w * k, dashed: false, upTo: 1) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = 0.0023 + lift; parts = [e] }
                line = (mapped, w * k, false)
            case .segments(let segs, let w):
                let mapped = segs.map { [P($0.0), P($0.1)] }
                if let m = Self.mesh(mapped, width: w * k, dashed: false, upTo: 1) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = 0.0017 + lift; parts = [e] }
                line = (mapped, w * k, false)
                length = 0.9
            case .text(let str, let p, let size, let weight, let anchor, let digits):
                // written a letter at a time: each letter its own piece, where the whole line puts it
                let f = PaperText.font(size * k, weight, digits: digits), at = P(p), w = PaperText.width(str, f)
                let left = at.x - anchor.x * w, offsets = PaperText.offsets(str, f)
                for (j, ch) in str.enumerated() {
                    if ch == " " { continue }
                    let x = left + offsets[j]
                    parts.append(PaperText.label(String(ch), f, colour(item.colour), at: CGPoint(x: x, y: at.y), anchor: UnitPoint(x: 0, y: anchor.y), y: 0.0024 + lift))
                }
                length = min(1.0, 0.3 + Double(parts.count) * Self.letter)
            case .icon(let name, let r):
                if let e = PaperText.icon(name, colour(item.colour), in: CGRect(origin: P(r.origin), size: CGSize(width: r.width * k, height: r.height * k)), y: 0.0025 + lift) { parts = [e] }
            }
            guard !parts.isEmpty else { continue }
            for e in parts { e.isEnabled = false; root.addChild(e) }
            // a part with its own start (a map piece's words) keeps it, unless that's passed: then it draws in now
            let at = item.at.map { max($0, now) } ?? start + Double(order) * gap
            nodes[item.id] = Node(id: item.id, sig: sigs[i], parts: parts, line: line, start: at, length: length)
            if item.at == nil { order += 1 }
        }
    }

    /// Wanted again after undrawing (a problem opened again straight away): what's left of it finishes undrawing,
    /// and the next build draws it all in afresh.
    func revive() { leftAt = nil; key = "" }

    /// Everything undraws, last first (leaving).
    func undrawAll(at t: Double) {
        guard leftAt == nil else { return }
        leftAt = t
        let all = Array(nodes.values); nodes = [:]
        undraw(all, at: t)
    }

    private func undraw(_ list: [Node], at t: Double) {
        let sorted = list.sorted { $0.start > $1.start }
        let gap = sorted.count > 1 ? min(Self.each, Self.undrawMost / Double(sorted.count)) : 0
        for (i, n) in sorted.enumerated() {
            // a part still drawing in turns round from where it got to
            let at = max(0, min(1, n.shown))
            n.undrawing = true; n.start = t + Double(i) * gap - (1 - at) * Self.undraw; n.length = Self.undraw
            going.append(n)
        }
    }

    /// Some lines' mesh, stroked on as far as `k` of their whole length, one after another.
    static func mesh(_ lines: [[CGPoint]], width: Double, dashed: Bool, upTo k: Double) -> MeshResource? {
        var part: [[CGPoint]] = lines
        if k < 1 {
            let lengths = lines.map { l in zip(l, l.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) } }
            var left = lengths.reduce(0, +) * max(0, k)
            part = []
            for (l, len) in zip(lines, lengths) where left > 0.01 {
                part.append(left >= len ? l : Self.partial(l, left / len))
                left -= len
            }
        }
        let drawn = part.filter { $0.count > 1 }
        guard !drawn.isEmpty else { return nil }
        let all = dashed ? Rig.dashes(drawn) : drawn, u = Paper.unit
        let segs = all.flatMap { l in zip(l, l.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) } }
        return Rig.lines(segs, width: Float(width / u))
    }

    /// Moves every part that's drawing in or undrawing to where it is at `t`; true while any still moves.
    @discardableResult
    func update(at t: Double) -> Bool {
        var moving = false
        for n in nodes.values where n.shown < 1 { apply(n, ease((t - n.start) / n.length)); if n.shown < 1 { moving = true } }
        going = going.filter { n in
            let k = 1 - ease((t - n.start) / n.length)
            apply(n, k)
            if k <= 0 { for e in n.parts { e.removeFromParent() }; return false }
            moving = true
            return true
        }
        return moving
    }

    private func apply(_ n: Node, _ raw: Double) {
        let k = snapped(raw, 24)
        guard k != n.shown else { return }
        n.shown = k
        if let l = n.line, let e = n.parts.first {
            e.isEnabled = k > 0
            if k > 0, let m = Self.mesh(l.pts, width: l.width, dashed: l.dashed, upTo: k) { e.model?.mesh = m }
        } else if n.parts.count > 1 || isText(n) {
            // letters: the first k of them showing, the one being written fading in
            let shown = k * Double(n.parts.count)
            for (j, e) in n.parts.enumerated() {
                let f = min(1, max(0, shown - Double(j)))
                e.isEnabled = f > 0
                if f >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(f))) }
            }
        } else if let e = n.parts.first {
            e.isEnabled = k > 0
            if k >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(k))) }
        }
    }
    private func isText(_ n: Node) -> Bool { n.sig.hasPrefix("text") }

    /// The first `k` of a line, by length.
    static func partial(_ pts: [CGPoint], _ k: Double) -> [CGPoint] {
        guard pts.count > 1 else { return pts }
        let total = zip(pts, pts.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
        var left = total * min(1, max(0, k)), out = [pts[0]]
        for (a, b) in zip(pts, pts.dropFirst()) where left > 0.01 {
            let len = hypot(b.x - a.x, b.y - a.y), f = len > 0 ? min(1, left / len) : 1
            out.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
            left -= len
        }
        return out
    }
}
