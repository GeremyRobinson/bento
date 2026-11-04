import Foundation

/// What 4th grade's Mixed numbers chapter shares (design/grade4.md chapter 5, the preview design/prototype/grade4-ch5.html):
/// bars half as long as chapter 4's, so a mixed number stands in one column and two numbers stand side by side. A whole
/// is 24 squares (20 for fifths, 21 for sevenths); a whole bar, all shaded, is 2 squares tall (it has no pieces to count)
/// and grows to 4 when it's opened into pieces.
public enum Mixed4 {
    /// A whole bar's length in squares for pieces of 1/d: 24, 20 for fifths, 21 for sevenths.
    public static func whole(_ d: Int) -> Int { [24, 20, 21].first { $0 % max(1, d) == 0 } ?? 2 * max(1, d) }
    /// "1 whole", "3 wholes".
    public static func wholes(_ w: Int) -> String { "\(w) \(w == 1 ? "whole" : "wholes")" }
    /// A mixed number as words write it: "4 2/5", "3", "2/5".
    public static func text(_ w: Int, _ n: Int, _ d: Int) -> String {
        w > 0 && n > 0 ? "\(w) \(n)/\(d)" : n > 0 ? "\(n)/\(d)" : "\(w)"
    }
    static func mixed(_ w: Int, _ n: Int, _ d: Int) -> MathLine { [.num(Double(w)), .frac(.num(Double(n)), .num(Double(d)))] }
    static func int(_ v: [String: Double], _ k: String) -> Int { Int((v[k] ?? -1).rounded()) }
}

/// Adding mixed numbers (the web app's g4-mixed, 4.NF.3c, 4.NF.3d): w1 n1/d + w2 n2/d.
///
/// On the paper: w1 whole bars and an n1 bar on the left; w2 and n2, striped, on the right, each named under its column.
/// Slide the right's wholes under the left's; slide its pieces into the left's part bar (past its end they spill into a
/// new bar); a full bar is tapped and closes into a whole. Then the problem is written with the answer's boxes.
///
/// Every step's picture has "at": 0 the question, 1 the wholes' slide, 2 the pieces' slide, 3 the trade (only with one),
/// 4 write, 5 done.
public enum AddMixed {
    public static func numbers(w1: Int, n1: Int, w2: Int, n2: Int, d: Int) -> Numbers {
        ["w1": Double(w1), "n1": Double(n1), "w2": Double(w2), "n2": Double(n2), "d": Double(d)]
    }

    public struct Parts: Sendable {
        public let w1: Int, n1: Int, w2: Int, n2: Int, d: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            w1 = i("w1", 2); n1 = i("n1", 3); w2 = i("w2", 1); n2 = i("n2", 4); d = max(2, i("d", 5))
        }
        /// The pieces together, and past a whole: a trade.
        public var S: Int { n1 + n2 }
        public var trade: Bool { S > d }
        /// The pieces left after the trade.
        public var R: Int { trade ? S - d : S }
        /// The wholes together, and the answer's wholes.
        public var Wt: Int { w1 + w2 }
        public var total: Int { trade ? Wt + 1 : Wt }
        public var W: Int { Mixed4.whole(d) }
        public var pw: Int { W / d }
        public var name: String { Fractions4.piece(d) }
        public var text: String {
            "Mia walks \(w1) \(n1)/\(d) miles on Monday and \(w2) \(n2)/\(d) miles on Tuesday. How far does she walk in all?"
        }
    }

    /// The web's generator: d 3, 4, 5, 6 or 8; wholes 1–3 each; a trade half the time for index < 3, then three times in
    /// four; never exactly a whole of pieces; the answer's fraction in lowest terms.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let trade = Double.random(in: 0..<1, using: &rng) < (i < 3 ? 0.5 : 0.75)
        while true {
            let d = Fractions4.pick([3, 4, 5, 6, 8], &rng)
            let n1 = Int.random(in: 1...(d - 1), using: &rng), n2 = Int.random(in: 1...(d - 1), using: &rng), S = n1 + n2
            if S == d || (S > d) != trade || gcd(S % d, d) != 1 { continue }
            return numbers(w1: Int.random(in: 1...3, using: &rng), n1: n1, w2: Int.random(in: 1...3, using: &rng), n2: n2, d: d)
        }
    }

    public static let spec = LessonSpec(id: "g4-mixed", title: "Adding mixed numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return Mixed4.mixed(s.w1, s.n1, s.d) + [.op("+")] + Mixed4.mixed(s.w2, s.n2, s.d) },
        idea: { _ in "Wholes and pieces are different sizes, so wholes go with wholes and pieces go with pieces." },
        story: { Parts($0).text }, storyOp: { _ in "+" },
        depends: ["g4-likefrac"],
        check: [CheckItem(0, when: { !Parts($0).trade }), CheckItem(3, when: { Parts($0).trade }),
                CheckItem(3, when: { let s = Parts($0); return s.trade && s.d >= 6 }), CheckItem(3, story: true)]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), d = s.d, name = s.name, R = s.R, Wt = s.Wt, total = s.total
        let say1 = "Put the wholes together. Slide the striped wholes under the left ones."
        let hint1 = "Only the whole numbers: \(s.w1) + \(s.w2)."
        let wholes = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint1,
                               explain: "\(Mixed4.wholes(s.w1)) and \(Mixed4.wholes(s.w2)) make \(Mixed4.wholes(Wt)).",
                               check: { v in (v["s"] ?? 0) == 1 ? .right : .soft("Put them under the wholes on the left.") }, byHand: true),
            picture: ["at": 1], onMiss: ["target": 1])
        let say2 = "Now put the \(name) together. Slide the striped \(name) into the left bar."
        let hint2 = "They go after the shaded \(name)."
        let pieces = LessonStep(StepWords(say: say2, hint: hint2, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint2,
                               explain: "\(s.n1) + \(s.n2) = \(Fractions4.pieces(s.S, d)).",
                               check: { v in (v["s"] ?? 0) == 1 ? .right : .soft("Slide them into the left bar.") }, byHand: true),
            picture: ["at": 2], onMiss: ["target": 1])
        // the trade: the full bar tapped (1); the spill bar (−1) or a whole (−2) is a miss
        let say3 = "\(d) \(name) fill a bar, so trade them for 1 whole. Tap the full bar."
        let hint3 = "\(d)/\(d) is 1 whole."
        let trade = LessonStep(StepWords(say: say3, hint: hint3, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": 1], hint: hint3,
                               explain: "\(d) \(name) = 1 whole, so \(s.S)/\(d) is 1 whole and \(R)/\(d).",
                               check: { v in
                                   switch Mixed4.int(v, "t") {
                                   case 1: return .right
                                   case -2: return .wrong("That’s a whole already. Tap the full bar.")
                                   default: return .wrong("That bar isn’t full. Tap the full bar.")
                                   }
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1])
        // write: the wholes, then the pieces (the bottom stays d)
        let say4 = (s.trade ? "Add the new whole to the \(Mixed4.wholes(Wt))." : "Put the wholes and the pieces back together.")
            + " Write the wholes, then the pieces."
        let count = "Count the \(name) in the last bar."
        let write = LessonStep(StepWords(say: say4, hint: s.trade ? "The wholes you put together, and the 1 you made." : "The wholes, then the pieces.", action: "Check"),
            answer: AnswerTask(prompt: Mixed4.mixed(s.w1, s.n1, d) + [.op("+")] + Mixed4.mixed(s.w2, s.n2, d) + [.op("="), .box("W"), .frac(.box("N"), .num(Double(d)))],
                               expected: ["W": Double(total), "N": Double(R)],
                               hint: s.trade ? "The wholes you put together, and the 1 you made." : "The wholes, then the pieces.",
                               explain: s.trade ? "\(Mixed4.wholes(Wt)) and 1 more make \(Mixed4.wholes(total)), with \(R)/\(d) left: \(total) \(R)/\(d)."
                                   : "\(Mixed4.wholes(Wt)) and \(R)/\(d): \(total) \(R)/\(d).",
                               check: { v in
                                   let w = Mixed4.int(v, "W"), n = Mixed4.int(v, "N")
                                   if w == total && n == R { return .right }
                                   if s.trade {
                                       if w == Wt && n == s.S { return .wrong("\(s.S)/\(d) is more than 1 whole. Trade \(d) \(name) for 1 whole first.") }
                                       if w == Wt && n == R { return .wrong("The \(d) \(name) you traded made 1 more whole. Add it: \(Wt) + 1.") }
                                       if w == total && n == s.S { return .wrong("\(d) of the pieces became the whole, so take \(d) away: \(s.S) − \(d) = \(R).") }
                                   } else if w == Wt + 1 && n == R {
                                       return .wrong("\(s.S)/\(d) is less than 1, so there’s no whole to trade.")
                                   }
                                   let times = s.w1 * s.w2
                                   if times != Wt && (w == times || w == times + (s.trade ? 1 : 0)) { return .wrong("This is adding: \(s.w1) + \(s.w2).") }
                                   return .wrong(w != total ? "Count the whole bars on the left." : count)
                               }, incomplete: "Fill in both boxes."),
            picture: ["at": 4])
        let why = s.trade ? "\(d) \(name) make a whole, so \(Wt) wholes become \(total)." : "Wholes go with wholes, and pieces with pieces."
        return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]),
                wholes, pieces] + (s.trade ? [trade] : []) + [write,
                LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 5])]
    }
}

/// Subtracting mixed numbers (g4-mixedsub, 4.NF.3c, 4.NF.3d; new, Adding mixed numbers' mirror): w1 n1/d − w2 n2/d.
///
/// On the paper: the first number's bars on the left, the second's, striped, on the right. Slide the striped pieces onto
/// the shaded ones from the right: each one covered is crossed out. Too few: the slide stops; a whole is tapped and grows
/// into a bar of its d pieces, and the slide goes on. Then the striped wholes slide onto the left's wholes.
///
/// Every step's picture has "at": 1 the pieces' slide, 2 open a whole (only when one must be), 3 the slide again, 4 the
/// wholes' slide, 5 write, 6 done. The hands keep "opened" when a whole is opened.
public enum SubtractMixed {
    public static func numbers(w1: Int, n1: Int, w2: Int, n2: Int, d: Int, story: Int = 0) -> Numbers {
        ["w1": Double(w1), "n1": Double(n1), "w2": Double(w2), "n2": Double(n2), "d": Double(d), "story": Double(story)]
    }

    public struct Parts: Sendable {
        public let w1: Int, n1: Int, w2: Int, n2: Int, d: Int, story: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            w1 = i("w1", 3); n1 = i("n1", 2); w2 = i("w2", 1); n2 = i("n2", 4); d = max(2, i("d", 5)); story = i("story", 0)
        }
        /// Too few pieces: a whole must be opened.
        public var need: Bool { n1 < n2 }
        /// The pieces and the wholes left.
        public var R: Int { need ? n1 + d - n2 : n1 - n2 }
        public var Wa: Int { w1 - w2 - (need ? 1 : 0) }
        public var W: Int { Mixed4.whole(d) }
        public var pw: Int { W / d }
        public var name: String { Fractions4.piece(d) }
        public var text: String {
            let a = "\(w1) \(n1)/\(d)", b = "\(w2) \(n2)/\(d)"
            switch story % 3 {
            case 0: return "A ribbon is \(a) m long. Mia cuts off \(b) m. How much ribbon is left?"
            case 1: return "A jug holds \(a) L of juice. Leo pours out \(b) L. How much juice is left?"
            default: return "A trail is \(a) miles long. Ana has walked \(b) miles. How far does she still have to walk?"
            }
        }
    }

    /// d 3, 4, 5, 6 or 8; w1 2–4, w2 1 to w1 − 1; n1 and n2 1 to d − 1, never equal; a whole to open half the time for
    /// index < 3, then three times in four; the answer's fraction in lowest terms.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let open = Double.random(in: 0..<1, using: &rng) < (i < 3 ? 0.5 : 0.75)
        while true {
            let d = Fractions4.pick([3, 4, 5, 6, 8], &rng)
            let n1 = Int.random(in: 1...(d - 1), using: &rng), n2 = Int.random(in: 1...(d - 1), using: &rng)
            if n1 == n2 || (n1 < n2) != open || gcd(open ? n1 + d - n2 : n1 - n2, d) != 1 { continue }
            let w1 = Int.random(in: 2...4, using: &rng)
            return numbers(w1: w1, n1: n1, w2: Int.random(in: 1...(w1 - 1), using: &rng), n2: n2, d: d, story: Int.random(in: 0...2, using: &rng))
        }
    }

    public static let spec = LessonSpec(id: "g4-mixedsub", title: "Subtracting mixed numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return Mixed4.mixed(s.w1, s.n1, s.d) + [.op("−")] + Mixed4.mixed(s.w2, s.n2, s.d) },
        idea: { _ in "A whole is pieces too, so it can be opened to take away." },
        story: { Parts($0).text }, storyOp: { _ in "−" },
        depends: ["g4-mixed", "g4-likesub"],
        check: [CheckItem(0, when: { !Parts($0).need }), CheckItem(3, when: { Parts($0).need }),
                CheckItem(3, when: { let s = Parts($0); return s.need && s.d >= 6 }), CheckItem(3, story: true)]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), d = s.d, name = s.name, R = s.R, Wa = s.Wa
        let slide = "Slide the striped \(name) onto the shaded ones."
        // the first slide: with enough pieces it takes them away (1); with too few it stops (2), or a whole tapped first
        // opens it (3); a whole tapped with enough pieces is a miss (−1)
        let say1 = "Take away the \(name) first. " + slide
        let hint1 = "Each striped piece takes away a shaded one."
        let take = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": s.need ? 2 : 1], hint: hint1,
                               explain: s.need ? "\(Fractions4.pieces(s.n1, d)) can’t take away \(s.n2)." : "\(Fractions4.pieces(s.n2, d)) taken away: \(R) left.",
                               check: { v in
                                   switch Mixed4.int(v, "s") {
                                   case 1, 2, 3: return .right
                                   case -1: return .wrong("There are enough \(name). Take away first.")
                                   default: return .soft("Slide them onto the shaded pieces.")
                                   }
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["target": 1])
        let say2 = "\(Fractions4.pieces(s.n1, d)) can’t take away \(s.n2). Open a whole. Tap a whole bar."
        let hint2 = "A whole is \(d) \(name)."
        let open = LessonStep(StepWords(say: say2, hint: hint2, action: "Check"),
            answer: AnswerTask(prompt: [.box("o")], expected: ["o": 1], hint: hint2,
                               explain: "A whole is \(d) \(name): \(s.n1) + \(d) = \(s.n1 + d).",
                               check: { v in Mixed4.int(v, "o") == 1 ? .right : .soft("Tap a whole bar.") }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1])
        let say3 = "Now take away the \(name). " + slide
        let take2 = LessonStep(StepWords(say: say3, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint1,
                               explain: "\(Fractions4.pieces(s.n1 + d, d)) take away \(s.n2): \(R) left.",
                               check: { v in Mixed4.int(v, "s") == 1 ? .right : .soft("Slide them onto the shaded pieces.") }, byHand: true),
            picture: ["at": 3], onMiss: ["target": 1])
        let say4 = "Now take away the wholes. Slide the striped wholes onto the shaded ones."
        let hint4 = "Each striped whole takes away a shaded one."
        let wholes = LessonStep(StepWords(say: say4, hint: hint4, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint4,
                               explain: "\(Mixed4.wholes(s.w1 - (s.need ? 1 : 0))) take away \(s.w2): \(Wa) left.",
                               check: { v in Mixed4.int(v, "s") == 1 ? .right : .soft("Slide them onto the shaded wholes.") }, byHand: true),
            picture: ["at": 4], onMiss: ["target": 1])
        // write what's left: the wholes (none left: only the fraction), then the pieces
        let first = s.need ? Mixed4.mixed(s.w1 - 1, s.n1 + d, d) : Mixed4.mixed(s.w1, s.n1, d)
        let ans: MathLine = (Wa > 0 ? [.box("W")] : []) + [.frac(.box("N"), .num(Double(d)))]
        let count = "Count what isn’t crossed out."
        let write = LessonStep(StepWords(say: "Write what’s left. " + count, hint: count, action: "Check"),
            answer: AnswerTask(prompt: first + [.op("−")] + Mixed4.mixed(s.w2, s.n2, d) + [.op("=")] + ans,
                               expected: Wa > 0 ? ["W": Double(Wa), "N": Double(R)] : ["N": Double(R)], hint: count,
                               explain: "\(Mixed4.text(Wa, R, d)) isn’t crossed out.",
                               check: { v in
                                   let w = Wa > 0 ? Mixed4.int(v, "W") : 0, n = Mixed4.int(v, "N")
                                   if w == Wa && n == R { return .right }
                                   if s.need {
                                       if w == s.w1 - s.w2 && n == s.n2 - s.n1 { return .wrong("You can’t take \(s.n2) \(name) from \(s.n1). Open a whole first.") }
                                       if w == s.w1 - s.w2 && n == R { return .wrong("One whole became \(name), so \(s.w1) wholes are \(s.w1 - 1) now.") }
                                   }
                                   return .wrong(w != Wa ? "Count the wholes that aren’t crossed out." : "Count the \(name) that aren’t crossed out.")
                               }, incomplete: Wa > 0 ? "Fill in both boxes." : "Type the number in the box."),
            picture: ["at": 5])
        let why = s.need ? "A whole is \(d) \(name), so it can be opened to take away." : "Wholes from wholes, pieces from pieces."
        return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]), take]
            + (s.need ? [open, take2] : []) + [wholes, write,
               LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 6])]
    }
}

/// Fraction times a whole number (the web app's g4-fracwhole, 4.NF.4): W × n/d.
///
/// On the paper: W bars, each a whole with n of its d pieces shaded (the groups take turns plain and striped), braced and
/// named W × n/d; an empty answer bar on the right. Slide the groups over: their pieces pack into the answer bar group
/// after group, spilling into a new bar when one fills. Write the top (W × n/d = S × 1/d = S/d). When it can be written
/// another way: tap each full bar (it closes into a whole) or the last bar (its cuts change to the simplest pieces), and
/// write it.
///
/// Every step's picture has "at": 1 the slide, 2 the top, 3 the taps (only when it can be written another way), 4 write,
/// 5 done.
public enum FracTimesWhole {
    public static func numbers(n: Int, d: Int, W: Int) -> Numbers { ["n": Double(n), "d": Double(d), "W": Double(W)] }

    public struct Parts: Sendable {
        public let n: Int, d: Int, W: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            n = i("n", 2); d = max(2, i("d", 5)); W = max(1, i("W", 3))
        }
        /// The pieces in all, the answer bars they fill, the full ones and what's in the last.
        public var S: Int { W * n }
        public var bars: Int { (S + d - 1) / d }
        public var full: Int { S / d }
        public var rem: Int { S % d }
        public var g: Int { gcd(S, d) }
        /// The answer as simple as it gets: whole, top, bottom.
        public var whole: Int { S / d }
        public var top: Int { rem > 0 ? rem / gcd(rem, d) : 0 }
        public var bottom: Int { rem > 0 ? d / gcd(rem, d) : 1 }
        /// The last bar's cuts change to bigger pieces (S/d below 1 that simplifies, or a remainder that does).
        public var recut: Bool { (S < d && g > 1) || (S > d && rem > 0 && gcd(rem, d) > 1) }
        /// It can be written another way: a step of taps, then one of writing.
        public var more: Bool { S >= d || g > 1 }
        public var Wb: Int { Mixed4.whole(d) }
        public var pw: Int { Wb / d }
        public var name: String { Fractions4.piece(d) }
        public var text: String { "Each muffin uses \(n)/\(d) cup of milk. How much milk do \(W) muffins use?" }
        /// The boxes the answer is written in: a whole number, a fraction, or both.
        public var boxes: [String] { rem == 0 ? ["W"] : S > d ? ["W", "N", "D"] : ["N", "D"] }
    }

    /// The web's generator: d 3–8, n in lowest terms, W 2–6.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let d = Int.random(in: 3...8, using: &rng)
        var n: Int
        repeat { n = Int.random(in: 1...(d - 1), using: &rng) } while gcd(n, d) != 1
        return numbers(n: n, d: d, W: Int.random(in: 2...6, using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-fracwhole", title: "Fraction times a whole number", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return [.num(Double(s.W)), .op("×"), .frac(.num(Double(s.n)), .num(Double(s.d)))] },
        idea: { _ in "Times a whole number means that many groups of the same pieces, so the pieces stay the same size." },
        story: { Parts($0).text }, storyOp: { _ in "×" },
        depends: ["g4-likefrac", "g3-facts"],
        check: [CheckItem(0, when: { let s = Parts($0); return s.S < s.d }), CheckItem(0, when: { let s = Parts($0); return s.S > s.d && s.rem != 0 }),
                CheckItem(0, when: { Parts($0).rem == 0 }), CheckItem(0, story: true)]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), d = s.d, n = s.n, W = s.W, S = s.S, name = s.name
        let say1 = "Put all the groups together. Slide the bars into the answer bar."
        let hint1 = "Every group’s pieces go in the answer bar."
        let slide = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint1,
                               explain: "\(W) groups of \(Fractions4.pieces(n, d)) make \(Fractions4.pieces(S, d)).",
                               check: { v in Mixed4.int(v, "s") == 1 ? .right : .soft("Put them in the answer bar.") }, byHand: true),
            picture: ["at": 1], onMiss: ["target": 1])
        let count = "Count the \(name) in the answer bar\(s.bars > 1 ? "s" : "")."
        let top = LessonStep(StepWords(say: "How many \(name) in all? The pieces stay the same size.", hint: count, action: "Check"),
            answer: AnswerTask(prompt: [.num(Double(W)), .op("×"), .frac(.num(Double(n)), .num(Double(d))), .op("="), .frac(.box("T"), .num(Double(d)))],
                               expected: ["T": Double(S)], hint: count,
                               explain: "\(W) groups of \(Fractions4.pieces(n, d)): \(Fractions4.pieces(S, d)).",
                               check: { v in
                                   let t = Mixed4.int(v, "T")
                                   if t == S { return .right }
                                   if t == W * d && W * d != S { return .wrong("The pieces stay the same size. Only the number of pieces changes.") }
                                   return .wrong(count)
                               }, incomplete: "Type the number in the box."),
            picture: ["at": 2])
        // the taps: every full bar closes into a whole, and a last bar that simplifies changes its cuts (1 once all are
        // done); a bar that isn't full is a miss (−1)
        let g = s.g, rem = s.rem
        let tapSay: String
        if S >= d {
            let then = s.recut ? " Then simplify the \(rem)/\(d)." : ""
            tapSay = "Every \(d) \(name) make one whole.\(then) " + (s.recut ? "Tap each full bar, then the last bar." : s.full > 1 ? "Tap each full bar." : "Tap the full bar.")
        } else {
            tapSay = "Divide the top and the bottom by \(g). Tap the answer bar: \(g) \(name) make 1 \(Fractions4.piece(d / g, false))."
        }
        let tapHint = S >= d ? "\(d)/\(d) is 1 whole." : "\(g) \(name) make 1 \(Fractions4.piece(d / g, false))."
        let tap = LessonStep(StepWords(say: tapSay, hint: tapHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": 1], hint: tapHint,
                               explain: S >= d ? "\(d) \(name) are 1 whole." : "\(S)/\(d) = \(S / g)/\(d / g).",
                               check: { v in Mixed4.int(v, "t") == 1 ? .right : .wrong(S >= d ? "That bar isn’t full. Tap a full bar." : "Tap the answer bar.") },
                               byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1])
        // write it another way: a whole number, a mixed number, or bigger pieces
        let writeSay = rem == 0 ? "Write it as a whole number." : S > d ? "Write it as a mixed number." : "Write it with the bigger pieces."
        let boxes = s.boxes
        var ans: MathLine = []
        if boxes.contains("W") { ans.append(.box("W")) }
        if boxes.contains("N") { ans.append(.frac(.box("N"), .box("D"))) }
        var expected: [String: Double] = ["W": Double(s.whole), "N": Double(s.top), "D": Double(s.bottom)]
        expected = expected.filter { boxes.contains($0.key) }
        let writeHint = S > d ? "How many whole \(d)s fit into \(S)? What’s left over goes on top." : "Divide the top and the bottom by \(g)."
        let write = LessonStep(StepWords(say: writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(S)), .num(Double(d))), .op("=")] + ans, expected: expected, hint: writeHint,
                               explain: "\(S)/\(d) = \(Mixed4.text(s.whole, s.top, s.bottom)).",
                               check: { v in
                                   let w = boxes.contains("W") ? Mixed4.int(v, "W") : 0
                                   let nn = boxes.contains("N") ? Mixed4.int(v, "N") : 0, dd = boxes.contains("D") ? Mixed4.int(v, "D") : 1
                                   if dd == 0 { return .wrong("The bottom can’t be 0.") }
                                   if (w * dd + nn) * d != S * dd {
                                       return .wrong(S > d ? "That’s not equal to \(S)/\(d). How many whole \(d)s fit into \(S)? That’s the whole number.\(rem > 0 ? " What’s left over goes on top." : "")"
                                           : "That’s not equal to \(S)/\(d). Divide the top and the bottom by the same number.")
                                   }
                                   if boxes.contains("N") && nn >= dd { return .wrong("That’s the right amount. Now write it as a mixed number. How many whole \(dd)s fit into \(nn)?") }
                                   if boxes.contains("N") && nn > 0 && gcd(nn, dd) > 1 { return .wrong("Same amount. \(nn)/\(dd) can still be simplified. Both \(nn) and \(dd) divide by \(gcd(nn, dd)).") }
                                   return .right
                               }, incomplete: boxes.count == 1 ? "Type the number in the box." : "Fill in every box."),
            picture: ["at": 4])
        let why = "\(W) groups of \(Fractions4.pieces(n, d)) make \(Fractions4.pieces(S, d)). The pieces stay \(name)."
        let first = LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0])
        return [first, slide, top] + (s.more ? [tap, write] : []) + [LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 5])]
    }
}
