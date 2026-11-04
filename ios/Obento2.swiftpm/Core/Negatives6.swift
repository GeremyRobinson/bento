import Foundation

/// What 6th grade's Negative numbers chapter shares (design/grade6.md chapter 4, the preview
/// design/prototype/grade6-ch4.html): a line running both ways from 0 on the grid's own squares, 0 on a strong line, and
/// the plane as two such lines crossing at 0, two squares a unit. Negatives are written with a true minus (−7).
public enum Neg6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// A number as the paper writes it: −7, 3.5, −2.5.
    public static func fm(_ x: Double) -> String { fmt(x) }
    /// A pair: (−3, 5).
    public static func pair(_ u: Double, _ v: Double) -> String { "(\(fm(u)), \(fm(v)))" }
    /// The plane in four quadrants: −12 to 12 across, −7 to 7 up, two squares a unit (the design's −8 to 8 up is a unit
    /// taller each way than the iPad shows at 75% with the words over it; every problem fits in −7 to 7).
    public static let X = 12, Y = 7
    /// A drop on a line checked as it's let go, written into one box: how many are placed right when the move finishes the
    /// step, else which one was dropped where (`wrong`), read back by `dropped`.
    public static func wrong(_ j: Int, _ v: Double) -> Double { -(1 + Double(j) * 1000 + ((v + 100) * 2).rounded()) }
    public static func dropped(_ x: Double) -> (j: Int, v: Double) {
        let c = Int((-x - 1).rounded())
        return (c / 1000, Double(c % 1000) / 2 - 100)
    }
    /// A corner dropped on the plane, in one box (whole units).
    public static func corner(_ u: Int, _ v: Int) -> Double { -(1 + Double((u + 50) * 100 + (v + 50))) }
    public static func cornerAt(_ x: Double) -> (u: Int, v: Int) { let c = Int((-x - 1).rounded()); return (c / 100 - 50, c % 100 - 50) }
}

// MARK: - Negative numbers

/// Negative numbers (g6-negatives, 6.NS.5, 6.NS.6a, 6.NS.6c): a line through 0, upright for temperature and for height
/// against sea level (a square a one, −15 to 15), across for money and yards (two squares a one, −15 to 15; with halves
/// −8 to 8). Drag the point to the number; fold the half with it over 0 (it prints its opposite); write the opposite.
/// The opposite's opposite folds twice and lands where it started.
///
/// "at": 0 the question, 1 place, 2 fold, 3 fold back (the opposite's opposite), 4 write, 5 done.
public enum Negatives6 {
    /// kind: 0 below zero (upright), 1 below sea level (upright), 2 owe, 3 have, 4 the opposite's opposite, 5 a half (°C),
    /// 6 a loss of yards.
    public static func numbers(kind: Int, n: Double) -> Numbers { ["kind": Double(kind), "n": n] }

    public struct Parts: Sendable {
        public let kind: Int, n: Double
        public init(_ x: Numbers) { kind = Int((x["kind"] ?? 0).rounded()); n = x["n"] ?? 7 }
        public var up: Bool { kind <= 1 }
        public var half: Bool { kind == 5 }
        public var twice: Bool { kind == 4 }
        /// The number placed.
        public var t: Double { kind == 3 || kind == 4 ? n : -n }
        /// What's written: −(t) = −t, or the opposite's opposite −(−n) = n.
        public var start: Double { twice ? -t : t }
        public var ans: Double { twice ? t : -t }
        /// Squares a one, and the line's ends.
        public var U: Double { up ? 1 : 2 }
        public var lo: Double { half ? -8 : -15 }
        public var hi: Double { -lo }
        public var step: Double { half ? 0.5 : 1 }
        /// What 0 means, small beside it.
        public var zero: String? { [0: "water freezes", 1: "sea level", 2: "$0", 3: "$0", 5: "water freezes", 6: "no gain"][kind] }
        public var story: String {
            let k = fmt(n)
            switch kind {
            case 0: return "It’s \(k) below zero."
            case 1: return "A diver is \(k) meters below sea level."
            case 2: return "You owe $\(k)."
            case 3: return "You have $\(k)."
            case 4: return "Find −(−\(k))."
            case 5: return "It’s \(Neg6.fm(t)) °C."
            default: return "A loss of \(k) yards."
            }
        }
        public var placeSay: String {
            twice || half ? "\(story) Put \(Neg6.fm(t)) on the line." : "\(story) Drag the point to it."
        }
        /// What dropping the point at v says (nil: right).
        public func placed(_ v: Double) -> String? {
            if abs(v - t) < 1e-9 { return nil }
            if abs(v + t) < 1e-9 {
                let a = up ? (t < 0 ? "above" : "below") : (t < 0 ? "right of" : "left of")
                return "That’s \(fmt(abs(t))) \(a) 0."
            }
            if t < 0, abs(v - (lo + abs(t))) < 1e-9 { return "Count from 0, not from the end of the line." }
            return "That’s \(Neg6.fm(v))."
        }
        public let foldSay = "Fold the paper at 0. Drag the half with the point over the 0 line."
        public let backSay = "Now fold that half back over 0."
        public let writeSay = "Write the opposite."
        public var why: String {
            if twice { return "Two folds land where it started: −(−\(fmt(n))) = \(fmt(n))." }
            if kind == 6 { return "A loss of \(fmt(n)) and a gain of \(fmt(n)) are the same distance from 0, on opposite sides." }
            return "\(Neg6.fm(t)) and \(Neg6.fm(-t)) are the same distance from 0, on opposite sides."
        }
        /// What writing v says (nil: right).
        public func written(_ v: Double) -> String? {
            if abs(v - ans) < 1e-9 { return nil }
            if twice && abs(v + t) < 1e-9 { return "That’s one fold. The second lands where it started." }
            if !twice && abs(v - t) < 1e-9 { return "That’s where it started. The fold lands on the other side of 0." }
            return "Read the number where the fold printed it."
        }
    }

    /// Problems 1–3 a story number below 0 within −10, upright (the first within 6); 4–6 opposites across (owe, have,
    /// owe); 7+ the opposite's opposite, a half (−3.5 °C), a loss of yards, in turn.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i < 3 {
            let sea = i == 1 || (i == 2 && Bool.random(using: &rng))
            return numbers(kind: sea ? 1 : 0, n: Double(i == 0 ? r(2, 6) : r(1, 10)))
        }
        if i < 6 { return numbers(kind: i == 4 ? 3 : 2, n: Double(r(2, 12))) }
        switch (i - 6) % 3 {
        case 0: return numbers(kind: 4, n: Double(r(2, 12)))
        case 1: return numbers(kind: 5, n: Double(r(1, 7)) + 0.5)
        default: return numbers(kind: 6, n: Double(r(2, 12)))
        }
    }

    public static let spec = LessonSpec(id: "g6-negatives", title: "Negative numbers", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.num(Parts(x).t)] },
        idea: { _ in "A number and its opposite are the same distance from 0, on opposite sides." },
        depends: ["g5-coord"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6), CheckItem(7)]) { x in
        let s = Parts(x)
        let placeHint = "Count from 0: each mark is \(s.half ? "a half" : "one")."
        let ask = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Let’s find out"), picture: ["at": 0])
        let place = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": s.t], hint: placeHint, explain: "\(Neg6.fm(s.t)) is \(fmt(abs(s.t))) from 0.",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.placeSay) }
                                   return s.placed(x).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        func fold(_ at: Double, _ say: String) -> LessonStep {
            let hint = "Grab the paper on the point’s side of 0."
            return LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("f")], expected: ["f": 1], hint: hint, explain: "The fold prints it on the other side of 0.",
                                   check: { v in Neg6.int(v, "f", 0) == 1 ? .right : .wrong("Fold the half with the point.") }, byHand: true),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let writeHint = "The fold printed it on the other side of 0."
        let write = LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.text("−(\(Neg6.fm(s.start)))"), .op("="), .box("x")], expected: ["x": s.ans], hint: writeHint, explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Write the number.") }
                                   return s.written(x).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Fold at 0: the opposite is the same distance on the other side.", action: "Next problem"), picture: ["at": 5])
        return [ask, place, fold(2, s.foldSay)] + (s.twice ? [fold(3, s.backSay)] : []) + [write, done]
    }
}

// MARK: - Compare and order

/// Compare and order (g6-compare, 6.NS.7a–d): the line across −12 to 12, two squares a one. Two numbers (later three),
/// each a point in its own shade waiting over its name at the line's right end: drag each to its number, then pick < or
/// > between the names (or write three in order); absolute value problems drag a bracket from 0 to each point, then
/// pick which is farther.
///
/// "at": 0 the question, 1 place, 2 sign or order, 3 measure, 4 farther, 5 done.
public enum Compare6 {
    /// kind: 0 a negative and a positive, 1 two negatives, 2 absolute value, 3 halves, 4 three in order, 5 debts, 6 temperatures.
    public static func numbers(kind: Int, _ vs: [Double]) -> Numbers {
        var n: Numbers = ["kind": Double(kind), "a": vs[0], "b": vs[1]]
        if vs.count > 2 { n["c"] = vs[2] }
        return n
    }

    public struct Parts: Sendable {
        public let kind: Int, vs: [Double]
        public init(_ x: Numbers) {
            kind = Int((x["kind"] ?? 1).rounded())
            vs = [x["a"] ?? -7, x["b"] ?? -3] + (x["c"].map { [$0] } ?? [])
        }
        public var three: Bool { vs.count == 3 }
        public var abs: Bool { kind == 2 || kind == 5 }
        public var half: Bool { kind == 3 }
        public var A: Double { vs[0] }
        public var B: Double { vs[1] }
        public var sorted: [Double] { vs.sorted() }
        public var lo: Double { sorted.first! }
        public var hi: Double { sorted.last! }
        public var names: [String] { vs.map(Neg6.fm) }
        /// The pick that's right: 0 "<", 1 ">".
        public var sign: Int { A < B ? 0 : 1 }
        /// Which is farther from 0.
        public var far: Int { Swift.abs(A) > Swift.abs(B) ? 0 : 1 }
        public var placeSay: String {
            switch kind {
            case 6: return "It’s \(names[0]) °C in one town and \(names[1]) °C in another. Drag each point to its number."
            case 5: return "One friend owes $\(fmt(-A)), another owes $\(fmt(-B)). A debt is below 0: drag each point to its number."
            default: return three ? "Put \(names[0]), \(names[1]) and \(names[2]) on the line: drag each point to its number."
                : "Put \(names[0]) and \(names[1]) on the line: drag each point to its number."
            }
        }
        /// What dropping point j at v says (nil: right).
        public func placed(_ j: Int, _ v: Double) -> String? {
            let tv = vs[j]
            if Swift.abs(v - tv) < 1e-9 { return nil }
            if tv != 0, (v < 0) != (tv < 0) || v == 0 { return "That’s \(Neg6.fm(v)). \(Neg6.fm(tv)) is \(tv < 0 ? "left" : "right") of 0." }
            return "That’s \(Neg6.fm(v))."
        }
        public let signSay = "Pick < or > between them."
        public var signed: String { A < B ? "\(names[0]) is left of \(names[1]), so it’s less." : "\(names[0]) is right of \(names[1]), so it’s more." }
        public let orderSay = "Write them in order, least first."
        public let measureSay = "Measure each one from 0: drag from 0 to each point."
        public var farSay: String { kind == 5 ? "Which is the bigger debt?" : "Which is farther from 0?" }
        public var farMiss: String { kind == 5 ? "Look at the brackets: the longer one is the bigger debt." : "Look at the brackets: the longer one is farther from 0." }
        public var farChoices: [String] { kind == 5 ? vs.map { "$\(fmt(-$0)) debt" } : names }
        /// The story's words once the sign is picked: "−7 °C is colder than −3 °C."
        public var tempWords: String { "\(names[0]) °C is \(A < B ? "colder" : "warmer") than \(names[1]) °C." }
        public var why: String {
            if three { return "Left is less. \(sorted.map(Neg6.fm).joined(separator: " < ")) reads left to right." }
            if kind == 5 { return "Left is less. \(Neg6.fm(lo)) is less than \(Neg6.fm(hi)), but a $\(fmt(-lo)) debt is the bigger debt." }
            if abs { return "Left is less. \(Neg6.fm(lo)) is less than \(Neg6.fm(hi)), but farther from 0." }
            if kind == 6 { return "Left is less. \(Neg6.fm(lo)) °C is colder than \(Neg6.fm(hi)) °C." }
            return "Left is less. \(Neg6.fm(lo)) is less than \(Neg6.fm(hi))."
        }
        /// What the three typed in order say (nil: right).
        public func ordered(_ got: [Double]) -> String? {
            if got == sorted { return nil }
            let byDigits = vs.sorted { Swift.abs($0) < Swift.abs($1) }
            return got == byDigits ? "Left is less: read them off the line from the left." : "Write each number from the line, least first."
        }
    }

    /// Problems 1–3 a negative and a positive; 4–6 two negatives (the 4th the farther first); 7+ in turn absolute value,
    /// halves, three in order, debts, temperatures. Every number is in −12 to 12.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Double { Double(Int.random(in: a...b, using: &rng)) }
        func mix(_ a: [Double]) -> [Double] { a.shuffled(using: &rng) }
        if i < 3 { return numbers(kind: 0, mix([-r(1, 11), r(1, 11)])) }
        if i < 6 { let a = -r(5, 12), b = -r(1, 4); return numbers(kind: 1, i == 3 ? [a, b] : mix([a, b])) }
        switch (i - 6) % 5 {
        case 0: return numbers(kind: 2, mix([-r(5, 12), -r(1, 4)]))
        case 1:
            let a = -(r(1, 10) + 0.5)
            return numbers(kind: 3, mix([a, a + (Bool.random(using: &rng) ? 0.5 : -0.5)]))
        case 2:
            var vs: [Double] = []
            repeat { vs = [-r(1, 9), -r(1, 9), r(1, 9)] } while Set(vs).count < 3
            return numbers(kind: 4, mix(vs))
        case 3: return numbers(kind: 5, mix([-r(6, 12), -r(1, 5)]))
        default:
            var a = 0.0, b = 0.0
            repeat { a = -r(1, 12); b = Bool.random(using: &rng) ? -r(1, 12) : r(1, 5) } while a == b
            return numbers(kind: 6, mix([a, b]))
        }
    }

    public static let spec = LessonSpec(id: "g6-compare", title: "Compare and order", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in Parts(x).vs.enumerated().flatMap { i, v -> MathLine in (i > 0 ? [.text(", ")] : []) + [.num(v)] } },
        idea: { _ in "Left is less on the number line." },
        depends: ["g6-negatives"],
        check: [CheckItem(3), CheckItem(0), CheckItem(7), CheckItem(6)]) { x in
        let s = Parts(x)
        let placeHint = "Count from 0: each mark is \(s.half ? "a half" : "one")."
        let ask = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Let’s find out"), picture: ["at": 0])
        let count = Double(s.vs.count)
        let place = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": count], hint: placeHint, explain: "Each point on its number.",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.placeSay) }
                                   if Swift.abs(x - count) < 1e-9 { return .right }
                                   guard x < 0 else { return .soft(s.placeSay) }
                                   let d = Neg6.dropped(x)
                                   return .wrong(s.placed(min(max(0, d.j), s.vs.count - 1), d.v) ?? "That’s \(Neg6.fm(d.v)).")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        var steps = [ask, place]
        if s.three {
            let toks: MathLine = [.box("o0"), .op("<"), .box("o1"), .op("<"), .box("o2")]
            steps.append(LessonStep(StepWords(say: s.orderSay, hint: "Read them off the line from the left.", action: "Check"),
                answer: AnswerTask(prompt: toks, expected: ["o0": s.sorted[0], "o1": s.sorted[1], "o2": s.sorted[2]], hint: "Read them off the line from the left.",
                                   explain: s.why,
                                   check: { v in
                                       let got = ["o0", "o1", "o2"].compactMap { v[$0] }
                                       guard got.count == 3 else { return .soft("Fill in every box.") }
                                       return s.ordered(got).map { .wrong($0) } ?? .right
                                   }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            steps.append(LessonStep(StepWords(say: s.signSay, hint: "Which point is further left?", action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": Double(s.sign)], hint: "Which point is further left?", explain: s.signed,
                                   check: { v in Neg6.int(v, "c") == s.sign ? .right : .wrong(s.signed) }, choices: ["<", ">"]),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if s.abs {
            steps.append(LessonStep(StepWords(say: s.measureSay, hint: "Start at 0 and stop on a point.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": 2], hint: "Start at 0 and stop on a point.", explain: "Each bracket runs from 0 to its point.",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft(s.measureSay) }
                                       return Neg6.int(["x": x], "x") == 2 ? .right : x < 0 ? .wrong("Stop at a point.") : .soft(s.measureSay)
                                   }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
            steps.append(LessonStep(StepWords(say: s.farSay, hint: s.farMiss, action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": Double(s.far)], hint: s.farMiss, explain: s.why,
                                   check: { v in Neg6.int(v, "c") == s.far ? .right : .wrong(s.farMiss) }, choices: s.farChoices),
                picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "Left is less.", action: "Next problem"), picture: ["at": 5]))
        return steps
    }
}

// MARK: - Distance on a number line

/// Distance on a number line (the web app's g6-numline, 6.NS.7c, 6.NS.8): from a (−12 to −1) to b (1 to 12). The line
/// across from a − 1 to b + 1, two squares a step (four when both are within 5 of 0), 0 on a strong line, dots at a and
/// b. Drag a bracket from a to 0, then from 0 to b; write |a| + |b| = −a + b, and the brackets join into one.
///
/// "at": 0 the question, 1 to 0, 2 from 0, 3 write, 4 done.
public enum Distance6 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = Int((x["a"] ?? -3).rounded()); b = Int((x["b"] ?? 5).rounded()) }
        public var sum: Int { b - a }
        /// Squares a step.
        public var U: Int { -a <= 5 && b <= 5 ? 4 : 2 }
        public static func steps(_ n: Int) -> String { "\(n) \(n == 1 ? "step" : "steps")" }
        public var negSay: String { "How far apart are \(fmt(Double(a))) and \(b)? Drag from \(fmt(Double(a))) to 0." }
        public var posSay: String { "Now from 0 to \(b)." }
        public let sumSay = "Add the two distances."
        public let why = "You cross 0, so the two distances add."
        /// What writing v says (nil: right): the web's slips.
        public func written(_ v: Int) -> String? {
            if v == sum { return nil }
            if v == Swift.abs(b + a) { return "Going from a negative to a positive crosses 0, so add." }
            if v < 0 { return "Distance counts steps, so it’s always positive." }
            if v == sum + 1 { return "Count the jumps between marks, starting after 0." }
            return "You cross 0, so add the two distances."
        }
    }

    /// The web's generator: the first three within 5 of 0, then a −12 to −1 and b 1 to 12.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        i < 3 ? numbers(a: -Int.random(in: 1...5, using: &rng), b: Int.random(in: 1...5, using: &rng))
            : numbers(a: -Int.random(in: 1...12, using: &rng), b: Int.random(in: 1...12, using: &rng))
    }

    public static let spec = LessonSpec(id: "g6-numline", title: "Distance on a number line", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.num(Double(s.a)), .text(" to "), .num(Double(s.b))] },
        idea: { _ in "From a negative to a positive, add the steps to 0 and the steps after 0." },
        depends: [],
        check: [CheckItem(0), CheckItem(3), CheckItem(3, when: { let s = Parts($0); return -s.a >= 7 && s.b >= 7 }),
                CheckItem(3, when: { let s = Parts($0); return -s.a > s.b })]) { x in
        let s = Parts(x)
        let ask = LessonStep(StepWords(say: s.negSay, hint: "Count the steps from the left dot to 0.", action: "Let’s find out"), picture: ["at": 0])
        func drag(_ at: Double, _ say: String, to: Int, hint: String) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(to)], hint: hint, explain: "\(Parts.steps(Swift.abs(to == 0 ? s.a : s.b))).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft(say) }
                                       return Int(x.rounded()) == to ? .right : .wrong("Stop at \(to).")
                                   }, byHand: true),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let neg = drag(1, s.negSay, to: 0, hint: "Count the steps from the left dot to 0.")
        let pos = drag(2, s.posSay, to: s.b, hint: "Count the steps from 0 to the right dot.")
        let sum = LessonStep(StepWords(say: s.sumSay, hint: "You cross 0, so add the two distances.", action: "Check"),
            answer: AnswerTask(prompt: [.text("|\(fmt(Double(s.a)))|"), .op("+"), .text("|\(s.b)|"), .op("="), .num(Double(-s.a)), .op("+"), .num(Double(s.b)), .op("="), .box("x")],
                               expected: ["x": Double(s.sum)], hint: "You cross 0, so add the two distances.", explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Write the number.") }
                                   return s.written(Int(x.rounded())).map { .wrong($0) } ?? (x == x.rounded() ? .right : .wrong("You cross 0, so add the two distances."))
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "From a negative to a positive, add the steps to 0 and the steps after 0.", action: "Next problem"), picture: ["at": 4])
        return [ask, neg, pos, sum, done]
    }
}

// MARK: - Points in four quadrants

/// Points in four quadrants (g6-quadrants, 6.NS.6b, 6.NS.6c): the plane, two squares a unit, −12 to 12 across and −7 to 7
/// up. Place the point (dotted lines drop to both axes); later problems fold the half with it over an axis (or both, one
/// at a time) to print its mirror and write that pair, or pick the quadrant from the signs.
///
/// "at": 0 the question, 1 place, 2 fold, 3 fold again, 4 write, 5 quadrant, 6 done.
public enum Quadrants6 {
    /// kind: 0 place, 1 fold over the x-axis, 2 over the y-axis, 3 over both, 4 a half (place), 5 which quadrant.
    public static func numbers(x: Double, y: Double, kind: Int) -> Numbers { ["x": x, "y": y, "kind": Double(kind)] }
    public static let quads = ["I", "II", "III", "IV"]
    public static func quadrant(_ u: Double, _ v: Double) -> Int { u > 0 ? (v > 0 ? 0 : 3) : (v > 0 ? 1 : 2) }

    public struct Parts: Sendable {
        public let x: Double, y: Double, kind: Int
        public init(_ n: Numbers) { x = n["x"] ?? -3; y = n["y"] ?? 5; kind = Int((n["kind"] ?? 0).rounded()) }
        /// The axes folded over, in order ("x", "y").
        public var want: [String] { kind == 1 ? ["x"] : kind == 2 ? ["y"] : kind == 3 ? ["x", "y"] : [] }
        public var ans: (x: Double, y: Double) { (kind == 1 ? x : -x, kind == 2 ? y : -y) }
        public var placeSay: String { "Put \(Neg6.pair(x, y)) on the paper: drag the point." }
        /// What dropping the point at (u, v) says (nil: right).
        public func placed(_ u: Double, _ v: Double) -> String? {
            if u == x && v == y { return nil }
            let p = Neg6.pair(u, v)
            if u == y && v == x { return "That’s \(p). x comes first." }
            if u == -x && v == y { return "That’s \(p). x is \(Neg6.fm(x)), \(x < 0 ? "left" : "right") of 0." }
            if u == x && v == -y { return "That’s \(p). y is \(Neg6.fm(y)), \(y < 0 ? "below" : "above") 0." }
            return "That’s \(p)."
        }
        public var foldSay: String { kind == 3 ? "Fold over both axes, one at a time. Drag the half with the point over an axis." : "Fold over the \(want[0])-axis. Drag the half with the point over it." }
        public let againSay = "Now fold over the other axis."
        /// What a fold says: `f` 1 over the x-axis, 2 over the y-axis, 0 the half without the point (nil: right). The
        /// second fold of both: 1 the other axis, 3 the x-axis again, 4 the y-axis again.
        public func folded(_ f: Int, second: Bool = false) -> String? {
            if f == 0 { return "Fold the half with the point." }
            if second { return f == 1 ? nil : f == 3 ? "That’s the x-axis again. Now fold over the y-axis." : "That’s the y-axis again. Now fold over the x-axis." }
            if kind == 3 { return nil }
            let axis = f == 1 ? "x" : "y"
            if axis == want[0] { return nil }
            return axis == "y" ? "That flips x. Over the x-axis, y flips." : "That flips y. Over the y-axis, x flips."
        }
        public let writeSay = "Write where it printed."
        /// What the pair typed says (nil: right).
        public func written(_ gx: Double, _ gy: Double) -> String? {
            let flipX = want.contains("y"), flipY = want.contains("x")
            func say(_ n: String, _ flips: Bool) -> String {
                if kind == 3 { return "Both flip." }
                let v = n == "x" ? x : y
                return flips ? "\(n) flips: \(Neg6.fm(v)) becomes \(Neg6.fm(-v))." : "Over the \(want[0])-axis, \(n) stays."
            }
            if gx != ans.x { return gx == -ans.x ? say("x", flipX) : "Read the pair where the fold printed it." }
            if gy != ans.y { return gy == -ans.y ? say("y", flipY) : "Read the pair where the fold printed it." }
            return nil
        }
        public let quadSay = "Which quadrant is it in?"
        public var quadMiss: String { "\(x < 0 ? "Left" : "Right") of the y-axis and \(y < 0 ? "below" : "above") the x-axis: find that corner." }
        public var why: String {
            switch kind {
            case 1: return "A fold over the x-axis keeps x and flips the sign of y."
            case 2: return "A fold over the y-axis keeps y and flips the sign of x."
            case 3: return "Two folds flip the signs of both x and y."
            case 5: return "x is \(x < 0 ? "negative" : "positive") and y is \(y < 0 ? "negative" : "positive"): quadrant \(quads[quadrant(x, y)])."
            default: return "x is \(Neg6.fm(x)), so \(x < 0 ? "left" : "right") of 0; y is \(Neg6.fm(y)), so \(y < 0 ? "down" : "up")."
            }
        }
    }

    /// Problems 1–3 one negative number within 6 (quadrants II and IV, the first in II); 4–6 any quadrant (the 4th in
    /// III); 7+ in turn folds over x, y and both, a half, and the quadrant from the signs.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Double { Double(Int.random(in: a...b, using: &rng)) }
        func s() -> Double { Bool.random(using: &rng) ? -1 : 1 }
        if i < 3 {
            var x = 0.0, y = 0.0
            repeat { x = r(1, 6); y = r(1, 6) } while x == y
            return i == 0 || Bool.random(using: &rng) ? numbers(x: -x, y: y, kind: 0) : numbers(x: x, y: -y, kind: 0)
        }
        if i < 6 {
            var x = 0.0, y = 0.0
            repeat { x = r(1, 10); y = r(1, Neg6.Y) } while x == y
            return i == 3 ? numbers(x: -x, y: -y, kind: 0) : numbers(x: s() * x, y: s() * y, kind: 0)
        }
        let k = [1, 2, 3, 4, 5][(i - 6) % 5]
        var x = 0.0, y = 0.0
        repeat { x = s() * r(1, 9); y = s() * r(1, 7) } while abs(x) == abs(y)
        if k == 4 { x = s() * (r(0, 8) + 0.5) }
        return numbers(x: x, y: y, kind: k)
    }

    public static let spec = LessonSpec(id: "g6-quadrants", title: "Points in four quadrants", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text(Neg6.pair(s.x, s.y))] },
        idea: { _ in "x says how far left or right of 0, y how far up or down." },
        depends: ["g6-negatives", "g5-coord"],
        check: [CheckItem(0, when: { let s = Parts($0); return s.x < 0 && s.y > 0 }), CheckItem(4, when: { let s = Parts($0); return s.x < 0 && s.y < 0 }),
                CheckItem(4, when: { let s = Parts($0); return s.x > 0 && s.y < 0 }), CheckItem(6)]) { n in
        let s = Parts(n)
        let placeHint = "x first: left or right of 0. Then y: up or down."
        let ask = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Let’s find out"), picture: ["at": 0])
        let place = LessonStep(StepWords(say: s.placeSay, hint: placeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x"), .box("y")], expected: ["x": s.x, "y": s.y], hint: placeHint, explain: s.why,
                               check: { v in
                                   guard let u = v["x"], let w = v["y"] else { return .soft(s.placeSay) }
                                   return s.placed(u, w).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        var steps = [ask, place]
        if !s.want.isEmpty {
            let hint = "Grab the paper on the point’s side of the axis."
            func fold(_ at: Double, _ say: String, second: Bool) -> LessonStep {
                LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("f")], expected: ["f": second ? 1 : (s.want[0] == "y" ? 2 : 1)], hint: hint, explain: "The fold prints the point’s mirror.",
                                       check: { v in s.folded(Neg6.int(v, "f", 0), second: second).map { .wrong($0) } ?? .right }, byHand: true),
                    picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
            }
            steps.append(fold(2, s.foldSay, second: false))
            if s.kind == 3 { steps.append(fold(3, s.againSay, second: true)) }
            let wHint = "Read the pair where the fold printed it."
            steps.append(LessonStep(StepWords(say: s.writeSay, hint: wHint, action: "Check"),
                answer: AnswerTask(prompt: [.text("("), .box("x"), .text(","), .box("y"), .text(")")], expected: ["x": s.ans.x, "y": s.ans.y], hint: wHint, explain: s.why,
                                   check: { v in
                                       guard let gx = v["x"], let gy = v["y"] else { return .soft("Fill in every box.") }
                                       return s.written(gx, gy).map { .wrong($0) } ?? .right
                                   }),
                picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if s.kind == 5 {
            let q = quadrant(s.x, s.y)
            steps.append(LessonStep(StepWords(say: s.quadSay, hint: s.quadMiss, action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": Double(q)], hint: s.quadMiss, explain: s.why,
                                   check: { v in Neg6.int(v, "c") == q ? .right : .wrong(s.quadMiss) }, choices: quads),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "x first, then y.", action: "Next problem"), picture: ["at": 6]))
        return steps
    }
}

// MARK: - Shapes on the plane

/// Shapes on the plane (g6-planeshapes, 6.NS.8, 6.G.3): the plane as Points in four quadrants'. Two corners of a
/// rectangle drawn with their pairs; place the other two (the sides draw in); drag along the top from corner to corner
/// (crossing an axis splits the count); write the other side, then the area or the perimeter.
///
/// "at": 0 the question, 1 corners, 2 measure, 3 the side, 4 area or perimeter, 5 done.
public enum Shapes6 {
    public static let things = ["park", "pen", "garden"]
    /// out: 0 area, 1 perimeter.
    public static func numbers(x1: Int, x2: Int, y1: Int, y2: Int, out: Int = 0, thing: Int = 0) -> Numbers {
        ["x1": Double(x1), "x2": Double(x2), "y1": Double(y1), "y2": Double(y2), "out": Double(out), "thing": Double(thing)]
    }

    public struct Parts: Sendable {
        public let x1: Int, x2: Int, y1: Int, y2: Int, perim: Bool, thing: Int
        public init(_ n: Numbers) {
            func i(_ k: String, _ d: Int) -> Int { Int((n[k] ?? Double(d)).rounded()) }
            x1 = i("x1", -4); x2 = i("x2", 5); y1 = i("y1", -2); y2 = i("y2", 3); perim = i("out", 0) == 1; thing = i("thing", 0)
        }
        public var w: Int { x2 - x1 }
        public var h: Int { y2 - y1 }
        public var crossX: Bool { x1 < 0 && x2 > 0 }
        public var crossY: Bool { y1 < 0 && y2 > 0 }
        public var total: Int { perim ? 2 * (w + h) : w * h }
        /// The corners: top left, top right (given), bottom right, bottom left (to place).
        public var corners: [(u: Int, v: Int)] { [(x1, y2), (x2, y2), (x2, y1), (x1, y1)] }
        public var cornersSay: String { "The \(Shapes6.things[thing % 3]) is a rectangle. Put its other two corners: both have y = \(fmt(Double(y1)))." }
        /// What dropping a corner at (u, v) says (nil: one of the two).
        public func placed(_ u: Int, _ v: Int) -> String? {
            if (u == x1 || u == x2) && v == y1 { return nil }
            if (u == x1 || u == x2) && v != y1 && v != y2 { return "That’s \(Neg6.pair(Double(u), Double(v))). Its y is \(fmt(Double(y1)))." }
            return "A corner shares x with one corner and y with the other."
        }
        public let measureSay = "Measure the top: drag along it from corner to corner."
        /// The top's count: "4 + 5 = 9" across the y-axis, "11 − 4 = 7" on one side of it.
        public var topCount: String {
            crossX ? "\(abs(x1)) + \(x2) = \(w)" : "\(max(abs(x1), abs(x2))) − \(min(abs(x1), abs(x2))) = \(w)"
        }
        public let sideSay = "Now the side."
        public var totalSay: String { perim ? "Now the perimeter." : "Now the area." }
        /// The side's line: |3| + |−2| or |8| − |3| (the farther first).
        public var sideTerms: (Int, Int) { crossY ? (y2, y1) : (abs(y1) > abs(y2) ? (y1, y2) : (y2, y1)) }
        /// What the side typed says (nil: right).
        public func side(_ v: Int) -> String? {
            if v == h { return nil }
            if crossY && v == abs(abs(y2) - abs(y1)) { return "The side crosses 0: \(abs(y2)) and \(abs(y1)) add." }
            if !crossY && v == abs(y1) + abs(y2) { return "Both ends are on one side of 0: take away." }
            if v == h + 1 { return "Count the units between the corners, not the points." }
            return crossY ? "Count from each corner to the axis, and add." : "Take the nearer one’s distance from the farther one’s."
        }
        /// What the area or perimeter typed says (nil: right).
        public func totalled(_ v: Int) -> String? {
            if v == total { return nil }
            if perim { return v == w * h ? "That’s the area. Add all four sides." : "Add all four sides." }
            return v == 2 * (w + h) ? "That’s all the way round. Area: multiply the sides." : "Multiply the two sides."
        }
        public var why: String { crossX ? "The side crosses the axis, so the two distances to it add." : "The side stays on one side of the axis, so take the distances away." }
    }

    /// Problems 1–3 one side crossing an axis; 4–6 both crossing; 7+ in turn on one side of the axes (take away, area),
    /// both crossing (perimeter), one side (perimeter). Corners never 1 from an axis; never area = perimeter.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        func s() -> Int { Bool.random(using: &rng) ? -1 : 1 }
        while true {
            var x1 = 0, x2 = 0, y1 = 0, y2 = 0, out = 0
            if i < 3 {
                x1 = -r(2, 8); x2 = r(2, 9); y1 = r(2, 5); y2 = r(y1 + 2, Neg6.Y)
                if i > 0 && r(0, 9) < 4 { (y1, y2) = (-y2, -y1) }
            } else if i < 6 {
                x1 = -r(2, 9); x2 = r(2, 9); y1 = -r(2, 6); y2 = r(2, Neg6.Y)
            } else {
                switch (i - 6) % 3 {
                case 0:
                    let sx = s(), sy = s(), a = r(2, 7), b = r(a + 2, 11), c = r(2, 4), d = r(c + 2, Neg6.Y)
                    (x1, x2) = sx > 0 ? (a, b) : (-b, -a); (y1, y2) = sy > 0 ? (c, d) : (-d, -c)
                case 1:
                    out = 1; x1 = -r(2, 9); x2 = r(2, 9); y1 = -r(2, 6); y2 = r(2, Neg6.Y)
                default:
                    out = 1
                    let a = r(2, 7), b = r(a + 2, 11)
                    (x1, x2) = s() > 0 ? (a, b) : (-b, -a); y1 = r(2, 4); y2 = r(y1 + 2, Neg6.Y)
                }
            }
            let w = x2 - x1, h = y2 - y1
            if w * h != 2 * (w + h) { return numbers(x1: x1, x2: x2, y1: y1, y2: y2, out: out, thing: r(0, 2)) }
        }
    }

    public static let spec = LessonSpec(id: "g6-planeshapes", title: "Shapes on the plane", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text("\(Neg6.pair(Double(s.x1), Double(s.y2))) \(Neg6.pair(Double(s.x2), Double(s.y2)))")] },
        idea: { _ in "A side that crosses an axis is the two distances to it added." },
        depends: ["g6-quadrants", "g6-numline"],
        check: [CheckItem(0), CheckItem(6), CheckItem(3), CheckItem(7)]) { n in
        let s = Parts(n)
        let cHint = "A corner shares x with one corner and y with the other."
        let ask = LessonStep(StepWords(say: s.cornersSay, hint: cHint, action: "Let’s find out"), picture: ["at": 0])
        let corners = LessonStep(StepWords(say: s.cornersSay, hint: cHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 2], hint: cHint, explain: "Under each corner, at y = \(fmt(Double(s.y1))).",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.cornersSay) }
                                   if Neg6.int(["x": x], "x") == 2 { return .right }
                                   guard x < 0 else { return .soft(s.cornersSay) }
                                   let c = Neg6.cornerAt(x)
                                   return .wrong(s.placed(c.u, c.v) ?? cHint)
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let mHint = "Start on a top corner and stop on the other."
        let measure = LessonStep(StepWords(say: s.measureSay, hint: mHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.w)], hint: mHint, explain: s.topCount,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.measureSay) }
                                   return Neg6.int(["x": x], "x") == s.w ? .right : .wrong("Stop at the corner.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let (fa, fb) = s.sideTerms
        let sHint = s.crossY ? "Count from each corner to the axis, and add." : "Take the nearer one’s distance from the farther one’s."
        let side = LessonStep(StepWords(say: s.sideSay, hint: sHint, action: "Check"),
            answer: AnswerTask(prompt: [.text("|\(fmt(Double(fa)))|"), .op(s.crossY ? "+" : "−"), .text("|\(fmt(Double(fb)))|"), .op("="), .box("h")],
                               expected: ["h": Double(s.h)], hint: sHint, explain: "The side is \(s.h).",
                               check: { v in
                                   guard let x = v["h"] else { return .soft("Write the number.") }
                                   return s.side(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tHint = s.perim ? "Add all four sides." : "Multiply the two sides."
        let lead: MathLine = s.perim
            ? [.text("Perimeter"), .op("="), .num(Double(s.w)), .op("+"), .num(Double(s.h)), .op("+"), .num(Double(s.w)), .op("+"), .num(Double(s.h))]
            : [.text("Area"), .op("="), .num(Double(s.w)), .op("×"), .num(Double(s.h))]
        let total = LessonStep(StepWords(say: s.totalSay, hint: tHint, action: "Check"),
            answer: AnswerTask(prompt: lead + [.op("="), .box("A")], expected: ["A": Double(s.total)], hint: tHint, explain: "\(s.total).",
                               check: { v in
                                   guard let x = v["A"] else { return .soft("Write the number.") }
                                   return s.totalled(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Across an axis the distances add; on one side, take away.", action: "Next problem"), picture: ["at": 5])
        return [ask, corners, measure, side, total, done]
    }
}
