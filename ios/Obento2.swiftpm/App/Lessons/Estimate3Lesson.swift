import SwiftUI

/// Estimate to check on the paper, as in the preview (design/prototype/grade3-ch3.html, dEstimate): the line 0 to 1000 in
/// ten blocks of a hundred (a square is 20), the two numbers' points on it, the friend's answer in the instruction. Drag
/// each number to its nearest hundred (brackets say how far to each end while it's held); hop the rounded second number
/// on (or back), hops of 100 counted; write `458 + 275 ≈ 500 + 300 = [800]`. The friend's answer drops onto the line, a
/// band 100 each side of 800 shades in and a bracket says how far it is from 800: Yes or No.
///
/// Hand: "grab", "w" the number held (0 a, 1 b), "at" where it is, "gA"/"gB" rounded already; on the hop, "k" the hops.
@MainActor
struct Estimate3Lesson: PaperLesson {
    static let LY = 5.0, L = 50.0
    var liveKeys: Set<String> { ["at", "k"] }
    func recordRow(_ n: Numbers) -> Double? { Self.LY + 6 }
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
    static func xOf(_ v: Int) -> Double { Double(v) / 20 }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func got(_ s: PaperState, _ P: Estimate3.Parts) -> (Bool, Bool) {
        let past = stage(s) >= 1
        return (past || (s.h("gA") ?? 0) != 0 || P.a % 100 == 0, past || (s.h("gB") ?? 0) != 0 || P.b % 100 == 0)
    }

    /// Brackets under the line from each end of v's hundred to v, how far written under each.
    private static func brackets(_ p: inout GridPen, _ v: Int) {
        let lo = v / 100 * 100, x0 = xOf(lo), x1 = xOf(lo + 100), xp = xOf(v), by = LY + 3
        let f = PaperText.font(Sketch.small, .medium, digits: true), sL = "\(v - lo) to \(lo)", sR = "\(lo + 100 - v) to \(lo + 100)"
        let wL = PaperText.width(sL, f) / Paper.cell / 2 + 0.3, wR = PaperText.width(sR, f) / Paper.cell / 2 + 0.3
        p.line("brL", [(x0, by - 0.6), (x0, by), (xp, by), (xp, by - 0.6)], .chapter)
        p.line("brR", [(xp, by - 0.6), (xp, by), (x1, by), (x1, by - 0.6)], .chapter)
        var cL = max(x0 + wL - 0.5, (x0 + xp) / 2), cR = min(x1 - wR + 0.5, (xp + x1) / 2)
        if cR - wR < cL + wL + 0.6 { let m = (cL + wL + cR - wR) / 2; cL = m - wL - 0.3; cR = m + wR + 0.3 }
        p.label("brLw", sL, small.colour(.chapter), .below, edge: by, along: cL)
        p.label("brRw", sR, small.colour(.chapter), .below, edge: by, along: cR)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Estimate3.Parts(s.numbers), st = stage(s), judged = st >= 3, LY = Self.LY, X = Self.xOf
        let xs = X(P.ra), (gA, gB) = got(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // the band 100 each side of the estimate, shaded in once the friend's answer is on the line
        if judged {
            pic.sketch.delay = 0.7
            let x0 = X(max(0, P.E - 100)), x1 = X(min(1000, P.E + 100))
            pic.fill("band", col: x0, row: LY - 2, w: x1 - x0, h: 2, .tint(0.42))
            pic.sketch.delay = 0
        }
        // the line: 0 to 1000, a block a hundred, every hundred named under it (the ones in play in colour)
        let lit: Set<Int> = st == 0 ? Set([gA ? P.ra : -1, gB ? P.rb : -1]) : st == 1 ? [P.ra] : [P.E]
        pic.line("ln", [(0, LY), (Self.L, LY)])
        for i in 0...10 {
            let x = Double(i) * 5, on = lit.contains(i * 100)
            pic.line("t\(i)", [(x, LY - (i % 5 == 0 ? 2 : 1)), (x, LY)])
            pic.label("tl\(i)\(on)", "\(i * 100)", Self.small.colour(on ? .chapter : .ink2), .below, edge: LY, along: x)
        }
        // the two numbers: labelled while they're still to round; held, how far it is to each end of its hundred
        let w = Int((s.h("w") ?? -1).rounded()), now = s.h("at")
        let near = abs(X(P.a) - X(P.b)) < 4
        for (n, v, g) in [(0, P.a, gA), (1, P.b, gB)] {
            if g {
                if st == 0 { pic.dot("p\(n)got", at: X(P3.rh(v)), LY, radius: 0.4, .chapter, over: true) }
                else if n == 1 && !judged { pic.dot("p\(n)got", at: X(P3.rh(v)), LY, radius: 0.4, .ink3, over: true) }
                continue
            }
            let held = st == 0 && s.grabbed && w == n, x = held ? (now ?? X(v)) : X(v)
            if held {
                live.dot("was\(n)", at: X(v), LY, radius: 0.3, .ink3, over: true)
                Self.brackets(&live, v)
                let lo = v / 100 * 100
                live.reads("\(v - lo) to \(lo) · \(lo + 100 - v) to \(lo + 100)")
                live.dot("p\(n)", at: x, LY, radius: 0.55, .ink, over: true)
                live.label("pl\(n)", "\(v)", Self.small, .above, edge: LY - 2.1 - (near && n == 1 ? 2 : 0), along: x)
            } else {
                pic.dot("p\(n)", at: x, LY, radius: 0.4, .ink, over: true)
                pic.label("pl\(n)", "\(v)", Self.small, .above, edge: LY - 2.1 - (near && n == 1 ? 2 : 0), along: x)
            }
        }
        // hints: each number's hundred ringed (a first miss), then the hundred it rounds to (a second)
        if st == 0 {
            for (v, g) in [(P.a, gA), (P.b, gB)] where !g {
                if s.on("spot") { pic.circle("hs\(v)", at: X(P3.rh(v)), LY, radius: 1.3, .chapter, dashed: true) }
                else if s.on("ring") { KK.hintBox(&pic, "hr\(v)", x: X(v / 100 * 100), y: LY - 2, w: 5, h: 2) }
            }
        }
        // the hops of 100 from the first number, counted; the handle at the end of the last hop
        if st == 1 || st == 2 {
            let k = st == 1 ? Int((s.h("k") ?? 0).rounded()) : P.rb / 100
            var pen = st == 1 ? live : pic
            for i in stride(from: 1, through: max(1, k), by: 1) where k >= 1 {
                let x1 = xs + Double(P.s) * Double(i - 1) * 5, x2 = xs + Double(P.s) * Double(i) * 5
                pen.hop("hop\(i)", from: x1, to: x2, row: LY, height: 1.7)
                pen.word("hopn\(i)", "\(i)", at: (x1 + x2) / 2, LY - 2.6, Self.small.colour(.chapter))
            }
            if st == 1 {
                live = pen
                if s.grabbed { live.reads("\(G3.count(k, "hop")) · \(P.ra + P.s * k * 100)") }
                live.dot("hand", at: xs + Double(P.s * k) * 5, LY, radius: 0.55, .ink, over: true)
                if s.on("spot") { pic.circle("hs", at: X(P.E), LY, radius: 1.3, .chapter, dashed: true) }
                else if s.on("ring") { pic.circle("hr", at: xs, LY, radius: 1.3, .chapter, dashed: true) }
            } else {
                pic = pen
                pic.dot("est", at: X(P.E), LY, radius: 0.4, .chapter, over: true)
            }
            pic.dot("hopA", at: xs, LY, radius: 0.4, .chapter, over: true)
        }
        if judged {
            pic.dot("est", at: X(P.E), LY, radius: 0.4, .chapter, over: true)
            // the friend's answer drops onto the line; a bracket under it says how far it is from the estimate
            let xf = X(P.f), c = pic.P(xf, LY - 5), r = 0.5 * Paper.cell
            pic.sketch.from["leo"] = .plate((0..<24).map { i in let a = Double(i) / 24 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) })
            pic.dot("leo", at: xf, LY, radius: 0.4, .ink, over: true)
            pic.label("leol", "\(P.f)", Self.small, .above, edge: LY - 2.1, along: xf)
            if P.gap > 0 {
                pic.sketch.delay = 0.8
                let by = LY + 3, x0 = X(min(P.f, P.E)), x1 = X(max(P.f, P.E))
                pic.line("gapbr", [(x0, by - 0.6), (x0, by), (x1, by), (x1, by - 0.6)], .chapter)
                pic.label("gapw", "\(P.gap)", Self.small.colour(.chapter), .below, edge: by, along: (x0 + x1) / 2)
                pic.sketch.delay = 0
            }
        }

        // the record: 458 + 275 ≈ 500 + 300 = [800]; then why the friend's answer is or isn't close
        var toks: [M7.Tok] = [.n(P.a), .op(P.sign), .n(P.b), .op("≈"), .n(P.ra), .op(P.sign), .n(P.rb)]
        if st >= 2 { toks.append(.op("=")); toks.append(M3.box("E", P.E, cells: M3.cells(P.E), right: st >= 3)) }
        if st >= 1 { M7.row(&rec, "rec", toks, x: 0, line: 1) }
        if st == 3 {
            // Yes or No, tapped in the picture's squares under the record (red or green for its moment)
            let w = s.h("wrong"), r = s.h("picked"), y = Self.LY + 11
            T3.block(&pic, "yes", x: 0, y: y, w: 4, "Yes", wrong: w == 0, right: r == 0)
            T3.block(&pic, "no", x: 5, y: y, w: 4, "No", wrong: w == 1, right: r == 1)
        }
        if st == 3 { rec.word("see", "Each number moved 50 or less, so the answer is in here.", at: 0, 3.4, Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), anchor: UnitPoint(x: 0, y: 0.5)) }
        if st == 4 { rec.word("rec2", P.record, at: 0.4, 4, Record.words, anchor: UnitPoint(x: 0, y: 0.5)) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Estimate3.Parts(s.numbers), LY = Self.LY, X = Self.xOf, xs = X(P.ra), (gA, gB) = got(s, P)
        let keep: Numbers = ["gA": gA ? 1 : 0, "gB": gB ? 1 : 0]
        switch stage(s) {
        case 0:
            return Hands(
                grab: { q in
                    guard abs(q.y - LY) <= 2.5 else { return nil }
                    var best: Int? = nil, bd = 2.5
                    for (n, v, g) in [(0, P.a, gA), (1, P.b, gB)] where !g && abs(q.x - X(v)) < bd { bd = abs(q.x - X(v)); best = n }
                    guard let n = best else { return nil }
                    var h = keep; h["grab"] = 1; h["w"] = Double(n); h["at"] = X(n == 0 ? P.a : P.b)
                    return h
                },
                drag: { q, h in var h = h; h["at"] = min(Self.L, max(0, q.x)); return h },
                release: { h in
                    let n = Int((h["w"] ?? 0).rounded()), v = n == 0 ? P.a : P.b, at = h["at"] ?? X(v), kx = (at / 5).rounded() * 5
                    if kx == X(P3.rh(v)) {
                        var k = keep; k[n == 0 ? "gA" : "gB"] = 1
                        let both = (k["gA"] ?? 0) != 0 && (k["gB"] ?? 0) != 0
                        return HandMove(hand: k, missHand: k, set: both ? [("x", 1)] : [], check: both)
                    }
                    if abs(at - X(v)) < 1 { return HandMove(hand: keep, missHand: keep, set: [], check: false) }
                    let low = v % 100 == 50 && kx == X(v / 100 * 100)
                    return HandMove(hand: keep, missHand: keep, set: [("x", Double((low ? 4 : 2) + n))], check: true)
                })
        case 1:
            let k = Int((s.h("k") ?? 0).rounded()), kMax = P.s == 1 ? Int((Self.L - xs) / 5) : Int(xs / 5)
            return Hands(
                grab: { q in abs(q.y - LY) <= 2.5 && abs(q.x - (xs + Double(P.s * k) * 5)) <= 2.5 ? ["grab": 1, "k": Double(k)] : nil },
                drag: { q, _ in ["grab": 1, "k": Double(max(0, min(kMax, Int((Double(P.s) * (q.x - xs) / 5).rounded()))))] },
                release: { h in
                    let n = Int((h["k"] ?? 0).rounded())
                    if n == 0 { return HandMove(hand: ["k": 0], missHand: ["k": 0], set: [], check: false) }
                    return HandMove(hand: ["k": Double(n)], missHand: ["k": 0], set: [("k", Double(n))], check: true)
                })
        case 3:
            return Hands(tap: { q in
                guard q.y >= LY + 10.7, q.y <= LY + 13.3 else { return nil }
                let v: Double? = q.x >= -0.3 && q.x <= 4.3 ? 0 : q.x >= 4.7 && q.x <= 9.3 ? 1 : nil
                return v.map { HandMove(hand: ["picked": $0], missHand: ["wrong": $0], set: [("c", $0)], check: true) }
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Estimate3.Parts(s.numbers), X = Self.xOf, LY = Self.LY, (gA, gB) = got(s, P)
        switch stage(s) {
        case 0:
            var m: [GhostMove] = []
            for (v, g) in [(P.a, gA), (P.b, gB)] where !g { m.append(.drag(from: CGPoint(x: X(v), y: LY), to: CGPoint(x: X(P3.rh(v)), y: LY))) }
            return m
        case 1:
            let xs = X(P.ra), k = Double(Int((s.h("k") ?? 0).rounded()))
            return [.drag(from: CGPoint(x: xs + Double(P.s) * k * 5, y: LY), to: CGPoint(x: X(P.E), y: LY))]
        case 3: return [.tap(.picture(CGPoint(x: P.yes ? 2 : 7, y: LY + 12)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Estimate3.Parts(s.numbers)
        switch stage(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("x", 2)], check: true)
        case 1:
            let k = P.rb / 100 == 1 ? 2 : P.rb / 100 - 1
            return HandMove(hand: ["k": Double(k)], missHand: ["k": 0], set: [("k", Double(k))], check: true)
        case 3: let v: Double = P.yes ? 1 : 0; return HandMove(hand: ["picked": v], missHand: ["wrong": v], set: [("c", v)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Estimate3.Parts(s.numbers)
        return stage(s) == 2 ? ["E": Double(P.ra - P.s * P.rb)] : nil
    }
}
