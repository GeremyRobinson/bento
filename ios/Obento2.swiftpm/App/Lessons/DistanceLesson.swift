import SwiftUI

/// Distance on a number line on the paper, as in the preview (design/prototype/grade6-ch4.html, dNumline): the web's
/// line across from a − 1 to b + 1, two squares a step (four when both are within 5 of 0), 0 on a strong line, dots at a
/// and b, numbers at a, 0 and b. Drag a bracket from the left dot to 0 ("3 steps"), then from 0 to the right dot; write
/// `|−3| + |5| = 3 + 5 = [8]`, and the two brackets join into one, "8 apart".
@MainActor
struct DistanceLesson: PaperLesson {
    static let Y = 4.0
    var liveKeys: Set<String> { ["br"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    static func line(_ P: Distance6.Parts) -> N6.Line {
        let U = Double(P.U), x0 = (((1 - Double(P.a)) * U + 1) / 5).rounded(.up) * 5
        return N6.Line(x0: x0, y0: Y, U: U, lo: Double(P.a - 1), hi: Double(P.b + 1))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Distance6.Parts(s.numbers), at = stage(s), N = Self.line(P), Y = Self.Y, a = Double(P.a), b = Double(P.b)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        N.draw(&pic, "nl", labels: [a, 0, b])
        for (k, v) in [("da", a), ("db", b)] { let p = N.at(v); pic.dot(k, at: p.x, p.y, radius: 0.45, .chapter, over: true) }
        let lev = Y - 1.6
        func bracket(_ pen: inout GridPen, _ id: String, _ from: Double, _ to: Double, _ text: String?) {
            N6.bracket(&pen, id, from: N.at(from).x, to: N.at(to).x, line: Y, level: lev, text)
        }
        if at >= 4 {
            // the two brackets join into one: the left one stretches to b
            let pts = [N.at(a).x, N.at(0).x].map { pic.P($0, 0).x }
            pic.sketch.from["all"] = .line([CGPoint(x: pts[0], y: pic.P(0, Y - 0.7).y), CGPoint(x: pts[0], y: pic.P(0, lev).y), CGPoint(x: pts[1], y: pic.P(0, lev).y), CGPoint(x: pts[1], y: pic.P(0, Y - 0.7).y)], width: Sketch.stroke, dashed: false)
            bracket(&pic, "all", a, b, "\(P.sum) apart")
        } else {
            if at >= 2 { bracket(&pic, "bn", a, 0, Distance6.Parts.steps(-P.a)) }
            if at >= 3 { bracket(&pic, "bp", 0, b, Distance6.Parts.steps(P.b)) }
        }
        if (at == 1 || at == 2), s.grabbed, let br = s.h("br") {
            let from = at == 1 ? a : 0, n = Int(abs(br - from).rounded())
            bracket(&live, "bl", from, br, n == 0 ? nil : Distance6.Parts.steps(n))
            live.reads(Distance6.Parts.steps(n))
        }
        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        if at == 1 || at == 2 {
            let (from, to) = at == 1 ? (a, 0.0) : (0.0, b)
            if s.on("ring") { let x0 = N.at(from).x, x1 = N.at(to).x; R6.ring(&pic, "ring", x: x0, y: Y - 1, w: x1 - x0, h: 3.6) }
            if s.on("spot") { let p = N.at(to); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        }
        if at == 3 && s.on("ring") { let x0 = N.at(a).x, x1 = N.at(b).x; R6.ring(&pic, "ring", x: x0, y: lev - 1.6, w: x1 - x0, h: Y - lev + 1.6) }
        if at == 3 && s.on("spot") {
            for (k, v) in [("s1", a / 2), ("s2", b / 2)] { let p = N.at(v); pic.circle(k, at: p.x, lev - 0.9, radius: 2.2, .chapter, dashed: true) }
        }
        // the record
        if at >= 3 {
            let ans: M7.Tok = at == 3 ? .box("x", cells: 2) : .n(P.sum, .chapter)
            M7.row(&rec, "r", [.t("|\(fmt(a))|"), .op("+"), .t("|\(P.b)|"), .op("="), .n(-P.a), .op("+"), .n(P.b), .op("="), ans], x: 0, line: 1)
        }
        let right = N.at(N.hi).x + 2
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, Y + 2.5))
    }

    func recordRow(_ n: Numbers) -> Double? { Self.Y + 5 }

    func hands(_ s: PaperState) -> Hands? {
        let P = Distance6.Parts(s.numbers), N = Self.line(P), at = stage(s), a = Double(P.a), b = Double(P.b)
        guard at == 1 || at == 2 else { return nil }
        let from = at == 1 ? a : 0, to = at == 1 ? 0 : b
        return Hands(grab: { q in
            let p = N.at(from)
            return hypot(q.x - p.x, q.y - p.y) <= 2.2 ? ["grab": 1, "br": from] : nil
        }, drag: { q, _ in ["grab": 1, "br": min(b, max(a, N.val(q)))]
        }, release: { h in
            let v = h["br"] ?? from
            if v == from { return HandMove(hand: [:]) }
            return HandMove(hand: [:], missHand: [:], set: [("x", v == to ? to : v)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Distance6.Parts(s.numbers), N = Self.line(P)
        switch stage(s) {
        case 1: return [.drag(from: N.at(Double(P.a)), to: N.at(0))]
        case 2: return [.drag(from: N.at(0), to: N.at(Double(P.b)))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Distance6.Parts(s.numbers)
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("x", Double(P.a == -1 ? 1 : -1))], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("x", Double(P.b + 1))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Distance6.Parts(s.numbers)
        return stage(s) == 3 ? ["x": Double(abs(P.b + P.a))] : nil
    }
}
