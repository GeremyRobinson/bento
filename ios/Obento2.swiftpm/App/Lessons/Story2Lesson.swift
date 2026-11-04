import SwiftUI

/// Story problems to 100 on the paper, as in the preview (design/prototype/grade2-ch1.html, dStory): the story on the top
/// rows (its numbers in the chapter colour), and past 50 "1 square is 2 stickers." on its own row; the bars to scale, a bold
/// line every ten things. Joining, taking away and parts of a whole: one bar in two parts under a bracket for the whole;
/// comparing: two bars from one start line, the longer on top, the gap past the shorter one's end dashed. What we don't know
/// is dashed, its true length, with no number. Slide the ? onto it (it turns the chapter colour, the story's equation is
/// written with the ? where the story has it); pick + or − (+: the parts slide together; −: the known part slides off);
/// write the answer.
///
/// Hand: "grab", "gx", "gy", "dx", "dy" (the ? carried). Kept: nothing (a miss puts the ? back under the picture).
@MainActor
struct Story2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private struct Geo {
        let P: Story2.Parts, R: Int
        var U: Double { Double(P.U) }
        func X(_ v: Int) -> Double { Double(v) / U }
        var T0: Double { 2 * Double(R) + 1 + (P.U == 2 ? 2 : 0) }
        var PB: Double { P.cmp ? T0 + 1 : T0 + 5 }
        var tokY: Double { P.cmp ? PB + 12 : PB + 7 }
        func target(_ p: Story2.Piece) -> CGRect {
            switch (P.cmp, p) {
            case (false, .whole): return CGRect(x: 0, y: PB - 5, width: X(P.W), height: 4.5)
            case (true, .whole): return CGRect(x: 0, y: PB, width: X(P.W), height: 4)
            case (_, .p1): return CGRect(x: 0, y: P.cmp ? PB + 6 : PB, width: X(P.p1), height: 4)
            case (_, .p2): return CGRect(x: X(P.p1), y: P.cmp ? PB + 6 : PB, width: X(P.p2), height: 4)
            }
        }
        func over(_ c: CGPoint) -> Story2.Piece? {
            [Story2.Piece.whole, .p1, .p2].first { let r = target($0).insetBy(dx: -1, dy: -1); return r.contains(c) }
        }
    }
    private func geo(_ n: Numbers) -> Geo { let P = Story2.Parts(n); return Geo(P: P, R: A2.storyRows(P.lines, width: 44).count) }

    func told(_ s: PaperState) -> String? { Story2.Parts(s.numbers).lines.joined(separator: " ") }

    func draw(_ s: PaperState) -> PaperDrawing {
        let G = geo(s.numbers), P = G.P, st = at(s), PB = G.PB, u = P.U
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, P.lines, width: 44)
        if u == 2 { pic.word("scale", Bars2.scale(P.th), at: 0, 2 * Double(G.R) + 1, A2.words.colour(.ink2), anchor: UnitPoint(x: 0, y: 0.5)) }
        let placed = st >= 1, done = st >= 3, op = st >= 2 ? (P.unkWhole ? "+" : "−") : nil
        func look(_ p: Story2.Piece) -> (A2.Bar, String?, Sketch.Colour) {
            if p != P.unknown { return (p == .p2 ? (P.cmp ? .dash : .stripe) : .tint, "\(P.value(p))", .ink) }
            if done { return (.lit, "\(P.ans)", .chapter) }
            if placed { return (.lit, "?", .chapter) }
            return (.dash, nil, .ink)
        }
        let off = { (p: Story2.Piece) in op == "−" && p != P.unknown && p != .whole }
        if P.cmp {
            A2.start(&pic, y: PB, h: 10)
            let w = look(.whole)
            A2.bar(&pic, "bwhole", x: 0, y: PB, w: G.X(P.W), w.0, u: u, n: P.unknown == .whole ? w.1 : nil, nc: w.2)
            if P.unknown != .whole { pic.word("nW", "\(P.W)", at: G.X(P.W) + 0.5, PB + 2, A2.maths, anchor: UnitPoint(x: 0, y: 0.5)) }
            pic.word("nmN", P.N, at: G.X(P.W) + 4, PB + 2, A2.small, anchor: UnitPoint(x: 0, y: 0.5))
            for p in [Story2.Piece.p1, .p2] {
                let r = G.target(p), l = look(p), up = off(p) || (op == "+" && P.unkWhole)
                A2.bar(&pic, "b\(p)", x: r.minX, y: up ? PB : r.minY, w: r.width, l.0, u: u, from: Int((r.minX * G.U).rounded()), n: l.1, nc: l.2, cross: off(p))
            }
            pic.word("nmM", P.M, at: G.X(P.W) + 4, PB + 8, A2.small, anchor: UnitPoint(x: 0, y: 0.5))
        } else {
            A2.start(&pic, y: PB, h: 4)
            // the bracket over the whole, its number (or the ?) above it
            let bw = G.X(P.W), bc: Sketch.Colour = P.unknown == .whole ? .ink : .chapter
            pic.line("brk\(placed)", [(0, PB - 0.5), (0, PB - 1.5), (bw / 2 - 1, PB - 1.5), (bw / 2, PB - 2.5), (bw / 2 + 1, PB - 1.5), (bw, PB - 1.5), (bw, PB - 0.5)], bc,
                     dashed: P.unknown == .whole && !placed)
            let wl: String? = P.unknown == .whole ? (done ? "\(P.W)" : placed ? "?" : nil) : "\(P.W)"
            if let wl { pic.word("wl\(wl)", wl, at: bw / 2, PB - 3.6, A2.maths.colour(P.unknown == .whole ? .chapter : .ink)) }
            if op == "+" { pic.sketch.from = A2.kinds { q in A2.bar(&q, "bp2", x: G.X(P.p1) + 5, y: PB, w: G.X(P.p2), look(.p2).0, u: u, from: P.p1, n: look(.p2).1, nc: look(.p2).2) } }
            for p in [Story2.Piece.p1, .p2] {
                let r = G.target(p), l = look(p)
                if off(p) { A2.bar(&pic, "b\(p)", x: r.minX, y: r.minY + 7, w: r.width, .ghost, u: u, from: Int((r.minX * G.U).rounded()), n: l.1) }
                else { A2.bar(&pic, "b\(p)", x: r.minX, y: r.minY, w: r.width, l.0, u: u, from: Int((r.minX * G.U).rounded()), n: l.1, nc: l.2) }
            }
            pic.sketch.from = [:]
            if P.kind == .partWhole || P.kind == .partPart {
                pic.word("cr", "red", at: G.X(P.p1) / 2, PB + 5, A2.small); pic.word("cb", "blue", at: G.X(P.p1) + G.X(P.p2) / 2, PB + 5, A2.small)
            }
        }
        // the ? waits under the picture until it's put on what we don't know
        if st == 0 {
            let held = s.grabbed, tx = held ? (s.h("dx") ?? 0) : 0, ty = held ? (s.h("dy") ?? 0) : 0
            var pen = held ? live : pic
            pen.sketch.box("toko", pen.R(tx, G.tokY + ty, 3, 3), .chapter, width: Sketch.stroke)
            pen.word("tokq", "?", at: tx + 1.5, G.tokY + ty + 1.5, A2.maths.colour(.chapter))
            if held, let on = G.over(CGPoint(x: tx + 1.5, y: G.tokY + ty + 1.5)) {
                let r = G.target(on)
                pen.sketch.box("tgt", pen.R(r.minX, r.minY, r.width, r.height), .ink2, width: Sketch.stroke)
                pen.reads(on == .whole ? "the whole" : "a part")
            }
            if held { live = pen } else { pic = pen }
            if s.on("ring") && !s.on("spot") { let r = G.target(.whole).union(G.target(.p2)); KK.hintBox(&pic, "hr", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            if s.on("spot") { let r = G.target(P.unknown); KK.hintBox(&pic, "spot", x: r.minX, y: r.minY, w: r.width, h: r.height) }
        }
        if st == 2 && s.on("ring") && !s.on("spot") { let r = G.target(.whole).union(G.target(.p2)); KK.hintBox(&pic, "hr", x: r.minX, y: r.minY, w: r.width, h: r.height) }

        // the record: the story's equation (the ? where the story has it), then the child's line
        if st >= 1 {
            func eq(_ q: String) -> [M7.Tok] { P.equation.map { t in t.map { Int($0).map { M7.Tok.n($0) } ?? .op($0) } ?? .t(q, .chapter) } }
            let (l0, o, l2) = P.line
            if P.same {
                if st == 1 { M7.row(&rec, "seq", eq("?"), x: 0, line: 1) }
                else if st == 2 {
                    let end = M7.row(&rec, "seq", Array(eq("?").prefix(4)) + [.box("x", cells: 2)], x: 0, line: 1)
                    if s.on("spot") { A1.note(&rec, "spot", "\(P.ans)", x: end + 1, y: 1) }
                } else { M7.row(&rec, "seq", Array(eq("?").prefix(4)) + [.n(P.ans, .chapter)], x: 0, line: 1) }
            } else {
                M7.row(&rec, "seq", eq(done ? "\(P.ans)" : "?"), x: 0, line: 1)
                if st == 2 {
                    let end = M7.row(&rec, "cl", [.n(l0), .op(o), .n(l2), .op("="), .box("x", cells: 2)], x: 0, line: 4)
                    if s.on("spot") { A1.note(&rec, "spot", "\(P.ans)", x: end + 1, y: 4) }
                } else if done { M7.row(&rec, "cl", [.n(l0), .op(o), .n(l2), .op("="), .n(P.ans, .chapter)], x: 0, line: 4) }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let G = geo(s.numbers), P = G.P
        return Hands(
            grab: { q in
                guard q.x >= -0.5, q.x <= 3.5, q.y >= G.tokY - 0.5, q.y <= G.tokY + 3.5 else { return nil }
                return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
            },
            drag: { q, held in var h = held; h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h },
            release: { held in
                let c = CGPoint(x: (held["dx"] ?? 0) + 1.5, y: G.tokY + (held["dy"] ?? 0) + 1.5)
                guard let on = G.over(c) else { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("u", on == P.unknown ? 1 : -Double(on.rawValue) - 1)], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let G = geo(s.numbers), r = G.target(G.P.unknown)
        return [.drag(from: CGPoint(x: 1.5, y: G.tokY + 1.5), to: CGPoint(x: r.midX, y: r.midY))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard at(s) == 0 else { return nil }
        let P = Story2.Parts(s.numbers), wrong: Story2.Piece = P.unknown == .p1 ? .p2 : .p1
        return HandMove(hand: [:], missHand: [:], set: [("u", -Double(wrong.rawValue) - 1)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        at(s) == 2 ? ["x": Double(Story2.Parts(s.numbers).slips[0].0)] : nil
    }
}
