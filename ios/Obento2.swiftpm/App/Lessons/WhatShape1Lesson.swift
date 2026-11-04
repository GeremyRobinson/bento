import SwiftUI

/// What makes a triangle on the paper, as in the preview (design/prototype/grade1-ch6.html, dShapes): one shape with its corners
/// on the paper's crossings, its count beside it. Trace each side (a finger near a side covers the part under it; 80% of it, both
/// ends, traces it: it darkens in the chapter colour on a band and counts "1 side, 2 sides"; corners whose sides are traced get a
/// dot; a gap is ringed). Then tap Yes or No under it; after a yes, tap corners in the empty patch beside it (dashed, 25 squares)
/// to draw a different one, the first again to close it. The record under it: `3 straight sides, closed: a triangle`.
///
/// Kept: "s<j>" side j traced; "wrong" the block tapped wrong; the drawing "n", "x<i>", "y<i>", "closed", "bad". Hand: "grab", the
/// sides' covered samples "m<j>" (a bit each of 25), "d<j>" traced while held, "lx", "ly" the finger's last place, "any".
@MainActor
struct WhatShape1Lesson: PaperLesson {
    typealias Pt = KS.Pt
    var liveKeys: Set<String> { Set(["lx", "ly", "any"] + (0..<7).map { "m\($0)" }) }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let PW = 25.0

    @MainActor struct Layout {
        let P: WhatShape1.Parts
        var RX: Double { ceil(P.w) + 1.5 }
        var PX: Double { ((RX + 7) / 5).rounded(.up) * 5 }
        /// The record's row: two squares under the shape and the patch (on the next block line it showed at 73%).
        var recY: Double { max(ceil(P.h), P.yes ? WhatShape1Lesson.PW : 0) + 2 }
        var right: Double { P.yes ? PX + WhatShape1Lesson.PW + 1 : PX + 11 }
        /// Yes and No in a column beside the shape, where the patch comes after a yes (under it the problem showed at 70%).
        var blocks: [CGRect] { KS.rects(2, x: PX, y: 0, w: 10, .column) }
        var recWidth: Double { let r = P.record; return M7.width((r.n.map { [M7.Tok.n($0)] } ?? []) + [.w(r.words)]) }
        /// Done: Next problem beside the record.
        var next: CGPoint { CGPoint(x: max(PX, ((recWidth + 2) / 5).rounded(.up) * 5), y: recY) }
        init(_ n: Numbers) { P = WhatShape1.Parts(n) }
    }
    /// Which block is which: Yes is box value 1.
    private static let answers = [1.0, 0.0]

    private func done(_ s: PaperState, _ j: Int) -> Bool { (s.run.kept["s\(j)"] ?? 0) != 0 || (s.grabbed && (s.h("d\(j)") ?? 0) != 0) || at(s) > 0 }
    private func corners(_ s: PaperState) -> [Pt] { DrawShape.corners(s.run.kept).map { (Double($0.0), Double($0.1)) } }

    /// A band along a path, `w` squares each side.
    static func band(_ p: [Pt], w: Double = 0.55) -> [Pt] {
        guard p.count > 1 else { return [] }
        func n(_ i: Int) -> Pt {
            let a = p[max(0, i - 1)], b = p[min(p.count - 1, i + 1)], dx = b.0 - a.0, dy = b.1 - a.1, l = max(1e-9, hypot(dx, dy))
            return (-dy / l * w, dx / l * w)
        }
        let L = p.indices.map { i in (p[i].0 + n(i).0, p[i].1 + n(i).1) }, R = p.indices.map { i in (p[i].0 - n(i).0, p[i].1 - n(i).1) }
        return L + R.reversed()
    }
    /// A side lit along its length: one band for a straight side, a band a stretch for a curved one (a polygon fills only convex).
    static func bands(_ pen: inout GridPen, _ id: String, _ sd: WhatShape1.Side, _ c: Sketch.Colour, from a: Int = 0, to b: Int = 24) {
        if sd.kind != "curve" { KS.poly(&pen, id, band([sd.path[a], sd.path[b]]), c); return }
        for k in a..<b { KS.poly(&pen, "\(id)_\(k)", band([sd.path[k], sd.path[k + 1]] , w: 0.55), c) }
    }
    static func example(_ kind: String) -> [Pt] {
        switch kind {
        case "rectangle": [(2, 6), (23, 6), (23, 18), (2, 18)]
        case "square": [(4, 4), (21, 4), (21, 21), (4, 21)]
        case "hexagon": [(0, 12), (6, 2), (19, 2), (25, 12), (19, 22), (6, 22)]
        default: [(3, 22), (22, 22), (8, 4)]
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let Lo = Layout(s.numbers), P = Lo.P, st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let last = st == (P.yes ? 3 : 2)
        // the shape: untraced sides in ink, traced ones in the chapter colour on a band
        for (j, sd) in P.lines.enumerated() {
            if done(s, j) {
                Self.bands(&pic, "bd\(j)", sd, KS.lit)
                pic.line("sd\(j)L", sd.path, .chapter)
            } else {
                pic.line("sd\(j)", sd.path, .ink)
                // what the finger covers now
                if s.grabbed, let m = s.h("m\(j)"), m > 0 {
                    let bits = (0..<25).filter { (Int(m) >> $0) & 1 == 1 }
                    if let a = bits.first, let b = bits.last, b > a { Self.bands(&live, "tr\(j)", sd, .tint(0.3), from: a, to: b) }
                }
            }
        }
        // dots on corners whose two sides are traced
        for j in P.pts.indices {
            guard let into = P.lines.firstIndex(where: { $0.b == j && $0.kind != "short" }), let from = P.lines.firstIndex(where: { $0.a == j }) else { continue }
            if done(s, into) && done(s, from) && P.lines[into].kind != "curve" && P.lines[from].kind != "curve" { pic.dot("cd\(j)", at: P.pts[j].0, P.pts[j].1, radius: 0.45, .chapter, over: true) }
        }
        if let g = P.lines.firstIndex(where: { $0.kind == "short" }), done(s, g), let e = P.lines[g].end {
            let b = P.pts[P.lines[g].b]
            pic.circle("gap", at: (e.0 + b.0) / 2, (e.1 + b.1) / 2, radius: 2.2, .chapter)
        }
        let n = P.lines.indices.filter { done(s, $0) && P.lines[$0].kind != "curve" }.count
        if n > 0 && !last { A1.note(&pic, "cnt", Shapes1.pl(n, "side", "sides"), x: Lo.RX, y: P.h / 2) }
        if st == 0 && s.grabbed { live.reads(Shapes1.pl(n, "side", "sides")) }
        if st == 0 {
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: -1, y: -1, w: ceil(P.w) + 2, h: ceil(P.h) + 2) }
            if s.on("spot"), let j = P.lines.indices.first(where: { !done(s, $0) }) { pic.line("spot\(j)", P.lines[j].path, .chapter, dashed: true); Self.bands(&pic, "spb\(j)", P.lines[j], .tint(0.15)) }
        }
        if st == 1 {
            let wrong = s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil }
            let right = P.yes ? 0 : 1
            KS.blocks(&pic, "yn", ["Yes", "No"], Lo.blocks, wrong: wrong, spot: s.on("spot") ? right : nil, ring: s.on("ring") && !s.on("spot"))
        }
        // the patch to draw in, and the corners placed in it
        if P.yes && st >= 2 {
            let PX = Lo.PX, W = Self.PW
            var cs = corners(s)
            if last && cs.count < 3 { cs = Self.example(P.kind).map { ($0.0 + PX, $0.1) } }
            let closed = (s.run.kept["closed"] ?? 0) != 0 || last, bad = (s.run.kept["bad"] ?? 0) != 0 && !last
            if !last { KS.outline(&pic, "patch", [(PX, 0), (PX + W, 0), (PX + W, W), (PX, W)], .ink3, dashed: true) }
            let c: Sketch.Colour = bad ? KS.red : .chapter, key = cs.map { "\(Int($0.0)),\(Int($0.1))" }.joined(separator: "_")
            if closed && !bad && cs.count >= 3 { KS.poly(&pic, "dfill\(key)", cs, KS.fill) }
            if cs.count > 1 { pic.line("dl\(key)\(bad)", closed ? cs + [cs[0]] : cs, c) }
            for (j, p) in cs.enumerated() { pic.dot("dc\(j)_\(Int(p.0)),\(Int(p.1))\(bad)", at: p.0, p.1, radius: 0.45, c, over: true) }
            if !cs.isEmpty && !last {
                let f = closed ? cs.count : cs.count - 1
                if f > 0 { A1.note(&pic, "dn", Shapes1.pl(f, "side", "sides"), x: PX + W / 2, y: W + 1.5, centred: true) }
            }
            if st == 2 {
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hp", x: PX - 0.5, y: -0.5, w: W + 1, h: W + 1) }
                if s.on("spot") { KS.outline(&pic, "spot", Self.example(P.kind).map { ($0.0 + PX, $0.1) }, .chapter, dashed: true) }
            }
        }
        if st >= 2 {
            let r = P.record
            KS.line(&pic, "rec", (r.n.map { [M7.Tok.n($0, .chapter)] } ?? []) + [.w(r.words)], x: 0, line: Lo.recY + 1)
        }
        // the room this step takes, so the camera frames what's drawn now
        let bottom = st == 0 ? ceil(P.h) + 1 : st == 1 ? max(ceil(P.h), 9) + 1 : Lo.recY + 3
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(-1, -1, Lo.right + 1, bottom + 1))
    }

    /// The finger at q covers the samples of each untraced side near it; a side 80% covered, both ends, is traced.
    private func cover(_ P: WhatShape1.Parts, _ h: inout Numbers, _ q: Pt, _ s: PaperState) {
        for (j, sd) in P.lines.enumerated() where (s.run.kept["s\(j)"] ?? 0) == 0 && (h["d\(j)"] ?? 0) == 0 {
            var best = -1, bd = 1.6
            for (k, c) in sd.path.enumerated() { let d = hypot(c.0 - q.0, c.1 - q.1); if d < bd { bd = d; best = k } }
            guard best >= 0 else { continue }
            let m = Int(h["m\(j)"] ?? 0) | (1 << best)
            h["m\(j)"] = Double(m); h["any"] = 1
            let bits = (0..<25).filter { (m >> $0) & 1 == 1 }
            if bits.count >= 20 && bits.contains(where: { $0 <= 2 }) && bits.contains(where: { $0 >= 22 }) { h["d\(j)"] = 1 }
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let Lo = Layout(s.numbers), P = Lo.P
        switch at(s) {
        case 0:
            return Hands(
                grab: { q in
                    guard q.x >= -3, q.y >= -3, q.x <= P.w + 3, q.y <= P.h + 3 else { return nil }
                    var h: Numbers = ["grab": 1, "lx": q.x, "ly": q.y]
                    cover(P, &h, (q.x, q.y), s)
                    return h
                },
                drag: { q, h in
                    var h = h
                    let a = (h["lx"] ?? q.x, h["ly"] ?? q.y), d = hypot(q.x - a.0, q.y - a.1), k = max(1, Int(d / 0.4))
                    // the finger's walk, so a quick drag never skips a stretch of a side
                    for i in 1...k { let u = Double(i) / Double(k); cover(P, &h, (a.0 + (q.x - a.0) * u, a.1 + (q.y - a.1) * u), s) }
                    h["lx"] = q.x; h["ly"] = q.y
                    return h
                },
                release: { h in
                    var keep: Numbers = [:]
                    for j in P.lines.indices where (h["d\(j)"] ?? 0) != 0 { keep["s\(j)"] = 1 }
                    let all = P.lines.indices.allSatisfy { (s.run.kept["s\($0)"] ?? 0) != 0 || keep["s\($0)"] != nil }
                    if all { return HandMove(hand: [:], missHand: [:], set: [("t", 1)], keep: keep, check: true) }
                    if keep.isEmpty && (h["any"] ?? 0) == 0 { return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true) }
                    return HandMove(hand: [:], keep: keep)
                })
        case 1:
            let r = Lo.blocks
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                let v = Self.answers[j], right = v == (P.yes ? 1 : 0)
                return HandMove(hand: nil, missHand: nil, set: [("c", v)], keep: ["wrong": right ? -1 : Double(j)], check: true)
            })
        case 2 where P.yes:
            let PX = Lo.PX, W = Self.PW
            return Hands(tap: { q in
                guard q.x >= PX - 0.4, q.x <= PX + W + 0.4, q.y >= -0.4, q.y <= W + 0.4 else { return nil }
                let c = (min(PX + W, max(PX, q.x.rounded())), min(W, max(0, q.y.rounded())))
                var cs = corners(s)
                if (s.run.kept["bad"] ?? 0) != 0 || (s.run.kept["closed"] ?? 0) != 0 { cs = [] }
                func keep(_ cs: [Pt], closed: Bool, bad: Bool) -> Numbers {
                    var k = DrawShape.keep(cs.map { (Int($0.0), Int($0.1)) }, closed: closed); k["bad"] = bad ? 1 : 0; return k
                }
                if cs.count >= 3 && c == cs[0] {
                    let code = WhatShape1.drawn(P, cs.map { ($0.0 - PX, $0.1) })
                    return HandMove(hand: nil, missHand: nil, set: [("d", Double(code))], keep: keep(cs, closed: true, bad: code != 1), check: true)
                }
                if cs.contains(where: { $0 == c }) { return nil }
                return HandMove(hand: nil, missHand: nil, keep: keep(cs + [c], closed: false, bad: false))
            })
        default: return nil
        }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) == (WhatShape1.Parts(s.numbers).yes ? 3 : 2) ? Layout(s.numbers).next : nil }

    func demo(_ s: PaperState) -> [GhostMove] {
        let Lo = Layout(s.numbers), P = Lo.P
        switch at(s) {
        case 0:
            return P.lines.indices.filter { (s.run.kept["s\($0)"] ?? 0) == 0 }.map { j in
                .path(stride(from: 0, through: 24, by: 4).map { CGPoint(x: P.lines[j].path[$0].0, y: P.lines[j].path[$0].1) })
            }
        case 1: let r = Lo.blocks[P.yes ? 0 : 1]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case 2:
            let ex = Self.example(P.kind)
            return (ex + [ex[0]]).map { .tap(.picture(CGPoint(x: $0.0 + Lo.PX, y: $0.1))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let Lo = Layout(s.numbers), P = Lo.P
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        case 1:
            let j = P.yes ? 1 : 0
            return HandMove(hand: nil, missHand: nil, set: [("c", Self.answers[j])], keep: ["wrong": Double(j)], check: true)
        case 2:
            let bad: [Pt] = P.kind == "triangle" ? [(4, 4), (20, 4), (20, 18), (4, 18)] : [(4, 20), (20, 20), (10, 4)]
            var k = DrawShape.keep(bad.map { (Int($0.0 + Lo.PX), Int($0.1)) }, closed: true); k["bad"] = 1
            return HandMove(hand: nil, missHand: nil, set: [("d", Double(WhatShape1.drawn(P, bad)))], keep: k, check: true)
        default: return nil
        }
    }
}
