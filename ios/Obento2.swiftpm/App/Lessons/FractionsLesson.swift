import SwiftUI

/// Adding fractions, Subtracting fractions, and Adding and subtracting, on the paper, as on the test page G approved
/// (design/grade5.md). Two bars a whole long (36 to 48 squares, the smallest every bottom divides, so each piece is
/// a whole number of squares), 4 squares tall and 2 apart: a/b shaded, c/d striped, their fractions at their right ends
/// with the sign between (the problem, written once). The ruler: its handle above the first bar sets one piece's
/// length, snapping only to lengths that divide the whole; while it's dragged the piece is named, the cuts show dashed
/// across both bars, and under each bar a dot under each old cut, green when a new cut lands on it, red when none does.
/// Cut cuts both bars (it answers the new bottom and both rewrites): the cuts turn solid, the pieces are numbered, the
/// names become A/L and C/L. Then the striped pieces slide into the top bar: after the shaded ones, the count running
/// on (past the end they spill into a second whole bar under it, the second bar making room), or over the shaded ones
/// from the right, crossing them out, the count running down. Then the record a/b ± c/d = A/L ± C/L = [S]/L, typed, and
/// the simplest form when it can be simpler, the answer bars re-cut into the simplest pieces and named by what they hold.
/// The bars, the ruler and the slide are the family's kit (BarsKit.swift).
@MainActor
struct FractionsLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, the first bar, its old cuts' dots, the second bar, its dots.
    static let ruler = 2.0, bar1 = 4.0, barH = Bars.height, dots1 = 9.0, bar2 = 10.0, spillDown = 16.0

    var liveKeys: Set<String> { ["ruler", "dx", "dy"] }

    private static let maths = Bars.maths

    /// A problem's numbers, and the squares they make.
    struct Q {
        let a, b, c, d, L, A, C, S, W: Int
        let minus: Bool
        init(_ n: Numbers) {
            func i(_ k: String, _ d: Int) -> Int { Int((n[k] ?? Double(d)).rounded()) }
            a = i("a", 1); b = max(1, i("b", 2)); c = i("c", 1); d = max(1, i("d", 2)); L = max(1, i("L", 2)); A = i("A", 1); C = i("C", 1); S = i("S", 2)
            minus = n["minus"] == 1
            W = UnlikeFractions.wholeLength(L)
        }
        /// One piece's length once cut, and each bar's own pieces before.
        var pw: Int { W / L }
        var pw1: Int { W / b }
        var pw2: Int { W / d }
        /// More than a whole: the pieces past the top bar's end go into a second whole bar under it.
        var spill: Bool { !minus && S > L }
        var simplest: (whole: Int, num: Int, den: Int) { UnlikeFractions.finalForm(S, L) }
        /// The ruler's lengths (Ruler.lengths: every whole number of squares that divides the whole, 2 to half of it).
        var lengths: [Int] { Ruler.lengths(W) }
        /// Where the striped pieces go in the top bar: after the shaded ones, or over them from the right.
        var target: Int { minus ? A - C : A }
    }

    /// The ruler on the cut step: its handle over the top bar, cutting both bars; the old cuts are each bar's own, their
    /// dots a square under it. It starts at the bigger of the two bars' pieces.
    private func theRuler(_ q: Q) -> Ruler {
        Ruler(W: q.W, row: Self.ruler, from: Self.bar1 - 1, to: Self.bar2 + Self.barH + 1,
              old: [Ruler.Old(tag: 1, row: Self.dots1, at: (1..<max(1, q.b)).map { Double($0 * q.pw1) }),
                    Ruler.Old(tag: 2, row: Self.bar2 + Self.barH + 1, at: (1..<max(1, q.d)).map { Double($0 * q.pw2) })],
              start: q.lengths.contains(max(q.pw1, q.pw2)) ? max(q.pw1, q.pw2) : q.lengths.last ?? q.pw)
    }

    /// The slide: the second bar's striped pieces, from its left end, into the top bar.
    private func slide(_ q: Q) -> PieceSlide { PieceSlide(width: Double(q.C * q.pw), row: Self.bar2, target: Self.bar1, W: Double(q.W)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), W = Double(q.W), pw = Double(q.pw), h = Self.barH, y1 = Self.bar1
        let cut = s.on("cut"), sliding = s.on("slide"), slid = s.on("slid"), sum = s.on("sum"), done = s.picture["answer"] != nil
        let simple = s.on("answer"), held = sliding && s.grabbed, into = sliding && s.h("in") == 1
        // the striped pieces in the top bar: slid there (or let go there, the How to, until it's checked), or over it
        // in the hand
        let placed = slid || (into && !held), preview = into && held
        // the second bar makes room under the top bar for a sum past a whole
        let y2 = q.spill && (slid || into) ? Self.spillDown : Self.bar2
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let numbered = cut && !done

        // MARK: the top bar
        if simple {
            // the answer, re-cut into its simplest pieces: a whole first when it's more than one
            let F = q.simplest
            if q.spill {
                Bars.bar(&pic, "b1", row: y1, parts: 1, W: q.W)
                pic.fill("b1f", col: 0, row: y1, w: W, h: h, Bars.shade)
            } else {
                // as much as the sum is (S of L), cut into the simplest pieces (one piece when it's a whole)
                Bars.bar(&pic, "b1", row: y1, parts: F.num == 0 ? 1 : F.den, W: q.W)
                pic.fill("b1f", col: 0, row: y1, w: W * Double(q.S) / Double(q.L), h: h, Bars.shade)
            }
        } else {
            // taken away, the pieces the striped ones cover are theirs, not shaded too (two fills on one square fight
            // over which shows)
            let parts = cut ? q.L : q.b, per = cut ? pw : Double(q.pw1), shaded = cut ? (placed && q.minus ? q.S : q.A) : q.a
            pic.fill("b1f\(parts)", col: 0, row: y1, w: Double(shaded) * per, h: h, Bars.shade)
            Bars.bar(&pic, "b1", row: y1, parts: parts, W: q.W)
            if placed {
                // the striped pieces in it: after the shaded ones, or over them from the right, crossed out
                Bars.stripes(&pic, "b1s", row: y1, from: q.target, n: q.minus ? q.C : min(q.L, q.S) - q.A, per: pw, crossed: q.minus)
                if numbered { Bars.numbers(&pic, "n1_", 0..<(q.minus ? q.S : min(q.L, q.S)), row: y1, per: pw) }
            } else if preview && q.minus {
                // held over it, taking away: the count runs down to what's left
                Bars.numbers(&pic, "n1_", 0..<q.S, row: y1, per: pw)
            } else if numbered {
                Bars.numbers(&pic, "n1_", 0..<q.A, row: y1, per: pw)
            }
        }

        // MARK: the spill: a second whole bar under the top one, for a sum past a whole
        if q.spill && (slid || into) {
            if simple {
                let F = q.simplest
                Bars.bar(&pic, "b3", row: Self.bar2, parts: F.den, W: q.W)
                pic.fill("b3f", col: 0, row: Self.bar2, w: W * Double(F.num) / Double(F.den), h: h, Bars.shade)
            } else {
                Bars.bar(&pic, "b3", row: Self.bar2, parts: q.L, W: q.W)
                if placed { Bars.stripes(&pic, "b3s", row: Self.bar2, from: 0, n: q.S - q.L, per: pw, crossed: false) }
                if placed && numbered { Bars.numbers(&pic, "n3_", q.L..<q.S, row: Self.bar2, per: pw) }
            }
        }

        // MARK: the second bar: its striped pieces wait to be slid, then it's left empty
        let parts2 = cut ? q.L : q.d, per2 = cut ? pw : Double(q.pw2), striped2 = cut ? q.C : q.c
        if !placed && !held { Bars.stripes(&pic, "b2s\(parts2)", row: y2, from: 0, n: striped2, per: per2, crossed: false) }
        Bars.bar(&pic, "b2", row: y2, parts: parts2, W: q.W)
        if sliding && !held && !placed && numbered { Bars.numbers(&pic, "n2_", 0..<q.C, row: y2, per: pw) }
        if sliding && !held && !placed {
            // which way they go
            pic.word("up", "↑", at: Double(q.C) * pw / 2, y1 + h + 1, Self.maths.colour(.chapter))
        }

        // MARK: the names, at the bars' right ends, the sign between (hidden until a story's sign is picked)
        let nx = W + 2
        if simple {
            // the answer re-cut into its simplest pieces: each bar named by what it holds now (the whole bar 1 and the
            // next 7/12; a re-cut bar 1/2), and the bar the striped pieces left, empty, with no name
            let F = q.simplest
            if q.spill {
                Bars.whole(&pic, "f1", 1, col: nx, row: y1)
                if F.num > 0 { Bars.fraction(&pic, "f3", F.num, F.den, col: nx, row: Self.bar2) }
            } else if F.num == 0 {
                Bars.whole(&pic, "f1", F.whole, col: nx, row: y1)
            } else {
                Bars.fraction(&pic, "f1", F.num, F.den, col: nx, row: y1)
            }
        } else {
            Bars.fraction(&pic, "f1", cut ? q.A : q.a, cut ? q.L : q.b, col: nx, row: y1)
            if !s.picking { pic.word("sign", q.minus ? "−" : "+", at: nx + 2, y2 - 1, Self.maths) }
            Bars.fraction(&pic, "f2", cut ? q.C : q.c, cut ? q.L : q.d, col: nx, row: y2)
        }

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            // the ruler, the cuts it would make across both bars and the old cuts' dots (a hint rings them)
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: hints on the other steps: where the striped pieces go, the last piece counted, the simplest pieces
        if sliding && !placed && !held && s.on("target") {
            // where they go: the pieces they'll fill (or cover), outlined dashed just inside the bar's own lines
            let n = q.minus ? q.C : min(q.L, q.S) - q.A
            pic.sketch.box("target", pic.R(Double(q.target) * pw + 0.5, y1 + 0.5, Double(n) * pw - 1, h - 1), .chapter, width: Sketch.stroke, dashed: true)
        }
        if slid && !sum && s.on("last") {
            // the last piece counted: in the second whole bar when the sum spills into it
            let i = q.S - 1, inSpill = q.spill && i >= q.L, col = Double(inSpill ? i - q.L : i)
            pic.circle("last", at: (col + 0.5) * pw, (inSpill ? Self.bar2 : y1) + h / 2, radius: min(1.3, pw / 2 - 0.15), .chapter, dashed: true)
        }
        if sum && !done && s.on("simple") {
            let F = q.simplest
            if q.spill {
                // every L pieces make one whole: the top bar, all of it
                pic.sketch.box("whole", pic.R(0, y1 - 1, W, h + 2), .chapter, width: Sketch.stroke, dashed: true)
            } else if F.den < q.L {
                // the bigger pieces the answer is made of, marked over the top bar: a line along it, a tick down at each
                // of their cuts (3 sixths make a half)
                let top = y1 - 1
                pic.line("simpleTop", [(0, y1), (0, top), (W, top), (W, y1)], .chapter)
                for k in 1..<F.den { let x = W * Double(k) / Double(F.den); pic.line("simple\(k)", [(x, top), (x, y1)], .chapter) }
            }
        }

        // MARK: the striped pieces in the hand: following the finger, or snapped into the top bar
        if held {
            if into {
                // snapped into the top bar: the count runs on (adding) or the pieces under them are crossed out
                let n = q.minus ? q.C : min(q.L, q.S) - q.A
                Bars.stripes(&live, "into", row: y1, from: q.target, n: n, per: pw, crossed: q.minus)
                if !q.minus { Bars.numbers(&live, "lc", q.A..<min(q.L, q.S), row: y1, from: q.A, per: pw) }
                if q.spill {
                    Bars.stripes(&live, "spill", row: Self.bar2, from: 0, n: q.S - q.L, per: pw, crossed: false)
                    Bars.numbers(&live, "ls", q.L..<q.S, row: Self.bar2, per: pw)
                }
            } else {
                // following the finger
                slide(q).drawHeld(s, &live, per: pw, pieces: q.C)
            }
        }

        // MARK: the record: a/b ± c/d = A/L ± C/L = [S]/L (= the simplest form), from the slide on
        var boxes: [WorkBox] = []
        if slid {
            let sign = q.minus ? "−" : "+"
            Bars.fraction(&rec, "w1", q.a, q.b, col: 0, row: 0)
            rec.word("ws1", sign, at: 5, 2, Self.maths)
            Bars.fraction(&rec, "w2", q.c, q.d, col: 6, row: 0)
            rec.word("we1", "=", at: 11, 2, Self.maths)
            Bars.fraction(&rec, "w3", q.A, q.L, col: 12, row: 0)
            rec.word("ws2", sign, at: 17, 2, Self.maths)
            Bars.fraction(&rec, "w4", q.C, q.L, col: 18, row: 0)
            rec.word("we2", "=", at: 23, 2, Self.maths)
            if sum {
                Bars.fraction(&rec, "w5", q.S, q.L, col: 24, row: 0, .chapter)
            } else {
                Bars.fraction(&rec, "w5", nil, q.L, col: 24, row: 0)
                rec.answerBox("n", right: 28, mid: 1, per: 2, cells: 2, centred: true)
            }
            if sum && (simple || !done) && !(q.simplest.whole == 0 && q.simplest.den == q.L) {
                // the simplest form: a whole number and a fraction as it needs them, typed, then written
                let F = q.simplest
                rec.word("we3", "=", at: 29, 2, Self.maths.colour(done ? .chapter : .ink))
                var x = 30.0
                if F.whole > 0 {
                    if done { rec.word("ww", "\(F.whole)", at: x + 1, 2, Self.maths.colour(.chapter)) }
                    else { rec.answerBox("w", right: x + 2, mid: 2, per: 2, cells: 1, centred: true) }
                    // written, a mixed number's fraction sits right by its whole (1 7/12); typed, a square apart, so
                    // the boxes don't touch
                    x += done ? 2 : 3
                }
                if F.num > 0 {
                    Bars.fraction(&rec, "w6", done ? F.num : nil, done ? F.den : nil, col: x, row: 0, done ? .chapter : .ink)
                    if !done {
                        rec.answerBox("n", right: x + 4, mid: 1, per: 2, cells: 2, centred: true)
                        rec.answerBox("d", right: x + 4, mid: 3, per: 2, cells: 2, centred: true)
                    }
                }
            }
            boxes = rec.boxes
        }
        // the room the slide will need: the second bar moved down for a sum past a whole
        let extent: CGRect? = sliding && q.spill ? pic.R(0, 0, W + 6, Self.spillDown + h + 1) : nil
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers)
        // the ruler (Cut: how many pieces of its length make a whole, checked: that's the new bottom); the slide (let go
        // over the top bar, they're in)
        if s.on("ruler") { return theRuler(q).hands(s) }
        if s.on("slide") { return slide(q).hands() }
        return nil
    }

    /// The cut answered both rewrites: their tops are the shaded pieces counted.
    func autoAnswer(_ s: PaperState) -> [String: Double]? {
        guard s.byHand, s.on("cut"), !s.on("slide"), let a = s.step.answer, a.boxes == ["x"], let v = a.expected["x"] else { return nil }
        return ["x": v]
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers), pw = Double(q.pw)
        if s.on("ruler") { return theRuler(q).demo(s, to: q.pw) }
        if s.on("slide") { return slide(q).demo(to: min(Double(q.W) - 2, Double(q.target) * pw + Double(q.C) * pw / 2)) }
        return []
    }

    func messageRows(_ n: Numbers) -> Int {
        let q = Q(n), F = q.simplest
        // the simplest form's slips run long ("That's not equal to 19/12. How many whole 12s fit into 19? …")
        return F.whole == 0 && F.den == q.L ? 1 : 2
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        // a length that leaves old cuts with no new cut on them; pieces dropped off the top bar
        if s.on("ruler") { return theRuler(q).wrongMove(else: q.pw1) }
        if s.on("slide") { return slide(q).wrongMove }
        return nil
    }
}
