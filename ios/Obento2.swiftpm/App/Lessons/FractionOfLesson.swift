import SwiftUI

/// Fraction of a number on the paper (design/grade5.md, the fractions family): n/d of W. One square is one thing (a
/// 2 × 2 square when there are 30 or fewer), so the bar holds W things, each drawn in it, and is named "n/d of W" at its
/// right end: the problem, written once as the picture's own names. More than 54 things fill the bar a column of 2, 3
/// or 4 at a time (when a group is whole columns), so 108 is a bar 54 × 2, still counted, not a strip twice the screen.
/// The ruler's handle, over the bar, sets one group's size, snapping only to sizes that divide W; while it's dragged the readout names the groups ("fourths, 5 in each")
/// and the cuts show dashed down the bar. Cut cuts the bar into those groups and writes each group's count under it.
/// Then the child taps n groups to take them (they shade as they're tapped, the readout counting them); Take takes
/// them (skipped when n is 1: the one group is taken with the cut). The taken groups are bracketed n/d, and the record
/// n/d of W = W ÷ d × n = [ ] is written 3 rows under the picture, the answer typed. The last words say why.
@MainActor
struct FractionOfLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, and the bar's top.
    nonisolated static let ruler = 2.0, top = 4.0

    var liveKeys: Set<String> { ["ruler", "taps"] }

    /// A problem's numbers, and the squares they make.
    struct Q {
        /// The top, the bottom, the things, and each group's count.
        let n, d, W, g: Int
        /// Squares a thing (2 when there are 30 or fewer), things down a column, and the bar's length in squares.
        let c, r, L: Int
        init(_ p: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((p[k] ?? Double(v)).rounded()) }
            d = min(max(2, i("d", 2)), 12); n = min(max(1, i("n", 1)), d - 1)
            let w = max(d, i("W", d)); W = w - w % d; g = W / d
            c = W <= 30 ? 2 : 1
            // a long bar folds into columns of 2 to 4 things, each group still whole columns
            let (w0, g0) = (W, g)
            r = w0 <= 54 ? 1 : (2...4).first { g0 % $0 == 0 && w0 / $0 <= 54 } ?? 1
            L = W / r * c
        }
        var h: Double { Double(c * r) }
        /// A group's length in squares, and the bar's bottom.
        var gw: Double { Double(g / r * c) }
        var bottom: Double { FractionOfLesson.top + h }
        /// The rows under the bar: each group's count, and the taken groups' bracket.
        var counts: Double { bottom + 1 }
        var bracket: Double { bottom + 3 }
        /// The ruler's lengths (every group size that divides W in whole columns, in squares), and where it starts: the
        /// biggest that isn't the answer, so the hand has something to find.
        var snaps: [Int] { FractionOf.groupSizes(W).filter { $0 % r == 0 }.map { $0 / r * c } }
        var answer: Int { g / r * c }
        var start: Int { snaps.last { $0 != answer } ?? answer }
    }

    private func theRuler(_ q: Q) -> Ruler {
        let W = q.W, c = q.c, r = q.r
        return Ruler(W: q.L, row: Self.ruler, from: Self.top - 1, to: q.bottom + 1, old: [], start: q.start,
                     snaps: q.snaps, readout: { FractionOf.readout(W: W, each: $0 / c * r) })
    }

    /// The groups tapped, as bits of the hand's "taps".
    private func taps(_ s: PaperState) -> Set<Int> {
        let bits = Int(s.h("taps") ?? 0)
        return Set((0..<12).filter { bits & (1 << $0) != 0 })
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), L = Double(q.L), h = q.h, top = Self.top, gw = q.gw
        let cut = s.on("cut"), tap = s.on("tap"), taken = s.on("taken"), done = s.on("done")
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // MARK: the bar, a square (or 2 × 2) a thing; the taken groups shaded
        if taken { pic.fill("tf", col: 0, row: top, w: Double(q.n) * gw, h: h, Bars.shade) }
        let cols = q.W / q.r, rows = (1..<max(1, q.r)).map { j in (pic.P(0, top + Double(j * q.c)), pic.P(L, top + Double(j * q.c))) }
        pic.sketch.segments("things", (1..<cols).map { i in (pic.P(Double(i * q.c), top), pic.P(Double(i * q.c), top + h)) } + rows, .tint(0.42), width: 1)
        Bars.bar(&pic, "b", row: top, parts: cut ? q.d : 1, W: q.L, h: h)

        // MARK: each group's count under it, once it's cut
        if cut {
            for i in 0..<q.d { pic.label("g\(i)", "\(q.g)", Bars.count, .below, edge: q.bottom, along: (Double(i) + 0.5) * gw) }
        }
        // a hint on the record: the taken groups' counts ringed
        if taken && !done && s.on("ring") {
            for i in 0..<q.n { pic.circle("ring\(i)", at: (Double(i) + 0.5) * gw, q.counts, radius: 0.9, .chapter, dashed: true) }
        }
        // the taken groups bracketed, named n/d
        if taken {
            pic.bracket("br", from: 0, to: Double(q.n) * gw, row: q.bracket + 1, "\(q.n)/\(q.d)", Bars.small)
        }

        // MARK: the bar's name at its right end: n/d of W
        let nx = L + 2, mid = top + (h / 2).rounded(.up)
        Bars.fraction(&pic, "fn", q.n, q.d, col: nx, row: mid - 2)
        pic.word("fof", "of", at: nx + 5.5, mid, Bars.maths)
        pic.word("fW", "\(q.W)", at: nx + 7 + Double(String(q.W).count), mid, Bars.maths)

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: the take: groups shade as they're tapped, the readout counting them
        if tap {
            actions = ["Take"]
            let on = taps(s)
            for i in on.sorted() { live.fill("tap\(i)", col: Double(i) * gw, row: top, w: gw, h: h, Bars.shade) }
            live.label("tapw", "\(on.count) of \(q.d) groups", Bars.small, .above, edge: top - 0.5, along: max(L / 2, 5))
        }

        // MARK: the record, as school writes it: n/d of W = W ÷ d × n = [R], two squares a sign or a digit
        var boxes: [WorkBox] = []
        if taken {
            let maths = Bars.maths, k = Double(String(q.W).count)
            var x = 0.0
            func put(_ id: String, _ text: String, _ w: Double) { rec.word(id, text, at: x + w / 2, 2, maths); x += w }
            Bars.fraction(&rec, "rf", q.n, q.d, col: 0, row: 0); x = 4
            put("rof", "of", 3)
            put("rW", "\(q.W)", 2 * k)
            put("re1", "=", 2)
            put("rW2", "\(q.W)", 2 * k)
            put("rdiv", "÷", 2)
            put("rd", "\(q.d)", 2)
            if q.n > 1 { put("rx", "×", 2); put("rn", "\(q.n)", 2) }
            put("re2", "=", 2)
            let R = q.g * q.n
            if done { rec.word("ra", "\(R)", at: x + Double(String(R).count), 2, maths.colour(.chapter)) }
            else { rec.answerBox("x", right: x + 4, mid: 2, per: 2, cells: 2, centred: true, keepsLeft: true) }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers)
        if s.on("ruler") { return theRuler(q).hands(s) }
        guard s.on("tap") else { return nil }
        // a tap on a group (anywhere down the bar and its count) takes it, or puts it back; Take checks how many
        let bits = Int(s.h("taps") ?? 0), top = Self.top, gw = q.gw, L = Double(q.L), bottom = q.counts + 1
        let count = taps(s).count
        return Hands(
            tap: { p in
                guard p.x >= 0, p.x < L, p.y > top - 1.5, p.y < bottom else { return nil }
                let i = min(q.d - 1, Int(p.x / gw)), now = bits ^ (1 << i)
                return HandMove(hand: ["taps": Double(now)], missHand: nil, set: [("t", Double(now.nonzeroBitCount))])
            },
            actions: ["Take": { HandMove(hand: nil, missHand: nil, set: [("t", Double(count))], check: true) }])
    }

    /// The record is written 3 rows under the bracket's words.
    func recordRow(_ n: Numbers) -> Double? { Q(n).bracket + 6 }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        if s.on("ruler") { return theRuler(q).demo(s, to: q.answer) }
        guard s.on("tap") else { return [] }
        // the first n groups tapped (those already taken left as they are), then Take
        let on = taps(s)
        let flips = (0..<q.d).filter { ($0 < q.n) != on.contains($0) }
        return flips.map { .tap(.picture(CGPoint(x: (Double($0) + 0.5) * q.gw, y: Self.top + q.h / 2))) } + [.tap(.action("Take"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        // a cut into the wrong number of groups
        if s.on("ruler") { return HandMove(hand: ["ruler": Double(q.start)], missHand: nil, set: [("x", Double(q.L / q.start))], check: true) }
        // one group too many taken
        guard s.on("tap") else { return nil }
        let k = min(q.d, q.n + 1)
        return HandMove(hand: ["taps": Double((1 << k) - 1)], missHand: nil, set: [("t", Double(k))], check: true)
    }
}
