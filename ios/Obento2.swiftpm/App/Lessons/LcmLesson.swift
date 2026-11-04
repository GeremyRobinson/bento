import SwiftUI

/// Least common multiple on the paper, as in the preview (design/prototype/grade6-ch2.html, dLcm): one square a number
/// (two while the line is 24 or shorter), a tick a square, numbers on the fives (the grid's strong lines). Hop b along
/// the line (a tap lays a hop, a drag lays as many as reach the finger): each landing numbered above, "6, 12, 18, 24"
/// under the line. Then tap the first landing a goes into: a's hops come under the line to it (a miss shows where they
/// jump over). Then `LCM(4, 6) = 12` and `12 ÷ 4 = [ ]` are written.
@MainActor
struct LcmLesson: PaperLesson {
    /// The line's row, the landings' numbers above it, the readout under it.
    static let Y = 3.0, labelY = 0.6, roY = 6.6
    var liveKeys: Set<String> { ["grab"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func hops(_ s: PaperState, _ P: Lcm6.Parts) -> Int { stage(s) == 1 ? Int((s.h("h") ?? 0).rounded()) : stage(s) == 0 ? 0 : P.hops }
    func recordRow(_ n: Numbers) -> Double? { 9 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Lcm6.Parts(s.numbers), at = stage(s), U = Double(P.U), Y = Self.Y, a = P.a, b = P.b, L = P.L
        func xv(_ v: Int) -> Double { Double(v) * U }
        let endX = xv(P.N)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // a's hops under the line: to the landing tapped (or just past it), then to the LCM
        let tapped = at == 2 ? s.h("t").map { Int($0.rounded()) } : nil
        let to = at == 2 ? tapped.map { P.aTo($0) } ?? 0 : at >= 3 ? L : 0
        // the line, a tick a square (a strong one on the fives), numbered on the fives
        pic.line("ln", [(0, Y), (endX, Y)])
        if to > P.N { pic.line("lnx\(to)", [(endX, Y), (xv(to), Y)], .ink, dashed: true) }
        pic.sketch.segments("tk", (0...P.N).map { v in (pic.P(xv(v), Y), pic.P(xv(v), Y + (v % 5 == 0 ? 0.8 : 0.5))) }, .ink, width: Sketch.stroke)
        for v in stride(from: 0, through: P.N, by: 5) { pic.word("tn\(v)", "\(v)", at: xv(v), Y + 1.85, R6.small) }
        pic.word("nb", "\(b)s", at: endX + 1.5, Y - 1.2, R6.small, anchor: UnitPoint(x: 0, y: 0.5))
        if at >= 2 { pic.word("na", "\(a)s", at: endX + 1.5, Y + 1.2, R6.small, anchor: UnitPoint(x: 0, y: 0.5)) }
        // b's hops above, each landing numbered
        let h = hops(s, P)
        for j in stride(from: 1, through: h, by: 1) {
            pic.hop("bh\(j)", from: xv(b * (j - 1)), to: xv(b * j), row: Y, height: 1.5)
            pic.word("bl\(j)", "\(b * j)", at: xv(b * j), Self.labelY, R6.lit)
        }
        for j in stride(from: 1, through: to / a, by: 1) { pic.hop("ah\(j)", from: xv(a * (j - 1)), to: xv(a * j), row: Y, height: -1.2, .ink) }
        if let t = tapped, t != L { pic.circle("bad\(t)", at: xv(t), Self.labelY, radius: 1.05, Bars.red) }
        if at >= 3 { pic.circle("ok", at: xv(L), Self.labelY, radius: 1.05, .chapter) }
        // the readout: b's landings while hopping, a's once they hop
        if at == 1 && h > 0 {
            let ro = Lcm6.Parts.list(h, b)
            live.word("ro", ro, at: 0, Self.roY, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if s.grabbed { live.reads(ro) }
        }
        if to > 0 {
            let spot = at == 3 && s.on("spot")
            pic.word("roa\(to)\(spot)", Lcm6.Parts.list(to / a, a) + (spot ? ": \(to / a) hops" : ""), at: 0, Self.roY, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        if at == 1 && s.on("ring") { R6.ring(&pic, "ring", x: endX - 1.5, y: Y - 1, w: 1.5, h: 2) }
        if at == 1 && s.on("spot") { for j in 1...P.hops { pic.line("spot\(j)", [(xv(b * j), Y - 1.2), (xv(b * j), Y)], .chapter) } }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: Self.labelY - 0.8, w: endX + 0.5 - 1, h: 1.6) }
        if at == 2 && s.on("spot") { pic.circle("spot", at: xv(L), Self.labelY, radius: 1.3, .chapter, dashed: true) }
        if at == 3 && s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: Y, w: xv(L) - 1, h: 1.4) }
        // the record
        if at >= 3 {
            M7.row(&rec, "r1", [.t("LCM(\(a), \(b))"), .op("="), .n(L, .chapter)], x: 0, line: 1)
            let ans: M7.Tok = at == 3 ? .box("x", cells: String(L / a).count) : .n(L / a, .chapter)
            M7.row(&rec, "r2", [.n(L), .op("÷"), .n(a), .op("="), ans], x: 0, line: 4)
        }
        let reach = max(endX, xv(P.aTo(P.N))) + 2.5 + R6.width("\(b)s")
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: at <= 2 ? pic.R(0, 0, reach, Self.roY + 1) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Lcm6.Parts(s.numbers), at = stage(s), U = Double(P.U), Y = Self.Y, b = P.b
        let endX = Double(P.N) * U
        switch at {
        case 1:
            let h = hops(s, P)
            func inside(_ q: CGPoint) -> Bool { q.y >= Y - 4.5 && q.y <= Y + 2.5 && q.x >= -1 && q.x <= endX + 2 }
            func lay(_ n: Int) -> HandMove { HandMove(hand: ["h": Double(n)], missHand: nil, set: [("x", Double(n))], check: true) }
            return Hands(
                tap: { q in inside(q) && h < P.hops ? (h + 1 == P.hops ? lay(h + 1) : HandMove(hand: ["h": Double(h + 1)], missHand: nil)) : nil },
                grab: { q in inside(q) ? ["grab": 1, "h": Double(h), "from": Double(h)] : nil },
                drag: { q, hd in ["grab": 1, "from": hd["from"] ?? Double(h), "h": Double(max(0, min(P.hops, Int((q.x / (Double(b) * U)).rounded()))))] },
                release: { hd in
                    let n = Int((hd["h"] ?? 0).rounded())
                    // let go where it began, or with no hops: nothing to check
                    guard Double(n) != hd["from"], n > 0 else { return HandMove(hand: ["h": Double(n)], missHand: nil) }
                    return lay(n)
                })
        case 2:
            return Hands(tap: { q in
                guard q.y >= Y - 4, q.y <= Y + 1.5 else { return nil }
                let j = Int((q.x / (Double(b) * U)).rounded())
                guard j >= 1, j <= P.hops else { return nil }
                return HandMove(hand: [:], missHand: ["t": Double(j * b)], set: [("x", Double(j * b))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Lcm6.Parts(s.numbers), U = Double(P.U)
        switch stage(s) {
        case 1: return [.drag(from: CGPoint(x: Double(hops(s, P) * P.b) * U, y: Self.Y), to: CGPoint(x: Double(P.N) * U, y: Self.Y))]
        case 2: return [.tap(.picture(CGPoint(x: Double(P.L) * U, y: Self.labelY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Lcm6.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: ["h": Double(P.hops - 1)], missHand: nil, set: [("x", Double(P.hops - 1))], check: true)
        case 2:
            let v = P.b == P.L ? 2 * P.b : P.b
            return HandMove(hand: [:], missHand: ["t": Double(v)], set: [("x", Double(v))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Lcm6.Parts(s.numbers)
        return stage(s) == 3 ? ["x": Double(P.L / P.b == P.L / P.a ? P.L / P.a + 1 : P.L / P.b)] : nil
    }
}
