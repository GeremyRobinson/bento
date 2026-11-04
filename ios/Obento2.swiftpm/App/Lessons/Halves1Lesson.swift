import SwiftUI

/// Halves and fourths on the paper, as in the preview (design/prototype/grade1-ch6.html, dHalves, dCompareParts): the shape big
/// (a rectangle 40 × 24, a square 30 × 30, a circle 30 across), every half and fourth a whole number of squares. Cut with the
/// ruler: drag edge to edge (straight down or across, snapped to a square; corner to corner on the square; through the middle of
/// the circle); the parts' widths read out under them, their heights beside ("the same" for a diagonal or a circle). Not equal:
/// measured, the cut shows red and goes. Then tap the parts' name (in a row under it, or a column beside a square or circle), then
/// tap parts to shade them. The record: `3 fourths shaded`, `4 fourths make the whole`. The compare kind: the shape twice, cut in
/// halves and in fourths: tap a bigger piece.
///
/// Kept: the cuts "c0"… and "nc" (Halves1's numbers), "bad" a cut that wasn't equal; "wrong" the name tapped wrong; "s<j>" part j
/// shaded; a compare's "lit" (the half tapped) and "badp" (the fourth). Hand: "grab", "ax", "ay", "bx", "by".
@MainActor
struct Halves1Lesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { ["bx", "by"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let wrongTint = Sketch.Colour.hex(0xE9B7B2, 0x6B2E2A)

    /// The cuts that make the parts the words ask for (the layout measures with them; Show me makes them).
    static func asked(_ P: Halves1.Parts) -> [Int] {
        let g = P.g, W = Int(g.W), H = Int(g.H)
        if g.kind == 2 { return P.parts == 2 ? [Halves1.down(W / 2)] : [Halves1.down(W / 2), Halves1.across(W / 2)] }
        if P.parts == 2 { return [[Halves1.down(W / 2)], [Halves1.across(H / 2)], [Halves1.d0]][P.cut] }
        switch P.cut {
        case 1: return W % 4 == 0 ? [Halves1.down(W / 4), Halves1.down(W / 2), Halves1.down(3 * W / 4)] : [Halves1.across(H / 4), Halves1.across(H / 2), Halves1.across(3 * H / 4)]
        case 2: return [Halves1.d0, Halves1.d1]
        default: return [Halves1.down(W / 2), Halves1.across(H / 2)]
        }
    }
    private func cuts(_ s: PaperState, _ P: Halves1.Parts) -> [Int] {
        let n = Int(s.run.kept["nc"] ?? 0)
        if at(s) > 0 && n == 0 { return Self.asked(P) }
        return (0..<n).map { Int(s.run.kept["c\($0)"] ?? 0) }
    }
    /// The names and the record beside the shape (under the rectangle it showed at 69%).
    private func side(_ P: Halves1.Parts) -> Bool { true }
    private func names(_ P: Halves1.Parts) -> [CGRect] {
        side(P) ? KS.rects(3, x: P.g.W + 5, y: 5, w: 15, .column) : KS.rects(3, x: 0, y: P.g.H + 5, w: 12, .row).enumerated().map { $1.offsetBy(dx: Double($0) * 3, dy: 0) }
    }
    private func recAt(_ P: Halves1.Parts) -> CGPoint { side(P) ? CGPoint(x: P.g.W + 5, y: 5) : CGPoint(x: 0, y: P.g.H + 5) }
    static func outline(_ g: Halves1.Geom) -> [Pt] {
        g.kind == 2 ? KS.circlePts((g.cx, g.cy), g.r, 72) : [(g.x0, 0), (g.x0 + g.W, 0), (g.x0 + g.W, g.H), (g.x0, g.H)]
    }
    static func cutLine(_ pen: inout GridPen, _ id: String, _ g: Halves1.Geom, _ c: Int, _ colour: Sketch.Colour, dashed: Bool = false) {
        let (a, b) = Halves1.line(g, c)
        pen.line(id, [a, b], colour, dashed: dashed)
    }
    /// The readouts of a set of cuts: each part's width under it, each row's height beside it; "the same" for a diagonal or a circle.
    static func readouts(_ pen: inout GridPen, _ id: String, _ g: Halves1.Geom, _ cs: [Int]) {
        guard !cs.isEmpty else { return }
        if g.kind == 2 || cs.contains(where: { $0 >= 300 }) { A1.note(&pen, "\(id)same", "the same", x: g.x0 + g.W / 2, y: g.H + 1.5, centred: true); return }
        let cw = Halves1.sizes(cs, across: false, full: g.W), rh = Halves1.sizes(cs, across: true, full: g.H)
        if cw.count > 1 { var x = g.x0; for (i, w) in cw.enumerated() { A1.note(&pen, "\(id)w\(i)_\(Int(x))", "\(w)", x: x + Double(w) / 2, y: g.H + 1.5, centred: true); x += Double(w) } }
        if rh.count > 1 { var y = 0.0; for (i, h) in rh.enumerated() { A1.note(&pen, "\(id)h\(i)_\(Int(y))", "\(h)", x: g.x0 + g.W + 1, y: y + Double(h) / 2); y += Double(h) } }
    }
    /// A finger's drag as a cut: straight down or across (snapped to a square; through the middle of a circle), or the square's
    /// corner to corner. nil: too short to be a cut; code −1: not straight; −2: not edge to edge.
    static func snap(_ g: Halves1.Geom, _ a: CGPoint, _ b: CGPoint) -> Int? {
        let dx = b.x - a.x, dy = b.y - a.y, ax = abs(dx), ay = abs(dy)
        if hypot(dx, dy) < 3 { return nil }
        if g.kind == 1 {
            func near(_ p: CGPoint, _ c: Pt) -> Bool { hypot(p.x - c.0, p.y - c.1) < 4 }
            let TL = (g.x0, 0.0), TR = (g.x0 + g.W, 0.0), BR = (g.x0 + g.W, g.H), BL = (g.x0, g.H)
            if (near(a, TL) && near(b, BR)) || (near(a, BR) && near(b, TL)) { return Halves1.d0 }
            if (near(a, TR) && near(b, BL)) || (near(a, BL) && near(b, TR)) { return Halves1.d1 }
        }
        if ax < 0.35 * ay {
            if ay / g.H < 0.6 { return -2 }
            let at = Int(max(1, min(g.W - 1, ((a.x + b.x) / 2 - g.x0).rounded())))
            return Halves1.down(g.kind == 2 && abs(at - Int(g.r)) <= 2 ? Int(g.r) : at)
        }
        if ay < 0.35 * ax {
            if ax / g.W < 0.6 { return -2 }
            let at = Int(max(1, min(g.H - 1, ((a.y + b.y) / 2).rounded())))
            return Halves1.across(g.kind == 2 && abs(at - Int(g.r)) <= 2 ? Int(g.r) : at)
        }
        return -1
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Halves1.Parts(s.numbers)
        if P.compare { return drawCompare(s, P) }
        let st = at(s), g = P.g, cs = cuts(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let parts = Halves1.parts(g, cs), out = Self.outline(g)
        let shaded = st == 3 ? Array(0..<P.shaded) : parts.indices.filter { (s.run.kept["s\($0)"] ?? 0) != 0 }
        // each part filled once (fills laid over fills flicker): the shaded ones stronger
        for (j, p) in parts.enumerated() { let on = st >= 2 && shaded.contains(j); KS.poly(&pic, "pf\(cs.sorted())\(j)\(on)", p, on ? KS.lit : KS.fill) }
        KS.outline(&pic, "shapeo", out, .ink)
        for c in cs { Self.cutLine(&pic, "cut\(c)", g, c, .chapter) }
        if st == 0 {
            if !s.grabbed, let b = s.run.kept["bad"], b >= 0 { Self.cutLine(&pic, "bad\(Int(b))", g, Int(b), KS.red) }
            var show = cs
            if s.grabbed, let ax = s.h("ax"), let ay = s.h("ay"), let bx = s.h("bx"), let by = s.h("by"),
               let c = Self.snap(g, CGPoint(x: ax, y: ay), CGPoint(x: bx, y: by)), c > 0, !cs.contains(c) {
                Self.cutLine(&live, "lv", g, c, .chapter, dashed: true); show.append(c)
                let n = Halves1.parts(g, show).count
                live.reads(Shapes1.pl(n, "part", "parts"))
            }
            Self.readouts(&live, "ro", g, show)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: -1, w: g.W + 2, h: g.H + 2) }
            if s.on("spot") { for c in Self.asked(P) where !cs.contains(c) { Self.cutLine(&pic, "spot\(c)", g, c, .chapter, dashed: true) } }
        } else if st < 3 {
            Self.readouts(&pic, "ro", g, cs)
        }
        if st == 1 {
            let wrong = s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", Halves1.Parts.names, names(P), wrong: wrong, spot: s.on("spot") ? P.right : nil, ring: s.on("ring") && !s.on("spot"))
        }
        if st == 2 {
            let n = shaded.count
            if n > 0 { A1.note(&pic, "ns\(n)", "\(n) \(n == 1 ? P.one : P.name)", x: g.x0 + g.W + 1 + (cs.contains { $0 / 100 == 2 } ? 3 : 0), y: g.H / 2) }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: -1, w: g.W + 2, h: g.H + 2) }
            if s.on("spot"), let j = parts.indices.first(where: { !shaded.contains($0) }) { KS.outline(&pic, "spot\(j)", parts[j], .chapter, dashed: true) }
        }
        if st == 3 {
            let r = recAt(P)
            for (k, line) in P.record.enumerated() { KS.line(&pic, "rec\(k)", [.n(line.0, .chapter), .w(line.1)], x: r.x, line: r.y + 1 + 3 * Double(k)) }
        }
        let right = side(P) ? g.W + 5 + 15 + 1 : max(g.W + 4, M7.width([.n(4), .w("fourths make the whole")]) + 1, 3 * 15)
        let bottom = side(P) ? max(g.H, 5 + 14) + 1 : g.H + 10
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(-1, -1, right + 2, bottom + 1))
    }

    private func compareGeom(_ P: Halves1.Parts) -> (H: Halves1.Geom, F: Halves1.Geom, hc: [Int], fc: [Int]) {
        let gA = Halves1.geom(P.shape, small: true, x0: 0), gB = Halves1.geom(P.shape, small: true, x0: P.shape == 0 ? 35 : 30)
        let H = P.left == 0 ? gA : gB, F = P.left == 0 ? gB : gA
        let hc = [P.shape == 2 ? Halves1.down(Int(H.W) / 2) : P.hcut == 2 ? Halves1.d0 : P.hcut == 1 ? Halves1.across(Int(H.H) / 2) : Halves1.down(Int(H.W) / 2)]
        let fc = P.shape == 2 ? [Halves1.down(Int(F.W) / 2), Halves1.across(Int(F.W) / 2)] : P.fcut == 2 ? [Halves1.d0, Halves1.d1] : [Halves1.down(Int(F.W) / 2), Halves1.across(Int(F.H) / 2)]
        return (H, F, hc, fc)
    }
    private func drawCompare(_ s: PaperState, _ P: Halves1.Parts) -> PaperDrawing {
        let (H, F, hc, fc) = compareGeom(P), st = at(s)
        var pic = GridPen()
        let lit = st == 1 ? Int(s.run.kept["lit"] ?? 0) : nil, bad = st == 0 ? s.run.kept["badp"].map { Int($0) } : nil
        for (g, cs, nm, isH) in [(H, hc, "halves", true), (F, fc, "fourths", false)] {
            let out = Self.outline(g), parts = Halves1.parts(g, cs)
            for (j, p) in parts.enumerated() {
                let c: Sketch.Colour = isH && j == lit ? KS.lit : !isH && j == bad ? Self.wrongTint : KS.fill
                KS.poly(&pic, "o\(nm)\(j)\(c == KS.fill ? 0 : 1)", p, c)
            }
            KS.outline(&pic, "ol\(nm)", out, .ink)
            for c in cs { Self.cutLine(&pic, "c\(nm)\(c)", g, c, .chapter) }
            A1.note(&pic, "nm\(nm)", nm, x: g.x0 + g.W / 2, y: g.H + 2, centred: true)
            if isH && st == 0 {
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: g.x0 - 1, y: -1, w: g.W + 2, h: g.H + 2) }
                if s.on("spot") { KS.outline(&pic, "spot", parts[0], .chapter, dashed: true) }
            }
        }
        if st == 1 { KS.line(&pic, "rec", [.w("A half is bigger than a fourth.")], x: 0, line: H.H + 5) }
        return PaperDrawing(picture: pic.sketch, extent: pic.R(-1, -1, max(H.x0, F.x0) + H.W + 2, H.H + (st == 1 ? 7 : 4)))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Halves1.Parts(s.numbers), g = P.g, st = at(s)
        if P.compare {
            guard st == 0 else { return nil }
            let (H, F, hc, fc) = compareGeom(P), ph = Halves1.parts(H, hc), pf = Halves1.parts(F, fc)
            return Hands(tap: { q in
                if let j = ph.firstIndex(where: { KS.inside((q.x, q.y), $0) }) { return HandMove(hand: nil, missHand: nil, set: [("b", 1)], keep: ["lit": Double(j)], check: true) }
                if let j = pf.firstIndex(where: { KS.inside((q.x, q.y), $0) }) { return HandMove(hand: nil, missHand: nil, set: [("b", -1)], keep: ["badp": Double(j)], check: true) }
                return nil
            })
        }
        switch st {
        case 0:
            let cs = cuts(s, P)
            return Hands(
                grab: { q in
                    guard q.x >= g.x0 - 3, q.y >= -3, q.x <= g.x0 + g.W + 3, q.y <= g.H + 3 else { return nil }
                    return ["grab": 1, "ax": q.x, "ay": q.y, "bx": q.x, "by": q.y]
                },
                drag: { q, h in var h = h; h["bx"] = q.x; h["by"] = q.y; return h },
                release: { h in
                    let a = CGPoint(x: h["ax"] ?? 0, y: h["ay"] ?? 0), b = CGPoint(x: h["bx"] ?? 0, y: h["by"] ?? 0)
                    guard let c = Self.snap(g, a, b) else { return HandMove(hand: [:]) }
                    if c < 0 { return HandMove(hand: [:], missHand: [:], set: [("k", Double(c))], check: true) }
                    if cs.contains(c) { return HandMove(hand: [:]) }
                    guard let r = Halves1.cut(P, cs, c) else {
                        return HandMove(hand: [:], missHand: [:], set: [("k", Double(Halves1.missCode(P, cs, c)))], keep: ["bad": Double(c)], check: true)
                    }
                    var keep: Numbers = ["nc": Double(r.cuts.count), "bad": -1]
                    for (i, c) in r.cuts.enumerated() { keep["c\(i)"] = Double(c) }
                    return HandMove(hand: [:], missHand: [:], set: r.done ? [("k", 1)] : [], keep: keep, check: r.done)
                })
        case 1:
            let r = names(P)
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": j == P.right ? -1 : Double(j)], check: true)
            })
        case 2:
            let parts = Halves1.parts(g, cuts(s, P))
            return Hands(tap: { q in
                guard let j = parts.firstIndex(where: { KS.inside((q.x, q.y), $0) }) else { return nil }
                let on = (s.run.kept["s\(j)"] ?? 0) != 0
                let n = parts.indices.filter { $0 == j ? !on : (s.run.kept["s\($0)"] ?? 0) != 0 }.count
                return HandMove(hand: nil, missHand: nil, set: n == P.shaded ? [("s", Double(n))] : [], keep: ["s\(j)": on ? 0 : 1], check: n == P.shaded)
            })
        default: return nil
        }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Halves1.Parts(s.numbers)
        if P.compare { return at(s) == 1 ? CGPoint(x: 40, y: compareGeom(P).H.H + 4) : nil }
        guard at(s) == 3, side(P) else { return nil }
        let r = recAt(P); return CGPoint(x: r.x, y: r.y + 10)
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Halves1.Parts(s.numbers), g = P.g, st = at(s)
        func mid(_ p: [Pt]) -> GhostMove { let c = KS.centroid(p); return .tap(.picture(CGPoint(x: c.0, y: c.1))) }
        if P.compare {
            guard st == 0 else { return [] }
            let (H, _, hc, _) = compareGeom(P)
            return [mid(Halves1.parts(H, hc)[0])]
        }
        switch st {
        case 0:
            let made = cuts(s, P)
            return Self.asked(P).filter { !made.contains($0) }.map { c in
                let (a, b) = Halves1.line(g, c), u = (b.0 - a.0, b.1 - a.1), l = max(1e-9, hypot(u.0, u.1)), e = (u.0 / l * 0.6, u.1 / l * 0.6)
                return .drag(from: CGPoint(x: a.0 + e.0, y: a.1 + e.1), to: CGPoint(x: b.0 - e.0, y: b.1 - e.1))
            }
        case 1: let r = names(P)[P.right]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case 2:
            let parts = Halves1.parts(g, cuts(s, P)), on = parts.indices.filter { (s.run.kept["s\($0)"] ?? 0) != 0 }
            var moves = on.dropFirst(min(on.count, P.shaded)).map { mid(parts[$0]) }
            moves += parts.indices.filter { !on.contains($0) }.prefix(max(0, P.shaded - on.count)).map { mid(parts[$0]) }
            return moves
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Halves1.Parts(s.numbers), g = P.g, st = at(s)
        if P.compare { return st == 0 ? HandMove(hand: nil, missHand: nil, set: [("b", -1)], keep: ["badp": 0], check: true) : nil }
        switch st {
        case 0:
            let c = g.kind == 2 ? Halves1.down(10) : Halves1.down(Int(g.W) / 2 - 5)
            return HandMove(hand: [:], missHand: [:], set: [("k", Double(Halves1.missCode(P, [], c)))], keep: ["bad": Double(c)], check: true)
        case 1:
            let j = P.right == 1 ? 2 : 1
            return HandMove(hand: nil, missHand: nil, set: [("n", Double(j))], keep: ["wrong": Double(j)], check: true)
        default: return nil
        }
    }
}
