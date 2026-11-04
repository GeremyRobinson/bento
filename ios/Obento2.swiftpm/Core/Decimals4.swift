import Foundation

/// What 4th grade's Decimals chapter shares (design/grade4.md chapter 6, the preview design/prototype/grade4-ch6.html):
/// a whole is a square 20 × 20 squares, so a tenth is a column 2 × 20 and a hundredth 2 × 2; lines as in Rounding
/// decimals, 50 squares in ten blocks of 5. A decimal is one tight number ("0.62").
public enum Dec4 {
    /// "1 hundredth", "45 hundredths".
    public static func hund(_ n: Int) -> String { "\(n) \(n == 1 ? "hundredth" : "hundredths")" }
    /// "1 tenth", "7 tenths".
    public static func tenths(_ n: Int) -> String { "\(n) \(n == 1 ? "tenth" : "tenths")" }
    static func pad2(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
    /// A number of hundredths as a decimal: 0.6, 0.64, 0.05, 1.45, 1.
    public static func text(_ H: Int) -> String {
        let w = H / 100, h = H % 100
        return h == 0 ? "\(w)" : h % 10 == 0 ? "\(w).\(h / 10)" : "\(w).\(pad2(h))"
    }
    /// A decimal written with one or two places after the point: 0.5, 0.45, 0.50, 1.07.
    public static func written(_ w: Int, _ h: Int, _ places: Int) -> String { "\(w)." + (places == 1 ? "\(h / 10)" : pad2(h)) }
    static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    static func int(_ v: [String: Double], _ k: String) -> Int { Int((v[k] ?? -99).rounded()) }
}

/// Tenths and hundredths (the web app's g4-dec, 4.NF.5, 4.NF.6): a/10 + b/100, written as a decimal.
///
/// On the paper: two wholes side by side, 4 squares apart: a/10 as shaded tenths, b/100 as striped hundredths, named
/// under them with + between. Tap a shaded tenth and every one opens into ten hundredths; slide the striped hundredths
/// into the first whole, where they pour in after the shaded ones (past a full whole, on into the second); the names go
/// into the record (3/10 + 25/100 = 30/100 + 25/100 = 55/100 =), and the decimal is typed.
///
/// Every step's picture has "at": 0 the question, 1 open the tenths, 2 slide, 3 write, 4 done.
public enum TenthsHundredths {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) {
            a = min(9, max(1, Int((x["a"] ?? 3).rounded()))); b = min(99, max(1, Int((x["b"] ?? 25).rounded())))
        }
        /// The tenths as hundredths, and the sum in hundredths.
        public var A: Int { 10 * a }
        public var S: Int { A + b }
        public var text: String { Dec4.text(S) }
    }

    /// The web's generator: 1–9 tenths and 1–99 hundredths.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        numbers(a: Int.random(in: 1...9, using: &rng), b: Int.random(in: 1...99, using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-dec", title: "Tenths and hundredths", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return [.frac(.num(Double(s.a)), .num(10)), .op("+"), .frac(.num(Double(s.b)), .num(100))] },
        idea: { _ in "1 tenth is the same as 10 hundredths, so both can be written in hundredths." },
        depends: ["g4-equiv", "g4-likefrac"],
        check: [CheckItem(0, when: { Parts($0).S < 100 }), CheckItem(0, when: { Parts($0).S >= 100 }),
                CheckItem(0, when: { Parts($0).b < 10 }), CheckItem(0)]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), a = s.a, b = s.b, A = s.A, S = s.S
        let say1 = "Cut every tenth into 10 hundredths. Tap a shaded tenth."
        let hint1 = "Each shaded column is a tenth."
        let open = LessonStep(StepWords(say: say1, hint: hint1, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": 1], hint: hint1, explain: "\(a)/10 = \(A)/100.",
                               check: { v in
                                   switch Dec4.int(v, "t") {
                                   case 1: return .right
                                   case -2: return .wrong("Those are hundredths already. Tap a shaded tenth.")
                                   default: return .wrong("That part is empty. Tap a shaded tenth.")
                                   }
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let say2 = "Same-size pieces now, so add the tops. Slide the striped hundredths into the first whole."
        let hint2 = "They go after the shaded hundredths."
        let slide = LessonStep(StepWords(say: say2, hint: hint2, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: hint2, explain: "\(A) + \(b) = \(Dec4.hund(S)).",
                               check: { v in Dec4.int(v, "s") == 1 ? .right : .soft("Slide them into the first whole.") }, byHand: true),
            picture: ["at": 2], onMiss: ["target": 1], hint2: ["spot": 1])
        let say3 = "Write it as a decimal. Type it with its point."
        let hint3 = "Hundredths go two places after the point."
        let write = LessonStep(StepWords(say: say3, hint: hint3, action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(a)), .num(10)), .op("+"), .frac(.num(Double(b)), .num(100)), .op("="),
                                        .frac(.num(Double(A)), .num(100)), .op("+"), .frac(.num(Double(b)), .num(100)), .op("="),
                                        .frac(.num(Double(S)), .num(100)), .op("="), .box("x")],
                               expected: ["x": Double(S) / 100], hint: hint3,
                               explain: "\(S)/100 = \(s.text).",
                               check: { v in
                                   let t = v["x"] ?? -1
                                   func eq(_ y: Double) -> Bool { abs(t - y) < 1e-9 }
                                   if eq(Double(S) / 100) { return .right }
                                   if eq(Double(S) / 10) || eq(Double(S)) { return .wrong("Hundredths need two places after the decimal point.") }
                                   if eq(Double(a + b) / 100) { return .wrong("Tenths are bigger pieces. Use the \(A) hundredths from the step before.") }
                                   return .wrong("There are \(Dec4.hund(S)). Hundredths go two places after the point." + (S >= 100 ? " 100 hundredths make 1 whole." : ""))
                               }, incomplete: "Type the decimal."),
            picture: ["at": 3])
        let why = "A tenth is ten hundredths, so they add as hundredths."
        return [LessonStep(StepWords(say: say1, hint: hint1, action: "Let’s find out"), picture: ["at": 0]),
                open, slide, write,
                LessonStep(StepWords(say: why, hint: why, action: "Next problem"), picture: ["at": 4])]
    }
}

/// Decimals on a number line (g4-decline, 4.NF.6; new): Rounding decimals' two lines. Line 1 runs from a whole number to
/// the next in ten blocks of a tenth; tap the block the decimal is in and it opens below into line 2, ten blocks of a
/// hundredth; drag the point to the decimal (it snaps to hundredths). A tenths decimal is placed straight on line 1's
/// tick. Then it's written as a fraction, top and bottom.
///
/// Every step's picture has "at": 0 the question, 1 tap the tenth (not for a tenths decimal), 2 drag the point, 3 write,
/// 4 done.
public enum DecimalLine {
    public static func numbers(w: Int, h: Int, story: Int = 0, thing: Int = 0) -> Numbers {
        ["w": Double(w), "h": Double(h), "story": Double(story), "thing": Double(thing)]
    }
    public enum Kind: Sendable { case plain, under, tenths, whole }
    static let things = ["ribbon", "rope", "board"]

    public struct Parts: Sendable {
        public let w: Int, h: Int, story: Bool, thing: Int
        public init(_ x: Numbers) {
            w = min(9, max(0, Int((x["w"] ?? 0).rounded()))); h = min(99, max(1, Int((x["h"] ?? 62).rounded())))
            story = (x["story"] ?? 0) != 0; thing = min(2, max(0, Int((x["thing"] ?? 0).rounded())))
        }
        /// Its tenths and hundredths digits, all of it in hundredths, and how it's written.
        public var t: Int { h / 10 }
        public var u: Int { h % 10 }
        public var H: Int { 100 * w + h }
        public var X: String { Dec4.text(H) }
        public var tenOnly: Bool { u == 0 }
        public var kind: Kind { tenOnly ? .tenths : w > 0 ? .whole : t == 0 ? .under : .plain }
        /// Line 1's left end and line 2's, in hundredths.
        public var lo1: Int { 100 * w }
        public var lo2: Int { lo1 + 10 * t }
        /// " m" after the lines' numbers when it's told as a length.
        public var unit: String { story ? " m" : "" }
        public var intro: String { story ? "A \(DecimalLine.things[thing]) is \(X) m long." : "Each block is a tenth." }
        /// What the point says at step `i` of the line being dragged (line 1 in tenths for a tenths decimal).
        public func at(_ i: Int) -> String { tenOnly ? Dec4.text(lo1 + 10 * i) : Dec4.text(lo2 + i) }
        /// The last words: why.
        public var why: String {
            switch kind {
            case .tenths: return "\(Dec4.cap(Dec4.tenths(t))) is the same as \(Dec4.hund(h))."
            case .whole: return "\(w == 1 ? "1 whole" : "\(w) wholes"), \(Dec4.tenths(t)) and \(Dec4.hund(u)) make \(Dec4.hund(H))."
            case .under: return "No tenths, so \(X) is just \(Dec4.hund(u))."
            case .plain: return "\(Dec4.tenths(t)) and \(Dec4.hund(u)) make \(Dec4.hund(h))."
            }
        }
    }

    /// Index < 3 two places with no 0 digit (0.11–0.99); then by turns under a tenth (0.05), tenths only (0.7), two
    /// places again, and a whole number in front (1.45 on a line from 1 to 2); told as a length every third problem.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kinds: [Kind] = [.under, .tenths, .plain, .whole], kind = i < 3 ? .plain : kinds[(i - 3) % 4]
        let h: Int
        switch kind {
        case .under: h = Int.random(in: 1...9, using: &rng)
        case .tenths: h = 10 * Int.random(in: 1...9, using: &rng)
        default: h = 10 * Int.random(in: 1...9, using: &rng) + Int.random(in: 1...9, using: &rng)
        }
        return numbers(w: kind == .whole ? Int.random(in: 1...9, using: &rng) : 0, h: h, story: i % 3 == 2 ? 1 : 0, thing: (i / 3) % 3)
    }

    public static let spec = LessonSpec(id: "g4-decline", title: "Decimals on a number line", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).H) / 100)] },
        idea: { _ in "Find the tenth it's in, then count the hundredths in that tenth." },
        depends: ["g4-dec"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).kind == .under }), CheckItem(4, when: { Parts($0).kind == .tenths }),
                CheckItem(6, when: { Parts($0).kind == .whole })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), X = s.X, t = s.t, u = s.u, H = s.H
        var out: [LessonStep] = []
        let first: String
        if s.tenOnly {
            first = "\(s.intro) Drag the point to the number."
            let hint = "Count the tenths from the start of the line."
            out.append(LessonStep(StepWords(say: first, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(t)], hint: hint, explain: "\(X) is \(Dec4.tenths(t)) past \(Dec4.text(s.lo1)).",
                                   check: { v in
                                       let p = Dec4.int(v, "p")
                                       return p == t ? .right : .wrong("That’s \(s.at(p)). \(X) is \(Dec4.tenths(t)) past \(Dec4.text(s.lo1)).")
                                   }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            first = "\(s.intro) Tap the tenth the number is in."
            let hint1 = "Its tenths digit is \(t)."
            out.append(LessonStep(StepWords(say: first, hint: hint1, action: "Check"),
                answer: AnswerTask(prompt: [.box("b")], expected: ["b": Double(t)], hint: hint1,
                                   explain: "\(X) is between \(Dec4.text(s.lo2)) and \(Dec4.text(s.lo2 + 10)).",
                                   check: { v in Dec4.int(v, "b") == t ? .right : .wrong("\(X) is between \(Dec4.text(s.lo2)) and \(Dec4.text(s.lo2 + 10)).") },
                                   byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            let say2 = "Each block is a hundredth now. Drag the point to the number."
            let hint2 = "Count \(Dec4.hund(u)) from \(Dec4.text(s.lo2))."
            out.append(LessonStep(StepWords(say: say2, hint: hint2, action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(u)], hint: hint2, explain: "\(X) is \(Dec4.hund(u)) past \(Dec4.text(s.lo2)).",
                                   check: { v in
                                       let p = Dec4.int(v, "p")
                                       return p == u ? .right : .wrong("That’s \(s.at(p)). \(X) is \(Dec4.hund(u)) past \(Dec4.text(s.lo2)).")
                                   }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let say3 = "Write it as a fraction. Fill in the top and the bottom."
        let hint3 = s.tenOnly ? "Count the tenths from the start of the line to the point." : "Count the hundredths: a tenth is 10 of them."
        out.append(LessonStep(StepWords(say: say3, hint: hint3, action: "Check"),
            answer: AnswerTask(prompt: [.text(X), .op("="), .frac(.box("T"), .box("B"))], expected: ["T": Double(H), "B": 100], hint: hint3,
                               explain: s.why,
                               check: { v in
                                   let T = Dec4.int(v, "T"), B = Dec4.int(v, "B")
                                   if (B == 100 && T == H) || (B == 10 && T * 10 == H) { return .right }
                                   var msg: String?
                                   switch s.kind {
                                   case .tenths: msg = B == 100 && T == t ? "\(Dec4.hund(t)) is \(Dec4.text(t)). \(X) is \(Dec4.tenths(t))." : nil
                                   case .under: msg = B == 10 && T == u ? "That’s \(Dec4.tenths(u)). \(X) is \(Dec4.hund(u)): the bottom is 100."
                                       : B == 100 && T == 10 * u ? "That’s \(Dec4.hund(10 * u)). \(X) is \(Dec4.hund(u))." : nil
                                   default: break
                                   }
                                   if msg == nil, s.kind != .tenths, s.kind != .under {
                                       if T == 10 * s.w + t && (B == 10 || B == 100) { msg = "That’s the tenths only." }
                                       else if T == H && B == 10 { msg = "\(Dec4.hund(H)): the bottom is 100." }
                                       else if s.kind == .whole && T == s.h && B == 100 {
                                           msg = "That’s only the part after the point. \(s.w == 1 ? "1 whole is" : "\(s.w) wholes are") \(100 * s.w) hundredths more."
                                       }
                                   }
                                   return .wrong(msg ?? hint3)
                               }, incomplete: "Fill in the top and the bottom."),
            picture: ["at": 3]))
        return [LessonStep(StepWords(say: first, hint: first, action: "Let’s find out"), picture: ["at": 0])] + out
            + [LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 4])]
    }
}

/// Comparing decimals (the web app's g4-deccompare, 4.NF.7): w.(a hundredths) ? w.(b hundredths), written with pa and pb
/// places after the point.
///
/// On the paper: two wholes side by side, named by their decimals over them, ? between. Drag across each grid to shade
/// it: whole columns (tenths) left of the finger, then hundredths down the next column; its count is written under it
/// once it's right. Then tap <, = or >, and the sign goes between the names.
///
/// Every step's picture has "at": 0 the question, 1 shade the first, 2 shade the second, 3 the choice, 4 done.
public enum CompareDec4 {
    public static func numbers(w: Int, a: Int, b: Int, pa: Int, pb: Int) -> Numbers {
        ["w": Double(w), "a": Double(a), "b": Double(b), "pa": Double(pa), "pb": Double(pb)]
    }
    public static let signs = ["<", "=", ">"]
    static func cmp(_ x: Int, _ y: Int) -> Int { x < y ? 0 : x == y ? 1 : 2 }

    public struct Parts: Sendable {
        public let w: Int, a: Int, b: Int, pa: Int, pb: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            w = min(9, max(0, i("w", 0))); a = min(99, max(1, i("a", 50))); b = min(99, max(1, i("b", 45)))
            pa = a % 10 == 0 && i("pa", 2) == 1 ? 1 : 2; pb = b % 10 == 0 && i("pb", 2) == 1 ? 1 : 2
        }
        public var Xs: String { Dec4.written(w, a, pa) }
        public var Ys: String { Dec4.written(w, b, pb) }
        /// 0 <, 1 =, 2 >; and what comparing the digits after the point as whole numbers says.
        public var k: Int { cmp(a, b) }
        public var naive: Int { cmp(pa == 1 ? a / 10 : a, pb == 1 ? b / 10 : b) }
        func partIs(_ X: String) -> String { w > 0 ? "After the point, \(X) has" : "\(X) is" }
        static func cols(_ n: Int) -> String { "\(n) full \(n == 1 ? "column" : "columns")" }
        /// The words over the grids.
        public var intro: String {
            w > 0 ? "Both have \(w == 1 ? "1 whole" : "\(w) wholes"). Shade what’s after the point." : "Each grid is one whole: a column is a tenth, a square a hundredth."
        }
        /// What a miss on grid j (0, 1) says, shaded to n hundredths (the web's slips; the rest say how the decimal reads).
        public func shadeMiss(_ j: Int, _ n: Int) -> String {
            let X = j == 0 ? Xs : Ys, hh = j == 0 ? a : b, pl = j == 0 ? pa : pb, tt = hh / 10, uu = hh % 10
            if pl == 1 && n == tt { return "\(partIs(X)) \(Dec4.tenths(tt)): \(Self.cols(tt))." }
            if pl == 2 && tt == 0 && n == 10 * uu { return "The \(uu) is in the hundredths place, two after the point. So it’s only \(Dec4.hund(uu))." }
            if pl == 2 && tt > 0 && n == tt { return "That’s only the tenths. \(X) has \(Dec4.tenths(tt)) and \(Dec4.hund(uu)), which is \(Dec4.hund(hh))." }
            return "That’s \(Dec4.hund(n)). " + (pl == 1 ? "\(partIs(X)) \(Dec4.tenths(tt)), and \(Dec4.tenths(tt)) is \(Dec4.hund(hh))."
                                                         : "The two digits after the point, \(Dec4.pad2(hh)), make \(Dec4.hund(hh)).")
        }
        /// What a wrong sign says (the web's slips): missed equal, the digits compared as whole numbers, called equal,
        /// turned round.
        public func wrong(_ i: Int) -> String {
            if k == 1 { return "\(Xs) and \(Ys) both have \(Dec4.hund(a))\(w > 0 ? " after the point" : ""). A zero on the end doesn’t change the amount." }
            if i == naive {
                let (one, oh, other) = pa == 1 ? (Xs, a, b) : (Ys, b, a)
                return "\(other) and \(oh / 10) aren’t the amounts. \(w > 0 ? "After the point, \(one) has" : "\(one) has") \(Dec4.hund(oh))."
            }
            if i == 1 { return "They’d be equal only with the same number of hundredths. \(a) and \(b) are not the same." }
            return "\(Dec4.cap(Dec4.hund(a))) is \(k == 0 ? "less" : "more") than \(Dec4.hund(b)), so \(Xs) \(signs[k]) \(Ys)."
        }
        public var why: String {
            k == 1 ? "The same number of hundredths, so they are equal." : "\(Dec4.cap(Dec4.hund(a))) is \(k == 0 ? "less" : "more") than \(b)."
        }
    }

    /// The web's generator (generateDecCompare): no whole number for index < 4; the trap (a tenths decimal against a
    /// two-place one) 45% of the time, then the same tenths, the same amount written two ways, any two; either way round.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let w = i < 4 ? 0 : Int.random(in: 0...9, using: &rng), kind = Double.random(in: 0..<1, using: &rng)
        var a: Int, b: Int, pa = 2, pb = 2
        if kind < 0.45 {
            let t = Int.random(in: 1...9, using: &rng)
            var u: Int
            repeat { u = Int.random(in: 0...9, using: &rng) } while u == t
            a = 10 * t; pa = 1; b = 10 * u + Int.random(in: 1...9, using: &rng)
        } else if kind < 0.75 {
            let t = Int.random(in: 0...9, using: &rng)
            a = 10 * t + Int.random(in: (t > 0 ? 0 : 1)...9, using: &rng); b = 10 * t + Int.random(in: 1...9, using: &rng)
            if a % 10 == 0 && Bool.random(using: &rng) { pa = 1 }
        } else if kind < 0.87 {
            a = 10 * Int.random(in: 1...9, using: &rng); b = a; pa = 1
        } else {
            a = Int.random(in: 1...99, using: &rng); b = Int.random(in: 1...99, using: &rng)
        }
        if a == b && pa == pb { b = b == 99 ? 98 : b + 1 }
        return Bool.random(using: &rng) ? numbers(w: w, a: b, b: a, pa: pb, pb: pa) : numbers(w: w, a: a, b: b, pa: pa, pb: pb)
    }

    public static let spec = LessonSpec(id: "g4-deccompare", title: "Comparing decimals", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return [.text(s.Xs), .op("?"), .text(s.Ys)] },
        idea: { _ in "Hundredths are all the same size, so more hundredths means bigger." },
        depends: ["g4-dec"],
        check: [CheckItem(0, when: { let s = Parts($0); return s.pa != s.pb && s.naive != s.k }),
                CheckItem(0, when: { let s = Parts($0); return s.a / 10 == s.b / 10 }),
                CheckItem(4, when: { Parts($0).a == Parts($0).b }),
                CheckItem(4, when: { let s = Parts($0); return s.w > 0 && s.pa != s.pb })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x)
        func shade(_ j: Int, _ say: String) -> LessonStep {
            let want = j == 0 ? s.a : s.b, X = j == 0 ? s.Xs : s.Ys, pl = j == 0 ? s.pa : s.pb
            let hint = pl == 1 ? "One tenth is 10 hundredths. Put a 0 on the end: \(X)0." : "Read the two digits after the point as hundredths."
            return LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(want)], hint: hint, explain: "\(X): \(Dec4.hund(want)).",
                                   check: { v in let n = Dec4.int(v, "n"); return n == want ? .right : .wrong(s.shadeMiss(j, n)) }, byHand: true),
                picture: ["at": Double(j + 1)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let say1 = "\(s.intro) Drag across the first grid."
        let hint3 = "Same-size pieces now: compare \(s.a) and \(s.b)."
        let choose = LessonStep(StepWords(say: "Which is more? Tap <, = or >.", hint: hint3, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(s.k)], hint: hint3, explain: s.why,
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Tap <, = or >.") }
                                   let i = Int(c.rounded())
                                   return i == s.k ? .right : .wrong(s.wrong(i))
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [LessonStep(StepWords(say: say1, hint: say1, action: "Let’s find out"), picture: ["at": 0]),
                shade(0, say1), shade(1, "Now the second. Drag across the second grid."), choose,
                LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 4])]
    }
}
