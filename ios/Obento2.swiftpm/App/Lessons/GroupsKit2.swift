import SwiftUI

/// What 2nd grade's chapter 3, Equal groups, shares on the paper (the preview design/prototype/grade2-ch3.html): a grid of
/// blocks (an array's dots, a rectangle's square tiles), "Tap each row" (a tap or a sweep along a row lights it and numbers
/// it at the left; a sweep down a column is a miss), the readout in the chapter colour beside the picture, the record
/// `4 + 4 + 4 = [ ]` and the running totals that write in at the rows' right ends once it's right.
///
/// Kept: "l0", "l1"… the rows lit, in the order they were tapped. Hand: "grab", "ax", "ay", "bx", "by" a sweep.
@MainActor
enum EG2 {
    /// rows × cols blocks of `size` squares from (x, y).
    struct Grid { let x: Double, y: Double, rows: Int, cols: Int; var size = 5.0
        var w: Double { size * Double(cols) }
        var h: Double { size * Double(rows) }
        func row(_ q: CGPoint) -> Int? {
            guard q.x >= x - 0.5, q.x <= x + w + 0.5, q.y >= y, q.y < y + h else { return nil }
            return min(rows - 1, Int((q.y - y) / size))
        }
        func mid(_ r: Int) -> Double { y + size * (Double(r) + 0.5) }
    }
    static let say = KK.words.colour(.chapter)

    /// The rows lit, in order; once the step that lights them is past, every row (in order) if none were kept.
    static func lit(_ s: PaperState, rows: Int, past: Bool) -> [Int] {
        var out: [Int] = []
        while let r = s.run.kept["l\(out.count)"] { out.append(Int(r.rounded())) }
        return past && out.count < rows ? Array(0..<rows) : out
    }

    /// "Tap each row": a tap, or a sweep along a row, lights it; all lit sets `box` to the rows and checks; a sweep down a
    /// column checks −1 ("That goes down. Rows go across.").
    static func rowHands(_ s: PaperState, _ G: Grid, box: String) -> Hands {
        let L = lit(s, rows: G.rows, past: false)
        func light(_ r: Int) -> HandMove {
            guard !L.contains(r) else { return HandMove(hand: [:]) }
            let all = L.count + 1 == G.rows
            return HandMove(hand: [:], missHand: [:], set: all ? [(box, Double(G.rows))] : [], keep: ["l\(L.count)": Double(r)], check: all)
        }
        return Hands(
            tap: { q in G.row(q).map(light) },
            grab: { q in G.row(q) == nil ? nil : ["grab": 1, "ax": q.x, "ay": q.y, "bx": q.x, "by": q.y] },
            drag: { q, h in var h = h; h["bx"] = q.x; h["by"] = q.y; return h },
            release: { h in
                let a = CGPoint(x: h["ax"] ?? 0, y: h["ay"] ?? 0), dx = (h["bx"] ?? a.x) - a.x, dy = (h["by"] ?? a.y) - a.y
                if abs(dy) > G.size * 0.8 && abs(dy) > abs(dx) { return HandMove(hand: [:], missHand: [:], set: [(box, -1)], check: true) }
                return G.row(a).map(light) ?? HandMove(hand: [:])
            })
    }

    /// The rows lit: a light band on each (while they're being tapped) and its number at the left, in the chapter colour;
    /// the sweep under the finger lit live. Hints: a miss rings the rows not lit yet; a second dashes the next one's band.
    static func drawRows(_ pic: inout GridPen, _ live: inout GridPen, _ s: PaperState, _ G: Grid, tapping: Bool, past: Bool) {
        let L = lit(s, rows: G.rows, past: past)
        for (i, r) in L.enumerated() {
            if tapping { pic.fill("band\(r)", col: G.x, row: G.y + G.size * Double(r), w: G.w, h: G.size, .tint(0.2)) }
            pic.word("rn\(r).\(i)", "\(i + 1)", at: G.x - 0.5, G.mid(r), say, anchor: UnitPoint(x: 1, y: 0.5))
        }
        guard tapping else { return }
        if s.grabbed, let r = G.row(CGPoint(x: s.h("ax") ?? 0, y: s.h("ay") ?? 0)), !L.contains(r) {
            live.fill("sweep", col: G.x, row: G.y + G.size * Double(r), w: G.w, h: G.size, .tint(0.12))
        }
        let todo = (0..<G.rows).filter { !L.contains($0) }
        if s.on("ring") || s.on("spot") { for r in todo { KK.hintBox(&pic, "hr\(r)", x: G.x, y: G.y + G.size * Double(r), w: G.w, h: G.size) } }
        if s.on("spot"), let r = todo.first { pic.line("sp\(r)", [(G.x + 0.5, G.mid(r)), (G.x + G.w - 0.5, G.mid(r))], .chapter, dashed: true) }
    }

    /// The readout beside the picture, in the chapter colour (live: it changes as the hand moves).
    static func readout(_ pen: inout GridPen, _ text: String, x: Double, y: Double) {
        pen.word("ro", text, at: x, y, say, anchor: UnitPoint(x: 0, y: 0.5))
    }

    /// The running totals at the rows' right ends (4, 8, 12): they prove the sum once it's written.
    static func totals(_ pen: inout GridPen, _ G: Grid, per: Int, x: Double) {
        for r in 0..<G.rows { pen.word("tot\(r)", "\(per * (r + 1))", at: x, G.mid(r), say, anchor: UnitPoint(x: 0, y: 0.5)) }
    }

    /// `4 + 4 + 4 =` then the box (or the answer, once it's right), from column x on the record's line 1; then a word.
    @discardableResult
    static func record(_ pen: inout GridPen, rows: Int, cols: Int, x: Double, box: String, cells: Int, done: Int?, word: String? = nil) -> Double {
        var toks: [M7.Tok] = []
        for i in 0..<rows { if i > 0 { toks.append(.op("+")) }; toks.append(.n(cols)) }
        toks.append(.op("="))
        toks.append(done.map { .n($0, .chapter) } ?? .box(box, cells: cells))
        if let word { toks.append(.w(word)) }
        return M7.row(&pen, "rec", toks, x: x, line: 1)
    }
    static func recordWidth(rows: Int, cols: Int, cells: Int, word: String? = nil) -> Double {
        var toks: [M7.Tok] = []
        for i in 0..<rows { if i > 0 { toks.append(.op("+")) }; toks.append(.n(cols)) }
        toks += [.op("="), .box("x", cells: cells)] + (word.map { [M7.Tok.w($0)] } ?? [])
        return M7.width(toks)
    }
    static func ceil5(_ v: Double) -> Double { (v / 5).rounded(.up) * 5 }
}
