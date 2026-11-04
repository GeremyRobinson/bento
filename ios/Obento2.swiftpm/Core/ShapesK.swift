import Foundation

/// What Kindergarten's Shapes chapter shares (design/gradeK.md chapter 2, the preview design/prototype/gradeK-ch2.html):
/// the shapes' names and sides, the words a child taps, and how the voice's lines are put together. Flat shapes have
/// their corners on the paper's crossings, so a side is a line of the grid's own squares; solids stand on the paper as
/// in Unit cubes (one block is one floor square).
public enum ShapesK {
    /// The flat shapes, as the web's k-shapes has them: kind, name and how many straight sides.
    public static let kinds: [(kind: String, sides: Int)] = [("circle", 0), ("triangle", 3), ("square", 4), ("rectangle", 4), ("hexagon", 6)]
    public static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    /// "a triangle", "an orange".
    public static func an(_ s: String) -> String { s.first.map { "aeiou".contains($0) } == true ? "an \(s)" : "a \(s)" }
    public static func sidesWord(_ n: Int) -> String { n == 1 ? "1 side" : "\(n) sides" }
    /// "1, 2, 3".
    static func countUp(_ n: Int) -> String { (1...max(1, n)).map(String.init).joined(separator: ", ") }
    static func int(_ v: [String: Double], _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    /// JavaScript's Math.round (halves up), so the preview's shapes come out the same.
    static func jsRound(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }

    /// The names to tap for a shape (the web's): the four-sided one offered is the square for a square, the rectangle
    /// for a rectangle, else by the problem's size.
    public static func choices(kind: String, w: Int, h: Int) -> [String] {
        let four = kind == "square" || kind == "rectangle" ? kind : (w + h) % 2 == 1 ? "square" : "rectangle"
        return kinds.filter { $0.sides != 4 || $0.kind == four }.map(\.kind)
    }
    /// A name tapped that isn't the shape's: the web's words.
    public static func nameMiss(kind: String, picked o: String) -> String {
        let n = kinds.first { $0.kind == kind }?.sides ?? 0, os = kinds.first { $0.kind == o }?.sides ?? 0
        if n == 0 { return "\(cap(an(o))) has straight sides and corners. This shape is round, with none." }
        if os == 0 { return "A circle is round, with no corners. This shape has \(sidesWord(n))." }
        return "\(cap(an(o))) has \(sidesWord(os)). This shape has \(sidesWord(n))."
    }
}

// MARK: - Flat shapes

/// Flat shapes (the web's k-shapes, K.G.A.2, K.G.B.4). What's counted is sides and corners, one tap each; every corner
/// sits on a crossing of the squares, so a side is a straight line of the grid's own squares. The web's sizes at 3
/// squares a web unit; a turned shape takes the nearest turn that keeps its corners on crossings (4 across and 1 up is
/// 14°, 5 and 3 is 31°, 1 and 1 is 45°); the hexagon is 24 × 20 squares (or 20 × 24 stood on a corner), a circle 26
/// across at most (the design's 32 × 28 and 30 showed at 67%).
///
/// Tap each side (it lights, numbered outside it), tap each corner (a dot, numbered), tap its name. Then a turned shape
/// turns upright and back (the same shape), and a square's or rectangle's side lifts off as a stick and lays itself on
/// each side in turn. The record: `3 sides · 3 corners`, `It's a triangle.` (a square adds `4 sides the same`).
///
/// "at": 0 sides, 1 corners, 2 name, 3 done.
public enum FlatShapes {
    public static let turns: [String: [Int]] = ["circle": [0], "triangle": [-30, -15, 0, 15, 30], "square": [0, 15, 30, 45], "rectangle": [-15, 0, 15], "hexagon": [0, 15, 30]]
    /// The grid's turns: a side going this far across and up.
    static let gridTurn: [Int: (Int, Int)] = [15: (4, 1), 30: (5, 3), 45: (1, 1)]
    public static let say: [String: String] = [
        "circle": "Round, with no sides and no corners: a circle.",
        "triangle": "3 straight sides and 3 corners make a triangle, turned or not.",
        "square": "4 sides the same and 4 corners make a square, turned or not.",
        "rectangle": "2 long sides, 2 short sides and 4 corners make a rectangle, turned or not.",
        "hexagon": "6 straight sides and 6 corners make a hexagon, turned or not.",
    ]

    public static func numbers(shape: Int, w: Int, h: Int, turn: Int) -> Numbers { ["shape": Double(shape), "w": Double(w), "h": Double(h), "turn": Double(turn)] }

    public struct Parts: Sendable {
        public let shape: Int, w: Int, h: Int, turn: Int
        public let kind: String, n: Int
        /// The corners, in squares from the shape's top-left (0, 0), going round; none for a circle.
        public let corners: [(Int, Int)]
        /// Its size in squares; a circle's radius.
        public let width: Int, height: Int, r: Int
        /// The angle it's turned through (radians, the grid's nearest turn).
        public let angle: Double
        public init(_ x: Numbers) {
            shape = max(0, min(4, ShapesK.int(x, "shape", 1))); w = ShapesK.int(x, "w", 9); h = ShapesK.int(x, "h", 7); turn = ShapesK.int(x, "turn")
            kind = ShapesK.kinds[shape].kind; n = ShapesK.kinds[shape].sides
            let g = FlatShapes.grid(kind, w: w, h: h, turn: turn)
            corners = g.pts; width = g.w; height = g.h; r = g.r; angle = g.angle
        }
        public var round: Bool { n == 0 }
        public var turned: Bool { turn != 0 }
        public var choices: [String] { ShapesK.choices(kind: kind, w: w, h: h) }
        public var right: Int { choices.firstIndex(of: kind) ?? 0 }
        /// A name tapped (its place among the choices): what to say, nil when it's right.
        public func picked(_ i: Int) -> String? {
            guard choices.indices.contains(i), i != right else { return choices.indices.contains(i) ? nil : "Tap its name." }
            return ShapesK.nameMiss(kind: kind, picked: choices[i])
        }
        public var why: String { FlatShapes.say[kind] ?? "" }
        /// The record's lines.
        public var record: [String] {
            ["\(n) sides · \(n) corners"] + (kind == "square" ? ["4 sides the same"] : []) + ["It’s \(ShapesK.an(kind))."]
        }
    }

    /// The shape on the squares (the preview's gridShape).
    static func grid(_ kind: String, w: Int, h: Int, turn: Int) -> (pts: [(Int, Int)], w: Int, h: Int, r: Int, angle: Double) {
        let T = abs(turn), sg = turn < 0 ? -1 : 1
        func norm(_ p: [(Int, Int)]) -> [(Int, Int)] {
            let x0 = p.map(\.0).min() ?? 0, y0 = p.map(\.1).min() ?? 0
            return p.map { ($0.0 - x0, $0.1 - y0) }
        }
        func box(_ p: [(Int, Int)]) -> (Int, Int) { (p.map(\.0).max() ?? 0, p.map(\.1).max() ?? 0) }
        // a circle 26 squares across at most, and the hexagon 24 × 20 (sides 12 and a little under 12, so it looks even),
        // so every shape shows at 75% with its counts round it
        if kind == "circle" { let r = min(13, ShapesK.jsRound(1.5 * Double(w))); return ([], 2 * r, 2 * r, r, 0) }
        if kind == "hexagon" {
            let pts = T > 0 ? [(10, 0), (20, 6), (20, 18), (10, 24), (0, 18), (0, 6)] : [(0, 10), (6, 0), (18, 0), (24, 10), (18, 20), (6, 20)]
            return (pts, T > 0 ? 20 : 24, T > 0 ? 24 : 20, 0, T > 0 ? .pi / 6 : 0)
        }
        let g = T > 0 ? gridTurn[T] ?? (1, 0) : (1, 0)
        let dir = (g.0, sg * (T > 0 ? g.1 : 0)), dl = hypot(Double(dir.0), Double(dir.1)), ang = atan2(Double(dir.1), Double(dir.0))
        var pts: [(Int, Int)]
        if kind == "square" || kind == "rectangle" {
            var k1 = max(2, ShapesK.jsRound(3 * Double(w) / dl)), k2 = kind == "square" ? k1 : max(2, ShapesK.jsRound(3 * Double(h) / dl))
            if T > 0 && kind == "square" { k1 = min(k1, 27 / (abs(dir.0) + abs(dir.1))); k2 = k1 }
            // an upright square 26 squares a side at most (so it shows at 75% with its counts round it)
            if T == 0 && kind == "square" { k1 = min(k1, 26); k2 = k1 }
            if kind == "rectangle" { k1 = max(k1, Int((1.5 * Double(k2)).rounded(.up))) }
            let u = (k1 * dir.0, k1 * dir.1), v = (-k2 * dir.1, k2 * dir.0)
            pts = norm([(0, 0), u, (u.0 + v.0, u.1 + v.1), v])
        } else {
            // a triangle turned so it would stand more than 27 squares tall is drawn a little smaller (corners still on
            // crossings), so it shows at 75% with its counts round it
            func tri(_ k: Double) -> [(Int, Int)] {
                let W = k * Double(w), H = k * Double(h), c = cos(ang), s = sin(ang)
                return norm([(-W / 2, H / 3), (W / 2, H / 3), (0.12 * W, -2 * H / 3)].map { p in (ShapesK.jsRound(p.0 * c - p.1 * s), ShapesK.jsRound(p.0 * s + p.1 * c)) })
            }
            pts = tri(3)
            var k = 3.0
            while box(pts).1 > 27 && k > 2 { k -= 0.1; pts = tri(k) }
        }
        let b = box(pts)
        return (pts, b.0, b.1, 0, ang)
    }

    /// The web's generator as it is: the first three a circle, triangle or square, upright.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let easy = index < 3
        let shape = easy ? ShapesK.pick([0, 1, 2], &rng) : Int.random(in: 0...4, using: &rng)
        let kind = ShapesK.kinds[shape].kind
        let h = kind == "rectangle" ? Int.random(in: 4...6, using: &rng) : Int.random(in: 6...9, using: &rng)
        let w = kind == "rectangle" ? Int.random(in: Int((1.5 * Double(h)).rounded(.up))...11, using: &rng) : Int.random(in: 7...10, using: &rng)
        return numbers(shape: shape, w: w, h: h, turn: easy ? 0 : ShapesK.pick(turns[kind] ?? [0], &rng))
    }

    public static let spec = LessonSpec(id: "k-shapes", title: "Flat shapes", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { _ in [.text("What shape is this?")] },
        idea: { _ in "A shape's sides and corners tell you its name." },
        depends: [],
        check: [CheckItem(3, when: { Parts($0).kind == "triangle" && Parts($0).turned }), CheckItem(3, when: { Parts($0).kind == "square" && Parts($0).turned }),
                CheckItem(3, when: { Parts($0).kind == "rectangle" }), CheckItem(3, when: { Parts($0).kind == "hexagon" })]) { x in
        let P = Parts(x), n = P.n, round = P.round
        let trace = round ? "Run your finger around the edge. Is any part straight?" : "Put your finger on one corner. Go around the shape and count each straight side."
        let sides = LessonStep(StepWords(say: "Tap each side.", hint: trace, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": Double(n)], hint: trace,
                               explain: round ? "The edge of a circle is round all the way. It has 0 straight sides." : "\(ShapesK.countUp(n)). It has \(n) straight sides.",
                               check: { v in ShapesK.int(v, "s", -1) == n ? .right : .wrong("You counted that side.") }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let cornerHint = round ? "A corner is a point where two straight sides meet. Can you find one?" : "A corner is where two sides meet. Touch each corner as you count."
        // the circle: what its edge showed is said with the next thing to do (the preview says it a moment, then moves on)
        let corners = LessonStep(StepWords(say: round ? "It’s round. No straight sides. Tap each corner." : "Tap each corner.", hint: cornerHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(n)], hint: cornerHint,
                               explain: round ? "There are no points where sides meet. It has 0 corners." : "\(ShapesK.countUp(n)). It has \(n) corners.",
                               check: { v in ShapesK.int(v, "c", -1) == n ? .right : .wrong("You counted that corner.") }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let nameHint = round ? "Which shape is round, with no sides and no corners?" : "Which shape has \(ShapesK.sidesWord(n)) and \(n) corners?"
        let name = LessonStep(StepWords(say: round ? "No corners. It’s round all the way. Tap its name." : "Tap its name.", hint: nameHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(P.right)],
                               known: P.choices.indices.filter { $0 != P.right }.map { (["p": Double($0)], P.picked($0) ?? "") }, hint: nameHint,
                               explain: P.why, check: { v in P.picked(ShapesK.int(v, "p", -1)).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [sides, corners, name, done]
    }
}

// MARK: - Draw shapes

/// Draw shapes (gk-draw, new; K.G.B.5, K.G.B.4). One block is one step of a side: corners sit on the crossings of the
/// strong lines, so a straight side is 1–10 blocks long and can be counted. The drawing place is 10 × 6 blocks of the
/// paper's own grid, a faint frame round it, its block crossings dotted faintly. Tap crossings to place corners (a side
/// draws from the last to the new one), tap the first corner again to close the shape; a corner can be dragged. Closed,
/// it's checked; the drawing stays to fix. A circle: drag out from the centre dot, its size snapping to whole blocks.
///
/// "at": 0 draw, 1 done. The drawing is kept (`n`, `x<i>`, `y<i>`, `closed`; a circle's `r`).
public enum DrawShape {
    public static let kinds = ["triangle", "square", "rectangle", "hexagon", "circle"]
    public static let sides: [String: Int] = ["triangle": 3, "square": 4, "rectangle": 4, "hexagon": 6, "circle": 0]
    /// The drawing place, in blocks.
    public static let across = 10, down = 6
    public static let say: [String: String] = [
        "triangle": "3 straight sides joined at 3 corners make a triangle.",
        "square": "4 sides the same joined at 4 square corners make a square.",
        "rectangle": "2 long sides and 2 short sides joined at 4 square corners make a rectangle.",
        "hexagon": "6 straight sides joined at 6 corners make a hexagon.",
        "circle": "A circle is round all the way: no sides, no corners.",
    ]
    public static func numbers(kind: String) -> Numbers { ["kind": Double(kinds.firstIndex(of: kind) ?? 0)] }

    public struct Parts: Sendable {
        public let kind: String
        public init(_ x: Numbers) { kind = DrawShape.kinds[max(0, min(4, ShapesK.int(x, "kind")))] }
        public var circle: Bool { kind == "circle" }
        public var want: Int { DrawShape.sides[kind] ?? 3 }
        public var say: String { "Draw \(ShapesK.an(kind))." }
        public var why: String { DrawShape.say[kind] ?? "" }
    }

    /// What's wrong with a closed drawing, as the paper shows it: the words, whether each straight side's blocks are
    /// numbered (a square that isn't), and which sides are longer (a tilted square that isn't).
    public struct Miss: Equatable, Sendable {
        public let msg: String
        public var blocks = false
        public var longer: [Bool]? = nil
    }
    /// A closed drawing's own check (on whole block steps, so exact): nil when it's right.
    public static func check(_ kind: String, _ P: [(Int, Int)]) -> Miss? {
        let n = P.count, want = sides[kind] ?? 3
        if n != want { return Miss(msg: "That has \(n) sides. \(ShapesK.cap(ShapesK.an(kind))) has \(want).") }
        if kind == "triangle" || kind == "hexagon" { return nil }
        let e = P.indices.map { i in (P[(i + 1) % n].0 - P[i].0, P[(i + 1) % n].1 - P[i].1) }
        let l2 = e.map { $0.0 * $0.0 + $0.1 * $0.1 }
        let square = e.indices.allSatisfy { i in e[i].0 * e[(i + 1) % n].0 + e[i].1 * e[(i + 1) % n].1 == 0 }
        if !square { return Miss(msg: "Make square corners, like the grid’s.") }
        let same = l2.allSatisfy { $0 == l2[0] }
        if kind == "rectangle" { return same ? Miss(msg: "That’s a square. Make 2 sides longer.") : nil }
        if same { return nil }
        if e.allSatisfy({ $0.0 == 0 || $0.1 == 0 }) {
            return Miss(msg: "Sides \(e.map { String(abs($0.0 + $0.1)) }.joined(separator: ", ")). Make them all the same.", blocks: true)
        }
        let lo = l2.min() ?? 0
        return Miss(msg: "These \(l2.filter { $0 > lo }.count) are longer.", longer: l2.map { $0 > lo })
    }

    static func orient(_ a: (Int, Int), _ b: (Int, Int), _ c: (Int, Int)) -> Int { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
    static func onSeg(_ a: (Int, Int), _ b: (Int, Int), _ p: (Int, Int)) -> Bool {
        min(a.0, b.0) <= p.0 && p.0 <= max(a.0, b.0) && min(a.1, b.1) <= p.1 && p.1 <= max(a.1, b.1)
    }
    /// Two sides meet (cross or touch).
    static func meet(_ a: (Int, Int), _ b: (Int, Int), _ c: (Int, Int), _ d: (Int, Int)) -> Bool {
        let o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b)
        if ((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) && ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0)) { return true }
        return (o1 == 0 && onSeg(a, b, c)) || (o2 == 0 && onSeg(a, b, d)) || (o3 == 0 && onSeg(c, d, a)) || (o4 == 0 && onSeg(c, d, b))
    }
    /// Why a set of corners can't be (the paper's reason: sides crossing, three in a line), or nil.
    public static func refuse(_ P: [(Int, Int)], closed: Bool) -> String? {
        let n = P.count
        guard n > 0 else { return nil }
        if Set(P.map { "\($0.0),\($0.1)" }).count != n { return "Sides can’t cross." }
        let last = n - 1 + (closed ? 1 : 0)
        if n >= 3 { for i in 1..<max(1, last) where orient(P[i - 1], P[i], P[(i + 1) % n]) == 0 { return "Those are in a line." } }
        if closed && n >= 3 && orient(P[n - 1], P[0], P[1]) == 0 { return "Those are in a line." }
        var segs: [(Int, Int)] = []
        for i in 0..<last { segs.append((i, (i + 1) % n)) }
        for a in segs.indices { for b in segs.indices where b > a {
            let (i, j) = segs[a], (k, l) = segs[b]
            if i == k || i == l || j == k || j == l { continue }
            if meet(P[i], P[j], P[k], P[l]) { return "Sides can’t cross." }
        } }
        return nil
    }
    /// The drawing kept on the run (the hands keep it as it's drawn): its corners, in blocks.
    public static func corners(_ v: [String: Double], prefix: String = "") -> [(Int, Int)] {
        let n = ShapesK.int(v, prefix + "n")
        return (0..<max(0, n)).map { (ShapesK.int(v, prefix + "x\($0)"), ShapesK.int(v, prefix + "y\($0)")) }
    }
    /// A refusal's code in the step's box (see the step's check).
    public static func code(_ why: String) -> Double { why.hasPrefix("Sides") ? -1 : -2 }
    public static func keep(_ P: [(Int, Int)], closed: Bool) -> Numbers {
        var k: Numbers = ["n": Double(P.count), "closed": closed ? 1 : 0]
        for (i, p) in P.enumerated() { k["x\(i)"] = Double(p.0); k["y\(i)"] = Double(p.1) }
        return k
    }

    /// Easy first: index 0–2 a triangle or a rectangle; 3–5 squares too; 6+ any, with hexagons and circles.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let list = index < 3 ? ["triangle", "rectangle"] : index < 6 ? ["triangle", "rectangle", "square"] : kinds
        return numbers(kind: ShapesK.pick(list, &rng))
    }

    public static let spec = LessonSpec(id: "gk-draw", title: "Draw shapes", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text(Parts(x).say)] },
        idea: { _ in "Straight sides joined at corners make a shape." },
        depends: ["k-shapes"],
        check: [CheckItem(3, when: { Parts($0).kind == "triangle" }), CheckItem(3, when: { Parts($0).kind == "square" }),
                CheckItem(3, when: { Parts($0).kind == "rectangle" }), CheckItem(6, when: { Parts($0).kind == "hexagon" })]) { x in
        let P = Parts(x)
        let hint = P.circle ? "Put your finger on the dot and drag out." : "Tap a dot for each corner. Tap the first one again to close it."
        let draw = LessonStep(StepWords(say: P.say, hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("d")], expected: ["d": 1], hint: hint, explain: P.why,
                               check: { v in
                                   if P.circle { return ShapesK.int(v, "d") >= 1 ? .right : .soft("Drag out from the dot.") }
                                   // a corner the paper won't take: its reason
                                   let d = ShapesK.int(v, "d")
                                   if d == -1 { return .wrong("Sides can’t cross.") }
                                   if d == -2 { return .wrong("Those are in a line.") }
                                   return DrawShape.check(P.kind, DrawShape.corners(v, prefix: "kept.")).map { .wrong($0.msg) } ?? .right
                               }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 1])
        return [draw, done]
    }
}

// MARK: - Solid shapes

/// Solid shapes (the web's k-solids, K.G.A.3, K.G.B.4, K.G.A.1; 3D). One block is one floor square, as in Unit cubes.
/// Flat first: the solid seen straight down beside a flat shape with the same outline (a square for the cube; a circle
/// for the sphere and an upright cylinder or cone; a rectangle or a triangle for one on its side), 2 blocks apart. Drag
/// the paper up and it tilts: the solid rises off it, the flat one stays. Tap the solid one; tap a flat face (or None,
/// the sphere's answer): its flat faces light as it turns once; tap rolls or slides, then push it; tap its name.
///
/// "at": 0 tilt, 1 solid, 2 face, 3 roll, 4 name, 5 done.
public enum Solids3K {
    public struct Solid: Sendable {
        public let kind: String, flat: String, rolls: Bool, faces: Int, isWhat: String, wherePart: String, things: [String]
    }
    public static let solids: [Solid] = [
        Solid(kind: "cube", flat: "square", rolls: false, faces: 6, isWhat: "has 6 flat square faces", wherePart: "the top, the bottom and 4 sides", things: ["block", "die", "box"]),
        Solid(kind: "sphere", flat: "circle", rolls: true, faces: 0, isWhat: "is round all over", wherePart: "it is round all over, so no part of it is flat", things: ["ball", "orange", "marble"]),
        Solid(kind: "cylinder", flat: "rectangle", rolls: true, faces: 2, isWhat: "has two flat circle ends", wherePart: "one circle at each end", things: ["can", "drum", "candle"]),
        Solid(kind: "cone", flat: "triangle", rolls: true, faces: 1, isWhat: "has one flat circle and a point", wherePart: "the circle at its wide end", things: ["party hat", "ice-cream cone", "traffic cone"]),
    ]
    public static func numbers(shape: Int, thing: Int = -1, turn: Int = 0, side: Int = 0) -> Numbers {
        ["shape": Double(shape), "thing": Double(thing), "turn": Double(turn), "side": Double(side)]
    }
    public static let rollChoices = ["rolls", "slides"]

    public struct Parts: Sendable {
        public let shape: Int, thing: Int, turn: Int, side: Int
        public init(_ x: Numbers) {
            shape = max(0, min(3, ShapesK.int(x, "shape"))); thing = max(-1, min(2, ShapesK.int(x, "thing", -1)))
            turn = max(0, min(2, ShapesK.int(x, "turn"))); side = ShapesK.int(x, "side") == 1 ? 1 : 0
        }
        public var s: Solid { Solids3K.solids[shape] }
        public var kind: String { s.kind }
        /// Lying on its side (a cylinder or cone, its axis along the paper).
        public var lying: Bool { turn == 2 && thing < 0 }
        /// An ice-cream cone stands on its point.
        public var upsideDown: Bool { kind == "cone" && thing == 1 }
        public var thingName: String? { thing >= 0 ? s.things[thing] : nil }
        /// The flat shape with the same outline seen from above.
        public var lookalike: String {
            switch kind { case "cube": "square"; case "sphere": "circle"; case "cylinder": lying ? "rectangle" : "circle"; default: lying ? "triangle" : "circle" }
        }
        /// The four names to tap (the web's: the answer, its flat look-alike and two other solids, in an order fixed by the problem).
        public var names: [String] {
            var others = Solids3K.solids.filter { $0.kind != kind }
            others.remove(at: (turn + thing + 3) % 3)
            let all = ([kind, s.flat] + others.map(\.kind)).map(ShapesK.cap), k = shape % 4
            return Array(all[k...] + all[..<k])
        }
        public var rightName: Int { names.firstIndex(of: ShapesK.cap(kind)) ?? 0 }
        public func nameMiss(_ i: Int) -> String? {
            guard names.indices.contains(i), i != rightName else { return nil }
            let n = names[i].lowercased()
            if n == s.flat { return "\(ShapesK.cap(ShapesK.an(n))) is flat, like a drawing. This shape is solid: \(ShapesK.an(kind))." }
            if (n == "cone" && kind == "cylinder") || (n == "cylinder" && kind == "cone") { return "A cone comes to a point. A cylinder has two flat ends." }
            let o = Solids3K.solids.first { $0.kind == n }!
            return "\(ShapesK.cap(ShapesK.an(o.kind))) \(o.isWhat). This one \(s.isWhat)."
        }
        /// rolls or slides guessed wrong: the web's line.
        public var rollMiss: String {
            kind == "cube" ? "A cube has flat faces and corners. It slides, but it can’t roll."
                : kind == "sphere" ? "A sphere is round all over. It rolls every way." : "\(ShapesK.cap(ShapesK.an(kind))) has a round side. Lay it down and it rolls."
        }
        /// A round part tapped for a flat face.
        public var roundTap: String { kind == "sphere" ? "That’s round. It’s round all over." : "That’s round. Find a flat part." }
        /// Where the flat faces are, as the See says it.
        public var seeLine: String { kind == "sphere" ? "It is round all over, so no part of it is flat." : "\(ShapesK.cap(s.wherePart))." }
        public var why: String { "It \(s.isWhat): \(ShapesK.an(kind))." }
        public var record: [String] { [s.faces > 0 ? "It has a flat face." : "No flat face.", s.rolls ? "It rolls." : "It slides.", "It’s \(ShapesK.an(kind))."] }
    }

    /// The web's generator as it is (any solid; the first three plain and upright; every third a thing; else a cylinder
    /// or cone upright or on its side, a cube either way round). New: which side the solid is on.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let shape = Int.random(in: 0...3, using: &rng), side = Int.random(in: 0...1, using: &rng)
        if index < 3 { return numbers(shape: shape, side: side) }
        if index % 3 == 2 { return numbers(shape: shape, thing: Int.random(in: 0...2, using: &rng), side: side) }
        let kind = solids[shape].kind
        let turn = kind == "cylinder" || kind == "cone" ? ShapesK.pick([0, 2], &rng) : kind == "cube" ? Int.random(in: 0...1, using: &rng) : 0
        return numbers(shape: shape, turn: turn, side: side)
    }

    public static let spec = LessonSpec(id: "k-solids", title: "Solid shapes", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { _ in [.text("Look at this shape.")] },
        idea: { _ in "Flat shapes lie on paper, but solid shapes are ones you can hold." },
        depends: ["k-shapes"],
        check: [CheckItem(3, when: { Parts($0).kind == "cylinder" && Parts($0).turn == 2 }), CheckItem(4, when: { Parts($0).kind == "cone" }),
                CheckItem(5, when: { Parts($0).kind == "cube" && Parts($0).thing >= 0 }), CheckItem(6, when: { Parts($0).kind == "sphere" })]) { x in
        let P = Parts(x), s = P.s
        let tilt = LessonStep(StepWords(say: "Tilt the paper.", hint: "Drag the paper up.", action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": 1], hint: "Drag the paper up.", explain: "The solid rises off the paper. The flat one stays.",
                               check: { v in ShapesK.int(v, "t") == 1 ? .right : .soft("Drag it further up.") }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let solid = LessonStep(StepWords(say: "Tap the solid one.", hint: "Which one rose off the paper?", action: "Check"),
            answer: AnswerTask(prompt: [.box("w")], expected: ["w": 1], known: [(["w": 0], "That one is flat. It lies on the paper.")],
                               hint: "Which one rose off the paper?", explain: "It stands up off the paper: it's solid.",
                               check: { v in ShapesK.int(v, "w") == 1 ? .right : .wrong("That one is flat. It lies on the paper.") }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        // f: 1 a flat face tapped, 0 None, −1 a round part
        let faceWant = s.faces > 0 ? 1.0 : 0.0
        let face = LessonStep(StepWords(say: "Tap a flat face.", hint: "Could it stand still on a table on one side?", action: "Check"),
            answer: AnswerTask(prompt: [.box("f")], expected: ["f": faceWant], hint: "Could it stand still on a table on one side?", explain: P.seeLine,
                               check: { v in
                                   let f = ShapesK.int(v, "f", -1)
                                   if Double(f) == faceWant { return .right }
                                   return .wrong(f == 0 ? "This part is flat." : P.roundTap)
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        // the See (its flat faces light as it turns once) is said with the next thing to do
        let roll = LessonStep(StepWords(say: "\(P.seeLine) Tap rolls or slides.", hint: "Is any part of it round?", action: "Check"),
            answer: AnswerTask(prompt: [.box("r")], expected: ["r": s.rolls ? 0 : 1], known: [(["r": s.rolls ? 1 : 0], P.rollMiss)], hint: "Is any part of it round?",
                               explain: s.rolls ? "It has a round part, so it rolls." : "It has only flat faces and corners, so it slides but doesn't roll.",
                               check: { v in ShapesK.int(v, "r", -1) == (s.rolls ? 0 : 1) ? .right : .wrong(P.rollMiss) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let nameHint = "Use what you found: it \(s.rolls ? "rolls" : "doesn’t roll") and has \(s.faces == 0 ? "no flat face" : s.faces == 1 ? "1 flat face" : "\(s.faces) flat faces"). Which solid is like that?"
        let name = LessonStep(StepWords(say: "Tap its name.", hint: nameHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(P.rightName)],
                               known: P.names.indices.filter { $0 != P.rightName }.map { (["n": Double($0)], P.nameMiss($0) ?? "") }, hint: nameHint,
                               explain: "It \(s.isWhat). It's \(ShapesK.an(s.kind)).",
                               check: { v in P.nameMiss(ShapesK.int(v, "n", -1)).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 5])
        return [tilt, solid, face, roll, name, done]
    }
}

// MARK: - Where is it?

/// Where is it? (gk-position, new; K.G.A.1; 3D). One block is one floor square, as in Unit cubes; each solid stands on
/// 2 × 2 blocks. A floor of 10 × 6 blocks holds 2–4 solids (cube, sphere, cone, cylinder) that never touch; from the 7th
/// problem a table (a slab 4 × 2 blocks on legs 2 blocks high, so a solid fits under it). Flat first with the words
/// written; then the paper tilts by itself (in front of and behind are depth). Put it: drag the thing across the floor,
/// block by block, up onto a flat top or under the table; the readout says where it is from the other one, in the
/// instruction's words. Find it: tap the one the words name.
///
/// Numbers: `kind` (0 put, 1 find), `word`, `n` solids each `k<j>` (its kind), `x<j>`, `y<j>` (its back-left block),
/// `on<j>` (−1 the floor, 9 the table, else the solid it sits on); the table `tx`, `ty` (−1: none); `ref` (9 the
/// table), `who` (the one to move or to find); a put's target `gx`, `gy`, `gon`. "at": 0 put or find, 1 done.
public enum WhereIsIt {
    public static let words = ["beside", "next to", "above", "in front of", "behind", "below"]
    public static let solids = ["cube", "sphere", "cone", "cylinder"]
    public static let table = 9
    public static let define: [String: String] = ["behind": "Behind is the far side.", "in front of": "In front is the near side.", "beside": "Beside is just left or right of it.",
                                                  "next to": "Next to is just left or right of it.", "above": "Above is on top of it.", "below": "Below is under it."]
    /// What a put let go reads (the box's codes): 0 not by it, 1 beside, 2 above, 3 in front of, 4 behind, 5 below,
    /// 8 on a round top (it slides off).
    public static let codes = [1: "beside", 2: "above", 3: "in front of", 4: "behind", 5: "below"]
    public static func code(_ rel: String?) -> Int { rel.flatMap { r in codes.first { $0.value == r }?.key } ?? 0 }

    public struct Thing: Equatable, Sendable {
        /// 0–3 a solid (cube, sphere, cone, cylinder), 9 the table.
        public var kind: Int
        public var bx: Int, by: Int
        /// −1 the floor, 9 the table, else the solid it sits on.
        public var on: Int
        public init(kind: Int, bx: Int, by: Int, on: Int = -1) { self.kind = kind; self.bx = bx; self.by = by; self.on = on }
        public var name: String { kind == WhereIsIt.table ? "table" : WhereIsIt.solids[kind] }
        public var isTable: Bool { kind == WhereIsIt.table }
        /// Its footprint in blocks.
        public var foot: (x: Int, y: Int, w: Int, h: Int) { (bx, by, isTable ? 4 : 2, 2) }
        /// A thing can sit on its top.
        public var flatTop: Bool { kind == 0 || kind == 3 || isTable }
    }
    static func touch(_ a: (x: Int, y: Int, w: Int, h: Int), _ b: (x: Int, y: Int, w: Int, h: Int)) -> Bool {
        a.x <= b.x + b.w && b.x <= a.x + a.w && a.y <= b.y + b.h && b.y <= a.y + a.h
    }
    /// Where `a` is from `ref` (its id: an index, or 9 the table), in the lesson's words, or nil when it isn't right by it.
    public static func relation(_ a: Thing, to refId: Int, _ ref: Thing) -> String? {
        if ref.isTable {
            if a.on == table { return "above" }
            let f = ref.foot
            return a.on < 0 && a.bx >= f.x && a.bx + 2 <= f.x + 4 && a.by >= f.y && a.by + 2 <= f.y + 2 ? "below" : nil
        }
        if a.on == refId { return "above" }
        if a.on != ref.on { return nil }
        if a.bx == ref.bx && a.by == ref.by + 2 { return "in front of" }
        if a.bx == ref.bx && a.by == ref.by - 2 { return "behind" }
        if a.by == ref.by && abs(a.bx - ref.bx) == 2 { return "beside" }
        return nil
    }
    /// The same place in the words asked (beside is next to).
    public static func same(_ rel: String?, _ word: String) -> Bool { rel == word || (rel == "beside" && word == "next to") }
    /// A relation as the words asked would say it.
    public static func say(_ rel: String, asked word: String) -> String { rel == "beside" && word == "next to" ? "next to" : rel }

    public static let sayWhy: [String: @Sendable (String, String) -> String] = [
        "behind": { m, r in "Behind is the far side: the \(r) is between you and the \(m)." },
        "in front of": { m, r in "In front is the near side: the \(m) is between you and the \(r)." },
        "beside": { m, r in "Beside is just left or right: the \(m) and the \(r) are side by side." },
        "next to": { m, r in "Next to is just left or right: the \(m) and the \(r) are side by side." },
        "above": { m, r in "Above is on top: the \(m) sits on the \(r)." },
        "below": { m, r in "Below is under: the \(r) is over the \(m)." },
    ]

    public struct Parts: Sendable {
        public let put: Bool, word: String
        public let things: [Thing]
        public let table: Thing?
        public let ref: Int, who: Int
        /// A put's place (its back-left block, and what it sits on).
        public let target: Thing?
        public init(_ x: Numbers) {
            put = ShapesK.int(x, "kind") == 0
            word = WhereIsIt.words[max(0, min(5, ShapesK.int(x, "word")))]
            let n = max(1, min(4, ShapesK.int(x, "n", 2)))
            things = (0..<n).map { j in Thing(kind: max(0, min(3, ShapesK.int(x, "k\(j)", j))), bx: ShapesK.int(x, "x\(j)"), by: ShapesK.int(x, "y\(j)"), on: ShapesK.int(x, "on\(j)", -1)) }
            let tx = ShapesK.int(x, "tx", -1)
            table = tx >= 0 ? Thing(kind: WhereIsIt.table, bx: tx, by: ShapesK.int(x, "ty")) : nil
            ref = ShapesK.int(x, "ref"); who = max(0, min(n - 1, ShapesK.int(x, "who", 1)))
            target = put ? Thing(kind: things[who].kind, bx: ShapesK.int(x, "gx"), by: ShapesK.int(x, "gy"), on: ShapesK.int(x, "gon", -1)) : nil
        }
        public func thing(_ id: Int) -> Thing? { id == WhereIsIt.table ? table : things.indices.contains(id) ? things[id] : nil }
        public var refThing: Thing { thing(ref) ?? things[0] }
        public var refName: String { refThing.name }
        public var whoName: String { things[who].name }
        public var say: String { put ? "Put the \(whoName) \(word) the \(refName)." : "Tap the one \(word) the \(refName)." }
        public var why: String { (WhereIsIt.sayWhy[word] ?? { _, _ in "" })(whoName, refName) }
        public var record: String { "The \(whoName) is \(word) the \(refName)." }
        /// Where thing `id` is from the one it goes by.
        public func relation(of t: Thing) -> String? { WhereIsIt.relation(t, to: ref, refThing) }
        /// A put let go reading `code` (see codes): what to say, nil when it's right.
        public func letGo(_ code: Int) -> String? {
            if code == 8 { return "That top is round. It slides off." }
            let rel = WhereIsIt.codes[code]
            if WhereIsIt.same(rel, word) { return nil }
            let at = rel.map { "That’s \(WhereIsIt.say($0, asked: word)) the \(refName). " } ?? ""
            return at + (WhereIsIt.define[word] ?? "")
        }
        /// A find's tap on thing `j`: what to say, nil when it's right.
        public func tapped(_ j: Int) -> String? {
            if j == who { return nil }
            if j == ref { return "That’s the \(refName)." }
            guard things.indices.contains(j) else { return "Tap one of the shapes." }
            let t = things[j]
            if let r = relation(of: t) { return "The \(t.name) is \(WhereIsIt.say(r, asked: word)) the \(refName)." }
            return "The \(t.name) isn’t \(word) the \(refName)."
        }
    }

    /// Easy first: index 0–2 put, beside, next to, above; 3–5 put, in front of and behind; 6+ a table, put below or find
    /// (any word but next to). Exactly one thing stands where a find's words say.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        func rnd(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        for _ in 0..<500 {
            let hasTable = index >= 6
            let put = index < 6 ? true : rnd(0, 1) == 1
            let word = index < 3 ? ShapesK.pick(["beside", "next to", "above"], &rng) : index < 6 ? ShapesK.pick(["in front of", "behind"], &rng)
                : put ? "below" : ShapesK.pick(["in front of", "behind", "beside", "above", "below"], &rng)
            let n = index < 3 ? rnd(2, 3) : rnd(2, 4)
            var kinds = [0, 1, 2, 3]; kinds.shuffle(using: &rng); kinds = Array(kinds.prefix(n))
            if word == "above" && !kinds.contains(where: { $0 == 0 || $0 == 3 }) { continue }
            var things = kinds.map { Thing(kind: $0, bx: 0, by: 0) }
            let tab: Thing? = hasTable ? Thing(kind: table, bx: rnd(0, 6), by: rnd(0, 4)) : nil
            // what's on the floor so far, as footprints (things on a top don't count)
            var placed: [(id: Int, f: (x: Int, y: Int, w: Int, h: Int))] = tab.map { [(table, $0.foot)] } ?? []
            func free(_ f: (x: Int, y: Int, w: Int, h: Int), except: Set<Int> = []) -> Bool {
                if f.x < 0 || f.y < 0 || f.x + f.w > 10 || f.y + f.h > 6 { return false }
                return placed.allSatisfy { except.contains($0.id) || !touch(f, $0.f) }
            }
            func drop(_ j: Int) -> Bool {
                for _ in 0..<80 {
                    things[j].bx = rnd(0, 8); things[j].by = rnd(0, 4); things[j].on = -1
                    if free(things[j].foot) { placed.append((j, things[j].foot)); return true }
                }
                return false
            }
            let refId = word == "below" ? table : word == "above" ? (things.firstIndex { $0.flatTop } ?? 0) : 0
            let others = things.indices.filter { $0 != refId }
            guard let main = others.first else { continue }
            if refId != table && !drop(refId) { continue }
            let ref = refId == table ? tab! : things[refId]
            var target: Thing
            if word == "above" { target = Thing(kind: things[main].kind, bx: ref.bx, by: ref.by, on: refId) }
            else if word == "below" { target = Thing(kind: things[main].kind, bx: ref.bx + 2 * rnd(0, 1), by: ref.by) }
            else {
                let opts = word == "in front of" ? [(0, 2)] : word == "behind" ? [(0, -2)] : [(-2, 0), (2, 0)]
                let d = ShapesK.pick(opts, &rng)
                target = Thing(kind: things[main].kind, bx: ref.bx + d.0, by: ref.by + d.1)
                let tf = target.foot
                if tf.x < 0 || tf.y < 0 || tf.x > 8 || tf.y > 4 || placed.contains(where: { $0.id != refId && touch(tf, $0.f) }) { continue }
            }
            var ok = true
            var out: Numbers = ["kind": put ? 0 : 1, "word": Double(words.firstIndex(of: word)!), "n": Double(n), "ref": Double(refId), "who": Double(main),
                                "tx": Double(tab?.bx ?? -1), "ty": Double(tab?.by ?? -1)]
            if put {
                // the place stays free while the rest go down
                if word != "above" { placed.append((-5, target.foot)) }
                for j in others { ok = ok && drop(j) }
                if !ok { continue }
                out["gx"] = Double(target.bx); out["gy"] = Double(target.by); out["gon"] = Double(target.on)
            } else {
                things[main] = target; placed.append((main, target.foot))
                let rest = Array(others.dropFirst())
                if !rest.isEmpty && refId != table && word != "above" {
                    // a decoy by the one it goes by, somewhere the words don't name
                    let d = rest[0]
                    let opts = [(0, 2), (0, -2), (2, 0), (-2, 0)].filter { o in
                        let r = relation(Thing(kind: 0, bx: ref.bx + o.0, by: ref.by + o.1, on: ref.on), to: refId, ref)
                        return r != nil && !same(r, word) && !(word == "beside" && r == "beside")
                    }
                    let o = opts.isEmpty ? (99, 99) : ShapesK.pick(opts, &rng)
                    let f = (x: ref.bx + o.0, y: ref.by + o.1, w: 2, h: 2)
                    if f.x >= 0 && f.y >= 0 && f.x <= 8 && f.y <= 4 && placed.allSatisfy({ $0.id == refId || !touch(f, $0.f) }) {
                        things[d].bx = f.x; things[d].by = f.y; things[d].on = -1; placed.append((d, f))
                    } else if !drop(d) { continue }
                    for j in rest.dropFirst() { ok = ok && drop(j) }
                } else if !rest.isEmpty && refId == table && rnd(0, 1) == 1 {
                    let d = rest[0]
                    things[d].bx = ref.bx + (target.bx == ref.bx ? 2 : 0); things[d].by = ref.by; things[d].on = table
                    for j in rest.dropFirst() { ok = ok && drop(j) }
                } else { for j in rest { ok = ok && drop(j) } }
                if !ok { continue }
                // exactly one thing stands where the words say
                let hits = things.indices.filter { $0 != refId && same(relation(things[$0], to: refId, ref), word) }
                if hits.count != 1 { continue }
            }
            for (j, t) in things.enumerated() { out["k\(j)"] = Double(t.kind); out["x\(j)"] = Double(t.bx); out["y\(j)"] = Double(t.by); out["on\(j)"] = Double(t.on) }
            return out
        }
        // never reached in practice: a plain put beside
        return ["kind": 0, "word": 0, "n": 2, "k0": 0, "x0": 2, "y0": 2, "on0": -1, "k1": 1, "x1": 7, "y1": 1, "on1": -1, "tx": -1, "ty": -1, "ref": 0, "who": 1,
                "gx": 4, "gy": 2, "gon": -1]
    }

    public static let spec = LessonSpec(id: "gk-position", title: "Where is it?", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text(Parts(x).say)] },
        idea: { _ in "Above, below, beside, in front of and behind say where a thing is." },
        depends: ["k-solids"],
        check: [CheckItem(3, when: { ["in front of", "behind"].contains(Parts($0).word) }), CheckItem(6, when: { Parts($0).word == "below" }),
                CheckItem(6, when: { !Parts($0).put }), CheckItem(3)]) { x in
        let P = Parts(x)
        let step: LessonStep
        if P.put {
            let hint = WhereIsIt.define[P.word] ?? ""
            step = LessonStep(StepWords(say: P.say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(WhereIsIt.code(P.word == "next to" ? "beside" : P.word))], hint: hint, explain: P.record,
                                   check: { v in P.letGo(ShapesK.int(v, "p")).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        } else {
            let hint = WhereIsIt.define[P.word] ?? ""
            step = LessonStep(StepWords(say: P.say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("f")], expected: ["f": Double(P.who)], hint: hint, explain: P.record,
                                   check: { v in P.tapped(ShapesK.int(v, "f", -1)).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 1])
        return [step, done]
    }
}

// MARK: - Put shapes together

/// Put shapes together (gk-compose, new; K.G.B.6). Every piece is whole blocks and snaps block by block. The big shape's
/// outline, dashed, on the left; the pieces a block past it on the right, some turned. Two triangles make a square 3
/// blocks a side, and two rectangles wait standing (2 × 4): the design's 4-block square showed at 72%. Slide each piece in; tap one to
/// turn it a quarter. One that hangs out or covers another slides back. Full, the sides that touch go dashed and fade
/// and the outline turns solid: one shape. Then tap its name; the record: `2 triangles make a square.`
///
/// Numbers: `set` (one of seven), `t<j>` each piece's starting quarter turns. "at": 0 fill, 1 name, 2 done. The pieces'
/// places are kept (`px<j>`, `py<j>`, `pt<j>`, in blocks from the outline's top-left).
public enum PutShapes {
    public struct Kit: Sendable {
        public let n: Int, piece: String, make: String
        public let outline: [(Double, Double)]
        public let pieces: [[(Double, Double)]]
    }
    static let sq: [(Double, Double)] = [(0, 0), (2, 0), (2, 2), (0, 2)], rc: [(Double, Double)] = [(0, 0), (2, 0), (2, 4), (0, 4)]
    public static let sets: [Kit] = [
        Kit(n: 2, piece: "squares", make: "rectangle", outline: [(0, 0), (4, 0), (4, 2), (0, 2)], pieces: [sq, sq]),
        Kit(n: 3, piece: "squares", make: "rectangle", outline: [(0, 0), (6, 0), (6, 2), (0, 2)], pieces: [sq, sq, sq]),
        Kit(n: 4, piece: "squares", make: "square", outline: [(0, 0), (4, 0), (4, 4), (0, 4)], pieces: [sq, sq, sq, sq]),
        Kit(n: 2, piece: "rectangles", make: "square", outline: [(0, 0), (4, 0), (4, 4), (0, 4)], pieces: [rc, rc]),
        Kit(n: 2, piece: "triangles", make: "square", outline: [(0, 0), (3, 0), (3, 3), (0, 3)], pieces: [[(0, 0), (3, 3), (0, 3)], [(0, 0), (3, 0), (3, 3)]]),
        Kit(n: 2, piece: "triangles", make: "rectangle", outline: [(0, 0), (4, 0), (4, 2), (0, 2)], pieces: [[(0, 0), (4, 2), (0, 2)], [(0, 0), (4, 0), (4, 2)]]),
        Kit(n: 2, piece: "triangles", make: "triangle", outline: [(2, 0), (4, 4), (0, 4)], pieces: [[(2, 0), (2, 4), (0, 4)], [(0, 0), (2, 4), (0, 4)]]),
    ]
    public static func numbers(set: Int, turns: [Int] = []) -> Numbers {
        var x: Numbers = ["set": Double(set)]
        for j in 0..<4 { x["t\(j)"] = Double(j < turns.count ? turns[j] : 0) }
        return x
    }

    static func bbox(_ p: [(Double, Double)]) -> (x0: Double, y0: Double, x1: Double, y1: Double) {
        (p.map(\.0).min() ?? 0, p.map(\.1).min() ?? 0, p.map(\.0).max() ?? 0, p.map(\.1).max() ?? 0)
    }
    public static func norm(_ p: [(Double, Double)]) -> [(Double, Double)] { let b = bbox(p); return p.map { ($0.0 - b.x0, $0.1 - b.y0) } }
    /// A quarter turn clockwise, kept from 0, 0.
    public static func turn(_ p: [(Double, Double)]) -> [(Double, Double)] { let b = bbox(p); return norm(p.map { (b.y1 - $0.1, $0.0) }) }
    public static func turned(_ p: [(Double, Double)], _ k: Int) -> [(Double, Double)] {
        var q = norm(p)
        for _ in 0..<(((k % 4) + 4) % 4) { q = turn(q) }
        return q
    }
    /// A point is inside a polygon (even-odd).
    public static func inside(_ p: (Double, Double), _ pts: [(Double, Double)]) -> Bool {
        var c = false, j = pts.count - 1
        for i in pts.indices {
            let (xi, yi) = pts[i], (xj, yj) = pts[j]
            if (yi > p.1) != (yj > p.1) && p.0 < (xj - xi) * (p.1 - yi) / (yj - yi) + xi { c.toggle() }
            j = i
        }
        return c
    }
    /// Sample points inside a polygon (off the grid lines, so none lies on a side).
    static func samples(_ pts: [(Double, Double)]) -> [(Double, Double)] {
        let b = bbox(pts)
        var out: [(Double, Double)] = []
        var x = b.x0
        while x < b.x1 { var y = b.y0; while y < b.y1 { let p = (x + 0.137, y + 0.291); if inside(p, pts) { out.append(p) }; y += 0.5 }; x += 0.5 }
        return out
    }

    public struct Parts: Sendable {
        public let which: Int, turns: [Int]
        public init(_ x: Numbers) {
            which = max(0, min(6, ShapesK.int(x, "set")))
            turns = (0..<4).map { ShapesK.int(x, "t\($0)") }
        }
        public var S: PutShapes.Kit { PutShapes.sets[which] }
        public var n: Int { S.n }
        /// The two halves of a square or rectangle are the same piece turned half way round.
        public var halves: Bool { which == 4 || which == 5 }
        /// Piece j as it starts (in blocks, from 0, 0).
        public func start(_ j: Int) -> [(Double, Double)] { PutShapes.turned(halves ? S.pieces[0] : S.pieces[j], turns[j]) }
        /// The outline's size in blocks.
        public var size: (w: Double, h: Double) { let b = PutShapes.bbox(S.outline); return (b.x1, b.y1) }
        /// Where each piece waits: left to right a block past the outline, a block apart, wrapping so nothing passes 13
        /// blocks across (65 squares: it shows at 75%).
        public var tray: [(Double, Double)] {
            var out: [(Double, Double)] = [], cx = size.w + 1, cy = 0.0, rowH = 0.0
            for j in 0..<n {
                let b = PutShapes.bbox(start(j))
                if cx > size.w + 1 && cx + b.x1 > 13 { cx = size.w + 1; cy += rowH + 1; rowH = 0 }
                out.append((cx, cy)); cx += b.x1 + 1; rowH = max(rowH, b.y1)
            }
            return out
        }
        /// A piece (its shape and place) lies wholly inside the outline, partly, or not at all.
        public func fit(_ p: [(Double, Double)]) -> (all: Bool, some: Bool) {
            let sp = PutShapes.samples(p)
            let ins = sp.map { PutShapes.inside($0, S.outline) }
            return (ins.allSatisfy { $0 }, ins.contains(true))
        }
        /// Two pieces cover the same place.
        public func overlap(_ a: [(Double, Double)], _ b: [(Double, Double)]) -> Bool { PutShapes.samples(a).contains { PutShapes.inside($0, b) } }
        public var choices: [String] { ShapesK.choices(kind: S.make, w: 1, h: 0) }
        public var right: Int { choices.firstIndex(of: S.make) ?? 0 }
        public func picked(_ i: Int) -> String? {
            guard choices.indices.contains(i), i != right else { return nil }
            return ShapesK.nameMiss(kind: S.make, picked: choices[i])
        }
        public var record: String { "\(S.n) \(S.piece) make \(ShapesK.an(S.make))." }
        public static let why = "Full sides touching, no gaps: they make one bigger shape."
    }
    /// A piece let go: 1 every piece in, −1 one sticking out, −2 two covering each other.
    /// Where each piece goes when the shape is filled as the set is made (in blocks from the outline's top-left), with its
    /// own shape: for Show me and a second miss's dashed places.
    public static let places: [[(Double, Double)]] = [[(0, 0), (2, 0)], [(0, 0), (2, 0), (4, 0)], [(0, 0), (2, 0), (0, 2), (2, 2)], [(0, 0), (2, 0)], [(0, 0), (0, 0)], [(0, 0), (0, 0)], [(0, 0), (2, 0)]]
    public static func solution(_ set: Int, _ j: Int) -> (shape: [(Double, Double)], at: (Double, Double)) {
        let S = sets[set]
        return (set == 4 || set == 5 ? turned(S.pieces[0], j * 2) : norm(S.pieces[j]), places[set][j])
    }
    public static func letGo(_ code: Int) -> String? { code == -1 ? "That one sticks out." : code == -2 ? "Pieces can’t stack." : nil }

    /// Easy first: index 0–2 squares and rectangles, nothing to turn; 3–5 triangles, one to turn; 6+ any set, any turns.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let set = index < 3 ? Int.random(in: 0...3, using: &rng) : index < 6 ? Int.random(in: 4...6, using: &rng) : Int.random(in: 0...6, using: &rng)
        var turns = [0, 0, 0, 0]
        if index >= 3 && index < 6 && set == 6 { turns[Int.random(in: 0...1, using: &rng)] = Int.random(in: 1...3, using: &rng) }
        if index >= 6 { turns = (0..<4).map { _ in Int.random(in: 0...3, using: &rng) } }
        return numbers(set: set, turns: turns)
    }

    public static let spec = LessonSpec(id: "gk-compose", title: "Put shapes together", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { _ in [.text("Fill the shape.")] },
        idea: { _ in "Shapes put together, sides touching, make a bigger shape." },
        depends: ["gk-draw"],
        check: [CheckItem(3, when: { let P = Parts($0); return P.halves || P.turns.prefix(P.n).contains { $0 % 4 != 0 } }), CheckItem(3, when: { Parts($0).which == 6 }),
                CheckItem(6, when: { Parts($0).n >= 3 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let fill = LessonStep(StepWords(say: "Fill the shape.", hint: "Slide each piece in. Tap a piece to turn it.", action: "Check"),
            answer: AnswerTask(prompt: [.box("f")], expected: ["f": 1], hint: "Slide each piece in. Tap a piece to turn it.", explain: P.record,
                               check: { v in PutShapes.letGo(ShapesK.int(v, "f")).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let nameHint = "Count its sides and corners."
        // the See (the inside sides fade, one shape) is said with the next thing to do
        let name = LessonStep(StepWords(say: "One shape. Tap its name.", hint: nameHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(P.right)],
                               known: P.choices.indices.filter { $0 != P.right }.map { (["n": Double($0)], P.picked($0) ?? "") }, hint: nameHint,
                               explain: P.record, check: { v in P.picked(ShapesK.int(v, "n", -1)).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [fill, name, done]
    }
}
