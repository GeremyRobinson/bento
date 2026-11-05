import SwiftUI

/// Time to the minute on the paper, as in the preview (design/prototype/grade3-ch6.html, dClock): one square is a minute. The
/// clock face 20 squares across, its middle on a grid crossing, numbers 1–12 and 60 minute marks; under it the hour laid out
/// straight, 60 squares from 0 to 60, the clock's numbers over its strong lines and the minutes under them. Read: tap the
/// hour (the number the short hand has passed; it's ringed); drag along the hour line from 0: a ghost long hand turns with
/// the finger and the line fills ("47 minutes" beside the face); let go where the ghost lies on the long hand; write
/// `[9]:[47]` right of the face. Set: turn the long hand round the face (it snaps to minute marks, the short hand creeps and
/// the hour line's point moves with it, "4:23"); the record writes 4:23.
///
/// Hand: drag "grab", "n" (minutes); turn "grab", "n", "acc" (degrees gone round), "prev", "mv", "gx", "gy".
@MainActor
struct Clock3Lesson: PaperLesson {
    var liveKeys: Set<String> { ["acc", "prev", "mv", "gx", "gy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let R = 10.0, cx = 30.0, cy = 10.0, LY = 25.0, RX = 45.0, RY = 8.0, nr = 7.4
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
    static func point(_ deg: Double, _ r: Double) -> CGPoint { CGPoint(x: cx + r * sin(deg * .pi / 180), y: cy - r * cos(deg * .pi / 180)) }
    static func angle(_ q: CGPoint) -> Double { atan2(q.x - cx, -(q.y - cy)) * 180 / .pi }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? { [2, 3, 6].contains(at(s)) ? CGPoint(x: Self.RX, y: Self.RY + 3) : nil }

    /// A hand at `deg`, `len` long and `w` wide at the hub.
    private func hand(_ pen: inout GridPen, _ id: String, _ deg: Double, _ len: Double, _ w: Double, _ c: Sketch.Colour = .ink) {
        let r = deg * .pi / 180, u = (sin(r), -cos(r)), n = (cos(r), sin(r))
        func p(_ t: Double, _ s: Double) -> CGPoint { pen.P(Self.cx + u.0 * t + n.0 * s, Self.cy + u.1 * t + n.1 * s) }
        let pts = [p(0, w / 2), p(len, 0), p(0, -w / 2), p(-1, 0)]
        pen.sketch.polygon(id, pts, c); pen.sketch.line(id + "o", pts + [pts[0]], c, width: Sketch.stroke)
    }
    private func hands(_ pen: inout GridPen, H: Int, minutes mm: Int) {
        hand(&pen, "lh", Double(mm) * 6, 8.2, 0.55)
        hand(&pen, "sh", (Double(H % 12) + Double(mm) / 60) * 30, 5.3, 1.2)
        pen.dot("hub", at: Self.cx, Self.cy, radius: 0.45, .ink)
    }
    /// The hour line's fill and point at n minutes.
    private func onLine(_ pen: inout GridPen, _ n: Int, held: Bool) {
        if n > 0 { pen.fill("lf", col: 0, row: Self.LY - 1, w: Double(n), h: 1, .tint(0.45)) }
        pen.dot("lp", at: Double(n), Self.LY, radius: held ? 0.7 : 0.55, .ink, over: true)
    }
    private func readout(_ pen: inout GridPen, _ text: String) {
        pen.word("ro", text, at: Self.cx - Self.R - 2, Self.cy, KK.words.colour(.chapter), anchor: UnitPoint(x: 1, y: 0.5))
        pen.reads(text)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Clock3.Parts(s.numbers), st = at(s), H = P.H, M = P.M, LY = Self.LY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let n = Int((s.h("n") ?? 0).rounded()), held = s.grabbed
        // the face: a circle, 60 minute marks (every fifth longer), the numbers
        pic.circle("face", at: Self.cx, Self.cy, radius: Self.R, .ink)
        var marks: [(CGPoint, CGPoint)] = []
        for j in 0..<60 {
            let a = Self.point(Double(j) * 6, Self.R), b = Self.point(Double(j) * 6, Self.R - (j % 5 == 0 ? 1.3 : 0.6))
            marks.append((pic.P(a.x, a.y), pic.P(b.x, b.y)))
        }
        pic.sketch.segments("marks", marks, .ink, width: Sketch.stroke)
        let wh = st == 0 ? s.run.kept["wh"].map { Int($0) } : nil, picked = !P.setting && st >= 1 ? H : nil
        for j in 1...12 {
            let p = Self.point(30 * Double(j), Self.nr), c: Sketch.Colour = wh == j ? KK.red : picked == j ? .chapter : .ink
            pic.word("cn\(j)\(c == .ink ? "" : wh == j ? "x" : "p")", "\(j)", at: p.x, p.y, KK.maths.colour(c))
        }
        if let picked { let p = Self.point(30 * Double(picked), Self.nr); pic.circle("pk", at: p.x, p.y, radius: 1.55, .chapter) }
        // the hands: the time; set, the long hand where it's turned to (live while it's held)
        let mm = st == 5 ? n : M
        if st == 5 && held { hands(&live, H: H, minutes: mm) } else { hands(&pic, H: H, minutes: mm) }
        // (read) a ghost long hand turns with the finger along the hour line
        if st == 1 && n > 0 { hand(&live, "gh", Double(n) * 6, 8.2, 0.4, .tint(0.6)) }
        // the hour laid out straight: a square a minute, the clock's numbers over the strong lines, the minutes under them
        pic.rule("hl", from: 0, to: 60, row: LY)
        var tk: [(CGPoint, CGPoint)] = []
        for j in 0...60 { tk.append((pic.P(Double(j), LY), pic.P(Double(j), LY - (j % 5 == 0 ? 1.2 : 0.6)))) }
        pic.sketch.segments("hlt", tk, .ink, width: Sketch.stroke)
        for j in 0...12 {
            pic.word("hn\(j)", "\(j % 12 == 0 ? 12 : j)", at: 5 * Double(j), LY - 2.05, Self.small)
            pic.word("hm\(j)", "\(5 * j)", at: 5 * Double(j), LY + 1.2, Self.small)
        }
        switch st {
        case 1, 5: if held { onLine(&live, n, held: true) } else { onLine(&pic, n, held: false) }
        case 2, 3: onLine(&pic, M, held: false)
        case 6: onLine(&pic, M, held: false)
        default: break
        }
        // the readout beside the face, on its left
        if st == 1 && (held || n > 0) { var pen = held ? live : pic; readout(&pen, Ms3.plural(n, "minute", "minutes")); if held { live = pen } else { pic = pen } }
        if st == 5 { var pen = held ? live : pic; readout(&pen, "\(H):\(Ms3.two(n))"); if held { live = pen } else { pic = pen } }
        // the record beside the face, on its right
        if st == 2 { M7.row(&rec, "rec", [.box("x", cells: 2), .op(":"), .box("y", cells: 2)], x: Self.RX, line: Self.RY) }
        if st == 3 || st == 6 { M7.row(&pic, "rec", [.t(P.time, .chapter)], x: Self.RX, line: Self.RY) }
        // hints: a first miss rings the general area, a second the exact spot
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let block5 = Double(M / 5 * 5)
        switch st {
        case 0:
            let short = Self.point((Double(H % 12) + Double(M) / 60) * 30, 3)
            if ring { KK.hint(&pic, "hr", short.x, short.y, radius: 3.4) }
            if spot { let p = Self.point(30 * Double(H), Self.nr); KK.hint(&pic, "spot", p.x, p.y, radius: 1.9) }
        case 1, 5:
            if ring { KK.hintBox(&pic, "hr", x: block5, y: LY - 3, w: 5, h: 4.5) }
            if spot { pic.circle("spot", at: Double(M), LY, radius: 1.1, .chapter, dashed: true); let p = Self.point(Double(M) * 6, Self.R - 0.3); pic.circle("spot2", at: p.x, p.y, radius: 1.1, .chapter, dashed: true) }
        case 2:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: LY - 3, w: Double(M), h: 4.5) }
            if spot { A1.note(&pic, "spot", P.time, x: Self.RX, y: Self.RY - 2.4) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-1, 0, 62, LY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Clock3.Parts(s.numbers), st = at(s), LY = Self.LY
        switch st {
        case 0:
            return Hands(tap: { q in
                guard let n = (1...12).first(where: { let p = Self.point(30 * Double($0), Self.nr); return abs(q.x - p.x) <= 1.8 && abs(q.y - p.y) <= 1.8 }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("h", Double(n))], keep: ["wh": n == P.H ? -1 : Double(n)], check: true)
            })
        case 1:
            return Hands(
                grab: { q in abs(q.y - LY) <= 3 && q.x >= -2 && q.x <= 62 ? ["grab": 1, "n": Double(max(0, min(59, Int(q.x.rounded()))))] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(0, min(59, Int(q.x.rounded())))); return h },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard n > 0 else { return HandMove(hand: ["n": 0]) }
                    return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("n", Double(n))], check: true)
                })
        case 5:
            let n0 = Int((s.h("n") ?? 0).rounded())
            return Hands(
                grab: { q in
                    guard hypot(q.x - Self.cx, q.y - Self.cy) <= Self.R + 1.5 else { return nil }
                    return ["grab": 1, "n": Double(n0), "acc": Double(n0) * 6, "prev": Self.angle(q), "mv": 0, "gx": q.x, "gy": q.y]
                },
                drag: { q, h in
                    var h = h
                    if hypot(q.x - (h["gx"] ?? q.x), q.y - (h["gy"] ?? q.y)) > 0.4 { h["mv"] = 1 }
                    let a = Self.angle(q)
                    var d = a - (h["prev"] ?? a)
                    if d > 180 { d -= 360 }
                    if d <= -180 { d += 360 }
                    let acc = max(0, min(359.9, (h["acc"] ?? 0) + d))
                    h["acc"] = acc; h["prev"] = a
                    h["n"] = Double(max(0, min(59, Int((acc / 6).rounded()))))   // snaps to the minute marks
                    return h
                },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard h["mv"] == 1, n > 0 else { return HandMove(hand: ["n": Double(n)]) }
                    return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("t", Double(n))], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Clock3.Parts(s.numbers)
        switch at(s) {
        case 0: return [.tap(.picture(Self.point(30 * Double(P.H), Self.nr)))]
        case 1: return [.drag(from: CGPoint(x: 0.5, y: Self.LY), to: CGPoint(x: Double(P.M), y: Self.LY))]
        case 5:
            let a = 6 * (s.h("n") ?? 0), b = 6 * Double(P.M), k = max(2, Int(abs(b - a) / 15))
            var out: [CGPoint] = []
            for i in 0...k { out.append(Self.point(a + (b - a) * Double(i) / Double(k), 6)) }
            return [.path(out)]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Clock3.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("h", Double(P.next))], keep: ["wh": Double(P.next)], check: true)
        case 1: let n = P.M > 2 ? P.M - 2 : P.M + 2; return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("n", Double(n))], check: true)
        case 5: let n = P.M <= 54 ? P.M + 5 : P.M - 5; return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("t", Double(n))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Clock3.Parts(s.numbers)
        guard at(s) == 2 else { return nil }
        return P.M >= 10 && P.M % 5 != 0 ? ["x": Double(P.H), "y": Double(P.M / 5)] : ["x": Double(P.next), "y": Double(P.M)]
    }
}
