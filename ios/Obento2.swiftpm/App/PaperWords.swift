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
    /// The map's words: each chapter's dot, title and count; each lesson's name, its Up next tab and, when chosen, its
    /// Start block. Rebuilt when what they say changes; each lesson's words fade in with its drawing.
    func drawWords(_ model: PaperModel, at t: Double) {
        let isDark = dark ?? false
        let key = "\(Progress.shared.checks.count) \(Progress.shared.learned.count) \(Progress.shared.tests) \(isDark) \(PageStore.version) \(model.selected?.id ?? "")"
        if key != wordsKey { wordsKey = key; startKey = "-"; rebuildWords(model, dark: isDark) }
        // the Start block moves with the choice on its own, so a tap rebuilds only it
        let chosen = model.selected.flatMap { $0.opens ? $0 : nil }
        if chosen?.id ?? "" != startKey { startKey = chosen?.id ?? ""; rebuildStart(chosen, dark: isDark) }
        // erasing on the way into a lesson: all the map's words fade together
        let gone = snapped(model.mapGone(at: t), 40)
        if gone < 1 { words.components.set(OpacityComponent(opacity: Float(gone))) } else if words.components.has(OpacityComponent.self) { words.components.remove(OpacityComponent.self) }
        // once everything has drawn in, the fades are done: nothing more to do each frame
        let settled = t - model.drawnAt > Piece.drawTime + 1
        if settled, pieceWordsK.count == Map.all.count, !pieceWordsK.values.contains(where: { $0 < 1 }) { return }
        for p in Map.all {
            guard let e = pieceWords[p.id] else { continue }
            let k = snapped(Piece.drawIn(p, time: t, drawnAt: model.drawnAt, from: model.drawFrom), 20)
            if pieceWordsK[p.id] == k { continue }
            pieceWordsK[p.id] = k
            e.isEnabled = k > 0
            if k >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(k))) }
        }
    }

    private func rebuildWords(_ model: PaperModel, dark: Bool) {
        for c in Array(words.children) { c.removeFromParent() }
        pieceWords = [:]; pieceWordsK = [:]
        let ink = colours.ink, ink3 = UIColor(hex: dark ? 0x878177 : 0x8C867D)
        // chapter titles, baselines on a grid line: a dot in the chapter's colour, the title, and how many are learned
        let title = PaperText.font(30, .medium), small = PaperText.font(17)
        for g in Map.groups {
            let o = g.origin, done = g.lessons.filter { Progress.shared.learned.contains($0.id) }.count
            if let d = PaperText.dot(at: CGPoint(x: o.x + 5, y: o.y + 27), radius: 5, UIColor(hex: g.chapter.hex)) { words.addChild(d) }
            words.addChild(PaperText.label(g.chapter.title, title, ink, at: CGPoint(x: o.x + 20, y: o.y + 40)))
            let w = PaperText.width(g.chapter.title, title)
            words.addChild(PaperText.label("\(done) of \(g.lessons.count)", small, ink3, at: CGPoint(x: o.x + 32 + w, y: o.y + 37)))
        }
        let name = PaperText.font(20, .medium), tagFont = PaperText.font(14, .semibold)
        for p in Map.all {
            let e = Entity(), r = CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height)
            e.addChild(PaperText.label(p.name, name, ink, at: CGPoint(x: r.minX, y: r.maxY + 28)))
            // stopped partway: how far they got, after the name
            if p.isTest {
                // its score once taken, else what it waits for
                let line = Progress.shared.tests[p.id].map { "Score \($0) of 4 · \(Mastery.levels[$0])" }
                    ?? (p.opens ? "\(p.id == "test-grade" ? 20 : 12) problems, no hints" : p.id == "test-grade" ? "Opens after the chapter tests" : Map.chapterHasLessons(p.chapter) ? "Opens when its lessons are learned" : "Coming soon")
                e.addChild(PaperText.label(PageStore.load(p.id).map { "Not finished · \($0.solved) of \($0.problems.count)" } ?? line, PaperText.font(16, .medium),
                                           p.opens || Progress.shared.tests[p.id] != nil ? UIColor(hex: p.chapter.hex) : ink3, at: CGPoint(x: r.minX, y: r.maxY + 50)))
            } else if let s = PageStore.load(p.id) {
                e.addChild(PaperText.label("Not finished · \(s.solved) of \(s.problems.count)", PaperText.font(16, .medium), UIColor(hex: p.chapter.hex),
                                           at: CGPoint(x: r.minX, y: r.maxY + 50)))
            }
            if p.state == .now, !(model.selected?.id == p.id && p.opens) {
                let tag = CGRect(x: r.maxX - 80, y: r.minY - 20, width: 80, height: 20)
                if let m = Self.fills([tag]) { let f = ModelEntity(mesh: m, materials: [flat(UIColor(hex: p.chapter.hex))]); f.position.y = 0.002; e.addChild(f) }
                e.addChild(PaperText.label("Up next", tagFont, .white, at: CGPoint(x: tag.midX, y: tag.midY), anchor: .center))
            }
            words.addChild(e)
            pieceWords[p.id] = e
        }
        words.addChild(start)
    }

    /// The chosen lesson's tag (G 18 Oct): the frame's top-right tab, in its chapter's colour, saying Start (or Keep
    /// going) with an arrow, where Up next sits on the others. No block under the name, so the rows stay a block apart.
    private func rebuildStart(_ p: Piece?, dark: Bool) {
        for c in Array(start.children) { c.removeFromParent() }
        guard let p else { return }
        let s = CGRect(x: p.start.x, y: p.start.y, width: p.start.width, height: p.start.height)
        if let m = Self.fills([s]) { let f = ModelEntity(mesh: m, materials: [flat(UIColor(hex: p.chapter.hex))]); f.position.y = 0.0021; start.addChild(f) }
        start.addChild(PaperText.label(PageStore.load(p.id) == nil ? "Start" : "Keep going", PaperText.font(14, .semibold), .white,
                                       at: CGPoint(x: s.minX + 12, y: s.midY), anchor: UnitPoint(x: 0, y: 0.5)))
        if let a = PaperText.icon("arrow-right", .white, in: CGRect(x: s.maxX - 26, y: s.midY - 8, width: 16, height: 16)) { start.addChild(a) }
    }
}
