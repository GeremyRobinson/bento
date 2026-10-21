import Foundation

/// Multiplying fractions (the web app's g5-multfrac): a/b × c/d, both proper and in lowest terms.
/// Multiply straight across (a×c over b×d), then simplify. The answer is always less than 1, so it is never whole.
/// Numbers: a, b, c, d (bottoms 2 to 9; 2 to 5 for the first three problems of a run): the web's ranges and order.
///
/// On the paper (design/grade5.md, the fractions family): one whole is a square whose side is the smallest multiple of
/// lcm(b, d) at least 24 squares, so every row and column is whole squares. 1. A ruler down the left side cuts it into
/// rows; Cut sets the cut's box to how many rows it makes, and a cut that isn't b rows says how many it made. 2. The
/// child taps a rows to shade them; Shade sets its box to how many are tapped (dropped when a is 1: the one row is
/// shaded with the cut). 3. A ruler along the top cuts it into columns, and 4. c columns are tapped and striped (dropped
/// when c is 1). The pieces shaded twice are numbered. 5. The record a/b × c/d = (a × c)/(b × d) = [N]/[D] is written,
/// with the web's slips (flipped like dividing, added), then 6. simplified, only when it can be, with the web's checks.
/// The last words say why.
///
/// Picture keys, by step (cumulative): "rulerR" (the rows' ruler); "rows" (the square cut into b rows); "tapR" (rows
/// tapped are shaded); "shR" (the first a rows shaded and named); "rulerC" (the columns' ruler); "cols" (cut into d
/// columns); "tapC" (columns tapped are striped); "shC" (the first c columns striped and named, the pieces shaded twice
/// numbered, the record written); "simp" (the simplest form asked); "done" (the answer in the chapter's colour).
public enum MultiplyFractions {
    public static func numbers(a: Int, b: Int, c: Int, d: Int) -> Numbers { ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)] }

    /// The web's gcd, on whatever the child types (decimals too), so its messages match.
    static func gcdOf(_ a: Double, _ b: Double) -> Double { b == 0 ? a : gcdOf(b, a.truncatingRemainder(dividingBy: b)) }

    /// S/L in lowest terms, as a whole part and a proper fraction (the web's finalForm).
    static func finalForm(_ S: Int, _ L: Int) -> (whole: Int, num: Int, den: Int) {
        let g = gcd(S, L), n = S / g, d = L / g
        return (n / d, n % d, d)
    }

    /// The whole square's side in squares: the smallest multiple of lcm(b, d) at least 24, so rows and columns are
    /// whole squares.
    public static func side(b: Int, d: Int) -> Int {
        let l = UnlikeFractions.lcm(max(1, b), max(1, d))
        return l * Int((24.0 / Double(l)).rounded(.up))
    }

    /// "1 row", "3 columns".
    static func count(_ k: Int, _ one: String) -> String { "\(k) \(k == 1 ? one : one + "s")" }

    /// What a cut into `x` rows (or columns) says: right at `want`, otherwise how many it made.
    static func cutVerdict(_ x: Double?, want: Int, _ one: String) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag the ruler first.") }
        if abs(x - Double(want)) < 1e-9 { return .right }
        guard x == x.rounded() else { return .wrong("Cut it into \(count(want, one)).") }
        return .wrong("That makes \(count(Int(x), one)). The bottom says \(want).")
    }

    /// What shading `t` rows (or columns) says: right at `want`, otherwise how many were shaded.
    static func shadeVerdict(_ t: Double?, want: Int, _ one: String) -> Verdict {
        guard let t, t > 0 else { return .soft("Tap a \(one) to shade it.") }
        if abs(t - Double(want)) < 1e-9 { return .right }
        return .wrong("That’s \(count(Int(t.rounded()), one)). The top says shade \(want).")
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
        let all: Numbers = ["rows": 1, "shR": 1, "cols": 1, "shC": 1]

        // the problem is written once, as the picture's own names (G 20 Oct): the first words say what the square is
        let ask = LessonStep(StepWords(say: "The square is one whole. Take part of it, then part of that part.",
                                       hint: "That’s \(C) of \(A). Look at the square.", action: "Let’s find out"))

        // 1. the rows: the ruler down the left cuts them; its box is how many rows
        let cutR = LessonStep(
            StepWords(say: "Drag the ruler to cut the square into \(b) rows, then cut.", hint: "The bottom of \(A) says \(b) rows.", action: "Cut"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(b)], hint: "The bottom says \(b) equal rows.",
                               explain: "Cut it into \(b) equal rows.", check: { v in cutVerdict(v["x"], want: b, "row") }, byHand: true),
            picture: ["rulerR": 1])
        // 2. a rows tapped and shaded (dropped when a is 1: the cut shades the one row)
        let shadeR = LessonStep(
            StepWords(say: "Tap \(a) rows to shade them.", hint: "The top of \(A) says shade \(a).", action: "Shade"),
            answer: AnswerTask(prompt: [.frac(.box("t"), .num(Double(b)))], expected: ["t": Double(a)], hint: "The top says shade \(a) rows.",
                               explain: "Shade \(a) of the \(b) rows.", check: { v in shadeVerdict(v["t"], want: a, "row") }, byHand: true),
            picture: ["rows": 1, "tapR": 1])
        // 3. the columns: the ruler along the top
        let cutC = LessonStep(
            StepWords(say: "Now drag the ruler to cut it into \(d) columns, then cut.", hint: "The bottom of \(C) says \(d) columns.", action: "Cut"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(d)], hint: "The bottom says \(d) equal columns.",
                               explain: "Cut it into \(d) equal columns.", check: { v in cutVerdict(v["x"], want: d, "column") }, byHand: true),
            picture: ["rows": 1, "shR": 1, "rulerC": 1])
        // 4. c columns tapped and striped (dropped when c is 1)
        let shadeC = LessonStep(
            StepWords(say: "Tap \(c) columns to shade them.", hint: "The top of \(C) says shade \(c).", action: "Shade"),
            answer: AnswerTask(prompt: [.frac(.box("t"), .num(Double(d)))], expected: ["t": Double(c)], hint: "The top says shade \(c) columns.",
                               explain: "Shade \(c) of the \(d) columns.", check: { v in shadeVerdict(v["t"], want: c, "column") }, byHand: true),
            picture: ["rows": 1, "shR": 1, "cols": 1, "tapC": 1])

        // 5. the record, as school writes it: a/b × c/d = (a × c)/(b × d) = [N]/[D], typed, with the web's slips. On the
        // paper the overlap is pieces (a square is the grid's), so the web's "squares" are "pieces" here
        let acrossHint = "Top times top counts the pieces shaded twice. Bottom times bottom counts all the pieces."
        let across = LessonStep(StepWords(say: "Count the pieces shaded twice, and all the pieces. Write them.", hint: "The pieces shaded twice are the answer.", action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(a)), .num(Double(b))), .op("×"), .frac(.num(Double(c)), .num(Double(d))), .op("="), .frac(.box("n"), .box("d"))],
                               expected: ["n": Double(N), "d": Double(D)],
                               known: [(["n": Double(a * d), "d": Double(b * c)], "Flipping is only for dividing. To multiply, go straight across."),
                                       (["n": Double(a + c), "d": Double(b + d)], "Multiply top × top and bottom × bottom.")],
                               hint: acrossHint,
                               explain: "\(a) × \(c) = \(N) on top and \(b) × \(d) = \(D) on the bottom: \(N)/\(D).",
                               // the web's ms: both boxes exactly, in place (no equivalent fraction yet; that's the next step)
                               check: { v in v["n"] == Double(N) && v["d"] == Double(D) ? .right : .wrong("Not quite. \(acrossHint)") }),
            picture: all)

        // 6. simplified, only when it can be: the web's simplifyStep (N < D here, so the whole-number box isn't written)
        let simpHint = N % D == 0 ? "\(N) ÷ \(D) = \(N / D) exactly, so it’s a whole number."
            : N >= D ? "\(N) ÷ \(D) = \(N / D) remainder \(N % D). The remainder goes on top."
            : "Both \(N) and \(D) can be divided by \(g)."
        let simpExplain = N >= D ? "\(N) ÷ \(D) = \(N / D) remainder \(N % D), then simplify." : "Divide top and bottom by \(g)."
        let simplify = LessonStep(StepWords(say: "Write it as simply as you can.", hint: "Divide the top and the bottom by \(g).", action: "Check"),
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
            picture: all.merging(["simp": 1]) { $1 })

        // the answer is in the record; the last words say why
        let done = LessonStep(StepWords(say: "\(N) of the \(D) pieces \(N == 1 ? "is" : "are") shaded twice.",
                                        hint: "Taking part of a part makes smaller pieces: half of a third is a sixth.",
                                        action: "Next problem"),
                              picture: all.merging(g > 1 ? ["simp": 1, "done": 1] : ["done": 1]) { $1 })
        return [ask, cutR] + (a > 1 ? [shadeR] : []) + [cutC] + (c > 1 ? [shadeC] : []) + [across] + (g > 1 ? [simplify] : []) + [done]
    }
}
