import SwiftUI

/// Unit fractions on the paper, as in the preview (design/prototype/grade3-ch5.html, dUnitFrac): the bar, a whole of 48
/// squares and 8 tall, cut into b parts with k shaded. Tap each part: it numbers as it's tapped, "4 parts" beside the bar;
/// Check. Slide one part up: the bar glides down two blocks to make room, the part follows the finger up and its place stays
/// dashed. Write `1 part = [1]/[4]` under the bar. With 2 or more shaded, hop it along the shaded parts: it lays itself on
/// each in turn, counting 1, 2, 3; write `shaded = [3]/[4]` beside the first line; the bar glides home and the shaded parts
/// are named 1/4, 2/4, 3/4 under it.
///
/// Hand: count "m" the parts tapped (bits), "o<i>" the order part i was tapped in; slide "grab", "held" the part, "gy" where
/// it was grabbed, "up" 1 once it's lifted; hop "grab", "h" the hops, "h0" before. Kept "p" the part slid up.
@MainActor
struct UnitFrac3Lesson: PaperLesson {
    static let BH = F3P.BH, W = Double(Fr3.whole)
    var liveKeys: Set<String> { ["h"] }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The bar's top: two blocks down while a part is out of it.
    static func barY(_ st: Int) -> Double { st >= 1 && st <= 4 ? 10 : 0 }
    static func lead1(_ P: UnitFrac3.Parts, right: Bool) -> [M7.Tok] { [.w("1 part"), .op("="), right ? .f(1, P.b, .chapter) : .fb("t1", "b1")] }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = UnitFrac3.Parts(s.numbers), st = at(s), y = Self.barY(st), BH = Self.BH, pw = Double(P.pw)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        let p = Int((s.run.kept["p"] ?? 0).rounded())
        let held = s.grabbed && st == 1 ? Int((s.h("held") ?? 0).rounded()) : -1, lifted = (s.h("up") ?? 0) != 0
        // the part out of the bar: the one held up, or the one slid up (until it's home)
        let out = st == 1 ? (held >= 0 && lifted ? held : -1) : st >= 2 && st <= 4 ? p : -1
        for i in 0..<P.b {
            let x = Double(i) * pw
            if i == out { pic.sketch.box("hole\(i)", pic.R(x, y, pw, BH), .ink3, width: Sketch.stroke, dashed: true); continue }
            if i < P.k { pic.fill("f\(i)", col: x, row: y, w: pw, h: BH, F3P.shade) }
            pic.sketch.box("o\(i)", pic.R(x, y, pw, BH), .ink, width: Sketch.stroke)
        }
        if st == 0 {
            // each part numbers as it's tapped; the count beside the bar
            let m = Int((s.h("m") ?? 0).rounded())
            var n = 0
            for i in 0..<P.b where (m >> i) & 1 == 1 {
                n += 1
                let o = Int((s.h("o\(i)") ?? 0).rounded())
                pic.word("cn\(i)", "\(o + 1)", at: (Double(i) + 0.5) * pw, y + BH / 2, F3P.lit)
            }
            if n > 0 { F3P.beside(&pic, "ro\(n)", Fr3.plural(n, "part", "parts"), x: Self.W + 1.5, y: y + BH / 2) }
            if ring { KK.hintBox(&pic, "hc", x: 0, y: y, w: Self.W, h: BH) }
        }
        // the piece: held, lifted, laid on a shaded part
        let hops = st == 3 ? Int((s.h("h") ?? 0).rounded()) : st == 4 ? P.k : 0
        if st == 1 && held >= 0 {
            F3P.lifted(&live, "pc", x: Double(held) * pw, y: lifted ? 0 : y, w: pw, h: BH, fill: F3P.tint, .chapter)
            live.reads("1 part of \(P.b)")
        } else if st >= 2 && st <= 4 {
            let px = hops > 0 ? Double(hops - 1) * pw : Double(p) * pw, py = hops > 0 ? y : 0
            // (on the shading, only its outline, so the shading shows through; on paper, tinted)
            let onShade = hops > 0 && hops <= P.k
            var pen = st == 3 && s.grabbed ? live : pic
            if !onShade { pen.fill("pcf", col: px, row: py, w: pw, h: BH, F3P.tint) }
            pen.sketch.box("pco", pen.R(px, py, pw, BH), .chapter, width: Sketch.stroke)
            if st == 3 && s.grabbed { pen.reads("\(Fr3.plural(hops, "piece", "pieces")) of 1/\(P.b)"); live = pen } else { pic = pen }
        } else if st == 9 && s.run.kept["p"] != nil {
            // (done) the piece glides home into its place as the bar comes back up, as the preview's does
            pic.sketch.box("pco", pic.R(Double(p) * pw, 0, pw, BH), .chapter, width: Sketch.stroke)
        }
        for i in 0..<hops { pic.word("hn\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y + BH / 2, F3P.lit) }
        if st == 3 {
            if ring { KK.hintBox(&pic, "hh", x: 0, y: y, w: Double(P.k) * pw, h: BH) }
            if spot { pic.circle("hs", at: (Double(P.k) - 0.5) * pw, y + BH / 2, radius: 2, .chapter, dashed: true) }
        }
        if (st == 2 || st == 4) && ring { KK.hintBox(&pic, "hw", x: 0, y: st == 2 ? 0 : y, w: st == 2 ? Self.W : Double(P.k) * pw, h: st == 2 ? y + BH : BH) }
        if (st == 2 || st == 4) && spot { for i in 0..<P.b where i != out { pic.word("hp\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y + BH - 1, F3P.smallLit) } }
        // the record under the bar: 1 part, then the shaded parts beside it
        let RY = y + BH + 5
        if st >= 2 {
            let t1 = Self.lead1(P, right: st > 2)
            M7.row(&rec, "r1", t1, x: 0, line: RY)
            if st == 4 || (st == 9 && P.k > 1) {
                F3P.record(&rec, "r2", [.w("shaded")], top: "t2", bottom: "b2", (P.k, P.b), right: st == 9, x: M7.width(Self.lead1(P, right: false)) + 4, line: RY)
            }
        }
        if st == 9 && P.k > 1 {
            // (See) the shaded parts named at their ends
            for i in 1...P.k {
                pic.sketch.delay = 0.3 + Double(i) * 0.25
                pic.word("nm\(i)", "\(i)/\(P.b)", at: Double(i) * pw, y + BH + 1.2, F3P.smallLit)
            }
            pic.sketch.delay = 0
        }
        let ext = st >= 1 && st <= 4 ? pic.R(0, 0, Self.W, y + BH) : pic.R(0, 0, Self.W + 8, BH)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: st == 0 ? ["Check"] : [], extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = UnitFrac3.Parts(s.numbers), st = at(s), y = Self.barY(st), BH = Self.BH, pw = Double(P.pw), W = Self.W
        switch st {
        case 0:
            let m = Int((s.h("m") ?? 0).rounded()), base = s.hand
            var n = 0
            for i in 0..<P.b where (m >> i) & 1 == 1 { n += 1 }
            let count = n
            return Hands(tap: { q in
                guard q.x >= 0, q.x < W, q.y >= y, q.y <= y + BH else { return nil }
                let i = min(P.b - 1, Int(q.x / pw))
                guard (m >> i) & 1 == 0 else { return nil }
                var h = base; h["m"] = Double(m | (1 << i)); h["o\(i)"] = Double(count)
                return HandMove(hand: h)
            }, actions: ["Check": { HandMove(hand: base, missHand: base, set: [("n", Double(count))], check: true) }])
        case 1:
            return Hands(
                grab: { q in
                    guard q.x >= 0, q.x <= W, q.y >= y - 0.5, q.y <= y + BH + 0.5 else { return nil }
                    return ["grab": 1, "held": Double(min(P.b - 1, max(0, Int(q.x / pw)))), "gy": q.y, "up": 0]
                },
                drag: { q, h in var h = h; h["up"] = q.y - (h["gy"] ?? y) < -BH / 2 ? 1 : 0; return h },
                release: { h in
                    let i = h["held"] ?? 0
                    guard (h["up"] ?? 0) != 0 else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], set: [("u", i + 1)], keep: ["p": i], check: true)
                })
        case 3:
            let h0 = Int((s.h("h") ?? 0).rounded()), p = Double(Int((s.run.kept["p"] ?? 0).rounded()))
            let px = h0 > 0 ? Double(h0 - 1) * pw : p * pw, py = h0 > 0 ? y : 0
            return Hands(
                grab: { q in
                    guard q.x >= px - 1, q.x <= px + pw + 1, q.y >= py - 1, q.y <= py + BH + 1 else { return nil }
                    return ["grab": 1, "h": Double(h0), "h0": Double(h0), "gx": q.x, "gy": q.y]
                },
                drag: { q, h in
                    var h = h
                    if h0 == 0 && hypot(q.x - (h["gx"] ?? q.x), q.y - (h["gy"] ?? q.y)) < 1.5 { return h }
                    h["h"] = Double(max(1, min(P.b, Int(q.x / pw) + 1)))
                    return h
                },
                release: { h in
                    let n = Int((h["h"] ?? 0).rounded())
                    if n >= P.k { return HandMove(hand: ["h": Double(n)], missHand: ["h": Double(h0)], set: [("h", Double(n))], check: true) }
                    return HandMove(hand: ["h": Double(n)])
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = UnitFrac3.Parts(s.numbers), st = at(s), y = Self.barY(st), BH = Self.BH, pw = Double(P.pw)
        switch st {
        case 0:
            let m = Int((s.h("m") ?? 0).rounded())
            var out: [GhostMove] = []
            for i in 0..<P.b where (m >> i) & 1 == 0 { out.append(.tap(.picture(CGPoint(x: (Double(i) + 0.5) * pw, y: y + BH / 2)))) }
            return out + [.tap(.action("Check"))]
        case 1: return [.drag(from: CGPoint(x: pw / 2, y: y + BH / 2), to: CGPoint(x: pw / 2, y: BH / 2))]
        case 3:
            let p = Double(Int((s.run.kept["p"] ?? 0).rounded()))
            return [.drag(from: CGPoint(x: (p + 0.5) * pw, y: BH / 2), to: CGPoint(x: (Double(P.k) - 0.5) * pw, y: y + BH / 2))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = UnitFrac3.Parts(s.numbers)
        switch at(s) {
        case 0:
            var h: Numbers = ["m": 3, "o0": 0, "o1": 1]
            if P.b < 3 { h = ["m": 1, "o0": 0] }
            return HandMove(hand: h, missHand: h, set: [("n", P.b < 3 ? 1 : 2)], check: true)
        case 3: return HandMove(hand: ["h": Double(P.k + 1)], missHand: ["h": 0], set: [("h", Double(P.k + 1))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = UnitFrac3.Parts(s.numbers)
        switch at(s) {
        case 2: return ["t1": Double(P.b), "b1": 1]
        case 4: return ["t2": Double(P.k), "b2": Double(P.b - P.k)]
        default: return nil
        }
    }
}
