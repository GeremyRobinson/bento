import SwiftUI
import RealityKit

extension Rig {
    /// The page of problems (G 19 Oct): a card for each problem, on the strong lines, under a heading for its part; or a
    /// finished test's result in their place (G 20 Oct). Drawn like everything else on the paper (SketchDrawer): the
    /// cards draw themselves in one after another, and undraw when a problem opens or the lesson closes (with Reduce
    /// Motion, or in a screenshot, they go at once). True while any of it moves.
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
        } else if page.instant {
            // Reduce Motion cuts (LESSONS.md §4), and a screenshot never catches the cards half gone under a problem
            if let d = cardsDrawer { d.root.removeFromParent(); cardsDrawer = nil }
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
        // every card on the page in one size (G 20 Oct): the biggest at which all their maths fits
        let room = BarsPage.card.width - 2 * Paper.cell
        let size = CardText.size(cards.compactMap { $0.display.map { CardText.parts($0).maths } }, room: room)
        for c in cards {
            let r = CGRect(x: c.rect.x, y: c.rect.y, width: c.rect.width, height: c.rect.height), id = c.id
            // a lesson thumbnail's frame and tab, the problem centred in it, its name and status under it; on a page that
            // mixes lessons (the daily review), each card in its own lesson's colour
            let state: Sketch.FrameState = c.state == .locked ? .locked : c.state == .now ? .now : c.state == .open ? .open : .done
            let tag = c.state == .done ? "Done" : c.state == .now ? "Now" : nil
            if let pen = c.pen {
                s.frame(id, r, state, pen: pen)
                if let tag { s.tab(id, frame: r, tag, pen: pen) }
            } else {
                s.frame(id, r, state)
                if let tag { s.tab(id, frame: r, tag) }
            }
            if let d = c.display { CardText.draw(&s, id, CardText.parts(d), in: r, size: size) }
            else { s.label(id + "twelve", "\(LessonPlan.test) problems", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: c.state == .locked ? .ink3 : .ink), at: CGPoint(x: r.midX, y: r.midY), anchor: .center) }
            s.label(id + "name", c.title, .label, at: CGPoint(x: r.minX, y: r.maxY + 30), anchor: UnitPoint(x: 0, y: 0.5))
            let lit: Sketch.Colour = c.pen?.full ?? .chapter
            s.label(id + "line", c.line, Sketch.Words.status.colour(c.state == .done || c.state == .now ? lit : c.state == .missed ? .ink : .ink3), at: CGPoint(x: r.minX, y: r.maxY + 50), anchor: UnitPoint(x: 0, y: 0.5), slot: lesson + id + "line")
        }
        return s
    }

    /// A finished test's result on the paper (G 20 Oct), where the cards were: its name; a frame with the score in it
    /// ("11 of 12 right", lightly filled once passed, as a done card is); what it means and why; then Continue, or, not
    /// passed, Take it again with a quieter way back beside it.
    private func resultSketch(_ page: BarsPage, _ r: BarsPage.Result) -> Sketch {
        var s = Sketch()
        let l = page.resultLayout, f = CGRect(x: l.frame.x, y: l.frame.y, width: l.frame.width, height: l.frame.height), width = page.resultWidth
        s.words("result-head", r.title, .heading, x: l.heading.x, top: l.heading.y - Sketch.row / 2, width: 1200)
        // the review's in ink: it mixes every chapter
        if r.kind == .review { s.frame("result", f, .done, pen: .ink) } else { s.frame("result", f, r.passed ? .done : .open) }
        s.label("result-score", "\(r.right) of \(r.of) right", Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink), at: CGPoint(x: f.midX, y: f.midY), anchor: .center)
        s.words("result-verdict", r.verdict, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink), x: l.verdict.x, top: l.verdict.y - Sketch.row / 2, width: width)
        // why, on as many rows as it takes (the review names every lesson it had a miss in; the blocks sit under it)
        for (i, row) in l.whyRows.enumerated() {
            s.text("result-why\(i):\(row)", row, at: CGPoint(x: l.why.x, y: l.why.y + Double(i) * Sketch.row), size: Sketch.small, weight: .regular, .ink2,
                   anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        }
        s.block("result-main", CGRect(x: l.main.x, y: l.main.y, width: l.main.width, height: l.main.height), .main, word: r.main, arrow: true)
        if let o = l.other, let word = r.other { s.block("result-other", CGRect(x: o.x, y: o.y, width: o.width, height: o.height), .plain, word: word) }
        return s
    }
}

/// A problem as its card writes it (G 20 Oct): its maths alone, the question's "= ?" left off, brackets spaced as school
/// writes them, and any words that go with it ("to the nearest hundredth", "in inches") on a row of their own under
/// it, at 20. A page's cards share one size: 36, or when any card's maths won't fit inside its frame with a square to
/// spare each side, 28, then 20, so they always fit and always match.
@MainActor
enum CardText {
    struct Parts: Equatable { let maths: MathLine; let words: String? }

    static func parts(_ d: MathLine) -> Parts {
        // the question's own tail: everything after the last = or ≈ that only words (or the box) follow
        func isQuestion(_ m: Math) -> Bool { if case .op(let o) = m { o == "=" || o == "≈" } else { false } }
        func isWords(_ m: Math) -> Bool { switch m { case .text, .box: true; default: false } }
        guard let i = d.lastIndex(where: isQuestion), d[(i + 1)...].allSatisfy(isWords) else { return Parts(maths: d, words: nil) }
        var w = d[(i + 1)...].compactMap { m -> String? in if case .text(let t) = m { t } else { nil } }.joined(separator: " ")
        for ch in ["?", "(", ")"] { w = w.replacingOccurrences(of: ch, with: " ") }
        w = w.split(separator: " ").joined(separator: " ")
        guard !w.isEmpty else { return Parts(maths: Array(d[..<i]), words: nil) }
        // "nearest hundredth": what it's rounded to; anything else is the unit it's written in ("inches")
        return Parts(maths: Array(d[..<i]), words: w.hasPrefix("nearest") ? "to the \(w)" : "in \(w)")
    }

    /// A line as one string, a space between its parts but none inside brackets: "9 + 6 × (7 − 6)".
    static func text(_ line: MathLine) -> String {
        var out = ""
        for m in line {
            let piece: String
            switch m {
            case .num(let x): piece = fmt(x)
            case .op(let o): piece = o
            case .text(let t): piece = t
            case .box: piece = "?"
            case .frac(let a, let b): piece = "\(text([a]))/\(text([b]))"
            }
            if !out.isEmpty && !out.hasSuffix("(") && piece != ")" { out += " " }
            out += piece
        }
        return out
    }

    /// A line with a fraction in it is stacked a digit to a square (Sketch.sum), the same size whatever the page's.
    static func stacked(_ m: MathLine) -> Bool { MathLineView.layout(m, size: 28).h > 2 }
    /// How wide a card's maths is written at `size`.
    static func width(_ m: MathLine, size: CGFloat) -> Double {
        if stacked(m) { return Double(MathLineView.layout(m, size: 28).w) * Paper.cell }
        return PaperText.width(text(m), PaperText.font(size, .medium, digits: true))
    }
    /// The size every card on a page is written at: the biggest of the three sizes at which every card's maths fits.
    static func size(_ lines: [MathLine], room: Double) -> CGFloat {
        [Sketch.maths, Sketch.wordSize].first { s in lines.allSatisfy { width($0, size: s) <= room } } ?? Sketch.small
    }
    /// The words' rows under the maths: one, or two when they're long.
    static func rows(_ words: String, room: Double) -> [String] {
        Array(PaperText.wrap(words, PaperText.font(Sketch.small, .regular), width: room).prefix(2))
    }

    /// Draws a card's problem in its frame: the maths centred on its rows, the words under it, the two centred together
    /// on the frame's squares.
    static func draw(_ s: inout Sketch, _ id: String, _ p: Parts, in r: CGRect, size: CGFloat) {
        let c = Paper.cell, room = r.width - 2 * c
        let words = p.words.map { rows($0, room: room) } ?? []
        // in squares: the maths two rows tall (four with a fraction), each row of words two
        let tall = stacked(p.maths) ? 4.0 : 2.0, total = tall + 2 * Double(words.count)
        let top = r.minY + ((r.height / c - total) / 2).rounded(.down) * c
        let mid = CGPoint(x: r.midX, y: top + tall / 2 * c)
        if stacked(p.maths) { s.sum(id + "sum", p.maths, at: mid, centred: true) }
        else { let t = text(p.maths); s.text(id + "sum:\(t)\(size)", t, at: mid, size: size, weight: .medium, .ink, anchor: .center) }
        for (i, line) in words.enumerated() {
            s.text(id + "words\(i):\(line)", line, at: CGPoint(x: r.midX, y: top + (tall + 1 + 2 * Double(i)) * c), size: Sketch.small, weight: .regular, .ink2, anchor: .center, digits: false)
        }
    }

    /// Every lesson's cards checked (a screenshot's check, `-shot cards-fit`): its problems from easy to hard and its
    /// test's, many of each, written as their cards write them. Returns, for each lesson, the size its cards need and any
    /// card that fits at none (none should).
    static func check() -> [String] {
        let room = BarsPage.card.width - 2 * Paper.cell
        var out: [String] = []
        for p in Map.pieces {
            guard let spec = p.spec else { continue }
            var rng = SeededRandom(seed: 7), lines: [Parts] = []
            for i in 0..<12 { for _ in 0..<40 { lines.append(parts(spec.display(spec.generate(&rng, i)))) } }
            for item in spec.check { for _ in 0..<40 { lines.append(parts(spec.display(item.draw(spec, using: &rng)))) } }
            let need = lines.map { size([$0.maths], room: room) }.min() ?? Sketch.maths
            let bad = lines.filter { l in
                width(l.maths, size: Sketch.small) > room || (l.words.map { PaperText.wrap($0, PaperText.font(Sketch.small, .regular), width: room).count > 2 } ?? false)
            }
            let widest = lines.max { width($0.maths, size: need) < width($1.maths, size: need) }
            out.append("\(spec.id): \(Int(need)) pt, widest \"\(widest.map { text($0.maths) } ?? "")\"\(widest?.words.map { " / \($0)" } ?? "")" +
                       (bad.isEmpty ? "" : "; DOESN'T FIT: \(bad.prefix(3).map { text($0.maths) })"))
        }
        return out
    }
}
