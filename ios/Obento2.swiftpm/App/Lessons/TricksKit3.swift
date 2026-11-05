import SwiftUI

/// What 3rd grade's chapter 2, Times-table tricks, shares on the paper (the preview design/prototype/grade3-ch2.html), on
/// top of chapter 1's arrays (M3): an array a cut parts in two (the second part may stand a square away; the keys never
/// change, so it glides), the ruler (a handle on a stem at the picture's edge that snaps between things, a dashed cut
/// across while it moves), and a small block drawn on the paper (Even, Odd).
@MainActor
enum T3 {
    /// An array of rows × cols cells of c squares from (x, y), cut after `at` columns (`byCols`) or rows: the second part
    /// `gap` squares away. Before the cut it reads as one array; once cut, the cut's edges are ink. `tint`: each part lit.
    @discardableResult
    static func split(_ pen: inout GridPen, _ id: String, x: Double, y: Double, rows: Int, cols: Int, c: Double, byCols: Bool, at: Int,
                      gap: Double, cut: Bool, tint: (Bool, Bool)) -> [CGRect] {
        let A: CGRect, B: CGRect
        if byCols {
            A = CGRect(x: x, y: y, width: Double(at) * c, height: Double(rows) * c)
            B = CGRect(x: x + Double(at) * c + gap, y: y, width: Double(cols - at) * c, height: Double(rows) * c)
        } else {
            A = CGRect(x: x, y: y, width: Double(cols) * c, height: Double(at) * c)
            B = CGRect(x: x, y: y + Double(at) * c + gap, width: Double(cols) * c, height: Double(rows - at) * c)
        }
        let parts = [A, B], lit = [tint.0, tint.1]
        for (n, p) in parts.enumerated() where lit[n] { pen.fill("\(id)t\(n)", col: p.minX, row: p.minY, w: p.width, h: p.height, .tint(0.2)) }
        // the faint inner lines, each its own so the second part's glide with it
        for (n, p) in parts.enumerated() {
            let w = Int((p.width / c).rounded()), h = Int((p.height / c).rounded()), j0 = byCols && n == 1 ? at : 0, i0 = !byCols && n == 1 ? at : 0
            for j in 1..<max(1, w) { pen.sketch.segments("\(id)v\(j0 + j)", [(pen.P(p.minX + Double(j) * c, p.minY), pen.P(p.minX + Double(j) * c, p.maxY))], .ink3, width: 1) }
            for i in 1..<max(1, h) { pen.sketch.segments("\(id)h\(n).\(i0 + i)", [(pen.P(p.minX, p.minY + Double(i) * c), pen.P(p.maxX, p.minY + Double(i) * c))], .ink3, width: 1) }
            for i in 0..<h { for j in 0..<w { pen.dot("\(id)d\(i0 + i).\(j0 + j)", at: p.minX + (Double(j) + 0.5) * c, p.minY + (Double(i) + 0.5) * c, radius: M3.dotR(c), over: true) } }
        }
        // the outline: each part's sides, so the second part's glide; the cut's edges once it's cut
        if byCols {
            pen.line(id + "l", [(A.minX, y), (A.minX, A.maxY)]); pen.line(id + "r", [(B.maxX, y), (B.maxX, B.maxY)])
            for (n, p) in parts.enumerated() { pen.line("\(id)T\(n)", [(p.minX, y), (p.maxX, y)]); pen.line("\(id)B\(n)", [(p.minX, p.maxY), (p.maxX, p.maxY)]) }
            if cut { pen.line(id + "c0", [(A.maxX, y), (A.maxX, A.maxY)]); pen.line(id + "c1", [(B.minX, y), (B.minX, B.maxY)]) }
            else { pen.sketch.segments("\(id)v\(at)", [(pen.P(A.maxX, y), pen.P(A.maxX, A.maxY))], .ink3, width: 1) }
        } else {
            pen.line(id + "t", [(x, A.minY), (A.maxX, A.minY)]); pen.line(id + "b", [(x, B.maxY), (B.maxX, B.maxY)])
            for (n, p) in parts.enumerated() { pen.line("\(id)L\(n)", [(x, p.minY), (x, p.maxY)]); pen.line("\(id)R\(n)", [(p.maxX, p.minY), (p.maxX, p.maxY)]) }
            if cut { pen.line(id + "c0", [(x, A.maxY), (A.maxX, A.maxY)]); pen.line(id + "c1", [(x, B.minY), (B.maxX, B.minY)]) }
            else { pen.sketch.segments("\(id)hc", [(pen.P(x, A.maxY), pen.P(A.maxX, A.maxY))], .ink3, width: 1) }
        }
        return parts
    }

    /// The ruler: a handle on a stem `len` squares long at the picture's edge. `down`: the stem stands over the top edge
    /// at column x + k·c and the cut runs down; else it sticks out of the right edge at row y + k·c and the cut runs
    /// across. `span` cells long the other way; `n` cells along the way it cuts (k at n: it rests at the far end, no cut).
    @MainActor struct Ruler {
        let down: Bool, x: Double, y: Double, c: Double, n: Int, span: Int
        var len = 3.0
        func at(_ k: Int) -> CGPoint { down ? CGPoint(x: x + Double(k) * c, y: y - len) : CGPoint(x: x + Double(span) * c + len, y: y + Double(k) * c) }
        /// Is q on the handle or its stem (a finger's width round them)?
        func holds(_ q: CGPoint, _ k: Int) -> Bool {
            let h = at(k)
            return down ? abs(q.x - h.x) < 2 && q.y > h.y - 2 && q.y < y + 0.5
                        : abs(q.y - h.y) < 2 && q.x > x + Double(span) * c - 0.5 && q.x < h.x + 2
        }
        /// The cut a finger here snaps to: between things, 1 to n − 1.
        func snap(_ q: CGPoint) -> Int { max(1, min(n - 1, Int(((down ? q.x - x : q.y - y) / c).rounded()))) }
        func draw(_ pen: inout GridPen, _ k: Int, held: Bool) {
            let h = at(k), L = Double(span) * c
            if down { pen.line("rus", [(h.x, y), (h.x, h.y)], .chapter) } else { pen.line("rus", [(x + L, h.y), (h.x, h.y)], .chapter) }
            pen.dot("ruh", at: h.x, h.y, radius: held ? 0.7 : 0.55)
            guard k > 0, k < n else { return }
            if down { pen.line("rucut", [(h.x, y - 0.6), (h.x, y + L + 0.6)], .ink2, dashed: true) }
            else { pen.line("rucut", [(x - 0.6, h.y), (x + L + 0.6, h.y)], .ink2, dashed: true) }
        }
    }

    /// A small block on the paper, 2 squares tall (Even, Odd): its outline red after a wrong tap, green once right.
    static func block(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, _ label: String, wrong: Bool = false, right: Bool = false) {
        let c: Sketch.Colour = wrong ? KK.red : right ? Bars.green : .ink
        pen.sketch.box("\(id)o\(wrong)\(right)", pen.R(x, y, w, 2), c, width: Sketch.stroke)
        pen.word("\(id)w\(wrong)\(right)", label, at: x + 1, y + 1, Sketch.Words(size: Sketch.small, weight: .semibold, colour: c), anchor: UnitPoint(x: 0, y: 0.5))
    }
}
