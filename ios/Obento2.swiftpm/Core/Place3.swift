import Foundation

// 3rd grade's chapter 3, Place value (design/grade3.md chapter 3, the preview design/prototype/grade3-ch3.html): Rounding
// decimals' two lines with whole numbers, the place chart's disks slid in a place at a time (biggest first, the web's
// jumps), and an estimate on a line 0 to 1000. Every number the child writes is typed with the iPad's keys and Check, as
// the preview types; the preview's grey lines (a story, a friend's answer) are folded into the instruction.

/// What the chapter shares: the places' names, rounding to the nearest hundred (halfway up), the friends' names.
public enum P3 {
    /// A place's names, many and one: 100 "hundreds", "hundred".
    public static func names(_ place: Int) -> (many: String, one: String) {
        place >= 1000 ? ("thousands", "thousand") : place >= 100 ? ("hundreds", "hundred") : place >= 10 ? ("tens", "ten") : ("ones", "one")
    }
    public static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    /// To the nearest hundred, halfway up.
    public static func rh(_ x: Int) -> Int { (x + 50) / 100 * 100 }
    public static let cast = ["Leo", "Mia", "Ava", "Sam"]
    /// The web's jumps: one per place of b with a digit, biggest first, where each starts and lands.
    public struct Jump: Sendable, Equatable {
        public let place: Int, d: Int, from: Int, to: Int
        public var v: Int { d * place }
        /// Its column on the chart: 0 hundreds, 1 tens, 2 ones.
        public var c: Int { place == 100 ? 0 : place == 10 ? 1 : 2 }
        /// What this place of `from` holds, as a number (50 for the 5 tens of 458).
        public var digit: Int { from % (place * 10) - from % place }
    }
    public static func jumps(a: Int, b: Int, s: Int) -> [Jump] {
        var out: [Jump] = [], r = a
        for place in [100, 10, 1] {
            let d = b / place % 10
            if d == 0 { continue }
            out.append(Jump(place: place, d: d, from: r, to: r + s * d * place)); r += s * d * place
        }
        return out
    }
    /// The web's generator for Add and subtract within 1000: early b is two-digit, then three-digit (hundreds 1–6); b has
    /// no zero digit; the answer is 1–999.
    static func addsub(_ rng: inout SeededRandom, _ i: Int, three: Bool) -> (a: Int, b: Int, s: Int) {
        let s = Double.random(in: 0..<1, using: &rng) < 0.5 ? 1 : -1
        while true {
            let H = i < 3 && !three ? 0 : Int.random(in: 1...6, using: &rng)
            let b = H * 100 + Int.random(in: 1...9, using: &rng) * 10 + Int.random(in: 1...9, using: &rng)
            let lo = s == 1 ? 100 : max(100, b + 50), hi = s == 1 ? 999 - b : 999
            guard lo <= hi else { continue }
            let a = Int.random(in: lo...hi, using: &rng)
            if a + s * b >= 1 { return (a, b, s) }
        }
    }
}

// MARK: - Rounding to 10 and 100

/// Rounding to 10 and 100 (the web's g3-round; 3.NBT.A.1). Line 1 is the hundred n is in, a block a ten (0 to 1000, a block
/// a hundred, when rounding to hundreds); n's point sits on it. Tap the block it's in: it opens below into line 2, ten blocks
/// again (340 to 350). Drag the point to the end it's closer to (brackets say how far to each end), write `347 ≈ [350]`;
/// then the place's digit underlined, the next ringed, "7 is 5 or more: round up".
///
/// "n", "to". "at": 0 tap, 1 drag, 2 write, 3 done. Boxes: "x" the block tapped (0–9), then the end let go at (0 or 10); "R".
public enum Round3 {
    public static func numbers(n: Int, to: Int) -> Numbers { ["n": Double(n), "to": Double(to)] }
    public struct Parts: Sendable {
        public let n: Int, to: Int
        public init(_ x: Numbers) { n = max(1, min(999, G3.int(x, "n", 347))); to = G3.int(x, "to", 10) == 100 ? 100 : 10 }
        /// Line 1's start; the place's round numbers either side; halfway.
        public var lo1: Int { n / (10 * to) * (10 * to) }
        public var T: Int { n / to * to }
        public var hi: Int { T + to }
        public var mid: Int { T + to / 2 }
        public var rest: Int { n - T }
        public var up: Bool { n >= mid }
        public var half: Bool { n == mid }
        public var R: Int { up ? hi : T }
        public var other: Int { up ? T : hi }
        /// The block of line 1 the point is in.
        public var block: Int { (n - lo1) / to }
        public var one: String { to == 10 ? "ten" : "hundred" }
        /// The digit after the place's, which decides.
        public var next: Int { n / (to / 10) % 10 }
        public var between: String { "\(n) is between \(T) and \(hi)." }
        /// Let go at an end (0 the lower, 10 the upper) that isn't the closer.
        public func end(_ e: Int) -> String {
            if half { return "Exactly halfway rounds up." }
            let far = e == 10 ? to - rest : rest
            return "That end is \(far) away. The other end is \(to - far)."
        }
        public var slips: [(Int, String)] {
            let why = !up ? "\(n) is less than the halfway mark \(mid), so it is closer to \(T)."
                : half ? "\(n) is exactly halfway. A number exactly halfway rounds up, to \(hi)." : "\(n) is past the halfway mark \(mid), so it is closer to \(hi)."
            var out: [(Int, String)] = [(other, why)]
            if to == 100 { out.append(((n + 5) / 10 * 10, "That's the nearest ten. Round to the nearest hundred: \(T) or \(hi).")) }
            return out
        }
        public var hint: String { up ? "\(n) is at or past halfway (\(mid)), so it rounds up." : "\(n) is below halfway (\(mid)), so it rounds down." }
        public var why: String {
            half ? "\(to / 2) to \(hi), \(to / 2) to \(T). Exactly halfway rounds up."
                : "\(abs(R - n)) to \(R), \(abs(other - n)) to \(other). \(R) is closer."
        }
        public var rule: String { "\(next) is " + (next >= 5 ? "5 or more: round up" : "less than 5: round down") }
    }

    /// The web's: problems 0–2 two-digit numbers to the nearest ten; then three-digit numbers to 10 or 100 (a coin toss);
    /// a quarter of them exactly halfway.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let to = i < 3 ? 10 : (Bool.random(using: &rng) ? 10 : 100)
        let lo = i < 3 ? Int.random(in: 1...9, using: &rng) * 10 : to == 10 ? Int.random(in: 10...99, using: &rng) * 10 : Int.random(in: 1...9, using: &rng) * 100
        let half = Double.random(in: 0..<1, using: &rng) < 0.25
        let off = half ? to / 2 : to == 10 ? Int.random(in: 1...9, using: &rng) : Int.random(in: 1...99, using: &rng)
        return numbers(n: lo + (off % to == 0 ? 1 : off), to: to)
    }

    public static let spec = LessonSpec(id: "g3-round", title: "Rounding to 10 and 100", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.n)), .op("≈"), .text("?")] },
        idea: { _ in "Rounding picks whichever ten or hundred is closer, and exactly halfway rounds up." },
        depends: ["g2-hundreds"],
        check: [CheckItem(3, when: { Parts($0).to == 10 && Parts($0).up }), CheckItem(3, when: { Parts($0).to == 100 && !Parts($0).up }),
                CheckItem(3, when: { Parts($0).to == 100 && Parts($0).up }), CheckItem(3, when: { Parts($0).half })]) { x in
        let P = Parts(x)
        let tapHint = "Find the point. Tap the block it sits in."
        let tap = LessonStep(StepWords(say: "Round \(P.n) to the nearest \(P.one). Tap the block it's in.", hint: tapHint, action: "Check"),
            answer: G2.hand("x", P.block, hint: tapHint, explain: P.between, said: { _ in P.between }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let dragHint = "Count how far it is to each end."
        let drag = LessonStep(StepWords(say: "Drag \(P.n) to the end it's closer to.", hint: dragHint, action: "Check"),
            answer: G2.hand("x", P.up ? 10 : 0, hint: dragHint, explain: P.why, said: { e in P.end(e) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write the end it's closer to.", hint: P.hint, action: "Check"),
            answer: G3.typed("R", P.R, P.slips, hint: P.hint, explain: "\(P.n) ≈ \(P.R)."),
            picture: ["at": 2])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [tap, drag, write, done]
    }
}

// MARK: - Add and subtract within 1000

/// Add and subtract within 1000 (the web's g3-addsub; 3.NBT.A.2). The place chart: hundreds | tens | ones, each column 15
/// squares wide a block apart; a disk is a 3-square cell and says what it's worth. a's disks fill the top; b's wait under
/// their columns (striped to take away). A place at a time, biggest first (the web's jumps): slide its disks in (taking
/// away, they land on a's and cross them out; too few, open one of the next place up first: it opens into ten); adding, a
/// full ten is tapped and closes into one of the next place; then write the jump, `458 + 200 = [658]`.
///
/// "a", "b", "s" (1 or −1), "story". "ph": the step's place in `Parts.phases`. Boxes: "c" the pick (a story: 0 add, 1 take
/// away), "x" the hands' code, "w0"… the jumps written.
public enum AddSub3 {
    public static func numbers(a: Int, b: Int, s: Int, story: Bool = false) -> Numbers {
        ["a": Double(a), "b": Double(b), "s": Double(s), "story": story ? 1 : 0]
    }
    /// What the hands do, in order: pick (a story), slide jump k's disks (opening what it needs), close a full ten in a
    /// column, write jump k.
    public enum Phase: Sendable, Equatable { case pick, slide(Int), close(Int, Int), write(Int), done }
    public struct Parts: Sendable {
        public let a: Int, b: Int, s: Int, story: Bool
        public init(_ x: Numbers) {
            a = max(100, min(999, G3.int(x, "a", 458))); b = max(1, min(999, G3.int(x, "b", 275)))
            s = G3.int(x, "s", 1) < 0 ? -1 : 1; story = G3.int(x, "story") != 0
        }
        public var sub: Bool { s == -1 }
        public var sign: String { sub ? "−" : "+" }
        public var R: Int { a + s * b }
        public var jumps: [P3.Jump] { P3.jumps(a: a, b: b, s: s) }
        /// Each jump's opens (the columns opened, in order) and closes (the columns whose full ten closes), and the
        /// chart's counts before it: a's digits, moved on jump by jump.
        public var plan: [(opens: [Int], closes: [Int], before: [Int])] {
            var n = [a / 100, a / 10 % 10, a % 10], out: [(opens: [Int], closes: [Int], before: [Int])] = []
            for j in jumps {
                let c = j.c, before = n
                var opens: [Int] = [], closes: [Int] = []
                if sub {
                    while n[c] < j.d { let o = n[c - 1] > 0 ? c - 1 : c - 2; opens.append(o); n[o] -= 1; n[o + 1] += 10 }
                    n[c] -= j.d
                } else {
                    n[c] += j.d
                    var k = c
                    while k > 0 && n[k] >= 10 { closes.append(k); n[k] -= 10; n[k - 1] += 1; k -= 1 }
                }
                out.append((opens, closes, before))
            }
            return out
        }
        public var phases: [Phase] {
            var out: [Phase] = story ? [.pick] : []
            let p = plan
            for k in jumps.indices {
                out.append(.slide(k))
                for c in p[k].closes { out.append(.close(k, c)) }
                out.append(.write(k))
            }
            out.append(.done)
            return out
        }
        /// Something was carried or traded: a ten closed or opened.
        public var regroups: Bool { plan.contains { !$0.opens.isEmpty || !$0.closes.isEmpty } }
        public var tell: String {
            sub ? "A farm has \(a) apples. It sells \(b) of them. How many apples are left?"
                : "A school has \(a) books. It gets \(b) more. How many books does it have now?"
        }
        /// What to do on jump k's slide, with `o` opens done.
        public func slideSay(_ k: Int, need: Bool, opened o: Int) -> String {
            let j = jumps[k], m = P3.names(j.place).many
            if need, let w = opener(k, o) { return "Open a \(P3.names(w).one): tap one." }
            return sub ? "Slide the \(m) up to take them away." : "Slide in the \(m)."
        }
        /// The chart's counts on jump k with `o` of its opens done.
        public func counts(_ k: Int, opened o: Int) -> [Int] {
            let p = plan[k]
            var n = p.before
            for c in p.opens.prefix(o) { n[c] -= 1; n[c + 1] += 10 }
            return n
        }
        /// The place to open next on jump k (nil: there are enough).
        public func opener(_ k: Int, _ o: Int) -> Int? {
            let p = plan[k]
            guard o < p.opens.count else { return nil }
            return [100, 10, 1][p.opens[o]]
        }
        /// The hands' codes on a slide: 1 right, 2 dropped on another column, 3 another column grabbed, 4 + 10·o slid with
        /// too few (o opens done), 5 a disk tapped with enough, 6 + 10·o the wrong disk tapped to open.
        public func slideSaid(_ k: Int, _ x: Int) -> String {
            let j = jumps[k], (m, one) = P3.names(j.place), o = x / 10, n = counts(k, opened: o)
            switch x % 10 {
            case 2: return "\(P3.cap(m)) go with \(m)."
            case 3: return "Slide in the \(m) first."
            case 4:
                let have = n[j.c], w = opener(k, o) ?? 100, there = have == 0 ? "There are no \(m)" : have == 1 ? "There is only 1 \(one)" : "There are only \(have) \(m)"
                let up = P3.names([100, 10, 1][max(0, j.c - 1)]).many
                return w == [100, 10, 1][max(0, j.c - 1)] ? "\(there). Open a \(P3.names(w).one)." : "\(there) and no \(up). Open a \(P3.names(w).one)."
            case 5: return "There are enough \(m). Slide them up."
            case 6: return "Open a \(P3.names(opener(k, o) ?? 100).one)."
            default: return slideSay(k, need: false, opened: 0)
            }
        }
        public func closeSaid(_ c: Int) -> String {
            let place = [100, 10, 1][c]
            return "10 \(P3.names(place).many) make a \(P3.names(place * 10).one). Tap the full ten."
        }
        public func writeSlips(_ k: Int) -> [(Int, String)] {
            let j = jumps[k], (m, one) = P3.names(j.place), digit = j.digit, place = j.place
            func count(_ n: Int) -> String { G3.count(n, one, m) }
            var out: [(Int, String)] = []
            if place > 1 { out.append((j.from + s * j.d, "The \(j.d) in \(b) means \(count(j.d)), so \(sub ? "take away" : "add") \(j.v).")) }
            out.append((j.from - s * j.v, sub ? "This is taking away, so the number gets smaller." : "This is adding, so the number gets bigger."))
            if !sub && place < 100 && digit + j.v >= place * 10 {
                out.append((j.to - place * 10, "\(count(digit / place)) + \(count(j.d)) is \(count((digit + j.v) / place)). That makes a new \(P3.names(place * 10).one), so the next place goes up by 1."))
            }
            if sub && place < 100 && digit < j.v {
                let n = digit / place
                out.append((j.from - digit + (j.v - digit), "There \(digit == place ? "is" : "are") only \(n) \(digit == place ? one : m) in \(j.from), fewer than \(j.d). So taking away \(j.v) goes past \(j.from - digit). Taking \(n) from \(j.d) goes the wrong way."))
                out.append((j.to + place * 10, "When you trade 1 \(P3.names(place * 10).one) for 10 \(m), the next place goes down by 1."))
            }
            return out
        }
        public func writeHint(_ k: Int) -> String {
            let j = jumps[k], (m, one) = P3.names(j.place)
            return "Count \(sub ? "back" : "on") \(G3.count(j.d, one, m)) from \(j.from)."
        }
        public var why: String { regroups ? "Ten of one place make one of the next." : "Hundreds, tens and ones, each on its own." }
    }

    /// The web's: early b is two-digit, then three-digit; every 4th is a story (books +, apples −).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let (a, b, s) = P3.addsub(&rng, i, three: false)
        return numbers(a: a, b: b, s: s, story: i % 4 == 3)
    }

    public static let spec = LessonSpec(id: "g3-addsub", title: "Add and subtract within 1000", master: "place-chart",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op(P.sign), .num(Double(P.b))] },
        idea: { _ in "Break the second number into hundreds, tens and ones, and jump one place at a time." },
        depends: ["g2-within1000", "g2-subregroup"],
        check: [CheckItem(4, when: { let P = Parts($0); return !P.sub && P.regroups }), CheckItem(5, when: { let P = Parts($0); return P.sub && P.regroups }),
                CheckItem(6, when: { Parts($0).sub }), CheckItem(3)]) { x in
        let P = Parts(x), js = P.jumps
        var steps: [LessonStep] = []
        for (i, ph) in P.phases.enumerated() {
            let pic: Numbers = ["ph": Double(i)]
            switch ph {
            case .pick:
                let why = P.sub ? "It sells some, so there are fewer. Take away." : "It gets more, so there are more. Add."
                steps.append(LessonStep(StepWords(say: "\(P.tell) Pick what to do.", hint: "Will there be more or fewer?", action: "Check"),
                    answer: G2.hand("c", P.sub ? 1 : 0, hint: "Will there be more or fewer?", explain: why, said: { _ in why }),
                    picture: pic, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .slide(let k):
                let say = P.slideSay(k, need: false, opened: 0), m = P3.names(js[k].place).many
                let hint = P.sub ? "Slide the striped \(m) up onto the \(m)." : "Slide the \(m) up into their column."
                steps.append(LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint, explain: hint,
                                       check: { v in
                                           let c = Int((v["x"] ?? 0).rounded())
                                           return c == 1 ? .right : .wrong(P.slideSaid(k, c))
                                       }, byHand: true),
                    picture: pic, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .close(_, let c):
                steps.append(LessonStep(StepWords(say: "Tap the full ten.", hint: P.closeSaid(c), action: "Check"),
                    answer: G2.hand("x", 1, hint: P.closeSaid(c), explain: P.closeSaid(c), said: { _ in P.closeSaid(c) }),
                    picture: pic, onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .write(let k):
                let j = js[k]
                steps.append(LessonStep(StepWords(say: "Write \(j.from) \(P.sign) \(j.v).", hint: P.writeHint(k), action: "Check"),
                    answer: G3.typed("w\(k)", j.to, P.writeSlips(k), hint: P.writeHint(k), explain: "\(j.from) \(P.sign) \(j.v) = \(j.to)."),
                    picture: pic, onMiss: ["ring": 1]))
            case .done:
                steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: pic))
            }
        }
        return steps
    }
}

// MARK: - Estimate to check

/// Estimate to check (g3-estimate, new; 3.OA.D.8, 3.NBT.A.1, 3.NBT.A.2). A friend's answer, "Leo says 458 + 275 = 633.", in
/// the instruction; the line 0 to 1000, a block a hundred, the two numbers' points on it. Drag each to its nearest hundred,
/// hop the rounded second on (or back), write `458 + 275 ≈ 500 + 300 = [800]`; Leo's answer drops onto the line, a band 100
/// each side of 800 shades in, and Yes or No: could Leo be right?
///
/// "a", "b", "s", "f" the friend's answer, "who". "at": 0 round, 1 hop, 2 write, 3 judge, 4 done. Boxes: "x" the drags'
/// code, "k" the hops let go at, "E", "c" the pick (0 Yes, 1 No).
public enum Estimate3 {
    public static func numbers(a: Int, b: Int, s: Int, f: Int, who: Int) -> Numbers {
        ["a": Double(a), "b": Double(b), "s": Double(s), "f": Double(f), "who": Double(who)]
    }
    public struct Parts: Sendable {
        public let a: Int, b: Int, s: Int, f: Int, who: Int
        public init(_ x: Numbers) {
            a = max(100, min(999, G3.int(x, "a", 458))); b = max(1, min(999, G3.int(x, "b", 275))); s = G3.int(x, "s", 1) < 0 ? -1 : 1
            f = max(1, min(999, G3.int(x, "f", 633))); who = max(0, min(P3.cast.count - 1, G3.int(x, "who")))
        }
        public var name: String { P3.cast[who] }
        public var sign: String { s == 1 ? "+" : "−" }
        public var ra: Int { P3.rh(a) }
        public var rb: Int { P3.rh(b) }
        public var E: Int { ra + s * rb }
        public var gap: Int { abs(f - E) }
        public var yes: Bool { gap <= 100 }
        public var on: String { s == 1 ? "on" : "back" }
        public var says: String { "\(name) says \(a) \(sign) \(b) = \(f)." }
        /// A number let go away from its nearest hundred (`low`: on the hundred below, which halfway doesn't round to).
        public func far(_ v: Int, low: Bool) -> String {
            let lo = v / 100 * 100, hi = lo + 100
            if v - lo == 50 && low { return "Exactly halfway rounds up." }
            return hi - v <= v - lo ? "\(v) is \(hi - v) from \(hi) and \(v - lo) from \(lo)." : "\(v) is \(v - lo) from \(lo) and \(hi - v) from \(hi)."
        }
        /// The drags' codes: 1 both rounded, 2 / 3 a or b let go on the wrong hundred, 4 / 5 the same on the lower end of halfway.
        public func roundSaid(_ x: Int) -> String {
            switch x {
            case 2: return far(a, low: false)
            case 3: return far(b, low: false)
            case 4: return far(a, low: true)
            case 5: return far(b, low: true)
            default: return "Drag each number to its nearest hundred."
            }
        }
        public func hops(_ k: Int) -> String { "That's \(k * 100). Hop \(rb) \(on)." }
        public var judged: String {
            !yes ? "\(f) is \(gap) from \(E). That's outside." : gap == 0 ? "\(f) is right on \(E). It could be right." : "\(f) is only \(gap) from \(E). It could be right."
        }
        public var why: String { "About \(E), so \(f) \(yes ? "could" : "can't") be right." }
        public var record: String { yes ? "\(f) is close to \(E)." : "\(f) is too far from \(E)." }
    }

    /// The design's: a, b, s from Add and subtract's generator (b three-digit), the friend's answer f: half the time right;
    /// otherwise one of Add and subtract's slips or the answer ± 200, at least 150 from the estimate (early: 300).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        while true {
            let (a, b, s) = P3.addsub(&rng, i, three: true), r = a + s * b, E = P3.rh(a) + s * P3.rh(b)
            let who = Int.random(in: 0..<P3.cast.count, using: &rng)
            if Double.random(in: 0..<1, using: &rng) < 0.5 { return numbers(a: a, b: b, s: s, f: r, who: who) }
            let far = i < 3 ? 300 : 150
            var cands: [Int] = []
            for j in P3.jumps(a: a, b: b, s: s) {
                if j.place == 100 { cands.append(r - s * (j.v - j.d)) }
                if s == 1 && j.place == 10 && j.digit + j.v >= 100 { cands.append(r - 100) }
                if s == -1 && j.place == 10 && j.digit < j.v { cands.append(r + 100) }
            }
            cands += [a - s * b, r + 200, r - 200]
            let ok = cands.filter { $0 != r && $0 >= 1 && $0 <= 999 && abs($0 - E) >= far }
            if !ok.isEmpty { return numbers(a: a, b: b, s: s, f: ok[Int.random(in: 0..<ok.count, using: &rng)], who: who) }
        }
    }

    public static let spec = LessonSpec(id: "g3-estimate", title: "Estimate to check", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op(P.sign), .num(Double(P.b)), .op("="), .num(Double(P.f)), .text("?")] },
        idea: { _ in "Round each number to the nearest hundred: the answer must be close to that." },
        depends: ["g3-round", "g3-addsub"],
        check: [CheckItem(3, when: { Parts($0).f == Parts($0).a + Parts($0).s * Parts($0).b }),
                CheckItem(3, when: { Parts($0).f != Parts($0).a + Parts($0).s * Parts($0).b }),
                CheckItem(3, when: { Parts($0).s == -1 }),
                CheckItem(3, when: { let P = Parts($0); return P.s == -1 && P.f != P.a - P.b })]) { x in
        let P = Parts(x)
        let roundHint = "Which hundred is each number closer to?"
        let round = LessonStep(StepWords(say: "\(P.says) Drag each number to its nearest hundred.", hint: roundHint, action: "Check"),
            answer: G2.hand("x", 1, hint: roundHint, explain: "\(P.a) ≈ \(P.ra), \(P.b) ≈ \(P.rb).", said: { c in P.roundSaid(c) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hopHint = "One hop is 100."
        let hop = LessonStep(StepWords(say: "Hop \(P.rb) \(P.on) from \(P.ra).", hint: hopHint, action: "Check"),
            answer: G2.hand("k", P.rb / 100, hint: hopHint, explain: "\(P.ra) \(P.sign) \(P.rb) = \(P.E).", said: { k in P.hops(k) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Count \(P.on) \(G3.count(P.rb / 100, "hundred")) from \(P.ra)."
        let write = LessonStep(StepWords(say: "Write \(P.ra) \(P.sign) \(P.rb).", hint: writeHint, action: "Check"),
            answer: G3.typed("E", P.E, [(P.ra - P.s * P.rb, P.s == 1 ? "This is adding, so the number gets bigger." : "This is taking away, so the number gets smaller.")],
                             hint: writeHint, explain: "\(P.ra) \(P.sign) \(P.rb) = \(P.E)."),
            picture: ["at": 2])
        let judge = LessonStep(StepWords(say: "\(P.says) Tap Yes or No: could \(P.name) be right?", hint: "Is \(P.f) in the band?", action: "Check"),
            answer: G2.hand("c", P.yes ? 0 : 1, hint: "Is \(P.f) in the band?", explain: P.judged, said: { _ in P.judged }),
            picture: ["at": 3])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [round, hop, write, judge, done]
    }
}
