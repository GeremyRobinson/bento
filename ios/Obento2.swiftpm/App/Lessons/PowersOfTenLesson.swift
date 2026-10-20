import SwiftUI

/// Multiply by 10, 100, 1000 on the paper (design/grade5.md). A place chart, a table as school draws it: a column for
/// each place from the ten thousands to x's last decimal (the same chart for × 10, × 100 and × 1000, so how far to drag
/// is counted, not read off it), each place's name in its head, the point fixed on the strong line between the ones and
/// the tenths, x's digits in their cells (the problem's number, written once; the words say what it's multiplied by).
/// A place is two blocks (the smallest words' "ten thousands" and "hundredths" are wider than one), so the chart is 60
/// or 70 squares. Drag the digits left together: they snap a place at a time, and under the chart a hop for each place
/// counts from the point, the readout under the hops ("× 10", "× 100", "× 1000"); let go on k places ("That's × 1000.
/// × 100 moves every digit 2 places." when it isn't). Tap each gap the digits left between them and the point: a 0 is
/// written there. Then the record, x × 10^k = [ ], typed (a slip is said of the chart: "The 0 in the ones place is part
/// of the number."); done, the answer in the chapter's colour, the multiplier's zeros underlined and the rule under it
/// ("2 zeros: 2 places bigger"), and the last words say why.
@MainActor
struct PowersOfTenLesson: PaperLesson {
    /// The picture's rows, in its squares: the names' row in the chart's head, the head's foot, the digits' row and the
    /// chart's foot (the hops hang from it), and a place's width (two blocks).
    static let names = 1.5, top = 3.0, row = 5.0, bottom = 7.0, col = 10.0
    /// How deep a hop dips under the chart, and the readout's middle under the hops.
    static let dip = 1.5, readout = 9.5

    var liveKeys: Set<String> { ["d", "fx"] }

    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let label = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    /// The stage: 0 the question, 1 drag the digits, 2 write the 0s, 3 write the record, 4 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// Where a problem's places are: the chart's first place (P.hi) is its first column.
    @MainActor private struct Chart {
        let P: PowersOfTen.Parts
        func left(_ place: Int) -> Double { Double(P.hi - place) * col }
        func mid(_ place: Int) -> Double { left(place) + col / 2 }
        /// The point's line, between the ones and the tenths (on a block line, as every column's edge is).
        var point: Double { left(-1) }
        var width: Double { Double(P.columns.count) * col }
        /// The place a spot on the chart is in.
        func place(at x: Double) -> Int { P.hi - min(P.columns.count - 1, max(0, Int((x / col).rounded(.down)))) }
        /// On the chart (its head, its cells, a little round them): where a finger takes hold of the digits or taps.
        func on(_ q: CGPoint) -> Bool { q.x > -1 && q.x < width + 1 && q.y > -1 && q.y < bottom + 1 }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PowersOfTen.Parts(s.numbers), C = Chart(P: P), at = stage(s), held = at == 1 && s.grabbed
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        chart(&pic, C)
        if at <= 1 {
            // the digits where they are: in the hand, following it a place at a time, the hops and what they make
            // counted under the chart; else where the number has them
            if held {
                let d = Int((s.h("d") ?? 0).rounded())
                digits(&live, C, by: d, .chapter)
                if d > 0 { hops(&live, C, "live", d) }
            } else {
                digits(&pic, C, by: 0, .ink)
                // what the hand moves, ringed, as Rounding's point is (only while it waits to be dragged)
                if at == 1 {
                    for i in P.digits.indices { live.circle("handle\(i)", at: C.mid(P.place(i)), Self.row, radius: 1.4, .chapter, dashed: true) }
                }
            }
            // a hint (after a miss, or asked for): the hops the digits make, dashed, and what they make (the live
            // readout takes its place while they're held)
            if at == 1, s.on("target") { hops(&pic, C, "target", P.k, dashed: true, words: !held) }
        } else {
            // moved: the digits in their new places, the hops they made and what they made; the 0s written in the gaps
            digits(&pic, C, by: P.k, .ink)
            hops(&pic, C, "made", P.k)
            let written = at >= 3 ? P.gaps : P.gaps.filter { s.h("z\($0)") == 1 }
            for p in written { pic.word("zero\(p)", "0", at: C.mid(p), Self.row, Self.maths.colour(.chapter)) }
            // a hint: each gap ringed
            if at == 2, s.on("gaps") {
                for p in P.gaps where !written.contains(p) { pic.circle("gap\(p)", at: C.mid(p), Self.row, radius: 1.5, .chapter, dashed: true) }
            }
            // a hint on the record: the new number outlined on the chart, from its first digit to its last (or its 0s)
            if at == 3, s.on("read") {
                let x0 = C.left(P.lead + P.k), x1 = C.left(min(0, P.k - P.decimals)) + Self.col
                pic.sketch.box("read", pic.R(x0 + 0.5, Self.top + 0.5, x1 - x0 - 1, Self.bottom - Self.top - 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }

        var boxes: [WorkBox] = []
        if at >= 3 {
            // the record, as school writes it: x × 10^k = the answer, two squares to a digit, the point on a line
            let X = fmt(P.x), M = P.M, A = fmt(P.answer)
            let xr = 2 * Double(X.filter { $0 != "." }.count), mr = xr + 4 + 2 * Double(M.count), a0 = mr + 4, row = 1.0
            rec.digits("rx", X, right: xr, row: row, per: 2)
            rec.word("times", "×", at: xr + 2, row, Self.maths)
            rec.digits("rm", M, right: mr, row: row, per: 2)
            rec.word("equals", "=", at: mr + 2, row, Self.maths)
            if at == 3 {
                // a box as many cells as the answer has characters, what's typed written in its middle as one number
                rec.answerBox("x", right: a0 + 2 * Double(A.count), mid: row, per: 2, cells: A.count, centred: true)
            } else {
                rec.digits("ra", A, right: a0 + 2 * Double(A.filter { $0 != "." }.count), row: row, per: 2, .chapter)
                // the rule as the record has it: the multiplier's zeros underlined, what they do written under them
                rec.rule("zeros", from: mr - 2 * Double(P.k), to: mr, row: row + 1, .chapter)
                rec.word("rule", P.rule, at: 0, row + 3, Self.small, anchor: UnitPoint(x: 0, y: 0.5))
            }
            boxes = rec.boxes
        }
        // the room the drag will need: the hops and the readout under the chart
        let extent: CGRect? = at == 1 ? pic.R(0, 0, C.width, Self.readout + 1.5) : nil
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, extent: extent)
    }

    /// The chart: a head with each place's name, a cell under it for its digit, the point's line strong, the point on it.
    private func chart(_ pen: inout GridPen, _ C: Chart) {
        let P = C.P
        for p in P.columns { pen.word("name\(p)", PowersOfTen.placeName(p), at: C.mid(p), Self.names, Self.small) }
        pen.sketch.box("chart\(P.columns.count)", pen.R(0, 0, C.width, Self.bottom), .ink2, width: Sketch.stroke)
        let edges = P.columns.dropFirst().map { C.left($0) }.filter { abs($0 - C.point) > 0.01 }
        // its inner lines at the one line weight, lighter in colour than its outline and the point's line
        pen.sketch.segments("cells\(P.hi)\(P.lo)", edges.map { x in (pen.P(x, 0), pen.P(x, Self.bottom)) } + [(pen.P(0, Self.top), pen.P(C.width, Self.top))], .ink3, width: Sketch.stroke)
        // the point's line, the chart's height; the point on it, sitting on the digits' line as a written point does
        pen.line("pointLine", [(C.point, 0), (C.point, Self.bottom)], .ink)
        let base = Self.row + Double(PaperText.font(Sketch.maths, .medium, digits: true).capHeight) / 2 / Paper.cell
        pen.dot("point", at: C.point, base - 0.3, radius: 0.3, .chapter, over: true)
    }

    /// x's digits in their cells, moved `by` places.
    private func digits(_ pen: inout GridPen, _ C: Chart, by d: Int, _ colour: Sketch.Colour) {
        for (i, ch) in C.P.digits.enumerated() {
            pen.word("digit\(i)", String(ch), at: C.mid(C.P.place(i, by: d)), Self.row, Self.maths.colour(colour))
        }
    }

    /// A hop for each place the digits move, hanging under the chart from the point's line leftward (the ones digit's
    /// journey, a place at a time), and what the places make under them ("× 100").
    private func hops(_ pen: inout GridPen, _ C: Chart, _ id: String, _ d: Int, dashed: Bool = false, words: Bool = true) {
        for j in 0..<d {
            let from = C.point - Double(j) * Self.col, to = from - Self.col
            let pts = (0...24).map { i -> CGPoint in let t = Double(i) / 24; return pen.P(from + (to - from) * t, Self.bottom + sin(.pi * t) * Self.dip) }
            if dashed { pen.sketch.segments("\(id)hop\(j)", GridPen.dashes(pts), .chapter, width: Sketch.stroke) }
            else { pen.sketch.line("\(id)hop\(j)", pts, .chapter, width: Sketch.stroke) }
            // its head, at the left end: two short strokes back along the hop's last direction
            let tip = pts[pts.count - 1], back = pts[pts.count - 3]
            let dx = back.x - tip.x, dy = back.y - tip.y, len = max(0.01, hypot(dx, dy)), ux = dx / len, uy = dy / len, h = 0.6 * Paper.cell
            func side(_ a: Double) -> CGPoint { CGPoint(x: tip.x + h * (ux * cos(a) - uy * sin(a)), y: tip.y + h * (ux * sin(a) + uy * cos(a))) }
            pen.sketch.line("\(id)head\(j)", [side(0.5), tip, side(-0.5)], .chapter, width: Sketch.stroke)
        }
        if words {
            pen.label("\(id)times", PowersOfTen.Parts.times(d), Self.label.colour(dashed ? .ink2 : .chapter), .below,
                      edge: Self.bottom + Self.dip + 0.5, along: C.point - Double(d) * Self.col / 2)
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = PowersOfTen.Parts(s.numbers), C = Chart(P: P)
        switch stage(s) {
        case 1:
            // the digits, held anywhere on the chart: they follow the finger a place at a time, left only, as far as the
            // chart's first place
            return Hands(grab: { q in C.on(q) ? ["grab": 1, "fx": q.x, "d": 0] : nil },
                         drag: { q, h in
                             let fx = h["fx"] ?? q.x
                             return ["grab": 1, "fx": fx, "d": min(Double(P.most), max(0, ((fx - q.x) / Self.col).rounded()))]
                         },
                         release: { h in
                             let d = h["d"] ?? 0
                             return HandMove(hand: ["d": d], missHand: [:], set: [("x", d)], check: true)
                         })
        case 2:
            // a gap: a 0 is written there, and the last one answers the step; anywhere else on the chart says what's there
            return Hands(tap: { q in
                guard C.on(q) else { return nil }
                let p = C.place(at: q.x)
                guard P.gaps.contains(p) else { return HandMove(hand: nil, missHand: nil, set: [("x", PowersOfTen.tapCode(p))], check: true) }
                guard s.h("z\(p)") != 1 else { return nil }
                var h = s.hand
                h["z\(p)"] = 1
                let done = P.gaps.allSatisfy { h["z\($0)"] == 1 }
                return HandMove(hand: h, missHand: nil, set: done ? [("x", Double(P.gaps.count))] : [], check: done)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PowersOfTen.Parts(s.numbers), C = Chart(P: P)
        switch stage(s) {
        case 1:
            // from the middle of the digits, k places left
            let a = (C.mid(P.place(0)) + C.mid(P.place(P.digits.count - 1))) / 2
            return [.drag(from: CGPoint(x: a, y: Self.row), to: CGPoint(x: a - Double(P.k) * Self.col, y: Self.row))]
        case 2:
            return P.gaps.filter { s.h("z\($0)") != 1 }.map { .tap(.picture(CGPoint(x: C.mid($0), y: Self.row))) }
        default: return []
        }
    }

    func messageRows(_ n: Numbers) -> Int {
        // what a miss says, at its longest, over the chart's width
        let P = PowersOfTen.Parts(n), f = PaperText.font(Sketch.Words.note.size, Sketch.Words.note.weight)
        let longest = [P.moved(P.k + 1), P.madeSmaller, P.tapped(P.hi), P.zerosLeftOut, P.pointLeftOut].compactMap { $0 }
        return min(2, longest.map { PaperText.wrap($0, f, width: Chart(P: P).width * Paper.cell).count }.max() ?? 1)
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PowersOfTen.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // one place too far (the 1 counted as a zero), or one short when there's no room
            let d = Double(P.k + 1 <= P.most ? P.k + 1 : P.k - 1)
            return HandMove(hand: ["d": d], missHand: [:], set: [("x", d)], check: true)
        case 2:
            // a 0 after the point, the commonest wrong tap
            return HandMove(hand: nil, missHand: nil, set: [("x", PowersOfTen.tapCode(-1))], check: true)
        default: return nil
        }
    }
}
