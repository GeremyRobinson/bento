import SwiftUI

/// What 3rd grade's chapter 6, Time and measuring, shares on the paper (the preview design/prototype/grade3-ch6.html): the
/// things drawn in Obento²'s line style (a key, a dog, a bucket… each in a box 10 squares wide and 8 tall, one shape tinted;
/// the preview's own drawings, read from their paths), choice blocks a word wide, hops up a line, and the measuring stories'
/// picture (MSP: the amounts as cells in rows of 10, slid in or away, dragged down into equal rows, or dealt into rows).
@MainActor
enum MS3 {
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)

    // MARK: things

    /// The preview's drawings: each path in squares of a 10 × 8 box, and whether it's the tinted shape.
    static let things: [String: [(String, Bool)]] = [
        "paper clip": [("M7.5 4.6H3A0.7 0.7 0 0 1 3 3.2H8.5A1.1 1.1 0 0 1 8.5 5.4H2A1.6 1.6 0 0 1 2 2.2H7.5", false)],
        "grape": [(cl(5, 4.8, 2.6), true), ("M5 2.2Q5.2 1.2 6.2 0.6", false)],
        "coin": [(cl(5, 4, 3.4), true), (cl(5, 4, 2.5), false)],
        "pencil": [("M0.5 3H7.5L9.6 4L7.5 5H0.5Z", true), ("M1.6 3V5M7.5 3V5", false)],
        "key": [(cl(2.6, 4, 2), true), (cl(2.6, 4, 0.7), false), ("M4.6 3.5H9.6V4.5H4.6", false), ("M8 4.5V5.8H8.8V4.5M6.6 4.5V5.4H7.3V4.5", false)],
        "dog": [("M2 3.6H7.4V6.2H2Z", true), (cl(8.4, 3, 1.4), false), ("M2.6 6.2V7.9M3.6 6.2V7.9M6 6.2V7.9M7 6.2V7.9M2 3.9L0.8 2.4M7.6 2L8 0.9L8.8 1.7", false)],
        "bag of flour": [("M2 7.9H8Q9.2 4.6 7 2.6H3Q0.8 4.6 2 7.9Z", true), ("M3 2.6L3.6 1.2H6.4L7 2.6M3.3 1.9H6.7", false)],
        "watermelon": [(ell(5, 4.6, 4.5, 3.1), true), ("M2.6 2.2Q3.6 4.6 2.6 7.1M5 1.5Q6 4.6 5 7.7M7.4 2.2Q8.4 4.6 7.4 7.1", false)],
        "bike": [(cl(2.3, 5.6, 2), false), (cl(7.7, 5.6, 2), false), ("M2.3 5.6L4.4 3L6.9 3L7.7 5.6M4.4 3L5.4 5.6L6.9 3M5.4 5.6L2.3 5.6M3.9 2H5M4.4 2V3M6.9 3L6.6 1.6H7.8", false)],
        "backpack": [("M2 2.4Q2 1.2 3.2 1.2H6.8Q8 1.2 8 2.4V7.9H2Z", true), ("M3.2 4.8H6.8V7H3.2ZM4 1.2Q4 0.2 5 0.2Q6 0.2 6 1.2", false)],
        "bottle": [("M3.6 7.9V3.4Q3.6 2.6 4.4 2.2V1H5.6V2.2Q6.4 2.6 6.4 3.4V7.9Z", true), ("M4.2 0.4H5.8V1H4.2Z", false)],
        "watering can": [("M2 3.4H6.6V7.9H2Z", true), ("M6.6 6.4L9.4 2.8M9 2.4L9.8 3.2M2.8 3.4Q4.3 0.8 5.8 3.4", false)],
        "bucket": [("M1.6 2.8H8.4L7.4 7.9H2.6Z", true), ("M1.6 2.8Q5 -0.6 8.4 2.8", false)],
        "sink": [("M0.4 3.4H9.6Q9.2 7.8 5 7.8Q0.8 7.8 0.4 3.4Z", true), ("M5 3.4V1.2H6.6V1.8", false)],
        "fish tank": [("M0.4 2.6H9.6V7.9H0.4Z", true), ("M0.4 1.4H9.6V7.9H0.4ZM3.4 5Q4.6 3.8 6 5Q4.6 6.2 3.4 5ZM6 5L6.8 4.4V5.6Z", false)],
        "bathtub": [("M0.4 3.6H9.6V5Q9.6 7.4 7.2 7.4H2.8Q0.4 7.4 0.4 5Z", true), ("M2.4 7.4L2 8M7.6 7.4L8 8M1.2 3.6V1.8H2.4", false)],
    ]
    /// A thing lower than its box sits on the box's floor, so it rests on a pan.
    static let bottom: [String: Double] = ["paper clip": 5.4, "key": 5.8, "pencil": 5, "coin": 7.4, "grape": 7.4]
    static func cl(_ cx: Double, _ cy: Double, _ r: Double) -> String { "M\(cx - r) \(cy)a\(r) \(r) 0 1 0 \(2 * r) 0a\(r) \(r) 0 1 0 \(-2 * r) 0Z" }
    static func ell(_ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double) -> String { "M\(cx - rx) \(cy)a\(rx) \(ry) 0 1 0 \(2 * rx) 0a\(rx) \(ry) 0 1 0 \(-2 * rx) 0Z" }

    /// An SVG path (M L H V Q A Z and their relative forms) as polylines, each with whether it's closed.
    static func parse(_ d: String) -> [([CGPoint], Bool)] {
        var toks: [String] = [], num = ""
        func flush() { if !num.isEmpty { toks.append(num); num = "" } }
        for ch in d {
            if ch.isLetter { flush(); toks.append(String(ch)) }
            else if ch == " " || ch == "," { flush() }
            else if ch == "-" { flush(); num = "-" }
            else if ch == "." && num.contains(".") { flush(); num = "." }
            else { num.append(ch) }
        }
        flush()
        var out: [([CGPoint], Bool)] = [], cur: [CGPoint] = [], p = CGPoint.zero, start = CGPoint.zero, cmd = "M", i = 0
        func n() -> Double { defer { i += 1 }; return i < toks.count ? Double(toks[i]) ?? 0 : 0 }
        func end(_ closed: Bool) { if cur.count > 1 { out.append((cur, closed)) }; cur = [] }
        while i < toks.count {
            if let c = toks[i].first, c.isLetter { cmd = toks[i]; i += 1; if cmd == "Z" || cmd == "z" { end(true); p = start; continue } }
            let rel = cmd == cmd.lowercased()
            switch cmd.uppercased() {
            case "M":
                end(false); let x = n(), y = n(); p = rel ? CGPoint(x: p.x + x, y: p.y + y) : CGPoint(x: x, y: y); start = p; cur = [p]
                cmd = rel ? "l" : "L"
            case "L": let x = n(), y = n(); p = rel ? CGPoint(x: p.x + x, y: p.y + y) : CGPoint(x: x, y: y); cur.append(p)
            case "H": let x = n(); p = CGPoint(x: rel ? p.x + x : x, y: p.y); cur.append(p)
            case "V": let y = n(); p = CGPoint(x: p.x, y: rel ? p.y + y : y); cur.append(p)
            case "Q":
                let cx = n(), cy = n(), x = n(), y = n()
                let c = rel ? CGPoint(x: p.x + cx, y: p.y + cy) : CGPoint(x: cx, y: cy), e = rel ? CGPoint(x: p.x + x, y: p.y + y) : CGPoint(x: x, y: y), s = p
                for k in 1...10 { let t = Double(k) / 10, u = 1 - t; cur.append(CGPoint(x: u * u * s.x + 2 * u * t * c.x + t * t * e.x, y: u * u * s.y + 2 * u * t * c.y + t * t * e.y)) }
                p = e
            case "A":
                let rx0 = n(), ry0 = n(); _ = n(); let large = n() != 0, sweep = n() != 0, x = n(), y = n()
                let e = rel ? CGPoint(x: p.x + x, y: p.y + y) : CGPoint(x: x, y: y)
                cur += arc(from: p, to: e, rx: rx0, ry: ry0, large: large, sweep: sweep)
                p = e
            default: i += 1
            }
        }
        end(false)
        return out
    }
    /// An SVG arc (no rotation) from a to b as points (the spec's endpoint to centre conversion).
    static func arc(from a: CGPoint, to b: CGPoint, rx rx0: Double, ry ry0: Double, large: Bool, sweep: Bool) -> [CGPoint] {
        var rx = abs(rx0), ry = abs(ry0)
        guard rx > 0, ry > 0 else { return [b] }
        let dx = (a.x - b.x) / 2, dy = (a.y - b.y) / 2
        let l = dx * dx / (rx * rx) + dy * dy / (ry * ry)
        if l > 1 { rx *= sqrt(l); ry *= sqrt(l) }
        let num = rx * rx * ry * ry - rx * rx * dy * dy - ry * ry * dx * dx, den = rx * rx * dy * dy + ry * ry * dx * dx
        var f = den > 0 ? sqrt(max(0, num / den)) : 0
        if large == sweep { f = -f }
        let cxp = f * rx * dy / ry, cyp = -f * ry * dx / rx
        let cx = cxp + (a.x + b.x) / 2, cy = cyp + (a.y + b.y) / 2
        func ang(_ ux: Double, _ uy: Double) -> Double { atan2(uy, ux) }
        let t1 = ang((dx - cxp) / rx, (dy - cyp) / ry)
        var dt = ang((-dx - cxp) / rx, (-dy - cyp) / ry) - t1
        if sweep && dt < 0 { dt += 2 * .pi }
        if !sweep && dt > 0 { dt -= 2 * .pi }
        let k = max(4, Int(abs(dt) / (.pi / 12)))
        return (1...k).map { i in let t = t1 + dt * Double(i) / Double(k); return CGPoint(x: cx + rx * cos(t), y: cy + ry * sin(t)) }
    }

    /// A thing drawn in its 10 × 8 box from (x, y), `k` times bigger: its tinted shape, its lines.
    static func thing(_ pen: inout GridPen, _ id: String, _ name: String, x: Double, y: Double, k: Double = 1) {
        guard let parts = things[name] else { return }
        let dy = 7.9 - (bottom[name] ?? 7.9)
        for (j, part) in parts.enumerated() {
            for (m, (pts, closed)) in parse(part.0).enumerated() {
                let q = pts.map { pen.P(x + $0.x * k, y + ($0.y + dy) * k) }
                if part.1 && closed { pen.sketch.polygon("\(id)\(j).\(m)f", q, .tint(0.2)) }
                pen.sketch.line("\(id)\(j).\(m)", closed ? q + [q[0]] : q, .ink, width: Sketch.stroke)
            }
        }
    }

    // MARK: choices

    /// A block's width for its word: the word and a square either side, whole squares.
    static func blockW(_ label: String) -> Double { (KK.width(label, KK.words) + 2).rounded(.up) }
    /// Blocks in a row from x0, each starting on the next block line after the one before and a `gap`.
    static func blockRow(_ labels: [String], x0: Double = 0, gap: Double = 2) -> [CGRect] {
        var x = x0, out: [CGRect] = []
        for l in labels { let w = blockW(l); out.append(CGRect(x: x, y: 0, width: w, height: 2)); x = EG2.ceil5(x + w + gap) }
        return out
    }
    /// A choice block w × 2 with its word centred: red when picked wrong, the chapter colour when right.
    static func pick(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, _ label: String, bad: Bool, on: Bool) {
        let c: Sketch.Colour = bad ? KK.red : on ? .chapter : .ink
        pen.sketch.box("\(id)o\(bad)\(on)", pen.R(x, y, w, 2), c, width: Sketch.stroke)
        pen.word("\(id)w\(bad)\(on)", label, at: x + w / 2, y + 1, KK.words.colour(c))
    }

    /// Hops up a line at column x from y0, `step` squares a hop, n of them, each counted beside its middle.
    static func vhops(_ pen: inout GridPen, _ id: String, x: Double, y0: Double, step: Double, n: Int) {
        guard n > 0 else { return }
        let h = min(4, step * 0.8)
        for i in 1...n {
            let a = y0 - Double(i - 1) * step, b = y0 - Double(i) * step
            pen.sketch.line("\(id)a\(i)", (0...12).map { k in let t = Double(k) / 12; return pen.P(x + sin(.pi * t) * h / 1.3, a + (b - a) * t) }, .chapter, width: Sketch.stroke)
            if step >= 2 { pen.word("\(id)n\(i)", "\(i)", at: x + h / 2 + 0.9, (a + b) / 2, KK.lit) }
        }
    }
    /// Hops along a line at row y from x0, `step` squares a hop, n of them, each counted over its middle.
    static func hhops(_ pen: inout GridPen, _ id: String, x0: Double, y: Double, step: Double, n: Int) {
        guard n > 0 else { return }
        let h = min(6, step * 0.8)
        for i in 1...n {
            let a = x0 + Double(i - 1) * step
            pen.hop("\(id)a\(i)", from: a, to: a + step, row: y, height: h)
            pen.word("\(id)n\(i)", "\(i)", at: a + step / 2, y - h - 0.9, KK.lit)
        }
    }
}

/// The measuring stories' picture (MStory3, the preview's dStory): the story on the top rows, then the amounts as cells in
/// rows of 10 (a cell is 10 g, 1 kg or 1 L; 3 squares, or 2 when 3 won't show at 75%). Pick what to do: four blocks under
/// the cells. + slides the second amount in after the first, − slides it over the end (what it covers is crossed out); ×
/// drags down equal rows; ÷ deals the pile into rows. The record beside the cells: `230 + 150 = [380] g`.
///
/// "at" 10 pick, 11 move, 12 write, 13 done. Hand: slide "grab", "px", "o0", "off"; rows "grab", "n"; share "grab", "k", "k0".
/// Kept: "op" a wrong sign picked.
@MainActor
struct MSP {
    let P: MStory3.Parts, rows: Int, c: Double
    /// The cells the slid amount lands on (column, row), and how far right it waits.
    let cells: [(Int, Int)], S: Int
    init(_ P: MStory3.Parts) {
        self.P = P
        rows = A2.storyRows([P.story], width: 52).count
        var cs: [(Int, Int)] = []
        for t in 0..<(P.op < 2 ? P.B : 0) {
            let i = P.op == 0 ? P.A + t : P.A - P.B + t
            cs.append((i % 10, i / 10))
        }
        cells = cs
        S = cs.isEmpty ? 0 : 11 - (cs.map(\.0).min() ?? 0)
        let tall: Int, wide: Int
        switch P.op {
        case 0: tall = (P.A + P.B + 9) / 10; wide = (cs.map(\.0).max() ?? 0) + S + 1
        case 1: tall = (P.A + 9) / 10; wide = (cs.map(\.0).max() ?? 0) + S + 1
        case 2: tall = G3.cap(P.a, 3); wide = P.b
        default: tall = max((P.A + 9) / 10, P.b); wide = 12 + 10
        }
        // 3 squares a cell when the cells, the slid amount waiting and the record beside them all fit 66 squares (75%)
        let recW = M7.width([.n(P.a), .op(P.o), .n(P.b), .op("="), .box("v", cells: max(2, String(P.ans).count)), .w(P.u)])
        func fits(_ c: Double) -> Bool {
            let SX = EG2.ceil5(10 * c + 4), done: Double
            switch P.op {
            case 2: done = EG2.ceil5(Double(P.b) * c + 3)
            case 3: done = EG2.ceil5(SX + Double(P.q) * c + 3)
            default: done = EG2.ceil5(Double(min(10, max(P.A, P.op == 0 ? P.A + P.B : 0))) * c + 3)
            }
            let moving = P.op == 3 ? SX + 10 * c : Double(wide) * c
            return Double(tall) * c <= 24 && moving <= 66 && done + recW <= 66
        }
        c = fits(3) ? 3 : 2
    }
    var Y0: Double { 2 * Double(rows) + 2 }
    var SX: Double { EG2.ceil5(10 * c + 4) }
    var pileRows: Int { P.op == 0 ? (P.A + P.B + 9) / 10 : (P.A + 9) / 10 }
    func at(_ col: Int, _ row: Int) -> CGPoint { CGPoint(x: Double(col) * c, y: Y0 + Double(row) * c) }
    /// How many of the slid cells cover the pile's places, `off` cells right of where they land.
    func covered(_ off: Int) -> Int {
        cells.filter { col, row in let x = col + off; return P.op == 0 ? x < 10 : x < 10 && row * 10 + x < P.A }.count
    }
    /// The record's place: a block right of the cells once they're done.
    var RX: Double {
        switch P.op {
        case 2: return EG2.ceil5(Double(P.b) * c + 3)
        case 3: return EG2.ceil5(SX + Double(P.q) * c + 3)
        default: return EG2.ceil5(Double(min(10, max(P.A, P.op == 0 ? P.A + P.B : 0))) * c + 3)
        }
    }
    var RY: Double { Y0 + 1 }
    func recToks(right: Bool) -> [M7.Tok] {
        [.n(P.a), .op(P.o), .n(P.b), .op("=")] + (right ? [.n(P.ans, .chapter), .w(P.u, .chapter)] : [.box("v", cells: max(2, String(P.ans).count)), .w(P.u)])
    }
    var picks: [CGRect] {
        var labels: [String] = []
        for i in 0..<4 { labels.append("\(MStory3.ops[i]) \(MStory3.opName[i])") }
        // under the cells, or in a column beside them when they're tall (so the problem shows at 75%)
        let h = Double(P.op == 2 ? 1 : pileRows) * c
        if h >= 12 {
            let x = EG2.ceil5(Double(min(10, P.op == 2 ? P.b : max(P.A, 1))) * c + 3), w = labels.map(MS3.blockW).max() ?? 10
            return labels.indices.map { CGRect(x: x, y: Y0 + 3 * Double($0), width: w, height: 2) }
        }
        let y = EG2.ceil5(Y0 + h + 2)
        return MS3.blockRow(labels).map { CGRect(x: $0.minX, y: y, width: $0.width, height: 2) }
    }

    func blocksAt(_ st: Int) -> CGPoint? { st >= 12 ? CGPoint(x: RX, y: RY + 2) : nil }

    func draw(_ s: PaperState, _ st: Int) -> PaperDrawing {
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, [P.story], width: 52)
        let moved = st >= 12, c = self.c, Y0 = self.Y0
        func cell(_ pen: inout GridPen, _ id: String, _ i: Int, tint: Bool = false, gone: Bool = false) {
            let p = at(i % 10, i / 10)
            if tint { pen.fill(id + "f", col: p.x, row: p.y, w: c, h: c, .tint(0.2)) }
            pen.sketch.box(id + "o", pen.R(p.x, p.y, c, c), .ink, width: Sketch.stroke)
            pen.dot("\(id)d\(gone)", at: p.x + c / 2, p.y + c / 2, radius: M3.dotR(c), gone ? .tint(0.4) : .chapter)
            if gone { M3.cross(&pen, id, cx: p.x + c / 2, cy: p.y + c / 2, c: c) }
        }
        var extent: CGRect?
        switch P.op {
        case 0, 1:
            for i in 0..<P.A { cell(&pic, "c\(i)", i, gone: P.op == 1 && moved && i >= P.A - P.B) }
            if P.op == 0 && moved { for i in P.A..<(P.A + P.B) { cell(&pic, "c\(i)", i, tint: true) } }
            if st == 11 {
                let off = Int((s.h("off") ?? Double(S)).rounded())
                var pen = s.grabbed ? live : pic
                for (t, cl) in cells.enumerated() {
                    let p = at(cl.0 + off, cl.1)
                    pen.fill("bk\(t)f", col: p.x, row: p.y, w: c, h: c, .tint(0.2))
                    pen.sketch.box("bk\(t)o", pen.R(p.x, p.y, c, c), .ink, width: Sketch.stroke)
                    pen.dot("bk\(t)d", at: p.x + c / 2, p.y + c / 2, radius: M3.dotR(c), over: true)
                }
                if s.grabbed {
                    let cov = covered(off)
                    pen.reads(P.op == 0 ? "\(Ms3.wc(P.a + cov * P.cv)) \(P.u)" : "\(Ms3.wc(P.a - cov * P.cv)) \(P.u) left")
                    live = pen
                } else { pic = pen }
                let r = at((cells.map(\.0).max() ?? 0) + S + 1, pileRows)
                extent = pic.R(0, Y0, r.x, r.y - Y0)
                let x0 = cells.map(\.0).min() ?? 0, x1 = cells.map(\.0).max() ?? 0, y0 = cells.map(\.1).min() ?? 0, y1 = cells.map(\.1).max() ?? 0
                if s.on("ring") || s.on("spot") { let p = at(x0, y0); KK.hintBox(&pic, "hs", x: p.x, y: p.y, w: Double(x1 - x0 + 1) * c, h: Double(y1 - y0 + 1) * c) }
                if s.on("spot") { for (t, cl) in cells.enumerated() { let p = at(cl.0, cl.1); pic.sketch.box("sps\(t)", pic.R(p.x, p.y, c, c), .chapter, width: Sketch.stroke, dashed: true) } }
            }
        case 2:
            let n = st == 10 ? 1 : moved ? P.a : Int((s.h("n") ?? 1).rounded()), B = Double(P.b) * c
            M3.array(&pic, "ar", x: 0, y: Y0, rows: n, cols: P.b, c: c, outline: false)
            for i in 0..<n { pic.sketch.box("rw\(i)", pic.R(0, Y0 + Double(i) * c, B, c), .ink, width: Sketch.stroke) }
            if st == 11 {
                M3.edge(&live, rows: true, x: 0, y: Y0, at: Y0 + Double(n) * c, span: B, held: s.grabbed)
                if s.grabbed { live.reads("\(Ms3.plural(n, P.groups.0, P.groups.1)) · \(n * P.b) \(P.u)") }
                extent = pic.R(0, Y0, B + 1, Double(G3.cap(P.a, Int(c))) * c + 1)
                if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hr", x: -0.5, y: Y0 + Double(max(1, P.a - 2)) * c, w: B + 1, h: 4 * c) }
                if s.on("spot") { pic.line("sp", [(-0.5, Y0 + Double(P.a) * c), (B + 0.5, Y0 + Double(P.a) * c)], .chapter, dashed: true) }
            }
        default:
            let k = st == 11 ? Int((s.h("k") ?? 0).rounded()) : moved ? P.q : 0
            for i in 0..<P.A {
                var p = CGPoint(x: (Double(i % 10) + 0.5) * c, y: Y0 + (Double(i / 10) + 0.5) * c)
                let e = P.A - 1 - i, j = e / P.b, r = e % P.b
                if st >= 11 && j < k { p = CGPoint(x: SX + (Double(j) + 0.5) * c, y: Y0 + (Double(r) + 0.5) * c) }
                pic.dot("d\(i)", at: p.x, p.y, radius: M3.dotR(c))
            }
            // the pile's places, faint (cleared away once it's all dealt)
            if !moved {
                var segs: [(CGPoint, CGPoint)] = []
                for i in 0..<P.A { let p = at(i % 10, i / 10); let r = pic.R(p.x, p.y, c, c); segs += [(r.origin, CGPoint(x: r.maxX, y: r.minY)), (CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY)), (CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)), (CGPoint(x: r.minX, y: r.maxY), r.origin)] }
                pic.sketch.segments("pl", segs, .ink3, width: 1)
            }
            if st >= 11 {
                DivFacts3Lesson.rows(&pic, &live, sx: SX, y: Y0, rows: P.b, k: k, done: moved, held: s.grabbed, c: c)
                if st == 11 {
                    if s.grabbed { let left = P.A - k * P.b; live.reads(left >= 0 ? "\(k) \(P.u) in each · \(left) \(P.u) left" : "\(k) \(P.u) in each · \(-left) \(P.u) missing") }
                    extent = pic.R(0, Y0, SX + 10 * c + 1, Double(max(pileRows, P.b)) * c)
                    if s.on("ring") || s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Y0, w: 10 * c, h: Double(pileRows) * c) }
                    if s.on("spot") { pic.line("sp", [(SX + Double(P.q) * c, Y0 - 0.5), (SX + Double(P.q) * c, Y0 + Double(P.b) * c + 0.5)], .chapter, dashed: true) }
                }
            }
        }
        // pick what to do: four blocks under the cells
        if st == 10 {
            let bad = s.run.kept["op"].map { Int($0) }
            for (i, r) in picks.enumerated() { MS3.pick(&pic, "op\(i)", x: r.minX, y: r.minY, w: r.width, "\(MStory3.ops[i]) \(MStory3.opName[i])", bad: bad == i, on: false) }
            if s.on("ring") && !s.on("spot") { let r = picks; KK.hintBox(&pic, "hp", x: r[0].minX - 0.5, y: r[0].minY - 0.5, w: r[3].maxX - r[0].minX + 1, h: r[3].maxY - r[0].minY + 1) }
            if s.on("spot") { let r = picks[P.op]; KK.hintBox(&pic, "hp2", x: r.minX - 0.5, y: r.minY - 0.5, w: r.width + 1, h: 3) }
        }
        // the record beside the cells
        if st == 12 { M7.row(&rec, "rec", recToks(right: false), x: RX, line: RY) }
        if st == 13 { M7.row(&pic, "rec", recToks(right: true), x: RX, line: RY) }
        if st == 12 && s.on("spot") { A1.note(&pic, "spot", "\(Ms3.wc(P.ans)) \(P.u)", x: RX, y: RY - 2.4) }
        if st >= 12 { let e = M7.width(recToks(right: false)); extent = pic.R(0, Y0, RX + e + 1, Double(max(pileRows, P.op == 3 ? P.b : P.op == 2 ? P.a : 0)) * c) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: extent)
    }

    func hands(_ s: PaperState, _ st: Int) -> Hands? {
        let c = self.c, Y0 = self.Y0
        if st == 10 {
            let r = picks
            return Hands(tap: { q in
                guard let i = r.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("o", Double(i))], keep: ["op": i == P.op ? -1 : Double(i)], check: true)
            })
        }
        guard st == 11 else { return nil }
        switch P.op {
        case 0, 1:
            let off = Int((s.h("off") ?? Double(S)).rounded())
            func on(_ q: CGPoint) -> Bool { cells.contains { cl in let p = at(cl.0 + off, cl.1); return q.x >= p.x - 0.5 && q.x <= p.x + c + 0.5 && q.y >= p.y - 0.5 && q.y <= p.y + c + 0.5 } }
            let S = self.S, cov = { (o: Int) in self.covered(o) }
            return Hands(
                grab: { q in on(q) ? ["grab": 1, "px": q.x, "o0": Double(off), "off": Double(off)] : nil },
                drag: { q, h in var h = h; h["off"] = Double(max(0, min(S + 1, Int(h["o0"] ?? 0) + Int(((q.x - (h["px"] ?? 0)) / c).rounded())))); return h },
                release: { h in
                    let o = Int((h["off"] ?? Double(S)).rounded()), k = cov(o)
                    if o == 0 { return HandMove(hand: ["off": 0], set: [("s", Double(MStory3.landed))], check: true) }
                    if k > 0 { return HandMove(hand: ["off": Double(o)], missHand: ["off": Double(S)], set: [("s", Double(k))], check: true) }
                    return HandMove(hand: ["off": Double(S)])
                })
        case 2:
            let n = Int((s.h("n") ?? 1).rounded()), B = Double(P.b) * c, cap = G3.cap(P.a, Int(c))
            return Hands(
                grab: { q in M3.onEdge(q, rows: true, x: 0, y: Y0, at: Y0 + Double(n) * c, span: B) ? ["grab": 1, "n": Double(n)] : nil },
                drag: { q, h in var h = h; h["n"] = Double(max(1, min(cap, Int(((q.y - Y0) / c).rounded())))); return h },
                release: { h in
                    let k = Int((h["n"] ?? 1).rounded())
                    guard k != 1 else { return HandMove(hand: ["n": 1]) }
                    return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("e", Double(k))], check: true)
                })
        default:
            return DivFacts3Lesson.shareHands(s, sx: SX, y: Y0, rows: P.b, q: P.q, box: "k", c: c)
        }
    }

    func demo(_ s: PaperState, _ st: Int) -> [GhostMove] {
        let c = self.c, Y0 = self.Y0
        if st == 10 { let r = picks[P.op]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] }
        guard st == 11 else { return [] }
        switch P.op {
        case 0, 1:
            guard let first = cells.first else { return [] }
            let off = Int((s.h("off") ?? Double(S)).rounded()), a = at(first.0 + off, first.1), b = at(first.0, first.1)
            return [.drag(from: CGPoint(x: a.x + c / 2, y: a.y + c / 2), to: CGPoint(x: b.x + c / 2, y: b.y + c / 2))]
        case 2:
            let n = Double(Int((s.h("n") ?? 1).rounded())), x = Double(P.b) * c / 2
            return [.drag(from: CGPoint(x: x, y: Y0 + n * c), to: CGPoint(x: x, y: Y0 + Double(P.a) * c))]
        default:
            let k = Double(Int((s.h("k") ?? 0).rounded())), y = Y0 + Double(P.b) * c / 2
            return [.drag(from: CGPoint(x: SX + k * c, y: y), to: CGPoint(x: SX + Double(P.q) * c, y: y))]
        }
    }

    func wrongMove(_ st: Int) -> HandMove? {
        if st == 10 { let i = (P.op + 1) % 4; return HandMove(hand: nil, missHand: nil, set: [("o", Double(i))], keep: ["op": Double(i)], check: true) }
        guard st == 11 else { return nil }
        switch P.op {
        case 0, 1: let k = max(1, covered(1)); return HandMove(hand: ["off": 1], missHand: ["off": Double(S)], set: [("s", Double(k))], check: true)
        case 2: let k = P.a + 1; return HandMove(hand: ["n": Double(k)], missHand: ["n": 1], set: [("e", Double(k))], check: true)
        default: let n = min(10, P.q + 1); return HandMove(hand: ["k": Double(n)], missHand: ["k": 0], set: [("k", Double(n))], check: true)
        }
    }
    func wrongTyping(_ st: Int) -> [String: Double]? { st == 12 ? ["v": Double(P.solveSlips.first?.0 ?? P.a)] : nil }
}
