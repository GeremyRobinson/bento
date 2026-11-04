import SwiftUI

/// Negative numbers on the paper, as in the preview (design/prototype/grade6-ch4.html, dNeg): a line through 0, upright
/// for temperature and sea level (a square a one, −15 to 15), across for money and yards (two squares a one; −8 to 8 with
/// halves), what 0 means written small beside 0. Drag the point to the number (its sign shows as it crosses 0); fold the
/// half with it over the 0 line (it turns over, prints the point on the other side, and lies back); write the opposite,
/// `−(−7) = [7]`. The opposite's opposite folds twice and lands where it started.
@MainActor
struct NegativesLesson: PaperLesson {
    var liveKeys: Set<String> { ["v", "grab", "th", "from"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    static func line(_ P: Negatives6.Parts) -> N6.Line {
        P.up ? N6.Line(x0: 5, y0: 16, U: 1, lo: -15, hi: 15, up: true)
            : P.half ? N6.Line(x0: 20, y0: 5, U: 2, lo: -8, hi: 8) : N6.Line(x0: 35, y0: 5, U: 2, lo: -15, hi: 15)
    }
    /// The fold at 0, lifting the half on `side` (+1: right of 0 across, below it upright).
    static func fold(_ N: N6.Line, _ side: Double) -> N6.Fold {
        N.up ? N6.Fold(vertical: false, at: N.y0, mid: N.x0, side: side) : N6.Fold(vertical: true, at: N.x0, mid: N.y0, side: side)
    }
    /// The side of 0 a value's paper is on, in the fold's terms.
    static func side(_ N: N6.Line, _ v: Double) -> Double { N.up ? (v < 0 ? 1 : -1) : (v < 0 ? -1 : 1) }
    /// The sheet a fold lifts: the half's band of paper.
    static func sheet(_ N: N6.Line, _ side: Double) -> CGRect {
        if N.up { let far = 16.5 * side; return CGRect(x: N.x0 - 4.5, y: min(N.y0, N.y0 + far), width: 8, height: abs(far)) }
        let far = (N.hi * N.U + 1.5) * side
        return CGRect(x: min(N.x0, N.x0 + far), y: N.y0 - 3.5, width: abs(far), height: 7)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Negatives6.Parts(s.numbers), at = stage(s), N = Self.line(P), up = P.up, t = P.t
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let kept = s.run.kept
        // the folds landed so far: the half each lifted, and how far it had turned when it was let go
        var landed: [(side: Double, th: Double)] = []
        if at >= 3 { landed.append((Self.side(N, t), kept["th1"] ?? .pi * 0.75)) }
        if at >= 4 && P.twice { landed.append((Self.side(N, -t), kept["th2"] ?? .pi * 0.75)) }
        // the fold being made now (held), or one let go short that falls back flat
        let held = s.grabbed && (at == 2 || at == 3) ? s.h("sd") : nil
        let back = (at == 2 || at == 3) && !s.grabbed ? s.h("back").map { ($0, s.h("sd") ?? 1) } : nil
        let lifting = (landed.map(\.side) + [held, back?.1].compactMap { $0 })
        func base(_ p: CGPoint) -> Bool { !lifting.contains { Self.fold(N, $0).lifted(p) } }

        // what the paper carries: the line, the point, what the folds printed (each with its number)
        let placing = at <= 1
        // a fold held across the line: 0's number and what 0 means step off the fold line to the side that stays down, so
        // the turning half's edge doesn't run through them (on the money line "$0" read over "0")
        let aside = held.flatMap { up ? nil : $0 }
        let fives = stride(from: N.lo.rounded(.up), through: N.hi, by: 1).filter { $0.truncatingRemainder(dividingBy: 5) == 0 }
        func content(_ pen: inout GridPen, _ keep: (CGPoint) -> Bool) {
            N.draw(&pen, "nl", keep: keep, labels: aside != nil ? fives.filter { $0 != 0 } : nil)
            if !placing {
                let p = N.at(t)
                if keep(p) { N6.point(&pen, "pt", p); N6.readout(&pen, "pr", p, Neg6.fm(t), up: up) }
            }
            let prints = at >= 3 ? [-t] + (P.twice && at >= 4 ? [t] : []) : []
            // a new print fades in once the landed half lies over it (N6.flap's turn to 180°)
            pen.sketch.startAt = PaperClock.now + N6.printAt
            defer { pen.sketch.startAt = nil }
            for (j, w) in prints.enumerated() {
                let q = N.at(w)
                guard keep(q) else { continue }
                N6.point(&pen, "pp\(j)", q, shade: 1)
                let lit = at == 4 && s.on("spot") && j == prints.count - 1
                if !(P.twice && j == 1) { N6.readout(&pen, "ppr\(j)\(lit)", q, Neg6.fm(w), up: up, quiet: !lit) }
            }
        }
        // what 0 means, small beside 0 (and 0's number), over a half turning about the 0 line
        func zero(_ pen: inout GridPen) {
            if let z = P.zero {
                if up { pen.label("zero", z, N6.small, .right, edge: N.x0 + 1.2, along: N.y0) }
                else if let sd = aside { pen.word("zeroa", z, at: N.x0 - sd * 0.4, N.y0 - 2.05, N6.small, anchor: UnitPoint(x: sd > 0 ? 1 : 0, y: 0.5)) }
                else { pen.label("zero", z, N6.small, .above, edge: N.y0 - 1.2, along: N.x0) }
            }
        }
        if aside == nil { zero(&pic) }
        content(&pic, base)
        // the landed halves lie back flat (each from where it was let go), carrying what's on them
        for (j, l) in landed.enumerated() {
            let f = Self.fold(N, l.side)
            N6.flap(&pic, "fl\(j)", f, rect: Self.sheet(N, l.side), th: 0, from: l.th, landed: true, gridTop: s.gridTop) { content(&$0) { f.carries($0) } }
        }
        if let (th, sd) = back {
            let f = Self.fold(N, sd)
            N6.flap(&pic, "fb", f, rect: Self.sheet(N, sd), th: 0, from: th, gridTop: s.gridTop) { content(&$0) { f.carries($0) } }
        }
        if let sd = held {
            let f = Self.fold(N, sd)
            N6.flap(&live, "fh", f, rect: Self.sheet(N, sd), th: s.h("th") ?? 0, gridTop: s.gridTop) { content(&$0) { f.carries($0) } }
            zero(&live)
            if up { live.label("z0", "0", N6.small, .left, edge: N.x0 - 0.6, along: N.y0) }
            else { live.word("z0a", "0", at: N.x0 - sd * 0.4, N.y0 + 1.35, N6.small, anchor: UnitPoint(x: sd > 0 ? 1 : 0, y: 0.5)) }
        }
        // the point being placed: it follows the finger, its sign showing as it crosses 0
        if placing {
            let v = s.h("v") ?? 0, p = N.at(v)
            N6.point(&live, "pt", p, held: s.grabbed)
            if s.grabbed || s.h("v") != nil { N6.readout(&live, "pr", p, Neg6.fm(v), up: up) }
            if s.grabbed { live.reads(Neg6.fm(v)) }
        }
        if s.grabbed && held != nil { live.reads(Neg6.fm(-(at == 3 ? -t : t))) }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let Z = N.at(0)
        if at == 1 {
            if s.on("ring") {
                let E = N.at(t < 0 ? N.lo : N.hi)
                if up { R6.ring(&pic, "ring", x: N.x0 - 4, y: min(Z.y, E.y), w: 5.5, h: abs(E.y - Z.y)) }
                else { R6.ring(&pic, "ring", x: min(Z.x, E.x), y: N.y0 - 1, w: abs(E.x - Z.x), h: 3.6) }
            }
            if s.on("spot") { let p = N.at(t); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 2 || at == 3 {
            let cur = at == 2 ? t : -t, r = Self.sheet(N, Self.side(N, cur))
            if s.on("ring") && held == nil { R6.ring(&pic, "ring", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            if s.on("spot") { let p = N.at(-cur); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 4 && s.on("ring") { let p = N.at(P.twice ? t : -t); pic.circle("ring", at: p.x, p.y, radius: 2.4, .chapter, dashed: true) }

        // the record: −(−7) = [7]
        if at >= 4 {
            let ans: M7.Tok = at == 4 ? .box("x", cells: max(2, Neg6.fm(P.ans).count)) : .t(Neg6.fm(P.ans), .chapter)
            M7.row(&rec, "r", [.t("−(\(Neg6.fm(P.start)))"), .op("="), ans], x: 0, line: 1)
        }
        // room for the readout above the line's ends and the flap
        let ext = up ? pic.R(0, -1, N.x0 + 12, 35) : pic.R(N.x0 + N.lo * N.U - 2, N.y0 - 4, (N.hi - N.lo) * N.U + 4, 8)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    /// Upright: the record beside the line, level with 0. Across: under the line's numbers.
    func recordBeside(_ n: Numbers) -> Double? { Negatives6.Parts(n).up ? Self.line(Negatives6.Parts(n)).y0 - 1 : nil }
    func recordRow(_ n: Numbers) -> Double? { let P = Negatives6.Parts(n); return P.up ? nil : Self.line(P).y0 + 5 }

    func hands(_ s: PaperState) -> Hands? {
        let P = Negatives6.Parts(s.numbers), N = Self.line(P), at = stage(s)
        switch at {
        case 1:
            let now = s.h("v") ?? 0
            return Hands(grab: { q in N.near(q) ? ["grab": 1, "v": N.val(q, step: P.step), "from": now] : nil },
                         drag: { q, h in ["grab": 1, "v": N.val(q, step: P.step), "from": h["from"] ?? now] },
                         release: { h in
                             let v = h["v"] ?? 0
                             if v == h["from"] { return HandMove(hand: ["v": v], missHand: nil) }
                             return HandMove(hand: ["v": v], missHand: nil, set: [("x", v)], check: true)
                         })
        case 2, 3:
            let want = Self.side(N, at == 2 ? P.t : -P.t)
            return Hands(grab: { q in
                let band = N.up ? abs(q.x - N.x0) <= 5 && abs(q.y - N.y0) <= 16.5 : abs(q.y - N.y0) <= 4 && abs(q.x - N.x0) <= N.hi * N.U + 2
                let d = N.up ? q.y - N.y0 : q.x - N.x0
                guard band, abs(d) >= 0.5 else { return nil }
                return ["grab": 1, "sd": d > 0 ? 1 : -1, "g": abs(d), "th": 0]
            }, drag: { q, h in
                var h = h
                h["th"] = Self.fold(N, h["sd"] ?? 1).angle(q, grab: h["g"] ?? 1)
                return h
            }, release: { h in
                let th = h["th"] ?? 0, sd = h["sd"] ?? 1
                if th > 1.75 {
                    if sd == want { return HandMove(hand: [:], missHand: [:], set: [("f", 1)], keep: [at == 2 ? "th1" : "th2": th], check: true) }
                    return HandMove(hand: ["back": th, "sd": sd], missHand: ["back": th, "sd": sd], set: [("f", 0)], check: true)
                }
                if th < 0.05 { return HandMove(hand: [:]) }
                return HandMove(hand: ["back": th, "sd": sd])
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Negatives6.Parts(s.numbers), N = Self.line(P)
        switch stage(s) {
        case 1: let a = N.at(s.h("v") ?? 0), b = N.at(P.t); return [.drag(from: a, to: b)]
        case 2, 3:
            let sd = Self.side(N, stage(s) == 2 ? P.t : -P.t), d = N.up ? 8.0 : 12.0
            return N.up ? [.drag(from: CGPoint(x: N.x0, y: N.y0 + sd * d), to: CGPoint(x: N.x0, y: N.y0 - sd * d))]
                : [.drag(from: CGPoint(x: N.x0 + sd * d, y: N.y0), to: CGPoint(x: N.x0 - sd * d, y: N.y0))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Negatives6.Parts(s.numbers), N = Self.line(P)
        switch stage(s) {
        case 1: return HandMove(hand: ["v": -P.t], missHand: nil, set: [("x", -P.t)], check: true)
        case 2, 3:
            let sd = -Self.side(N, stage(s) == 2 ? P.t : -P.t)
            return HandMove(hand: ["back": 2.2, "sd": sd], missHand: ["back": 2.2, "sd": sd], set: [("f", 0)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Negatives6.Parts(s.numbers)
        return stage(s) == 4 ? ["x": P.twice ? -P.t : P.t] : nil
    }
}
