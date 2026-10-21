import SwiftUI

/// Order of operations on the paper (design/grade5.md). The expression is written once, big, as the record's first line,
/// and rewritten line under line as school does it (`= 3 + 4 × 4`, `= 3 + 16`, `= 19`). The child taps the part that goes
/// first in the line (or presses and slides along it: the part under the finger is ringed as it moves); a wrong part is
/// lit red and answered in plain words. The right part is lit, its squares build under the record, and its value is
/// typed in the next line, where school writes it. Then the part that goes next is tapped and written, and the last one
/// written. One square is one: a number is a row of squares, × makes rows, − crosses squares out, ÷ deals them into rows.
/// The record sits at the top of the picture (recordRow 0), so a tap on the line lands in the picture's own squares.
@MainActor
struct OrderLesson: PaperLesson {
    var liveKeys: Set<String> { ["part", "grab"] }

    private static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    private static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let proved = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    private static let wrongFill = Sketch.Colour.hex(Ink.mix(0xF3F2EF, 0xC8372D, 0.2), Ink.mix(0x121211, 0xFF6B5E, 0.24))
    private static let crossInk = Sketch.Colour.ink2

    /// The lines start here (the "=" of a rewritten line sits before it); a line's middle row; the squares' top row.
    nonisolated static let x0 = 3.0, top = 14.0
    nonisolated static func mid(_ line: Int) -> Double { 1 + 3 * Double(line) }
    /// The stage each line's value is written on (line 0 is the expression).
    private static let writes = [0, 2, 4, 5]

    typealias Token = OrderOfOperations.Token
    /// Each token's columns: two squares a digit, four a sign (so a number's digits never read as two numbers), one a
    /// parenthesis; a square more after an answer box (its cursor's room).
    static func columns(_ line: [Token], box: Int? = nil) -> [(Double, Double)] {
        var x = x0, out: [(Double, Double)] = []
        for (i, t) in line.enumerated() {
            let w: Double
            switch t { case .n(let v): w = 2 * Double(String(v).count); case .op: w = 4; case .open, .close: w = 1 }
            out.append((x, x + w)); x += w + (i == box ? 1 : 0)
        }
        return out
    }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The line tapped on this stage (1: the expression, 3: the second line).
    private func tapLine(_ at: Int) -> Int? { at == 1 ? 0 : at == 3 ? 1 : nil }

    func messageRows(_ n: Numbers) -> Int { 2 }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let w = OrderOfOperations.working(s.numbers), at = stage(s)
        var rec = GridPen(), pic = GridPen(), live = GridPen(stableIds: true)

        // MARK: the record: the expression, then each line as it's written
        for i in 0..<4 where i == 0 || at >= Self.writes[i] {
            let boxAt = i > 0 && at == Self.writes[i] ? w.worked[i - 1].lowerBound : nil
            let line = w.lines[i], cols = Self.columns(line, box: boxAt), m = Self.mid(i)
            // the part being worked, lit behind it; a wrong part tapped, red
            if i < 3, at == Self.writes[i + 1] { span(&rec, "lit\(i)", cols, w.worked[i], m, .tint(0.3)) }
            if let t = tapLine(at), t == i, let bad = s.h("wrong") {
                let signs = OrderOfOperations.Working.signs(line), j = Int(bad)
                if signs.indices.contains(j) { span(&rec, "wrong\(j)", cols, OrderOfOperations.Working.span(line, sign: signs[j]), m, Self.wrongFill) }
            }
            if i > 0 { rec.word("eq\(i)", "=", at: 1.5, m, Self.maths) }
            let colour: Sketch.Colour = i == 3 && at >= 6 ? .chapter : .ink
            for (j, t) in line.enumerated() {
                let (a, b) = cols[j]
                switch t {
                case .n(let v):
                    if j == boxAt { rec.answerBox("x", right: b, mid: m, per: 2, cells: String(v).count) }
                    else { rec.digits("L\(i)n\(j)", "\(v)", right: b, row: m, per: 2, colour) }
                case .op(let o): rec.word("L\(i)o\(j)", o, at: (a + b) / 2, m, Self.maths)
                case .open: rec.word("L\(i)p\(j)", "(", at: (a + b) / 2, m, Self.maths)
                case .close: rec.word("L\(i)q\(j)", ")", at: (a + b) / 2, m, Self.maths)
                }
            }
        }

        // MARK: the part the finger is on, ringed as it moves
        if let t = tapLine(at), let p = s.h("part") {
            let line = w.lines[t], signs = OrderOfOperations.Working.signs(line), j = Int(p)
            if signs.indices.contains(j) {
                let r = OrderOfOperations.Working.span(line, sign: signs[j]), cols = Self.columns(line)
                let x0 = cols[r.lowerBound].0, x1 = cols[r.upperBound - 1].1
                live.ring("held", col: x0 - 0.5, row: Self.mid(t) - 1.75, w: x1 - x0 + 1, h: 3.5)
            }
        }

        // MARK: the picture: the squares each part makes, under the record
        drawSquares(&pic, s.numbers, w, at)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// A fill behind some tokens of a line.
    private func span(_ pen: inout GridPen, _ id: String, _ cols: [(Double, Double)], _ r: Range<Int>, _ m: Double, _ colour: Sketch.Colour) {
        let x0 = cols[r.lowerBound].0, x1 = cols[r.upperBound - 1].1
        pen.fill(id, col: x0 - 0.5, row: m - 1.5, w: x1 - x0 + 1, h: 3, colour)
    }

    /// How many squares a side one unit is: 2 while the problem's picture fits at that size, else 1 (one square is one).
    static func unit(_ n: Numbers) -> Double {
        let t = Int(n["t"] ?? 0), a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 0), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 0)
        let (W, H): (Int, Int) = t == 1 ? (a + b, c) : t == 2 ? (b + 4 + c / max(1, d), max(a, d)) : (max(c, c - d, a), b + 2)
        return W * 2 <= 36 && H * 2 <= 16 ? 2 : 1
    }

    /// A rectangle of units (`u` squares a side): its outline, every unit, every ten stronger, its fill; lit while it's
    /// the part being worked.
    private func units(_ pen: inout GridPen, _ id: String, x: Double, y: Double, cols: Int, rows: Int, u: Double, lit: Bool) {
        guard cols > 0, rows > 0 else { return }
        let tag = "\(id)\(lit)", r = pen.R(x, y, Double(cols) * u, Double(rows) * u)
        pen.sketch.box(tag + "o", r, .chapter, width: Sketch.stroke)
        func lines(every: Int) -> [(CGPoint, CGPoint)] {
            stride(from: every, to: cols, by: every).map { j in (pen.P(x + Double(j) * u, y), pen.P(x + Double(j) * u, y + Double(rows) * u)) }
                + stride(from: every, to: rows, by: every).map { j in (pen.P(x, y + Double(j) * u), pen.P(x + Double(cols) * u, y + Double(j) * u)) }
        }
        pen.sketch.segments(tag + "c", lines(every: 1), lit ? .tint(0.6) : .tint(0.42), width: 1)
        pen.sketch.segments(tag + "t", lines(every: 10), .tint(lit ? 1 : 0.8), width: Sketch.stroke)
        pen.sketch.fill(tag + "f", r, lit ? .tint(0.38) : .tint(0.16))
    }

    /// The last `n` of `count` units laid in rows of `cols`, crossed out (taken away): an X through each.
    private func crossLast(_ pen: inout GridPen, _ id: String, x: Double, y: Double, cols: Int, count: Int, n: Int, u: Double) {
        let e = 0.2 * u
        let segs = (max(0, count - n)..<count).flatMap { k -> [(CGPoint, CGPoint)] in
            let c = x + Double(k % cols) * u, r = y + Double(k / cols) * u
            return [(pen.P(c + e, r + u - e), pen.P(c + u - e, r + e)), (pen.P(c + e, r + e), pen.P(c + u - e, r + u - e))]
        }
        pen.sketch.segments(id, segs, Self.crossInk, width: Sketch.stroke)
    }

    private func drawSquares(_ pen: inout GridPen, _ n: Numbers, _ w: OrderOfOperations.Working, _ at: Int) {
        guard at >= 2 else { return }
        let t = Int(n["t"] ?? 0), a = Int(n["a"] ?? 0), b = Int(n["b"] ?? 0), c = Int(n["c"] ?? 0), d = Int(n["d"] ?? 0)
        let X = Self.x0, T = Self.top, r0 = w.values[0], r1 = w.values[1], u = Self.unit(n)
        func D(_ v: Int) -> Double { Double(v) * u }
        switch t {
        case 1: // (a + b) × c − d
            if at < 4 {
                // a + b: a row of a units, then b striped
                units(&pen, "ra", x: X, y: T, cols: a, rows: 1, u: u, lit: at == 2)
                units(&pen, "rb", x: X + D(a), y: T, cols: b, rows: 1, u: u, lit: at == 2)
                pen.stripes("rbs", col: X + D(a), row: T, w: D(b), h: u)
                pen.label("la", "\(a)", Self.name, .above, edge: T, along: X + D(a) / 2)
                pen.label("lb", "\(b)", Self.name, .above, edge: T, along: X + D(a) + D(b) / 2)
                if at == 3 { pen.label("v0", "\(r0)", Self.proved, .below, edge: T + u, along: X + D(r0) / 2) }
            } else {
                // × c: c rows of it; then − d: the last d crossed out
                units(&pen, "R", x: X, y: T, cols: r0, rows: c, u: u, lit: at == 4)
                pen.label("w", "\(r0)", Self.name, .above, edge: T, along: X + D(r0) / 2)
                pen.label("h", "\(c)", Self.name, .left, edge: X, along: T + D(c) / 2)
                if at >= 5 {
                    pen.label("v1", "\(r1)", Self.proved, .right, edge: X + D(r0), along: T + D(c) / 2)
                    crossLast(&pen, "x", x: X, y: T, cols: r0, count: r1, n: d, u: u)
                }
            }
        case 2: // a × b − c ÷ d
            units(&pen, "R", x: X, y: T, cols: b, rows: a, u: u, lit: at == 2)
            pen.label("w", "\(b)", Self.name, .above, edge: T, along: X + D(b) / 2)
            pen.label("h", "\(a)", Self.name, .left, edge: X, along: T + D(a) / 2)
            if at >= 3 { pen.label("v0", "\(r0)", Self.proved, .right, edge: X + D(b), along: T + D(a) / 2) }
            if at >= 4 {
                // c ÷ d: c units dealt into d rows, beside it; a row of them is the answer
                let Xd = X + D(b) + 7
                units(&pen, "deal", x: Xd, y: T, cols: r1, rows: d, u: u, lit: at == 4)
                pen.label("dh", "\(d)", Self.name, .left, edge: Xd, along: T + D(d) / 2)
                pen.label("dn", "\(c) in \(d) rows", Self.small, .below, edge: T + D(d), along: Xd + D(r1) / 2)
                if at >= 5 {
                    pen.label("v1", "\(r1)", Self.proved, .above, edge: T, along: Xd + D(r1) / 2)
                    crossLast(&pen, "x", x: X, y: T, cols: b, count: r0, n: r1, u: u)
                }
            }
        default: // a + b × (c − d)
            if at < 4 {
                // c − d: a row of c units, the last d crossed out
                units(&pen, "row", x: X, y: T, cols: c, rows: 1, u: u, lit: at == 2)
                crossLast(&pen, "x", x: X, y: T, cols: c, count: c, n: d, u: u)
                pen.label("lc", "\(c)", Self.name, .above, edge: T, along: X + D(c) / 2)
                if at == 3 { pen.label("v0", "\(r0)", Self.proved, .below, edge: T + u, along: X + D(r0) / 2) }
            } else {
                // b × it: b rows of what's left; then + a: a units, striped, under them
                units(&pen, "R", x: X, y: T, cols: r0, rows: b, u: u, lit: at == 4)
                pen.label("w", "\(r0)", Self.name, .above, edge: T, along: X + D(r0) / 2)
                pen.label("h", "\(b)", Self.name, .left, edge: X, along: T + D(b) / 2)
                if at >= 5 {
                    let y = T + D(b) + u
                    pen.label("v1", "\(r1)", Self.proved, .right, edge: X + D(r0), along: T + D(b) / 2)
                    units(&pen, "A", x: X, y: y, cols: a, rows: 1, u: u, lit: at == 5)
                    pen.stripes("As", col: X, row: y, w: D(a), h: u)
                    pen.label("la", "\(a)", Self.name, .right, edge: X + D(a), along: y + u / 2)
                }
            }
        }
    }

    // MARK: the hands: tap the part that goes first (or next), or press and slide along the line

    /// The sign whose part is nearest a place on line `t`, or nil off the line.
    private func part(_ w: OrderOfOperations.Working, _ t: Int, _ p: CGPoint, strict: Bool) -> Int? {
        let line = w.lines[t], cols = Self.columns(line), signs = OrderOfOperations.Working.signs(line)
        if strict { guard abs(p.y - Self.mid(t)) < 2, p.x > Self.x0 - 1, p.x < (cols.last?.1 ?? 0) + 1 else { return nil } }
        return signs.indices.min { abs((cols[signs[$0]].0 + cols[signs[$0]].1) / 2 - p.x) < abs((cols[signs[$1]].0 + cols[signs[$1]].1) / 2 - p.x) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let w = OrderOfOperations.working(s.numbers)
        guard let t = tapLine(stage(s)) else { return nil }
        func move(_ j: Int) -> HandMove { HandMove(hand: ["part": Double(j)], missHand: ["wrong": Double(j)], set: [("c", Double(j))], check: true) }
        return Hands(
            tap: { p in part(w, t, p, strict: true).map(move) },
            grab: { p in part(w, t, p, strict: true).map { ["grab": 1, "part": Double($0)] } },
            drag: { p, h in ["grab": 1, "part": part(w, t, p, strict: false).map(Double.init) ?? h["part"] ?? 0] },
            release: { h in move(Int(h["part"] ?? 0)) })
    }

    /// The ghost taps the right part's sign.
    func demo(_ s: PaperState) -> [GhostMove] {
        let w = OrderOfOperations.working(s.numbers)
        guard let t = tapLine(stage(s)) else { return [] }
        let line = w.lines[t], cols = Self.columns(line), sign = OrderOfOperations.Working.signs(line)[t == 0 ? w.first : w.next]
        return [.tap(.picture(CGPoint(x: (cols[sign].0 + cols[sign].1) / 2, y: Self.mid(t))))]
    }

    /// Screenshots only: the first wrong part tapped (left to right, as a child reading left to right would).
    func wrongMove(_ s: PaperState) -> HandMove? {
        let w = OrderOfOperations.working(s.numbers)
        guard let t = tapLine(stage(s)) else { return nil }
        let right = t == 0 ? w.first : w.next, j = right == 0 ? 1 : 0
        return HandMove(hand: ["part": Double(j)], missHand: ["wrong": Double(j)], set: [("c", Double(j))], check: true)
    }
}
