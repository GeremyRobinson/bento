import SwiftUI

/// Mixed numbers to fractions on the paper (design/grade5.md, the fractions family). The wholes are bars a whole long
/// (40 to 48 squares, the smallest the bottom divides, so each piece is a whole number of squares), 4 squares tall and 2
/// apart, all shaded, each named 1; under them the extra bar, cut into d pieces with n shaded, named n/d; the column of
/// names braced: the mixed number, written once. The ruler's handle, over the first whole, sets one piece's length; the
/// cuts it would make show dashed down every bar, and a dot under each of the extra bar's cuts is green when a new cut
/// lands on it, red when none does. Cut cuts every whole into those pieces: the cuts turn solid, every shaded piece is
/// numbered on across all the bars (the count reaching w × d + n), and the wholes are named d/d. Then the record,
/// w n/d = (w × d + n)/d = [S]/d, the top typed, and the last words say why. The bars and the ruler are the family's kit
/// (BarsKit.swift).
@MainActor
struct MixedNumbersLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, the first whole's top, and a bar's step down to the next.
    nonisolated static let ruler = 2.0, top = 4.0, step = Bars.height + Bars.gap

    var liveKeys: Set<String> { ["ruler"] }

    /// A problem's numbers, and the squares they make.
    struct Q {
        let w, n, d, W: Int
        init(_ p: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((p[k] ?? Double(v)).rounded()) }
            w = max(1, i("w", 1)); n = i("n", 1); d = max(2, i("d", 2))
            W = UnlikeFractions.wholeLength(d)
        }
        /// One piece's length: the extra bar's, and the wholes' once cut.
        var pw: Int { W / d }
        /// Every piece counted.
        var S: Int { w * d + n }
        /// Bar j's top row: the wholes, then the extra bar (j = w).
        func row(_ j: Int) -> Double { MixedNumbersLesson.top + MixedNumbersLesson.step * Double(j) }
        var extra: Double { row(w) }
        /// The row of the extra bar's old cuts' dots, a square under it.
        var dots: Double { extra + Bars.height + 1 }
        /// Where the ruler starts: the longest piece that isn't the extra bar's, so the hand has something to find.
        var start: Int { Ruler.lengths(W).last { $0 != pw } ?? pw }
    }

    /// The ruler on the cut step: over the first whole, its cuts dashed down every bar; the old cuts are the extra bar's.
    private func theRuler(_ q: Q) -> Ruler {
        Ruler(W: q.W, row: Self.ruler, from: Self.top - 1, to: q.dots,
              old: [Ruler.Old(tag: 1, row: q.dots, at: (1..<q.d).map { Double($0 * q.pw) })], start: q.start)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), W = Double(q.W), pw = Double(q.pw), h = Bars.height
        let cut = s.on("cut"), done = s.on("done")
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // MARK: the wholes: shaded, one piece each until the ruler cuts them, then every piece counted on
        for j in 0..<q.w {
            let y = q.row(j)
            pic.fill("w\(j)f", col: 0, row: y, w: W, h: h, Bars.shade)
            Bars.bar(&pic, "w\(j)", row: y, parts: cut ? q.d : 1, W: q.W)
            if cut { Bars.numbers(&pic, "n\(j)_", j * q.d ..< (j + 1) * q.d, row: y, per: pw) }
        }

        // MARK: the extra bar: n of its d pieces shaded, counted on from the wholes once they're cut
        let y = q.extra
        pic.fill("xf", col: 0, row: y, w: Double(q.n) * pw, h: h, Bars.shade)
        Bars.bar(&pic, "x", row: y, parts: q.d, W: q.W)
        if cut { Bars.numbers(&pic, "nx_", q.w * q.d ..< q.S, row: y, per: pw) }

        // MARK: the names at the bars' right ends: 1 for a whole (d/d once it's cut into d pieces), n/d for the extra bar,
        // the column braced: they're one number
        let nx = W + 2
        for j in 0..<q.w {
            if cut { Bars.fraction(&pic, "f\(j)", q.d, q.d, col: nx, row: q.row(j)) } else { Bars.whole(&pic, "f\(j)", 1, col: nx, row: q.row(j)) }
        }
        Bars.fraction(&pic, "fx", q.n, q.d, col: nx, row: y)
        Bars.brace(&pic, "brace", col: nx + 5, from: Self.top, to: y + h)

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: a hint on the record: the last piece counted, ringed
        if cut && !done && s.on("last") {
            pic.circle("last", at: (Double(q.n - 1) + 0.5) * pw, y + h / 2, radius: min(1.3, pw / 2 - 0.15), .chapter, dashed: true)
        }

        // MARK: the record, as school writes it: w n/d = (w × d + n)/d = [S]/d, the bottom written for the child
        var boxes: [WorkBox] = []
        if cut {
            let maths = Bars.maths
            rec.word("rw", "\(q.w)", at: 1, 2, maths)
            Bars.fraction(&rec, "rf", q.n, q.d, col: 2, row: 0)
            rec.word("re1", "=", at: 7, 2, maths)
            // its top: a digit or a sign to two squares, over the bottom, which stays d
            for (i, ch) in ["\(q.w)", "×", "\(q.d)", "+", "\(q.n)"].enumerated() { rec.word("rt\(i)", ch, at: 9 + 2 * Double(i), 1, maths) }
            rec.rule("rbar", from: 8, to: 18, row: 2)
            rec.word("rb", "\(q.d)", at: 13, 3, maths)
            rec.word("re2", "=", at: 19, 2, maths)
            if done {
                Bars.fraction(&rec, "ra", q.S, q.d, col: 20, row: 0, .chapter)
            } else {
                Bars.fraction(&rec, "ra", nil, q.d, col: 20, row: 0)
                rec.answerBox("n", right: 24, mid: 1, per: 2, cells: 2, centred: true)
            }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    func hands(_ s: PaperState) -> Hands? {
        // the ruler (Cut: how many pieces of its length make a whole, checked against the extra bar's)
        s.on("ruler") ? theRuler(Q(s.numbers)).hands(s) : nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        return s.on("ruler") ? theRuler(q).demo(s, to: q.pw) : []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        // a length that leaves one of the extra bar's cuts with no new cut on it
        let q = Q(s.numbers)
        return s.on("ruler") ? theRuler(q).wrongMove(else: q.start) : nil
    }
}
