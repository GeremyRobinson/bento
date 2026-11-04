import SwiftUI

/// What 6th grade's Data lessons share (design/grade6.md chapter 8, the preview design/prototype/grade6-ch8.html): one
/// square for one of what was counted. The question over the picture, written as words; the answers waiting as cards
/// (4 × 2 squares, 8 to a row a square apart, crossed off once placed; the next one in the chapter's colour), each a dot
/// or a square gliding from its card onto its stack (4th grade's line plots' X's do the same); bars of squares, each
/// number written tight under its bar. The rest is borrowed: chapter 1's handle and ring (R6), its words.
@MainActor
enum D8 {
    static let small = R6.small, lit = R6.lit, maths = R6.maths, words = R6.words
    static let fill = Sketch.Colour.tint(0.22), strong = Sketch.Colour.tint(0.42)

    // MARK: the question

    /// The question's rows wrapped `width` squares wide.
    static func rows(_ text: String, width: Double) -> [String] {
        PaperText.wrap(text, PaperText.font(words.size, words.weight), width: width * Paper.cell)
    }
    /// The question written from (0, row 1), a row of two squares each line. Returns how many rows.
    @discardableResult
    static func question(_ pen: inout GridPen, _ text: String, width: Double, top: Double = 0) -> Int {
        let r = rows(text, width: width)
        for (i, line) in r.enumerated() { pen.word("q\(i)", line, at: 0, top + 1 + 2 * Double(i), words, anchor: UnitPoint(x: 0, y: 0.5)) }
        return r.count
    }

    // MARK: cards

    /// Card j's top-left, the cards from row `y0`.
    static func card(_ j: Int, y0: Double) -> CGPoint { CGPoint(x: 5 * Double(j % 8), y: y0 + 3 * Double(j / 8)) }
    static func cardsHeight(_ n: Int) -> Double { 3 * Double((n + 7) / 8) - 1 }
    enum CardState { case idle, now, done, held }
    /// A card with its number written tight in its middle: in ink, the next one in the chapter's colour, a placed one
    /// faint and crossed off.
    static func card(_ pen: inout GridPen, _ id: String, at p: CGPoint, _ v: Int, _ st: CardState) {
        let c: Sketch.Colour = st == .now || st == .held ? .chapter : st == .done ? .ink3 : .ink
        if st == .held { pen.sketch.plate(id + "bg", pen.R(p.x, p.y, 4, 2), .paper) }
        pen.sketch.box(id + "o\(st)", pen.R(p.x, p.y, 4, 2), c, width: Sketch.stroke)
        pen.word(id + "v\(st)", "\(v)", at: p.x + 2, p.y + 1, maths.colour(st == .done ? .ink3 : .ink))
        if st == .done { pen.line(id + "x", [(p.x + 0.4, p.y + 1), (p.x + 3.6, p.y + 1)], .ink3) }
    }
    /// The card under a finger (not placed yet).
    static func cardAt(_ q: CGPoint, n: Int, y0: Double, placed: (Int) -> Bool) -> Int? {
        (0..<n).first { j in
            let p = card(j, y0: y0)
            return !placed(j) && q.x >= p.x - 0.3 && q.x <= p.x + 4.3 && q.y >= p.y - 0.3 && q.y <= p.y + 2.3
        }
    }

    // MARK: a stack of answers placed one by one

    /// Cards placed so far: each card's place in the order they went down (1, 2, …), from the hand while it's being
    /// done, kept after it (LessonRun.kept), so every stack stays in the order it was built.
    static func order(_ s: PaperState, n: Int) -> [Int: Int] {
        var out: [Int: Int] = [:]
        for j in 0..<n { if let p = s.h("p\(j)") ?? s.run.kept["p\(j)"] { out[j] = Int(p.rounded()) } }
        return out
    }
    /// Every card, in order: placed in the order they went down, the rest after them by their own order.
    static func sequence(_ placed: [Int: Int], n: Int) -> [Int] {
        (0..<n).sorted { a, b in (placed[a] ?? 1000 + a) < (placed[b] ?? 1000 + b) }
    }
    /// The hand and what's kept once card j goes down.
    static func placing(_ j: Int, _ hand: Numbers, placed: [Int: Int]) -> (hand: Numbers, keep: Numbers) {
        var h = hand.filter { $0.key.hasPrefix("p") }
        let p = Double((placed.values.max() ?? 0) + 1)
        h["p\(j)"] = p
        return (h, ["p\(j)": p])
    }

    /// What's drawn at `from`'s shapes before it glides to where it's drawn (a dot or a square off its card): the parts
    /// a builder draws there, by id.
    static func glide(_ pen: inout GridPen, from build: (inout GridPen) -> Void) {
        var was = GridPen()
        build(&was)
        for it in was.sketch.items { pen.sketch.from[it.id] = it.kind }
    }

    /// The same for a shape the parts pass through on the way (Sketch.via): they rest there a beat, then go on.
    static func via(_ pen: inout GridPen, _ build: (inout GridPen) -> Void) {
        var was = GridPen()
        build(&was)
        for it in was.sketch.items { pen.sketch.via[it.id] = it.kind }
    }

    // MARK: bars of squares

    /// A bar's squares from its bottom row `base` up, `w` wide: each square its own outlined block (so each one dropped
    /// draws in or glides by itself), tinted. `from` u: the first square drawn.
    static func bar(_ pen: inout GridPen, _ id: String, x: Double, base: Double, w: Double, h: Int, from u0: Int = 0, _ tint: Sketch.Colour = D8.fill) {
        guard h > u0 else { return }
        for u in u0..<h { square(&pen, "\(id)_\(u)", x: x, y: base - Double(u) - 1, w: w, h: 1, tint) }
    }
    /// One block: tinted, outlined in the chapter's colour.
    static func square(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, _ tint: Sketch.Colour = D8.fill, edge: Sketch.Colour = .chapter) {
        pen.fill(id + "f", col: x, row: y, w: w, h: h, tint)
        pen.sketch.box(id + "o", pen.R(x, y, w, h), edge, width: Sketch.stroke)
    }
    /// A number written tight, centred under a bar `w` wide (its middle on the row under the bar's bottom).
    static func under(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, base: Double, w: Double = 4, _ c: Sketch.Colour = .ink) {
        pen.label(id + text, text, maths.colour(c), .below, edge: base, along: x + w / 2)
    }
    /// Bars 4 squares wide, 2 apart: bar j's left edge.
    static func barX(_ j: Int) -> Double { 6 * Double(j) }
    /// The bar under a finger (`m` squares of slack either side), if any.
    static func barAt(_ q: CGPoint, n: Int, margin m: Double = 0) -> Int? { (0..<n).first { q.x >= barX($0) - m && q.x <= barX($0) + 4 + m } }
    /// A record that breaks onto a second line (at its "=") when it's wider than `room`: where each part starts.
    static func split(_ a: [M7.Tok], _ b: [M7.Tok], room: Double) -> Bool { M7.width(a) + M7.width(b) > room }

    /// The pill's readout and the paper's, beside what's moving.
    static func readout(_ pen: inout GridPen, _ text: String, x: Double, y: Double, held: Bool) {
        pen.word("rd", text, at: x, y, lit, anchor: UnitPoint(x: 0, y: 0.5))
        if held { pen.reads(text) }
    }

    /// The tight widths of record tokens (M7) for a line of numbers and signs.
    static func plus(_ v: [Int], _ c: Sketch.Colour = .ink) -> [M7.Tok] {
        v.enumerated().flatMap { j, u -> [M7.Tok] in (j > 0 ? [.op("+")] : []) + [.n(u, c)] }
    }
    /// (3 + 5 + 7 + 9) ÷ 4: the brackets tight against the numbers they hold.
    static func shared(_ v: [Int], by n: Int) -> [M7.Tok] {
        guard let first = v.first else { return [] }
        return [.t("(\(first)")] + v.dropFirst().flatMap { u -> [M7.Tok] in [.op("+"), .n(u)] } + [.t(")"), .op("÷"), .n(n)]
    }
    /// A box the record will ask for later, faint, at token `i` of a line from column x (its line's middle on `line`).
    static func waiting(_ pen: inout GridPen, _ id: String, _ toks: [M7.Tok], _ i: Int, x: Double, line: Double) {
        let w = M7.widths(toks), x0 = x + w[..<i].reduce(0, +)
        pen.sketch.box(id, pen.R(x0 + 0.25, line - 1, w[i] - 0.5, 2), .ink3, width: Sketch.stroke)
    }
}
