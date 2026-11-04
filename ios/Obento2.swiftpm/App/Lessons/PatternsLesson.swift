import SwiftUI

/// Number and shape patterns on the paper, as in the preview (design/prototype/grade4-ch3.html).
///
/// A number rule: a number line one square a one, 0 to 60, a strong tick and its number every 5, the start ringed.
/// Drag each hop out from the last number: it snaps a square at a time, live "+3 = 4", and the number lands over it;
/// five hops. Tap the odd numbers: each is ringed. Then tap Odd or Even for a far number.
///
/// A shape rule: shapes 1–3 side by side, each one's new squares tinted. Tap squares to build shape 4 in its place (the
/// count live), and Check. Under the shapes, shape 1's squares lie in a row with the new squares of each shape after
/// it: drag out copies, live "shape 7: 3 + 6 × 2 = 15", to the shape asked about; then write its squares.
@MainActor
struct PatternsLesson: PaperLesson {
    /// The number line's row, the numbers' row over it.
    static let ly = 5.0, ny = 2.0
    var liveKeys: Set<String> { ["grab", "len"] }
    static let oddEven = ["Odd", "Even"]
    private static let tick = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let landed = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing { Patterns.Parts(s.numbers).isShape ? drawShapes(s) : drawNumbers(s) }
    func hands(_ s: PaperState) -> Hands? { Patterns.Parts(s.numbers).isShape ? shapeHands(s) : numberHands(s) }
    func messageRows(_ n: Numbers) -> Int { 1 }
    func recordRow(_ n: Numbers) -> Double? {
        let P = Patterns.Parts(n)
        return P.isShape ? Shape(P).yr + 4 : Self.ly + 4
    }

    // MARK: a number rule

    /// How many numbers have landed (1: the start).
    private func landedCount(_ s: PaperState) -> Int { stage(s) >= 2 ? 6 : Int((s.h("n") ?? 1).rounded()) }
    private func ringed(_ s: PaperState, _ P: Patterns.Parts) -> Set<Int> {
        stage(s) >= 3 ? Set(P.want) : Set(P.vals.filter { (s.h("r\($0)") ?? 0) != 0 })
    }
    private func ringR(_ v: Int) -> Double { v >= 10 ? 1.25 : 1 }
    private func choicesTop(_ n: Numbers) -> Double { (recordRow(n) ?? 0) + 6 }

    private func drawNumbers(_ s: PaperState) -> PaperDrawing {
        let P = Patterns.Parts(s.numbers), at = stage(s), d = P.d, vals = P.vals, ly = Self.ly, ny = Self.ny
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // the line, 0 to 60, a strong tick and its number every 5
        pic.line("nl", [(0, ly), (60, ly)], .ink)
        var minor: [(CGPoint, CGPoint)] = [], major: [(CGPoint, CGPoint)] = []
        for x in 0...60 {
            let big = x % 5 == 0, h = big ? 0.5 : 0.25
            let seg = (pic.P(Double(x), ly - h), pic.P(Double(x), ly + h))
            if big { major.append(seg) } else { minor.append(seg) }
            if big { pic.word("tn\(x)", "\(x)", at: Double(x), ly + 1.4, Self.tick) }
        }
        pic.sketch.segments("tkm", minor, .ink3, width: Sketch.stroke)
        pic.sketch.segments("tkM", major, .ink, width: Sketch.stroke)
        // the numbers landed, the hops between them
        let k = landedCount(s)
        for j in 0..<k {
            pic.word("nv\(j)", "\(vals[j])", at: Double(vals[j]), ny, j == 0 ? Squares.named : Self.landed)
            if j > 0 { pic.line("nh\(j)", arc(Double(vals[j - 1]), Double(vals[j])), .chapter) }
        }
        if at <= 1 {
            let r = ringR(P.s)
            pic.ring("start", col: Double(P.s) - r, row: ny - r, w: 2 * r, h: 2 * r, .ink)
        }
        if at == 1 {
            let last = Double(vals[k - 1]), len = Int((s.h("len") ?? 0).rounded())
            if len > 0 { live.line("hl", arc(last, last + Double(len)), .chapter) }
            Squares.handle(&live, s, at: last + Double(len), ly)
            if s.grabbed && len > 0 { live.reads("+\(len) = \(vals[k - 1] + len)") }
            // a hint: where the next number lands, dashed
            if s.on("ring"), k < 6 { pic.line("ring", [(Double(vals[k]), ly - 1.5), (Double(vals[k]), ly + 1)], .chapter, dashed: true) }
        }
        let rg = ringed(s, P)
        for v in rg.sorted() { let r = ringR(v); pic.ring("rg\(v)", col: Double(v) - r, row: ny - r, w: 2 * r, h: 2 * r) }
        // a hint while tapping: the next one to ring, dashed
        if at == 2, s.on("ring"), let v = P.want.first(where: { !rg.contains($0) }) { pic.circle("ring", at: Double(v), ny, radius: ringR(v) + 0.3, .chapter, dashed: true) }

        // the record: the numbers (the ones to tap ringed), odd and even in words, the choice, the far number
        if at >= 2 {
            Squares.list(&rec, "rl", vals, x: 0, y: 1, ringed: rg, tail: "…")
            if at >= 3 {
                Record.line(&rec, "rw", [.w(vals.map { $0 % 2 == 1 ? "odd" : "even" }.joined(separator: ", ") + ", …")], x: -0.5, row: 4)
            }
            if at == 3 { Squares.choices(&rec, "oe", Self.oddEven, x: 0, y: 6, bad: s.h("bad").map { Int($0.rounded()) }) }
            if at >= 4 { Record.line(&rec, "ra", [.w("the \(Patterns.ord(P.k)) number is \(P.answerWord)")], x: -0.5, row: 7, colours: [0: .chapter]) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch,
                            extent: pic.R(0, 0, 61, ly + 2))
    }

    /// A hop from a to b over the line, rising 1.5 squares.
    private func arc(_ a: Double, _ b: Double) -> [(Double, Double)] {
        (0...16).map { i in let u = Double(i) / 16; return (a + (b - a) * u, Self.ly - sin(.pi * u) * 1.5) }
    }

    private func numberHands(_ s: PaperState) -> Hands? {
        let P = Patterns.Parts(s.numbers), vals = P.vals, ly = Self.ly, ny = Self.ny
        switch stage(s) {
        case 1:
            let k = landedCount(s), last = vals[k - 1], base = s.hand
            return Hands(
                grab: { q in
                    guard abs(q.x - Double(last)) <= 1.5, abs(q.y - ly) <= 2 else { return nil }
                    var h = base; h["grab"] = 1; h["len"] = 0; return h
                },
                drag: { q, h in
                    var h = h
                    h["len"] = Double(max(0, min(15, 60 - last, Int((q.x - Double(last)).rounded()))))
                    return h
                },
                release: { h in
                    var out = h; out["grab"] = nil; out["len"] = nil
                    let len = Int((h["len"] ?? 0).rounded())
                    guard len > 0 else { return HandMove(hand: out, missHand: nil) }
                    // a wrong hop is said and goes; a right one lands its number (the fifth answers the step)
                    if len != P.d { return HandMove(hand: out, missHand: nil, set: [("x", Double(len))], check: true) }
                    out["n"] = Double(k + 1)
                    return HandMove(hand: out, missHand: nil, set: k + 1 == 6 ? [("x", Double(len))] : [], check: k + 1 == 6)
                })
        case 2:
            let base = s.hand
            return Hands(tap: { q in
                guard q.y >= ny - 1.6, q.y <= ly + 0.8 else { return nil }
                let reach = max(0.9, min(Double(P.d) / 2, 1.5))
                guard let v = vals.min(by: { abs(Double($0) - q.x) < abs(Double($1) - q.x) }), abs(Double(v) - q.x) <= reach else { return nil }
                if v % 2 != P.target { return HandMove(hand: base, missHand: nil, set: [("x", Double(1000 + v))], check: true) }
                var h = base; h["r\(v)"] = 1
                let all = P.want.allSatisfy { (h["r\($0)"] ?? 0) != 0 }
                return HandMove(hand: h, missHand: nil, set: all ? [("x", 1)] : [], check: all)
            })
        case 3:
            let top = choicesTop(s.numbers)
            return Hands(tap: { q in
                guard let i = Squares.choice(at: q, Self.oddEven, x: 0, y: top) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    // MARK: a shape rule

    /// Where the shapes go: each one's left edge (a block apart), the bottom they stand on, the row of copies.
    @MainActor struct Shape {
        let P: Patterns.Parts, C: [[(x: Int, y: Int, g: Int)]], S: [(w: Int, h: Int)], sx: [Double], yb: Double, yr: Double, bw: Int, bh: Int
        init(_ P: Patterns.Parts) {
            self.P = P
            C = (1...4).map { P.cells($0) }; S = (1...4).map { P.size($0) }
            var x = [0.0]
            for k in 1..<4 { x.append(((x[k - 1] + Double(S[k - 1].w) + 3) / 5).rounded(.up) * 5) }
            sx = x
            yb = Double(S[3].h) + 1; yr = yb + 4
            bw = S[3].w + 2; bh = S[3].h + 2
        }
        /// The square under q in shape 4's place, from its bottom-left going up (nil: outside it).
        func spot(_ q: CGPoint) -> (x: Int, y: Int)? {
            let x = Int((q.x - sx[3]).rounded(.down)), y = Int((yb - q.y).rounded(.down))
            return x >= 0 && x < bw && y >= 0 && y < bh ? (x, y) : nil
        }
    }
    private func added(_ s: PaperState, _ sh: Shape) -> [(x: Int, y: Int)] {
        var out: [(x: Int, y: Int)] = []
        for x in 0..<sh.bw { for y in 0..<sh.bh where (s.h("a\(x)_\(y)") ?? 0) != 0 { out.append((x, y)) } }
        return out
    }
    private func copies(_ s: PaperState, _ P: Patterns.Parts) -> Int { stage(s) >= 3 ? P.q - 1 : Int((s.h("c") ?? 3).rounded()) }

    private func drawShapes(_ s: PaperState) -> PaperDrawing {
        let P = Patterns.Parts(s.numbers), sh = Shape(P), at = stage(s), build = at <= 1, f = P.f, d = P.d
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // shapes 1–3 (and 4 once built) side by side, the newest squares tinted
        for k in 0..<4 {
            if k == 3 && build { continue }
            for c in sh.C[k] { Squares.cell(&pic, "s\(k)_\(c.x)_\(c.y)", sh.sx[k] + Double(c.x), sh.yb - 1 - Double(c.y), fill: c.g == k && k > 0 ? .tint(0.2) : .paper) }
            pic.word("sl\(k)", "shape \(k + 1)", at: sh.sx[k] + Double(sh.S[k].w) / 2, sh.yb + 1, Squares.small)
        }
        // shape 4 being built in its place: shape 3's squares, and the ones tapped in
        if build {
            for c in sh.C[2] { Squares.cell(&pic, "s3_\(c.x)_\(c.y)", sh.sx[3] + Double(c.x), sh.yb - 1 - Double(c.y), fill: .paper) }
            let add = added(s, sh)
            for a in add { Squares.cell(&pic, "s3_\(a.x)_\(a.y)", sh.sx[3] + Double(a.x), sh.yb - 1 - Double(a.y)) }
            pic.word("sl3", "shape 4", at: sh.sx[3] + Double(sh.S[2].w) / 2, sh.yb + 1, Squares.small)
            if at == 1 {
                let n = sh.C[2].count + add.count
                live.reads("\(n) squares")
                // a hint: where shape 4's new squares go, dashed
                if s.on("ring") {
                    for c in sh.C[3] where c.g == 3 { Squares.dashed(&pic, "ring\(c.x)_\(c.y)", sh.sx[3] + Double(c.x), sh.yb - 1 - Double(c.y), .chapter) }
                }
            }
        }
        // the row of copies: shape 1's squares, then the new squares of each shape after it, numbered by their shape
        if !build {
            let c = copies(s, P), yr = sh.yr
            for i in 0..<f { Squares.cell(&pic, "cr\(i)", Double(i), yr, fill: .paper) }
            pic.word("cn0", "1", at: Double(f) / 2, yr + 2, Squares.small)
            for j in 0..<c {
                let moving = at == 2 && j >= 3
                for i in 0..<d {
                    let x = Double(f + j * d + i)
                    if moving { Squares.cell(&live, "cc\(j)_\(i)", x, yr, fill: j % 2 == 1 ? .tint(0.4) : .tint(0.2)) }
                    else { Squares.cell(&pic, "cc\(j)_\(i)", x, yr, fill: j % 2 == 1 ? .tint(0.4) : .tint(0.2)) }
                }
                if moving { live.word("cn\(j + 1)", "\(j + 2)", at: Double(f + j * d) + Double(d) / 2, yr + 2, Squares.count) }
                else { pic.word("cn\(j + 1)", "\(j + 2)", at: Double(f + j * d) + Double(d) / 2, yr + 2, Squares.count) }
            }
            if at == 2 {
                Squares.handle(&live, s, at: Double(f + c * d), yr + 0.5)
                if s.grabbed { live.reads("shape \(c + 1): \(f) + \(c) × \(d) = \(f + c * d)") }
                if s.on("ring") { let x = Double(f + (P.q - 1) * d); pic.line("ring", [(x, yr - 1), (x, yr + 2)], .chapter, dashed: true) }
            }
        }
        // the record: the counts, then shape q's, then how it's made
        var boxes: [WorkBox] = []
        if !build {
            Squares.list(&rec, "rl", (1...4).map { P.count($0) }, x: 0, y: 1, tail: "…")
            if at >= 3 {
                Record.line(&rec, "rq", [.w("shape"), .n(P.q), .op("="), at == 3 ? .box("x", cells: String(P.ans).count) : .n(P.ans), .w("squares")], x: 0, row: 4,
                            colours: at >= 4 ? [3: .chapter] : [:])
            }
            if at >= 4 { Record.line(&rec, "rs", [.n(f), .op("+"), .n(P.q - 1), .op("×"), .n(d), .op("="), .n(P.ans)], x: 0, row: 7) }
            boxes = rec.boxes
        }
        let wide = max(sh.sx[3] + Double(sh.bw), Double(f + (P.q + 2) * d) + 1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes,
                            actions: at == 1 ? ["Check"] : [],
                            extent: at <= 2 ? pic.R(0, 0, wide, build ? sh.yb + 2 : sh.yr + 2.5) : nil)
    }

    private func shapeHands(_ s: PaperState) -> Hands? {
        let P = Patterns.Parts(s.numbers), sh = Shape(P), base = s.hand
        switch stage(s) {
        case 1:
            let pre = Set(sh.C[2].map { "\($0.x)_\($0.y)" })
            return Hands(
                tap: { q in
                    guard let p = sh.spot(q) else { return nil }
                    let key = "\(p.x)_\(p.y)"
                    if pre.contains(key) { return HandMove(hand: base, missHand: nil) }
                    var h = base; h["a" + key] = (h["a" + key] ?? 0) != 0 ? nil : 1
                    return HandMove(hand: h, missHand: nil)
                },
                actions: ["Check": {
                    let n = sh.C[2].count + base.keys.filter { $0.hasPrefix("a") && (base[$0] ?? 0) != 0 }.count
                    return HandMove(hand: base, missHand: nil, set: [("x", Double(n))], check: true)
                }])
        case 2:
            let c = copies(s, P), hd = CGPoint(x: Double(P.f + c * P.d), y: sh.yr + 0.5)
            return Hands(
                grab: { q in abs(q.x - hd.x) <= 2 && abs(q.y - hd.y) <= 2 ? ["grab": 1, "c": Double(c), "c0": Double(c), "gx": q.x] : nil },
                drag: { q, h in
                    var h = h
                    h["c"] = Double(max(1, min(P.q + 1, Int(h["c0"] ?? 3) + Int(((q.x - (h["gx"] ?? 0)) / Double(P.d)).rounded()))))
                    return h
                },
                release: { h in
                    let k = Int((h["c"] ?? 3).rounded())
                    guard k != c else { return HandMove(hand: ["c": Double(k)], missHand: nil) }
                    return HandMove(hand: ["c": Double(k)], missHand: nil, set: [("x", Double(k + 1))], check: true)
                })
        default: return nil
        }
    }

    // MARK: Show me, and a child's slips

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Patterns.Parts(s.numbers), at = stage(s)
        if P.isShape {
            let sh = Shape(P)
            switch at {
            case 1:
                let have = Set(added(s, sh).map { "\($0.x)_\($0.y)" })
                let taps = sh.C[3].filter { $0.g == 3 && !have.contains("\($0.x)_\($0.y)") }
                    .map { GhostMove.tap(.picture(CGPoint(x: sh.sx[3] + Double($0.x) + 0.5, y: sh.yb - 0.5 - Double($0.y)))) }
                return taps + [.tap(.action("Check"))]
            case 2:
                let c = copies(s, P), y = sh.yr + 0.5
                return [.drag(from: CGPoint(x: Double(P.f + c * P.d), y: y), to: CGPoint(x: Double(P.f + (P.q - 1) * P.d), y: y))]
            default: return []
            }
        }
        switch at {
        case 1:
            let k = landedCount(s)
            return (k..<6).map { j in .drag(from: CGPoint(x: Double(P.vals[j - 1]), y: Self.ly), to: CGPoint(x: Double(P.vals[j]), y: Self.ly)) }
        case 2:
            let rg = ringed(s, P)
            return P.want.filter { !rg.contains($0) }.map { .tap(.picture(CGPoint(x: Double($0), y: Self.ny))) }
        case 3:
            let r = Squares.choiceRects(Self.oddEven, x: 0, y: choicesTop(s.numbers))[P.answer]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Patterns.Parts(s.numbers), at = stage(s)
        if P.isShape {
            switch at {
            case 1: return HandMove(hand: s.hand, missHand: nil, set: [("x", Double(P.count(3) + 1))], check: true)
            case 2: return HandMove(hand: ["c": Double(P.q - 2)], missHand: nil, set: [("x", Double(P.q - 1))], check: true)
            default: return nil
            }
        }
        switch at {
        case 1: return HandMove(hand: s.hand, missHand: nil, set: [("x", Double(P.d + 1))], check: true)
        case 2:
            guard let v = P.vals.first(where: { $0 % 2 != P.target }) else { return nil }
            return HandMove(hand: s.hand, missHand: nil, set: [("x", Double(1000 + v))], check: true)
        case 3:
            let i = 1 - P.answer
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Patterns.Parts(s.numbers)
        return P.isShape && stage(s) == 3 ? ["x": Double(P.q * P.d)] : nil
    }
}
