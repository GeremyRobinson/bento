import SwiftUI
import RealityKit

extension Rig {
    /// The page of problems (G 19 Oct): a card for each problem, on the strong lines, under a heading for its part; or a
    /// finished test's result in their place (G 20 Oct). Drawn like everything else on the paper (SketchDrawer): the
    /// cards draw themselves in one after another, and undraw when a problem opens or the lesson closes. True while any
    /// of it moves.
    @discardableResult
    func drawCards(_ page: BarsPage?, at t: Double) -> Bool {
        guard let page, page.showing else {
            if let d = cardsDrawer { d.root.removeFromParent(); cardsDrawer = nil }
            return false
        }
        // the cards are there only while a problem is being chosen (G found them under a problem reopened on coming back),
        // the result only while it's read
        let result = page.mode == .result ? page.result : nil
        if (page.mode == .choose || result != nil), page.cardsGoneAt == nil {
            // wanted: a fresh drawer if the last one undrew, then only what changed draws in
            if cardsDrawer?.leftAt != nil { cardsDrawer?.root.removeFromParent(); cardsDrawer = nil }
            // the page of problems is passed through on the way to a problem: it draws in about twice as fast
            let d = cardsDrawer ?? { let d = SketchDrawer(); d.pace = 0.45; cardsRoot.addChild(d.root); cardsDrawer = d; return d }()
            let isDark = dark ?? false
            if let result {
                let key = "result \(result) \(isDark)"
                if key != d.key {
                    d.key = key
                    d.build(resultSketch(page, result), rig: self, chapter: page.piece.chapter.hex, dark: isDark, origin: .zero, from: d.isEmpty ? page.cardsAt : t, now: t)
                }
            } else {
                let cards = page.cards
                let key = cards.map { "\($0.title)\($0.line)\($0.state)\($0.rect.x)\($0.rect.y)" }.joined() + page.headings.map(\.1).joined() + "\(isDark)"
                if key != d.key {
                    d.key = key
                    d.build(cardsSketch(page, cards), rig: self, chapter: page.piece.chapter.hex, dark: isDark, origin: .zero, from: d.isEmpty ? page.cardsAt : t, now: t)
                }
            }
        } else {
            cardsDrawer?.undrawAll(at: page.cardsGoneAt ?? t)
        }
        return cardsDrawer?.update(at: t) ?? false
    }

    private func cardsSketch(_ page: BarsPage, _ cards: [BarsPage.Card]) -> Sketch {
        var s = Sketch()
        // the headings first, so each part's name draws in before its cards
        let lesson = page.piece.id
        for (n, (p, words)) in page.headings.enumerated() { s.words("head", words, .heading, x: p.x, top: p.y - Sketch.row / 2, width: 1200, slot: "\(lesson)head\(n)") }
        for c in cards {
            let r = CGRect(x: c.rect.x, y: c.rect.y, width: c.rect.width, height: c.rect.height), id = c.id
            // a lesson thumbnail's frame and tab, the problem centred in it, its name and status under it
            s.frame(id, r, c.state == .locked ? .locked : c.state == .now ? .now : c.state == .open ? .open : .done)
            if let tag = c.state == .done ? "Done" : c.state == .now ? "Now" : nil { s.tab(id, frame: r, tag) }
            if let d = c.display {
                // the problem as it's written, inside its frame with a square to spare each side: in the maths' size, or
                // the words' when it's too long for that ("3 + 8 × (10 − 7) = ?")
                var probe = Sketch()
                let fits = probe.sum("probe", d, at: .zero, size: Sketch.maths, centred: true) <= r.width - 2 * Paper.cell
                s.sum(id + "sum", d, at: CGPoint(x: r.midX, y: r.midY), size: fits ? Sketch.maths : Sketch.wordSize, centred: true)
            }
            else { s.label(id + "twelve", "\(LessonPlan.test) problems", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: c.state == .locked ? .ink3 : .ink), at: CGPoint(x: r.midX, y: r.midY), anchor: .center) }
            s.label(id + "name", c.title, .label, at: CGPoint(x: r.minX, y: r.maxY + 30), anchor: UnitPoint(x: 0, y: 0.5))
            s.label(id + "line", c.line, Sketch.Words.status.colour(c.state == .done || c.state == .now ? .chapter : c.state == .missed ? .ink : .ink3), at: CGPoint(x: r.minX, y: r.maxY + 50), anchor: UnitPoint(x: 0, y: 0.5), slot: lesson + id + "line")
        }
        return s
    }

    /// A finished test's result on the paper (G 20 Oct), where the cards were: its name, a frame with the score in it
    /// (lightly filled once passed, as a done card is), what it means (Learned, in the chapter's colour; Take it again),
    /// what passes when it wasn't, and Continue.
    private func resultSketch(_ page: BarsPage, _ r: BarsPage.Result) -> Sketch {
        var s = Sketch()
        let l = page.resultLayout, f = CGRect(x: l.frame.x, y: l.frame.y, width: l.frame.width, height: l.frame.height)
        s.words("result-head", r.title, .heading, x: l.heading.x, top: l.heading.y - Sketch.row / 2, width: 1200)
        s.frame("result", f, r.passed ? .done : .open)
        s.label("result-score", "\(r.right) of \(r.of)", Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink), at: CGPoint(x: f.midX, y: f.midY), anchor: .center)
        s.label("result-verdict", r.verdict, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: r.passed ? .chapter : .ink), at: CGPoint(x: l.verdict.x, y: l.verdict.y), anchor: UnitPoint(x: 0, y: 0.5))
        if let needs = r.needs {
            s.label("result-needs", needs, Sketch.Words.status, at: CGPoint(x: l.needs.x, y: l.needs.y), anchor: UnitPoint(x: 0, y: 0.5))
        }
        let b = CGRect(x: l.block.x, y: l.block.y, width: l.block.width, height: l.block.height)
        s.block("result-continue", b, .main, word: "Continue", arrow: true)
        return s
    }
}
