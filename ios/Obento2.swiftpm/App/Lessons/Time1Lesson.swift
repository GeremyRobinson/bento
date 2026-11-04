import SwiftUI

/// Time to the hour and half hour on the paper, as in the preview (design/prototype/grade1-ch5.html, dTime). One square is
/// one minute: the clock face 20 squares across (centred on a block corner, its edge on the strong lines), its numbers inside
/// the edge, the short hand thick, the long hand long; under it the hour strip, 60 squares (a block for each number on the
/// face), 3 tall, so half past is its middle, right under the 6. Tap the number the short hand points at (or just passed):
/// it's ringed and the hour and the next are written at the strip's ends. Then trace from 12 round to the long hand: the
/// face shades behind the finger, the strip fills a square a minute, the short hand's ghost moves on with it, counted
/// ("30 minutes"); on the hour, tap where the long hand points. Then write the time, [8] : [30], "half past 8" beside it,
/// with the digit pad in its grid left of the clock.
///
/// Kept: "wn" a number tapped and wrong; "chkh", "chkm" what was last checked. Hand while tracing: "grab", "acc" (degrees
/// gone round), "prev", "m", "bad" (started away from 12), "ww" (gone the wrong way), "mv", "gx", "gy".
@MainActor
struct Time1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["acc", "prev", "m", "bad", "ww", "mv", "gx", "gy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let cx = 35.0, cy = 10.0, R = 10.0, nr = 7.9, sx = 5.0, sy = 20.0, line = 29.0, padX = 0.0, padY = -1.0

    static func point(_ deg: Double, _ r: Double) -> CGPoint { CGPoint(x: cx + r * sin(deg * .pi / 180), y: cy - r * cos(deg * .pi / 180)) }
    static func angle(_ q: CGPoint) -> Double { atan2(q.x - cx, -(q.y - cy)) * 180 / .pi }

    /// A hand at `deg`, `len` long and `w` wide at the hub (a ghost: only its outline, faint).
    private func hand(_ pen: inout GridPen, _ id: String, _ deg: Double, _ len: Double, _ w: Double, ghost: Bool = false) {
        let r = deg * .pi / 180, u = (sin(r), -cos(r)), n = (cos(r), sin(r))
        func p(_ t: Double, _ s: Double) -> CGPoint { pen.P(Self.cx + u.0 * t + n.0 * s, Self.cy + u.1 * t + n.1 * s) }
        let pts = [p(0, w / 2), p(len, 0), p(0, -w / 2), p(-1, 0)]
        if ghost { pen.sketch.line(id, pts + [pts[0]], .ink3, width: Sketch.stroke) }
        else { pen.sketch.polygon(id, pts, .ink); pen.sketch.line(id + "o", pts + [pts[0]], .ink, width: Sketch.stroke) }
    }
    /// The face shaded from 12 round `m` minutes, and the strip filled `m` squares.
    private func traced(_ pen: inout GridPen, _ m: Double) {
        guard m > 0.05 else { return }
        let n = max(2, Int(m.rounded(.up)))
        let arc = (0...n).map { i in Self.point(6 * m * Double(i) / Double(n), Self.R) }
        pen.sketch.polygon("sec", [pen.P(Self.cx, Self.cy)] + arc.map { pen.P($0.x, $0.y) }, .tint(0.2))
        pen.fill("sfill", col: Self.sx, row: Self.sy, w: m, h: 3, .tint(0.45))
    }

    func blocksAt(_ s: PaperState) -> CGPoint? { (2...3).contains(at(s)) ? DigitPad.checkAt(x: Self.padX, y: Self.padY, .grid) : nil }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Time1.Parts(s.numbers), st = at(s), T = Double(P.minute)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let tracing = st == 1 && s.grabbed && s.h("bad") != 1
        // what's been traced: live while the finger goes round, the whole of it once it's right
        if tracing {
            let m = s.h("m") ?? 0
            traced(&live, m)
            // the numbers and hands over the shading (the live layer lies over the picture)
            for n in 1...12 {
                let p = Self.point(30 * Double(n), Self.nr)
                live.word("Lcn\(n)", "\(n)", at: p.x, p.y, n == P.hour ? KK.maths.colour(.chapter) : KK.maths)
            }
            hand(&live, "Llh", T * 6, 6.6, 0.5)
            hand(&live, "Lsh", (Double(P.hour % 12) + T / 60) * 30, 4.4, 1.1)
            live.dot("Lhub", at: Self.cx, Self.cy, radius: 0.45, .ink)
            if P.half { hand(&live, "ghost", (Double(P.hour % 12) + m / 60) * 30, 4.4, 1.1, ghost: true) }
            let ro = Len1.pl(Int(m), "minute", "minutes")
            live.reads(ro)
            A1.note(&live, "mn", ro, x: Self.cx + Self.R + 1.5, y: Self.cy)
        } else if st >= 2 {
            traced(&pic, T)
            A1.note(&pic, "mn", Len1.pl(P.minute, "minute", "minutes"), x: Self.cx + Self.R + 1.5, y: Self.cy)
        }
        pic.circle("face", at: Self.cx, Self.cy, radius: Self.R, .ink)
        let wn = st == 0 ? s.run.kept["wn"].map { Int($0) } : nil
        for n in 1...12 {
            let p = Self.point(30 * Double(n), Self.nr), bad = wn == n, picked = st >= 1 && n == P.hour
            pic.word("cn\(n)\(bad)\(picked)", "\(n)", at: p.x, p.y, bad ? KK.maths.colour(KK.red) : picked ? KK.maths.colour(.chapter) : KK.maths)
        }
        if st >= 1 { let p = Self.point(30 * Double(P.hour), Self.nr); pic.circle("pk", at: p.x, p.y, radius: 1.55, .chapter) }
        hand(&pic, "lh", T * 6, 6.6, 0.5)
        hand(&pic, "sh", (Double(P.hour % 12) + T / 60) * 30, 4.4, 1.1)
        pic.dot("hub", at: Self.cx, Self.cy, radius: 0.45, .ink)
        // the hour strip, the hours at its ends once the hour is read
        pic.sketch.box("strip", pic.R(Self.sx, Self.sy, 60, 3), .ink, width: Sketch.stroke)
        if st >= 1 {
            // under the strip's ends (beside them, the 11-inch iPad showed it at 74%)
            pic.word("hl", "\(P.hour)", at: Self.sx, Self.sy + 4.5, KK.maths)
            pic.word("hr", "\(P.next)", at: Self.sx + 60, Self.sy + 4.5, KK.maths)
        }
        let short = Self.point((Double(P.hour % 12) + T / 60) * 30, 2.5)
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hint(&pic, "hr", short.x, short.y, radius: 3.2) }
            if s.on("spot") { let p = Self.point(30 * Double(P.hour), Self.nr); KK.hint(&pic, "spot", p.x, p.y, radius: 1.9) }
        case 1:
            let twelve = Self.point(0, Self.nr), end = Self.point(T * 6, Self.nr)
            if s.on("ring") && !s.on("spot") { KK.hint(&pic, "hr", twelve.x, twelve.y, radius: 1.9) }
            if s.on("spot") { KK.hint(&pic, "spot", end.x, end.y, radius: 1.9) }
        case 2, 3:
            let (vh, wh) = DigitPad.typed(s, "x", want: P.hour, chk: "chkh"), (vm, wm) = DigitPad.typed(s, "y", want: P.minute, chk: "chkm")
            let toks: [A1.Tok] = st == 2 ? [.box(vh, wrong: wh), .op(":"), .box(nil, wrong: false)] : [.n(P.hour, .chapter), .op(":"), .box(vm, wrong: wm)]
            let end = A1.record(&pic, "rec", toks, x: Self.sx, line: Self.line)
            M7.row(&pic, "recw", [.w(P.said)], x: end.rounded(.up) + 1, line: Self.line)
            DigitPad.draw(&pic, "pad", x: Self.padX, y: Self.padY, .grid)
            if s.on("ring") && !s.on("spot") {
                if st == 2 { KK.hint(&pic, "hr", short.x, short.y, radius: 3.2) } else { KK.hintBox(&pic, "hr", x: Self.sx, y: Self.sy, w: max(1, T), h: 3) }
            }
            if s.on("spot") { A1.note(&pic, "spot", st == 2 ? "\(P.hour)" : P.half ? "30" : "00", x: Self.padX + 14, y: Self.padY + 2) }
        default:
            let end = M7.row(&pic, "rec", [.n(P.hour, .chapter), .op(":"), .t(P.half ? "30" : "00", .chapter)], x: Self.sx, line: Self.line)
            M7.row(&pic, "recw", [.w(P.said)], x: end.rounded(.up) + 1, line: Self.line)
        }
        let right = max(Self.sx + 60 + KK.width("\(P.next)", KK.maths) / 2, Self.cx + Self.R + 1.5 + L5.smallWidth("30 minutes"))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: (2...3).contains(st) ? ["Check"] : [], extent: pic.R(0, -1, right, Self.sy + 7))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Time1.Parts(s.numbers)
        switch at(s) {
        case 0:
            return Hands(tap: { q in
                guard let n = (1...12).first(where: { let p = Self.point(30 * Double($0), Self.nr); return abs(q.x - p.x) <= 1.8 && abs(q.y - p.y) <= 1.8 }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("h", Double(n))], keep: ["wn": n == P.hour ? -1 : Double(n)], check: true)
            })
        case 1:
            let T = P.minute
            return Hands(
                tap: { q in
                    guard hypot(q.x - Self.cx, q.y - Self.cy) <= Self.R + 1.5 else { return nil }
                    // on the hour, a tap where the long hand points is the answer; a tap elsewhere waits for a trace
                    if T == 0 && abs(Self.angle(q)) <= 35 { return HandMove(hand: [:], missHand: [:], set: [("m", 0)], check: true) }
                    return abs(Self.angle(q)) > 35 ? HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true) : HandMove(hand: nil)
                },
                grab: { q in
                    guard hypot(q.x - Self.cx, q.y - Self.cy) <= Self.R + 1.5 else { return nil }
                    let a = Self.angle(q)
                    if abs(a) > 35 { return ["grab": 1, "bad": 1, "gx": q.x, "gy": q.y] }
                    return ["grab": 1, "bad": 0, "acc": a, "prev": a, "m": Double(max(0, min(60, Int((a / 6).rounded())))), "ww": 0, "mv": 0, "gx": q.x, "gy": q.y]
                },
                drag: { q, h in
                    var h = h
                    if hypot(q.x - (h["gx"] ?? q.x), q.y - (h["gy"] ?? q.y)) > 0.4 { h["mv"] = 1 }
                    guard h["bad"] != 1 else { return h }
                    let a = Self.angle(q)
                    var d = a - (h["prev"] ?? a)
                    if d > 180 { d -= 360 }
                    if d <= -180 { d += 360 }
                    let acc = (h["acc"] ?? 0) + d
                    h["acc"] = acc; h["prev"] = a
                    if acc < -12 { h["ww"] = 1 }
                    h["m"] = Double(max(0, min(60, Int((acc / 6).rounded()))))
                    return h
                },
                release: { h in
                    if h["bad"] == 1 { return HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true) }
                    let m = Int(h["m"] ?? 0)
                    if h["mv"] != 1 { return T == 0 ? HandMove(hand: [:], missHand: [:], set: [("m", 0)], check: true) : HandMove(hand: [:]) }
                    if h["ww"] == 1 { return HandMove(hand: [:], missHand: [:], set: [("m", -2)], check: true) }
                    if abs(m - T) <= 2 { return HandMove(hand: [:], missHand: [:], set: [("m", Double(T))], check: true) }
                    return HandMove(hand: [:], missHand: [:], set: [("m", m > T ? -3 : -4)], check: true)
                })
        case 2: return DigitPad.hands(s, "x", want: P.hour, x: Self.padX, y: Self.padY, .grid, chk: "chkh")
        case 3: return DigitPad.hands(s, "y", want: P.minute, x: Self.padX, y: Self.padY, .grid, chk: "chkm")
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Time1.Parts(s.numbers)
        switch at(s) {
        case 0: return [.tap(.picture(Self.point(30 * Double(P.hour), Self.nr)))]
        case 1:
            if !P.half { return [.tap(.picture(Self.point(0, 5)))] }
            return [.path((0...12).map { Self.point(15 * Double($0), 5.5) })]
        case 2: return DigitPad.demo(P.hour, x: Self.padX, y: Self.padY, .grid)
        case 3: return DigitPad.demo(P.minute, x: Self.padX, y: Self.padY, .grid)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Time1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let n = P.half ? P.next : P.longAt
            return HandMove(hand: nil, missHand: nil, set: [("h", Double(n))], keep: ["wn": Double(n)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("m", P.half ? -4 : -1)], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.longAt))], keep: ["chkh": Double(P.longAt)], check: true)
        case 3: return HandMove(hand: nil, missHand: nil, set: [("y", Double(P.longAt))], keep: ["chkm": Double(P.longAt)], check: true)
        default: return nil
        }
    }
}
