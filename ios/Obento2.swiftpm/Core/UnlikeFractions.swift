import Foundation

/// Adding and subtracting fractions with different bottoms (the web app's 5th grade "add", "sub" and "mix", shared
/// code in web/src/curriculum/lessons/_tape-family/unlike.ts): a/b ± c/d. Find the least common denominator L,
/// rewrite both fractions over L, add or take away the tops, then simplify.
///
/// Numbers: a, b, c, d (the problem a/b ± c/d); minus (1 for −, 0 for +); and, worked out from them, L (the LCD),
/// A = a·L/b and C = c·L/d (the tops over L) and S = A ± C (the answer's top over L).
///
/// Picture (master "tape", the web's fraction bars, web/src/explanations/diagrams/tape): two bars one whole long,
/// a/b shaded blue ("on") in b parts, c/d shaded orange ("two") in d parts, each labelled with its fraction. Keys,
/// all 0 or 1 unless said otherwise, and cumulative (once on, they stay on):
/// - cut: both bars are cut into L pieces (web beat 1: the knife draws the new cuts, then the pieces come apart; a bar
///   already in L pieces has the knife run down the cuts it has).
/// - first: the first bar's shaded pieces are counted 1...A and its label becomes A/L (web beat 2).
/// - second: the second bar's shaded pieces are counted 1...C and its label becomes C/L (web beat 3).
/// - combine: the answer bar(s) appear (web beat 4). Adding: bars of L pieces, A shaded "on" then C more shaded
///   "two", counted 1...S, one bar per whole the total needs. Taking away: one bar of L pieces with the first S
///   shaded "on" and the next C (up to A) struck out ("cut"), the S left counted. Labelled S/L in amber.
/// - answer: "= <S/L in lowest terms or as a mixed number>" is written beside the answer, when that differs from S/L
///   (web beat 5).
/// - focus: the rows this step asks about, lit while the rest stay quiet: 1 the first bar, 2 the second bar,
///   3 both bars, 4 the answer bar(s). Absent: nothing is singled out.
public enum UnlikeFractions {
    /// a/b ± c/d with every derived value, as the web's createUnlikeFractions.
    public static func numbers(a: Int, b: Int, c: Int, d: Int, minus: Bool) -> Numbers {
        let L = lcm(b, d), A = a * (L / b), C = c * (L / d)
        return ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d), "minus": minus ? 1 : 0,
                "L": Double(L), "A": Double(A), "C": Double(C), "S": Double(minus ? A - C : A + C)]
    }

    /// The web's generateUnlikeFractions: bottoms 2–12, different, LCD ≤ 24; the first problem is the easy kind
    /// (one bottom divides the other); from the third on, that kind is mostly skipped; a take-away stays positive.
    public static func generate(_ rng: inout SeededRandom, _ i: Int, minus: Bool) -> Numbers {
        var b = 2, d = 2
        while true {
            b = Int.random(in: 2...12, using: &rng); d = Int.random(in: 2...12, using: &rng)
            if b == d || lcm(b, d) > 24 { continue }
            let multiple = b % d == 0 || d % b == 0
            if i == 0 && !multiple { continue }
            if i >= 2 && multiple && Double.random(in: 0..<1, using: &rng) < 0.6 { continue }
            break
        }
        func top(_ den: Int) -> Int { var n: Int; repeat { n = Int.random(in: 1...(den - 1), using: &rng) } while gcd(n, den) != 1; return n }
        var a = top(b), c = top(d)
        let L = lcm(b, d), A = a * (L / b), C = c * (L / d)
        if minus {
            if A == C { return generate(&rng, i, minus: minus) }
            if A < C { (a, b, c, d) = (c, d, a, b) } // keep the answer positive
        }
        return numbers(a: a, b: b, c: c, d: d, minus: minus)
    }

    /// S/L in lowest terms: whole part, top and bottom (the web's finalForm).
    public static func finalForm(_ S: Int, _ L: Int) -> (whole: Int, num: Int, den: Int) {
        let g = gcd(S, L), n = S / g, d = L / g
        return (n / d, n % d, d)
    }

    /// The same as a label: "1 3/22", "5", "3/4" (the web's mixedLabel).
    public static func mixedLabel(_ S: Int, _ L: Int) -> String {
        let F = finalForm(S, L)
        if F.num == 0 { return "\(F.whole)" }
        return (F.whole > 0 ? "\(F.whole) " : "") + "\(F.num)/\(F.den)"
    }

    /// The answer in lowest terms, as the paper writes it: a whole number, a fraction, or both.
    static func mixedMath(_ S: Int, _ L: Int) -> MathLine {
        let F = finalForm(S, L)
        if F.num == 0 { return [.num(Double(F.whole))] }
        return (F.whole > 0 ? [.num(Double(F.whole))] : []) + [.frac(.num(Double(F.num)), .num(Double(F.den)))]
    }

    /// Name of a piece size: halves, thirds, ..., twentieths, 22nds (the web's pieceName).
    static func pieceName(_ d: Int, _ plural: Bool = true) -> String {
        let names: [Int: (String, String)] = [
            2: ("half", "halves"), 3: ("third", "thirds"), 4: ("fourth", "fourths"), 5: ("fifth", "fifths"), 6: ("sixth", "sixths"),
            7: ("seventh", "sevenths"), 8: ("eighth", "eighths"), 9: ("ninth", "ninths"), 10: ("tenth", "tenths"),
            11: ("eleventh", "elevenths"), 12: ("twelfth", "twelfths"), 13: ("thirteenth", "thirteenths"), 14: ("fourteenth", "fourteenths"),
            15: ("fifteenth", "fifteenths"), 16: ("sixteenth", "sixteenths"), 17: ("seventeenth", "seventeenths"),
            18: ("eighteenth", "eighteenths"), 19: ("nineteenth", "nineteenths"), 20: ("twentieth", "twentieths"), 100: ("hundredth", "hundredths"),
        ]
        if let n = names[d] { return plural ? n.1 : n.0 }
        let last = d % 10, teen = (11...13).contains(d % 100)
        let suffix = teen ? "th" : last == 1 ? "st" : last == 2 ? "nd" : last == 3 ? "rd" : "th"
        return "\(d)\(suffix)\(plural ? "s" : "")"
    }

    static func lcm(_ a: Int, _ b: Int) -> Int { a * b / gcd(a, b) }

    /// The web's gcd on whatever the child typed (decimals too), so the checks behave the same on any number.
    static func gcdTyped(_ a: Double, _ b: Double) -> Double {
        var a = a, b = b, guardrail = 0
        while b != 0 && guardrail < 200 { (a, b) = (b, fmod(a, b)); guardrail += 1 }
        return a
    }
    static func divides(_ by: Int, _ x: Double) -> Bool { fmod(x, Double(by)) == 0 }
    static func same(_ x: Double?, _ y: Int) -> Bool { x.map { abs($0 - Double(y)) < 1e-9 } ?? false }

    public enum Lesson: String, Sendable { case add, sub, mix }

    static let ideas: [Lesson: String] = [
        .add: "The bottom is the size of the pieces, and only same-size pieces can be added.",
        .sub: "Only same-size pieces can be taken away, so the bottoms have to match first.",
        .mix: "Adding and taking away both need same-size pieces, so the first steps never change.",
    ]

    static func story(_ lesson: Lesson, _ n: Numbers) -> String {
        let a = Int(n["a"] ?? 1), b = Int(n["b"] ?? 2), c = Int(n["c"] ?? 1), d = Int(n["d"] ?? 2), minus = (n["minus"] ?? 0) == 1
        switch lesson {
        case .add: return "You walked \(a)/\(b) of a mile to the park and then \(c)/\(d) of a mile to the store. How far did you walk in all?"
        case .sub: return "There was \(a)/\(b) of a cake left. The family ate \(c)/\(d) of a cake. How much cake is left now?"
        case .mix: return minus ? "A jug had \(a)/\(b) gallon of water. You poured out \(c)/\(d) gallon. How much is left?"
            : "A plant grew \(a)/\(b) inch in May and \(c)/\(d) inch in June. How much did it grow in all?"
        }
    }

    /// The answer's top over L can be divided down (the check recipes' `simplifies`).
    static func simplifies(_ n: Numbers) -> Bool {
        let S = Int(n["S"] ?? 0), L = Int(n["L"] ?? 1)
        return S > 0 && gcd(S, L) > 1
    }

    static func makeSpec(_ lesson: Lesson, id: String, title: String, depends: [String], check: [CheckItem],
                         sign: @escaping @Sendable (Int) -> Bool) -> LessonSpec {
        LessonSpec(id: id, title: title, master: "tape",
                   generate: { rng, i in generate(&rng, i, minus: sign(i)) },
                   display: { n in [.frac(.num(n["a"] ?? 1), .num(n["b"] ?? 2)), .op((n["minus"] ?? 0) == 1 ? "−" : "+"), .frac(.num(n["c"] ?? 1), .num(n["d"] ?? 2))] },
                   idea: { _ in ideas[lesson]! },
                   story: { n in story(lesson, n) },
                   storyOp: { n in (n["minus"] ?? 0) == 1 ? "−" : "+" },
                   depends: depends, check: check) { n in steps(lesson, n) }
    }

    /// The web's five steps (lcd, first, second, add/subtract, simplify), with their checks and messages,
    /// between an opening question and the answer.
    static func steps(_ lesson: Lesson, _ n: Numbers) -> [LessonStep] {
        let a = Int(n["a"] ?? 1), b = Int(n["b"] ?? 2), c = Int(n["c"] ?? 1), d = Int(n["d"] ?? 2)
        let L = Int(n["L"] ?? 1), A = Int(n["A"] ?? 0), C = Int(n["C"] ?? 0), S = Int(n["S"] ?? 0)
        let sub = (n["minus"] ?? 0) == 1, sign = sub ? "−" : "+"
        let big = max(b, d), small = min(b, d)
        let problem = "\(a)/\(b) \(sign) \(c)/\(d)"

        let ask = LessonStep(StepWords(say: "What is \(problem)?", hint: "Look at the two bars. Are the pieces the same size?", action: "Let’s find out"))

        // lcd: the web's question, its check() and messages; the narration (specs/k12/grade5.md §3) as the step's hint
        let lcd = LessonStep(
            StepWords(say: "Smallest number that both \(b) and \(d) go into:",
                      hint: "Both \(b) and \(d) go into \(L), so cut both bars into \(pieceName(L)).", action: "Check"),
            answer: AnswerTask(
                prompt: [.text("LCD of"), .num(Double(b)), .text("and"), .num(Double(d)), .text("is"), .box("x")],
                expected: ["x": Double(L)],
                hint: "Count by the bigger bottom number, and stop at the first number the smaller one also goes into.",
                explain: "Counting by \(big)s, the first number \(small) also goes into is \(L).",
                check: { v in
                    guard let x = v["x"] else { return .wrong("Type a number first.") }
                    if same(x, L) { return .right }
                    if same(x, b + d) {
                        return .wrong("You added \(b) + \(d). The bottom number is the size of the pieces, so it doesn’t get added. Find a number that \(b) and \(d) both go into evenly.")
                    }
                    if sub && same(x, abs(b - d)) {
                        return .wrong("You subtracted \(big) − \(small). The bottom number is the size of the pieces, so it doesn’t get subtracted. Find a number that \(b) and \(d) both go into evenly.")
                    }
                    if x > 0 && divides(b, x) && divides(d, x) {
                        return .wrong("\(fmt(x)) works, since \(b) and \(d) both go into it. Find a smaller one. It keeps the numbers easier.")
                    }
                    if !(x > 0) { return .wrong("Type a number first.") }
                    let bad = divides(b, x) ? d : b
                    return .wrong("\(bad) doesn’t go into \(fmt(x)) evenly (\(fmt(x)) ÷ \(bad) has a remainder). Both bottom numbers must divide into it.")
                }),
            picture: ["focus": 3])

        func rewrite(_ top: Int, _ den: Int, _ N: Int, first: Bool) -> LessonStep {
            let k = L / den
            return LessonStep(
                StepWords(say: "Rewrite \(first ? "the first" : "the second") fraction",
                          hint: "Each \(pieceName(den, false)) is \(k) \(pieceName(L, k != 1)).", action: "Check"),
                answer: AnswerTask(
                    prompt: [.frac(.num(Double(top)), .num(Double(den))), .op("="), .frac(.box("x"), .num(Double(L)))],
                    expected: ["x": Double(N)],
                    hint: "\(den) × ? = \(L). Whatever you multiply the bottom by, do the same to the top.",
                    explain: "\(den) × \(k) = \(L), so \(top) × \(k) = \(N).",
                    check: { v in
                        let x = v["x"]
                        if same(x, N) { return .right }
                        if same(x, top) {
                            return .wrong("You changed the bottom from \(den) to \(L), but kept the top as \(top). Whatever you multiply the bottom by, multiply the top by the same number.")
                        }
                        if same(x, top + (L - den)) {
                            return .wrong("You added \(L - den) to the top because the bottom went up by \(L - den). A fraction stays the same only when you multiply top and bottom by the same number. What times \(den) makes \(L)?")
                        }
                        return .wrong("\(den) × ? = \(L). Then multiply the top, \(top), by that number.")
                    }),
                picture: first ? ["cut": 1, "focus": 1] : ["cut": 1, "first": 1, "focus": 2])
        }

        let combine = LessonStep(
            StepWords(say: sub ? "Subtract" : "Add",
                      hint: sub ? "Same-size pieces now, so take away. The bottom stays \(L)." : "Same-size pieces now, so add the tops. The bottom stays \(L).",
                      action: "Check"),
            answer: AnswerTask(
                prompt: [.frac(.num(Double(A)), .num(Double(L))), .op(sign), .frac(.num(Double(C)), .num(Double(L))), .op("="), .frac(.box("n"), .box("d"))],
                expected: ["n": Double(S), "d": Double(L)],
                hint: "The pieces are the same size now, so only the tops \(sub ? "get taken away" : "add"). Does the size of a piece change?",
                explain: "\(A) \(sign) \(C) = \(S), and the bottom stays \(L).",
                check: { v in
                    guard let top = v["n"], let dd = v["d"] else { return .soft("Fill in both boxes, the top and the bottom.") }
                    if same(top, S) && same(dd, L) { return .right }
                    if !sub && same(dd, 2 * L) {
                        return .wrong("You added the bottoms too (\(L) + \(L)). The pieces are already the same size, \(L)ths, so the bottom stays \(L). Picture a pizza: \(A) slices plus \(C) slices is \(S) slices, still \(L)ths.")
                    }
                    if sub && same(dd, 0) {
                        return .wrong("You subtracted the bottoms too (\(L) − \(L) = 0). The pieces are already the same size, \(L)ths, so the bottom stays \(L). Picture a pizza: \(A) slices take away \(C) is \(S) slices, still \(L)ths.")
                    }
                    if !same(dd, L) {
                        return .wrong("When the bottoms match, the bottom stays the same: \(L). Only the tops get \(sub ? "subtracted" : "added").")
                    }
                    if sub && same(top, A + C) { return .wrong("You added \(A) + \(C). Look at the sign: this one is a minus.") }
                    if !sub && same(top, abs(A - C)) { return .wrong("You subtracted. Look at the sign: this one is a plus.") }
                    return .wrong("The bottom is right. Check the top: \(A) \(sign) \(C) = ?")
                }),
            picture: ["cut": 1, "first": 1, "second": 1, "focus": 3])

        let simplify = LessonStep(
            StepWords(say: "Simplify", hint: simplifyNarration(S, L), action: "Check"),
            answer: simplifyTask(S, L),
            picture: ["cut": 1, "first": 1, "second": 1, "combine": 1, "focus": 4])

        let F = finalForm(S, L), changes = !(F.whole == 0 && F.den == L)
        let done = LessonStep(StepWords(say: "\(problem) = \(mixedLabel(S, L)).", hint: ideas[lesson]!, action: "Next problem"),
                              picture: ["cut": 1, "first": 1, "second": 1, "combine": 1, "answer": changes ? 1 : 0])
        return [ask, lcd, rewrite(a, b, A, first: true), rewrite(c, d, C, first: false), combine, simplify, done]
    }

    /// The simplify narration (specs/k12/grade5.md §3).
    static func simplifyNarration(_ S: Int, _ L: Int) -> String {
        let g = gcd(S, L)
        return S >= L ? "Every \(L) pieces make one whole." : g > 1 ? "Divide the top and the bottom by \(g)." : "It’s already as simple as it gets."
    }

    /// The web's simplifyStep: S/L to lowest terms or a mixed number. The web shows a small whole-number box and a
    /// fraction, and leaves unused boxes empty; the engine needs every box filled, so only the boxes the answer uses
    /// are drawn (the whole number when there is one, the fraction when there's a part left).
    static func simplifyTask(_ S: Int, _ L: Int) -> AnswerTask {
        let F = finalForm(S, L), hasWhole = F.whole > 0, fracPart = F.num > 0, g = gcd(S, L)
        var prompt: MathLine = [.frac(.num(Double(S)), .num(Double(L))), .op("=")]
        var expected: [String: Double] = [:]
        if hasWhole { prompt.append(.box("w")); expected["w"] = Double(F.whole) }
        if fracPart { prompt.append(.frac(.box("n"), .box("d"))); expected["n"] = Double(F.num); expected["d"] = Double(F.den) }
        let hint = S % L == 0 ? "\(S) ÷ \(L) = \(S / L) exactly, so it’s a whole number."
            : S >= L ? "\(S) ÷ \(L) = \(S / L) remainder \(S % L). The remainder goes on top."
            : g > 1 ? "Both \(S) and \(L) can be divided by \(g)." : "No number (other than 1) divides both \(S) and \(L). It’s already simplest."
        let explain = S % L == 0 ? "\(S) ÷ \(L) = \(S / L) with nothing left over: a whole number."
            : S > L ? "\(S) ÷ \(L) = \(S / L) remainder \(S % L), then simplify."
            : g > 1 ? "Divide top and bottom by \(g)." : "It was already as simple as it gets."
        return AnswerTask(prompt: prompt, expected: expected, hint: hint, explain: explain, check: { v in
            // the web's `|| 0` and `|| 1`: an empty or zero box counts as none
            let w = v["w"].flatMap { $0 == 0 || $0.isNaN ? nil : $0 } ?? 0
            let top = v["n"].flatMap { $0 == 0 || $0.isNaN ? nil : $0 } ?? 0
            let dd = v["d"]
            if v["n"] != nil && dd == nil { return .soft("Fill in the bottom number too.") }
            if dd == 0 { return .soft("The bottom can’t be 0.") }
            let den = dd.flatMap { $0 == 0 || $0.isNaN ? nil : $0 } ?? 1
            if abs((w * den + top) * Double(L) - Double(S) * den) > 1e-9 {
                return .wrong(S > L
                    ? "That’s not equal to \(S)/\(L). How many whole \(L)s fit into \(S)? That’s the whole number. What’s left over goes on top."
                    : "That’s not equal to \(S)/\(L). Divide the top and the bottom by the same number.")
            }
            if let dd, dd != 0, top >= dd {
                return .soft("That’s the right amount. Now write it as a mixed number. How many whole \(fmt(dd))s fit into \(fmt(top))?")
            }
            if let dd, dd != 0, top > 0, gcdTyped(top, dd) > 1 {
                return .wrong("Same amount. \(fmt(top))/\(fmt(dd)) can still be simplified. Both \(fmt(top)) and \(fmt(dd)) divide by \(fmt(gcdTyped(top, dd))).")
            }
            return .right
        })
    }
}

/// Adding fractions (web "add"): a/b + c/d.
public enum AddingFractions {
    public static let spec = UnlikeFractions.makeSpec(
        .add, id: "add", title: "Adding fractions", depends: ["g4-equiv", "g4-likefrac", "g4-factors"],
        check: [CheckItem(1),
                CheckItem(3, when: { ($0["S"] ?? 0) > ($0["L"] ?? 0) }),
                CheckItem(3, when: { UnlikeFractions.simplifies($0) }),
                CheckItem(4, story: true)],
        sign: { _ in false })
}

/// Subtracting fractions (web "sub"): a/b − c/d, with the bigger fraction first.
public enum SubtractingFractions {
    public static let spec = UnlikeFractions.makeSpec(
        .sub, id: "sub", title: "Subtracting fractions", depends: ["add"],
        check: [CheckItem(1),
                CheckItem(3, when: { n in
                    let b = Int(n["b"] ?? 2), d = Int(n["d"] ?? 2)
                    return b % d != 0 && d % b != 0
                }),
                CheckItem(3, when: { UnlikeFractions.simplifies($0) }),
                CheckItem(4, story: true)],
        sign: { _ in true })
}

/// Adding and subtracting (web "mix"): plus on even problems, minus on odd ones.
public enum AddAndSubtract {
    public static let spec = UnlikeFractions.makeSpec(
        .mix, id: "mix", title: "Adding and subtracting", depends: ["add", "sub"],
        // the web asks these in order (inOrder), so the sign changes between items
        check: [CheckItem(2, when: { $0["minus"] == 0 }), CheckItem(3, when: { $0["minus"] == 1 }),
                CheckItem(4, when: { $0["minus"] == 0 }), CheckItem(5, when: { $0["minus"] == 1 })],
        sign: { $0 % 2 == 1 })
}
