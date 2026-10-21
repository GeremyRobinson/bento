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

    // MARK: fractions

    static func frac(_ a: Int, _ b: Int) -> Math { .frac(.num(Double(a)), .num(Double(b))) }

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
