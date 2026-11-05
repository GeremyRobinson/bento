import SwiftUI

/// Equal parts of a shape on the paper, as in the preview (design/prototype/grade3-ch5.html, dShapeParts): a rectangle W × H
/// tiles of c squares (a square unit, 5 or 4 squares), its tiles faint. Strips: the ruler over the top snaps at every tile
/// line; while it moves the cuts repeat across, dashed, each part counts its squares under it and the words beside say
/// "2 parts of 12"; let go on b equal parts and they turn solid and tint ("fourths: 6 squares each"). Tap one part: it
/// lifts a square, its place dashed. Write `1 part = [1]/[4]` beside. Other shapes: the parts' edges in ink; tap each part
/// (it tints, its squares count on its middle tile); Yes or No beside; equal: `each part = [1]/[4]`.
///
/// Hand: strips "grab", "k" the ruler's columns a part; kept "up" the part lifted. Shapes "m" the parts tapped (bits),
/// "wrong" the choice picked wrong.
@MainActor
struct ShapeParts3Lesson: PaperLesson {
    static let X0 = 0.0, Y0 = 4.0
    var liveKeys: Set<String> { ["k"] }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Where the words and record beside the rectangle start.
    static func rx(_ P: ShapeParts3.Parts) -> Double { ((X0 + Double(P.W * P.c) + 3) / 5).rounded(.up) * 5 }

    /// A part's tiles, and the one its count sits on (the nearest its middle).
    static func tiles(_ rg: [[Int]], _ i: Int) -> [(Int, Int)] {
        var out: [(Int, Int)] = []
        for (r, row) in rg.enumerated() { for (j, v) in row.enumerated() where v == i { out.append((r, j)) } }
        return out
    }
    static func labTile(_ rg: [[Int]], _ i: Int) -> (Int, Int) {
        let t = tiles(rg, i)
        guard !t.isEmpty else { return (0, 0) }
        var mr = 0.0, mj = 0.0
        for q in t { mr += Double(q.0); mj += Double(q.1) }
        mr /= Double(t.count); mj /= Double(t.count)
        var best = t[0], bd = Double.infinity
        for q in t {
            let d = (Double(q.0) - mr) * (Double(q.0) - mr) + (Double(q.1) - mj) * (Double(q.1) - mj)
            if d < bd { bd = d; best = q }
        }
        return best
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = ShapeParts3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, c = Double(P.c)
        let L = Double(P.W) * c, Hh = Double(P.H) * c, rx = Self.rx(P), ry = Y0 + 1
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        let rg = P.regions
        if P.strips {
            let cutDone = st >= 1, k = cutDone ? P.k0 : Int((s.h("k") ?? Double(P.W)).rounded())
            let up = st >= 2 ? Int((s.run.kept["up"] ?? 0).rounded()) : -1
            let n = Int((Double(P.W) / Double(k)).rounded(.up))
            func span(_ j: Int) -> (Double, Double, Int) { let a = j * k, w = min(k, P.W - a); return (X0 + Double(a) * c, Double(w) * c, w) }
            if cutDone { for j in 0..<n where j != up { let (px, pw, _) = span(j); pic.fill("tp\(j)", col: px, row: Y0, w: pw, h: Hh, F3P.tint) } }
            S3P.tiles(&pic, "g", x: X0, y: Y0, rows: P.H, cols: P.W, c: c)
            // the cuts: dashed while the ruler moves, ink once they're equal
            if k < P.W {
                for a in stride(from: k, to: P.W, by: k) {
                    let x = X0 + Double(a) * c
                    if cutDone { pic.line("cut\(a)", [(x, Y0), (x, Y0 + Hh)]) }
                    else { live.line("dc\(a)_\(k)", [(x, Y0 - 0.6), (x, Y0 + Hh)], .ink2, dashed: true) }
                }
                // (each part counts its squares, under it)
                for j in 0..<n {
                    let (px, pw, w) = span(j)
                    if cutDone { pic.word("pc\(j)", "\(w * P.H)", at: px + pw / 2, Y0 + Hh + 1, F3P.lit) }
                    else { live.word("pc\(j)_\(k)_\(w)", "\(w * P.H)", at: px + pw / 2, Y0 + Hh + 1, F3P.lit) }
                }
            }
            if up >= 0 {
                // the part lifts a square, tinted; its place stays dashed
                let (px, pw, _) = span(up)
                F3P.hole(&pic, "hole", x: px, y: Y0, w: pw, h: Hh, top: Y0 + Hh - 1)
                F3P.lifted(&pic, "lp", x: px, y: Y0 - 1, w: pw, h: Hh, c: c)
            }
            if !cutDone {
                // the ruler: a handle on a stem over the top edge
                let hx = X0 + Double(k) * c
                live.line("rus", [(hx, Y0), (hx, Y0 - 3)], .chapter)
                live.dot("ruh", at: hx, Y0 - 3, radius: s.grabbed ? 0.7 : 0.55)
                let t = P.cutText(k)
                if !t.isEmpty { F3P.beside(&live, "ro\(t)", t, x: rx, y: ry); if s.grabbed { live.reads(t) } }
                if ring { KK.hintBox(&pic, "hr", x: X0, y: Y0 - 4, w: L, h: 3) }
                if spot { for a in stride(from: P.k0, to: P.W, by: P.k0) { pic.line("hs\(a)", [(X0 + Double(a) * c, Y0 - 0.6), (X0 + Double(a) * c, Y0 + Hh + 0.6)], .chapter, dashed: true) } }
            } else {
                F3P.beside(&pic, "rod", P.cutDone, x: rx, y: ry)
            }
            if st == 2 && ring { KK.hintBox(&pic, "hw", x: X0, y: Y0 - 1, w: L, h: Hh + 1) }
            if st == 2 && spot { for j in 0..<P.b { pic.word("hn\(j)", "\(j + 1)", at: X0 + (Double(j * P.k0) + 0.5) * c, Y0 + c / 2 - (j == up ? 1 : 0), F3P.smallLit) } }
            if st >= 2 { F3P.record(&rec, "rec", [.w("1 part")], top: "t", bottom: "b", (1, P.b), right: st == 9, x: rx, line: ry + 4) }
        } else {
            let m = Int((s.h("m") ?? 0).rounded()), sizes = P.sizes
            for i in 0..<P.b where st >= 1 || (m >> i) & 1 == 1 {
                for (r, j) in Self.tiles(rg, i) { pic.fill("tt\(r)_\(j)", col: X0 + Double(j) * c, row: Y0 + Double(r) * c, w: c, h: c, F3P.tint) }
            }
            S3P.tiles(&pic, "g", x: X0, y: Y0, rows: P.H, cols: P.W, c: c)
            // the parts' edges in ink, where two tiles of different parts meet
            var segs: [(CGPoint, CGPoint)] = []
            for r in 0..<P.H {
                for j in 0..<P.W {
                    if j + 1 < P.W && rg[r][j] != rg[r][j + 1] { segs.append((pic.P(X0 + Double(j + 1) * c, Y0 + Double(r) * c), pic.P(X0 + Double(j + 1) * c, Y0 + Double(r + 1) * c))) }
                    if r + 1 < P.H && rg[r][j] != rg[r + 1][j] { segs.append((pic.P(X0 + Double(j) * c, Y0 + Double(r + 1) * c), pic.P(X0 + Double(j + 1) * c, Y0 + Double(r + 1) * c))) }
                }
            }
            pic.sketch.segments("edges", segs, .ink, width: Sketch.stroke)
            for i in 0..<P.b where st >= 1 || (m >> i) & 1 == 1 {
                let (r, j) = Self.labTile(rg, i)
                pic.word("rc\(i)", "\(sizes[i])", at: X0 + (Double(j) + 0.5) * c, Y0 + (Double(r) + 0.5) * c, F3P.lit)
            }
            if st == 1 {
                let w = s.h("wrong")
                F3P.choice(&pic, "yes", x: rx, y: ry - 1, "Yes", wrong: w == 0)
                F3P.choice(&pic, "no", x: rx + 5, y: ry - 1, "No", wrong: w == 1)
                if ring { KK.hintBox(&pic, "hj", x: X0, y: Y0, w: L, h: Hh) }
            }
            if st == 2 && ring { KK.hintBox(&pic, "hw", x: X0, y: Y0, w: L, h: Hh) }
            if st == 2 && spot { F3P.beside(&pic, "hb", "\(P.b) parts", x: rx, y: ry, F3P.lit) }
            if st >= 2 && P.equal { F3P.record(&rec, "rec", [.w("each part")], top: "t", bottom: "b", (1, P.b), right: st == 9, x: rx, line: ry + 4) }
        }
        let ext = pic.R(X0, Y0 - 4, max(L, rx + 17 - X0), Hh + 6)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = ShapeParts3.Parts(s.numbers), st = at(s), rx = Self.rx(P)
        if st == 9 && !P.strips && !P.equal { return CGPoint(x: rx, y: Self.Y0) }
        return st >= 2 ? CGPoint(x: rx, y: Self.Y0 + 9) : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = ShapeParts3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, c = Double(P.c)
        let L = Double(P.W) * c, Hh = Double(P.H) * c, rx = Self.rx(P), W = P.W
        if P.strips {
            switch st {
            case 0:
                let k0 = Int((s.h("k") ?? Double(W)).rounded())
                return Hands(
                    grab: { q in
                        let hx = X0 + Double(k0) * c
                        return abs(q.x - hx) < 2 && q.y > Y0 - 5 && q.y < Y0 + 0.5 ? ["grab": 1, "k": Double(k0)] : nil
                    },
                    drag: { q, h in var h = h; h["k"] = Double(max(1, min(W, Int(((q.x - X0) / c).rounded())))); return h },
                    release: { h in
                        let k = Int((h["k"] ?? Double(W)).rounded())
                        guard k < W else { return HandMove(hand: ["k": Double(W)]) }
                        return HandMove(hand: ["k": Double(k)], missHand: ["k": Double(k)], set: [("k", Double(k))], check: true)
                    })
            case 1:
                return Hands(tap: { q in
                    guard q.x >= X0, q.x <= X0 + L, q.y >= Y0, q.y <= Y0 + Hh else { return nil }
                    let j = min(P.b - 1, Int((q.x - X0) / (Double(P.k0) * c)))
                    return HandMove(hand: [:], set: [("p", Double(j + 1))], keep: ["up": Double(j)], check: true)
                })
            default: return nil
            }
        }
        switch st {
        case 0:
            let m = Int((s.h("m") ?? 0).rounded()), rg = P.regions
            return Hands(tap: { q in
                guard q.x >= X0, q.x < X0 + L, q.y >= Y0, q.y < Y0 + Hh else { return nil }
                let i = rg[min(P.H - 1, Int((q.y - Y0) / c))][min(W - 1, Int((q.x - X0) / c))], m2 = m | (1 << i)
                if m2 == (1 << P.b) - 1 { return HandMove(hand: ["m": Double(m2)], missHand: ["m": Double(m2)], set: [("n", Double(P.b))], check: true) }
                return HandMove(hand: ["m": Double(m2)])
            })
        case 1:
            return Hands(tap: { q in
                guard q.y >= Y0 - 0.3, q.y <= Y0 + 2.3 else { return nil }
                let v: Double? = q.x >= rx - 0.3 && q.x <= rx + 4.3 ? 0 : q.x >= rx + 4.7 && q.x <= rx + 9.3 ? 1 : nil
                return v.map { HandMove(hand: [:], missHand: ["wrong": $0], set: [("c", $0)], check: true) }
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = ShapeParts3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, c = Double(P.c), rx = Self.rx(P)
        if P.strips {
            switch st {
            case 0:
                let k = (s.h("k") ?? Double(P.W)).rounded()
                return [.drag(from: CGPoint(x: X0 + k * c, y: Y0 - 3), to: CGPoint(x: X0 + Double(P.k0) * c, y: Y0 - 3))]
            case 1: return [.tap(.picture(CGPoint(x: X0 + Double(P.k0) * c / 2, y: Y0 + Double(P.H) * c / 2)))]
            default: return []
            }
        }
        switch st {
        case 0:
            let m = Int((s.h("m") ?? 0).rounded()), rg = P.regions
            var out: [GhostMove] = []
            for i in 0..<P.b where (m >> i) & 1 == 0 {
                let (r, j) = Self.labTile(rg, i)
                out.append(.tap(.picture(CGPoint(x: X0 + (Double(j) + 0.5) * c, y: Y0 + (Double(r) + 0.5) * c))))
            }
            return out
        case 1: return [.tap(.picture(CGPoint(x: rx + (P.equal ? 2 : 7), y: Y0 + 1)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = ShapeParts3.Parts(s.numbers), st = at(s)
        if P.strips && st == 0 {
            let k = P.k0 + 1 < P.W ? P.k0 + 1 : max(1, P.k0 - 1)
            return HandMove(hand: ["k": Double(k)], missHand: ["k": Double(k)], set: [("k", Double(k))], check: true)
        }
        if !P.strips && st == 1 { let v: Double = P.equal ? 1 : 0; return HandMove(hand: [:], missHand: ["wrong": v], set: [("c", v)], check: true) }
        return nil
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = ShapeParts3.Parts(s.numbers)
        return at(s) == 2 ? ["t": Double(P.b), "b": 1] : nil
    }
}
