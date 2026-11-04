import Foundation

/// What 6th grade's Expressions chapter shares (design/grade6.md chapter 5, the preview
/// design/prototype/grade6-ch5.html): a letter is a strip whose length isn't known yet, the same length wherever it's
/// written; swapping in a number drags the strip to that length, and every copy goes with it.
public enum Expr6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// A power as the paper writes it: 4², 2³.
    public static func power(_ a: Int, _ n: Int) -> String { "\(a)\(n == 2 ? "²" : n == 3 ? "³" : "^\(n)")" }
    static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? abs(a) : gcd(b, a % b) }
    /// "x", "2x", "3n": a number times a letter, tight.
    public static func term(_ k: Int, _ x: String) -> String { k == 1 ? x : "\(k)\(x)" }
}

// MARK: - Exponents and order

/// Exponents and order (the web app's g6-expo, 6.EE.1, 6.EE.2c): aⁿ + b × c written once, big, as the record's first
/// line. Tap what goes first (the power); build it under the line, a block a one (Unit cubes' block): drag the corner out a
/// block at a time to a by a, and for a cube stand it up and drag up its layers; write aⁿ; tap what's next (the ×); write
/// b × c, then the sum.
///
/// "at": 0 the question, 1 tap first, 2 build, 3 layers (a cube), 4 write the power, 5 tap next, 6 multiply, 7 add, 8 done.
public enum Expo6 {
    public static func numbers(a: Int, n: Int, b: Int, c: Int) -> Numbers { ["a": Double(a), "n": Double(n), "b": Double(b), "c": Double(c)] }
    /// The parts of the line a tap can pick: the power, the +, the product.
    public static let pow = 0, plus = 1, times = 2

    public struct Parts: Sendable {
        public let a: Int, n: Int, b: Int, c: Int
        public init(_ x: Numbers) {
            a = Int((x["a"] ?? 4).rounded()); n = Int((x["n"] ?? 2).rounded()); b = Int((x["b"] ?? 5).rounded()); c = Int((x["c"] ?? 3).rounded())
        }
        public var cube: Bool { n == 3 }
        public var E: Int { (0..<n).reduce(1) { r, _ in r * a } }
        public var M: Int { b * c }
        public var S: Int { E + M }
        public var pw: String { Expr6.power(a, n) }
        /// "4 × 4", "2 × 2 × 2".
        public var times: String { Array(repeating: "\(a)", count: n).joined(separator: " × ") }
        public let firstSay = "Tap what goes first."
        public var buildSay: String { cube ? "Build \(pw). Start with its floor: drag the corner out a block at a time." : "Build \(pw). Drag the corner out a block at a time." }
        public let layersSay = "Build it up. Drag up to stack the layers."
        public var expSay: String { "Write what \(pw) makes. Count the \(cube ? "cubes" : "squares")." }
        public let nextSay = "Tap what’s next."
        public let mulSay = "Multiply next."
        public let addSay = "Add last."
        public var why: String { "\(pw) is \(times), and it goes before × and +." }
        /// What a rectangle w by h let go says (nil: right).
        public func built(_ w: Int, _ h: Int) -> String? {
            if w == a && h == a { return nil }
            return cube ? "That’s \(w) × \(h). The floor of \(pw) is \(a) by \(a)." : "That’s \(w) × \(h). \(pw) is \(a) by \(a)."
        }
        public func stacked(_ l: Int) -> String? { l == a ? nil : "That’s \(a) × \(a) × \(l). \(pw) is \(a) by \(a) by \(a)." }
        public func power(_ v: Int) -> String? {
            if v == E { return nil }
            if v == a * n { return "\(pw) means \(times), not \(a) × \(n)." }
            return cube ? "Count the cubes: \(a) layers of \(a * a)." : "Count the squares: \(a) rows of \(a)."
        }
        public func product(_ v: Int) -> String? {
            v == M ? nil : v == b + c ? "The sign is ×: \(b) groups of \(c)." : "\(b) × \(c) is \(b) groups of \(c)."
        }
        public func sum(_ v: Int) -> String? {
            if v == S { return nil }
            if v == (E + b) * c { return "\(b) × \(c) comes first. Add \(M), not \(b)." }
            if v == a * n + M { return "\(pw) means \(times), not \(a) × \(n)." }
            if v == E * M { return "The sign is +, so add." }
            return "Add \(E) and \(M)."
        }
    }

    /// The web's generator: the first three a 3–4 squared, b and c 2–5; then a 2–5 (2 always cubed, never 2²), squared
    /// or cubed, b and c 2–9.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i < 3 { return numbers(a: r(3, 4), n: 2, b: r(2, 5), c: r(2, 5)) }
        let a = r(2, 5)
        return numbers(a: a, n: a == 2 ? 3 : r(2, 3), b: r(2, 9), c: r(2, 9))
    }

    public static let spec = LessonSpec(id: "g6-expo", title: "Exponents and order", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(s.pw), .op("+"), .num(Double(s.b)), .op("×"), .num(Double(s.c))] },
        idea: { _ in "An exponent means multiply the number by itself, and it comes before × and +." },
        depends: ["g5-order", "g3-facts"],
        check: [CheckItem(3, when: { Parts($0).n == 3 }), CheckItem(3, when: { Parts($0).n == 2 && Parts($0).a >= 3 }),
                CheckItem(3, when: { !(Parts($0).a == 2 && Parts($0).n == 2) }), CheckItem(3, when: { !(Parts($0).a == 2 && Parts($0).n == 2) })]) { x in
        let s = Parts(x)
        let firstHint = "Powers first, then ×, then +."
        let ask = LessonStep(StepWords(say: s.firstSay, hint: firstHint, action: "Let’s find out"), picture: ["at": 0])
        func tap(_ at: Double, _ say: String, want: Int, miss: String, hint: String) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(want)], hint: hint, explain: hint,
                                   check: { v in
                                       let p = Expr6.int(v, "p")
                                       if p == want { return .right }
                                       return p == Expo6.plus || p == Expo6.times ? .wrong(miss) : .soft(say)
                                   }, byHand: true),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let first = tap(1, s.firstSay, want: Expo6.pow, miss: "The exponent goes before × and +.", hint: firstHint)
        let buildHint = "\(s.pw) is \(s.a) by \(s.a)\(s.cube ? " on the floor" : "")."
        let build = LessonStep(StepWords(say: s.buildSay, hint: buildHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.a * 10 + s.a)], hint: buildHint, explain: "\(s.a) by \(s.a).",
                               check: { v in
                                   let x = Expr6.int(v, "x", 0)
                                   return s.built(x / 10, x % 10).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        var steps = [ask, first, build]
        if s.cube {
            let hint = "\(s.pw) is \(s.a) layers of \(s.a) by \(s.a)."
            steps.append(LessonStep(StepWords(say: s.layersSay, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("l")], expected: ["l": Double(s.a)], hint: hint, explain: "\(s.a) layers.",
                                   check: { v in s.stacked(Expr6.int(v, "l", 0)).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        func typed(_ at: Double, _ say: String, _ prompt: MathLine, _ want: Int, hint: String, _ judge: @escaping @Sendable (Int) -> String?) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: prompt, expected: ["x": Double(want)], hint: hint, explain: "That makes \(want).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Write the number.") }
                                       return judge(Int(x.rounded())).map { .wrong($0) } ?? (x == x.rounded() ? .right : .wrong(hint))
                                   }, incomplete: "Write the number."),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        steps.append(typed(4, s.expSay, [.text(s.pw), .op("="), .box("x")], s.E, hint: "\(s.pw) means \(s.times).") { s.power($0) })
        steps.append(tap(5, s.nextSay, want: Expo6.times, miss: "× goes before +.", hint: "× before +."))
        steps.append(typed(6, s.mulSay, [.num(Double(s.b)), .op("×"), .num(Double(s.c)), .op("="), .box("x")], s.M,
                           hint: "\(s.b) groups of \(s.c).") { s.product($0) })
        steps.append(typed(7, s.addSay, [.num(Double(s.E)), .op("+"), .num(Double(s.M)), .op("="), .box("x")], s.S,
                           hint: "Only the adding is left.") { s.sum($0) })
        steps.append(LessonStep(StepWords(say: s.why, hint: firstHint, action: "Next problem"), picture: ["at": 8]))
        return steps
    }
}

// MARK: - Write expressions

/// Write expressions (g6-write, 6.EE.2a, 6.EE.2b, 6.EE.6): a tray with an n strip (8 squares, its end dashed) and ten
/// squares; a build line 40 squares long. Slide pieces onto the line (they snap end to end; dropped over the end they take
/// away, crossed out; a strip alone on the line is cut with the ruler for "half of"), then Check; write it the short way
/// (the numbers typed); then tap the part named.
///
/// "at": 0 the question, 1 build, 2 write, 3 tap a part, 4 done.
public enum Write6 {
    /// kind: 0 more than, 1 times, 2 times plus, 3 less than, 4 half of, 5 twice the sum.
    public static func numbers(kind: Int, story: Bool = false, p: Int = 5, k: Int = 3, q: Int = 12, m: Int = 4, ask: Int = 0) -> Numbers {
        ["kind": Double(kind), "story": story ? 1 : 0, "p": Double(p), "k": Double(k), "q": Double(q), "m": Double(m), "ask": Double(ask)]
    }
    /// A written token of the short way: words and signs as they're written, or a box for a number.
    public enum Tok: Sendable, Equatable { case s(String), box(String, Int) }
    public struct Span: Sendable, Equatable { public let id: String, from: Int, to: Int }

    public struct Parts: Sendable {
        public let kind: Int, story: Bool, p: Int, k: Int, q: Int, m: Int, ask: Bool
        public init(_ x: Numbers) {
            func i(_ s: String, _ d: Int) -> Int { Int((x[s] ?? Double(d)).rounded()) }
            kind = i("kind", 0); story = i("story", 0) == 1; p = i("p", 5); k = i("k", 3); q = i("q", 12); m = i("m", 4); ask = i("ask", 0) == 1
        }
        /// What's built: so many n strips, so many squares (negative: taken away), the strip cut into (1: whole).
        public var wantK: Int { [0: 1, 1: k, 2: k, 3: -1, 4: 1, 5: 2][kind] ?? 1 }
        public var wantC: Int { [0: p, 1: 0, 2: p, 3: q, 4: 0, 5: 2 * m][kind] ?? 0 }
        public var cut: Int { kind == 4 ? 2 : 1 }
        public var phrase: String {
            switch kind {
            case 0: return story ? "Sam has n cards and gets \(p) more." : "\(p) more than n"
            case 1: return story ? "A box holds n pens. How many pens in \(k) boxes?" : "\(k) times n"
            case 2: return "\(k) times n, plus \(p)"
            case 3: return story ? "Mia had \(q) stickers and gave n away." : "n less than \(q)"
            case 4: return "half of n"
            default: return "twice the sum of n and \(m)"
            }
        }
        /// The phrase as a sentence: capitalised, with its full stop.
        public var sentence: String {
            var s = phrase
            if let f = s.first, f != "n" { s = f.uppercased() + s.dropFirst() }
            return s.hasSuffix(".") || s.hasSuffix("?") ? s : s + "."
        }
        public var buildSay: String { "\(sentence) Slide pieces onto the line, then Check." }
        public var writeSay: String { "\(sentence) Write it the short way." }
        /// The short way: n + [5], [3]n, [3]n + [5], [12] − n, n ÷ [2], [2](n + [4]).
        public var toks: [Tok] {
            switch kind {
            case 0: return [.s("n"), .s("+"), .box("a", p)]
            case 1: return [.box("a", k), .s("n")]
            case 2: return [.box("a", k), .s("n"), .s("+"), .box("b", p)]
            case 3: return [.box("a", q), .s("−"), .s("n")]
            case 4: return [.s("n"), .s("÷"), .box("a", 2)]
            // the brackets written tight against what they hold: 2(n + 4)
            default: return [.box("a", 2), .s("(n"), .s("+"), .box("b", m), .s(")")]
            }
        }
        /// The parts a tap can pick, by the tokens they run over.
        public var spans: [Span] {
            func S(_ id: String, _ a: Int, _ b: Int) -> Span { Span(id: id, from: a, to: b) }
            switch kind {
            case 0: return [S("n", 0, 0), S("p", 2, 2), S("all", 0, 2)]
            case 1: return [S("k", 0, 0), S("n", 1, 1), S("all", 0, 1)]
            case 2: return [S("k", 0, 0), S("n", 1, 1), S("kn", 0, 1), S("p", 3, 3), S("all", 0, 3)]
            case 3: return [S("q", 0, 0), S("n", 2, 2), S("all", 0, 2)]
            case 4: return [S("n", 0, 0), S("d", 2, 2), S("all", 0, 2)]
            default: return [S("two", 0, 0), S("n", 1, 1), S("m", 3, 3), S("sum", 1, 4), S("all", 0, 4)]
            }
        }
        /// The part asked for, and the spans that are it.
        public var name: String {
            switch kind {
            case 0: return "the sum"
            case 1: return ask ? "the product" : "the coefficient"
            case 2: return "the coefficient"
            case 3: return "a term"
            case 4: return "the quotient"
            default: return ask ? "a factor" : "the sum"
            }
        }
        public var right: [String] {
            switch kind {
            case 0: return ["all"]
            case 1: return ask ? ["all"] : ["k"]
            case 2: return ["k"]
            case 3: return ["q", "n"]
            case 4: return ["all"]
            default: return ask ? ["two", "sum"] : ["sum"]
            }
        }
        public var tapSay: String { "Tap \(name)." }
        /// What tapping span `id` says when it isn't the part asked for.
        public func wrongTap(_ id: String) -> String {
            switch kind {
            case 0: return "\(id == "n" ? "n" : "\(p)") is one term. The sum is all of n + \(p)."
            case 1:
                if ask { return "That’s a factor. The product is all of \(k)n." }
                return id == "n" ? "n is the letter. The coefficient is the number that multiplies it." : "That’s the whole product. The coefficient is the number in it."
            case 2:
                switch id {
                case "p": return "\(p) is a term on its own. The coefficient multiplies n."
                case "n": return "n is the letter. The coefficient is the number that multiplies it."
                case "kn": return "That’s the whole term. The coefficient is the number in it."
                default: return "That’s the whole sum. The coefficient is the number that multiplies n."
                }
            case 3: return "That’s the whole difference. A term is one part: \(q) or n."
            case 4: return "The quotient is all of n ÷ 2: what the dividing makes."
            default:
                if ask { return id == "all" ? "That’s the product. A factor is one of what’s multiplied." : "That’s inside the sum. The factors are 2 and (n + \(m))." }
                return id == "two" ? "2 is a factor. The sum is n + \(m)." : id == "all" ? "That’s the product. The sum is inside the brackets." : "That’s one term. The sum is n + \(m)."
            }
        }
        public var why: String {
            switch kind {
            case 0: return "n + \(p) adds two terms, so it’s a sum."
            case 1: return ask ? "\(k)n means \(k) times n, so it’s a product." : "\(k)n means \(k) n’s, so \(k) is the coefficient."
            case 2: return "\(k)n means \(k) n’s, so \(k) is the coefficient."
            case 3: return "\(q) − n has two terms: \(q) and n."
            case 4: return "n ÷ 2 is n cut into 2 equal parts: a quotient."
            default: return ask ? "2(n + \(m)) multiplies 2 by the sum, so both are factors." : "2(n + \(m)) is two of the sum n + \(m)."
            }
        }
        public func boxMiss(_ box: String, _ v: Int) -> String {
            switch kind {
            case 0: return "Count the squares you laid."
            case 1: return "Count the n strips."
            case 2: return box == "a" ? "Count the n strips." : "Count the squares."
            case 3: return "Count the squares you started with."
            case 4: return "Half is n cut into 2 equal parts."
            default: return box == "a" ? "Count the copies of n + \(m)." : v == 2 * m ? "Inside the brackets is one n + \(m)." : "Count the squares in one copy."
            }
        }
        /// What's built, the short way: "3n + 5", "12 − n", "n ÷ 2".
        public static func compact(k: Int, c: Int, cut: Int) -> String {
            if cut > 1 && k == 1 && c == 0 { return "n ÷ \(cut)" }
            if k < 0 && c > 0 { return "\(c) − \(Expr6.term(-k, "n"))" }
            let kn = k == 1 ? "n" : k == -1 ? "−n" : k != 0 ? "\(k)n" : ""
            if kn.isEmpty { return fmt(Double(c)) }
            return c > 0 ? "\(kn) + \(c)" : c < 0 ? "\(kn) − \(-c)" : kn
        }
        /// What Check on the built line says (nil: right).
        public func built(k: Int, c: Int, cut: Int) -> Verdict {
            if k == 0 && c == 0 { return .soft("Slide pieces onto the line.") }
            if k == wantK && c == wantC && cut == self.cut { return .right }
            let got = Parts.compact(k: k, c: c, cut: cut)
            if kind == 3 && k == 1 && c == -q { return .wrong("\(q) − n: start with \(q) and take n away.") }
            if kind == 5 && k == 2 && c == m { return .wrong("That’s 2n + \(m). Twice the sum is two of n + \(m).") }
            if story { return .wrong("That’s \(got). Read the story again.") }
            if (kind == 1 || kind == 2) && k == 1 { return .wrong("That’s \(got). The words say \(self.k) times n.") }
            return .wrong("That’s \(got). The words say \(phrase).")
        }
    }

    /// Problems 1–3 "more than" and "times"; 4–6 "less than", "half of", "times, plus"; 7+ twice a sum and stories that
    /// need the letter, with the rest mixed in. Numbers 2–9 (10–20 when taking away).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        var kind: Int, story = false
        if i == 0 { kind = 0 } else if i == 1 { kind = 1 } else if i == 2 { kind = [0, 1][r(0, 1)] }
        else if i < 6 { kind = [3, 4, 2][i - 3] }
        else {
            let pick = [5, 9, 5, 9, 2, 3, 4][r(0, 6)]
            if pick == 9 { kind = [0, 1, 3][r(0, 2)]; story = true } else { kind = pick }
        }
        return numbers(kind: kind, story: story, p: r(2, 9), k: kind == 1 ? r(2, 5) : r(2, 3), q: r(10, 20), m: r(2, 9), ask: r(0, 1))
    }

    public static let spec = LessonSpec(id: "g6-write", title: "Write expressions", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text(Parts(x).phrase)] },
        idea: { _ in "A letter stands for a number you don’t know yet; the short way writes what’s done to it." },
        depends: ["g6-expo", "g5-order"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).kind == 3 && !Parts($0).story }), CheckItem(6, when: { Parts($0).kind == 5 }),
                CheckItem(2, when: { Parts($0).kind == 1 })]) { x in
        let s = Parts(x)
        let buildHint = "An n strip for each n, a square for each one."
        let ask = LessonStep(StepWords(say: s.buildSay, hint: buildHint, action: "Let’s find out"), picture: ["at": 0])
        let build = LessonStep(StepWords(say: s.buildSay, hint: buildHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k"), .box("c"), .box("h")], expected: ["k": Double(s.wantK), "c": Double(s.wantC), "h": Double(s.cut)],
                               hint: buildHint, explain: Parts.compact(k: s.wantK, c: s.wantC, cut: s.cut),
                               check: { v in s.built(k: Expr6.int(v, "k", 0), c: Expr6.int(v, "c", 0), cut: Expr6.int(v, "h", 1)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        var prompt: MathLine = [], want: [String: Double] = [:]
        for t in s.toks {
            switch t {
            case .s(let w): prompt.append(w.count == 1 && "+−×÷=".contains(w) ? .op(w) : .text(w))
            case .box(let id, let v): prompt.append(.box(id)); want[id] = Double(v)
            }
        }
        let writeHint = "Write the numbers you built with."
        let write = LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: want, hint: writeHint, explain: Parts.compact(k: s.wantK, c: s.wantC, cut: s.cut),
                               check: { v in
                                   for t in s.toks {
                                       guard case .box(let id, let w) = t else { continue }
                                       guard let got = v[id] else { return .soft("Write the number.") }
                                       if Int(got.rounded()) != w || got != got.rounded() { return .wrong(s.boxMiss(id, Int(got.rounded()))) }
                                   }
                                   return .right
                               }, incomplete: "Write the number."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let spans = s.spans, rightIdx = spans.indices.filter { s.right.contains(spans[$0].id) }
        let tapHint = "Tap under the part to pick it."
        let tap = LessonStep(StepWords(say: s.tapSay, hint: tapHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(rightIdx.first ?? 0)], hint: tapHint, explain: s.why,
                               check: { v in
                                   let p = Expr6.int(v, "p")
                                   guard spans.indices.contains(p) else { return .soft(s.tapSay) }
                                   return rightIdx.contains(p) ? .right : .wrong(s.wrongTap(spans[p].id))
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: buildHint, action: "Next problem"), picture: ["at": 4])
        return [ask, build, write, tap, done]
    }
}

// MARK: - Evaluate expressions

/// Evaluate expressions (the web app's g6-eval, 6.EE.2c): ax + by as rows, a cell two squares: a rows of an x strip and,
/// a block away, b rows of a y strip (striped); the values the picture's names. Drag an x strip's end: every x row
/// stretches a cell at a time; let go at x and the letter gives way to the number; write a × x; the same for y; add.
///
/// "at": 0 the question, 1 make x, 2 write ax, 3 make y, 4 write by, 5 add, 6 done.
public enum Eval6 {
    public static func numbers(a: Int, b: Int, x: Int, y: Int) -> Numbers { ["a": Double(a), "b": Double(b), "x": Double(x), "y": Double(y)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int, x: Int, y: Int
        public init(_ n: Numbers) {
            a = Int((n["a"] ?? 3).rounded()); b = Int((n["b"] ?? 2).rounded()); x = Int((n["x"] ?? 4).rounded()); y = Int((n["y"] ?? 5).rounded())
        }
        public var AX: Int { a * x }
        public var BY: Int { b * y }
        public var S: Int { AX + BY }
        /// The strips' longest, in cells (the first three problems' numbers are 5 or less).
        public var cap: Int { max(a, b, x, y) <= 5 ? 6 : 9 }
        public var xSay: String { "Make x \(x). Drag the end of an x strip." }
        public var ySay: String { "Make y \(y). Drag the end of a y strip." }
        public var axSay: String { "Write what \(a)x is. Count the cells." }
        public var bySay: String { "Write what \(b)y is. Count the cells." }
        public let addSay = "Add the two parts."
        public var why: String { "Every x is \(x), so \(a)x is \(a) rows of \(x)." }
        public func made(_ got: Int, _ letter: String) -> String? {
            let want = letter == "x" ? x : y
            return got == want ? nil : "That’s \(got). \(letter) is \(want)."
        }
        public func times(_ v: Int, _ k: Int, _ val: Int, _ letter: String) -> String? {
            if v == k * val { return nil }
            if v == Int("\(k)\(val)") || v == k + val { return "\(k)\(letter) means \(k) × \(val)." }
            return "Count the cells: \(k) rows of \(val)."
        }
        public func sum(_ v: Int) -> String? { v == S ? nil : v == AX * BY ? "The sign between \(AX) and \(BY) is +, so add." : "Add the two parts." }
    }

    /// The web's generator: the first three all 5 or less, then a and b 2–9, x and y 1–9.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let t = i < 3 ? 5 : 9
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        return numbers(a: r(2, t), b: r(2, t), x: r(1, t), y: r(1, t))
    }

    public static let spec = LessonSpec(id: "g6-eval", title: "Evaluate expressions", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text("\(s.a)x"), .op("+"), .text("\(s.b)y")] },
        idea: { _ in "A letter stands for a number, so the number can take its place." },
        depends: ["g5-order", "g3-facts"],
        check: [CheckItem(3), CheckItem(3), CheckItem(3, when: { Parts($0).x == 1 || Parts($0).y == 1 }), CheckItem(3)]) { n in
        let s = Parts(n)
        let ask = LessonStep(StepWords(say: s.xSay, hint: "Drag until the strip is \(s.x) cells long.", action: "Let’s find out"), picture: ["at": 0])
        func make(_ at: Double, _ say: String, _ letter: String, _ want: Int) -> LessonStep {
            let hint = "Drag until the strip is \(want) cells long."
            return LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(want)], hint: hint, explain: "\(letter) = \(want)",
                                   check: { v in s.made(Expr6.int(v, "x", 0), letter).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        func typed(_ at: Double, _ say: String, _ prompt: MathLine, _ want: Int, hint: String, _ judge: @escaping @Sendable (Int) -> String?) -> LessonStep {
            LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: prompt, expected: ["x": Double(want)], hint: hint, explain: "That makes \(want).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Write the number.") }
                                       return judge(Int(x.rounded())).map { .wrong($0) } ?? .right
                                   }, incomplete: "Write the number."),
                picture: ["at": at], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        return [ask, make(1, s.xSay, "x", s.x),
                typed(2, s.axSay, [.num(Double(s.a)), .op("×"), .num(Double(s.x)), .op("="), .box("x")], s.AX, hint: "\(s.a)x means \(s.a) times x.") { s.times($0, s.a, s.x, "x") },
                make(3, s.ySay, "y", s.y),
                typed(4, s.bySay, [.num(Double(s.b)), .op("×"), .num(Double(s.y)), .op("="), .box("x")], s.BY, hint: "\(s.b)y means \(s.b) times y.") { s.times($0, s.b, s.y, "y") },
                typed(5, s.addSay, [.num(Double(s.AX)), .op("+"), .num(Double(s.BY)), .op("="), .box("x")], s.S, hint: "The + between the parts means add them.") { s.sum($0) },
                LessonStep(StepWords(say: s.why, hint: "Swap in the numbers, then × before +.", action: "Next problem"), picture: ["at": 6])]
    }
}

// MARK: - Equivalent expressions

/// Equivalent expressions (g6-equiv, 6.EE.3, 6.EE.4): an area a cell two squares, rows tall and x + b across, the x part
/// a strip of any length (its end dashed), the b part b cells. Combine: slide x strips together into one rectangle;
/// distribute: cut where x ends; factor: drag the rows' edge until both parts make whole rows; then drag x to any length:
/// both sides' values, the same every time. A pair that isn't the same shows two numbers: pick Same or Not the same.
///
/// "at": 0 the question, 1 the move (slide, cut, rows), 2 write, 3 drag x, 4 done, 5 pick (a pair).
public enum Equiv6 {
    /// kind: 0 combine, 1 distribute, 2 factor, 3 same or not.
    public static func numbers(kind: Int, k: Int = 3, a: Int = 3, b: Int = 4, g: Int = 3, m: Int = 2, n: Int = 3, same: Bool = true) -> Numbers {
        ["kind": Double(kind), "k": Double(k), "a": Double(a), "b": Double(b), "g": Double(g), "m": Double(m), "n": Double(n), "same": same ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let kind: Int, k: Int, a: Int, b: Int, g: Int, m: Int, n: Int, same: Bool
        public init(_ x: Numbers) {
            func i(_ s: String, _ d: Int) -> Int { Int((x[s] ?? Double(d)).rounded()) }
            kind = i("kind", 0); k = i("k", 3); a = i("a", 3); b = i("b", 4); g = i("g", 3); m = i("m", 2); n = i("n", 3); same = i("same", 1) == 1
        }
        /// Factoring: the x strips and the cells in all.
        public var PX: Int { g * m }
        public var QN: Int { g * n }
        public var mx: String { Expr6.term(m, "x") }
        /// The two sides' values at x = v.
        public func sides(_ v: Int) -> (Int, Int) {
            switch kind {
            case 0: return (k * v, k * v)
            case 1: return (a * (v + b), a * v + a * b)
            case 2: return (PX * v + QN, g * (m * v + n))
            default: return (a * (v + b), a * v + (same ? a * b : b))
            }
        }
        /// The tallest the rows' edge can go when factoring.
        public var hMax: Int { min(6, PX, QN) }
        /// The longest x is dragged, in cells.
        public var xCap: Int { kind == 2 ? min(12, (21 - n) / m) : kind == 0 ? 12 : min(12, 21 - b) }
        public var sum: String { Array(repeating: "x", count: k).joined(separator: " + ") }
        public var moveSay: String {
            switch kind {
            case 0: return "Slide them together. Drag the bottom strip up."
            case 1: return "Cut where x ends. Drag down along a grid line."
            case 2: return "Make rows that both parts fill. Drag the bottom edge down."
            default: return "Drag x. Are they the same for every x?"
            }
        }
        public var writeSay: String { ["Write how many x’s that is.", "Write each part.", "Write it as rows."][min(2, kind)] }
        public let dragSay = "Drag x. Try two lengths: see both sides each time."
        public let pickSay = "Same or not the same? Drag x again to try more."
        public var why: String {
            switch kind {
            case 0: return "\(k) rows of x are \(k)x, whatever x is."
            case 1: return "\(a) rows of x + \(b) are \(a)x + \(a * b), whatever x is."
            case 2: return "\(g) rows of \(mx) + \(n) are \(PX)x + \(QN), whatever x is."
            default: return same ? "\(a) rows of x + \(b) are \(a)x + \(a * b), whatever x is." : "\(a)(x + \(b)) is \(a)x + \(a * b), not \(a)x + \(b)."
            }
        }
        /// The display: "x + x + x", "3(x + 4)", "6x + 9", "3(x + 4) and 3x + 12".
        public var shown: String {
            switch kind {
            case 0: return sum
            case 1: return "\(a)(x + \(b))"
            case 2: return "\(PX)x + \(QN)"
            default: return "\(a)(x + \(b)) and \(a)x + \(same ? a * b : b)"
            }
        }
        /// What the rows' edge let go at h rows says (nil: right).
        public func rows(_ h: Int) -> String? {
            if h == g { return nil }
            if h <= 1 { return "Drag the bottom edge down to make rows." }
            return PX % h == 0 && QN % h == 0 ? "That fits, but more rows fit too." : "Not every row gets the same."
        }
        /// What the writing says (nil: right).
        public func written(_ v: [String: Double]) -> Verdict {
            func got(_ id: String) -> Int? { v[id].map { Int($0.rounded()) } }
            switch kind {
            case 0:
                guard let c = got("c") else { return .soft("Write the number.") }
                return c == k ? .right : .wrong("Count the rows: each row is one x.")
            case 1:
                guard let c = got("c"), let d = got("d") else { return .soft("Fill in every box.") }
                if c != a { return .wrong("\(a) rows of x make \(a)x.") }
                if d != a * b { return .wrong(d == b ? "Every row has \(b) too: \(a) rows of \(b)." : "\(a) rows of \(b): count the cells.") }
                return .right
            default:
                guard let G = got("g"), let N = got("n"), m == 1 || got("m") != nil else { return .soft("Fill in every box.") }
                if G != g { return .wrong(G > 1 && g % G == 0 ? "That’s a common factor, but not the greatest." : "Count the rows.") }
                if (m != 1 && got("m") != m) || N != n { return .wrong("Write what one row holds.") }
                return .right
            }
        }
    }

    /// Problems 1–3 combining 2–5 strips (the first 3); 4–6 distributing (a 2–6, b 1–9); 7+ factoring (g 2–5, m and n
    /// with no shared factor, every row fitting 21 cells) and same-or-not pairs, in turn.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i < 3 { return numbers(kind: 0, k: i == 0 ? 3 : r(2, 5)) }
        if i < 6 { return numbers(kind: 1, a: r(2, 6), b: r(1, 9)) }
        if i % 2 == 0 {
            while true {
                let g = r(2, 5), m = r(1, 4), n = r(1, 5)
                if Expr6.gcd(m, n) == 1 && g * (2 * m + n) <= 21 && 4 * m + n <= 21 { return numbers(kind: 2, g: g, m: m, n: n) }
            }
        }
        return numbers(kind: 3, a: r(2, 6), b: r(1, 9), same: r(0, 1) == 1)
    }

    public static let spec = LessonSpec(id: "g6-equiv", title: "Equivalent expressions", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text(Parts(x).shown)] },
        idea: { _ in "Two expressions are the same when they make the same number whatever x is." },
        depends: ["g6-eval", "g6-gcf"],
        check: [CheckItem(1), CheckItem(4), CheckItem(6, when: { Parts($0).kind == 2 }), CheckItem(7, when: { Parts($0).kind == 3 })]) { x in
        let s = Parts(x)
        let moveHint = ["Every strip is one x: put them in one block.", "x ends where the cells begin.", "Both parts must split into the same rows.",
                        "Drag x and read both numbers."][s.kind]
        let ask = LessonStep(StepWords(say: s.moveSay, hint: moveHint, action: "Let’s find out"), picture: ["at": 0])
        var steps = [ask]
        let dragHint = "Drag x’s end, let go, then drag again."
        let drag = LessonStep(StepWords(say: s.dragSay, hint: dragHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": 2], hint: dragHint, explain: "The same at every length.",
                               check: { v in Expr6.int(v, "t", 0) >= 2 ? .right : .soft(s.dragSay) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        if s.kind == 3 {
            let one = LessonStep(StepWords(say: s.moveSay, hint: moveHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("t")], expected: ["t": 1], hint: moveHint, explain: "Both numbers show.",
                                   check: { v in Expr6.int(v, "t", 0) >= 1 ? .right : .soft(s.moveSay) }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
            let miss = s.same ? "Look at the two numbers: they match at every x you try. They’re the same."
                : "Look at the two numbers: they’re different, so not the same."
            let pick = LessonStep(StepWords(say: s.pickSay, hint: "Read the two numbers.", action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": s.same ? 0 : 1], hint: "Read the two numbers.", explain: s.why,
                                   check: { v in Expr6.int(v, "c") == (s.same ? 0 : 1) ? .right : .wrong(miss) }, choices: ["Same", "Not the same"]),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
            steps += [one, pick]
        } else {
            let move: LessonStep
            switch s.kind {
            case 0:
                move = LessonStep(StepWords(say: s.moveSay, hint: moveHint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: moveHint, explain: "\(s.k) rows of x.",
                                       check: { v in Expr6.int(v, "x", 0) == 1 ? .right : .wrong("Slide them all together.") }, byHand: true),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            case 1:
                move = LessonStep(StepWords(say: s.moveSay, hint: moveHint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: moveHint, explain: "x | \(s.b)",
                                       check: { v in
                                           let c = Expr6.int(v, "x", 0)
                                           return c == 1 ? .right : c == -1 ? .wrong("Cut all the way down.") : .wrong("Cut where x ends.")
                                       }, byHand: true),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            default:
                move = LessonStep(StepWords(say: s.moveSay, hint: moveHint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.g)], hint: moveHint, explain: "\(s.g) rows: \(s.mx) and \(s.n)",
                                       check: { v in s.rows(Expr6.int(v, "x", 0)).map { .wrong($0) } ?? .right }, byHand: true),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            }
            let prompt: MathLine, want: [String: Double]
            switch s.kind {
            case 0: prompt = [.text(s.sum), .op("="), .box("c"), .text("x")]; want = ["c": Double(s.k)]
            case 1: prompt = [.text("\(s.a)(x + \(s.b))"), .op("="), .box("c"), .text("x"), .op("+"), .box("d")]; want = ["c": Double(s.a), "d": Double(s.a * s.b)]
            default:
                prompt = [.text("\(s.PX)x + \(s.QN)"), .op("="), .box("g"), .text("(")] + (s.m == 1 ? [] : [.box("m")]) + [.text("x"), .op("+"), .box("n"), .text(")")]
                want = ["g": Double(s.g), "n": Double(s.n)].merging(s.m == 1 ? [:] : ["m": Double(s.m)]) { $1 }
            }
            let writeHint = ["Each row is one x.", "Every row has x and \(s.b).", "Count the rows, then what one row holds."][s.kind]
            let write = LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
                answer: AnswerTask(prompt: prompt, expected: want, hint: writeHint, explain: s.why, check: { v in s.written(v) }, incomplete: "Fill in every box."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            steps += [move, write, drag]
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "The same whatever x is.", action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
