import Foundation

/// What 2nd grade's chapter 6, Time and money, shares (design/grade2.md chapter 6, the preview
/// design/prototype/grade2-ch6.html): on the clock's hour strip a square is 5 minutes; the coins true to each other's size; a
/// cent is a 3 × 3 counter, so a dollar is a 30 × 30 square of 100 cents in four quarter blocks; a bill is 10 × 4 and a dollar
/// a little $1 cell of the dollar chart. Every number the child writes is typed with the iPad's keys and Check, as the preview
/// types; the hands do the rest (tap the hour, trace round the clock, turn its long hand, tap a name or a coin, slide coins and
/// bills in, fill the dollar square). The preview's words, slips and generators word for word.
public enum TM2 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G2.int(v, k, d) }
    /// "05", "25".
    public static func two(_ m: Int) -> String { m < 10 ? "0\(m)" : "\(m)" }
    public static func cents(_ v: Int) -> String { "\(v) \(v == 1 ? "cent" : "cents")" }
    static func shuffled(_ a: [Int], _ rng: inout SeededRandom) -> [Int] { Data2.shuffled(a, &rng) }

    /// The coins: a penny, a nickel, a dime and a quarter (the preview's COINS).
    public struct Coin: Sendable {
        public let name: String, many: String, value: Int
        /// Across, in squares, in Name the coin (true to each other's size), and fanned in a row (Counting money).
        public let across: Int, small: Int
        public let bumpy: Bool
    }
    public static let coins = [
        Coin(name: "penny", many: "pennies", value: 1, across: 16, small: 6, bumpy: false),
        Coin(name: "nickel", many: "nickels", value: 5, across: 18, small: 7, bumpy: false),
        Coin(name: "dime", many: "dimes", value: 10, across: 15, small: 6, bumpy: true),
        Coin(name: "quarter", many: "quarters", value: 25, across: 20, small: 8, bumpy: true),
    ]
    public static let penny = 0, nickel = 1, dime = 2, quarter = 3
    public static func coinName(_ c: Int, _ n: Int) -> String { n == 1 ? coins[c].name : coins[c].many }

    /// A kind of coin or bill counted in, biggest first: its kind (a coin's index, or a bill's dollars), how many, the
    /// running total before and after.
    public struct Group: Sendable, Equatable {
        public let kind: Int, value: Int, count: Int, before: Int
        public var after: Int { before + value * count }
    }
    /// The coins of q quarters, d dimes, n nickels and p pennies, biggest first, the empty kinds left out.
    public static func groups(q: Int, d: Int, n: Int, p: Int) -> [Group] {
        var out: [Group] = [], t = 0
        let list = [(quarter, q), (dime, d), (nickel, n), (penny, p)]
        for (c, k) in list where k > 0 {
            out.append(Group(kind: c, value: coins[c].value, count: k, before: t))
            t += coins[c].value * k
        }
        return out
    }
    /// An amount in the fewest coins: quarters, dimes, nickels, pennies.
    public static func coinsFor(_ a: Int) -> [Group] {
        let q = a / 25, d = a % 25 / 10, n = a % 25 % 10 / 5
        return groups(q: q, d: d, n: n, p: a - 25 * q - 10 * d - 5 * n)
    }
    /// The n-th cent's cell in the dollar square (its top-left, from the square's): block by block (25), row by row (5).
    public static func centAt(_ n: Int) -> (x: Int, y: Int) {
        let b = n / 25, w = n % 25
        return (15 * (b % 2) + 3 * (w % 5), 15 * (b / 2) + 3 * (w / 5))
    }
}

// MARK: - Time to 5 minutes

/// Time to 5 minutes (g2-time5; 2.MD.C.7, folds a.m./p.m. and setting a clock). A square is 5 minutes on the hour strip
/// (12 squares an hour) beside 1st grade's clock. Tap the hour (the number the short hand has just passed); trace from 12 to
/// the long hand (the face shades, snapping at each number, 5, 10, 15 … written outside the edge); write [3]:[25]. On
/// problems 4, 7, 10 … a time of day ("School ends.") and a.m. or p.m. picked; on 5, 8, 11 … the time is written and the
/// long hand turned round to it, the short hand creeping with it.
///
/// "kind" 0 read, 1 a.m. or p.m., 2 set; "hour", "minute", "e" the time of day. "at": 0 hour, 1 trace, 2 write, 3 a.m. or
/// p.m., 4 done, 5 turn. Boxes: "h" the number tapped; "n" the numbers traced (−1 started away from 12, −2 the wrong way);
/// "x", "y" the time written; "c" 0 a.m., 1 p.m.; "t" the numbers the long hand was turned on.
public enum Time5 {
    public struct Event: Sendable { public let what: String, hours: [Int], pm: Bool, why: String }
    public static let events = [
        Event(what: "Time to wake up.", hours: [6], pm: false, why: "You wake up in the morning: a.m."),
        Event(what: "Breakfast.", hours: [7], pm: false, why: "Breakfast is in the morning: a.m."),
        Event(what: "School starts.", hours: [8], pm: false, why: "School starts in the morning: a.m."),
        Event(what: "Recess.", hours: [10], pm: false, why: "Recess is in the morning: a.m."),
        Event(what: "Lunch.", hours: [12], pm: true, why: "Lunch is just after noon: p.m."),
        Event(what: "School ends.", hours: [2], pm: true, why: "School ends in the afternoon: p.m."),
        Event(what: "Soccer.", hours: [4], pm: true, why: "Soccer is in the afternoon: p.m."),
        Event(what: "Dinner.", hours: [5, 6], pm: true, why: "Dinner is in the evening: p.m."),
        Event(what: "Bedtime.", hours: [7, 8], pm: true, why: "Bedtime is in the evening: p.m."),
    ]
    public enum Kind: Int, Sendable { case read, ampm, set }
    public static func kind(_ i: Int) -> Kind { i >= 4 && (i - 4) % 3 == 0 ? .ampm : i >= 5 && (i - 5) % 3 == 0 ? .set : .read }
    public static let wrongStart = -1, wrongWay = -2

    public static func numbers(kind: Kind = .read, hour: Int, minute: Int, e: Int = 0) -> Numbers {
        ["kind": Double(kind.rawValue), "hour": Double(hour), "minute": Double(minute), "e": Double(e)]
    }
    public struct Parts: Sendable {
        public let kind: Kind, H: Int, M: Int, e: Int
        public init(_ x: Numbers) {
            kind = Kind(rawValue: TM2.int(x, "kind")) ?? .read
            H = max(1, min(12, TM2.int(x, "hour", 3)))
            M = 5 * max(0, min(11, TM2.int(x, "minute", 25) / 5))
            e = max(0, min(Time5.events.count - 1, TM2.int(x, "e")))
        }
        public var ev: Event? { kind == .ampm ? Time5.events[e] : nil }
        public var set: Bool { kind == .set }
        /// The number the long hand points at (12 on the hour).
        public var K: Int { M == 0 ? 12 : M / 5 }
        public var next: Int { H % 12 + 1 }
        public var prev: Int { (H + 10) % 12 + 1 }
        /// "3:25".
        public var time: String { "\(H):\(TM2.two(M))" }
        /// The long hand on n: "3:05" … "4:00".
        public func timeOf(_ n: Int) -> String { n >= 12 ? "\(next):00" : "\(H):\(TM2.two(5 * n))" }
        /// The story's sentence before each line (the preview's: on the one row with the instruction).
        func told(_ s: String) -> String { ev.map { "\($0.what) \(s)" } ?? s }
        public static let hourSay = "Tap the hour.", traceSay = "Trace from 12 to the long hand.", writeSay = "Write the time."
        public static let ampmSay = "Tap a.m. or p.m.", turnSay = "Turn the long hand to this time."
        public static let why = "The long hand moves 5 minutes from one number to the next."
        public func tapped(_ n: Int) -> String {
            if M > 0 && n == next { return "The short hand is past \(H) but has not reached \(next) yet, so the hour is still \(H)." }
            if n == K { return "That's the long hand. The hour hand is the short one." }
            return M > 0 ? "Find the short hand. Which number has it just passed?" : "Find the short hand. Which number does it point to?"
        }
        public func traced(_ n: Int) -> String {
            if n == Time5.wrongStart { return "Start at 12." }
            if n == Time5.wrongWay { return "Clocks go this way." }
            if M == 0 { return "On 12, no minutes have gone by." }
            return n > K ? "That's \(5 * n). Stop at the long hand." : "Keep going to the long hand."
        }
        public func turned(_ n: Int) -> String {
            if n > K { return "That's \(timeOf(n)). " + (n == K + 1 ? "Back one number." : "Back to \(K).") }
            return "That's \(timeOf(n)). Keep going."
        }
        /// The web's slips for the written time (an answer that is itself right is left out).
        public var slips: [(h: Int, m: Int, say: String)] {
            let all: [(h: Int, m: Int, say: String)] = [
                (next, M, "The short hand has not reached \(next) yet, so the hour is \(H)."),
                (H, K, "The long hand on \(K) means \(M) minutes."),
                (K, (H % 12) * 5, "The short hand gives the hour and the long hand gives the minutes."),
            ]
            return all.filter { !($0.h == H && $0.m == M) }
        }
        public static let plain = "The hour from the short hand goes first, then the minutes you counted."
        public func written(_ h: Int, _ m: Int) -> String? {
            if h == H && m == M { return nil }
            return slips.first { $0.h == h && $0.m == m }?.say ?? Parts.plain
        }
    }

    /// The web's: hour 1–12; problems 0–2 minutes 5–30, later 0–55. The fold's times of day; a time to set is never on the hour.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let k = kind(i)
        if k == .ampm {
            let e = Int.random(in: 0..<events.count, using: &rng), hs = events[e].hours
            return numbers(kind: k, hour: hs[Int.random(in: 0..<hs.count, using: &rng)], minute: 5 * Int.random(in: 0...11, using: &rng), e: e)
        }
        let h = Int.random(in: 1...12, using: &rng)
        let m = k == .set ? Int.random(in: 1...11, using: &rng) : i < 3 ? Int.random(in: 1...6, using: &rng) : Int.random(in: 0...11, using: &rng)
        return numbers(kind: k, hour: h, minute: 5 * m)
    }

    public static let spec = LessonSpec(id: "g2-time5", title: "Time to 5 minutes", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("What time is it?")] },
        idea: { _ in Parts.why },
        depends: ["g1-time", "g2-skip"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).M >= 35 }), CheckItem(3, when: { Parts($0).M == 0 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let done = LessonStep(StepWords(say: P.told(Parts.why), hint: "", action: "Next problem"), picture: ["at": 4])
        if P.set {
            let hint = "Go round from 12, 5 minutes a number."
            let turn = LessonStep(StepWords(say: Parts.turnSay, hint: hint, action: "Check"),
                answer: G2.hand("t", P.K, hint: hint, explain: "\(P.time).", said: { P.turned($0) }),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [turn, done]
        }
        let hourHint = "The short hand is the short, thick one."
        let hour = LessonStep(StepWords(say: P.told(Parts.hourSay), hint: hourHint, action: "Check"),
            answer: G2.hand("h", P.H, hint: hourHint, explain: "The short hand tells the hour: \(P.H).", said: { P.tapped($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let traceHint = "Start at 12 and go round the way the numbers count."
        let trace = LessonStep(StepWords(say: P.told(Parts.traceSay), hint: traceHint, action: "Check"),
            answer: G2.hand("n", P.M == 0 ? 0 : P.K, hint: traceHint, explain: "\(P.M) minutes.", said: { P.traced($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: P.told(Parts.writeSay), hint: Parts.plain, action: "Check"),
            answer: AnswerTask(prompt: [.box("x"), .op(":"), .box("y")], expected: ["x": Double(P.H), "y": Double(P.M)], hint: Parts.plain,
                               explain: "\(P.time).",
                               check: { v in
                                   guard let h = v["x"], let m = v["y"] else { return .soft(Parts.writeSay) }
                                   return P.written(Int(h.rounded()), Int(m.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: Parts.writeSay),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        guard let ev = P.ev else { return [hour, trace, write, done] }
        let apHint = "Morning is a.m. Afternoon and evening are p.m."
        let ampm = LessonStep(StepWords(say: P.told(Parts.ampmSay), hint: apHint, action: "Check"),
            answer: G2.hand("c", ev.pm ? 1 : 0, hint: apHint, explain: ev.pm ? "p.m." : "a.m.", said: { _ in ev.why }),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [hour, trace, write, ampm, done]
    }
}

// MARK: - Name the coin

/// Name the coin (g2-coins; 2.MD.C.8). The coin big, true to the others' size (a dime 15 squares across, a penny 16, a nickel
/// 18, a quarter 20), its edge bumpy or smooth, a star (heads) or two leaves (tails), no name or number; four name blocks
/// under it. Tap its name (its edge traces), then write `A dime is [10]¢` and its cents draw beside it, five to a row. From
/// problem 5 a pair every third: both names, then tap the one worth more, the cents drawn under both.
///
/// "kind" 0 one coin, 1 a pair; "coin" (the left), "other" (the right), "side" 0 heads 1 tails. "at": 0 name (the left), 1
/// the right's name, 2 the one worth more, 3 write, 4 done. Boxes: "c" the name tapped (0 penny … 3 quarter), "w" the coin
/// tapped (0 left, 1 right), "x" written.
public enum Coins2 {
    public static func numbers(coin: Int, other: Int? = nil, side: Int = 0) -> Numbers {
        ["kind": other == nil ? 0 : 1, "coin": Double(coin), "other": Double(other ?? coin), "side": Double(side)]
    }
    public struct Parts: Sendable {
        public let pair: Bool, coin: Int, other: Int, side: Int
        public init(_ x: Numbers) {
            pair = TM2.int(x, "kind") == 1
            coin = max(0, min(3, TM2.int(x, "coin", 1)))
            let o = max(0, min(3, TM2.int(x, "other", coin)))
            other = pair && o == coin ? (coin + 1) % 4 : o
            side = TM2.int(x, "side") == 1 ? 1 : 0
        }
        public var a: TM2.Coin { TM2.coins[coin] }
        public var b: TM2.Coin { TM2.coins[other] }
        /// The coins shown, left to right.
        public var shown: [Int] { pair ? [coin, other] : [coin] }
        /// Which is worth more: 0 the left, 1 the right.
        public var right: Int { a.value > b.value ? 0 : 1 }
        public var win: TM2.Coin { right == 0 ? a : b }
        public var lose: TM2.Coin { right == 0 ? b : a }
        /// The one worth more is the smaller one.
        public var fooled: Bool { pair && win.across < lose.across }
        public static let nameSay = "Tap its name.", leftSay = "Tap the left coin's name.", rightSay = "Tap the right coin's name."
        public static let moreSay = "Tap the one worth more.", writeSay = "Write what it's worth."
        public static let why = "A coin's size doesn't tell what it's worth."
        /// The web's: why a picked name is wrong for this coin.
        public static func nameSlip(_ coin: Int, _ i: Int) -> String {
            if coin == TM2.dime && i == TM2.nickel { return "The dime is the smallest coin and has a bumpy edge. A nickel is bigger and smooth." }
            if coin != TM2.penny && i == TM2.penny { return "A penny is the copper-colored coin. This one is silver." }
            if coin == TM2.nickel && i == TM2.quarter { return "The quarter is the biggest coin and has a bumpy edge. A nickel's edge is smooth." }
            if coin == TM2.penny { return "This coin is copper-colored: that's a penny." }
            if coin == TM2.nickel && i == TM2.dime { return "A dime is smaller and has a bumpy edge. This one is smooth: a nickel." }
            if coin == TM2.quarter { return "This is the biggest coin, with a bumpy edge: a quarter." }
            return "This is the smallest coin, with a bumpy edge: a dime."
        }
        public var moreMiss: String {
            fooled ? "The \(lose.name) is bigger, but the \(win.name) is worth more: \(win.value) cents to \(lose.value)."
                : "A \(lose.name) is worth \(TM2.cents(lose.value)) and a \(win.name) \(TM2.cents(win.value)). The \(win.name) is worth more."
        }
        public var slips: [(Int, String)] {
            var out: [(Int, String)] = []
            if coin == TM2.dime { out.append((5, "A dime is small but worth 10 cents.")) }
            if coin == TM2.nickel { out.append((1, "A nickel is worth 5 pennies: 5 cents.")) }
            for (i, o) in TM2.coins.enumerated() where i != coin {
                out.append((o.value, "That's what a \(o.name) is worth. A \(a.name) is worth \(TM2.cents(a.value))."))
            }
            return out
        }
        public static let plain = "Penny 1, nickel 5, dime 10, quarter 25."
    }

    /// The web's: single coins in turn; from problem 5 a pair every third, half of them a dime against a bigger coin worth less.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let side = Int.random(in: 0...1, using: &rng)
        if i < 3 || i % 3 != 2 { return numbers(coin: (i * 3 + 1) % 4, side: side) }
        var two: [Int]
        if Int.random(in: 0...1, using: &rng) == 1 { two = [TM2.dime, Int.random(in: 0...1, using: &rng)] }
        else { two = Array(TM2.shuffled([0, 1, 2, 3], &rng).prefix(2)) }
        if Int.random(in: 0...1, using: &rng) == 1 { two.reverse() }
        return numbers(coin: two[0], other: two[1], side: side)
    }

    public static let spec = LessonSpec(id: "g2-coins", title: "Name the coin", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Which coin is this?")] },
        idea: { _ in Parts.why },
        check: [CheckItem(0, when: { Parts($0).coin == TM2.nickel && !Parts($0).pair }), CheckItem(3, when: { Parts($0).coin == TM2.dime && !Parts($0).pair }),
                CheckItem(5, when: { Parts($0).fooled }), CheckItem(5)]) { x in
        let P = Parts(x)
        let nameHint = "Look at its size, its color and its edge."
        func name(_ j: Int, _ say: String, _ at: Int) -> LessonStep {
            let c = P.shown[j]
            return LessonStep(StepWords(say: say, hint: nameHint, action: "Check"),
                answer: G2.hand(j == 0 ? "c" : "d", c, hint: nameHint, explain: "A \(TM2.coins[c].name).", said: { Parts.nameSlip(c, $0) }),
                picture: ["at": Double(at)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        if P.pair {
            let moreHint = "Think of what each coin is worth, not its size."
            let more = LessonStep(StepWords(say: Parts.moreSay, hint: moreHint, action: "Check"),
                answer: G2.hand("w", P.right, hint: moreHint, explain: "The \(P.win.name): \(P.win.value)¢.", said: { _ in P.moreMiss }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [name(0, Parts.leftSay, 0), name(1, Parts.rightSay, 1), more, done]
        }
        let write = LessonStep(StepWords(say: Parts.writeSay, hint: Parts.plain, action: "Check"),
            answer: G2.typed("x", P.a.value, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "A \(P.a.name) is \(P.a.value)¢."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [name(0, Parts.nameSay, 0), write, done]
    }
}

// MARK: - Counting money

/// Counting money (g2-money; 2.MD.C.8). A cent is a 3 × 3 counter, so a dollar is the dollar square (30 × 30) in four quarter
/// blocks. The coins at the left in rows by kind, the biggest on top, fanned; the empty square at the right. Slide each kind in,
/// biggest first: its cents pour into the square block by block, row by row (the readout counts coins, never cents); write the
/// running total after each kind: `50¢ 60¢ [65]¢`.
///
/// "q", "d", "n", "p" the coins; "side". "at": 2k slide kind k, 2k + 1 write after it, 2 × kinds done. Boxes: "s<k>" the row
/// slid in (its index), "a<k>" written.
public enum Money2 {
    public static func numbers(q: Int, d: Int, n: Int, p: Int, side: Int = 0) -> Numbers {
        ["q": Double(q), "d": Double(d), "n": Double(n), "p": Double(p), "side": Double(side)]
    }
    public struct Parts: Sendable {
        public let q: Int, d: Int, n: Int, p: Int, side: Int
        public init(_ x: Numbers) {
            q = max(0, min(3, TM2.int(x, "q"))); d = max(0, min(4, TM2.int(x, "d", 2))); n = max(0, min(4, TM2.int(x, "n", 1)))
            p = max(0, min(4, TM2.int(x, "p", 3))); side = TM2.int(x, "side") == 1 ? 1 : 0
        }
        public var G: [TM2.Group] { TM2.groups(q: q, d: d, n: n, p: p) }
        public var total: Int { 25 * q + 10 * d + 5 * n + p }
        public static func name(_ g: TM2.Group) -> String { TM2.coinName(g.kind, g.count) }
        public func say(_ k: Int) -> String { "Slide in the \(Parts.name(G[k]))." }
        public static func writeSay(_ k: Int) -> String { k == 0 ? "Count the cents. Write how much." : "Count on. Write how much." }
        public static let why = "Count the coins worth most first, then count on."
        public func order(_ k: Int) -> String {
            let g = G[k]
            return k == 0 ? "Start with the \(Parts.name(g))." : "The \(Parts.name(g)) \(g.count == 1 ? "comes" : "come") next."
        }
        /// The web's slips for each kind's running total.
        public static func slips(_ g: TM2.Group) -> [(Int, String)] {
            let v = g.value, c = g.count, before = g.before, one = TM2.coins[g.kind].name
            var out: [(Int, String)] = []
            if v != 1 { out.append((before + c, "A \(one) is worth \(v)¢, not 1¢. Count on by \(v)s.")) }
            if v == 5 { out.append((before + 10 * c, "A nickel is 5¢. It's bigger than a dime, but worth less.")) }
            if v == 10 { out.append((before + 5 * c, "A dime is 10¢, even though it's the smallest coin.")) }
            if v == 25 { out.append((before + 10 * c, "A quarter is 25¢. Count 25, 50, 75.")) }
            if v == 1 { out.append((before + 5 * c, "A penny is only 1¢. Count on by ones.")) }
            if before > 0 { out.append((c * v, "Keep the \(before)¢ you already counted and count on from there.")) }
            out.append((before + (c + 1) * v, "There \(c == 1 ? "is" : "are") \(c) \(TM2.coinName(g.kind, c)). Count one \(v) for each."))
            return out
        }
        public static func plain(_ g: TM2.Group) -> String {
            (g.before > 0 ? "Start at \(g.before)¢ and count on" : "Count") + " by \(g.value)s, one count for each coin."
        }
    }

    /// The web's: problems 0–2 two kinds of dimes, nickels and pennies (1–4 each); later 1–3 quarters and more; at most 9 coins,
    /// at least two kinds, under a dollar.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let side = Int.random(in: 0...1, using: &rng)
        while true {
            var q = 0, d = 0, n = 0, p = 0
            if i < 3 {
                let two = TM2.shuffled([0, 1, 2], &rng).prefix(2)
                if two.contains(0) { d = Int.random(in: 1...4, using: &rng) }
                if two.contains(1) { n = Int.random(in: 1...4, using: &rng) }
                if two.contains(2) { p = Int.random(in: 1...4, using: &rng) }
            } else {
                q = Int.random(in: 1...3, using: &rng)
                if Double.random(in: 0..<1, using: &rng) < 0.7 { d = Int.random(in: 1...3, using: &rng) }
                if Double.random(in: 0..<1, using: &rng) < 0.6 { n = Int.random(in: 1...2, using: &rng) }
                if Double.random(in: 0..<1, using: &rng) < 0.7 { p = Int.random(in: 1...4, using: &rng) }
            }
            var kinds = 0
            for c in [q, d, n, p] where c > 0 { kinds += 1 }
            let all = q + d + n + p, cents = 25 * q + 10 * d + 5 * n + p
            if kinds >= 2 && all <= 9 && cents <= 99 { return numbers(q: q, d: d, n: n, p: p, side: side) }
        }
    }

    public static let spec = LessonSpec(id: "g2-money", title: "Counting money", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How much money is this?")] },
        idea: { _ in Parts.why },
        depends: ["g2-coins", "g2-skip"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).d == 0 }), CheckItem(3, when: { Parts($0).G.count >= 3 }), CheckItem(3)]) { x in
        let P = Parts(x), G = P.G
        var out: [LessonStep] = []
        for (k, g) in G.enumerated() {
            let slideHint = "Coins worth the most go first."
            out.append(LessonStep(StepWords(say: P.say(k), hint: slideHint, action: "Check"),
                answer: G2.hand("s\(k)", k, hint: slideHint, explain: "The \(Parts.name(g)).", said: { _ in P.order(k) }),
                picture: ["at": Double(2 * k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            let plain = Parts.plain(g)
            out.append(LessonStep(StepWords(say: Parts.writeSay(k), hint: plain, action: "Check"),
                answer: G2.typed("a\(k)", g.after, Parts.slips(g), plain: plain, hint: plain, explain: "\(g.after)¢."),
                picture: ["at": Double(2 * k + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        out.append(LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": Double(2 * G.count)]))
        return out
    }
}

// MARK: - Dollars and cents

/// Dollars and cents (g2-dollars, new; 2.MD.C.8, $ and ¢, word problems). Bills: bills 10 × 4 fanned in rows by kind, the
/// biggest on top; at the right the dollar chart, rows of ten $1 cells; slide each kind in, biggest first, and write the total
/// after it (`$20 $25 $[27]`). Cents stories, the story and the instruction on the top row over Counting money's dollar square,
/// the first amount's cents poured in from its coins: making a dollar (tap each empty row or block to fill it; `100¢ − 65¢ =
/// [35]¢`), buying (slide the price over the cents and they're crossed out; `45¢ − 30¢ = [15]¢`), in all (slide in the second
/// amount's coins; `45¢ + 30¢ = [75]¢`).
///
/// "kind" 0 bills, 1 a dollar, 2 buying, 3 in all; bills "b20", "b10", "b5", "b1"; "who", "who2", "A", "B", "p" the price,
/// "item". "at": bills as Counting money (2k slide, 2k + 1 write, 2 × kinds done); the stories 0 fill or slide, 1 write, 2
/// done. Boxes: bills "s<k>", "a<k>"; "f" filled (100 full, −1 a full part tapped), "t" 1 slid in; "x" written.
public enum Dollars2 {
    public enum Kind: Int, Sendable { case bills, dollar, buy, inall }
    public static let people = ["Ana", "Ben", "Mia", "Sam", "Leo", "Zoe", "Max", "Ivy"]
    public struct Item: Sendable { public let thing: String, a: String }
    public static let items = [Item(thing: "pencil", a: "A pencil"), Item(thing: "crayon", a: "A crayon"), Item(thing: "eraser", a: "An eraser"),
                               Item(thing: "marker", a: "A marker"), Item(thing: "ribbon", a: "A ribbon")]
    public static let bills = [20, 10, 5, 1]
    public static func kind(_ i: Int) -> Kind {
        let list: [Kind] = [.bills, .dollar, .buy, .inall]
        return i < 3 ? list[i] : list[(i - 3) % 4]
    }
    public static func numbers(bills c: [Int: Int]) -> Numbers {
        var out: Numbers = ["kind": 0]
        for v in bills { out["b\(v)"] = Double(c[v] ?? 0) }
        return out
    }
    public static func numbers(_ kind: Kind, who: Int = 0, A: Int, B: Int = 0, price: Int = 0, item: Int = 0, who2: Int = 1) -> Numbers {
        ["kind": Double(kind.rawValue), "who": Double(who), "who2": Double(who2), "A": Double(A), "B": Double(B), "p": Double(price), "item": Double(item)]
    }
    public struct Parts: Sendable {
        public let kind: Kind, c: [Int: Int], who: Int, who2: Int, A: Int, B: Int, price: Int, item: Int
        public init(_ x: Numbers) {
            kind = Kind(rawValue: TM2.int(x, "kind")) ?? .bills
            var cs: [Int: Int] = [:]
            for v in Dollars2.bills { cs[v] = max(0, min(4, TM2.int(x, "b\(v)"))) }
            if kind == .bills && cs.values.reduce(0, +) == 0 { cs[10] = 2; cs[1] = 3 }
            c = cs
            who = max(0, min(7, TM2.int(x, "who")))
            let w2 = max(0, min(7, TM2.int(x, "who2", 1))); who2 = w2 == who ? (who + 1) % 8 : w2
            A = max(5, min(99, TM2.int(x, "A", 45)))
            B = max(0, min(99 - A, TM2.int(x, "B", 30)))
            price = max(1, min(A, TM2.int(x, "p", 30)))
            item = max(0, min(4, TM2.int(x, "item")))
        }
        public var N1: String { Dollars2.people[who] }
        public var N2: String { Dollars2.people[who2] }
        public var thing: Item { Dollars2.items[item] }
        /// The bills, biggest first, as groups whose value is the bill's dollars.
        public var G: [TM2.Group] {
            var out: [TM2.Group] = [], t = 0
            for v in Dollars2.bills where (c[v] ?? 0) > 0 {
                out.append(TM2.Group(kind: v, value: v, count: c[v] ?? 0, before: t))
                t += v * (c[v] ?? 0)
            }
            return out
        }
        public var total: Int { G.last?.after ?? 0 }
        public static func billName(_ g: TM2.Group) -> String { "$\(g.value) \(g.count == 1 ? "bill" : "bills")" }
        public func say(_ k: Int) -> String { "Slide in the \(Parts.billName(G[k]))." }
        public static func writeSay(_ k: Int) -> String { k == 0 ? "Count the dollars. Write how much." : "Count on. Write how much." }
        public static let billsWhy = "Count bills like coins: biggest first."
        public func order(_ k: Int) -> String {
            let g = G[k]
            return k == 0 ? "Start with the \(Parts.billName(g))." : "The \(Parts.billName(g)) \(g.count == 1 ? "comes" : "come") next."
        }
        public static func billSlips(_ g: TM2.Group) -> [(Int, String)] {
            let v = g.value, c = g.count, b = g.before
            var out: [(Int, String)] = []
            if v == 5 { out.append((b + c, "A $5 bill is 5 dollars. Count on by 5.")) }
            if v == 20 { out.append((b + 10 * c, "A $20 bill is 20 dollars. Count on by 20.")); out.append((b + c, "A $20 bill is 20 dollars. Count on by 20.")) }
            if v == 10 { out.append((b + c, "A $10 bill is 10 dollars. Count on by 10.")) }
            if b > 0 { out.append((c * v, "Keep the $\(b) you already counted and count on.")) }
            out.append((g.after + 10, "That's a ten too many. Each full row is $10."))
            out.append((g.after - 10, "That's a ten too few. Each full row is $10."))
            return out
        }
        public static func billPlain(_ g: TM2.Group) -> String {
            (g.before > 0 ? "Start at $\(g.before) and count on" : "Count") + " by \(g.value)s, one for each bill."
        }

        // the cents stories
        public var story: String { kind == .inall ? "\(N1) has \(A)¢. \(N2) has \(B)¢." : "\(N1) has \(A)¢." }
        public var want: Int { kind == .buy ? A - price : kind == .dollar ? 100 - A : A + B }
        public var firstSay: String {
            switch kind {
            case .buy: return "\(thing.a) is \(price)¢. Slide it over."
            case .dollar: return "Fill it to make a dollar."
            default: return "Slide in \(N2)'s coins."
            }
        }
        public var writeSay: String {
            switch kind {
            case .buy: return "How much is left? Write it."
            case .dollar: return "How much more makes a dollar?"
            default: return "How much in all? Write it."
            }
        }
        public static let centsWhy = "100 cents fill the dollar square."
        public static let full = "That part is full. Tap an empty row."
        public var slips: [(Int, String)] {
            switch kind {
            case .buy:
                return [(A + price, "Buying takes money away. Count the cents not crossed out."), (A, "That's what \(N1) had. Count the cents not crossed out."),
                        (price, "That's the price. Count the cents not crossed out."), (want + 10, "That's a ten too many. Count the cents left by tens, then ones."),
                        (want - 10, "That's a ten too few. Count the cents left by tens, then ones.")]
            case .dollar:
                return [(A, "That's what you have. How much more makes 100¢?"), (100, "That's the whole dollar. Count only the new cents."),
                        (want + 10, "That's a ten too many. A block is 25 and a row is 5."), (want - 10, "That's a ten too few. A block is 25 and a row is 5.")]
            default:
                return [(abs(A - B), "In all means put them together. Add."), (A, "That's \(N1)'s money. Count both together."), (B, "That's \(N2)'s money. Count both together."),
                        (want + 10, "That's a ten too many. Count by 25s, then tens, then ones."), (want - 10, "That's a ten too few. Count by 25s, then tens, then ones.")]
            }
        }
        public var plain: String {
            switch kind {
            case .buy: return "Count the cents not crossed out."
            case .dollar: return "Count the new cents: 25 for a block, 5 for a row."
            default: return "Count all the cents in the square."
            }
        }
        /// The fills of making a dollar: from A, the next row (5) until a block is whole, then a block (25), to 100.
        public var fills: [Int] {
            var out: [Int] = [], t = A
            while t < 100 { t += t % 25 != 0 ? 5 : 25; out.append(t) }
            return out
        }
        /// The record's line before its box: `45¢ − 30¢ =`.
        public var lead: [String] {
            switch kind {
            case .buy: return ["\(A)¢", "−", "\(price)¢", "="]
            case .dollar: return ["100¢", "−", "\(A)¢", "="]
            default: return ["\(A)¢", "+", "\(B)¢", "="]
            }
        }
    }

    /// Bills $1, $5, $10 ($20 from problem 6), 2–7 bills, up to $99 (problems 0–2: $10 and $1 only); making a dollar from
    /// 10–95¢ in 5s (problem 1: a whole ten); buying 20–99¢ with a price of 10–80¢ less than it (problem 2: no trade); in all,
    /// two amounts up to 99¢.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let k = kind(i), who = Int.random(in: 0..<people.count, using: &rng)
        switch k {
        case .bills:
            while true {
                let pool = i < 3 ? [10, 1] : i >= 6 ? [20, 10, 5, 1] : [10, 5, 1]
                var c: [Int: Int] = [:]
                for v in pool { c[v] = v == 1 ? Int.random(in: 0...4, using: &rng) : v == 5 ? Int.random(in: 0...2, using: &rng) : Int.random(in: 0...3, using: &rng) }
                var all = 0, kinds = 0, tot = 0
                for (v, n) in c { all += n; tot += v * n; if n > 0 { kinds += 1 } }
                if all >= 2 && all <= 7 && kinds >= 2 && tot <= 99 { return numbers(bills: c) }
            }
        case .dollar:
            let A = i < 3 ? 10 * Int.random(in: 1...9, using: &rng) : 5 * Int.random(in: 2...19, using: &rng)
            return numbers(.dollar, who: who, A: A)
        case .buy:
            while true {
                let A = Int.random(in: 20...99, using: &rng), p = Int.random(in: 10...80, using: &rng)
                if p >= A || (i < 3 && p % 10 > A % 10) { continue }
                return numbers(.buy, who: who, A: A, price: p, item: Int.random(in: 0..<items.count, using: &rng))
            }
        case .inall:
            while true {
                let A = Int.random(in: 10...89, using: &rng), B = Int.random(in: 10...89, using: &rng)
                if A + B > 99 { continue }
                return numbers(.inall, who: who, A: A, B: B, who2: (who + Int.random(in: 1...(people.count - 1), using: &rng)) % people.count)
            }
        }
    }

    public static let spec = LessonSpec(id: "g2-dollars", title: "Dollars and cents", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How much money?")] },
        idea: { x in Parts(x).kind == .bills ? Parts.billsWhy : Parts.centsWhy },
        depends: ["g2-money", "g2-subregroup"],
        check: [CheckItem(3), CheckItem(4), CheckItem(5), CheckItem(6)]) { x in
        let P = Parts(x)
        if P.kind == .bills {
            var out: [LessonStep] = []
            for (k, g) in P.G.enumerated() {
                let slideHint = "Bills worth the most go first."
                out.append(LessonStep(StepWords(say: P.say(k), hint: slideHint, action: "Check"),
                    answer: G2.hand("s\(k)", k, hint: slideHint, explain: "The \(Parts.billName(g)).", said: { _ in P.order(k) }),
                    picture: ["at": Double(2 * k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
                let plain = Parts.billPlain(g)
                out.append(LessonStep(StepWords(say: Parts.writeSay(k), hint: plain, action: "Check"),
                    answer: G2.typed("a\(k)", g.after, Parts.billSlips(g), plain: plain, hint: plain, explain: "$\(g.after)."),
                    picture: ["at": Double(2 * k + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            }
            out.append(LessonStep(StepWords(say: Parts.billsWhy, hint: "", action: "Next problem"), picture: ["at": Double(2 * P.G.count)]))
            return out
        }
        let told = { (s: String) -> String in "\(P.story) \(s)" }
        let first: LessonStep
        if P.kind == .dollar {
            let hint = "Tap the empty rows and blocks."
            first = LessonStep(StepWords(say: told(P.firstSay), hint: hint, action: "Check"),
                answer: G2.hand("f", 100, hint: hint, explain: "100¢.", said: { _ in Parts.full }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        } else {
            let hint = P.kind == .buy ? "Drag it onto the cents." : "Drag the coins into the square."
            first = LessonStep(StepWords(say: told(P.firstSay), hint: hint, action: "Check"),
                answer: G2.hand("t", 1, hint: hint, explain: P.kind == .buy ? "\(P.price)¢ crossed out." : "\(P.B)¢ more.", said: { _ in hint }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let write = LessonStep(StepWords(say: told(P.writeSay), hint: P.plain, action: "Check"),
            answer: G2.typed("x", P.want, P.slips, plain: P.plain, hint: P.plain, explain: "\(P.want)¢."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: told(Parts.centsWhy), hint: "", action: "Next problem"), picture: ["at": 2])
        return [first, write, done]
    }
}
