import Foundation

// 6th grade, chapter 7: Area and volume (design/grade6.md from "## 7. Area and volume", the preview
// design/prototype/grade6-ch7.html). One square is one square unit, every corner on a grid point, so every area can be
// counted. Each lesson's steps are hand moves on the picture (a cut, a slide, a copy fitted, a net folded, the floor
// covered and built up) followed by the record, as school writes it. The web's two lessons (Area of a triangle, of a
// trapezoid) keep its generators, checks and slips.

enum Area6 {
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { Int.random(in: min(a, b)...max(a, b), using: &rng) }
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// A typed whole number's check, with the lesson's own slips first.
    static func typed(_ want: Int, _ judge: @escaping @Sendable (Int) -> String?) -> @Sendable ([String: Double]) -> Verdict {
        { v in
            guard let x = v["x"] else { return .soft("Write the number.") }
            if x != x.rounded() { return .wrong(judge(-1) ?? "Write a whole number.") }
            let n = Int(x.rounded())
            return n == want ? .right : .wrong(judge(n) ?? "Not quite.")
        }
    }
    static func ask(_ say: String, _ hint: String) -> LessonStep { LessonStep(StepWords(say: say, hint: hint, action: "Let’s find out"), picture: ["at": 0]) }
    static func write(_ at: Double, _ say: String, _ prompt: MathLine, _ want: Int, hint: String, _ judge: @escaping @Sendable (Int) -> String?) -> LessonStep {
        LessonStep(StepWords(say: say, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: ["x": Double(want)], hint: hint, explain: "That makes \(want).", check: typed(want, judge), incomplete: "Write the number."),
            picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
    }
    static func hand(_ at: Double, _ say: String, box: String, want: Double, hint: String, picture: Numbers = [:], _ check: @escaping @Sendable ([String: Double]) -> Verdict) -> LessonStep {
        LessonStep(StepWords(say: say, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box(box)], expected: [box: want], hint: hint, explain: hint, check: check, byHand: true),
            picture: picture.merging(["at": at]) { $1 }, onMiss: ["ring": 1], hint2: ["spot": 1])
    }
}

// MARK: Area of a parallelogram

/// Area of a parallelogram (g6-para, new; builds on g4-area): its base `b` on a grid line, its top `s` units along
/// (leaning right, `lean` 1, or left, −1), its height `h`. Cut straight down a column from the top side to the bottom
/// side, slide the piece to the other end, and the same squares make a b by h rectangle: Area = b × h.
public enum Para6 {
    public static func numbers(b: Int, h: Int, s: Int, lean: Int = 1, story: Int = 0) -> Numbers {
        ["b": Double(b), "h": Double(h), "s": Double(s), "lean": Double(lean), "story": Double(story)]
    }
    public static let stories = [("It’s a garden bed, measured in feet.", "square feet"), ("It’s a sign, measured in inches.", "square inches")]
    public struct Parts: Sendable {
        public let b: Int, h: Int, s: Int, lean: Int, story: Int
        public init(_ n: Numbers) {
            b = Int((n["b"] ?? 8).rounded()); h = Int((n["h"] ?? 4).rounded()); s = Int((n["s"] ?? 2).rounded())
            lean = (n["lean"] ?? 1) < 0 ? -1 : 1; story = Int((n["story"] ?? 0).rounded())
        }
        public var A: Int { b * h }
        public var unit: String { story > 0 ? Para6.stories[(story - 1) % 2].1 : "square units" }
        /// A cut at column c (from the shape's left end) runs from the top side to the bottom side.
        public func cuts(_ c: Int) -> Bool { c >= s && c <= b }
        public var cutSay: String { story > 0 ? "\(Para6.stories[(story - 1) % 2].0) Cut straight down a grid line." : "Cut straight down. Drag down a grid line." }
        public var why: String { "Cut and slide: the same squares make a \(b) by \(h) rectangle." }
        public func area(_ v: Int) -> String? {
            if v == A { return nil }
            if v * 2 == A { return "That’s a triangle’s area. A parallelogram is the whole rectangle." }
            if v == b + h { return "Multiply: \(h) rows of \(b)." }
            return "Count the squares: \(h) rows of \(b)."
        }
    }

    /// The first three lean right, base 10 or less, height 6 or less, top 3 or less along; then either way, the full
    /// range, and stories from the sixth on.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { let b = Area6.r(4, 10, &rng); return numbers(b: b, h: Area6.r(2, 6, &rng), s: Area6.r(1, min(3, b - 1), &rng)) }
        let b = Area6.r(4, 16, &rng), h = Area6.r(2, 12, &rng), s = Area6.r(1, b - 1, &rng), lean = Bool.random(using: &rng) ? 1 : -1
        let story = i >= 5 && Bool.random(using: &rng) ? Area6.r(1, 2, &rng) : 0
        return numbers(b: b, h: h, s: s, lean: lean, story: story)
    }

    public static let spec = LessonSpec(id: "g6-para", title: "Area of a parallelogram", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { n in let p = Parts(n); return [.text("base"), .num(Double(p.b)), .text("height"), .num(Double(p.h))] },
        idea: { _ in "Cut a parallelogram straight down and slide the piece over: it’s a rectangle with the same base and height." },
        depends: ["g4-area", "g4-mult2x2"],
        check: [CheckItem(3, when: { Parts($0).lean < 0 }), CheckItem(3, when: { Parts($0).h % 2 == 1 }), CheckItem(3, when: { Parts($0).b >= 12 }),
                CheckItem(6, when: { Parts($0).story > 0 })]) { n in
        let p = Parts(n)
        let cutHint = "Cut down a grid line that crosses the top side and the bottom side."
        let cut = Area6.hand(1, p.cutSay, box: "c", want: Double(p.s), hint: cutHint) { v in
            p.cuts(Area6.int(v, "c")) ? .right : .wrong("Cut from the top side to the bottom side.")
        }
        let slideHint = "Slide it until its slanted side meets the other slanted side."
        let slide = Area6.hand(2, "Slide the piece to the other end. Drag either piece.", box: "d", want: 1, hint: slideHint) { v in
            Area6.int(v, "d") == 1 ? .right : .wrong("Slide it to the other end.")
        }
        let area = Area6.write(3, "Write the area.", [.text("Area"), .op("="), .num(Double(p.b)), .op("×"), .num(Double(p.h)), .op("="), .box("x")], p.A,
                               hint: "\(p.h) rows of \(p.b).") { p.area($0) }
        return [Area6.ask("Cut straight down.", cutHint), cut, slide, area,
                LessonStep(StepWords(say: p.why, hint: cutHint, action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: Area of a triangle

/// Area of a triangle (g6-tri, the web's maths: b and h 2–20 with b × h even, its check and slips), drawn so the top sits
/// over one end (a right triangle, `p` 0 or b), over the base (0 < p < b), or past its end (p > b), all with the same
/// b and h. A copy turned half a turn fits against the slanted side, and the two make a b by h rectangle (or a
/// parallelogram that cuts and slides into one): b × h, then half.
public enum Tri6 {
    public static func numbers(b: Int, h: Int, p: Int) -> Numbers { ["b": Double(b), "h": Double(h), "p": Double(p)] }
    public struct Parts: Sendable {
        public let b: Int, h: Int, p: Int
        public init(_ n: Numbers) { b = Int((n["b"] ?? 6).rounded()); h = Int((n["h"] ?? 4).rounded()); p = Int((n["p"] ?? 2).rounded()) }
        public var R: Int { b * h }
        public var A: Int { R / 2 }
        /// The top past the base's end: the two make a parallelogram, cut and slid into the rectangle.
        public var past: Bool { p > b }
        public var why: String { "Two copies make a \(b) by \(h) rectangle, so one is half." }
        public func rect(_ v: Int) -> String? { v == R ? nil : v == b + h ? "Multiply base × height." : "The rectangle is \(h) rows of \(b)." }
        public func half(_ v: Int) -> String? { v == A ? nil : v == R ? "A triangle is half of a rectangle: divide by 2." : "Two triangles make \(R): take half." }
    }
    /// The web's generator; the top over the base first, then at an end, then past it, then any.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        var b = 0, h = 0
        repeat { b = Area6.r(2, 20, &rng); h = Area6.r(2, 20, &rng) } while (b * h) % 2 != 0
        let kind = i < 3 ? [1, 0, 2][i] : Area6.r(0, 2, &rng)
        let p = kind == 0 ? (Bool.random(using: &rng) ? 0 : b) : kind == 1 ? Area6.r(1, b - 1, &rng) : b + Area6.r(1, max(1, min(4, b - 1)), &rng)
        return numbers(b: b, h: h, p: p)
    }
    public static let spec = LessonSpec(id: "g6-tri", title: "Area of a triangle", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { n in let p = Parts(n); return [.text("base"), .num(Double(p.b)), .text("height"), .num(Double(p.h))] },
        idea: { _ in "A triangle is half of the rectangle two copies of it make." },
        depends: ["g4-area", "g4-mult2x2"],
        check: [CheckItem(0, when: { Parts($0).b % 2 == 1 || Parts($0).h % 2 == 1 }), CheckItem(0, when: { Parts($0).b >= 10 && Parts($0).h >= 10 }), CheckItem(1), CheckItem(2)]) { n in
        let p = Parts(n)
        let fitHint = "The copy’s slanted side goes against the triangle’s."
        let fit = Area6.hand(1, "Fit the copy against it. Drag the copy.", box: "f", want: 1, hint: fitHint) { v in
            Area6.int(v, "f") == 1 ? .right : .wrong("Put it against the slanted side.")
        }
        let rect = Area6.write(2, "Write the rectangle’s area.", [.num(Double(p.b)), .op("×"), .num(Double(p.h)), .op("="), .box("x")], p.R,
                               hint: "Multiply the base and the height.") { p.rect($0) }
        let half = Area6.write(3, "Write the triangle’s area.", [.num(Double(p.R)), .op("÷"), .num(2), .op("="), .box("x")], p.A,
                               hint: "A triangle is half of a rectangle.") { p.half($0) }
        return [Area6.ask("Fit the copy against it.", fitHint), fit, rect, half,
                LessonStep(StepWords(say: p.why, hint: fitHint, action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: Area of a trapezoid

/// Area of a trapezoid (g6-trap, the web's maths: bases a ≠ b 2–15, height 2–12, a whole area, its check and slips; its
/// picture, a right trapezoid). The copy swings half a turn as it's picked up and fits against the slanted side: the two
/// make a rectangle a + b long. a + b, times h, then half.
public enum Trap6 {
    public static func numbers(a: Int, b: Int, h: Int) -> Numbers { ["a": Double(a), "b": Double(b), "h": Double(h)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, h: Int
        public init(_ n: Numbers) { a = Int((n["a"] ?? 4).rounded()); b = Int((n["b"] ?? 8).rounded()); h = Int((n["h"] ?? 5).rounded()) }
        public var S: Int { a + b }
        public var P: Int { S * h }
        public var A: Int { P / 2 }
        public var why: String { "Two trapezoids make a \(S) by \(h) rectangle, so one is half." }
        public func sum(_ v: Int) -> String? { v == S ? nil : v == a * b ? "Put the bases end to end: add them." : "The bottom is \(a) and \(b) end to end." }
        public func times(_ v: Int) -> String? { v == P ? nil : v == S + h ? "Area is length times height." : "The rectangle is \(h) rows of \(S)." }
        public func half(_ v: Int) -> String? { v == A ? nil : v == P ? "Divide by 2 at the end." : "That area holds two trapezoids. Take half." }
    }
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        var a = 0, b = 0, h = 0
        repeat { a = Area6.r(2, 15, &rng); b = Area6.r(2, 15, &rng); h = Area6.r(2, 12, &rng) } while a == b || ((a + b) * h) % 2 != 0
        return numbers(a: a, b: b, h: h)
    }
    public static let spec = LessonSpec(id: "g6-trap", title: "Area of a trapezoid", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { n in let p = Parts(n); return [.text("bases"), .num(Double(p.a)), .text("and"), .num(Double(p.b)), .text("height"), .num(Double(p.h))] },
        idea: { _ in "Turn a copy upside down and the two trapezoids make a rectangle, so one trapezoid is half of it." },
        depends: ["g6-tri", "g4-mult2x2"],
        check: [CheckItem(0, when: { (Parts($0).a + Parts($0).b) % 2 == 1 }), CheckItem(0, when: { Parts($0).h % 2 == 1 }), CheckItem(0), CheckItem(0)]) { n in
        let p = Parts(n)
        let fitHint = "Lay a turned copy next to it, so the bases sit end to end."
        let fit = Area6.hand(1, "Fit the copy against it. Pick it up and slide it.", box: "f", want: 1, hint: fitHint) { v in
            Area6.int(v, "f") == 1 ? .right : .wrong("Put it against the slanted side.")
        }
        let sum = Area6.write(2, "The two make a rectangle. Write how long it is.", [.num(Double(p.a)), .op("+"), .num(Double(p.b)), .op("="), .box("x")], p.S,
                              hint: "The two copies lie end to end along the bottom: \(p.a) + \(p.b).") { p.sum($0) }
        let times = Area6.write(3, "Write the rectangle’s area.", [.num(Double(p.S)), .op("×"), .num(Double(p.h)), .op("="), .box("x")], p.P,
                                hint: "The two copies make a rectangle: length × height, \(p.S) × \(p.h).") { p.times($0) }
        let half = Area6.write(4, "Write the trapezoid’s area.", [.num(Double(p.P)), .op("÷"), .num(2), .op("="), .box("x")], p.A,
                               hint: "That area holds two trapezoids. Take half.") { p.half($0) }
        return [Area6.ask("Fit the copy against it.", fitHint), fit, sum, times, half,
                LessonStep(StepWords(say: p.why, hint: fitHint, action: "Next problem"), picture: ["at": 5])]
    }
}

// MARK: Area of a polygon

/// Area of a polygon (g6-poly, new; builds on g6-tri): a shape of rectangles and right triangles (an L, a rectangle and a
/// triangle, two triangles, a house, a rectangle with a corner off), every corner on a grid point, turned and flipped.
/// Cut it along grid lines into rectangles and triangles (or, with a corner off, cut the corner away along its slanted
/// side); Cut names the pieces. The pieces the child's cuts made are kept (`Poly6.keep`), and each is written in the
/// record (w × h, or w × h ÷ 2), then they're added (or the corner taken away).
public enum Poly6 {
    public enum Kind: Int, Sendable { case L = 0, rt, tri2, take, house }
    public struct Piece: Equatable, Sendable {
        public var tri: Bool, w: Int, h: Int, sign: Int
        public init(tri: Bool, w: Int, h: Int, sign: Int = 1) { self.tri = tri; self.w = w; self.h = h; self.sign = sign }
        public var A: Int { tri ? w * h / 2 : w * h }
    }
    public static func numbers(kind: Kind, W: Int, H: Int, a: Int, b: Int = 0, tr: Int = 0, fx: Int = 0, fy: Int = 0) -> Numbers {
        ["kind": Double(kind.rawValue), "W": Double(W), "H": Double(H), "a": Double(a), "b": Double(b), "tr": Double(tr), "fx": Double(fx), "fy": Double(fy)]
    }
    /// The shape: its corners in units (turned and flipped), what it is, its pieces the usual way.
    public struct Shape: Sendable {
        public let kind: Kind, W: Int, H: Int, a: Int, b: Int, tr: Bool, fx: Bool, fy: Bool
        public init(_ n: Numbers) {
            kind = Kind(rawValue: Int((n["kind"] ?? 0).rounded())) ?? .L
            W = Int((n["W"] ?? 8).rounded()); H = Int((n["H"] ?? 6).rounded()); a = Int((n["a"] ?? 3).rounded()); b = Int((n["b"] ?? 3).rounded())
            tr = (n["tr"] ?? 0) != 0; fx = (n["fx"] ?? 0) != 0; fy = (n["fy"] ?? 0) != 0
        }
        /// Corners before turning.
        var raw: [(Int, Int)] {
            switch kind {
            case .L: return [(0, 0), (W - a, 0), (W - a, b), (W, b), (W, H), (0, H)]
            case .rt: return [(0, 0), (W, 0), (W + a, H), (0, H)]
            case .tri2: return [(0, H), (W, H), (a, 0)]
            case .house: return [(0, a), (W / 2, 0), (W, a), (W, a + H), (0, a + H)]
            case .take: return [(0, 0), (W - a, 0), (W, b), (W, H), (0, H)]
            }
        }
        var rawW: Int { kind == .rt ? W + a : W }
        var rawH: Int { kind == .house ? a + H : H }
        /// Its size across and down, turned.
        public var width: Int { tr ? rawH : rawW }
        public var height: Int { tr ? rawW : rawH }
        func turned(_ p: (Int, Int)) -> (Int, Int) {
            var (x, y) = tr ? (p.1, p.0) : p
            if fx { x = width - x }
            if fy { y = height - y }
            return (x, y)
        }
        public var corners: [(Int, Int)] { raw.map(turned) }
        /// A height drawn dashed inside (a triangle on top of its base: two triangles, a house's roof): its top and foot.
        public var heights: [((Int, Int), (Int, Int))] {
            switch kind {
            case .tri2: return [(turned((a, 0)), turned((a, H)))]
            case .house: return [(turned((W / 2, 0)), turned((W / 2, a)))]
            default: return []
            }
        }
        /// A rectangle with a corner off: the whole rectangle and the corner, to take it away.
        public var takeRect: [(Int, Int)]? { kind == .take ? [(0, 0), (W, 0), (W, H), (0, H)].map(turned) : nil }
        public var takeCorner: [(Int, Int)]? { kind == .take ? [(W - a, 0), (W, 0), (W, b)].map(turned) : nil }
        /// The corner's legs, labelled outside the rectangle: along the top, then down the side.
        public var takeLegs: [((Int, Int), (Int, Int), Int)] { kind == .take ? [(turned((W - a, 0)), turned((W, 0)), a), (turned((W, 0)), turned((W, b)), b)] : [] }
        /// The pieces the usual way (the record for Show me and the tests).
        public var pieces: [Piece] {
            switch kind {
            case .L: return [Piece(tri: false, w: W - a, h: H), Piece(tri: false, w: a, h: H - b)]
            case .rt: return [Piece(tri: false, w: W, h: H), Piece(tri: true, w: a, h: H)]
            case .tri2: return [Piece(tri: true, w: a, h: H), Piece(tri: true, w: W - a, h: H)]
            case .house: return [Piece(tri: true, w: W / 2, h: a), Piece(tri: true, w: W / 2, h: a), Piece(tri: false, w: W, h: H)]
            case .take: return [Piece(tri: false, w: W, h: H), Piece(tri: true, w: a, h: b, sign: -1)]
            }
        }
        /// How many pieces the record has room for (a corner taken off is two, cut into pieces three).
        public var slots: Int { kind == .house || kind == .take ? 3 : 2 }
        public var area: Int { pieces.reduce(0) { $0 + $1.sign * $1.A } }
    }

    /// What the cut kept, for the record and its checks: how many pieces, and each one's kind, sides and sign.
    public static func keep(_ ps: [Piece]) -> Numbers {
        var out: Numbers = ["n": Double(ps.count)]
        for (i, p) in ps.enumerated() { out["t\(i)"] = p.tri ? 1 : 0; out["w\(i)"] = Double(p.w); out["h\(i)"] = Double(p.h); out["s\(i)"] = Double(p.sign) }
        return out
    }
    /// The pieces kept (`prefix` "kept." inside a check).
    public static func pieces(_ v: [String: Double], prefix: String = "") -> [Piece]? {
        guard let n = v[prefix + "n"] else { return nil }
        return (0..<Int(n.rounded())).map { i in
            Piece(tri: (v[prefix + "t\(i)"] ?? 0) != 0, w: Int((v[prefix + "w\(i)"] ?? 0).rounded()), h: Int((v[prefix + "h\(i)"] ?? 0).rounded()),
                  sign: (v[prefix + "s\(i)"] ?? 1) < 0 ? -1 : 1)
        }
    }

    static func even(_ lo: Int, _ hi: Int, _ rng: inout SeededRandom, _ ok: (Int) -> Bool) -> Int {
        for _ in 0..<100 { let v = Area6.r(lo, hi, &rng); if ok(v) { return v } }
        return lo
    }
    /// Problems 1–3 L-shapes, 4–6 a rectangle and a triangle, then two triangles, a house or a corner taken off.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind: Kind = i < 3 ? .L : i < 6 ? .rt : [Kind.tri2, .take, .house][Area6.r(0, 2, &rng)]
        var W = 0, H = 0, a = 0, b = 0
        switch kind {
        case .L: W = Area6.r(5, 12, &rng); H = Area6.r(5, 12, &rng); a = Area6.r(2, W - 3, &rng); b = Area6.r(2, H - 3, &rng)
        case .rt: H = Area6.r(2, 10, &rng); a = even(2, 6, &rng) { ($0 * H) % 2 == 0 }; W = Area6.r(3, 12 - a, &rng)
        case .tri2: H = Area6.r(2, 12, &rng); W = H % 2 == 1 ? 2 * Area6.r(2, 6, &rng) : Area6.r(4, 12, &rng); a = even(2, W - 2, &rng) { ($0 * H) % 2 == 0 && ((W - $0) * H) % 2 == 0 }
        case .house: W = 2 * Area6.r(2, 6, &rng); a = even(2, 6, &rng) { (W / 2 * $0) % 2 == 0 }; H = Area6.r(2, 8, &rng)
        case .take: W = Area6.r(5, 12, &rng); H = Area6.r(5, 12, &rng); a = Area6.r(2, W - 3, &rng); b = even(2, H - 3, &rng) { (a * $0) % 2 == 0 }
        }
        return numbers(kind: kind, W: W, H: H, a: a, b: b, tr: Area6.r(0, 1, &rng), fx: Area6.r(0, 1, &rng), fy: Area6.r(0, 1, &rng))
    }

    static func line(_ p: Piece, _ box: String) -> MathLine {
        [.num(Double(p.w)), .op("×"), .num(Double(p.h))] + (p.tri ? [.op("÷"), .num(2)] : []) + [.op("="), .box(box)]
    }
    public static func pieceSlip(_ p: Piece, _ v: Int) -> String? {
        if v == p.A { return nil }
        if p.tri && v == p.w * p.h { return "A triangle is half its rectangle: divide by 2." }
        if v == p.w + p.h { return "Multiply the two sides." }
        return "It’s \(p.h) rows of \(p.w)\(p.tri ? ", then half" : "")."
    }
    public static func totalSlip(_ ps: [Piece], _ v: Int) -> String? {
        let S = ps.reduce(0) { $0 + $1.sign * $1.A }, take = ps.contains { $0.sign < 0 }
        if v == S { return nil }
        if take && v == ps.reduce(0) { $0 + $1.A } { return "The corner is taken away: subtract it." }
        if ps.contains(where: { v == S + $0.A }) { return "That counts a piece twice." }
        return take ? "Take the corner’s area from the rectangle’s." : "Add the pieces’ areas."
    }
    public static func done(_ ps: [Piece]) -> String {
        if ps.contains(where: { $0.sign < 0 }) { return "Take the corner away: the rectangle less the triangle." }
        let r = ps.filter { !$0.tri }.count, t = ps.filter(\.tri).count
        func w(_ n: Int, _ s: String) -> String { n == 0 ? "" : "\(["", "a", "two", "three", "four"][min(n, 4)]) \(s)\(n > 1 ? "s" : "")" }
        return "Cut into \([w(r, "rectangle"), w(t, "triangle")].filter { !$0.isEmpty }.joined(separator: " and ")), the areas add."
    }

    public static let spec = LessonSpec(id: "g6-poly", title: "Area of a polygon", master: "bars",
        generate: { rng, i in make(&rng, i) },
        idea: { _ in "Cut a shape into rectangles and triangles, and its area is theirs added up." },
        depends: ["g6-tri", "g4-area"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { Shape($0).kind == .tri2 }), CheckItem(6, when: { Shape($0).kind == .take })]) { n in
        let S = Shape(n), base = S.pieces
        let cutHint = S.kind == .take ? "Cut along grid lines, or along the slanted side to take its corner off." : "Cut along grid lines, from edge to edge."
        let cut = Area6.hand(1, "Cut it into rectangles and triangles. Drag along a grid line, edge to edge, then tap Cut.", box: "k", want: 1, hint: cutHint) { v in
            switch Area6.int(v, "k") {
            case 1: return .right
            case 0: return .wrong("That piece isn’t a rectangle or a triangle.")
            case -2: return .soft("Cut along a grid line, from edge to edge.")
            default: return .soft("Cut it first, then tap Cut.")
            }
        }
        var steps = [Area6.ask("Cut it into rectangles and triangles.", cutHint), cut]
        let say = S.kind == .take ? "Write each area, then take the corner away." : "Write each piece’s area, then add them."
        for i in 0..<S.slots {
            let want = i < base.count ? base[i].A : 0
            let line = i < base.count ? line(base[i], "x") : [.box("x")]
            steps.append(LessonStep(StepWords(say: say, hint: "A rectangle is rows × columns; a triangle is half its rectangle.", action: "Check"),
                answer: AnswerTask(prompt: line, expected: ["x": Double(want)], hint: "Multiply the two sides; half for a triangle.", explain: "That makes \(want).",
                    check: { v in
                        guard let ps = pieces(v, prefix: "kept."), i < ps.count else { return Area6.int(v, "x") == 0 ? .right : .wrong("Write the number.") }
                        guard let x = v["x"] else { return .soft("Write the number.") }
                        return pieceSlip(ps[i], Int(x.rounded())).map { .wrong($0) } ?? (x == x.rounded() ? .right : .wrong("Write a whole number."))
                    }, incomplete: "Write the number.",
                    expectKept: { kept in pieces(kept).map { ps in ["x": Double(i < ps.count ? ps[i].A : 0)] } ?? ["x": Double(want)] }),
                picture: ["at": 2, "k": Double(i)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let total = base.reduce(0) { $0 + $1.sign * $1.A }
        steps.append(LessonStep(StepWords(say: say, hint: "Add the pieces; take away a corner taken off.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(total)], hint: "Add the pieces’ areas.", explain: "That makes \(total).",
                check: { v in
                    let ps = pieces(v, prefix: "kept.") ?? base
                    guard let x = v["x"] else { return .soft("Write the number.") }
                    return totalSlip(ps, Int(x.rounded())).map { .wrong($0) } ?? .right
                }, incomplete: "Write the number.",
                expectKept: { kept in ["x": Double((pieces(kept) ?? base).reduce(0) { $0 + $1.sign * $1.A })] }),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: done(base), hint: cutHint, action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}

// MARK: Nets and surface area

/// Nets and surface area (g6-nets, new; 6.G.4; builds on g6-tri and g5-volume): a box's net flat on the paper (the
/// strip of four sides across, the top and bottom above and below one of them), a cube's, a triangular prism's or a
/// square pyramid's. Fold each face up (the paper tilts: Unit cubes' view), it closes, then lies flat again; tap each
/// face (faces the same size light together after the first) and its area is written in it; write SA.
public enum Nets6 {
    public enum Kind: Int, Sendable { case cube = 0, box, prism, pyramid }
    public static func numbers(kind: Kind, a: Int = 0, b: Int = 0, c: Int = 0, tri: Int = 0, L: Int = 0) -> Numbers {
        ["kind": Double(kind.rawValue), "a": Double(a), "b": Double(b), "c": Double(c), "tri": Double(tri), "L": Double(L)]
    }
    public static func cube(_ e: Int) -> Numbers { numbers(kind: .cube, a: e, b: e, c: e) }
    public static func box(a: Int, b: Int, c: Int) -> Numbers { numbers(kind: .box, a: a, b: b, c: c) }
    public static func prism(right: Bool, L: Int) -> Numbers { numbers(kind: .prism, tri: right ? 0 : 1, L: L) }
    /// A square pyramid: base s, each triangle's height l.
    public static func pyramid(s: Int, l: Int) -> Numbers { numbers(kind: .pyramid, a: s, b: l) }

    /// A face of the net (units): its corners flat, the face it folds up from (nil: the base, which stays down), its
    /// hinge (a point on its fold line, and `n` the way into the face), how far it turns up (degrees), and its size.
    public struct Face: Sendable {
        public let id: String, pts: [(Double, Double)], parent: String?, P: (Double, Double), n: (Double, Double), turn: Double
        public let w: Int, h: Int, tri: Bool
        public var A: Int { tri ? w * h / 2 : w * h }
        /// Faces the same size light together.
        public var key: String { tri ? "t\(w)x\(h)" : "r\(min(w, h))x\(max(w, h))" }
        public var hinge: ((Double, Double), (Double, Double)) { (P, (P.0 + n.1, P.1 - n.0)) }
    }
    public struct Net: Sendable {
        public let kind: Kind, faces: [Face], width: Double, height: Double
        /// What it folds into ("box" for a cube too), its volume (nil for a pyramid), a cube's edge.
        public var solid: String { kind == .prism ? "prism" : kind == .pyramid ? "pyramid" : "box" }
        public let V: Int?, e: Int
        public var SA: Int { faces.reduce(0) { $0 + $1.A } }
        /// Faces the same size, together: (how many, one's area), in the net's order.
        public var groups: [(n: Int, A: Int)] {
            var out: [(key: String, n: Int, A: Int)] = []
            for f in faces { if let i = out.firstIndex(where: { $0.key == f.key }) { out[i].n += 1 } else { out.append((f.key, 1, f.A)) } }
            return out.map { ($0.n, $0.A) }
        }
        /// SA = 2 × 20 + 2 × 15 + 2 × 12, or a cube's 6 × 4².
        public var terms: MathLine {
            if kind == .cube { return [.num(6), .op("×"), .text("\(e)²")] }
            var out: MathLine = []
            for (j, g) in groups.enumerated() {
                if j > 0 { out.append(.op("+")) }
                if g.n > 1 { out += [.num(Double(g.n)), .op("×")] }
                out.append(.num(Double(g.A)))
            }
            return out
        }
    }
    public static func net(_ x: Numbers) -> Net {
        let kind = Kind(rawValue: Int((x["kind"] ?? 1).rounded())) ?? .box
        func R(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> [(Double, Double)] { [(x0, y0), (x1, y0), (x1, y1), (x0, y1)] }
        let Q = 90.0
        switch kind {
        case .cube, .box:
            // a the strip's long side, b the depth (the top and bottom's other side), c the height of the strip
            let a = Double(Int((x["a"] ?? 4).rounded())), b = Double(Int((x["b"] ?? 3).rounded())), c = Double(Int((x["c"] ?? 2).rounded()))
            let ai = Int(a), bi = Int(b), ci = Int(c)
            let faces = [
                Face(id: "base", pts: R(b, b, b + a, b + c), parent: nil, P: (0, 0), n: (0, 0), turn: 0, w: ai, h: ci, tri: false),
                Face(id: "s0", pts: R(0, b, b, b + c), parent: "base", P: (b, b), n: (-1, 0), turn: Q, w: bi, h: ci, tri: false),
                Face(id: "s2", pts: R(b + a, b, 2 * b + a, b + c), parent: "base", P: (b + a, b), n: (1, 0), turn: Q, w: bi, h: ci, tri: false),
                Face(id: "s3", pts: R(2 * b + a, b, 2 * b + 2 * a, b + c), parent: "s2", P: (2 * b + a, b), n: (1, 0), turn: Q, w: ai, h: ci, tri: false),
                Face(id: "cT", pts: R(b, 0, b + a, b), parent: "base", P: (b, b), n: (0, -1), turn: Q, w: ai, h: bi, tri: false),
                Face(id: "cB", pts: R(b, b + c, b + a, 2 * b + c), parent: "base", P: (b, b + c), n: (0, 1), turn: Q, w: ai, h: bi, tri: false)]
            return Net(kind: kind, faces: faces, width: 2 * a + 2 * b, height: 2 * b + c, V: ai * bi * ci, e: kind == .cube ? ai : 0)
        case .prism:
            let right = (x["tri"] ?? 0) == 0, L = Double(Int((x["L"] ?? 3).rounded())), Li = Int(L)
            let (q, th, ax): (Double, Double, Double) = right ? (4, 3, 0) : (6, 4, 3)
            let sL = (ax * ax + th * th).squareRoot(), sR = ((q - ax) * (q - ax) + th * th).squareRoot()
            let tl = 180 - atan2(th, ax) * 180 / .pi, tr = 180 - atan2(th, q - ax) * 180 / .pi
            let faces = [
                Face(id: "base", pts: R(sL, th, sL + q, th + L), parent: nil, P: (0, 0), n: (0, 0), turn: 0, w: Int(q), h: Li, tri: false),
                Face(id: "fl", pts: R(0, th, sL, th + L), parent: "base", P: (sL, th), n: (-1, 0), turn: tl, w: Int(sL.rounded()), h: Li, tri: false),
                Face(id: "fr", pts: R(sL + q, th, sL + q + sR, th + L), parent: "base", P: (sL + q, th), n: (1, 0), turn: tr, w: Int(sR.rounded()), h: Li, tri: false),
                Face(id: "cT", pts: [(sL, th), (sL + q, th), (sL + ax, 0)], parent: "base", P: (sL, th), n: (0, -1), turn: Q, w: Int(q), h: Int(th), tri: true),
                Face(id: "cB", pts: [(sL, th + L), (sL + q, th + L), (sL + ax, 2 * th + L)], parent: "base", P: (sL, th + L), n: (0, 1), turn: Q, w: Int(q), h: Int(th), tri: true)]
            return Net(kind: kind, faces: faces, width: sL + q + sR, height: 2 * th + L, V: Int(q * th / 2 * L), e: 0)
        case .pyramid:
            let s = Double(Int((x["a"] ?? 4).rounded())), l = Double(Int((x["b"] ?? 4).rounded())), si = Int(s), li = Int(l)
            let tg = acos(-s / (2 * l)) * 180 / .pi
            let faces = [
                Face(id: "base", pts: R(l, l, l + s, l + s), parent: nil, P: (0, 0), n: (0, 0), turn: 0, w: si, h: si, tri: false),
                Face(id: "tT", pts: [(l, l), (l + s, l), (l + s / 2, 0)], parent: "base", P: (l, l), n: (0, -1), turn: tg, w: si, h: li, tri: true),
                Face(id: "tB", pts: [(l, l + s), (l + s, l + s), (l + s / 2, 2 * l + s)], parent: "base", P: (l, l + s), n: (0, 1), turn: tg, w: si, h: li, tri: true),
                Face(id: "tL", pts: [(l, l), (l, l + s), (0, l + s / 2)], parent: "base", P: (l, l), n: (-1, 0), turn: tg, w: si, h: li, tri: true),
                Face(id: "tR", pts: [(l + s, l), (l + s, l + s), (2 * l + s, l + s / 2)], parent: "base", P: (l + s, l), n: (1, 0), turn: tg, w: si, h: li, tri: true)]
            return Net(kind: kind, faces: faces, width: s + 2 * l, height: s + 2 * l, V: nil, e: 0)
        }
    }

    static func boxDims(_ caps: [Int], _ rng: inout SeededRandom) -> Numbers {
        for _ in 0..<200 {
            let d = caps.map { Area6.r(2, $0, &rng) }.sorted(by: >)
            if !(d[0] == d[1] && d[1] == d[2]) { return box(a: d[0], b: d[2], c: d[1]) }
        }
        return box(a: 4, b: 2, c: 3)
    }
    /// Problems 1–3 cubes and boxes with edges to 5 (a cube's net is 4 edges across and 3 down, so cubes stop at 4); 4–6
    /// boxes to 6 × 5 × 4; then prisms, pyramids and boxes in turn.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { return i == 0 || (i == 2 && Bool.random(using: &rng)) ? cube(Area6.r(2, 4, &rng)) : boxDims([5, 5, 5], &rng) }
        if i < 6 { return boxDims([6, 5, 4], &rng) }
        switch i % 3 {
        case 0: return prism(right: Bool.random(using: &rng), L: Area6.r(2, 5, &rng))
        case 1:
            for _ in 0..<200 {
                let s = Area6.r(2, 6, &rng), l = Area6.r(3, 6, &rng)
                if 2 * l > s && (s * l) % 2 == 0 && s + 2 * l <= 14 { return pyramid(s: s, l: l) }
            }
            return pyramid(s: 4, l: 4)
        default: return Area6.r(0, 2, &rng) > 0 ? boxDims([6, 5, 4], &rng) : cube(Area6.r(2, 4, &rng))
        }
    }

    public static func slip(_ N: Net, _ v: Int) -> String? {
        if v == N.SA { return nil }
        if let V = N.V, v == V { return "That’s the cubes inside. The surface is the faces." }
        if N.faces.count == 6 && v * 2 == N.SA { return "That’s 3 faces. A box has 6." }
        return "Add the faces’ areas: every face counts."
    }

    public static let spec = LessonSpec(id: "g6-nets", title: "Nets and surface area", master: "bars",
        generate: { rng, i in make(&rng, i) },
        idea: { _ in "A net is a solid’s outside laid flat: its surface area is all its faces added up." },
        depends: ["g6-tri", "g5-volume"],
        check: [CheckItem(0), CheckItem(3), CheckItem(7), CheckItem(6)]) { x in
        let N = net(x), nF = N.faces.count
        let foldHint = "Drag a face over its fold line, toward the middle."
        let fold = Area6.hand(1, "Fold it into a \(N.solid). Drag each face toward the middle.", box: "f", want: Double(nF - 1), hint: foldHint) { v in
            let f = Area6.int(v, "f")
            if f == nF - 1 { return .right }
            return f == -2 ? .soft("Fold the sides up first.") : .soft("Fold it all the way up.")
        }
        let tapHint = "Faces the same size light together."
        let tap = Area6.hand(2, "Tap each face: its area is written in it.", box: "t", want: Double(nF), hint: tapHint) { v in
            Area6.int(v, "t") == nF ? .right : .soft("Tap a face of the net.")
        }
        let write = LessonStep(StepWords(say: "Write the surface area. Every face counts.", hint: "Add the faces’ areas.", action: "Check"),
            answer: AnswerTask(prompt: [.text("SA"), .op("=")] + N.terms + [.op("="), .box("x")], expected: ["x": Double(N.SA)], hint: "Add the faces’ areas.",
                               explain: "That makes \(N.SA).", check: Area6.typed(N.SA) { slip(N, $0) }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [Area6.ask("Fold it into a \(N.solid).", foldHint), fold, tap, write,
                LessonStep(StepWords(say: "The net is the \(N.solid)’s outside laid flat: \(N.SA) squares cover it.", hint: tapHint, action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: Volume with fraction edges

/// Volume with fraction edges (g6-fracvol, new; 6.G.2; builds on g5-volume and g5-multfrac): a small cube with edges of
/// 1/2 (1/3 from problem 7 on, every third) is a block, a whole cube 2 × 2 × 2 of them (3 × 3 × 3). Cover the floor, the
/// paper tilts and it rises into the first layer, build it up, 8 small cubes in a corner light as one whole, write
/// N ÷ 8 as a mixed number, and the record V = l × w × h (or B × h) says the same.
public enum FracVol6 {
    public static func numbers(x: Int, y: Int, z: Int, d: Int = 2, mode: Int = 0) -> Numbers {
        ["x": Double(x), "y": Double(y), "z": Double(z), "d": Double(d), "mode": Double(mode)]
    }
    public struct Parts: Sendable {
        /// The edges in small cubes, how many small edges a whole one is, and the kind (0 counted, 1 B × h, 2 thirds).
        public let x: Int, y: Int, z: Int, d: Int, mode: Int
        public init(_ n: Numbers) {
            x = Int((n["x"] ?? 3).rounded()); y = Int((n["y"] ?? 4).rounded()); z = Int((n["z"] ?? 3).rounded())
            d = Int((n["d"] ?? 2).rounded()); mode = Int((n["mode"] ?? 0).rounded())
        }
        public var floor: Int { x * y }
        public var N: Int { floor * z }
        public var per: Int { d * d * d }
        public var V: Double { Double(N) / Double(per) }
        public var whole: Bool { N % per == 0 }
        /// An edge as a mixed number: "1½", "2", "⅔".
        public func edge(_ n: Int) -> String { FracVol6.mixed(n, d) }
        public var Vs: String { FracVol6.mixed(N, per, glyph: false) }
        public var Bs: String { FracVol6.mixed(floor, d * d, glyph: false) }
        public var wholes: Int { (x / d) * (y / d) * (z / d) }
        public func written(_ v: Double) -> String? {
            if abs(v - V) < 1e-9 { return nil }
            if abs(v - Double(N)) < 1e-9 { return "\(per) small cubes make one whole." }
            if abs(v - Double(wholes)) < 1e-9 { return "The \(d == 2 ? "halves" : "thirds") count too: share all \(N) small cubes into wholes of \(per)." }
            return "Share the \(N) small cubes into wholes of \(per)."
        }
        public var why: String { "\(per) small cubes make one whole cube, so \(N) of them make \(Vs)." }
    }
    /// A number of `d`ths as a mixed number, lowest terms: "1½" (glyphs, for the picture's names), or "4 1/2".
    public static func mixed(_ n: Int, _ d: Int, glyph: Bool = true) -> String {
        func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
        let g = max(1, gcd(n, d)), a = n / g, b = d / g, w = a / b, r = a % b
        if r == 0 { return "\(w)" }
        let glyphs = ["1/2": "½", "1/3": "⅓", "2/3": "⅔", "1/4": "¼", "3/4": "¾"]
        let f = glyph ? (glyphs["\(r)/\(b)"] ?? "\(r)/\(b)") : "\(r)/\(b)"
        return w == 0 ? f : glyph ? "\(w)\(f)" : "\(w) \(f)"
    }
    /// Problems 1–3 one edge a half, 4–6 two, then all three, B × h, and thirds in turn; at most 72 small cubes.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let mode = i < 6 ? 0 : [0, 1, 2][i % 3], d = mode == 2 ? 3 : 2
        for _ in 0..<500 {
            let x = Area6.r(d, 6, &rng), y = Area6.r(d, 6, &rng), z = Area6.r(d, 6, &rng)
            if x * y * z > 72 { continue }
            let odd = [x, y, z].filter { $0 % d != 0 }.count
            if mode == 0 ? odd != (i < 3 ? 1 : i < 6 ? 2 : 3) : odd == 0 { continue }
            return numbers(x: x, y: y, z: z, d: d, mode: mode)
        }
        return numbers(x: 3, y: 4, z: 2)
    }

    public static let spec = LessonSpec(id: "g6-fracvol", title: "Volume with fraction edges", master: "bars",
        generate: { rng, i in make(&rng, i) },
        idea: { _ in "Small cubes with edges of 1/2 fill the box; 8 of them make one whole cube." },
        depends: ["g5-volume", "g5-multfrac"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6), CheckItem(7)]) { n in
        let p = Parts(n)
        let coverHint = "Drag across the floor until every small square is covered."
        let cover = Area6.hand(1, "Cover the floor. Drag across it.", box: "c", want: Double(p.floor), hint: coverHint) { v in
            let c = Area6.int(v, "c", 0)
            return c == p.floor ? .right : .soft("Cover every square: \(c) of \(p.floor) so far.")
        }
        let buildHint = "Each layer is \(p.edge(1)) high."
        let build = Area6.hand(2, "Build it up to \(p.edge(p.z)). Drag up, a layer at a time.", box: "l", want: Double(p.z), hint: buildHint) { v in
            let l = Area6.int(v, "l", 0)
            return l == p.z ? .right : .wrong("That’s \(p.edge(l)) high. Build it to \(p.edge(p.z)).")
        }
        let shareHint = "\(p.per) small cubes make one whole: \(p.N) ÷ \(p.per)."
        let prompt: MathLine = [.num(Double(p.N)), .op("÷"), .num(Double(p.per)), .op("="), .box("w")] + (p.whole ? [] : [.frac(.box("n"), .box("d"))])
        let w = p.N / p.per, g = { (a: Int, b: Int) -> Int in var a = a, b = b; while b != 0 { (a, b) = (b, a % b) }; return a }(p.N % p.per, p.per)
        var expected: [String: Double] = ["w": Double(w)]
        if !p.whole { expected["n"] = Double((p.N % p.per) / g); expected["d"] = Double(p.per / g) }
        let write = LessonStep(StepWords(say: "Write how many whole cubes.", hint: shareHint, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: expected, hint: shareHint, explain: "That makes \(p.Vs).",
                check: { v in
                    guard let w = v["w"] else { return .soft("Write the whole number and the fraction.") }
                    var x = w
                    if !p.whole {
                        guard let a = v["n"], let b = v["d"], b != 0 else { return .soft("Write the whole number and the fraction.") }
                        x += a / b
                    }
                    return p.written(x).map { .wrong($0) } ?? .right
                }, incomplete: "Write the whole number and the fraction."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [Area6.ask("Cover the floor.", coverHint), cover, build, write,
                LessonStep(StepWords(say: p.why, hint: shareHint, action: "Next problem"), picture: ["at": 4])]
    }
}
