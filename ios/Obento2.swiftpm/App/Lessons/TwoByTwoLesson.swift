import SwiftUI

/// Two-digit times two-digit on the paper, as in the preview (design/prototype/grade4-ch2.html): 5th grade's rectangle,
/// one square a seat, every ten bold, the bigger number across (named over its top) and the smaller down (beside its left
/// side). Cut down where the across number's tens end: a handle on a stem over the top edge, the cut dashed through the
/// rectangle and the two widths written over it as it moves. Then cut across where the down number's tens end, with a
/// handle beside the left side. The four parts part a square, gliding apart; each lights in turn (tens × tens first),
/// its count written on it, and is written in the record with its multiplication beside it; then the four are added.
/// The biggest rectangles are seen from further back, their words, record and blocks drawn twice as big (whole steps).
@MainActor
struct TwoByTwoLesson: PaperLesson {
    var liveKeys: Set<String> { ["cx", "cy", "grab"] }
    /// A size being tried (Q.k lays the problem out at each size it tries); nil: the problem's own.
    var trying: Double? = nil
    private func q(_ run: LessonRun) -> Q { Q(run.numbers, story: run.story, k: trying) }

    private static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    private static let readout = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let product = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let minor = Sketch.Colour.tint(0.45), ten = Sketch.Colour.tint(0.85)

    @MainActor struct Q {
        let P: TwoByTwo.Parts
        /// Words, blocks and the record drawn k times as big when the rectangle is big.
        let k: Double
        init(_ n: Numbers, story: Bool = false, k fixed: Double? = nil) {
            P = TwoByTwo.Parts(n)
            k = fixed ?? Self.k(a: P.a, b: P.b, story: story)
        }
        /// Bigger by a whole step while its words would show smaller than 20 points (MultiplyLesson's rule).
        static func k(a: Int, b: Int, story: Bool) -> Double {
            let key = "\(a)×\(b)\(story ? " story" : "")"
            if let k = scales[key] { return k }
            let run = LessonRun(TwoByTwo.spec, numbers: TwoByTwo.numbers(a: a, b: b), story: story)
            var k = 1.0
            while k < 2, ProblemGrid.stackPlan(TwoByTwoLesson(trying: k), run, auto: false).zoom * Sketch.wordSize * k < 20 { k += 1 }
            scales[key] = k
            return k
        }
        private static var scales: [String: Double] = [:]
        /// The rectangle's corner; the cut's handle rows over its top and beside its left side.
        var x0: Double { 5 * k }
        var top: Double { 4 * k }
        var hY: Double { top - 3 * k }
        var hX: Double { k }
        /// Where each part sits once parted (across × down: tens × tens, tens × ones, ones × tens, ones × ones).
        func at(_ i: Int) -> CGPoint {
            let across = i >= 2, down = i % 2 == 1
            return CGPoint(x: x0 + (across ? Double(P.T + 1) : 0), y: top + (down ? Double(P.S + 1) : 0))
        }
        /// Where a width written over the top goes beside the cut's stem at column c: its part's middle, or half a
        /// square clear of the stem.
        func clear(_ text: String, _ w: Sketch.Words, of c: Double, _ along: Double) -> Double {
            let half = PaperText.width(text, PaperText.font(w.size * k, w.weight, digits: true)) / Paper.cell / 2
            return along < c ? min(along, c - 0.5 * k - half) : max(along, c + 0.5 * k + half)
        }
    }

    /// 0 question, 1 cut down, 2 cut across, 3 a part, 4 the sum, 5 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func part(_ s: PaperState) -> Int { Int((s.picture["k"] ?? 0).rounded()) }

    func scale(_ run: LessonRun) -> Double { q(run).k }
    func recordBeside(_ run: LessonRun) -> Double? { q(run).top }
    func scale(_ n: Numbers) -> Double { Q(n, k: trying).k }
    func recordBeside(_ n: Numbers) -> Double? { Q(n, k: trying).top }
    func messageRows(_ n: Numbers) -> Int { 2 }

    /// The cuts' places now: the hand's while it cuts, the tens' after.
    private func cuts(_ s: PaperState, _ q: Q) -> (Int, Int) {
        let at = stage(s)
        let cx = at >= 2 ? q.P.T : Int((s.h("cx") ?? Double(q.P.a / 2)).rounded())
        let cy = at >= 3 ? q.P.S : Int((s.h("cy") ?? Double(q.P.b / 2)).rounded())
        return (cx, cy)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = self.q(s.run), P = q.P, at = stage(s), k = q.k, x0 = q.x0, top = q.top
        let a = Double(P.a), b = Double(P.b), T = Double(P.T), S = Double(P.S)
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)
        let parted = at >= 3, (cx, cy) = cuts(s, q), lit = at == 3 ? part(s) : at >= 4 ? -1 : -2

        // the rectangle: whole until both cuts are made, then four parts a square apart
        // drawn as its four parts from the start (their edges where the tens end are bold lines, as every ten is), so
        // when the cuts part them each glides from where it was
        for i in 0..<4 {
            let (w, h) = P.sides[i], p = parted ? q.at(i) : CGPoint(x: x0 + (i >= 2 ? T : 0), y: top + (i % 2 == 1 ? S : 0))
            squares(&pic, "pt\(i)", x: p.x, y: p.y, w: w, h: h, c0: i >= 2 ? P.T : 0, r0: i % 2 == 1 ? P.S : 0, lit: lit == i || lit == -1, edge: parted)
        }
        if !parted { pic.sketch.box("whole", pic.R(x0, top, a, b), .chapter, width: Sketch.stroke) }
        // the cuts while they're placed: a handle on a stem, the cut dashed through the rectangle
        if at == 1 {
            let x = x0 + Double(cx)
            live.line("stem1", [(x, q.hY), (x, top)], .ink)
            live.dot("h1", at: x, q.hY, radius: (s.grabbed ? 0.75 : 0.55) * k, .ink, over: true)
            live.line("cut1d", [(x, top), (x, top + b)], .chapter, dashed: true)
        }
        if at == 2 {
            pic.line("cut1s", [(x0 + T, top), (x0 + T, top + b)], .ink)
            let y = top + Double(cy)
            live.line("stem2", [(q.hX, y), (x0, y)], .ink)
            live.dot("h2", at: q.hX, y, radius: (s.grabbed ? 0.75 : 0.55) * k, .ink, over: true)
            live.line("cut2d", [(x0, y), (x0 + a, y)], .chapter, dashed: true)
        }
        // its names: the across number over the top, the down number beside the left; the parts' sizes once cut
        let pg = parted ? 1.0 : 0
        if at <= 1 && !s.grabbed && s.h("cx") == nil {
            pic.label("wa", "\(P.a)", Self.name, .above, edge: top, along: x0 + a / 2)
        } else {
            let c1 = Double(cx), w1 = "\(cx)", w2 = "\(P.a - cx)", W: Sketch.Words = at == 1 ? Self.readout : Self.name
            var pen = at == 1 ? live : pic
            pen.label("w1", w1, W, .above, edge: top, along: q.clear(w1, W, of: x0 + c1, x0 + c1 / 2))
            pen.label("w2", w2, W, .above, edge: top, along: q.clear(w2, W, of: x0 + c1 + pg, x0 + c1 + pg + (a - c1) / 2))
            if at == 1 { live = pen; live.reads("\(w1) | \(w2)") } else { pic = pen }
        }
        if at <= 1 || (at == 2 && !s.grabbed && s.h("cy") == nil) {
            pic.label("hb", "\(P.b)", Self.name, .left, edge: x0, along: top + b / 2)
        } else {
            let c2 = Double(cy), h1 = "\(cy)", h2 = "\(P.b - cy)", W: Sketch.Words = at == 2 ? Self.readout : Self.name, hh = 0.5 * k
            var pen = at == 2 ? live : pic
            pen.label("h1", h1, W, .left, edge: x0, along: min(top + c2 / 2, top + c2 - 0.5 * k - hh))
            pen.label("h2", h2, W, .left, edge: x0, along: max(top + c2 + pg + (b - c2) / 2, top + c2 + pg + 0.5 * k + hh))
            if at == 2 { live = pen; live.reads("\(h1) | \(h2)") } else { pic = pen }
        }
        // a hint: every ten counted along the edge being cut
        if at == 1, s.on("ring") { for j in 0..<(P.T / 10) { pic.word("ten\(j)", "10", at: x0 + Double(10 * j) + 5, top + 1.5 * k, Self.small) } }
        if at == 2, s.on("ring") { for j in 0..<(P.S / 10) { pic.word("tend\(j)", "10", at: x0 + 2.5 * k, top + Double(10 * j) + 5, Self.small) } }
        // a lit part's count on it, then its squares once written (when they fit; under it when they don't)
        if parted {
            for i in 0..<4 {
                let (w, h) = P.sides[i], p = q.at(i)
                let txt = lit == i ? P.counts[i] : (at > 3 || (at == 3 && i < part(s))) ? BigNumbers.commas(P.values[i]) : nil
                guard let txt else { continue }
                let tw = PaperText.width(txt, PaperText.font(Self.product.size * k, Self.product.weight, digits: true)) / Paper.cell
                if tw + k <= Double(w) && Double(h) >= 2 * k {
                    // on a plate of paper, so the bold lines don't run through it
                    pic.plate("onp\(i)", over: (cols: w, rows: h), at: p.x, p.y, w: Int((tw + 1).rounded(.up)), h: Int(2 * k))
                    pic.word("on\(i)", txt, at: p.x + Double(w) / 2, p.y + Double(h) / 2, Self.product)
                }
                else if lit == i {
                    // too small to hold it: beside the part, to its right
                    pic.label("on\(i)", txt, Self.product, .right, edge: p.x + Double(w), along: p.y + Double(h) / 2)
                }
            }
        }

        // the record: each part with its multiplication beside it; a rule; the sum
        var boxes: [WorkBox] = []
        if parted {
            let per = 2 * k, xr = (3 + 2 * Double(String(P.total).count)) * k
            func row(_ i: Int) -> Double { (Double(i) * 2 + 1) * k }
            let shown = at == 3 ? part(s) + 1 : 4
            for i in 0..<shown {
                let v = P.values[i]
                if at == 3 && i == part(s) { rec.answerBox("x", right: xr, mid: row(i), per: per, cells: String(v).count, commas: true) }
                else { number(&rec, "pv\(i)", v, right: xr, row: row(i), per: per) }
                let (x, y) = P.sides[i]
                let xe = xr + 2 * k + per * Double(String(x).count)
                number(&rec, "pe\(i)a", x, right: xe, row: row(i), per: per)
                rec.word("pe\(i)x", "×", at: xe + 1.5 * k, row(i), Record.maths)
                number(&rec, "pe\(i)b", y, right: xe + 3 * k + per * Double(String(y).count), row: row(i), per: per)
            }
            if at >= 4 {
                rec.word("plus", "+", at: per / 2, row(3), Record.maths)
                rec.rule("rule", from: 0, to: xr, row: 8 * k)
                if at == 4 { rec.answerBox("x", right: xr, mid: 9 * k, per: per, cells: String(P.total).count, commas: true) }
                else { number(&rec, "tot", P.total, right: xr, row: 9 * k, per: per, .chapter) }
            }
            boxes = rec.boxes
        }
        let extent = pic.R(0, q.hY - k, x0 + a + 1 + 3 * k, top + b + 2 - q.hY + k)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, extent: extent)
    }

    /// A number written `per` squares a digit, its ones digit ending on column `right`, its commas on the lines between.
    private func number(_ pen: inout GridPen, _ id: String, _ v: Int, right: Double, row: Double, per: Double, _ colour: Sketch.Colour = .ink) {
        let s = Array(String(v))
        for (i, ch) in s.reversed().enumerated() {
            pen.word("\(id)d\(i)", String(ch), at: right - per * (Double(i) + 0.5), row, Record.maths.colour(colour))
            if i > 0 && i % 3 == 0 { pen.word("\(id)c\(i)", ",", at: right - per * Double(i), row, Record.maths.colour(colour)) }
        }
    }

    /// A part of the rectangle: its squares fine, every ten of the whole rectangle bold, its outline, its fill (lit while
    /// it's being written). Its pieces keep their ids, so when the cuts part it, it glides.
    private func squares(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Int, h: Int, c0: Int, r0: Int, lit: Bool, edge: Bool) {
        var fine: [(CGPoint, CGPoint)] = [], bold: [(CGPoint, CGPoint)] = []
        for i in 1..<max(1, w) { let seg = (pen.P(x + Double(i), y), pen.P(x + Double(i), y + Double(h))); if (c0 + i) % 10 == 0 { bold.append(seg) } else { fine.append(seg) } }
        for j in 1..<max(1, h) { let seg = (pen.P(x, y + Double(j)), pen.P(x + Double(w), y + Double(j))); if (r0 + j) % 10 == 0 { bold.append(seg) } else { fine.append(seg) } }
        pen.sketch.segments("\(id)m", fine, Self.minor, width: 1)
        pen.sketch.segments("\(id)t", bold, Self.ten, width: Sketch.stroke)
        pen.sketch.box("\(id)o", pen.R(x, y, Double(w), Double(h)), edge ? .chapter : Self.ten, width: Sketch.stroke)
        pen.fill("\(id)f\(lit)", col: x, row: y, w: Double(w), h: Double(h), .tint(lit ? 0.3 : 0.1))
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = self.q(s.run), P = q.P, at = stage(s), k = q.k, (cx, cy) = cuts(s, q)
        /// The square under the finger; drawn big (the camera far back), a bold line within half a square for each size up
        /// takes it, so a ten is easy to land on.
        func snap(_ v: Double, _ most: Int) -> Int {
            let ten = (v / 10).rounded() * 10
            let at = k > 1 && abs(v - ten) <= k / 2 ? ten : v.rounded()
            return max(1, min(most - 1, Int(at)))
        }
        if at == 1 {
            let hx = q.x0 + Double(cx)
            return Hands(
                grab: { p in abs(p.x - hx) < 2 * k && p.y > q.hY - 2 * k && p.y < q.top + Double(P.b) ? ["grab": 1, "cx": Double(cx)] : nil },
                drag: { p, _ in ["grab": 1, "cx": Double(snap(p.x - q.x0, P.a))] },
                release: { h in
                    let c = h["cx"] ?? Double(cx)
                    return HandMove(hand: ["cx": c], missHand: nil, set: [("x", c)], check: true)
                })
        }
        if at == 2 {
            let hy = q.top + Double(cy)
            return Hands(
                grab: { p in abs(p.y - hy) < 2 * k && p.x > q.hX - 2 * k && p.x < q.x0 + Double(P.a) ? ["grab": 1, "cy": Double(cy)] : nil },
                drag: { p, _ in ["grab": 1, "cy": Double(snap(p.y - q.top, P.b))] },
                release: { h in
                    let c = h["cy"] ?? Double(cy)
                    return HandMove(hand: ["cy": c], missHand: nil, set: [("x", c)], check: true)
                })
        }
        return nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = self.q(s.run), at = stage(s), (cx, cy) = cuts(s, q)
        if at == 1 { return [.drag(from: CGPoint(x: q.x0 + Double(cx), y: q.hY), to: CGPoint(x: q.x0 + Double(q.P.T), y: q.hY))] }
        if at == 2 { return [.drag(from: CGPoint(x: q.hX, y: q.top + Double(cy)), to: CGPoint(x: q.hX, y: q.top + Double(q.P.S)))] }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = q(s.run).P, at = stage(s)
        if at == 1 { let x = Double(P.T >= 20 ? P.T - 10 : P.T + 1); return HandMove(hand: ["cx": x], missHand: nil, set: [("x", x)], check: true) }
        if at == 2 { let y = Double(P.v > 1 ? P.S + 1 : P.S - 1); return HandMove(hand: ["cy": y], missHand: nil, set: [("x", y)], check: true) }
        return nil
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        guard stage(s) == 3, part(s) == 0 else { return nil }
        let P = q(s.run).P
        return ["x": Double(P.t * P.s)]
    }
}
