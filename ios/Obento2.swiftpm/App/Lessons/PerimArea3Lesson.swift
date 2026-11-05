import SwiftUI

/// Same perimeter, different area on the paper, as in the preview (design/prototype/grade3-ch4.html, dPerimArea), one
/// square of the grid a unit: the fence is counted along the squares' edges (a tick across it at each one), the area in
/// tinted tiles, and both measures are written beside it ("fence 16 · area 15"), live while it moves. A missing side:
/// drag the open side down a square at a time; write `8 + [4] + 8 + 4 = 24`. Same fence: drag the corner along the
/// fence's dashed slant (it snaps to whole squares); write `5 × 3 = [15]`; then every garden the fence makes is listed and
/// the one made ringed. Same tiles: drag the corner; it snaps only where the tiles make a rectangle, and they glide into
/// it; write `3 + 4 + 3 + 4 = [14]`.
///
/// Hand: "grab", "n" the rows (a missing side), "cp", "cq" where the corner is.
@MainActor
struct PerimArea3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let X0 = 5.0, Y0 = 3.0
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    /// Where a missing side starts (a row; two when the side to find is one row).
    private static func startRows(_ P: PerimArea3.Parts) -> Int { P.q == 1 ? 2 : 1 }
    private static func dims(_ P: PerimArea3.Parts, _ s: PaperState) -> (Int, Int) {
        if at(s) > 0 { return (P.p, P.q) }
        if P.kind == 0 { return (P.p, Int((s.h("n") ?? Double(startRows(P))).rounded())) }
        return (Int((s.h("cp") ?? Double(P.start.0)).rounded()), Int((s.h("cq") ?? Double(P.start.1)).rounded()))
    }
    private static func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PerimArea3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, (p, q) = Self.dims(P, s), ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), moving = st == 0
        let maxW = P.kind == 0 ? P.p : P.spots.map(\.0).max() ?? P.p, maxH = P.kind == 0 ? P.maxRows : P.spots.map(\.1).max() ?? P.q
        // the tiles (when tiles regroup, each glides to its new place) and the outline, with a tick at every square
        if P.kind == 2 {
            for t in 0..<P.A { pic.fill("tile\(t)", col: X0 + Double(t % p), row: Y0 + Double(t / p), w: 1, h: 1, S3P.tint) }
        } else if moving { live.fill("tint", col: X0, row: Y0, w: Double(p), h: Double(q), S3P.tint) }
        else { pic.fill("tint", col: X0, row: Y0, w: Double(p), h: Double(q), S3P.tint) }
        if moving {
            S3P.tiles(&live, "g\(p)x\(q)", x: X0, y: Y0, rows: q, cols: p)
            S3P.fence(&live, "fence", x: X0, y: Y0, p: p, q: q)
            live.label("lt", "\(p)\(P.um)", P.kind == 0 ? S3P.small : S3P.lit, .above, edge: Y0 - 0.4, along: X0 + Double(p) / 2)
            live.label("lr", "\(q)\(P.um)", S3P.lit, .right, edge: X0 + Double(p) + 1.2, along: Y0 + Double(q) / 2)
        } else {
            S3P.tiles(&pic, "g\(p)x\(q)", x: X0, y: Y0, rows: q, cols: p)
            S3P.fence(&pic, "fence", x: X0, y: Y0, p: p, q: q)
            pic.label("lt", "\(p)\(P.um)", P.kind == 0 ? S3P.small : S3P.lit, .above, edge: Y0 - 0.4, along: X0 + Double(p) / 2)
            pic.label("lr", "\(q)\(P.um)", S3P.lit, .right, edge: X0 + Double(p) + 0.4, along: Y0 + Double(q) / 2)
        }
        if moving {
            if P.kind == 0 {
                M3.edge(&live, rows: true, x: X0, y: Y0, at: Y0 + Double(q), span: Double(p), held: s.grabbed)
                if s.grabbed { live.reads("\(p) + \(q) + \(p) + \(q) = \(2 * (p + q))") }
                if ring { KK.hintBox(&pic, "hr", x: X0 - 3, y: Y0, w: 2, h: Double(maxH)) }
                if spot { pic.line("sp", [(X0 - 0.5, Y0 + Double(P.q)), (X0 + Double(p) + 0.5, Y0 + Double(P.q))], ch, dashed: true) }
            } else {
                // where the corner can go: the fence's slant, dashed, or the rectangles the tiles make
                let sp = P.spots
                if P.kind == 1, let a = sp.first, let b = sp.last {
                    pic.line("slant", [(X0 + Double(a.0), Y0 + Double(a.1)), (X0 + Double(b.0), Y0 + Double(b.1))], .ink3, dashed: true)
                }
                for (i, c) in sp.enumerated() { pic.dot("spt\(i)", at: X0 + Double(c.0), Y0 + Double(c.1), radius: 0.3, .ink3) }
                live.dot("hold", at: X0 + Double(p), Y0 + Double(q), radius: s.grabbed ? 0.7 : 0.55)
                if s.grabbed { live.reads(P.kind == 1 ? "\(p) by \(q) · area \(p * q)" : "\(p) by \(q) · fence \(2 * (p + q))") }
                if ring { pic.circle("hr", at: X0 + Double(p), Y0 + Double(q), radius: 1.5, .chapter, dashed: true) }
                if spot { pic.circle("sp", at: X0 + Double(P.p), Y0 + Double(P.q), radius: 1.2, .chapter, dashed: true) }
            }
        } else if st == 1 {
            if ring { KK.hintBox(&pic, "hw", x: X0, y: Y0, w: Double(p), h: Double(q)) }
            if spot { S3P.count(&pic, "sp", "\(P.want)", x: X0 + Double(p) + 3, y: Y0 + Double(q) + 1) }
        }

        // beside it: both measures, then the record
        rec.word("ro\(p)_\(q)", "fence \(2 * (p + q)) · area \(p * q)", at: 0.4, 1, Record.words, anchor: UnitPoint(x: 0, y: 0.5))
        if st >= 1 {
            let box = M3.box("w", P.want, cells: 2, right: st == 2)
            switch P.kind {
            case 0: M7.row(&rec, "rec", [.n(p), .op("+"), box, .op("+"), .n(p), .op("+"), .n(q), .op("="), .n(P.P)], x: 0, line: 4)
            case 2: M7.row(&rec, "rec", [.n(p), .op("+"), .n(q), .op("+"), .n(p), .op("+"), .n(q), .op("="), box], x: 0, line: 4)
            default:
                if st == 1 { M7.row(&rec, "rec", [.n(p), .op("×"), .n(q), .op("="), box], x: 0, line: 4) }
                else {
                    // every garden this fence makes; the one made ringed
                    for (j, g) in P.spots.enumerated() {
                        let c: Sketch.Colour = g.0 == P.p ? ch : .ink, y = 4 + 3 * Double(j)
                        let toks: [M7.Tok] = [.n(g.0, c), .op("×", c), .n(g.1, c), .op("=", c), .n(g.0 * g.1, c)]
                        M7.row(&rec, "g\(g.0)", toks, x: 0, line: y)
                        if g.0 == P.p { rec.sketch.box("ringG", rec.R(-1, y - 1.5, M7.width(toks) + 2, 3), ch, width: Sketch.stroke) }
                    }
                }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, 0, X0 + Double(maxW) + 5, Y0 + Double(maxH) + 1))
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = PerimArea3.Parts(s.numbers), X0 = Self.X0, Y0 = Self.Y0, (p, q) = Self.dims(P, s)
        if P.kind == 0 {
            let start = Double(Self.startRows(P))
            return Hands(
                grab: { c in M3.onEdge(c, rows: true, x: X0, y: Y0, at: Y0 + Double(q), span: Double(p)) ? ["grab": 1, "n": Double(q)] : nil },
                drag: { c, h in var h = h; h["n"] = Double(max(1, min(P.maxRows, Int((c.y - Y0).rounded())))); return h },
                release: { h in
                    let k = (h["n"] ?? start).rounded()
                    guard k != Double(q) else { return HandMove(hand: ["n": k]) }
                    return HandMove(hand: ["n": k], missHand: ["n": k], set: [("d", k)], check: true)
                })
        }
        let spots = P.spots
        return Hands(
            grab: { c in hypot(c.x - (X0 + Double(p)), c.y - (Y0 + Double(q))) <= 2.5 ? ["grab": 1, "cp": Double(p), "cq": Double(q)] : nil },
            drag: { c, h in
                var best = (p, q), bd = Double.infinity
                for sp in spots { let d = hypot(c.x - (X0 + Double(sp.0)), c.y - (Y0 + Double(sp.1))); if d < bd { bd = d; best = sp } }
                return ["grab": 1, "cp": Double(best.0), "cq": Double(best.1)]
            },
            release: { h in
                let cp = Int((h["cp"] ?? Double(p)).rounded()), cq = Int((h["cq"] ?? Double(q)).rounded()), at: Numbers = ["cp": Double(cp), "cq": Double(cq)]
                guard cp != p || cq != q else { return HandMove(hand: at) }
                return HandMove(hand: at, missHand: at, set: [("d", Double(100 * cp + cq))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let P = PerimArea3.Parts(s.numbers), X0 = Self.X0, Y0 = Self.Y0, (p, q) = Self.dims(P, s)
        if P.kind == 0 { return [.drag(from: CGPoint(x: X0 + Double(p) / 2, y: Y0 + Double(q)), to: CGPoint(x: X0 + Double(p) / 2, y: Y0 + Double(P.q)))] }
        return [.drag(from: CGPoint(x: X0 + Double(p), y: Y0 + Double(q)), to: CGPoint(x: X0 + Double(P.p), y: Y0 + Double(P.q)))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard at(s) == 0 else { return nil }
        let P = PerimArea3.Parts(s.numbers)
        if P.kind == 0 { let k = Double(min(P.maxRows, P.q + 1)); return HandMove(hand: ["n": k], missHand: ["n": k], set: [("d", k)], check: true) }
        guard let sp = P.spots.first(where: { $0 != (P.p, P.q) && $0 != P.start }) ?? P.spots.first(where: { $0 != (P.p, P.q) }) else { return nil }
        let h: Numbers = ["cp": Double(sp.0), "cq": Double(sp.1)]
        return HandMove(hand: h, missHand: h, set: [("d", Double(100 * sp.0 + sp.1))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = PerimArea3.Parts(s.numbers)
        guard at(s) == 1 else { return nil }
        return ["w": Double(P.kind == 0 ? P.P - P.p : P.kind == 1 ? P.P : P.A)]
    }
}
