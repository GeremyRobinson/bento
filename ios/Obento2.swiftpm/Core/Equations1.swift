import Foundation

/// 1st grade's chapter 2, Equations and stories (design/grade1.md chapter 2, the preview design/prototype/grade1-ch2.html):
/// counters 3 × 3 squares, two rows lined up from one start line; every number tapped on the number row (0–20). Every line
/// here is spoken (App's Voice); a story's sentences start its first instruction (written once, said with it), as chapter 1's.
public enum Eq1 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G1.int(v, k, d) }
    public static let names = ["Maya", "Leo", "Ana", "Sam", "Noor", "Eli"]
    public static let her: [String: String] = ["Maya": "her", "Ana": "her", "Noor": "her", "Leo": "his", "Sam": "his", "Eli": "his"]
    static func pick<T>(_ list: [T], _ rng: inout SeededRandom) -> T { list[Int.random(in: 0...(list.count - 1), using: &rng)] }
}

// MARK: - Add to take away

/// Add to take away (g1-related, new; 1.OA.4, 6). The problem c − a is the record's first line. The whole is a row of c
/// places, outlined; under it a row starting with the a counters, the rest empty. Drag the bottom row's end out: striped
/// counters fill in behind the finger, counted ("8 + 4"). Level with the whole's end it lifts into the whole, a | b. Write the
/// take away; the other facts of the family draw in.
///
/// "at": 0 drag, 1 write, 2 done. The drag step's box "k": how many striped counters were let go (b right).
public enum Related1 {
    public static func numbers(c: Int, a: Int) -> Numbers { ["c": Double(c), "a": Double(a)] }
    public struct Parts: Sendable {
        public let c: Int, a: Int
        public init(_ x: Numbers) { c = max(3, min(18, Eq1.int(x, "c", 12))); a = max(1, min(c - 1, Eq1.int(x, "a", 8))) }
        public var b: Int { c - a }
        public func dragged(_ k: Int) -> String { k > b ? "That's past \(c)." : "It doesn't reach \(c) yet." }
        public var slips: [(Int, String)] {
            [(c + a, "That's adding. Taking away leaves less than \(c)."), (a, "That's the part you take. Find the other part."),
             (b - 1, "Count the striped ones again."), (b + 1, "Count the striped ones again.")]
        }
        public static let other = "The striped ones are the part left. Count them."
        public var why: String { "The part you add to \(a) is the part left." }
    }
    /// New: the first three c 6–10, a 2 to c − 2 (within 10); then c 11–18, a from c − 9 to 9 (the other part 9 or less).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { let c = Int.random(in: 6...10, using: &rng); return numbers(c: c, a: Int.random(in: 2...(c - 2), using: &rng)) }
        let c = Int.random(in: 11...18, using: &rng)
        return numbers(c: c, a: Int.random(in: (c - 9)...9, using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-related", title: "Add to take away", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.c)), .op("−"), .num(Double(P.a))] },
        idea: { _ in "To take away, find what you add to get back to the whole." },
        depends: ["g1-sub20", "k-bonds"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).c >= 15 }), CheckItem(4, when: { Parts($0).a < Parts($0).b }), CheckItem(4)]) { x in
        let P = Parts(x)
        let dragHint = "Make the bottom row as long as the top row."
        let drag = LessonStep(StepWords(say: "Drag the bottom row out to the end.", hint: dragHint, action: "Check"),
            answer: AddSubK.hand("k", P.b, hint: dragHint, explain: "\(P.a) and \(P.b) make \(P.c).", said: { P.dragged($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "How many striped ones did you add?"
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.b, P.slips, other: { _ in Parts.other }, hint: writeHint, explain: "\(P.a) + \(P.b) = \(P.c), so \(P.c) − \(P.a) = \(P.b)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [drag, write, done]
    }
}

// MARK: - Missing numbers

/// Missing numbers (the web's g1-missing; 1.OA.8, 4). The record's first line is the problem, a + ? = c (or ? + a = c). The
/// line 0 to 20, a ringed as the start and c flagged as the end. Hop up to 10, then on to the flag; one bracket over both
/// hops; write the missing number.
///
/// "at": 0 to ten, 1 to the flag, 2 write, 3 done. The hops' boxes: where each landed ("t" 10 right, "e" c right).
public enum Missing1 {
    public static func numbers(a: Int, c: Int, first: Bool = false) -> Numbers { ["a": Double(a), "c": Double(c), "first": first ? 1 : 0] }
    public struct Parts: Sendable {
        public let a: Int, c: Int, first: Bool
        public init(_ x: Numbers) {
            a = max(1, min(9, Eq1.int(x, "a", 8))); c = max(11, min(a + 9, Eq1.int(x, "c", 13))); first = Eq1.int(x, "first") == 1
        }
        public var up: Int { 10 - a }
        public var rest: Int { c - 10 }
        public var ans: Int { c - a }
        public func toTen(_ n: Int) -> String { n > 10 ? "Stop at 10 first." : "Keep going to 10." }
        public func toEnd(_ n: Int) -> String { n < c ? "Keep going to \(c)." : "That's past \(c)." }
        public var slips: [(Int, String)] {
            let both = "Add both hops: \(up) to get to 10, and \(rest) more."
            return [(c, "\(c) is already there. The missing number is how far it is from \(a) to \(c)."),
                    (c + a, "That adds \(a) too. Only add the hops: \(up) and \(rest)."), (up, both), (rest, both)]
        }
        public var other: String { "Put the hops together: \(up) and \(rest)." }
        public static let why = "Count up from the number you know."
    }
    /// The web's generator: a 6–9 for the first three, then 2–9; c 11 to min(18, a + 9); ? + a only after the first three.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let a = Int.random(in: (i < 3 ? 6 : 2)...9, using: &rng)
        let c = Int.random(in: 11...min(18, a + 9), using: &rng)
        return numbers(a: a, c: c, first: i >= 3 && Bool.random(using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-missing", title: "Missing numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return P.first ? [.box("q"), .op("+"), .num(Double(P.a)), .op("="), .num(Double(P.c))]
                                                          : [.num(Double(P.a)), .op("+"), .box("q"), .op("="), .num(Double(P.c))] },
        idea: { _ in "Count up from the number you know to the total." },
        depends: ["g1-add20", "g1-ten"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).first }), CheckItem(6, when: { Parts($0).a <= 5 }), CheckItem(6)]) { x in
        let P = Parts(x)
        let tenHint = "Land on 10 first."
        let ten = LessonStep(StepWords(say: "Hop up to 10.", hint: tenHint, action: "Check"),
            answer: AddSubK.hand("t", 10, hint: tenHint, explain: "\(P.a) and \(P.up) make 10.", said: { P.toTen($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let endHint = "Hop to where the flag is."
        let end = LessonStep(StepWords(say: "Now hop on to the flag.", hint: endHint, action: "Check"),
            answer: AddSubK.hand("e", P.c, hint: endHint, explain: "10 and \(P.rest) make \(P.c).", said: { P.toEnd($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Add the two hops."
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.ans, P.slips, other: { _ in P.other }, hint: writeHint, explain: "\(P.up) + \(P.rest) = \(P.ans)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [ten, end, write, done]
    }
}

// MARK: - True or false?

/// True or false? (g1-equal, new; 1.OA.7, 8). The equation written once, big, at the top. Under it each side's amount as
/// counters from one start line: the left side on top, the right side under it. A sum's second part (striped) sits a block
/// to the right; a take away's last counters are crossed out; a single number is one row.
/// True or false: slide each side into one row (a dashed line drops from the shorter row's end, "5 and 7"), then tap True
/// or False. Make it true (from the 7th): drag the box's row until the two rows end level, then write the box.
///
/// A side is "t" 0 a number, 1 a sum, 2 a take away, with its parts "0" and "1" (−1 is the box): l…, r…. "at": true or
/// false: 0 slide (only when a side isn't one row), 1 tap, 2 done; make it true: 0 drag, 1 write, 2 done. The slide's box
/// "j": 1 once every side is one row. The tap's "tf": 1 true, 0 false. The drag's "k": the box's counters let go.
public enum Equal1 {
    public struct Side: Sendable, Equatable {
        public let t: Int, p0: Int, p1: Int
        public init(_ t: Int, _ p0: Int, _ p1: Int = 0) { self.t = t; self.p0 = p0; self.p1 = p1 }
        public var box: Bool { p0 < 0 || (t > 0 && p1 < 0) }
        public var sign: String { t == 1 ? "+" : "−" }
        /// Its value with the box worth k.
        public func value(_ k: Int = 0) -> Int {
            let a = p0 < 0 ? k : p0, b = p1 < 0 ? k : p1
            return t == 0 ? a : t == 1 ? a + b : a - b
        }
        /// How many counters its row takes before it's joined (a sum's two parts, a take away's start).
        public var count: Int { t == 0 ? p0 : t == 1 ? p0 + p1 : p0 }
    }
    public static func numbers(_ l: Side, _ r: Side, make: Bool = false) -> Numbers {
        ["make": make ? 1 : 0, "lt": Double(l.t), "l0": Double(l.p0), "l1": Double(l.p1), "rt": Double(r.t), "r0": Double(r.p0), "r1": Double(r.p1)]
    }
    public enum Form: Sendable { case box, boxPlus, plusBox, boxMinus, minusBox }
    public struct Parts: Sendable {
        public let L: Side, R: Side, make: Bool
        public init(_ x: Numbers) {
            func side(_ k: String) -> Side { Side(max(0, min(2, Eq1.int(x, k + "t"))), Eq1.int(x, k + "0", 3), Eq1.int(x, k + "1", 0)) }
            L = side("l"); R = side("r"); make = Eq1.int(x, "make") == 1
        }
        public var sides: [Side] { [L, R] }
        public var vL: Int { L.value() }
        public var vR: Int { R.value() }
        public var truth: Bool { vL == vR }
        /// A side to slide into one row (a sum or a take away).
        public var slides: Bool { !make && (L.t != 0 || R.t != 0) }
        // make it true: the box's side B, the known side K, the target T
        public var boxLeft: Bool { L.box }
        public var B: Side { boxLeft ? L : R }
        public var K: Side { boxLeft ? R : L }
        public var T: Int { K.value() }
        public var form: Form {
            switch (B.t, B.p0 < 0) {
            case (0, _): .box
            case (1, true): .boxPlus
            case (1, false): .plusBox
            case (2, true): .boxMinus
            default: .minusBox
            }
        }
        /// The box's other number (d): what it's added to, taken, or taken from.
        public var d: Int { B.p0 < 0 ? B.p1 : B.p0 }
        /// The box's answer.
        public var x: Int {
            switch form {
            case .box: T
            case .boxPlus, .plusBox: T - d
            case .boxMinus: T + d
            case .minusBox: d - T
            }
        }
        /// The box's side's value with k counters for the box.
        public func bval(_ k: Int) -> Int {
            switch form {
            case .box: k
            case .boxPlus, .plusBox: k + d
            case .boxMinus: max(0, k - d)
            case .minusBox: d - k
            }
        }
        /// How many counters the box's row can take (a row never passes 18).
        public var kmax: Int {
            switch form {
            case .minusBox: d
            case .box, .boxMinus: 18
            default: 18 - d
            }
        }
        public func tapped(_ said: Int) -> String { truth ? "Both rows are \(vL). That's the same amount." : "Not the same: \(vL) and \(vR)." }
        public func dragged(_ k: Int) -> String { bval(k) > T ? "That's past the other row's end." : "It doesn't reach the other row's end yet." }
        public var dragSay: String { form == .minusBox ? "Drag the row's end back until they match." : "Drag the striped row until the ends match." }
        public var slips: [(Int, String)] {
            let kd = K.t == 0 ? "\(T) is the whole." : "\(K.p0) \(K.sign) \(K.p1) is \(T)."
            switch form {
            case .box:
                if K.t == 1 { let l = "The box is the whole amount: \(K.p0) and \(K.p1) together."; return [(K.p0, l), (K.p1, l)] }
                return [(K.p0, "\(K.p1) go away, so the box is less than \(K.p0)."), (K.p0 + K.p1, "That's adding. \(K.p1) go away.")]
            case .boxPlus, .plusBox: return [(T + d, "The box and \(d) make \(T) together."), (T, "\(kd) The box goes with \(d) to make \(T).")]
            case .boxMinus: return [(T - d, "The box is the start. \(d) go, \(T) are left."), (T, "\(T) are left. The box is the start, before \(d) go.")]
            case .minusBox: return [(d + T, "That's adding. Some go away to leave \(T)."), (T, "\(T) are left. The box is how many go.")]
            }
        }
        public var other: String { form == .minusBox ? "Count the crossed-out ones: that's the box." : "Count the striped ones: that's the box." }
        public static let slide = "Slide each side into one row."
        public static let tap = "Same amount? Tap True or False."
        public static let why = "= means both sides are the same amount."
    }

    /// A side worth v: a sum, or one time in three a take away (never past `max` counters).
    static func expr(_ v: Int, _ max: Int, _ rng: inout SeededRandom) -> Side {
        if v >= 2 && (Int.random(in: 0...2, using: &rng) != 0 || max - v < 1) {
            let x = Int.random(in: 1...(v - 1), using: &rng); return Side(1, x, v - x)
        }
        let y = Int.random(in: 1...min(5, max - v), using: &rng)
        return Side(2, v + y, y)
    }
    /// New: true or false first (one side a single number within 10 for the first three, on either side, now and then
    /// 6 = 6; true half the time, false by 1 or 2), then both sides sums or take aways, turn-arounds among them; from the
    /// 7th, make it true with the box in any place, within 20 (no row longer than 18 counters).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 6 {
            let truth = Bool.random(using: &rng)
            var L: Side, R: Side
            if i < 3 {
                let v = Int.random(in: 3...9, using: &rng)
                if truth && Int.random(in: 0...4, using: &rng) == 0 { return numbers(Side(0, v), Side(0, v)) }
                var n = v
                if !truth {
                    let d = Int.random(in: 1...2, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
                    n = (1...10).contains(v + d) ? v + d : v - d
                }
                L = expr(v, 10, &rng); R = Side(0, n)
            } else {
                let v = Int.random(in: 3...11, using: &rng)
                L = expr(v, 12, &rng)
                if truth {
                    if L.t == 1 && L.p0 != L.p1 && Bool.random(using: &rng) { R = Side(1, L.p1, L.p0) }
                    else {
                        R = expr(v, 12, &rng)
                        for _ in 0..<20 where R.t == L.t && R.p0 == L.p0 { R = expr(v, 12, &rng) }
                    }
                } else {
                    let d = Int.random(in: 1...2, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
                    let w = (2...12).contains(v + d) ? v + d : v - d
                    R = expr(w, 12, &rng)
                }
            }
            return Bool.random(using: &rng) ? numbers(L, R) : numbers(R, L)
        }
        while true {
            let T = Int.random(in: 3...18, using: &rng)
            let K = Int.random(in: 0...2, using: &rng) == 0 ? Side(0, T) : expr(T, 18, &rng)
            let f = Int.random(in: 0...4, using: &rng)
            var B: Side
            switch f {
            case 0:
                if K.t == 0 { continue }
                B = Side(0, -1)
            case 1, 2:
                let d = Int.random(in: 1...(T - 1), using: &rng)
                B = f == 1 ? Side(1, -1, d) : Side(1, d, -1)
            case 3:
                if T > 17 { continue }
                B = Side(2, -1, Int.random(in: 1...min(9, 18 - T), using: &rng))
            default:
                if T > 17 { continue }
                let x = Int.random(in: 1...min(9, 18 - T), using: &rng)
                B = Side(2, T + x, -1)
            }
            return Bool.random(using: &rng) ? numbers(B, K, make: true) : numbers(K, B, make: true)
        }
    }

    public static let spec = LessonSpec(id: "g1-equal", title: "True or false?", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let P = Parts(x)
            func toks(_ s: Side) -> [Math] {
                let n: (Int) -> Math = { $0 < 0 ? .box("q") : .num(Double($0)) }
                return s.t == 0 ? [n(s.p0)] : [n(s.p0), .op(s.sign), n(s.p1)]
            }
            return toks(P.L) + [.op("=")] + toks(P.R)
        },
        idea: { _ in "= means both sides are the same amount." },
        depends: ["g1-related", "g1-missing"],
        check: [CheckItem(0), CheckItem(4, when: { !Parts($0).truth }), CheckItem(6, when: { Parts($0).boxLeft }), CheckItem(7)]) { x in
        let P = Parts(x)
        if P.make {
            let dragHint = "Look where the other row ends."
            let drag = LessonStep(StepWords(say: P.dragSay, hint: dragHint, action: "Check"),
                answer: AddSubK.hand("k", P.x, hint: dragHint, explain: "Both rows end at \(P.T).", said: { P.dragged($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let writeHint = P.form == .minusBox ? "Count the crossed-out ones." : "Count the striped ones."
            let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
                answer: G1.write("x", P.x, P.slips, other: { _ in P.other }, hint: writeHint, explain: "Both sides are \(P.T)."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
            return [drag, write, done]
        }
        let slideHint = "Drag the striped ones left, or the crossed-out ones away."
        let slide = LessonStep(StepWords(say: Parts.slide, hint: slideHint, action: "Check"),
            answer: AddSubK.hand("j", 1, hint: slideHint, explain: "Each side is one row.", said: { _ in slideHint }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tapHint = "Do the rows end in the same place?"
        let tap = LessonStep(StepWords(say: Parts.tap, hint: tapHint, action: "Check"),
            answer: AddSubK.hand("tf", P.truth ? 1 : 0, hint: tapHint, explain: P.truth ? "Both sides are \(P.vL)." : "\(P.vL) and \(P.vR) aren't the same.",
                                 said: { P.tapped($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return (P.slides ? [slide] : []) + [tap, done]
    }
}

// MARK: - Story problems

/// Story problems (g1-story, new; 1.OA.1). The story's sentences start the first instruction; the things are counters on
/// one row of places (10 for stories within 10, else 18); every number in the story names its group with a bracket. Each
/// kind of story is acted out with its own hand move, then written as an equation with the box where the unknown is.
///
/// "kind": 0 join, 1 take, 2 together, 3 joinChange (how many came), 4 takeChange (how many went), 5 joinStart, 6
/// takeStart (the start unknown), 7 apart. "s" start, "ch" change, "e" end (for apart: "e" all, "s" in the box, "ch" the rest).
/// "at": 0 move, 1 write, 2 done. The move's box "m": how many moved or counted (ch right), −1 a touch on the wrong ones.
public enum Story1 {
    public enum Kind: Int, Sendable, CaseIterable { case join, take, together, joinChange, takeChange, joinStart, takeStart, apart }
    public static func numbers(_ kind: Kind, s: Int, ch: Int, e: Int, thing: Int = 0, name: Int = 0) -> Numbers {
        ["kind": Double(kind.rawValue), "s": Double(s), "ch": Double(ch), "e": Double(e), "thing": Double(thing), "name": Double(name)]
    }
    struct Thing: Sendable {
        let t: String, at: String, own: Bool
        let more: @Sendable (Int, String) -> String, someMore: @Sendable (String) -> String
        let go: @Sendable (Int, String) -> String, someGo: @Sendable (String) -> String
        let qCame: @Sendable (String) -> String, qWent: @Sendable (String) -> String
        let came: @Sendable (String) -> String, went: @Sendable (String) -> String
    }
    static let things: [Thing] = [
        Thing(t: "birds", at: "sit in a tree", own: false, more: { n, _ in "\(n) more fly in." }, someMore: { _ in "Some more fly in." },
              go: { n, _ in "\(n) fly away." }, someGo: { _ in "Some fly away." }, qCame: { _ in "How many flew in?" }, qWent: { _ in "How many flew away?" },
              came: { _ in "Some flew in" }, went: { _ in "Some flew away" }),
        Thing(t: "frogs", at: "sit on a log", own: false, more: { n, _ in "\(n) more hop on." }, someMore: { _ in "Some more hop on." },
              go: { n, _ in "\(n) hop off." }, someGo: { _ in "Some hop off." }, qCame: { _ in "How many hopped on?" }, qWent: { _ in "How many hopped off?" },
              came: { _ in "Some hopped on" }, went: { _ in "Some hopped off" }),
        Thing(t: "cars", at: "are in the lot", own: false, more: { n, _ in "\(n) more drive in." }, someMore: { _ in "Some more drive in." },
              go: { n, _ in "\(n) drive away." }, someGo: { _ in "Some drive away." }, qCame: { _ in "How many drove in?" }, qWent: { _ in "How many drove away?" },
              came: { _ in "Some drove in" }, went: { _ in "Some drove away" }),
        Thing(t: "apples", at: "", own: true, more: { n, N in "\(N) picks \(n) more." }, someMore: { N in "\(N) picks some more." },
              go: { n, N in "\(N) eats \(n)." }, someGo: { N in "\(N) eats some." }, qCame: { N in "How many did \(N) pick?" }, qWent: { N in "How many did \(N) eat?" },
              came: { N in "\(N) picked some" }, went: { N in "\(N) ate some" }),
        Thing(t: "shells", at: "", own: true, more: { n, N in "\(N) finds \(n) more." }, someMore: { N in "\(N) finds some more." },
              go: { n, N in "\(N) gives \(n) away." }, someGo: { N in "\(N) gives some away." }, qCame: { N in "How many did \(N) find?" },
              qWent: { N in "How many did \(N) give away?" }, came: { N in "\(N) found some" }, went: { N in "\(N) gave some away" }),
        Thing(t: "books", at: "", own: true, more: { n, N in "\(N) gets \(n) more." }, someMore: { N in "\(N) gets some more." },
              go: { n, N in "\(N) gives \(n) away." }, someGo: { N in "\(N) gives some away." }, qCame: { N in "How many did \(N) get?" },
              qWent: { N in "How many did \(N) give away?" }, came: { N in "\(N) got some" }, went: { N in "\(N) gave some away" }),
    ]
    /// One record token: a number, a sign, or the box.
    public enum Tok: Sendable, Equatable { case n(Int), op(String), box }
    public struct Parts: Sendable {
        public let kind: Kind, s: Int, ch: Int, e: Int, thing: Int, name: String
        public init(_ x: Numbers) {
            kind = Kind(rawValue: max(0, min(7, Eq1.int(x, "kind")))) ?? .join
            s = max(0, min(18, Eq1.int(x, "s", 5))); ch = max(0, min(18, Eq1.int(x, "ch", 3))); e = max(0, min(18, Eq1.int(x, "e", 8)))
            thing = max(0, min(5, Eq1.int(x, "thing"))); name = Eq1.names[max(0, min(5, Eq1.int(x, "name")))]
        }
        var th: Thing { Story1.things[thing] }
        /// The row's places: 10 for a story within 10, else 18.
        public var places: Int { max(s, e) <= 10 ? 10 : 18 }
        public var ans: Int {
            switch kind {
            case .join, .together, .take: e
            case .joinChange, .takeChange, .apart: ch
            case .joinStart, .takeStart: s
            }
        }
        /// A group that slides (join, together, the start unknown); the rest are dragged or counted.
        public var slides: Bool { [.join, .together, .joinStart, .takeStart].contains(kind) }
        public var lines: [String] {
            let N = name, t = th.t
            let open = { (n: Int) in th.own ? "\(N) has \(n) \(t)." : "\(n) \(t) \(th.at)." }
            let some = th.own ? "\(N) has some \(t)." : "Some \(t) \(th.at)."
            switch kind {
            case .join: return [open(s), th.more(ch, N), "How many \(t) now?"]
            case .take: return [open(s), th.go(ch, N), "How many are left?"]
            case .together: return ["\(N) has \(s) \(t) in a box.", "\(N) has \(ch) in a bag.", "How many \(t) in all?"]
            case .joinChange: return [open(s), "\(th.someMore(N)) Now there are \(e).", th.qCame(N)]
            case .takeChange: return [open(s), "\(th.someGo(N)) Now there are \(e).", th.qWent(N)]
            case .joinStart: return [some, "\(th.more(ch, N)) Now there are \(e).", "How many were there first?"]
            case .takeStart: return [some, "\(th.go(ch, N)) Now there are \(e).", "How many were there first?"]
            case .apart: return ["\(N) has \(e) \(t).", "\(s) are in a box. The rest are in a bag.", "How many are in the bag?"]
            }
        }
        public var action: String {
            switch kind {
            case .join: "Slide the new ones onto the row."
            case .together: "Slide the bag's ones onto the row."
            case .take: "Slide off the ones that go away."
            case .joinChange: "Drag the row out to fill the outline."
            case .takeChange: "Slide ones off down to the outline."
            case .joinStart: "Slide the ones that came back off."
            case .takeStart: "Slide the ones that went back on."
            case .apart: "Drag across the bag's ones to count them."
            }
        }
        public var say: String { (lines + [action]).joined(separator: " ") }
        public var record: [Tok] {
            switch kind {
            case .join, .together: [.n(s), .op("+"), .n(ch), .op("="), .box]
            case .take: [.n(s), .op("−"), .n(ch), .op("="), .box]
            case .joinChange, .apart: [.n(s), .op("+"), .box, .op("="), .n(e)]
            case .takeChange: [.n(s), .op("−"), .box, .op("="), .n(e)]
            case .joinStart: [.box, .op("+"), .n(ch), .op("="), .n(e)]
            case .takeStart: [.box, .op("−"), .n(ch), .op("="), .n(e)]
            }
        }
        public var why: String {
            switch kind {
            case .join: "More came, so add."
            case .together: "Put them together, so add."
            case .take: "Some went away, so take away."
            case .joinChange: "Fill up to the end to see how many came."
            case .takeChange: "Cross off down to the end to see how many went."
            case .joinStart, .takeStart: "Undo the story to find the start."
            case .apart: "Two parts make the whole, so count the rest."
            }
        }
        public var slips: [(Int, String)] {
            let N = name, fewer = "\(th.went(N)), so there are fewer."
            switch kind {
            case .join: return [(s - ch, "That's taking away. More came, so add.")]
            case .together: return [(abs(s - ch), "That's taking away. Put them together, so add.")]
            case .take: return [(s + ch, fewer), (s, "\(s) were there first. Some went away.")]
            case .joinChange: return [(e, "\(e) is how many now. \(th.qCame(N))"), (s + e, "\(s + e) is \(s) and \(e) together. \(th.came(N)) to make \(e)."),
                                      (s, "\(s) were there first. \(th.qCame(N))")]
            case .takeChange: return [(s + e, fewer), (e, "\(e) are left. \(th.qWent(N))"), (s, "\(s) were there first. \(th.qWent(N))")]
            case .joinStart: return [(e, "\(e) is how many now. How many were there first?"), (e + ch, "\(e + ch) is \(ch) and \(e) together. Take the \(ch) back off."),
                                     (ch, "\(ch) came later. How many were there first?")]
            case .takeStart: return [(e - ch, "\(th.went(N)), so there were more at the start."), (e, "\(e) are left now. How many were there first?")]
            case .apart: return [(e, "\(e) is all of them. How many are in the bag?"), (e + s, "\(e + s) is \(s) and \(e) together. The bag has part of \(e)."),
                                 (s, "\(s) are in the box. How many are in the bag?")]
            }
        }
        public var other: String {
            switch kind {
            case .join: "Count them all: the row and the ones that came."
            case .together: "Count them all: the box and the bag."
            case .take: "Count the ones not crossed out."
            case .joinChange: "Count the striped ones."
            case .takeChange: "Count the crossed-out ones."
            case .joinStart: "Count the ones left on the row."
            case .takeStart: "Count the whole row."
            case .apart: "Count the ones in the bag."
            }
        }
        /// What a move that isn't right says: m how many moved (−1 a touch on the wrong ones).
        public func moved(_ m: Int) -> String {
            switch kind {
            case .joinChange: return m > ch ? "That's past \(e)." : "It doesn't reach \(e) yet."
            case .takeChange: return m > ch ? "That leaves \(s - m). \(e) are left." : "That leaves \(s - m). Keep going to \(e)."
            case .take: return m > ch ? "That's \(m) gone. Only \(ch) go away." : "\(ch) go away. Slide off \(ch)."
            case .joinStart: return "Those were there at the start. Slide off the ones that came."
            case .apart: return "That one is in the box. Count the ones in the bag."
            default: return action
            }
        }
        public var hint: String {
            switch kind {
            case .join, .together, .takeStart: "Drag the striped ones up onto the row."
            case .joinStart: "Drag the striped ones off the row."
            case .take: "Drag back from the row's end."
            case .takeChange: "Drag back from the row's end to the outline's end."
            case .joinChange: "Drag the row's end to the outline's end."
            case .apart: "Count only the dotted ones."
            }
        }
    }
    /// New: the first three the end unknown within 10 (joining, going away, putting together); the next three the change or
    /// a part unknown within 20; from the 7th any kind, the start unknown only from there. Rows up to 18.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind: Kind = i < 3 ? [.join, .take, .together][i] : i < 6 ? Eq1.pick([.joinChange, .takeChange, .apart], &rng) : Eq1.pick(Kind.allCases, &rng)
        let mx = i < 3 ? 10 : 18
        var s = 0, ch = 0, e = 0
        switch kind {
        case .join, .together: s = Int.random(in: 2...(mx - 2), using: &rng); ch = Int.random(in: 2...(mx - s), using: &rng); e = s + ch
        case .take: s = Int.random(in: 3...mx, using: &rng); ch = Int.random(in: 2...(s - 1), using: &rng); e = s - ch
        case .joinChange, .joinStart: e = Int.random(in: 5...mx, using: &rng); ch = Int.random(in: 2...(e - 2), using: &rng); s = e - ch
        case .takeChange, .takeStart: s = Int.random(in: 5...mx, using: &rng); ch = Int.random(in: 2...(s - 2), using: &rng); e = s - ch
        case .apart: e = Int.random(in: 5...mx, using: &rng); s = Int.random(in: 2...(e - 2), using: &rng); ch = e - s
        }
        let own = kind == .together || kind == .apart
        return numbers(kind, s: s, ch: ch, e: e, thing: own ? Int.random(in: 3...5, using: &rng) : Int.random(in: 0...5, using: &rng),
                       name: Int.random(in: 0...5, using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-story", title: "Story problems", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            Parts(x).record.map { t -> Math in
                switch t { case .n(let v): .num(Double(v)); case .op(let o): .op(o); case .box: .box("q") }
            }
        },
        idea: { _ in "Act the story out, then write it with the box where the unknown is." },
        depends: ["k-story", "g1-related"],
        check: [CheckItem(0), CheckItem(3, when: { [.joinChange, .takeChange].contains(Parts($0).kind) }),
                CheckItem(6, when: { [.joinStart, .takeStart].contains(Parts($0).kind) }), CheckItem(7, when: { Parts($0).kind == .apart })]) { x in
        let P = Parts(x)
        let move = LessonStep(StepWords(say: P.say, hint: P.hint, action: "Check"),
            answer: AddSubK.hand("m", P.ch, hint: P.hint, explain: P.lines.joined(separator: " "), said: { P.moved($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = P.other
        let write = LessonStep(StepWords(say: G1.tap, hint: writeHint, action: "Check"),
            answer: G1.write("x", P.ans, P.slips, other: { _ in P.other }, hint: writeHint, explain: "The box is \(P.ans)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [move, write, done]
    }
}

// MARK: - How many more?

/// How many more? (g1-more, new; 1.OA.1 comparing). Two rows lined up from one start line, one per child, each child's name
/// and number at the row's end. How many more (or fewer): tap the counters with no partner. The bigger one unknown: drag
/// that row's end out from its dashed partners. The smaller one unknown: drag that row back until the extra ones show.
/// Then write.
///
/// "kind": 0 more, 1 fewer, 2 bigger, 3 smaller, 4 bigger (mixed-up words), 5 smaller (mixed-up words); "big", "small";
/// "bn", "sn" the children's names; "thing". "at": 0 move, 1 write, 2 done. The move's box "m": how many lit or dragged
/// (big − small right), −1 a counter with a partner.
public enum More1 {
    public static let things = ["shells", "stickers", "marbles", "books", "apples", "cars"]
    public static func numbers(kind: Int, big: Int, small: Int, bn: Int = 0, sn: Int = 1, thing: Int = 0) -> Numbers {
        ["kind": Double(kind), "big": Double(big), "small": Double(small), "bn": Double(bn), "sn": Double(sn), "thing": Double(thing)]
    }
    public enum Find: Sendable { case diff, big, small }
    public struct Parts: Sendable {
        public let kind: Int, big: Int, small: Int, Bg: String, Sm: String, t: String
        public init(_ x: Numbers) {
            kind = max(0, min(5, Eq1.int(x, "kind"))); big = max(2, min(16, Eq1.int(x, "big", 9))); small = max(1, min(big - 1, Eq1.int(x, "small", 5)))
            let bn = max(0, min(5, Eq1.int(x, "bn"))), sn = max(0, min(5, Eq1.int(x, "sn", 1)))
            Bg = Eq1.names[bn]; Sm = Eq1.names[sn == bn ? (bn + 1) % 6 : sn]; t = More1.things[max(0, min(5, Eq1.int(x, "thing")))]
        }
        public var d: Int { big - small }
        public var find: Find { kind == 2 || kind == 4 ? .big : kind == 3 || kind == 5 ? .small : .diff }
        public var fewerQ: Bool { kind == 1 }
        /// The first child named is the top row.
        public var topBig: Bool { !(kind == 1 || kind == 2 || kind == 4) }
        public var lines: [String] {
            switch kind {
            case 0: ["\(Bg) has \(big) \(t). \(Sm) has \(small).", "How many more does \(Bg) have?"]
            case 1: ["\(Sm) has \(small) \(t). \(Bg) has \(big).", "How many fewer does \(Sm) have?"]
            case 2: ["\(Sm) has \(small) \(t).", "\(Bg) has \(d) more.", "How many does \(Bg) have?"]
            case 3: ["\(Bg) has \(big) \(t).", "\(Sm) has \(d) fewer.", "How many does \(Sm) have?"]
            case 4: ["\(Sm) has \(d) fewer than \(Bg).", "\(Sm) has \(small).", "How many does \(Bg) have?"]
            default: ["\(Bg) has \(d) more than \(Sm).", "\(Bg) has \(big).", "How many does \(Sm) have?"]
            }
        }
        public var action: String {
            switch find { case .diff: "Tap the ones with no partner."; case .big: "Drag \(Bg)'s row out."; case .small: "Drag \(Sm)'s row back." }
        }
        public var say: String { (lines + [action]).joined(separator: " ") }
        public var ans: Int { find == .big ? big : find == .small ? small : d }
        /// The record: (first, sign, second), the box last.
        public var record: (Int, String, Int) { find == .big ? (small, "+", d) : find == .small ? (big, "−", d) : (big, "−", small) }
        public var slips: [(Int, String)] {
            switch find {
            case .big: [(small - d, "\(Bg) has more, so \(Eq1.her[Bg] ?? "the") row is longer.")]
            case .small: [(big + d, "\(Sm) has fewer, so \(Eq1.her[Sm] ?? "the") row is shorter.")]
            case .diff: [(big + small, "How many \(fewerQ ? "fewer" : "more") means the extra ones. Take away.")]
            }
        }
        public var other: String {
            switch find { case .big: "\(Bg)'s row is \(small) and \(d) more."; case .small: "\(Sm)'s row is \(big) take away \(d)."; case .diff: "Count the ones with no partner." }
        }
        public func moved(_ m: Int) -> String {
            if m < 0 { return "That one has a partner. Count the ones past \(Sm)'s row." }
            return find == .big ? "That's \(m) more. \(Bg) has \(d) more." : "That's \(m) fewer. \(Sm) has \(d) fewer."
        }
        public var hint: String {
            switch find { case .diff: "Look past the end of \(Sm)'s row."; case .big: "\(Bg) has \(d) more than \(small)."; case .small: "\(Sm) has \(d) fewer than \(big)." }
        }
        public static let why = "Line them up: the extra ones are how many more."
    }
    /// New: how many more first (both rows 10 or fewer); then the bigger or the smaller with matching words; from the 7th
    /// any kind within 20 (rows up to 16, so the names fit at their ends), "fewer" and mixed-up wording too.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : i < 6 ? Eq1.pick([2, 3], &rng) : Int.random(in: 0...5, using: &rng)
        let big = Int.random(in: 3...(i < 6 ? 10 : 16), using: &rng), small = Int.random(in: 2...(big - 1), using: &rng)
        let a = Int.random(in: 0...5, using: &rng), b = (a + Int.random(in: 1...5, using: &rng)) % 6
        return numbers(kind: kind, big: big, small: small, bn: a, sn: b, thing: Int.random(in: 0...5, using: &rng))
    }

    public static let spec = LessonSpec(id: "g1-more", title: "How many more?", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let r = Parts(x).record; return [.num(Double(r.0)), .op(r.1), .num(Double(r.2)), .op("="), .box("q")] },
        idea: { _ in "Line them up: the extra ones are how many more." },
        depends: ["g1-story", "k-compare"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).find == .big }), CheckItem(4, when: { Parts($0).find == .small }),
                CheckItem(7, when: { Parts($0).kind >= 4 })]) { x in
        let P = Parts(x)
        let move = LessonStep(StepWords(say: P.say, hint: P.hint, action: "Check"),
            answer: AddSubK.hand("m", P.d, hint: P.hint, explain: "\(P.Bg) has \(P.d) more than \(P.Sm).", said: { P.moved($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: G1.tap, hint: P.other, action: "Check"),
            answer: G1.write("x", P.ans, P.slips, other: { _ in P.other }, hint: P.other, explain: "The box is \(P.ans)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [move, write, done]
    }
}
