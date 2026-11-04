import Foundation

/// What 4th grade's Measurement chapter shares (design/grade4.md chapter 7, the preview design/prototype/grade4-ch7.html).
public enum Meas4 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// A whole number as school writes it: 1,250.
    public static func n(_ v: Int) -> String { BigNumbers.commas(v) }
    static func pad2(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
    /// A time of day from minutes: 3:05 (12 for noon and midnight).
    public static func clock(_ t: Int) -> String { let h = (t / 60) % 12; return "\(h == 0 ? 12 : h):\(pad2(t % 60))" }
    /// A length of time: 1 h 20 min, 1 h, 45 min.
    public static func dur(_ t: Int) -> String { t >= 60 ? "\(t / 60) h" + (t % 60 != 0 ? " \(t % 60) min" : "") : "\(t) min" }
    /// Money from cents: $2.75, $10.
    public static func usd(_ c: Int) -> String { c % 100 != 0 ? "$\(c / 100).\(pad2(c % 100))" : "$\(c / 100)" }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func chance(_ p: Double, _ rng: inout SeededRandom) -> Bool { Double.random(in: 0..<1, using: &rng) < p }
}

// MARK: - Converting measurements

/// Converting measurements (the web app's g4-convert, 4.MD.1): n big units and m small units, written in small units.
///
/// On the paper (5th grade's Converting units, big to small): one big unit is a bar 48 squares long (40 when it's 100 or
/// 1,000 small units), a bar for each big unit, the amount over them, the extra small units a striped bar under them,
/// true to size. Drag the ruler along the first bar: it snaps a piece at a time (a small unit, or tens or hundreds of
/// them), and let go all the way along it, that bar is cut; the other bars cut and count on, each a row of a table
/// beside them (ft | in). Then n × 12 is typed, and the extra small units count on and are added.
///
/// Every step's picture has "at": 0 the question, 1 the ruler, 2 multiply (every bar cut, the table filled), 3 add the
/// extra (it counts on), 4 done.
public enum Convert4 {
    public struct Unit: Sendable {
        public let one: String, many: String, smallOne: String, smalls: String, b: String, s: String
        /// Small units in one big unit; a bar's squares; what one piece of the cut is worth; the extras' range and step.
        public let per: Int, W: Int, pv: Int, lo: Int, hi: Int, by: Int
        public let slips: [(Int, String)]
        public let short: String?
        public let story: String
    }
    /// The web's four pairs, then 4.MD.1's other units (the fold), from index 6.
    public static let units: [Unit] = [
        Unit(one: "foot", many: "feet", smallOne: "inch", smalls: "inches", b: "ft", s: "in", per: 12, W: 48, pv: 1, lo: 3, hi: 11, by: 1,
             slips: [(10, "A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."), (3, "3 is the feet in a yard. A foot is 12 inches.")],
             short: nil, story: "A rope is this long."),
        Unit(one: "meter", many: "meters", smallOne: "centimeter", smalls: "centimeters", b: "m", s: "cm", per: 100, W: 40, pv: 10, lo: 20, hi: 95, by: 5,
             slips: [(10, "A meter is 100 centimeters. “Centi” means a hundredth.")], short: nil, story: "A table is this long."),
        Unit(one: "hour", many: "hours", smallOne: "minute", smalls: "minutes", b: "h", s: "min", per: 60, W: 48, pv: 10, lo: 15, hi: 55, by: 5,
             slips: [], short: nil, story: "A road trip takes this long."),
        Unit(one: "pound", many: "pounds", smallOne: "ounce", smalls: "ounces", b: "lb", s: "oz", per: 16, W: 48, pv: 1, lo: 4, hi: 15, by: 1,
             slips: [(12, "12 is the inches in a foot. A pound is 16 ounces."), (10, "A pound is 16 ounces, not 10.")], short: nil, story: "A bag of flour weighs this much."),
        Unit(one: "kilometer", many: "kilometers", smallOne: "meter", smalls: "meters", b: "km", s: "m", per: 1000, W: 40, pv: 100, lo: 50, hi: 950, by: 50,
             slips: [], short: "Kilo means a thousand.", story: "A race is this long."),
        Unit(one: "kilogram", many: "kilograms", smallOne: "gram", smalls: "grams", b: "kg", s: "g", per: 1000, W: 40, pv: 100, lo: 50, hi: 950, by: 50,
             slips: [], short: "Kilo means a thousand.", story: "A sack of potatoes weighs this much."),
        Unit(one: "liter", many: "liters", smallOne: "milliliter", smalls: "milliliters", b: "L", s: "mL", per: 1000, W: 40, pv: 100, lo: 50, hi: 950, by: 50,
             slips: [], short: "A liter is 1,000 milliliters.", story: "A jug holds this much."),
        Unit(one: "minute", many: "minutes", smallOne: "second", smalls: "seconds", b: "min", s: "s", per: 60, W: 48, pv: 10, lo: 5, hi: 55, by: 5,
             slips: [], short: "A minute is 60 seconds.", story: "A song lasts this long."),
    ]

    public static func numbers(k: Int, n: Int, m: Int = 0, story: Bool = false) -> Numbers {
        ["k": Double(k), "n": Double(n), "m": Double(m), "story": story ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let k: Int, n: Int, m: Int, story: Bool, u: Unit
        public init(_ x: Numbers) {
            k = min(units.count - 1, max(0, Meas4.int(x, "k", 0)))
            u = units[k]
            n = min(9, max(1, Meas4.int(x, "n", 3)))
            let mm = max(0, Meas4.int(x, "m", 0))
            m = mm % units[k].by == 0 && mm < units[k].per ? mm : 0
            story = (x["story"] ?? 0) != 0
        }
        public var per: Int { u.per }
        /// The small units in the n big units, and in all of it.
        public var all: Int { n * u.per }
        public var tot: Int { all + m }
        /// A piece of the cut, in squares; pieces in a bar; the extra small units' pieces, and one's squares.
        public var pS: Int { u.pv * u.W / u.per }
        public var np: Int { u.per / u.pv }
        public var nx: Int { m / u.by }
        public var xS: Int { u.by * u.W / u.per }
        /// The extra small units' bar, in squares.
        public var xW: Int { m * u.W / u.per }
        public func smallsOf(_ c: Int) -> String { c == 1 ? u.smallOne : u.smalls }
        public var amount: String { "\(n) \(n == 1 ? u.one : u.many)" + (m > 0 ? " \(m) \(smallsOf(m))" : "") }
        /// What it asks: a story's question, or "Change it to inches."
        public var ask: String { story ? "\(u.story) How many \(u.smalls) is that?" : "Change it to \(u.smalls)." }
        /// What letting go of the ruler short of the bar's end says.
        public func cutMiss(_ c: Int) -> String {
            if let s = u.slips.first(where: { $0.0 == c && c != u.per }) { return s.1 }
            return u.short ?? "That’s \(Meas4.n(c)) \(smallsOf(c)). Cut all the way along the \(u.one)."
        }
    }

    /// The web's generator: n 2–5 for index < 3, then 2–9; extra small units 35% of the time early, 65% later; from index 6
    /// half the problems use the fold's units. A story every third problem.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let k = i >= 6 && Meas4.chance(0.5, &rng) ? Int.random(in: 4...7, using: &rng) : Int.random(in: 0...3, using: &rng)
        let u = units[k]
        let m = Meas4.chance(i < 3 ? 0.35 : 0.65, &rng) ? u.by * Int.random(in: ((u.lo + u.by - 1) / u.by)...(u.hi / u.by), using: &rng) : 0
        return numbers(k: k, n: Int.random(in: 2...(i < 3 ? 5 : 9), using: &rng), m: m, story: i % 3 == 2)
    }

    public static let spec = LessonSpec(id: "g4-convert", title: "Converting measurements", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let s = Parts(x)
            return [.num(Double(s.n)), .text(s.u.b)] + (s.m > 0 ? [.num(Double(s.m)), .text(s.u.s)] : []) + [.op("="), .text("? \(s.u.s)")]
        },
        idea: { x in "Every \(Parts(x).u.one) is the same number of \(Parts(x).u.smalls), so multiply." },
        depends: ["g3-split", "g3-mult10"],
        check: [CheckItem(0, when: { Parts($0).m == 0 }), CheckItem(3, when: { let s = Parts($0); return s.m > 0 && (s.k == 0 || s.k == 3) }),
                CheckItem(3, when: { let s = Parts($0); return s.m > 0 && (s.k == 1 || s.k == 2) }), CheckItem(8, when: { Parts($0).story })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), u = s.u, n = s.n, m = s.m, per = s.per, all = s.all, tot = s.tot, P = Meas4.n(per)
        let say1 = "\(s.ask) Drag the ruler along the first \(u.one)."
        let hint1 = "Start with just one \(u.one)."
        let cut = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.num(1), .text(u.b), .op("="), .box("c"), .text(u.s)], expected: ["c": Double(per)],
                               known: u.slips.filter { $0.0 != per }.map { (["c": Double($0.0)], $0.1) }, hint: hint1,
                               explain: "1 \(u.one) is \(P) \(u.smalls).",
                               check: { v in let c = Meas4.int(v, "c"); return c == per ? .right : .wrong(s.cutMiss(c)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])
        let hint2 = "Every \(u.one) adds \(P) more \(u.smalls), so multiply."
        var known2: [(values: [String: Double], message: String)] = []
        for (w, msg) in [(n * 10, "That’s \(n) × 10. Each \(u.one) is \(P) \(u.smalls), so multiply by \(P)."),
                         (n + per, "There are \(n) \(u.many), each \(P) \(u.smalls). That’s \(n) groups of \(P): multiply.")]
        where w != all && !known2.contains(where: { $0.values["R"] == Double(w) }) { known2.append((["R": Double(w)], msg)) }
        let mul = LessonStep(StepWords(say: "How many \(u.smalls) in \(n) \(u.many)? Type the number.", hint: hint2, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(n)), .op("×"), .num(Double(per)), .op("="), .box("R")], expected: ["R": Double(all)],
                               known: known2, hint: hint2, explain: "\(n) × \(P) = \(Meas4.n(all)).",
                               check: { [known2] v in
                                   let r = Meas4.int(v, "R")
                                   if r == all { return .right }
                                   return .wrong(known2.first { $0.values["R"] == Double(r) }?.message ?? "Count on \(P) for each \(u.one).")
                               }, incomplete: "Type the number in the box."),
            picture: ["at": 2], onMiss: ["ring": 1])
        var out = [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), cut, mul]
        if m > 0 {
            let hint3 = "Then hop on the \(m) extra \(s.smallsOf(m))."
            var known3: [(values: [String: Double], message: String)] = [(["R": Double(all)], "\(s.amount) has \(m) more \(s.smallsOf(m)). Add them on.")]
            if all + m * per != tot { known3.append((["R": Double(all + m * per)], "The \(m) \(s.smallsOf(m)) are already small units. Add them on.")) }
            out.append(LessonStep(StepWords(say: "Add on the \(m) extra \(s.smallsOf(m)). Type the number.", hint: hint3, action: "Check"),
                answer: AnswerTask(prompt: [.num(Double(all)), .op("+"), .num(Double(m)), .op("="), .box("R")], expected: ["R": Double(tot)],
                                   known: known3, hint: hint3, explain: "\(Meas4.n(all)) + \(m) = \(Meas4.n(tot)).",
                                   check: { [known3] v in
                                       let r = Meas4.int(v, "R")
                                       if r == tot { return .right }
                                       return .wrong(known3.first { $0.values["R"] == Double(r) }?.message ?? "Count on \(m) from \(Meas4.n(all)).")
                                   }, incomplete: "Type the number in the box."),
                picture: ["at": 3], onMiss: ["ring": 1]))
        }
        let why = "Every \(u.one) is \(P) \(u.smalls)."
        out.append(LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 4]))
        return out
    }
}

// MARK: - Measurement story problems

/// Measurement story problems (g4-measure, 4.MD.2; new): time, money, liquid volume, distance and mass, each on a
/// measuring line whose square the story sets (5 minutes, 25¢, 100 mL, 100 m, 100 g), its big unit a long tick with its
/// name, the start ringed. Hop each amount the story gives (a square at a time); a "How long?" story hops from the start to
/// the end, counting up. Then the answer is written in the unit the story asks for, any change of unit first.
///
/// Numbers: kind (0 time, 1 money, 2 liquid, 3 distance, 4 mass), sub (what the story does: `Sub`), s (where it starts,
/// in the line's units: minutes, cents, mL, m or g), t (where a "How long?" or change story ends), L0 (the line's left end),
/// n hops h0, h1, h2 (signed), B (the whole liters, kilometers or kilograms a story starts from), half, alt (the bus).
///
/// Every step's picture has "at": 0 the question, 1 the hops, 2 write, 3 done.
public enum MeasureStory {
    public enum Sub: Int, Sendable { case len, end1, end2, change, both, one, rep, two, take2 }
    public static let kinds = ["time", "money", "liquid", "distance", "mass"]
    /// The metric units: small, big, and how a story says half of the big one.
    static let metric: [(s: String, b: String, half: String)] = [("mL", "L", "1/2 L"), ("m", "km", "0.5 km"), ("g", "kg", "1/2 kg")]

    public struct Parts: Sendable {
        public let kind: Int, sub: Sub, s: Int, t: Int, L0: Int, hops: [Int], B: Int, half: Bool, alt: Bool
        public init(_ x: Numbers) {
            kind = min(4, max(0, Meas4.int(x, "kind", 0)))
            sub = Sub(rawValue: Meas4.int(x, "sub", 1)) ?? .end1
            s = Meas4.int(x, "s", 0); t = Meas4.int(x, "t", 0); L0 = Meas4.int(x, "L0", 0)
            let k = min(3, max(0, Meas4.int(x, "n", 0)))
            hops = (0..<k).map { Meas4.int(x, "h\($0)", 0) }
            B = Meas4.int(x, "B", 0); half = (x["half"] ?? 0) != 0; alt = (x["alt"] ?? 0) != 0
        }
        public var time: Bool { kind == 0 }
        public var money: Bool { kind == 1 }
        public var unit: (s: String, b: String, half: String)? { kind >= 2 ? MeasureStory.metric[kind - 2] : nil }
        /// What a square stands for, and the line's squares.
        public var per: Int { kind == 0 ? 5 : kind == 1 ? 25 : 100 }
        public var LW: Int { kind >= 2 ? 50 : 48 }
        /// A "How long?" story (counting up from the start to the end) or one that hops the amounts it gives.
        public var counts: Bool { sub == .len || sub == .change }
        public var take: Bool { hops.first.map { $0 < 0 } ?? false }
        /// Where it lands, and how long it was (counting up).
        public var end: Int { counts ? t : s + hops.reduce(0, +) }
        public var D: Int { t - s }
        /// A place on the line, in squares from its left end.
        public func x(_ v: Int) -> Int { (v - L0) / per }
        public var sx: Int { x(s) }
        public var tx: Int { x(t) }
        /// Where each hop starts, in squares.
        public var starts: [Int] { var out: [Int] = [], at = s; for h in hops { out.append(x(at)); at += h }; return out }
        /// An amount and a place on the line as the story says them.
        public func amount(_ q: Int) -> String {
            switch kind { case 0: Meas4.dur(q * per); case 1: Meas4.usd(q * per); default: "\(Meas4.n(q * per)) \(unit!.s)" }
        }
        public func place(_ x: Int) -> String {
            switch kind { case 0: Meas4.clock(L0 + x * per); case 1: Meas4.usd(x * per); default: "\(Meas4.n(x * per)) \(unit!.s)" }
        }
        /// A metric amount as a story says it: 2 L, 1 L 300 mL, 400 mL.
        func say(_ v: Int) -> String {
            let U = unit!
            return v % 1000 == 0 ? "\(v / 1000) \(U.b)" : v > 1000 ? "\(v / 1000) \(U.b) \(v % 1000) \(U.s)" : "\(Meas4.n(v)) \(U.s)"
        }
        /// The first metric amount as the story says it (half of the big unit, or as it is).
        var s1: String { half ? unit!.half : say(abs(hops.first ?? 0)) }

        /// The story, and what each hop is (said when a hop is the wrong length).
        public var story: String { told.story }
        public var why: [String] { told.why }
        private var told: (story: String, why: [String]) {
            switch (kind, sub) {
            case (0, .len): return ("A movie starts at \(Meas4.clock(s)) and ends at \(Meas4.clock(t)). How long is it?", [])
            case (0, .end1):
                let d = hops[0]
                return alt ? ("A bus leaves at \(Meas4.clock(s)). The ride takes \(Meas4.dur(d)). When does it get there?", ["The ride takes \(Meas4.dur(d))."])
                           : ("A game starts at \(Meas4.clock(s)) and lasts \(Meas4.dur(d)). When does it end?", ["The game lasts \(Meas4.dur(d))."])
            case (0, _):
                let d1 = hops[0], d2 = hops.count > 1 ? hops[1] : 0
                let said = !half ? Meas4.dur(d1) : d1 == 15 ? "a quarter hour" : "half an hour"
                let why1 = !half ? "She reads for \(Meas4.dur(d1))." : d1 == 15 ? "A quarter hour is 3 squares: 15 min." : "Half an hour is 6 squares: 30 min."
                return ("Ava starts reading at \(Meas4.clock(s)). She reads for \(said), then walks the dog for \(Meas4.dur(d2)). What time is it then?",
                        [why1, "The walk takes \(Meas4.dur(d2))."])
            case (1, .change): return ("A book costs \(Meas4.usd(s)). You pay with a \(Meas4.usd(t)) bill. How much change do you get?", [])
            case (1, _):
                let p1 = hops[0], p2 = hops.count > 1 ? hops[1] : 0
                return ("A cap costs \(Meas4.usd(p1)) and a ball costs \(Meas4.usd(p2)). How much for both?", ["The cap costs \(Meas4.usd(p1)).", "The ball costs \(Meas4.usd(p2))."])
            default: break
            }
            let a1 = abs(hops.first ?? 0), a2 = hops.count > 1 ? abs(hops[1]) : 0, U = unit!, kk = kind - 2
            switch sub {
            case .one:
                let a = Meas4.n(s), b = a1
                let T = [[("A pot has \(a) mL of soup. You add \(b) mL. How much soup is in it now?", "You add \(b) mL."),
                          ("A jug has \(a) mL of juice. You drink \(b) mL. How much juice is left?", "You drink \(b) mL.")],
                         [("Sam has run \(a) m. He runs \(b) m more. How far has he run now?", "He runs \(b) m more."),
                          ("A trail is \(a) m long. Mia has walked \(b) m of it. How much is left?", "Mia has walked \(b) m.")],
                         [("A box weighs \(a) g. You put in \(b) g of books. How heavy is it now?", "You put in \(b) g."),
                          ("A bag has \(a) g of flour. You use \(b) g. How much flour is left?", "You use \(b) g.")]][kk][take ? 1 : 0]
                return (T.0, [T.1])
            case .rep:
                let k = hops.count, c = a1
                let T = [("A jug has \(B) L of juice. You pour \(k) glasses of \(c) mL. How much juice is left?", "Each glass is \(c) mL."),
                         ("A road is \(B) km long. \(k) teams each paint \(c) m of it. How much is left to paint?", "Each team paints \(c) m."),
                         ("A bag has \(B) kg of rice. You cook \(k) pots of \(c) g. How much rice is left?", "Each pot takes \(c) g.")][kk]
                return (T.0, Array(repeating: T.1, count: k))
            case .two:
                let T = [("A bucket gets \(s1) of rain on Monday and \(a2) mL on Tuesday. How much rain is that?", "Monday’s rain is \(s1).", "Tuesday’s rain is \(a2) mL."),
                         ("Sam runs \(s1), then \(a2) m more. How far does he run in all?", "He runs \(s1) first.", "Then he runs \(a2) m more."),
                         ("A bag of apples weighs \(s1). A bag of pears weighs \(a2) g. How much do they weigh together?", "The apples weigh \(s1).", "The pears weigh \(a2) g.")][kk]
                return (T.0, [half ? "\(U.half) is 5 squares: \(a1) \(U.s)." : T.1, T.2])
            default:
                let T = [("A jug has \(B) L of milk. You pour \(s1) into a pot and \(a2) mL into a cup. How much is left?", "You pour \(s1) into the pot.", "You pour \(a2) mL into the cup."),
                         ("A trail is \(B) km long. Mia walks \(s1), then \(a2) m more. How much is left?", "Mia walks \(s1) first.", "Then she walks \(a2) m."),
                         ("A bag holds \(B) kg of apples. You use \(s1) for a pie and \(a2) g for jam. How much is left?", "The pie takes \(s1).", "The jam takes \(a2) g.")][kk]
                return (T.0, [half ? "\(U.half) is 5 squares: \(a1) \(U.s)." : T.1, T.2])
            }
        }

        /// The record's change of unit first (2 L = 2,000 mL; 1/2 L = 500 mL), as [big, small] amounts.
        public var unitRows: [(big: String, small: Int)] {
            guard let U = unit else { return [] }
            var out: [(String, Int)] = []
            if sub == .rep || sub == .take2 { out.append(("\(B) \(U.b)", 1000 * B)) }
            let a1 = abs(hops.first ?? 0)
            if (sub == .two || sub == .take2) && (half || a1 > 1000) { out.append((half ? U.half : say(a1), a1)) }
            return out
        }
        /// The hours and minutes of where a time story lands.
        public var eh: Int { let h = (end / 60) % 12; return h == 0 ? 12 : h }
        public var em: Int { end % 60 }
        /// The answer boxes.
        public var boxes: [String] { time ? (sub == .len ? (D >= 60 ? ["H", "M"] : ["M"]) : ["H", "M"]) : ["R"] }
        /// The line written before the answer: 3:45 + 1 h 20 min; $10 − $4.25; 2,000 − 3 × 300.
        public var lead: String {
            switch kind {
            case 0: return sub == .len ? "\(Meas4.clock(t)) − \(Meas4.clock(s))" : ([Meas4.clock(s)] + hops.map { Meas4.dur($0) }).joined(separator: " + ")
            case 1: return sub == .change ? "\(Meas4.usd(t)) − \(Meas4.usd(s))" : "\(Meas4.usd(hops[0])) + \(Meas4.usd(hops[1]))"
            default:
                let U = unit!, a1 = abs(hops.first ?? 0)
                switch sub {
                case .one: return "\(Meas4.n(s)) \(take ? "−" : "+") \(a1)"
                case .rep: return "\(B) \(U.b) − \(hops.count) × \(a1) \(U.s)"
                case .two: return "\(Meas4.n(a1)) + \(abs(hops[1]))"
                default: return "\(Meas4.n(s)) − \(Meas4.n(a1)) − \(abs(hops[1]))"
                }
            }
        }

        /// What a hop from `x` (squares) of `h` squares says: right (the last hop, or counting up to the end), the next
        /// hop now (soft), or what went wrong.
        public func hop(x: Int, h: Int) -> Verdict {
            if counts {
                if h < 0 { return .wrong("Count up: hop to the right.") }
                if x + h > tx { return .wrong("That goes past \(place(tx)).") }
                return x + h == tx ? .right : .soft("Hop on to the end.")
            }
            guard let j = starts.firstIndex(of: x) else { return .wrong("Hop on from where you are.") }
            let want = hops[j] / per
            if h == want { return j == hops.count - 1 ? .right : .soft("Now the next part.") }
            if (h > 0) != (want > 0) {
                return .wrong(want < 0 ? "That hop adds. This part is taken away: hop back." : "That hop takes away. This part is added: hop on.")
            }
            return .wrong("That hop is \(amount(abs(h))). \(why.indices.contains(j) ? why[j] : "")")
        }

        /// What the typed answer says.
        public func write(_ v: [String: Double]) -> Verdict {
            if time {
                let h = Meas4.int(v, "H", 0), mm = Meas4.int(v, "M", 0)
                if sub == .len ? (h * 60 + mm == D && mm < 60) : (h == eh && mm == em) { return .right }
                return .wrong(mm >= 60 ? "An hour is 60 minutes." : sub == .len ? "Add up your hops: a square is 5 minutes." : "Read where you land on the line.")
            }
            let x = v["R"] ?? -1
            func eq(_ y: Double) -> Bool { abs(x - y) < 1e-9 }
            if money {
                let ans = sub == .change ? t - s : end
                if eq(Double(ans) / 100) { return .right }
                if sub == .change && eq(Double(t + s) / 100) { return .wrong("That’s adding. Change is what’s left: take it away.") }
                if eq(Double(ans)) { return .wrong("That’s cents. Write dollars with a point: \(Meas4.usd(ans)).") }
                return .wrong(sub == .change ? "Add up your hops: a square is 25¢." : "Read where you land on the line.")
            }
            if eq(Double(end)) { return .right }
            let sum = hops.reduce(0) { $0 + abs($1) }, a1 = abs(hops.first ?? 0)
            if let big = unitRows.first, eq(Double(end) / 1000) || (sub == .two && !half && eq(Double(a1 % 1000 + abs(hops[1])))) {
                return .wrong("\(big.big) is \(Meas4.n(big.small)) \(unit!.s).")
            }
            if take && eq(Double(s + sum)) { return .wrong("That’s adding. The story takes it away.") }
            if !take && eq(Double(s - sum)) { return .wrong("That’s taking away. The story adds it on.") }
            return .wrong("Read where you land on the line.")
        }
    }

    public static func numbers(kind: Int, sub: Sub, s: Int, t: Int = 0, L0: Int = 0, hops: [Int] = [], B: Int = 0, half: Bool = false, alt: Bool = false) -> Numbers {
        var x: Numbers = ["kind": Double(kind), "sub": Double(sub.rawValue), "s": Double(s), "t": Double(t), "L0": Double(L0),
                          "n": Double(hops.count), "B": Double(B), "half": half ? 1 : 0, "alt": alt ? 1 : 0]
        for i in 0..<3 { x["h\(i)"] = Double(i < hops.count ? hops[i] : 0) }
        return x
    }

    /// The preview's generator: index < 5 runs through the five kinds (easy first), then any. Index < 3: one hop, one unit;
    /// then two hops or a change of unit; from index 4, now and then a half (1/2 L, 1/2 kg, 0.5 km, half an hour, a
    /// quarter hour).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 5 ? i : Int.random(in: 0...4, using: &rng), late = i >= 3, half = i >= 4 && Meas4.chance(0.4, &rng)
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if kind == 0 {
            let H0 = r(1, 7), s = H0 * 60 + 5 * r(0, 11)
            let sub: Sub = !late ? .end1 : half ? .end2 : Meas4.pick([.end1, .end2, .len], &rng)
            switch sub {
            case .len: return numbers(kind: 0, sub: .len, s: s, t: s + 5 * r(5, 30), L0: H0 * 60)
            case .end1:
                let d = late ? 5 * r(13, 30) : 5 * r(3, 11), bus = late && Meas4.chance(0.5, &rng)
                return numbers(kind: 0, sub: .end1, s: s, L0: H0 * 60, hops: [d], alt: bus)
            default:
                let d1 = half ? Meas4.pick([15, 30], &rng) : 5 * r(3, 11), d2 = 5 * r(12, 18)
                return numbers(kind: 0, sub: .end2, s: s, L0: H0 * 60, hops: [d1, d2], half: half)
            }
        }
        if kind == 1 {
            if !late || Meas4.chance(0.5, &rng) {
                let p = 25 * r(5, 39), B = p < 400 && Meas4.chance(0.5, &rng) ? 500 : 1000
                return numbers(kind: 1, sub: .change, s: p, t: B)
            }
            let p1 = 25 * r(4, 26), p2 = 25 * r(4, min(26, (1200 - p1) / 25))
            return numbers(kind: 1, sub: .both, s: 0, hops: [p1, p2])
        }
        if !late {
            let a = 100 * r(5, 25), b = 100 * r(3, 9), take = Meas4.chance(0.5, &rng) && b <= a - 100
            return numbers(kind: kind, sub: .one, s: a, hops: [take ? -b : b])
        }
        let sub: Sub = half ? Meas4.pick([.two, .take2], &rng) : Meas4.pick([.rep, .two, .take2], &rng)
        if sub == .rep {
            let B = r(2, 5), k = r(2, 3), c = 100 * r(2, 4)
            return numbers(kind: kind, sub: .rep, s: 1000 * B, hops: Array(repeating: -c, count: k), B: B)
        }
        let a1 = half ? 500 : sub == .two ? 1000 * r(1, 3) + 100 * r(1, 9) : 100 * r(3, 9), a2 = 100 * r(3, 9)
        if sub == .two { return numbers(kind: kind, sub: .two, s: 0, hops: [a1, a2], half: half) }
        let B = r(2, 5)
        return numbers(kind: kind, sub: .take2, s: 1000 * B, hops: [-a1, -a2], B: B, half: half)
    }

    public static let spec = LessonSpec(id: "g4-measure", title: "Measurement story problems", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).lead)] },
        idea: { _ in "Hop each part, then read where you land." },
        depends: ["g3-elapsed", "g4-convert", "g4-dec"],
        check: [CheckItem(5, when: { Parts($0).kind == 0 }), CheckItem(5, when: { Parts($0).kind == 1 }),
                CheckItem(5, when: { let s = Parts($0); return s.kind == 2 && !s.unitRows.isEmpty }),
                CheckItem(5, when: { let s = Parts($0); return s.kind == 3 && s.hops.count == 2 })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x)
        let say1 = s.story + " " + (s.counts ? "Hop from the ring to the end, counting up." : "Drag a hop out from where you are, one for each part.")
        let hint1 = s.counts ? "Hop from the start up to the end." : s.why.first ?? "Hop each part the story gives."
        let hop = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("x"), .box("h")], expected: ["x": Double(s.counts ? s.sx : s.starts.last ?? 0), "h": Double(s.counts ? s.tx - s.sx : (s.hops.last ?? 0) / s.per)],
                               hint: hint1, explain: "You land on \(s.place(s.x(s.end))).", check: { v in s.hop(x: Meas4.int(v, "x"), h: Meas4.int(v, "h")) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])
        let unitWord = s.time ? (s.sub == .len ? "Type the hours and minutes." : "Type the time.") : s.money ? "Type it in dollars." : "Type it in \(s.unit!.s)."
        let hint2 = s.counts && s.time ? "Add up your hops: a square is 5 minutes." : "Read where you land on the line."
        var prompt: MathLine = [.text(s.lead), .op("=")]
        var expected: [String: Double] = [:]
        if s.time {
            if s.sub == .len {
                if s.D >= 60 { prompt += [.box("H"), .text("h")]; expected["H"] = Double(s.D / 60) }
                prompt += [.box("M"), .text("min")]; expected["M"] = Double(s.D % 60)
            } else { prompt += [.box("H"), .text(":"), .box("M")]; expected = ["H": Double(s.eh), "M": Double(s.em)] }
        } else if s.money {
            prompt += [.text("$"), .box("R")]; expected["R"] = Double(s.sub == .change ? s.t - s.s : s.end) / 100
        } else { prompt += [.box("R"), .text(s.unit!.s)]; expected["R"] = Double(s.end) }
        let incomplete = s.time && s.boxes.count == 2 ? (s.sub == .len ? "Fill in the hours and the minutes." : "Fill in the hour and the minutes.") : "Type the number in the box."
        let write = LessonStep(StepWords(say: "\(s.story) \(unitWord)", hint: hint2, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: expected, hint: hint2, explain: "Hop each part, then read where you land.",
                               check: { v in s.write(v) }, incomplete: incomplete),
            picture: ["at": 2])
        let why = "Hop each part, then read where you land."
        return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), hop, write,
                LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 3])]
    }
}

// MARK: - Area and perimeter

/// Area and perimeter (the web app's g4-area, 4.MD.3, with the missing side folded in): an l by w meter rectangle.
///
/// On the paper: a square meter is one block (5 × 5 squares, its sides the paper's strong lines), as a cube is one block
/// in Unit cubes; when that's too big to see at 75% or more, a meter is 2 squares (or 1), and the picture says so. Drag
/// the corner out (it snaps to meters, the blocks inside counting), type the area; trace one long side and one short side,
/// type it; the traced half goes round onto the other two sides, and the perimeter is typed. From index 6, now and then the
/// area or the perimeter is given with one side: drag the free edge until the blocks make the area, or trace until the
/// two sides make half the way round, and the missing side is typed.
///
/// Every step's picture has "at": 0 the question, 1 make the rectangle (drag the corner, or the side), 2 the area typed,
/// 3 trace, 4 the half typed, 5 the perimeter typed (the half turned round), 6 the missing side typed, 7 done.
public enum AreaPerim {
    public static func numbers(l: Int, w: Int, fold: Int = 0) -> Numbers { ["l": Double(l), "w": Double(w), "fold": Double(fold)] }

    public struct Parts: Sendable {
        public let l: Int, w: Int, fold: Int
        public init(_ x: Numbers) {
            l = min(15, max(2, Meas4.int(x, "l", 5))); w = min(10, max(2, Meas4.int(x, "w", 3))); fold = min(2, max(0, Meas4.int(x, "fold", 0)))
        }
        public var A: Int { l * w }
        public var Pm: Int { 2 * (l + w) }
        /// Squares to a meter: 5 (a block) while the picture shows at 75% or more, else 2, else 1.
        public var U: Int {
            // the record under a rectangle 3 m tall at most, or beside one 6 m long at most (4 m tall)
            if (w <= 3 && l <= 12) || (l <= 6 && w <= 4) { return 5 }
            return 2
        }
        /// What the squares inside are called: blocks when a block is a square meter.
        public var blocks: String { U == 5 ? "blocks" : "square meters" }
        /// What a square is, when a meter isn't a block.
        public var unitLine: String { U == 5 ? "A block is a square meter." : U == 2 ? "2 squares are 1 m." : "A square is 1 m." }
        /// The edge traced `t` meters round from the top-left corner (along the top, down the side, back along the bottom).
        public func traced(_ t: Int) -> String {
            if t <= l { return "\(t) m" }
            if fold == 2 || t <= l + w { return "\(l) m + \(t - l) m = \(t) m" }
            return "\(l) m + \(w) m + \(t - l - w) m = \(t) m"
        }
    }

    /// The web's generator (l 3–15, w 2–10); from index 6, 40% of the time the area (up to 150 m²) or the perimeter is
    /// given with one side (2–15 and 2–10 m).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && Meas4.chance(0.4, &rng) {
            if Meas4.chance(0.5, &rng) {
                let w = Int.random(in: 2...10, using: &rng)
                var l: Int
                repeat { l = Int.random(in: 2...15, using: &rng) } while w * l > 150
                return numbers(l: l, w: w, fold: 1)
            }
            return numbers(l: Int.random(in: 2...10, using: &rng), w: Int.random(in: 2...10, using: &rng), fold: 2)
        }
        return numbers(l: Int.random(in: 3...15, using: &rng), w: Int.random(in: 2...10, using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-area", title: "Area and perimeter", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return [.num(Double(s.l)), .text("m"), .op("×"), .num(Double(s.w)), .text("m")] },
        idea: { _ in "Area counts the square meters inside; perimeter goes round the edge." },
        depends: ["g3-area", "g3-perim"],
        check: [CheckItem(0, when: { Parts($0).l <= 10 }), CheckItem(0, when: { Parts($0).l >= 11 }), CheckItem(0), CheckItem(6, when: { Parts($0).fold != 0 })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), l = s.l, w = s.w, A = s.A, Pm = s.Pm, half = l + w
        func typed(_ say: String, _ hint: String, _ prompt: MathLine, _ box: String, _ want: Int, _ slips: [(Int, String)], _ other: String, _ at: Int) -> LessonStep {
            let known = slips.filter { $0.0 != want }.map { (values: [box: Double($0.0)], message: $0.1) }
            return LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: prompt, expected: [box: Double(want)], known: known, hint: hint, explain: hint,
                                   check: { v in
                                       let r = Meas4.int(v, box)
                                       return r == want ? .right : .wrong(known.first { $0.values[box] == Double(r) }?.message ?? other)
                                   }, incomplete: "Type the number in the box."),
                picture: ["at": Double(at)], onMiss: ["ring": 1])
        }
        let why = "Area counts the square meters inside; perimeter goes round the edge."
        let done = LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 7])
        switch s.fold {
        case 1:
            let say1 = "Drag the side out until the \(s.blocks) make the area."
            let hint1 = "Count the \(s.blocks) along the top."
            let edge = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.num(Double(w)), .op("×"), .box("a"), .op("="), .num(Double(A))], expected: ["a": Double(l)], hint: hint1,
                                   explain: "\(w) × \(l) = \(A).",
                                   check: { v in let a = Meas4.int(v, "a"); return a == l ? .right : .wrong("\(w) × \(a) = \(w * a). The area is \(A) m².") }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1])
            let write = typed("How long is the top? Type it.", "What times \(w) makes \(A)?", [.num(Double(w)), .op("×"), .box("R"), .op("="), .num(Double(A))], "R", l, [],
                              "What times \(w) makes \(A)? Count the \(s.blocks) along the top.", 6)
            return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), edge, write, done]
        case 2:
            let say1 = "Half the way round is one long side and one short side. Trace along the top and down the side."
            let hint1 = "Half of \(Pm) m is \(Pm / 2) m."
            let trace = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.box("t")], expected: ["t": Double(half)], hint: hint1, explain: "\(l) m + \(w) m = \(half) m.",
                                   check: { v in
                                       let t = Meas4.int(v, "t")
                                       if t == half { return .right }
                                       return .wrong(t <= l ? "That’s \(t) m. Go along the top, then down the side." : "That’s \(s.traced(t)). Half of \(Pm) m is \(Pm / 2) m.")
                                   }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1])
            let write = typed("How long is the side? Type it.", "\(l) and what make \(Pm / 2)?", [.num(Double(l)), .op("+"), .box("R"), .op("="), .num(Double(Pm / 2))], "R", w,
                              [(Pm / 2, "\(Pm / 2) is both sides. Take away the \(l) m top."), (Pm - l, "Half of \(Pm) is \(Pm / 2): take \(l) from that.")],
                              "\(l) and what make \(Pm / 2)?", 6)
            return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), trace, write, done]
        default:
            let say1 = "Drag the corner out to make the rectangle. \(s.unitLine)"
            let hint1 = "Make it \(l) m along the top and \(w) m down the side."
            let drag = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.box("a"), .text("by"), .box("b")], expected: ["a": Double(l), "b": Double(w)], hint: hint1,
                                   explain: "\(l) m by \(w) m.",
                                   check: { v in
                                       let a = Meas4.int(v, "a"), b = Meas4.int(v, "b")
                                       return a == l && b == w ? .right : .wrong("That’s \(a) m by \(b) m. Make it \(l) m by \(w) m.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1])
            let area = typed("How many \(s.blocks) inside? Type the area.", "\(w) \(w == 1 ? "row" : "rows") of \(l) \(s.blocks) fill the inside.",
                             [.text("Area"), .op("="), .num(Double(l)), .op("×"), .num(Double(w)), .op("="), .box("A"), .text("m²")], "A", A,
                             [(Pm, "That’s the distance around. Area is length × width."), (half, "Area is length × width.")],
                             "Count the \(s.blocks): \(w) rows of \(l).", 2)
            let hint3 = "Go along one long side and one short side."
            let trace = LessonStep(StepWords(say: "Now the edge. Trace one long side and one short side.", hint: hint3, action: "Check"),
                answer: AnswerTask(prompt: [.box("t")], expected: ["t": Double(half)], hint: hint3, explain: "\(l) m + \(w) m = \(half) m.",
                                   check: { v in
                                       let t = Meas4.int(v, "t")
                                       return t == half ? .right : .wrong("That’s \(s.traced(t)). Trace one long side and one short side.")
                                   }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1])
            let halfStep = typed("How far did you trace? Type it.", hint3, [.num(Double(l)), .op("+"), .num(Double(w)), .op("="), .box("H")], "H", half,
                                 [(A, "This step goes along the edge: one long side plus one short side.")], "Add the two sides you traced.", 4)
            let per = typed("All the way round is that twice. Type the perimeter.", "All the way around is that twice.",
                            [.num(2), .op("×"), .num(Double(half)), .op("="), .box("Q"), .text("m")], "Q", Pm,
                            [(A, "Perimeter goes around the edge: add all four sides.")], "Both halves go round: 2 × \(half).", 5)
            return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), drag, area, trace, halfStep, per, done]
        }
    }
}

// MARK: - Line plots with fractions

/// Line plots with fractions (the web app's g4-lineplot, 4.MD.4, with making the plot folded in): 8–12 lengths in
/// fourths or eighths of an inch, plotted as X's over a line two inches long.
///
/// On the paper: two inches are 48 squares, so an inch is 24, a fourth 6 and an eighth 3. The line, its ticks, the whole
/// inches and halves named, the X's stacked over it (each 2 × 2), its title over it. The first three problems make the
/// plot: the lengths wait on cards; tap the tick for each of the first three, and the rest drop in. Then the web's
/// question (index % 3): longest minus shortest (tap them, hop between, type it), the total of one stack (tap it, type
/// it), or how many are longer (tap each X past it, or None).
///
/// Numbers: d, thing, lo (the line's left end, in d-ths), ask, v (the length asked about), make, N and x0 … x11 (the
/// lengths, in d-ths of an inch). Every step's picture has "at": 0 the question, 1 place the X's, 2 tap the longest, 3 the
/// shortest, 4 hop, 5 tap the stack, 6 tap the longer X's, 7 write, 8 done.
public enum LinePlot4 {
    public struct Thing: Sendable { public let many, one, title, long, most, least, more, together: String }
    public static let things = [
        Thing(many: "ribbons", one: "ribbon", title: "Ribbon lengths (in)", long: "long", most: "longest", least: "shortest", more: "longer", together: "Laid end to end"),
        Thing(many: "pencils", one: "pencil", title: "Pencil lengths (in)", long: "long", most: "longest", least: "shortest", more: "longer", together: "Laid end to end"),
        Thing(many: "sprouts", one: "sprout", title: "Bean sprout heights (in)", long: "tall", most: "tallest", least: "shortest", more: "taller", together: "Stacked one on top of another"),
        Thing(many: "nails", one: "nail", title: "Nail lengths (in)", long: "long", most: "longest", least: "shortest", more: "longer", together: "Laid end to end"),
    ]
    /// The box a tap on the longer X's fills once every one is lit.
    public static let allLit = 999.0

    public static func numbers(d: Int, thing: Int = 0, lo: Int = 0, ask: Int, v: Int, data: [Int], make: Bool = false) -> Numbers {
        var x: Numbers = ["d": Double(d), "thing": Double(thing), "lo": Double(lo), "ask": Double(ask), "v": Double(v), "N": Double(data.count), "make": make ? 1 : 0]
        for (i, u) in data.prefix(12).enumerated() { x["x\(i)"] = Double(u) }
        return x
    }

    /// A length in d-ths as a mixed number: (whole, top, bottom), in lowest terms.
    public static func mixed(_ v: Int, _ d: Int) -> (w: Int, n: Int, d: Int) {
        let w = v / d, r = v % d, g = gcd(r, d) == 0 ? d : gcd(r, d)
        return (w, r / g, d / g)
    }
    /// 1 3/4, 3/4, 2.
    public static func said(_ v: Int, _ d: Int) -> String {
        let m = mixed(v, d)
        return m.n == 0 ? "\(m.w)" : (m.w > 0 ? "\(m.w) " : "") + "\(m.n)/\(m.d)"
    }

    public struct Parts: Sendable {
        public let d: Int, thing: Int, lo: Int, ask: Int, v: Int, make: Bool, data: [Int]
        public init(_ x: Numbers) {
            d = Meas4.int(x, "d", 4) == 8 ? 8 : 4
            thing = min(3, max(0, Meas4.int(x, "thing", 0))); lo = Meas4.int(x, "lo", 0); ask = min(2, max(0, Meas4.int(x, "ask", 0)))
            v = Meas4.int(x, "v", 0); make = (x["make"] ?? 0) != 0
            let N = min(12, max(1, Meas4.int(x, "N", 1)))
            data = (0..<N).map { Meas4.int(x, "x\($0)", 1) }
        }
        public var th: Thing { things[thing] }
        public var hi: Int { data.max() ?? 0 }
        public var low: Int { data.min() ?? 0 }
        public func count(_ u: Int) -> Int { data.filter { $0 == u }.count }
        public var nAt: Int { count(v) }
        public var longer: Int { data.filter { $0 > v }.count }
        /// What's typed: the difference, or the stack's total (in d-ths).
        public var fin: Int { ask == 0 ? hi - low : nAt * v }
        /// The line runs two inches from lo.
        public var top: Int { lo + 2 * d }
        public func said(_ u: Int) -> String { LinePlot4.said(u, d) }
        /// How many X's are already under each one in its stack.
        public var level: [Int] { data.indices.map { i in data[..<i].filter { $0 == data[i] }.count } }
        public var tallest: Int { Set(data).map(count).max() ?? 0 }
        public var question: String {
            switch ask {
            case 0: return "How much \(th.more) is the \(th.most) \(th.one) than the \(th.least)?"
            case 1: return "\(th.together), how \(th.long) are the \(th.many) at \(said(v)) in?"
            default: return "How many \(th.many) are \(th.more) than \(said(v)) in?"
            }
        }
        /// The answer's boxes: a whole number only when it's at least 1.
        public var boxes: [String] { (fin >= d ? ["W"] : []) + ["N", "D"] }
    }

    /// The web's createFracLine checks, as they are: one tallest stack; the stack asked about has X's; no whole-inch
    /// lengths or answers in the difference and total questions.
    static func ok(_ p: Parts) -> Bool {
        let vs = Set(p.data), top = vs.map(p.count).max() ?? 0
        if vs.filter({ p.count($0) == top }).count != 1 { return false }
        if p.ask == 1 && p.nAt == 0 { return false }
        if p.ask < 2 {
            let xs = p.ask == 0 ? [p.hi, p.low, p.fin] : [p.v, p.fin]
            if xs.contains(where: { $0 % p.d == 0 }) { return false }
        }
        return true
    }

    /// The web's generator: index < 3 fourths and the longest-minus-shortest question, from 0, the plot made by hand; then
    /// fourths or eighths, the question by index % 3, starting at 0 or 1 inch; 8–12 X's.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, d = early ? 4 : Meas4.pick([4, 8], &rng), ask = early ? 0 : i % 3
        for _ in 0..<500 {
            let lo = early ? 0 : Meas4.pick([0, d], &rng), n = Int.random(in: 8...12, using: &rng), span = early ? d - 1 : 2 * d
            let data = (0..<n).map { _ in lo + 1 + min(span - 1, (Int.random(in: 0...(span - 1), using: &rng) + Int.random(in: 0...(span - 1), using: &rng)) / 2) }
            let vs = Array(Set(data)).sorted(), v = Meas4.pick(vs, &rng)
            let x = numbers(d: d, thing: Int.random(in: 0...3, using: &rng), lo: lo, ask: ask, v: v, data: data, make: early)
            if ok(Parts(x)) { return x }
        }
        return numbers(d: 4, lo: 0, ask: 0, v: 3, data: [1, 2, 2, 2, 3, 3, 1, 2], make: early)
    }

    public static let spec = LessonSpec(id: "g4-lineplot", title: "Line plots with fractions", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).question)] },
        idea: { _ in "Each X is one thing, placed above its length." },
        depends: ["g3-lineplot", "g4-likefrac", "g4-fracwhole"],
        check: [CheckItem(3, when: { Parts($0).ask == 0 }), CheckItem(4, when: { Parts($0).ask == 1 }), CheckItem(5, when: { Parts($0).ask == 2 }),
                CheckItem(6, when: { Parts($0).d == 8 })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), th = s.th, q = s.question, d = s.d, data = s.data
        func hand(_ say: String, _ hint: String, _ box: String, _ want: Int, _ at: Int, _ verdict: @escaping @Sendable (Int) -> Verdict) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: hint,
                                   check: { v in verdict(Meas4.int(v, box)) }, byHand: true),
                picture: ["at": Double(at)], onMiss: ["ring": 1])
        }
        var out: [LessonStep] = []
        if s.make {
            let say = "Each X is one \(th.one). Place the first three. Tap the line where the card’s length is."
            let hint = "Find the card’s length under the line."
            out.append(LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("k"), .box("u")], expected: ["k": 2, "u": Double(data[min(2, data.count - 1)])], hint: hint, explain: hint,
                                   check: { v in
                                       let k = min(max(0, Meas4.int(v, "k", 0)), data.count - 1), u = Meas4.int(v, "u")
                                       if u != data[k] { return .wrong("That’s \(s.said(u)). This \(th.one) is \(s.said(data[k])).") }
                                       return k >= 2 ? .right : .soft("Now the next card.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1]))
        }
        let hi = s.hi, low = s.low, v = s.v
        switch s.ask {
        case 0:
            out.append(hand("\(q) Tap the \(th.most).", "The \(th.most) is the X farthest to the right.", "u", hi, 2) { u in
                u == hi ? .right : .wrong("That’s \(s.said(u)). The \(th.most) is the X farthest to the right.") })
            out.append(hand("\(q) Now tap the \(th.least).", "The \(th.least) is the X farthest to the left.", "u", low, 3) { u in
                u == low ? .right : .wrong("That’s \(s.said(u)). The \(th.least) is the X farthest to the left.") })
            out.append(hand("\(q) Hop from the \(th.least) to the \(th.most).", "Hop until you land on \(s.said(hi)).", "h", hi - low, 4) { h in
                low + h == hi ? .right : .wrong("That lands on \(s.said(low + h)). Hop to the \(th.most) X.") })
        case 1:
            out.append(hand("\(q) Tap the \(th.many) at \(s.said(v)).", "Count the X’s above \(s.said(v)).", "u", v, 5) { u in
                u == v ? .right : .wrong("That’s the stack above \(s.said(u)). Find \(s.said(v)) first.") })
        default:
            let longer = s.longer
            out.append(hand("\(q) Tap each X \(th.more) than \(s.said(v)), or None.", "Count only the X’s to the right of \(s.said(v)).", "x",
                            longer > 0 ? Int(allLit) : -1, 6) { x in
                if x == Int(allLit) { return longer > 0 ? .right : .wrong("Look again: none are past \(s.said(v)).") }
                if x == -1 { return longer == 0 ? .right : .wrong("Look again: some X’s are past \(s.said(v)).") }
                if x == v { return .wrong("\(s.said(v)) isn’t \(th.more) than \(s.said(v)).") }
                if x < v { return .wrong("That’s \(s.said(x)): shorter than \(s.said(v)).") }
                return .soft("Tap the next one.")
            })
        }
        if s.ask < 2 {
            let fin = s.fin, nAt = s.nAt, boxes = s.boxes, m = mixed(fin, d)
            func line(_ u: Int) -> MathLine { let a = mixed(u, d); return (a.w > 0 || a.n == 0 ? [.num(Double(a.w))] : []) + (a.n > 0 ? [.frac(.num(Double(a.n)), .num(Double(a.d)))] : []) }
            let lead: MathLine = s.ask == 0 ? line(hi) + [.op("−")] + line(low) : [.num(Double(nAt)), .op("×")] + line(v)
            let ans: MathLine = (boxes.contains("W") ? [.box("W")] : []) + [.frac(.box("N"), .box("D")), .text("in")]
            var expected: [String: Double] = ["N": Double(m.n), "D": Double(m.d)]
            if boxes.contains("W") { expected["W"] = Double(m.w) }
            let hint = s.ask == 0 ? "Subtract \(s.said(hi)) − \(s.said(low)), or count the jumps between." : "Add \(s.said(v)) once for each \(th.one)."
            out.append(LessonStep(StepWords(say: "\(q) \(s.ask == 0 ? "Type the difference." : "Type the total.")", hint: hint, action: "Check"),
                answer: AnswerTask(prompt: lead + [.op("=")] + ans, expected: expected, hint: hint, explain: "That’s \(s.said(fin)) in.",
                                   check: { typed in
                                       let W = boxes.contains("W") ? Meas4.int(typed, "W", 0) : 0, n = Meas4.int(typed, "N", 0), dd = Meas4.int(typed, "D", 0)
                                       if dd == 0 { return .wrong("The bottom number can’t be 0.") }
                                       let got = Double(W) + Double(n) / Double(dd)
                                       func isv(_ x: Int) -> Bool { abs(got - Double(x) / Double(d)) < 1e-9 }
                                       if isv(fin) { return .right }
                                       if s.ask == 0 {
                                           if isv(hi + low) { return .wrong("How much \(th.more) means subtract.") }
                                           if isv(hi - low + 1) && (hi - low + 1) % d != 0 { return .wrong("Count the jumps between the two X’s, not the marks.") }
                                           return .wrong("\(s.said(hi)) − \(s.said(low)). Count the spaces between them on the line.")
                                       }
                                       if isv(nAt * d) { return .wrong("That’s how many. Each one is \(s.said(v)) \(th.long): add \(s.said(v)) \(nAt) times.") }
                                       if nAt > 1 && isv((nAt - 1) * v) { return .wrong("There are \(nAt) of them: add \(s.said(v)) \(nAt) times.") }
                                       return .wrong("Add \(s.said(v)) once for each \(th.one).")
                                   }, incomplete: boxes.contains("W") ? "Fill in every box." : "Fill in the fraction: top and bottom."),
                picture: ["at": 7]))
        }
        let why = "Each X is one \(th.one), over its length."
        let first = out[0].words.say
        return [LessonStep(StepWords(say: first, hint: out[0].words.hint, action: "Let’s find out"), picture: ["at": 0])] + out
            + [LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 8])]
    }
}
