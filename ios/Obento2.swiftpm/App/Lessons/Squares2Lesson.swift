import SwiftUI

/// Rows and columns of squares on the paper, as in the preview (design/prototype/grade2-ch3.html, dSquares): a square tile is
/// a block, so every cut falls on a strong line. The rectangle, bold, a block in (room for the rows' numbers and the
/// handle at its left), 2–5 blocks tall and 2–6 across, plain inside. The ruler: drag down its left side (rows) or along
/// its top (columns); a small handle marks the first cut, the cuts it would make dash across, snapping to equal pieces that
/// fit, the readout beside it ("3 rows", "4 columns of squares"); Cut. Once both are cut the tiles tint in a light checker.
/// Then tap each row, and write `4 + 4 + 4 = [ ] squares`; once it's right the running totals write in.
///
/// Hand: "grab", "s0" / "s1" the piece (in squares) each cut snaps to now; it stays after the finger lifts, until Cut.
@MainActor
struct Squares2Lesson: PaperLesson {
    static let SX = 5.0, SY = 0.0
    var liveKeys: Set<String> { ["s0", "s1"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static func grid(_ P: Squares2.Parts) -> EG2.Grid { EG2.Grid(x: SX, y: SY, rows: P.R, cols: P.C) }
    private static func RY(_ P: Squares2.Parts) -> Double { SY + 5 * Double(P.R) + 2 }
    func recordRow(_ n: Numbers) -> Double? { Self.RY(Squares2.Parts(n)) }
    /// Cut under the rectangle (Check and Next problem under the record: beside it, the keys would cover Check). The top's
    /// handle, its hint and its cuts sit inside the rectangle's top, clear of what a miss says over it.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Squares2.Parts(s.numbers), st = at(s)
        if st <= 1 { return CGPoint(x: Self.SX, y: Self.RY(P) - 1) }
        return nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Squares2.Parts(s.numbers), st = at(s), G = Self.grid(P), SX = Self.SX, SY = Self.SY, W = G.w, H = G.h
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let cutting = st <= 1, rows = cutting ? P.rowsCut(st) : true
        // what's cut: the first cut after step 0, both after step 1 (every 5 squares, a block)
        let cutRows = (st > 0 && P.rowsCut(0)) || (st > 1 && P.rowsCut(1)), cutCols = (st > 0 && !P.rowsCut(0)) || (st > 1 && !P.rowsCut(1))
        if cutRows && cutCols {
            // a row being lit takes its band instead (two fills over each other fight)
            let lit = st == 2 ? EG2.lit(s, rows: P.R, past: false) : []
            for r in 0..<P.R where !lit.contains(r) { for c in 0..<P.C where (r + c) % 2 == 0 { pic.fill("tile\(r).\(c)", col: SX + 5 * Double(c), row: SY + 5 * Double(r), w: 5, h: 5, .tint(0.2)) } }
        }
        if cutRows { for r in 1..<P.R { pic.line("cy\(r)", [(SX, SY + 5 * Double(r)), (SX + W, SY + 5 * Double(r))], .chapter) } }
        if cutCols { for c in 1..<P.C { pic.line("cx\(c)", [(SX + 5 * Double(c), SY), (SX + 5 * Double(c), SY + H)], .chapter) } }
        pic.sketch.box("shape", pic.R(SX, SY, W, H), .ink, width: Sketch.stroke)
        EG2.drawRows(&pic, &live, s, G, tapping: st == 2, past: st > 2)

        let rx = SX + W + 1.5
        if cutting {
            let key = "s\(st)", len = Double(P.len(rows)), cut = s.h(key).map { Int($0) }
            // the cuts the handle would make now, dashed, live; the handle on the side it cuts along, at the first cut
            if let c = cut, c > 0 {
                for p in stride(from: Double(c), to: len, by: Double(c)) {
                    if rows { live.line("ly\(Int(p))", [(SX - 0.8, SY + p), (SX + W + 0.8, SY + p)], .ink2, dashed: true) }
                    else { live.line("lx\(Int(p))", [(SX + p, SY), (SX + p, SY + H + 0.8)], .ink2, dashed: true) }
                }
                let k = Int(len) / c, squares = st == 1 && c == 5
                EG2.readout(&live, squares ? "\(k) \(Squares2.Parts.name(rows)) of squares" : "\(k) \(Squares2.Parts.name(rows))", x: rx, y: SY + 2.5)
                if s.grabbed { live.reads(squares ? "\(k) \(Squares2.Parts.name(rows)) of squares" : "\(k) \(Squares2.Parts.name(rows))") }
            }
            let a = Double(cut ?? 0)
            let tri = rows ? [live.P(SX - 1.6, SY + a - 0.6), live.P(SX - 0.4, SY + a), live.P(SX - 1.6, SY + a + 0.6)]
                           : [live.P(SX + a - 0.6, SY + 0.4), live.P(SX + a, SY + 1.6), live.P(SX + a + 0.6, SY + 0.4)]
            live.sketch.polygon("handle", tri, .chapter)
            // hints: a miss rings the side to drag along; a second dashes where the cuts go
            if s.on("ring") || s.on("spot") {
                if rows { KK.hintBox(&pic, "hs", x: SX - 2, y: SY, w: 2, h: H) } else { KK.hintBox(&pic, "hs", x: SX, y: SY, w: W, h: 2) }
            }
            if s.on("spot") {
                for p in stride(from: 5.0, to: len, by: 5) {
                    if rows { pic.line("sy\(Int(p))", [(SX, SY + p), (SX + W, SY + p)], .chapter, dashed: true) }
                    else { pic.line("sx\(Int(p))", [(SX + p, SY), (SX + p, SY + H)], .chapter, dashed: true) }
                }
            }
        }
        if st == 2 {
            let n = EG2.lit(s, rows: P.R, past: false).count
            if n > 0 { EG2.readout(&pic, G2.count(n, "row"), x: rx, y: SY + 2.5) }
            if s.grabbed { live.reads(G2.count(n + 1, "row")) }
        }
        if st >= 3 {
            EG2.record(&rec, rows: P.R, cols: P.C, x: SX, box: "x", cells: 3, done: st == 4 ? P.T : nil, word: "squares")
            if st == 4 { EG2.totals(&pic, G, per: P.C, x: SX + W + 1) }
            if st == 3 && s.on("ring") { KK.hintBox(&pic, "ht", x: SX - 2, y: SY, w: 2, h: H) }
            if st == 3 && s.on("spot") { for r in 0..<P.R { A1.note(&pic, "sp\(r)", "\(P.C * (r + 1))", x: SX + W + 1, y: G.mid(r)) } }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: cutting ? ["Cut"] : [])
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Squares2.Parts(s.numbers), st = at(s), G = Self.grid(P)
        if st == 2 { return EG2.rowHands(s, G, box: "r") }
        guard st <= 1 else { return nil }
        let rows = P.rowsCut(st), key = "s\(st)", sizes = P.sizes(rows)
        func snap(_ q: CGPoint) -> Double {
            let d = rows ? q.y - Self.SY : q.x - Self.SX
            return Double(sizes.min { abs(Double($0) - d) < abs(Double($1) - d) } ?? 5)
        }
        let box = st == 0 ? "k1" : "k2", now = s.h(key).map { Int($0) } ?? 0
        let code = st == 0 ? (now > 0 ? P.len(rows) / now : 0) : now
        let inside = { (q: CGPoint) in q.x >= Self.SX - 2.5 && q.x <= Self.SX + G.w + 2 && q.y >= Self.SY - 2.5 && q.y <= Self.SY + G.h + 2 }
        return Hands(
            grab: { q in inside(q) ? ["grab": 1, key: snap(q)] : nil },
            drag: { q, h in var h = h; h[key] = snap(q); return h },
            release: { h in HandMove(hand: [key: h[key] ?? 5]) },
            actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [(box, Double(code))], check: true) }])
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Squares2.Parts(s.numbers), st = at(s), G = Self.grid(P)
        if st == 2 {
            let L = EG2.lit(s, rows: P.R, past: false)
            return (0..<P.R).filter { !L.contains($0) }.map { .tap(.picture(CGPoint(x: G.x + G.w / 2, y: G.mid($0)))) }
        }
        guard st <= 1 else { return [] }
        let rows = P.rowsCut(st)
        let from = rows ? CGPoint(x: Self.SX - 1, y: Self.SY + 1) : CGPoint(x: Self.SX + 1, y: Self.SY + 1)
        let to = rows ? CGPoint(x: Self.SX - 1, y: Self.SY + 5) : CGPoint(x: Self.SX + 5, y: Self.SY + 1)
        return [.drag(from: from, to: to), .tap(.action("Cut"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Squares2.Parts(s.numbers), st = at(s)
        switch st {
        case 0:
            let rows = P.rowsCut(0), bad = P.sizes(rows).first { $0 != 5 }
            guard let b = bad else { return nil }
            return HandMove(hand: ["s0": Double(b)], missHand: nil, set: [("k1", Double(P.len(rows) / b))], check: true)
        case 1:
            guard let b = P.sizes(P.rowsCut(1)).first(where: { $0 != 5 }) else { return nil }
            return HandMove(hand: ["s1": Double(b)], missHand: nil, set: [("k2", Double(b))], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("r", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Squares2.Parts(s.numbers)
        return at(s) == 3 ? ["x": Double(P.R + P.C)] : nil
    }
}
