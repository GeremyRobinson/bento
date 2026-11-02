import SwiftUI

/// Fractions as division on the paper, as in the preview G approved on 1 Nov 2026 (design/prototype/new5-lessons.html,
/// dFracDiv), with the fractions family's kit (BarsKit.swift): a things shared by b friends, each thing a bar a whole
/// long (48 squares, 40 for fifths) and 3 tall, the bars 5 squares apart, named "3 subs" at the first one's right end.
/// The ruler's handle, over the bars, sets one piece's length ("6 pieces" while it's dragged), its cuts dashed down every
/// bar; Cut cuts them. Then the child taps one friend's share (the pieces shade as they're tapped, counted under the
/// bars) and checks it. The share slides together into one bar under a rule, named "one share" (a second bar when it's
/// more than a whole), and beside the bars the record a ÷ b gets its = [ ]/[ ], typed. The last words say why.
@MainActor
struct FractionsAsDivisionLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, a bar's height, and bar i's top.
    nonisolated static let ruler = 2.0, H = 3.0
    nonisolated static func row(_ i: Int) -> Double { 4 + 5 * Double(i) }

    var liveKeys: Set<String> { ["ruler", "taps"] }

    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    /// A problem's numbers and the squares they make.
    struct Q {
        let p: FractionsAsDivision.Parts
        init(_ n: Numbers) { p = FractionsAsDivision.Parts(n) }
        var a: Int { p.a }
        var b: Int { p.b }
        var W: Int { p.W }
        var pw: Int { p.pw }
        /// The last bar's bottom.
        var bottom: Double { FractionsAsDivisionLesson.row(a - 1) + FractionsAsDivisionLesson.H }
        /// The share's first bar, under a rule two squares over it.
        var share: Double { FractionsAsDivisionLesson.row(a) + 3 }
        /// The record's top row (level with the second bar, clear of the first bar's name) and its left column.
        var recordTop: Double { FractionsAsDivisionLesson.row(1) - 1 }
        var recordLeft: Double { Double(W) + 5 }
        /// Where the ruler starts: the longest piece that isn't the answer, so the hand has something to find.
        var start: Int { Ruler.lengths(W).last { $0 != pw } ?? pw }
        /// Piece k of bar i: its bit in the hand's "taps".
        func bit(_ i: Int, _ k: Int) -> Int { i * b + k }
    }

    private func theRuler(_ q: Q) -> Ruler {
        let W = q.W
        return Ruler(W: W, row: Self.ruler, from: Self.row(0) - 1, to: q.bottom + 1, old: [], start: q.start,
                     readout: { "\(W / max(1, $0)) pieces" })
    }

    private static func bits(_ v: Double?) -> Set<Int> { let b = Int(v ?? 0); return Set((0..<40).filter { b & (1 << $0) != 0 }) }

    /// The pieces taken for the share once it's checked: the ones the child tapped (kept by Check), or the first piece of
    /// every bar when what's kept doesn't fit.
    private func taken(_ s: PaperState, _ q: Q) -> Set<Int> {
        let kept = Self.bits(s.run.kept["taken"])
        return kept.count == q.a && kept.allSatisfy({ $0 < q.a * q.b }) ? kept : Set((0..<q.a).map { q.bit($0, 0) })
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), W = Double(q.W), pw = Double(q.pw), H = Self.H
        let cut = s.on("cut"), sharing = s.on("share"), slid = s.on("slid"), done = s.on("done")
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // MARK: the things, a bar a whole long each: the share's pieces shaded once it's taken, cut once they're cut
        let took = slid ? taken(s, q) : []
        for i in 0..<q.a {
            let y = Self.row(i)
            for k in 0..<q.b where took.contains(q.bit(i, k)) { pic.fill("s\(i)_\(k)", col: Double(k) * pw, row: y, w: pw, h: H, Bars.shade) }
            Bars.bar(&pic, "bar\(i)", row: y, parts: cut ? q.b : 1, W: q.W, h: H)
        }
        pic.label("barsn", q.p.named, Self.small, .right, edge: W, along: Self.row(0) + H / 2)

        // MARK: the ruler, and the cuts it would make down every bar, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: the share: pieces shade as they're tapped, counted under the bars; a hint rings a piece of every bar
        if sharing {
            actions = ["Check"]
            let on = Self.bits(s.h("taps"))
            for i in 0..<q.a {
                for k in 0..<q.b where on.contains(q.bit(i, k)) { live.fill("t\(i)_\(k)", col: Double(k) * pw, row: Self.row(i), w: pw, h: H, Bars.shade) }
                if s.on("ring") { pic.circle("ring\(i)", at: pw / 2, Self.row(i) + H / 2, radius: min(1.3, pw / 2 - 0.15), .chapter, dashed: true) }
            }
            live.label("count", "\(on.count) piece\(on.count == 1 ? "" : "s")", Self.small, .below, edge: q.bottom, along: 4)
        }

        // MARK: one friend's share, slid together into whole bars under a rule
        if slid {
            let sy = q.share
            pic.rule("rule", from: 0, to: W, row: sy - 2, .ink3)
            for j in 0..<q.p.shareBars {
                let y = sy + 5 * Double(j), n = min(q.b, q.a - j * q.b)
                pic.fill("sh\(j)", col: 0, row: y, w: Double(n) * pw, h: H, Bars.shade)
                Bars.bar(&pic, "shb\(j)", row: y, parts: q.b, W: q.W, h: H)
            }
            pic.label("shn", "one share", Self.small.colour(.chapter), .right, edge: W, along: sy + H / 2)
        }

        // MARK: the record, beside the bars from the start: a ÷ b, then = [ ]/[ ] typed, then the fraction
        var boxes: [WorkBox] = []
        let rx = q.recordLeft, fr = q.recordTop, mid = fr + 2, maths = Bars.maths
        rec.word("ra", "\(q.a)", at: rx + 1, mid, maths)
        rec.word("rdiv", "÷", at: rx + 3.5, mid, maths)
        rec.word("rb", "\(q.b)", at: rx + 6, mid, maths)
        if done {
            rec.word("req", "=", at: rx + 8.5, mid, maths.colour(.chapter))
            Bars.fraction(&rec, "rf", q.a, q.b, col: rx + 10, row: fr, .chapter)
        } else if slid {
            rec.word("req", "=", at: rx + 8.5, mid, maths)
            Bars.fraction(&rec, "rf", nil, nil, col: rx + 10, row: fr)
            rec.answerBox("t", right: rx + 14, mid: fr + 1, per: 2, cells: 2, centred: true)
            rec.answerBox("b", right: rx + 14, mid: fr + 3, per: 2, cells: 2, centred: true)
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers)
        if s.on("ruler") { return theRuler(q).hands(s) }
        guard s.on("share") else { return nil }
        // a tap on a piece shades it, or takes it back; Check checks how many
        let bits = Int(s.h("taps") ?? 0), pw = Double(q.pw), W = Double(q.W), H = Self.H
        return Hands(
            tap: { p in
                guard p.x >= 0, p.x < W else { return nil }
                guard let i = (0..<q.a).first(where: { p.y >= Self.row($0) - 0.5 && p.y <= Self.row($0) + H + 0.5 }) else { return nil }
                let k = min(q.b - 1, Int(p.x / pw)), now = bits ^ (1 << q.bit(i, k))
                return HandMove(hand: ["taps": Double(now)], missHand: nil, set: [("n", Double(now.nonzeroBitCount))])
            },
            // Check keeps which pieces were tapped, so they stay the share
            actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [("n", Double(bits.nonzeroBitCount))], keep: ["taken": Double(bits)], check: true) }])
    }

    /// The record is beside the bars, in the picture's own squares.
    func recordRow(_ n: Numbers) -> Double? { 0 }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        if s.on("ruler") { return theRuler(q).demo(s, to: q.pw) }
        guard s.on("share") else { return [] }
        // the first piece of every bar (any others tapped taken back), then Check
        let on = Self.bits(s.h("taps")), want = Set((0..<q.a).map { q.bit($0, 0) })
        let flips = on.symmetricDifference(want).sorted()
        return flips.map { k in
            let i = k / q.b, piece = k % q.b
            return .tap(.picture(CGPoint(x: (Double(piece) + 0.5) * Double(q.pw), y: Self.row(i) + Self.H / 2)))
        } + [.tap(.action("Check"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers)
        // a cut into the wrong number of pieces; one piece shaded for a friend instead of one from every bar
        if s.on("ruler") { return theRuler(q).wrongMove(else: q.start) }
        guard s.on("share") else { return nil }
        return HandMove(hand: ["taps": 1], missHand: nil, set: [("n", 1)], keep: ["taken": 1], check: true)
    }
}
