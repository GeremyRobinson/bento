import SwiftUI

/// Multiply by breaking apart on the paper, as in the preview (design/prototype/grade3-ch2.html, dSplit): a rows of b dots
/// (a dot in a cell of 5, 4 or 3 squares, so 5 things always end on a strong line), a down the left and b over the top.
/// The ruler's handle stands on a stem over the top edge at the far end; dragged along it snaps between things, a dashed
/// cut runs down and the two widths ride over it ("5 | 3"). Let go after 5: the cut turns solid and the b − 5 part glides
/// a square away. The 5 part lights: write `7 × 5 = [35]` (also written under it); then the other part, `7 × 3 = [21]`;
/// they glide back and `35 + 21 = [56]`. The record: `7 × 8 = 7 × 5 + 7 × 3`, `= 35 + 21`, `= 56`.
///
/// Hand: "grab", "k" the cut the ruler is at (b: resting at the far end).
@MainActor
struct Split3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static let X0 = M3.X0, Y0 = M3.Y0
    var liveKeys: Set<String> { ["k"] }
    func recordBeside(_ n: Numbers) -> Double? { Self.Y0 }
    func recordRow(_ n: Numbers) -> Double? { let P = Split3.Parts(n); return Self.Y0 + Double(P.a * P.c) + 5 }
    private static func ruler(_ P: Split3.Parts) -> T3.Ruler { T3.Ruler(down: true, x: X0, y: Y0, c: Double(P.c), n: P.b, span: P.a) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Split3.Parts(s.numbers), st = at(s), c = Double(P.c), X0 = Self.X0, Y0 = Self.Y0, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let H = Double(P.a) * c, W = Double(P.b) * c, cut = st > 0
        // the b − 5 part stands a square away while each part is written, then glides back
        let gap: Double = st == 1 || st == 2 ? 1 : 0
        let parts = T3.split(&pic, "ar", x: X0, y: Y0, rows: P.a, cols: P.b, c: c, byCols: true, at: 5, gap: gap, cut: cut,
                             tint: (st == 1 || st >= 3, st >= 2))
        let A = parts[0], B = parts[1]
        M3.bracket(&pic, "bl", x: X0 - 1, y1: Y0, y2: Y0 + H, open: false, name: "\(P.a)")
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        if st == 0 {
            let k = Int((s.h("k") ?? Double(P.b)).rounded()), held = s.grabbed && k < P.b
            // over the top: b, or while the ruler moves the two widths riding over the cut
            if held {
                live.label("w1", "\(k)", M3.maths.colour(ch), .above, edge: Y0, along: X0 + Double(k) * c / 2)
                live.label("w2", "\(P.b - k)", M3.maths.colour(ch), .above, edge: Y0, along: X0 + (Double(k) + Double(P.b - k) / 2) * c)
            } else { pic.label("top", "\(P.b)", M3.maths, .above, edge: Y0, along: X0 + W / 2) }
            Self.ruler(P).draw(&live, k, held: s.grabbed)
            if s.grabbed { live.reads("\(k) | \(P.b - k)") }
            // a miss rings the top edge the ruler slides along; a second dashes the cut after 5
            if ring { KK.hintBox(&pic, "hr", x: X0, y: Y0 - 3.5, w: W, h: 3) }
            if spot { pic.line("sp", [(X0 + 5 * c, Y0 - 0.5), (X0 + 5 * c, Y0 + H + 0.5)], ch, dashed: true) }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(X0 - 1, Y0 - 4, W + 2, H + 4))
        }
        // the widths over the parts, once cut
        pic.label("w1", "5", M3.maths, .above, edge: Y0, along: A.midX)
        pic.label("w2", "\(P.r)", M3.maths, .above, edge: Y0, along: B.midX)
        // each part's number, written under it once it's found
        if st >= 2 { pic.label("p5", "\(P.f5)", M3.maths.colour(ch), .below, edge: Y0 + H, along: A.midX) }
        if st >= 3 { pic.label("pr", "\(P.fr)", M3.maths.colour(ch), .below, edge: Y0 + H, along: B.midX) }
        if st == 1 && ring { KK.hintBox(&pic, "hf", x: A.minX, y: Y0, w: A.width, h: H) }
        if st == 1 && spot { A1.note(&pic, "sf", "\(P.f5)", x: A.midX, y: Y0 + H + 1.5, centred: true) }
        if st == 2 && ring { KK.hintBox(&pic, "hp", x: B.minX, y: Y0, w: B.width, h: H) }
        if st == 2 && spot { A1.note(&pic, "sp", "\(P.fr)", x: B.midX, y: Y0 + H + 1.5, centred: true) }
        if st == 3 && ring { KK.hintBox(&pic, "hs", x: X0, y: Y0 + H + 0.5, w: W, h: 2.5) }

        // the record
        let lit = { (v: String, on: Bool) -> M7.Tok in .t(v, on ? ch : .ink) }
        let l1: [M7.Tok] = [.n(P.a), .op("×"), .n(P.b), .op("="), lit("\(P.a)", st == 1), .op("×", st == 1 ? ch : .ink), lit("5", st == 1), .op("+"),
                            lit("\(P.a)", st == 2), .op("×", st == 2 ? ch : .ink), lit("\(P.r)", st == 2)]
        M7.row(&rec, "l1", l1, x: 0, line: 1)
        let x6 = M7.width([.n(P.a), .op("×"), .n(P.b)])
        var l2: [M7.Tok] = [.op("="), M3.box("f", P.f5, cells: 2, right: st >= 2)]
        if st >= 2 { l2 += [.op("+"), M3.box("r", P.fr, cells: 2, right: st >= 3)] }
        M7.row(&rec, "l2", l2, x: x6, line: 4)
        if st >= 3 { M7.row(&rec, "l3", [.op("="), M3.box("s", P.P, cells: 2, right: st == 4)], x: x6, line: 7) }
        if st == 3 && spot { A1.note(&pic, "ss", "\(P.P)", x: X0 + W + 1.5, y: Y0 + H / 2) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(X0 - 1, Y0, W + 3, H + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = Split3.Parts(s.numbers), R = Self.ruler(P), k = Int((s.h("k") ?? Double(P.b)).rounded())
        return Hands(
            grab: { q in R.holds(q, k) ? ["grab": 1, "k": Double(k)] : nil },
            drag: { q, h in var h = h; h["k"] = Double(R.snap(q)); return h },
            release: { h in
                let k = Int((h["k"] ?? Double(P.b)).rounded())
                guard k < P.b else { return HandMove(hand: ["k": Double(P.b)]) }
                return HandMove(hand: ["k": Double(k)], missHand: ["k": Double(P.b)], set: [("k", Double(k))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let P = Split3.Parts(s.numbers), R = Self.ruler(P)
        return [.drag(from: R.at(P.b), to: R.at(5))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard at(s) == 0 else { return nil }
        let P = Split3.Parts(s.numbers)
        return HandMove(hand: ["k": 4], missHand: ["k": Double(P.b)], set: [("k", 4)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Split3.Parts(s.numbers)
        switch at(s) { case 1: return ["f": Double(P.a + 5)]; case 2: return ["r": Double(P.a + P.r)]; case 3: return ["s": Double(P.f5)]; default: return nil }
    }
}
