import SwiftUI

/// Grams and kilograms on the paper, as in the preview (design/prototype/grade3-ch6.html, dUnit, dScale, dStory). Which unit:
/// the thing, a kitchen scale marked g (a pan on a stem, a round dial) and a floor scale marked kg; drag the thing onto the
/// scale that fits (the readout names the scale it's over; a wrong one sends it home), the empty scale is cleared away, then
/// tap about how heavy it is: three tags light to heavy, and the dial's needle swings to the one tapped. Read the scale: the
/// dial laid straight, 20 marks 3 squares apart, labeled every 5 marks on the strong lines, the needle at the value; hop from 0
/// to the first label ("5 marks to 50"), write `each mark = [10] g`; hop from the label before the needle to it ("3 marks past
/// 100"), write `[130] g`. A story: MSP, a cell 10 g or 1 kg.
///
/// Hand: drop "grab", "x", "y" (the thing's place), "gx", "gy"; hops "grab", "n". Kept: "tag" the tag tapped, "bad" a wrong one.
@MainActor
struct Mass3Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    func told(_ s: PaperState) -> String? { let P = Mass3.Parts(s.numbers); return P.kind == 2 ? P.storyText : nil }

    // which unit: where things go
    static let GY = 18.0, home = CGPoint(x: 0, y: 10)
    static let scaleX: [Double] = [15, 30], scaleW: [Double] = [10, 15]
    static let rest = [CGPoint(x: 15, y: 3), CGPoint(x: 32.5, y: 6)]
    static let dial: [(Double, Double, Double)] = [(20, 15, 2), (37.5, 16, 1.4)]
    static let TY = 23.0
    static func over(_ p: CGPoint) -> Int? {
        let cx = p.x + 5, cy = p.y + 4
        if cy > GY + 1 { return nil }
        return cx >= 13 && cx <= 27 ? 0 : cx >= 29 && cx <= 46 ? 1 : nil
    }
    static func tags(_ P: Mass3.Parts) -> [CGRect] { MS3.blockRow(P.order.map { P.labels[$0] }).map { CGRect(x: $0.minX, y: TY, width: $0.width, height: 2) } }
    // read the scale
    static let LY = 5.0, RY = 14.0

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 0: guard st == 2 else { return nil }; let t = Self.tags(P); return CGPoint(x: EG2.ceil5(t[2].maxX + 3), y: Self.TY)
        case 1:
            if st == 1 { return CGPoint(x: EG2.ceil5(M7.width(eachToks(P, right: false)) + 1), y: Self.RY - 1) }
            if st >= 3 { return CGPoint(x: EG2.ceil5(max(M7.width(eachToks(P, right: false)), M7.width(readToks(P, right: false))) + 1), y: Self.RY + 2) }
            return nil
        default: return MSP(P.story).blocksAt(st)
        }
    }
    private func eachToks(_ P: Mass3.Parts, right: Bool) -> [M7.Tok] {
        [.w("each mark"), .op("=")] + (right ? [.n(P.step, .chapter)] : [.box("s", cells: max(2, String(P.step).count))]) + [.w(P.u)]
    }
    private func readToks(_ P: Mass3.Parts, right: Bool) -> [M7.Tok] {
        (right ? [.n(P.value, .chapter)] : [.box("v", cells: max(2, String(P.value).count))]) + [.w(P.u)]
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 0: return unit(s, P, st)
        case 1: return scale(s, P, st)
        default: return MSP(P.story).draw(s, st)
        }
    }

    private func unit(_ s: PaperState, _ P: Mass3.Parts, _ st: Int) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let want = P.th.kg ? 1 : 0, on = st >= 1 ? want : nil, GY = Self.GY
        let tag = s.run.kept["tag"].map { Int($0) }, bad = s.run.kept["bad"].map { Int($0) }
        for k in 0..<2 {
            // (once the thing is on its scale, the empty one is cleared away)
            if let on, on != k { continue }
            let x = Self.scaleX[k], w = Self.scaleW[k], (dx, dy, dr) = Self.dial[k]
            if k == 0 {
                pic.sketch.box("kb", pic.R(x, GY - 6, w, 6), .ink, width: Sketch.stroke)
                pic.line("kst", [(x + 5, GY - 7), (x + 5, GY - 6)]); pic.line("kpan", [(x - 1, GY - 7), (x + w + 1, GY - 7)])
            } else { pic.sketch.box("fb", pic.R(x, GY - 4, w, 4), .ink, width: Sketch.stroke) }
            pic.circle("dl\(k)", at: dx, dy, radius: dr, .ink)
            pic.word("un\(k)", k == 0 ? "g" : "kg", at: k == 0 ? x + w - 1.4 : x + w - 1.8, dy, MS3.small)
            // the needle: at rest pointing left; on the picked scale it swings to the tapped tag (light to heavy)
            let ang = (on == k && tag != nil ? -45 + 45 * Double(tag!) : -90) * .pi / 180
            pic.sketch.morphs = true; pic.sketch.swings = true
            pic.sketch.line("nd\(k)", [pic.P(dx, dy), pic.P(dx + (dr - 0.35) * sin(ang), dy - (dr - 0.35) * cos(ang))], on == k && st == 2 ? .chapter : .ink, width: Sketch.stroke)
            pic.sketch.morphs = false; pic.sketch.swings = false
        }
        // the thing: carried by the finger, home, or on its scale
        if st == 0 && s.grabbed {
            MS3.thing(&live, "th", P.th.name, x: s.h("x") ?? Self.home.x, y: s.h("y") ?? Self.home.y)
            let o = Self.over(CGPoint(x: s.h("x") ?? 0, y: s.h("y") ?? 0))
            let r = o == 0 ? "Kitchen scale: grams" : o == 1 ? "Floor scale: kilograms" : ""
            if !r.isEmpty { live.word("ro", r, at: 0, GY + 2, KK.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)); live.reads(r) }
        } else {
            let p = st >= 1 ? Self.rest[want] : Self.home
            MS3.thing(&pic, "th", P.th.name, x: p.x, y: p.y)
        }
        // the tags, light to heavy, on the block lines under the scales
        if st >= 1 {
            for (j, r) in Self.tags(P).enumerated() {
                MS3.pick(&pic, "tg\(j)", x: r.minX, y: r.minY, w: r.width, P.labels[P.order[j]], bad: st == 1 && bad == j, on: st == 2 && j == P.rightTag)
            }
        }
        // hints: a first miss rings the scales or the tags, a second the right one
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 {
            if ring { KK.hintBox(&pic, "hr", x: 13, y: GY - 8, w: 34, h: 9) }
            if spot { let x = Self.scaleX[want], w = Self.scaleW[want]; KK.hintBox(&pic, "hs", x: x - 1.5, y: GY - 8, w: w + 3, h: 9) }
        }
        if st == 1 {
            let t = Self.tags(P)
            if ring { KK.hintBox(&pic, "hr", x: -0.5, y: Self.TY - 0.5, w: t[2].maxX + 1, h: 3) }
            if spot { let r = t[P.rightTag]; KK.hintBox(&pic, "hs", x: r.minX - 0.5, y: r.minY - 0.5, w: r.width + 1, h: 3) }
        }
        let wide = max(46, Self.tags(P)[2].maxX + (st == 2 ? 14 : 0))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, wide, st >= 1 ? Self.TY + 2 : GY + 3))
    }

    private func scale(_ s: PaperState, _ P: Mass3.Parts, _ st: Int) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let LY = Self.LY, nx = Double(P.marks) * 3, n = Int((s.h("n") ?? 0).rounded())
        // stage names: 0 first, 1 each, 2 past, 3 read, 4 done (no past when the needle is on a label)
        // the strip: a mark every 3 squares, a long one at each label; the labels under it, the unit at its left end
        pic.sketch.box("strip", pic.R(0, LY, 60, 2), .ink, width: Sketch.stroke)
        var tk: [(CGPoint, CGPoint)] = []
        for j in 1..<20 { tk.append((pic.P(3 * Double(j), LY), pic.P(3 * Double(j), LY + (j % 5 == 0 ? 2 : 0.8)))) }
        pic.sketch.segments("stk", tk, .ink, width: Sketch.stroke)
        for k in 0...4 { pic.word("sl\(k)", Ms3.wc(5 * k * P.step), at: 15 * Double(k), LY + 2.85, MS3.small) }
        pic.word("su", P.u, at: -0.6, LY + 1, KK.words, anchor: UnitPoint(x: 1, y: 0.5))
        // the needle, standing over its mark
        pic.sketch.polygon("nd", [pic.P(nx - 0.6, LY - 1.2), pic.P(nx + 0.6, LY - 1.2), pic.P(nx, LY)], .ink)
        pic.line("nds", [(nx, LY - 1.2), (nx, LY - 4)])
        // the hops: 0 to the first label (until its mark is written), then the label before the needle to it
        let x2 = Double(P.lb) * 3
        func handle(_ pen: inout GridPen, _ x: Double) { pen.dot("hh", at: x, LY, radius: s.grabbed ? 0.7 : 0.55, .ink, over: true) }
        if st == 0 {
            var pen = s.grabbed ? live : pic
            MS3.hhops(&pen, "h1", x0: 0, y: LY, step: 3, n: n); handle(&pen, Double(n) * 3)
            if s.grabbed { pen.reads("\(Ms3.plural(n, "mark", "marks"))\(n > 0 && n % 5 == 0 ? " to \(Ms3.wc(n * P.step))" : "")") }
            if s.grabbed { live = pen } else { pic = pen }
        } else if st == 1 { MS3.hhops(&pic, "h1", x0: 0, y: LY, step: 3, n: 5) }
        if st == 2 {
            var pen = s.grabbed ? live : pic
            MS3.hhops(&pen, "h2", x0: x2, y: LY, step: 3, n: n); handle(&pen, x2 + Double(n) * 3)
            if s.grabbed { pen.reads("\(Ms3.plural(n, "mark", "marks")) past \(Ms3.wc(P.label))") }
            if s.grabbed { live = pen } else { pic = pen }
        } else if st >= 3 && !P.onLabel { MS3.hhops(&pic, "h2", x0: x2, y: LY, step: 3, n: P.marks % 5) }
        // the record under the strip: each mark, then the mass
        if st >= 1 {
            if st == 1 { M7.row(&rec, "r1", eachToks(P, right: false), x: 0, line: Self.RY) } else { M7.row(&pic, "r1", eachToks(P, right: true), x: 0, line: Self.RY) }
        }
        if st == 3 { M7.row(&rec, "r2", readToks(P, right: false), x: 0, line: Self.RY + 3) }
        if st == 4 { M7.row(&pic, "r2", readToks(P, right: true), x: 0, line: Self.RY + 3) }
        // hints: a first miss rings the stretch, a second the place (or what to count)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0: if ring { KK.hintBox(&pic, "hr", x: -0.5, y: LY - 4, w: 16, h: 7) }; if spot { pic.circle("sp", at: 15, LY, radius: 1.1, .chapter, dashed: true) }
        case 1: if ring { KK.hintBox(&pic, "hr", x: -0.5, y: LY - 4, w: 16, h: 8) }; if spot { A1.note(&pic, "sp", "5 marks: 0 to \(Ms3.wc(5 * P.step))", x: 0, y: Self.RY - 2.6) }
        case 2: if ring { KK.hintBox(&pic, "hr", x: x2 - 0.5, y: LY - 4, w: 16, h: 7) }; if spot { pic.circle("sp", at: nx, LY, radius: 1.1, .chapter, dashed: true) }
        case 3: if ring { KK.hintBox(&pic, "hr", x: x2 - 0.5, y: LY - 4, w: max(4, nx - x2 + 1), h: 8) }; if spot { A1.note(&pic, "sp", "\(Ms3.wc(P.label)) and \(Ms3.plural(P.marks % 5, "mark", "marks")) of \(P.step)", x: 0, y: Self.RY + 0.6) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-3, 0, 63, Self.RY + 5))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 0:
            if st == 1 {
                let t = Self.tags(P)
                return Hands(tap: { q in
                    guard let j = t.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                    return HandMove(hand: nil, missHand: nil, set: [("g", Double(j))], keep: ["tag": Double(j), "bad": j == P.rightTag ? -1 : Double(j)], check: true)
                })
            }
            guard st == 0 else { return nil }
            let h0 = Self.home
            return Hands(
                grab: { q in
                    guard q.x >= h0.x - 0.5, q.x <= h0.x + 10.5, q.y >= h0.y - 0.5, q.y <= h0.y + 8.5 else { return nil }
                    return ["grab": 1, "x": h0.x, "y": h0.y, "gx": q.x, "gy": q.y]
                },
                drag: { q, h in var h = h; h["x"] = h0.x + (q.x - (h["gx"] ?? q.x)).rounded(); h["y"] = h0.y + (q.y - (h["gy"] ?? q.y)).rounded(); return h },
                release: { h in
                    guard let o = Self.over(CGPoint(x: h["x"] ?? 0, y: h["y"] ?? 0)) else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [("s", Double(o))], check: true)
                })
        case 1:
            guard st == 0 || st == 2 else { return nil }
            let x0 = st == 0 ? 0 : Double(P.lb) * 3, mx = st == 0 ? 20 : 20 - P.lb, n0 = Int((s.h("n") ?? 0).rounded()), LY = Self.LY, box = st == 0 ? "f" : "p"
            return Hands(
                grab: { q in abs(q.x - (x0 + Double(n0) * 3)) <= 2 && abs(q.y - LY) <= 3 ? ["grab": 1, "n": Double(n0)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(0, min(mx, Int(((q.x - x0) / 3).rounded())))); return h },
                release: { h in
                    let n = Int((h["n"] ?? 0).rounded())
                    guard n > 0 else { return HandMove(hand: ["n": 0]) }
                    return HandMove(hand: ["n": Double(n)], missHand: nil, set: [(box, Double(n))], check: true)
                })
        default: return MSP(P.story).hands(s, st)
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 0:
            if st == 0 { let r = Self.rest[P.th.kg ? 1 : 0]; return [.drag(from: CGPoint(x: Self.home.x + 5, y: Self.home.y + 4), to: CGPoint(x: r.x + 5, y: r.y + 4))] }
            if st == 1 { let r = Self.tags(P)[P.rightTag]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] }
            return []
        case 1:
            let n0 = Double(Int((s.h("n") ?? 0).rounded()))
            if st == 0 { return [.drag(from: CGPoint(x: n0 * 3, y: Self.LY), to: CGPoint(x: 15, y: Self.LY))] }
            if st == 2 { let x0 = Double(P.lb) * 3; return [.drag(from: CGPoint(x: x0 + n0 * 3, y: Self.LY), to: CGPoint(x: Double(P.marks) * 3, y: Self.LY))] }
            return []
        default: return MSP(P.story).demo(s, st)
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 0:
            if st == 0 { return HandMove(hand: [:], missHand: [:], set: [("s", P.th.kg ? 0 : 1)], check: true) }
            if st == 1 { let j = (P.rightTag + 1) % 3; return HandMove(hand: nil, missHand: nil, set: [("g", Double(j))], keep: ["tag": Double(j), "bad": Double(j)], check: true) }
            return nil
        case 1:
            if st == 0 { return HandMove(hand: ["n": 3], missHand: nil, set: [("f", 3)], check: true) }
            if st == 2 { let n = P.marks % 5 + 1; return HandMove(hand: ["n": Double(n)], missHand: nil, set: [("p", Double(n))], check: true) }
            return nil
        default: return MSP(P.story).wrongMove(st)
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Mass3.Parts(s.numbers), st = at(s)
        switch P.kind {
        case 1: return st == 1 ? ["s": Double(5 * P.step)] : st == 3 ? ["v": Double(P.readSlips.last?.0 ?? P.value + P.step)] : nil
        case 2: return MSP(P.story).wrongTyping(st)
        default: return nil
        }
    }
}
