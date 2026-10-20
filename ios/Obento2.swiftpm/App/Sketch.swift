import SwiftUI
import RealityKit

/// A lesson's picture as plain parts on the paper: lines, filled shapes and words, in points from the picture's
/// top-left (a WorkProblem's origin, its picture's top). Each part has an id: when the picture changes, the parts that
/// are new draw in and the rest stay. Everything sits on the grid's cells, so a lesson builds it in cells (`c`).
@MainActor
struct Sketch {
    enum Colour: Hashable { case ink, ink2, ink3, chapter, tint(Double), paper, line }
    enum Kind {
        case line([CGPoint], width: Double, dashed: Bool)
        case fill([CGPoint])
        case text(String, CGPoint, size: CGFloat, weight: UIFont.Weight, anchor: UnitPoint, digits: Bool)
    }
    struct Item { let id: String; let kind: Kind; let colour: Colour }
    private(set) var items: [Item] = []
    static let c = Paper.cell

    mutating func line(_ id: String, _ pts: [CGPoint], _ colour: Colour = .ink, width: Double = 2, dashed: Bool = false) {
        items.append(Item(id: id, kind: .line(pts, width: width, dashed: dashed), colour: colour))
    }
    /// A rectangle's outline.
    mutating func box(_ id: String, _ r: CGRect, _ colour: Colour = .ink, width: Double = 2, dashed: Bool = false) {
        line(id, [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)], colour, width: width, dashed: dashed)
    }
    mutating func fill(_ id: String, _ r: CGRect, _ colour: Colour) {
        items.append(Item(id: id, kind: .fill([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]), colour: colour))
    }
    mutating func polygon(_ id: String, _ pts: [CGPoint], _ colour: Colour) { items.append(Item(id: id, kind: .fill(pts), colour: colour)) }
    mutating func text(_ id: String, _ s: String, at p: CGPoint, size: CGFloat = 20, weight: UIFont.Weight = .medium, _ colour: Colour = .ink,
                       anchor: UnitPoint = .center, digits: Bool = true) {
        items.append(Item(id: id, kind: .text(s, p, size: size, weight: weight, anchor: anchor, digits: digits), colour: colour))
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
        let chars = Array(s), pointAt = chars.firstIndex(of: ".")
        let afterPoint = pointAt.map { chars.count - 1 - $0 } ?? 0
        var col = 0
        for (i, ch) in chars.enumerated().reversed() {
            if ch == "." { text("\(id).", ".", at: CGPoint(x: right - Double(col) * cell + 0.5, y: y), size: size, weight: .bold, colour); continue }
            _ = afterPoint
            text("\(id)\(i)", String(ch), at: CGPoint(x: right - (Double(col) + 0.5) * cell, y: y), size: size, colour)
            col += 1
        }
    }
}

extension Rig {
    /// A WorkProblem's picture, rebuilt when what it shows changes; its new parts draw themselves in (G 19 Oct):
    /// lines stroke on, fills and words fade in, one after another.
    func drawSketch(_ m: WorkProblem, into d: SketchDrawer, at t: Double) {
        let dark = self.dark ?? false
        let key = "\(m.lesson.numbers) \(m.lesson.index) \(m.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(m.lesson.typed) \(dark) \(m.lesson.missedSteps.count) \(m.scale)"
        if key != d.key {
            d.key = key
            let s = LessonPictures.sketch(m)
            let l = m.layout, o = m.contentOrigin
            // the first time, everything draws in as the problem opens; after that, only what's new, as the step moves
            d.build(s, rig: self, chapter: m.chapter.hex, dark: dark, origin: CGPoint(x: o.x, y: o.y + l.pictureTop * l.scale), scale: l.pictureScale * l.scale,
                    from: d.isEmpty ? m.openedAt + 0.15 : max(m.pictureAt, t))
        }
        d.update(at: t, gone: m.gone(at: t))
    }
}

/// Draws a Sketch into the scene. Parts it already had stay; new ones draw themselves in, each a moment after the one
/// before: a line strokes on from its start, a fill or a word fades in.
@MainActor
final class SketchDrawer {
    let root = Entity()
    var key = ""
    private var ids: Set<String> = []
    var isEmpty: Bool { ids.isEmpty }
    /// The parts still drawing in: when each starts, and for a line what it strokes along.
    private struct Fresh {
        let entity: ModelEntity
        let start: Double
        let line: (pts: [CGPoint], width: Double, dashed: Bool)?
        var shown: Double = -1
    }
    private var fresh: [Fresh] = []
    private var faded = -1.0
    static let each = 0.025, length = 0.45, most = 0.9

    func build(_ s: Sketch, rig: Rig, chapter: UInt32, dark: Bool, origin o: CGPoint, scale k: Double = 1, from start: Double) {
        for c in Array(root.children) { c.removeFromParent() }
        fresh = []
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
            }
        }
        func P(_ p: CGPoint) -> CGPoint { CGPoint(x: o.x + p.x * k, y: o.y + p.y * k) }
        var next: Set<String> = [], order = 0
        let newCount = s.items.filter { !ids.contains($0.id) }.count
        // the whole drawing-in takes at most `most` seconds, however many parts are new
        let gap = newCount > 1 ? min(Self.each, Self.most / Double(newCount)) : 0
        for (n, item) in s.items.enumerated() {
            next.insert(item.id)
            let isNew = !ids.contains(item.id)
            // later parts sit a hair above earlier ones, fills under lines under words
            let lift = Float(n) * 0.000002
            var e: ModelEntity?, line: (pts: [CGPoint], width: Double, dashed: Bool)?
            switch item.kind {
            case .fill(let pts):
                if let m = Rig.polygons([pts.map(P)]) { e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e?.position.y = 0.0016 + lift }
            case .line(let pts, let w, let dashed):
                let mapped = pts.map(P)
                if let m = Self.mesh(mapped, width: w * k, dashed: dashed, upTo: 1) { e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e?.position.y = 0.0018 + lift }
                line = (mapped, w * k, dashed)
            case .text(let str, let p, let size, let weight, let anchor, let digits):
                e = PaperText.label(str, PaperText.font(size * k, weight, digits: digits), colour(item.colour), at: P(p), anchor: anchor, y: 0.0024 + lift)
            }
            guard let e else { continue }
            root.addChild(e)
            if isNew {
                fresh.append(Fresh(entity: e, start: start + Double(order) * gap, line: line))
                order += 1
            }
        }
        ids = next
        faded = -1
    }

    /// A line's mesh, stroked on as far as `k` of its length.
    static func mesh(_ pts: [CGPoint], width: Double, dashed: Bool, upTo k: Double) -> MeshResource? {
        let part = k >= 1 ? pts : Self.partial(pts, k)
        guard part.count > 1 else { return nil }
        let lines = dashed ? Rig.dashes([part]) : [part], u = Paper.unit
        let segs = lines.flatMap { l in zip(l, l.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) } }
        return Rig.lines(segs, width: Float(width / u))
    }

    func update(at t: Double, gone: Double) {
        let g = snapped(gone, 30)
        if g != faded {
            faded = g
            root.isEnabled = g > 0
            if g >= 1 { root.components.remove(OpacityComponent.self) } else { root.components.set(OpacityComponent(opacity: Float(g))) }
        }
        guard !fresh.isEmpty else { return }
        var still: [Fresh] = []
        for var f in fresh {
            let k = snapped(ease((t - f.start) / Self.length), 24)
            if k != f.shown {
                f.shown = k
                f.entity.isEnabled = k > 0
                if let l = f.line {
                    // a line strokes on; its mesh is remade only as it grows
                    if k > 0, let m = Self.mesh(l.pts, width: l.width, dashed: l.dashed, upTo: k) { f.entity.model?.mesh = m }
                } else if k >= 1 { f.entity.components.remove(OpacityComponent.self) } else { f.entity.components.set(OpacityComponent(opacity: Float(k))) }
            }
            if k < 1 { still.append(f) }
        }
        fresh = still
    }
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
    /// Something is still drawing in.
    var drawing: Bool { !fresh.isEmpty }
}
