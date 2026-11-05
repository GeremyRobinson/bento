import SwiftUI

/// Time to 5 minutes on the paper, as in the preview (design/prototype/grade2-ch6.html, dTime5): 1st grade's clock, 24 squares
/// across, centred on a block corner, the numbers inside the edge, 60 minute marks with every fifth longer; at its right the
/// hour strip, the hour before, the hour and the hour after, 12 squares an hour (a square is 5 minutes). Tap the hour (the
/// number the short hand has just passed): it's ringed, the strip's hours are written and the short hand's place marked on it.
/// Trace from 12 to the long hand: the face shades behind the finger, snapping at each number, writing 5, 10, 15 … outside the
/// edge, the strip filling a square a number ("25 minutes"). Write [3]:[25] under the strip. The folds: a time of day (said
/// with every line) and a.m. or p.m. picked under the record, then the day strip (midnight, noon, midnight) drops the time into
/// its half; or the time written and the long hand turned round to it, snapping at each number, the short hand creeping with it.
///
/// Kept: "wh" a number tapped and wrong, "wc" a wrong pick, "tn" where the long hand was turned to. Hand: "grab", "bad",
/// "acc" (degrees gone round), "prev", "n" (numbers passed), "back", "mv".
@MainActor
struct Time5Lesson: PaperLesson {
    var liveKeys: Set<String> { ["acc", "prev", "back", "mv"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let cx = 15.0, cy = 14.0, R = 12.0, nr = 9.4, sx = 30.0, sy = 4.0, rr = 17.0, py = 21.0
    static let picks = [CGRect(x: sx, y: py, width: 8, height: 4), CGRect(x: sx + 10, y: py, width: 8, height: 4)]

    static func point(_ deg: Double, _ r: Double) -> CGPoint { CGPoint(x: cx + r * sin(deg * .pi / 180), y: cy - r * cos(deg * .pi / 180)) }
    static func angle(_ q: CGPoint) -> Double { atan2(q.x - cx, -(q.y - cy)) * 180 / .pi }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    private func recToks(_ s: PaperState, _ P: Time5.Parts) -> [M7.Tok] {
        at(s) == 2 ? [.box("x", cells: 2), .op(":"), .box("y", cells: 2)] : [.t(P.time)]
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Time5.Parts(s.numbers), st = at(s)
        guard st == 2 || st == 4 else { return nil }
        let w = M7.width(recToks(s, P)) + (P.ev != nil && st == 4 ? KK.width("p.m.", KK.words) + 1 : 0)
        return CGPoint(x: EG2.ceil5(Self.sx + w + 1), y: Self.rr - 1)
    }

    /// A hand at `deg`, `len` long and `w` wide at the hub.
    private func hand(_ pen: inout GridPen, _ id: String, _ deg: Double, _ len: Double, _ w: Double) {
        let r = deg * .pi / 180, u = (sin(r), -cos(r)), n = (cos(r), sin(r))
        func p(_ t: Double, _ s: Double) -> CGPoint { pen.P(Self.cx + u.0 * t + n.0 * s, Self.cy + u.1 * t + n.1 * s) }
        let pts = [p(0, w / 2), p(len, 0), p(0, -w / 2), p(-1, 0)]
        pen.sketch.polygon(id, pts, .ink); pen.sketch.line(id + "o", pts + [pts[0]], .ink, width: Sketch.stroke)
    }
    private func hands(_ pen: inout GridPen, _ id: String, H: Int, minutes mm: Double) {
        hand(&pen, id + "lh", mm * 6, 8.2, 0.55)
        hand(&pen, id + "sh", (Double(H % 12) + mm / 60) * 30, 5.3, 1.2)
        pen.dot(id + "hub", at: Self.cx, Self.cy, radius: 0.45, .ink)
    }
    /// The face shaded from 12 round n numbers, the strip filled n squares, and the count by 5s outside the edge.
    private func traced(_ pen: inout GridPen, _ n: Int, strip: Bool = true) {
        guard n > 0 else { return }
        let steps = max(2, 4 * n)
        var arc: [CGPoint] = [pen.P(Self.cx, Self.cy)]
        for i in 0...steps { let p = Self.point(30 * Double(n) * Double(i) / Double(steps), Self.R); arc.append(pen.P(p.x, p.y)) }
        pen.sketch.polygon("sec\(n)", arc, .tint(0.2))
        if strip && n < 12 { pen.fill("sfill\(n)", col: Self.sx + 12, row: Self.sy, w: Double(n), h: 3, .tint(0.45)) }
        for j in 1...min(n, 12) { let p = Self.point(30 * Double(j), Self.R + 1.7); pen.word("ct\(j)", "\(5 * j)", at: p.x, p.y, KK.lit) }
    }
    private func numbers(_ pen: inout GridPen, _ id: String, bad: Int?, picked: Int?) {
        for j in 1...12 {
            let p = Self.point(30 * Double(j), Self.nr), c: Sketch.Colour = bad == j ? KK.red : picked == j ? .chapter : .ink
            pen.word("\(id)\(j)\(bad == j)\(picked == j)", "\(j)", at: p.x, p.y, KK.maths.colour(c))
        }
    }
    private func readout(_ pen: inout GridPen, _ text: String) {
        pen.word("ro", text, at: Self.sx, 11, KK.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
    }
    private func marker(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.sketch.polygon(id, [pen.P(x - 0.7, y - 1.3), pen.P(x + 0.7, y - 1.3), pen.P(x, y - 0.1)], .chapter)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Time5.Parts(s.numbers), st = at(s), H = P.H, M = Double(P.M)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && s.h("bad") != 1, n = Int(s.h("n") ?? 0)
        let tn = Int(s.run.kept["tn"] ?? 0), turned = st == 5 ? (held ? n : tn) : P.K % 12
        let picked: Int? = st >= 1 && !P.set ? H : nil
        // the face, its marks; the shading behind the finger (live) or once traced
        if st == 1 && held { traced(&pic, n) } else if st >= 2 && st != 5 && P.M > 0 { traced(&pic, P.K, strip: false) }
        if st == 5 && turned > 0 { traced(&pic, turned) }
        pic.circle("face", at: Self.cx, Self.cy, radius: Self.R, .ink)
        var marks: [(CGPoint, CGPoint)] = []
        for j in 0..<60 {
            let a = Self.point(Double(j) * 6, Self.R), b = Self.point(Double(j) * 6, Self.R - (j % 5 == 0 ? 1.3 : 0.6))
            marks.append((pic.P(a.x, a.y), pic.P(b.x, b.y)))
        }
        pic.sketch.segments("marks", marks, .ink, width: Sketch.stroke)
        let wh = st == 0 ? s.run.kept["wh"].map { Int($0) } : nil
        numbers(&pic, "cn", bad: wh, picked: picked)
        if let picked { let p = Self.point(30 * Double(picked), Self.nr); pic.circle("pk", at: p.x, p.y, radius: 1.55, .chapter) }
        // the hands (over the shading: the live layer lies over the picture, so they're drawn there too while it moves)
        let mm = st == 5 ? 5 * Double(turned) : M
        hands(&pic, "", H: H, minutes: mm)
        // the hour strip: 12 squares an hour; once the hour is read, its hours and the short hand's place
        pic.sketch.box("strip", pic.R(Self.sx, Self.sy, 36, 3), .ink, width: Sketch.stroke)
        var tk: [(CGPoint, CGPoint)] = []
        for j in 1..<36 {
            if j % 12 == 0 { tk.append((pic.P(Self.sx + Double(j), Self.sy), pic.P(Self.sx + Double(j), Self.sy + 3))) }
            else { tk.append((pic.P(Self.sx + Double(j), Self.sy), pic.P(Self.sx + Double(j), Self.sy + 0.7))) }
        }
        pic.sketch.segments("stk", tk, .ink, width: Sketch.stroke)
        if st >= 1 {
            let hs = [P.prev, H, P.next, P.next % 12 + 1]
            for (j, v) in hs.enumerated() { pic.word("sh\(j)\(v)", "\(v)", at: Self.sx + 12 * Double(j), Self.sy + 4.6, KK.words.colour(j == 1 ? .chapter : .ink)) }
            let place = st == 5 ? Double(turned) : M / 5
            marker(&pic, "mk\(place)", x: Self.sx + 12 + place, y: Self.sy)
            if st >= 2 && st != 5 && P.M > 0 { pic.fill("sfill", col: Self.sx + 12, row: Self.sy, w: M / 5, h: 3, .tint(0.45)) }
        }
        // the readout beside the picture: the minutes counted, or the time the clock shows
        if st == 1 && held && n > 0 { let ro = "\(5 * n) minutes"; readout(&live, ro); live.reads(ro) }
        if st == 5 && held { let ro = P.timeOf(n); readout(&live, ro); live.reads(ro) }
        // the record under the strip: [3]:[25], then 3:25 and a.m. or p.m.
        if st >= 2 || st == 5 {
            let toks = recToks(s, P)
            let end = st == 2 ? M7.row(&rec, "rec", toks, x: Self.sx, line: Self.rr) : M7.row(&pic, "rec", toks, x: Self.sx, line: Self.rr)
            if st == 4, let ev = P.ev { pic.word("recap", ev.pm ? "p.m." : "a.m.", at: end + 0.5, Self.rr, KK.words, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        let wc = s.run.kept["wc"].map { Int($0) }
        if st == 3 { for (i, w) in ["a.m.", "p.m."].enumerated() { let r = Self.picks[i]; E1.block(&pic, "ap\(i)", x: r.minX, y: r.minY, w: r.width, w, wrong: wc == i) } }
        // the day strip: midnight, noon in the middle, midnight; the time drops into its half
        if st == 4, let ev = P.ev {
            pic.fill("dhalf", col: ev.pm ? Self.sx + 18 : Self.sx, row: Self.py, w: 18, h: 3, .tint(0.2))
            pic.sketch.box("day", pic.R(Self.sx, Self.py, 36, 3), .ink, width: Sketch.stroke)
            pic.line("dmid", [(Self.sx + 18, Self.py), (Self.sx + 18, Self.py + 3)])
            pic.word("dam", "a.m.", at: Self.sx + 9, Self.py + 1.5, LN2.small)
            pic.word("dpm", "p.m.", at: Self.sx + 27, Self.py + 1.5, LN2.small)
            // the ends' words start and end with the strip, so the picture is no wider than the strip
            pic.word("dl0", "midnight", at: Self.sx, Self.py + 4.3, LN2.small, anchor: UnitPoint(x: 0, y: 0.5))
            pic.word("dl1", "noon", at: Self.sx + 18, Self.py + 4.3, LN2.small)
            pic.word("dl2", "midnight", at: Self.sx + 36, Self.py + 4.3, LN2.small, anchor: UnitPoint(x: 1, y: 0.5))
            let dx = Self.sx + 1.5 * (Double(H % 12) + (ev.pm ? 12 : 0) + M / 60)
            marker(&pic, "dmk", x: dx, y: Self.py)
        }
        // hints: a first miss rings the general area, a second the exact spot
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let short = Self.point((Double(H % 12) + M / 60) * 30, 3)
        switch st {
        case 0:
            if ring { KK.hint(&pic, "hr", short.x, short.y, radius: 3.4) }
            if spot { let p = Self.point(30 * Double(H), Self.nr); KK.hint(&pic, "spot", p.x, p.y, radius: 1.9) }
        case 1:
            if ring { let p = Self.point(0, Self.nr); KK.hint(&pic, "hr", p.x, p.y, radius: 1.9) }
            if spot { let p = Self.point(30 * Double(P.K), Self.nr); KK.hint(&pic, "spot", p.x, p.y, radius: 1.9) }
        case 2:
            if ring { KK.hintBox(&pic, "hr", x: Self.sx + 12, y: Self.sy, w: max(1, M / 5), h: 3) }
            if spot { A1.note(&pic, "spot", P.time, x: Self.sx, y: Self.rr - 2.6) }
        case 3:
            if ring { KK.hintBox(&pic, "hr", x: Self.sx, y: Self.py, w: 18, h: 4) }
            if spot, let ev = P.ev { let r = Self.picks[ev.pm ? 1 : 0]; KK.hintBox(&pic, "spot", x: r.minX, y: r.minY, w: r.width, h: r.height) }
        case 5:
            if ring { KK.hintBox(&pic, "hr", x: Self.sx, y: Self.rr - 1, w: M7.width([.t(P.time)]), h: 2) }
            if spot { let p = Self.point(30 * Double(P.K), Self.nr); KK.hint(&pic, "spot", p.x, p.y, radius: 1.9) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, Self.sx + 37, Self.py + 5))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Time5.Parts(s.numbers), st = at(s)
        func onFace(_ q: CGPoint) -> Bool { hypot(q.x - Self.cx, q.y - Self.cy) <= Self.R + 1.5 }
        func turning(start: Double) -> Hands {
            Hands(
                grab: { q in
                    guard onFace(q) else { return nil }
                    let a = Self.angle(q)
                    if st == 1 && abs(a) > 35 { return ["grab": 1, "bad": 1] }
                    return ["grab": 1, "bad": 0, "acc": start, "prev": a, "n": start / 30, "back": 0, "mv": 0, "gx": q.x, "gy": q.y]
                },
                drag: { q, h in
                    var h = h
                    guard h["bad"] != 1 else { return h }
                    if hypot(q.x - (h["gx"] ?? q.x), q.y - (h["gy"] ?? q.y)) > 0.4 { h["mv"] = 1 }
                    let a = Self.angle(q)
                    var d = a - (h["prev"] ?? a)
                    if d > 180 { d -= 360 }
                    if d <= -180 { d += 360 }
                    let acc = (h["acc"] ?? 0) + d
                    h["acc"] = acc; h["prev"] = a
                    if st == 1 && acc < -12 { h["back"] = 1 }
                    h["n"] = Double(max(0, min(12, Int((acc / 30).rounded()))))   // snaps at each number
                    return h
                },
                release: { h in
                    if h["bad"] == 1 { return HandMove(hand: [:], missHand: [:], set: [("n", Double(Time5.wrongStart))], check: true) }
                    let n = Int(h["n"] ?? 0)
                    if st == 5 {
                        if h["mv"] != 1 { return HandMove(hand: [:]) }
                        return HandMove(hand: [:], missHand: [:], set: [("t", Double(n))], keep: ["tn": Double(n)], check: true)
                    }
                    if h["mv"] != 1 { return P.M == 0 ? HandMove(hand: [:], missHand: [:], set: [("n", 0)], check: true) : HandMove(hand: [:]) }
                    if h["back"] == 1 { return HandMove(hand: [:], missHand: [:], set: [("n", Double(Time5.wrongWay))], check: true) }
                    return HandMove(hand: [:], missHand: [:], set: [("n", Double(n))], check: true)
                })
        }
        switch st {
        case 0:
            return Hands(tap: { q in
                guard let n = (1...12).first(where: { let p = Self.point(30 * Double($0), Self.nr); return abs(q.x - p.x) <= 1.8 && abs(q.y - p.y) <= 1.8 }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("h", Double(n))], keep: ["wh": n == P.H ? -1 : Double(n)], check: true)
            })
        case 1:
            var h = turning(start: 0)
            h.tap = { q in
                guard onFace(q) else { return nil }
                if P.M == 0 && abs(Self.angle(q)) <= 35 { return HandMove(hand: [:], missHand: [:], set: [("n", 0)], check: true) }
                return abs(Self.angle(q)) > 35 ? HandMove(hand: [:], missHand: [:], set: [("n", Double(Time5.wrongStart))], check: true) : HandMove(hand: nil)
            }
            return h
        case 3:
            return Hands(tap: { q in
                guard let i = Self.picks.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                let right = (P.ev?.pm ?? false) ? 1 : 0
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["wc": i == right ? -1 : Double(i)], check: true)
            })
        case 5: return turning(start: 30 * (s.run.kept["tn"] ?? 0))
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Time5.Parts(s.numbers)
        func round(from a: Double, to b: Double) -> [CGPoint] {
            let k = max(2, Int(abs(b - a) / 15))
            var out: [CGPoint] = []
            for i in 0...k { out.append(Self.point(a + (b - a) * Double(i) / Double(k), 6)) }
            return out
        }
        switch at(s) {
        case 0: return [.tap(.picture(Self.point(30 * Double(P.H), Self.nr)))]
        case 1: return P.M == 0 ? [.tap(.picture(Self.point(0, 6)))] : [.path(round(from: 0, to: 30 * Double(P.K)))]
        case 3: let r = Self.picks[(P.ev?.pm ?? false) ? 1 : 0]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case 5: return [.path(round(from: 30 * (s.run.kept["tn"] ?? 0), to: 30 * Double(P.K)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Time5.Parts(s.numbers)
        switch at(s) {
        case 0:
            let n = P.M > 0 ? P.next : P.H % 12 + 2
            return HandMove(hand: nil, missHand: nil, set: [("h", Double(n))], keep: ["wh": Double(n)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("n", Double(P.M == 0 ? 2 : min(12, P.K + 1)))], check: true)
        case 3: let i = (P.ev?.pm ?? false) ? 0 : 1; return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["wc": Double(i)], check: true)
        case 5: let n = P.K < 11 ? P.K + 1 : P.K - 1; return HandMove(hand: [:], missHand: [:], set: [("t", Double(n))], keep: ["tn": Double(n)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Time5.Parts(s.numbers)
        guard at(s) == 2 else { return nil }
        return P.M > 0 ? ["x": Double(P.next), "y": Double(P.M)] : ["x": Double(P.H), "y": 12]
    }
}
