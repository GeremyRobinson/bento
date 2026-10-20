import Foundation

/// Adding and subtracting fractions with different bottoms (the web app's 5th grade "add", "sub" and "mix", shared
/// code in web/src/curriculum/lessons/_tape-family/unlike.ts): a/b ± c/d. Find the least common denominator L,
/// rewrite both fractions over L, add or take away the tops, then simplify.
///
/// Numbers: a, b, c, d (the problem a/b ± c/d); minus (1 for −, 0 for +); and, worked out from them, L (the LCD),
/// A = a·L/b and C = c·L/d (the tops over L) and S = A ± C (the answer's top over L).
///
/// On the paper (design/grade5.md, the test page G approved): two bars a whole long (`wholeLength`, so every piece is
/// a whole number of squares), a/b shaded, c/d striped, named by their fractions at their right ends. The child drags
/// the ruler and cuts both bars into the same pieces (that answers the new bottom and both rewrites: their boxes are
/// set from the cut), slides the striped pieces into the top bar (adding: after the shaded ones; taking away: over
/// them from the right), then writes the record a/b ± c/d = A/L ± C/L = S/L, and simplifies when it can be simpler.
///
/// Picture keys, by step (cumulative): "ruler" (the cut: the ruler's handle above the first bar); "cut" (both bars cut
/// into L pieces, numbered, named A/L and C/L); "slide" (the striped pieces wait to be slid); "slid" (they're in the
/// top bar: after the shaded pieces, spilling into a second whole bar under it past the end; or over the shaded ones,
/// crossing them out); "sum" (the record's S/L written); "answer" (the simplest form written, the answer bars cut into
/// the simplest pieces). A hint (after a miss, or asked for) lights: "oldCuts" (every old cut's dot ringed: each needs
/// a new cut on it), "target" (where the striped pieces go, dashed in the top bar), "last" (the last piece counted,
/// ringed) and "simple" (the simplest pieces' cuts, dashed over the answer).
public enum UnlikeFractions {
    /// A whole bar's length in squares for a problem whose new bottom is L (G 20 Oct, design/grade5.md): 48, as on the
    /// test page G approved, whenever every bottom divides it (halves to twelfths, 16ths, 24ths); else the first of 40
    /// (fifths, tenths, 20ths), 42 (sevenths, 14ths, 21sts), 45 (ninths, 15ths), 44 (elevenths, 22nds) and 36 (18ths)
    /// that L divides (so its factors do too). Every piece is a whole number of squares, 2 at least.
    public static func wholeLength(_ L: Int) -> Int { [48, 40, 42, 45, 44, 36].first { $0 % max(1, L) == 0 } ?? max(2, L) * 2 }

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

    /// The steps on the paper (G 20 Oct, design/grade5.md): the cut (it answers the web's lcd step, and the two
    /// rewrites after it, whose boxes are set from the cut), the slide, then the web's add/subtract and simplify steps
    /// written in the record, between an opening question and the answer. A rewrite that changes nothing and a simplify
    /// with nothing to do are left out, and the answer's bottom is given.
    static func steps(_ lesson: Lesson, _ n: Numbers) -> [LessonStep] {
        let a = Int(n["a"] ?? 1), b = Int(n["b"] ?? 2), c = Int(n["c"] ?? 1), d = Int(n["d"] ?? 2)
        let L = Int(n["L"] ?? 1), A = Int(n["A"] ?? 0), C = Int(n["C"] ?? 0), S = Int(n["S"] ?? 0)
        let sub = (n["minus"] ?? 0) == 1, sign = sub ? "−" : "+"
        let big = max(b, d), small = min(b, d), piece = pieceName(L)

        // the problem is written once, as the bars' own names (G 20 Oct): the first step points at the bars
        let ask = LessonStep(StepWords(say: "Look at the bars. Are the pieces the same size?", hint: ideas[lesson]!, action: "Let’s find out"))

        // the cut: the ruler sets one piece's size, and Cut cuts both bars into it. Its box is how many of those pieces
        // make a whole: the new bottom. What a cut that doesn't fit says is measured on the bars (the test page).
        let lcd = LessonStep(
            StepWords(say: "Drag the ruler to cut both bars into the same size pieces.",
                      hint: "Every old cut needs a new cut on it.", action: "Cut"),
            answer: AnswerTask(
                prompt: [.text("LCD of"), .num(Double(b)), .text("and"), .num(Double(d)), .text("is"), .box("x")],
                expected: ["x": Double(L)],
                hint: "Every old cut needs a new cut on it. Then try bigger pieces.",
                explain: "Counting by \(big)s, the first number \(small) also goes into is \(L): \(pieceName(L)) fit both bars.",
                check: { v in
                    guard let x = v["x"], x > 0 else { return .soft("Drag the ruler first.") }
                    if same(x, L) { return .right }
                    if divides(b, x) && divides(d, x) { return .wrong("Those fit both bars. Bigger pieces fit too.") }
                    return .wrong("Some old cuts have no new cut on them.")
                }, byHand: true),
            picture: ["ruler": 1], onMiss: ["oldCuts": 1])

        // the rewrites: the cut answers them (A and C are the shaded pieces counted once the bars are cut); a fraction
        // already over L is written for the child
        func rewrite(_ top: Int, _ den: Int, _ N: Int) -> LessonStep {
            let k = L / den
            return LessonStep(
                StepWords(say: "How many \(pieceName(L)) is \(top == 1 ? "one" : "\(top)") \(pieceName(den, top != 1))?",
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
                    }, byHand: true),
                picture: ["cut": 1])
        }

        // the slide: the striped pieces into the top bar, after the shaded ones (adding) or over them from the right
        // (taking away). Its box is 1 once they're dropped in the top bar.
        let slideSay: String
        switch (lesson, sub) {
        case (.mix, false): slideSay = "Slide the striped \(piece) in to add."
        case (.mix, true): slideSay = "Slide the striped \(piece) over to take away."
        case (_, false): slideSay = "Slide the striped \(piece) into the top bar."
        case (_, true): slideSay = "Slide the striped \(piece) over the shaded ones."
        }
        let slide = LessonStep(
            StepWords(say: slideSay, hint: sub ? "Drag the striped pieces up onto the shaded pieces." : "Drag the striped pieces up into the top bar.", action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1],
                               hint: sub ? "Same-size pieces, so they can be taken away." : "Same-size pieces, so they can go together.",
                               explain: sub ? "The striped \(piece) cover \(C) of the shaded ones: \(S) are left." : "The striped \(piece) go after the shaded ones: \(S) in all.",
                               check: { v in same(v["s"], 1) ? .right : .soft("Put them in the top bar.") }, byHand: true),
            picture: ["cut": 1, "slide": 1], onMiss: ["target": 1])

        // the record: a/b ± c/d = A/L ± C/L = [S]/L, the answer's bottom written for the child (G 20 Oct)
        let count = sub ? "Count the shaded \(piece) that aren’t crossed out." : S > L ? "Count the \(piece) in both bars." : "Count the \(piece) in the top bar."
        var slips: [(values: [String: Double], message: String)] = []
        if !sub, a + c != S { slips.append((["n": Double(a + c)], "That adds the old tops. \(count)")) }
        let combine = LessonStep(
            StepWords(say: sub ? "How many \(piece) are left? Write it." : "How many \(piece) in all? Write it.", hint: count, action: "Check"),
            answer: AnswerTask(
                prompt: [.frac(.num(Double(A)), .num(Double(L))), .op(sign), .frac(.num(Double(C)), .num(Double(L))), .op("="), .frac(.box("n"), .num(Double(L)))],
                expected: ["n": Double(S)], known: slips,
                hint: "The pieces are the same size now, so only the tops \(sub ? "get taken away" : "add"). Does the size of a piece change?",
                explain: "\(A) \(sign) \(C) = \(S), and the bottom stays \(L).",
                check: { v in
                    guard let top = v["n"] else { return .soft("Fill in the top.") }
                    if same(top, S) { return .right }
                    if sub && same(top, A + C) { return .wrong("You added \(A) + \(C). Look at the sign: this one is a minus.") }
                    if !sub && same(top, abs(A - C)) { return .wrong("You subtracted. Look at the sign: this one is a plus.") }
                    return .wrong("Check the top: \(A) \(sign) \(C) = ?")
                }),
            picture: ["cut": 1, "slid": 1], onMiss: ["last": 1])

        let simplify = LessonStep(
            StepWords(say: "Write it as simply as you can.", hint: simplifyNarration(S, L), action: "Check"),
            answer: simplifyTask(S, L),
            picture: ["cut": 1, "slid": 1, "sum": 1], onMiss: ["simple": 1])

        let F = finalForm(S, L), changes = !(F.whole == 0 && F.den == L)
        // the answer is in the record, in the chapter's colour; the last words say why it works, not the sum again
        let done = LessonStep(StepWords(say: sub ? "Same-size pieces, so the tops are taken away." : "Same-size pieces, so the tops add.", hint: ideas[lesson]!, action: "Next problem"),
                              picture: ["cut": 1, "slid": 1, "sum": 1, "answer": changes ? 1 : 0])
        // a simplify with nothing to do is left out (G 20 Oct): only the steps that change something are asked
        return [ask, lcd] + (b == L ? [] : [rewrite(a, b, A)]) + (d == L ? [] : [rewrite(c, d, C)])
            + [slide, combine] + (changes ? [simplify] : []) + [done]
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
