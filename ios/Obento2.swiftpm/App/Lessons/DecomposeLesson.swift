import SwiftUI

/// Breaking fractions apart on the paper, as in the preview (design/prototype/grade4-ch4.html): the bar is one whole.
/// Unit pieces: tap each line between the shaded pieces; the pieces part a square there, each part named under it (1/8);
/// then write how many pieces of 1/d. Two ways: tap one line; a copy of the bar draws under it; split the copy another way
/// (the same way again is a miss that names it). Wholes and a part: tap each whole bar; its pieces count and its name
/// turns from 1 into d/d. The record under the bars: 5/8 = 1/8 + … = [5] × 1/8; 5/8 = 2/8 + 3/8, 5/8 = 1/8 + 4/8;
/// 2 1/8 = 1 + 1 + 1/8 = 8/8 + 8/8 + 1/8.
@MainActor
struct DecomposeLesson: PaperLesson {
    /// The bar and its copy.
    static let y1 = 0.0, y2 = 7.0
    /// A whole bar's row (wholes and a part: one under another, the part last).
    static func yw(_ j: Int) -> Double { 6 * Double(j) }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    /// The splits on bar b (0 the bar, 1 the copy) now: the hand's on the step that makes them, kept after it.
    private func splits(_ s: PaperState, _ P: Decompose.Parts, bar b: Int) -> Set<Int> {
        let at = stage(s), key = b == 0 ? "s" : "c", working = (b == 0 && at == 1) || (b == 1 && at == 2)
        if P.kind == 0 && b == 0 && at >= 2 { return Set(1..<P.a) }
        let src = working ? s.hand : s.run.kept
        return Set((1..<P.d).filter { (src["\(key)\($0)"] ?? 0) != 0 })
    }
    /// Where joint j is on bar b with these splits (the middle of the gap when it's split).
    private func jx(_ P: Decompose.Parts, _ S: Set<Int>, _ j: Int) -> Double {
        Double(j * P.pw) + Double(S.filter { $0 < j }.count) + (S.contains(j) ? 0.5 : 0)
    }

    /// One bar: its pieces part a square where it's split, each part named under it; returns where it ends.
    private func drawBar(_ pen: inout GridPen, _ P: Decompose.Parts, _ S: Set<Int>, b: Int, y: Double) -> Double {
        let pw = Double(P.pw)
        for i in 0..<P.d {
            let shift = Double(S.filter { $0 <= i }.count)
            F4.piece(&pen, "p\(b)_\(i)", x: Double(i) * pw + shift, y: y, pw: pw, shaded: i < P.a)
        }
        if !S.isEmpty {
            var i0 = 0
            for (q, n) in P.parts(S).enumerated() {
                pen.label("pn\(b)_\(i0)_\(n)", "\(n)/\(P.d)", Bars.small, .below, edge: y + F4.h, along: Double(i0) * pw + Double(q) + Double(n) * pw / 2)
                i0 += n
            }
        }
        return Double(P.W + S.count)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Decompose.Parts(s.numbers)
        return P.kind == 2 ? drawWholes(s, P) : drawSplit(s, P)
    }

    private func drawSplit(_ s: PaperState, _ P: Decompose.Parts) -> PaperDrawing {
        let at = stage(s), d = P.d, a = P.a, unit = P.kind == 0, done = at >= 3
        var pic = GridPen(), rec = GridPen()
        let S0 = splits(s, P, bar: 0)
        let end = drawBar(&pic, P, S0, b: 0, y: Self.y1)
        F4.frac(&pic, "nm", "\(a)", "\(d)", col: end + 1, line: Self.y1 + 2)
        let copy = !unit && at >= 2
        var S1 = Set<Int>()
        if copy { S1 = splits(s, P, bar: 1); _ = drawBar(&pic, P, S1, b: 1, y: Self.y2) }
        // a hint: the lines still to split, ringed (between the shaded pieces)
        if s.on("ring") && (at == 1 || at == 2) {
            let S = at == 1 ? S0 : S1, y = at == 1 ? Self.y1 : Self.y2
            for j in 1..<a where !S.contains(j) { pic.circle("ring\(j)", at: jx(P, S, j), y + F4.h / 2, radius: 1, .chapter, dashed: true) }
        }

        // the record, a few rows under the bars
        var boxes: [WorkBox] = []
        if unit && at >= 2 {
            // a/d = 1/d + 1/d + … = [a] × 1/d, wrapped at the bar's width
            var segs: [[F4.Tok]] = [[.f("\(a)", "\(d)"), .op("="), .f("1", "\(d)")]]
            for _ in 1..<a { segs.append([.op("+"), .f("1", "\(d)")]) }
            segs.append([.op("="), done ? .n(a, .chapter) : .box("x", cells: 1), .op("×"), .f("1", "\(d)")])
            let most = max(Double(P.W), 44)
            var lines: [[F4.Tok]] = [[]], x = 0.0
            for g in segs {
                let w = F4.width(g)
                if x + w > most && !lines[lines.count - 1].isEmpty { lines.append([]); x = 4 }
                lines[lines.count - 1] += g; x += w
            }
            for (i, l) in lines.enumerated() { F4.row(&rec, "ru\(i)", l, x: i == 0 ? 0 : 4, line: 2 + 5 * Double(i)) }
            boxes = rec.boxes
        }
        if copy {
            func line(_ S: Set<Int>, _ c: Sketch.Colour) -> [F4.Tok] {
                [.f("\(a)", "\(d)"), .op("=")] + P.parts(S).enumerated().flatMap { i, n -> [F4.Tok] in (i > 0 ? [.op("+", c)] : []) + [.f("\(n)", "\(d)", c)] }
            }
            F4.row(&rec, "r1", line(S0, .ink), x: 0, line: 2)
            if done { F4.row(&rec, "r2", line(S1, .chapter), x: 0, line: 7) }
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: boxes,
                            extent: !unit && at >= 1 ? pic.R(0, 0, Double(P.W + a - 1) + 6, Self.y2 + F4.h + 2) : pic.R(0, 0, Double(P.W + a - 1) + 6, F4.h + 2))
    }

    private func drawWholes(_ s: PaperState, _ P: Decompose.Parts) -> PaperDrawing {
        let at = stage(s), d = P.d, W = P.W, done = at >= 2
        var pic = GridPen(), rec = GridPen()
        let tapped = done ? Set(0..<P.w) : Set((0..<P.w).filter { (s.hand["w\($0)"] ?? 0) != 0 })
        for j in 0..<P.w {
            let t = tapped.contains(j), y = Self.yw(j)
            F4.bar(&pic, "wb\(j)", y: y, W: W, d: d, on: d, uncut: !t)
            if t {
                F4.counts(&pic, "wc\(j)_", y: y, pw: Double(P.pw), d)
                F4.frac(&pic, "wn\(j)", "\(d)", "\(d)", col: Double(W) + 1, line: y + 2)
            } else { Bars.whole(&pic, "wn\(j)", 1, col: Double(W) + 1, row: y) }
            if at == 1 && !t && s.on("ring") { pic.sketch.box("ring\(j)", pic.R(-0.5, y - 0.5, Double(W) + 1, F4.h + 1), .chapter, width: Sketch.stroke, dashed: true) }
        }
        let yp = Self.yw(P.w)
        F4.bar(&pic, "pb", y: yp, W: W, d: d, on: P.n)
        F4.frac(&pic, "pn", "\(P.n)", "\(d)", col: Double(W) + 1, line: yp + 2)
        // the record: w n/d = 1 + 1 + n/d, and once every whole is tapped = d/d + d/d + n/d
        var toks: [F4.Tok] = [.n(P.w), .f("\(P.n)", "\(d)"), .op("=")]
        for _ in 0..<P.w { toks += [.n(1), .op("+")] }
        toks.append(.f("\(P.n)", "\(d)"))
        if done {
            toks.append(.op("="))
            for _ in 0..<P.w { toks += [.f("\(d)", "\(d)", .chapter), .op("+", .chapter)] }
            toks.append(.f("\(P.n)", "\(d)", .chapter))
        }
        F4.row(&rec, "rw", toks, x: 0, line: 2)
        return PaperDrawing(picture: pic.sketch, record: rec.sketch)
    }

    /// Under the bars (the copy's, two ways), or the part bar (wholes).
    func recordRow(_ n: Numbers) -> Double? {
        let P = Decompose.Parts(n)
        switch P.kind {
        case 0: return Self.y1 + F4.h + 3
        case 1: return Self.y2 + F4.h + 3
        default: return Self.yw(P.w) + F4.h + 2
        }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Decompose.Parts(s.numbers), at = stage(s)
        if P.kind == 2 {
            guard at == 1 else { return nil }
            let W = Double(P.W)
            return Hands(tap: { q in
                guard q.x >= -0.5, q.x <= W + 0.5, let j = (0...P.w).first(where: { q.y >= Self.yw($0) - 0.5 && q.y <= Self.yw($0) + F4.h + 0.5 }) else { return nil }
                if j == P.w { return HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) }
                var h = s.hand; h["w\(j)"] = 1
                let n = (0..<P.w).filter { (h["w\($0)"] ?? 0) != 0 }.count
                return n == P.w ? HandMove(hand: h, missHand: nil, set: [("x", Double(n))], check: true) : HandMove(hand: h, missHand: nil)
            })
        }
        let b = at == 1 ? 0 : at == 2 && P.kind == 1 ? 1 : -1
        guard b >= 0 else { return nil }
        let y = b == 0 ? Self.y1 : Self.y2, S = splits(s, P, bar: b), key = b == 0 ? "s" : "c"
        return Hands(tap: { q in
            guard q.y >= y - 1, q.y <= y + F4.h + 1 else { return nil }
            guard let j = (1..<P.d).min(by: { abs(q.x - jx(P, S, $0)) < abs(q.x - jx(P, S, $1)) }), abs(q.x - jx(P, S, j)) < 1.3 else { return nil }
            if j >= P.a { return HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) }
            var T = S
            if T.contains(j) { T.remove(j) } else { T.insert(j) }
            var h: Numbers = [:]
            for t in T { h["\(key)\(t)"] = 1 }
            let keep = h
            if P.kind == 0 {
                return T.count == P.a - 1 ? HandMove(hand: h, missHand: nil, set: [("x", Double(T.count))], keep: keep, check: true) : HandMove(hand: h, missHand: nil)
            }
            if b == 0 { return HandMove(hand: h, missHand: nil, set: [("x", Double(j))], keep: keep, check: true) }
            guard !T.isEmpty else { return HandMove(hand: h, missHand: nil) }
            let S0 = splits(s, P, bar: 0)
            if P.same(T, S0) { return HandMove(hand: h, missHand: nil, set: [("x", Double(100 + (S0.min() ?? 1)))], check: true) }
            return HandMove(hand: h, missHand: nil, set: [("x", 1)], keep: keep, check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Decompose.Parts(s.numbers), at = stage(s)
        if P.kind == 2 {
            guard at == 1 else { return [] }
            return (0..<P.w).filter { (s.hand["w\($0)"] ?? 0) == 0 }.map { .tap(.picture(CGPoint(x: Double(P.W) / 2, y: Self.yw($0) + 2))) }
        }
        if at == 1 {
            let S = splits(s, P, bar: 0)
            if P.kind == 0 {
                // each line left to split, from the right so the places before it don't move
                return (1..<P.a).reversed().filter { !S.contains($0) }.map { .tap(.picture(CGPoint(x: jx(P, S, $0), y: Self.y1 + 2))) }
            }
            return [.tap(.picture(CGPoint(x: jx(P, S, P.a / 2), y: Self.y1 + 2)))]
        }
        if at == 2 && P.kind == 1 {
            let S0 = splits(s, P, bar: 0), first = S0.min() ?? 1
            let j = (1..<P.a).first { !P.same([$0], S0) } ?? first
            return [.tap(.picture(CGPoint(x: jx(P, [], j), y: Self.y2 + 2)))]
        }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Decompose.Parts(s.numbers), at = stage(s)
        if P.kind == 2 { return at == 1 ? HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) : nil }
        if at == 1 { return HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) }
        if at == 2 && P.kind == 1 {
            // the copy split the same way as the bar
            let j = splits(s, P, bar: 0).min() ?? 1
            return HandMove(hand: ["c\(j)": 1], missHand: nil, set: [("x", Double(100 + j))], check: true)
        }
        return nil
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Decompose.Parts(s.numbers)
        return P.kind == 0 && stage(s) == 2 ? ["x": Double(P.d)] : nil
    }
}
