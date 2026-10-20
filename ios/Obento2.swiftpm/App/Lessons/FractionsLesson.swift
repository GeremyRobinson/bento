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
/// the simplest form when it can be simpler, the answer bars re-cut into the simplest pieces.
@MainActor
struct FractionsLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, the first bar, its old cuts' dots, the second bar, its dots.
    static let ruler = 2.0, bar1 = 4.0, barH = 4.0, dots1 = 9.0, bar2 = 10.0, spillDown = 16.0

    var liveKeys: Set<String> { ["ruler", "dx", "dy"] }

    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let count = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let green = Sketch.Colour.hex(0x178A57, 0x3CCF8E), red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)

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
        /// The ruler's lengths: every whole number of squares that divides the whole (2 squares at least, so a piece
        /// holds its number), up to half the whole.
        var lengths: [Int] { (2...max(2, W / 2)).filter { W % $0 == 0 } }
        /// Where the striped pieces go in the top bar: after the shaded ones, or over them from the right.
        var target: Int { minus ? A - C : A }
    }

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
                bar(&pic, "b1", row: y1, parts: 1, W: q.W)
                pic.fill("b1f", col: 0, row: y1, w: W, h: h, .tint(0.4))
            } else {
                // as much as the sum is (S of L), cut into the simplest pieces (one piece when it's a whole)
                bar(&pic, "b1", row: y1, parts: F.num == 0 ? 1 : F.den, W: q.W)
                pic.fill("b1f", col: 0, row: y1, w: W * Double(q.S) / Double(q.L), h: h, .tint(0.4))
            }
        } else {
            let parts = cut ? q.L : q.b, per = cut ? pw : Double(q.pw1), shaded = cut ? q.A : q.a
            pic.fill("b1f\(parts)", col: 0, row: y1, w: Double(shaded) * per, h: h, .tint(0.4))
            bar(&pic, "b1", row: y1, parts: parts, W: q.W)
            if placed {
                // the striped pieces in it: after the shaded ones, or over them from the right, crossed out
                stripes(&pic, "b1s", row: y1, from: q.target, n: q.minus ? q.C : min(q.L, q.S) - q.A, per: pw, crossed: q.minus)
                if numbered {
                    let upTo = q.minus ? q.S : min(q.L, q.S)
                    for i in 0..<upTo { pic.word("n1_\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y1 + h / 2, Self.count) }
                }
            } else if preview && q.minus {
                // held over it, taking away: the count runs down to what's left
                for i in 0..<q.S { pic.word("n1_\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y1 + h / 2, Self.count) }
            } else if numbered {
                for i in 0..<q.A { pic.word("n1_\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y1 + h / 2, Self.count) }
            }
        }

        // MARK: the spill: a second whole bar under the top one, for a sum past a whole
        if q.spill && (slid || into) {
            if simple {
                let F = q.simplest
                bar(&pic, "b3", row: Self.bar2, parts: F.den, W: q.W)
                pic.fill("b3f", col: 0, row: Self.bar2, w: W * Double(F.num) / Double(F.den), h: h, .tint(0.4))
            } else {
                bar(&pic, "b3", row: Self.bar2, parts: q.L, W: q.W)
                if placed { stripes(&pic, "b3s", row: Self.bar2, from: 0, n: q.S - q.L, per: pw, crossed: false) }
                if placed && numbered {
                    for i in q.L..<q.S { pic.word("n3_\(i)", "\(i + 1)", at: (Double(i - q.L) + 0.5) * pw, Self.bar2 + h / 2, Self.count) }
                }
            }
        }

        // MARK: the second bar: its striped pieces wait to be slid, then it's left empty
        let parts2 = cut ? q.L : q.d, per2 = cut ? pw : Double(q.pw2), striped2 = cut ? q.C : q.c
        if !placed && !held { stripes(&pic, "b2s\(parts2)", row: y2, from: 0, n: striped2, per: per2, crossed: false) }
        bar(&pic, "b2", row: y2, parts: parts2, W: q.W)
        if sliding && !held && !placed && numbered {
            for i in 0..<q.C { pic.word("n2_\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y2 + h / 2, Self.count) }
        }
        if sliding && !held && !placed {
            // which way they go
            pic.word("up", "↑", at: Double(q.C) * pw / 2, y1 + h + 1, Self.maths.colour(.chapter))
        }

        // MARK: the names, at the bars' right ends, the sign between (hidden until a story's sign is picked)
        let nx = W + 2
        fraction(&pic, "f1", cut ? q.A : q.a, cut ? q.L : q.b, col: nx, row: y1)
        if !s.picking { pic.word("sign", q.minus ? "−" : "+", at: nx + 2, y2 - 1, Self.maths) }
        fraction(&pic, "f2", cut ? q.C : q.c, cut ? q.L : q.d, col: nx, row: y2)

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            actions = ["Cut"]
            let w = Double(ruler(s, q)), R = Self.ruler
            live.line("ruler", [(0, R + 1), (0, R), (w, R), (w, R + 1)], .chapter)
            live.dot("handle", at: w, R, radius: s.grabbed ? 0.75 : 0.6, .chapter, over: true)
            // the piece's name over the ruler, centred on it, but never past the bars' left end (a short ruler's long
            // name, "twenty-fourths", starts where the bars do)
            let name = UnlikeFractions.pieceName(q.W / Int(w))
            let half = PaperText.width(name, PaperText.font(Self.small.size, Self.small.weight, digits: true)) / 2 / Paper.cell
            // (its ink half a square over the handle, which a short ruler's name would otherwise touch)
            live.label("rulerw", name, Self.small, .above, edge: R - 0.75, along: max(w / 2, half))
            // the cuts it would make, dashed across both bars
            for k in 1..<max(1, Int((W / w).rounded())) {
                let x = Double(k) * w
                live.line("cut\(k)", [(x, y1 - 1), (x, y2 + h + 1)], .ink2, dashed: true)
            }
            // a dot under each old cut: green when a new cut lands on it, red when none does
            for i in 1..<q.b { let ox = Double(i * q.pw1); live.dot("d1_\(i)", at: ox, Self.dots1, radius: 0.35, ox.truncatingRemainder(dividingBy: w) == 0 ? Self.green : Self.red, over: true) }
            for i in 1..<q.d { let ox = Double(i * q.pw2); live.dot("d2_\(i)", at: ox, y2 + h + 1, radius: 0.35, ox.truncatingRemainder(dividingBy: w) == 0 ? Self.green : Self.red, over: true) }
            // a hint: every old cut's dot ringed (each needs a new cut on it)
            if s.on("oldCuts") {
                for i in 1..<q.b { pic.circle("r1_\(i)", at: Double(i * q.pw1), Self.dots1, radius: 0.9, .chapter, dashed: true) }
                for i in 1..<q.d { pic.circle("r2_\(i)", at: Double(i * q.pw2), y2 + h + 1, radius: 0.9, .chapter, dashed: true) }
            }
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
                stripes(&live, "into", row: y1, from: q.target, n: n, per: pw, crossed: q.minus)
                if !q.minus {
                    for i in q.A..<min(q.L, q.S) { live.word("lc\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y1 + h / 2, Self.count) }
                }
                if q.spill {
                    stripes(&live, "spill", row: Self.bar2, from: 0, n: q.S - q.L, per: pw, crossed: false)
                    for i in q.L..<q.S { live.word("ls\(i)", "\(i + 1)", at: (Double(i - q.L) + 0.5) * pw, Self.bar2 + h / 2, Self.count) }
                }
            } else {
                let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0, gw = Double(q.C) * pw
                live.stripes("group", col: dx, row: Self.bar2 + dy, w: gw, h: h)
                for i in 1..<max(1, q.C) { live.line("gc\(i)", [(dx + Double(i) * pw, Self.bar2 + dy), (dx + Double(i) * pw, Self.bar2 + dy + h)], .chapter) }
                live.sketch.box("go", live.R(dx, Self.bar2 + dy, gw, h), .chapter, width: Sketch.stroke)
            }
        }

        // MARK: the record: a/b ± c/d = A/L ± C/L = [S]/L (= the simplest form), from the slide on
        var boxes: [WorkBox] = []
        if slid {
            let sign = q.minus ? "−" : "+"
            fraction(&rec, "w1", q.a, q.b, col: 0, row: 0)
            rec.word("ws1", sign, at: 5, 2, Self.maths)
            fraction(&rec, "w2", q.c, q.d, col: 6, row: 0)
            rec.word("we1", "=", at: 11, 2, Self.maths)
            fraction(&rec, "w3", q.A, q.L, col: 12, row: 0)
            rec.word("ws2", sign, at: 17, 2, Self.maths)
            fraction(&rec, "w4", q.C, q.L, col: 18, row: 0)
            rec.word("we2", "=", at: 23, 2, Self.maths)
            if sum {
                fraction(&rec, "w5", q.S, q.L, col: 24, row: 0, .chapter)
            } else {
                fraction(&rec, "w5", nil, q.L, col: 24, row: 0)
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
                    fraction(&rec, "w6", done ? F.num : nil, done ? F.den : nil, col: x, row: 0, done ? .chapter : .ink)
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

    /// A bar a whole long: its outline and its cuts in the chapter's colour.
    private func bar(_ pen: inout GridPen, _ id: String, row: Double, parts: Int, W: Int) {
        let per = Double(W) / Double(max(1, parts))
        pen.sketch.box("\(id)o", pen.R(0, row, Double(W), Self.barH), .chapter, width: Sketch.stroke)
        if parts > 1 {
            pen.sketch.segments("\(id)c\(parts)", (1..<parts).map { i in (pen.P(Double(i) * per, row), pen.P(Double(i) * per, row + Self.barH)) }, .chapter, width: Sketch.stroke)
        }
    }

    /// `n` pieces striped from piece `from`, crossed out when they take away the shaded pieces under them.
    private func stripes(_ pen: inout GridPen, _ id: String, row: Double, from: Int, n: Int, per: Double, crossed: Bool) {
        guard n > 0 else { return }
        pen.stripes(id, col: Double(from) * per, row: row, w: Double(n) * per, h: Self.barH)
        // the pieces' own cuts over the stripes
        for i in 1..<max(1, n) { pen.line("\(id)c\(i)", [(Double(from + i) * per, row), (Double(from + i) * per, row + Self.barH)], .chapter) }
        if crossed {
            for i in 0..<n {
                let x0 = Double(from + i) * per
                pen.line("\(id)x\(i)a", [(x0 + 0.5, row + 0.5), (x0 + per - 0.5, row + Self.barH - 0.5)], .ink2)
                pen.line("\(id)x\(i)b", [(x0 + per - 0.5, row + 0.5), (x0 + 0.5, row + Self.barH - 0.5)], .ink2)
            }
        }
    }

    /// A fraction in a column 4 squares wide: its top centred down row r + 1, its bar on r + 2, its bottom down r + 3
    /// (nil leaves a part empty, for a box).
    private func fraction(_ pen: inout GridPen, _ id: String, _ top: Int?, _ bottom: Int?, col: Double, row r: Double, _ colour: Sketch.Colour = .ink) {
        if let top { pen.word(id + "t", "\(top)", at: col + 2, r + 1, Self.maths.colour(colour)) }
        pen.rule(id + "bar", from: col, to: col + 4, row: r + 2, colour)
        if let bottom { pen.word(id + "b", "\(bottom)", at: col + 2, r + 3, Self.maths.colour(colour)) }
    }

    /// The ruler's length now: where the hand left it, or the bigger of the two bars' pieces to start.
    private func ruler(_ s: PaperState, _ q: Q) -> Int {
        if let r = s.h("ruler") { return Int(r.rounded()) }
        return q.lengths.contains(max(q.pw1, q.pw2)) ? max(q.pw1, q.pw2) : q.lengths.last ?? q.pw
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers), W = Double(q.W), pw = Double(q.pw)
        if s.on("ruler") {
            let w = Double(ruler(s, q))
            return Hands(
                // the handle (or the ruler's end), a finger's width around it
                grab: { p in abs(p.x - w) < 2.5 && p.y > Self.ruler - 2.5 && p.y < Self.bar1 + 1 ? ["grab": 1, "ruler": w] : nil },
                drag: { p, _ in
                    let best = q.lengths.min { abs(Double($0) - p.x) < abs(Double($1) - p.x) } ?? q.pw
                    return ["grab": 1, "ruler": Double(best)]
                },
                release: { h in HandMove(hand: ["ruler": h["ruler"] ?? w], missHand: nil) },
                // Cut: how many pieces of that length make a whole, checked (that's the new bottom)
                actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", W / w)], check: true) }])
        }
        if s.on("slide") {
            let gw = Double(q.C) * pw
            return Hands(
                grab: { p in p.x > -0.5 && p.x < gw + 0.5 && p.y > Self.bar2 - 0.5 && p.y < Self.bar2 + Self.barH + 0.5 ? ["grab": 1, "fx": p.x, "fy": p.y, "dx": 0, "dy": 0] : nil },
                drag: { p, h in
                    let fx = h["fx"] ?? 0, fy = h["fy"] ?? 0
                    let dx = (p.x - fx).rounded(), dy = (p.y - fy).rounded()
                    // over the top bar: it snaps in
                    let top = Self.bar2 + dy, into = abs(top - Self.bar1) <= 3 && dx + gw > 0 && dx < W
                    return ["grab": 1, "fx": fx, "fy": fy, "dx": dx, "dy": dy, "in": into ? 1 : 0]
                },
                release: { h in
                    h["in"] == 1 ? HandMove(hand: ["in": 1], missHand: [:], set: [("s", 1)], check: true)
                                 : HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true)
                })
        }
        return nil
    }

    /// The cut answered both rewrites: their tops are the shaded pieces counted.
    func autoAnswer(_ s: PaperState) -> [String: Double]? {
        guard s.byHand, s.on("cut"), !s.on("slide"), let a = s.step.answer, a.boxes == ["x"], let v = a.expected["x"] else { return nil }
        return ["x": v]
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers), pw = Double(q.pw)
        if s.on("ruler") {
            let w = Double(ruler(s, q))
            return (w == pw ? [] : [.drag(from: CGPoint(x: w, y: Self.ruler), to: CGPoint(x: pw, y: Self.ruler))]) + [.tap(.action("Cut"))]
        }
        if s.on("slide") {
            let gw = Double(q.C) * pw, from = CGPoint(x: gw / 2, y: Self.bar2 + Self.barH / 2)
            let to = CGPoint(x: min(Double(q.W) - 2, Double(q.target) * pw + gw / 2), y: Self.bar1 + Self.barH / 2)
            return [.drag(from: from, to: to)]
        }
        return []
    }

    func messageRows(_ n: Numbers) -> Int {
        let q = Q(n), F = q.simplest
        // the simplest form's slips run long ("That's not equal to 19/12. How many whole 12s fit into 19? …")
        return F.whole == 0 && F.den == q.L ? 1 : 2
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        if s.on("ruler") {
            // a length that leaves old cuts with no new cut on them
            let w = q.lengths.first { (q.W / $0) % q.b != 0 || (q.W / $0) % q.d != 0 } ?? q.pw1
            return HandMove(hand: ["ruler": Double(w)], missHand: nil, set: [("x", Double(q.W / w))], check: true)
        }
        if s.on("slide") { return HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true) }
        return nil
    }
}
