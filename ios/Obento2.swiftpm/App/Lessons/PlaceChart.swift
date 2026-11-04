import SwiftUI

/// 4th grade's place chart (design/grade4.md, chapter 1; the preview design/prototype/grade4-ch1.html): a column for each
/// place, two blocks wide on the strong lines, its name over it; a disk is a dot in a cell in the chapter's colour, one of
/// its column's place. Disks fill ten-frames (2 rows of 5), one or two frames side by side in a column, frames a square
/// apart down it. Cells are 2 × 2 squares when the columns and their frames fit across the screen, else 1 square.
/// A disk keeps its id wherever it goes, so it glides there (SketchDrawer): ten that close into one glide to one place
/// and stay there as a stack; a stack that opens glides apart into a full frame.
@MainActor
struct PlaceChart {
    /// Columns, cell size in squares (1 or 2), frames side by side in a column (1 or 2), the left edge, the frames' top.
    let n: Int, c: Double, pr: Int, x0: Double, y0: Double
    /// A frame row's height and the gap under it: 5 squares for 2-square cells, 3 for 1-square.
    var period: Double { c == 2 ? 5 : 3 }
    /// A column's width: 5 cells for each frame across it.
    var cw: Double { 5 * c * Double(pr) }
    var right: Double { x0 + Double(n) * cw }
    /// A disk's radius.
    var r: Double { 0.36 * c }

    init(n: Int, c: Double, pr: Int, x0: Double = 0, y0: Double) { self.n = n; self.c = c; self.pr = pr; self.x0 = x0; self.y0 = y0 }
    /// The biggest cells that fit (the preview's cellsFor): 2-square cells, two frames across, when the columns fit the
    /// screen (64 squares) and a column needs at most `maxRows` rows; 2-square cells one frame across when that fits;
    /// else 1-square cells, two frames across.
    static func sized(n: Int, frames: Int, maxRows: Int = 6, y0: Double) -> PlaceChart {
        if n * 20 <= 64 && (frames + 1) / 2 <= maxRows { return PlaceChart(n: n, c: 2, pr: 2, y0: y0) }
        if n * 10 <= 64 && frames <= maxRows { return PlaceChart(n: n, c: 2, pr: 1, y0: y0) }
        return PlaceChart(n: n, c: 1, pr: 2, y0: y0)
    }

    /// Place p's column's left edge and middle (p 0 the ones, on the right).
    func colX(_ p: Int) -> Double { x0 + Double(n - 1 - p) * cw }
    func mid(_ p: Int) -> Double { colX(p) + cw / 2 }
    /// The place under column x, or nil.
    func place(at x: Double) -> Int? {
        let i = Int(((x - x0) / cw).rounded(.down))
        return i < 0 || i >= n ? nil : n - 1 - i
    }
    /// Frame k of place p's column: its top-left (from band top `by`).
    func frame(_ p: Int, _ k: Int, band by: Double? = nil) -> CGPoint {
        CGPoint(x: colX(p) + Double(k % pr) * 5 * c, y: (by ?? y0) + Double(k / pr) * period)
    }
    /// Where disk j of place p's column sits (filling frame after frame).
    func slot(_ p: Int, _ j: Int, band by: Double? = nil) -> CGPoint {
        let f = frame(p, j / 10, band: by), i = j % 10
        return CGPoint(x: f.x + (Double(i % 5) + 0.5) * c, y: f.y + (Double(i / 5) + 0.5) * c)
    }
    /// Frame k's middle.
    func centre(_ p: Int, _ k: Int, band by: Double? = nil) -> CGPoint { let f = frame(p, k, band: by); return CGPoint(x: f.x + 2.5 * c, y: f.y + c) }
    /// The frame a finger is on in place p's column (nil in the gap between frames), among `count` frames.
    func frame(at q: CGPoint, _ p: Int, band by: Double? = nil, count: Int) -> Int? {
        let top = by ?? y0, lx = q.x - colX(p), row = Int(((q.y - top) / period).rounded(.down))
        guard row >= 0, q.y - top - Double(row) * period <= 2 * c + 0.4, lx >= -0.3, lx <= cw + 0.3 else { return nil }
        let k = row * pr + (pr == 2 && lx >= 5 * c ? 1 : 0)
        return k < count ? k : nil
    }
    /// The last row a column of `frames` frames reaches, from the band top.
    func bottom(frames: Int, band by: Double? = nil) -> Double { (by ?? y0) + Double((max(1, frames) + pr - 1) / pr - 1) * period + 2 * c }

    /// The chart's lines: each column's frames (light, their cells finer when they're big), the columns' lines from
    /// `top` to `bottom`, and the places' names over the columns (two words on two rows), `lit` in the chapter's colour.
    func draw(_ pen: inout GridPen, _ id: String, bands: [(y: Double, frames: (Int) -> Int)], top: Double, bottom: Double, lit: Int? = nil) {
        for b in bands {
            for p in 0..<n {
                for k in 0..<b.frames(p) {
                    let f = frame(p, k, band: b.y), fid = "\(id)f\(b.y)_\(p)_\(k)"
                    pen.sketch.box(fid, pen.R(f.x, f.y, 5 * c, 2 * c), .ink3, width: Sketch.stroke)
                    if c > 1 {
                        let segs = (1..<5).map { i in (pen.P(f.x + Double(i) * c, f.y), pen.P(f.x + Double(i) * c, f.y + 2 * c)) }
                            + [(pen.P(f.x, f.y + c), pen.P(f.x + 5 * c, f.y + c))]
                        pen.sketch.segments(fid + "c", segs, .ink3, width: 1)
                    }
                }
            }
        }
        pen.sketch.segments("\(id)cols\(n)_\(top)_\(bottom)", (0...n).map { i in (pen.P(x0 + Double(i) * cw, top), pen.P(x0 + Double(i) * cw, bottom)) }, .ink, width: Sketch.stroke)
        for p in 0..<n {
            let words = BigNumbers.places[p].split(separator: " ").map(String.init), w = PlaceChart.name.colour(lit == p ? .chapter : .ink2)
            if words.count == 1 { pen.word("\(id)nm\(p)", words[0], at: mid(p), top + 1.5, w) }
            else { pen.word("\(id)nm\(p)a", words[0], at: mid(p), top + 1, w); pen.word("\(id)nm\(p)b", words[1], at: mid(p), top + 2.1, w) }
        }
    }
    static let name = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    /// A disk at a place on the paper; `striped`: a second number's (outlined, lightly filled, striped).
    func disk(_ pen: inout GridPen, _ id: String, at p: CGPoint, striped: Bool = false, faint: Bool = false) {
        PlaceChart.disk(&pen, id, at: p, r: r, striped: striped, faint: faint)
    }
    static func disk(_ pen: inout GridPen, _ id: String, at p: CGPoint, r: Double, striped: Bool = false, faint: Bool = false) {
        let c = pen.P(p.x, p.y), rr = r * Paper.cell
        let pts = (0..<24).map { i in let a = Double(i) / 24 * 2 * .pi; return CGPoint(x: c.x + rr * cos(a), y: c.y + rr * sin(a)) }
        if !striped { pen.sketch.plate("dk" + id, pts, faint ? .tint(0.35) : .chapter); return }
        pen.sketch.plate("dk" + id, pts, .tint(0.22))
        // stripes corner to corner, inside the disk
        var segs: [(CGPoint, CGPoint)] = []
        var t = -rr * 0.7
        while t <= rr * 0.7 {
            let h = sqrt(max(0, rr * rr - 2 * t * t)) / sqrt(2)
            segs.append((CGPoint(x: c.x + t - h, y: c.y - t - h), CGPoint(x: c.x + t + h, y: c.y - t + h)))
            t += rr * 0.45
        }
        pen.sketch.segments("dks" + id, segs, .chapter, width: Sketch.stroke)
        pen.sketch.overLine("dko" + id, pts + [pts[0]], .chapter, width: Sketch.stroke)
    }
}

/// A line of the record as school writes it on squared paper (the preview's mrow): numbers two squares a digit with
/// their commas on the grid lines between, signs three squares, words in whole squares, answer boxes.
@MainActor
enum Record {
    enum Token {
        case n(Int)
        /// A number's digits as text (a part being pulled down, digits only).
        case op(String)
        case w(String)
        case gap(Double)
        /// An answer box of `cells` digits, typing into the step's box `id`.
        case box(String, cells: Int)
    }
    static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    static let words = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)

    /// A word's width in whole squares, half a square either side.
    static func width(_ w: String) -> Double { (PaperText.width(w, PaperText.font(Sketch.wordSize, .medium)) / Paper.cell + 1).rounded(.up) }
    /// Laid out as words are (G 3 Nov, design/README.md "Calls made" 1): each number or sign takes the fewest whole
    /// squares its tight width fits with a quarter square either side, and the next starts on the following square, so
    /// the gaps are even ("7 × 10 = 70").
    static func width(_ t: Token) -> Double {
        switch t {
        case .n(let v): (tightWidth(v) + 0.5).rounded(.up)
        case .op(let o): opWidth(o)
        case .w(let s): width(s)
        case .gap(let g): g
        case .box(_, let cells): boxWidth(cells: cells, commas: true)
        }
    }
    static func width(_ toks: [Token]) -> Double { toks.reduce(0) { $0 + width($1) } }
    /// A sign's whole squares (2 for + − × ÷ =).
    static func opWidth(_ o: String) -> Double { (PaperText.width(o, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell + 0.5).rounded(.up) }
    /// An answer box in a line: the fewest whole squares that fit an answer `cells` digits long written tight, and room
    /// for the cursor.
    static func boxWidth(cells: Int, commas: Bool) -> Double {
        let sample = String(repeating: "8", count: max(1, cells)), text = commas && cells >= 4 ? BigNumbers.commas(Int(sample) ?? 0) : sample
        return ((PaperText.width(text, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell + 1.25)).rounded(.up)
    }

    /// A number in a line written tight, as one word (G 3 Nov, design/README.md "Calls made"): "10,935", centred in the
    /// whole squares it takes (Record.width), which end on column `right`.
    static func tight(_ pen: inout GridPen, _ id: String, _ v: Int, right: Double, row: Double, _ colour: Sketch.Colour = .ink) {
        pen.word(id, BigNumbers.commas(v), at: right - width(.n(v)) / 2, row, maths.colour(colour))
    }
    /// How wide a number written tight is, in squares.
    static func tightWidth(_ v: Int) -> Double { PaperText.width(BigNumbers.commas(v), PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell }

    /// A number in column working (a vertical sum, long division, a place chart's digits): two squares a digit, its ones
    /// digit ending on column `right`, its commas on the grid lines, so the places line up.
    static func number(_ pen: inout GridPen, _ id: String, _ v: Int, right: Double, row: Double, _ colour: Sketch.Colour = .ink) {
        let s = Array(String(v))
        for (k, ch) in s.reversed().enumerated() {
            pen.word("\(id)d\(k)", String(ch), at: right - 2 * Double(k) - 1, row, maths.colour(colour))
            if k > 0 && k % 3 == 0 { pen.word("\(id)c\(k)", ",", at: right - 2 * Double(k), row, maths.colour(colour)) }
        }
    }

    /// A line of tokens from column x on the row whose middle is `row`; `colour` per token index. Returns where it ends.
    @discardableResult
    static func line(_ pen: inout GridPen, _ id: String, _ toks: [Token], x: Double, row: Double, colours: [Int: Sketch.Colour] = [:]) -> Double {
        var cx = x
        for (i, t) in toks.enumerated() {
            let c = colours[i] ?? .ink, kid = "\(id).\(i)"
            switch t {
            case .n(let v): tight(&pen, kid + "n\(v)", v, right: cx + width(t), row: row, c)
            case .op(let o): pen.word(kid + o, o, at: cx + width(t) / 2, row, maths.colour(c))
            case .w(let s): pen.word(kid + s, s, at: cx + 0.5, row, words.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
            case .gap: break
            case .box(let b, _): pen.answerBox(b, right: cx + width(t), mid: row, per: 2, cells: 1, commas: true, word: width(t))
            }
            cx += width(t)
        }
        return cx
    }
}
