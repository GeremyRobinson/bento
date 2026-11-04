import SwiftUI

/// Dividing fractions on the paper, as in the preview (design/prototype/grade6-ch2.html, dDivide): a whole bar is the
/// fractions family's length (DivideFrac6.wholeLength). a/b shaded on top, c/d striped under it, named at their right
/// ends. Pick More than 1 or Less than 1 (the engine's choice row); lay c/d's along under the a/b (a tap lays one, a drag as
/// many as reach the finger): numbered, the last cut off at the a/b's end, its whole outline dashed, "2 and part of one";
/// cut both bars into the same small pieces with the ruler (the cuts dashed across all three rows, "8 pieces ÷ 3 pieces");
/// then the school way in one line: `2/3 ÷ 1/4 = 2/3 × [ ]/[ ] = [ ]/[ ] = [ ] [ ]/[ ]`. The pieces counted light as
/// the product that counts them is written.
@MainActor
struct DivideFractionsLesson: PaperLesson {
    /// The a/b bar, the copies laid right under it, the c/d bar; the readouts' row, the ruler's.
    static let H = 4.0
    /// Where things go: bars a whole of 69 squares or more (70, 72) have their names over their right ends, so the problem
    /// still shows at 75%, and the bars sit further apart for it.
    struct Lay {
        let above: Bool, Y1: Double, YL: Double, Y2: Double
        init(_ P: DivideFrac6.Parts) {
            above = P.W + 5 > 73
            Y1 = above ? 4 : 0; YL = Y1 + DivideFractionsLesson.H; Y2 = above ? YL + DivideFractionsLesson.H + 5 : 10
        }
        var roY: Double { Y2 + DivideFractionsLesson.H + 1.6 }
        var RY: Double { Y2 + DivideFractionsLesson.H + 2 }
        /// A name's column and top row: right of its bar, or over its right end.
        func name(_ W: Int, _ y: Double) -> (col: Double, row: Double) { above ? (Double(W) - 4, y - 4) : (Double(W) + 1, y) }
    }
    var liveKeys: Set<String> { ["cx", "grab"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func count(_ s: PaperState, _ P: DivideFrac6.Parts) -> Int { stage(s) <= 1 ? 0 : stage(s) == 2 ? Int((s.h("c") ?? 0).rounded()) : P.copies }
    private func cx(_ s: PaperState) -> Int { Int((s.h("cx") ?? 0).rounded()) }
    /// How far a cut-off copy's dashed outline reaches: a square past the names, so the problem still shows at 75%.
    static func reach(_ P: DivideFrac6.Parts) -> Double { Double(P.W) + (Lay(P).above ? 0 : 5) }
    /// The most copies the hand can lay: one past the end when it still fits beside the names.
    static func most(_ P: DivideFrac6.Parts) -> Int { Double((P.copies + 1) * P.Cl) <= reach(P) ? P.copies + 1 : P.copies }
    func recordRow(_ n: Numbers) -> Double? { Lay(DivideFrac6.Parts(n)).RY + 2 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DivideFrac6.Parts(s.numbers), at = stage(s), done = at >= 7
        let lay = Lay(P)
        let W = Double(P.W), Al = Double(P.Al), Cl = Double(P.Cl), Pc = Double(P.P), H = Self.H, Y1 = lay.Y1, YL = lay.YL, Y2 = lay.Y2
        let reach = Self.reach(P), cutDone = at >= 4
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        var actions: [String] = []
        // the two bars, named at their right ends
        F4.bar(&pic, "b1", y: Y1, W: P.W, d: P.b, on: P.a)
        F4.bar(&pic, "b2", y: Y2, W: P.W, d: P.d, on: P.c, striped: true)
        let n1 = lay.name(P.W, Y1), n2 = lay.name(P.W, Y2)
        Bars.fraction(&pic, "n1", P.a, P.b, col: n1.col, row: n1.row)
        Bars.fraction(&pic, "n2", P.c, P.d, col: n2.col, row: n2.row)
        // the copies laid along under the a/b: whole ones striped, the last cut off at the a/b's end (its outline dashed)
        let laid = count(s, P)
        for j in 0..<laid {
            let x0 = Double(j) * Cl, x1 = x0 + Cl
            if x0 >= Al {
                pic.sketch.box("cp\(j)bad", pic.R(x0, YL, Cl, H), Bars.red, width: Sketch.stroke)
                pic.word("cn\(j)bad", "\(j + 1)", at: x0 + Cl / 2, YL + H / 2, Bars.count.colour(Bars.red))
                continue
            }
            let end = min(x1, Al)
            pic.stripes("cp\(j)s", col: x0, row: YL, w: end - x0, h: H)
            if x1 <= Al { pic.sketch.box("cp\(j)o", pic.R(x0, YL, Cl, H), .chapter, width: Sketch.stroke) }
            else {
                let xr = min(x1, reach)
                pic.line("cp\(j)t", [(x0, YL), (xr, YL)], .chapter, dashed: true)
                pic.line("cp\(j)b", [(x0, YL + H), (xr, YL + H)], .chapter, dashed: true)
                if x1 <= reach { pic.line("cp\(j)r", [(x1, YL), (x1, YL + H)], .chapter, dashed: true) }
                pic.line("cp\(j)l", [(x0, YL), (x0, YL + H)], .chapter)
                pic.line("cp\(j)e", [(end, YL), (end, YL + H)], .chapter)
            }
            if !cutDone && end - x0 >= 1.5 { pic.word("cn\(j)", "\(j + 1)", at: (x0 + end) / 2, YL + H / 2, Bars.count) }
        }
        func ro(_ id: String, _ t: String, x: Double = 0) { pic.word(id, t, at: x, lay.roY, R6.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at == 2 && laid > 0 {
            let t = laid == P.copies && P.partLast ? (laid == 1 ? "part of one" : "\(laid - 1) and part of one") : laid > P.copies ? "\(laid)" : "\(laid)"
            ro("lro\(laid)", t)
            if s.grabbed { live.reads(t) }
        }
        // the three rows a cut runs across: the a/b, the copies, the c/d
        let rows: [(Double, Double)] = [(Y1, Al), (YL, min(Double(P.copies) * Cl, reach)), (Y2, Cl)]
        if at == 3 {
            let c = cx(s), RY = lay.RY
            if c > 0 {
                for (r, (y, len)) in rows.enumerated() {
                    for x in stride(from: Double(c), to: len, by: Double(c)) { live.line("dc\(r)_\(Int(x))", [(x, y - 0.6), (x, y + H + 0.6)], .ink2, dashed: true) }
                }
                let t = P.Al % c != 0 || P.Cl % c != 0 ? "pieces of \(c): some over" : "\(P.Al / c) pieces ÷ \(P.Cl / c) pieces"
                live.word("kro", t, at: 0, RY + 1.6, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(t) }
            }
            live.line("ruler", [(0, RY - 0.6), (0, RY), (Double(c), RY), (Double(c), RY - 0.6)], .chapter)
            R6.handle(&live, "rh", Double(c), RY, held: s.grabbed)
            actions = ["Cut"]
        }
        if cutDone {
            for (r, (y, len)) in rows.enumerated() {
                let xs = Array(stride(from: Pc, to: len, by: Pc))
                pic.sketch.segments("sc\(r)", xs.filter { r != 1 || $0 <= Al }.map { x in (pic.P(x, y), pic.P(x, y + H)) }, .chapter, width: Sketch.stroke)
                if r == 1 { for x in xs where x > Al { pic.line("sd\(Int(x))", [(x, y), (x, y + H)], .chapter, dashed: true) } }
            }
            let lit = done || (at >= 6 && P.S == P.S1 && P.L == P.L1)
            let w = Bars.count.colour(lit ? .chapter : .ink)
            if P.P >= 2 {
                for j in 0..<P.S1 { pic.word("p1_\(j)\(lit)", "\(j + 1)", at: Pc * (Double(j) + 0.5), Y1 + H / 2, w) }
                for j in 0..<P.L1 { pic.word("p2_\(j)\(lit)", "\(j + 1)", at: Pc * (Double(j) + 0.5), Y2 + H / 2, w) }
            }
            if P.partLast { pic.word("cov", "\(P.covered) of \(P.L1)", at: Double(P.copies - 1) * Cl + 0.5, YL + H + 1, R6.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
            ro("cro", "\(P.S1) pieces ÷ \(P.L1) pieces")
        }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let roEnd = R6.width("\(P.S1) pieces ÷ \(P.L1) pieces") + 2
        switch at {
        case 1:
            if s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: Y1, w: W - 1, h: Y2 + H - Y1) }
            if s.on("spot") { pic.line("spot", [(Cl, Y1 - 1), (Cl, Y2 + H + 1)], .chapter, dashed: true) }
        case 2:
            if s.on("ring") { R6.ring(&pic, "ring", x: Al - 1.5, y: Y1, w: 3, h: 2 * H) }
            if s.on("spot") { pic.line("spot", [(Al, Y1 - 1), (Al, YL + H + 1)], .chapter, dashed: true) }
        case 3:
            if s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: Y1, w: W - 1, h: Y2 + H - Y1) }
            if s.on("spot") { pic.line("spot", [(Pc, Y1 - 1), (Pc, Y2 + H + 1)], .chapter, dashed: true) }
        case 4:
            if s.on("ring") { R6.ring(&pic, "ring", x: n2.col, y: n2.row, w: 4, h: H) }
            if s.on("spot") { ro("spot", "\(P.c)/\(P.d) flipped is \(P.d)/\(P.c)", x: roEnd) }
        case 5:
            if s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: lay.roY - 0.8, w: roEnd - 1.5 - 1, h: 1.6) }
            if s.on("spot") { ro("spot", "\(P.a) × \(P.d) = \(P.S), \(P.b) × \(P.c) = \(P.L)", x: roEnd) }
        case 6:
            // the whole copies laid (or the a/b, when none fits whole)
            let wholes = P.copies - (P.partLast ? 1 : 0)
            if s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: wholes > 0 ? YL : Y1, w: (wholes > 0 ? Double(wholes) * Cl : Al) - 1, h: H) }
            if s.on("spot") { ro("spot", "\(P.S)/\(P.L) = \(Ratio6.mixed(P.S, P.L))", x: roEnd) }
        default: break
        }
        // the record: a/b ÷ c/d = a/b × [d]/[c] = [S]/[L] = [w] [n]/[d]
        if at >= 4 {
            var toks: [F4.Tok] = [.f("\(P.a)", "\(P.b)"), .op("÷"), .f("\(P.c)", "\(P.d)"), .op("="), .f("\(P.a)", "\(P.b)"), .op("×")]
            toks.append(at == 4 ? .fb(top: .box("fn"), bottom: .box("fd")) : .f("\(P.d)", "\(P.c)", .chapter))
            if at >= 5 { toks += [.op("="), at == 5 ? .fb(top: .box("mn"), bottom: .box("md")) : .f("\(P.S)", "\(P.L)", .chapter)] }
            if at >= 6 && !P.simplest {
                let F = P.F
                toks.append(.op("="))
                if F.whole > 0 { toks.append(done ? .n(F.whole, .chapter) : .box("w", cells: String(F.whole).count)) }
                if F.num > 0 { toks.append(done ? .f("\(F.num)", "\(F.den)", .chapter) : .fb(top: .box("sn"), bottom: .box("sd"))) }
            }
            F4.row(&rec, "r", toks, x: 0, line: 2)
        }
        let wide = max(lay.above ? W : W + 5, min(Double(Self.most(P) * P.Cl), reach))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions,
                            extent: at <= 3 ? pic.R(0, 0, wide, lay.RY + 2.3) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = DivideFrac6.Parts(s.numbers), lay = Lay(P), Cl = Double(P.Cl), Y1 = lay.Y1, Y2 = lay.Y2, H = Self.H
        switch stage(s) {
        case 2:
            let c = count(s, P), most = Self.most(P), right = max(Double(P.W), Double(most * P.Cl)) + 1
            func inside(_ q: CGPoint) -> Bool { q.y >= Y1 - 1 && q.y <= Y2 + H + 1 && q.x >= -1 && q.x <= right }
            func lay(_ n: Int) -> HandMove {
                if n < P.copies { return HandMove(hand: ["c": Double(n)], missHand: nil) }
                return HandMove(hand: ["c": Double(n)], missHand: n > P.copies ? ["c": 0] : nil, set: [("x", Double(n))], check: true)
            }
            return Hands(
                tap: { q in inside(q) && c < P.copies ? lay(c + 1) : nil },
                grab: { q in inside(q) ? ["grab": 1, "c": Double(c), "from": Double(c)] : nil },
                drag: { q, h in ["grab": 1, "from": h["from"] ?? Double(c), "c": Double(max(0, min(most, Int((q.x / Cl).rounded()))))] },
                release: { h in
                    let n = Int((h["c"] ?? 0).rounded())
                    guard Double(n) != h["from"] else { return HandMove(hand: ["c": Double(n)], missHand: nil) }
                    return lay(n)
                })
        case 3:
            let c = cx(s), top = max(P.Al, P.Cl), right = max(Double(P.W), Double(P.copies * P.Cl)) + 1
            func snap(_ x: Double) -> Double { Double(max(1, min(top, Int(x.rounded())))) }
            return Hands(
                grab: { q in q.y >= Y1 - 1 && q.y <= lay.RY + 1.5 && q.x >= -1 && q.x <= right ? ["grab": 1, "cx": snap(q.x)] : nil },
                drag: { q, _ in ["grab": 1, "cx": snap(q.x)] },
                release: { h in HandMove(hand: ["cx": h["cx"] ?? Double(c)], missHand: nil) },
                actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", Double(c))], check: true) }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = DivideFrac6.Parts(s.numbers), lay = Lay(P), Cl = Double(P.Cl)
        switch stage(s) {
        case 2:
            let y = lay.YL + Self.H / 2
            return [.drag(from: CGPoint(x: Double(count(s, P)) * Cl, y: y), to: CGPoint(x: Double(P.copies) * Cl, y: y))]
        case 3:
            let c = Double(cx(s))
            return (c == Double(P.P) ? [] : [.drag(from: CGPoint(x: c, y: lay.RY), to: CGPoint(x: Double(P.P), y: lay.RY))]) + [.tap(.action("Cut"))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DivideFrac6.Parts(s.numbers)
        switch stage(s) {
        case 2:
            let n = Self.most(P) > P.copies ? P.copies + 1 : P.copies - 1
            if n < 1 { return nil }
            return HandMove(hand: ["c": Double(n)], missHand: n > P.copies ? ["c": 0] : nil, set: [("x", Double(n))], check: true)
        case 3:
            // a length that leaves some over (or a smaller one that fits)
            let c = (2...max(2, max(P.Al, P.Cl))).first { P.Al % $0 != 0 || P.Cl % $0 != 0 } ?? 1
            return HandMove(hand: ["cx": Double(c)], missHand: nil, set: [("x", Double(c))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = DivideFrac6.Parts(s.numbers), F = P.F
        switch stage(s) {
        case 4: return ["fn": Double(P.c), "fd": Double(P.d)]
        case 5: return ["mn": Double(P.a * P.c), "md": Double(P.b * P.d)]
        case 6:
            if F.whole > 0 && F.num > 0 { return ["w": 0, "sn": Double(P.S), "sd": Double(P.L)] }
            if F.whole > 0 { return ["w": Double(F.whole + 1)] }
            return ["sn": Double(P.S), "sd": Double(P.L)]
        default: return nil
        }
    }

    func messageRows(_ n: Numbers) -> Int { 1 }
}
