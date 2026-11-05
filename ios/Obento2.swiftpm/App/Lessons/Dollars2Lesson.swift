import SwiftUI

/// Dollars and cents on the paper, as in the preview (design/prototype/grade2-ch6.html, dDollars). Bills: bills 10 × 4 fanned
/// in rows by kind, the biggest on top (only the part a bill over it leaves shows); at the right the dollar chart, rows of ten
/// $1 cells (each a little bill 3 × 2; 30 × 20, up to $99); slide each kind in and write the total after it (SlideIn, as
/// Counting money). The cents stories: Counting money's dollar square, the first amount's cents pouring in from the left as the
/// picture draws; making a dollar (tap each empty row or block: the new cents in the chapter colour, the readout counting on by
/// 5s and 25s); buying (the price, a dashed tag holding the thing, slides over the cents and crosses the last ones out); in all
/// (the second amount's coins slide in together, their cents in the chapter colour). The record left of the square, under
/// the readout: `45¢ − 30¢ = [15]¢` (under the square the problem showed at 70%).
///
/// Kept: "tot" the dollar square's total while filling; "lx", "ly" where the tag or the coins were let go. Hand: "grab",
/// "gx", "gy", "dx", "dy".
@MainActor
struct Dollars2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    static let CHX = 25.0, SX = 20.0, RO = 15.0, RL = 21.0
    static let tag = CGRect(x: 0, y: 10, width: 12, height: 4)
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    // MARK: bills

    func bills(_ n: Numbers) -> SlideIn {
        let P = Dollars2.Parts(n), G = P.G
        var rows: [CGRect] = []
        for (j, g) in G.enumerated() { rows.append(CGRect(x: 0, y: 5 * Double(j), width: 3 * Double(g.count - 1) + 10, height: 4)) }
        return SlideIn(groups: G, rows: rows, target: CGRect(x: Self.CHX, y: 0, width: 30, height: 20), colX: Self.CHX + 32,
            readout: { g in "\(g.count) \(Dollars2.Parts.billName(g))" }, money: { "$\($0)" },
            box: { [.t("$"), .box($0, cells: 2)] },
            drawRow: { pen, id, i, dx, dy in
                let g = G[i], r = rows[i]
                for j in 0..<g.count { TMK.bill(&pen, "\(id)\(j)", g.value, x: r.minX + dx + 3 * Double(j), y: r.minY + dy, covered: j + 1 < g.count) }
            },
            piece: { pen, id, _, p, lit in pen.fill(id + "\(lit)", col: p.x + 0.3, row: p.y + 0.3, w: 2.4, h: 1.4, .tint(lit ? 0.45 : 0.22)) },
            pieceAt: { CGPoint(x: Self.CHX + 3 * Double($0 % 10), y: 2 * Double($0 / 10)) })
    }
    private func chart(_ pen: inout GridPen) {
        let x = Self.CHX
        var segs: [(CGPoint, CGPoint)] = []
        for r in 1..<10 { segs.append((pen.P(x, 2 * Double(r)), pen.P(x + 30, 2 * Double(r)))) }
        for c in 1..<10 where c != 5 { segs.append((pen.P(x + 3 * Double(c), 0), pen.P(x + 3 * Double(c), 20))) }
        pen.sketch.segments("chi", segs, .line, width: Sketch.stroke)
        pen.line("chm", [(x + 15, 0), (x + 15, 20)], .ink3)
        pen.sketch.box("cho", pen.R(x, 0, 30, 20), .ink, width: Sketch.stroke)
    }

    // MARK: the cents stories

    private struct Rows { let G: [TM2.Group]; let rows: [CGRect] }
    /// The second amount's coins in rows by kind at the left, fanned.
    private func coinRows(_ amount: Int) -> Rows {
        let G = TM2.coinsFor(amount)
        var rows: [CGRect] = [], y = 0.0
        for g in G { let md = Double(TM2.coins[g.kind].small); rows.append(CGRect(x: 0, y: y, width: 3 * Double(g.count - 1) + md, height: md)); y += md + 1 }
        return Rows(G: G, rows: rows)
    }
    private func drawCoins(_ pen: inout GridPen, _ R: Rows, dx: Double, dy: Double) {
        for (i, g) in R.G.enumerated() {
            let md = Double(TM2.coins[g.kind].small), r = R.rows[i]
            for j in 0..<g.count {
                let x = r.minX + dx + md / 2 + 3 * Double(j), y = r.minY + dy + md / 2
                TMK.coin(&pen, "b\(i):\(j)", g.kind, cx: x, cy: y, r: md / 2, side: 0, under: j + 1 < g.count ? (x + 3, y, md / 2) : nil)
            }
        }
    }
    private func toks(_ P: Dollars2.Parts, done: Bool) -> [M7.Tok] {
        var out: [M7.Tok] = []
        for t in P.lead { out.append(t == "−" || t == "+" || t == "=" ? .op(t) : .t(t)) }
        if done { out.append(.t("\(P.want)¢", .chapter)) } else { out.append(.box("x", cells: 2)); out.append(.t("¢")) }
        return out
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Dollars2.Parts(s.numbers)
        if P.kind == .bills { return bills(s.numbers).blocksAt(s) }
        return at(s) >= 1 ? CGPoint(x: 0, y: Self.RL + 2) : nil
    }
    private func total(_ s: PaperState, _ P: Dollars2.Parts) -> Int { at(s) >= 1 ? 100 : Int(s.run.kept["tot"] ?? Double(P.A)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Dollars2.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.kind == .bills {
            chart(&pic)
            bills(s.numbers).draw(s, &pic, &live, &rec)
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, Self.CHX + 40, 20))
        }
        let SX = Self.SX, A = P.A, held = s.grabbed, dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        TMK.dollarSquare(&pic, x: SX, y: 0)
        // the first amount: its cents pour in from the left as the picture draws, crossed out once the price is over them
        let crossed = P.kind == .buy && st >= 1
        pic.sketch.from = A2.kinds { q in for m in 0..<A { TMK.cent(&q, "c\(m)", x: 4, y: 12, ink: true, cross: false) } }
        for m in 0..<A {
            let p = TMK.centAt(m, x: SX, y: 0)
            pic.sketch.delay = 0.012 * Double(m)
            TMK.cent(&pic, "c\(m)", x: p.x, y: p.y, ink: true, cross: crossed && m >= A - P.price)
        }
        pic.sketch.from = [:]; pic.sketch.delay = 0
        var ro: String?
        switch P.kind {
        case .dollar:
            // the new cents in the chapter colour; the readout counts on by 5s and 25s
            let t = total(s, P)
            for m in A..<t { let p = TMK.centAt(m, x: SX, y: 0); TMK.cent(&pic, "n\(m)", x: p.x, y: p.y, lit: true) }
            var fills: [Int] = []
            for f in P.fills where f <= t { fills.append(f) }
            if !fills.isEmpty { ro = (fills.count > 4 ? "\(fills[0]), \(fills[1]), \(fills[2]) … \(fills[fills.count - 1])" : fills.map(String.init).joined(separator: ", ")) + "¢" }
        case .buy:
            if st == 0 {
                let x = Self.tag.minX + (held ? dx : 0), y = Self.tag.minY + (held ? dy : 0)
                if held {
                    live.sketch.box("tago", live.R(x, y, 12, 4), .chapter, width: Sketch.stroke, dashed: true)
                    LN2.thing(&live, "tagt", P.thing.thing, x0: x + 1, x1: x + 11, y: y + 1)
                } else {
                    if let lx = s.run.kept["lx"], let ly = s.run.kept["ly"] {
                        pic.sketch.from = A2.kinds { q in q.sketch.box("tago", q.R(Self.tag.minX + lx, Self.tag.minY + ly, 12, 4), .chapter, width: Sketch.stroke, dashed: true) }
                    }
                    pic.sketch.box("tago", pic.R(x, y, 12, 4), .chapter, width: Sketch.stroke, dashed: true)
                    pic.sketch.from = [:]
                    LN2.thing(&pic, "tagt", P.thing.thing, x0: x + 1, x1: x + 11, y: y + 1)
                }
            }
            if held || st >= 1 { ro = "\(P.price)¢ crossed out" }
        default:
            // in all: the second amount's coins, slid in together; their cents pour after the first, in the chapter colour
            let R = coinRows(P.B)
            var nB = 0
            for g in R.G { nB += g.count }
            if st >= 1 {
                let lx = s.run.kept["lx"] ?? 0, ly = s.run.kept["ly"] ?? 0
                pic.sketch.from = A2.kinds { q in for m in A..<(A + P.B) { TMK.cent(&q, "n\(m)", x: lx + 4, y: ly + 10, lit: true) } }
                for m in A..<(A + P.B) { let p = TMK.centAt(m, x: SX, y: 0); pic.sketch.delay = 0.02 * Double(m - A); TMK.cent(&pic, "n\(m)", x: p.x, y: p.y, lit: true) }
                pic.sketch.from = [:]; pic.sketch.delay = 0
            } else if held { drawCoins(&live, R, dx: dx, dy: dy) }
            else {
                if let lx = s.run.kept["lx"], let ly = s.run.kept["ly"] { pic.sketch.from = A2.kinds { q in drawCoins(&q, R, dx: lx, dy: ly) } }
                drawCoins(&pic, R, dx: 0, dy: 0)
                pic.sketch.from = [:]
            }
            if held || st >= 1 { ro = "\(nB) \(nB == 1 ? "coin" : "coins")" }
        }
        if let ro {
            if held { TMK.readout(&live, ro, x: 0, y: Self.RO); live.reads(ro) } else { TMK.readout(&pic, ro, x: 0, y: Self.RO) }
        }
        // the record left of the square: 45¢ − 30¢ = [ ]¢
        if st == 1 { M7.row(&rec, "rec", toks(P, done: false), x: 0, line: Self.RL) }
        if st >= 2 { M7.row(&pic, "rec", toks(P, done: true), x: 0, line: Self.RL) }
        // hints: a first miss rings the general area, a second the exact spot
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 {
            switch P.kind {
            case .dollar:
                let t = total(s, P), p = TMK.centAt(t, x: SX, y: 0)
                if ring { KK.hintBox(&pic, "hr", x: SX, y: 0, w: 30, h: 30) }
                if spot && t < 100 { KK.hintBox(&pic, "spot", x: p.x, y: p.y, w: t % 25 == 0 ? 15 : 3 * Double(5 - t % 25 % 5), h: t % 25 == 0 ? 15 : 3) }
            case .buy:
                if ring { KK.hintBox(&pic, "hr", x: Self.tag.minX, y: Self.tag.minY, w: 12, h: 4) }
                if spot { KK.hintBox(&pic, "spot", x: SX, y: 0, w: 30, h: 30) }
            default:
                let R = coinRows(P.B), h = R.rows.last?.maxY ?? 6, w = R.rows.map(\.maxX).max() ?? 6
                if ring { KK.hintBox(&pic, "hr", x: 0, y: 0, w: w, h: h) }
                if spot { KK.hintBox(&pic, "spot", x: SX, y: 0, w: 30, h: 30) }
            }
        }
        if st == 1 {
            if ring { KK.hintBox(&pic, "hr", x: SX, y: 0, w: 30, h: 30) }
            if spot { A1.note(&pic, "spot", "\(P.want)", x: M7.width(toks(P, done: false)) - 5, y: Self.RL - 2.6) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, SX + 30, 30))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Dollars2.Parts(s.numbers), st = at(s), SX = Self.SX
        if P.kind == .bills { return bills(s.numbers).hands(s) }
        guard st == 0 else { return nil }
        let square = CGRect(x: SX, y: 0, width: 30, height: 30)
        if P.kind == .dollar {
            let t = total(s, P)
            return Hands(tap: { q in
                guard square.contains(q) else { return nil }
                let bx = q.x < SX + 15 ? 0 : 1, by = q.y < 15 ? 0 : 1
                let r = max(0, min(4, Int((q.y - 15 * Double(by)) / 3))), c = max(0, min(4, Int((q.x - SX - 15 * Double(bx)) / 3)))
                let n = 25 * (2 * by + bx) + 5 * r + c
                if n < t { return HandMove(hand: nil, missHand: nil, set: [("f", -1)], check: true) }
                let next = t + (t % 25 != 0 ? 5 : 25)
                return HandMove(hand: nil, missHand: nil, set: next == 100 ? [("f", 100)] : [], keep: ["tot": Double(next)], check: next == 100)
            })
        }
        let grabbable: CGRect = {
            if P.kind == .buy { return Self.tag }
            let R = coinRows(P.B)
            return CGRect(x: 0, y: 0, width: R.rows.map(\.maxX).max() ?? 6, height: R.rows.last?.maxY ?? 6)
        }()
        return Hands(
            grab: { q in grabbable.insetBy(dx: -0.6, dy: -0.6).contains(q) ? ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] : nil },
            drag: { q, h in var h = h; h["dx"] = q.x - (h["gx"] ?? q.x); h["dy"] = q.y - (h["gy"] ?? q.y); return h },
            release: { h in
                let dx = h["dx"] ?? 0, dy = h["dy"] ?? 0, q = CGPoint(x: (h["gx"] ?? 0) + dx, y: (h["gy"] ?? 0) + dy)
                let keep: Numbers = ["lx": dx, "ly": dy]
                guard square.insetBy(dx: -1, dy: -1).contains(q) else { return HandMove(hand: [:], keep: keep) }
                return HandMove(hand: [:], missHand: [:], set: [("t", 1)], keep: keep, check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Dollars2.Parts(s.numbers), SX = Self.SX
        if P.kind == .bills { return bills(s.numbers).demo(s) }
        guard at(s) == 0 else { return [] }
        switch P.kind {
        case .dollar:
            var out: [GhostMove] = [], t = total(s, P)
            while t < 100 { let p = TMK.centAt(t, x: SX, y: 0); out.append(.tap(.picture(CGPoint(x: p.x + 1.5, y: p.y + 1.5)))); t += t % 25 != 0 ? 5 : 25 }
            return out
        case .buy: return [.drag(from: CGPoint(x: Self.tag.midX, y: Self.tag.midY), to: CGPoint(x: SX + 15, y: 22))]
        default: return [.drag(from: CGPoint(x: 3, y: 3), to: CGPoint(x: SX + 15, y: 22))]
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Dollars2.Parts(s.numbers)
        if P.kind == .bills { return bills(s.numbers).wrongMove(s) }
        guard at(s) == 0, P.kind == .dollar else { return nil }
        return HandMove(hand: nil, missHand: nil, set: [("f", -1)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Dollars2.Parts(s.numbers), st = at(s)
        if P.kind == .bills {
            let K = bills(s.numbers), k = st / 2
            guard st % 2 == 1, k < K.n else { return nil }
            return ["a\(k)": Double(Dollars2.Parts.billSlips(K.groups[k]).first?.0 ?? 1)]
        }
        guard st == 1 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? 1)]
    }
}
