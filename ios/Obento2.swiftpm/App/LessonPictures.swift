import SwiftUI

/// The 5th grade lessons not yet moved onto the paper (PaperLessons has those designed the way G approved on 20 Oct,
/// in App/Lessons/), each drawn as a Sketch from its numbers and what its step shows
/// (`picture` keys, as each spec in Core documents them): the work as school writes it beside a picture that shows why
/// it works, built in squares on the grid (GridPen). Each will move to App/Lessons/ when it's designed for the paper.
@MainActor
enum LessonPictures {
    /// A lesson's drawing: its picture, its work, and (for a lesson answered in its work) where its answer boxes go,
    /// each in squares from its own corner; the problem's layout (ProblemGrid) places them. `shared`: the lesson placed
    /// its picture and work itself, in one set of squares, and the layout keeps them so.
    struct Drawing {
        var picture: Sketch; var work: Sketch; var boxes: [WorkBox] = []; var shared = false
    }

    static func drawing(_ id: String, _ n: Numbers, _ p: Numbers) -> Drawing {
        let d = drawingParts(id, n, p)
        return Drawing(picture: d.picture, work: d.work, boxes: d.box.map { [WorkBox(id: nil, right: $0.right, mid: $0.mid, cell: $0.cell)] } ?? [])
    }

    static func drawingParts(_ id: String, _ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch, box: (right: Double, mid: Double, cell: Double)?) {
        func with(_ t: (picture: Sketch, work: Sketch)) -> (picture: Sketch, work: Sketch, box: (right: Double, mid: Double, cell: Double)?) { (t.picture, t.work, nil) }
        func v(_ k: String) -> Double { n[k] ?? 0 }
        func k(_ key: String) -> Double { p[key] ?? 0 }
        switch id {
        case "g5-order": return with(orderGrid(n, beat: Int(k("beat"))))
        case "g5-divdec": return with(divideDecimalGrid(d: Int(v("d")), qt: Int(v("qt")), p))
        case "g5-multfrac": return with(multiplyFractionsGrid(n, p))
        case "g5-volume": return with(volumeGrid(n, p))
        case "g5-units": return with(unitsGrid(n, p))
        default: return (Sketch(), Sketch(), nil)
        }
    }

    /// Words drawn bigger in a big problem (whole steps, so they stay on the grid): none of these lessons' yet (the
    /// paper lessons size themselves, PaperLesson.scale).
    static func scale(_ id: String, _ n: Numbers) -> Double { 1 }

    /// The How to's explaining beats for a lesson, after its first words: what each says, and what it turns on.
    static func beats(_ id: String, _ n: Numbers) -> [(words: String, picture: Numbers)] { [] }

    // MARK: dividing by a decimal

    /// 4.8 ÷ 0.6 on the grid: two number lines a step of squares apart for every tick, the top counting by 0.6, the
    /// bottom by 6, "× 10" between them; matched one step, then all, then the hops counted.
    static func divideDecimalGrid(d: Int, qt: Int, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        let one = p["one"] == 1, all = p["all"] == 1, hops = p["hops"] == 1, lit = p["lit"]
        var pen = GridPen()
        var wk = GridPen()
        let per = Double(max(3, 40 / qt)), top = 8.0, bottom = 14.0, x0 = 5.0
        let small = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
        let atTop = pen.numberLine("top", col: x0, row: top, steps: qt, per: per, long: qt)
        _ = pen.numberLine("bottom", col: x0, row: bottom, steps: qt, per: per, long: qt)
        pen.label("x10", "× 10", small.colour(.chapter), .left, edge: x0, along: (top + bottom) / 2)
        for i in 0...qt {
            let c = atTop(i), litTop = (lit == 0 && i == 1) || (lit == 1 && i == qt)
            if qt <= 8 || i % 2 == 0 || i == qt { pen.label("tl\(i)", fmt(Double(d * i) / 10), small.colour(litTop ? .chapter : .ink2), .above, edge: top - 2, along: c) }
            if all || (one && i <= 1) { pen.label("bl\(i)", String(d * i), small.colour(litTop ? .chapter : .ink2), .below, edge: bottom, along: c) }
            if all { pen.sketch.line("wire\(i)", [pen.P(c, top), pen.P(c, bottom - 2)], .tint(0.45), width: 1.5) }
        }
        if all { pen.rule("topb", from: x0, to: atTop(qt), row: top, .chapter, width: Sketch.stroke); pen.rule("botb", from: x0, to: atTop(qt), row: bottom, .chapter, width: Sketch.stroke) }
        else if one { pen.rule("top1", from: x0, to: atTop(1), row: top, .chapter, width: Sketch.stroke); pen.rule("bot1", from: x0, to: atTop(1), row: bottom, .chapter, width: Sketch.stroke) }
        if hops {
            // over the top line's numbers, so they never meet
            for i in 0..<qt { pen.hop("h\(i)", from: atTop(i), to: atTop(i + 1), row: top - 4.5, height: 1) }
            pen.label("count", "\(qt) hops", small.colour(.chapter), .above, edge: top - 6, along: atTop(qt))
        }
        let line = hops ? "\(d * qt) ÷ \(d) = \(qt), and \(fmt(Double(d * qt) / 10)) ÷ \(fmt(Double(d) / 10)) = \(qt)"
            : all ? "\(fmt(Double(d * qt) / 10)) × 10 = \(d * qt)" : one ? "\(fmt(Double(d) / 10)) × 10 = \(d)" : nil
        if let line { wk.word("line\(line)", line, at: x0, 18, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink), anchor: UnitPoint(x: 0, y: 0.5)) }
        return (pen.sketch, wk.sketch)
    }

    // MARK: fractions

    static func frac(_ a: Int, _ b: Int) -> Math { .frac(.num(Double(a)), .num(Double(b))) }


    /// 2/3 × 3/4 on the grid: the square cut into b rows and d columns of whole squares, a rows and c columns shaded,
    /// their overlap counted; on the left top times top over bottom times bottom.
    static func multiplyFractionsGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 1), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 1)
        let at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        wk.math("prob", [frac(a, b), .op("×"), frac(c, d)], col: 0, row: 1)
        if at >= 3 || ask == 3 { wk.math("mul", [.op("="), .frac(.text("\(a) × \(c)"), .text("\(b) × \(d)"))], col: 7, row: 1) }
        if at >= 3 { wk.math("res", [.op("="), frac(a * c, b * d)], col: 7, row: 7) }
        if at >= 4 {
            let g = gcd(a * c, b * d)
            wk.word("simp", g > 1 ? "= \(a * c / g)/\(b * d / g)" : "already simplest", at: 13, 9, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        // the grid: each piece `s` squares a side
        let s = Double(max(2, min(6, 16 / b, 24 / d))), x0 = 30.0, y0 = 2.0
        for r in 0..<b { for col in 0..<d {
            let inRow = r < a, inCol = col < c, rect = pen.R(x0 + Double(col) * s, y0 + Double(r) * s, s, s)
            if inRow && inCol { pen.sketch.fill("o\(r)_\(col)\(at >= 3 || ask == 3)", rect, ask == 3 || at >= 3 ? .tint(0.7) : .tint(0.55)) }
            else if inRow { pen.sketch.fill("r\(r)_\(col)\(ask == 1)", rect, ask == 1 ? .tint(0.4) : .tint(0.22)) }
            else if inCol { pen.sketch.fill("c\(r)_\(col)\(ask == 2)", rect, ask == 2 ? .tint(0.4) : .tint(0.12)) }
            if at >= 3, inRow && inCol { pen.word("n\(r)_\(col)", "\(r * c + col + 1)", at: x0 + (Double(col) + 0.5) * s, y0 + (Double(r) + 0.5) * s, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .paper)) }
        } }
        pen.sketch.segments("grid", (0...d).map { i in (pen.P(x0 + Double(i) * s, y0), pen.P(x0 + Double(i) * s, y0 + Double(b) * s)) }
            + (0...b).map { j in (pen.P(x0, y0 + Double(j) * s), pen.P(x0 + Double(d) * s, y0 + Double(j) * s)) }, .tint(0.6), width: 1.5)
        let small = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
        pen.label("rl", "\(a)/\(b)", small.colour(ask == 1 ? .chapter : .ink2), .left, edge: x0, along: y0 + Double(a) * s / 2)
        pen.label("cl", "\(c)/\(d)", small.colour(ask == 2 ? .chapter : .ink2), .above, edge: y0, along: x0 + Double(c) * s / 2)
        return (pen.sketch, wk.sketch)
    }

    // MARK: order of operations

    /// 3 + 4 × (6 − 2) on the grid: rewritten line under line as school does it, two squares to a character, the group
    /// done on each line lit behind it; on the right the order to follow, the rule being used lit.
    static func orderGrid(_ n: Numbers, beat: Int) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let t = Int(n["t"] ?? 0), a = n["a"] ?? 0, b = n["b"] ?? 0, c = n["c"] ?? 0, d = n["d"] ?? 0
        let A = fmt(a), B = fmt(b), C = fmt(c), D = fmt(d)
        var lines: [[String]] = [], groups: [Range<Int>] = [], rules: [Int] = []
        switch t {
        case 0:
            let v1 = c - d, v2 = b * v1, v3 = a + v2
            lines = [[A, "+", B, "×", "(", C, "−", D, ")"], [A, "+", B, "×", fmt(v1)], [A, "+", fmt(v2)], [fmt(v3)]]
            groups = [4..<9, 2..<5, 0..<3]; rules = [0, 1, 2]
        case 1:
            let v1 = a + b, v2 = v1 * c, v3 = v2 - d
            lines = [["(", A, "+", B, ")", "×", C, "−", D], [fmt(v1), "×", C, "−", D], [fmt(v2), "−", D], [fmt(v3)]]
            groups = [0..<5, 0..<3, 0..<3]; rules = [0, 1, 2]
        default:
            let v1 = a * b, v2 = c / d, v3 = v1 - v2
            lines = [[A, "×", B, "−", C, "÷", D], [fmt(v1), "−", C, "÷", D], [fmt(v1), "−", fmt(v2)], [fmt(v3)]]
            groups = [0..<3, 2..<5, 0..<3]; rules = [1, 1, 2]
        }
        let big = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink), shown = min(max(beat, 0), 3)
        for i in 0...shown {
            let row = 1 + Double(i) * 4, x0 = 3.0
            if i > 0 { pen.word("eq\(i)", "=", at: 1, row + 1, big) }
            // each character two squares wide; a token as wide as its characters
            var x = x0, spans: [(Double, Double)] = []
            for tok in lines[i] { let w = Double(tok.count) * 2; spans.append((x, x + w)); x += w }
            if i == beat - 1, i < groups.count, let first = spans[safe: groups[i].lowerBound], let last = spans[safe: groups[i].upperBound - 1] {
                pen.sketch.fill("hl\(i)", pen.R(first.0 - 0.5, row - 0.5, last.1 - first.0 + 1, 3), .tint(0.3))
            }
            for (j, tok) in lines[i].enumerated() {
                for (q, ch) in tok.enumerated() { pen.word("t\(i)_\(j)_\(q)\(ch)", String(ch), at: spans[j].0 + Double(q) * 2 + 1, row + 1, big.colour(i == 3 ? .chapter : .ink)) }
            }
        }
        // the order to follow
        let names = ["( )   first", "×  ÷   next", "+  −   last"], rx = 40.0
        let litRule = beat >= 1 && beat <= 3 ? rules[beat - 1] : -1
        for (i, name) in names.enumerated() {
            let row = 1 + Double(i) * 3
            wk.sketch.fill("rf\(i)\(i == litRule)", pen.R(rx, row, 12, 2), i == litRule ? .tint(0.4) : .tint(0.15))
            wk.word("rn\(i)", "\(i + 1)", at: rx + 1, row + 1, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter))
            wk.word("rt\(i)", name, at: rx + 2.5, row + 1, Sketch.Words(size: Sketch.small, weight: .medium, colour: i == litRule ? .ink : .ink2), anchor: UnitPoint(x: 0, y: 0.5))
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: volume

    /// A box 4 × 3 × 2 on the grid, each cube three squares a side, seen two ways as school draws it flat: its floor from
    /// above (length × width, the layer of cubes on it) and its front (length × height, the layers stacked); the
    /// working beside them.
    static func volumeGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let l = Int(n["length"] ?? 1), w = Int(n["width"] ?? 1), h = Int(n["height"] ?? 1)
        let floor = p["floor"] == 1, layers = Int(p["layers"] ?? 0), height = p["height"] == 1, cube = 3.0
        let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2), head = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink3)
        func grid(_ id: String, col: Double, row: Double, cols: Int, rows: Int, filled: Int, lit: Bool) {
            if filled > 0 { pen.sketch.fill("\(id)f\(filled)", pen.R(col, row + Double(rows - filled) * cube, Double(cols) * cube, Double(filled) * cube), lit ? .tint(0.4) : .tint(0.22)) }
            pen.sketch.segments("\(id)g\(filled > 0)", (0...cols).map { i in (pen.P(col + Double(i) * cube, row), pen.P(col + Double(i) * cube, row + Double(rows) * cube)) }
                + (0...rows).map { j in (pen.P(col, row + Double(j) * cube), pen.P(col + Double(cols) * cube, row + Double(j) * cube)) }, filled > 0 ? .tint(0.7) : .tint(0.45), width: 1.5)
            pen.sketch.box("\(id)o", pen.R(col, row, Double(cols) * cube, Double(rows) * cube), .chapter, width: Sketch.stroke)
        }
        // from above: the floor
        let fx = 3.0, fy = 3.0
        pen.word("fh", "from above", at: fx, 1, head, anchor: UnitPoint(x: 0, y: 0.5))
        grid("floor", col: fx, row: fy, cols: l, rows: w, filled: floor || layers > 0 ? w : 0, lit: floor && layers == 0)
        pen.label("fl", "\(l) cm", label.colour(floor ? .chapter : .ink2), .below, edge: fy + Double(w) * cube, along: fx + Double(l) * cube / 2)
        pen.label("fw", "\(w) cm", label.colour(floor ? .chapter : .ink2), .left, edge: fx, along: fy + Double(w) * cube / 2)
        // from the front: the layers
        let sx = fx + Double(l) * cube + 6, sy = 3.0
        pen.word("sh", "from the front", at: sx, 1, head, anchor: UnitPoint(x: 0, y: 0.5))
        grid("front", col: sx, row: sy, cols: l, rows: h, filled: min(layers, h), lit: layers > 0)
        pen.label("hl", "\(h) cm", label.colour(height ? .chapter : .ink2), .right, edge: sx + Double(l) * cube, along: sy + Double(h) * cube / 2)
        pen.label("sl", "\(l) cm", label, .below, edge: sy + Double(h) * cube, along: sx + Double(l) * cube / 2)
        // the working
        let wx = sx + Double(l) * cube + 8, line = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        wk.word("v", "Volume = l × w × h", at: wx, 3, line, anchor: UnitPoint(x: 0, y: 0.5))
        if floor || layers > 0 { wk.word("b", "\(l) × \(w) = \(l * w) in a layer", at: wx, 6, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        if height { wk.word("t", "\(l * w) × \(h) = \(l * w * h) cm³", at: wx, 9, line.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        return (pen.sketch, wk.sketch)
    }

    // MARK: converting units

    /// 3 feet = ? inches on the grid: a bar of big units, each a block wide, opened up into small ones one after
    /// another; the brackets over and under it say what it holds.
    static func unitsGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let pair = ConvertUnits.units[min(ConvertUnits.units.count - 1, Int(n["u"] ?? 0))]
        let count = p["units"] ?? 1, per = p["per"] ?? pair.per, rows = Int(p["rows"] ?? 1), fill = Int(p["fill"] ?? 0)
        let one = p["one"] == 1, ask = p["ask"] == 1, total = p["total"] == 1, up = n["up"] == 1, amount = n["n"] ?? 0
        let cells = Int(count.rounded(.up)), perRow = rows == 2 ? Int((Double(cells) / 2).rounded(.up)) : cells
        let cw = 5.0, ch = 3.0, x0 = 0.0, y0 = 4.0, label = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
        pen.label("amt", up ? "\(fmt(amount)) \(pair.small)" : "\(fmt(amount)) \(amount == 1 ? pair.one : pair.many)", label.colour(.ink2), .above, edge: y0, along: x0 + Double(perRow) * cw / 2)
        for i in 0..<cells {
            let r = i / perRow, c = i % perRow, col = x0 + Double(c) * cw, row = y0 + Double(r) * (ch + 1)
            let part = i == cells - 1 && count < Double(cells) ? count - Double(cells - 1) : 1, opened = i < fill
            pen.sketch.fill("u\(i)\(opened)", pen.R(col, row, cw * part, ch), opened ? .tint(0.4) : .tint(0.2))
            pen.sketch.box("ub\(i)", pen.R(col, row, cw, ch), .tint(0.7), width: Sketch.stroke)
            let text = opened ? fmt(per * part) : (ask && i > 0 ? "?" : (part < 1 ? "½" : "1"))
            pen.word("ul\(i)\(text)", text, at: col + cw / 2, row + ch / 2, label.colour(opened ? .ink : .ink2))
        }
        let below = y0 + Double(rows) * (ch + 1) + 1, line = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        if one { wk.word("one", "1 \(pair.one) = \(fmt(per)) \(pair.small)", at: x0, below + 1, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        if total {
            let ans = up ? amount / per : amount * per
            wk.word("tot", up ? "\(fmt(amount)) ÷ \(fmt(per)) = \(fmt(ans)) \(pair.many)" : "\(fmt(amount)) × \(fmt(per)) = \(fmt(ans)) \(pair.small)",
                     at: x0, below + 4, line.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        return (pen.sketch, wk.sketch)
    }
}
