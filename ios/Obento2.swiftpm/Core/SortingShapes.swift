import Foundation

/// Sorting shapes (g5-shapes, 5.G.3–4; design/grade5.md "Added 1 Nov 2026", the preview G approved on 1 Nov:
/// design/prototype/new5-lessons.html, dShapes). A four-sided shape drawn by its corners on grid points, each side's
/// length in squares beside it where it's whole (tilted sides use 3-4-5 steps, so a 15-square side is 9 across and 12 up).
///
/// Numbers: "kind" (which list of the catalogue: square, rectangle, rhombus, parallelogram, trapezoid, other
/// quadrilateral), "v" (which shape in it), "m" (1: mirrored, left to right). The shape's family is worked out from its
/// corners, never from the list it came from (the catalogue's third parallelogram has four 15-square sides, so it's a
/// rhombus, and is sorted as one). Every shape is at most 24 squares wide, so it never runs into the family picture.
///
/// 1. **Tap two sides** that are parallel: a pair found gets matching arrowheads; a wrong pair is answered measured on the
///    grid ("Not parallel: one goes 4 across, 3 up, the other 4 across, 3 down."); **No more** when every pair is found.
/// 2. **Tap each square corner**: it gets the little square mark; a corner that isn't square says whether it's wider or
///    narrower than a grid square's corner; **No more** when every one is marked.
/// 3. The family picture draws in beside it (boxes inside boxes: Quadrilaterals ⊃ Trapezoids ⊃ Parallelograms ⊃
///    Rectangles and Rhombuses, overlapping in Squares); **tap the smallest box it fits in**. Then every box around it
///    lights, and the last words name them all. The inclusive trapezoid (at least one pair of parallel sides), so
///    parallelograms sit inside trapezoids.
///
/// Each step's one box is set by the hands: step 1, the pairs found when No more is pressed, or 100 + 10 i + j for a
/// pair of sides i, j that isn't parallel; step 2, the corners marked when No more is pressed, or 100 + i for corner i
/// that isn't square; step 3, the box tapped (Box.rawValue). Picture keys: "at", 0 the question, 1 sides, 2 corners,
/// 3 the family picture, 4 done; a hint lights "ring".
public enum SortingShapes {
    /// The catalogue, in squares from the shape's top-left (y down, as the paper's rows): the preview's own lists.
    public static let catalogue: [[[(Int, Int)]]] = [
        // squares, straight and tilted
        [[(0, 0), (15, 0), (15, 15), (0, 15)], [(0, 9), (12, 0), (21, 12), (9, 21)], [(0, 0), (20, 0), (20, 20), (0, 20)]],
        // rectangles
        [[(0, 0), (24, 0), (24, 10), (0, 10)], [(0, 0), (15, 0), (15, 20), (0, 20)], [(0, 0), (20, 0), (20, 15), (0, 15)]],
        // rhombuses
        [[(0, 9), (12, 0), (24, 9), (12, 18)], [(9, 0), (24, 0), (15, 12), (0, 12)]],
        // parallelograms (the third has four sides of 15: a rhombus)
        [[(6, 0), (24, 0), (18, 8), (0, 8)], [(0, 0), (15, 0), (21, 8), (6, 8)], [(0, 0), (15, 0), (24, 12), (9, 12)]],
        // trapezoids, with and without square corners
        [[(9, 0), (15, 0), (24, 12), (0, 12)], [(0, 0), (15, 0), (24, 12), (0, 12)], [(6, 0), (14, 0), (20, 8), (0, 8)]],
        // other quadrilaterals
        [[(0, 4), (14, 0), (20, 15), (4, 12)], [(0, 0), (12, 0), (20, 16), (3, 10)]],
    ]
    /// No shape is wider than this (the family picture starts past it).
    public static let widest = 24

    public static func numbers(kind: Int, v: Int, mirrored: Bool = false) -> Numbers { ["kind": Double(kind), "v": Double(v), "m": mirrored ? 1 : 0] }

    /// The family picture's boxes, from the smallest.
    public enum Box: Int, CaseIterable, Sendable {
        case squares, rectangles, rhombuses, parallelograms, trapezoids, quadrilaterals
        public var name: String { ["Squares", "Rectangles", "Rhombuses", "Parallelograms", "Trapezoids", "Quadrilaterals"][rawValue] }
        /// "a square"
        public var one: String { ["a square", "a rectangle", "a rhombus", "a parallelogram", "a trapezoid", "a quadrilateral"][rawValue] }
        /// What a shape needs to be in it.
        public var needs: String {
            ["4 square corners and 4 equal sides", "4 square corners", "4 equal sides", "2 pairs of parallel sides",
             "at least one pair of parallel sides", "4 sides"][rawValue]
        }
    }

    /// A shape's parts, all from its numbers.
    public struct Parts: Sendable {
        /// Its corners, in order round it, in squares from its top-left.
        public let corners: [(x: Int, y: Int)]
        public init(_ n: Numbers) {
            let k = min(catalogue.count - 1, max(0, Int((n["kind"] ?? 0).rounded())))
            let list = catalogue[k], v = min(list.count - 1, max(0, Int((n["v"] ?? 0).rounded())))
            var c = list[v].map { (x: $0.0, y: $0.1) }
            if (n["m"] ?? 0) >= 0.5 {
                let w = c.map(\.x).max() ?? 0
                c = c.map { (x: w - $0.x, y: $0.y) }.reversed()
            }
            corners = c
        }
        public var width: Int { corners.map(\.x).max() ?? 0 }
        public var height: Int { corners.map(\.y).max() ?? 0 }
        /// Side i, from corner i to the next: how far across and down.
        public func side(_ i: Int) -> (dx: Int, dy: Int) {
            let a = corners[i % 4], b = corners[(i + 1) % 4]
            return (b.x - a.x, b.y - a.y)
        }
        static func cross(_ u: (dx: Int, dy: Int), _ v: (dx: Int, dy: Int)) -> Int { u.dx * v.dy - u.dy * v.dx }
        static func dot(_ u: (dx: Int, dy: Int), _ v: (dx: Int, dy: Int)) -> Int { u.dx * v.dx + u.dy * v.dy }
        public func parallel(_ i: Int, _ j: Int) -> Bool { i != j && Self.cross(side(i), side(j)) == 0 }
        /// The pairs of parallel sides: [0, 2], [1, 3], or both, or neither.
        public var pairs: [[Int]] { [[0, 2], [1, 3]].filter { parallel($0[0], $0[1]) } }
        /// The two sides out of corner i.
        public func cornerSides(_ i: Int) -> ((dx: Int, dy: Int), (dx: Int, dy: Int)) {
            let p = side((i + 3) % 4)
            return (side(i), (-p.dx, -p.dy))
        }
        /// How corner i opens: 0 square, more than 0 narrower, less than 0 wider.
        public func opening(_ i: Int) -> Int { let (u, v) = cornerSides(i); return Self.dot(u, v) }
        /// The square corners.
        public var rights: [Int] { (0..<4).filter { opening($0) == 0 } }
        public func length(_ i: Int) -> Double { let s = side(i); return Double(s.dx * s.dx + s.dy * s.dy).squareRoot() }
        /// A side's length in squares, when it's whole.
        public func wholeLength(_ i: Int) -> Int? { let l = length(i); return abs(l - l.rounded()) < 1e-9 ? Int(l.rounded()) : nil }
        public var equalSides: Bool { let s = (0..<4).map { side($0) }.map { $0.dx * $0.dx + $0.dy * $0.dy }; return Set(s).count == 1 }

        /// The boxes it fits in, from the smallest: its family.
        public var chain: [Box] {
            let p = pairs.count, r = rights.count == 4, e = equalSides
            if p == 2 && r && e { return [.squares, .rectangles, .rhombuses, .parallelograms, .trapezoids, .quadrilaterals] }
            if p == 2 && r { return [.rectangles, .parallelograms, .trapezoids, .quadrilaterals] }
            if p == 2 && e { return [.rhombuses, .parallelograms, .trapezoids, .quadrilaterals] }
            if p == 2 { return [.parallelograms, .trapezoids, .quadrilaterals] }
            if p == 1 { return [.trapezoids, .quadrilaterals] }
            return [.quadrilaterals]
        }
        public var smallest: Box { chain[0] }

        /// How a side goes, measured on the grid: "straight across", "straight up", "4 across, 3 up".
        public func how(_ i: Int) -> String {
            var (dx, dy) = side(i)
            if dy == 0 { return "straight across" }
            if dx == 0 { return "straight up" }
            if dx < 0 { dx = -dx; dy = -dy }
            let g = gcd(abs(dx), abs(dy))
            return "\(dx / g) across, \(abs(dy) / g) \(dy < 0 ? "up" : "down")"
        }

        /// The last words: what it is, and every box around it.
        public var why: String {
            let c = chain
            let first = "It’s \(c[0].one)."
            guard c.count > 1 else { return first + " It has 4 sides, but no parallel sides." }
            let rest = c.dropFirst().map(\.one)
            let list = rest.count == 1 ? rest[0] : rest.dropLast().joined(separator: ", ") + " and " + rest.last!
            return first + " So it’s also \(list)."
        }
    }

    /// Step 1: pairs found when No more is pressed, or a pair tapped that isn't parallel (100 + 10 i + j).
    public static func sidesVerdict(_ x: Double?, _ s: Parts) -> Verdict {
        guard let x else { return .soft("Tap two sides that are parallel.") }
        let n = Int(x.rounded())
        if n >= 100 {
            let i = (n - 100) / 10, j = (n - 100) % 10
            return .wrong("Not parallel: one goes \(s.how(i)), the other \(s.how(j)).")
        }
        if n >= s.pairs.count { return .right }
        return .wrong(n > 0 ? "There’s another parallel pair." : "Look again: two sides go the same way.")
    }

    /// Step 2: corners marked when No more is pressed, or a corner tapped that isn't square (100 + i).
    public static func cornersVerdict(_ x: Double?, _ s: Parts) -> Verdict {
        guard let x else { return .soft("Tap every square corner.") }
        let n = Int(x.rounded())
        if n >= 100 {
            let o = s.opening(n - 100)
            if o == 0 { return .soft("Tap every square corner.") }
            return .wrong("That corner isn’t square. It’s \(o > 0 ? "narrower" : "wider") than a grid square’s corner.")
        }
        if n >= s.rights.count { return .right }
        return .wrong("There’s another square corner.")
    }

    /// Step 3: the box tapped.
    public static func boxVerdict(_ x: Double?, _ s: Parts) -> Verdict {
        guard let x, let b = Box(rawValue: Int(x.rounded())) else { return .soft("Tap the smallest box it fits in.") }
        if b == s.smallest { return .right }
        if s.chain.contains(b) { return .wrong("It fits there. Is there a smaller box inside that it fits in too?") }
        return .wrong("\(b.name) need \(b.needs).")
    }

    public static let spec = LessonSpec(id: "g5-shapes", title: "Sorting shapes", master: "shapes", generate: { rng, _ in
        let kind = Int.random(in: 0..<catalogue.count, using: &rng)
        let v = Int.random(in: 0..<catalogue[kind].count, using: &rng)
        return numbers(kind: kind, v: v, mirrored: Bool.random(using: &rng))
    }, display: { _ in [.text("Sort the shape.")] },
    idea: { _ in "A shape belongs to every family whose rules it keeps: a square is also a rectangle." },
    depends: ["g4-lines", "g3-quads"],
    check: [CheckItem(3, when: { Parts($0).chain.count >= 4 }), CheckItem(3, when: { Parts($0).smallest == .trapezoids }),
            CheckItem(3, when: { Parts($0).smallest == .parallelograms || Parts($0).smallest == .rhombuses }), CheckItem(3)]) { n in
        let s = Parts(n), pairs = s.pairs.count, rights = s.rights.count, box = s.smallest

        let ask = LessonStep(StepWords(say: "Tap two sides that are parallel.", hint: "Parallel sides go the same way.", action: "Let’s find out"),
                             picture: ["at": 0])
        let sides = LessonStep(StepWords(say: "Tap two sides that are parallel. Parallel sides go the same way. When there are no more, tap No more.",
                                         hint: "Count how far each side goes across and up.", action: "No more"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(pairs)],
                               hint: pairs == 0 ? "No two sides go the same way." : "Sides that go the same number across and up are parallel.",
                               explain: pairs == 0 ? "No two sides go the same way." : pairs == 1 ? "One pair of sides goes the same way." : "Both pairs of opposite sides go the same way.",
                               check: { v in sidesVerdict(v["x"], s) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])
        let corners = LessonStep(StepWords(say: "Tap every square corner. When there are no more, tap No more.",
                                           hint: "A square corner fits a grid square’s corner.", action: "No more"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(rights)],
                               hint: "A square corner fits a grid square’s corner.",
                               explain: rights == 0 ? "None of its corners is square." : rights == 4 ? "All 4 corners are square." : "\(rights) of its corners are square.",
                               check: { v in cornersVerdict(v["x"], s) }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1])
        let sort = LessonStep(StepWords(say: "Tap the smallest box it fits in. Its sides are counted in squares.",
                                        hint: "Rectangles need 4 square corners. Rhombuses need 4 equal sides.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(box.rawValue)],
                               hint: "\(box.name) need \(box.needs).", explain: s.why,
                               check: { v in boxVerdict(v["x"], s) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "A shape belongs to every family whose rules it keeps.", action: "Next problem"),
                              picture: ["at": 4])
        return [ask, sides, corners, sort, done]
    }
}
