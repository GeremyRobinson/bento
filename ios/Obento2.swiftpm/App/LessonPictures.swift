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
        case "g5-mult2": return multiplyGrid(n, a: Int(v("a")), b: Int(v("b")), split: k("split") == 1, strip: Int(k("strip")), found: Int(k("found")), sum: k("sum") == 1, box: k("box") == 1)
        case "g5-divide": return divideGrid(dv: Int(v("dv")), qt: Int(v("qt")), strip: Int(k("strip")), found: Int(k("found")), left: k("left") == 1, sum: k("sum") == 1, box: k("box") == 1)
        case "g5-order": return with(orderGrid(n, beat: Int(k("beat"))))
        case "g5-multdec": return with(multiplyDecimalsGrid(n, p))
        case "g5-divdec": return with(divideDecimalGrid(d: Int(v("d")), qt: Int(v("qt")), p))
        case "g5-multfrac": return with(multiplyFractionsGrid(n, p))
        case "g5-volume": return with(volumeGrid(n, p))
        case "g5-units": return with(unitsGrid(n, p))
        default: return (Sketch(), Sketch(), nil)
        }
    }

    /// Words drawn bigger in a big problem (whole steps, so they stay on the grid): Multiply's and Long division's.
    static func scale(_ id: String, _ n: Numbers) -> Double {
        switch id {
        case "g5-mult2": return areaGeometry(tall: n["a"] ?? 12, wide: n["b"] ?? 12).k
        case "g5-divide": return areaGeometry(tall: n["dv"] ?? 12, wide: n["qt"] ?? 12).k
        default: return 1
        }
    }

    /// The How to's explaining beats for a lesson, after its first words: what each says, and what it turns on.
    static func beats(_ id: String, _ n: Numbers) -> [(words: String, picture: Numbers)] {
        func v(_ k: String) -> Double { n[k] ?? 0 }
        switch id {
        case "g5-mult2":
            let b = Int(v("b")), ps = MultiplyTwoDigit.parts(b)
            return [("Split \(b) into \(ps.map(String.init).joined(separator: " and ")). Each part makes a strip.", ["split": 1])]
        case "g5-divide":
            return [("Take out tens of \(Int(v("dv"))) first. They fill the big strip.", ["strip": 1])]
        default: return []
        }
    }

    // MARK: whole numbers

    /// Where an area model's parts sit (Multiply, Long division), in squares from the problem's origin (before k): the
    /// rectangle's corner, the school work's column, the step under the work, and the keypad beside the step. k is 1, or
    /// 2 when the rectangle is too big to read at the camera's distance (whole steps only, so everything stays on the grid).
    static func areaGeometry(tall a: Double, wide b: Double) -> (k: Double, rx: Double, ry: Double, h: Double, w: Double, colX: Double, stepY: Double, keyX: Double) {
        let k: Double = a > 50 || b > 60 ? 2 : 1
        // the rectangle's squares are the paper's; in the problem's units (k times bigger) each is 20 / k
        let c = Paper.cell / k
        // one left edge for the whole problem (G 19 Oct): the name, the sum and the side's number all start on it, and
        // the rectangle three squares in, past that number
        // on blocks (G 19 Oct): the rectangle one block in and one block down (its widths in the row over it), the
        // school work's column, the step and the keypad each starting on a block line
        let rx = 100.0, ry = 100.0, w = (b + 1) * c
        let colX = ((rx + w + 60) / 100).rounded(.up) * 100
        return (k, rx, ry, a, w, colX, 400, colX + 400)
    }

    /// Multiply on the grid (GridPen): the rectangle a squares tall and b wide, split into its strips a square apart,
    /// each width in the row above it, the side's number on the left edge level with the middle, each product on a
    /// plate centred on its strip; the school work beside it, two squares to a digit. k (1 or 2) draws the words and
    /// the school work bigger in a big problem; the rectangle's squares are always the paper's.
    static func multiplyGrid(_ n: Numbers, a: Int, b: Int, split: Bool, strip: Int, found: Int, sum: Bool, box: Bool) -> (picture: Sketch, work: Sketch, box: (right: Double, mid: Double, cell: Double)?) {
        let ps = MultiplyTwoDigit.parts(b), products = ps.map { a * $0 }, g = areaGeometry(tall: Double(a), wide: Double(b)), k = g.k, kk = Int(k)
        var pen = GridPen(k: k)
        var wk = GridPen(k: k)
        func sq(_ design: Double) -> Double { design / Paper.cell * k }
        let rx = sq(g.rx), ry = sq(g.ry), H = Double(a), widths = split ? ps : [b]
        let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        let product = Sketch.Words(size: Sketch.maths, weight: .semibold, colour: .chapter)
        // every label half a square from what it labels: the side's number beside the rectangle, each width over its strip
        pen.label("side", String(a), label.colour(.chapter), .left, edge: rx, along: ry + H / 2)
        var x = rx
        for (i, w) in widths.enumerated() {
            let lit = split && strip == i + 1, id = "s\(i)\(split)"
            pen.squares(id, col: x, row: ry, cols: w, rows: a, lit: lit)
            pen.label(id + "top\(lit)", String(split ? ps[i] : b), label.colour(lit ? .chapter : .ink2), .above, edge: ry, along: x + Double(w) / 2)
            if split, i < found {
                if w >= 4 * kk + 1 {
                    // straight on its squares, big and firm in the strip's colour (no white patch, G 19 Oct)
                    pen.word("p\(i)", String(products[i]), at: x + Double(w) / 2, ry + H / 2, product)
                } else {
                    pen.label("p\(i)", String(products[i]), product, .below, edge: ry + H, along: x + Double(w) / 2)
                }
            }
            x += Double(w) + (split ? 1 : 0)
        }
        // (no sum bracket under it: the total is added up in the work, once, G 19 Oct)
        // the work as school writes it, two squares to a digit: the problem written once, at its top; each part in its
        // row as it's found; the answer box in the row being worked (G 19 Oct: answered in the work)
        let per = 2 * k, right = 5 * per, ry0 = 0.0
        func row(_ r: Double) -> Double { ry0 + (r + 0.5) * per }
        let sign = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
        wk.digits("wa", String(a), right: right, row: row(0), per: per)
        wk.word("wx", "×", at: right - 4.5 * per, row(1), sign)
        wk.digits("wb", String(b), right: right, row: row(1), per: per)
        wk.rule("wr1", from: right - 5 * per, to: right, row: ry0 + 2 * per)
        for (i, pr) in products.enumerated() where i < found {
            wk.digits("wp\(i)", String(pr), right: right, row: row(Double(2 + i)), per: per)
        }
        let working = box && !sum ? found : -1
        if working >= 0 { wk.box = (Double(wk.P(right, 0).x), Double(wk.P(0, row(Double(2 + working))).y), Double(wk.P(per, 0).x)) }
        // the plus before the last part, as school writes it, once that row is being worked or written
        if products.count > 1, found >= products.count - 1, working == products.count - 1 || found >= products.count {
            wk.word("wplus", "+", at: right - 4.5 * per, row(Double(1 + products.count)), sign)
        }
        if sum {
            let r = Double(2 + products.count)
            wk.rule("wr2", from: right - 5 * per, to: right, row: ry0 + r * per)
            if box { wk.box = (Double(wk.P(right, 0).x), Double(wk.P(0, row(r)).y), Double(wk.P(per, 0).x)) }
            else { wk.digits("wt", String(products.reduce(0, +)), right: right, row: row(r), per: per, .chapter) }
        }
        return (pen.sketch, wk.sketch, wk.box)
    }

    // MARK: long division

    /// Long division on the grid: Multiply's rectangle run backwards. It's dv squares tall and qt wide, but its widths
    /// are what's found: the tens strip first ("?" until it is), then the ones strip with what's left in it. The
    /// division as school writes it beside it, two squares to a digit: the divisor, the bracket, the number under it,
    /// each part taken away and its quotient beside it, the answer over the bracket at the end.
    static func divideGrid( dv: Int, qt: Int, strip: Int, found: Int, left: Bool, sum: Bool, box: Bool) -> (picture: Sketch, work: Sketch, box: (right: Double, mid: Double, cell: Double)?) {
        let n = dv * qt, T = qt - qt % 10, O = qt % 10, rest = n - dv * T, widths = [T, O], products = [dv * T, dv * O]
        let g = areaGeometry(tall: Double(dv), wide: Double(qt)), k = g.k, kk = Int(k)
        var pen = GridPen(k: k)
        var wk = GridPen(k: k)
        func sq(_ design: Double) -> Double { design / Paper.cell * k }
        let rx = sq(g.rx), ry = sq(g.ry), H = Double(dv)
        let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        let product = Sketch.Words(size: Sketch.maths, weight: .semibold, colour: .chapter)
        pen.label("side", String(dv), label.colour(.chapter), .left, edge: rx, along: ry + H / 2)
        var x = rx
        for (i, w) in widths.enumerated() where w > 0 {
            let lit = strip == i + 1, id = "s\(i)"
            pen.squares(id, col: x, row: ry, cols: w, rows: dv, lit: lit)
            // its width once found; until then a question, lit when it's the one being found
            pen.label(id + "top\(i < found)\(lit)", i < found ? String(w) : "?", label.colour(lit || i >= found ? .chapter : .ink2), .above, edge: ry, along: x + Double(w) / 2)
            let inside = i < found ? String(products[i]) : (i == 1 && left ? String(rest) : nil)
            if let inside {
                if w >= 4 * kk + 1 {
                    pen.word("p\(i)\(inside)", inside, at: x + Double(w) / 2, ry + H / 2, product.colour(i < found ? .chapter : .tint(0.7)))
                } else {
                    pen.label("p\(i)\(inside)", inside, product.colour(i < found ? .chapter : .tint(0.7)), .below, edge: ry + H, along: x + Double(w) / 2)
                }
            }
            x += Double(w) + 1
        }
        // (no sum bracket: the answer is worked out in the bracket, G 19 Oct)
        // the division as school writes it, answered in it (G 19 Oct): two squares to a digit, the problem written once
        // in the bracket; each part taken away under it and how many groups beside it; the box where the next number
        // goes; the answer over the bracket at the end
        let per = 2 * k, nd = Double(String(n).count), right = (2 + nd) * per + per, qRight = right + 3 * per
        func row(_ r: Double) -> Double { (r + 0.5) * per }
        func boxAt(_ x: Double, _ r: Double) { wk.box = (Double(wk.P(x, 0).x), Double(wk.P(0, row(r)).y), Double(wk.P(per, 0).x)) }
        let bracketX = right - nd * per - 0.3 * per
        if sum && !box { wk.digits("q", String(qt), right: right, row: row(0), per: per, .chapter) }
        wk.digits("dv", String(dv), right: bracketX - 0.4 * per, row: row(1), per: per)
        wk.sketch.line("bracket", [wk.P(bracketX - 0.3 * per, 2 * per), wk.P(bracketX, 1.5 * per), wk.P(bracketX - 0.3 * per, per), wk.P(right, per)], .ink, width: Sketch.stroke)
        wk.digits("n", String(n), right: right, row: row(1), per: per)
        let sign = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
        // how many tens: the box beside the first row, then its number
        if found >= 1 {
            wk.word("m1", "−", at: right - (Double(String(products[0]).count) + 0.5) * per, row(2), sign)
            wk.digits("p1", String(products[0]), right: right, row: row(2), per: per)
            wk.rule("u1", from: right - Double(String(products[0]).count) * per, to: right, row: 3 * per)
            wk.digits("t1", String(T), right: qRight, row: row(2), per: per, .chapter)
        } else if box && strip == 1 { boxAt(qRight, 2) }
        // what's left: the box under the line, then its number
        if left || found >= 2 { wk.digits("rest", String(rest), right: right, row: row(3), per: per) }
        else if box && found == 1 { boxAt(right, 3) }
        // how many ones: the box beside the second row, then its rows
        if found >= 2 {
            wk.word("m2", "−", at: right - (Double(String(products[1]).count) + 0.5) * per, row(4), sign)
            wk.digits("p2", String(products[1]), right: right, row: row(4), per: per)
            wk.rule("u2", from: right - Double(String(products[1]).count) * per, to: right, row: 5 * per)
            wk.digits("zero", "0", right: right, row: row(5), per: per)
            wk.digits("t2", String(O), right: qRight, row: row(4), per: per, .chapter)
        } else if box && left { boxAt(qRight, 4) }
        // the answer: the box over the bracket
        if sum && box { boxAt(right, 0) }
        return (pen.sketch, wk.sketch, wk.box)
    }

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

    // MARK: multiplying decimals

    /// 2.4 × 0.3 on the grid: the multiplication as school writes it, two squares to a digit, each number's decimal
    /// places counted beside it and the answer's under; beside it one whole as ten squares by ten, with the one piece
    /// the two numbers' places make lit (a tenth is a column of it, a hundredth one square).
    static func multiplyDecimalsGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let A = Int(n["A"] ?? 0), B = Int(n["B"] ?? 0), pa = Int(n["pa"] ?? 0), pb = Int(n["pb"] ?? 0)
        let x = Double(A) / pow(10, Double(pa)), y = Double(B) / pow(10, Double(pb)), ans = x * y, places = pa + pb
        let line = p["line"].map(Int.init), per = 2.0, right = 14.0
        let note = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3), placeWord = { (k: Int) in k == 1 ? "1 place" : "\(k) places" }
        wk.digits("a", fmt(x), right: right, row: 2, per: per)
        wk.word("x", "×", at: right - 4.5 * per, 4, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink))
        wk.digits("b", fmt(y), right: right, row: 4, per: per)
        wk.word("pa", placeWord(pa), at: right + 1, 2, note.colour(p["piece"] == 1 ? .chapter : .ink3), anchor: UnitPoint(x: 0, y: 0.5))
        wk.word("pb", placeWord(pb), at: right + 1, 4, note.colour(p["piece"] == 1 ? .chapter : .ink3), anchor: UnitPoint(x: 0, y: 0.5))
        wk.rule("r", from: right - 5 * per, to: right, row: 5)
        if line == 2 {
            wk.digits("t", fmt(ans), right: right, row: 6, per: per, .chapter)
            wk.word("pt", placeWord(places), at: right + 1, 6, note.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        let lines = ["\(A) × \(B) = \(A * B) small pieces",
                     "\(fmt(1 / pow(10, Double(pa)))) × \(fmt(1 / pow(10, Double(pb)))) = \(fmt(1 / pow(10, Double(places))))",
                     "\(A * B) \(places == 1 ? "tenths" : places == 2 ? "hundredths" : "thousandths") = \(fmt(ans))"]
        if let l = line { wk.word("line\(l)", lines[l], at: 0, 10, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink), anchor: UnitPoint(x: 0, y: 0.5)) }
        // one whole: ten squares by ten; the piece lit
        let ux = 30.0, uy = 2.0, lit = p["piece"] == 1 || p["lit"] == 1
        pen.word("wl", "1 whole", at: ux + 5, uy - 1, note.colour(.ink2))
        if lit {
            let piece = places == 1 ? pen.R(ux, uy, 1, 10) : pen.R(ux, uy, 1, 1)
            pen.sketch.fill("piece\(places)", piece, .tint(0.6))
        }
        pen.sketch.segments("unit", (0...10).map { i in (pen.P(ux + Double(i), uy), pen.P(ux + Double(i), uy + 10)) } + (0...10).map { j in (pen.P(ux, uy + Double(j)), pen.P(ux + 10, uy + Double(j))) }, .tint(0.5), width: 1)
        pen.sketch.box("unito", pen.R(ux, uy, 10, 10), .chapter, width: Sketch.stroke)
        if lit {
            let size = fmt(1 / pow(10, Double(places)))
            pen.label("ps", places > 2 ? "one piece: \(size) (a tenth of a square)" : "one piece: \(size)", Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter), .below, edge: uy + 10, along: ux + 5)
        }
        return (pen.sketch, wk.sketch)
    }
}
