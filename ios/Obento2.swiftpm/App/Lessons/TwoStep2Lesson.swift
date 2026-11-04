import SwiftUI

/// Two-step story problems on the paper, as in the preview (design/prototype/grade2-ch1.html, dTwoStep): the story on the
/// top rows; the start bar (tinted, its number at its end) from the start line; the first change waiting under it as a loose
/// striped bar with its number. Slide it in: let go after the end it joins ("45 + 18"), over the end it crosses out what it
/// covers ("63 − 27"); write how many now, and the bar ends there, named so. Then the second change the same way. More, then
/// in all: Sam's bar and Ana's, which starts as long as Sam's; drag Ana's end on ("34 + 15"), write how many Ana has; slide
/// Ana's bar onto the end of Sam's, write how many in all.
///
/// Hand: "grab", "gx", "gy", "dx", "dy" (a bar carried) or "end" (Ana's end dragged, "a" how long it is).
@MainActor
struct TwoStep2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy", "a"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private struct Geo {
        let P: TwoStep2.Parts, R: Int
        var U: Double { Double(P.U) }
        func X(_ v: Int) -> Double { Double(v) / U }
        var PB: Double { 2 * Double(R) + 2 + (P.U == 2 ? 2 : 0) }
        var LY: Double { PB + 6 }
        /// Where a bar of `len` things let go with its left end at x lands: 1 after the end, 2 over it, 0 nowhere.
        func mode(_ x: Double, _ y: Double, len: Int, end: Int) -> Int {
            guard abs(y - PB) <= 2.5 else { return 0 }
            let j = abs(x - X(end)), c = abs(x - X(end - len))
            if j <= 3 && j <= c { return 1 }
            if c <= 3 && !P.more { return 2 }
            return 0
        }
    }
    private func geo(_ n: Numbers) -> Geo { let P = TwoStep2.Parts(n); return Geo(P: P, R: A2.storyRows(P.lines, width: 44).count) }

    func told(_ s: PaperState) -> String? { TwoStep2.Parts(s.numbers).lines.joined(separator: " ") }

    func draw(_ s: PaperState) -> PaperDrawing {
        let G = geo(s.numbers), P = G.P, st = at(s), PB = G.PB, LY = G.LY, u = P.U, k = st >= 2 ? 1 : 0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, P.lines, width: 44)
        if u == 2 { pic.word("scale", Bars2.scale(P.th), at: 0, 2 * Double(G.R) + 1, A2.words.colour(.ink2), anchor: UnitPoint(x: 0, y: 0.5)) }
        A2.start(&pic, y: PB, h: P.more ? 10 : 4)
        let held = s.grabbed, dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        var ro: String?
        if P.more {
            let together = st >= 3
            A2.bar(&pic, "sam", x: 0, y: PB, w: G.X(P.s), .tint, u: u, n: "\(P.s)")
            if !together && !(st == 2 && held) { pic.word("nmS", "Sam", at: G.X(P.s) + 0.5, PB + 2, A2.small, anchor: UnitPoint(x: 0, y: 0.5)) }
            if st == 4 { pic.word("tot", "\(P.s + P.s + P.d)", at: G.X(2 * P.s + P.d) + 0.5, PB + 2, A2.maths.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
            let ana = st == 0 ? Int(held ? (s.h("a") ?? Double(P.s)) : Double(P.s)) : P.s + P.d
            let named = st >= 2 ? "\(P.s + P.d)" : nil
            if together { A2.bar(&pic, "ana", x: G.X(P.s), y: PB, w: G.X(ana), .stripe, u: u, from: P.s, n: named) }
            else if st == 2 && held {
                let m = G.mode(dx, LY + dy, len: ana, end: P.s)
                A2.bar(&live, "ana", x: m == 1 ? G.X(P.s) : dx, y: m == 1 ? PB : LY + dy, w: G.X(ana), .stripe, u: u, n: named)
                if m == 1 { ro = "\(P.s) + \(P.s + P.d)" }
            } else {
                if st == 0 && held { A2.bar(&live, "ana", x: 0, y: LY, w: G.X(ana), .stripe, u: u); ro = "\(P.s) + \(ana - P.s)" }
                else { A2.bar(&pic, "ana", x: 0, y: LY, w: G.X(ana), .stripe, u: u, n: named) }
                if st == 0 && held {
                    live.dot("anaH", at: G.X(ana), LY + 2, radius: 0.75)
                    live.word("nmA", "Ana", at: G.X(ana) + 1, LY + 2, A2.small, anchor: UnitPoint(x: 0, y: 0.5))
                } else {
                    if st == 0 { pic.dot("anaH", at: G.X(ana), LY + 2, radius: 0.6) }
                    pic.word("nmA", "Ana", at: G.X(ana) + (st == 0 ? 1 : 0.5), LY + 2, A2.small, anchor: UnitPoint(x: 0, y: 0.5))
                }
            }
        } else {
            let st0 = P.steps[k], e = st0.a, c = st0.c, joined = st == 1 || st == 3
            if st == 4 { A2.bar(&pic, "run", x: 0, y: PB, w: G.X(P.e2), .tint, u: u); pic.word("end\(P.e2)", "\(P.e2)", at: G.X(P.e2) + 0.5, PB + 2, A2.maths.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
            else if joined && st0.op == "−" {
                A2.bar(&pic, "run", x: 0, y: PB, w: G.X(e - c), .tint, u: u)
                A2.bar(&pic, "cov", x: G.X(e - c), y: PB, w: G.X(c), .stripe, u: u, from: e - c, cross: true)
            } else { A2.bar(&pic, "run", x: 0, y: PB, w: G.X(e), .tint, u: u) }
            if joined && st0.op == "+" { A2.bar(&pic, "add", x: G.X(e), y: PB, w: G.X(c), .stripe, u: u, from: e, n: "\(c)") }
            if !joined && st != 4 && !held { pic.word("end\(e)", "\(e)", at: G.X(e) + 0.5, PB + 2, A2.maths.colour(k == 1 ? .chapter : .ink), anchor: UnitPoint(x: 0, y: 0.5)) }
            // the change waiting under the bar, loose and striped, with its number
            if st == 0 || st == 2 {
                if held {
                    let m = G.mode(dx, LY + dy, len: c, end: e)
                    let x = m == 1 ? G.X(e) : m == 2 ? G.X(e - c) : dx, y = m != 0 ? PB : LY + dy
                    A2.bar(&live, "loose\(k)", x: x, y: y, w: G.X(c), .stripe, u: u, n: "\(c)")
                    if m != 0 { ro = "\(e) \(m == 1 ? "+" : "−") \(c)" }
                } else { A2.bar(&pic, "loose\(k)", x: 0, y: LY, w: G.X(c), .stripe, u: u, n: "\(c)") }
            }
        }
        if let ro { live.reads(ro) }

        // hints: a first miss rings the bar's end, a second shows where the change goes
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 || st == 2 {
            let st0 = P.steps[k], end = P.more ? P.s : st0.a
            if ring { KK.hintBox(&pic, "hr", x: G.X(end) - 2, y: (P.more && st == 0 ? LY : PB), w: 4, h: 4) }
            if spot {
                if P.more && st == 0 { pic.line("spot", [(G.X(P.s + P.d), LY - 1), (G.X(P.s + P.d), LY + 5)], .chapter, dashed: true) }
                else {
                    let len = P.more ? P.s + P.d : st0.c, x = st0.op == "+" ? G.X(end) : G.X(end - len)
                    pic.sketch.box("spot", pic.R(x, PB, G.X(len), 4), .chapter, width: Sketch.stroke, dashed: true)
                }
            }
        } else if ring { KK.hintBox(&pic, "hr", x: 0, y: PB, w: G.X(P.maxEnd), h: 4) }

        // the record: each step's line, written in turn
        for (i, step) in P.steps.enumerated() where i <= k {
            let line = 1 + 3 * Double(i), toks: [M7.Tok] = [.n(step.a), .op(step.op), .n(step.c), .op("=")]
            if st > 2 * i + 1 { M7.row(&rec, "r\(i)", toks + [.n(step.ans, .chapter)], x: 0, line: line) }
            else if st == 2 * i + 1 {
                let end = M7.row(&rec, "r\(i)", toks + [.box("x\(i + 1)", cells: 2)], x: 0, line: line)
                if spot { A1.note(&rec, "spot", "\(step.ans)", x: end + 1, y: line) }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let G = geo(s.numbers), P = G.P, st = at(s), k = st >= 2 ? 1 : 0
        guard st == 0 || st == 2 else { return nil }
        let box = "m\(k + 1)"
        if P.more && st == 0 {
            return Hands(
                grab: { q in
                    guard abs(q.x - G.X(P.s)) < 2, q.y > G.LY - 1, q.y < G.LY + 5 else { return nil }
                    return ["grab": 1, "end": 1, "gx": q.x, "a": Double(P.s)]
                },
                drag: { q, held in var h = held; h["a"] = Double(max(P.s, min(P.s + 50, Int((Double(P.s) + (q.x - (held["gx"] ?? q.x)) * G.U).rounded())))); return h },
                release: { held in
                    let d = Int(held["a"] ?? Double(P.s)) - P.s
                    return d == 0 ? HandMove(hand: [:]) : HandMove(hand: [:], missHand: [:], set: [(box, Double(d))], check: true)
                })
        }
        let len = P.more ? P.s + P.d : P.steps[k].c, end = P.more ? P.s : P.steps[k].a
        let want = P.more || P.steps[k].op == "+" ? 1 : 2
        return Hands(
            grab: { q in
                guard q.x >= -0.5, q.x <= G.X(len) + 0.5, q.y >= G.LY - 0.5, q.y <= G.LY + 4.5 else { return nil }
                return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
            },
            drag: { q, held in var h = held; h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h },
            release: { held in
                let m = G.mode(held["dx"] ?? 0, G.LY + (held["dy"] ?? 0), len: len, end: end)
                if m == 0 { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [(box, m == want ? 1 : -1)], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let G = geo(s.numbers), P = G.P, st = at(s), k = st >= 2 ? 1 : 0
        guard st == 0 || st == 2 else { return [] }
        if P.more && st == 0 { return [.drag(from: CGPoint(x: G.X(P.s), y: G.LY + 2), to: CGPoint(x: G.X(P.s + P.d), y: G.LY + 2))] }
        let len = P.more ? P.s + P.d : P.steps[k].c, end = P.more ? P.s : P.steps[k].a
        let to = P.more || P.steps[k].op == "+" ? G.X(end) : G.X(end - len)
        return [.drag(from: CGPoint(x: G.X(len) / 2, y: G.LY + 2), to: CGPoint(x: to + G.X(len) / 2, y: G.PB + 2))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TwoStep2.Parts(s.numbers), st = at(s)
        guard st == 0 || st == 2 else { return nil }
        return HandMove(hand: [:], missHand: [:], set: [("m\(st / 2 + 1)", P.more && st == 0 ? Double(P.d + 2) : -1)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = TwoStep2.Parts(s.numbers), st = at(s)
        guard st == 1 || st == 3 else { return nil }
        return ["x\(st / 2 + 1)": Double(P.slips(st / 2)[0].0)]
    }
}
