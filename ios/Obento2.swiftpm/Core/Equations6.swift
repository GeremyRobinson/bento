import Foundation

/// What 6th grade's Equations chapter shares (design/grade6.md chapter 6, the preview design/prototype/grade6-ch6.html):
/// an equation is two sides that balance, what's left of = as long as what's right of it; whatever is done to one side
/// is done to the other. x is a plain strip with no squares in it (chapter 5's strip).
public enum Eq6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }
    /// A count of cells of `cv` as school writes it: "2.75", "2 3/4" (`fr`), "8".
    public static func value(_ cells: Int, _ cv: Double, fr: Bool) -> String {
        fr ? Ratio6.mixed(Int((Double(cells) * cv * 4).rounded()), 4) : fmt(Double(cells) * cv)
    }
}

// MARK: - One-step equations

/// One-step equations (the web app's g6-onestep, 6.EE.7, 6.EE.5): x + a = q, x − a = q, ax = q, x ÷ a = q. A cell is
/// one (a quarter or a half in the extra type, from problem 8 every other problem). x + 7 = 15 and x − 7 = 8: the left
/// side over the right side as bars; 3x = 27: 3 rows of x beside a rectangle 3 rows tall whose width is found; x ÷ 3 = 4:
/// x as a rectangle 3 rows tall, one row shaded, beside a row of 4 cells. Undo by hand (slide the a off both sides, put
/// it back on both, share into rows, make all the rows), write x, then check.
///
/// "at": 0 the question, 1 undo, 2 write x, 3 check, 4 done.
public enum OneStep6 {
    /// kind: 0 x + a, 1 x − a, 2 ax, 3 x ÷ a. `a` is cells for + and −, a count for × and ÷; `xc` is x's cells (the
    /// right side's for ÷); `cv` what a cell is worth; `fr` the values written as fractions (quarters).
    public static func numbers(kind: Int, a: Int, xc: Int, cv: Double = 1, fr: Bool = false) -> Numbers {
        ["kind": Double(kind), "a": Double(a), "xc": Double(xc), "cv": cv, "fr": fr ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let kind: Int, a: Int, xc: Int, cv: Double, fr: Bool
        public init(_ n: Numbers) {
            kind = Eq6.int(n, "kind", 0); a = Eq6.int(n, "a", 7); xc = Eq6.int(n, "xc", 8); cv = n["cv"] ?? 1; fr = Eq6.int(n, "fr", 0) == 1
        }
        /// + or − (the bars), × or ÷ (the rows).
        public var bars: Bool { kind < 2 }
        /// x in cells.
        public var X: Int { kind == 3 ? a * xc : xc }
        /// The right side in cells.
        public var Q: Int { [xc + a, xc - a, a * xc, xc][kind] }
        public var xv: Double { Double(X) * cv }
        public var qv: Double { kind == 3 ? Double(xc) * cv : Double(Q) * cv }
        /// What's done to x: a value for + and −, a count for × and ÷.
        public var pv: Double { bars ? Double(a) * cv : Double(a) }
        /// x when the same operation is done instead of the opposite (the web's slip).
        public var same: Double { [qv + pv, qv - pv, qv * Double(a), qv / Double(a)][kind] }
        public func V(_ cells: Int) -> String { Eq6.value(cells, cv, fr: fr) }
        public var xS: String { V(X) }
        public var qS: String { kind == 3 ? fmt(qv) : V(Q) }
        public var pS: String { bars ? V(a) : "\(a)" }
        /// A cell's worth in words, for the extra type ("1/4").
        public var cellS: String { cv == 0.25 ? "1/4" : "1/2" }
        public var each: String { cv == 1 ? "" : ", each \(cellS)" }

        public var undoSay: String {
            switch kind {
            case 0: return "Take \(pS) off both sides. Slide it off the end."
            case 1: return "Put \(pS) back on both sides. Slide them onto the ends."
            case 2: return "Share \(qS) into \(a) rows. Drag the right edge."
            default: return "Make all \(a) rows. Drag the bottom edge down."
            }
        }
        public let xSay = "Write what x is. x lines up with what’s left."
        public var checkSay: String { "Check it. Put \(xS) back in for x." }
        public var why: String {
            switch kind {
            case 0: return "Take \(pS) off both sides and they still balance: x is \(xS)."
            case 1: return "Put \(pS) back on both sides and they still balance: x is \(xS)."
            case 2: return "Share \(qS) into \(a) rows: one row is x, so x is \(xS)."
            default: return "Make all \(a) rows: x is \(a) rows of \(qS), so x is \(xS)."
            }
        }
        /// The move's goal: the cells slid (+, −), the columns (×), the rows (÷).
        public var goal: Int { [a, a, X, a][kind] }
        /// What the undo's move says when it's let go (nil: right). `u`: how many slid (−1: the right side moved
        /// instead, 0: the tray dropped short of the ends), the columns, or the rows.
        public func undo(_ u: Int) -> String? {
            if u == goal { return nil }
            switch kind {
            case 0: return "Take it off both sides."
            case 1: return u < 0 ? "Do the opposite to undo it." : "Slide them onto the ends."
            case 2:
                let used = a * u
                return used < Q ? "\(V(Q - used)) \(Q - used == 1 && cv == 1 ? "is" : "are") left: another column fits."
                    : "\(a) rows of \(V(u)) is \(V(used)). There are only \(V(Q))."
            default: return "That’s \(u) row\(u == 1 ? "" : "s"). x has \(a)."
            }
        }
        /// What x written says (nil: right).
        public func written(_ v: Double) -> String? {
            if Eq6.near(v, xv) { return nil }
            if Eq6.near(v, same) { return "Do the opposite to undo it." }
            switch kind {
            case 2: return "One row is one x: count its cells\(each)."
            case 3: return "x is all \(a) rows: count their cells."
            default: return "Count the cells under x\(each)."
            }
        }
        /// The check's left side in words: "8 + 7".
        public var work: String { ["\(xS) + \(pS)", "\(xS) − \(pS)", "\(a) × \(xS)", "\(xS) ÷ \(a)"][kind] }
        public func checked(_ v: Double) -> String? {
            if Eq6.near(v, qv) { return nil }
            return Eq6.near(v, xv) ? "That’s x again. Work out \(work)." : "Work out \(work)."
        }
        /// x written as a fraction: its whole part (nil when it's less than 1) and its fraction in lowest terms.
        public var xParts: (w: Int?, n: Int, d: Int) {
            let q = Int((xv * 4).rounded()), w = q / 4, r = q % 4, g = r == 2 ? 2 : 1
            return (w > 0 ? w : nil, r / g, 4 / g)
        }
        /// A value as the line writes it: a number, or a whole and a fraction.
        public func math(_ cells: Int) -> MathLine {
            guard fr else { return [.num(Double(cells) * cv)] }
            let q = Int((Double(cells) * cv * 4).rounded()), w = q / 4, r = q % 4, g = r == 2 ? 2 : 1
            if r == 0 { return [.num(Double(w))] }
            return (w > 0 ? [.num(Double(w))] : []) + [.frac(.num(Double(r / g)), .num(Double(4 / g)))]
        }
        public var left: MathLine {
            switch kind {
            case 0: return [.text("x"), .op("+")] + math(a)
            case 1: return [.text("x"), .op("−")] + math(a)
            case 2: return [.text("\(a)x")]
            default: return [.text("x"), .op("÷"), .num(Double(a))]
            }
        }
        public var display: MathLine { left + [.op("=")] + (kind == 3 ? [.num(qv)] : math(Q)) }
    }

    /// The web's generator (t 0–3, a 2–9, r 2–12: x is r for + and ×, the right side is r for − and ÷), its first four one
    /// of each kind; from problem 8, every other problem the extra type: x + 1.5 = 4.25 (quarters), x + 3/4 = 2
    /// (quarters written as fractions), 3x = 4.5 (halves).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let t = i < 4 ? i : i >= 8 && i % 2 == 1 ? 4 + r(0, 2) : r(0, 3), a = r(2, 9), rr = r(2, 12)
        switch t {
        case 0: return numbers(kind: 0, a: a, xc: rr)
        case 1: return numbers(kind: 1, a: a, xc: rr + a)
        case 2: return numbers(kind: 2, a: a, xc: rr)
        case 3: return numbers(kind: 3, a: a, xc: rr)
        case 4: let pa = Eq6.pick([2, 3, 5, 6, 7], &rng); return numbers(kind: 0, a: pa, xc: r(2, 21 - pa), cv: 0.25)
        case 5: let pa = r(1, 3), q = r(pa > 2 ? 2 : 1, 5); return numbers(kind: 0, a: pa, xc: 4 * q - pa, cv: 0.25, fr: true)
        default: return numbers(kind: 2, a: r(2, 4), xc: Eq6.pick([3, 5, 7], &rng), cv: 0.5)
        }
    }

    public static let spec = LessonSpec(id: "g6-onestep", title: "One-step equations", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in Parts(n).display },
        idea: { _ in "An equation is a balance, so do the same thing to both sides." },
        depends: ["g6-eval", "g3-divfacts"],
        check: [CheckItem(4, when: { Parts($0).kind == 0 }), CheckItem(4, when: { Parts($0).kind == 1 }),
                CheckItem(4, when: { Parts($0).kind == 2 }), CheckItem(4, when: { Parts($0).kind == 3 })]) { n in
        let s = Parts(n)
        let undoHint = ["Take the same off both sides.", "Put the same back on both sides.", "Fill the rows until it’s all used.", "x is all the rows."][s.kind]
        let ask = LessonStep(StepWords(say: s.undoSay, hint: undoHint, action: "Let’s find out"), picture: ["at": 0])
        let goal = Double(s.goal)
        let undo = LessonStep(StepWords(say: s.undoSay, hint: undoHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("u")], expected: ["u": goal], hint: undoHint, explain: s.why,
                               check: { v in
                                   guard let u = v["u"] else { return .soft(s.undoSay) }
                                   return s.undo(Int(u.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        // x written: a number, or a whole number and a fraction
        let xp = s.xParts
        let xPrompt: MathLine = s.fr ? [.text("x"), .op("=")] + (xp.w != nil ? [.box("w")] : []) + [.frac(.box("n"), .box("d"))] : [.text("x"), .op("="), .box("x")]
        var xWant: [String: Double] = s.fr ? ["n": Double(xp.n), "d": Double(xp.d)] : ["x": s.xv]
        if s.fr, let w = xp.w { xWant["w"] = Double(w) }
        let xHint = "x lines up with what’s left."
        let write = LessonStep(StepWords(say: s.xSay, hint: xHint, action: "Check"),
            answer: AnswerTask(prompt: xPrompt, expected: xWant, hint: xHint, explain: "x = \(s.xS)",
                               check: { v in
                                   var got: Double
                                   if s.fr {
                                       guard let nn = v["n"], let d = v["d"], d != 0, xp.w == nil || v["w"] != nil else { return .soft("Write the whole number and the fraction.") }
                                       got = (v["w"] ?? 0) + nn / d
                                   } else {
                                       guard let x = v["x"] else { return .soft("Write the number.") }
                                       got = x
                                   }
                                   return s.written(got).map { .wrong($0) } ?? .right
                               }, incomplete: s.fr ? "Write the whole number and the fraction." : "Write the number."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let ckLeft: MathLine = [[.text(s.xS), .op("+"), .text(s.pS)], [.text(s.xS), .op("−"), .text(s.pS)],
                                [.num(Double(s.a)), .op("×"), .text(s.xS)], [.text(s.xS), .op("÷"), .num(Double(s.a))]][s.kind]
        let ckHint = "Work out \(s.work)."
        let check = LessonStep(StepWords(say: s.checkSay, hint: ckHint, action: "Check"),
            answer: AnswerTask(prompt: ckLeft + [.op("="), .box("q")], expected: ["q": s.qv], hint: ckHint, explain: "\(s.work) = \(s.qS), the other side.",
                               check: { v in
                                   guard let q = v["q"] else { return .soft("Write the number.") }
                                   return s.checked(q).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [ask, undo, write, check,
                LessonStep(StepWords(say: s.why, hint: "Do the opposite to both sides.", action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: - Inequalities

/// Inequalities (g6-ineq, 6.EE.8, 6.EE.5): a story's rule ("You must be older than 8.") on a line two squares a one,
/// 20 ones around the story's number. Drag the circle onto the number and tap it open or filled; drag the arrow out of it
/// along the line and off the end; tap the test numbers that work; pick the sign and write the number: x > 8.
///
/// "at": 0 the question, 1 put the circle, 2 the ray, 3 test, 4 the sign, 5 the number, 6 done.
public enum Ineq6 {
    public static let signs = [">", "<", "≥", "≤"]
    /// sign: 0 >, 1 <, 2 ≥, 3 ≤. `tests` sorted; `dec`: halves written as decimals.
    public static func numbers(sign: Int, n: Double, age: Bool, tests: [Double], dec: Bool = false) -> Numbers {
        var x: Numbers = ["sign": Double(sign), "n": n, "age": age ? 1 : 0, "dec": dec ? 1 : 0]
        for (j, t) in tests.sorted().enumerated() { x["t\(j)"] = t }
        return x
    }

    public struct Parts: Sendable {
        public let sign: Int, n: Double, age: Bool, tests: [Double], dec: Bool
        public init(_ x: Numbers) {
            sign = Eq6.int(x, "sign", 0); n = x["n"] ?? 8; age = Eq6.int(x, "age", 0) == 1; dec = Eq6.int(x, "dec", 0) == 1
            tests = (0..<4).map { x["t\($0)"] ?? Double($0) }
        }
        public var big: Bool { sign == 0 || sign == 2 }
        public var strict: Bool { sign < 2 }
        public var lo: Double { n - 10 }
        public var hi: Double { n + 10 }
        public var N: String { Neg6.fm(n) }
        public var S: String { Ineq6.signs[sign] }
        /// A test number as the card writes it: 9 1/2 (or 9.5), −3.
        public func hs(_ v: Double) -> String {
            if v == v.rounded() || dec { return Neg6.fm(v) }
            return (v < 0 ? "−" : "") + Ratio6.half(Swift.abs(v))
        }
        public func works(_ v: Double) -> Bool { [v > n, v < n, v >= n, v <= n][sign] }
        public var working: [Int] { tests.indices.filter { works(tests[$0]) } }
        public var word: String { age ? (strict ? "older" : "at least") : ["warmer", "colder", "at least", "at most"][sign] }
        public var noun: String { age ? "age" : "temperature" }
        public var story: String {
            if age { return strict ? "You must be older than \(N)." : "You must be at least \(N) to ride." }
            return strict ? "It must be \(word) than \(N) degrees." : "It must be \(word) \(N) degrees."
        }
        public var putSay: String { "Put the circle on \(N). Tap it to fill it in or leave it open." }
        public var raySay: String { "Shade every \(noun) that works. Drag the arrow out of the circle along the line." }
        public let testSay = "Tap the ones that work."
        public let signSay = "Write it with x. Pick the sign."
        public let numberSay = "Write it with x. Type the number."
        public var why: String {
            ["Every number past \(N) works, far too many to list.", "Every number under \(N) works, far too many to list.",
             "\(N) and every number past it work, far too many to list.", "\(N) and every number under it work, far too many to list."][sign]
        }
        public func put(_ c: Double) -> String? { Eq6.near(c, n) ? nil : "That’s \(Neg6.fm(c)). Put it on \(N)." }

        /// The ray as it was let go: 1 right; 2 the wrong way; 3 short of the line's end; 4 filled for > or <; 5 open for ≥ or ≤.
        public static let rayRight = 1, rayWrongWay = 2, rayShort = 3, rayFilled = 4, rayOpen = 5
        public func ray(_ r: Int) -> String? {
            switch r {
            case Self.rayRight: return nil
            case Self.rayWrongWay:
                return ["\(age ? "Older" : "Warmer") than \(N) means bigger: to the right.", "Colder than \(N) means smaller: to the left.",
                        "At least \(N) means \(N) or bigger: to the right.", "At most \(N) means \(N) or smaller: to the left."][sign]
            case Self.rayShort: return "Every \(noun) \(big ? "past" : "under") \(N) works: take it off the end."
            case Self.rayFilled: return "\(N) isn’t \(word) than \(N): leave it open."
            default: return "\(N) is \(word) \(N): fill it in."
            }
        }
        /// A test number tapped that doesn't work.
        public func tested(_ v: Double) -> String {
            if Eq6.near(v, n) { return "\(N) isn’t \(word) than \(N)." }
            return v < n ? "\(hs(v)) is less than \(N)." : "\(hs(v)) is more than \(N)."
        }
        /// The sign picked (nil: right).
        public func picked(_ c: Int) -> String? {
            if c == sign { return nil }
            let s = Ineq6.signs[min(3, max(0, c))], turned = (c == 0 || c == 2) != big
            if turned { return "x \(s) \(N) says \(["more than", "less than", "at least", "at most"][c]) \(N): the ray goes the other way." }
            return c < 2 ? "x \(s) \(N) leaves \(N) out, but the circle is filled." : "x \(s) \(N) counts \(N) too, but the circle is open."
        }
    }

    /// Problems 1–3 > and < with whole numbers; 4–6 ≥ and ≤ ("at least", "at most"); 7+ any sign, negative numbers half
    /// the time, and a test number with a half (or written as a decimal). The test numbers: the number itself, one on the
    /// wrong side, two that work.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let sign = i < 3 ? [0, 1, r(0, 1)][i] : i < 6 ? [2, 3, 2 + r(0, 1)][i - 3] : r(0, 3)
        let big = sign == 0 || sign == 2, neg = i >= 6 && r(0, 1) == 1
        let age = big && !neg && (i < 6 || r(0, 1) == 1)
        let n = Double(age ? r(5, 15) : neg ? r(-10, -1) : i < 6 ? r(2, 20) : r(0, 20))
        let s = big ? 1.0 : -1.0
        let wrong = n - s * Double(r(1, 5)), w1 = n + s * Double(r(1, 3)), w2 = n + s * Double(r(5, 9)) + (i >= 6 ? s * 0.5 : 0)
        return numbers(sign: sign, n: n, age: age, tests: [n, wrong, w1, w2], dec: i >= 6 && r(0, 1) == 1)
    }

    public static let spec = LessonSpec(id: "g6-ineq", title: "Inequalities", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text("x"), .op(s.S), .num(s.n)] },
        idea: { _ in "An inequality has far too many answers to list, so the line shows them all." },
        depends: ["g6-compare", "g6-eval"],
        check: [CheckItem(0), CheckItem(1), CheckItem(3, when: { Parts($0).sign == 2 }), CheckItem(6, when: { Parts($0).n < 0 })]) { x in
        let s = Parts(x)
        let putHint = "Count along the line to \(s.N)."
        let ask = LessonStep(StepWords(say: s.putSay, hint: putHint, action: "Let’s find out"), picture: ["at": 0])
        let put = LessonStep(StepWords(say: s.putSay, hint: putHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": s.n], hint: putHint, explain: "The circle on \(s.N).",
                               check: { v in
                                   guard let c = v["c"] else { return .soft(s.putSay) }
                                   return s.put(c).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let rayHint = s.big ? "Bigger is to the right." : "Smaller is to the left."
        let ray = LessonStep(StepWords(say: s.raySay, hint: rayHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("r")], expected: ["r": Double(Parts.rayRight)], hint: rayHint, explain: "Every \(s.noun) that works, shaded.",
                               check: { v in
                                   guard let r = v["r"] else { return .soft(s.raySay) }
                                   return s.ray(Int(r.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let count = Double(s.working.count)
        let testHint = "The ones on the shaded part work."
        let test = LessonStep(StepWords(say: s.testSay, hint: testHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": count], hint: testHint, explain: "The ones on the shaded part.",
                               check: { v in
                                   guard let t = v["t"] else { return .soft(s.testSay) }
                                   if Eq6.near(t, count) { return .right }
                                   if t < 0 { let j = min(3, max(0, Int(-t.rounded()) - 1)); return .wrong(s.tested(s.tests[j])) }
                                   return .soft(s.testSay)
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let signHint = "The ray and the circle say which sign."
        let pick = LessonStep(StepWords(say: s.signSay, hint: signHint, action: "Check"),
            answer: AnswerTask(prompt: [], expected: ["c": Double(s.sign)], hint: signHint, explain: "x \(s.S) \(s.N)",
                               check: { v in s.picked(Eq6.int(v, "c")).map { .wrong($0) } ?? .right }, choices: Ineq6.signs),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let numHint = "The circle is on \(s.N)."
        let write = LessonStep(StepWords(say: s.numberSay, hint: numHint, action: "Check"),
            answer: AnswerTask(prompt: [.text("x"), .op(s.S), .box("x")], expected: ["x": s.n], hint: numHint, explain: "x \(s.S) \(s.N)",
                               check: { v in
                                   guard let w = v["x"] else { return .soft("Write the number.") }
                                   return Eq6.near(w, s.n) ? .right : .wrong(numHint)
                               }, incomplete: "Write the number."),
            picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [ask, put, ray, test, pick, write,
                LessonStep(StepWords(say: s.why, hint: "The ray shows them all.", action: "Next problem"), picture: ["at": 6])]
    }
}

// MARK: - Two quantities

/// Two quantities (g6-depend, 6.EE.9): one amount depends on another by a rule, m = 3 × h or a = s + 5. The plane across
/// 0–10 at 4 squares a one, up 0–30 squares (a square a one, or 5 for rules that grow by 5, 10 or 15); the story and the
/// table (the record) beside it. Drag the handle on the across axis to 2, 4 and 6: the point rides the rule's line and
/// the table writes a column at each stop; write the rule; use it past the paper (or backwards).
///
/// "at": 0 the question, 1–3 the stops, 4 the rule, 5 past the paper, 6 done.
public enum Depend6 {
    public struct Story: Sendable {
        public let s: String, X: String, Y: String, x1: String, y1: String, xl: String, yl: String, the: String, they: String, ks: [Int]
    }
    public static let times: [Story] = [
        Story(s: "You walk at one steady speed.", X: "hours", Y: "miles", x1: "hour", y1: "mile", xl: "h", yl: "m", the: "the hours", they: "the miles depend on them", ks: [2, 3]),
        Story(s: "You ride at one steady speed.", X: "hours", Y: "miles", x1: "hour", y1: "mile", xl: "h", yl: "m", the: "the hours", they: "the miles depend on them", ks: [5, 10, 15]),
        Story(s: "Every ticket costs the same.", X: "tickets", Y: "dollars", x1: "ticket", y1: "dollar", xl: "t", yl: "d", the: "the tickets", they: "the dollars depend on them", ks: [2, 3, 5, 10, 15]),
        Story(s: "Every song lasts the same time.", X: "songs", Y: "minutes", x1: "song", y1: "minute", xl: "s", yl: "m", the: "the songs", they: "the minutes depend on them", ks: [2, 3, 5]),
    ]
    public static let plus: [Story] = [
        Story(s: "Ali is older than his sister.", X: "sister’s age", Y: "Ali’s age", x1: "", y1: "", xl: "s", yl: "a", the: "the sister’s age", they: "Ali’s age depends on it", ks: []),
        Story(s: "Jo always has more cards than Kim.", X: "Kim’s cards", Y: "Jo’s cards", x1: "", y1: "", xl: "k", yl: "j", the: "Kim’s cards", they: "Jo’s cards depend on them", ks: []),
    ]
    /// The stops the handle is dragged to.
    public static let stops = [2, 4, 6]

    /// kind: 0 times (y = k·x), 1 plus (y = x + c). `back`: the last line asks which x gives y; `xs` that x.
    public static func numbers(kind: Int, st: Int, k: Int = 1, c: Int = 0, back: Bool = false, xs: Int = 20) -> Numbers {
        ["kind": Double(kind), "st": Double(st), "k": Double(k), "c": Double(c), "back": back ? 1 : 0, "xs": Double(xs)]
    }

    public struct Parts: Sendable {
        public let kind: Int, st: Int, k: Int, c: Int, back: Bool, xs0: Int
        public init(_ x: Numbers) {
            kind = Eq6.int(x, "kind", 0); st = Eq6.int(x, "st", 0); k = Eq6.int(x, "k", 3); c = Eq6.int(x, "c", 0)
            back = Eq6.int(x, "back", 0) == 1; xs0 = Eq6.int(x, "xs", 20)
        }
        public var times: Bool { kind == 0 }
        public var S: Story { times ? Depend6.times[min(st, 3)] : Depend6.plus[min(st, 1)] }
        public func f(_ h: Int) -> Int { times ? k * h : h + c }
        /// What a square up is worth: 5 for rules that grow by 5, 10 or 15.
        public var ys: Int { times && k >= 5 ? 5 : 1 }
        /// The x past the paper (20, or the backwards one) and its y.
        public var xs: Int { back ? xs0 : 20 }
        public var ysv: Int { f(xs) }
        public func unitX(_ h: Int) -> String { times && h == 1 ? S.x1 : S.X }
        public func unitY(_ y: Int) -> String { times && y == 1 ? S.y1 : S.Y }
        /// The readout while the handle is held: "2 hours · 6 miles", "sister’s age 2 · Ali’s age 7".
        public func read(_ h: Int) -> String { times ? "\(h) \(unitX(h)) · \(f(h)) \(unitY(f(h)))" : "\(S.X) \(h) · \(S.Y) \(f(h))" }
        public var rule: String { times ? "\(S.yl) = \(k) × \(S.xl)" : "\(S.yl) = \(S.xl) + \(c)" }
        public var stopSay: String { "Drag \(S.the) to 2, 4 and 6. The table writes each stop." }
        public let ruleSay = "Write the rule. Use the table."
        public var pastSay: String { back ? "Which \(S.xl) makes \(S.yl) = \(ysv)?" : "Use the rule past the paper." }
        public var why: String { "You change \(S.the); \(S.they): \(rule)." }
        public func stopped(_ h: Int) -> String? { Depend6.stops.contains(h) ? nil : "That’s \(h) \(unitX(h)). Stop on 2, 4 and 6." }
        /// The rule's number written (nil: right).
        public func ruled(_ v: Int) -> String? {
            if v == (times ? k : c) { return nil }
            if times && v == 2 * k - 2 { return "\(S.yl) = \(S.xl) + \(v) works at 2 \(S.X), but at 4 \(S.X) it gives \(4 + v), not \(4 * k)." }
            if times { return "\(S.yl) = \(v) × \(S.xl) makes \(2 * v) \(unitY(2 * v)) at 2 \(S.X). The table says \(2 * k)." }
            return "\(S.yl) = \(S.xl) + \(v) makes \(2 + v) at \(S.xl) = 2. The table says \(2 + c)."
        }
        /// The value past the paper written (nil: right).
        public func past(_ v: Int) -> String? {
            if back {
                if v == xs { return nil }
                if v == f(ysv) { return "That’s \(S.yl) when \(S.xl) is \(ysv). Here \(S.yl) is \(ysv)." }
                return times ? "\(k) × \(S.xl) = \(ysv): which \(S.xl)?" : "\(S.xl) + \(c) = \(ysv): which \(S.xl)?"
            }
            if v == ysv { return nil }
            if times && v * k == 20 { return "That’s \(S.xl) when \(S.yl) is 20. Here \(S.xl) is 20." }
            return "Use the rule: \(S.yl) = \(times ? "\(k) × 20" : "20 + \(c)")."
        }
    }

    /// Problems 1–3 times rules (k 2 or 3); 4–6 adding rules (c 1–20); 7+ either, any k, and half the time backwards
    /// (which x gives y, x 12–20).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let kind = i < 3 ? 0 : i < 6 ? 1 : r(0, 1)
        let back = i >= 6 && r(0, 1) == 1, xs = r(12, 20)
        if kind == 0 {
            let list = times.indices.filter { i >= 3 || times[$0].ks.contains { $0 <= 3 } }, st = Eq6.pick(list, &rng)
            let k = Eq6.pick(times[st].ks.filter { i >= 3 || $0 <= 3 }, &rng)
            return numbers(kind: 0, st: st, k: k, back: back, xs: xs)
        }
        return numbers(kind: 1, st: r(0, 1), c: r(1, 20), back: back, xs: xs)
    }

    public static let spec = LessonSpec(id: "g6-depend", title: "Two quantities", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text("\(s.S.X) and \(s.S.Y)")] },
        idea: { _ in "One amount depends on the other: a rule says how." },
        depends: ["g6-ratiotable", "g6-eval"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { !Parts($0).back }), CheckItem(6, when: { Parts($0).back })]) { x in
        let s = Parts(x)
        let stopHint = "Let go on 2, then 4, then 6."
        let ask = LessonStep(StepWords(say: s.stopSay, hint: stopHint, action: "Let’s find out"), picture: ["at": 0])
        func stop(_ j: Int) -> LessonStep {
            LessonStep(StepWords(say: s.stopSay, hint: stopHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("h")], expected: ["h": Double(Depend6.stops[j])], hint: stopHint, explain: s.read(Depend6.stops[j]),
                                   check: { v in
                                       guard let h = v["h"] else { return .soft(s.stopSay) }
                                       return s.stopped(Int(h.rounded())).map { .wrong($0) } ?? .right
                                   }, byHand: true),
                picture: ["at": Double(1 + j)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let ruleHint = s.times ? "Each \(s.S.xl) makes the same more: \(s.S.yl) is how many times \(s.S.xl)?" : "How much more is \(s.S.yl) than \(s.S.xl)?"
        let rulePrompt: MathLine = s.times ? [.text(s.S.yl), .op("="), .box("r"), .op("×"), .text(s.S.xl)] : [.text(s.S.yl), .op("="), .text(s.S.xl), .op("+"), .box("r")]
        let rule = LessonStep(StepWords(say: s.ruleSay, hint: ruleHint, action: "Check"),
            answer: AnswerTask(prompt: rulePrompt, expected: ["r": Double(s.times ? s.k : s.c)], hint: ruleHint, explain: s.rule,
                               check: { v in
                                   guard let r = v["r"] else { return .soft("Write the number.") }
                                   return s.ruled(Int(r.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pastHint = s.back ? "Which \(s.S.xl) does the rule turn into \(s.ysv)?" : "Put 20 into the rule."
        let pastPrompt: MathLine = s.back ? [.text(s.S.xl), .op("="), .box("p")] : [.text(s.S.yl), .op("="), .box("p")]
        let past = LessonStep(StepWords(say: s.pastSay, hint: pastHint, action: "Check"),
            answer: AnswerTask(prompt: pastPrompt, expected: ["p": Double(s.back ? s.xs : s.ysv)], hint: pastHint, explain: s.rule,
                               check: { v in
                                   guard let p = v["p"] else { return .soft("Write the number.") }
                                   return s.past(Int(p.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [ask, stop(0), stop(1), stop(2), rule, past,
                LessonStep(StepWords(say: s.why, hint: "The rule turns one amount into the other.", action: "Next problem"), picture: ["at": 6])]
    }
}
