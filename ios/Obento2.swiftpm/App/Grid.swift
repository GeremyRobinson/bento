import SwiftUI

/// Pictures built in squares (G 19 Oct): the grid's own unit, so nothing can land off it. A lesson's picture says "a
/// rectangle 19 squares tall", "a number line 10 steps of 5 squares", "a label centred over these squares", never a
/// point; GridPen turns squares into the paper's points at the very end. Edges always fall on grid lines; only a word
/// or a number may sit in the middle of a square (to be centred on what it labels), and something centred on an odd
/// count of squares is an odd count itself. Its origin (0, 0) is a crossing of the grid.
/// An answer box written into the work, where the number goes (G 19 Oct: the work is where you answer), in points: its
/// right edge (numbers line up on the right, as in columns), its row's middle and a digit's cell. It's `cells` digits
/// wide at least, `spare` more than what's typed, and types into the answer's box `id` (nil: the step's first box).
struct WorkBox {
    var id: String?
    var right: Double, mid: Double, cell: Double
    var cells = 3, spare = 1
    /// Centred (a fraction's top or bottom): the box is its column, and what's typed sits in its middle.
    var centred = false
    /// A sum in columns (Adding decimals): what's typed lines up on its point, which sits on this line (in the box's
    /// points, as `right` is): the digits before the point end on it, the digits after start on it, and the point is
    /// written on the line itself, so the answer's places line up with the numbers above it. The box is its `cells`
    /// columns, ending at `right`.
    var point: Double?
    /// A centred box after an = sign (a whole number answer at the end of the record): it keeps its left edge and grows
    /// to the right as more is typed than it holds, so it never covers the =.
    var keepsLeft = false
    func moved(_ by: CGPoint) -> WorkBox { var b = self; b.right += by.x; b.mid += by.y; b.point = point.map { $0 + by.x }; return b }
    /// Where each typed character goes when the box lines up on its point: its middle's x (the point's: the line).
    func placed(_ typed: String) -> [(ch: Character, x: Double)] {
        guard let point else { return [] }
        let parts = typed.split(separator: ".", omittingEmptySubsequences: false).map(Array.init)
        let whole = parts.first ?? []
        var out = whole.enumerated().map { (ch: $0.element, x: point - (Double(whole.count - $0.offset) - 0.5) * cell) }
        if parts.count > 1 {
            out.append((ch: ".", x: point))
            out += parts[1].enumerated().map { (ch: $0.element, x: point + (Double($0.offset) + 0.5) * cell) }
        }
        return out
    }
    /// Where the cursor goes when the box lines up on its point: just past the last digit typed.
    func pointCursor(_ typed: String) -> Double? {
        guard let point else { return nil }
        guard let dot = typed.firstIndex(of: ".") else { return point + 0.15 * cell }
        let after = typed.distance(from: dot, to: typed.endIndex) - 1
        return point + (after == 0 ? 0.3 : Double(after) + 0.15) * cell
    }
    /// Its rect with `typed` in it: a box lined up on its point grows either way to hold what's typed (a 4th whole digit
    /// to the left, a 3rd decimal to the right), as a column box grows left.
    func rect(for typed: String) -> CGRect {
        guard let point else { return rect(typed: typed.count) }
        let parts = typed.split(separator: ".", omittingEmptySubsequences: false)
        let whole = Double(parts.first?.count ?? 0), after = Double(parts.dropFirst().first?.count ?? 0)
        let left = min(right - Double(cells) * cell, point - whole * cell), end = max(right, point + after * cell)
        return CGRect(x: left, y: mid - cell / 2, width: end - left + 0.5 * cell, height: cell)
    }
    /// Its rect when `typed` digits are in it, with half a cell past its right edge for the cursor.
    func rect(typed: Int = 0) -> CGRect {
        if point != nil {
            return CGRect(x: right - Double(cells) * cell, y: mid - cell / 2, width: (Double(cells) + 0.5) * cell, height: cell)
        }
        if centred {
            let n = Double(max(cells, typed)), left = right - Double(cells) * cell, mid = right - Double(cells) * cell / 2
            return CGRect(x: keepsLeft ? left : mid - n * cell / 2, y: self.mid - cell / 2, width: n * cell, height: cell)
        }
        let n = Double(max(cells, typed + spare))
        return CGRect(x: right - n * cell, y: mid - cell / 2, width: (n + 0.5) * cell, height: cell)
    }
}

@MainActor
struct GridPen {
    var sketch = Sketch()
    /// The answer box written into the work, where the number goes (G 19 Oct: the work is where you answer): its
    /// right edge (numbers line up on the right, as in columns), its row's middle, and the size of a digit's cell, in
    /// points. The box grows left as digits are typed.
    var box: (right: Double, mid: Double, cell: Double)?
    /// More than one answer box in the work (a fraction's top, a mixed number's whole and its fraction), each named by
    /// the answer's box it types into.
    var boxes: [WorkBox] = []
    /// The words' size: 1, or a whole number bigger in a big problem (its squares stay the paper's).
    let k: Double
    /// Words keep the id they're given, whatever they say (a live part: a count that changes as the hand moves is the
    /// same part, written again at once). Otherwise what they say is part of their id, so new words draw in.
    var stableIds = false
    static let sq = Paper.cell

    init(k: Double = 1, stableIds: Bool = false) { self.k = k; self.stableIds = stableIds }

    /// An answer box `cells` digits wide whose right edge is column `right`, on the row whose middle is `mid` (a digit is
    /// `per` squares): it grows left as digits are typed, so they line up on the right as written work does.
    /// `keepsLeft`: a centred box that grows to the right (WorkBox.keepsLeft).
    mutating func answerBox(_ id: String, right: Double, mid: Double, per: Double, cells: Int, spare: Int = 0, centred: Bool = false, point: Double? = nil, keepsLeft: Bool = false) {
        boxes.append(WorkBox(id: id, right: P(right, 0).x, mid: P(0, mid).y, cell: per * Self.sq, cells: cells, spare: spare, centred: centred,
                             point: point.map { P($0, 0).x }, keepsLeft: keepsLeft))
    }

    /// Every box the work has: the one `box`, then the named ones.
    var allBoxes: [WorkBox] { (box.map { [WorkBox(id: nil, right: $0.right, mid: $0.mid, cell: $0.cell)] } ?? []) + boxes }

    /// A place on the grid, in squares across and down from the origin.
    func P(_ col: Double, _ row: Double) -> CGPoint { CGPoint(x: col * Self.sq, y: row * Self.sq) }
    func R(_ col: Double, _ row: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: col * Self.sq, y: row * Self.sq, width: w * Self.sq, height: h * Self.sq) }

    // MARK: words and numbers

    /// Words centred on a place (the middle of what they label), in a kind of words; `size` overrides its size.
    mutating func word(_ id: String, _ text: String, at col: Double, _ row: Double, _ w: Sketch.Words, anchor: UnitPoint = .center) {
        sketch.text(stableIds ? id : "\(id):\(text)", text, at: P(col, row), size: w.size * k, weight: w.weight, w.colour, anchor: anchor, digits: true)
    }
    enum Side { case above, below, left, right }
    /// A label on one side of what it labels (G 19 Oct): its ink always half a square from that edge, whichever side,
    /// however many digits; `edge` is the edge's row (above, below) or column (left, right), `along` the middle of
    /// what it labels the other way.
    mutating func label(_ id: String, _ text: String, _ w: Sketch.Words, _ side: Side, edge: Double, along: Double) {
        let f = PaperText.font(w.size * k, w.weight, digits: true), gap = 0.5 * k
        // a centred line sits on its capitals' middle (SketchDrawer), so half their height clears the edge
        let cap = Double(f.capHeight) / Self.sq
        let at: CGPoint, anchor: UnitPoint
        switch side {
        case .above: at = P(along, edge - gap - cap / 2); anchor = .center
        case .below: at = P(along, edge + gap + cap / 2); anchor = .center
        case .left: at = P(edge - gap, along); anchor = UnitPoint(x: 1, y: 0.5)
        case .right: at = P(edge + gap, along); anchor = UnitPoint(x: 0, y: 0.5)
        }
        sketch.text(stableIds ? id : "\(id):\(text)", text, at: at, size: w.size * k, weight: w.weight, w.colour, anchor: anchor, digits: true)
    }

    /// A number in its squares: `per` squares to a digit, the ones digit ending on column `right`, the point on the
    /// grid line between two digits (as school writes it on squared paper), centred down `row`.
    mutating func digits(_ id: String, _ text: String, right: Double, row: Double, per: Double, size: CGFloat = Sketch.maths, _ colour: Sketch.Colour = .ink) {
        var col = 0.0
        for (i, ch) in Array(text).enumerated().reversed() {
            // the point on the grid line between its digits, level with them (its glyph sits it on their baseline)
            // the point sits on the baseline: its line box is placed as the digits' are, not centred on its own ink
            if ch == "." { sketch.text("\(id).", ".", at: P(right - col, row), size: size * k, weight: .bold, colour, anchor: UnitPoint(x: 0.5, y: 0.49)); continue }
            sketch.text("\(id)\(i)", String(ch), at: P(right - col - per / 2, row), size: size * k, colour)
            col += per
        }
    }

    // MARK: lines

    /// A rule along a grid line (school work's line, a total's line).
    mutating func rule(_ id: String, from c0: Double, to c1: Double, row: Double, _ colour: Sketch.Colour = .ink, width: Double = Sketch.stroke) {
        sketch.line(id, [P(c0, row), P(c1, row)], colour, width: width)
    }
    /// A bracket under some squares, its ends a square tall, and its words in the row under it.
    mutating func bracket(_ id: String, from c0: Double, to c1: Double, row: Double, _ text: String, _ w: Sketch.Words = .message, tick: Double = 1) {
        sketch.line(id, [P(c0, row - tick), P(c0, row), P(c1, row), P(c1, row - tick)], w.colour, width: Sketch.stroke)
        word(id + "w", text, at: c0, row + tick, w, anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// An arc hopping from one column to another over `row`, rising `height` squares.
    mutating func hop(_ id: String, from c0: Double, to c1: Double, row: Double, height: Double, _ colour: Sketch.Colour = .chapter) {
        let pts = (0...16).map { i -> CGPoint in let t = Double(i) / 16; return P(c0 + (c1 - c0) * t, row - sin(.pi * t) * height) }
        sketch.line(id, pts, colour, width: Sketch.stroke)
    }
    /// A dot on the grid (a number's place on a line). `over`: it sits over the lines (a handle, a mark on a cut).
    mutating func dot(_ id: String, at col: Double, _ row: Double, radius: Double = 0.35, _ colour: Sketch.Colour = .chapter, over: Bool = false) {
        let c = P(col, row), r = radius * Self.sq
        let pts = (0..<24).map { i in let a = Double(i) / 24 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
        if over { sketch.plate(id, pts, colour) } else { sketch.polygon(id, pts, colour) }
    }
    /// A circle round a place (a hint: look here), solid or dashed.
    mutating func circle(_ id: String, at col: Double, _ row: Double, radius: Double, _ colour: Sketch.Colour = .chapter, dashed: Bool = false) {
        let c = P(col, row), r = radius * Self.sq
        let pts = (0...40).map { i in let a = Double(i) / 40 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
        if dashed { sketch.segments(id, Self.dashes(pts), colour, width: Sketch.stroke) }
        else { sketch.line(id, pts, colour, width: Sketch.stroke) }
    }
    /// A curve cut into dashes along its whole length (a straight line's own dashes are cut segment by segment, which
    /// leaves a curve's short segments whole): about 5 points drawn, 5 left, as chords of the curve.
    static func dashes(_ pts: [CGPoint], on: Double = 5, off: Double = 5) -> [(CGPoint, CGPoint)] {
        var out: [(CGPoint, CGPoint)] = [], pos = 0.0
        let period = on + off
        for (a, b) in zip(pts, pts.dropFirst()) {
            let len = hypot(b.x - a.x, b.y - a.y)
            guard len > 0 else { continue }
            var t = 0.0
            while t < len {
                // where in the pattern this point is, and how far to the next change
                let phase = (pos + t).truncatingRemainder(dividingBy: period), drawing = phase < on
                let step = min(len - t, drawing ? on - phase : period - phase)
                if drawing {
                    let f0 = t / len, f1 = (t + step) / len
                    out.append((CGPoint(x: a.x + (b.x - a.x) * f0, y: a.y + (b.y - a.y) * f0), CGPoint(x: a.x + (b.x - a.x) * f1, y: a.y + (b.y - a.y) * f1)))
                }
                t += max(step, 0.01)
            }
            pos += len
        }
        return out
    }
    /// A line through places on the grid, solid or dashed.
    mutating func line(_ id: String, _ pts: [(Double, Double)], _ colour: Sketch.Colour = .ink, dashed: Bool = false) {
        sketch.line(id, pts.map { P($0.0, $0.1) }, colour, width: Sketch.stroke, dashed: dashed)
    }
    /// Squares filled (a piece shaded, a block lit).
    mutating func fill(_ id: String, col: Double, row: Double, w: Double, h: Double, _ colour: Sketch.Colour) {
        sketch.fill(id, R(col, row, w, h), colour)
    }
    /// Squares striped (the second amount): lightly filled, a stripe corner to corner of every square.
    mutating func stripes(_ id: String, col: Double, row: Double, w: Double, h: Double) {
        sketch.fill(id + "f", R(col, row, w, h), .tint(0.2))
        var segs: [(CGPoint, CGPoint)] = []
        var t = -h
        while t < w {
            segs.append((P(col + max(0, t), row + max(0, -t)), P(col + min(w, t + h), row + min(h, w - t))))
            t += 1
        }
        sketch.segments(id + "s", segs, .tint(0.6), width: Sketch.stroke)
    }
    /// A ring round some squares (a digit to look at).
    mutating func ring(_ id: String, col: Double, row: Double, w: Double, h: Double, _ colour: Sketch.Colour = .chapter) {
        let c = P(col + w / 2, row + h / 2), rx = w / 2 * Self.sq, ry = h / 2 * Self.sq
        sketch.line(id, (0...32).map { i in let a = Double(i) / 32 * 2 * .pi; return CGPoint(x: c.x + rx * cos(a), y: c.y + ry * sin(a)) }, colour, width: Sketch.stroke)
    }

    // MARK: pieces

    /// A bar one whole long (`length` squares) cut into `parts` equal pieces, each a whole number of squares (the
    /// caller picks a length every part divides): pieces from `from` for `shaded` filled (striped for a second
    /// amount), some struck out, lit when it's the one being looked at.
    mutating func bar(_ id: String, col: Double, row: Double, length: Int, height: Double = 2, parts: Int, shaded: Int, from: Int = 0,
                      striped: Bool = false, lit: Bool = false, struck: Range<Int>? = nil) {
        let per = Double(length / max(1, parts)), tag = "\(id)\(parts)\(lit)"
        for i in 0..<max(1, parts) {
            let r = R(col + Double(i) * per, row, per, height)
            if i >= from && i < from + shaded {
                sketch.fill("\(tag)f\(i)\(striped)", r, lit ? .tint(0.45) : .tint(0.25))
                if striped {
                    // stripes a square apart, corner to corner of each square
                    var segs: [(CGPoint, CGPoint)] = []
                    var t = -height
                    while t < per { segs.append((P(r.minX / Self.sq + max(0, t), r.minY / Self.sq + max(0, -t)), P(r.minX / Self.sq + min(per, t + height), r.minY / Self.sq + min(height, per - t)))); t += 1 }
                    sketch.segments("\(tag)s\(i)", segs, .tint(0.65), width: 1.5)
                }
            }
            if let st = struck, st.contains(i) { sketch.line("\(tag)x\(i)", [P(r.minX / Self.sq + 0.3, r.maxY / Self.sq - 0.3), P(r.maxX / Self.sq - 0.3, r.minY / Self.sq + 0.3)], .ink2, width: Sketch.stroke) }
        }
        sketch.box("\(tag)o", R(col, row, Double(length), height), lit ? .chapter : .tint(0.7), width: Sketch.stroke)
        if parts > 1 {
            sketch.segments("\(tag)cuts", (1..<parts).map { i in (P(col + Double(i) * per, row), P(col + Double(i) * per, row + height)) }, lit ? .chapter : .tint(0.7), width: 1.5)
        }
    }

    /// A line of math on the squares, a digit to a square (fractions stacked: their bar on the row `row` + 2).
    mutating func math(_ id: String, _ line: MathLine, col: Double, row: Double, size: CGFloat = 26) {
        sketch.mathLine(id, line, at: P(col, row), size: size * k, cell: Self.sq * k)
    }

    /// A rectangle of squares, one for each unit (an area model, an array): its outline strokes on, then every square,
    /// then every ten stronger, then its fill under them. Lit, it's the part being worked.
    mutating func squares(_ id: String, col: Double, row: Double, cols: Int, rows: Int, lit: Bool) {
        let r = R(col, row, Double(cols), Double(rows)), tag = "\(id)\(lit)"
        sketch.box(tag + "o", r, .chapter, width: Sketch.stroke)
        func lines(every: Int) -> [(CGPoint, CGPoint)] {
            stride(from: every, to: cols, by: every).map { j in (P(col + Double(j), row), P(col + Double(j), row + Double(rows))) }
                + stride(from: every, to: rows, by: every).map { j in (P(col, row + Double(j)), P(col + Double(cols), row + Double(j))) }
        }
        sketch.segments(tag + "c", lines(every: 1), lit ? .tint(0.6) : .tint(0.42), width: 1)
        sketch.segments(tag + "t", lines(every: 10), .tint(lit ? 1 : 0.8), width: Sketch.stroke)
        sketch.fill(tag + "f", r, lit ? .tint(0.38) : .tint(0.16))
    }

    /// A plate of paper over squares (a number written on a picture), centred on (col, row) and sized in whole
    /// squares that keep it centred: odd across an odd span, odd down an odd one.
    mutating func plate(_ id: String, over span: (cols: Int, rows: Int), at col: Double, _ row: Double, w: Int, h: Int) {
        let across = w + (span.cols - w) % 2, down = h + (span.rows - h) % 2
        sketch.plate(id, R(col + Double((span.cols - across) / 2), row + Double((span.rows - down) / 2), Double(across), Double(down)), .paper)
    }

    /// A number line along `row` from column `col`: `steps` steps of `per` squares each, a short tick on each step
    /// (a square tall, above the line) and a long one every `long` steps (two squares). Halfway is always a grid line
    /// when `steps` is even. Returns the column of step `i` for placing things on it.
    @discardableResult
    mutating func numberLine(_ id: String, col: Double, row: Double, steps: Int, per: Double, long: Int, _ colour: Sketch.Colour = .ink) -> (Int) -> Double {
        let end = col + Double(steps) * per
        sketch.line(id, [P(col, row), P(end, row)], colour, width: Sketch.stroke)
        sketch.segments(id + "ticks", (0...steps).map { i in
            let x = col + Double(i) * per, tall = i % long == 0
            return (P(x, row - (tall ? 2 : 1)), P(x, row))
        }, colour, width: Sketch.stroke)
        return { i in col + Double(i) * per }
    }
}
