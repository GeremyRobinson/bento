import SwiftUI
import RealityKit

extension Rig {
    /// The page of problems (G 19 Oct): a card for each problem, on the strong lines, under a heading for its part.
    /// Drawn like everything else on the paper (SketchDrawer): the cards draw themselves in one after another, and
    /// undraw when a problem opens or the lesson closes. True while any of it moves.
    @discardableResult
    func drawCards(_ page: BarsPage?, at t: Double) -> Bool {
        guard let page, page.showing else {
            if let d = cardsDrawer { d.root.removeFromParent(); cardsDrawer = nil }
            return false
        }
        if page.cardsGoneAt == nil {
            // wanted: a fresh drawer if the last one undrew, then only what changed draws in
            if cardsDrawer?.leftAt != nil { cardsDrawer?.root.removeFromParent(); cardsDrawer = nil }
            let d = cardsDrawer ?? { let d = SketchDrawer(); cardsRoot.addChild(d.root); cardsDrawer = d; return d }()
            let isDark = dark ?? false, cards = page.cards
            let key = cards.map { "\($0.title)\($0.line)\($0.state)\($0.rect.x)\($0.rect.y)" }.joined() + page.headings.map(\.1).joined() + "\(isDark)"
            if key != d.key {
                d.key = key
                d.build(cardsSketch(page, cards), rig: self, chapter: page.piece.chapter.hex, dark: isDark, origin: .zero, from: d.isEmpty ? page.cardsAt : t, now: t)
            }
        } else if let gone = page.cardsGoneAt {
            cardsDrawer?.undrawAll(at: gone)
        }
        return cardsDrawer?.update(at: t) ?? false
    }

    private func cardsSketch(_ page: BarsPage, _ cards: [BarsPage.Card]) -> Sketch {
        var s = Sketch()
        // the headings first, so each part's name draws in before its cards
        for (p, words) in page.headings {
            s.text("head\(words)", words, at: CGPoint(x: p.x, y: p.y), size: 26, weight: .semibold, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        }
        for c in cards {
            let r = CGRect(x: c.rect.x, y: c.rect.y, width: c.rect.width, height: c.rect.height), id = "card\(c.index ?? -1)"
            let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)]
            switch c.state {
            case .locked: s.line(id + "o-locked", corners, .tint(0.35), width: 1.5, dashed: true)
            case .now: s.line(id + "o-now", corners, .chapter, width: 2.5)
            case .done, .missed:
                s.fill(id + "f", r, .tint(0.08))
                s.line(id + "o", corners, .tint(0.3), width: 1.5)
            case .open: s.line(id + "o", corners, .tint(0.3), width: 1.5)
            }
            // the tab on its corner: Done once solved, Now on the one worked last
            if let tag = c.state == .done ? "Done" : c.state == .now ? "Now" : nil {
                let t = CGRect(x: r.maxX - 80, y: r.minY - 20, width: 80, height: 20)
                s.fill(id + "tab" + tag, t, .chapter)
                s.text(id + "tabw" + tag, tag, at: CGPoint(x: t.midX, y: t.midY), size: 14, weight: .semibold, .hex(0xFFFFFF, 0xFFFFFF), digits: false)
            }
            // on the grid: the name in the top row of squares, the problem a digit to every two squares under it, and
            // what's next in the bottom row
            s.text(id + "name", c.title, at: CGPoint(x: r.minX + 20, y: r.minY + 40), size: 22, .ink3, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
            if let d = c.display {
                // a digit to every two squares; a fraction (four rows tall) a digit to a square, so it fits the card
                let tall = MathLineView.layout(d, size: 28).h > 2
                s.mathLine(id + "sum", d, at: CGPoint(x: r.minX + 20, y: r.minY + 80), size: tall ? 30 : 40, cell: tall ? 20 : 40)
            } else {
                s.text(id + "twelve", "12 problems", at: CGPoint(x: r.minX + 20, y: r.minY + 140), size: 40, c.state == .locked ? .ink3 : .ink, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
            }
            let colour: Sketch.Colour = c.state == .done || c.state == .now ? .chapter : c.state == .missed ? .ink : .ink2
            s.text(id + "line" + c.line, c.line, at: CGPoint(x: r.minX + 20, y: r.maxY - 40), size: 22, colour, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        }
        return s
    }
}
