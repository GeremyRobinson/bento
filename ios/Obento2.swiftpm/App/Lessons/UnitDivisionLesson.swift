import SwiftUI

/// Dividing by a unit fraction on the paper (design/grade5.md, the fractions family): W ÷ 1/d asks how many 1/d pieces
/// fit in W wholes. The wholes are bars a whole long (48 squares; 40 for fifths, 42 for sevenths, so a piece is a whole
/// number of squares), all shaded, each named 1, their column braced and named W; above them the 1/d piece, alone and
/// the size it really is, named 1/d: the problem, written once as the picture's own names. The ruler's handle, over the
/// piece, sets one piece's length; the cuts it would make show dashed down the piece and the first whole, and the dot
/// under the piece's end is green when a new cut lands on it, red when none does. Cut cuts the first whole (how many fit
/// in one whole); then every whole is cut the same way and every piece is counted on, whole by whole (See), and the
/// record W ÷ 1/d = W × d = [ ] is written 3 rows under the wholes, the product typed. The last words say why.
///
/// Up to three wholes are the family's 4-square bars, a square apart (three fill the screen at full size, as Mixed
/// numbers' do); more (the web's ten at most) are 2 squares tall, so ten fit at three quarters size, every piece still
/// numbered and counted on the paper. The bars, the ruler and the names are the family's kit (BarsKit.swift).
@MainActor
struct UnitDivisionLesson: PaperLesson {
    /// The picture's rows, in its squares: the ruler, and the piece's top (the wholes under it, Q.row).
    nonisolated static let ruler = 2.0, top = 4.0
    /// The most wholes drawn as the family's 4-square bars; more are 2 squares tall.
    nonisolated static let tallWholes = 3

    var liveKeys: Set<String> { ["ruler"] }

    /// A problem's numbers, and the squares they make.
    struct Q {
        /// The wholes (the web's W), the bottom, and a whole's length in squares.
        let n, d, L: Int
        /// A bar's height: the family's 4 squares, or 2 when there are more wholes than 4-square bars fit.
        let h: Double
        init(_ p: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((p[k] ?? Double(v)).rounded()) }
            n = min(max(1, i("W", 2)), 20); d = min(max(2, i("d", 2)), 24)
            L = UnlikeFractions.wholeLength(d)
            h = n <= UnitDivisionLesson.tallWholes ? Bars.height : 2
        }
        /// The piece's length (a whole's 1/d), and every piece counted.
        var pw: Int { L / d }
        var all: Int { n * d }
        /// The piece's top row, and its end's dot a square under it.
        var piece: Double { UnitDivisionLesson.top }
        var dots: Double { piece + h + 1 }
        /// Whole j's top row: the first two squares under the piece (its end's dot between them), the rest a square apart.
        func row(_ j: Int) -> Double { piece + h + 2 + Double(j) * (h + 1) }
        /// The last whole's bottom.
        var bottom: Double { row(n - 1) + h }
        /// Where the ruler starts: the longest piece that isn't the answer, so the hand has something to find.
        var start: Int { Ruler.lengths(L).last { $0 != pw } ?? pw }
    }

    /// The ruler on the cut step: over the piece, its cuts dashed down the piece and the first whole; the old cut is the
    /// piece's end, its dot a square under it.
    private func theRuler(_ q: Q) -> Ruler {
        Ruler(W: q.L, row: Self.ruler, from: Self.top - 1, to: q.row(0) + q.h + 1,
              old: [Ruler.Old(tag: 1, row: q.dots, at: [Double(q.pw)])], start: q.start)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), L = Double(q.L), pw = Double(q.pw), h = q.h
        let cut = s.on("cut"), done = s.on("done")
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()

        // MARK: the 1/d piece, alone, the size it really is
        pic.fill("pf", col: 0, row: q.piece, w: pw, h: h, Bars.shade)
        Bars.bar(&pic, "p", row: q.piece, parts: 1, W: q.pw, h: h)

        // MARK: the wholes: whole until the ruler cuts the first; then every whole is cut into d pieces and every piece
        // counted on, the first whole first (the See: they draw in in this order)
        for j in 0..<q.n {
            let y = q.row(j)
            pic.fill("w\(j)f", col: 0, row: y, w: L, h: h, Bars.shade)
            Bars.bar(&pic, "w\(j)", row: y, parts: cut ? q.d : 1, W: q.L, h: h)
            if cut { Bars.numbers(&pic, "n\(j)_", j * q.d ..< (j + 1) * q.d, row: y, per: pw, h: h) }
        }

        // MARK: the names at the bars' right ends: the piece's 1/d, each whole's 1, and the wholes braced, named W
        let nx = L + 2
        Bars.fraction(&pic, "fp", 1, q.d, col: nx, row: q.piece + h / 2 - 2)
        for j in 0..<q.n { Bars.whole(&pic, "f\(j)", 1, col: nx, row: q.row(j), h: h) }
        Bars.brace(&pic, "brace", col: nx + 5, from: q.row(0), to: q.bottom)
        pic.label("fW", "\(q.n)", Bars.maths, .right, edge: nx + 7, along: (q.row(0) + q.bottom) / 2)

        // MARK: the ruler, and what it would cut, live as it's dragged
        var actions: [String] = []
        if s.on("ruler") {
            actions = ["Cut"]
            theRuler(q).draw(s, live: &live, still: &pic)
        }

        // MARK: a hint on the record: the last piece counted, ringed
        if cut && !done && s.on("last") {
            pic.circle("last", at: (Double(q.d) - 0.5) * pw, q.row(q.n - 1) + h / 2, radius: min(h == Bars.height ? 1.3 : 0.9, pw / 2 - 0.15), .chapter, dashed: true)
        }

        // MARK: the record, as school writes it: W ÷ 1/d = W × d = [W·d], two squares a sign or a digit, the product typed
        var boxes: [WorkBox] = []
        if cut {
            let maths = Bars.maths, k = Double(String(q.n).count)
            var x = 0.0
            func put(_ id: String, _ text: String, _ w: Double) { rec.word(id, text, at: x + w / 2, 2, maths); x += w }
            put("rW", "\(q.n)", 2 * k)
            put("rdiv", "÷", 2)
            Bars.fraction(&rec, "rf", 1, q.d, col: x, row: 0); x += 4
            put("re1", "=", 2)
            put("rW2", "\(q.n)", 2 * k)
            put("rx", "×", 2)
            put("rd", "\(q.d)", 2)
            put("re2", "=", 2)
            if done { rec.word("ra", "\(q.all)", at: x + 2, 2, maths.colour(.chapter)) }
            // (a wrong way round, 0.75, grows the box to the right, never over the =)
            else { rec.answerBox("n", right: x + 4, mid: 2, per: 2, cells: 2, centred: true, keepsLeft: true) }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes, actions: actions)
    }

    func hands(_ s: PaperState) -> Hands? {
        // the ruler (Cut: how many pieces of its length make a whole, checked against the piece)
        s.on("ruler") ? theRuler(Q(s.numbers)).hands(s) : nil
    }

    /// The record is written once the ruler and the piece's dot are put away: 3 rows under the wholes.
    func recordRow(_ n: Numbers) -> Double? { Q(n).bottom + 3 }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers)
        return s.on("ruler") ? theRuler(q).demo(s, to: q.pw) : []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        // a length whose cuts miss the piece's end
        let q = Q(s.numbers)
        return s.on("ruler") ? theRuler(q).wrongMove(else: q.start) : nil
    }
}
