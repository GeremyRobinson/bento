import SwiftUI

/// Hundreds, tens and ones on the paper, as in the preview (design/prototype/grade2-ch2.html, dHundreds): one square is
/// one. Three place columns, their names over them: hundreds (flats 10 × 10 in rows of three, a square apart), tens
/// (strips 1 × 10 a square apart), ones (two columns of five). Tap the column to put the next piece in (a dashed place
/// waits after the last; the last drags back out), Check; the column rings as it's counted. A tenth ten (or one) slides
/// together into a hundred (a ten) and the line says so. Then the record under the tens and ones, `347 = [300] + [40] + [7]`.
/// The record sits 6 squares under the pieces, so a miss written over it with the keys up clears them.
/// The number is written once, in the record from the start (its digit being built ringed, its column's name lit), so
/// the columns start on the top rows and nine hundreds still show at 75%; a number told in words is written there in words
/// (`six hundred five = [605]`, said as the problem opens), and a name to write ends with word blocks under the record.
///
/// Hand: "grab", "gx", "gy", "dx", "dy" the last piece dragged. Kept: "k0" "k1" "k2" the pieces in each column, "tog" 1 the
/// ten tens slid together (2 the ten ones), "wr" the words written, "bad" the word block tapped wrong.
@MainActor
struct Hundreds2Lesson: PaperLesson {
    static let PY = 2.0, TX = 35.0, OX = 55.0, RX = 35.0
    static let RY = PY + 16
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { Self.RY }
    func blocksLeft(_ n: Numbers) -> Double? { Self.RX }
    func told(_ s: PaperState) -> String? { let P = Hundreds2.Parts(s.numbers); return P.read ? P.name : nil }

    /// The flats' rows: 11 squares apart, or touching when seven or more could be in (so nine show at 75%).
    private static func rowH(_ P: Hundreds2.Parts) -> Double { P.D[0] >= 7 ? 10 : 11 }
    private static func spot(_ P: Hundreds2.Parts, _ c: Int, _ k: Int) -> CGRect {
        switch c {
        case 0: return CGRect(x: 11 * Double(k % 3), y: PY + rowH(P) * Double(k / 3), width: 10, height: 10)
        case 1: return CGRect(x: TX + 2 * Double(k), y: PY, width: 1, height: 10)
        default: return CGRect(x: OX + 2 * Double(k / 5), y: PY + 2 * Double(k % 5), width: 1, height: 1)
        }
    }
    private static let most = [9, 9, 9]
    /// A column's room: the whole of its pieces' places.
    private static func column(_ P: Hundreds2.Parts, _ c: Int, _ k: Int) -> CGRect {
        switch c {
        case 0: let rows = Double(max(1, (k + 2) / 3)); return CGRect(x: 0, y: PY, width: 32, height: rowH(P) * rows - (rowH(P) - 10))
        case 1: return CGRect(x: TX, y: PY, width: 19, height: 10)
        default: return CGRect(x: OX, y: PY, width: 3, height: 9)
        }
    }

    /// How many pieces each column shows.
    private func counts(_ s: PaperState) -> [Int] {
        let P = Hundreds2.Parts(s.numbers), st = at(s)
        return (0..<3).map { c in c < st ? P.D[c] : c == st ? Int(s.run.kept["k\(c)"] ?? 0) : 0 }
    }
    private func tog(_ s: PaperState) -> Int { at(s) <= 2 ? Int(s.run.kept["tog"] ?? 0) : 0 }

    func say(_ s: PaperState) -> String? {
        let t = tog(s), P = Hundreds2.Parts(s.numbers)
        return t != 0 && t == at(s) ? P.together(t) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Hundreds2.Parts(s.numbers), st = at(s), K = counts(s), T = tog(s), PY = Self.PY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && st <= 2, dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        for c in 0..<3 {
            let k = K[c]
            // its name over what's built (or waits), lit while it's the one being built
            let m = max(1, k + (c == st ? 1 : 0))
            let cx = c == 0 ? (Double(min(3, m)) * 11 - 1) / 2 : c == 1 ? Self.TX + (2 * Double(min(10, m)) - 1) / 2 : Self.OX + (m > 5 ? 1.5 : 0.5)
            pic.label("nm\(c)", Num2.place[c], c == st ? KK.lit : N2.small, .above, edge: PY - 0.5, along: cx)
            for j in 0..<k {
                var r = Self.spot(P, c, j)
                if T == c && c == 1 { r.origin.x = Self.TX + Double(j) }
                if T == c && c == 2 { r = CGRect(x: Self.OX + 1, y: PY + Double(j), width: 1, height: 1) }
                if held && c == st && j == k - 1 { N2.piece(&live, "p\(c).\(j)", x: r.minX + dx, y: r.minY + dy, w: r.width, h: r.height) }
                else { N2.piece(&pic, "p\(c).\(j)", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            }
            // a tenth slid in with them: ten of them, one piece of the next place
            if T != 0 && T == c {
                let r = c == 1 ? CGRect(x: Self.TX + 9, y: PY, width: 1, height: 10) : CGRect(x: Self.OX + 1, y: PY + 9, width: 1, height: 1)
                N2.piece(&pic, "p\(c).9", x: r.minX, y: r.minY, w: r.width, h: r.height)
                pic.sketch.box("tog\(c)", c == 1 ? pic.R(Self.TX, PY, 10, 10) : pic.R(Self.OX + 1, PY, 1, 10), .chapter, width: 3)
            }
            if (c == st || (c > st && k == 0)) && k < Self.most[c] && T == 0 { let r = Self.spot(P, c, k); N2.place(&pic, "dp\(c).\(k)", x: r.minX, y: r.minY, w: r.width, h: r.height) }
            // counted: the column rings
            if (c < st || st >= 3) && k > 0 {
                let w = c == 0 ? Double(min(3, k)) * 11 - 1 : c == 1 ? 2 * Double(k) - 1 : (k > 5 ? 3 : 1)
                let h = c == 0 ? Self.rowH(P) * Double((k + 2) / 3) - (Self.rowH(P) - 10) : c == 1 ? 10 : 2 * Double(min(5, k)) - 1
                pic.sketch.box("ring\(c)", pic.R(Self.spot(P, c, 0).minX - 0.5, PY - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke)
            }
        }
        // hints: a first miss rings the column, a second shows the places the pieces go
        if st <= 2 {
            if ring { let r = Self.column(P, st, max(K[st], 1)); KK.hintBox(&pic, "hr\(st)", x: r.minX, y: r.minY, w: r.width, h: min(r.height, 32 - PY)) }
            if spot { for j in K[st]..<max(K[st], P.D[st]) { let r = Self.spot(P, st, j); pic.sketch.box("sp\(j)", pic.R(r.minX, r.minY, r.width, r.height), .chapter, width: Sketch.stroke, dashed: true) } }
        }
        if held { live.reads(st == 2 ? "\(K[2])" : "\(K[st] * [100, 10, 1][st])") }

        // the record, under the tens and ones: the number from the start, then what each part is worth
        let RX = Self.RX, done = st > 3
        if P.read {
            let toks: [M7.Tok] = [.w(P.name)] + (st >= 3 ? [.op("=")] + (done ? [.n(P.n, .chapter)] : [.box("x", cells: 3)]) : [])
            M7.row(&rec, "rec", toks, x: RX, line: 1)
            if st == 3 && spot { A1.note(&rec, "spot", "\(P.n)", x: RX, y: 3.5) }
        } else {
            let D = P.D, parts = [D[0] * 100, D[1] * 10, D[2]]
            var toks: [M7.Tok] = []
            N2.number(&rec, "num", P.n, x: RX, row: 1) { st <= 2 && $0 == st ? .chapter : .ink }
            if st >= 3 {
                for (i, v) in parts.enumerated() { toks += (i == 0 ? [.op("=")] : [.op("+")]) + [done ? .n(v, .chapter) : .box("e\(i)", cells: 3 - i)] }
            }
            if !toks.isEmpty { M7.row(&rec, "rec", toks, x: RX + Record.width(.n(P.n)), line: 1) }
            if st <= 2 { N2.ringDigit(&rec, "rg\(st)", P.n, st, x: RX, row: 1) }
            if st == 3 && ring { KK.hintBox(&rec, "hr", x: RX, y: 0, w: Record.width(.n(P.n)), h: 2) }
            if st == 3 && spot { A1.note(&rec, "spot", "\(parts[0]) + \(parts[1]) + \(parts[2])", x: RX, y: 3.5) }
        }
        // its name from word blocks: 605 = six hundred five, a word at a time
        if P.named == 2 && st >= 4 {
            let wrote = st == 4 ? Int(s.run.kept["wr"] ?? 0) : P.need.count
            var toks: [M7.Tok] = [.n(P.n), .op("=")]
            if wrote > 0 { toks.append(.w(Num2.joined(Array(P.need.prefix(wrote))), .chapter)) }
            M7.row(&rec, "wrec", toks, x: RX, line: 4)
            if st == 4 {
                let r = Self.blockRects(P)
                let bad = s.run.kept["bad"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }
                let next = wrote < P.need.count ? P.blocks.firstIndex(of: P.need[wrote]) : nil
                KS.blocks(&rec, "wb", P.blocks, r, wrong: bad, spot: spot ? next : nil)
                if ring, let u = r.dropFirst().reduce(r.first, { $0?.union($1) }) { KK.hintBox(&rec, "wbr", x: u.minX, y: u.minY, w: u.width, h: u.height) }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: st <= 2 ? ["Check"] : [])
    }

    /// The word blocks under the record (in its squares), wrapping at 25 squares, 4 tall, a square apart.
    static func blockRects(_ P: Hundreds2.Parts) -> [CGRect] {
        var x = RX, y = 6.0, out: [CGRect] = []
        for w in P.blocks {
            let bw = (KK.width(w, KK.words) + 2).rounded(.up)
            if x + bw > RX + 25 { x = RX; y += 5 }
            out.append(CGRect(x: x, y: y, width: bw, height: 4)); x += bw + 1
        }
        return out
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Hundreds2.Parts(s.numbers), st = at(s), K = counts(s), T = tog(s)
        let box = ["h", "t", "o"]
        if st <= 2 {
            let k = K[st]
            func colAt(_ q: CGPoint) -> Int? {
                (0..<3).first { c in Self.column(P, c, max(K[c], c == 0 ? 9 : 1)).insetBy(dx: -0.6, dy: -0.6).contains(q) }
            }
            func tapped(_ q: CGPoint) -> HandMove? {
                guard let c = colAt(q) else { return nil }
                if c > st { return HandMove(hand: nil, missHand: nil, set: [(box[st], -1)], check: true) }
                guard c == st else { return nil }
                if T != 0 { return HandMove(hand: nil, keep: ["tog": 0]) }
                if k >= Self.most[c] { return c == 0 ? nil : HandMove(hand: nil, keep: ["tog": Double(c)]) }
                return HandMove(hand: nil, keep: ["k\(c)": Double(k + 1)])
            }
            return Hands(
                tap: tapped,
                grab: { q in
                    guard k > 0, T == 0, Self.spot(P, st, k - 1).insetBy(dx: -0.6, dy: -0.6).contains(q) else { return nil }
                    return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                },
                drag: { q, held in var h = held; h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h },
                release: { held in
                    let dx = held["dx"] ?? 0, dy = held["dy"] ?? 0
                    if hypot(dx, dy) < 0.5 { var m = tapped(CGPoint(x: held["gx"] ?? 0, y: held["gy"] ?? 0)) ?? HandMove(hand: [:]); m.hand = [:]; return m }
                    let r = Self.spot(P, st, k - 1), c = CGPoint(x: r.midX + dx, y: r.midY + dy)
                    if !Self.column(P, st, k).insetBy(dx: -1, dy: -1).contains(c) { return HandMove(hand: [:], keep: ["k\(st)": Double(k - 1)]) }
                    return HandMove(hand: [:])
                },
                actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [(box[st], Double(k))], keep: ["tog": 0], check: true) }])
        }
        guard st == 4, P.named == 2 else { return nil }
        let r = Self.blockRects(P), wrote = Int(s.run.kept["wr"] ?? 0)
        return Hands(tap: { q in
            let p = CGPoint(x: q.x, y: q.y - Self.RY)
            guard let j = KS.hit(p, r), wrote < P.need.count else { return nil }
            if P.blocks[j] == P.need[wrote] {
                let all = wrote + 1 == P.need.count
                return HandMove(hand: nil, missHand: nil, set: all ? [("w", 1)] : [], keep: ["wr": Double(wrote + 1), "bad": -1], check: all)
            }
            return HandMove(hand: nil, missHand: nil, set: [("w", Double(-1 - j - 10 * wrote))], keep: ["bad": Double(j)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Hundreds2.Parts(s.numbers), st = at(s), K = counts(s)
        if st <= 2 {
            let k = K[st], want = P.D[st]
            var out: [GhostMove] = []
            if tog(s) != 0 { let r = Self.spot(P, st, 0); out.append(.tap(.picture(CGPoint(x: r.midX, y: r.midY)))) }
            if k < want { for j in k..<want { let r = Self.spot(P, st, j); out.append(.tap(.picture(CGPoint(x: r.midX, y: r.midY)))) } }
            else if k > want { for j in stride(from: k - 1, through: want, by: -1) { let r = Self.spot(P, st, j); out.append(.drag(from: CGPoint(x: r.midX, y: r.midY), to: CGPoint(x: r.midX, y: Self.PY + 16))) } }
            return out + [.tap(.action("Check"))]
        }
        guard st == 4 else { return [] }
        let r = Self.blockRects(P), wrote = Int(s.run.kept["wr"] ?? 0)
        return P.need.dropFirst(wrote).compactMap { w in P.blocks.firstIndex(of: w).map { .tap(.picture(CGPoint(x: r[$0].midX, y: r[$0].midY + Self.RY))) } }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Hundreds2.Parts(s.numbers), st = at(s)
        if st <= 2 {
            let k = P.D[st] < 9 ? P.D[st] + 1 : P.D[st] - 1
            return HandMove(hand: nil, missHand: nil, set: [(["h", "t", "o"][st], Double(k))], keep: ["k\(st)": Double(k)], check: true)
        }
        guard st == 4, let j = P.blocks.firstIndex(where: { $0 != P.need[0] }) else { return nil }
        return HandMove(hand: nil, missHand: nil, set: [("w", Double(-1 - j))], keep: ["bad": Double(j)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Hundreds2.Parts(s.numbers)
        guard at(s) == 3 else { return nil }
        return P.read ? ["x": Double(P.n + 10)] : ["e0": Double(P.D[0]), "e1": Double(P.D[1]), "e2": Double(P.D[2])]
    }
}
