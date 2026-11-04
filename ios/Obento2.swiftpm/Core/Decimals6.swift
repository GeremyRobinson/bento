import Foundation

/// What 6th grade's Long division and decimals chapter shares (design/grade6.md chapter 3, the preview
/// design/prototype/grade6-ch3.html): exact decimals (no float sums anywhere) and the places' names.
public struct Dec6: Equatable, Hashable, Sendable {
    /// m / 10^p, with no 0 at the end of its decimals.
    public let m: Int, p: Int
    public init(_ m: Int, _ p: Int) {
        var m = m, p = p
        while p < 0 { m *= 10; p += 1 }
        while p > 0 && m % 10 == 0 { m /= 10; p -= 1 }
        self.m = m; self.p = p
    }
    /// As school writes it: "8.64", "0.05", "975".
    public var s: String {
        guard p > 0 else { return String(m) }
        let t = String(repeating: "0", count: max(0, p + 1 - String(m).count)) + String(m)
        return t.dropLast(p) + "." + t.suffix(p)
    }
    /// × 10^k (÷ when k < 0).
    public func times10(_ k: Int) -> Dec6 { Dec6(m, p - k) }
    /// How many digits it has before its point ("0.96" has 1).
    public var intDigits: Int { s.split(separator: ".", omittingEmptySubsequences: false)[0].count }
    public var double: Double { Double(m) / pow(10, Double(p)) }
    /// Its digit in place e (0 the ones, −1 the tenths).
    public func digit(_ e: Int) -> Int {
        if e < -p { return 0 }
        return (m / Dec6.pow10(e + p)) % 10
    }
    public static func pow10(_ k: Int) -> Int { k <= 0 ? 1 : (1...k).reduce(1) { a, _ in a * 10 } }
}

/// The places' names, from the hundred thousands to the thousandths (e is the power of ten).
public enum Place6 {
    static let names: [Int: (String, String)] = [5: ("hundred thousand", "hundred thousands"), 4: ("ten thousand", "ten thousands"),
        3: ("thousand", "thousands"), 2: ("hundred", "hundreds"), 1: ("ten", "tens"), 0: ("one", "ones"), -1: ("tenth", "tenths"),
        -2: ("hundredth", "hundredths"), -3: ("thousandth", "thousandths")]
    /// Its name for n of them ("1 ten", "5 tens").
    public static func name(_ e: Int, _ n: Int = 2) -> String { let x = names[e] ?? ("", ""); return n == 1 ? x.0 : x.1 }
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func rows(_ k: Int) -> String { k == 1 ? "1 row" : "\(k) rows" }
}

// MARK: - Long division (and Dividing decimals' sharing)

/// Long division as rows (g6-longdiv, 6.NS.2; Dividing decimals' too): the amount being shared is squares in rows as long
/// as the divisor, so a quotient digit is a count of rows and what's left is the short last row. From the first digits
/// the divisor goes into, place by place: drag down the rows that fit (the digit), write what's left; the next digit
/// comes down beside it. Dividing decimals breaks what's left after the last digit into tenths (a 0 written after the
/// point) and goes on.
///
/// Every step's picture has "at": 0 the question, 1 start, 2 the rows of place "t", 3 what's left there, 4 done, 5 make
/// the divisor whole, 6 break what's left into place "t".
public enum LongDiv6 {
    /// One place's sharing: the digit's index in the number, its place, the amount there (what was left × 10 and the
    /// digit that came down), the rows that fit, what they take and what's left; `app` when its digit is a 0 written
    /// after the point (the ones left broken into tenths).
    public struct Place: Equatable, Sendable {
        public let j: Int, e: Int, A: Int, carry: Int, qd: Int, prod: Int, left: Int, app: Bool
    }

    public struct Plan: Equatable, Sendable {
        public let d: Int
        /// The number shared (Dividing decimals: once the divisor is whole), its digits (the 0s written after the point
        /// included), how many it has before its point, how many are its own.
        public let N: Dec6, digs: [Int], intLen: Int, L0: Int
        /// The digit the sharing starts at (its index), and every place's sharing.
        public let j0: Int, places: [Place]

        public init(d: Int, N: Dec6, goOn: Bool) {
            self.d = d; self.N = N
            let base = N.s.replacingOccurrences(of: ".", with: "")
            var digs = base.compactMap { $0.wholeNumberValue }
            L0 = digs.count; intLen = N.intDigits
            j0 = Plan.start(digs, d) ?? max(0, digs.count - 1)
            var places: [Place] = []
            var j = j0, A = Int(digs[0...j0].map(String.init).joined()) ?? 0, carry = 0, app = false
            while true {
                let qd = A / d, left = A - qd * d
                places.append(Place(j: j, e: intLen - 1 - j, A: A, carry: carry, qd: qd, prod: qd * d, left: left, app: app))
                if j + 1 < digs.count { carry = left * 10; A = carry + digs[j + 1]; app = false }
                else if goOn && left > 0 && places.count < 8 { digs.append(0); carry = left * 10; A = carry; app = true }
                else { break }
                j += 1
            }
            self.digs = digs; self.places = places
        }
        /// The fewest digits the divisor goes into (their last index), nil if it never does.
        public static func start(_ digs: [Int], _ d: Int) -> Int? {
            var v = 0
            for (j, x) in digs.enumerated() { v = v * 10 + x; if v >= d { return j } }
            return nil
        }
        /// The number made of the first n digits.
        public func prefix(_ n: Int) -> Int { digs.prefix(max(0, n)).reduce(0) { $0 * 10 + $1 } }
        /// What's left at the end (Long division's remainder).
        public var r: Int { places.last?.left ?? 0 }
        /// The most rows any place's amount takes (with a row more for dragging past it).
        public var mostRows: Int { places.map { ($0.A + d - 1) / d }.max() ?? 1 }

        public var startSay: String { "Start where \(d) goes in." }
        /// What tapping the digits up to index j (j + 1 of them) says (nil: the right start).
        public func started(_ n: Int) -> Verdict {
            if n <= 0 { return .soft(startSay) }
            if n < j0 + 1 { return .wrong("\(d) doesn’t go into \(prefix(n)). Take one more digit.") }
            if n > j0 + 1 { return .wrong("Fewer digits: \(d) already goes into \(prefix(n - 1)).") }
            return .right
        }
        public func rowsSay(_ t: Int) -> String {
            let P = places[t], act = P.A < d ? "Not one row of \(d) fits: tap to write 0." : "Drag down a row of \(d) at a time."
            guard t > 0 else { return act }
            let lf = places[t - 1].left, dg = P.A - P.carry, e = P.e, nm = Place6.name
            let pre = P.app ? "\(lf) \(nm(e + 1, lf)) = \(lf * 10) \(nm(e, 2))."
                : lf > 0 ? "\(lf) \(nm(e + 1, lf)) left = \(lf * 10) \(nm(e, 2)), and \(dg) more: \(P.A) \(nm(e, P.A))."
                : "Nothing left, and \(dg) \(nm(e, dg)) \(dg == 1 ? "comes" : "come") down."
            return "\(pre) \(act)"
        }
        /// k rows dragged down at place t: what it says.
        public func rowsDragged(_ t: Int, _ k: Int) -> Verdict {
            let P = places[t]
            if k == P.qd { return .right }
            if k == 0 { return .soft(rowsSay(t)) }
            if k > P.qd { return .wrong("\(Place6.rows(k)) is \(k * d). There are only \(P.A).") }
            return .wrong("\(P.A - k * d) are left: another row fits.")
        }
        public func leftMiss(_ t: Int) -> String { "\(places[t].A) − \(places[t].prod): count the squares not filled in." }
        public func breakSay(_ t: Int) -> String {
            let lf = places[t - 1].left, e = places[t].e, them = lf == 1 ? "it" : "them"
            return "\(lf) \(Place6.name(e + 1, lf)) left. Break \(them) into \(Place6.name(e)): tap \(them)."
        }
    }

    /// The steps from the start (a shift before it is the caller's): start, then each place's rows and what's left (a
    /// break first when its digit is a 0 written after the point), then the last words.
    static func steps(_ plan: Plan, ask: String, done: String, before: [LessonStep] = []) -> [LessonStep] {
        var steps = [LessonStep(StepWords(say: ask, hint: "Share a place at a time, from the left.", action: "Let’s find out"), picture: ["at": 0])] + before
        let startHint = "\(plan.d) goes into the first number that’s \(plan.d) or more."
        steps.append(LessonStep(StepWords(say: plan.startSay, hint: startHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(plan.j0 + 1)], hint: startHint,
                               explain: "\(plan.d) goes into \(plan.prefix(plan.j0 + 1)).",
                               check: { v in plan.started(Place6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        for (t, P) in plan.places.enumerated() {
            if P.app {
                steps.append(LessonStep(StepWords(say: plan.breakSay(t), hint: "Each one left breaks into ten.", action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: "Each one left breaks into ten.",
                                       explain: "\(plan.places[t - 1].left) left = \(P.A) \(Place6.name(P.e, P.A)).",
                                       check: { v in Place6.int(v, "x", 0) == 1 ? .right : .soft(plan.breakSay(t)) }, byHand: true),
                    picture: ["at": 6, "t": Double(t)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            }
            let rowsHint = "Drag down until another row of \(plan.d) won’t fit."
            steps.append(LessonStep(StepWords(say: plan.rowsSay(t), hint: rowsHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(P.qd)], hint: rowsHint,
                                   explain: "\(Place6.rows(P.qd)) of \(plan.d) fit in \(P.A).",
                                   check: { v in plan.rowsDragged(t, Place6.int(v, "x", 0)) }, byHand: true),
                picture: ["at": 2, "t": Double(t)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            let miss = plan.leftMiss(t)
            steps.append(LessonStep(StepWords(say: "Write what’s left.", hint: "Count the squares not filled in.", action: "Check"),
                answer: AnswerTask(prompt: [.num(Double(P.A)), .op("−"), .num(Double(P.prod)), .op("="), .box("l")], expected: ["l": Double(P.left)],
                                   hint: "Count the squares not filled in.", explain: "\(P.A) − \(P.prod) = \(P.left)",
                                   check: { v in Place6.int(v, "l") == P.left ? .right : .wrong(miss) }, incomplete: "Write the number in the box."),
                picture: ["at": 3, "t": Double(t)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: done, hint: "Share a place at a time; what’s left joins the next place.", action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}

/// Long division (g6-longdiv, 6.NS.2; new): n ÷ d, d 12–39. Problems 1–3 d 12–19 and a quotient 12–49 (a 3-digit
/// number); then 3-digit quotients (4- and 5-digit numbers), from problem 4 a quotient digit may be 0, from problem 7 a
/// remainder.
public enum LongDivision6 {
    public static func numbers(d: Int, q: Int, r: Int = 0) -> Numbers { ["d": Double(d), "q": Double(q), "r": Double(r)] }

    public struct Parts: Sendable {
        public let d: Int, q: Int, r: Int
        public init(_ x: Numbers) { d = Place6.int(x, "d", 23); q = Place6.int(x, "q", 324); r = Place6.int(x, "r", 0) }
        public var n: Int { d * q + r }
        public var plan: LongDiv6.Plan { LongDiv6.Plan(d: d, N: Dec6(n, 0), goOn: false) }
        public var why: String {
            let ps = plan.places.map { "\($0.qd) \(Place6.name($0.e, $0.qd))" }
            let list = ps.count > 1 ? ps.dropLast().joined(separator: ", ") + " and " + ps.last! : ps[0]
            return "\(list): \(q) rows of \(d)\(r > 0 ? " and \(r) more" : "") make \(n)."
        }
    }

    /// The preview's generator (genLongDiv).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        while true {
            let d = i < 3 ? Int.random(in: 12...19, using: &rng) : Int.random(in: 12...39, using: &rng)
            var q = i < 3 ? Int.random(in: 12...49, using: &rng) : Int.random(in: 100...999, using: &rng)
            // from problem 4 a quotient digit may be 0 (in the tens or the ones)
            if i >= 3 && Int.random(in: 0..<10, using: &rng) < 4 {
                var s = Array(String(q)); s[Int.random(in: 1...2, using: &rng)] = "0"; q = Int(String(s)) ?? q
            }
            let r = i >= 6 ? Int.random(in: 1...(d - 1), using: &rng) : 0, n = d * q + r
            if i < 3 ? n > 999 : (n < 1000 || n > 99999) { continue }
            return numbers(d: d, q: q, r: r)
        }
    }

    public static let spec = LessonSpec(id: "g6-longdiv", title: "Long division", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.num(Double(s.n)), .op("÷"), .num(Double(s.d))] },
        idea: { _ in "Share a place at a time: a digit is how many rows fit, and what's left joins the next place." },
        depends: ["g5-divide", "g4-share"],
        check: [CheckItem(3, when: { String(Parts($0).q).contains("0") && Parts($0).r == 0 }), CheckItem(3, when: { Parts($0).n >= 10000 }),
                CheckItem(6, when: { Parts($0).r > 0 }), CheckItem(3, when: { !String(Parts($0).q).contains("0") })]) { x in
        let s = Parts(x)
        return LongDiv6.steps(s.plan, ask: s.plan.startSay, done: s.why)
    }
}

/// Dividing decimals (g6-decdiv, 6.NS.3; new): n ÷ V, the quotient ending by the hundredths. Problems 1–3 a whole number
/// ÷ one digit with a .5 or .25 answer (18 ÷ 4 = 4.5); 4–6 a decimal ÷ a whole number (8.64 ÷ 12 = 0.72); 7+ a decimal
/// ÷ a decimal (9.75 ÷ 1.5 = 6.5), made whole first. Numbers: d (the divisor once whole), q100 (the quotient × 100),
/// s (how many places both move).
public enum DivideDec6 {
    public static func numbers(d: Int, q100: Int, s: Int = 0) -> Numbers { ["d": Double(d), "q100": Double(q100), "s": Double(s)] }

    public struct Parts: Sendable {
        public let d: Int, q100: Int, s: Int
        public init(_ x: Numbers) { d = Place6.int(x, "d", 4); q100 = Place6.int(x, "q100", 450); s = Place6.int(x, "s", 0) }
        public var q: Dec6 { Dec6(q100, 2) }
        /// The problem's numbers, and the divisor as it's given.
        public var n: Dec6 { Dec6(d * q100, 2 + s) }
        public var V: Dec6 { Dec6(d, s) }
        /// Both made whole: the number shared.
        public var N: Dec6 { n.times10(s) }
        public var plan: LongDiv6.Plan { LongDiv6.Plan(d: d, N: N, goOn: true) }
        /// The most the digits may move (the chart runs from the hundreds).
        public var kmax: Int { min(s + 1, 3 - n.intDigits) }
        public var shiftSay: String { "Make the divisor whole." }
        public func shifted(_ k: Int) -> Verdict {
            if k == s { return .right }
            if k <= 0 { return .soft(shiftSay) }
            return k < s ? .wrong("\(V.times10(k).s) still has a point.") : .wrong("\(d) is already whole.")
        }
        public var why: String {
            let P = plan
            if let fa = P.places.firstIndex(where: { $0.app }), fa > 0 {
                let lf = P.places[fa - 1].left, e = P.places[fa].e
                return "The \(lf) \(Place6.name(e + 1, lf)) left \(lf == 1 ? "is" : "are") \(lf * 10) \(Place6.name(e)), so the sharing goes on past the point."
            }
            return "Tenths share into tenths, so the point goes straight up: \(N.s) ÷ \(d) = \(q.s)."
        }
    }

    /// The preview's generator (genDecDiv); a decimal ÷ a decimal keeps its number in the chart's places once moved.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        while true {
            var x: Numbers
            if i < 3 {
                let d = r(2, 9), q100 = r(1, 9) * 100 + [50, 25, 75][r(0, 2)]
                if (d * q100) % 100 != 0 { continue }
                x = numbers(d: d, q100: q100)
            } else if i < 6 {
                let d = r(2, 25), q100 = r(11, 999)
                if d % 10 == 0 || q100 % 100 == 0 || (d * q100) % 100 == 0 || d * q100 > 9999 { continue }
                x = numbers(d: d, q100: q100)
            } else {
                let s = r(0, 3) != 0 ? 1 : 2, d = r(2, 25), q100 = r(11, 999)
                if d % 10 == 0 || q100 % 100 == 0 { continue }
                let N = Dec6(d * q100, 2 + s)
                if N.p == 0 || N.p > 3 || d * q100 > 99999 || N.intDigits > 2 || N.intDigits + s > 3 { continue }
                x = numbers(d: d, q100: q100, s: s)
            }
            let P = Parts(x)
            if LongDiv6.Plan.start(P.N.s.replacingOccurrences(of: ".", with: "").compactMap { $0.wholeNumberValue }, P.d) == nil { continue }
            return x
        }
    }

    public static let spec = LessonSpec(id: "g6-decdiv", title: "Dividing decimals", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(s.n.s), .op("÷"), .text(s.V.s)] },
        idea: { _ in "Share as long division does; what's left after the ones breaks into tenths, so the sharing goes on past the point." },
        depends: ["g6-longdiv", "g5-divdec"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { Parts($0).N.p > 0 }), CheckItem(6, when: { Parts($0).N.p == 0 })]) { x in
        let s = Parts(x), plan = s.plan
        var before: [LessonStep] = []
        if s.s > 0 {
            let hint = "Move both until \(s.V.s) has no point."
            before.append(LessonStep(StepWords(say: s.shiftSay, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.s)], hint: hint,
                                   explain: "× \(Dec6.pow10(s.s)): \(s.N.s) ÷ \(s.d)", check: { v in s.shifted(Place6.int(v, "x", 0)) }, byHand: true),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        return LongDiv6.steps(plan, ask: s.s > 0 ? s.shiftSay : plan.startSay, done: s.why, before: before)
    }
}

// MARK: - Adding and subtracting decimals

/// Adding and subtracting decimals (g6-decaddsub, 6.NS.3; new): five place columns (tens to thousandths), a disc a one of
/// its column's place. Fill the empty places with 0s; slide b's discs up into a's columns (adding: tap ten to close them
/// into one of the next place; taking away: the covered ones are crossed out, and a short column waits while one of the
/// place to its left is broken into ten); then write the answer under the line.
///
/// Every step's picture has "at": 0 the question, 1 fill, 2 slide (phase "ph"), 3 close (phase "ph"), 4 break (phase
/// "ph"), 5 write, 6 done.
public enum DecAddSub6 {
    public static let places = [1, 0, -1, -2, -3]
    public static func numbers(a: Dec6, b: Dec6, add: Bool) -> Numbers {
        ["am": Double(a.m), "ap": Double(a.p), "bm": Double(b.m), "bp": Double(b.p), "op": add ? 0 : 1]
    }

    /// The columns: each place's discs on top (0 a's, 1 b's slid in, 2 new: closed or broken into), how many of them are
    /// crossed out (the last ones), b's discs still waiting, and the school's marks (a broken digit's change, a carry).
    public struct Cols: Equatable, Sendable {
        public var items: [Int: [Int]] = [:], crossed: [Int: Int] = [:], waiting: [Int: Int] = [:], broke: [Int: Int] = [:], carried: [Int: Int] = [:], lent: [Int: Int] = [:]
        public func live(_ e: Int) -> Int { (items[e]?.count ?? 0) - (crossed[e] ?? 0) }
        /// The place that needs breaking into: the smallest with discs still waiting.
        public var needy: Int? { DecAddSub6.places.reversed().first { (waiting[$0] ?? 0) > 0 } }
        /// The nearest place left of n with any discs.
        public func lender(_ n: Int) -> Int? { ((n + 1)...max(n + 1, 1)).first { live($0) > 0 } }
        /// The biggest-but-smallest place with ten or more (the one to close first).
        public var full: Int? { DecAddSub6.places.reversed().first { (items[$0]?.count ?? 0) >= 10 } }

        mutating func slide(add: Bool) {
            for e in DecAddSub6.places {
                let w = waiting[e] ?? 0
                guard w > 0 else { continue }
                if add { items[e, default: []] += Array(repeating: 1, count: w); waiting[e] = 0 }
                else if live(e) >= w { crossed[e, default: 0] += w; waiting[e] = 0 }
            }
        }
        /// Ten of place e close into one of the next.
        public mutating func close(_ e: Int) {
            items[e]?.removeLast(10); items[e + 1, default: []].append(2); carried[e + 1, default: 0] += 1
        }
        /// One of place e breaks into ten of the place after it.
        public mutating func breakOne(_ e: Int) {
            let lv = live(e)
            items[e]?.remove(at: lv - 1); broke[e, default: 0] -= 1; lent[e, default: 0] += 1
            items[e - 1, default: []].insert(contentsOf: Array(repeating: 2, count: 10), at: live(e - 1)); broke[e - 1, default: 0] += 10
        }
    }

    public enum Phase: Equatable, Sendable { case slide, close, breaks }

    public struct Parts: Sendable {
        public let a: Dec6, b: Dec6, add: Bool
        public init(_ x: Numbers) {
            a = Dec6(Place6.int(x, "am", 124), Place6.int(x, "ap", 1)); b = Dec6(Place6.int(x, "bm", 375), Place6.int(x, "bp", 2))
            add = Place6.int(x, "op", 0) == 0
        }
        /// The places both are written to.
        public var P: Int { max(a.p, b.p) }
        public var needA: Int { P - a.p }
        public var needB: Int { P - b.p }
        /// A number's biggest place.
        public static func top(_ x: Dec6) -> Int { x.intDigits - 1 }
        /// The answer, in P places.
        public var R: Int { let A = a.m * Dec6.pow10(P - a.p), B = b.m * Dec6.pow10(P - b.p); return add ? A + B : A - B }
        public var answer: Dec6 { Dec6(R, P) }
        public var start: Cols {
            var c = Cols()
            for e in DecAddSub6.places { c.items[e] = Array(repeating: 0, count: a.digit(e)); c.waiting[e] = b.digit(e) }
            return c
        }
        /// The hands' phases after the fill (each a step) and the columns before each; `end` after them all.
        public var phases: (list: [Phase], before: [Cols], end: Cols) {
            var c = start, list: [Phase] = [], before: [Cols] = []
            func push(_ p: Phase) { list.append(p); before.append(c) }
            push(.slide); c.slide(add: add)
            if add {
                if c.full != nil { push(.close); while let e = c.full { c.close(e) } }
            } else {
                var guardN = 0
                while let n = c.needy, guardN < 6 {
                    guardN += 1
                    push(.breaks)
                    while c.live(n) < (c.waiting[n] ?? 0), let l = c.lender(n) { c.breakOne(l) }
                    push(.slide); c.slide(add: false)
                }
            }
            return (list, before, c)
        }

        public var fillSay: String { "Fill the empty places." }
        /// The fill's taps: what a wrong one says (code 2: a 0 in front of a, 3: of b, 4: past the other's places).
        public func filled(_ code: Int) -> Verdict {
            switch code {
            case 1: return .right
            case 2: return .wrong("No 0 in front: \(a.s) starts at the \(Place6.name(Parts.top(a))).")
            case 3: return .wrong("No 0 in front: \(b.s) starts at the \(Place6.name(Parts.top(b))).")
            case 4: return .wrong("Only the places the other number has.")
            default: return .soft(fillSay)
            }
        }
        public var slideSay: String { add ? "Slide them in." : "Slide them over to take away." }
        public static func closeSay(_ e: Int) -> String { "Tap ten \(Place6.name(e)): they close into a \(Place6.name(e + 1, 1))." }
        /// A close tap's code: 1 done, 1000 + 100 (e + 3) + n a column of n under ten.
        public static func closed(_ code: Int) -> Verdict {
            if code == 1 { return .right }
            guard code >= 1000 else { return .soft("Tap ten of a place.") }
            let e = (code - 1000) / 100 - 3, n = (code - 1000) % 100
            return .wrong("Only \(n) \(Place6.name(e, n)): it takes ten to close.")
        }
        public static func breakSay(_ c: Cols) -> String {
            guard let n = c.needy else { return "Break one into ten." }
            let lv = c.live(n), lend = c.lender(n) ?? n + 1
            // the preview's two lines ("Break one into ten." and "Only 3 tenths. Break a one.") said as one
            return c.live(n + 1) > 0 || lend == n + 1 ? "Only \(lv) \(Place6.name(n, lv)): break a \(Place6.name(n + 1, 1)) into ten."
                : "Only \(lv) \(Place6.name(n, lv)), and no \(Place6.name(n + 1)): break a \(Place6.name(lend, 1)) into ten first."
        }
        /// A break tap's code: 1 done, 2 at or right of the place that needs it, 2000 + 10 (e + 3) + (lender + 3) a place
        /// with none, 3000 + … one further than the nearest.
        public static func broken(_ code: Int) -> Verdict {
            if code == 1 { return .right }
            if code == 2 { return .wrong("Break one from the place to its left.") }
            guard code >= 2000 else { return .soft("Break one into ten.") }
            let e = (code % 1000) / 10 - 3, lend = code % 10 - 3
            return code < 3000 ? .wrong("No \(Place6.name(e)) to break. Break a \(Place6.name(lend, 1)) first.")
                : .wrong("Break the nearest place that has some: a \(Place6.name(lend, 1)).")
        }
        public var writeSay: String { add ? "Write the total under the line." : "Write what’s left under the line." }
        /// The typed answer, as m in P places (nil: more places than that).
        public func typedM(_ v: Double) -> Int? {
            let x = v * Double(Dec6.pow10(P)), r = x.rounded()
            return abs(x - r) < 1e-6 ? Int(r) : nil
        }
        public func written(_ v: Double) -> Verdict {
            let m = typedM(v)
            if m == R { return .right }
            if add {
                let noCarry = DecAddSub6.places.reduce(0) { $0 + (a.digit($1) + b.digit($1)) % 10 * Dec6.pow10($1 + P) }
                return .wrong(m == noCarry ? "Each ten you closed is one more in the next place." : "Count the discs in each column.")
            }
            let naive = DecAddSub6.places.reduce(0) { $0 + abs(a.digit($1) - b.digit($1)) * Dec6.pow10($1 + P) }
            let end = phases.end
            let forgot = DecAddSub6.places.contains { (end.lent[$0] ?? 0) > 0 && m == R + Dec6.pow10($0 + P) }
            if m == naive && naive != R { return .wrong("In each column, take from the top number: that’s why it was broken.") }
            return .wrong(forgot ? "A broken place has one less now." : "Count what’s left in each column, not the crossed ones.")
        }
        public var why: String { add ? "Points under points, so tenths add to tenths." : "Points under points, so each place takes from its own place." }
        /// A carry over the point (the tenths close into a one).
        public var carriesOverPoint: Bool { add && phases.end.carried[0] != nil }
    }

    /// The preview's generator (genAddSub): problems 1–3 add a number with fewer places to one with more, one carry,
    /// under 100; 4–6 take away with a 0 to write and one break; 7+ in turn an add, one across a 0, a whole number minus
    /// a decimal, any take-away.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let kind = i < 3 ? "add" : i < 6 ? "sub1" : ["add", "sub0", "subw", "sub"][(i - 6) % 4]
        while true {
            var pa = 1, pb = 2
            if i < 3 || kind == "sub1" { pa = 1; pb = 2 }
            else if kind == "subw" { pa = 0; pb = r(1, 2) }
            else { pa = r(kind == "sub0" ? 1 : 0, 3); pb = r(1, 3); if pa == pb || max(pa, pb) < 2 { continue } }
            let add = kind == "add"
            func num(_ p: Int, _ lo: Int, _ hi: Int) -> Dec6 {
                let w = r(lo, hi)
                if p == 0 { return Dec6(w, 0) }
                var f = 0
                repeat { f = r(1, Dec6.pow10(p) - 1) } while f % 10 == 0
                return Dec6(w * Dec6.pow10(p) + f, p)
            }
            let a = num(pa, add ? 1 : 3, add ? 59 : 99), b = num(pb, 1, add ? 39 : 60)
            if a.p != pa || b.p != pb { continue }
            let P = max(pa, pb), Am = a.m * Dec6.pow10(P - pa), Bm = b.m * Dec6.pow10(P - pb)
            var borrows = 0, across = false, carries = 0, k = 0
            for e in -P...1 {
                let x = a.digit(e), y = b.digit(e)
                if add { k = x + y + k >= 10 ? 1 : 0; carries += k; continue }
                if x - k < y { borrows += 1; if a.digit(e + 1) == 0 { across = true }; k = 1 } else { k = 0 }
            }
            if add {
                if Am + Bm >= 100 * Dec6.pow10(P) { continue }
                if i < 3 ? carries != 1 : carries < 1 { continue }
            } else {
                if Bm >= Am || Am - Bm < Dec6.pow10(P) / 10 { continue }
                if kind == "sub1" && (borrows != 1 || across) { continue }
                if kind == "sub0" && !across { continue }
                if (kind == "sub" || kind == "subw") && borrows < 1 { continue }
            }
            return numbers(a: a, b: b, add: add)
        }
    }

    public static let spec = LessonSpec(id: "g6-decaddsub", title: "Adding and subtracting decimals", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(s.a.s), .op(s.add ? "+" : "−"), .text(s.b.s)] },
        idea: { _ in "Points under points, so each place adds to or takes from its own place." },
        depends: ["g5-adddec"],
        check: [CheckItem(0, when: { Parts($0).carriesOverPoint }), CheckItem(3), CheckItem(7), CheckItem(8)]) { x in
        let s = Parts(x), ph = s.phases
        let fillHint = "Write 0s until both have as many places."
        var steps = [LessonStep(StepWords(say: s.fillSay, hint: fillHint, action: "Let’s find out"), picture: ["at": 0])]
        steps.append(LessonStep(StepWords(say: s.fillSay, hint: fillHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: fillHint, explain: "\(s.a.s) and \(s.b.s), both to \(Place6.name(-s.P)).",
                               check: { v in s.filled(Place6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        for (k, p) in ph.list.enumerated() {
            switch p {
            case .slide:
                let hint = "Drag the bottom number’s discs up onto the top number."
                steps.append(LessonStep(StepWords(say: s.slideSay, hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint,
                                       check: { v in Place6.int(v, "x", 0) == 1 ? .right : .soft("Slide them up onto the top number.") }, byHand: true),
                    picture: ["at": 2, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .close:
                let e = ph.before[k].full ?? 0, hint = "A column with ten or more closes ten into one of the next place."
                steps.append(LessonStep(StepWords(say: Parts.closeSay(e), hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint, check: { v in Parts.closed(Place6.int(v, "x", 0)) }, byHand: true),
                    picture: ["at": 3, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .breaks:
                let hint = "Tap one in the nearest place to the left that has some."
                steps.append(LessonStep(StepWords(say: Parts.breakSay(ph.before[k]), hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint, check: { v in Parts.broken(Place6.int(v, "x", 0)) }, byHand: true),
                    picture: ["at": 4, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            }
        }
        let writeHint = s.add ? "Count the discs in each column." : "Count what’s left in each column."
        steps.append(LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.text(s.a.s), .op(s.add ? "+" : "−"), .text(s.b.s), .op("="), .box("t")], expected: ["t": s.answer.double],
                               hint: writeHint, explain: "\(s.a.s) \(s.add ? "+" : "−") \(s.b.s) = \(s.answer.s)",
                               check: { v in v["t"].map { s.written($0) } ?? .soft(s.writeSay) }, incomplete: "Write the answer under the line."),
            picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: s.why, hint: "Line up the points.", action: "Next problem"), picture: ["at": 6]))
        return steps
    }
}

// MARK: - Multiplying decimals

/// Multiplying decimals (g6-decmult, 6.NS.3; new): a × b on the place chart (hundreds or more to thousandths, the point
/// fixed). Drag a's digits left until it's whole, then b's; multiply the wholes in columns, the school way; drag the
/// product's digits right to undo both; tap 0s into the empty places between the point and the digits.
///
/// Every step's picture has "at": 0 the question, 1 a's digits, 2 b's, 3 multiply, 4 undo, 5 the 0s, 6 done.
public enum DecMult6 {
    /// `typed`: the partial products are the child's to write (from problem 4), not written for them.
    public static func numbers(a: Dec6, b: Dec6, typed: Bool) -> Numbers {
        ["am": Double(a.m), "ap": Double(a.p), "bm": Double(b.m), "bp": Double(b.p), "pt": typed ? 1 : 0]
    }

    public struct Parts: Sendable {
        public let a: Dec6, b: Dec6, typed: Bool
        public init(_ x: Numbers) {
            a = Dec6(Place6.int(x, "am", 425), Place6.int(x, "ap", 2)); b = Dec6(Place6.int(x, "bm", 36), Place6.int(x, "bp", 1))
            typed = Place6.int(x, "pt", 0) == 1
        }
        public var A: Int { a.m }
        public var B: Int { b.m }
        public var W: Int { A * B }
        public var K: Int { a.p + b.p }
        public var product: Dec6 { Dec6(W, K) }
        public var two: Bool { B >= 10 }
        public var partials: Bool { two && typed }
        public var p1: Int { A * (B % 10) }
        public var p2: Int { A * (B - B % 10) }
        /// The product's first digit's place once undone; the places between the point and it, 0s to tap.
        public var hiE: Int { String(W).count - 1 - K }
        public var zeros: [Int] { hiE < 0 ? (0..<(-hiE)).map { -$0 } : [] }
        /// The chart's biggest place.
        public var topE: Int { max(2, String(W).count - 1, String(A).count - 1) }

        public func shiftSay(_ second: Bool) -> String { second ? "Make both whole: now drag \(b.s)’s digits left." : "Make both whole: drag \(a.s)’s digits left." }
        public func shifted(_ x: Dec6, _ k: Int) -> Verdict {
            if k == x.p { return .right }
            if k <= 0 { return .soft(shiftSay(x == b && x != a)) }
            return k < x.p ? .wrong("\(x.times10(k).s) still has a point.") : .wrong("\(x.m) is already whole.")
        }
        public var multSay: String { "Multiply \(A) × \(B) the school way" + (partials ? ": write each row, then add them." : ".") }
        public func multiplied(_ v: [String: Double]) -> Verdict {
            if partials && Place6.int(v, "p1") != p1 { return .wrong("First \(A) × \(B % 10).") }
            if partials && Place6.int(v, "p2") != p2 {
                let tn = B / 10
                return .wrong(Place6.int(v, "p2") == A * tn ? "The \(tn) is \(tn) tens: \(A) × \(tn * 10) ends in 0." : "Next \(A) × \(tn * 10).")
            }
            if Place6.int(v, "t") != W { return .wrong(two ? "Add the two rows." : "Multiply \(A) by \(B) again, one place at a time.") }
            return .right
        }
        public var undoSay: String { "Undo both: drag the product’s digits right." }
        public func undone(_ k: Int) -> Verdict {
            if k == K { return .right }
            if k <= 0 { return .soft(undoSay) }
            let ma = Dec6.pow10(a.p), mb = Dec6.pow10(b.p)
            return .wrong(b.p > 0 ? "× \(ma) and × \(mb) is × \(ma * mb), so ÷ \(ma * mb)." : "× \(ma) made it \(ma) times bigger, so ÷ \(ma).")
        }
        public var zerosSay: String { "Tap the empty places to write 0s." }
        public var why: String {
            let ma = Dec6.pow10(a.p), mb = Dec6.pow10(b.p)
            return b.p > 0 ? "× \(ma) and × \(mb) made it \(ma * mb) times bigger, so the point goes back \(K) places."
                : "× \(ma) made it \(ma) times bigger, so the point goes back \(K) place\(K == 1 ? "" : "s")."
        }
        /// A factor rounded for the estimate: to a whole number, or to one digit when it's under 1.
        static func roughly(_ x: Dec6) -> Dec6 {
            func half(_ m: Int, _ d: Int) -> Int { (2 * m + d) / (2 * d) }
            return x.m >= Dec6.pow10(x.p) ? Dec6(max(1, half(x.m, Dec6.pow10(x.p))), 0) : Dec6(max(1, half(x.m, Dec6.pow10(x.p - 1))), 1)
        }
        /// "4 × 4 = 16: 15.3 is near 16."
        public var estimate: String {
            let ra = Parts.roughly(a), rb = Parts.roughly(b), v = Dec6(ra.m * rb.m, ra.p + rb.p)
            return "\(ra.s) × \(rb.s) = \(v.s): \(product.s) is near \(v.s)."
        }
    }

    /// The preview's generator (genDecMult): problems 1–3 tenths × a whole number (2.4 × 3); 4–6 tenths × tenths or
    /// hundredths × a whole number; 7+ hundredths × tenths, and a factor under 1 (0.24 × 0.4); a product of 6 digits at
    /// most. From problem 4 the partial products are the child's to write.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        while true {
            var a: Dec6, b: Dec6
            if i < 3 { a = Dec6(r(11, 99), 1); b = Dec6(r(2, 9), 0) }
            else if i < 6 {
                if r(0, 1) == 1 { a = Dec6(r(11, 99), 1); b = Dec6(r(11, 99), 1) } else { a = Dec6(r(101, 999), 2); b = Dec6(r(2, 36), 0) }
            } else if r(0, 1) == 1 { a = Dec6(r(101, 4999), 2); b = Dec6(r(11, 99), 1) }
            else { a = Dec6(r(11, 99), 2); b = Dec6(r(2, 9), 1) }
            if a.p == 0 || (i >= 3 && i < 6 && b.p == 0 && a.p != 2) || (i >= 6 && (a.p != 2 || b.p != 1)) { continue }
            if i < 3 && a.p != 1 { continue }
            if String(a.m * b.m).count > 6 { continue }
            return numbers(a: a, b: b, typed: i >= 3)
        }
    }

    public static let spec = LessonSpec(id: "g6-decmult", title: "Multiplying decimals", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(s.a.s), .op("×"), .text(s.b.s)] },
        idea: { _ in "Make both whole, multiply, then undo both: the point goes back as many places as it moved." },
        depends: ["g5-multdec", "g5-pow10"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).a.p == 1 && Parts($0).b.p == 1 }),
                CheckItem(6, when: { Parts($0).a.m < Dec6.pow10(Parts($0).a.p) || Parts($0).b.m < Dec6.pow10(Parts($0).b.p) }),
                CheckItem(6, when: { Parts($0).a.p == 2 && Parts($0).b.p == 1 && Parts($0).a.m >= 100 })]) { x in
        let s = Parts(x)
        let shiftHint = "Each column left is × 10."
        var steps = [LessonStep(StepWords(say: s.shiftSay(false), hint: shiftHint, action: "Let’s find out"), picture: ["at": 0])]
        steps.append(LessonStep(StepWords(say: s.shiftSay(false), hint: shiftHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.a.p)], hint: shiftHint, explain: "× \(Dec6.pow10(s.a.p)): \(s.A)",
                               check: { v in s.shifted(s.a, Place6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        if s.b.p > 0 {
            steps.append(LessonStep(StepWords(say: s.shiftSay(true), hint: shiftHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.b.p)], hint: shiftHint, explain: "× \(Dec6.pow10(s.b.p)): \(s.B)",
                                   check: { v in s.shifted(s.b, Place6.int(v, "x", 0)) }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let multHint = s.two ? "One row for each digit of \(s.B), then add them." : "Multiply each digit of \(s.A) by \(s.B), from the ones."
        var want: [String: Double] = ["t": Double(s.W)]
        if s.partials { want["p1"] = Double(s.p1); want["p2"] = Double(s.p2) }
        steps.append(LessonStep(StepWords(say: s.multSay, hint: multHint, action: "Check"),
            answer: AnswerTask(prompt: (s.partials ? [.box("p1"), .box("p2")] : []) + [.box("t")], expected: want, hint: multHint,
                               explain: "\(s.A) × \(s.B) = \(s.W)", check: { v in s.multiplied(v) }, incomplete: "Fill in every box."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let undoHint = "Move it back as many places as both moved."
        steps.append(LessonStep(StepWords(say: s.undoSay, hint: undoHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.K)], hint: undoHint, explain: "÷ \(Dec6.pow10(s.K)): \(s.product.s)",
                               check: { v in s.undone(Place6.int(v, "x", 0)) }, byHand: true),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        if !s.zeros.isEmpty {
            let miss = "Tap the empty places between the point and the digits."
            steps.append(LessonStep(StepWords(say: s.zerosSay, hint: miss, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: miss,
                                   check: { v in Place6.int(v, "x", 0) == 1 ? .right : Place6.int(v, "x", 0) == 2 ? .wrong(miss) : .soft(s.zerosSay) }, byHand: true),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "Count the places both moved.", action: "Next problem"), picture: ["at": 6]))
        return steps
    }
}
