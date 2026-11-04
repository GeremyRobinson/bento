import Foundation

/// What 6th grade's Factors and fractions chapter shares (design/grade6.md chapter 2, the preview
/// design/prototype/grade6-ch2.html): the numbers' factors and multiples counted on the paper (hops along a line, a
/// ruler cutting bars), and the fractions family's bars (a whole a length every bottom divides).
public enum Fact6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func gcd(_ a: Int, _ b: Int) -> Int { Ratio6.gcd(a, b) }
    static func lcm(_ a: Int, _ b: Int) -> Int { Ratio6.lcm(a, b) }
    /// "a" or "an" before a number said aloud (an 8, an 11, an 18).
    public static func aOrAn(_ n: Int) -> String { ["8", "11", "18"].contains { String(n).hasPrefix($0) } ? "an" : "a" }
}

// MARK: - Least common multiple

/// Least common multiple (the web app's g6-lcm, 6.NS.4): LCM(a, b), a < b. One square a number (two while the line is 24
/// or shorter); a line from 0 to a × b, or to the last multiple of b that is 60 or less (it always holds the LCM). Hop
/// by b's to the end, tap the first landing a goes into (a's hops come under the line to it), then write L ÷ a.
///
/// "at": 0 the question, 1 hop, 2 tap, 3 write, 4 done.
public enum Lcm6 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ n: Numbers) { a = Int((n["a"] ?? 4).rounded()); b = Int((n["b"] ?? 6).rounded()) }
        public var L: Int { Fact6.lcm(a, b) }
        /// The line's end: a × b, or the last multiple of b that's 60 or less.
        public var N: Int { a * b <= 60 ? a * b : (60 / b) * b }
        /// Squares a number.
        public var U: Int { N <= 24 ? 2 : 1 }
        /// Hops of b to the line's end.
        public var hops: Int { N / b }
        /// The first multiple of a at or past v (where a's hops stop when v is tapped).
        public func aTo(_ v: Int) -> Int { v % a == 0 ? v : (v / a + 1) * a }
        /// What tapping the landing v says (nil: it's the LCM).
        public func tapped(_ v: Int) -> String? {
            if v == L { return nil }
            if v % a == 0 { return "\(v) works, but \(L) comes first." }
            let lo = v / a * a
            return "\(a)s go \(lo), \(lo + a): they jump over \(v)."
        }
        public var hopSay: String { "Hop by \(b)s to the end." }
        public var tapSay: String { "Tap the first \(b) that \(a) goes into." }
        public var writeSay: String { "Write how many \(a)s make \(L)." }
        public var why: String { "\(L) is the first number both counts land on." }
        /// "6, 12, 18" (the live readout of n hops of s).
        public static func list(_ n: Int, _ s: Int) -> String { (1...max(1, n)).map { String($0 * s) }.joined(separator: ", ") }
    }

    /// The web's generator: 2 ≤ a < b ≤ 12; a × b 60 or less when they share no factor (no easy start).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        var a = 2, b = 2
        repeat { a = Int.random(in: 2...12, using: &rng); b = Int.random(in: 2...12, using: &rng) }
        while a == b || (Fact6.lcm(a, b) == a * b && a * b > 60)
        return numbers(a: min(a, b), b: max(a, b))
    }

    static func shares(_ s: Parts) -> Bool { Fact6.gcd(s.a, s.b) > 1 }

    public static let spec = LessonSpec(id: "g6-lcm", title: "Least common multiple", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text("LCM("), .num(Double(s.a)), .text(","), .num(Double(s.b)), .text(")")] },
        idea: { _ in "The least common multiple is the first number both counts land on." },
        depends: ["g4-factors"],
        check: [CheckItem(0, when: { let s = Parts($0); return shares(s) && s.b % s.a != 0 }), CheckItem(0, when: { Parts($0).L == Parts($0).a * Parts($0).b }),
                CheckItem(0, when: { Parts($0).b % Parts($0).a == 0 }), CheckItem(0, when: { let s = Parts($0); return shares(s) && s.b % s.a != 0 })]) { n in
        let s = Parts(n)
        let ask = LessonStep(StepWords(say: s.hopSay, hint: "Each hop is \(s.b).", action: "Let’s find out"), picture: ["at": 0])
        let hop = LessonStep(StepWords(say: s.hopSay, hint: "Each hop is \(s.b). Hop to the line’s end.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.hops)], hint: "Each hop is \(s.b). Hop to the line’s end.",
                               explain: "\(s.hops) hops of \(s.b) reach \(s.N).",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.hopSay) }
                                   return Int(x.rounded()) >= s.hops ? .right : .wrong("Keep hopping to the end.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tapHint = "Check each landing: does \(s.a) go into it evenly?"
        let tap = LessonStep(StepWords(say: s.tapSay, hint: tapHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.L)],
                               known: s.L != s.a * s.b ? [(["x": Double(s.a * s.b)], "\(s.a * s.b) works, but \(s.L) comes first.")] : [],
                               hint: tapHint, explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.tapSay) }
                                   return s.tapped(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let count = "Count the hops under the line."
        let other = "Check with \(s.a), the smaller number: does it go in evenly?"
        let write = LessonStep(StepWords(say: s.writeSay, hint: count, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.L)), .op("÷"), .num(Double(s.a)), .op("="), .box("x")], expected: ["x": Double(s.L / s.a)],
                               known: s.L / s.b != s.L / s.a ? [(["x": Double(s.L / s.b)], other)] : [], hint: count, explain: s.why,
                               check: { v in
                                   let x = Fact6.int(v, "x")
                                   if x == s.L / s.a { return .right }
                                   return .wrong(x == s.L / s.b ? other : count)
                               }, incomplete: "Write the number in the box."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Count by the bigger number until the smaller one goes into it.", action: "Next problem"), picture: ["at": 4])
        return [ask, hop, tap, write, done]
    }
}

// MARK: - Factor out the GCF

/// Factor out the GCF (the web app's g6-gcf, 6.NS.4, 6.EE.3): A + B = g(m + n), m and n sharing no factor. One square a
/// number (two when both are 24 or less): two bars A and B squares long. Cut both with the ruler into the biggest pieces
/// that fit both (the handle sets one piece's length; each bar's end shows what's over), then write how many pieces each.
///
/// "at": 0 the question, 1 cut, 2 write, 3 done.
public enum Gcf6 {
    public static func numbers(g: Int, m: Int, n: Int) -> Numbers { ["g": Double(g), "m": Double(m), "n": Double(n)] }

    public struct Parts: Sendable {
        public let g: Int, m: Int, n: Int
        public init(_ x: Numbers) { g = Int((x["g"] ?? 6).rounded()); m = Int((x["m"] ?? 3).rounded()); n = Int((x["n"] ?? 5).rounded()) }
        public var A: Int { g * m }
        public var B: Int { g * n }
        public var U: Int { A <= 24 && B <= 24 ? 2 : 1 }
        public var short: Int { min(A, B) }
        public var long: Int { max(A, B) }
        /// The ruler cut at pieces of p: what it says (nil: the biggest that fit both).
        public func cut(_ p: Int) -> Verdict {
            if p <= 0 { return .soft("Drag the ruler first.") }
            if p == 1 { return .wrong("Pieces of 1 always fit. Find bigger ones.") }
            if A % p != 0 || B % p != 0 { let X = A % p != 0 ? A : B; return .wrong("\(X) has \(X % p) over.") }
            if p < g { return .wrong("Those fit. Bigger pieces fit too.") }
            return .right
        }
        public var cutSay: String { "Cut both bars into the biggest pieces that fit both." }
        public var writeSay: String { "Write how many \(g)s are in each bar." }
        public var why: String { "Both bars are made of \(g)s, so the \(g) is written once." }
        public var whole: String { "Divide each number by \(g). The answers go inside the parentheses." }
        public var subtracted: String { "Factoring out \(g) divides by it: \(A) ÷ \(g) and \(B) ÷ \(g)." }
    }

    /// The longest bar, in squares: past it the problem shows under 75% (call of 4 Nov: drop 9 × 9 = 81, don't shrink it).
    public static let longest = 72
    /// The web's generator: g 2–9; m and n 1–9, different, no shared factor; the first three all 5 or less. No bar is
    /// longer than `longest` (only g = 9 with a 9, 81, is dropped).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let top = index < 3 ? 5 : 9
        while true {
            var m = 1, n = 1
            repeat { m = Int.random(in: 1...top, using: &rng); n = Int.random(in: 1...top, using: &rng) } while m == n || Fact6.gcd(m, n) != 1
            let g = Int.random(in: 2...top, using: &rng), P = Parts(numbers(g: g, m: m, n: n))
            if P.long * P.U <= longest { return numbers(g: g, m: m, n: n) }
        }
    }

    public static let spec = LessonSpec(id: "g6-gcf", title: "Factor out the GCF", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.num(Double(s.A)), .op("+"), .num(Double(s.B))] },
        idea: { _ in "Both numbers share a factor, so it can be written once outside the parentheses." },
        depends: ["g4-factors", "g3-split"],
        check: [CheckItem(3, when: { [4, 6, 8, 9].contains(Parts($0).g) }), CheckItem(3, when: { Parts($0).m == 1 || Parts($0).n == 1 }), CheckItem(3), CheckItem(3)]) { x in
        let s = Parts(x)
        let ask = LessonStep(StepWords(say: s.cutSay, hint: "A piece that fits a bar leaves nothing over.", action: "Let’s find out"), picture: ["at": 0])
        let cutHint = "Try the smaller number’s factors, biggest first."
        let cut = LessonStep(StepWords(say: s.cutSay, hint: cutHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.g)], hint: cutHint, explain: "Pieces of \(s.g) fit both bars.",
                               check: { v in s.cut(Fact6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let count = "Count the pieces in each bar."
        let write = LessonStep(StepWords(say: s.writeSay, hint: count, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(s.A)), .op("+"), .num(Double(s.B)), .op("="), .num(Double(s.g)), .text("("), .box("m"), .op("+"), .box("n"), .text(")")],
                               expected: ["m": Double(s.m), "n": Double(s.n)],
                               known: [(["m": Double(s.A), "n": Double(s.B)], s.whole), (["m": Double(s.A - s.g), "n": Double(s.B - s.g)], s.subtracted)],
                               hint: count, explain: "\(s.A) ÷ \(s.g) = \(s.m) and \(s.B) ÷ \(s.g) = \(s.n), so \(s.A) + \(s.B) = \(s.g)(\(s.m) + \(s.n)).",
                               check: { v in
                                   let m = Fact6.int(v, "m"), n = Fact6.int(v, "n")
                                   if m == s.m && n == s.n { return .right }
                                   if m == s.A && n == s.B { return .wrong(s.whole) }
                                   if m == s.A - s.g && n == s.B - s.g { return .wrong(s.subtracted) }
                                   return .wrong(count)
                               }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: s.why, hint: "Find the biggest piece that fits both.", action: "Next problem"), picture: ["at": 3])
        return [ask, cut, write, done]
    }
}

// MARK: - Dividing fractions

/// Dividing fractions (the web app's g6-divide, 6.NS.1): a/b ÷ c/d, both proper and in lowest terms, bottoms 2–9. A
/// whole bar is the fractions family's length (`wholeLength`). a/b shaded on top, c/d striped under it. Pick whether more
/// than one c/d fits; lay c/d's along under the a/b (the last cut off at its end); cut both into the same small pieces;
/// then the school way: flip, multiply, write it as simply as it goes. From the 6th problem every third is the web's
/// ribbon story (index 5, 8, …), told in the pick's words.
///
/// "at": 0 the question, 1 pick, 2 lay, 3 cut, 4 flip, 5 multiply, 6 simplest, 7 done.
public enum DivideFrac6 {
    public static func numbers(a: Int, b: Int, c: Int, d: Int, story: Bool = false) -> Numbers {
        ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d), "story": story ? 1 : 0]
    }
    /// A whole bar's squares: the first of 48, 40, 42, 45, 44, 36 the bottoms' LCM divides; else twice the LCM up to 70;
    /// else the LCM.
    public static func wholeLength(_ b: Int, _ d: Int) -> Int {
        let l = Fact6.lcm(b, d)
        return [48, 40, 42, 45, 44, 36].first { $0 % l == 0 } ?? (2 * l <= 70 ? 2 * l : l)
    }
    /// S/L in lowest terms as a whole number and a fraction (the web's finalForm).
    public static func finalForm(_ S: Int, _ L: Int) -> (whole: Int, num: Int, den: Int) {
        let g = Fact6.gcd(S, L), n = S / g, d = L / g
        return (n / d, n % d, d)
    }

    public struct Parts: Sendable {
        public let a: Int, b: Int, c: Int, d: Int, story: Bool
        public init(_ x: Numbers) {
            a = Int((x["a"] ?? 2).rounded()); b = Int((x["b"] ?? 3).rounded()); c = Int((x["c"] ?? 1).rounded()); d = Int((x["d"] ?? 4).rounded())
            story = (x["story"] ?? 0) != 0
        }
        public var W: Int { wholeLength(b, d) }
        /// The two bars' shaded lengths, and the biggest piece both are cut into.
        public var Al: Int { a * W / b }
        public var Cl: Int { c * W / d }
        public var P: Int { Fact6.gcd(Al, Cl) }
        /// How many small pieces each holds.
        public var S1: Int { Al / P }
        public var L1: Int { Cl / P }
        /// The school way's product: S/L.
        public var S: Int { a * d }
        public var L: Int { b * c }
        public var F: (whole: Int, num: Int, den: Int) { finalForm(S, L) }
        public var more: Bool { S > L }
        /// Copies laid to reach the a/b's end (the last cut off when they don't fit exactly).
        public var copies: Int { (Al + Cl - 1) / Cl }
        public var partLast: Bool { Al % Cl != 0 }
        /// How many of the last copy's small pieces the a/b covers.
        public var covered: Int { (Al - (copies - 1) * Cl) / P }
        /// S/L is already as simple as it goes (proper, lowest terms): no simplest step.
        public var simplest: Bool { F.whole == 0 && F.den == L }
        /// The simplest step's boxes: a whole number, a fraction, or both.
        public var simpleBoxes: [String] { (F.whole > 0 ? ["w"] : []) + (F.num > 0 ? ["sn", "sd"] : []) }

        public var fa: String { "\(a)/\(b)" }
        public var fc: String { "\(c)/\(d)" }
        public var pickSay: String {
            story ? "You have \(fa) yard of ribbon. How many times does \(Fact6.aOrAn(c)) \(fc)-yard piece fit in it?" : "Pick how many \(fc)s fit in \(fa)."
        }
        public var picked: String { "\(fc) is \(Cl) squares, \(fa) is \(Al): \(more ? "more" : "less") than one fits." }
        public var laySay: String { "Lay \(fc)s along the \(fa)." }
        public var past: String { "That’s past \(fa)." }
        public var cutSay: String { "Cut both bars into the same small pieces." }
        /// The ruler cut at pieces of p squares: what it says (nil: the biggest pieces that fit both).
        public func cut(_ p: Int) -> Verdict {
            if p <= 0 { return .soft("Drag the ruler first.") }
            if Al % p != 0 { return .wrong("\(fa) has \(Al % p) square\(Al % p == 1 ? "" : "s") over.") }
            if Cl % p != 0 { return .wrong("\(fc) has \(Cl % p) square\(Cl % p == 1 ? "" : "s") over.") }
            if p < P { return .wrong("That works. Can the pieces be bigger?") }
            return .right
        }
        public var flipSay: String { "Flip \(fc) and multiply." }
        public var multSay: String { "Multiply the tops and the bottoms." }
        public var simpSay: String { "Write it as simply as you can." }
        public var why: String {
            let fs = "\(F.num)/\(F.den)"
            if F.whole > 0 && F.num > 0 { return "\(F.whole) whole \(fc)\(F.whole == 1 ? " fits" : "s fit"), and \(fs) of another." }
            if F.whole > 0 { return "\(F.whole) whole \(fc)s fit." }
            return "\(fs) of \(Fact6.aOrAn(c)) \(fc) fits."
        }
        /// The simplest step's typed values: what they say (nil: right).
        public func simplified(_ v: [String: Double]) -> Verdict {
            let w = Fact6.int(v, "w", 0), n = Fact6.int(v, "sn", 0), dd = v["sd"].map { Int($0.rounded()) }
            if dd == 0 { return .wrong("The bottom can't be 0.") }
            let den = dd ?? 1
            if (w * den + n) * L != S * den { return .wrong("That’s not the same amount as \(S)/\(L).") }
            if let dd, n >= dd { return .wrong("Same amount. Take the whole \(dd)s out of \(n) first.") }
            if let dd, n > 0, Fact6.gcd(n, dd) > 1 { return .wrong("Same amount. Both \(n) and \(dd) still divide by \(Fact6.gcd(n, dd)).") }
            return .right
        }
    }

    /// The web's generator: bottoms 2–9, proper fractions in lowest terms, never equal; the first three divide by a unit
    /// fraction that fits more than once. Every third from the 6th (index 5, 8, …) is told as the ribbon story.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        func top(_ den: Int) -> Int { var x = 1; repeat { x = Int.random(in: 1...(den - 1), using: &rng) } while Fact6.gcd(x, den) != 1; return x }
        while true {
            let b = Int.random(in: 2...9, using: &rng), d = Int.random(in: 2...9, using: &rng)
            let a = top(b), c = index < 3 ? 1 : top(d)
            if a * d == b * c || (index < 3 && a * d <= b) { continue }
            return numbers(a: a, b: b, c: c, d: d, story: index >= 3 && index % 3 == 2)
        }
    }

    public static let spec = LessonSpec(id: "g6-divide", title: "Dividing fractions", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.frac(.num(Double(s.a)), .num(Double(s.b))), .op("÷"), .frac(.num(Double(s.c)), .num(Double(s.d)))] },
        idea: { _ in "Dividing asks how many of the second amount fit into the first." },
        depends: ["g5-unitdiv", "g5-multfrac"],
        check: [CheckItem(0), CheckItem(3, when: { let s = Parts($0); return s.c > 1 && s.more && !s.story }),
                CheckItem(3, when: { let s = Parts($0); return !s.more && !s.story }), CheckItem(5, when: { Parts($0).more })]) { x in
        let s = Parts(x)
        let sizeHint = "Which is longer, \(s.fa) or \(s.fc)?"
        let ask = LessonStep(StepWords(say: s.pickSay, hint: sizeHint, action: "Let’s find out"), picture: ["at": 0])
        let pick = LessonStep(StepWords(say: s.pickSay, hint: sizeHint, action: "Check"),
            answer: AnswerTask(prompt: [], expected: ["c": s.more ? 0 : 1], hint: sizeHint, explain: s.picked,
                               check: { v in Fact6.int(v, "c") == (s.more ? 0 : 1) ? .right : .wrong(s.picked) },
                               choices: ["More than 1", "Less than 1"]),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let lay = LessonStep(StepWords(say: s.laySay, hint: "Lay them end to end to the \(s.fa)’s end.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.copies)], hint: "Lay them end to end to the \(s.fa)’s end.",
                               explain: s.partLast ? "\(s.copies - 1) whole and part of one reach the end." : "\(s.copies) reach the end.",
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.laySay) }
                                   let k = Int(x.rounded())
                                   return k == s.copies ? .right : k > s.copies ? .wrong(s.past) : .soft(s.laySay)
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let cutHint = "Pieces that fit both bars leave nothing over."
        let cut = LessonStep(StepWords(say: s.cutSay, hint: cutHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.P)], hint: cutHint, explain: "\(s.S1) pieces ÷ \(s.L1) pieces",
                               check: { v in s.cut(Fact6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let head: MathLine = [.frac(.num(Double(s.a)), .num(Double(s.b))), .op("÷"), .frac(.num(Double(s.c)), .num(Double(s.d))), .op("="),
                              .frac(.num(Double(s.a)), .num(Double(s.b))), .op("×")]
        let flipMiss = "Swap them: \(s.d) is the new top, \(s.c) the new bottom."
        let flip = LessonStep(StepWords(say: s.flipSay, hint: flipMiss, action: "Check"),
            answer: AnswerTask(prompt: head + [.frac(.box("fn"), .box("fd"))], expected: ["fn": Double(s.d), "fd": Double(s.c)],
                               known: [(["fn": Double(s.c), "fd": Double(s.d)], "That’s the same fraction. Swap the top and the bottom."),
                                       (["fn": Double(s.b), "fd": Double(s.a)], "Keep the first fraction. Flip the second one.")],
                               hint: flipMiss, explain: "\(s.fc) flipped is \(s.d)/\(s.c).",
                               check: { v in
                                   let n = Fact6.int(v, "fn"), d = Fact6.int(v, "fd")
                                   if n == s.d && d == s.c { return .right }
                                   if n == s.c && d == s.d { return .wrong("That’s the same fraction. Swap the top and the bottom.") }
                                   if n == s.b && d == s.a { return .wrong("Keep the first fraction. Flip the second one.") }
                                   return .wrong(flipMiss)
                               }),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let multMiss = "Top: \(s.a) × \(s.d). Bottom: \(s.b) × \(s.c)."
        let unflipped = "Multiply by the flipped fraction, \(s.d)/\(s.c)."
        let mult = LessonStep(StepWords(say: s.multSay, hint: multMiss, action: "Check"),
            answer: AnswerTask(prompt: head + [.frac(.num(Double(s.d)), .num(Double(s.c))), .op("="), .frac(.box("mn"), .box("md"))],
                               expected: ["mn": Double(s.S), "md": Double(s.L)],
                               known: [(["mn": Double(s.a * s.c), "md": Double(s.b * s.d)], unflipped)],
                               hint: multMiss, explain: "\(s.a) × \(s.d) = \(s.S) and \(s.b) × \(s.c) = \(s.L).",
                               check: { v in
                                   let n = Fact6.int(v, "mn"), d = Fact6.int(v, "md")
                                   if n == s.S && d == s.L { return .right }
                                   return .wrong(n == s.a * s.c && d == s.b * s.d ? unflipped : multMiss)
                               }),
            picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
        var steps = [ask, pick, lay, cut, flip, mult]
        if !s.simplest {
            let F = s.F
            let simpHint = s.S % s.L == 0 ? "\(s.S) ÷ \(s.L) = \(s.S / s.L) exactly, so it’s a whole number."
                : s.S >= s.L ? "\(s.S) ÷ \(s.L) = \(s.S / s.L) remainder \(s.S % s.L). The remainder is the top."
                : "Both \(s.S) and \(s.L) divide by \(Fact6.gcd(s.S, s.L))."
            var boxes: MathLine = []
            if F.whole > 0 { boxes.append(.box("w")) }
            if F.num > 0 { boxes.append(.frac(.box("sn"), .box("sd"))) }
            var want: [String: Double] = [:]
            if F.whole > 0 { want["w"] = Double(F.whole) }
            if F.num > 0 { want["sn"] = Double(F.num); want["sd"] = Double(F.den) }
            steps.append(LessonStep(StepWords(say: s.simpSay, hint: simpHint, action: "Check"),
                answer: AnswerTask(prompt: [.frac(.num(Double(s.S)), .num(Double(s.L))), .op("=")] + boxes, expected: want, hint: simpHint, explain: s.why,
                                   check: { v in s.simplified(v) }),
                picture: ["at": 6], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "Dividing asks how many fit.", action: "Next problem"), picture: ["at": 7]))
        return steps
    }
}
