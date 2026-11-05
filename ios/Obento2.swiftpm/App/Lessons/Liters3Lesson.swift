import SwiftUI

/// Liters on the paper, as in the preview (design/prototype/grade3-ch6.html, dJug, dEstimate, dStory). Read the jug: a tall
/// clear box 20 squares wide and 20 or 30 tall (a liter 1, 3 or 6 squares, the preview's; 40 tall showed at 61%), its marks on the left wall labeled as the web labels them, the water tinted to its level, the record to
/// its right. Hop up from 0 to the first label ("1 mark to 2"), write `each mark = [2] L`; hop up to the top of the water ("4
/// marks"), write `[8] L`. About how much: the thing beside a one-liter bottle; tap one of three tags, ten times apart. A story:
/// MSP, a cell a liter.
///
/// Hand: hops "grab", "n". Kept: "bad" a wrong tag.
@MainActor
struct Liters3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    func told(_ s: PaperState) -> String? { let P = Liters3.Parts(s.numbers); return P.kind == 1 ? P.story.story : nil }
    static let JX = 5.0, JW = 20.0, RX = 30.0, RY = 3.0, TY = 15.0, k = 1.2
    static func JB(_ P: Liters3.Parts) -> Double { Double(P.cap * P.per) }
    static var HX: Double { JX + 2.5 }
    static func tags(_ P: Liters3.Parts) -> [CGRect] { MS3.blockRow(P.vals.map { "\(Ms3.wc($0)) L" }).map { CGRect(x: $0.minX, y: TY, width: $0.width, height: 2) } }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).blocksAt(st)
        case 2: guard st == 1 else { return nil }; return CGPoint(x: EG2.ceil5(Self.tags(P)[2].maxX + 3), y: Self.TY)
        default:
            if st == 1 { return CGPoint(x: Self.RX, y: Self.RY + 2) }
            if st >= 3 { return CGPoint(x: Self.RX, y: Self.RY + 5) }
            return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).draw(s, st)
        case 2: return about(s, P, st)
        default: return jug(s, P, st)
        }
    }

    private func jug(_ s: PaperState, _ P: Liters3.Parts, _ st: Int) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let JX = Self.JX, JW = Self.JW, JB = Self.JB(P), u = Double(P.per), ms = Double(P.step) * u, n = Int((s.h("n") ?? 0).rounded())
        // the water, then the jug: an open box; its marks on the left wall, labeled to their left
        pic.fill("water", col: JX, row: JB - Double(P.value) * u, w: JW, h: Double(P.value) * u, .tint(0.2))
        pic.line("jug", [(JX, 0), (JX, JB), (JX + JW, JB), (JX + JW, 0)])
        var tk: [(CGPoint, CGPoint)] = []
        for j in 1...P.n { tk.append((pic.P(JX, JB - Double(j) * ms), pic.P(JX + (j % P.every == 0 ? 1.8 : 1), JB - Double(j) * ms))) }
        pic.sketch.segments("jtk", tk, .ink, width: Sketch.stroke)
        var j = 0
        while j <= P.n { pic.word("jl\(j)", "\(j * P.step)", at: JX - 0.6, JB - Double(j) * ms, MS3.small, anchor: UnitPoint(x: 1, y: 0.5)); j += P.every }
        // the hops up the wall: 0 to the first label (until its mark is written), then 0 to the top of the water
        func handle(_ pen: inout GridPen, _ k: Int) { pen.dot("hh", at: Self.HX, JB - Double(k) * ms, radius: s.grabbed ? 0.7 : 0.55, .ink, over: true) }
        if st == 0 || st == 2 {
            var pen = s.grabbed ? live : pic
            MS3.vhops(&pen, st == 0 ? "h1" : "h2", x: Self.HX, y0: JB, step: ms, n: n); handle(&pen, n)
            if s.grabbed || n > 0 {
                let r = st == 0 ? "\(Ms3.plural(n, "mark", "marks"))\(n > 0 && n % P.every == 0 ? " to \(n * P.step)" : "")" : Ms3.plural(n, "mark", "marks")
                pen.word("ro", r, at: Self.RX, JB - 1, KK.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { pen.reads(r) }
            }
            if s.grabbed { live = pen } else { pic = pen }
        } else if st == 1 { MS3.vhops(&pic, "h1", x: Self.HX, y0: JB, step: ms, n: P.every) }
        else if st >= 3 { MS3.vhops(&pic, "h2", x: Self.HX, y0: JB, step: ms, n: P.marks) }
        // the record to the jug's right
        let each: (Bool) -> [M7.Tok] = { r in [.w("each mark"), .op("=")] + (r ? [.n(P.step, .chapter)] : [.box("s", cells: 2)]) + [.w("L")] }
        let read: (Bool) -> [M7.Tok] = { r in (r ? [.n(P.value, .chapter)] : [.box("v", cells: 2)]) + [.w("L")] }
        if st == 1 { M7.row(&rec, "r1", each(false), x: Self.RX, line: Self.RY) }
        if st >= 2 { M7.row(&pic, "r1", each(true), x: Self.RX, line: Self.RY) }
        if st == 3 { M7.row(&rec, "r2", read(false), x: Self.RX, line: Self.RY + 3) }
        if st == 4 { M7.row(&pic, "r2", read(true), x: Self.RX, line: Self.RY + 3) }
        // hints: a first miss rings the stretch of wall, a second the place to stop (or what to count)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot"), top = JB - Double(P.value) * u, first = JB - Double(P.every) * ms
        switch st {
        case 0: if ring { KK.hintBox(&pic, "hr", x: JX - 4, y: first - 1, w: 9, h: JB - first + 2) }; if spot { pic.circle("sp", at: Self.HX, first, radius: 1.1, .chapter, dashed: true) }
        case 1: if ring { KK.hintBox(&pic, "hr", x: JX - 4, y: first - 1, w: 9, h: JB - first + 2) }; if spot { A1.note(&pic, "sp", "\(Ms3.plural(P.every, "mark", "marks")): 0 to \(P.every * P.step)", x: Self.RX, y: Self.RY - 2.6) }
        case 2: if ring { KK.hintBox(&pic, "hr", x: JX - 0.5, y: top - 2, w: JW + 1, h: 4) }; if spot { pic.circle("sp", at: Self.HX, top, radius: 1.1, .chapter, dashed: true) }
        case 3: if ring { KK.hintBox(&pic, "hr", x: JX - 4, y: top - 1.5, w: JW + 4.5, h: 3) }; if spot { A1.note(&pic, "sp", "\(Ms3.plural(P.marks, "mark", "marks")) of \(P.step) L", x: Self.RX, y: Self.RY + 5.6) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, Self.RX + 18, JB + 1))
    }

    private func about(_ s: PaperState, _ P: Liters3.Parts, _ st: Int) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let k = Self.k
        MS3.thing(&pic, "bt", "bottle", x: 0, y: 0, k: k)
        pic.word("btl", "1 L", at: 5 * k, 8 * k + 1.2, MS3.small)
        MS3.thing(&pic, "th", P.th.name, x: 15, y: 0, k: k)
        let bad = s.run.kept["bad"].map { Int($0) }, t = Self.tags(P)
        for (j, r) in t.enumerated() { MS3.pick(&pic, "tg\(j)", x: r.minX, y: r.minY, w: r.width, "\(Ms3.wc(P.vals[j])) L", bad: st == 0 && bad == j, on: st == 1 && j == P.p) }
        if st == 0 && s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: -0.5, y: 0, w: 15 + 10 * k + 1, h: 8 * k + 2.5) }
        if st == 0 && s.on("spot") { let r = t[P.p]; KK.hintBox(&pic, "hs", x: r.minX - 0.5, y: r.minY - 0.5, w: r.width + 1, h: 3) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, max(28, t[2].maxX + (st == 1 ? 14 : 0)), Self.TY + 2))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).hands(s, st)
        case 2:
            guard st == 0 else { return nil }
            let t = Self.tags(P)
            return Hands(tap: { q in
                guard let j = t.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("g", Double(j))], keep: ["bad": j == P.p ? -1 : Double(j)], check: true)
            })
        default:
            guard st == 0 || st == 2 else { return nil }
            let JB = Self.JB(P), ms = Double(P.step * P.per), n0 = Int((s.h("n") ?? 0).rounded()), box = st == 0 ? "f" : "u", mx = P.n
            return Hands(
                grab: { q in abs(q.y - (JB - Double(n0) * ms)) <= max(2, ms / 2 + 0.5) && abs(q.x - Self.HX) <= 3 ? ["grab": 1, "n": Double(n0)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(0, min(mx, Int(((JB - q.y) / ms).rounded())))); return h },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard n > 0 else { return HandMove(hand: ["n": 0]) }
                    return HandMove(hand: ["n": Double(n)], missHand: nil, set: [(box, Double(n))], check: true)
                })
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).demo(s, st)
        case 2: let r = Self.tags(P)[P.p]; return st == 0 ? [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] : []
        default:
            guard st == 0 || st == 2 else { return [] }
            let JB = Self.JB(P), ms = Double(P.step * P.per), n0 = Double(Int((s.h("n") ?? 0).rounded())), to = Double(st == 0 ? P.every : P.marks)
            return [.drag(from: CGPoint(x: Self.HX, y: JB - n0 * ms), to: CGPoint(x: Self.HX, y: JB - to * ms))]
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).wrongMove(st)
        case 2: let j = (P.p + 1) % 3; return st == 0 ? HandMove(hand: nil, missHand: nil, set: [("g", Double(j))], keep: ["bad": Double(j)], check: true) : nil
        default:
            if st == 0 { return HandMove(hand: ["n": Double(P.every + 1)], missHand: nil, set: [("f", Double(P.every + 1))], check: true) }
            if st == 2 { let n = P.marks > 1 ? P.marks - 1 : P.marks + 1; return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("u", Double(n))], check: true) }
            return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Liters3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return MSP(P.story).wrongTyping(st)
        case 2: return nil
        default: return st == 1 ? ["s": Double(P.cap)] : st == 3 ? ["v": Double(P.cap)] : nil
        }
    }
}
