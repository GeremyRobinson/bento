import Foundation

/// Converting units (the web app's g5-units): n big units = ? small units (multiply), or with `up`,
/// n small units = ? big units (divide). Big units may be a half (3.5 kilograms), and small-to-big answers may come out
/// a half (250 centimeters = 2.5 meters).
/// Numbers: u (which unit pair, an index into `units`), n (the amount the problem starts from, in big units, or in small
/// units when up), up (0 = big to small, 1 = small to big).
///
/// Picture keys (master "tape", the web's tape diagram: a bar of big units, stacked in two rows when there are 4 or more):
/// - "units": how many big units the bar holds (n, or n ÷ per when up; the last unit is part full for a half).
/// - "per": how many small units are in one big unit.
/// - "rows": 1, or 2 when the bar has 4 or more units (the first row holds the first half, rounded up).
/// - "fill": how many big units are shown cut into small units: 0, then 1 (the first), then all of them.
/// - "one": 1 = the first unit reads `per`, with the bracket "1 foot = 12 inches" under it.
/// - "ask": 1 = every unit after the first shows "?", one after another (still to be turned into small units).
/// - "total": 1 = every unit reads its small units, with the bracket "3 × 12 = 36 inches" (or "250 ÷ 100 = 2.5 meters").
/// Every step shows the bracket over the bar with the amount the problem starts from ("3 feet" or "250 centimeters"),
/// and before "fill" each unit reads "1".
public enum ConvertUnits {
    /// [one big unit, many big units, small units, small units in one big unit], as the web's UNITS.
    public static let units: [(one: String, many: String, small: String, per: Double)] = [
        ("foot", "feet", "inches", 12), ("yard", "yards", "feet", 3), ("meter", "meters", "centimeters", 100), ("kilogram", "kilograms", "grams", 1000),
        ("hour", "hours", "minutes", 60), ("gallon", "gallons", "quarts", 4), ("pound", "pounds", "ounces", 16),
    ]

    /// The choices of the "More or fewer?" step; its box "c" holds the index of the one picked.
    public static let choices = ["More", "Fewer"]

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
    depends: ["g4-convert", "g4-partial"],
    check: [CheckItem(1, when: { $0["up"] == 0 }), CheckItem(4, when: { $0["up"] == 1 }), CheckItem(5, when: { $0["up"] == 1 }),
            CheckItem(7, when: { x in x["up"] == 1 && fmod(x["n"] ?? 0, Problem(x).f) != 0 })]) { x in
        let p = Problem(x), f = p.f, n = p.n, N = fmt(n), F = fmt(f), ans = p.answer
        let W = p.big, P = W.rounded(.up)
        let bar: Numbers = ["units": W, "per": f, "rows": P >= 4 ? 2 : 1]
        let ask = LessonStep(StepWords(say: "How many \(p.target) is \(p.given)?", hint: "Look at one \(p.one) first.", action: "Let’s find out"),
                             picture: bar.merging(["fill": 0]) { $1 })
        // hints are the spec's narration (specs/k12/grade5.md §3)
        let one = LessonStep(StepWords(say: "1 \(p.one) = how many \(p.small)?", hint: "Start with just one \(p.one).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": f], known: unitSlips(f, mixUps[p.one] ?? []),
                               hint: "Think of one \(p.one). How many \(p.small) fit in it?", explain: "1 \(p.one) is \(F) \(p.small)."),
            picture: bar.merging(["fill": 1, "one": 1]) { $1 })
        // a pick-one step, as on the web: the child taps More or Fewer; box "c" holds the index of the choice
        let s1 = smallOne[p.small] ?? p.small
        let more = LessonStep(StepWords(say: "Will the answer be more or fewer \(p.target) than \(N)?",
                                        hint: p.up ? "\(cap(p.many)) are bigger, so there will be fewer of them than \(N)."
                                                   : "\(cap(p.small)) are smaller, so there will be more of them than \(N).",
                                        action: "Check"),
            answer: AnswerTask(prompt: p.givenMath + [.op("→")], expected: ["c": p.up ? 1 : 0],
                               known: p.up ? [(["c": 0], "\(cap(p.many)) are bigger than \(p.small), so you need fewer of them.")]
                                           : [(["c": 1], "\(cap(p.small)) are smaller than \(p.many), so you need more of them.")],
                               hint: "Which is bigger, \(an(p.one)) \(p.one) or \(an(s1)) \(s1)?",
                               explain: p.up ? "\(cap(p.many)) are bigger, so it takes fewer of them." : "\(cap(p.small)) are smaller, so it takes more of them.",
                               choices: choices.map { "\($0) \(p.target)" }),
            picture: bar.merging(["fill": 1, "ask": 1]) { $1 })
        let work = p.up
            ? LessonStep(StepWords(say: "Divide", hint: "Every \(F) \(p.small) make one \(p.one), so divide.", action: "Check"),
                answer: AnswerTask(prompt: [.num(n), .op("÷"), .num(f), .op("="), .box("x")], expected: ["x": ans],
                                   known: [(["x": n * f], "\(cap(p.many)) are bigger, so there are fewer of them: divide."),
                                           (["x": n - f], "Take away \(F) again and again, or divide: \(N) ÷ \(F).")],
                                   hint: "Every \(F) \(p.small) make one \(p.one). How many \(F)s fit in \(N)?",
                                   explain: "\(N) ÷ \(F) = \(fmt(ans)) \(p.many)."),
                picture: bar.merging(["fill": W, "total": 1]) { $1 })
            : LessonStep(StepWords(say: "Multiply", hint: "Every \(p.one) is another \(F) \(p.small), so multiply.", action: "Check"),
                answer: AnswerTask(prompt: [.num(n), .op("×"), .num(f), .op("="), .box("x")], expected: ["x": ans],
                                   known: [(["x": n + f], "Each \(p.one) is \(F) \(p.small), so multiply."),
                                           (["x": n / f], "\(cap(p.small)) are smaller, so there are more of them: multiply.")],
                                   hint: "Every \(p.one) is \(F) \(p.small), and there are \(N) of them.",
                                   explain: "\(N) × \(F) = \(fmt(ans)) \(p.small)."),
                picture: bar.merging(["fill": W, "total": 1]) { $1 })
        let done = LessonStep(StepWords(say: "\(p.given) = \(fmt(ans)) \(p.target).",
                                        hint: "A big unit holds many small ones, so the same amount takes more small units.",
                                        action: "Next problem"),
                              picture: bar.merging(["fill": W, "total": 1]) { $1 })
        return [ask, one, more, work, done]
    }
}
