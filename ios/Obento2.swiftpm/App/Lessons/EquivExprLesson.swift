import SwiftUI

/// Equivalent expressions on the paper, as in the preview (design/prototype/grade6-ch5.html, dEquiv): an area, a cell two
/// squares, rows tall and x + b across, the x part a strip of any length (its end dashed), the b part b cells. Combine:
/// x + x + x as strips a row apart, the bottom one slid up pushing the others into one block; distribute: 3(x + 4), cut
/// down where x ends (the cells part from the strips); factor: 6x + 9 as one long row, its bottom edge dragged down until
/// both parts make whole rows (the strips and cells regroup as it goes). Then write it, and drag x to two lengths: both
/// sides' values written under the record, the same every time. A pair that may not be the same: drag x, then pick.
///
/// Everything is in the picture's squares (recordRow 0). Hand keys: "slid", "col", "cy", "h", "xl", "t1"…"t3" (x's tries).
@MainActor
struct EquivExprLesson: PaperLesson {
    static let X0 = 3.0, Y0 = 2.0
    var liveKeys: Set<String> { ["slid", "col", "cy", "xl", "grab"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    struct Shape {
        let P: Equiv6.Parts
        init(_ n: Numbers) { P = Equiv6.Parts(n) }
        var tallest: Double { P.kind == 0 ? Double(4 * P.k - 2) : P.kind == 2 ? Double(2 * P.hMax) : Double(2 * P.a) }
        var RY: Double { EquivExprLesson.Y0 + tallest + 4 }
        /// x's length (cells) before it's dragged.
        var x0: Double { P.kind == 2 ? 2 : 6 }
        var xMin: Double { P.kind == 2 ? 2 : 3 }
        var width: Double {
            let cells: Int
            switch P.kind {
            case 0: cells = 16
            case 2: cells = max(2 * P.PX + P.QN, P.m * P.xCap + P.n)
            default: cells = P.xCap + P.b
            }
            return EquivExprLesson.X0 + 3 + 2 * Double(cells)
        }
        /// The strips' tops while sliding (the bottom one pushes the ones above it).
        func stripY(_ r: Int, slid: Double) -> Double {
            var y = EquivExprLesson.Y0 + 4 * Double(P.k - 1) - slid, out = Array(repeating: 0.0, count: P.k)
            for j in stride(from: P.k - 1, through: 0, by: -1) { out[j] = min(EquivExprLesson.Y0 + 4 * Double(j), y); y = out[j] - 2 }
            return out[r]
        }
        func rows(_ at: Int, _ h: Numbers) -> Int { P.kind == 0 ? P.k : P.kind == 2 ? (at >= 2 ? P.g : Int(h["h"] ?? 1)) : P.a }
    }

    /// x's tries so far (the last three), from the hand or what the drag kept.
    static func tries(_ h: Numbers) -> [Int] { (1...3).compactMap { h["t\($0)"].map { Int($0) } } }
    static func adding(_ v: Int, to t: [Int]) -> [Int] { var t = t.filter { $0 != v }; t.append(v); return Array(t.suffix(3)) }
    static func store(_ t: [Int], _ h: inout Numbers) { for i in 1...3 { h["t\(i)"] = i <= t.count ? Double(t[i - 1]) : nil } }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers)
        switch stage(s) {
        case 2: return CGPoint(x: 0, y: S.RY + 2)
        case 4: return CGPoint(x: 0, y: S.RY + 8)
        // Same / Not the same in a column beside the record and x's tries
        case 5: return CGPoint(x: 30, y: S.RY - 1)
        default: return nil
        }
    }
    func keysFocus(_ s: PaperState) -> CGRect? {
        let S = Shape(s.numbers)
        return stage(s) == 2 ? CGRect(x: 0, y: Self.Y0 - 2, width: S.width, height: S.tallest + 2) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.P, at = stage(s), X0 = Self.X0, Y0 = Self.Y0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let kept = s.run.kept, base = at == 3 || at == 5 ? kept.merging(s.hand) { $1 } : at == 4 ? kept : s.hand
        let held = s.grabbed, xHeld = held && (at == 3 || at == 5)
        let xl = s.h("xl") ?? kept["xl"] ?? S.x0
        let tries = Self.tries(base)
        func xstrip(_ pen: inout GridPen, _ id: String, _ x: Double, _ y: Double) {
            X6.strip(&pen, id, x: x, y: y, len: 2 * xl, h: 2, cell: xHeld ? 2 : nil, label: "x", held: xHeld)
        }
        var pen = xHeld ? live : pic

        switch P.kind {
        case 0:
            let slid = at >= 2 ? Double(2 * (P.k - 1)) : s.h("slid") ?? 0, sliding = at == 1 && held
            var p2 = sliding ? live : pen
            for r in 0..<P.k { xstrip(&p2, "cs\(r)", X0, S.stripY(r, slid: slid)) }
            let yb = S.stripY(P.k - 1, slid: slid)
            if at == 1 {
                R6.handle(&p2, "hs", X0, yb + 2, held: sliding)
                var group = 1
                for r in stride(from: P.k - 2, through: 0, by: -1) { if S.stripY(r, slid: slid) + 2 >= S.stripY(r + 1, slid: slid) - 0.01 { group += 1 } else { break } }
                if sliding { p2.word("rds", "\(group) rows of x", at: X0 + 2 * xl + 1, yb + 1, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)); p2.reads("\(group) rows of x") }
            }
            if sliding { live = p2 } else { pen = p2 }
            if at >= 2 {
                pen.label("kl", "\(P.k)", X6.words.colour(.chapter), .left, edge: X0 - 0.6, along: Y0 + Double(P.k))
                pen.label("xl", "x", X6.words.colour(.chapter), .above, edge: Y0 - 0.6, along: X0 + xl)
            }
            if at == 1 && s.on("ring") { X6.ring(&pen, "ring", x: X0, y: Y0, w: 2 * xl, h: Double(4 * P.k - 2)) }
            if at == 1 && s.on("spot") { pen.sketch.box("spot", pen.R(X0, Y0, 2 * xl, Double(2 * P.k)), .chapter, width: Sketch.stroke, dashed: true) }
        case 2:
            let hh = S.rows(at, s.hand), rowsHeld = at == 1 && held
            var p2 = rowsHeld ? live : pen
            for r in 0..<hh {
                let sr = P.PX / hh + (r < P.PX % hh ? 1 : 0), cr = P.QN / hh + (r < P.QN % hh ? 1 : 0)
                var cx = X0
                for j in 0..<sr { xstrip(&p2, "fs\(r)_\(j)", cx, Y0 + 2 * Double(r)); cx += 2 * xl }
                for j in 0..<cr {
                    p2.fill("fc\(r)_\(j)f", col: cx + 2 * Double(j), row: Y0 + 2 * Double(r), w: 2, h: 2, .tint(0.42))
                    p2.sketch.box("fc\(r)_\(j)", p2.R(cx + 2 * Double(j), Y0 + 2 * Double(r), 2, 2), .chapter, width: Sketch.stroke)
                }
            }
            if at == 1 {
                R6.handle(&p2, "hr", X0, Y0 + 2 * Double(hh), held: rowsHeld)
                if rowsHeld {
                    let fits = P.PX % hh == 0 && P.QN % hh == 0
                    let rd = fits ? "\(hh) rows: \(Expr6.term(P.PX / hh, "x")) and \(P.QN / hh)" : "\(hh) rows: not the same"
                    p2.word("rdr", rd, at: X0 - 2, Y0 + 2 * Double(hh) + 1.6, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)); p2.reads(rd)
                }
            }
            if rowsHeld { live = p2 } else { pen = p2 }
            if at >= 2 { pen.label("gl", "\(P.g)", X6.words.colour(.chapter), .left, edge: X0 - 0.6, along: Y0 + Double(P.g)) }
            if at == 1 && s.on("ring") { X6.ring(&pen, "ring", x: X0, y: Y0, w: S.width - X0 - 3, h: 2 * Double(P.hMax)) }
            if at == 1 && s.on("spot") { pen.line("spot", [(X0 - 1, Y0 + 2 * Double(P.g)), (X0 + 2 * (Double(P.m) * xl + Double(P.n)) + 1, Y0 + 2 * Double(P.g))], .chapter, dashed: true) }
        default:
            // the area: a rows of x, then the b cells (apart once cut)
            let cut = P.kind == 1 && at >= 2, gap = cut ? 1.0 : 0, bx = X0 + 2 * xl + gap
            for r in 0..<P.a { xstrip(&pen, "as\(r)", X0, Y0 + 2 * Double(r)) }
            R6.cells(&pen, "bc", x: bx, y: Y0, cols: P.b, rows: P.a, c: 2)
            pen.label("al", "\(P.a)", X6.words.colour(.chapter), .left, edge: X0 - 0.6, along: Y0 + Double(P.a))
            pen.label("xlab", "x", X6.words.colour(.chapter), .above, edge: Y0 - 0.6, along: X0 + xl)
            pen.label("blab", "\(P.b)", X6.words.colour(.chapter), .above, edge: Y0 - 0.6, along: bx + Double(P.b))
            if P.kind == 1 && at == 1 {
                if held, let col = s.h("col"), let cy = s.h("cy") {
                    let cx = X0 + 2 * col
                    live.line("cut", [(cx, Y0 - 1), (cx, cy)], .chapter)
                    R6.handle(&live, "hc", cx, cy, held: true)
                    if Int(col) == Int(xl) { live.word("rdc", "x | \(P.b)", at: cx + 0.8, Y0 + 2 * Double(P.a) + 1.4, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads("x | \(P.b)") }
                } else if let bad = s.h("bad") {
                    pen.line("badcut\(bad)", [(X0 + 2 * bad, Y0), (X0 + 2 * bad, Y0 + 2 * Double(P.a))], R6.red)
                }
                if s.on("ring") { X6.ring(&pen, "ring", x: X0, y: Y0, w: 2 * (xl + Double(P.b)), h: 2 * Double(P.a)) }
                if s.on("spot") { pen.line("spot", [(X0 + 2 * xl, Y0 - 1.5), (X0 + 2 * xl, Y0 + 2 * Double(P.a) + 1)], .chapter, dashed: true) }
            }
        }
        // x's end can be dragged now
        if at == 3 || at == 5 {
            R6.handle(&pen, "hx", X0 + 2 * xl, Y0, held: xHeld)
            if at == 3 && s.on("ring") { X6.ring(&pen, "ring", x: X0 + 2 * xl - 2, y: Y0 - 2, w: 4, h: S.tallest + 2) }
        }
        if xHeld { live = pen } else { pic = pen }

        // the record; x's tries under it
        let cs = { (v: Int) in "\(v)" }
        func box(_ id: String, _ v: Int) -> M7.Tok { at == 2 ? .box(id, cells: max(1, cs(v).count)) : .n(v, .chapter) }
        switch P.kind {
        case 0: if at >= 2 { M7.row(&rec, "rec", Array(Array(repeating: [M7.Tok.t("x"), .op("+")], count: P.k).flatMap { $0 }.dropLast()) + [.op("="), box("c", P.k), .t("x")], x: 0, line: S.RY) }
        case 1: if at >= 2 { M7.row(&rec, "rec", [.t("\(P.a)(x"), .op("+"), .t("\(P.b))"), .op("="), box("c", P.a), .t("x"), .op("+"), box("d", P.a * P.b)], x: 0, line: S.RY) }
        case 2:
            if at >= 2 {
                M7.row(&rec, "rec", [.t("\(P.PX)x"), .op("+"), .n(P.QN), .op("="), box("g", P.g), .t("(")] + (P.m == 1 ? [] : [box("m", P.m)])
                       + [.t("x"), .op("+"), box("n", P.n), .t(")")], x: 0, line: S.RY)
            }
        default:
            M7.row(&rec, "rec", [.t("\(P.a)(x"), .op("+"), .t("\(P.b))"), .w("and"), .t("\(P.a)x"), .op("+"), .n(P.same ? P.a * P.b : P.b)], x: 0, line: S.RY)
        }
        if at == 2 && s.on("ring") { X6.ring(&pic, "ring", x: X0, y: Y0, w: S.width - X0 - 3, h: S.tallest) }
        if at >= 3 {
            var list = tries
            if xHeld && !list.contains(Int(xl)) { list.append(Int(xl)) }
            let lines = list.suffix(3)
            var tp = xHeld ? live : rec
            for (j, v) in lines.enumerated() {
                let (p, q) = P.sides(v), on = v == Int(xl)
                tp.word("try\(j)_\(v)\(on)", "x = \(v): \(p) and \(q)", at: 0, S.RY + 2.6 + Double(j) * 1.6, on ? X6.lit : X6.small, anchor: UnitPoint(x: 0, y: 0.5))
            }
            if xHeld { live = tp; live.reads("x = \(Int(xl)): \(P.sides(Int(xl)).0) and \(P.sides(Int(xl)).1)") } else { rec = tp }
            if at == 5 && s.on("ring") { X6.ring(&rec, "ring", x: 0, y: S.RY + 1.8, w: 16, h: 4.8) }
        }
        let ext = pic.R(-1, Y0 - 2.5, S.width + 1, S.tallest + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), P = S.P, at = stage(s), X0 = Self.X0, Y0 = Self.Y0, kept = s.run.kept
        let xl = s.h("xl") ?? kept["xl"] ?? S.x0
        switch at {
        case 1 where P.kind == 0:
            let slid = s.h("slid") ?? 0, yb = S.stripY(P.k - 1, slid: slid)
            return Hands(grab: { q in
                q.x > X0 - 1.5 && q.x < X0 + 2 * xl + 1 && q.y > yb - 1 && q.y < yb + 3.5 ? ["grab": 1, "slid": slid, "y0": q.y, "s0": slid] : nil
            }, drag: { q, h in
                var h = h
                let raw = (h["s0"] ?? 0) + ((h["y0"] ?? q.y) - q.y)
                h["slid"] = max(0, min(Double(2 * (P.k - 1)), (raw / 2).rounded() * 2))
                return h
            }, release: { h in
                let v = h["slid"] ?? 0, done = v >= Double(2 * (P.k - 1))
                return HandMove(hand: ["slid": v], missHand: ["slid": v], set: [("x", done ? 1 : 0)], check: true)
            })
        case 1 where P.kind == 1:
            return Hands(grab: { q in
                guard q.x > X0, q.x < X0 + 2 * (xl + Double(P.b)), q.y > Y0 - 2.5, q.y < Y0 + 1.5 else { return nil }
                return ["grab": 1, "col": max(1, min(xl + Double(P.b) - 1, ((q.x - X0) / 2).rounded())), "cy": Y0]
            }, drag: { q, h in
                var h = h
                h["col"] = max(1, min(xl + Double(P.b) - 1, ((q.x - X0) / 2).rounded()))
                h["cy"] = max(Y0, min(Y0 + 2 * Double(P.a), q.y))
                return h
            }, release: { h in
                let col = h["col"] ?? 1, cy = h["cy"] ?? Y0
                if cy < Y0 + 2 * Double(P.a) - 1 { return HandMove(hand: [:], missHand: [:], set: [("x", -1)], check: true) }
                if col != xl { return HandMove(hand: [:], missHand: ["bad": col], set: [("x", 0)], check: true) }
                return HandMove(hand: [:], set: [("x", 1)], check: true)
            })
        case 1 where P.kind == 2:
            let h0 = s.h("h") ?? 1
            return Hands(grab: { q in
                abs(q.y - (Y0 + 2 * h0)) < 1.8 && q.x > X0 - 2.5 && q.x < X0 + 12 ? ["grab": 1, "h": h0] : nil
            }, drag: { q, _ in
                ["grab": 1, "h": max(1, min(Double(P.hMax), ((q.y - Y0) / 2).rounded()))]
            }, release: { h in
                let v = h["h"] ?? 1
                return HandMove(hand: ["h": v], missHand: ["h": v], set: [("x", v)], check: true)
            })
        case 3, 5:
            let base = kept.merging(s.hand) { $1 }, t = Self.tries(base)
            return Hands(grab: { q in
                guard abs(q.x - (X0 + 2 * xl)) < 1.8 && q.y > Y0 - 2 && q.y < Y0 + S.tallest + 1 else { return nil }
                // the tries so far go with the hand while it holds x
                var h: Numbers = ["grab": 1, "xl": xl]; Self.store(t, &h); return h
            }, drag: { q, h in
                var h = h
                h["xl"] = max(S.xMin, min(Double(P.xCap), ((q.x - X0) / 2).rounded()))
                return h
            }, release: { h in
                let t = Self.tries(h)
                let v = h["xl"] ?? xl, now = Self.adding(Int(v), to: t)
                var out: Numbers = ["xl": v]; Self.store(now, &out)
                if at == 5 { return HandMove(hand: out, missHand: nil) }
                let need = P.kind == 3 ? 1 : 2
                if now.count >= need { return HandMove(hand: out, missHand: nil, set: [("t", Double(now.count))], keep: out, check: true) }
                return HandMove(hand: out, missHand: nil)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers), P = S.P, at = stage(s), X0 = Self.X0, Y0 = Self.Y0
        let xl = s.h("xl") ?? s.run.kept["xl"] ?? S.x0
        switch at {
        case 1 where P.kind == 0:
            let slid = s.h("slid") ?? 0, yb = S.stripY(P.k - 1, slid: slid)
            return [.drag(from: CGPoint(x: X0 + 2, y: yb + 1), to: CGPoint(x: X0 + 2, y: yb + 1 - (Double(2 * (P.k - 1)) - slid)))]
        case 1 where P.kind == 1:
            let x = X0 + 2 * xl
            return [.drag(from: CGPoint(x: x, y: Y0 - 1), to: CGPoint(x: x, y: Y0 + 2 * Double(P.a) + 0.5))]
        case 1 where P.kind == 2:
            let h0 = s.h("h") ?? 1
            return [.drag(from: CGPoint(x: X0, y: Y0 + 2 * h0), to: CGPoint(x: X0, y: Y0 + 2 * Double(P.g)))]
        case 3:
            let cap = Double(P.xCap)
            let v1 = xl + 3 <= cap ? xl + 3 : xl - 2, v2 = v1 + 2 <= cap ? v1 + 2 : v1 - 3
            let y = Y0 + 1
            var m: [GhostMove] = [.drag(from: CGPoint(x: X0 + 2 * xl, y: y), to: CGPoint(x: X0 + 2 * v1, y: y))]
            if P.kind != 3 { m.append(.drag(from: CGPoint(x: X0 + 2 * v1, y: y), to: CGPoint(x: X0 + 2 * v2, y: y))) }
            return m
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Shape(s.numbers), P = S.P, xl = s.h("xl") ?? S.x0
        guard stage(s) == 1 else { return nil }
        switch P.kind {
        case 0: let v = Double(2 * (P.k - 1) - 2); return HandMove(hand: ["slid": v], missHand: ["slid": v], set: [("x", 0)], check: true)
        case 1: return HandMove(hand: [:], missHand: ["bad": xl - 1], set: [("x", 0)], check: true)
        case 2:
            let smaller = (2..<P.g).last { P.g % $0 == 0 } ?? 1
            return HandMove(hand: ["h": Double(smaller)], missHand: ["h": Double(smaller)], set: [("x", Double(smaller))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Equiv6.Parts(s.numbers)
        guard stage(s) == 2 else { return nil }
        switch P.kind {
        case 0: return ["c": Double(P.k - 1)]
        case 1: return ["c": Double(P.a), "d": Double(P.b)]
        default:
            // a common factor but not the greatest when there is one; else one row's number miscounted
            guard let smaller = (2..<P.g).last(where: { P.g % $0 == 0 }) else {
                var out: [String: Double] = ["g": Double(P.g), "n": Double(P.n + 1)]
                if P.m != 1 { out["m"] = Double(P.m) }
                return out
            }
            var out: [String: Double] = ["g": Double(smaller), "n": Double(P.n * P.g / smaller)]
            if P.m != 1 { out["m"] = Double(P.m * P.g / smaller) }
            return out
        }
    }
}
