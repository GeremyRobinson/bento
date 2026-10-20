import SwiftUI

/// Every 5th grade lesson's picture, drawn as a Sketch from its numbers and what its step shows (`picture` keys, as
/// each spec in Core documents them). Each puts the work as school writes it (columns, the division bracket, the
/// points lined up, fractions over each other) on the left, filling in as the child does each step, beside a picture
/// on the right that shows why it works (the web app's pictures: area models, bars, number lines), the part the step
/// is about lit (G 19 Oct). The picture area is 720 wide and 290 tall.
@MainActor
enum LessonPictures {
    static let width = 720.0, height = 290.0
    /// The fills: every part soft, the part the step is about stronger (the web's picture system).
    static let soft = Sketch.Colour.tint(0.22), mid = Sketch.Colour.tint(0.5)

    /// Where an open problem puts things: the plain layout, or a lesson's own.
    static func layout(_ m: WorkProblem) -> WorkProblem.Layout {
        func v(_ k: String) -> Double { m.lesson.numbers[k] ?? 0 }
        switch m.lesson.spec.id {
        case "g5-mult2": return multiplyLayout(m.lesson.numbers)
        case "g5-round": return roundLayout()
        case "g5-divide": return areaLayout(tall: v("dv"), wide: v("qt"))
        case "g5-divdec", "g5-pow10", "g5-adddec": return gridLayout()
        case "add", "sub", "mix", "g5-multfrac", "g5-fracof": return gridLayout()
        case "g5-improper": return gridLayout(rows: 3 * (Int(v("w")) + 1))
        case "g5-order", "g5-units", "g5-multdec": return gridLayout()
        case "g5-volume": return gridLayout(rows: Int(max(v("width"), v("height"))) * 3 + 6)
        case "g5-unitdiv": return gridLayout(rows: Int(v("W")) * (v("W") > 6 ? 2 : 3))
        default: return WorkProblem.Layout()
        }
    }

    /// A lesson's drawing for these numbers and this step's picture keys: its picture, and its work as school writes
    /// it, each in squares from its own corner; the problem's layout (ProblemGrid) places them.
    static func drawing(_ id: String, _ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        func v(_ k: String) -> Double { n[k] ?? 0 }
        func k(_ key: String) -> Double { p[key] ?? 0 }
        switch id {
        case "g5-mult2": return multiplyGrid(n, a: Int(v("a")), b: Int(v("b")), split: k("split") == 1, strip: Int(k("strip")), found: Int(k("found")), sum: k("sum") == 1)
        case "g5-divide": return divideGrid(dv: Int(v("dv")), qt: Int(v("qt")), strip: Int(k("strip")), found: Int(k("found")), left: k("left") == 1, sum: k("sum") == 1)
        case "g5-order": return orderGrid(n, beat: Int(k("beat")))
        case "g5-pow10": return powersGrid(x: v("x"), k: Int(v("k")), hop: k("hop") == 1)
        case "g5-round": return roundGrid(n, p)
        case "g5-adddec": return addDecimalsGrid(a: v("a"), b: v("b"), p)
        case "g5-multdec": return multiplyDecimalsGrid(n, p)
        case "g5-divdec": return divideDecimalGrid(d: Int(v("d")), qt: Int(v("qt")), p)
        case "add", "sub", "mix": return unlikeGrid(n, p)
        case "g5-multfrac": return multiplyFractionsGrid(n, p)
        case "g5-improper": return improperGrid(n, p)
        case "g5-fracof": return fractionOfGrid(n, p)
        case "g5-unitdiv": return unitDivideGrid(n, p)
        case "g5-volume": return volumeGrid(n, p)
        case "g5-units": return unitsGrid(n, p)
        default: return (Sketch(), Sketch())
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
        case "g5-pow10":
            let k = Int(v("k"))
            return [("Each zero makes every digit 10 times bigger. The point hops \(k == 1 ? "1 place" : "\(k) places") right.", ["zeros": 1, "hop": 1])]
        case "g5-adddec":
            return [("Line up the points. Tenths go under tenths.", ["lineUp": 1, "lit": 0])]
        case "add", "sub", "mix":
            return [("Cut both bars into the same size pieces.", ["cut": 1, "focus": 3])]
        default: return []
        }
    }

    // MARK: helpers

    static func f(_ x: Double) -> String { fmt(x) }
    static func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    static func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }
    /// A bracket under a span, its ends turned up, and words under it.
    static func bracket(_ s: inout Sketch, _ id: String, x0: Double, x1: Double, y: Double, _ words: String, _ colour: Sketch.Colour = .chapter) {
        s.line(id, [P(x0, y - 8), P(x0, y), P(x1, y), P(x1, y - 8)], colour, width: 2)
        s.text(id + "w", words, at: P((x0 + x1) / 2, y + 18), size: 18, colour)
    }

    // MARK: whole numbers

    /// 47 × 36: on the left the multiplication as school writes it, its partial products one per strip; on the right
    /// the area model, 36 split into 30 and 6, each strip 47 tall.
    static func multiply(_ s: inout Sketch, a: Int, b: Int, split: Bool, strip: Int, found: Int, sum: Bool) {
        let ps = MultiplyTwoDigit.parts(b), products = ps.map { a * $0 }
        // school: 47 over × 36, a line, the parts, a line, the total
        let rx = 150.0, cell = 22.0
        s.digits("a", String(a), right: rx, y: 24, cell: cell)
        s.text("x", "×", at: P(rx - 4 * cell - 6, 62), size: 24)
        s.digits("b", String(b), right: rx, y: 62, cell: cell)
        s.line("r1", [P(rx - 5 * cell, 84), P(rx + 4, 84)], .ink, width: 2)
        for (i, pr) in products.enumerated() where i < found {
            let y = 106 + Double(i) * 36
            s.digits("p\(i)", String(pr), right: rx, y: y, cell: cell)
            s.text("pl\(i)", "\(a) × \(ps[i])", at: P(rx + 14, y), size: 15, .ink3, anchor: UnitPoint(x: 0, y: 0.5))
        }
        if sum {
            let y = 106 + Double(products.count) * 36
            s.line("r2", [P(rx - 5 * cell, y - 18), P(rx + 4, y - 18)], .ink, width: 2)
            s.digits("t", String(products.reduce(0, +)), right: rx, y: y + 4, .chapter, cell: cell)
        }
        // the area model: one scale both ways, the strips a gap apart once split
        let x0 = 400.0, top = 46.0, maxW = 300.0, maxH = 150.0
        let k = min(maxW / Double(b), maxH / Double(a)), h = max(70, Double(a) * k)
        var widths = ps.map { max(30, Double($0) * k) }
        if !split { widths = [max(60, Double(b) * k)] }
        let gap = split ? 10.0 : 0
        s.text("side", String(a), at: P(x0 - 20, top + h / 2), size: 20, .chapter)
        var x = x0
        for (i, w) in widths.enumerated() {
            let lit = split && strip == i + 1
            s.fill("s\(i)\(split)", R(x, top, w, h), lit ? mid : soft)
            s.box("o\(i)\(split)", R(x, top, w, h), .chapter, width: 2)
            s.text("top\(i)\(split)", split ? String(ps[i]) : String(b), at: P(x + w / 2, top - 16), size: 20, lit ? .chapter : .ink2)
            if split, i < found {
                let fits = w > CGFloat(PaperText.width(String(products[i]), PaperText.font(18, .medium, digits: true))) + 8
                s.text("in\(i)", String(products[i]), at: P(x + w / 2, fits ? top + h / 2 : top + h + 18), size: 18, .ink)
            }
            x += w + gap
        }
        if sum { bracket(&s, "br", x0: x0, x1: x - gap, y: top + h + 40, "\(products.map(String.init).joined(separator: " + ")) = \(products.reduce(0, +))") }
    }

    /// Multiply two-digit numbers on the grid itself (G 19 Oct): the rectangle is a squares tall and b wide, one square of
    /// the paper for each, so the child can count it; a strong line every 10 squares shows the tens and the hundreds.
    /// The school work runs down beside it, and the step's words under that. Too big for the screen, everything but the
    /// squares is drawn bigger and the camera steps back.
    static func multiplyLayout(_ n: Numbers) -> WorkProblem.Layout { areaLayout(tall: n["a"] ?? 12, wide: n["b"] ?? 12) }

    /// An area model's problem (Multiply, Long division): the rectangle `tall` squares by `wide`, the school work in a
    /// column beside it, the step under the work, the keypad beside the step.
    static func areaLayout(tall: Double, wide: Double) -> WorkProblem.Layout {
        let g = areaGeometry(tall: tall, wide: wide)
        var l = WorkProblem.Layout()
        l.scale = g.k
        // the picture is built in squares (GridPen), the paper's own: not drawn bigger with the words
        l.pictureTop = 0; l.pictureScale = 1 / g.k
        l.stepX = g.colX; l.stepY = g.stepY; l.lineY = g.stepY + 100; l.column = g.keyX - g.colX - 40
        l.actions = g.stepY + 200; l.messageBelow = true
        l.keypadX = g.keyX; l.keypadY = g.stepY
        // a wide, short picture (long division's strips): the step goes under it, on the left edge, so the problem
        // stays narrow enough to be drawn big (G 19 Oct: kids, big)
        if wide > 2.5 * tall {
            let under = ((g.ry + tall * Paper.cell / g.k + 120) / Paper.unit).rounded(.up) * Paper.unit
            l.stepX = 0; l.stepY = under; l.lineY = under + 100; l.actions = under + 200
            l.column = 600; l.keypadX = 700; l.keypadY = under
            l.height = ((under + 400) * g.k / Paper.unit).rounded(.up) / g.k
            return l
        }
        // the box (for the page's layout) holds it all, in whole blocks
        l.width = ((g.keyX + 180 + 80) * g.k / Paper.unit).rounded(.up) / g.k
        l.height = ((max(g.ry + g.h * Paper.cell / g.k + 120, g.stepY + 400) + 200) * g.k / Paper.unit).rounded(.up) / g.k
        return l
    }

    /// Where Multiply's parts sit, in squares from the problem's origin (before k): the rectangle's corner, the school
    /// work's column, the step under the work, and the keypad beside the step. k is 1, or 2 when the rectangle is too
    /// big to read at the camera's distance (whole steps only, so everything stays on the grid).
    static func geometry(_ n: Numbers) -> (k: Double, rx: Double, ry: Double, h: Double, w: Double, colX: Double, stepY: Double, keyX: Double) {
        areaGeometry(tall: n["a"] ?? 12, wide: n["b"] ?? 12)
    }
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
    static func multiplyGrid(_ n: Numbers, a: Int, b: Int, split: Bool, strip: Int, found: Int, sum: Bool) -> (picture: Sketch, work: Sketch) {
        let ps = MultiplyTwoDigit.parts(b), products = ps.map { a * $0 }, g = geometry(n), k = g.k, kk = Int(k)
        var pen = GridPen(k: k)
        var wk = GridPen(k: k)
        func sq(_ design: Double) -> Double { design / Paper.cell * k }
        let rx = sq(g.rx), ry = sq(g.ry), H = Double(a), widths = split ? ps : [b]
        let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        // every label half a square from what it labels: the side's number beside the rectangle, each width over its strip
        pen.label("side", String(a), label.colour(.chapter), .left, edge: rx, along: ry + H / 2)
        var x = rx
        for (i, w) in widths.enumerated() {
            let lit = split && strip == i + 1, id = "s\(i)\(split)"
            pen.squares(id, col: x, row: ry, cols: w, rows: a, lit: lit)
            pen.label(id + "top\(lit)", String(split ? ps[i] : b), label.colour(lit ? .chapter : .ink2), .above, edge: ry, along: x + Double(w) / 2)
            if split, i < found {
                if w >= 4 * kk + 1 {
                    pen.plate("pf\(i)", over: (w, a), at: x, ry, w: 4 * kk, h: 2 * kk)
                    pen.word("p\(i)", String(products[i]), at: x + Double(w) / 2, ry + H / 2, label)
                } else {
                    pen.label("p\(i)", String(products[i]), label, .below, edge: ry + H, along: x + Double(w) / 2)
                }
            }
            x += Double(w) + (split ? 1 : 0)
        }
        if sum {
            let narrow = found > 0 && widths.contains { $0 < 4 * kk + 1 }
            pen.bracket("sum", from: rx, to: x - (split ? 1 : 0), row: ry + H + (narrow ? 3 : 2) * k, "\(products.map(String.init).joined(separator: " + ")) = \(products.reduce(0, +))",
                        Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), tick: k)
        }
        // the work as school writes it, two squares to a digit, down the column beside it
        let per = 2 * k, right = sq(g.colX) + 5 * per
        func row(_ r: Double) -> Double { ry + (r + 0.5) * per }
        wk.digits("wa", String(a), right: right, row: row(0), per: per)
        wk.word("wx", "×", at: right - 4.5 * per, row(1), Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink))
        wk.digits("wb", String(b), right: right, row: row(1), per: per)
        wk.rule("wr1", from: right - 5 * per, to: right, row: ry + 2 * per)
        for (i, pr) in products.enumerated() where i < found {
            wk.digits("wp\(i)", String(pr), right: right, row: row(Double(2 + i)), per: per, i + 1 == strip ? .chapter : .ink)
        }
        // the plus before the last part, in the ×'s column, once every part is written (as school adds them); a sign,
        // so in ink like the ×
        if products.count > 1, found >= products.count {
            wk.word("wplus", "+", at: right - 4.5 * per, row(Double(1 + products.count)), Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink))
        }
        if sum {
            let r = Double(2 + products.count)
            wk.rule("wr2", from: right - 5 * per, to: right, row: ry + r * per)
            wk.digits("wt", String(products.reduce(0, +)), right: right, row: row(r), per: per, .chapter)
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: long division

    /// Long division on the grid: Multiply's rectangle run backwards. It's dv squares tall and qt wide, but its widths
    /// are what's found: the tens strip first ("?" until it is), then the ones strip with what's left in it. The
    /// division as school writes it beside it, two squares to a digit: the divisor, the bracket, the number under it,
    /// each part taken away and its quotient beside it, the answer over the bracket at the end.
    static func divideGrid( dv: Int, qt: Int, strip: Int, found: Int, left: Bool, sum: Bool) -> (picture: Sketch, work: Sketch) {
        let n = dv * qt, T = qt - qt % 10, O = qt % 10, rest = n - dv * T, widths = [T, O], products = [dv * T, dv * O]
        let g = areaGeometry(tall: Double(dv), wide: Double(qt)), k = g.k, kk = Int(k)
        var pen = GridPen(k: k)
        var wk = GridPen(k: k)
        func sq(_ design: Double) -> Double { design / Paper.cell * k }
        let rx = sq(g.rx), ry = sq(g.ry), H = Double(dv)
        let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
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
                    pen.plate("pf\(i)", over: (w, dv), at: x, ry, w: 4 * kk, h: 2 * kk)
                    pen.word("p\(i)\(inside)", inside, at: x + Double(w) / 2, ry + H / 2, label.colour(i < found ? .ink : .ink2))
                } else {
                    pen.label("p\(i)\(inside)", inside, label.colour(i < found ? .ink : .ink2), .below, edge: ry + H, along: x + Double(w) / 2)
                }
            }
            x += Double(w) + 1
        }
        if sum {
            pen.bracket("sum", from: rx, to: x - 1, row: ry + H + (O < 4 * kk + 1 ? 3 : 2) * k, "\(T) + \(O) = \(qt)", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), tick: k)
        }
        // the division as school writes it: two squares to a digit
        let per = 2 * k, nd = Double(String(n).count), right = sq(g.colX) + (2 + nd) * per + per
        func row(_ r: Double) -> Double { ry + (r + 0.5) * per }
        let bracketX = right - nd * per - 0.3 * per
        if sum { wk.digits("q", String(qt), right: right, row: row(0), per: per, .chapter) }
        wk.digits("dv", String(dv), right: bracketX - 0.4 * per, row: row(1), per: per)
        wk.sketch.line("bracket", [wk.P(bracketX - 0.3 * per, ry + 2 * per), wk.P(bracketX, ry + 1.5 * per), wk.P(bracketX - 0.3 * per, ry + per), wk.P(right, ry + per)], .ink, width: 2)
        wk.digits("n", String(n), right: right, row: row(1), per: per)
        if found >= 1 {
            wk.word("m1", "−", at: right - (Double(String(products[0]).count) + 0.5) * per, row(2), label)
            wk.digits("p1", String(products[0]), right: right, row: row(2), per: per)
            wk.rule("u1", from: right - Double(String(products[0]).count) * per, to: right, row: ry + 3 * per)
            wk.word("t1", String(T), at: right + k, row(2), label.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        if left || found >= 2 { wk.digits("rest", String(rest), right: right, row: row(3), per: per) }
        if found >= 2 {
            wk.word("m2", "−", at: right - (Double(String(products[1]).count) + 0.5) * per, row(4), label)
            wk.digits("p2", String(products[1]), right: right, row: row(4), per: per)
            wk.rule("u2", from: right - Double(String(products[1]).count) * per, to: right, row: ry + 5 * per)
            wk.digits("zero", "0", right: right, row: row(5), per: per)
            wk.word("t2", "+ \(O)", at: right + k, row(4), label.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: the plain grid layout

    /// The picture across the top four blocks, the step on the block line under it, its line and Check a block apart,
    /// the keypad on the right.
    /// `rows`: how many rows of squares the picture needs; the step starts on the block line after them.
    static func gridLayout(rows: Int = 18) -> WorkProblem.Layout {
        var l = WorkProblem.Layout()
        let stepY = max(400, ((Double(rows) + 1) * Paper.cell / Paper.unit).rounded(.up) * Paper.unit)
        l.pictureTop = 0; l.pictureScale = 1
        l.stepX = 0; l.stepY = stepY; l.lineY = stepY + 100; l.column = 760; l.actions = stepY + 200; l.messageBelow = false
        l.keypadX = 900; l.keypadY = stepY
        l.height = max(10, (stepY + 300 + 200) / Paper.unit)
        return l
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
        if all { pen.rule("topb", from: x0, to: atTop(qt), row: top, .chapter, width: 4); pen.rule("botb", from: x0, to: atTop(qt), row: bottom, .chapter, width: 4) }
        else if one { pen.rule("top1", from: x0, to: atTop(1), row: top, .chapter, width: 4); pen.rule("bot1", from: x0, to: atTop(1), row: bottom, .chapter, width: 4) }
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

    // MARK: multiply by 10, 100, 1000

    /// 3.47 × 100 on a place-value chart of whole blocks: a column a block wide for each place, the digits in their
    /// columns, the point on the grid line between ones and tenths. The answer under it, its point hopped a block for
    /// each zero, every digit worth ten times more for each, a written-in 0 in each empty place.
    static func powersGrid(x: Double, k: Int, hop: Bool) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let names = ["thousands", "hundreds", "tens", "ones", "tenths", "hundredths"], cw = 5.0
        let head = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3), big = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
        for (i, n) in names.enumerated() {
            pen.word("h\(i)", n, at: (Double(i) + 0.5) * cw, 1, head)
            if i > 0 { pen.sketch.line("c\(i)", [pen.P(Double(i) * cw, 2), pen.P(Double(i) * cw, 15)], .line, width: 1) }
        }
        let pointX = 4 * cw
        func row(_ id: String, _ value: Double, at r: Double, written: Int = 0) {
            let (dg, whole) = PowersOfTen.digits(value)
            for (i, ch) in dg.enumerated() {
                let col = 4 - whole + i
                guard col >= 0, col < names.count else { continue }
                let isWritten = i >= dg.count - written
                if isWritten { pen.sketch.plate("\(id)z\(i)", pen.R(Double(col) * cw + 1, r - 1.5, 3, 3), .tint(0.3)) }
                pen.word("\(id)\(i)\(ch)", String(ch), at: (Double(col) + 0.5) * cw, r, big.colour(isWritten ? .chapter : .ink))
            }
            if dg.count > whole { pen.word("\(id).", ".", at: pointX, r + 0.6, Sketch.Words(size: Sketch.maths, weight: .bold, colour: .ink)) }
        }
        row("a", x, at: 5)
        pen.label("m", "× \(fmt(pow(10, Double(k))))", Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), .right, edge: 6 * cw, along: 5)
        if hop {
            let ans = x * pow(10, Double(k)), (dg, w) = PowersOfTen.digits(x), (ag, _) = PowersOfTen.digits(ans)
            row("b", ans, at: 11, written: max(0, ag.count - dg.count))
            _ = w
            for j in 0..<k { pen.hop("hop\(j)", from: pointX + Double(j) * cw, to: pointX + Double(j + 1) * cw, row: 7, height: 1.2) }
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: adding decimals

    /// 12.5 + 3.75 on the grid: the sum in columns two squares to a digit, the points on one grid line with a line down
    /// through them, a 0 written in so both have hundredths; the whole columns' band, then the decimal columns'; the
    /// parts' sums on the right; the total under the line.
    static func addDecimalsGrid(a: Double, b: Double, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        // three squares to a digit, so each column has room for its place's name over it
        // five squares to a column, a block, so each column's place name fits over it
        let lit = p["lit"], per = 5.0, pointCol = 20.0, right = pointCol + 2 * per
        let A = String(format: "%.2f", a), B = String(format: "%.2f", b), big: CGFloat = Sketch.maths
        let small = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3)
        // the place names over the columns
        for (i, n) in ["tens", "ones", "tenths", "hundredths"].enumerated() {
            pen.word("h\(i)", n, at: pointCol + (Double(i) - 2 + 0.5) * per, 1, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3))
        }
        if lit == 1 { pen.sketch.fill("bw", pen.R(pointCol - 2 * per, 2, 2 * per, 12), .tint(0.16)) }
        if lit == 2 { pen.sketch.fill("bd", pen.R(pointCol, 2, 2 * per, 12), .tint(0.16)) }
        pen.digits("a", A, right: right, row: 3.5, per: per, size: big)
        if (a * 10).rounded() == a * 10 {
            pen.sketch.plate("zf", pen.R(right - per, 2, per, per), lit == 0 ? .tint(0.38) : .tint(0.2))
            pen.word("z", "0", at: right - per / 2, 3.5, Sketch.Words(size: Sketch.maths, weight: .medium, colour: .chapter))
        }
        pen.word("plus", "+", at: pointCol - 2.5 * per, 6.5, Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink))
        pen.digits("b", B, right: right, row: 6.5, per: per, size: big)
        pen.rule("rule", from: pointCol - 3 * per, to: right, row: 8)
        pen.sketch.line("wire", [pen.P(pointCol, 2), pen.P(pointCol, 14)], .chapter, width: 1.5, dashed: true)
        if p["total"] == 1 { pen.digits("t", String(format: "%.2f", a + b), right: right, row: 9.5, per: per, size: big, .chapter) }
        // the parts, on the right, row for row with the sum
        let wx = 36.0, whole = Double(Int(a) + Int(b)), dec = (a - Double(Int(a))) + (b - Double(Int(b)))
        wk.word("hw", "wholes", at: wx, 3.5, small, anchor: UnitPoint(x: 0, y: 0.5))
        wk.word("hd", "after the point", at: wx, 6.5, small, anchor: UnitPoint(x: 0, y: 0.5))
        let num = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
        if p["whole"] == 1 { wk.word("sw", fmt(whole), at: wx + 20, 3.5, num, anchor: UnitPoint(x: 1, y: 0.5)) }
        if p["decimal"] == 1 { wk.word("sd", String(format: "%.2f", dec), at: wx + 20, 6.5, num.colour(p["carry"] == 1 ? .chapter : .ink), anchor: UnitPoint(x: 1, y: 0.5)) }
        if p["total"] == 1 {
            wk.rule("r2", from: wx + 10, to: wx + 20, row: 8)
            wk.word("st", String(format: "%.2f", a + b), at: wx + 20, 9.5, num.colour(.chapter), anchor: UnitPoint(x: 1, y: 0.5))
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: fractions

    static func frac(_ a: Int, _ b: Int) -> Math { .frac(.num(Double(a)), .num(Double(b))) }

    /// 1/2 + 1/3 on the grid: on the left the sum as school writes it, each fraction rewritten over the common bottom
    /// with its × beside it, a digit to a square; on the right the bars, one whole each, a length every bottom divides
    /// (so a third and a fourth of twelve are exact squares), cut into the same size pieces, then put together (or
    /// taken away).
    static func unlikeGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 1), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 1), minus = n["minus"] == 1
        let L = Int(n["L"] ?? 1), A = Int(n["A"] ?? 0), C = Int(n["C"] ?? 0), S = Int(n["S"] ?? 0)
        let cut = p["cut"] == 1, first = p["first"] == 1, second = p["second"] == 1, combine = p["combine"] == 1, focus = p["focus"]
        let small = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2), chapter = Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter)
        // school: a/b = A/L (× L/b) over c/d = C/L, a line, S/L
        wk.math("f1", first ? [frac(a, b), .op("="), frac(A, L)] : [frac(a, b)], col: 1, row: 1)
        if first { wk.word("k1", "× \(L / b)", at: 9, 3, chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        wk.word("op", minus ? "−" : "+", at: 0, 8, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink))
        wk.math("f2", second ? [frac(c, d), .op("="), frac(C, L)] : [frac(c, d)], col: 1, row: 6)
        if second { wk.word("k2", "× \(L / d)", at: 9, 8, chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        if combine {
            wk.rule("r", from: 0, to: 12, row: 11)
            wk.math("ans", [frac(S, L)], col: 5, row: 11)
            if p["answer"] == 1 {
                let g = gcd(S, L), whole = S / L, rem = S % L
                let simple = whole >= 1 ? (rem == 0 ? "\(whole)" : "\(whole) \(rem / gcd(rem, L))/\(L / gcd(rem, L))") : "\(S / g)/\(L / g)"
                wk.word("simp", "= \(simple)", at: 8, 13, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        // the bars: a whole is L pieces of `per` squares
        let per = max(1, 36 / L), length = L * per, x0 = 20.0
        pen.bar("b1", col: x0, row: 2, length: length, parts: cut ? L : b, shaded: cut ? A : a, lit: focus == 1 || focus == 3)
        pen.label("l1", first ? "\(A)/\(L)" : "\(a)/\(b)", small, .right, edge: x0 + Double(length), along: 3)
        pen.bar("b2", col: x0, row: 7, length: length, parts: cut ? L : d, shaded: cut ? C : c, striped: true, lit: focus == 2 || focus == 3)
        pen.label("l2", second ? "\(C)/\(L)" : "\(c)/\(d)", small, .right, edge: x0 + Double(length), along: 8)
        if combine {
            if minus {
                pen.bar("b3", col: x0, row: 12, length: length, parts: L, shaded: S, lit: focus == 4, struck: S..<min(L, S + C))
            } else {
                let bars = max(1, Int((Double(S) / Double(L)).rounded(.up)))
                for j in 0..<bars {
                    let row = 12 + Double(j) * 3, base = j * L
                    pen.bar("b3\(j)", col: x0, row: row, length: length, parts: L, shaded: max(0, min(L, A - base)), lit: focus == 4)
                    let from = max(0, A - base), count = max(0, min(L - from, S - base - from))
                    if count > 0 { pen.bar("b3c\(j)", col: x0, row: row, length: length, parts: L, shaded: count, from: from, striped: true, lit: focus == 4) }
                }
            }
            pen.label("l3", "\(S)/\(L)", chapter, .right, edge: x0 + Double(length), along: 13)
        }
        return (pen.sketch, wk.sketch)
    }

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

    /// 2 3/4 on the grid: a bar per whole and one for the extra pieces, each piece a whole number of squares, every
    /// piece counted on; on the right the mixed number rewritten.
    static func improperGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let w = Int(n["w"] ?? 1), nn = Int(n["n"] ?? 1), d = Int(n["d"] ?? 2)
        let wholes = Int(p["wholes"] ?? 0), extra = p["extra"] == 1, fraction = p["fraction"] == 1, focus = p["focus"]
        let per = max(2, 30 / d), length = d * per, x0 = 3.0, small = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
        for j in 0...w {
            let row = 1 + Double(j) * 3, isExtra = j == w, filled = isExtra ? (extra ? nn : 0) : (j < wholes ? d : 0)
            pen.bar("b\(j)", col: x0, row: row, length: length, parts: d, shaded: filled, striped: isExtra,
                    lit: (focus == 1 && !isExtra) || (focus == 2 && isExtra) || focus == 3)
            pen.label("bl\(j)", isExtra ? "\(nn)/\(d)" : "1", small, .left, edge: x0, along: row + 1)
            if filled > 0 { pen.label("cnt\(j)\(j * d + filled)", "\(j * d + filled)", small.colour(isExtra || j == w - 1 ? .chapter : .ink2), .right, edge: x0 + Double(length), along: row + 1) }
        }
        let wx = x0 + Double(length) + 8, line = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        wk.math("mixed", [.num(Double(w)), frac(nn, d)] + (fraction ? [.op("="), frac(w * d + nn, d)] : []), col: wx, row: 1)
        if wholes >= w { wk.word("l1", "\(w) × \(d) = \(w * d)", at: wx, 8, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        if extra { wk.word("l2", "\(w * d) + \(nn) = \(w * d + nn)", at: wx, 11, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        return (pen.sketch, wk.sketch)
    }

    /// 3/4 of 20 on the grid: the bar of 20 cut into 4 equal groups (each a whole number of squares), 3 taken, a
    /// bracket under them; the working under the bar.
    static func fractionOfGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let nn = Int(n["n"] ?? 1), d = Int(n["d"] ?? 2), W = Int(n["W"] ?? 0), g = W / max(1, d)
        let at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        let length = d * max(3, 40 / d), x0 = 0.0, row = 3.0, label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
        pen.label("W", "\(W)", label, .above, edge: row, along: x0 + Double(length) / 2)
        let cutNow = at >= 1 || ask == 1
        pen.bar("g", col: x0, row: row, length: length, height: 3, parts: cutNow ? d : 1, shaded: at >= 2 ? nn : (cutNow ? 0 : 1), lit: ask == 2 || at >= 2)
        if at >= 1 { for i in 0..<d { pen.word("gl\(i)", "\(g)", at: x0 + (Double(i) + 0.5) * Double(length / d), row + 1.5, Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)) } }
        if at >= 2 { pen.bracket("br", from: x0, to: x0 + Double(nn * (length / d)), row: row + 5, "\(nn)/\(d)", Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter)) }
        let line = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        if at >= 1 { wk.word("l1", "\(W) ÷ \(d) = \(g)", at: x0, 12, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at >= 2 { wk.word("l2", "\(g) × \(nn) = \(g * nn)", at: x0, 15, line.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        return (pen.sketch, wk.sketch)
    }

    /// 3 ÷ 1/4 on the grid: a bar per whole, cut into fourths of whole squares and counted on; on the right, 1 = 4 × 1/4
    /// and 3 × 4 = 12.
    static func unitDivideGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        var pen = GridPen()
        var wk = GridPen()
        let W = Int(n["W"] ?? 1), d = Int(n["d"] ?? 2), at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        let per = max(2, 32 / d), length = d * per, x0 = 2.0, tall: Double = W > 6 ? 1 : 2, step = tall + 1
        let small = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)
        for j in 0..<W {
            let row = 1 + Double(j) * step, beat = min(j + 1, 3), isCut = at >= beat
            pen.bar("b\(j)", col: x0, row: row, length: length, height: tall, parts: isCut ? d : 1, shaded: isCut ? d : 1, lit: ask == beat)
            pen.label("one\(j)", "1", small, .left, edge: x0, along: row + tall / 2)
            if isCut { pen.label("c\(j)", "\((j + 1) * d)", small.colour(j == W - 1 ? .chapter : .ink2), .right, edge: x0 + Double(length), along: row + tall / 2) }
        }
        let wx = x0 + Double(length) + 6, line = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
        if at >= 1 { wk.word("l1", "1 = \(d) × 1/\(d)", at: wx, 2, line, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at >= min(W, 3) { wk.word("l2", "\(W) × \(d) = \(W * d)", at: wx, 5, line.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
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
            pen.sketch.box("\(id)o", pen.R(col, row, Double(cols) * cube, Double(rows) * cube), .chapter, width: 2)
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
            pen.sketch.box("ub\(i)", pen.R(col, row, cw, ch), .tint(0.7), width: 2)
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
        pen.sketch.box("unito", pen.R(ux, uy, 10, 10), .chapter, width: 2)
        if lit {
            let size = fmt(1 / pow(10, Double(places)))
            pen.label("ps", places > 2 ? "one piece: \(size) (a tenth of a square)" : "one piece: \(size)", Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter), .below, edge: uy + 10, along: ux + 5)
        }
        return (pen.sketch, wk.sketch)
    }

    // MARK: rounding

    /// Rounding on the grid: the number two squares to a digit along the top, the step under the number line, the
    /// keypad beside it.
    static func roundLayout() -> WorkProblem.Layout {
        var l = WorkProblem.Layout()
        l.pictureTop = 0; l.pictureScale = 1
        l.stepX = 0; l.stepY = 300; l.lineY = 400; l.column = 700; l.actions = 500; l.messageBelow = false
        l.keypadX = 800; l.keypadY = 300
        return l
    }

    /// 6.723 to the nearest tenth, on the grid: the number two squares to a digit, its place underlined and the next
    /// digit ringed; the number line from 6.7 to 6.8 where the squares are the distance (ten steps of four squares, so
    /// halfway is the middle grid line and 6.723 sits 9.2 squares along: plainly nearer 6.7); the hop to the nearer end;
    /// and the working beside it.
    static func roundGrid(_ n: Numbers, _ p: Numbers) -> (picture: Sketch, work: Sketch) {
        let parts = RoundDecimals.Parts(n)
        let lo = p["lo"] ?? parts.T, hi = p["hi"] ?? parts.up, tick = p["tick"] ?? parts.place / 10, value = parts.value
        let lit = p["lit"], halfway = p["halfway"] == 1, hop = p["hop"] == 1
        var pen = GridPen()
        var wk = GridPen()
        let big = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink), label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink2)

        // the number, two squares to a digit, from the left edge; its place underlined, the digit after it ringed
        // written as the problem writes it (3.18, not 3.180)
        let text = fmt(value), digitsOnly = text.filter { $0 != "." }, wholeDigits = text.split(separator: ".")[0].count
        let right = Double(digitsOnly.count) * 2
        pen.digits("num", text, right: right, row: 1, per: 2, size: Sketch.maths)
        let placeCol = Double(wholeDigits + parts.p - 1) * 2, nextCol = placeCol + 2
        pen.rule("place", from: placeCol, to: placeCol + 2, row: 2, lit == 0 ? .chapter : .ink2, width: 3)
        if halfway { pen.ring("next", col: nextCol, row: 0, w: 2, h: 2) }
        _ = big

        // the number line: ten steps of four squares from lo to hi, long ticks at the ends and halfway
        let per = 4.0, row = 10.0
        let at = pen.numberLine("line", col: 0, row: row, steps: 10, per: per, long: 5)
        func col(_ v: Double) -> Double { (v - lo) / tick * per }
        // every label half a square from what it labels: the ends and halfway under the line, the number over the ticks
        pen.label("lo", fmt(lo), label.colour(lit == 0 ? .chapter : .ink2), .below, edge: row, along: at(0))
        pen.label("hi", fmt(hi), label.colour(lit == 0 ? .chapter : .ink2), .below, edge: row, along: at(10))
        if halfway {
            pen.dot("half", at: at(5), row, radius: 0.3, lit == 1 ? .chapter : .ink2)
            pen.label("halfw", fmt(parts.half), label.colour(lit == 1 ? .chapter : .ink3), .below, edge: row, along: at(5))
        }
        pen.dot("value", at: col(value), row, radius: 0.4, .tint(0.7))
        pen.label("valuew", fmt(value), label.colour(lit == 0 ? .chapter : .ink), .above, edge: row - 2, along: col(value))
        if hop {
            let to = col(parts.R)
            // under the tall ticks' tops, so it stays clear of the number's label over them
            pen.hop("hop", from: col(value), to: to, row: row, height: 1.5)
            pen.dot("rounded", at: to, row, radius: 0.4)
            // over the hop and above the number's label, so the two never meet
            pen.label("hopw", parts.halfway ? "halfway: up" : "closer", label.colour(.chapter), .above, edge: row - 4.5, along: (col(value) + to) / 2)
        }

        // the working, beside the line: the next digit against 5, then the answer
        let wx = 45.0
        if halfway {
            wk.word("cmp", parts.next >= 5 ? "\(parts.next) is 5 or more: up" : "\(parts.next) is 4 or less: stays", at: wx, 1, label.colour(.ink), anchor: UnitPoint(x: 0, y: 0.5))
        }
        if hop {
            wk.word("ans", "\(fmt(value)) ≈ \(fmt(parts.R))", at: wx, 3, Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter), anchor: UnitPoint(x: 0, y: 0.5))
        }
        return (pen.sketch, wk.sketch)
    }

    /// 864 ÷ 12 in chunks: on the left the division bracket as school writes it, the tens taken away first and the
    /// partial answers beside them; on the right the area model run backwards, 12 tall, its strips' widths found.
    static func divide(_ s: inout Sketch, dv: Int, qt: Int, strip: Int, found: Int, left: Bool, sum: Bool) {
        let n = dv * qt, T = qt - qt % 10, O = qt % 10, rest = n - dv * T
        let cell = 20.0, rx = 160.0, bx = rx - 4 * cell - 10
        // the bracket: the divisor outside, the number under the line, the answer over it at the end
        s.digits("dv", String(dv), right: bx - 6, y: 50, cell: cell)
        s.line("br", [P(bx, 70), P(bx + 6, 50), P(bx, 30), P(rx + 6, 30)], .ink, width: 2)
        s.digits("n", String(n), right: rx, y: 50, cell: cell)
        if sum { s.digits("q", String(qt), right: rx, y: 12, .chapter, cell: cell) }
        if found >= 1 {
            s.text("m1", "−", at: P(rx - Double(String(dv * T).count) * cell - 12, 84), size: 22)
            s.digits("p1", String(dv * T), right: rx, y: 84, cell: cell)
            s.line("u1", [P(rx - 3.5 * cell, 102), P(rx + 4, 102)], .ink, width: 2)
            s.text("t1", String(T), at: P(rx + 36, 84), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
        }
        if left || found >= 2 { s.digits("l", String(rest), right: rx, y: 120, cell: cell) }
        if found >= 2 {
            s.text("m2", "−", at: P(rx - Double(String(dv * O).count) * cell - 12, 154), size: 22)
            s.digits("p2", String(dv * O), right: rx, y: 154, cell: cell)
            s.line("u2", [P(rx - 2.5 * cell, 172), P(rx + 4, 172)], .ink, width: 2)
            s.digits("z", "0", right: rx, y: 190, cell: cell)
            s.text("t2", "+ \(O)", at: P(rx + 36, 154), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // the area model: dv tall, the tens strip and the ones strip
        let x0 = 400.0, top = 46.0, k = min(270.0 / Double(qt), 140.0 / Double(dv)), h = max(64, Double(dv) * k)
        let widths = [max(60, Double(T) * k), max(34, Double(O) * k)], products = [dv * T, dv * O]
        s.text("side", String(dv), at: P(x0 - 20, top + h / 2), size: 20, .chapter)
        var x = x0
        for i in 0..<2 {
            let lit = strip == i + 1
            s.fill("s\(i)", R(x, top, widths[i], h), lit ? mid : soft)
            s.box("o\(i)", R(x, top, widths[i], h), .chapter, width: 2)
            if i < found {
                s.text("w\(i)", String(i == 0 ? T : O), at: P(x + widths[i] / 2, top - 16), size: 20, lit ? .chapter : .ink2)
                s.text("in\(i)", String(products[i]), at: P(x + widths[i] / 2, top + h / 2), size: 17)
            } else if i == 1, left {
                s.text("left", String(rest), at: P(x + widths[i] / 2, top + h / 2), size: 17, .ink2)
                s.text("w1q", "?", at: P(x + widths[i] / 2, top - 16), size: 20, .chapter)
            } else if lit {
                s.text("q\(i)", "?", at: P(x + widths[i] / 2, top - 16), size: 20, .chapter)
            }
            x += widths[i] + 10
        }
        if sum { bracket(&s, "sum", x0: x0, x1: x - 10, y: top + h + 40, "\(T) + \(O) = \(qt)") }
    }

    /// 3 + 4 × (6 − 2): the expression rewritten line under line as school does it, the part to do first lit on each
    /// line; on the right the order to follow, the rule being used lit.
    static func order(_ s: inout Sketch, _ n: Numbers, beat: Int) {
        let t = Int(n["t"] ?? 0), a = n["a"] ?? 0, b = n["b"] ?? 0, c = n["c"] ?? 0, d = n["d"] ?? 0
        let A = f(a), B = f(b), C = f(c), D = f(d)
        var lines: [String] = [], groups: [String] = [], rules: [Int] = []
        switch t {
        case 0:
            let v1 = c - d, v2 = b * v1, v3 = a + v2
            lines = ["\(A) + \(B) × (\(C) − \(D))", "\(A) + \(B) × \(f(v1))", "\(A) + \(f(v2))", f(v3)]
            groups = ["(\(C) − \(D))", "\(B) × \(f(v1))", "\(A) + \(f(v2))"]; rules = [0, 1, 2]
        case 1:
            let v1 = a + b, v2 = v1 * c, v3 = v2 - d
            lines = ["(\(A) + \(B)) × \(C) − \(D)", "\(f(v1)) × \(C) − \(D)", "\(f(v2)) − \(D)", f(v3)]
            groups = ["(\(A) + \(B))", "\(f(v1)) × \(C)", "\(f(v2)) − \(D)"]; rules = [0, 1, 2]
        default:
            let v1 = a * b, v2 = c / d, v3 = v1 - v2
            lines = ["\(A) × \(B) − \(C) ÷ \(D)", "\(f(v1)) − \(C) ÷ \(D)", "\(f(v1)) − \(f(v2))", f(v3)]
            groups = ["\(A) × \(B)", "\(C) ÷ \(D)", "\(f(v1)) − \(f(v2))"]; rules = [1, 1, 2]
        }
        let font = PaperText.font(26, .medium, digits: true), shown = min(max(beat, 0), 3)
        for i in 0...shown {
            let y = 24 + Double(i) * 52, x0 = i == 0 ? 0.0 : 30.0
            if i > 0 { s.text("eq\(i)", "=", at: P(0, y), size: 26, anchor: UnitPoint(x: 0, y: 0.5)) }
            let line = lines[i]
            // the part done on this line, lit
            if i == beat - 1, i < groups.count, let r = line.range(of: groups[i]) {
                let before = PaperText.width(String(line[..<r.lowerBound]), font), w = PaperText.width(groups[i], font)
                s.fill("hl\(i)", R(x0 + before - 6, y - 20, w + 12, 40), mid)
            }
            s.text("l\(i)", line, at: P(x0, y), size: 26, i == 3 ? .chapter : .ink, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // the order to follow
        let names = ["( )  first", "×  ÷  next", "+  −  last"], rx = 520.0
        let litRule = beat >= 1 && beat <= 3 ? rules[beat - 1] : -1
        for (i, name) in names.enumerated() {
            let y = 30 + Double(i) * 46
            s.fill("rf\(i)", R(rx, y - 18, 150, 36), i == litRule ? mid : soft)
            s.text("rn\(i)", "\(i + 1)", at: P(rx + 18, y), size: 18, .chapter)
            s.text("rt\(i)", name, at: P(rx + 40, y), size: 18, i == litRule ? .ink : .ink2, anchor: UnitPoint(x: 0, y: 0.5))
        }
    }

    // MARK: decimals

    /// 3.47 × 100: a place-value chart, the number in it; each zero hops the point one place right (every digit worth
    /// ten times more), with a 0 written in for each empty place.
    static func powers(_ s: inout Sketch, x: Double, k: Int, counted: Bool, hop: Bool) {
        let names = ["thousands", "hundreds", "tens", "ones", "tenths", "hundredths"], cw = 100.0, x0 = 20.0
        for (i, name) in names.enumerated() {
            s.text("h\(i)", name, at: P(x0 + (Double(i) + 0.5) * cw, 14), size: 13, .ink3)
            if i > 0 { s.line("c\(i)", [P(x0 + Double(i) * cw, 30), P(x0 + Double(i) * cw, 190)], .line, width: 1) }
        }
        let pointX = x0 + 4 * cw
        func row(_ id: String, _ value: Double, y: Double, colour: Sketch.Colour, zerosFrom: Int? = nil) {
            let (dg, whole) = PowersOfTen.digits(value)
            for (i, ch) in dg.enumerated() {
                let col = 4 - whole + i
                guard col >= 0, col < names.count else { continue }
                let written = zerosFrom.map { i >= $0 } ?? false
                if written { s.fill("\(id)z\(i)", R(x0 + Double(col) * cw + 18, y - 22, cw - 36, 44), mid) }
                s.text("\(id)\(i)", String(ch), at: P(x0 + (Double(col) + 0.5) * cw, y), size: 28, written ? .chapter : colour)
            }
            s.text("\(id).", ".", at: P(pointX, y + 8), size: 30, weight: .bold, colour)
        }
        row("a", x, y: 70, colour: .ink)
        if counted { s.text("m", "× \(f(pow(10, Double(k))))", at: P(x0 + 6 * cw + 20, 70), size: 22, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        if hop {
            let ans = x * pow(10, Double(k)), (dg, w) = PowersOfTen.digits(x)
            row("b", ans, y: 150, colour: .ink, zerosFrom: dg.count - w < k ? dg.count + 0 : nil)
            // the point's hops, one arc per place
            for j in 0..<k {
                let x1 = pointX + Double(j) * cw, x2 = x1 + cw
                let arc = (0...10).map { i -> CGPoint in let t = Double(i) / 10; return P(x1 + (x2 - x1) * t, 96 + sin(.pi * t) * 18) }
                s.line("hop\(j)", arc, .chapter, width: 2)
            }
            s.text("cap", "every digit is worth \(f(pow(10, Double(k)))) times more", at: P(x0, 214), size: 16, .ink2, anchor: UnitPoint(x: 0, y: 0.5))
        }
    }

    /// 3.476 to the nearest hundredth: the number with its place underlined and the next digit ringed; under it the
    /// number line from 3.47 to 3.48, its halfway mark, and the hop to the closer end.
    static func round(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let N = Int(n["N"] ?? 0), places = Int(n["p"] ?? 2), value = Double(N) / 1000
        let text = String(format: "%.3f", value), chars = Array(text)
        let lo = p["lo"] ?? 0, hi = p["hi"] ?? 0, half = p["half"] ?? 0, rounded = p["rounded"] ?? 0
        let lit = p["lit"], halfway = p["halfway"] == 1, hop = p["hop"] == 1
        // the number, digit by digit: the place being rounded to underlined, the digit after it ringed
        let font = PaperText.font(32, .medium, digits: true), dot = chars.firstIndex(of: ".") ?? 0
        var x = 0.0
        for (i, ch) in chars.enumerated() {
            let w = PaperText.width(String(ch), font)
            s.text("d\(i)", String(ch), at: P(x + w / 2, 30), size: 32)
            if i == dot + places { s.line("u", [P(x, 54), P(x + w, 54)], .chapter, width: 3) }
            if i == dot + places + 1, halfway {
                let ring = (0...24).map { j -> CGPoint in let a = Double(j) / 24 * 2 * .pi; return P(x + w / 2 + 18 * cos(a), 30 + 22 * sin(a)) }
                s.line("ring", ring, .chapter, width: 2)
            }
            x += w
        }
        if hop { s.text("ans", "≈ \(f(rounded))", at: P(x + 16, 30), size: 32, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        // the number line
        let x0 = 30.0, x1 = 690.0, y = 170.0
        func X(_ v: Double) -> Double { hi == lo ? x0 : x0 + (v - lo) / (hi - lo) * (x1 - x0) }
        s.line("axis", [P(x0, y), P(x1, y)], .ink, width: 2)
        for i in 0...10 {
            let tx = x0 + Double(i) / 10 * (x1 - x0), long = i == 0 || i == 5 || i == 10
            s.line("t\(i)", [P(tx, y - (long ? 12 : 6)), P(tx, y + (long ? 12 : 6))], .ink, width: 2)
        }
        s.text("lo", f(lo), at: P(x0, y + 30), size: 18, lit == 0 ? .chapter : .ink2)
        s.text("hi", f(hi), at: P(x1, y + 30), size: 18, lit == 0 ? .chapter : .ink2)
        let vx = X(value)
        s.polygon("vd", circle(P(vx, y), 7), mid)
        s.text("vl", f(value), at: P(vx, y - 30), size: 18, lit == 0 ? .chapter : .ink)
        if halfway {
            s.polygon("hd", circle(P(X(half), y), 6), .chapter)
            s.text("hl", f(half), at: P(X(half), y + 30), size: 16, lit == 1 ? .chapter : .ink3)
        }
        if hop, rounded != value {
            let rx = X(rounded)
            let arc = (0...12).map { i -> CGPoint in let t = Double(i) / 12; return P(vx + (rx - vx) * t, y - 44 - sin(.pi * t) * 26) }
            s.line("hop", arc, .chapter, width: 2)
            s.polygon("rd", circle(P(rx, y), 7), .chapter)
            s.text("hw", p["halfwayUp"] == 1 ? "halfway: up" : "closer", at: P((vx + rx) / 2, y - 84), size: 16, .chapter)
        }
    }

    static func circle(_ c: CGPoint, _ r: Double) -> [CGPoint] {
        (0..<20).map { i in let a = Double(i) / 20 * 2 * .pi; return P(c.x + r * cos(a), c.y + r * sin(a)) }
    }

    /// 12.5 + 3.75: the sum in columns as school writes it, the points lined up and a 0 written in; on the right the
    /// whole parts added, the decimal parts added, then the two together.
    static func addDecimals(_ s: inout Sketch, a: Double, b: Double, _ p: Numbers) {
        let A = String(format: "%.2f", a), Bs = String(format: "%.2f", b), lit = p["lit"]
        let cell = 26.0, rx = 170.0, pointX = rx - 2 * cell
        // bands behind the columns being added
        if lit == 1 { s.fill("bw", R(pointX - 3 * cell, 8, 3 * cell, 120), soft) }
        if lit == 2 { s.fill("bd", R(pointX, 8, 2 * cell, 120), soft) }
        s.digits("a", A, right: rx, y: 30, cell: cell)
        if Double(Int(a * 10)) == a * 10 { s.fill("zf", R(rx - cell + 2, 14, cell - 4, 32), lit == 0 ? mid : soft); s.text("z", "0", at: P(rx - cell / 2, 30), size: 24, .chapter) }
        s.text("plus", "+", at: P(pointX - 4 * cell, 72), size: 24)
        s.digits("b", Bs, right: rx, y: 72, cell: cell)
        s.line("rule", [P(pointX - 4.5 * cell, 96), P(rx + 4, 96)], .ink, width: 2)
        s.line("wire", [P(pointX + 0.5, 4), P(pointX + 0.5, 130)], .chapter, width: 1.5, dashed: true)
        if p["total"] == 1 { s.digits("t", String(format: "%.2f", a + b), right: rx, y: 118, .chapter, cell: cell) }
        // the parts, on the right
        let wx = 560.0, whole = Double(Int(a) + Int(b)), dec = (a - Double(Int(a))) + (b - Double(Int(b)))
        s.text("hw", "wholes", at: P(380, 30), size: 15, .ink3, anchor: UnitPoint(x: 0, y: 0.5))
        s.text("hd", "after the point", at: P(380, 72), size: 15, .ink3, anchor: UnitPoint(x: 0, y: 0.5))
        if p["whole"] == 1 { s.text("sw", f(whole), at: P(wx + 60, 30), size: 24, anchor: UnitPoint(x: 1, y: 0.5)) }
        if p["decimal"] == 1 { s.text("sd", String(format: "%.2f", dec), at: P(wx + 60, 72), size: 24, p["carry"] == 1 ? .chapter : .ink, anchor: UnitPoint(x: 1, y: 0.5)) }
        if p["total"] == 1 {
            s.line("r2", [P(wx - 20, 96), P(wx + 64, 96)], .ink, width: 2)
            s.text("st", String(format: "%.2f", a + b), at: P(wx + 60, 118), size: 24, .chapter, anchor: UnitPoint(x: 1, y: 0.5))
        }
    }

    /// 2.4 × 0.3: on the left the multiplication with each number's places counted; on the right the strip on whole
    /// unit squares, cut into the small pieces its places make.
    static func multiplyDecimals(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let A = Int(n["A"] ?? 0), B = Int(n["B"] ?? 0), pa = Int(n["pa"] ?? 0), pb = Int(n["pb"] ?? 0)
        let x = Double(A) / pow(10, Double(pa)), y = Double(B) / pow(10, Double(pb)), ans = x * y
        let line = p["line"], cell = 22.0, rx = 120.0
        s.digits("a", f(x), right: rx, y: 30, cell: cell)
        s.text("x", "×", at: P(rx - 5 * cell, 72), size: 24)
        s.digits("b", f(y), right: rx, y: 72, cell: cell)
        s.text("pa", pa == 1 ? "1 place" : "\(pa) places", at: P(rx + 14, 30), size: 15, p["piece"] == 1 ? .chapter : .ink3, anchor: UnitPoint(x: 0, y: 0.5))
        s.text("pb", pb == 1 ? "1 place" : "\(pb) places", at: P(rx + 14, 72), size: 15, p["piece"] == 1 ? .chapter : .ink3, anchor: UnitPoint(x: 0, y: 0.5))
        s.line("r", [P(rx - 5.5 * cell, 94), P(rx + 4, 94)], .ink, width: 2)
        if line == 2 {
            s.digits("t", f(ans), right: rx, y: 116, .chapter, cell: cell)
            s.text("pt", pa + pb == 1 ? "1 place" : "\(pa + pb) places", at: P(rx + 14, 116), size: 15, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
        }
        let lines = ["\(A) × \(B) = \(A * B) small pieces", "\(f(1 / pow(10, Double(pa)))) × \(f(1 / pow(10, Double(pb)))) = \(f(1 / pow(10, Double(pa + pb))))",
                     "\(A * B) \(pa + pb == 1 ? "tenths" : pa + pb == 2 ? "hundredths" : "thousandths") = \(f(ans))"]
        if let l = line { s.text("line", lines[Int(l)], at: P(0, 160), size: 18, .ink2, anchor: UnitPoint(x: 0, y: 0.5)) }
        // the strip on its unit squares
        let wide = max(x, y), tall = min(x, y), cols = max(1, Int(wide.rounded(.up))), rows = max(1, Int(tall.rounded(.up)))
        let u = min(320.0 / Double(cols), 150.0 / Double(rows), 130), x0 = 360.0, y0 = 20.0
        for i in 0..<cols { for j in 0..<rows { s.box("u\(i)\(j)", R(x0 + Double(i) * u, y0 + Double(j) * u, u, u), .line, width: 1) } }
        let sw = wide * u, sh = tall * u, sy = y0 + Double(rows) * u - sh
        s.fill("strip", R(x0, sy, sw, sh), p["lit"] == 0 ? mid : soft)
        s.box("so", R(x0, sy, sw, sh), .chapter, width: 2)
        let stepX = u / pow(10, Double(x >= y ? pa : pb)), stepY = u / pow(10, Double(x >= y ? pb : pa))
        if stepX >= 4 { var gx = x0 + stepX; while gx < x0 + sw - 1 { s.line("gx\(Int(gx))", [P(gx, sy), P(gx, sy + sh)], .tint(0.45), width: 1); gx += stepX } }
        if stepY >= 4 { var gy = sy + stepY; while gy < sy + sh - 1 { s.line("gy\(Int(gy))", [P(x0, gy), P(x0 + sw, gy)], .tint(0.45), width: 1); gy += stepY } }
        s.text("sl", f(wide), at: P(x0 + sw / 2, y0 + Double(rows) * u + 18), size: 17, .ink2)
        s.text("sh", f(tall), at: P(x0 - 18, sy + sh / 2), size: 17, .ink2)
        if p["piece"] == 1, stepX >= 4, stepY >= 4 {
            s.box("pc", R(x0, sy + sh - stepY, stepX, stepY), .chapter, width: 2)
            s.fill("chip", R(x0 + sw + 24, sy + sh - 34, 34, 34), mid)
            s.text("chipl", f(1 / pow(10, Double(pa + pb))), at: P(x0 + sw + 41, sy + sh + 14), size: 16, .chapter)
            s.line("lead", [P(x0 + stepX, sy + sh - stepY / 2), P(x0 + sw + 24, sy + sh - 17)], .chapter, width: 1.5)
        }
    }

    /// 4.8 ÷ 0.6: both numbers ten times bigger on a double number line, the top counting by 0.6, the bottom by 6,
    /// tick for tick; then the hops counted.
    static func divideDecimal(_ s: inout Sketch, d: Int, qt: Int, _ p: Numbers) {
        let x0 = 70.0, x1 = 700.0, top = 60.0, bottom = 150.0, step = (x1 - x0) / Double(qt)
        let one = p["one"] == 1, all = p["all"] == 1, hops = p["hops"] == 1, lit = p["lit"]
        s.text("x10", "× 10", at: P(24, (top + bottom) / 2), size: 18, .chapter)
        for (id, y) in [("top", top), ("bot", bottom)] {
            s.line(id, [P(x0, y), P(x1, y)], .ink2, width: 2)
            if all { s.line(id + "b", [P(x0, y), P(x1, y)], .chapter, width: 4) } else if one { s.line(id + "1", [P(x0, y), P(x0 + step, y)], .chapter, width: 4) }
        }
        for i in 0...qt {
            let x = x0 + Double(i) * step
            s.line("tt\(i)", [P(x, top - 6), P(x, top + 6)], .ink, width: 2)
            s.line("bt\(i)", [P(x, bottom - 6), P(x, bottom + 6)], .ink, width: 2)
            if qt <= 8 || i % 2 == 0 || i == qt {
                let litTop = (lit == 0 && i == 1) || (lit == 1 && i == qt)
                s.text("tl\(i)", f(Double(d * i) / 10), at: P(x, top - 22), size: 15, litTop ? .chapter : .ink2)
                if all || (one && i <= 1) { s.text("bl\(i)", String(d * i), at: P(x, bottom + 24), size: 15, litTop ? .chapter : .ink2) }
            }
            if all { s.line("w\(i)", [P(x, top + 8), P(x, bottom - 8)], .tint(0.45), width: 1.5) }
        }
        if hops {
            for i in 0..<qt {
                let a = x0 + Double(i) * step, b = a + step
                let arc = (0...8).map { j -> CGPoint in let t = Double(j) / 8; return P(a + (b - a) * t, top - 34 - sin(.pi * t) * 12) }
                s.line("h\(i)", arc, .chapter, width: 1.5)
            }
            s.text("count", "\(qt) hops", at: P(x1, top - 62), size: 16, .chapter, anchor: UnitPoint(x: 1, y: 0.5))
        }
        let line = hops ? "\(d * qt) ÷ \(d) = \(qt), and \(f(Double(d * qt) / 10)) ÷ \(f(Double(d) / 10)) = \(qt)"
            : all ? "\(f(Double(d * qt) / 10)) × 10 = \(d * qt)" : one ? "\(f(Double(d) / 10)) × 10 = \(d)" : ""
        s.text("line", line, at: P(0, 230), size: 20, .ink, anchor: UnitPoint(x: 0, y: 0.5))
    }

    // MARK: fractions

    /// A bar one whole long, cut into `parts`, the first `shaded` filled (solid, or striped for a second amount).
    static func bar(_ s: inout Sketch, _ id: String, x: Double, y: Double, w: Double, h: Double, parts: Int, shaded: Int, from: Int = 0,
                    striped: Bool = false, lit: Bool = false, struck: Range<Int>? = nil) {
        let pw = w / Double(max(1, parts))
        for i in 0..<max(1, parts) {
            let r = R(x + Double(i) * pw, y, pw, h)
            if i >= from && i < from + shaded {
                s.fill("\(id)f\(i)", r, lit ? mid : soft)
                if striped {
                    var t = -h
                    while t < pw { s.line("\(id)s\(i)\(Int(t))", [P(r.minX + max(0, t), r.minY + max(0, -t)), P(r.minX + min(pw, t + h), r.minY + min(h, pw - t))], .tint(0.6), width: 1.5); t += 9 }
                }
            }
            if let st = struck, st.contains(i) { s.line("\(id)x\(i)", [P(r.minX + 4, r.maxY - 4), P(r.maxX - 4, r.minY + 4)], .ink2, width: 2) }
            s.box("\(id)b\(i)", r, lit ? .chapter : .tint(0.6), width: 2)
        }
    }

    /// 1/2 + 1/3: on the left the sum written as school writes it, each fraction rewritten over the common bottom with
    /// its × beside it; on the right the bars, cut into the same size pieces, then put together (or taken away).
    static func unlike(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 1), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 1), minus = n["minus"] == 1
        let L = Int(n["L"] ?? 1), A = Int(n["A"] ?? 0), C = Int(n["C"] ?? 0), S = Int(n["S"] ?? 0)
        let cut = p["cut"] == 1, first = p["first"] == 1, second = p["second"] == 1, combine = p["combine"] == 1, focus = p["focus"]
        // school: a/b = A/L over c/d = C/L, a line, S/L
        s.fraction("f1", "\(a)", "\(b)", at: P(40, 40))
        if first { s.text("e1", "=", at: P(78, 40), size: 24); s.fraction("g1", "\(A)", "\(L)", at: P(116, 40), .chapter); s.text("k1", "× \(L / b)", at: P(150, 40), size: 15, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        s.text("op", minus ? "−" : "+", at: P(10, 112), size: 24)
        s.fraction("f2", "\(c)", "\(d)", at: P(40, 112))
        if second { s.text("e2", "=", at: P(78, 112), size: 24); s.fraction("g2", "\(C)", "\(L)", at: P(116, 112), .chapter); s.text("k2", "× \(L / d)", at: P(150, 112), size: 15, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
        if combine {
            s.line("r", [P(0, 150), P(200, 150)], .ink, width: 2)
            s.fraction("ans", "\(S)", "\(L)", at: P(116, 190), .chapter)
            if p["answer"] == 1 {
                let g = gcd(S, L), whole = S / L, rem = S % L
                let simple = whole >= 1 ? (rem == 0 ? "\(whole)" : "\(whole) \(rem / gcd(rem, L))/\(L / gcd(rem, L))") : "\(S / g)/\(L / g)"
                s.text("simp", "= \(simple)", at: P(150, 190), size: 22, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        // the bars
        let x0 = 330.0, w = 340.0, h = 40.0
        bar(&s, "b1\(cut)", x: x0, y: 20, w: w, h: h, parts: cut ? L : b, shaded: cut ? A : a, lit: focus == 1 || focus == 3)
        s.text("l1", first ? "\(A)/\(L)" : "\(a)/\(b)", at: P(x0 + w + 4, 40), size: 16, .ink2, anchor: UnitPoint(x: 0, y: 0.5))
        bar(&s, "b2\(cut)", x: x0, y: 92, w: w, h: h, parts: cut ? L : d, shaded: cut ? C : c, striped: true, lit: focus == 2 || focus == 3)
        s.text("l2", second ? "\(C)/\(L)" : "\(c)/\(d)", at: P(x0 + w + 4, 112), size: 16, .ink2, anchor: UnitPoint(x: 0, y: 0.5))
        if combine {
            if minus {
                bar(&s, "b3", x: x0, y: 170, w: w, h: h, parts: L, shaded: S, lit: focus == 4, struck: S..<min(L, S + C))
            } else {
                let bars = max(1, Int((Double(S) / Double(L)).rounded(.up)))
                for j in 0..<bars {
                    let y = 170 + Double(j) * (h + 8), base = j * L
                    bar(&s, "b3\(j)", x: x0, y: y, w: w, h: h, parts: L, shaded: max(0, min(L, A - base)), lit: focus == 4)
                    let cStart = max(0, A - base), cCount = max(0, min(L - cStart, S - base - cStart))
                    if cCount > 0 { bar(&s, "b3c\(j)", x: x0, y: y, w: w, h: h, parts: L, shaded: cCount, from: cStart, striped: true, lit: focus == 4) }
                }
            }
        }
    }

    /// 2/3 × 3/4: on the left top times top over bottom times bottom; on the right a square cut into 3 rows and 4
    /// columns, 2 rows and 3 columns shaded, their overlap the answer.
    static func multiplyFractions(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 1), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 1)
        let at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        s.fraction("f1", "\(a)", "\(b)", at: P(24, 50)); s.text("x", "×", at: P(56, 50), size: 24); s.fraction("f2", "\(c)", "\(d)", at: P(88, 50))
        if at >= 3 || ask == 3 {
            s.text("e", "=", at: P(124, 50), size: 24)
            s.fraction("m", "\(a) × \(c)", "\(b) × \(d)", at: P(178, 50), size: 18, .chapter)
        }
        if at >= 3 { s.text("e2", "=", at: P(124, 130), size: 24); s.fraction("r", "\(a * c)", "\(b * d)", at: P(160, 130), .chapter) }
        if at >= 4 {
            let g = gcd(a * c, b * d)
            s.text("simp", g > 1 ? "= \(a * c / g)/\(b * d / g)" : "already simplest", at: P(190, 130), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // the grid: b rows, d columns
        let cell = min(64.0, 280 / Double(d), 230 / Double(b)), x0 = 420.0, y0 = 30.0
        for r in 0..<b { for col in 0..<d {
            let rect = R(x0 + Double(col) * cell + 3, y0 + Double(r) * cell + 3, cell - 6, cell - 6)
            let inRow = r < a, inCol = col < c
            if inRow && inCol { s.fill("o\(r)\(col)", rect, ask == 3 || at >= 3 ? .tint(0.75) : .tint(0.6)) }
            else if inRow { s.fill("r\(r)\(col)", rect, ask == 1 ? mid : soft) }
            else if inCol { s.fill("c\(r)\(col)", rect, ask == 2 ? mid : .tint(0.15)) }
            s.box("g\(r)\(col)", rect, .tint(0.5), width: 1.5)
            if at >= 3, inRow && inCol { s.text("n\(r)\(col)", "\(r * c + col + 1)", at: P(rect.midX, rect.midY), size: 14, .paper) }
        } }
        s.text("rl", "\(a)/\(b)", at: P(x0 - 26, y0 + Double(a) * cell / 2), size: 17, ask == 1 ? .chapter : .ink2)
        s.text("cl", "\(c)/\(d)", at: P(x0 + Double(c) * cell / 2, y0 - 16), size: 17, ask == 2 ? .chapter : .ink2)
    }

    /// 2 3/4: on the left the mixed number rewritten, wholes times pieces plus the extra; on the right a bar per whole
    /// and one for the extra pieces, every piece counted on.
    static func improper(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let w = Int(n["w"] ?? 1), nn = Int(n["n"] ?? 1), d = Int(n["d"] ?? 2)
        let wholes = Int(p["wholes"] ?? 0), extra = p["extra"] == 1, fraction = p["fraction"] == 1, focus = p["focus"]
        s.text("w", "\(w)", at: P(18, 50), size: 30); s.fraction("f", "\(nn)", "\(d)", at: P(46, 50))
        if wholes >= w { s.text("l1", "\(w) × \(d) = \(w * d)", at: P(0, 120), size: 22, anchor: UnitPoint(x: 0, y: 0.5)) }
        if extra { s.text("l2", "\(w * d) + \(nn) = \(w * d + nn)", at: P(0, 160), size: 22, anchor: UnitPoint(x: 0, y: 0.5)) }
        if fraction { s.text("e", "=", at: P(78, 50), size: 26); s.fraction("r", "\(w * d + nn)", "\(d)", at: P(114, 50), size: 26, .chapter) }
        let x0 = 340.0, bw = 320.0, h = min(36.0, 230 / Double(w + 1) - 6)
        for j in 0...w {
            let y = 10 + Double(j) * (h + 6), isExtra = j == w
            let filled = isExtra ? (extra ? nn : 0) : (j < wholes ? d : 0)
            bar(&s, "b\(j)", x: x0, y: y, w: bw, h: h, parts: d, shaded: filled, striped: isExtra, lit: (focus == 1 && !isExtra) || (focus == 2 && isExtra) || focus == 3)
            s.text("bl\(j)", isExtra ? "\(nn)/\(d)" : "1", at: P(x0 - 16, y + h / 2), size: 15, .ink2)
            if filled > 0 { s.text("cnt\(j)", "\(j * d + filled)", at: P(x0 + bw + 26, y + h / 2), size: 17, (isExtra || j == w - 1) ? .chapter : .ink2) }
        }
    }

    /// 3/4 of 20: the bar of 20 cut into 4 equal groups of 5, 3 of them taken; under it, 20 ÷ 4 = 5 and 5 × 3 = 15.
    static func fractionOf(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let nn = Int(n["n"] ?? 1), d = Int(n["d"] ?? 2), W = Int(n["W"] ?? 0), g = W / max(1, d)
        let at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        let x0 = 20.0, w = 680.0, y = 50.0, h = 50.0
        s.text("W", "\(W)", at: P(x0 + w / 2, y - 22), size: 20, .ink2)
        if at >= 1 || ask == 1 {
            bar(&s, "g", x: x0, y: y, w: w, h: h, parts: d, shaded: at >= 2 ? nn : 0, lit: ask == 2 || at >= 2)
            if at >= 1 { for i in 0..<d { s.text("gl\(i)", "\(g)", at: P(x0 + (Double(i) + 0.5) * w / Double(d), y + h / 2), size: 17) } }
        } else {
            s.fill("whole", R(x0, y, w, h), soft); s.box("wo", R(x0, y, w, h), .tint(0.6), width: 2)
        }
        if at >= 2 { bracket(&s, "br", x0: x0, x1: x0 + Double(nn) * w / Double(d), y: y + h + 18, "\(nn)/\(d)") }
        if at >= 1 { s.text("l1", "\(W) ÷ \(d) = \(g)", at: P(0, 190), size: 22, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at >= 2 { s.text("l2", "\(g) × \(nn) = \(g * nn)", at: P(0, 232), size: 22, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
    }

    /// 3 ÷ 1/4: a bar per whole, each cut into fourths and counted on; under them, 1 = 4 × 1/4 and 3 × 4 = 12.
    static func unitDivide(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let W = Int(n["W"] ?? 1), d = Int(n["d"] ?? 2), at = Int(p["at"] ?? 0), ask = p["ask"].map(Int.init)
        let x0 = 60.0, w = 420.0, h = min(30.0, 200 / Double(W) - 6)
        for j in 0..<W {
            let y = 6 + Double(j) * (h + 6), beat = min(j + 1, 3), isCut = at >= beat
            bar(&s, "b\(j)\(isCut)", x: x0, y: y, w: w, h: h, parts: isCut ? d : 1, shaded: isCut ? d : 1, lit: ask == beat)
            s.text("one\(j)", "1", at: P(x0 - 16, y + h / 2), size: 15, .ink2)
            if isCut { s.text("c\(j)", "\((j + 1) * d)", at: P(x0 + w + 24, y + h / 2), size: 17, j == W - 1 ? .chapter : .ink2) }
        }
        if at >= 1 { s.text("l1", "1 = \(d) × 1/\(d)", at: P(x0 + w + 70, 30), size: 20, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at >= min(W, 3) { s.text("l2", "\(W) × \(d) = \(W * d)", at: P(x0 + w + 70, 70), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
    }

    // MARK: measurement

    /// A box 4 × 3 × 2 drawn as school draws it, its layers of cubes filling in; beside it the volume worked out.
    static func volume(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let l = Int(n["length"] ?? 1), w = Int(n["width"] ?? 1), h = Int(n["height"] ?? 1)
        let floor = p["floor"] == 1, layers = Int(p["layers"] ?? 0), height = p["height"] == 1
        // an oblique box: the front face l × h, the depth w going up and right at half size
        let u = min(56.0, 300 / (Double(l) + Double(w) * 0.6), 210 / (Double(h) + Double(w) * 0.5))
        let dx = u * 0.6, dy = u * 0.5, x0 = 380.0, base = 30 + Double(w) * dy + Double(h) * u
        func pt(_ x: Double, _ y: Double, _ z: Double) -> CGPoint { P(x0 + x * u + z * dx, base - y * u - z * dy) }
        // cubes, layer by layer: each layer's front, top and side
        let shownLayers = layers > 0 ? layers : (floor ? 0 : 0)
        if floor && layers == 0 {
            for i in 0..<l { for k in 0..<w { s.polygon("fl\(i)\(k)", [pt(Double(i), 0, Double(k)), pt(Double(i + 1), 0, Double(k)), pt(Double(i + 1), 0, Double(k + 1)), pt(Double(i), 0, Double(k + 1))], soft) } }
            for i in 0...l { s.line("fx\(i)", [pt(Double(i), 0, 0), pt(Double(i), 0, Double(w))], .tint(0.6), width: 1.5) }
            for k in 0...w { s.line("fz\(k)", [pt(0, 0, Double(k)), pt(Double(l), 0, Double(k))], .tint(0.6), width: 1.5) }
        }
        if shownLayers > 0 {
            let top = Double(shownLayers)
            s.polygon("front", [pt(0, 0, 0), pt(Double(l), 0, 0), pt(Double(l), top, 0), pt(0, top, 0)], .tint(0.35))
            s.polygon("side", [pt(Double(l), 0, 0), pt(Double(l), 0, Double(w)), pt(Double(l), top, Double(w)), pt(Double(l), top, 0)], .tint(0.5))
            s.polygon("topf", [pt(0, top, 0), pt(Double(l), top, 0), pt(Double(l), top, Double(w)), pt(0, top, Double(w))], .tint(0.25))
            for i in 0...l { s.line("cx\(i)", [pt(Double(i), 0, 0), pt(Double(i), top, 0), pt(Double(i), top, Double(w))], .tint(0.7), width: 1.5) }
            for j in 0...shownLayers { s.line("cy\(j)", [pt(0, Double(j), 0), pt(Double(l), Double(j), 0), pt(Double(l), Double(j), Double(w))], .tint(0.7), width: 1.5) }
            for k in 0...w { s.line("cz\(k)", [pt(0, top, Double(k)), pt(Double(l), top, Double(k)), pt(Double(l), 0, Double(k))], .tint(0.7), width: 1.5) }
        }
        // the box's outline
        let H = Double(h), Lx = Double(l), Wz = Double(w)
        s.line("ob", [pt(0, 0, 0), pt(Lx, 0, 0), pt(Lx, 0, Wz)], .chapter, width: 2)
        s.line("ot", [pt(0, H, 0), pt(Lx, H, 0), pt(Lx, H, Wz), pt(0, H, Wz), pt(0, H, 0)], .chapter, width: 2)
        s.line("ov", [pt(0, 0, 0), pt(0, H, 0)], .chapter, width: 2)
        s.line("ov2", [pt(Lx, 0, 0), pt(Lx, H, 0)], .chapter, width: 2)
        s.line("ov3", [pt(Lx, 0, Wz), pt(Lx, H, Wz)], .chapter, width: 2)
        s.line("hid", [pt(0, 0, 0), pt(0, 0, Wz), pt(Lx, 0, Wz)], .tint(0.5), width: 1.5, dashed: true)
        s.line("hid2", [pt(0, 0, Wz), pt(0, H, Wz)], .tint(0.5), width: 1.5, dashed: true)
        let lp = pt(Lx / 2, 0, 0), wp = pt(Lx, 0, Wz / 2), hp = pt(0, H / 2, 0)
        s.text("ll", "\(l) cm", at: P(lp.x, lp.y + 20), size: 17, floor ? .chapter : .ink2)
        s.text("wl", "\(w) cm", at: P(wp.x + 34, wp.y + 8), size: 17, floor ? .chapter : .ink2)
        s.text("hl", "\(h) cm", at: P(hp.x - 32, hp.y), size: 17, height ? .chapter : .ink2)
        // the working
        s.text("v", "Volume = l × w × h", at: P(0, 40), size: 20, .ink, anchor: UnitPoint(x: 0, y: 0.5))
        if floor || layers > 0 { s.text("b", "\(l) × \(w) = \(l * w) in a layer", at: P(0, 90), size: 20, anchor: UnitPoint(x: 0, y: 0.5)) }
        if height { s.text("t", "\(l * w) × \(h) = \(l * w * h) cm³", at: P(0, 132), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5)) }
    }

    /// 3 feet = ? inches: a bar of big units, the first opened up into small ones, then all of them; the working
    /// under it.
    static func units(_ s: inout Sketch, _ n: Numbers, _ p: Numbers) {
        let pair = ConvertUnits.units[min(ConvertUnits.units.count - 1, Int(n["u"] ?? 0))]
        let count = p["units"] ?? 1, per = p["per"] ?? pair.per, rows = Int(p["rows"] ?? 1), fill = Int(p["fill"] ?? 0)
        let one = p["one"] == 1, ask = p["ask"] == 1, total = p["total"] == 1, up = n["up"] == 1, amount = n["n"] ?? 0
        let cellsN = Int(count.rounded(.up)), perRow = rows == 2 ? Int((Double(cellsN) / 2).rounded(.up)) : cellsN
        let x0 = 20.0, w = 680.0, cw = min(110.0, w / Double(max(1, perRow))), h = 48.0
        s.text("amt", up ? "\(f(amount)) \(pair.small)" : "\(f(amount)) \(amount == 1 ? pair.one : pair.many)", at: P(x0 + Double(perRow) * cw / 2, 14), size: 18, .ink2)
        for i in 0..<cellsN {
            let row = i / perRow, col = i % perRow
            let r = R(x0 + Double(col) * cw, 34 + Double(row) * (h + 10), cw, h)
            let part = i == cellsN - 1 && count < Double(cellsN) ? count - Double(cellsN - 1) : 1
            let opened = i < fill
            s.fill("u\(i)\(opened)", R(r.minX, r.minY, r.width * part, r.height), opened ? mid : soft)
            s.box("ub\(i)", r, .tint(0.6), width: 2)
            let label = opened ? f(per * part) : (ask && i > 0 ? "?" : (part < 1 ? "½" : "1"))
            s.text("ul\(i)", label, at: P(r.midX, r.midY), size: 18, opened ? .ink : .ink2)
        }
        let below = 34 + Double(rows) * (h + 10) + 26
        if one { s.text("one", "1 \(pair.one) = \(f(per)) \(pair.small)", at: P(x0, below), size: 20, anchor: UnitPoint(x: 0, y: 0.5)) }
        if total {
            let ans = up ? amount / per : amount * per
            s.text("tot", up ? "\(f(amount)) ÷ \(f(per)) = \(f(ans)) \(pair.many)" : "\(f(amount)) × \(f(per)) = \(f(ans)) \(pair.small)",
                   at: P(x0, below + 40), size: 20, .chapter, anchor: UnitPoint(x: 0, y: 0.5))
        }
    }
}
