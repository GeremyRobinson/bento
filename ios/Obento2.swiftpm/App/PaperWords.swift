import SwiftUI
import RealityKit
import CoreText

/// Words drawn on the paper itself: flat shapes in the 3D scene, under the same camera as the grid and the pictures.
/// Drawn as SwiftUI on top they were a separate picture that RealityKit's sometimes reached the screen a refresh
/// later than, so in a glide the words jiggled against their boxes (G 17 Oct). Here they can't: one picture, one camera.
@MainActor
enum PaperText {
    private static var meshes: [String: MeshResource] = [:]
    private static var icons: [String: UnlitMaterial] = [:]

    /// The app's type (SF Pro Rounded, as `Typeface`).
    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular, digits: Bool = false) -> UIFont {
        let f = UIFont.systemFont(ofSize: size, weight: weight)
        var d = f.fontDescriptor.withDesign(.rounded) ?? f.fontDescriptor
        // digits all one width, so numbers line up as they change
        if digits { d = d.addingAttributes([.featureSettings: [[UIFontDescriptor.FeatureKey.type: kNumberSpacingType, UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector]]]) }
        return UIFont(descriptor: d, size: size)
    }

    /// Text wrapped to `width`, one line under another, as SwiftUI wraps it: placed by its top-left, or by its
    /// bottom-left so more lines grow upward.
    static func block(_ s: String, _ f: UIFont, _ c: UIColor, width: Double, topLeft: CGPoint? = nil, bottomLeft: CGPoint? = nil, maxLines: Int = 6) -> [ModelEntity] {
        let lines = Array(wrap(s, f, width: width).prefix(maxLines)), h = Double(f.lineHeight)
        let top = topLeft?.y ?? ((bottomLeft?.y ?? 0) - Double(lines.count) * h), x = topLeft?.x ?? bottomLeft?.x ?? 0
        return lines.enumerated().map { i, line in label(line, f, c, at: CGPoint(x: x, y: top + Double(i) * h), anchor: .topLeading) }
    }

    /// The lines a text breaks into at `width`, by word.
    static func wrap(_ s: String, _ f: UIFont, width: Double) -> [String] {
        let attributed = NSAttributedString(string: s, attributes: [.font: f])
        let setter = CTFramesetterCreateWithAttributedString(attributed)
        let frame = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0), CGPath(rect: CGRect(x: 0, y: 0, width: width, height: 10_000), transform: nil), nil)
        let lines = CTFrameGetLines(frame) as? [CTLine] ?? []
        let text = s as NSString
        return lines.map { line in
            let r = CTLineGetStringRange(line)
            return text.substring(with: NSRange(location: r.location, length: r.length)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Where each character of a line starts, as the font sets the whole line (its kerning included), so letters drawn
    /// one at a time sit exactly where the whole word would put them.
    static func offsets(_ s: String, _ f: UIFont) -> [Double] {
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: [.font: f]))
        var out: [Double] = [], i = 0
        for ch in s {
            out.append(Double(CTLineGetOffsetForStringIndex(line, i, nil)))
            i += String(ch).utf16.count
        }
        return out
    }

    static func width(_ s: String, _ f: UIFont) -> Double { Double((s as NSString).size(withAttributes: [.font: f]).width) }


    /// A line of text lying on the paper, the point `anchor` of its box at `p` (paper points), as SwiftUI places text.
    /// The shapes are made once per text and size and reused.
    static func label(_ s: String, _ f: UIFont, _ c: UIColor, at p: CGPoint, anchor: UnitPoint = .bottomLeading, y: Float = 0.0025) -> ModelEntity {
        let key = "\(s)|\(f.pointSize)|\(f.fontName)"
        // made from styled text, so the letters are spaced as SwiftUI spaces them (the plain-string maker spaced them
        // an eighth wider)
        let mesh = meshes[key] ?? {
            var str = AttributedString(s); str.uiKit.font = f
            var o = MeshResource.ShapeExtrusionOptions(); o.extrusionMethod = .linear(depth: 0)
            let m = (try? MeshResource(extruding: str, extrusionOptions: o)) ?? .generatePlane(width: 0, depth: 0)
            meshes[key] = m
            return m
        }()
        // the text's shapes start at the bottom-left of its line, standing up, 72 to a unit: lay them on the paper
        let w = width(s, f), h = Double(f.lineHeight), u = Paper.unit
        let left = p.x - anchor.x * w, bottom = p.y - anchor.y * h + h
        let e = ModelEntity(mesh: mesh, materials: [flat(c)])
        e.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        e.scale = SIMD3(repeating: Float(72 / u))
        e.position = SIMD3(Float(left / u), y, Float(bottom / u))
        return e
    }

    /// A line of text standing up, in points, its line's bottom-left at its origin: for words that face the child.
    static func standing(_ s: String, _ f: UIFont, _ c: UIColor) -> ModelEntity {
        let e = label(s, f, c, at: .zero)
        e.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
        e.scale = SIMD3(repeating: 72)
        e.position = .zero
        return e
    }

    /// A Phosphor icon lying on the paper in rect `r`, filled with colour `c`, as drawn.
    static func icon(_ name: String, _ c: UIColor, in r: CGRect, y: Float = 0.0025) -> ModelEntity? {
        var red: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&red, green: &g, blue: &b, alpha: &a)
        let key = "\(name) \(red) \(g) \(b)"
        if icons[key] == nil {
            guard let image = UIImage(named: "ph-\(name)") else { return nil }
            // drawn large enough to stay sharp when the paper is zoomed in
            let side: CGFloat = 96
            let tinted = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
                c.setFill()
                image.withRenderingMode(.alwaysTemplate).withTintColor(c).draw(in: CGRect(x: 0, y: 0, width: side, height: side))
            }
            guard let cg = tinted.cgImage, let texture = try? TextureResource.generate(from: cg, options: .init(semantic: .color)) else { return nil }
            var m = UnlitMaterial(applyPostProcessToneMap: false)
            m.color = .init(tint: .white, texture: .init(texture))
            m.blending = .transparent(opacity: .init(floatLiteral: 1))
            icons[key] = m
        }
        let u = Paper.unit
        let e = ModelEntity(mesh: .generatePlane(width: Float(r.width / u), depth: Float(r.height / u)), materials: [icons[key]!])
        e.position = SIMD3(Float(r.midX / u), y, Float(r.midY / u))
        return e
    }

    /// A filled circle on the paper.
    static func dot(at c: CGPoint, radius: Double, _ colour: UIColor, y: Float = 0.002) -> ModelEntity? {
        let u = Paper.unit, n = 24
        var pos: [SIMD3<Float>] = [SIMD3(Float(c.x / u), 0, Float(c.y / u))], idx: [UInt32] = []
        for i in 0..<n {
            let a = Double(i) / Double(n) * 2 * .pi
            pos.append(SIMD3(Float((c.x + cos(a) * radius) / u), 0, Float((c.y + sin(a) * radius) / u)))
            let j = UInt32(i + 1), k = UInt32((i + 1) % n + 1)
            idx += [0, j, k, 0, k, j]
        }
        var desc = MeshDescriptor(name: "dot")
        desc.positions = MeshBuffers.Positions(pos)
        desc.primitives = .triangles(idx)
        guard let mesh = try? MeshResource.generate(from: [desc]) else { return nil }
        let e = ModelEntity(mesh: mesh, materials: [flat(colour)])
        e.position.y = y
        return e
    }
}

extension Rig {
    /// The map's words (G 19 Oct, master components): each chapter's dot, title and count; each lesson's name and how
    /// far it got, its Up next tab or, when chosen, its Start tab; a test's badge. Drawn like everything else
    /// (SketchDrawer): each lesson's words write themselves on as its frame draws in, only what changes redraws, and
    /// leaving for a lesson they undraw.
    func drawWords(_ model: PaperModel, at t: Double) {
        let isDark = dark ?? false
        // gone (into a lesson): undraw; back on the map, a fresh drawing
        if let left = model.mapLeftAt { mapDrawer?.undrawAll(at: left) }
        else if mapDrawer?.leftAt != nil { mapDrawer?.root.removeFromParent(); mapDrawer = nil }
        let d = mapDrawer ?? { let d = SketchDrawer(); words.addChild(d.root); mapDrawer = d; return d }()
        let key = "\(Progress.shared.checks.count) \(Progress.shared.learned.count) \(Progress.shared.tests) \(isDark) \(PageStore.version) \(model.selected?.id ?? "") \(model.drawnAt)"
        if key != d.key, model.mapLeftAt == nil {
            d.key = key
            d.build(mapSketch(model, dark: isDark), rig: self, chapter: Chapter.whole.hex, dark: isDark, origin: .zero, from: t, now: t)
        }
        let moving = d.update(at: t)
        if moving != model.mapDrawing { Task { @MainActor in model.setMapDrawing(moving) } }
    }

    private func mapSketch(_ model: PaperModel, dark: Bool) -> Sketch {
        var s = Sketch()
        /// When a place's words start: as its frame draws in (Piece.drawIn), a moment after.
        func at(_ p: Point) -> Double { model.drawnAt + Piece.drawDelay(p, from: model.drawFrom) + 0.3 }
        // chapter titles, baselines on a grid line: a dot in the chapter's colour, the title, and how many are learned
        for g in Map.groups {
            let o = g.origin, done = g.lessons.filter { Progress.shared.learned.contains($0.id) }.count
            s.startAt = at(Point(o.x + 150, o.y + 100))
            s.polygon("dot\(g.chapter)", Self.circle(CGPoint(x: o.x + 5, y: o.y + 27), 5), .hex(g.chapter.hex, g.chapter.hex))
            s.label("title\(g.chapter)", g.chapter.title, .chapter, at: CGPoint(x: o.x + 20, y: o.y + 40))
            let w = PaperText.width(g.chapter.title, PaperText.font(Sketch.Words.chapter.size, Sketch.Words.chapter.weight))
            s.label("count\(g.chapter)", "\(done) of \(g.lessons.count)", .count, at: CGPoint(x: o.x + 32 + w, y: o.y + 37))
        }
        for p in Map.all {
            let r = CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height), id = p.id
            let hex = p.chapter.hex, chapter = Sketch.Colour.hex(hex, hex)
            s.startAt = at(p.frame.mid)
            // its name, and under it how far it got (stopped partway), or for a test what it waits for
            s.label(id + "name", p.name, .label, at: CGPoint(x: r.minX, y: r.maxY + 28))
            if p.isTest {
                let line = PageStore.load(p.id).map { "\($0.solved) of \($0.problems.count) done" } ?? Progress.shared.tests[p.id].map { _ in "Done" }
                    ?? (p.opens ? "\(p.id == "test-grade" ? 20 : 12) problems" : p.id == "test-grade" ? "Finish the chapter tests first" : Map.chapterHasLessons(p.chapter) ? "Finish the lessons first" : "Coming soon")
                s.label(id + "line", line, Sketch.Words(size: 16, weight: .medium, colour: p.opens || Progress.shared.tests[p.id] != nil ? chapter : .ink3), at: CGPoint(x: r.minX, y: r.maxY + 50))
            } else if let saved = PageStore.load(p.id) {
                s.label(id + "line", "\(saved.solved) of \(saved.problems.count) done", Sketch.Words(size: 16, weight: .medium, colour: chapter), at: CGPoint(x: r.minX, y: r.maxY + 50))
            }
            if p.isTest {
                // a test's badge (G 18 Oct): a round seal on the frame's top-left corner, how many problems it has (a tick
                // once taken); filled in the chapter's colour when it can be taken, an outline while it waits
                let corner = CGPoint(x: r.minX, y: r.minY), taken = Progress.shared.tests[p.id] != nil, ready = p.opens || taken
                s.plate(id + "seal\(ready)", Self.circle(corner, 22), ready ? chapter : .paper)
                if !ready { s.overLine(id + "ring", Self.circle(corner, 21) + [Self.circle(corner, 21)[0]], .hex(Ink.mix(0xF3F2EF, hex, 0.45), Ink.mix(0x121211, hex, 0.45)), width: 1.5) }
                let mark: Sketch.Colour = ready ? .hex(0xFFFFFF, 0xFFFFFF) : .hex(Ink.mix(0xF3F2EF, hex, 0.7), Ink.mix(0x121211, hex, 0.7))
                if taken { s.overLine(id + "tick", [CGPoint(x: corner.x - 8, y: corner.y), CGPoint(x: corner.x - 2.5, y: corner.y + 6), CGPoint(x: corner.x + 9, y: corner.y - 6.5)], mark, width: 3) }
                else { s.text(id + "n", "\(p.id == "test-grade" ? 20 : 12)", at: corner, size: 15, weight: .bold, mark) }
            } else if model.selected?.id == p.id && p.opens {
                // chosen: its tab says Start (or Continue), with an arrow (G 18 Oct)
                s.startAt = nil
                s.tab(id, frame: r, PageStore.load(p.id) == nil ? "Start" : "Continue", width: p.start.width, arrow: true)
            } else if p.state == .now {
                s.tab(id, frame: r, "Up next")
            }
        }
        return s
    }

    static func circle(_ c: CGPoint, _ r: Double) -> [CGPoint] {
        (0..<40).map { i in let a = Double(i) / 40 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
    }
}
