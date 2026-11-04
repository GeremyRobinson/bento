import Foundation

/// What 4th grade's Lines and shapes chapter shares (design/grade4.md chapter 8, the preview
/// design/prototype/grade4-ch8.html): angles and shapes on the grid. Every corner sits on a grid point and a first arm
/// runs along a grid line; an arm turned off the grid is drawn at its true angle. Angles are degrees, counter-clockwise
/// from the right, with the paper's rows running down (so "up" is a smaller row). Two tools lie beside the picture and
/// are dragged on: the page corner (a square corner, 6 squares a side) and the protractor (a half circle, a tick every
/// degree, two scales).
public enum Geo4 {
    /// A place in squares, across and down.
    public struct Pt: Sendable, Equatable {
        public var x: Double, y: Double
        public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
        public static func + (a: Pt, b: Pt) -> Pt { Pt(a.x + b.x, a.y + b.y) }
        public static func - (a: Pt, b: Pt) -> Pt { Pt(a.x - b.x, a.y - b.y) }
    }
    static let rad = Double.pi / 180
    /// The point r squares from c at angle a.
    public static func pol(_ c: Pt, _ r: Double, _ a: Double) -> Pt { Pt(c.x + r * cos(a * rad), c.y - r * sin(a * rad)) }
    /// The angle from c to p, 0 to 360.
    public static func angOf(_ c: Pt, _ p: Pt) -> Double {
        let a = atan2(c.y - p.y, p.x - c.x) / rad
        return (a.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }
    /// a − b, turned into −180 … 180.
    public static func adiff(_ a: Double, _ b: Double) -> Double { ((a - b).truncatingRemainder(dividingBy: 360) + 540).truncatingRemainder(dividingBy: 360) - 180 }
    public static func dist(_ a: Pt, _ b: Pt) -> Double { hypot(a.x - b.x, a.y - b.y) }
    /// How far p is from the segment a–b.
    public static func segDist(_ p: Pt, _ a: Pt, _ b: Pt) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y, l = dx * dx + dy * dy
        let t = l == 0 ? 0 : max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / l))
        return hypot(p.x - a.x - t * dx, p.y - a.y - t * dy)
    }
    static func g(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : g(b, a % b) }
    /// Grid steps at their smallest: (4, −2) is (2, −1).
    public static func redv(_ x: Int, _ y: Int) -> (Int, Int) { let k = max(1, g(abs(x), abs(y))); return (x / k, y / k) }
    /// How a side or a line goes on the grid, in words: "3 across and 1 up".
    public static func stepsWords(_ x: Int, _ y: Int) -> String {
        var (dx, dy) = redv(x, y)
        if dx < 0 || (dx == 0 && dy > 0) { dx = -dx; dy = -dy }
        if dy == 0 { return "straight across" }
        if dx == 0 { return "straight up" }
        return "\(dx) across and \(abs(dy)) \(dy < 0 ? "up" : "down")"
    }
    public static func same(_ u: (Int, Int), _ v: (Int, Int)) -> Bool { u.0 * v.1 - u.1 * v.0 == 0 }
    public static func perp(_ u: (Int, Int), _ v: (Int, Int)) -> Bool { u.0 * v.0 + u.1 * v.1 == 0 }
    /// An angle's kind: 0 acute, 1 right, 2 obtuse, 3 straight.
    public static func kind(_ d: Int) -> Int { d < 90 ? 0 : d == 90 ? 1 : d < 180 ? 2 : 3 }
    public static let kinds = ["Acute", "Right", "Obtuse", "Straight"]
    /// What the page corner does on an angle of each kind.
    public static let fit = ["fits inside the page corner", "fits the page corner exactly", "opens past the page corner", "opens past the page corner"]
    static func aAn(_ w: String) -> String { (["a", "e", "i", "o", "u"].contains(w.prefix(1).lowercased()) ? "an " : "a ") + w }
    static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { Int.random(in: a...b, using: &rng) }
    /// The first slip that matches what was typed and isn't the answer.
    static func slip(_ ans: Double, _ v: Double, _ list: [(Double, String)]) -> String? {
        list.first { abs($0.0 - v) < 1e-9 && abs($0.0 - ans) > 1e-9 }?.1
    }
}

// MARK: - Points, lines, rays and angles

/// Points, lines, rays and angles (the web app's g4-lines, 4.G.1): three kinds, a line, ray or segment (kind 0), an angle
/// (1) and two lines (2), each a figure 30–40 squares long through points on grid points, turned by grid steps.
///
/// 1. Line, ray or segment: tap each end (a dot: it stops; an arrowhead: it goes on), then tap its name.
/// 2. An angle: drag the page corner onto its corner (it fits inside, fits exactly, or opens past), then tap its name.
/// 3. Two lines: drag an arrowhead of each away so it runs on (they stay 4 squares apart, or cross); where they cross,
///    drag the page corner on; then tap their name.
/// From index 6 every other problem asks the child to make it: tap the ends to dots or arrowheads, turn an angle's free
/// arm (live acute, right, obtuse), or draw a line through P (live parallel, perpendicular).
///
/// Numbers: kind, item (the answer's index in its names), deg (an angle's size; two crossing lines' angle), turn, make.
/// Picture keys: "at", a stage (`Stage`).
public enum LinesRays {
    public enum Stage: Int, Sendable { case ask, ends, name, corner, run, make, turn, draw, done }
    public static let figs = ["Line", "Ray", "Segment"], pairs = ["Parallel", "Perpendicular", "Intersecting"]
    /// A figure's six turns, as grid steps (across, down); two crossing lines' angles as grid steps.
    public static let dirs: [(Int, Int)] = [(1, 0), (2, -1), (1, -2), (0, -1), (-1, -1), (3, 1)]
    public static let gridAngles: [(Int, Int)] = [(3, 2), (4, 3), (1, 1), (3, 4), (2, 3), (1, 2)]

    public static func numbers(kind: Int, item: Int, deg: Int = 0, turn: Int = 0, make: Bool = false) -> Numbers {
        ["kind": Double(kind), "item": Double(item), "deg": Double(deg), "turn": Double(turn), "make": make ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let kind: Int, item: Int, deg: Int, turn: Int, make: Bool
        public init(_ x: Numbers) {
            kind = min(2, max(0, Geo4.int(x, "kind", 0)))
            item = min(kind == 1 ? 3 : 2, max(0, Geo4.int(x, "item", 0)))
            deg = Geo4.int(x, "deg", 0); turn = min(5, max(0, Geo4.int(x, "turn", 0))); make = (x["make"] ?? 0) != 0
        }
        /// The names to pick from (Straight only for a straight angle).
        public var names: [String] { kind == 0 ? LinesRays.figs : kind == 1 ? (deg == 180 ? Geo4.kinds : Array(Geo4.kinds.prefix(3))) : LinesRays.pairs }
        /// The right name's index.
        public var right: Int { kind == 1 && !make ? Geo4.kind(deg) : item }
        /// Its name, as the record writes it: "ray AB", "obtuse angle", "parallel lines".
        public var named: String {
            switch kind {
            case 0: "\(LinesRays.figs[item].lowercased()) AB"
            case 1: "\(Geo4.kinds[right].lowercased()) angle"
            default: "\(LinesRays.pairs[item].lowercased()) lines"
            }
        }
        /// Two lines: the first's grid steps, and the second's.
        public var d1: (Int, Int) { LinesRays.dirs[turn] }
        public var d2: (Int, Int) {
            let a = d1
            switch item {
            case 0: return a
            case 1: return (-a.1, a.0)
            default:
                let target = Double(deg)
                let gA = LinesRays.gridAngles.min { abs(atan2(Double($0.1), Double($0.0)) / Geo4.rad - target) < abs(atan2(Double($1.1), Double($1.0)) / Geo4.rad - target) }!
                let mx = a.0, my = -a.1
                return Geo4.redv(mx * gA.0 - my * gA.1, -(mx * gA.1 + my * gA.0))
            }
        }
        /// A line drawn through P with these grid steps: 0 parallel, 1 perpendicular, 2 crosses.
        public func relation(_ v: (Int, Int)) -> Int { Geo4.same(v, d1) ? 0 : Geo4.perp(v, d1) ? 1 : 2 }
        public var stages: [Stage] {
            if make { return [.ask, [Stage.make, .turn, .draw][kind], .done] }
            switch kind {
            case 0: return [.ask, .ends, .name, .done]
            case 1: return [.ask, .corner, .name, .done]
            default: return [.ask, .run] + (item > 0 ? [.corner] : []) + [.name, .done]
            }
        }
        /// What the page corner shows, once it's laid.
        public var finding: String {
            kind == 1 ? "It \(Geo4.fit[Geo4.kind(deg)])." : item == 1 ? "The page corner fits where they cross." : "The page corner doesn’t fit where they cross."
        }
        /// What running both lines on shows.
        public var ran: String { item == 0 ? "4 squares apart all the way" : "They cross." }

        /// The question for a stage, with what to do (the preview's grey line folded in).
        public func say(_ st: Stage) -> String {
            if make {
                switch st {
                case .make: return ["Make a line through A and B.", "Make a ray from A through B.", "Make a segment from A to B."][item] + " Tap each end for a dot or an arrowhead. Then Check."
                case .turn: return "Make \(Geo4.aAn(Geo4.kinds[item].lowercased())) angle. Turn the free arm."
                case .draw: return (item == 0 ? "Draw a line through P that never meets this one." : "Draw a line through P that meets this one in square corners.") + " Drag from P."
                default: break
                }
            }
            switch st {
            case .ends: return "Tap each end. A dot or an arrowhead?"
            case .corner: return kind == 1 ? "How wide does it open? Drag the page corner onto its corner." : "Are the corners square? Drag the page corner to where they cross."
            case .run: return "Run each line on. Drag an arrowhead away from the line."
            case .name: return (kind == 0 ? "What is it called?" : kind == 1 ? "What kind of angle is it?" : "What are these lines called?") + " Tap its name."
            default: return why
            }
        }
        /// The last words: why.
        public var why: String {
            kind == 0 ? "No endpoints is a line, 1 is a ray, 2 is a segment."
                : kind == 1 ? (deg == 180 && !make ? "Opened all the way into a straight line, it’s a straight angle." : "Smaller than a square corner is acute, exactly is right, bigger is obtuse.")
                : "Never meet: parallel. Square corners: perpendicular. Otherwise: intersecting."
        }

        /// Tap a name: the choice's index.
        public func choose(_ i: Int) -> Verdict {
            if i == right { return .right }
            if kind == 0 { return .wrong(["A line goes on forever both ways: arrowheads at both ends.", "A ray has one endpoint and goes on forever one way.", "A segment has two endpoints and stops at both."][min(2, max(0, i))]) }
            if kind == 1 {
                if deg < 90 && i > 0 { return .wrong("Long arms don’t make a bigger angle. Look at how wide it opens.") }
                return .wrong(["Acute is smaller than a square corner.", "Right is exactly a square corner.", "Obtuse is bigger than a square corner but not a straight line.", "Straight is a straight line: 180°."][min(3, max(0, i))])
            }
            switch i {
            case 0: return .wrong("Keep them going: they get closer and cross. Parallel lines stay the same distance apart.")
            case 1: return .wrong("Perpendicular lines meet at square corners.")
            default: return .wrong(item == 0 ? "These never meet, so they’re parallel." : "They meet at square corners, so they’re perpendicular.")
            }
        }
        /// Make it with its ends: 10 × the first end + the second (0 not set, 1 a dot, 2 an arrowhead).
        public func ends(_ code: Int) -> Verdict {
            let e0 = code / 10, e1 = code % 10
            if e0 == 0 || e1 == 0 { return .soft("Tap both ends: a dot or an arrowhead.") }
            let n = (e0 == 2 ? 1 : 0) + (e1 == 2 ? 1 : 0), got = [2, 1, 0][n]
            if got == item && (item != 1 || e0 == 1) { return .right }
            if got == item { return .wrong("That ray starts at the other end. Ray AB starts at A and goes on through B.") }
            switch item {
            case 0: return .wrong("That’s \(got == 1 ? "a ray: it stops at one end" : "a segment: it stops at both ends"). A line goes on both ways.")
            case 1: return .wrong(got == 0 ? "That’s a line: it goes on both ways. A ray stops at A." : "That’s a segment: it stops at both ends. A ray goes on past B.")
            default: return .wrong(got == 0 ? "That’s a line: it goes on both ways. A segment stops at A and at B." : "That’s a ray: it goes on one way. A segment stops at both ends.")
            }
        }
        /// Make an angle: the free arm let go at v degrees.
        public func turned(_ v: Int) -> Verdict {
            let g = Geo4.kind(v)
            if g == item { return .right }
            if v == 180 {
                return .wrong("That’s a straight angle: a straight line. " + ["An acute angle fits inside the page corner.", "A right angle fits the page corner exactly.", "An obtuse angle opens past the page corner, but not all the way."][item])
            }
            return .wrong("That’s \(Geo4.aAn(Geo4.kinds[g].lowercased())) angle: it \(Geo4.fit[g]). \(Geo4.cap(Geo4.aAn(Geo4.kinds[item].lowercased()))) angle \(["fits inside it", "fits it exactly", "opens past it"][item]).")
        }
        /// Draw a line through P: how it goes with the first (relation).
        public func drawn(_ rel: Int) -> Verdict {
            if (item == 0 && rel == 0) || (item == 1 && rel == 1) { return .right }
            if item == 0 { return .wrong("Run them on: they’d cross. Go the same steps as this one: \(Geo4.stepsWords(d1.0, d1.1)).") }
            return .wrong(rel == 0 ? "Those never meet. Make one that crosses it in square corners." : "They cross, but the page corner doesn’t fit where they cross.")
        }
    }

    /// The preview's generator: index 0 and 2 a line, ray or segment, 1 an angle of 30, 90 or 150; then the three kinds in
    /// turn (index % 3); angles 15–75 or 100–165 in fives, 90 a quarter of the time, 180 a tenth; crossing lines at 30–70;
    /// from index 6 every other problem is made.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i == 1 { let d = Geo4.pick([30, 90, 150], &rng); return numbers(kind: 1, item: Geo4.kind(d), deg: d) }
        if i < 3 { return numbers(kind: 0, item: Geo4.r(0, 2, &rng)) }
        let kind = i % 3, mk = i >= 6 && i % 2 == 0, turn = Geo4.r(0, 5, &rng)
        if kind == 1 {
            if mk { return numbers(kind: 1, item: Geo4.r(0, 2, &rng), turn: turn % 4, make: true) }
            let deg = Geo4.r(0, 9, &rng) == 0 ? 180 : Geo4.r(0, 3, &rng) == 0 ? 90 : Geo4.pick((0..<14).flatMap { [15 + 5 * $0, 100 + 5 * $0] }, &rng)
            return numbers(kind: 1, item: Geo4.kind(deg), deg: deg, turn: turn % 4)
        }
        let item = mk && kind == 2 ? Geo4.r(0, 1, &rng) : Geo4.r(0, 2, &rng)
        return numbers(kind: kind, item: item, deg: kind == 2 && item == 2 ? Geo4.r(30, 70, &rng) : 0, turn: turn, make: mk)
    }

    public static let spec = LessonSpec(id: "g4-lines", title: "Points, lines, rays and angles", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let p = Parts(x); return [.text(p.say(p.stages[1]))] },
        idea: { x in ["A line goes on both ways, a ray goes one way, and a segment stops.",
                      "An angle is named by how wide it opens, compared with a square corner.",
                      "Two lines can never meet, meet at square corners, or cross another way."][Parts(x).kind] },
        depends: ["g3-quads"],
        check: [CheckItem(3), CheckItem(4, when: { let p = Parts($0); return p.kind == 1 && !p.make && p.deg < 90 }),
                CheckItem(7, when: { let p = Parts($0); return p.kind == 1 && !p.make && p.deg > 90 && p.deg < 180 }),
                CheckItem(5, when: { let p = Parts($0); return p.kind == 2 && !p.make && p.item == 1 }),
                CheckItem(11, when: { let p = Parts($0); return p.kind == 2 && !p.make && p.item == 2 })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let p = Parts(x)
        var out: [LessonStep] = []
        for st in p.stages {
            let pic: Numbers = ["at": Double(st.rawValue)], say = p.say(st)
            func hand(_ box: String, _ want: Double, _ hint: String, _ check: @escaping @Sendable ([String: Double]) -> Verdict, ring: Bool = true) -> LessonStep {
                LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                           answer: AnswerTask(prompt: [.box(box)], expected: [box: want], hint: hint, explain: hint, check: check, byHand: true),
                           picture: pic, onMiss: ring ? ["ring": 1] : [:], hint2: ring ? ["spot": 1] : [:])
            }
            switch st {
            case .ask: out.append(LessonStep(StepWords(say: p.say(p.stages[1]), hint: "", action: "Let’s find out"), picture: pic))
            case .ends:
                out.append(hand("e", 1, "A dot is an endpoint. An arrowhead means it keeps going.", { v in
                    switch Geo4.int(v, "e") {
                    case 1: return .right
                    case -1: return .soft("That’s point A, not an end. Tap where it stops or goes on.")
                    case -2: return .soft("That’s point B, not an end. Tap where it stops or goes on.")
                    default: return .soft("Tap the ends: where it stops or goes on.")
                    }
                }, ring: false))
            case .corner:
                let miss = p.kind == 1 ? "Put the page corner’s point on the angle’s corner." : "Put the page corner’s point where the lines cross."
                out.append(hand("k", 1, p.kind == 1 ? "Look at how wide it opens, not how long the arms are." : "Put the page corner where they cross.",
                                { v in Geo4.int(v, "k") == 1 ? .right : .wrong(miss) }))
            case .run:
                out.append(hand("r", 1, "Picture both lines running on past the arrowheads.", { v in
                    Geo4.int(v, "r") == 1 ? .right : .soft("Drag the arrowhead away from the line, so it goes on.")
                }, ring: false))
            case .name:
                out.append(hand("c", Double(p.right), p.why, { v in p.choose(Geo4.int(v, "c")) }))
            case .make:
                out.append(hand("m", Double(p.item == 0 ? 22 : p.item == 1 ? 12 : 11), "A dot is an endpoint. An arrowhead means it keeps going.", { v in p.ends(Geo4.int(v, "m", 0)) }))
            case .turn:
                out.append(hand("a", Double([45, 90, 135][p.item]), "Compare it with the page corner.", { v in p.turned(Geo4.int(v, "a", 0)) }))
            case .draw:
                out.append(hand("d", Double(p.item), p.item == 0 ? "Go the same steps as this one." : "The page corner fits where they cross.", { v in p.drawn(Geo4.int(v, "d", 2)) }))
            case .done:
                out.append(LessonStep(StepWords(say: p.why, hint: p.why, action: "Next problem"), picture: pic))
            }
        }
        return out
    }
}

// MARK: - Angles and degrees

/// Angles and degrees (g4-turns, 4.MD.5; new): a circle of radius 16 squares round a corner on a grid point, a tick every
/// 10°, longer every 90°; a fixed arm along the grid line to the right and a second on it to turn. A part of a turn: turn
/// the arm (it snaps every 5°, the arc between the arms shading, the circle's dashed cuts showing a part with a 4th grade
/// bottom), then write it. The clock: the circle as a clock face, the hand snapping to the numbers; then write it.
///
/// Numbers: clock (1 for the clock), h (the clock's number), n and d (the part). Picture keys: "at" 0 the question,
/// 1 turn, 2 write, 3 done.
public enum Turns4 {
    public static let bottoms = [2, 3, 4, 6, 8, 12]
    public static func numbers(n: Int, d: Int) -> Numbers { ["clock": 0, "n": Double(n), "d": Double(d), "h": 0] }
    public static func clock(_ h: Int) -> Numbers { ["clock": 1, "h": Double(h), "n": 0, "d": 0] }
    /// The part of a turn an angle is, with a 4th grade bottom (nil when it isn't one).
    public static func part(_ a: Int) -> (Int, Int)? {
        guard a % 360 != 0 else { return nil }
        for d in bottoms where (a * d) % 360 == 0 { let n = a * d / 360; if Geo4.g(n, d) == 1 { return (n, d) } }
        return nil
    }

    public struct Parts: Sendable {
        public let clock: Bool, h: Int, n: Int, d: Int
        public init(_ x: Numbers) {
            clock = (x["clock"] ?? 0) != 0
            h = min(11, max(1, Geo4.int(x, "h", 1)))
            d = Turns4.bottoms.contains(Geo4.int(x, "d", 4)) ? Geo4.int(x, "d", 4) : 4
            n = min(d - 1, max(1, Geo4.int(x, "n", 1)))
        }
        public var ans: Int { clock ? 30 * h : 360 * n / d }
        /// "A quarter", "Three quarters", "2/3 of a turn".
        public var partWord: String { n == 1 && d == 2 ? "A half" : n == 1 && d == 4 ? "A quarter" : n == 3 && d == 4 ? "Three quarters" : "\(n)/\(d) of a turn" }
        public var question: String { clock ? "The minute hand turns from 12 to \(h)." : "Turn it \(n)/\(d) of the way round." }
        /// The arm let go at v degrees.
        public func turned(_ v: Int) -> Verdict {
            if v == ans { return .right }
            if clock { return .wrong("That’s from 12 to \(v / 30). Stop at \(h).") }
            if let p = Turns4.part(v) { return .wrong("That’s \(p.0)/\(p.1) of a turn: \(v)°. \(partWord) is \(ans)°.") }
            return .wrong("That’s \(v)°. \(partWord) is \(ans)°.")
        }
        public func written(_ v: Double) -> Verdict {
            let a = Double(ans)
            if abs(v - a) < 1e-9 { return .right }
            if clock {
                return .wrong(Geo4.slip(a, v, [(Double(h * 5), "That’s minutes. Each number is 30° of the turn."), (360 - a, "That’s the rest of the way round."),
                                               (Double(h), "Each number is a 30° step.")]) ?? "Count the 30° steps from 12.")
            }
            return .wrong(Geo4.slip(a, v, [(100 * Double(n) / Double(d), "A whole turn is 360°."), (360 - a, "That’s the rest of the turn. Read the part you turned."),
                                           (180 * Double(n) / Double(d), "That’s a part of half a turn.")]) ?? "Split 360° into \(d) equal parts.")
        }
    }

    /// Index < 3: 1/4, 1/2 and 3/4; then the clock every third problem, and parts in thirds or sixths or fourths, eighths
    /// or twelfths or sixths.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { let q = [(1, 4), (1, 2), (3, 4)][i]; return numbers(n: q.0, d: q.1) }
        if i % 3 == 1 { return clock(Geo4.r(1, 11, &rng)) }
        let d = Geo4.pick(i % 3 == 0 ? [3, 6, 4] : [8, 12, 6], &rng)
        var n = 1
        repeat { n = Geo4.r(1, d - 1, &rng) } while Geo4.g(n, d) != 1
        return numbers(n: n, d: d)
    }

    public static let spec = LessonSpec(id: "g4-turns", title: "Angles and degrees", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).question)] },
        idea: { _ in "A whole turn is 360 one-degree steps." },
        depends: ["g4-lines", "g4-fracwhole"],
        check: [CheckItem(0), CheckItem(3, when: { let p = Parts($0); return !p.clock && (p.d == 3 || p.d == 6) }),
                CheckItem(4, when: { Parts($0).clock }), CheckItem(5, when: { let p = Parts($0); return !p.clock && (p.d == 8 || p.d == 12) })]) { x in
        let p = Parts(x), ans = p.ans
        let say1 = "\(p.question) \(p.clock ? "Turn the hand." : "Drag the arm round.")"
        let hint1 = p.clock ? "Each number is a 30° step." : "A whole turn is 360°."
        let why = "A whole turn is 360 one-degree steps."
        return [
            LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]),
            LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.box("t")], expected: ["t": Double(ans)], hint: hint1, explain: "\(p.partWord): \(ans)°.",
                                   check: { v in p.turned(Geo4.int(v, "t", 0)) }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]),
            LessonStep(StepWords(say: "How many degrees is that? Type it.", hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.box("R")], expected: ["R": Double(ans)], hint: hint1, explain: "\(ans)°.",
                                   check: { v in p.written(v["R"] ?? -1) }, incomplete: "Type the number in the box."),
                picture: ["at": 2]),
            LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 3]),
        ]
    }
}

// MARK: - Measuring angles

/// Measuring angles (g4-protractor, 4.MD.6; new): the corner on a grid point, the first arm along a grid line pointing
/// right or left. Measure: lay the protractor on (it snaps only with its centre on the corner and its edge along the first
/// arm; the scale whose 0 is on that arm is lit, its 0 ringed), then read and type it. Draw: the protractor already on;
/// turn the free arm (it snaps to whole degrees, live on the first arm's scale).
///
/// Numbers: deg, draw, left (the first arm points left). Picture keys: "at" 0 the question, 1 lay (or turn), 2 write,
/// 3 done.
public enum Protractor4 {
    public static func numbers(deg: Int, draw: Bool = false, left: Bool = false) -> Numbers { ["deg": Double(deg), "draw": draw ? 1 : 0, "left": left ? 1 : 0] }
    public struct Parts: Sendable {
        public let deg: Int, draw: Bool, left: Bool
        public init(_ x: Numbers) {
            deg = min(170, max(10, Geo4.int(x, "deg", 60))); draw = (x["draw"] ?? 0) != 0; left = (x["left"] ?? 0) != 0
        }
    }
    /// The preview's slips for a reading of an angle `ans`.
    public static func read(_ ans: Int, _ v: Double) -> Verdict {
        let a = Double(ans)
        if abs(v - a) < 1e-9 { return .right }
        let off = "That’s one long mark off. Find the long mark just before the arm, then count on: each small mark is 1°."
        return .wrong(Geo4.slip(a, v, [(180 - a, "That’s the other scale. Count from the 0 on the bottom arm: this angle is \(ans > 90 ? "bigger" : "smaller") than a square corner."),
                                       (a - 10, off), (a + 10, off)]) ?? "Read the scale that starts at 0 on the first arm.")
    }
    /// Index < 3 tens, then fives, then any whole degree; measuring and drawing take turns, the first arm right or left
    /// two at a time.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let deg = i < 3 ? 10 * Geo4.r(1, 17, &rng) : i < 6 ? 5 * Geo4.r(2, 34, &rng) : Geo4.r(10, 170, &rng)
        return numbers(deg: deg, draw: i % 2 == 1, left: (i / 2) % 2 == 1)
    }

    public static let spec = LessonSpec(id: "g4-protractor", title: "Measuring angles", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let p = Parts(x); return [.text(p.draw ? "Make an angle of \(p.deg)°." : "How big is this angle?")] },
        idea: { _ in "Count from the 0 on the first arm." },
        depends: ["g4-turns"],
        check: [CheckItem(4, when: { let p = Parts($0); return !p.draw && p.deg > 90 }), CheckItem(6, when: { let p = Parts($0); return !p.draw && p.left && p.deg < 90 }),
                CheckItem(5, when: { let p = Parts($0); return p.draw && p.deg < 90 }), CheckItem(7, when: { let p = Parts($0); return p.draw && p.deg > 90 })]) { x in
        let p = Parts(x), deg = p.deg, why = "Count from the 0 on the first arm."
        if p.draw {
            let say = "Make an angle of \(deg)°. Turn the free arm."
            return [
                LessonStep(StepWords(say: say, hint: why, action: "Let’s find out"), picture: ["at": 0]),
                LessonStep(StepWords(say: say, hint: why, action: "Check"),
                    answer: AnswerTask(prompt: [.box("a")], expected: ["a": Double(deg)], hint: why, explain: "\(deg)° on the scale from the first arm.",
                                       check: { v in
                                           let a = Geo4.int(v, "a", 0)
                                           if a == deg { return .right }
                                           return .wrong(a == 180 - deg ? "That’s \(a)°. \(deg)° is \(deg < 90 ? "smaller" : "bigger") than a square corner." : "That’s \(a)°. Count from the 0 on the first arm.")
                                       }, byHand: true),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]),
                LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 3]),
            ]
        }
        let say = "How big is this angle? Lay the protractor on it."
        return [
            LessonStep(StepWords(say: say, hint: "Put its centre on the corner.", action: "Let’s find out"), picture: ["at": 0]),
            LessonStep(StepWords(say: say, hint: "Put its centre on the corner.", action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": 1], hint: "Put its centre on the corner.", explain: "Its centre on the corner, its edge on the first arm.",
                                   check: { v in Geo4.int(v, "p") == 1 ? .right : .wrong("Put its centre on the corner.") }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]),
            LessonStep(StepWords(say: "Read where the other arm crosses. Type it.", hint: why, action: "Check"),
                answer: AnswerTask(prompt: [.box("R")], expected: ["R": Double(deg)], hint: why, explain: "\(deg)°.",
                                   check: { v in read(deg, v["R"] ?? -1) }, incomplete: "Type the number in the box."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]),
            LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 3]),
        ]
    }
}

// MARK: - Angles add up

/// Angles add up (the web app's g4-angles, 4.MD.7): a right angle's arms along grid lines, 20 squares long, or a straight
/// line 40 across; the part we know inside it with its arc and size, the missing part's arc dashed with ?. Lay the page
/// corner on it (one fits a right angle; two side by side fit the straight line), then write the missing part. The fold
/// (from index 6, now and then): the whole is a measured angle, read with the protractor first; or the whole is missing
/// and both parts are given.
///
/// Numbers: st (a straight line), a (the part we know), fold (0, 1 a measured whole W, 2 a missing whole with a second
/// part b). Picture keys: "at" 0 the question, 1 the page corner (or the protractor), 2 the second page corner, 3 read the
/// whole, 4 write, 5 done.
public enum AnglesAdd {
    public static func numbers(st: Bool = false, a: Int, fold: Int = 0, W: Int = 0, b: Int = 0) -> Numbers {
        ["st": st ? 1 : 0, "a": Double(a), "fold": Double(fold), "W": Double(W), "b": Double(b)]
    }
    public struct Parts: Sendable {
        public let st: Bool, a: Int, fold: Int, W: Int, b: Int
        public init(_ x: Numbers) {
            fold = min(2, max(0, Geo4.int(x, "fold", 0)))
            st = fold == 0 && (x["st"] ?? 0) != 0
            W = Geo4.int(x, "W", 90); b = Geo4.int(x, "b", 0)
            let top = fold == 1 ? W : fold == 2 ? 175 : st ? 180 : 90
            a = min(top - 5, max(5, Geo4.int(x, "a", 35)))
        }
        /// The whole, and the part that's missing (nil when the whole is).
        public var T: Int { fold == 1 ? W : fold == 2 ? a + b : st ? 180 : 90 }
        public var miss: Int? { fold == 2 ? nil : T - a }
        /// What the answer box holds.
        public var ans: Int { miss ?? T }
        public func written(_ v: Double) -> Verdict {
            if abs(v - Double(ans)) < 1e-9 { return .right }
            if fold == 2 { return .wrong(Geo4.slip(Double(T), v, [(Double(abs(a - b)), "Both parts fill the whole angle: add them.")]) ?? "Add the two parts: \(a)° and \(b)°.") }
            var list: [(Double, String)] = []
            if fold == 0 { list.append((Double((st ? 90 : 180) - a), "These two make \(st ? "a straight line, 180°" : "a right angle, 90°").")) }
            list.append((Double(T + a), "The missing part is smaller than the whole."))
            return .wrong(Geo4.slip(Double(ans), v, list) ?? "What goes with \(a)° to make \(T)°?")
        }
        public var why: String { fold != 0 ? "The two parts fill the whole angle." : st ? "The two parts fill the straight line." : "The two parts fill the square corner." }
    }

    /// The web's maths: index < 3 a right angle with a part in tens (20–70°); then a straight line half the time (a part
    /// 20–160°), else a right angle (15–75°); from index 6, 4 times in 10, the fold.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { return numbers(a: 10 * Geo4.r(2, 7, &rng)) }
        if i >= 6 && Double.random(in: 0..<1, using: &rng) < 0.4 {
            if Bool.random(using: &rng) { let W = 5 * Geo4.r(8, 34, &rng); return numbers(a: 5 * Geo4.r(3, W / 5 - 3, &rng), fold: 1, W: W) }
            let a = 5 * Geo4.r(4, 18, &rng)
            return numbers(a: a, fold: 2, b: 5 * Geo4.r(4, 34 - a / 5, &rng))
        }
        let st = Bool.random(using: &rng)
        return numbers(st: st, a: st ? Geo4.r(20, 160, &rng) : Geo4.r(15, 75, &rng))
    }

    public static let spec = LessonSpec(id: "g4-angles", title: "Angles add up", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let p = Parts(x); return [.text(p.fold == 2 ? "\(p.a)° + \(p.b)° = ?" : p.fold == 1 ? "\(p.a)° + ? = the whole angle" : "Two angles make \(p.st ? "a straight line" : "a right angle"). One is \(p.a)°. How big is the other one?")] },
        idea: { _ in "Angles add up: the parts fill the whole." },
        depends: ["g4-lines", "g3-addsub"],
        check: [CheckItem(0), CheckItem(3, when: { let p = Parts($0); return p.fold == 0 && !p.st }), CheckItem(3, when: { Parts($0).st }),
                CheckItem(3, when: { let p = Parts($0); return p.st && p.a % 10 != 0 }), CheckItem(6, when: { Parts($0).fold != 0 })]) { x in
        let p = Parts(x)
        var out: [LessonStep] = []
        let take = "Take away the part you know to find what’s left."
        let first: String
        switch p.fold {
        case 1: first = "How big is the whole angle? Lay the protractor on it."
        case 2: first = "How big is the whole angle? Type it."
        default: first = "How big is the whole corner? " + (p.st ? "Drag page corners onto it, side by side." : "Drag the page corner onto it.")
        }
        out.append(LessonStep(StepWords(say: first, hint: "", action: "Let’s find out"), picture: ["at": 0]))
        let wholeHint = p.st ? "Together they make a straight line, two square corners." : "Together they make a right angle, a square corner."
        if p.fold == 0 {
            let miss = "Put the page corner’s point on the angle’s corner."
            out.append(LessonStep(StepWords(say: first, hint: wholeHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("k")], expected: ["k": 1], hint: wholeHint, explain: wholeHint,
                                   check: { v in Geo4.int(v, "k") == 1 ? .right : .wrong(miss) }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            if p.st {
                out.append(LessonStep(StepWords(say: "How big is the whole corner? Another one fits beside it.", hint: wholeHint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("k")], expected: ["k": 1], hint: wholeHint, explain: wholeHint,
                                       check: { v in Geo4.int(v, "k") == 1 ? .right : .wrong(miss) }, byHand: true),
                    picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
            }
        }
        if p.fold == 1 {
            out.append(LessonStep(StepWords(say: first, hint: "Put its centre on the corner.", action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": 1], hint: "Put its centre on the corner.", explain: "Its centre on the corner.",
                                   check: { v in Geo4.int(v, "p") == 1 ? .right : .wrong("Put its centre on the corner.") }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            out.append(LessonStep(StepWords(say: "Read where the other arm crosses. Type it.", hint: "Count from the 0 on the first arm.", action: "Check"),
                answer: AnswerTask(prompt: [.box("W")], expected: ["W": Double(p.T)], hint: "Count from the 0 on the first arm.", explain: "\(p.T)°.",
                                   check: { v in Protractor4.read(p.T, v["W"] ?? -1) }, incomplete: "Type the number in the box."),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let say = p.fold == 2 ? first : "How big is the other part? Type it."
        out.append(LessonStep(StepWords(say: say, hint: p.fold == 2 ? "Both parts fill the whole angle: add them." : take, action: "Check"),
            answer: AnswerTask(prompt: [.box("R")], expected: ["R": Double(p.ans)], hint: p.fold == 2 ? "Add the two parts." : take,
                               explain: p.fold == 2 ? "\(p.a)° + \(p.b)° = \(p.T)°." : "\(p.T)° − \(p.a)° = \(p.ans)°.",
                               check: { v in p.written(v["R"] ?? -1) }, incomplete: "Type the number in the box."),
            picture: ["at": 4]))
        out.append(LessonStep(StepWords(say: p.why, hint: p.why, action: "Next problem"), picture: ["at": 5]))
        return out
    }
}

// MARK: - Sorting by sides and angles

/// Sorting by sides and angles (g4-classify, 4.G.2; new): a shape with its corners on grid points, every side whole grid
/// steps, on the left; a two-loop diagram a block to its right, named "parallel sides" and "a square corner" (for
/// triangles "a square corner" and "an obtuse angle"). 1. Tap each square corner (the page corner lays itself on it; the
/// square mark is drawn), and for triangles an obtuse one too; No more. 2. Tap two sides that are parallel (matching
/// arrowheads); No more. 3. Drag the shape into one loop, the other, both, or neither.
///
/// Numbers: shape (`shapes`), rot (quarter turns), flip. Picture keys: "at" 0 the question, 1 corners, 2 sides, 3 sort,
/// 4 done. Boxes: step 1 "x" the corners marked when No more is pressed, or 100 + i for a corner that doesn't fit; step 2
/// "y" the pairs found, or 100 + 10 i + j for sides that aren't parallel (i tapped first); step 3 "z" 2 × in the first
/// loop + in the second.
public enum Classify4 {
    public struct Shape: Sendable { public let name: String, pts: [(Int, Int)], tri: Bool }
    public static let shapes: [Shape] = [
        Shape(name: "rectangle", pts: [(0, 0), (20, 0), (20, 12), (0, 12)], tri: false),
        Shape(name: "right triangle", pts: [(0, 0), (0, 12), (18, 12)], tri: true),
        Shape(name: "parallelogram", pts: [(6, 0), (24, 0), (18, 12), (0, 12)], tri: false),
        Shape(name: "square", pts: [(0, 0), (16, 0), (16, 16), (0, 16)], tri: false),
        Shape(name: "rhombus", pts: [(0, 0), (15, 0), (24, 12), (9, 12)], tri: false),
        Shape(name: "trapezoid", pts: [(5, 0), (17, 0), (22, 12), (0, 12)], tri: false),
        Shape(name: "right trapezoid", pts: [(0, 0), (12, 0), (20, 12), (0, 12)], tri: false),
        Shape(name: "kite", pts: [(8, 0), (13, 7), (8, 20), (3, 7)], tri: false),
        Shape(name: "quadrilateral", pts: [(0, 0), (14, 2), (18, 12), (3, 10)], tri: false),
        Shape(name: "isosceles right triangle", pts: [(0, 0), (0, 14), (14, 14)], tri: true),
        Shape(name: "obtuse triangle", pts: [(0, 12), (18, 12), (24, 0)], tri: true),
        Shape(name: "acute triangle", pts: [(8, 0), (18, 14), (0, 12)], tri: true),
    ]
    public static func numbers(shape: Int, rot: Int = 0, flip: Bool = false) -> Numbers { ["shape": Double(shape), "rot": Double(rot), "flip": flip ? 1 : 0] }

    public enum Corner: Sendable { case square, obtuse, acute }
    public struct Parts: Sendable {
        public let shape: Int, rot: Int, flip: Bool
        /// Its corners in squares from its box's top-left, its sides (across, down), how each corner opens, its parallel
        /// pairs, and its size.
        public let pts: [(Int, Int)], sides: [(Int, Int)], corners: [Corner], pairs: [(Int, Int)], w: Int, h: Int
        public init(_ x: Numbers) {
            shape = min(Classify4.shapes.count - 1, max(0, Geo4.int(x, "shape", 0)))
            let r = ((Geo4.int(x, "rot", 0) % 4) + 4) % 4, f = (x["flip"] ?? 0) != 0
            rot = r; flip = f
            var p = Classify4.shapes[shape].pts.map { (f ? -$0.0 : $0.0, $0.1) }
            for _ in 0..<r { p = p.map { (-$0.1, $0.0) } }
            let mx = p.map(\.0).min() ?? 0, my = p.map(\.1).min() ?? 0
            p = p.map { ($0.0 - mx, $0.1 - my) }
            pts = p
            let n = p.count
            let s = (0..<n).map { (p[($0 + 1) % n].0 - p[$0].0, p[($0 + 1) % n].1 - p[$0].1) }
            sides = s
            corners = (0..<n).map { i in
                let u = s[i], w = (-s[(i + n - 1) % n].0, -s[(i + n - 1) % n].1), dt = u.0 * w.0 + u.1 * w.1
                return dt == 0 ? .square : dt < 0 ? .obtuse : .acute
            }
            var pr: [(Int, Int)] = []
            for i in 0..<n { for j in (i + 1)..<n where Geo4.same(s[i], s[j]) { pr.append((i, j)) } }
            pairs = pr
            w = p.map(\.0).max() ?? 0; h = p.map(\.1).max() ?? 0
        }
        public var tri: Bool { Classify4.shapes[shape].tri }
        /// The two loops' names.
        public var names: [String] { tri ? ["a square corner", "an obtuse angle"] : ["parallel sides", "a square corner"] }
        /// Whether it goes in each loop.
        public var want: [Bool] {
            tri ? [corners.contains(.square), corners.contains(.obtuse)] : [!pairs.isEmpty, corners.contains(.square)]
        }
        /// The corners to tap: the square ones (and for triangles the obtuse one).
        public var marks: [Int] { corners.indices.filter { corners[$0] == .square || (tri && corners[$0] == .obtuse) } }
        public var nS: Int { corners.filter { $0 == .square }.count }
        public var nO: Int { corners.filter { $0 == .obtuse }.count }
        /// The record: "1 pair of parallel sides, 2 square corners: both loops."
        public var record: String {
            let bare = { (s: String) in s.replacingOccurrences(of: "^an? ", with: "", options: .regularExpression) }
            let loops = want[0] && want[1] ? "both loops" : want[0] ? "the \(bare(names[0])) loop" : want[1] ? "the \(bare(names[1])) loop" : "neither loop"
            if tri { return "\(nS > 0 ? "1 square corner" : nO > 0 ? "1 obtuse angle" : "No square corner, no obtuse angle"): \(loops)." }
            let np = pairs.count
            return "\(np > 0 ? "\(np) \(np == 1 ? "pair" : "pairs") of parallel sides" : "No parallel sides"), \(nS > 0 ? "\(nS) square \(nS == 1 ? "corner" : "corners")" : "no square corners"): \(loops)."
        }
        public var why: String { tri ? "A triangle with a square corner is a right triangle." : "Parallel sides and square corners sort shapes." }

        public func cornersVerdict(_ x: Int) -> Verdict {
            if x >= 100 { return .wrong("That corner isn’t square: the page corner doesn’t fit it.") }
            if x >= marks.count { return .right }
            let left = marks.dropFirst(max(0, x)).first ?? marks[0]
            return .wrong(corners[left] == .square ? "There’s another square corner." : "There’s a corner that opens past the page corner.")
        }
        public func sidesVerdict(_ x: Int) -> Verdict {
            if x >= 100 {
                let j = (x - 100) / 10, i = (x - 100) % 10
                guard sides.indices.contains(i), sides.indices.contains(j) else { return .soft("Tap two sides.") }
                return .wrong("Not parallel: one goes \(Geo4.stepsWords(sides[j].0, sides[j].1)), the other \(Geo4.stepsWords(sides[i].0, sides[i].1)).")
            }
            if x >= pairs.count { return .right }
            return .wrong(x > 0 ? "There’s another parallel pair." : "Look again: two of its sides go the same steps.")
        }
        public func sortVerdict(_ z: Int) -> Verdict {
            let got = [z / 2 % 2 == 1, z % 2 == 1]
            if got == want { return .right }
            let k = got[0] != want[0] ? 0 : 1, nm = names[k]
            return .wrong(want[k] ? "It has \(nm), so it goes in that loop too."
                                  : "It has no \(nm.replacingOccurrences(of: "^an? ", with: "", options: .regularExpression)): keep it out of that loop.")
        }
    }

    /// Index < 3 a rectangle, a right triangle, a parallelogram; then any, turned by quarter turns or mirrored.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        i < 3 ? numbers(shape: [0, 1, 2][i]) : numbers(shape: Geo4.r(0, shapes.count - 1, &rng), rot: Geo4.r(0, 3, &rng), flip: Bool.random(using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-classify", title: "Sorting by sides and angles", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Where does it go?")] },
        idea: { _ in "Parallel sides and square corners sort shapes." },
        depends: ["g4-lines", "g4-angles"],
        check: [CheckItem(3, when: { [1, 9].contains(Parts($0).shape) }), CheckItem(3, when: { Parts($0).shape == 2 }),
                CheckItem(3, when: { Parts($0).shape == 6 }), CheckItem(3, when: { Parts($0).shape == 7 })]) { x in
        let p = Parts(x)
        let c1 = "Which corners are square? " + (p.tri ? "Tap each square corner, and a corner that opens wider. Then No more." : "Tap each square corner. Then No more.")
        var out = [LessonStep(StepWords(say: c1, hint: "", action: "Let’s find out"), picture: ["at": 0])]
        out.append(LessonStep(StepWords(say: c1, hint: "A square corner fits the page corner.", action: "No more"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(p.marks.count)], hint: "A square corner fits the page corner.",
                               explain: "\(p.marks.count) to mark.", check: { v in p.cornersVerdict(Geo4.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        if !p.tri {
            out.append(LessonStep(StepWords(say: "Which sides are parallel? Tap two sides that go the same steps. Then No more.", hint: "Parallel sides go the same steps.", action: "No more"),
                answer: AnswerTask(prompt: [.box("y")], expected: ["y": Double(p.pairs.count)], hint: "Parallel sides go the same steps.",
                                   explain: "\(p.pairs.count) parallel.", check: { v in p.sidesVerdict(Geo4.int(v, "y", 0)) }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let z = (p.want[0] ? 2 : 0) + (p.want[1] ? 1 : 0)
        out.append(LessonStep(StepWords(say: "Where does it go? Drag it into the loops.", hint: p.why, action: "Check"),
            answer: AnswerTask(prompt: [.box("z")], expected: ["z": Double(z)], hint: p.why, explain: p.record,
                               check: { v in p.sortVerdict(Geo4.int(v, "z", 0)) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        out.append(LessonStep(StepWords(say: p.why, hint: p.why, action: "Next problem"), picture: ["at": 4]))
        return out
    }
}

// MARK: - Lines of symmetry

/// Lines of symmetry (the web app's g4-symmetry, 4.G.3): the shape centred on a grid point, about 28 squares across,
/// corners on grid points where it allows (the regular triangle, pentagon and hexagon drawn true). Is the dashed line a
/// line of symmetry: fold on it (drag one half over the line; every corner lands on a corner, or parts stick out), then
/// Yes or No. How many lines: draw a fold line across it (it snaps to lines through the middle) and let go: it folds; a
/// match stays drawn and counted; No more; type the count.
///
/// Numbers: kind (0 the dashed line, 1 how many), shape, line (the dashed line's index in its lines and its tempting
/// lines), turn (quarter turns). Picture keys: "at" 0 the question, 1 fold (or draw), 2 Yes or No (or write), 3 done.
public enum Symmetry4 {
    public typealias Pt = Geo4.Pt
    public struct Shape: Sendable { public let name: String, pts: [Pt], lines: [Double], traps: [Double], regular: Int }
    static func reg(_ n: Int, _ r: Double, _ start: Double) -> [Pt] { (0..<n).map { Geo4.pol(Pt(0, 0), r, start + 360 * Double($0) / Double(n)) } }
    static let heart: [Pt] = {
        let raw = (0..<48).map { i -> Pt in
            let t = 2 * Double.pi * Double(i) / 48
            return Pt(14 * pow(sin(t), 3), -0.875 * (13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)))
        }
        let t = raw.map(\.y).min()!, b = raw.map(\.y).max()!, c = ((t + b) / 2).rounded()
        return raw.map { Pt($0.x, $0.y - c) }
    }()
    public static let shapes: [Shape] = [
        Shape(name: "square", pts: [Pt(-12, -12), Pt(12, -12), Pt(12, 12), Pt(-12, 12)], lines: [0, 90, 45, 135], traps: [], regular: 4),
        Shape(name: "rectangle", pts: [Pt(-14, -8), Pt(14, -8), Pt(14, 8), Pt(-14, 8)], lines: [0, 90], traps: [atan2(8, 14) / Geo4.rad, 180 - atan2(8, 14) / Geo4.rad], regular: 0),
        Shape(name: "triangle", pts: reg(3, 14, 90), lines: [90, 30, 150], traps: [0], regular: 3),
        Shape(name: "triangle", pts: [Pt(0, -14), Pt(9, 10), Pt(-9, 10)], lines: [90], traps: [0], regular: 0),
        Shape(name: "triangle", pts: [Pt(-3, -12), Pt(13, 9), Pt(-12, 9)], lines: [], traps: [90], regular: 0),
        Shape(name: "hexagon", pts: reg(6, 14, 0), lines: [0, 30, 60, 90, 120, 150], traps: [], regular: 6),
        Shape(name: "parallelogram", pts: [Pt(-6, -7), Pt(14, -7), Pt(6, 7), Pt(-14, 7)], lines: [], traps: [0, 90, atan2(7, 14) / Geo4.rad], regular: 0),
        Shape(name: "heart", pts: heart, lines: [90], traps: [0], regular: 0),
        Shape(name: "kite", pts: [Pt(0, -14), Pt(8, 0), Pt(0, 7), Pt(-8, 0)], lines: [90], traps: [0], regular: 0),
        Shape(name: "pentagon", pts: reg(5, 14, 90), lines: [90, 18, 54, 126, 162], traps: [0], regular: 5),
    ]
    public static func numbers(kind: Int, shape: Int, line: Int = 0, turn: Int = 0) -> Numbers {
        ["kind": Double(kind), "shape": Double(shape), "line": Double(line), "turn": Double(turn)]
    }

    /// p reflected in the line through the middle at angle a.
    public static func refl(_ p: Pt, _ a: Double) -> Pt {
        let ux = cos(a * Geo4.rad), uy = -sin(a * Geo4.rad), d = p.x * ux + p.y * uy
        return Pt(2 * d * ux - p.x, 2 * d * uy - p.y)
    }
    /// Which side of the line through the middle at angle a a point is (its distance, signed).
    public static func side(_ p: Pt, _ a: Double) -> Double { p.x * sin(a * Geo4.rad) + p.y * cos(a * Geo4.rad) }
    public static func isSym(_ pts: [Pt], _ a: Double) -> Bool { pts.allSatisfy { p in pts.contains { Geo4.dist($0, refl(p, a)) < 0.05 } } }
    /// The corners of the half on `s`'s side that land on no corner when folded.
    public static func stickOut(_ pts: [Pt], _ a: Double, _ s: Double) -> [Pt] {
        pts.filter { p in s * side(p, a) > 1e-6 && !pts.contains { Geo4.dist($0, refl(p, a)) < 0.05 } }
    }
    /// One side of the shape, cut off by the line through the middle at angle a (s: +1 or −1).
    public static func half(_ pts: [Pt], _ a: Double, _ s: Double) -> [Pt] {
        var out: [Pt] = []
        for (i, p) in pts.enumerated() {
            let q = pts[(i + 1) % pts.count], sp = s * side(p, a), sq = s * side(q, a)
            if sp >= 0 { out.append(p) }
            if (sp >= 0) != (sq >= 0) { let t = sp / (sp - sq); out.append(Pt(p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t)) }
        }
        return out
    }
    /// A point of the folding half turned th about the line: its distance from the line shrinks by cos th and it rises by
    /// sin th toward you, so it's seen a little bigger (perspective, the preview's).
    public static func folded(_ p: Pt, _ a: Double, _ th: Double) -> Pt {
        let ux = cos(a * Geo4.rad), uy = -sin(a * Geo4.rad), nx = sin(a * Geo4.rad), ny = cos(a * Geo4.rad)
        let al = p.x * ux + p.y * uy, d = p.x * nx + p.y * ny, h = abs(d) * sin(th), k = 70 / (70 - h)
        return Pt((al * ux + d * cos(th) * nx) * k, (al * uy + d * cos(th) * ny) * k)
    }
    /// The angles a drawn fold line snaps to: every 15°, and the shape's own lines and tempting lines.
    public static func snaps(_ s: Shape, turn: Int) -> [Double] {
        var out = (0..<12).map { 15 * Double($0) }
        for a in s.lines + s.traps { let b = (a + 90 * Double(turn)).truncatingRemainder(dividingBy: 180); if !out.contains(where: { abs($0 - b) < 1e-6 }) { out.append(b) } }
        return out
    }

    public struct Parts: Sendable {
        public let kind: Int, shape: Int, line: Int, turn: Int
        public init(_ x: Numbers) {
            kind = min(1, max(0, Geo4.int(x, "kind", 0)))
            shape = min(Symmetry4.shapes.count - 1, max(0, Geo4.int(x, "shape", 0)))
            let c = Symmetry4.shapes[shape].lines.count + Symmetry4.shapes[shape].traps.count
            line = min(c - 1, max(0, Geo4.int(x, "line", 0)))
            turn = ((Geo4.int(x, "turn", 0) % 4) + 4) % 4
        }
        public var S: Shape { Symmetry4.shapes[shape] }
        /// Its corners turned, about its middle.
        public var local: [Pt] {
            let r = 90 * Double(turn)
            return S.pts.map { Geo4.pol(Pt(0, 0), hypot($0.x, $0.y), Geo4.angOf(Pt(0, 0), $0) + r) }
        }
        public var trueLines: [Double] { S.lines.map { ($0 + 90 * Double(turn)).truncatingRemainder(dividingBy: 180) } }
        /// The dashed line's angle.
        public var la: Double { ((S.lines + S.traps)[line] + 90 * Double(turn)).truncatingRemainder(dividingBy: 180) }
        public var ok: Bool { Symmetry4.isSym(local, la) }
        public var n: Int { S.lines.count }
        public var heart: Bool { S.name == "heart" }
        /// What the fold shows, folded from side s.
        public func landed(_ s: Double) -> String {
            if ok { return "Every corner lands on a corner." }
            if heart { return "Parts stick out." }
            let k = Symmetry4.stickOut(local, la, s).count
            return "\(k) \(k == 1 ? "corner sticks" : "corners stick") out."
        }
        public func yesNo(_ c: Int) -> Verdict {
            if (c == 0) == ok { return .right }
            return .wrong(ok ? "Every corner lands on a corner." : shape == 1 ? "Folded on a diagonal, the corners stick out."
                          : shape == 6 ? "A parallelogram’s halves match if you turn one, not if you fold it." : "Parts stick out past the other half.")
        }
        public func count(_ v: Double) -> Verdict {
            let a = Double(n)
            if abs(v - a) < 1e-9 { return .right }
            var list: [(Double, String)] = []
            if shape == 1 { list.append((4, "The diagonals don’t work for a rectangle. Only the two through the middles of the sides: 2.")) }
            if shape == 0 { list.append((2, "A square folds on its diagonals too: 4 in all.")) }
            if S.regular > 0 { list += [(a - 1, "A regular shape with \(n) sides has \(n) lines of symmetry."), (a + 1, "A regular shape with \(n) sides has \(n) lines of symmetry.")] }
            if shape == 6 { list.append((2, "Fold a parallelogram on any line and parts stick out. It has no lines of symmetry.")) }
            return .wrong(Geo4.slip(a, v, list) ?? "Try every fold: across, up and down, corner to corner.")
        }
        public var why: String {
            if kind == 0 { return ok ? "Every corner lands on a corner." : "A line of symmetry lands every corner on a corner." }
            return n > 0 ? "\(Geo4.cap(Geo4.aAn(S.name))) folds \(n) \(n == 1 ? "way" : "ways")." : "No fold makes the two halves match."
        }
    }

    /// Index < 3 the rectangle, the square and the heart with a dashed line (half the time a tempting one); then the two
    /// kinds in turn, turned by quarter turns after index 5.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 {
            let shape = [1, 0, 7][i], c = shapes[shape], trap = !c.traps.isEmpty && Bool.random(using: &rng)
            return numbers(kind: 0, shape: shape, line: trap ? c.lines.count + Geo4.r(0, c.traps.count - 1, &rng) : Geo4.r(0, c.lines.count - 1, &rng))
        }
        let shape = Geo4.r(0, shapes.count - 1, &rng), c = shapes[shape]
        return numbers(kind: i % 2, shape: shape, line: Geo4.r(0, c.lines.count + c.traps.count - 1, &rng), turn: i > 5 ? Geo4.r(0, 3, &rng) : 0)
    }

    public static let spec = LessonSpec(id: "g4-symmetry", title: "Lines of symmetry", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).kind == 0 ? "Is the dashed line a line of symmetry?" : "How many lines of symmetry?")] },
        idea: { _ in "A line of symmetry folds a shape into two halves that match." },
        depends: ["g3-quads", "g2-shares"],
        check: [CheckItem(4, when: { let p = Parts($0); return p.kind == 0 && p.ok }), CheckItem(6, when: { let p = Parts($0); return p.kind == 0 && !p.ok }),
                CheckItem(3), CheckItem(5, when: { [1, 6].contains(Parts($0).shape) })]) { x in
        let p = Parts(x)
        if p.kind == 0 {
            let say = "Is the dashed line a line of symmetry? Fold on it: drag one half over the line."
            return [
                LessonStep(StepWords(say: say, hint: "", action: "Let’s find out"), picture: ["at": 0]),
                LessonStep(StepWords(say: say, hint: "Fold one half over the dashed line.", action: "Check"),
                    answer: AnswerTask(prompt: [.box("f")], expected: ["f": 1], hint: "Fold one half over the dashed line.", explain: p.landed(1),
                                       check: { v in Geo4.int(v, "f", 0) == 1 ? .right : .soft("Drag the half all the way over the line.") }, byHand: true),
                    picture: ["at": 1]),
                LessonStep(StepWords(say: "Do the halves match? Tap Yes or No.", hint: "Every corner should land on a corner.", action: "Check"),
                    answer: AnswerTask(prompt: [.box("c")], expected: ["c": p.ok ? 0 : 1], hint: "Every corner should land on a corner.", explain: p.why,
                                       check: { v in p.yesNo(Geo4.int(v, "c", 0)) }, byHand: true),
                    picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]),
                LessonStep(StepWords(say: p.why, hint: p.why, action: "Next problem"), picture: ["at": 3]),
            ]
        }
        let say = "How many lines of symmetry? Draw a fold line across it. Then No more."
        return [
            LessonStep(StepWords(say: say, hint: "", action: "Let’s find out"), picture: ["at": 0]),
            LessonStep(StepWords(say: say, hint: "Try every fold: across, up and down, corner to corner.", action: "No more"),
                answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(p.n)], hint: "Try every fold: across, up and down, corner to corner.", explain: p.why,
                                   check: { v in
                                       let k = Geo4.int(v, "n", 0)
                                       return k == -1 ? .wrong("Parts stick out: that’s not a line of symmetry.") : k == -2 ? .soft("You’ve folded on that line.") : .right
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]),
            LessonStep(StepWords(say: "How many lines of symmetry? Type it.", hint: "Try every fold: across, up and down, corner to corner.", action: "Check"),
                answer: AnswerTask(prompt: [.box("R")], expected: ["R": Double(p.n)], hint: "Try every fold: across, up and down, corner to corner.", explain: p.why,
                                   check: { v in p.count(v["R"] ?? -1) }, incomplete: "Type the number in the box."),
                picture: ["at": 2]),
            LessonStep(StepWords(say: p.why, hint: p.why, action: "Next problem"), picture: ["at": 3]),
        ]
    }
}
