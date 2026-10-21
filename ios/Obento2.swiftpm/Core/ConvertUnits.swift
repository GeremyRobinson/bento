import Foundation

/// Converting units (the web app's g5-units): n big units = ? small units (multiply), or with `up`,
/// n small units = ? big units (divide). Big units may be a half (3.5 kilograms), and small-to-big answers may come out
/// a half (250 centimeters = 2.5 meters).
/// Numbers: u (which unit pair, an index into `units`), n (the amount the problem starts from, in big units, or in small
/// units when up), up (0 = big to small, 1 = small to big). The web's generator, ranges, order, slips and stories.
///
/// On the paper (design/grade5.md): big to small, one big unit is a bar 48 squares long (40 for 100 and 1000), one bar
/// for each big unit (the last half long for a half), each named "1 ft" at its right end and their column braced and
/// named with the amount ("3 ft"): the problem, written once as the picture's own names. The child drags the ruler and
/// cuts the first bar into its small units (for 60, 100 and 1000 the pieces are tens, or hundreds of grams): the cut's
/// box is how many small units one big unit holds (the web's "one" step, with its mix-ups), measured when it's neither
/// ("One foot is more than 8 inches."). Then every bar is cut the same way and every piece counted on (See), and the
/// record `n ft = n × 12 = [ ] in` is written, the product typed. Small to big, the small units are one long bar named
/// with the amount; a one-big-unit ruler hops along it, as far as whole big units go (the hops' box, measured when
/// it's short or long: "3 meters is 300 centimeters, more than 250."), what's left a half; then `n cm = n ÷ 100 = [ ] m`,
/// the quotient typed. The web's "More or fewer?" step is gone: the picture shows it, and its words are the record's
/// slips (multiplied instead of divided, or the other way). Units are written the school way in the picture and the
/// record (ft, in, yd, m, cm, kg, g, h, min, gal, qt, lb, oz).
///
/// Picture keys, by step (cumulative): big to small "ruler" (the cut), "cut" (every bar cut and counted, the record
/// written), "done" (the answer written); small to big "hops" (the ruler hopping), "hopped" (the hops laid, what's left
/// bracketed, the record written), "done". A hint on the record (after a miss, or asked for) lights "last" (the last
/// piece counted, or what's left, ringed).
public enum ConvertUnits {
    /// [one big unit, many big units, small units, small units in one big unit], as the web's UNITS.
    public static let units: [(one: String, many: String, small: String, per: Double)] = [
        ("foot", "feet", "inches", 12), ("yard", "yards", "feet", 3), ("meter", "meters", "centimeters", 100), ("kilogram", "kilograms", "grams", 1000),
        ("hour", "hours", "minutes", 60), ("gallon", "gallons", "quarts", 4), ("pound", "pounds", "ounces", 16),
    ]

    /// Each unit written the school way, by its name (one or many).
    public static let abbr = ["foot": "ft", "feet": "ft", "inches": "in", "yard": "yd", "yards": "yd", "meter": "m", "meters": "m",
                              "centimeters": "cm", "kilogram": "kg", "kilograms": "kg", "grams": "g", "hour": "h", "hours": "h",
                              "minutes": "min", "gallon": "gal", "gallons": "gal", "quarts": "qt", "pound": "lb", "pounds": "lb", "ounces": "oz"]

    /// One big unit's bar, in squares: 48 long (40 for 100 and 1000, cut in tens), and what one of its pieces is worth
    /// in small units (1; 10 for minutes and centimeters, 100 for grams), so a piece is a whole number of squares.
    public static func bar(_ per: Double) -> (length: Int, piece: Double) {
        (per == 100 || per == 1000 ? 40 : 48, per == 1000 ? 100 : per >= 60 ? 10 : 1)
    }

    /// one small unit, by its plural
    static let smallOne = ["inches": "inch", "feet": "foot", "centimeters": "centimeter", "grams": "gram", "minutes": "minute", "quarts": "quart", "ounces": "ounce"]

    /// "a" or "an" before a unit: "an inch", "an hour" (said with a silent h)
    static func an(_ w: String) -> String { w == "hour" || "aeiou".contains(w.first!.lowercased()) ? "an" : "a" }
    static func cap(_ w: String) -> String { w.prefix(1).uppercased() + w.dropFirst() }

    /// The mix-ups for "how many in one?", in order (g4-convert's, for the units it has).
    static let mixUps: [String: [(Double, String)]] = [
        "foot": [(10, "A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."), (3, "3 is the feet in a yard. A foot is 12 inches.")],
        "yard": [(12, "12 is the inches in a foot. A yard is 3 feet."), (36, "36 is the inches in a yard. A yard is 3 feet.")],
        "meter": [(10, "A meter is 100 centimeters. “Centi” means a hundredth."), (1000, "1,000 is the millimeters in a meter. A meter is 100 centimeters.")],
        "kilogram": [(100, "“Kilo” means a thousand: a kilogram is 1,000 grams."), (10, "“Kilo” means a thousand: a kilogram is 1,000 grams.")],
        "hour": [(100, "Clocks don’t count by 100s. An hour is 60 minutes."), (24, "24 is the hours in a day. An hour is 60 minutes.")],
        "gallon": [(8, "8 is the pints in a gallon. A gallon is 4 quarts."), (2, "2 is the pints in a quart. A gallon is 4 quarts.")],
        "pound": [(12, "12 is the inches in a foot. A pound is 16 ounces."), (10, "A pound is 16 ounces, not 10.")],
    ]

    /// The web's slips(): drop any slip that is the answer or repeats an earlier one.
    static func unitSlips(_ ans: Double, _ list: [(Double, String)]) -> [(values: [String: Double], message: String)] {
        var seen: Set<Double> = [ans]
        return list.filter { seen.insert($0.0).inserted }.map { (["x": $0.0], $0.1) }
    }

    /// A problem by its big unit's name: ("foot", 3) is 3 feet = ? inches; ("meter", 250, up: true) is 250 centimeters = ? meters.
    public static func numbers(_ one: String, _ n: Double, up: Bool = false) -> Numbers {
        ["u": Double(units.firstIndex { $0.one == one } ?? 0), "n": n, "up": up ? 1 : 0]
    }

    struct Problem {
        let one: String, many: String, small: String, f: Double, n: Double, up: Bool
        init(_ x: Numbers) {
            let u = units[min(max(Int((x["u"] ?? 0).rounded()), 0), units.count - 1)]
            one = u.one; many = u.many; small = u.small; f = u.per; n = x["n"] ?? 0; up = (x["up"] ?? 0) == 1
        }
        /// how many big units the problem is about
        var big: Double { up ? n / f : n }
        var answer: Double { ((up ? n / f : n * f) * 1_000_000).rounded() / 1_000_000 }
        var target: String { up ? many : small }
        /// "3.5 kilograms" or "250 centimeters", without the number
        var givenUnit: String { up ? (n == 1 ? smallOne[small] ?? small : small) : (n == 1 ? one : many) }
        var given: String { "\(fmt(n)) \(givenUnit)" }
        var givenMath: MathLine { [.num(n), .text(givenUnit)] }
        /// The units the school way: the big one and the small one.
        var B: String { abbr[one] ?? one }
        var S: String { abbr[small] ?? small }
        /// What one piece of the cut is worth (1, or tens), and how many pieces one big unit is cut into.
        var piece: Double { bar(f).piece }
        var pieces: Int { Int((f / piece).rounded()) }
        /// The whole big units that fit (the hops), and what's left over in small units.
        var whole: Int { Int((big + 1e-9).rounded(.down)) }
        var left: Double { n - Double(whole) * f }
    }

    /// The web's order: the first three big to small (2–12 big units, any conversion), then small to big for three,
    /// then either way at random, with halves when the small units in one big unit are even.
    static func draw(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let u = Int.random(in: 0...(units.count - 1), using: &rng), f = units[u].per
        let half = index >= 6 && Int(f) % 2 == 0
        if index < 3 { return ["u": Double(u), "n": Double(Int.random(in: 2...12, using: &rng)), "up": 0] }
        let up = index < 6 || Double.random(in: 0..<1, using: &rng) < 0.5
        let w = Double(Int.random(in: 2...9, using: &rng)) + (half ? 0.5 : 0)
        return ["u": Double(u), "n": up ? w * f : w, "up": up ? 1 : 0]
    }

    /// What a cut of one big unit says (`x`: the small units the ruler's pieces add up to). Right at `f`; the web's mix-ups
    /// are the step's slips; anything else is measured against one big unit.
    static func cutVerdict(_ x: Double?, _ p: Problem) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag the ruler first.") }
        if abs(x - p.f) < 1e-9 { return .right }
        let one = "One \(p.one)", X = fmt(x)
        return x < p.f ? .wrong("\(one) is more than \(X) \(p.small). Cut smaller pieces.")
                       : .wrong("\(one) is less than \(X) \(p.small). Cut bigger pieces.")
    }

    /// What the hops say (`h`: how many big units hopped): right at the whole big units that fit; too many go past the
    /// end, too few leave room for another, each measured in small units.
    static func hopVerdict(_ h: Double?, _ p: Problem) -> Verdict {
        guard let h, h > 0 else { return .soft("Hop the ruler along the bar first.") }
        let k = Int(h.rounded())
        if k == p.whole { return .right }
        let K = "\(k) \(k == 1 ? p.one : p.many)", N = fmt(p.n), T = fmt(Double(k) * p.f)
        return k > p.whole ? .wrong("\(K) is \(T) \(p.small), more than \(N). Hop back.")
                           : .wrong("\(K) is only \(T) \(p.small). Another \(p.one) fits in \(N).")
    }

    public static let spec = LessonSpec(id: "g5-units", title: "Converting units", master: "tape", generate: { rng, index in draw(&rng, index) },
    display: { x in let p = Problem(x); return p.givenMath + [.op("="), .text("? \(p.target)")] },
    idea: { _ in "A big unit holds many small ones, so the same amount takes more small units." },
    story: { x in
        let p = Problem(x)
        if ["kilogram", "pound"].contains(p.one) { return "A bag of flour weighs \(p.given). How many \(p.target) is that?" }
        if p.one == "hour" { return "A road trip takes \(p.given). How many \(p.target) is that?" }
        if p.one == "gallon" { return "A fish tank holds \(p.given) of water. How many \(p.target) is that?" }
        return "A rope is \(p.given) long. How many \(p.target) long is it?"
    },
    storyOp: { n in (n["up"] ?? 0) == 1 ? "÷" : "×" },
    depends: ["g4-convert", "g4-partial"],
    check: [CheckItem(1, when: { $0["up"] == 0 }), CheckItem(4, when: { $0["up"] == 1 }), CheckItem(5, when: { $0["up"] == 1 }),
            CheckItem(7, when: { x in x["up"] == 1 && fmod(x["n"] ?? 0, Problem(x).f) != 0 })]) { x in
        let p = Problem(x), f = p.f, n = p.n, N = fmt(n), F = fmt(f), ans = p.answer
        if p.up {
            // small to big: hop a one-big-unit ruler along the small units, as far as whole big units go
            let ask = LessonStep(StepWords(say: "How many \(p.many) fit along the bar?", hint: "Look at one \(p.one) first.", action: "Let’s find out"))
            let K = "\(p.whole) \(p.many)", rest = p.left > 0 ? ", and \(fmt(p.left)) \(p.small) are left: half \(an(p.one)) \(p.one)" : ""
            let hop = LessonStep(
                StepWords(say: "Hop the ruler along the bar, one \(p.one) at a time, as far as it goes.",
                          hint: "Every \(F) \(p.small) make one \(p.one), so divide.", action: "Check"),
                answer: AnswerTask(prompt: [.box("h"), .text(p.B)], expected: ["h": Double(p.whole)],
                                   hint: "1 \(p.one) is \(F) \(p.small). How many \(F)s fit in \(N)?",
                                   explain: "\(K) fit\(rest).", check: { v in hopVerdict(v["h"], p) }, byHand: true),
                picture: ["hops": 1])
            let write = LessonStep(
                StepWords(say: "How many \(p.many) is that? Write it.", hint: "Every \(F) \(p.small) make one \(p.one), so divide.", action: "Check"),
                answer: AnswerTask(prompt: [.num(n), .text(p.S), .op("="), .num(n), .op("÷"), .num(f), .op("="), .box("x"), .text(p.B)], expected: ["x": ans],
                                   known: [(["x": n * f], "\(cap(p.many)) are bigger, so there are fewer of them: divide."),
                                           (["x": n - f], "Take away \(F) again and again, or divide: \(N) ÷ \(F).")],
                                   hint: "Every \(F) \(p.small) make one \(p.one). How many \(F)s fit in \(N)?",
                                   explain: "\(N) ÷ \(F) = \(fmt(ans)) \(p.many)."),
                picture: ["hopped": 1], onMiss: ["last": 1])
            let done = LessonStep(StepWords(say: "\(F) \(p.small) make every \(p.one), so there are fewer \(p.many).",
                                            hint: "A big unit holds many small ones, so the same amount takes fewer big units.",
                                            action: "Next problem"),
                                  picture: ["hopped": 1, "done": 1])
            return [ask, hop, write, done]
        }
        // big to small: cut one big unit into its small units with the ruler, then every one the same way
        let tens = p.piece > 1
        let ask = LessonStep(StepWords(say: "How many \(p.small) fit in one \(p.one)?", hint: "Look at one \(p.one) first.", action: "Let’s find out"))
        let cut = LessonStep(
            StepWords(say: tens ? "Drag the ruler to cut one \(p.one) into pieces of \(fmt(p.piece)) \(p.small), then cut."
                                : "Drag the ruler to cut one \(p.one) into \(p.small), then cut.",
                      hint: "Start with just one \(p.one).", action: "Cut"),
            answer: AnswerTask(prompt: [.num(1), .text(p.B), .op("="), .box("x"), .text(p.S)], expected: ["x": f], known: unitSlips(f, mixUps[p.one] ?? []),
                               hint: "Think of one \(p.one). How many \(p.small) fit in it?", explain: "1 \(p.one) is \(F) \(p.small).",
                               check: { v in cutVerdict(v["x"], p) }, byHand: true),
            picture: ["ruler": 1])
        let write = LessonStep(
            StepWords(say: "How many \(p.small) in all? Write it.", hint: "Every \(p.one) is another \(F) \(p.small), so multiply.", action: "Check"),
            answer: AnswerTask(prompt: [.num(n), .text(p.B), .op("="), .num(n), .op("×"), .num(f), .op("="), .box("x"), .text(p.S)], expected: ["x": ans],
                               known: [(["x": n + f], "Each \(p.one) is \(F) \(p.small), so multiply."),
                                       (["x": n / f], "\(cap(p.small)) are smaller, so there are more of them: multiply.")],
                               hint: "Every \(p.one) is \(F) \(p.small), and there are \(N) of them.",
                               explain: "\(N) × \(F) = \(fmt(ans)) \(p.small)."),
            picture: ["cut": 1], onMiss: ["last": 1])
        let done = LessonStep(StepWords(say: "\(F) \(p.small) in every \(p.one), so there are more \(p.small).",
                                        hint: "A big unit holds many small ones, so the same amount takes more small units.",
                                        action: "Next problem"),
                              picture: ["cut": 1, "done": 1])
        return [ask, cut, write, done]
    }
}
