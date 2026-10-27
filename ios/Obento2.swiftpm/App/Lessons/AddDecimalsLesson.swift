import SwiftUI

/// Adding decimals on the paper (design/grade5.md). The record leads, because lining up is the lesson: a over b in
/// columns, two squares to a digit, their points on one strong line, dashed down through them to the total's row under
/// the rule; a row over them for what's carried. The part after each point is drawn beside the record as a 10 × 10 grid
/// of hundredths (a cell is 2 × 2 squares and one hundredth, a column a tenth, the grid one whole), its name over it:
/// a's shaded, b's striped. Tap each empty place after a point: a 0 is written there in the chapter's colour (a whole
/// number's point with it), and the grid's name says it too (0.5, then 0.50: the same cells). Slide b's hundredths into
/// a's grid: held over it they snap in after its shaded cells and the count is written over it ("50 + 75 = 125
/// hundredths"); let go, they pour in a column at a time, and past a full grid into the next. Tap the full grid: its 1
/// slides along to the ones column as the carried 1, and what's left slides up beside the record. Then the total, typed
/// under the line, lined up on the point; done, the carries school writes and the total in the chapter's colour, and the
/// last words say why.
@MainActor
struct AddDecimalsLesson: PaperLesson {
    /// The record, in the picture's squares: the points' line (a strong line) and two squares to a digit; the rows of
    /// what's carried, a, b, the rule and the total.
    nonisolated static let point = 10.0, per = 2.0
    nonisolated static let carryRow = 2.0, aRow = 4.0, bRow = 6.0, rule = 8.0, totalRow = 10.0
    /// The grids: a cell is 2 × 2 squares, a grid 20 squares a side, its top level with a's row; the first a block past
    /// the record, the second a block past the first.
    nonisolated static let cell = 2.0, side = 20.0, top = 3.0, first = 20.0, second = 45.0

    var liveKeys: Set<String> { ["dx", "dy", "in"] }

    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    /// The cells' lines: finer than the outline, and darker than a's shaded cells, so every hundredth can be counted.
    private static let lines = Sketch.Colour.tint(0.65)

    /// The stage: 0 the question, 1 write the 0s, 2 slide the hundredths, 3 carry the full grid, 4 write the total, 5 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The middle of a place's column (2 the hundreds … −2 the hundredths), and a row's middle.
    nonisolated static func mid(_ place: Int) -> Double { point - per * Double(place) - per / 2 }
    nonisolated static func row(_ r: Int) -> Double { r == 0 ? aRow : bRow }
    /// The hand's key for a 0 written in an empty place.
    static func key(_ g: AddDecimals.Gap) -> String { "z\(g.row)\(g.place + 2)" }
    /// The place a tap on the record is in: its row (0 a, 1 b) and place (2 the hundreds … −2 the hundredths).
    static func place(at q: CGPoint) -> (row: Int, place: Int)? {
        guard q.x >= point - 3 * per, q.x < point + 2 * per, q.y >= aRow - 1.5, q.y < bRow + 1.5 else { return nil }
        let k = Int(((q.x - point) / per).rounded(.down))
        return (q.y < (aRow + bRow) / 2 ? 0 : 1, k >= 0 ? -(k + 1) : -k - 1)
    }
    /// On a grid (a finger's width round it).
    static func on(_ q: CGPoint, grid x: Double) -> Bool { q.x > x - 0.5 && q.x < x + side + 0.5 && q.y > top - 0.5 && q.y < top + side + 0.5 }

    /// The 0s written so far: as they're tapped, then all of them.
    private func written(_ s: PaperState, _ P: AddDecimals.Parts) -> Set<AddDecimals.Gap> {
        Set(stage(s) >= 2 ? P.gaps : P.gaps.filter { s.h(Self.key($0)) == 1 })
    }
    /// A grid's name before the slide: the part after its number's point, to the places the record shows it (0.5, then
    /// 0.50 once its 0 is written).
    private func name(_ row: Int, _ s: PaperState, _ P: AddDecimals.Parts) -> String {
        let mine = P.gaps.filter { $0.row == row }, done = mine.allSatisfy { written(s, P).contains($0) }
        return AddDecimals.Parts.part(row == 0 ? P.da : P.db, done ? 2 : P.decimals(row))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = AddDecimals.Parts(s.numbers), at = stage(s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let A = Self.first, B = Self.second, top = Self.top, side = Self.side

        // MARK: the record: a over b in columns, the points on one line, the rule, the total's row
        let zeros = written(s, P)
        for r in 0...1 {
            let y = Self.row(r), dec = P.decimals(r), mine = P.gaps.filter { $0.row == r && zeros.contains($0) }
            rec.digits("n\(r)", P.written(r), right: Self.point + Self.per * Double(dec), row: y, per: Self.per)
            // a whole number's point is written with its first 0, in the colour of what's written in
            if dec == 0, !mine.isEmpty {
                rec.sketch.text("n\(r)pt", ".", at: rec.P(Self.point, y), size: Sketch.maths, weight: .bold, .chapter, anchor: UnitPoint(x: 0.5, y: 0.49))
            }
            for g in mine { rec.word("z\(r)\(g.place)", "0", at: Self.mid(g.place), y, Self.maths.colour(.chapter)) }
        }
        // the sign in the hundreds' column, by b as school writes it (no number here has hundreds; a total that does
        // writes its 1 under it, under the rule); a story's sign stays hidden until it's picked
        if !s.picking { rec.word("plus", "+", at: Self.mid(2), Self.bRow, Self.maths) }
        rec.rule("rule", from: Self.point - 3 * Self.per, to: Self.point + 2 * Self.per, row: Self.rule)
        // the points' line, through both points and the total's
        rec.line("pointLine", [(Self.point, Self.aRow - 1), (Self.point, Self.totalRow + 1)], .chapter, dashed: true)
        // a hint: each empty place still to fill, ringed
        if at == 1, s.on("gaps") {
            for g in P.gaps where !zeros.contains(g) { rec.circle("gap\(g.row)\(g.place)", at: Self.mid(g.place), Self.row(g.row), radius: 1.15, .chapter, dashed: true) }
        }
        // a tap that wasn't on an empty place after a point: where it landed, ringed in pencil (what's there is said
        // under the instruction)
        if at == 1, let t = s.h("tapped") {
            let code = Int(t.rounded()) - 100, place = code % 10 - 2
            rec.circle("tapped", at: Self.mid(place), Self.row(code / 10), radius: 1.15, .ink3)
        }
        // what's carried, over its column: the full grid's 1 (its name's id, so it slides there from over the grid) from
        // the carry on; done, the tens and hundreds school carries too
        if P.carries && at >= 4 { rec.label("g1n", "1", Self.label.colour(.chapter), .above, edge: top, along: Self.mid(0)) }
        if at >= 5 {
            if P.ones >= 10 { rec.label("c1", "1", Self.label.colour(.chapter), .above, edge: top, along: Self.mid(1)) }
            if P.tens >= 10 { rec.label("c2", "1", Self.label.colour(.chapter), .above, edge: top, along: Self.mid(2)) }
        }
        var boxes: [WorkBox] = []
        let T = AddDecimals.two(P.sum)
        if at == 4 {
            // the total, typed under the line, lined up on the point
            rec.answerBox("x", right: Self.point + 2 * Self.per, mid: Self.totalRow, per: Self.per, cells: T.filter { $0 != "." }.count, point: Self.point)
            boxes = rec.boxes
            // a hint: the carried 1, ringed
            if s.on("read"), P.carries { rec.circle("readCarry", at: Self.mid(0), Self.carryRow, radius: 1.1, .chapter, dashed: true) }
        } else if at >= 5 {
            rec.digits("t", T, right: Self.point + 2 * Self.per, row: Self.totalRow, per: Self.per, .chapter)
        }

        // MARK: the grids: the part after each point, in hundredths
        switch at {
        case 0...2:
            let held = at == 2 && s.grabbed
            grid(&pic, "g1", x: A, shaded: P.na, striped: 0..<0)
            // b's hundredths are in the hand while it's held: its grid is left empty
            grid(&pic, "g2", x: B, shaded: 0, striped: held ? 0..<0 : 0..<P.nb)
            if held {
                if s.h("in") == 1 {
                    // over the first grid: they snap in after its shaded cells, past a full grid into the next, and the
                    // count is written over it
                    let fill = min(100, P.n)
                    cells(&live, "intoA", x: A, y: top, P.na..<fill)
                    live.sketch.box("intoAo", live.R(A, top, side, side), .chapter, width: Sketch.stroke)
                    if P.n > 100 {
                        cells(&live, "intoB", x: B, y: top, 0..<(P.n - 100))
                        live.sketch.box("intoBo", live.R(B, top, side, side), .chapter, width: Sketch.stroke)
                    }
                    live.label("count", P.pour, Self.label.colour(.chapter), .above, edge: top, along: A + side / 2)
                    live.reads(P.pour)
                } else {
                    // following the finger, a square at a time, its name with it
                    let gx = B + (s.h("dx") ?? 0), gy = top + (s.h("dy") ?? 0)
                    cells(&live, "held", x: gx, y: gy, 0..<P.nb)
                    live.line("heldo", Self.outline(P.nb).map { (gx + $0.0, gy + $0.1) }, .chapter)
                    live.label("heldName", name(1, s, P), Self.label, .above, edge: gy, along: gx + side / 2)
                    live.reads(name(1, s, P))
                    live.label("aName", name(0, s, P), Self.label, .above, edge: top, along: A + side / 2)
                }
            } else {
                pic.label("g1n", name(0, s, P), Self.label, .above, edge: top, along: A + side / 2)
                pic.label("g2n", name(1, s, P), Self.label, .above, edge: top, along: B + side / 2)
                // a hint: where the hundredths go, dashed in the first grid
                if at == 2, s.on("target") {
                    let k = min(100, P.n) - P.na, x0 = A + Self.cell * Double(P.ta)
                    pic.line("target", Self.outline(k, inset: 0.5).map { (x0 + $0.0, top + $0.1) }, .chapter, dashed: true)
                }
            }
        case 3:
            // the first grid full, its name 1: one whole; what was left over in the next
            grid(&pic, "g1", x: A, shaded: P.na, striped: P.na..<100)
            pic.label("g1n", "1", Self.label.colour(.chapter), .above, edge: top, along: A + side / 2)
            if P.left > 0 {
                grid(&pic, "g2", x: B, shaded: 0, striped: 0..<P.left)
                pic.label("g2n", AddDecimals.two(Double(P.left) / 100), Self.label, .above, edge: top, along: B + side / 2)
                // the grid tapped that isn't full: outlined red (red means wrong)
                if s.h("wrong") == 1 { pic.sketch.box("g2wrong", pic.R(B, top, side, side), Bars.red, width: Sketch.stroke) }
            }
            // a hint: the full grid, outlined
            if s.on("full") { pic.sketch.box("full", pic.R(A + 0.5, top + 0.5, side - 1, side - 1), .chapter, width: Sketch.stroke, dashed: true) }
        default:
            // what's after the point: the hundredths left once the whole is carried (slid up beside the record), or all
            // of them in the first grid
            if P.carries {
                if P.left > 0 {
                    grid(&pic, "g2", x: A, shaded: 0, striped: 0..<P.left)
                    pic.label("g2n", AddDecimals.two(Double(P.left) / 100), Self.label, .above, edge: top, along: A + side / 2)
                }
            } else {
                grid(&pic, "g1", x: A, shaded: P.na, striped: P.na..<P.n)
                pic.label("g1n", AddDecimals.two(P.D), Self.label, .above, edge: top, along: A + side / 2)
            }
            // a hint on the total: the grid with what's after the point, outlined
            if at == 4, s.on("read"), !(P.carries && P.left == 0) {
                pic.sketch.box("read", pic.R(A + 0.5, top + 0.5, side - 1, side - 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    /// A grid of hundredths at column x: `shaded` cells solid (a's), then the `striped` ones (b's), filled a column at a
    /// time from the top, each column its own part so they pour in one after another; its cells' lines over them, finer
    /// than its outline.
    private func grid(_ pen: inout GridPen, _ id: String, x: Double, shaded: Int, striped: Range<Int>) {
        let y = Self.top, c = Self.cell, side = Self.side
        for k in Self.chunks(0..<shaded) {
            pen.fill("\(id)s\(k.c)_\(k.r0)_\(k.r1)", col: x + Double(k.c) * c, row: y + Double(k.r0) * c, w: c, h: Double(k.r1 - k.r0) * c, Bars.shade)
        }
        for k in Self.chunks(striped) {
            pen.stripes("\(id)p\(k.c)_\(k.r0)_\(k.r1)", col: x + Double(k.c) * c, row: y + Double(k.r0) * c, w: c, h: Double(k.r1 - k.r0) * c)
        }
        let inner = (1..<10).flatMap { i -> [(CGPoint, CGPoint)] in
            let d = Double(i) * c
            return [(pen.P(x + d, y), pen.P(x + d, y + side)), (pen.P(x, y + d), pen.P(x + side, y + d))]
        }
        pen.sketch.segments("\(id)l", inner, Self.lines, width: 1)
        pen.sketch.box("\(id)o", pen.R(x, y, side, side), .chapter, width: Sketch.stroke)
    }

    /// Some hundredths of a grid at (x, y), striped, with their own cells' lines (live parts, drawn over the still grid).
    private func cells(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ range: Range<Int>) {
        let c = Self.cell
        for k in Self.chunks(range) {
            pen.stripes("\(id)p\(k.c)", col: x + Double(k.c) * c, row: y + Double(k.r0) * c, w: c, h: Double(k.r1 - k.r0) * c)
        }
        var segs: [(CGPoint, CGPoint)] = []
        for i in range {
            let cx = x + Double(i / 10) * c, cy = y + Double(i % 10) * c
            segs += [(pen.P(cx, cy), pen.P(cx + c, cy)), (pen.P(cx, cy), pen.P(cx, cy + c)),
                     (pen.P(cx + c, cy), pen.P(cx + c, cy + c)), (pen.P(cx, cy + c), pen.P(cx + c, cy + c))]
        }
        pen.sketch.segments("\(id)l", segs, Self.lines, width: 1)
    }

    /// The cells `range` of a grid, a column at a time: each column's part (its column and first and last rows).
    nonisolated static func chunks(_ range: Range<Int>) -> [(c: Int, r0: Int, r1: Int)] {
        guard !range.isEmpty else { return [] }
        return (range.lowerBound / 10 ... (range.upperBound - 1) / 10).map { c in
            (c, max(range.lowerBound, 10 * c) - 10 * c, min(range.upperBound, 10 * c + 10) - 10 * c)
        }
    }

    /// The outline of `k` hundredths filled from a column's top: its full columns, and the part of the next; `inset`
    /// squares inside it (a hint's dashed line, clear of the grid's own lines).
    nonisolated static func outline(_ k: Int, inset d: Double = 0) -> [(Double, Double)] {
        let full = Double(k / 10) * cell, part = Double(k % 10) * cell
        if k % 10 == 0 { return [(d, d), (full - d, d), (full - d, side - d), (d, side - d), (d, d)] }
        if k < 10 { return [(d, d), (cell - d, d), (cell - d, part - d), (d, part - d), (d, d)] }
        return [(d, d), (full + cell - d, d), (full + cell - d, part - d), (full - d, part - d), (full - d, side - d), (d, side - d), (d, d)]
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = AddDecimals.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // an empty place after a point: a 0 is written there, and the last one answers the step; anywhere else on the
            // record says what's there
            return Hands(tap: { q in
                guard let (row, place) = Self.place(at: q) else { return nil }
                guard let g = P.gaps.first(where: { $0.row == row && $0.place == place }) else {
                    let code = AddDecimals.tapCode(row, place)
                    return HandMove(hand: s.hand.merging(["tapped": code]) { $1 }, missHand: nil, set: [("x", code)], check: true)
                }
                guard s.h(Self.key(g)) != 1 else { return nil }
                var h = s.hand
                h[Self.key(g)] = 1
                h["tapped"] = nil
                let done = P.gaps.allSatisfy { h[Self.key($0)] == 1 }
                return HandMove(hand: h, missHand: nil, set: done ? [("x", Double(P.gaps.count))] : [], check: done)
            })
        case 2:
            // b's hundredths, held anywhere on their grid: they follow the finger a square at a time, and over the first
            // grid they snap in; let go there, they're poured (the box: the hundredths in all, as a decimal)
            let A = Self.first, B = Self.second, top = Self.top, side = Self.side, D = P.D
            return Hands(
                grab: { q in Self.on(q, grid: B) ? ["grab": 1, "fx": q.x, "fy": q.y, "dx": 0, "dy": 0, "in": 0] : nil },
                drag: { q, h in
                    let fx = h["fx"] ?? 0, fy = h["fy"] ?? 0, dx = (q.x - fx).rounded(), dy = (q.y - fy).rounded()
                    // over the first grid when their grid's middle is
                    let cx = B + side / 2 + dx, cy = top + side / 2 + dy
                    let into = cx > A - 2 && cx < A + side + 2 && cy > top - 4 && cy < top + side + 4
                    return ["grab": 1, "fx": fx, "fy": fy, "dx": dx, "dy": dy, "in": into ? 1 : 0]
                },
                release: { h in
                    h["in"] == 1 ? HandMove(hand: ["in": 1], missHand: [:], set: [("x", D)], check: true)
                        : HandMove(hand: [:], missHand: [:], set: [("x", 0)], check: true)
                })
        case 3:
            // the full grid: its 1 is carried; the grid that isn't full is a miss, outlined red
            return Hands(tap: { q in
                if Self.on(q, grid: Self.first) { return HandMove(hand: nil, missHand: nil, set: [("x", 1)], check: true) }
                if P.left > 0, Self.on(q, grid: Self.second) { return HandMove(hand: nil, missHand: ["wrong": 1], set: [("x", 0)], check: true) }
                return nil
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = AddDecimals.Parts(s.numbers), middle = Self.top + Self.side / 2
        switch stage(s) {
        case 1: return P.gaps.filter { s.h(Self.key($0)) != 1 }.map { .tap(.picture(CGPoint(x: Self.mid($0.place), y: Self.row($0.row)))) }
        case 2: return [.drag(from: CGPoint(x: Self.second + Self.side / 2, y: middle), to: CGPoint(x: Self.first + Self.side / 2, y: middle))]
        case 3: return [.tap(.picture(CGPoint(x: Self.first + Self.side / 2, y: middle)))]
        default: return []
        }
    }

    /// The record leads: it's written from the picture's top, beside the grids.
    func recordRow(_ n: Numbers) -> Double? { 0 }

    func messageRows(_ n: Numbers) -> Int {
        // what a miss or a hint says, at its longest, over the picture's width
        let P = AddDecimals.Parts(n), f = PaperText.font(Sketch.Words.note.size, Sketch.Words.note.weight)
        let steps = AddDecimals.spec.steps(n)
        let said = steps.flatMap { st in [st.words.hint] + (st.answer?.known.map(\.message) ?? []) }
            + [P.notFull, P.tapped(1, 2), "The digits are right. The point goes under the points.", "Not quite. Add each column, right to left."]
        return min(2, said.map { PaperText.wrap($0, f, width: (Self.second + Self.side) * Paper.cell).count }.max() ?? 1)
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = AddDecimals.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // a 0 in front of b (in its tens, under a's), else on a's ones digit
            let tap = P.digit(1, 1) == nil && P.digit(0, 1) != nil ? (1, 1) : (0, 0), code = AddDecimals.tapCode(tap.0, tap.1)
            return HandMove(hand: s.hand.merging(["tapped": code]) { $1 }, missHand: nil, set: [("x", code)], check: true)
        case 2:
            // let go off the first grid
            return HandMove(hand: [:], missHand: [:], set: [("x", 0)], check: true)
        case 3:
            // the grid that isn't full
            return P.left > 0 ? HandMove(hand: nil, missHand: ["wrong": 1], set: [("x", 0)], check: true) : nil
        default: return nil
        }
    }
}
