import SwiftUI

/// Sides and corners on the paper, as in the preview (design/prototype/grade2-ch7.html, dShapes): one square is a step of a side,
/// every corner on a grid crossing. Name it: the shape (18–30 squares across) from the picture's corner, the readout beside it at
/// its middle (`3 corners · 3 sides`); tap each corner (it gets a dot; two dotted corners light the side between) or trace each side
/// (a finger near a side covers the part under it, 80% of it with both ends traces it, on a band), then Check under it. The four
/// name blocks under it, each starting on a block line; tap its name. Draw it: a dashed patch 30 × 22; tap crossings to place
/// corners (each draws the side from the last), tap the first to close; a placed corner can be dragged. The record where the
/// blocks were, `5 sides, 5 corners: pentagon`, Next problem beside it.
///
/// Kept: "k<j>" corner j tapped, "s<j>" side j traced; "wn" the name tapped wrong; the drawing "n", "x<i>", "y<i>", "closed",
/// "bad" (its miss code). Hand: "grab", the sides' covered samples "m<j>", "d<j>" traced while held, "lx", "ly", "any"; a corner
/// held "hj" with "hx", "hy".
@MainActor
struct Sides2Lesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { Set(["lx", "ly", "any", "hx", "hy"] + (0..<7).map { "m\($0)" }) }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The name blocks' widths (the preview's blockW: a whole number of blocks less a square).
    static let blockW = [9.0, 14, 9, 9]
    static func names(y: Double) -> [CGRect] {
        var out: [CGRect] = [], x = 0.0
        for w in blockW { out.append(CGRect(x: x, y: y, width: w, height: 4)); x += w + 1 }
        return out
    }
    /// A shape to show for each count, inside the 30 × 22 patch (Show me and a second miss's hint).
    static func example(_ n: Int) -> [Pt] {
        switch n {
        case 3: return [(4, 20), (26, 20), (12, 2)]
        case 4: return [(3, 4), (24, 2), (27, 19), (6, 20)]
        case 5: return [(15, 1), (28, 9), (23, 21), (7, 21), (2, 9)]
        default: return [(2, 11), (8, 1), (22, 1), (28, 11), (22, 21), (8, 21)]
        }
    }
    static let say = KK.words

    @MainActor struct Lay {
        let P: Sides2.Parts
        var W: Double { ceil(P.w) }
        var H: Double { ceil(P.h) }
        /// The readout's column, beside the shape.
        var RX: Double { W + 2 }
        /// The blocks' row (Check, the names), then the record's.
        var REC: Double { H + 3 }
        init(_ n: Numbers) { P = Sides2.Parts(n) }
    }

    // MARK: what's counted
    private func sides(_ P: Sides2.Parts) -> [(Pt, Pt)] { P.pts.indices.map { (P.pts[$0], P.pts[($0 + 1) % P.n]) } }
    private func tapped(_ s: PaperState, _ j: Int) -> Bool { (s.run.kept["k\(j)"] ?? 0) != 0 }
    private func traced(_ s: PaperState, _ j: Int) -> Bool { (s.run.kept["s\(j)"] ?? 0) != 0 || (s.grabbed && (s.h("d\(j)") ?? 0) != 0) }
    private func litCorner(_ s: PaperState, _ P: Sides2.Parts, _ j: Int) -> Bool { tapped(s, j) || (traced(s, j) && traced(s, (j + P.n - 1) % P.n)) }
    private func litSide(_ s: PaperState, _ P: Sides2.Parts, _ j: Int) -> Bool { traced(s, j) || (tapped(s, j) && tapped(s, (j + 1) % P.n)) }
    private func counts(_ s: PaperState, _ P: Sides2.Parts) -> (c: Int, s: Int) {
        var c = 0, d = 0
        for j in 0..<P.n { if litCorner(s, P, j) { c += 1 }; if litSide(s, P, j) { d += 1 } }
        return (c, d)
    }
    private func corners(_ s: PaperState) -> [Pt] { DrawShape.corners(s.run.kept).map { (Double($0.0), Double($0.1)) } }
    /// The drawing as it is now: a corner held follows the finger.
    private func drawing(_ s: PaperState) -> [Pt] {
        var cs = corners(s)
        if s.grabbed, let j = s.h("hj").map({ Int($0) }), cs.indices.contains(j), let x = s.h("hx"), let y = s.h("hy") { cs[j] = (x, y) }
        return cs
    }
    /// The facts the name is judged by: the shape's, or the drawing's.
    private func facts(_ s: PaperState, _ P: Sides2.Parts) -> Sides2.Facts {
        if !P.draw { return Sides2.facts(P.pts) }
        let cs = corners(s)
        return Sides2.facts(cs.count >= 3 ? cs : Self.example(P.n))
    }
    private func record(_ P: Sides2.Parts) -> [M7.Tok] { [.n(P.n, .chapter), .w("sides,"), .n(P.n, .chapter), .w("corners: \(P.shapeName)")] }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let L = Lay(s.numbers)
        switch at(s) {
        case 0: return L.P.draw ? nil : CGPoint(x: 0, y: L.REC)
        case 2: return CGPoint(x: EG2.ceil5(M7.width(record(L.P)) + 1), y: L.REC)
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let L = Lay(s.numbers), P = L.P, st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        var actions: [String] = []
        if !P.draw {
            let sd = sides(P), done = st > 0
            if done { KS.poly(&pic, "fill", P.pts, KS.fill) }
            for (j, e) in sd.enumerated() {
                let lit = done || litSide(s, P, j)
                if lit { KS.poly(&pic, "bd\(j)", KS.band(e.0, e.1), KS.fill) }
                pic.line("sd\(j)\(lit ? "L" : "")", [e.0, e.1], lit ? .chapter : .ink)
                // what the finger covers now
                if !lit, s.grabbed, let m = s.h("m\(j)"), m > 0 {
                    let bits = (0..<25).filter { (Int(m) >> $0) & 1 == 1 }
                    if let a = bits.first, let b = bits.last, b > a {
                        func pt(_ t: Int) -> Pt { (e.0.0 + (e.1.0 - e.0.0) * Double(t) / 24, e.0.1 + (e.1.1 - e.0.1) * Double(t) / 24) }
                        KS.poly(&live, "tr\(j)", KS.band(pt(a), pt(b)), .tint(0.3))
                    }
                }
            }
            for j in 0..<P.n where done || litCorner(s, P, j) { pic.dot("cd\(j)", at: P.pts[j].0, P.pts[j].1, radius: 0.45, .chapter, over: true) }
            let n = counts(s, P)
            if st == 0 {
                if n.c > 0 || n.s > 0 {
                    let ro = "\(G2.count(n.c, "corner")) · \(G2.count(n.s, "side"))"
                    TMK.readout(&pic, ro, x: L.RX, y: L.H / 2)
                    if s.grabbed { live.reads(ro) }
                }
                if n.c > 0 { actions = ["Check"] }
                if ring { KK.hintBox(&pic, "hr", x: -1, y: -1, w: L.W + 2, h: L.H + 2) }
                if spot, let j = (0..<P.n).first(where: { !litCorner(s, P, $0) }) { KK.hint(&pic, "spot\(j)", P.pts[j].0, P.pts[j].1, radius: 1.6) }
            }
        } else {
            let cs = drawing(s), closed = (s.run.kept["closed"] ?? 0) != 0 || st > 0, bad = (s.run.kept["bad"] ?? 0) != 0 && st == 0
            if st == 0 { KS.outline(&pic, "patch", [(0, 0), (Sides2.PW, 0), (Sides2.PW, Sides2.PH), (0, Sides2.PH)], .ink3, dashed: true) }
            let c: Sketch.Colour = bad ? KS.red : .chapter, key = cs.map { "\(Int($0.0)),\(Int($0.1))" }.joined(separator: "_")
            let held = s.grabbed && s.h("hj") != nil
            var pen = held ? live : pic
            if closed && !bad && cs.count >= 3 && st > 0 { KS.poly(&pen, "dfill\(key)", cs, KS.fill) }
            if cs.count > 1 { pen.line("dl\(key)\(bad)", closed && cs.count >= 3 ? cs + [cs[0]] : cs, c) }
            for (j, p) in cs.enumerated() { pen.dot("dc\(j)_\(Int(p.0)),\(Int(p.1))\(bad)", at: p.0, p.1, radius: 0.45, c, over: true) }
            if held { live = pen } else { pic = pen }
            if st == 0 && cs.count > 1 {
                let k = closed && cs.count >= 3 ? Sides2.facts(cs).n : cs.count - 1
                TMK.readout(&pic, G2.count(k, "side"), x: Sides2.PW + 2, y: Sides2.PH / 2)
                if held { live.reads(G2.count(k, "side")) }
            }
            if st == 0 {
                if ring { KK.hintBox(&pic, "hr", x: -1, y: -1, w: Sides2.PW + 2, h: Sides2.PH + 2) }
                if spot { KS.outline(&pic, "spot", Self.example(P.n), .chapter, dashed: true) }
            }
        }
        if st == 1 {
            let wn = s.run.kept["wn"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", Sides2.names, Self.names(y: L.REC), wrong: wn, spot: spot ? P.n - 3 : nil, ring: ring)
        }
        if st == 2 { KS.line(&pic, "rec", record(P), x: 0, line: L.REC + 2) }
        let roW = KK.width(P.draw ? "6 sides" : "6 corners · 6 sides", KK.words)
        var right = max(L.RX + roW, 44)
        if st == 2 { right = max(right, EG2.ceil5(M7.width(record(P)) + 1) + 10) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: actions, extent: pic.R(-1, -1, right + 2, L.REC + 6))
    }

    /// The finger at q covers the samples of each untraced side near it; a side 80% covered, both ends, is traced.
    private func cover(_ P: Sides2.Parts, _ h: inout Numbers, _ q: Pt, _ s: PaperState) {
        for (j, e) in sides(P).enumerated() where (s.run.kept["s\(j)"] ?? 0) == 0 && (h["d\(j)"] ?? 0) == 0 {
            var best = -1, bd = 1.6
            for t in 0...24 {
                let u = Double(t) / 24, c = (e.0.0 + (e.1.0 - e.0.0) * u, e.0.1 + (e.1.1 - e.0.1) * u), d = hypot(c.0 - q.0, c.1 - q.1)
                if d < bd { bd = d; best = t }
            }
            guard best >= 0 else { continue }
            let m = Int(h["m\(j)"] ?? 0) | (1 << best)
            h["m\(j)"] = Double(m); h["any"] = 1
            let bits = (0..<25).filter { (m >> $0) & 1 == 1 }
            if bits.count >= 20 && bits.contains(where: { $0 <= 2 }) && bits.contains(where: { $0 >= 22 }) { h["d\(j)"] = 1 }
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let L = Lay(s.numbers), P = L.P, st = at(s)
        if st == 1 {
            let r = Self.names(y: L.REC), f = facts(s, P)
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("m", Double(Sides2.pickCode(f, j)))], keep: ["wn": j == P.n - 3 ? -1 : Double(j)], check: true)
            })
        }
        guard st == 0 else { return nil }
        if !P.draw {
            let n = counts(s, P).c
            return Hands(
                tap: { q in
                    guard let j = P.pts.indices.first(where: { hypot(P.pts[$0].0 - q.x, P.pts[$0].1 - q.y) < 1.6 }) else { return nil }
                    if litCorner(s, P, j) { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], check: true) }
                    return HandMove(hand: nil, missHand: nil, keep: ["k\(j)": 1])
                },
                grab: { q in
                    let near = Shapes1.polyDist((q.x, q.y), P.pts) <= 2
                    guard near else { return nil }
                    var h: Numbers = ["grab": 1, "lx": q.x, "ly": q.y]
                    cover(P, &h, (q.x, q.y), s)
                    return h
                },
                drag: { q, h in
                    var h = h
                    let a = (h["lx"] ?? q.x, h["ly"] ?? q.y), d = hypot(q.x - a.0, q.y - a.1), k = max(1, Int(d / 0.4))
                    for i in 1...k { let u = Double(i) / Double(k); cover(P, &h, (a.0 + (q.x - a.0) * u, a.1 + (q.y - a.1) * u), s) }
                    h["lx"] = q.x; h["ly"] = q.y
                    return h
                },
                release: { h in
                    var keep: Numbers = [:]
                    for j in 0..<P.n where (h["d\(j)"] ?? 0) != 0 { keep["s\(j)"] = 1 }
                    return HandMove(hand: [:], keep: keep)
                },
                actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [("c", Double(n))], check: true) }])
        }
        // drawing: tap crossings in the patch; tap the first to close; a placed corner can be dragged
        let W = Sides2.PW, H = Sides2.PH, cs0 = corners(s), bad = Int(s.run.kept["bad"] ?? 0), closed = (s.run.kept["closed"] ?? 0) != 0
        func keep(_ cs: [Pt], closed: Bool, code: Int) -> Numbers {
            var k = DrawShape.keep(cs.map { (Int($0.0), Int($0.1)) }, closed: closed); k["bad"] = code == 1 ? 0 : Double(code); return k
        }
        func snap(_ q: CGPoint) -> Pt { (min(W, max(0, q.x.rounded())), min(H, max(0, q.y.rounded()))) }
        return Hands(
            tap: { q in
                guard q.x >= -0.4, q.x <= W + 0.4, q.y >= -0.4, q.y <= H + 0.4 else { return nil }
                let c = snap(q)
                var cs = cs0
                if bad != 0 || closed { cs = [] }
                if cs.count >= 3 && c == cs[0] {
                    let code = Sides2.drawn(P.n, cs)
                    return HandMove(hand: nil, missHand: nil, set: [("d", Double(code))], keep: keep(cs, closed: true, code: code), check: true)
                }
                if cs.contains(where: { $0 == c }) { return nil }
                return HandMove(hand: nil, missHand: nil, keep: keep(cs + [c], closed: false, code: 1))
            },
            grab: { q in
                guard bad == 0 || bad == -2, let j = cs0.firstIndex(where: { hypot($0.0 - q.x, $0.1 - q.y) < 0.9 }) else { return nil }
                return ["grab": 1, "hj": Double(j), "hx": cs0[j].0, "hy": cs0[j].1]
            },
            drag: { q, h in
                var h = h
                let c = snap(q), j = Int(h["hj"] ?? 0)
                if !cs0.enumerated().contains(where: { $0.offset != j && $0.element == c }) { h["hx"] = c.0; h["hy"] = c.1 }
                return h
            },
            release: { h in
                let j = Int(h["hj"] ?? 0)
                var cs = cs0
                guard cs.indices.contains(j) else { return HandMove(hand: [:]) }
                cs[j] = (h["hx"] ?? cs[j].0, h["hy"] ?? cs[j].1)
                if closed {
                    let code = Sides2.drawn(P.n, cs)
                    return HandMove(hand: [:], missHand: [:], set: [("d", Double(code))], keep: keep(cs, closed: true, code: code), check: true)
                }
                return HandMove(hand: [:], keep: keep(cs, closed: false, code: 1))
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let L = Lay(s.numbers), P = L.P
        switch at(s) {
        case 0:
            if P.draw { let ex = Self.example(P.n); return (ex + [ex[0]]).map { .tap(.picture(CGPoint(x: $0.0, y: $0.1))) } }
            var moves: [GhostMove] = (0..<P.n).filter { !litCorner(s, P, $0) }.map { .tap(.picture(CGPoint(x: P.pts[$0].0, y: P.pts[$0].1))) }
            moves.append(.tap(.action("Check")))
            return moves
        case 1: let r = Self.names(y: L.REC)[P.n - 3]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let L = Lay(s.numbers), P = L.P
        switch at(s) {
        case 0:
            if !P.draw {
                var k: Numbers = [:]
                for j in 0..<(P.n - 1) { k["k\(j)"] = 1 }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(P.n - 1))], keep: k, check: true)
            }
            let bad: [Pt] = P.n == 4 ? [(4, 4), (26, 4), (14, 20)] : [(4, 4), (26, 4), (26, 20), (4, 20)]
            var k = DrawShape.keep(bad.map { (Int($0.0), Int($0.1)) }, closed: true)
            let code = Sides2.drawn(P.n, bad); k["bad"] = Double(code)
            return HandMove(hand: nil, missHand: nil, set: [("d", Double(code))], keep: k, check: true)
        case 1:
            let j = P.n == 4 ? 0 : P.n - 4, f = facts(s, P)
            return HandMove(hand: nil, missHand: nil, set: [("m", Double(Sides2.pickCode(f, j)))], keep: ["wn": Double(j)], check: true)
        default: return nil
        }
    }
}
