import SwiftUI

/// Multiplying decimals on the paper (design/grade5.md). A whole is a bold square 10 squares a side, so one square is a
/// tenth by a tenth, a hundredth, in every problem. The wholes the strip needs are laid out (as many across as x needs,
/// one up for tenths, y up for a whole number), and the problem is written once as the strip's two marks: x under the
/// bottom edge, y beside the left edge. The child drags the strip's corner out from the bottom-left corner to both marks
/// (hundredths × tenths has its width already, a tenth of a square too fine for a finger, and is dragged up); it snaps
/// a piece at a time and the readout over the wholes counts the pieces it covers ("24 × 3 pieces"). Then one piece is
/// blown up beside the wholes with its size (0.1, 0.01, 0.001), the pieces are written as school writes them without
/// the points (24 × 3 = [72]), and the child taps where the point goes in 72 under it: the places are hopped from the
/// right and the answer is written in the chapter's colour. The last words say why it has that many places.
@MainActor
struct MultiplyDecimalsLesson: PaperLesson {
    var liveKeys: Set<String> { ["cx", "cy", "grab"] }
    /// A size being tried (Q.k lays the problem out at each size it tries); nil: the problem's own.
    var trying: Double? = nil

    private static let name = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let readout = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let fine = Sketch.Colour.tint(0.4), shade = Sketch.Colour.tint(0.3)

    /// A problem's numbers and where its parts go, in its squares.
    @MainActor struct Q {
        let A, B, pa, pb, P, n: Int
        let x, y: Double
        let X, Y: String
        /// Wholes across and up; the strip's size in squares, and a piece's.
        let wx, wy: Int
        let sw, sh, pw, ph: Double
        let k: Double
        init(_ v: Numbers, story: Bool = false, k fixed: Double? = nil) {
            let s = MultiplyDecimals.Parts(v)
            A = s.A; B = s.B; pa = s.pa; pb = s.pb; P = s.P; n = s.n; x = s.x; y = s.y; X = fmt(x); Y = fmt(y)
            wx = max(1, Int(x.rounded(.up))); wy = pb == 0 ? max(1, B) : 1
            pw = pa == 1 ? 1 : 0.1; ph = pb == 1 ? 1 : 10
            sw = Double(A) * pw; sh = Double(B) * ph
            k = fixed ?? Self.k(v, story: story)
        }
        var W: Double { Double(10 * wx) }
        var H: Double { Double(10 * wy) }
        /// The wholes' top (the readout's row over it) and bottom.
        var top: Double { 3 * k }
        var bottom: Double { top + H }
        /// The blown-up piece, beside the wholes: its size in squares and its left edge.
        var piece: (w: Double, h: Double) { pa == 2 ? (1, 10) : pb == 0 ? (2, 20) : (5, 5) }
        var pieceX: Double { W + 6 * k }
        /// Where the corner starts: the bottom-left corner (hundredths × tenths: already across).
        var start: (Double, Double) { (pa == 2 ? sw : 0, 0) }

        // MARK: the record, two squares a digit (more, drawn big): A × B = [P], then x × y = P with the point tapped in
        var per: Double { 2 * k }
        var recordRow: Double { bottom + 5 * k }
        func cells(_ s: String) -> Double { Double(s.filter { $0 != "." }.count) * per }
        /// The left parts end, and the "=" after them, level in both rows; the answer's cells after that (one more when
        /// it's less than 1, for its 0).
        var eq: Double { max(cells("\(A)"), cells(X)) + per + max(cells("\(B)"), cells(Y)) }
        var digits: Int { String(P).count }
        var R: Double { eq + per + Double(max(digits, n + 1)) * per }
        func row(_ r: Double) -> Double { (r + 0.5) * per }
        /// The gap j (0 before the first digit … digits after the last) of P in the second row, as a column.
        func gap(_ j: Int) -> Double { R - Double(digits - j) * per }

        static let readable = 22.0
        static func k(_ v: Numbers, story: Bool) -> Double {
            let s = MultiplyDecimals.Parts(v), key = "\(s.A) \(s.B) \(s.pa) \(s.pb)\(story ? " story" : "")"
            if let k = scales[key] { return k }
            let run = LessonRun(MultiplyDecimals.spec, numbers: v, story: story)
            var k = 1.0
            while k < 6, ProblemGrid.stackPlan(MultiplyDecimalsLesson(trying: k), run, auto: false).zoom * Sketch.wordSize * k < readable { k += 1 }
            scales[key] = k
            return k
        }
        private static var scales: [String: Double] = [:]
    }

    private func q(_ run: LessonRun) -> Q { Q(run.numbers, story: run.story, k: trying) }
    /// The stage: 0 the question, 1 the strip, 2 write the pieces, 3 the point, 4 done.
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func scale(_ run: LessonRun) -> Double { q(run).k }
    func scale(_ n: Numbers) -> Double { Q(n, k: trying).k }
    func recordRow(_ n: Numbers) -> Double? { Q(n, k: trying).recordRow }
    /// Beside a tall picture (a whole number's wholes stacked up), level with the wholes' top, when that shows it bigger.
    func recordBeside(_ run: LessonRun) -> Double? { q(run).top }
    func recordBeside(_ n: Numbers) -> Double? { Q(n, k: trying).top }
    /// Where the record's corner is, in the picture's squares: under it or beside it, as the layout put it.
    private func recordOrigin(_ run: LessonRun) -> CGPoint {
        let plan = ProblemGrid.stackPlan(self, run, auto: false)
        return CGPoint(x: plan.recordLeft, y: plan.recordTop - plan.pictureTop)
    }
    func messageRows(_ run: LessonRun) -> Int { missRows(q(run)) }
    func messageRows(_ n: Numbers) -> Int { missRows(Q(n, k: trying)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = self.q(s.run), at = stage(s), k = q.k
        var pic = GridPen(k: k), live = GridPen(k: k, stableIds: true), rec = GridPen(k: k)
        let top = q.top, bottom = q.bottom, W = q.W, H = q.H

        // MARK: the wholes: every square fine, each whole's edges bold in the chapter's colour
        var segs: [(CGPoint, CGPoint)] = []
        for c in 1..<Int(W) where c % 10 != 0 { segs.append((pic.P(Double(c), top), pic.P(Double(c), bottom))) }
        for r in 1..<Int(H) where r % 10 != 0 { segs.append((pic.P(0, top + Double(r)), pic.P(W, top + Double(r)))) }
        // drawn big (the camera far back), the fine lines a little firmer so the squares still show
        let thin = k > 1 ? Sketch.stroke : 1
        pic.sketch.segments("sq", segs, Self.fine, width: thin)
        var wholes: [(CGPoint, CGPoint)] = []
        for c in 0...q.wx { wholes.append((pic.P(Double(10 * c), top), pic.P(Double(10 * c), bottom))) }
        for r in 0...q.wy { wholes.append((pic.P(0, top + Double(10 * r)), pic.P(W, top + Double(10 * r)))) }
        pic.sketch.segments("wholes", wholes, .chapter, width: Sketch.stroke)

        // MARK: the marks, the problem's own names: x under the bottom edge, y beside the left edge
        let hint = at == 1 && s.on("marks")
        pic.line("mx", [(q.sw, bottom), (q.sw, bottom + 0.75 * k)], .ink)
        pic.label("nx", q.X, Self.name, .below, edge: bottom + 0.5 * k, along: q.sw)
        pic.line("my", [(0, bottom - q.sh), (-0.75 * k, bottom - q.sh)], .ink)
        pic.label("ny", q.Y, Self.name, .left, edge: -0.5 * k, along: bottom - q.sh)
        if hint {
            pic.circle("rx", at: q.sw, bottom, radius: 0.9 * k, .chapter, dashed: true)
            pic.circle("ry", at: 0, bottom - q.sh, radius: 0.9 * k, .chapter, dashed: true)
        }

        // MARK: the strip: live while its corner is dragged, then still; its pieces' edges a little firmer than the squares
        func strip(_ pen: inout GridPen, cx: Double, cy: Double) {
            guard cx > 0, cy > 0 else { return }
            pen.fill("sf", col: 0, row: bottom - cy, w: cx, h: cy, Self.shade)
            var cuts: [(CGPoint, CGPoint)] = []
            // a piece's edges: tenths across; up, every piece (a whole number's pieces are a whole tall: its bold lines)
            if q.pa == 1 { for c in stride(from: 1.0, to: cx, by: 1) { cuts.append((pen.P(c, bottom - cy), pen.P(c, bottom))) } }
            else {
                // hundredths: the part-square at the end cut into its tenths of a square
                let whole = cx.rounded(.down)
                for c in stride(from: 1.0, through: whole, by: 1) where c < cx { cuts.append((pen.P(c, bottom - cy), pen.P(c, bottom))) }
                for t in stride(from: whole + 0.1, to: cx - 0.05, by: 0.1) { cuts.append((pen.P(t, bottom - cy), pen.P(t, bottom))) }
            }
            if q.pb == 1 { for r in stride(from: 1.0, to: cy, by: 1) { cuts.append((pen.P(0, bottom - r), pen.P(cx, bottom - r))) } }
            pen.sketch.segments("sc", cuts, .tint(0.7), width: k > 1 ? Sketch.stroke : 1)
            pen.line("so", [(0, bottom - cy), (cx, bottom - cy), (cx, bottom)], .chapter)
        }
        func count(_ cx: Double, _ cy: Double) -> String { "\(Int((cx / q.pw).rounded())) × \(Int((cy / q.ph).rounded())) pieces" }

        var actions: [String] = []
        if at == 1 {
            let (cx0, cy0) = q.start
            let cx = s.h("cx") ?? cx0, cy = s.h("cy") ?? cy0
            strip(&live, cx: cx, cy: cy)
            live.dot("corner", at: cx, bottom - cy, radius: (s.grabbed ? 0.75 : 0.6) * k, .chapter, over: true)
            if cx > 0, cy > 0 { live.label("count", count(cx, cy), Self.readout, .above, edge: top, along: W / 2) }
        } else if at >= 2 {
            strip(&pic, cx: q.sw, cy: q.sh)
            pic.label("count", at >= 3 ? "\(q.P) pieces" : count(q.sw, q.sh), Self.readout.colour(at >= 3 ? .chapter : .ink), .above, edge: top, along: W / 2)
        }
        // a hint: each row of pieces counted at its right end
        if at == 2, s.on("rows") {
            for r in 0..<q.B { pic.label("row\(r)", "\(q.A)", Self.small, .right, edge: q.sw, along: bottom - (Double(r) + 0.5) * q.ph) }
        }

        // MARK: one piece, ringed in the strip's corner and blown up beside the wholes with its size
        if at >= 3 {
            let (w, h) = q.piece
            pic.line("p1", [(0, bottom - q.ph), (q.pw, bottom - q.ph), (q.pw, bottom)], .ink)
            pic.fill("pbf", col: q.pieceX, row: bottom - h, w: w, h: h, Self.shade)
            pic.sketch.box("pbo", pic.R(q.pieceX, bottom - h, w, h), .chapter, width: Sketch.stroke)
            pic.label("pbs", fmt(1 / pow(10, Double(q.n))), Self.name.colour(.chapter), .below, edge: bottom + 0.5 * k, along: q.pieceX + w / 2)
            pic.label("pbn", "one piece", Self.small.colour(.ink), .above, edge: bottom - h, along: q.pieceX + w / 2)
        }

        // MARK: the record: A × B = [P], then x × y = P with its point tapped in
        var boxes: [WorkBox] = []
        if at >= 2 {
            let per = q.per
            func line(_ r: Double, _ a: String, _ b: String, _ id: String) {
                let y = q.row(r), right = q.eq - q.cells(b) - per
                rec.digits("\(id)a", a, right: right, row: y, per: per)
                rec.word("\(id)x", "×", at: right + per / 2, y, Self.maths)
                rec.digits("\(id)b", b, right: q.eq, row: y, per: per)
                rec.word("\(id)e", "=", at: q.eq + per / 2, y, Self.maths)
            }
            line(0, "\(q.A)", "\(q.B)", "r0")
            if at == 2 { rec.answerBox("x", right: q.R, mid: q.row(0), per: per, cells: q.digits) }
            else { rec.digits("r0p", "\(q.P)", right: q.R, row: q.row(0), per: per) }
            if at >= 3, !s.picking {
                line(2, q.X, q.Y, "r1")
                let y = q.row(2), ans = MultiplyDecimals.Parts(s.numbers).answer
                if at == 3 { rec.digits("r1p", "\(q.P)", right: q.R, row: y, per: per) }
                else { rec.digits("r1p", fmt(ans), right: q.R, row: y, per: per, .chapter) }
                // a tap that missed: the point where it went, in pencil, ringed
                if at == 3, let j = s.h("tap") {
                    rec.sketch.text("miss.", ".", at: rec.P(q.gap(Int(j)), y), size: Sketch.maths * k, weight: .bold, .ink3, anchor: UnitPoint(x: 0.5, y: 0.49))
                    rec.circle("missr", at: q.gap(Int(j)), y + 0.4 * k, radius: 0.8 * k, .ink3)
                }
                // the places hopped from the right, numbered: the proof once it's placed, a hint before
                if at >= 4 || s.on("count") {
                    for i in 0..<q.n {
                        let c1 = q.R - Double(i) * per, c0 = c1 - per
                        rec.hop("hop\(i)", from: c1, to: c0, row: y + per * 0.75, height: -0.8 * k)
                        rec.label("hn\(i)", "\(i + 1)", Self.small, .below, edge: y + per * 0.75 + 0.8 * k, along: (c0 + c1) / 2)
                    }
                }
            }
            boxes = rec.boxes
        }
        let extent = pic.R(-3 * k, 0, q.pieceX + q.piece.w / 2 + 3 * k + 3 * k, q.bottom + 3 * k)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions, extent: extent)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = self.q(s.run), k = q.k, at = stage(s)
        if at == 1 {
            let (cx0, cy0) = q.start
            let cx = s.h("cx") ?? cx0, cy = s.h("cy") ?? cy0, bottom = q.bottom
            /// The corner for the finger here: across a tenth (a square) at a time, up a piece at a time.
            func snap(_ p: CGPoint) -> Numbers {
                let x = q.pa == 2 ? q.sw : min(q.W, max(0, p.x.rounded()))
                let y = min(q.H, max(0, ((bottom - p.y) / q.ph).rounded() * q.ph))
                return ["cx": x, "cy": y]
            }
            func move(_ h: Numbers) -> HandMove {
                let x = h["cx"] ?? cx, y = h["cy"] ?? cy
                return HandMove(hand: ["cx": x, "cy": y], missHand: nil,
                                set: [("a", (x / q.pw).rounded()), ("b", (y / q.ph).rounded())], check: true)
            }
            return Hands(
                // a tap on the wholes puts the corner there
                tap: { p in p.x > -0.5 && p.x < q.W + 0.5 && p.y > q.top - 0.5 && p.y < bottom + 0.5 ? move(snap(p)) : nil },
                grab: { p in hypot(p.x - cx, p.y - (bottom - cy)) < 2 * k ? ["grab": 1, "cx": cx, "cy": cy] : nil },
                drag: { p, _ in snap(p).merging(["grab": 1]) { $1 } },
                release: { h in move(h) })
        }
        guard at == 3, !s.picking else { return nil }
        // the point: a tap in the second row, at the gap nearest the finger
        let o = recordOrigin(s.run), y0 = q.row(2), P = q.P, d = q.digits
        return Hands(tap: { t in
            let p = CGPoint(x: t.x - o.x, y: t.y - o.y)
            guard abs(p.y - y0) < q.per, p.x > q.gap(0) - q.per / 2, p.x < q.gap(d) + q.per / 2 else { return nil }
            let j = min(d, max(0, Int(((p.x - q.gap(0)) / q.per).rounded())))
            return HandMove(hand: ["tap": Double(j)], missHand: ["tap": Double(j)], set: [("x", MultiplyDecimals.pointed(P, d - j))], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = self.q(s.run), at = stage(s)
        if at == 1 {
            let cx = s.h("cx") ?? q.start.0, cy = s.h("cy") ?? q.start.1
            return [.drag(from: CGPoint(x: cx, y: q.bottom - cy), to: CGPoint(x: q.sw, y: q.bottom - q.sh))]
        }
        guard at == 3 else { return [] }
        let o = recordOrigin(s.run)
        return [.tap(.picture(CGPoint(x: o.x + q.gap(q.digits - q.n), y: o.y + q.row(2))))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = self.q(s.run), at = stage(s)
        if at == 1 {
            // a tenth short across (hundredths × tenths: a tenth too high)
            let x = q.pa == 2 ? q.sw : q.sw - 1, y = q.pa == 2 ? q.sh + 1 : q.sh
            return HandMove(hand: ["cx": x, "cy": y], missHand: nil, set: [("a", (x / q.pw).rounded()), ("b", (y / q.ph).rounded())], check: true)
        }
        guard at == 3 else { return nil }
        // the point a place too far right (the answer ten times too big)
        let j = q.digits - q.n + 1
        return HandMove(hand: ["tap": Double(j)], missHand: ["tap": Double(j)], set: [("x", MultiplyDecimals.pointed(q.P, q.n - 1))], check: true)
    }

    /// What a miss says can run to two rows on a narrow problem.
    private func missRows(_ q: Q) -> Int {
        let longest = "That’s \(fmt(q.x - 0.1)) across and \(fmt(q.y + 0.1)) up. Take the corner to both marks."
        let w = PaperText.width(longest, PaperText.font(Sketch.small * q.k, .medium)) / Paper.cell
        return w > max(30, q.pieceX + q.piece.w) ? 2 : 1
    }
}
