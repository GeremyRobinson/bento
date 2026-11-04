import SwiftUI

/// Long division and Dividing decimals on the paper, as in the preview (design/prototype/grade6-ch3.html, dDiv): one
/// square is one of the place being shared now (its name over the picture); a 2 × 2 cell while the divisor is 19 or
/// less. The amount being shared is squares in rows as long as the divisor, filled from the top: what's left from the
/// last place plain, the digit that came down striped. Drag the bottom edge down a row at a time (the rows above it
/// fill; "3 rows · 69"); let go to set the quotient digit; write what's left. The bracket on the right is the record,
/// the school's column working (a digit to two squares): each place's take-away and what's left, the next digit
/// brought down beside it. Dividing decimals first moves both numbers' digits left on a place chart until the divisor
/// is whole, and breaks what's left after the last digit into tenths (a 0 written after the point).
///
/// The record shares the picture's squares (recordRow 0), so a tap on the bracket's digits lands in the picture's
/// squares. Hand keys: "tj" (digits tapped, a wrong start), "k" (rows dragged), "sk" (places the digits moved).
@MainActor
struct LongDiv6Lesson: PaperLesson {
    /// Dividing decimals (the shift, the breaks, the point).
    let dec: Bool
    static let PT = 3.0
    var liveKeys: Set<String> { ["k", "sk", "y0", "k0", "x0"] }

    private static let red = Bars.red
    private static let lit = R6.lit, small = R6.small, maths = Record.maths

    @MainActor struct Shape {
        let plan: LongDiv6.Plan, d: Int, c: Double, W: Double
        /// The shift: how far both numbers move (0: none), the numbers as given.
        let s: Int, n: Dec6?, V: Dec6?, kmax: Int
        init(_ x: Numbers, dec: Bool) {
            if dec {
                let p = DivideDec6.Parts(x)
                plan = p.plan; s = p.s; n = p.n; V = p.V; kmax = p.kmax
            } else {
                plan = LongDivision6.Parts(x).plan; s = 0; n = nil; V = nil; kmax = 0
            }
            d = plan.d; c = d <= 19 ? 2 : 1; W = Double(d) * c
        }
        var dvs: String { "\(d)" }
        /// The bracket's left (a block line clear of the rows' readout), the divisor's right, the number's first column.
        var bx: Double { ((W + 10) / 5).rounded(.up) * 5 }
        var dvR: Double { bx + 2 * Double(dvs.count) }
        var nx: Double { dvR + 1 }
        static let Qy = PT + 1, numY = PT + 3
        func rowP(_ t: Int) -> Double { Shape.numY + 2 + 4 * Double(t) }
        func digitX(_ j: Int) -> Double { nx + 2 * Double(j) + 1 }
        /// The place chart of the shift: its columns from the hundreds, the point's line, the rows of the two numbers.
        func colX(_ e: Int) -> Double { 5 + Double(2 - e) * 5 }
        static let tilesN = 3.0, tilesV = 8.0
    }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func place(_ s: PaperState) -> Int { Int((s.picture["t"] ?? 0).rounded()) }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 1 }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers, dec: dec), at = stage(s)
        if at == 3 { return CGPoint(x: S.bx, y: S.rowP(place(s)) + 4) }
        if at == 4 { return CGPoint(x: S.bx, y: S.rowP(S.plan.places.count - 1) + 4) }
        return nil
    }

    // MARK: drawing

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers, dec: dec), plan = S.plan, at = stage(s), t = place(s), d = S.d, c = S.c, PT = Self.PT
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let done = at == 4, places = plan.places
        let rowsEnd = PT + Double(plan.mostRows + 1) * c
        var extent = pic.R(0, 0, S.W + 9, rowsEnd + 0.5)

        if at == 5 {
            drawShift(s, S, &pic, &live)
            extent = extent.union(pic.R(0, 0, S.colX(-3) + 5, 15))
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
        }

        // the picture: the amount being shared, in rows of d
        func name(_ e: Int) { pic.word("pn\(e)", Place6.name(e), at: 0, PT - 1.5, Self.small, anchor: UnitPoint(x: 0, y: 0.5)) }
        if at <= 1 {
            // a start tapped too soon: the amount those digits make, too short for a row
            if let n = s.h("tj").map({ Int($0.rounded()) }), n > 0, n <= plan.j0 {
                name(plan.intLen - n)
                let v = plan.prefix(n)
                if v > 0 { amount(&pic, "st\(n)", A: v, carry: 0, striped: false, taken: 0, S) }
            }
        } else if at == 2 || at == 3 {
            let P = places[t]
            name(P.e)
            let k = at == 3 ? P.qd : Int((s.h("k") ?? 0).rounded())
            amount(&pic, "a\(t)", A: P.A, carry: P.carry, striped: t > 0 && !P.app, taken: at == 3 ? P.qd : 0, S)
            if at == 3 { edge(&pic, "e", k: k, A: P.A, S, handle: false) }
            else {
                live.fill("tk", col: 0, row: PT, w: S.W, h: Double(min(k, P.A / d)) * c, .tint(0.3))
                edge(&live, "e", k: k, A: P.A, S, handle: true, held: s.grabbed)
                if s.grabbed { live.reads("\(Place6.rows(k)) · \(k * d)") }
            }
            // a hint: the amount ringed; a second miss, the edge where the rows end
            if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: 0, y: PT, w: S.W, h: Double((P.A + d - 1) / d) * c) }
            if at == 2 && s.on("spot") { pic.line("spot", [(-1, PT + Double(P.qd) * c), (S.W + 1, PT + Double(P.qd) * c)], .chapter, dashed: true) }
            if at == 3 && (s.on("ring") || s.on("spot")) {
                // what's left: the short row ringed, and then each square in it outlined
                let full = P.A / d
                if P.left > 0 { R6.ring(&pic, "ringl", x: 0, y: PT + Double(full) * c, w: Double(P.A % d) * c, h: c) }
                if s.on("spot") { for i in 0..<P.left { pic.sketch.box("ls\(i)", pic.R(Double(i) * c, PT + Double(full) * c, c, c), .chapter, width: Sketch.stroke) } }
            }
        } else if at == 6 {
            let Pp = places[t - 1]
            name(Pp.e)
            amount(&pic, "a\(t - 1)", A: Pp.A, carry: Pp.carry, striped: t > 1 && !Pp.app, taken: Pp.qd, S)
            // the squares left, outlined: they're what the finger taps
            for i in 0..<Pp.left { pic.sketch.box("bl\(i)", pic.R(Double(i) * c, PT + Double(Pp.qd) * c, c, c), .chapter, width: Sketch.stroke) }
            if s.on("ring") { R6.ring(&pic, "ring", x: 0, y: PT + Double(Pp.qd) * c, w: Double(Pp.left) * c, h: c) }
        } else if done, let Pl = places.last {
            name(Pl.e)
            amount(&pic, "a\(places.count - 1)", A: Pl.A, carry: Pl.carry, striped: places.count > 1 && !Pl.app, taken: Pl.qd, S)
        }

        // the record: the shift said small over it; the divisor, the bracket, the number (its 0s after the point as they're
        // broken into), the quotient over it, the working under it
        let shownApp = places.enumerated().filter { u, p in p.app && (u < t || (u == t && at != 6) || done) && at >= 2 }.count
        let curLen = plan.L0 + shownApp, pointShown = plan.N.p > 0 || shownApp > 0
        if S.s > 0, let n = S.n, let V = S.V {
            rec.word("shl", "\(n.s) ÷ \(V.s), both × \(Dec6.pow10(S.s))", at: S.bx, PT - 1.5, Self.small, anchor: UnitPoint(x: 0, y: 0.5))
        }
        let numY = Shape.numY, Qy = Shape.Qy
        rec.digits("dv", "\(d)", right: S.dvR, row: numY, per: 2)
        let end = S.nx + 2 * Double(curLen) + 0.5
        rec.line("brk\(curLen)", [(S.dvR + 0.1, numY + 1), (S.dvR + 0.45, numY + 0.3), (S.dvR + 0.55, numY - 0.4), (S.dvR + 0.45, numY - 1), (end, numY - 1)])
        let litStart = (at == 2 || at == 3) && t == 0
        for j in 0..<curLen {
            let lit = litStart && j <= plan.j0
            rec.word("nd\(j)\(lit)", "\(plan.digs[j])", at: S.digitX(j), numY, Self.maths.colour(lit ? .chapter : .ink))
        }
        if pointShown { rec.digits("npt", ".", right: S.nx + 2 * Double(plan.intLen), row: numY, per: 2) }
        // a hint on the start: the number ringed; a second miss, the digits it starts with
        if at == 1 && s.on("ring") { R6.ring(&rec, "rs", x: S.nx, y: numY - 1, w: 2 * Double(plan.L0), h: 2) }
        if at == 1 && s.on("spot") { rec.sketch.box("ss", rec.R(S.nx + 0.25, numY - 1.25, 2 * Double(plan.j0 + 1) - 0.5, 2.5), .chapter, width: Sketch.stroke) }

        // the quotient: each place's digit once its rows are dragged; the point over the point (and the 0s before the
        // first digit) once the sharing is past the ones
        func shown(_ u: Int) -> Bool { done || u < t || (u == t && at == 3) }
        guard at >= 2 else {
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
        }
        for (u, p) in places.enumerated() where shown(u) {
            rec.word("q\(u)", "\(p.qd)", at: S.digitX(p.j), Qy, Self.maths.colour(.chapter))
        }
        let curE = done ? (places.last?.e ?? 0) : places[t].e
        if dec && curE < 0 {
            rec.digits("qpt", ".", right: S.nx + 2 * Double(plan.intLen), row: Qy, per: 2, .chapter)
            if plan.intLen - 1 < plan.j0 { for j in (plan.intLen - 1)..<plan.j0 { rec.word("qz\(j)", "0", at: S.digitX(j), Qy, Self.maths.colour(.chapter)) } }
        }
        if done && plan.r > 0 {
            let x = S.nx + 2 * Double(plan.digs.count)
            rec.word("qr", "r", at: x + 1, Qy, Self.maths.colour(.chapter))
            rec.digits("qrv", "\(plan.r)", right: x + 2 + 2 * Double("\(plan.r)".count), row: Qy, per: 2, .chapter)
        }
        // the working: what the rows took (− 69), its line, what's left with the next digit brought down beside it
        for (u, p) in places.enumerated() where done || u < t || (u == t && at == 3) {
            let y = S.rowP(u), R = S.nx + 2 * Double(p.j) + 2, np = Double("\(p.prod)".count)
            rec.digits("wp\(u)", "\(p.prod)", right: R, row: y, per: 2)
            rec.word("wm\(u)", "−", at: R - 2 * np - 1, y, Self.maths)
            rec.rule("wl\(u)", from: R - 2 * max(Double("\(p.A)".count), np) - 2, to: R, row: y + 1)
            if u == t && at == 3 {
                rec.answerBox("l", right: R, mid: y + 2, per: 2, cells: "\(p.A)".count)
                continue
            }
            rec.digits("wf\(u)", "\(p.left)", right: R, row: y + 2, per: 2)
            if u + 1 < places.count, done || t > u + 1 || (t == u + 1 && at != 6) {
                let nxt = places[u + 1], x = S.digitX(nxt.j)
                rec.word("wd\(u)", "\(plan.digs[nxt.j])", at: x, y + 2, Self.maths)
                rec.line("wa\(u)", [(x, numY + 1.1), (x, y + 0.9)], .ink3, dashed: true)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    /// An amount A in rows of d from the picture's top row: the part left from the last place plain, the digit that
    /// came down striped; the rows taken darker; the cells' faint lines and the amount's outline.
    private func amount(_ pen: inout GridPen, _ id: String, A: Int, carry: Int, striped: Bool, taken: Int, _ S: Shape) {
        let d = S.d, c = S.c, W = S.W, PT = Self.PT, full = A / d, short = A % d, rowsN = full + (short > 0 ? 1 : 0)
        func runs(_ from: Int, _ n: Int, _ body: (Double, Double, Double) -> Void) {
            var i = from
            while i < from + n { let row = i / d, col = i % d, run = min(d - col, from + n - i); body(Double(col) * c, PT + Double(row) * c, Double(run) * c); i += run }
        }
        let plain = striped ? carry : A
        runs(0, plain) { x, y, w in pen.fill("\(id)c\(y)_\(x)", col: x, row: y, w: w, h: c, .tint(0.22)) }
        if striped && A > carry { runs(carry, A - carry) { x, y, w in pen.stripes("\(id)n\(y)_\(x)", col: x, row: y, w: w, h: c) } }
        if taken > 0 { pen.fill("\(id)tk", col: 0, row: PT, w: W, h: Double(min(taken, full)) * c, .tint(0.3)) }
        var segs: [(CGPoint, CGPoint)] = []
        for x in 1..<max(2, d) where x < d {
            let h = Double(x < short ? full + 1 : full) * c
            if h > 0 { segs.append((pen.P(Double(x) * c, PT), pen.P(Double(x) * c, PT + h))) }
        }
        if rowsN > 1 { for y in 1..<rowsN { segs.append((pen.P(0, PT + Double(y) * c), pen.P(y < full ? W : Double(short) * c, PT + Double(y) * c))) } }
        if !segs.isEmpty { pen.sketch.segments("\(id)cl", segs, .tint(0.42), width: 1) }
        let o: [(Double, Double)] = full == 0 ? [(0, PT), (Double(short) * c, PT), (Double(short) * c, PT + c), (0, PT + c), (0, PT)]
            : short > 0 ? [(0, PT), (W, PT), (W, PT + Double(full) * c), (Double(short) * c, PT + Double(full) * c), (Double(short) * c, PT + Double(full + 1) * c), (0, PT + Double(full + 1) * c), (0, PT)]
            : [(0, PT), (W, PT), (W, PT + Double(full) * c), (0, PT + Double(full) * c), (0, PT)]
        if A > 0 { pen.line("\(id)ol", o, .chapter) }
    }

    /// The bottom edge at k rows: rows past the amount dashed red (the squares that aren't there), the edge, its handle
    /// while it's dragged, and what the rows take.
    private func edge(_ pen: inout GridPen, _ id: String, k: Int, A: Int, _ S: Shape, handle: Bool, held: Bool = false) {
        let d = S.d, c = S.c, PT = Self.PT, full = A / d, short = A % d, y = PT + Double(k) * c
        if k > full {
            for rr in full..<k {
                let from = rr == full ? short : 0
                pen.sketch.box("\(id)ov\(rr)_\(from)", pen.R(Double(from) * c, PT + Double(rr) * c, Double(d - from) * c, c), Self.red, width: Sketch.stroke, dashed: true)
            }
        }
        pen.line("\(id)l", [(0, y), (S.W + 1, y)], .chapter)
        if handle { R6.handle(&pen, "\(id)h", S.W + 1, y, held: held) }
        if k > 0 || held { pen.word("\(id)ro", "\(Place6.rows(k)) · \(k * d)", at: S.W + 2.2, y, Self.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
    }

    /// Dividing by a decimal: the chart, both numbers' digits moving left together past the fixed point.
    private func drawShift(_ s: PaperState, _ S: Shape, _ pic: inout GridPen, _ live: inout GridPen) {
        guard let n = S.n, let V = S.V else { return }
        DecMultLesson.names(&pic, [2, 1, 0, -1, -2, -3], S.colX, y: 1.2)
        for e in [1, 0, -2, -3] { pic.line("cl\(e)", [(S.colX(e), 1.9), (S.colX(e), 13)], .ink3) }
        pic.line("cpt", [(S.colX(0) + 5, 1.9), (S.colX(0) + 5, 13)], .ink2)
        let k = Int((s.h("sk") ?? 0).rounded()), held = s.grabbed
        var pen = held ? live : pic
        tiles(&pen, "tn", n.times10(k).s, y: Shape.tilesN, S)
        tiles(&pen, "tv", V.times10(k).s, y: Shape.tilesV, S)
        if held { live = pen } else { pic = pen }
        pic.dot("pn", at: S.colX(0) + 5, Shape.tilesN + 3.3, radius: 0.25, .ink, over: true)
        pic.dot("pv", at: S.colX(0) + 5, Shape.tilesV + 3.3, radius: 0.25, .ink, over: true)
        pic.word("dvs", "÷", at: 2.5, Shape.tilesV + 2, Self.maths)
        if k > 0 {
            let ro = "× \(Dec6.pow10(k)): \(n.times10(k).s) ÷ \(V.times10(k).s)"
            live.word("ro", ro, at: 5, 14.6, Self.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if held { live.reads(ro) }
        }
        // a hint: the divisor ringed; a second miss, where its last digit lands (the ones)
        if s.on("ring") { R6.ring(&pic, "ring", x: 5, y: Shape.tilesV, w: 30, h: 4) }
        if s.on("spot") { pic.sketch.box("spot", pic.R(S.colX(0) + 0.5, Shape.tilesV + 0.5, 4, 3), .chapter, width: Sketch.stroke, dashed: true) }
    }

    /// A number's tiles: each digit a column wide (5 squares), 4 tall, in its place's column. A tile keeps its id (the
    /// digit's index) wherever it moves, so it glides.
    private func tiles(_ pen: inout GridPen, _ id: String, _ str: String, y: Double, _ S: Shape) {
        let parts = str.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        let ip = parts[0], fp = parts.count > 1 ? parts[1] : ""
        // the digits counted from the number's last significant one, so the same digit keeps its id as it moves
        let all = Array(ip + fp)
        for (i, ch) in all.enumerated() {
            let e = ip.count - 1 - i, key = "\(id)\(all.count - 1 - i)"
            pen.sketch.box(key + "o", pen.R(S.colX(e), y, 5, 4), .ink2, width: Sketch.stroke)
            pen.word(key + "d", String(ch), at: S.colX(e) + 2.5, y + 2, Self.maths)
        }
    }

    // MARK: the hands

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers, dec: dec), plan = S.plan, at = stage(s), t = place(s), c = S.c, PT = Self.PT
        switch at {
        case 1:
            return Hands(tap: { q in
                guard abs(q.y - Shape.numY) <= 1.6, q.x >= S.nx - 0.3, q.x <= S.nx + 2 * Double(plan.L0) + 0.3 else { return nil }
                let n = max(1, min(plan.L0, Int(((q.x - S.nx) / 2).rounded(.down)) + 1))
                return HandMove(hand: ["tj": Double(n)], missHand: ["tj": Double(n)], set: [("x", Double(n))], check: true)
            })
        case 2:
            let P = plan.places[t], kNow = Int((s.h("k") ?? 0).rounded()), most = min(9, P.A / S.d + 1)
            let bottom = PT + Double(most + 1) * c
            func on(_ q: CGPoint) -> Bool { q.x >= -1 && q.x <= S.W + 3 && q.y >= PT - 2 && q.y <= bottom + 1 }
            return Hands(
                tap: { q in on(q) && P.qd == 0 ? HandMove(hand: ["k": 0], missHand: nil, set: [("x", 0)], check: true) : nil },
                grab: { q in on(q) ? ["grab": 1, "k": Double(kNow), "k0": Double(kNow), "y0": q.y] : nil },
                drag: { q, h in
                    var h = h
                    let k = Int(h["k0"] ?? 0) + Int(((q.y - (h["y0"] ?? q.y)) / c).rounded())
                    h["k"] = Double(max(0, min(most, k)))
                    return h
                },
                release: { h in
                    let k = Int((h["k"] ?? 0).rounded())
                    return HandMove(hand: ["k": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
                })
        case 6:
            let Pp = plan.places[t - 1]
            return Hands(tap: { q in
                // on the squares left (their row, a little round it)
                guard q.x >= -1, q.x <= Double(Pp.left) * c + 1, q.y >= PT + Double(Pp.qd) * c - 1, q.y <= PT + Double(Pp.qd + 1) * c + 1 else { return nil }
                return HandMove(hand: [:], missHand: nil, set: [("x", 1)], check: true)
            })
        case 5:
            let sk = Int((s.h("sk") ?? 0).rounded())
            return Hands(
                grab: { q in q.y >= 1 && q.y <= 13 && q.x >= 0 && q.x <= 36 ? ["grab": 1, "sk": Double(sk), "k0": Double(sk), "x0": q.x] : nil },
                drag: { q, h in
                    var h = h
                    let k = Int(h["k0"] ?? 0) + Int((((h["x0"] ?? q.x) - q.x) / 5).rounded())
                    h["sk"] = Double(max(0, min(S.kmax, k)))
                    return h
                },
                release: { h in
                    let k = Int((h["sk"] ?? 0).rounded())
                    return HandMove(hand: ["sk": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers, dec: dec), plan = S.plan, at = stage(s), t = place(s), c = S.c, PT = Self.PT
        switch at {
        case 1: return [.tap(.picture(CGPoint(x: S.digitX(plan.j0), y: Shape.numY)))]
        case 2:
            let P = plan.places[t], k = Double(Int((s.h("k") ?? 0).rounded()))
            if P.qd == 0 && k == 0 { return [.tap(.picture(CGPoint(x: min(S.W, Double(max(1, P.A)) * c) / 2, y: PT + c / 2)))] }
            return [.drag(from: CGPoint(x: S.W + 1, y: PT + k * c), to: CGPoint(x: S.W + 1, y: PT + Double(P.qd) * c))]
        case 6:
            let Pp = plan.places[t - 1]
            return [.tap(.picture(CGPoint(x: Double(Pp.left) * c / 2, y: PT + (Double(Pp.qd) + 0.5) * c)))]
        case 5:
            let k = Double(Int((s.h("sk") ?? 0).rounded())), from = CGPoint(x: S.colX(0) + 2.5 - 5 * k, y: Shape.tilesV + 2)
            return [.drag(from: from, to: CGPoint(x: S.colX(0) + 2.5 - 5 * Double(S.s), y: from.y))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let S = Shape(s.numbers, dec: dec), plan = S.plan, at = stage(s), t = place(s)
        switch at {
        case 1:
            let n = plan.j0 > 0 ? plan.j0 : plan.j0 + 2
            return HandMove(hand: ["tj": Double(n)], missHand: ["tj": Double(n)], set: [("x", Double(n))], check: true)
        case 2:
            let k = plan.places[t].qd + 1
            return HandMove(hand: ["k": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
        case 5:
            let k = S.s + 1 <= S.kmax ? S.s + 1 : S.s - 1
            return HandMove(hand: ["sk": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        guard stage(s) == 3 else { return nil }
        let P = Shape(s.numbers, dec: dec).plan.places[place(s)]
        return ["l": Double(P.left + 1)]
    }
}
