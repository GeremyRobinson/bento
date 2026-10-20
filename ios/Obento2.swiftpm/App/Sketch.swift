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
    /// A WorkProblem's picture, rebuilt when what it shows changes; its new parts draw in.
    func drawSketch(_ m: WorkProblem, into d: SketchDrawer, at t: Double) {
        let dark = self.dark ?? false
        let key = "\(m.lesson.numbers) \(m.lesson.index) \(m.picture.sorted { $0.key < $1.key }.map { "\($0.key)\($0.value)" }) \(m.lesson.typed) \(dark) \(m.lesson.missedSteps.count)"
        if key != d.key {
            d.key = key
            let s = LessonPictures.sketch(m)
            let l = m.layout, o = m.contentOrigin
            d.build(s, rig: self, chapter: m.chapter.hex, dark: dark, origin: CGPoint(x: o.x, y: o.y + l.pictureTop * l.scale), scale: l.pictureScale * l.scale)
        }
        d.fade(grow: m.grow(at: t), fresh: m.fresh(at: t))
    }
}

/// Draws a Sketch into the scene: the parts it already had in one group, the new ones in another that fades in.
@MainActor
final class SketchDrawer {
    let root = Entity()
    private let steady = Entity(), fresh = Entity()
    var key = ""
    private var ids: Set<String> = []
    private var faded: (Double, Double) = (-1, -1)

    init() { root.addChild(steady); root.addChild(fresh) }

    func build(_ s: Sketch, rig: Rig, chapter: UInt32, dark: Bool, origin o: CGPoint, scale k: Double = 1) {
        for e in [steady, fresh] { for c in Array(e.children) { c.removeFromParent() } }
        let paper: UInt32 = dark ? 0x121211 : 0xF3F2EF, u = Paper.unit
        func colour(_ c: Sketch.Colour) -> UIColor {
            switch c {
            case .ink: rig.colours.ink
            case .ink2: rig.colours.ink2
            case .ink3: UIColor(hex: dark ? 0x878177 : 0x8C867D)
            case .chapter: UIColor(hex: chapter)
            case .tint(let k): UIColor(hex: Ink.mix(paper, chapter, k))
            case .paper: UIColor(hex: paper)
            case .line: rig.colours.lineStrong
            }
        }
        func P(_ p: CGPoint) -> CGPoint { CGPoint(x: o.x + p.x * k, y: o.y + p.y * k) }
        var next: Set<String> = []
        for (n, item) in s.items.enumerated() {
            next.insert(item.id)
            let into = ids.contains(item.id) || ids.isEmpty ? steady : fresh
            // later parts sit a hair above earlier ones, fills under lines under words
            let lift = Float(n) * 0.000002
            switch item.kind {
            case .fill(let pts):
                if let m = Rig.polygons([pts.map(P)]) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = 0.0016 + lift; into.addChild(e) }
            case .line(let pts, let w, let dashed):
                let lines = dashed ? Rig.dashes([pts.map(P)]) : [pts.map(P)]
                let segs = lines.flatMap { l in zip(l, l.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) } }
                if let m = Rig.lines(segs, width: Float(w * k / u)) { let e = ModelEntity(mesh: m, materials: [flat(colour(item.colour))]); e.position.y = 0.0018 + lift; into.addChild(e) }
            case .text(let str, let p, let size, let weight, let anchor, let digits):
                into.addChild(PaperText.label(str, PaperText.font(size * k, weight, digits: digits), colour(item.colour), at: P(p), anchor: anchor, y: 0.0024 + lift))
            }
        }
        ids = next
        faded = (-1, -1)
    }

    func fade(grow: Double, fresh f: Double) {
        let g = snapped(grow, 30), n = snapped(f, 30)
        guard (g, n) != faded else { return }
        faded = (g, n)
        root.isEnabled = g > 0
        if g >= 1 { root.components.remove(OpacityComponent.self) } else { root.components.set(OpacityComponent(opacity: Float(g))) }
        fresh.isEnabled = n > 0
        if n >= 1 { fresh.components.remove(OpacityComponent.self) } else { fresh.components.set(OpacityComponent(opacity: Float(n))) }
    }
}
