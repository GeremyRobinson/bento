import Foundation

/// What 2nd grade's chapter 2, Numbers to 1000, shares (design/grade2.md chapter 2, the preview
/// design/prototype/grade2-ch2.html): number names, places, the problems' numbers, their slips and lines word for word.
/// Every number the child writes is typed with the iPad's keys and Check, as the preview types; the hands do the rest.
public enum Num2 {
    public static let place = ["hundreds", "tens", "ones"], unit = ["hundred", "ten", "one"]
    public static let ones = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    public static let teens = ["ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    public static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
    /// The hundreds, tens and ones digits.
    public static func digits(_ n: Int) -> [Int] { [n / 100, n / 10 % 10, n % 10] }
    static func rest(_ r: Int) -> [String] {
        if r == 0 { return [] }
        if r < 10 { return [ones[r]] }
        if r < 20 { return [teens[r - 10]] }
        return r % 10 != 0 ? [tens[r / 10], ones[r % 10]] : [tens[r / 10]]
    }
    /// A number's name as words, as school writes it: six hundred five → ["six", "hundred", "five"].
    public static func words(_ n: Int) -> [String] { [ones[n / 100], "hundred"] + rest(n % 100) }
    /// The words joined, a tens word and a ones word with a hyphen: "four hundred sixty-two".
    public static func joined(_ ws: [String]) -> String {
        var s = ""
        for (i, w) in ws.enumerated() {
            if i == 0 { s = w; continue }
            let prev = ws[i - 1]
            s += (tens.contains(prev) && !prev.isEmpty && ones.contains(w)) ? "-" + w : " " + w
        }
        return s
    }
    public static func name(_ n: Int) -> String { joined(words(n)) }
    static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
}

// MARK: - Hundreds, tens and ones

/// Hundreds, tens and ones (the web's g2-hundreds; 2.NBT.A.1, 1a, 1b, 2.NBT.A.3). One square is one: a ten is a strip 1 × 10,
/// a hundred a flat 10 × 10. Tap each place's column to put its pieces in (the last drags back out), Check; then write what
/// each part is worth, `347 = [300] + [40] + [7]`. A number told in words (problems 4, 10, …) is built and written as a
/// number (`six hundred five = [605]`); on 7, 13, … the record ends by tapping word blocks into its name.
///
/// "named" 0 a number, 1 told in words, 2 its name written with word blocks; "mix" the blocks' order.
/// "at": 0 hundreds, 1 tens, 2 ones, 3 write, 4 words, 5 done. Boxes: "h", "t", "o" the pieces counted (−1: a later
/// place tapped first), "e0" "e1" "e2" (or "x") written, "w" the words (1 done; a wrong word −1 − its block − 10 × written).
public enum Hundreds2 {
    public static func numbers(n: Int, named: Int = 0, mix: Int = 0) -> Numbers { ["n": Double(n), "named": Double(named), "mix": Double(mix)] }
    public struct Parts: Sendable {
        public let n: Int, named: Int, mix: Int
        public init(_ x: Numbers) {
            n = max(100, min(999, G2.int(x, "n", 347))); named = max(0, min(2, G2.int(x, "named"))); mix = G2.int(x, "mix")
        }
        public var D: [Int] { Num2.digits(n) }
        public var read: Bool { named == 1 }
        public var name: String { Num2.name(n) }
        /// How the lines name the number: "347", or "Six hundred five" when it was told in words.
        public var nm: String { read ? Num2.cap(name) : "\(n)" }
        public var need: [String] { Num2.words(n) }
        /// The word blocks: the name's words and up to two that put a digit in the wrong place, in the problem's own order.
        public var blocks: [String] {
            guard named == 2 else { return [] }
            let h = D[0], t = D[1], o = D[2]
            var extra: [String] = []
            for w in [h >= 2 ? Num2.tens[h] : nil, o >= 2 ? Num2.tens[o] : nil, t >= 1 ? Num2.ones[t] : nil].compactMap({ $0 })
            where !need.contains(w) && !extra.contains(w) && extra.count < 2 { extra.append(w) }
            var rng = SeededRandom(seed: UInt64(max(0, mix)) + 11)
            return (need + extra).map { ($0, Int.random(in: 0...9999, using: &rng)) }.sorted { $0.1 < $1.1 }.map(\.0)
        }
        public static let say = ["Put in the hundreds.", "Now the tens.", "Now the ones."]
        /// A later place tapped first.
        public static let first = ["Start with the hundreds.", "Now the tens.", "Now the ones."]
        public func miss(_ c: Int, _ k: Int) -> String {
            if k < 0 { return Self.first[c] }
            let v = k * [100, 10, 1][c], r = n % 100, h = D[0], t = D[1], o = D[2]
            if !read { return "That's \(v). The \(D[c]) means \(G2.count(D[c], Num2.unit[c]))." }
            if c == 0 { return "That's \(v). \(Num2.cap(Num2.ones[h])) hundred means \(G2.count(h, "hundred"))." }
            if r >= 10 && r < 20 { return "That's \(v). \(Num2.cap(Num2.teens[r - 10])) means 1 ten and \(G2.count(o, "one"))." }
            if c == 1 { return r >= 20 ? "That's \(v). \(Num2.cap(Num2.tens[t])) means \(G2.count(t, "ten"))." : "That's \(v). \(nm) has 0 tens." }
            return o > 0 ? "That's \(v). \(Num2.cap(Num2.ones[o])) means \(G2.count(o, "one"))." : "That's \(v). \(nm) has 0 ones."
        }
        /// A tenth ten (or one) tapped in: they slide together into the next place's piece.
        public func together(_ c: Int) -> String {
            c == 1 ? "10 tens make a hundred. \(nm) has \(G2.count(D[1], "ten"))." : "10 ones make a ten. \(nm) has \(G2.count(D[2], "one"))."
        }
        public var plainRead: String { "\(nm) is \(G2.count(D[0], "hundred")), \(G2.count(D[1], "ten")) and \(G2.count(D[2], "one"))." }
        /// A wrong word block: what it says (the code from the word's block and how many are written).
        public func word(_ code: Int) -> String {
            let k = -1 - code, wrote = k / 10, list = blocks, need = need
            guard list.indices.contains(k % 10), wrote < need.count else { return "Tap the words in order." }
            let w = list[k % 10], want = need[wrote], h = D[0], t = D[1], o = D[2]
            let di = Num2.tens.firstIndex(of: w) ?? -1, oi = Num2.ones.firstIndex(of: w) ?? -1
            if wrote < 2 && (w == "hundred" || (need.firstIndex(of: w) ?? -1) >= 2 || di >= 2 || (oi >= 0 && w != Num2.ones[h])) {
                return "Start with the hundreds: \(Num2.ones[h]) hundred."
            }
            if di >= 2 && di != t { return "\(Num2.cap(w)) is \(di) tens. \(n) has \(G2.count(t, "ten"))." }
            if oi >= 0 && !need.dropFirst(2).contains(w) { return "\(Num2.cap(w)) is \(G2.count(oi, "one")). \(n) has \(G2.count(o, "one"))." }
            return "Next comes \(want)."
        }
        public var why: String { "Where a digit sits tells what it's worth." }
    }

    /// The preview's: 100–999, problems 0–2 with no zero digit; whole hundreds on 5, 11, …; told in words on 4, 10, …,
    /// its name written with word blocks on 7, 13, ….
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let lo = i < 3 ? 1 : 0, whole = i >= 5 && i % 6 == 5
        let named = i >= 4 && (i - 4) % 3 == 0 ? ((i - 4) % 6 == 0 ? 1 : 2) : 0
        let h = Int.random(in: 1...9, using: &rng)
        let n = whole ? h * 100 : h * 100 + Int.random(in: lo...9, using: &rng) * 10 + Int.random(in: lo...9, using: &rng)
        return numbers(n: n, named: named, mix: Int.random(in: 0...9999, using: &rng))
    }

    public static let spec = LessonSpec(id: "g2-hundreds", title: "Hundreds, tens and ones", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).n))] },
        idea: { _ in "Each digit tells how many hundreds, tens or ones there are." },
        depends: ["g1-tensones"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).D[1] == 0 }), CheckItem(3, when: { Parts($0).D[2] == 0 }), CheckItem(3)]) { x in
        let P = Parts(x), D = P.D
        let hints = ["The hundreds digit is the first one on the left.", "The tens digit is the one in the middle.", "The ones digit is the last one, on the right."]
        let box = ["h", "t", "o"]
        var steps = (0..<3).map { c in
            LessonStep(StepWords(say: Parts.say[c], hint: hints[c], action: "Check"),
                       answer: G2.hand(box[c], D[c], hint: hints[c], explain: G2.count(D[c], Num2.unit[c]) + ".", said: { P.miss(c, $0) }),
                       picture: ["at": Double(c)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        if P.read {
            steps.append(LessonStep(StepWords(say: "Write the number.", hint: P.plainRead, action: "Check"),
                answer: G2.typed("x", P.n, [], plain: P.plainRead, hint: P.plainRead, explain: "\(P.nm) is \(P.n)."),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            let (h, t, o) = (D[0], D[1], D[2])
            let hint = "A hundred is worth 100 and a ten is worth 10."
            let task = AnswerTask(prompt: [.num(Double(P.n)), .op("="), .box("e0"), .op("+"), .box("e1"), .op("+"), .box("e2")],
                                  expected: ["e0": Double(h * 100), "e1": Double(t * 10), "e2": Double(o)], hint: hint,
                                  explain: "\(P.n) = \(h * 100) + \(t * 10) + \(o).",
                                  check: { v in
                                      guard let a = v["e0"], let b = v["e1"], let c = v["e2"] else { return .soft("Write each part.") }
                                      let A = Int(a.rounded()), B = Int(b.rounded()), C = Int(c.rounded())
                                      if A == h * 100 && B == t * 10 && C == o { return .right }
                                      if A == h && B == t && C == o && (h > 0 || t > 0) {
                                          return .wrong("Each digit is worth its place. \(G2.count(h, "hundred")) is \(h * 100), and \(G2.count(t, "ten")) is \(t * 10).")
                                      }
                                      if A == h * 100 && B == t && t > 0 && C == o { return .wrong("The \(t) is in the tens place, so it is worth \(t * 10).") }
                                      if A == h && B == t * 10 && C == o { return .wrong("The \(h) is in the hundreds place, so it is worth \(h * 100).") }
                                      return .wrong(hint)
                                  }, incomplete: "Write each part.")
            steps.append(LessonStep(StepWords(say: "Write what each part is worth.", hint: "Add up what each part is worth.", action: "Check"),
                                    answer: task, picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if P.named == 2 {
            let hint = "Read it from the left: \(Num2.ones[D[0]]) hundred first."
            steps.append(LessonStep(StepWords(say: "Write its name: tap the words.", hint: hint, action: "Check"),
                answer: G2.hand("w", 1, hint: hint, explain: "\(P.n) is \(P.name).", said: { P.word($0) }),
                picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 5]))
        return steps
    }
}

// MARK: - Skip counting

/// Skip counting (the web's g2-skip; 2.NBT.A.2, fold 2.NBT.B.8). A number line, six marks 10 squares apart, small marks
/// inside each hop for its units; the first three numbers under their marks, boxes under the other three. Hop from the
/// first to the second a unit at a time (the small hops count, "+5"); then hop on a whole jump and write where you land,
/// three times. Every third from problem 4 hops by 10 or 100 on or back, or by 1 across a hundred.
///
/// "start", "by", "back" (1: right to left, the numbers falling). "at": 0 the jump, then for each of marks 3–5 a hop
/// (1, 3, 5) and its write (2, 4, 6), 7 done. Boxes: "j" the small hops made (units), "p3"… the hop (1), "b3"… written.
public enum Skip2 {
    public static func numbers(start: Int, by: Int, back: Bool = false) -> Numbers { ["start": Double(start), "by": Double(by), "back": back ? 1 : 0] }
    public struct Parts: Sendable {
        public let start: Int, by: Int, back: Bool
        public init(_ x: Numbers) {
            by = [1, 2, 5, 10, 100].contains(G2.int(x, "by", 5)) ? G2.int(x, "by", 5) : 5
            back = G2.int(x, "back") != 0
            start = max(back ? 5 * by : 0, min(999 - (back ? 0 : 5 * by), G2.int(x, "start", 15)))
        }
        public var s: Int { back ? -1 : 1 }
        public func v(_ j: Int) -> Int { start + s * j * by }
        /// The small hops in a jump, each one's worth and length in squares.
        public var units: Int { by == 2 ? 2 : by == 5 ? 5 : by == 1 ? 1 : 10 }
        public var uv: Int { by / units }
        public var ul: Double { 10 / Double(units) }
        public var crosses: Bool { (1...5).contains { v($0) / 100 != v($0 - 1) / 100 } }
        public var op: String { back ? "−" : "+" }
        public var jump: String { "Hop \(back ? "back " : "")from \(v(0)) to \(v(1))." }
        public var hop: String { "Hop \(back ? "back" : "on"). Write where you land." }
        public func short(_ k: Int) -> String { "That's \(k * uv). Go on to \(v(1))." }
        public func slips(_ j: Int) -> [(Int, String)] {
            let before = v(j - 1)
            var out = [(before + s, "Jump by \(by), not by 1: \(before) \(op) \(by).")]
            if by != 10 { out.append((before + s * 10, "The jump is \(by), not 10: \(before) \(op) \(by).")) }
            out.append((before - s * by, back ? "The numbers are getting smaller, so count back." : "The numbers are getting bigger, so count up: \(before) + \(by)."))
            return out
        }
        public func plain(_ j: Int) -> String { back ? "Take \(by) from \(v(j - 1))." : "Add \(by) to \(v(j - 1))." }
        /// A number written whose hundreds digit changed.
        public func crossed(_ j: Int) -> Bool { v(j) / 100 != v(j - 1) / 100 }
        public static let hundred = "10 tens make a hundred, so the hundreds digit changed too."
        public var why: String {
            by == 100 ? "Every hop is 100, so only the hundreds digit changes."
                : crosses ? Self.hundred
                : by == 10 ? "Every hop is 10, so only the tens digit changes." : "Every hop is \(by), so each number is \(by) \(back ? "less" : "more")."
        }
    }

    /// The preview's: problems 0–2 by 2, 5 or 10 from a multiple (0–6 jumps in); then by 5 from 10–150, by 10 from 1–60,
    /// by 100 from 100–499; every third from problem 4 a fold: by 10 or 100 on or back (half of the tens crossing a hundred),
    /// or by 1 across a hundred.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i >= 4 && (i - 4) % 3 == 0 {
            let kind = r(0, 4)
            if kind == 4 { return numbers(start: r(2, 9) * 100 - r(3, 4), by: 1) }
            let by = kind >= 2 ? 100 : 10, back = kind % 2 == 1
            let start: Int
            if by == 100 { start = back ? r(600, 900) : r(100, 499) }
            else if r(0, 1) == 1 { start = back ? r(2, 8) * 100 + r(0, 40) : r(1, 8) * 100 + r(55, 99) }
            else { start = back ? r(150, 900) : r(100, 900) }
            return numbers(start: start, by: by, back: back)
        }
        if i < 3 { let by = [2, 5, 10][r(0, 2)]; return numbers(start: by * r(0, 6), by: by) }
        switch r(0, 2) {
        case 0: return numbers(start: 5 * r(2, 30), by: 5)
        case 1: return numbers(start: r(1, 60), by: 10)
        default: return numbers(start: r(1, 4) * 100 + [0, 20, 50, r(1, 99)][r(0, 3)], by: 100)
        }
    }

    public static let spec = LessonSpec(id: "g2-skip", title: "Skip counting", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.v(0))), .op(","), .num(Double(P.v(1))), .op(","), .num(Double(P.v(2))), .op(","), .box("b3")] },
        idea: { x in Parts(x).why },
        depends: ["k-tens", "g2-hundreds"],
        check: [CheckItem(0, when: { Parts($0).by == 2 }), CheckItem(3, when: { Parts($0).by == 5 }),
                CheckItem(3, when: { Parts($0).by == 10 && Parts($0).start % 10 != 0 }), CheckItem(3, when: { Parts($0).by == 100 })]) { x in
        let P = Parts(x)
        let jumpHint = "\(P.v(1)) to \(P.v(2)) is the same jump."
        var steps = [LessonStep(StepWords(say: P.jump, hint: jumpHint, action: "Check"),
                                answer: G2.hand("j", P.units, hint: jumpHint, explain: "\(P.v(0)) \(P.op) \(P.by) = \(P.v(1)).", said: { P.short($0) }),
                                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])]
        let hints = ["Hop \(P.by) more.", "Same jump again.", "One more hop of \(P.by)."]
        for (k, j) in (3...5).enumerated() {
            // a number written whose hundreds digit changed: the next hop's line says why (the preview's note)
            let say = j > 3 && P.by < 100 && P.crossed(j - 1) ? Parts.hundred + " " + P.hop : P.hop
            steps.append(LessonStep(StepWords(say: say, hint: hints[k], action: "Check"),
                answer: G2.hand("p\(j)", 1, hint: hints[k], explain: "", said: { _ in "Hop a whole jump." }),
                picture: ["at": Double(2 * k + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            steps.append(LessonStep(StepWords(say: P.hop, hint: hints[k], action: "Check"),
                answer: G2.typed("b\(j)", P.v(j), P.slips(j), plain: P.plain(j), hint: hints[k], explain: "\(P.v(j - 1)) \(P.op) \(P.by) = \(P.v(j))."),
                picture: ["at": Double(2 * k + 2)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 7]))
        return steps
    }
}

// MARK: - Compare three-digit numbers

/// Compare three-digit numbers (g2-compare, new; 2.NBT.A.4). 5th grade's Comparing decimals for whole numbers: line 1 runs
/// 0 to 1000 in ten blocks of a hundred; a block both numbers are in opens below into the next line, ten blocks of ten,
/// then ten blocks of one. Tap the block they're both in (or each one's), then <, = or >: `427 < 461`.
///
/// "a", "b". "at": 0, 1, 2 the same block on line 1, 2, 3 (as many as the places that match), then the split (each
/// one's block), the sign, done. Boxes: "s0"… the block tapped, "p" the split (1; −1 − the block neither is in), "g" the
/// sign (0 <, 1 =, 2 >).
public enum Compare2 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(100, min(999, G2.int(x, "a", 427))); b = max(100, min(999, G2.int(x, "b", 461))) }
        public var da: [Int] { Num2.digits(a) }
        public var db: [Int] { Num2.digits(b) }
        /// The place where they first differ (3: equal).
        public var d: Int { (0..<3).first { da[$0] != db[$0] } ?? 3 }
        public var sign: Int { a < b ? 0 : a == b ? 1 : 2 }
        public static let signs = ["<", "=", ">"]
        public var trap: Bool { d == 0 && ((da[0] < db[0] && da[1] > db[1]) || (db[0] < da[0] && db[1] > da[1])) }
        public static func size(_ j: Int) -> Int { [100, 10, 1][j] }
        /// Where line j starts.
        public func lo(_ j: Int) -> Int { j == 0 ? 0 : a / (10 * Self.size(j)) * 10 * Self.size(j) }
        public func span(_ j: Int, _ bl: Int) -> String {
            let base = lo(j), s = Self.size(j)
            return j == 2 ? "\(base + bl)" : "between \(base + bl * s) and \(base + (bl + 1) * s)"
        }
        /// The steps' lines: the same block(s) first, then each one's.
        public var stages: Int { min(d, 3) }
        public func sameSay(_ j: Int) -> String { j == 2 ? "Tap where they both are." : "Tap the \(Num2.unit[j]) they're both in." }
        public var splitSay: String { d == 2 ? "Tap where each one is." : "Tap the \(Num2.unit[d]) each one is in." }
        public func signMiss(_ p: Int) -> String {
            if d == 3 { return "Same hundreds, tens and ones. They're equal." }
            let look = "Look at the \(Num2.place[d]): \(da[d]) and \(db[d])."
            return p == 1 ? "\(look) They're not the same." : "\(look) The open side faces the bigger one."
        }
        public var why: String {
            if d == 3 { return "Same hundreds, tens and ones, so they're equal." }
            let big = max(da[d], db[d]), small = min(da[d], db[d])
            let are = "\(G2.count(big, Num2.unit[d])) \(big == 1 ? "is" : "are")"
            if d == 0 { return "\(are) more than \(G2.count(small, "hundred")), whatever the tens." }
            let both = (0..<d).map { G2.count(da[$0], Num2.unit[$0]) }.joined(separator: " and ")
            return "Both have \(both). \(are) more than \(G2.count(small, Num2.unit[d]))."
        }
    }

    /// The design's: problems 0–2 different hundreds; from 3 different hundreds 1 in 3 (half of them the trap: the smaller
    /// number has the bigger tens), the same hundreds 1 in 3, the same hundreds and tens 1 in 4, equal 1 in 12.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        var kind = 0, trap = false
        if i >= 3 { let k = r(0, 11); kind = k < 4 ? 0 : k < 8 ? 1 : k < 11 ? 2 : 3; trap = kind == 0 && r(0, 1) == 1 }
        while true {
            let h1 = r(1, 9), t1 = r(0, 9), o1 = r(0, 9)
            var h2 = h1, t2 = t1, o2 = o1
            switch kind {
            case 0:
                repeat { h2 = r(1, 9) } while h2 == h1
                t2 = r(0, 9); o2 = r(0, 9)
                if trap && !((h1 < h2 && t1 > t2) || (h2 < h1 && t2 > t1)) { continue }
            case 1: repeat { t2 = r(0, 9) } while t2 == t1; o2 = r(0, 9)
            case 2: repeat { o2 = r(0, 9) } while o2 == o1
            default: break
            }
            let A = h1 * 100 + t1 * 10 + o1, B = h2 * 100 + t2 * 10 + o2
            return r(0, 1) == 1 ? numbers(a: B, b: A) : numbers(a: A, b: B)
        }
    }

    public static let spec = LessonSpec(id: "g2-compare", title: "Compare three-digit numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .box("c"), .num(Double(P.b))] },
        idea: { _ in "Look at the hundreds first, then the tens, then the ones." },
        depends: ["g2-hundreds", "g1-compare"],
        check: [CheckItem(3, when: { Parts($0).trap }), CheckItem(3, when: { Parts($0).d >= 1 }), CheckItem(3, when: { Parts($0).d >= 2 }), CheckItem(3)]) { x in
        let P = Parts(x), da = P.da, db = P.db
        let lineHint = "Find each number's hundreds digit."
        var steps = (0..<P.stages).map { j in
            LessonStep(StepWords(say: P.sameSay(j), hint: j == 0 ? lineHint : "Find the \(Num2.place[j]) digit.", action: "Check"),
                       answer: G2.hand("s\(j)", da[j], hint: lineHint, explain: "", said: { "They aren't \(P.span(j, $0))." }),
                       picture: ["at": Double(j)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        if P.d < 3 {
            let hint = "Look at the \(Num2.place[P.d]) digits: \(da[P.d]) and \(db[P.d])."
            steps.append(LessonStep(StepWords(say: P.splitSay, hint: hint, action: "Check"),
                answer: G2.hand("p", 1, hint: hint, explain: "", said: { "Neither number is \(P.span(P.d, -1 - $0))." }),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let signHint = P.d == 3 ? "Same hundreds, tens and ones." : "The open side faces the bigger one."
        steps.append(LessonStep(StepWords(say: "Tap <, = or >.", hint: signHint, action: "Check"),
            answer: G2.hand("g", P.sign, hint: signHint, explain: "\(P.a) \(Parts.signs[P.sign]) \(P.b).", said: { P.signMiss($0) }),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 5]))
        return steps
    }
}

// MARK: - Add and subtract within 1000

/// Add and subtract within 1000 (the web's g2-within1000; 2.NBT.B.7, 2.NBT.B.9): the web's hops by place, on Comparing's
/// lines, each to scale. Line 1 is 0 to 1000, a block a hundred; line 2 two hundreds, 3 squares a ten; line 3 two tens,
/// 3 squares a one. Hop the hundreds, then the tens, then the ones (each line opening under the last), the record writing
/// each hop; then write the sum. Taking away hops back.
///
/// "a", "b", "sub". "at": 0 hundreds, 1 tens, 2 ones, 3 write, 4 done. Boxes: "h0" "h1" "h2" the hops made (signed),
/// "x" the answer.
public enum Within2 {
    public static func numbers(a: Int, b: Int, sub: Bool) -> Numbers { ["a": Double(a), "b": Double(b), "sub": sub ? 1 : 0] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, sub: Bool
        public init(_ x: Numbers) {
            sub = G2.int(x, "sub") != 0
            let bb = max(111, min(sub ? 699 : 599, G2.int(x, "b", 132)))
            b = bb
            a = sub ? max(bb + 1, min(999, G2.int(x, "a", 377))) : max(100, min(999 - bb, G2.int(x, "a", 245)))
        }
        public var s: Int { sub ? -1 : 1 }
        public var B: [Int] { Num2.digits(b) }
        public var sg: String { sub ? "−" : "+" }
        public var p1: Int { a + s * 100 * B[0] }
        public var p2: Int { p1 + s * 10 * B[1] }
        public var r: Int { p2 + s * B[2] }
        public var starts: [Int] { [a, p1, p2] }
        public var ends: [Int] { [p1, p2, r] }
        /// What each place of b is worth: 100, 30, 2.
        public func part(_ n: Int) -> Int { [100, 10, 1][n] * B[n] }
        /// Where lines 2 and 3 start (two hundreds, two tens).
        public var base2: Int { min(800, max(0, p1 / 100 * 100 - (sub ? 100 : 0))) }
        public var base3: Int { max(0, p2 / 10 * 10 - (sub ? 10 : 0)) }
        public var crossedH: Bool { p2 / 100 != p1 / 100 }
        public func say(_ n: Int) -> String { "Hop \(sub ? "back" : "on") \(G2.count(B[n], Num2.unit[n]))." }
        public func miss(_ n: Int, _ k: Int) -> String {
            if k != 0 && (k > 0 ? 1 : -1) != s { return sub ? "Taking away goes down." : "Adding goes up." }
            return "That's \(G2.count(abs(k), Num2.unit[n])). \(b) has \(B[n])."
        }
        /// Each place added (or taken) on its own, nothing traded: the web's "forgot to trade".
        public var untraded: Int {
            var acc = a
            for place in [100, 10, 1] {
                let dx = acc / place % 10, dy = b / place % 10
                acc = acc - dx * place + (sub ? abs(dx - dy) : (dx + dy) % 10) * place
            }
            return acc
        }
        public var slips: [(Int, String)] {
            [(untraded, sub ? "In a place where the top digit is smaller, trade from the next place first." : "When a place makes 10 or more, trade 10 of them for 1 in the next place."),
             (sub ? a + b : abs(a - b), sub ? "This is taking away, so the answer is smaller." : "This is adding, so the answer is bigger.")]
        }
        public static let plain = "Use your last hop: it landed on the answer."
        public var why: String {
            crossedH ? (sub ? "A hundred is 10 tens, so the hundreds changed too." : "10 tens make a hundred, so the hundreds changed too.")
                : "Hundreds, then tens, then ones: one place at a time."
        }
    }

    /// The web's: b with no zero digit, its hundreds 1–5 (1–6 taking away); problems 0–3 cross no ten or hundred and later
    /// ones always do; adding or taking away at random.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let easy = i < 4, sub = Bool.random(using: &rng)
        while true {
            let b = Int.random(in: 1...(sub ? 6 : 5), using: &rng) * 100 + Int.random(in: 1...9, using: &rng) * 10 + Int.random(in: 1...9, using: &rng)
            guard (sub ? b + 50 : 100) <= (sub ? 999 : 999 - b) else { continue }
            let a = sub ? Int.random(in: (b + 50)...999, using: &rng) : Int.random(in: 100...(999 - b), using: &rng)
            let A = Num2.digits(a), Bd = Num2.digits(b)
            let crosses = sub ? A[2] < Bd[2] || A[1] < Bd[1] : A[2] + Bd[2] >= 10 || A[1] + Bd[1] >= 10
            if easy == crosses { continue }
            return numbers(a: a, b: b, sub: sub)
        }
    }

    public static let spec = LessonSpec(id: "g2-within1000", title: "Add and subtract within 1000", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op(P.sg), .num(Double(P.b)), .op("="), .box("x")] },
        idea: { _ in "Break the second number into hundreds, tens and ones, then hop by each." },
        depends: ["g2-hundreds", "g2-regroup", "g2-subregroup"],
        check: [CheckItem(0), CheckItem(4, when: { !Parts($0).sub }), CheckItem(4, when: { Parts($0).sub }), CheckItem(4)]) { x in
        let P = Parts(x), how = P.sub ? "Hop back" : "Hop on"
        let hints = ["Break \(P.b) into \(P.part(0)), \(P.part(1)) and \(P.part(2)). \(how) \(P.part(0)) first.", "\(how) the tens.", "\(how) the ones."]
        var steps = (0..<3).map { n in
            LessonStep(StepWords(say: P.say(n), hint: hints[n], action: "Check"),
                       answer: G2.hand("h\(n)", P.s * P.B[n], hint: hints[n], explain: "\(P.starts[n]) \(P.sg) \(P.part(n)) = \(P.ends[n]).", said: { P.miss(n, $0) }),
                       picture: ["at": Double(n)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let hint = "The last hop lands on the answer."
        steps.append(LessonStep(StepWords(say: G2.write, hint: hint, action: "Check"),
            answer: G2.typed("x", P.r, P.slips, plain: Parts.plain, hint: hint, explain: "\(P.a) \(P.sg) \(P.b) = \(P.r)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
