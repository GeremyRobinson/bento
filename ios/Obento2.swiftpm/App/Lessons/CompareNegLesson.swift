import SwiftUI

/// Compare and order on the paper, as in the preview (design/prototype/grade6-ch4.html, dCompare): the line across −12 to
/// 12, two squares a one. Two numbers (later three) written at the line's right end, each with its point waiting over it
/// in its own shade (full, half, an outline): drag each to its number (the line's number under the finger lit, its own
/// readout over it). Then pick < or > between the names (a story writes it in words), or write three in order; absolute
/// value problems drag a bracket from 0 to each point ("7 from 0"), then pick which is farther.
@MainActor
struct CompareNegLesson: PaperLesson {
    /// The line's row; where the names start; squares between the line and the record.
    static let Y = 6.0, NX = 54.0
    static let N = N6.Line(x0: 25, y0: Y, U: 2, lo: -12, hi: 12)
    var liveKeys: Set<String> { ["hv", "br", "mv"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The names' left edges and widths (a 4-square gap for the sign between two).
    static func names(_ P: Compare6.Parts) -> [(x: Double, w: Double)] {
        var out: [(Double, Double)] = [], x = NX
        for (j, v) in P.vs.enumerated() {
            let w = (R6.width(Neg6.fm(v), R6.maths) + 0.5).rounded(.up)
            out.append((x, w)); x += w + (P.three ? 2 : j == 0 ? 4 : 0)
        }
        return out
    }
    /// Where point j is now: on its number (placed, or dropped somewhere), else waiting over its name.
    static func spot(_ P: Compare6.Parts, _ hand: Numbers, _ j: Int, done: Bool) -> CGPoint {
        if done || hand["p\(j)"] != nil { return N.at(P.vs[j]) }
        if let w = hand["w\(j)"] { return N.at(w) }
        let n = names(P)[j]
        return CGPoint(x: n.x + n.w / 2, y: Y - 3)
    }
    /// The measured points' order (by the hand, or all once measuring is done).
    private func measured(_ P: Compare6.Parts, _ s: PaperState) -> [Int] {
        guard P.abs else { return [] }
        if stage(s) >= 4 { return [0, 1] }
        guard stage(s) == 3 else { return [] }
        return (0..<2).compactMap { j in s.h("m\(j)").map { (j, $0) } }.sorted { $0.1 < $1.1 }.map(\.0)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Compare6.Parts(s.numbers), at = stage(s), N = Self.N, Y = Self.Y, done = at >= 5
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let names = Self.names(P), held = s.grabbed ? s.h("j").map { Int($0) } : nil, hv = s.h("hv") ?? 0
        N.draw(&pic, "nl")
        // the names at the right end, the sign between two
        for (j, v) in P.vs.enumerated() { pic.word("nm\(j)", Neg6.fm(v), at: names[j].x, Y, R6.maths, anchor: UnitPoint(x: 0, y: 0.5)) }
        let slotX = names[0].x + names[0].w + 1
        if !P.three {
            if at >= 3 { pic.word("sg\(done)", ["<", ">"][P.sign], at: slotX + 1, Y, R6.maths.colour(done ? .chapter : .ink)) }
            else if at == 2 { pic.sketch.box("slot", pic.R(slotX, Y - 1, 2, 2), .ink3, width: Sketch.stroke) }
        }
        // brackets from 0, each with how far
        let meas = measured(P, s)
        func level(_ n: Int) -> Double { Y - 2 - 1.6 * Double(n) }
        // the shorter bracket under the longer, so neither's end crosses the other's words
        func rank(_ v: Double) -> Int { P.vs.prefix(2).filter { abs($0) < abs(v) }.count }
        for j in meas {
            let v = P.vs[j]
            N6.bracket(&pic, "m\(j)", from: N.at(0).x, to: N.at(v).x, line: Y, level: level(rank(v)), "\(fmt(abs(v))) from 0")
        }
        if at == 3, s.grabbed, let br = s.h("br") {
            N6.bracket(&live, "br", from: N.at(0).x, to: N.at(br).x, line: Y, level: level(P.abs ? rank(br) : 0), br == 0 ? nil : "\(fmt(abs(br))) from 0")
            live.reads("\(fmt(abs(br))) from 0")
        }
        // the points, each in its shade
        for j in P.vs.indices {
            if held == j {
                let p = N.at(hv)
                N6.point(&live, "p\(j)", p, shade: j, held: true)
                live.word("hr", Neg6.fm(hv), at: p.x, p.y - 1.6, N6.lit)
                live.reads(Neg6.fm(hv))
            } else {
                N6.point(&pic, "p\(j)", Self.spot(P, s.hand, j, done: at >= 2), shade: j)
            }
        }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let todo = P.vs.indices.first { s.h("p\($0)") == nil } ?? 0
        if at == 1 && s.on("ring") {
            let v = P.vs[todo], a = N.at(0).x, b = N.at(v < 0 ? N.lo : N.hi).x
            R6.ring(&pic, "ring", x: min(a, b), y: Y - 1, w: abs(b - a), h: 3.6)
        }
        if at == 1 && s.on("spot") { let p = N.at(P.vs[todo]); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        if at == 2 && s.on("ring") { let a = N.at(P.lo).x, b = N.at(P.hi).x; R6.ring(&pic, "ring", x: a - 1, y: Y - 1, w: b - a + 2, h: 3.6) }
        if at == 2 && s.on("spot") { let p = N.at(P.lo); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        if at == 3 && s.on("ring") { let z = N.at(0); pic.circle("ring", at: z.x, z.y, radius: 1.6, .chapter, dashed: true) }
        if at == 3 && s.on("spot") {
            for j in 0..<2 where !meas.contains(j) { let p = N.at(P.vs[j]); pic.circle("spot\(j)", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 4 && s.on("ring") { let a = N.at(min(0, P.lo)).x, b = N.at(max(0, P.hi)).x; R6.ring(&pic, "ring", x: a, y: level(1) - 1.6, w: b - a, h: Y - level(1) + 1.6) }
        if at == 4 && s.on("spot") { let v = P.vs[P.far]; pic.circle("spot", at: (N.at(0).x + N.at(v).x) / 2, level(rank(v)) - 0.9, radius: 2.4, .chapter, dashed: true) }

        // the record: a story's words, the order written, |−7| = 7
        if P.kind == 6 && at >= 5 { M7.row(&rec, "tw", [.w(P.tempWords, .chapter)], x: 0, line: 1) }
        if P.three && at >= 2 {
            var toks: [M7.Tok] = []
            for j in 0..<3 {
                if j > 0 { toks.append(.op("<")) }
                toks.append(done ? .t(Neg6.fm(P.sorted[j]), .chapter) : .box("o\(j)", cells: 2))
            }
            M7.row(&rec, "ord", toks, x: 0, line: 1)
        }
        if P.abs {
            var x = 0.0
            for j in meas {
                x = M7.row(&rec, "ab\(j)", [.t("|\(Neg6.fm(P.vs[j]))|"), .op("="), .t(fmt(abs(P.vs[j])), .chapter)], x: x, line: 1) + 4
            }
        }
        let right = names.last.map { $0.x + $0.w } ?? Self.NX
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, Y - 6, right, 8))
    }

    func recordRow(_ n: Numbers) -> Double? { Self.Y + 5 }
    /// The sign's choices under the names.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Compare6.Parts(s.numbers)
        return stage(s) == 2 && !P.three ? CGPoint(x: Self.NX, y: Self.Y + 3) : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Compare6.Parts(s.numbers), N = Self.N, at = stage(s), step = P.half ? 0.5 : 1
        var base = s.hand
        for k in ["grab", "j", "hv", "br", "mv"] { base[k] = nil }
        switch at {
        case 1:
            return Hands(grab: { q in
                var best: Int?, bd = 1.8
                for j in P.vs.indices where base["p\(j)"] == nil {
                    let p = Self.spot(P, base, j, done: false), d = hypot(q.x - p.x, q.y - p.y)
                    if d < bd { bd = d; best = j }
                }
                guard let j = best else { return nil }
                var h = base; h["grab"] = 1; h["j"] = Double(j); h["hv"] = base["w\(j)"] ?? 0
                return h
            }, drag: { q, h in
                var h = h; h["hv"] = N.val(q, step: step); h["mv"] = 1; return h
            }, release: { h in
                guard let j = h["j"].map({ Int($0) }), h["mv"] != nil, let v = h["hv"] else { return HandMove(hand: base) }
                var b = base
                if v == P.vs[j] {
                    b["p\(j)"] = 1; b["w\(j)"] = nil
                    let n = P.vs.indices.filter { b["p\($0)"] != nil }.count
                    return n == P.vs.count ? HandMove(hand: b, missHand: b, set: [("x", Double(n))], check: true) : HandMove(hand: b)
                }
                b["w\(j)"] = v
                return HandMove(hand: b, missHand: b, set: [("x", Neg6.wrong(j, v))], check: true)
            })
        case 3:
            return Hands(grab: { q in
                let z = N.at(0)
                guard hypot(q.x - z.x, q.y - z.y) <= 2.2 else { return nil }
                var h = base; h["grab"] = 1; h["br"] = 0; return h
            }, drag: { q, h in var h = h; h["br"] = N.val(q, step: step); return h
            }, release: { h in
                let v = h["br"] ?? 0
                var b = base
                if let j = (0..<2).first(where: { P.vs[$0] == v && b["m\($0)"] == nil }) {
                    b["m\(j)"] = Double((0..<2).filter { b["m\($0)"] != nil }.count)
                    let n = (0..<2).filter { b["m\($0)"] != nil }.count
                    return n == 2 ? HandMove(hand: b, missHand: b, set: [("x", 2)], check: true) : HandMove(hand: b)
                }
                if v == 0 || P.vs.contains(v) { return HandMove(hand: b) }
                return HandMove(hand: b, missHand: b, set: [("x", -1)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Compare6.Parts(s.numbers), N = Self.N
        switch stage(s) {
        case 1:
            return P.vs.indices.filter { s.h("p\($0)") == nil }.map { j in .drag(from: Self.spot(P, s.hand, j, done: false), to: N.at(P.vs[j])) }
        case 3:
            return (0..<2).filter { s.h("m\($0)") == nil }.map { j in .drag(from: N.at(0), to: N.at(P.vs[j])) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Compare6.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let v = -P.vs[0]
            return HandMove(hand: ["w0": v], missHand: ["w0": v], set: [("x", Neg6.wrong(0, v))], check: true)
        case 3:
            return HandMove(hand: [:], missHand: [:], set: [("x", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Compare6.Parts(s.numbers)
        guard stage(s) == 2, P.three else { return nil }
        let byDigits = P.vs.sorted { abs($0) < abs($1) }
        return ["o0": byDigits[0], "o1": byDigits[1], "o2": byDigits[2]]
    }
}
