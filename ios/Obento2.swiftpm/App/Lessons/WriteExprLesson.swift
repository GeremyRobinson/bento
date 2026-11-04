import SwiftUI

/// Write expressions on the paper, as in the preview (design/prototype/grade6-ch5.html, dWrite): the words are the
/// instruction; a tray at the left (an n strip 8 squares long, its end dashed, and a row of ten squares that never run
/// out) and a build line 40 squares long under it. Slide pieces onto the line: they snap end to end; one dropped over
/// the end takes away (outlined over what it covers, crossed out); a strip alone on the line can be cut with the ruler
/// under it ("half of"). The readout says what's built ("n + n + n + 5"); Check. Then the record, the short way, its
/// numbers typed (`[3]n + [5]`); then tap the part named (a character, or a bracket under a longer part).
///
/// Everything is in the picture's squares (recordRow 0). Hand keys: "np" (pieces on the line), "t<i>" (100 an n strip,
/// else squares), "s<i>" (taken away), "cut", and while held "hk" (1 the ruler), "ht", "off", "qx", "qy", "rl".
@MainActor
struct WriteExprLesson: PaperLesson {
    static let NL = 8.0, LY = 6.0, LEN = 40.0, TQ = 12.0, RY = 13.0
    var liveKeys: Set<String> { ["qx", "qy", "rl", "part"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    struct Piece { var n: Bool; var len: Double; var sub: Bool }
    static func pieces(_ h: Numbers) -> [Piece] {
        (0..<Int(h["np"] ?? 0)).map { i in
            let t = h["t\(i)"] ?? 1
            return Piece(n: t >= 100, len: t >= 100 ? NL : t, sub: (h["s\(i)"] ?? 0) != 0)
        }
    }
    static func store(_ ps: [Piece], into h: inout Numbers) {
        for k in h.keys where k.hasPrefix("t") || k.hasPrefix("s") { h[k] = nil }
        h["np"] = Double(ps.count)
        for (i, p) in ps.enumerated() { h["t\(i)"] = p.n ? 100 : p.len; if p.sub { h["s\(i)"] = 1 } }
    }
    /// Where each piece sits: what's added end to end on the line, what's taken away over the end in the lane above.
    static func layout(_ ps: [Piece]) -> (out: [(p: Piece, x: Double, w: Double, y: Double)], cur: Double) {
        var cur = 0.0, out: [(Piece, Double, Double, Double)] = []
        for p in ps {
            if p.sub { out.append((p, max(0, cur - p.len), min(p.len, max(cur, 1)), LY - 2)) }
            else { out.append((p, cur, p.len, LY - 1)); cur += p.len }
        }
        return (out.map { (p: $0.0, x: $0.1, w: $0.2, y: $0.3) }, cur)
    }
    static func single(_ ps: [Piece]) -> Bool { ps.count == 1 && ps[0].n && !ps[0].sub }
    /// What's built as numbers: n strips, squares, the cut.
    static func value(_ ps: [Piece], cut: Double) -> (k: Int, c: Int, h: Int) {
        var k = 0, c = 0
        for p in ps { let s = p.sub ? -1 : 1; if p.n { k += s } else { c += s * Int(p.len) } }
        return (k, c, single(ps) ? Int(cut) : 1)
    }
    /// The readout: what's built, the long way ("n + n + n + 5", "12 − n", "n ÷ 2").
    static func built(_ ps: [Piece], cut: Double) -> String {
        if ps.isEmpty { return "" }
        if single(ps) && cut > 1 { return "n ÷ \(Int(cut))" }
        var ts: [Piece] = []
        for p in ps { if !p.n, let last = ts.last, !last.n, last.sub == p.sub { ts[ts.count - 1].len += p.len } else { ts.append(p) } }
        return ts.enumerated().map { j, p in (j > 0 ? (p.sub ? " − " : " + ") : p.sub ? "− " : "") + (p.n ? "n" : "\(Int(p.len))") }.joined()
    }

    /// The record's tokens and where each runs.
    static func toks(_ P: Write6.Parts, typing: Bool) -> [M7.Tok] {
        P.toks.map { t in
            switch t {
            case .s(let w): return "+−×÷".contains(w) ? .op(w) : .t(w)
            case .box(let id, let v): return typing ? .box(id, cells: "\(v)".count) : .n(v, .chapter)
            }
        }
    }
    /// A span's bracket level under the line: the shorter spans nearest.
    static func levels(_ spans: [Write6.Span]) -> [String: Int] {
        var lv: [String: Int] = [:], level = 0, last = -1
        for s in spans.filter({ $0.to > $0.from }).sorted(by: { $0.to - $0.from < $1.to - $1.from }) {
            if last >= 0 && s.to - s.from != last { level += 1 }
            last = s.to - s.from; lv[s.id] = level
        }
        return lv
    }
    static func bracketRow(_ level: Int) -> Double { RY + 1.6 + Double(level) * 1.2 }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch stage(s) {
        case 0, 1: return CGPoint(x: 0, y: 11)
        case 2: return CGPoint(x: 0, y: Self.RY + 2)
        default:
            let P = Write6.Parts(s.numbers), lv = Self.levels(P.spans).values.max() ?? 0
            return CGPoint(x: 0, y: (Self.bracketRow(lv) + 2).rounded(.up))
        }
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Write6.Parts(s.numbers), at = stage(s), NL = Self.NL, LY = Self.LY, TQ = Self.TQ
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let building = at <= 1
        // what's on the line: the hand's while building, what was checked after
        let hand: Numbers = building ? s.hand : s.run.kept.isEmpty ? s.hand : s.run.kept
        let ps = Self.pieces(hand), cut = hand["cut"] ?? 1, held = s.grabbed

        // the tray: an n strip and ten squares
        X6.strip(&pic, "tn", x: 0, y: 1, len: NL, h: 1, label: "n")
        R6.cells(&pic, "tu", x: TQ, y: 1, cols: 10, rows: 1, c: 1)
        // the line, a tick a block
        pic.line("ln", [(0, LY), (Self.LEN, LY)], .ink3)
        pic.sketch.segments("lt", stride(from: 0.0, through: Self.LEN, by: 5).map { (pic.P($0, LY), pic.P($0, LY + 0.5)) }, .ink3, width: Sketch.stroke)

        // the pieces on the line
        let (out, _) = Self.layout(ps), rl = held && s.h("hk") == 1 ? s.h("rl") ?? NL : NL / cut
        for (j, o) in out.enumerated() {
            let id = "pc\(j)\(o.p.n ? "n" : "u\(Int(o.p.len))")\(o.p.sub ? "s" : "")"
            if o.p.n && !o.p.sub {
                if Self.single(ps) && rl < NL {
                    // cut: the part kept is n ÷ 2, its length known now; the rest outlined and crossed off
                    let pen = held && s.h("hk") == 1
                    var p2 = pen ? live : pic
                    X6.strip(&p2, id + "k", x: o.x, y: o.y, len: rl, h: 1, known: true, label: nil)
                    p2.sketch.box(id + "rest\(rl)", p2.R(o.x + rl, o.y, NL - rl, 1), .ink3, width: Sketch.stroke)
                    p2.line(id + "x\(rl)", [(o.x + rl, o.y + 1), (o.x + NL, o.y)], .ink3)
                    if pen { live = p2 } else { pic = p2 }
                } else { X6.strip(&pic, id, x: o.x, y: o.y, len: o.w, h: 1, label: "n") }
            } else if o.p.n {
                // an n strip taken away: outlined over what it covers
                pic.sketch.box(id + "o", pic.R(o.x, o.y, o.w, 1), .chapter, width: Sketch.stroke, dashed: true)
                pic.word(id + "L", "n", at: o.x + o.w / 2, o.y + 0.5, X6.small)
            } else if o.p.sub {
                for u in 0..<Int(o.w) { pic.sketch.box("\(id)b\(u)", pic.R(o.x + Double(u), o.y, 1, 1), .chapter, width: Sketch.stroke) }
            } else { R6.cells(&pic, id, x: o.x, y: o.y, cols: Int(o.w), rows: 1, c: 1) }
            if o.p.sub {
                pic.line(id + "ld", [(o.x, o.y + 1), (o.x + o.w, o.y + 1)], .chapter)
                // what it covers is crossed out
                pic.line(id + "xo", [(o.x, LY - 1), (o.x + o.w, LY)], .ink2)
            }
        }
        // the ruler under a strip alone on the line
        if building && Self.single(ps) {
            let y = LY + 1.2, pen = held && s.h("hk") == 1
            var p2 = pen ? live : pic
            p2.line("rur", [(0, y - 0.6), (0, y), (rl, y), (rl, y - 0.6)], .chapter)
            R6.handle(&p2, "ruh", rl, y, held: pen)
            if pen { live = p2 } else { pic = p2 }
        }
        // the piece in the hand
        if held && s.h("hk") == 0, let qx = s.h("qx"), let qy = s.h("qy") {
            let t = s.h("ht") ?? 1, x = qx - (s.h("off") ?? 0), y = qy - 0.5
            if t >= 100 { X6.strip(&live, "held", x: x, y: y, len: NL, h: 1, label: "n", held: true) }
            else {
                for u in 0..<Int(t) { live.fill("hu\(u)", col: x + Double(u), row: y, w: 1, h: 1, .tint(0.42)); live.sketch.box("hb\(u)", live.R(x + Double(u), y, 1, 1), .chapter, width: Sketch.stroke) }
                live.word("hc", "\(Int(t))", at: x + t / 2, y - 0.9, X6.lit)
            }
        }
        // the readout: what's built
        if building {
            let rd = held && s.h("hk") == 1 ? (rl == NL ? "n" : "n ÷ \(Int(NL / rl))") : Self.built(ps, cut: cut)
            if !rd.isEmpty {
                if held { live.word("rd", rd, at: 0, LY + 3, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)); live.reads(rd) }
                else { pic.word("rd", rd, at: 0, LY + 3, X6.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
            }
            // hints: the line's room for the pieces wanted; then where the first piece of each kind goes
            if at == 1 && s.on("ring") { X6.ring(&pic, "ring", x: 0, y: LY - 2, w: Self.LEN, h: 2) }
            if at == 1 && s.on("spot") {
                let len = Double(abs(P.wantK)) * NL + Double(P.kind == 3 ? P.q : max(0, P.wantC))
                pic.sketch.box("spot", pic.R(0, LY - 1, min(Self.LEN, len), 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }

        // the record: the short way, its numbers typed; then the parts a tap can pick
        if at >= 2 {
            let toks = Self.toks(P, typing: at == 2), cols = X6.columns(toks, x: 0)
            M7.row(&rec, "rec", toks, x: 0, line: Self.RY)
            if at == 2 && s.on("ring") { X6.ring(&pic, "ring", x: 0, y: LY - 2, w: max(10, Self.layout(ps).cur), h: 2) }
            if at >= 3 {
                let lv = Self.levels(P.spans), picked = s.h("part").map { Int($0) } ?? (at == 4 ? P.spans.firstIndex { P.right.contains($0.id) } : nil)
                let bad = s.h("wrong").map { Int($0) }
                for (i, sp) in P.spans.enumerated() {
                    let x0 = cols[sp.from].0, x1 = cols[sp.to].1, on = picked == i || bad == i
                    let c: Sketch.Colour = bad == i ? R6.red : on ? .chapter : .ink3
                    if sp.to > sp.from {
                        let y = Self.bracketRow(lv[sp.id] ?? 0)
                        rec.line("br\(sp.id)\(on)\(bad == i)", [(x0 + 0.3, y), (x0 + 0.3, y + 0.6), (x1 - 0.3, y + 0.6), (x1 - 0.3, y)], c)
                    } else if on { rec.line("ul\(sp.id)\(bad == i)", [(x0 + 0.3, Self.RY + 1.3), (x1 - 0.3, Self.RY + 1.3)], c) }
                }
                if at == 3 && s.on("ring") { X6.ring(&rec, "ring", x: cols.first!.0, y: Self.RY - 1, w: cols.last!.1, h: 2) }
                if at == 3 && s.on("spot"), let r = P.spans.first(where: { P.right.contains($0.id) }) {
                    let x0 = cols[r.from].0, x1 = cols[r.to].1
                    rec.circle("spot", at: (x0 + x1) / 2, Self.RY, radius: max(1.5, (x1 - x0) / 2 + 0.6), .chapter, dashed: true)
                }
            }
        }
        let ext = pic.R(-1, 0, Self.LEN + 2, Self.RY + 6)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: at == 1 ? ["Check"] : [], extent: ext)
    }

    // MARK: the hands

    /// The span a tap at q picks: a character's (on the line) or a bracket's (under it).
    static func span(_ P: Write6.Parts, at q: CGPoint) -> Int? {
        let cols = X6.columns(toks(P, typing: false), x: 0), lv = levels(P.spans)
        if abs(q.y - RY) <= 1.3 {
            guard let t = X6.token(at: q.x, cols) else { return nil }
            return P.spans.firstIndex { $0.from == t && $0.to == t }
        }
        let hits = P.spans.indices.filter { i in
            let sp = P.spans[i]
            guard sp.to > sp.from else { return false }
            return abs(q.y - (bracketRow(lv[sp.id] ?? 0) + 0.3)) <= 0.6 && q.x >= cols[sp.from].0 - 0.5 && q.x <= cols[sp.to].1 + 0.5
        }
        return hits.min { (P.spans[$0].to - P.spans[$0].from) < (P.spans[$1].to - P.spans[$1].from) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Write6.Parts(s.numbers), at = stage(s), NL = Self.NL, LY = Self.LY
        if at == 3 {
            return Hands(tap: { q in
                Self.span(P, at: q).map { i in HandMove(hand: ["part": Double(i)], missHand: ["wrong": Double(i)], set: [("p", Double(i))], check: true) }
            })
        }
        guard at == 1 else { return nil }
        let base = s.hand.filter { !["grab", "hk", "ht", "off", "qx", "qy", "rl"].contains($0.key) }
        let ps = Self.pieces(base), cut = base["cut"] ?? 1
        return Hands(grab: { q in
            var h = base
            h["grab"] = 1
            if Self.single(ps), hypot(q.x - NL / cut, q.y - (LY + 1.2)) <= 1.6 { h["hk"] = 1; h["rl"] = NL / cut; return h }
            h["hk"] = 0; h["qx"] = q.x; h["qy"] = q.y
            if q.x >= -0.5, q.x <= NL + 0.5, q.y >= 0.2, q.y <= 2.8 { h["ht"] = 100; h["off"] = q.x; return h }
            if q.x >= Self.TQ, q.x <= Self.TQ + 10.5, q.y >= 0.2, q.y <= 2.8 {
                let j = max(1, min(10, (q.x - Self.TQ).rounded(.up))); h["ht"] = j; h["off"] = q.x - Self.TQ; return h
            }
            // a piece on the line, picked back up
            let (out, _) = Self.layout(ps)
            for (j, o) in out.enumerated().reversed() where q.x >= o.x - 0.3 && q.x <= o.x + o.w + 0.3 && q.y >= o.y - 0.7 && q.y <= o.y + 1.7 {
                var rest = ps; rest.remove(at: j)
                Self.store(rest, into: &h); h["cut"] = nil
                h["ht"] = o.p.n ? 100 : o.p.len; h["off"] = q.x - o.x
                return h
            }
            return nil
        }, drag: { q, h in
            var h = h
            if h["hk"] == 1 { let l = max(1, min(NL, q.x)); h["rl"] = [NL / 4, NL / 2, NL].min { abs($0 - l) < abs($1 - l) } }
            else { h["qx"] = q.x; h["qy"] = q.y }
            return h
        }, release: { h in
            var out = h.filter { !["grab", "hk", "ht", "off", "qx", "qy", "rl"].contains($0.key) }
            if h["hk"] == 1 {
                let rl = h["rl"] ?? NL
                out["cut"] = rl >= NL ? nil : NL / rl
                return HandMove(hand: out, missHand: nil)
            }
            let qx = h["qx"] ?? 0, qy = h["qy"] ?? 0, t = h["ht"] ?? 1
            // dropped off the line: back to the tray
            guard qy >= LY - 3, qy <= LY + 2.5, qx >= -3 else { return HandMove(hand: out, missHand: nil) }
            var ps = Self.pieces(out)
            let left = qx - (h["off"] ?? 0), cur = Self.layout(ps).cur, len = t >= 100 ? NL : t
            let sub = !ps.isEmpty && left < cur - 0.5
            if !sub && cur + len > Self.LEN { return HandMove(hand: out, missHand: nil) }
            ps.append(Piece(n: t >= 100, len: len, sub: sub))
            Self.store(ps, into: &out); out["cut"] = nil
            return HandMove(hand: out, missHand: nil)
        }, actions: ["Check": {
            let v = Self.value(ps, cut: cut)
            return HandMove(hand: nil, missHand: nil, set: [("k", Double(v.k)), ("c", Double(v.c)), ("h", Double(v.h))], keep: base, check: true)
        }])
    }

    /// The pieces the words want, in order (an n strip is 100).
    static func wanted(_ P: Write6.Parts) -> [(t: Double, sub: Bool)] {
        switch P.kind {
        case 0: return [(100, false), (Double(P.p), false)]
        case 1: return Array(repeating: (100, false), count: P.k)
        case 2: return Array(repeating: (100, false), count: P.k) + [(Double(P.p), false)]
        case 3: return (P.q > 10 ? [(10.0, false), (Double(P.q - 10), false)] : [(Double(P.q), false)]) + [(100, true)]
        case 4: return [(100, false)]
        default: return [(100, false), (Double(P.m), false), (100, false), (Double(P.m), false)]
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Write6.Parts(s.numbers), at = stage(s), NL = Self.NL, LY = Self.LY
        switch at {
        case 1:
            var moves: [GhostMove] = []
            // what's on the line goes back to the tray first, the last first
            var ps = Self.pieces(s.hand)
            while let last = ps.last {
                let o = Self.layout(ps).out.last!
                moves.append(.drag(from: CGPoint(x: o.x + o.w / 2, y: o.y + 0.5), to: CGPoint(x: o.x + o.w / 2, y: LY + 6)))
                _ = last; ps.removeLast()
            }
            var cur = 0.0
            for w in Self.wanted(P) {
                let from = w.t >= 100 ? CGPoint(x: NL / 2, y: 1.5) : CGPoint(x: Self.TQ + w.t - 0.5, y: 1.5)
                let off = w.t >= 100 ? NL / 2 : w.t - 0.5, len = w.t >= 100 ? NL : w.t
                let left = w.sub ? cur - len : cur
                moves.append(.drag(from: from, to: CGPoint(x: left + off, y: LY - 0.5)))
                if !w.sub { cur += len }
            }
            if P.kind == 4 { moves.append(.drag(from: CGPoint(x: NL, y: LY + 1.2), to: CGPoint(x: NL / 2, y: LY + 1.2))) }
            return moves + [.tap(.action("Check"))]
        case 3:
            let cols = X6.columns(Self.toks(P, typing: false), x: 0), lv = Self.levels(P.spans)
            guard let r = P.spans.first(where: { P.right.contains($0.id) }) else { return [] }
            let x = (cols[r.from].0 + cols[r.to].1) / 2
            return [.tap(.picture(CGPoint(x: x, y: r.to > r.from ? Self.bracketRow(lv[r.id] ?? 0) + 0.3 : Self.RY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Write6.Parts(s.numbers)
        switch stage(s) {
        case 1:
            var ps: [Piece]
            switch P.kind {
            case 3: ps = [Piece(n: true, len: Self.NL, sub: false), Piece(n: false, len: Double(P.q), sub: true)]
            case 5: ps = [Piece(n: true, len: Self.NL, sub: false), Piece(n: true, len: Self.NL, sub: false), Piece(n: false, len: Double(P.m), sub: false)]
            default: ps = [Piece(n: true, len: Self.NL, sub: false)] + (P.wantC > 0 ? [Piece(n: false, len: Double(P.wantC), sub: false)] : [])
            }
            if P.kind == 1 && P.story { ps.append(Piece(n: false, len: Double(P.k), sub: false)) }
            var h: Numbers = [:]; Self.store(ps, into: &h)
            let v = Self.value(ps, cut: 1)
            return HandMove(hand: h, missHand: h, set: [("k", Double(v.k)), ("c", Double(v.c)), ("h", 1)], check: true)
        case 3:
            guard let i = P.spans.indices.first(where: { !P.right.contains(P.spans[$0].id) }) else { return nil }
            return HandMove(hand: ["part": Double(i)], missHand: ["wrong": Double(i)], set: [("p", Double(i))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Write6.Parts(s.numbers)
        guard stage(s) == 2 else { return nil }
        // the last box one too many (twice the sum: the copy's squares doubled, the slip the lesson names)
        var out: [String: Double] = [:]
        for t in P.toks { if case .box(let id, let v) = t { out[id] = Double(v) } }
        if P.kind == 5 { out["b"] = Double(2 * P.m) } else if let last = P.toks.last(where: { if case .box = $0 { true } else { false } }), case .box(let id, let v) = last { out[id] = Double(v + 1) }
        return out
    }
}
