import SwiftUI

/// What 4th grade's Measurement lessons share (design/grade4.md chapter 7, the preview design/prototype/grade4-ch7.html):
/// a line of the record or a name written as words are (G 3 Nov, design/README.md "Calls made" 1): numbers tight with
/// their commas, a time or a price as one word ("3:45", "$2.75"), units as words ("ft", "mL"), fractions three squares
/// wide, signs and boxes, each in the fewest whole squares it fits.
@MainActor
enum M7 {
    enum Tok {
        case n(Int, Sketch.Colour = .ink)
        /// Maths written tight as one word: a time, a price, a decimal.
        case t(String, Sketch.Colour = .ink)
        /// A unit or a word, as the line's words.
        case w(String, Sketch.Colour = .ink)
        case op(String, Sketch.Colour = .ink)
        /// A fraction three squares wide, its line on the row's line.
        case f(Int, Int, Sketch.Colour = .ink)
        /// An answer box for a number `cells` digits long.
        case box(String, cells: Int)
        /// A fraction four squares wide whose top and bottom are boxes.
        case fb(String, String)
        case gap(Double)
        @MainActor var width: Double {
            switch self {
            case .n(let v, _): Record.width(.n(v))
            case .t(let s, _): (PaperText.width(s, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell + 0.5).rounded(.up)
            case .w(let s, _): Record.width(s)
            case .op(let o, _): Record.opWidth(o)
            case .f: 3
            case .box(_, let cells): Record.boxWidth(cells: cells, commas: true)
            case .fb: 4
            case .gap(let g): g
            }
        }
    }
    static func width(_ toks: [Tok]) -> Double { widths(toks).reduce(0, +) }

    /// A number or box written before a letter or a bracket (a coefficient: 3x, 2(n + 4)) hugs it: no square's gap.
    static func hugs(_ toks: [Tok], _ i: Int) -> Bool {
        guard i + 1 < toks.count, case .t(let s, _) = toks[i + 1], let f = s.first, f.isLetter || f == "(" else { return false }
        switch toks[i] { case .n, .box: return true; default: return false }
    }
    /// Each token's whole squares: a hugging box the fewest that fit its answer and a little room for the cursor.
    static func widths(_ toks: [Tok]) -> [Double] {
        var out: [Double] = []
        for i in toks.indices {
            // a letter after a coefficient written from a bracket ("(2x") takes the squares its ink needs past the number's
            if i >= 2, case .t(let l, _) = toks[i], case .n(let v, _) = toks[i - 1], hugs(toks, i - 1), case .t("(", _) = toks[i - 2] {
                let ink = -0.3 + Record.tightWidth(v) + 0.06 + PaperText.width(l, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell
                out.append(max(1, (ink - out[i - 1] + 0.3).rounded(.up))); continue
            }
            out.append(plain(toks, i))
        }
        return out
    }
    private static func plain(_ toks: [Tok], _ i: Int) -> Double {
        if hugs(toks, i), case .box(_, let cells) = toks[i] {
            let sample = String(repeating: "8", count: max(1, cells))
            return (PaperText.width(sample, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell + 0.75).rounded(.up)
        }
        // a lone bracket takes one square, so it sits tight against what it holds: 3(2x + 1)
        if case .t(let b, _) = toks[i], b == "(" || b == ")" { return 1 }
        return toks[i].width
    }

    /// A line from column x on the row whose middle is `line`. Returns where it ends.
    @discardableResult
    static func row(_ pen: inout GridPen, _ id: String, _ toks: [Tok], x: Double, line: Double) -> Double {
        var cx = x
        let ws = widths(toks)
        func lone(_ j: Int, _ b: String) -> Bool { if j >= 0, j < toks.count, case .t(b, _) = toks[j] { return true }; return false }
        func written(_ j: Int) -> Bool { guard j >= 0 else { return false }; switch toks[j] { case .n, .box: return true; default: return false } }
        // where a coefficient's ink ends when it's written from the left (after a bracket), for its letter to follow
        var inkEnd: Double?
        for (i, t) in toks.enumerated() {
            let k = "\(id).\(i)", w = ws[i], hug = hugs(toks, i), hugged = i > 0 && hugs(toks, i - 1)
            switch t {
            // after a bracket, a coefficient starts right after it and its letter follows its ink: (2x
            case .n(let v, let c) where hug && lone(i - 1, "("):
                pen.word(k + "n\(v)", BigNumbers.commas(v), at: cx - 0.3, line, Bars.maths.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
                inkEnd = cx - 0.3 + Record.tightWidth(v)
            // a coefficient's number ends right at its squares' edge, its letter starts right after it: 3x
            case .n(let v, let c) where hug:
                pen.word(k + "n\(v)", BigNumbers.commas(v), at: cx + w - 0.08, line, Bars.maths.colour(c), anchor: UnitPoint(x: 1, y: 0.5))
            case .n(let v, let c): Record.tight(&pen, k + "n\(v)", v, right: cx + w, row: line, c)
            case .t(let s, let c) where hugged:
                let after: Double = { if case .box = toks[i - 1] { return 0.2 } else { return 0.04 } }()
                pen.word(k + "t", s, at: inkEnd.map { $0 + 0.06 } ?? cx + after, line, Bars.maths.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
                inkEnd = nil
            // a closing bracket hugs what it closes: + 1)
            case .t(let s, let c) where s == ")" && written(i - 1):
                let after: Double = { if case .box = toks[i - 1] { return 0.2 } else { return -0.3 } }()
                pen.word(k + "t", s, at: cx + after, line, Bars.maths.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
            case .t(let s, let c): pen.word(k + "t", s, at: cx + w / 2, line, Bars.maths.colour(c))
            case .w(let s, let c): pen.word(k + "w", s, at: cx + 0.5, line, Record.words.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
            case .op(let o, let c): pen.word(k + o, o, at: cx + w / 2, line, Bars.maths.colour(c))
            case .f(let a, let b, let c): F4.frac(&pen, k, "\(a)", "\(b)", col: cx, line: line, c, w: 3)
            case .box(let b, _): pen.answerBox(b, right: cx + w, mid: line, per: 2, cells: 1, commas: true, word: w, hugs: hug)
            case .fb(let a, let b):
                F4.frac(&pen, k, nil, nil, col: cx, line: line)
                pen.answerBox(a, right: cx + 4, mid: line - 1, per: 2, cells: 2, centred: true)
                pen.answerBox(b, right: cx + 4, mid: line + 1, per: 2, cells: 2, centred: true)
            case .gap: break
            }
            cx += w
        }
        return cx
    }

    /// A hint: a dashed ring round some squares.
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
}
