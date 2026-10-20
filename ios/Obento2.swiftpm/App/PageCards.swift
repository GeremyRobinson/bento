import SwiftUI
import RealityKit

extension Rig {
    /// The page of problems (G 19 Oct): a card for each problem, on the strong lines, under a heading for its part. Each
    /// card draws in a moment after the one before and out together when a problem opens. Rebuilt only when what the
    /// cards say changes; each frame only their fades move.
    func drawCards(_ page: BarsPage?, at t: Double) {
        guard let page, page.showing, page.cardsShown(at: t) > 0 || page.mode == .choose && t < page.cardsAt else {
            if !cardsRoot.children.isEmpty { for c in Array(cardsRoot.children) { c.removeFromParent() }; cardsKey = "" }
            return
        }
        let isDark = dark ?? false, cards = page.cards
        let key = cards.map { "\($0.title)\($0.line)\($0.state)\($0.rect.x)\($0.rect.y)" }.joined() + page.headings.map(\.1).joined() + "\(isDark)\(ObjectIdentifier(page).hashValue)"
        if key != cardsKey {
            cardsKey = key
            for c in Array(cardsRoot.children) { c.removeFromParent() }
            buildCards(page, cards, dark: isDark)
        }
        let out = page.cardsGoneAt.map { 1 - ease((t - $0) / 0.4) } ?? 1
        for (k, e) in cardsRoot.children.enumerated() {
            let f = snapped(min(ease((t - page.cardsAt - Double(k) * 0.05) / 0.45), out), 30)
            e.isEnabled = f > 0
            if f >= 1 { e.components.remove(OpacityComponent.self) } else { e.components.set(OpacityComponent(opacity: Float(f))) }
        }
    }

    private func buildCards(_ page: BarsPage, _ cards: [BarsPage.Card], dark: Bool) {
        let chapter = page.piece.chapter.hex, chapterC = UIColor(hex: chapter), ink = colours.ink, ink2 = colours.ink2
        let grey = UIColor(hex: dark ? 0x878177 : 0x8C867D), u = Paper.unit
        func segs(_ pts: [CGPoint]) -> [(SIMD2<Float>, SIMD2<Float>)] {
            zip(pts, pts.dropFirst()).map { (SIMD2(Float($0.x / u), Float($0.y / u)), SIMD2(Float($1.x / u), Float($1.y / u))) }
        }
        func add(_ e: Entity, _ mesh: MeshResource?, _ c: UIColor, _ y: Float) {
            guard let mesh else { return }
            let m = ModelEntity(mesh: mesh, materials: [flat(c)]); m.position.y = y; e.addChild(m)
        }
        // the headings first, so they draw in before their cards
        for (p, words) in page.headings {
            let e = Entity()
            e.addChild(PaperText.label(words, PaperText.font(26, .semibold), ink, at: CGPoint(x: p.x, y: p.y), anchor: UnitPoint(x: 0, y: 0.5)))
            cardsRoot.addChild(e)
        }
        for c in cards {
            let e = Entity(), r = CGRect(x: c.rect.x, y: c.rect.y, width: c.rect.width, height: c.rect.height)
            let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)]
            switch c.state {
            case .locked:
                add(e, Self.lines(Rig.dashes([corners]).flatMap(segs), width: Float(1.5 / u)), UIColor(hex: Ink.mix(paperHex, chapter, 0.35)), 0.001)
            case .now:
                add(e, Self.lines(segs(corners), width: Float(2.5 / u)), chapterC, 0.0011)
            case .done, .missed:
                add(e, Self.fills([r]), UIColor(hex: Ink.mix(paperHex, chapter, 0.08)), 0.0003)
                add(e, Self.lines(segs(corners), width: Float(1.5 / u)), UIColor(hex: Ink.mix(paperHex, chapter, 0.3)), 0.001)
            case .open:
                add(e, Self.lines(segs(corners), width: Float(1.5 / u)), UIColor(hex: Ink.mix(paperHex, chapter, 0.3)), 0.001)
            }
            // the tab on its corner: Done once solved, Now on the one worked last
            if let tag = c.state == .done ? "Done" : c.state == .now ? "Now" : nil {
                let t = CGRect(x: r.maxX - 80, y: r.minY - 20, width: 80, height: 20)
                add(e, Self.fills([t]), chapterC, 0.002)
                e.addChild(PaperText.label(tag, PaperText.font(14, .semibold), .white, at: CGPoint(x: t.midX, y: t.midY), anchor: .center))
            }
            e.addChild(PaperText.label(c.title, PaperText.font(22, .medium), grey, at: CGPoint(x: r.minX + 20, y: r.minY + 20), anchor: .topLeading))
            if let d = c.display {
                mathLine(d, at: CGPoint(x: r.minX + 20, y: r.minY + 70), typed: [:], into: e, size: 44)
            } else {
                e.addChild(PaperText.label("12 problems", PaperText.font(40, .medium), c.state == .locked ? grey : ink, at: CGPoint(x: r.minX + 20, y: r.minY + 100), anchor: UnitPoint(x: 0, y: 0.5)))
            }
            let lineColour = c.state == .done || c.state == .now ? chapterC : c.state == .missed ? ink : ink2
            PaperText.block(c.line, PaperText.font(22, .medium), lineColour, width: r.width - 40, topLeft: CGPoint(x: r.minX + 20, y: r.maxY - 64), maxLines: 2).forEach { e.addChild($0) }
            cardsRoot.addChild(e)
        }
    }
}
