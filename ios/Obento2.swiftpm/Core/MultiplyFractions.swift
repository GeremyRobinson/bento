import Foundation

/// Multiplying fractions (the web app's g5-multfrac): a/b × c/d, both proper and in lowest terms.
/// Multiply straight across (a×c over b×d), then simplify. The answer is always less than 1, so it is never whole.
/// Numbers: a, b, c, d (bottoms 2 to 9; 2 to 5 for the first three problems of a run).
///
/// Picture (master "frac-grid", the web's `buildFracGrid`): one square cut into b rows and d columns.
/// In practice everything is drawn from beat 0: a of the b rows shaded (labelled "a/b"), c of the d columns
/// shaded (labelled "c/d"), and their overlap, a×c squares, in one darker colour.
/// - beat 1: the rows lit, note "a of b rows".
/// - beat 2: the columns lit, note "c of d columns".
/// - beat 3: the overlap lit and counted square by square (1, 2, … a×c), note "a×c of b×d squares".
/// - beat 4: note "N/D = simplest" (or "N/D is already simplest").
/// Keys, as the web's practice screen places the picture (`pictureAt`):
/// - "at": the beat shown with its results (everything up to and including it).
/// - "ask": the beat being asked about now, lit without its answer (absent when nothing is asked).
public enum MultiplyFractions {
    public static func numbers(a: Int, b: Int, c: Int, d: Int) -> Numbers { ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)] }

    /// The web's gcd, on whatever the child types (decimals too), so its messages match.
    static func gcdOf(_ a: Double, _ b: Double) -> Double { b == 0 ? a : gcdOf(b, a.truncatingRemainder(dividingBy: b)) }

    /// S/L in lowest terms, as a whole part and a proper fraction (the web's finalForm).
    static func finalForm(_ S: Int, _ L: Int) -> (whole: Int, num: Int, den: Int) {
        let g = gcd(S, L), n = S / g, d = L / g
        return (n / d, n % d, d)
    }

    public static let spec = LessonSpec(id: "g5-multfrac", title: "Multiplying fractions", master: "frac-grid", generate: { rng, index in
        func top(_ den: Int) -> Int { var n: Int; repeat { n = Int.random(in: 1...(den - 1), using: &rng) } while gcd(n, den) != 1; return n }
        // the first three: halves to fifths
        let most = index < 3 ? 5 : 9
        let b = Int.random(in: 2...most, using: &rng), d = Int.random(in: 2...most, using: &rng)
        let a = top(b), c = top(d)
        return numbers(a: a, b: b, c: c, d: d)
    }, display: { p in [.frac(.num(p["a"] ?? 1), .num(p["b"] ?? 2)), .op("×"), .frac(.num(p["c"] ?? 1), .num(p["d"] ?? 2))] },
    idea: { _ in "Taking part of a part makes smaller pieces: half of a third is a sixth." },
    story: { p in
        "\(fmt(p["c"] ?? 1))/\(fmt(p["d"] ?? 2)) of a garden is vegetables. \(fmt(p["a"] ?? 1))/\(fmt(p["b"] ?? 2)) of the vegetable part is carrots. What part of the whole garden is carrots?"
    },
    storyOp: { _ in "×" },
    depends: ["g5-fracof", "g4-equiv"],
    check: [CheckItem(3, when: { p in gcd(Int((p["a"] ?? 1) * (p["c"] ?? 1)), Int((p["b"] ?? 2) * (p["d"] ?? 2))) > 1 }),
            CheckItem(3, when: { p in gcd(Int((p["a"] ?? 1) * (p["c"] ?? 1)), Int((p["b"] ?? 2) * (p["d"] ?? 2))) == 1 }),
            CheckItem(3), CheckItem(3, story: true)]) { p in
        let a = Int(p["a"] ?? 1), b = Int(p["b"] ?? 2), c = Int(p["c"] ?? 1), d = Int(p["d"] ?? 2)
        let N = a * c, D = b * d, F = finalForm(N, D), g = gcd(N, D)
        let A = "\(a)/\(b)", C = "\(c)/\(d)"
        let answer = F.num == 0 ? "\(F.whole)" : "\(F.whole > 0 ? "\(F.whole) " : "")\(F.num)/\(F.den)"
        // the spec's math fix for the cols beat: it reads "c/d of a/b", the problem's own order
        let ask = LessonStep(StepWords(say: "What is \(A) × \(C)?", hint: "That’s \(C) of \(A). Look at the grid.", action: "Let’s find out"),
                             picture: ["at": 0])

        let acrossHint = "Top times top counts the squares in the overlap. Bottom times bottom counts all the squares."
        let across = LessonStep(StepWords(say: "Multiply straight across.", hint: "The squares shaded twice are the answer.", action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(a)), .num(Double(b))), .op("×"), .frac(.num(Double(c)), .num(Double(d))), .op("="), .frac(.box("n"), .box("d"))],
                               expected: ["n": Double(N), "d": Double(D)],
                               known: [(["n": Double(a * d), "d": Double(b * c)], "Flipping is only for dividing. To multiply, go straight across."),
                                       (["n": Double(a + c), "d": Double(b + d)], "Multiply top × top and bottom × bottom.")],
                               hint: acrossHint,
                               explain: "\(a) × \(c) = \(N) on top and \(b) × \(d) = \(D) on the bottom: \(N)/\(D).",
                               // the web's ms: both boxes exactly, in place (no equivalent fraction yet; that's the next step)
                               check: { v in v["n"] == Double(N) && v["d"] == Double(D) ? .right : .wrong("Not quite. \(acrossHint)") }),
            picture: ["at": 0, "ask": 3])

        // the web's simplifyStep; N < D here, so the whole-number box (always left empty) isn't written
        let simpHint = N % D == 0 ? "\(N) ÷ \(D) = \(N / D) exactly, so it’s a whole number."
            : N >= D ? "\(N) ÷ \(D) = \(N / D) remainder \(N % D). The remainder goes on top."
            : g > 1 ? "Both \(N) and \(D) can be divided by \(g)." : "No number (other than 1) divides both \(N) and \(D). It’s already simplest."
        let simpExplain = N >= D ? "\(N) ÷ \(D) = \(N / D) remainder \(N % D), then simplify." : g > 1 ? "Divide top and bottom by \(g)." : "It was already as simple as it gets."
        let simplify = LessonStep(StepWords(say: "Simplify.", hint: g > 1 ? "Divide the top and the bottom by \(g)." : "It can’t be made simpler.", action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(N)), .num(Double(D))), .op("="), .frac(.box("n"), .box("d"))],
                               expected: ["n": Double(F.num), "d": Double(F.den)],
                               hint: simpHint, explain: simpExplain,
                               check: { v in
                                   let n = v["n"] ?? 0, dd = v["d"] ?? 0, S = Double(N), L = Double(D)
                                   if dd == 0 { return .soft("The bottom can’t be 0.") }
                                   if n * L != S * dd {
                                       return .wrong(S > L ? "That’s not equal to \(N)/\(D). How many whole \(D)s fit into \(N)? That’s the whole number. What’s left over goes on top."
                                                           : "That’s not equal to \(N)/\(D). Divide the top and the bottom by the same number.")
                                   }
                                   if n >= dd { return .soft("That’s the right amount. Now write it as a mixed number. How many whole \(fmt(dd))s fit into \(fmt(n))?") }
                                   let k = gcdOf(n, dd)
                                   if n > 0 && k > 1 { return .wrong("Same amount. \(fmt(n))/\(fmt(dd)) can still be simplified. Both \(fmt(n)) and \(fmt(dd)) divide by \(fmt(k)).") }
                                   return .right
                               }),
            picture: ["at": 3, "ask": 4])

        let done = LessonStep(StepWords(say: "\(A) × \(C) = \(answer).",
                                        hint: "Taking part of a part makes smaller pieces: half of a third is a sixth.",
                                        action: "Next problem"),
                              picture: ["at": 4])
        return [ask, across, simplify, done]
    }
}
