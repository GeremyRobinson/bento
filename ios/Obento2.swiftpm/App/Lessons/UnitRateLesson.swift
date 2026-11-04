import SwiftUI

/// Unit rates on the paper, as in the preview (design/prototype/grade6-ch1.html, dRate): $1 is a cell (2 × 2 squares, or
/// one square when the 2 × 2 cells wouldn't show at 75%), one row is one item. Left, n rows with no width yet, "4 apples"
/// over them and the total beside the edge: drag the right edge (each column puts $1 in every row; "$8 used, $4 left"),
/// let go when nothing is left. Then right, one row to copy: drag its bottom edge down to m rows, a row of $3 at a time.
/// Then `m × $3 = [ ]` is written. Told as speed (a mile a cell, an hour a row) and as units (an inch a cell, a foot a
/// row), the records keep their units.
@MainActor
struct UnitRateLesson: PaperLesson {
    static let x0 = 0.0, y0 = 2.0
    var liveKeys: Set<String> { ["w", "r"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The copied rows start on the first block line a square past the left rows' labels.
    private static func xr(_ P: UnitRate.Parts, _ C: Double) -> Double { ((x0 + C * Double(P.u) + R6.width(P.perRow) + 1.5) / 5).rounded(.up) * 5 }
    /// The most rows the copy can be dragged to (two past the answer, so it shows at 75%).
    static func most(_ P: UnitRate.Parts) -> Int { P.m + 2 }
    /// A cell's squares: 2 when the problem shows at 75% or more that way (the record under the rows or beside them), else 1.
    static func c(_ P: UnitRate.Parts) -> Double {
        let C = 2.0, n = Double(P.n), m = Double(P.m)
        let w = xr(P, C) + C * Double(P.u) + R6.width(P.perRow) + 1, pic = max(y0 + C * Double(most(P)) + 2, y0 + C * n + 3)
        let recW = max(M7.width(record1(P)), M7.width(record2(P, done: false))) + 1
        let under = ProblemGrid.zoom(squares: max(w, recW), max(pic, y0 + C * max(n, m) + 3 + 5 + 4) + 6)
        let beside = ProblemGrid.zoom(squares: ((w + 4) / 5).rounded(.up) * 5 + recW + 4, max(pic, y0 + 9) + 6)
        return max(under, beside) >= 0.75 ? 2 : 1
    }
    /// Every row is labelled with what it holds, but one-square rows only the first and every 5th (call of 3 Nov, 7).
    static func labelled(_ j: Int, _ C: Double) -> Bool { C >= 2 || j == 0 || (j + 1) % 5 == 0 }
    func recordRow(_ n: Numbers) -> Double? { let P = UnitRate.Parts(n); return Self.y0 + Self.c(P) * Double(max(P.n, P.m)) + 3 }
    func recordBeside(_ n: Numbers) -> Double? { Self.y0 }

    /// The record: the cost of one, then m of them.
    static func record1(_ P: UnitRate.Parts) -> [M7.Tok] {
        P.kind == .cost ? [.t("$\(P.total)"), .op("÷"), .n(P.n), .op("="), .t("$\(P.u)", .chapter)]
            : [.n(P.total), .w(P.smallUnit), .op("÷"), .n(P.n), .w(P.bigUnit), .op("="), .n(P.u, .chapter), .w("\(P.smallUnit) per \(P.bigUnit)", .chapter)]
    }
    static func record2(_ P: UnitRate.Parts, done: Bool) -> [M7.Tok] {
        let ans: M7.Tok = done ? .n(P.u * P.m, .chapter) : .box("x", cells: String(P.u * P.m).count)
        return P.kind == .cost ? [.n(P.m), .op("×"), .t("$\(P.u)"), .op("="), .t("$"), ans]
            : [.n(P.m), .op("×"), .n(P.u), .w(P.smallUnit), .op("="), ans, .w(P.smallUnit)]
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = UnitRate.Parts(s.numbers), at = stage(s), done = at >= 4, C = Self.c(P), x0 = Self.x0, y0 = Self.y0
        let u = Double(P.u), n = Double(P.n), xr = Self.xr(P, C)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let w = at <= 1 ? Int((s.h("w") ?? 0).rounded()) : P.u
        let r = at == 2 ? Int((s.h("r") ?? 1).rounded()) : at > 2 ? P.m : 1
        // left: n rows, filled a column at a time
        pic.word("ln", P.rows(P.n), at: x0, y0 - 1.2, R6.small.colour(.ink), anchor: UnitPoint(x: 0, y: 0.5))
        pic.line("le", [(x0, y0), (x0, y0 + C * n)])
        pic.sketch.segments("lt", (0...P.n).map { j in (pic.P(x0, y0 + C * Double(j)), pic.P(x0 + 1, y0 + C * Double(j))) }, .ink, width: Sketch.stroke)
        if at <= 1 {
            if w > 0 { R6.cells(&live, "lc", x: x0, y: y0, cols: w, rows: P.n, c: C) }
            let hx = x0 + C * Double(w)
            if at == 1 { R6.handle(&live, "lh", hx, y0 + C * n / 2, held: s.grabbed) }
            live.word("ltot", P.totalName, at: hx + 1.3, y0 + C * n / 2, R6.maths, anchor: UnitPoint(x: 0, y: 0.5))
            let ro = P.used(w * P.n, w <= P.u ? (P.u - w) * P.n : -1)
            live.word("lro", ro, at: x0, y0 + C * n + 1.3, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if s.grabbed { live.reads(ro) }
            if s.on("ring") { R6.ring(&pic, "ring", x: x0, y: y0, w: C * u + 4, h: C * n) }
            if s.on("spot") { pic.line("spot", [(x0 + C * u, y0 - 1), (x0 + C * u, y0 + C * n + 1)], .chapter, dashed: true) }
        } else {
            R6.cells(&pic, "lc", x: x0, y: y0, cols: P.u, rows: P.n, c: C)
            pic.label("ltot", P.totalName, R6.maths, .below, edge: y0 + C * n, along: x0 + C * u / 2)
            for j in 0..<P.n where Self.labelled(j, C) { pic.label("lv\(j)", P.perRow, R6.lit, .right, edge: x0 + C * u + 0.1, along: y0 + C * (Double(j) + 0.5)) }
            // right: one row to copy, dragged down to m rows
            pic.word("rn", P.rows(P.m), at: xr, y0 - 1.2, R6.small.colour(.ink), anchor: UnitPoint(x: 0, y: 0.5))
            func right(_ p: inout GridPen) {
                R6.cells(&p, "rc", x: xr, y: y0, cols: P.u, rows: r, c: C, striped: true)
                for j in 0..<r where Self.labelled(j, C) {
                    let v = at == 3 && s.on("spot") ? (P.kind == .cost ? "$\(P.u * (j + 1))" : "\(P.u * (j + 1))") : P.perRow
                    p.label("rv\(j)\(v)", v, R6.lit, .right, edge: xr + C * u + 0.1, along: y0 + C * (Double(j) + 0.5))
                }
            }
            if at == 2 { right(&live) } else { right(&pic) }
            if at == 2 {
                let by = y0 + C * Double(r)
                R6.handle(&live, "rh", xr + C * u, by, held: s.grabbed)
                live.word("rro", P.rows(r), at: xr, by + 1.3, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(P.rows(r)) }
                if s.on("ring") { R6.ring(&pic, "ring", x: xr, y: y0 - 2.2, w: R6.width(P.rows(P.m)), h: 2) }
                if s.on("spot") { pic.line("spot", [(xr - 1, y0 + C * Double(P.m)), (xr + C * u + 1, y0 + C * Double(P.m))], .chapter, dashed: true) }
            }
            if at == 3 && s.on("ring") { R6.ring(&pic, "ringR", x: xr, y: y0, w: C * u + 1 + R6.width("$\(P.u * P.m)"), h: C * Double(P.m)) }
            // the first line of the record waits while the rows are dragged, so rows past the answer never run over it
            if !(at == 2 && s.grabbed) { M7.row(&rec, "r1", Self.record1(P), x: 0, line: 1) }
            if at >= 3 { M7.row(&rec, "r2", Self.record2(P, done: done), x: 0, line: 4) }
        }
        // the room each drag can reach
        let reach = at <= 1 ? pic.R(0, 0, x0 + C * (u + 3) + 1.3 + R6.width(P.totalName, R6.maths) + 1, y0 + C * n + 2)
            : at == 2 ? pic.R(0, 0, xr + C * u + 4, y0 + C * Double(Self.most(P)) + 2) : nil
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: reach)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = UnitRate.Parts(s.numbers), at = stage(s), C = Self.c(P), x0 = Self.x0, y0 = Self.y0
        let u = Double(P.u), n = Double(P.n), xr = Self.xr(P, C)
        switch at {
        case 1:
            let w = s.h("w") ?? 0, hx = x0 + C * w
            return Hands(
                grab: { q in abs(q.x - hx) <= 2 && q.y >= y0 - 1 && q.y <= y0 + C * n + 1 ? ["grab": 1, "w": w] : nil },
                drag: { q, _ in ["grab": 1, "w": Double(max(0, min(P.u + 3, Int(((q.x - x0) / C).rounded()))))] },
                release: { h in
                    let w = h["w"] ?? 0
                    guard w != 0 else { return HandMove(hand: ["w": 0], missHand: nil) }
                    return HandMove(hand: ["w": w], missHand: Int(w) > P.u ? ["w": 0] : nil, set: [("x", w)], check: true)
                })
        case 2:
            let r = s.h("r") ?? 1, by = y0 + C * r
            return Hands(
                grab: { q in abs(q.y - by) <= 2 && q.x >= xr - 1 && q.x <= xr + C * u + 2 ? ["grab": 1, "r": r] : nil },
                drag: { q, _ in ["grab": 1, "r": Double(max(1, min(Self.most(P), Int(((q.y - y0) / C).rounded()))))] },
                release: { h in
                    let r = h["r"] ?? 1
                    guard r != 1 else { return HandMove(hand: ["r": 1], missHand: nil) }
                    return HandMove(hand: ["r": r], missHand: Int(r) > P.m ? ["r": 1] : nil, set: [("x", r)], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = UnitRate.Parts(s.numbers), at = stage(s), C = Self.c(P), x0 = Self.x0, y0 = Self.y0, xr = Self.xr(P, C)
        switch at {
        case 1:
            let y = y0 + C * Double(P.n) / 2
            return [.drag(from: CGPoint(x: x0 + C * (s.h("w") ?? 0), y: y), to: CGPoint(x: x0 + C * Double(P.u), y: y))]
        case 2:
            let x = xr + C * Double(P.u)
            return [.drag(from: CGPoint(x: x, y: y0 + C * (s.h("r") ?? 1)), to: CGPoint(x: x, y: y0 + C * Double(P.m)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = UnitRate.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: ["w": Double(P.u - 1)], missHand: nil, set: [("x", Double(P.u - 1))], check: true)
        case 2: let r = P.m > 2 ? P.m - 1 : P.m + 1; return HandMove(hand: ["r": Double(r)], missHand: nil, set: [("x", Double(r))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = UnitRate.Parts(s.numbers)
        return stage(s) == 3 ? ["x": Double(P.total * P.m)] : nil
    }

    func messageRows(_ n: Numbers) -> Int { 1 }
}
