import SwiftUI

/// Converting units on the paper (design/grade5.md, Converting units). Big to small: one big unit is a bar 48 squares
/// long (40 for 100 and 1000), a bar for each big unit (the last half long for a half), each named "1 ft" at its right
/// end, their column braced and named with the amount ("3 ft"): the problem, written once as the picture's own names.
/// The ruler over the first bar sets one piece; its readout says the small units the bar would be cut into ("12 in",
/// or "100 cm" for ten pieces of 10), its cuts dashed down the first bar. Cut cuts it; then every bar is cut the same
/// way and every piece counted on (See), and the record `3 ft = 3 × 12 = [ ] in` is written 3 rows under the bars, the
/// product typed. Small to big: the small units are one long bar named with the amount ("250 cm"); a one-big-unit
/// ruler hops along it, the hops arcing over the bar with their count, the readout "2 m = 200 cm" live; let go where
/// whole big units end, what's left is bracketed under the bar, and `250 cm = 250 ÷ 100 = [ ] m` is written. The last
/// words say why. The bars and the ruler are the fractions family's kit (BarsKit.swift).
@MainActor
struct UnitsLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, and the first bar's top (big to small); the long bar's top (small
    /// to big, the hops over it).
    nonisolated static let ruler = 2.0, top = 4.0, longTop = 6.0

    var liveKeys: Set<String> { ["ruler", "hops"] }

    /// A problem's numbers, and the squares they make.
    struct Q {
        let p: ConvertUnits.Problem
        /// Big to small: a bar's length, one piece's worth in small units, the pieces in a bar and their squares.
        let L: Int, worth: Double, k: Int, pw: Int
        /// How many big units, the bars drawn, and whether the last is a half.
        let W: Double, bars: Int, half: Bool
        /// A bar's height: 4 squares, or 2 when there are more bars than 4-square ones fit.
        let h: Double
        /// Small to big: a big unit's squares along the long bar (a hop), so the whole bar fills about 60 squares.
        let U: Int
        init(_ n: Numbers) {
            p = ConvertUnits.Problem(n)
            let b = ConvertUnits.bar(p.f)
            L = b.length; worth = b.piece; k = p.pieces; pw = L / max(1, k)
            W = p.big; bars = Int(W.rounded(.up)); half = W != W.rounded(.down)
            h = bars <= 3 ? Bars.height : 2
            // the hops the hand may lay: every whole big unit, and one past them (so a hop past the end can be made)
            let hops = Int((W + 1e-9).rounded(.down)) + 1
            U = [24, 20, 16, 12, 10, 8, 6].first { hops * $0 <= 60 } ?? 6
        }
        /// Bar j's top row: a gap of 2 under a 4-square bar, 1 under a 2-square one.
        func row(_ j: Int) -> Double { UnitsLesson.top + Double(j) * (h + (h == Bars.height ? Bars.gap : 1)) }
        var bottom: Double { row(bars - 1) + h }
        /// Bar j's length, in squares (the last half long for a half).
        func length(_ j: Int) -> Int { half && j == bars - 1 ? L / 2 : L }
        /// The pieces in bar j.
        func pieces(_ j: Int) -> Int { half && j == bars - 1 ? k / 2 : k }
        /// Where the ruler starts: the longest piece that isn't the answer, so the hand has something to find.
        var start: Int { Ruler.lengths(L).last { $0 != pw } ?? pw }
        /// Small to big: the long bar's length, its bottom, the whole hops, and the most the hand may hop (one past them).
        var long: Double { W * Double(U) }
        var longBottom: Double { UnitsLesson.longTop + Bars.height }
        var whole: Int { p.whole }
        var most: Int { p.whole + 1 }
        /// A hop's height over the bar.
        var hopH: Double { U >= 10 ? 3 : 2 }
    }

    // MARK: big to small: the ruler

    private func theRuler(_ q: Q) -> Ruler {
        let L = q.L, worth = q.worth, S = q.p.S
        return Ruler(W: L, row: Self.ruler, from: Self.top - 1, to: q.row(0) + q.h + (q.h == Bars.height ? 1 : 0.5), old: [], start: q.start,
                     readout: { l in "\(fmt(Double(L / max(1, l)) * worth)) \(S)" })
    }

    /// The small units the bar would be cut into at the ruler's length `l`.
    private func cutValue(_ q: Q, _ l: Int) -> Double { Double(q.L / max(1, l)) * q.worth }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers)
        return q.p.up ? drawUp(s, q) : drawDown(s, q)
    }

    private func drawDown(_ s: PaperState, _ q: Q) -> PaperDrawing {
        let cut = s.on("cut"), done = s.on("done"), h = q.h, pw = Double(q.pw)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let maths = Bars.maths, font = PaperText.font(maths.size, maths.weight, digits: true)

        // MARK: the bars, whole until the first is cut; then every bar cut and every piece counted on, in its small
        // units, the first bar first (the See: they draw in in this order)
        var counted = 0
        for j in 0..<q.bars {
            let y = q.row(j), len = q.length(j)
            pic.fill("b\(j)f", col: 0, row: y, w: Double(len), h: h, Bars.shade)
            Bars.bar(&pic, "b\(j)", row: y, parts: cut ? q.pieces(j) : 1, W: len, h: h)
            if cut {
                for i in 0..<q.pieces(j) {
                    counted += 1
                    pic.word("n\(j)_\(i)", fmt(Double(counted) * q.worth), at: (Double(i) + 0.5) * pw, y + h / 2, Bars.count)
                }
            }
        }

        // MARK: the names at the bars' right ends ("1 ft", the half "0.5 ft"), and the bars braced, named with the amount
        let nx = Double(q.L) + 1
        var widest = 0.0
        for j in 0..<q.bars {
            let name = "\(fmt(q.half && j == q.bars - 1 ? 0.5 : 1)) \(q.p.B)"
            widest = max(widest, PaperText.width(name, font) / Paper.cell)
            pic.label("nm\(j)", name, maths, .right, edge: nx, along: q.row(j) + h / 2)
        }
        let bx = (nx + 0.5 + widest + 0.5).rounded(.up)
        Bars.brace(&pic, "brace", col: bx, from: q.row(0), to: q.bottom)
        pic.label("amt", "\(fmt(q.p.n)) \(q.p.B)", maths, .right, edge: bx + 2, along: (q.row(0) + q.bottom) / 2)

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") && !cut {
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: a hint on the record: the last piece counted, ringed
        if cut && !done && s.on("last") {
            let j = q.bars - 1
            pic.circle("last", at: (Double(q.pieces(j)) - 0.5) * pw, q.row(j) + h / 2, radius: min(h == Bars.height ? 1.3 : 0.9, pw / 2 - 0.15), .chapter, dashed: true)
        }

        // MARK: the record, as school writes it: n ft = n × f = [n·f] in, the product typed
        var boxes: [WorkBox] = []
        if cut {
            var r = Record()
            r.num(&rec, "rn", q.p.n); r.unit(&rec, "rB", q.p.B); r.op(&rec, "re1", "=")
            r.num(&rec, "rn2", q.p.n); r.op(&rec, "rx", "×"); r.num(&rec, "rf", q.p.f); r.op(&rec, "re2", "=")
            r.answer(&rec, q.p.answer, done: done); r.unit(&rec, "rS", q.p.S)
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    // MARK: small to big: the hops

    /// The hops laid now: where the hand left them, or one to start.
    private func hops(_ s: PaperState) -> Int { s.h("hops").map { Int($0.rounded()) } ?? 1 }

    private func drawUp(_ s: PaperState, _ q: Q) -> PaperDrawing {
        let hopped = s.on("hopped"), done = s.on("done"), U = Double(q.U), T = Self.longTop, B = q.longBottom
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let maths = Bars.maths

        // MARK: the small units, one long bar named with the amount; cut where each big unit ends once it's hopped
        pic.fill("lf", col: 0, row: T, w: q.long, h: Bars.height, Bars.shade)
        pic.sketch.box("lo", pic.R(0, T, q.long, Bars.height), .chapter, width: Sketch.stroke)
        pic.label("amt", "\(fmt(q.p.n)) \(q.p.S)", maths, .right, edge: q.long + 1, along: T + Bars.height / 2)

        // the hops: arcs a big unit long over the bar, each counted under its top
        func lay(_ pen: inout GridPen, _ k: Int, tag: String) {
            for i in 0..<k {
                let a = Double(i) * U
                pen.hop("\(tag)h\(i)", from: a, to: a + U, row: T, height: q.hopH)
                pen.word("\(tag)c\(i)", "\(i + 1)", at: a + U / 2, T - q.hopH / 2 + 0.25, Bars.count)
            }
        }
        if hopped {
            lay(&pic, q.whole, tag: "s")
            if q.whole > 1 || q.p.left > 0 {
                pic.sketch.segments("lc", (1...q.whole).compactMap { i in Double(i) * U < q.long - 0.01 ? (pic.P(Double(i) * U, T), pic.P(Double(i) * U, B)) : nil }, .chapter, width: Sketch.stroke)
            }
            // what's left, bracketed under the bar
            if q.p.left > 0 {
                let a = Double(q.whole) * U, c = q.long
                pic.line("lb", [(a, B + 0.5), (a, B + 1), (c, B + 1), (c, B + 0.5)], .ink)
                pic.label("lbw", "\(fmt(q.p.left)) \(q.p.S)", Bars.small, .below, edge: B + 1, along: (a + c) / 2)
            }
        }

        // MARK: the ruler hopping, live as it's dragged: its hops, its handle, and the readout "2 m = 200 cm"
        if s.on("hops") && !hopped {
            let k = hops(s), x = Double(k) * U
            lay(&live, k, tag: "l")
            live.dot("handle", at: x, T, radius: s.grabbed ? 0.75 : 0.6, .chapter, over: true)
            let text = "\(k) \(q.p.B) = \(fmt(Double(k) * q.p.f)) \(q.p.S)"
            let half = PaperText.width(text, PaperText.font(Bars.small.size, Bars.small.weight, digits: true)) / 2 / Paper.cell
            live.label("readout", text, Bars.small, .above, edge: T - q.hopH - 0.5, along: max(x / 2, half))
            live.reads(text)
        }

        // MARK: a hint on the record: what's left (or the last hop), ringed
        if hopped && !done && s.on("last") {
            if q.p.left > 0 { pic.circle("last", at: (Double(q.whole) * U + q.long) / 2, T + Bars.height / 2, radius: min(1.6, U / 4), .chapter, dashed: true) }
            else { pic.circle("last", at: (Double(q.whole) - 0.5) * U, T - q.hopH / 2 + 0.25, radius: 1, .chapter, dashed: true) }
        }

        // MARK: the record: n cm = n ÷ f = [n/f] m, the quotient typed
        var boxes: [WorkBox] = []
        if hopped {
            var r = Record()
            r.num(&rec, "rn", q.p.n); r.unit(&rec, "rS", q.p.S); r.op(&rec, "re1", "=")
            r.num(&rec, "rn2", q.p.n); r.op(&rec, "rd", "÷"); r.num(&rec, "rf", q.p.f); r.op(&rec, "re2", "=")
            r.answer(&rec, q.p.answer, done: done); r.unit(&rec, "rB", q.p.B)
            boxes = rec.boxes
        }
        // room for the hops the hand may lay past the end
        let extent = pic.R(0, T - q.hopH - 2, Double(q.most) * U, B - T + q.hopH + 2)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: [], extent: extent)
    }

    /// The record written left to right on row 2's middle: numbers two squares a digit (the point on a grid line), signs
    /// two squares, units in whole squares with half a square or more either side.
    @MainActor private struct Record {
        var x = 0.0
        let maths = Bars.maths
        mutating func num(_ rec: inout GridPen, _ id: String, _ v: Double, _ colour: Sketch.Colour = .ink) {
            let t = fmt(v), w = 2 * Double(t.filter { $0 != "." }.count)
            rec.digits(id, t, right: x + w, row: 2, per: 2, colour); x += w
        }
        mutating func op(_ rec: inout GridPen, _ id: String, _ s: String) { rec.word(id, s, at: x + 1, 2, maths); x += 2 }
        mutating func unit(_ rec: inout GridPen, _ id: String, _ s: String) {
            let w = (PaperText.width(s, PaperText.font(maths.size, maths.weight, digits: true)) / Paper.cell + 1).rounded(.up)
            rec.word(id, s, at: x + w / 2, 2, maths); x += w
        }
        mutating func answer(_ rec: inout GridPen, _ v: Double, done: Bool) {
            if done { num(&rec, "ra", v, .chapter); return }
            let cells = fmt(v).count
            rec.answerBox("x", right: x + 2 * Double(cells), mid: 2, per: 2, cells: cells, centred: true, keepsLeft: true)
            x += 2 * Double(cells) + 2
        }
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers)
        if !q.p.up {
            guard s.on("ruler") && !s.on("cut") else { return nil }
            // the ruler's handle, dragged and snapping to the lengths that divide the bar (BarsKit's); Cut fills
            // "1 ft = [x] in" with the small units its pieces make, checked
            var h = theRuler(q).hands(s)
            let w = theRuler(q).length(s), v = cutValue(q, w)
            h.actions = ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", v)], check: true) }]
            return h
        }
        guard s.on("hops") && !s.on("hopped") else { return nil }
        let k = hops(s), U = Double(q.U), T = Self.longTop, most = q.most
        return Hands(
            grab: { p in abs(p.x - Double(k) * U) < 2.5 && p.y > T - 5 && p.y < T + Bars.height + 1 ? ["grab": 1, "hops": Double(k)] : nil },
            drag: { p, _ in ["grab": 1, "hops": Double(min(max(1, Int((p.x / U).rounded())), most))] },
            release: { h in
                let n = h["hops"] ?? Double(k)
                // let go where it was picked up: nothing to check
                return n == Double(k) ? HandMove(hand: ["hops": n], missHand: nil)
                                      : HandMove(hand: ["hops": n], missHand: nil, set: [("h", n)], check: true)
            })
    }

    /// The record is written once the ruler (or the hops' readout) is put away: 3 rows under the picture.
    func recordRow(_ n: Numbers) -> Double? {
        let q = Q(n)
        return q.p.up ? q.longBottom + (q.p.left > 0 ? 3 : 0) + 3 : q.bottom + 3
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        if !q.p.up { return s.on("ruler") && !s.on("cut") ? theRuler(q).demo(s, to: q.pw) : [] }
        guard s.on("hops") && !s.on("hopped") else { return [] }
        let U = Double(q.U)
        return [.drag(from: CGPoint(x: Double(hops(s)) * U, y: Self.longTop), to: CGPoint(x: Double(q.whole) * U, y: Self.longTop))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        if !q.p.up {
            guard s.on("ruler") else { return nil }
            // a cut the web names (a foot cut into 3), else the ruler where it starts
            let slips = Set((s.step.answer?.known ?? []).compactMap { $0.values["x"] })
            let l = Ruler.lengths(q.L).first { slips.contains(cutValue(q, $0)) } ?? q.start
            return HandMove(hand: ["ruler": Double(l)], missHand: nil, set: [("x", cutValue(q, l))], check: true)
        }
        // one hop past the end
        guard s.on("hops") else { return nil }
        return HandMove(hand: ["hops": Double(q.whole + 1)], missHand: nil, set: [("h", Double(q.whole + 1))], check: true)
    }
}
