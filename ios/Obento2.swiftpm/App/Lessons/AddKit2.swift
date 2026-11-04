import SwiftUI

/// What 2nd grade's chapter 1, Adding and subtracting to 100, shares on the paper (the preview
/// design/prototype/grade2-ch1.html): tens and ones counters 2 × 2 squares, a ten a closed row of ten (20 × 2, faint inner
/// lines, the chapter's outline), rows 3 squares apart so every fifth counter ends on a strong line; the column form two
/// squares a digit; a story on the picture's top rows (its numbers in the chapter colour); the bars to 100.
@MainActor
enum A2 {
    enum Style { case solid, striped, dashed }
    static let row = 3.0
    static let words = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let maths = KK.maths
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    static let carry = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)

    /// A counter in the 2 × 2 cell from (x, y). `cross`: taken away. `n`: its count written on it.
    static func counter(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ style: Style, cross: Bool = false, n: Int? = nil, size: Double = 2) {
        let r = size == 3 ? 1.2 : 0.8, cx = x + size / 2, cy = y + size / 2
        let ring = (0..<32).map { i in let a = Double(i) / 32 * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) }
        switch style {
        case .solid:
            pen.sketch.polygon(id + "f", ring, .tint(0.4))
            pen.circle(id + "o", at: cx, cy, radius: r, .chapter)
        case .striped:
            pen.sketch.polygon(id + "f", ring, .tint(0.2))
            var segs: [(CGPoint, CGPoint)] = []
            for k in -2...2 {
                let d = Double(k) * (size == 3 ? 0.7 : 0.5)
                guard abs(d) < r - 0.1 else { continue }
                let half = (r * r - d * d).squareRoot() / 2.0.squareRoot(), mx = cx + d / 2.0.squareRoot(), my = cy - d / 2.0.squareRoot()
                segs.append((pen.P(mx - half, my - half), pen.P(mx + half, my + half)))
            }
            pen.sketch.segments(id + "s", segs, .tint(0.6), width: Sketch.stroke)
            pen.circle(id + "o", at: cx, cy, radius: r, .chapter)
        case .dashed:
            pen.circle(id + "o", at: cx, cy, radius: r, .ink, dashed: true)
        }
        if cross { let d = r * 0.9; pen.line(id + "x", [(cx - d, cy + d), (cx + d, cy - d)]); pen.line(id + "y", [(cx - d, cy - d), (cx + d, cy + d)]) }
        if let n { pen.word("\(id)n\(n)", "\(n)", at: cx, cy, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)) }
    }

    /// A ten from (x, y): one strip 20 × 2, filled (tinted or striped) or dashed, its inner lines faint, a bold outline.
    static func ten(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ style: Style, cross: Bool = false) {
        switch style {
        case .solid: pen.fill(id + "f", col: x, row: y, w: 20, h: 2, .tint(0.4))
        case .striped: pen.stripes(id + "f", col: x, row: y, w: 20, h: 2)
        case .dashed: break
        }
        pen.sketch.segments(id + "i", (1..<10).map { i in (pen.P(x + 2 * Double(i), y), pen.P(x + 2 * Double(i), y + 2)) }, .ink3, width: 1)
        pen.sketch.box(id + "g\(style == .dashed)", pen.R(x, y, 20, 2), style == .dashed ? .ink : .chapter, width: Sketch.stroke, dashed: style == .dashed)
        if cross { pen.line(id + "x", [(x, y + 2), (x + 20, y)]) }
    }

    /// Each part `draw` makes, by id: where parts start from (Sketch.from) when they were let go somewhere else.
    static func kinds(_ draw: (inout GridPen) -> Void) -> [String: Sketch.Kind] { T1.kinds(draw) }

    // MARK: the column form

    /// The column form from (x, y): each number two squares a digit, its last digit ending at x + 6; the sign by the last
    /// number; the rule under them. Returns the answer's row middle (the row under the rule).
    @discardableResult
    static func column(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ nums: [Int], sign: String) -> Double {
        for (i, n) in nums.enumerated() { pen.digits("\(id)n\(i)", "\(n)", right: x + 6, row: y + 1 + 2 * Double(i), per: 2) }
        pen.word("\(id)s", sign, at: x + 1, y + 1 + 2 * Double(nums.count - 1), maths)
        pen.rule("\(id)r", from: x, to: x + 6, row: y + 2 * Double(nums.count))
        return y + 2 * Double(nums.count) + 1
    }
    /// The answer under the rule: its box (typed, two squares a digit), or the answer written in the chapter colour.
    static func answer(_ pen: inout GridPen, _ id: String, x: Double, mid: Double, done: Int?) {
        if let done { pen.digits(id + "d", "\(done)", right: x + 6, row: mid, per: 2, .chapter) }
        else { pen.answerBox("x", right: x + 6, mid: mid, per: 2, cells: 2) }
    }

    // MARK: a story on the top rows

    /// The story's rows: sentences joined while they fit `width` squares, a long one wrapped.
    static func storyRows(_ sentences: [String], width: Double) -> [String] {
        let f = PaperText.font(words.size, words.weight), w = width * Paper.cell
        var rows: [String] = [], cur = ""
        for s in sentences {
            let joined = cur.isEmpty ? s : cur + " " + s
            if PaperText.width(joined, f) <= w { cur = joined } else { if !cur.isEmpty { rows.append(cur) }; cur = s }
        }
        if !cur.isEmpty { rows.append(cur) }
        return rows.flatMap { PaperText.width($0, f) <= w ? [$0] : PaperText.wrap($0, f, width: w) }
    }
    /// The story written from the picture's top-left, a row of 2 squares a line, its numbers in the chapter colour.
    /// Returns the rows it took.
    @discardableResult
    static func tell(_ pen: inout GridPen, _ sentences: [String], width: Double) -> Int {
        let rows = storyRows(sentences, width: width), space = KK.width("a a", words) - KK.width("aa", words)
        for (r, line) in rows.enumerated() {
            var x = 0.0
            for (k, w) in line.split(separator: " ").enumerated() {
                let word = String(w), lit = word.first?.isNumber == true
                pen.word("st\(r).\(k)\(word)", word, at: x, 1 + 2 * Double(r), lit ? words.colour(.chapter) : words, anchor: UnitPoint(x: 0, y: 0.5))
                x += KK.width(word, words) + space
            }
        }
        return rows.count
    }

    // MARK: the bars to 100

    /// A bar from column x on row y, `w` squares long, 4 tall: tinted, lit, striped, dashed or a faint ghost, a bold line
    /// inside it every ten things (counted from `from`, things per square `u`), its number (or ?) in its middle.
    enum Bar { case tint, lit, stripe, dash, ghost }
    static func bar(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, _ style: Bar, u: Int = 1, from: Int = 0,
                    n: String? = nil, nc: Sketch.Colour = .ink, cross: Bool = false) {
        switch style {
        case .tint: pen.fill(id + "f", col: x, row: y, w: w, h: 4, .tint(0.2))
        case .lit: pen.fill(id + "f", col: x, row: y, w: w, h: 4, .tint(0.4))
        case .stripe: pen.stripes(id + "f", col: x, row: y, w: w, h: 4)
        case .dash, .ghost: break
        }
        let dashed = style == .dash || style == .ghost
        pen.sketch.box("\(id)o\(dashed)\(style == .ghost)", pen.R(x, y, w, 4), style == .ghost ? .ink3 : dashed ? .ink : .chapter, width: Sketch.stroke, dashed: dashed)
        if !dashed {
            var m = (from / 10) * 10 + 10
            while Double(m - from) / Double(u) < w - 0.01 {
                let lx = x + Double(m - from) / Double(u)
                pen.line("\(id)t\(m)", [(lx, y), (lx, y + 4)], .chapter)
                m += 10
            }
        }
        if let n { pen.word("\(id)n\(n)", n, at: x + w / 2, y + 2, maths.colour(style == .ghost ? .ink3 : nc)) }
        if cross { pen.sketch.segments(id + "x", (0..<Int(w.rounded())).map { i in (pen.P(x + Double(i), y + 4), pen.P(x + min(w, Double(i + 1)), y)) }, .ink, width: Sketch.stroke) }
    }
    /// The start line the bars rest on: a block line, a square past them above and below.
    static func start(_ pen: inout GridPen, y: Double, h: Double) { pen.line("start", [(0, y - 1), (0, y + h + 1)]) }
}
