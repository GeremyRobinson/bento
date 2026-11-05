import Foundation

// 3rd grade's chapter 6, Time and measuring (design/grade3.md chapter 6, the preview design/prototype/grade3-ch6.html): a
// clock face with the hour laid out straight under it (a square a minute), a timeline of o'clocks hopped to the o'clock,
// the whole hours and the minutes left (a square 5 minutes), a thing dropped on the scale that fits and a scale's dial laid
// straight, a tall jug's marks hopped up, and the measuring stories (cells in rows of 10, slid, dragged or dealt). Every
// number the child writes is typed with the iPad's keys and Check; misses and slips are the preview's words.

/// What the chapter shares.
public enum Ms3 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { a >= b ? a : Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func chance(_ p: Double, _ rng: inout SeededRandom) -> Bool { Double.random(in: 0..<1, using: &rng) < p }
    public static func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
    public static func two(_ m: Int) -> String { m < 10 ? "0\(m)" : "\(m)" }
    public static func h12(_ h: Int) -> Int { ((h + 11) % 12) + 1 }
    /// Minutes after midnight as a clock writes them: "9:40".
    public static func clk(_ t: Int) -> String { "\(h12(t / 60)):\(two(t % 60))" }
    public static func ampm(_ t: Int) -> String { t < 720 ? "a.m." : "p.m." }
    /// 1,000 with its comma.
    public static func wc(_ n: Int) -> String {
        let s = String(abs(n))
        var out = ""
        for (i, ch) in s.enumerated() { if i > 0 && (s.count - i) % 3 == 0 { out += "," }; out.append(ch) }
        return (n < 0 ? "−" : "") + out
    }
    public static let who = ["Maya", "Leo", "Ana", "Sam", "Noor", "Eli"]

    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : .wrong(said(x)) }, byHand: true)
    }
    /// Two boxes checked together (a time, or hours and minutes): right; the first slip that matches (nil matches anything);
    /// or the plain line.
    static func pair(_ prompt: MathLine, _ b1: String, _ b2: String, _ A: Int, _ B: Int, _ slips: [(Int?, Int?, String)], plain: String, hint: String,
                     explain: String, incomplete: String) -> AnswerTask {
        let list = slips
        var known: [(values: [String: Double], message: String)] = []
        for s in list { if let x = s.0, let y = s.1, !(x == A && y == B) { known.append(([b1: Double(x), b2: Double(y)], s.2)) } }
        return AnswerTask(prompt: prompt, expected: [b1: Double(A), b2: Double(B)], known: known, hint: hint, explain: explain,
                          check: { v in
                              guard let p = v[b1], let q = v[b2] else { return .soft(incomplete) }
                              let a = Int(p.rounded()), b = Int(q.rounded())
                              if a == A && b == B { return .right }
                              if let s = list.first(where: { ($0.0 == nil || $0.0 == a) && ($0.1 == nil || $0.1 == b) }) { return .wrong(s.2) }
                              return .wrong(plain)
                          }, incomplete: incomplete)
    }
    /// A number typed: right, a known slip, or "Not quite." and the hint (the preview's checkBox).
    static func typed(_ box: String, _ want: Int, _ slips: [(Int, String)], hint: String, explain: String) -> AnswerTask {
        G2.typed(box, want, slips, plain: "Not quite. \(hint)", hint: hint, explain: explain)
    }
}

// MARK: - Time to the minute

/// Time to the minute (g3-clock, new; 3.MD.A.1). One square is a minute: the clock face 20 squares across, and under it the
/// hour laid out straight, 60 squares from 0 to 60, the clock's numbers over its strong lines. Read: tap the hour (the
/// number the short hand has passed), drag along the hour line from 0 to the long hand (a ghost long hand turns with the
/// finger, "47 minutes"), write `[9]:[47]`. Set: turn the long hand to the time (the short hand creeps with it; "4:23").
///
/// "kind" 0 read, 1 set; "h", "m". "at": read 0 hour, 1 drag, 2 write, 3 done; set 5 turn, 6 done. Boxes: "h" the number
/// tapped, "n" the minutes dragged to, "x" "y" the time typed, "t" the minutes turned to.
public enum Clock3 {
    public static func numbers(set: Bool = false, h: Int, m: Int) -> Numbers { ["kind": set ? 1 : 0, "h": Double(h), "m": Double(m)] }
    public struct Parts: Sendable {
        public let setting: Bool, H: Int, M: Int
        public init(_ x: Numbers) {
            setting = Ms3.int(x, "kind") == 1; H = max(1, min(12, Ms3.int(x, "h", 9))); M = max(0, min(59, Ms3.int(x, "m", 47)))
        }
        public var next: Int { H % 12 + 1 }
        /// The number the long hand is nearest.
        public var longNum: Int { let k = Int((Double(M) / 5).rounded()) % 12; return k == 0 ? 12 : k }
        public var time: String { "\(H):\(Ms3.two(M))" }
        public func tapped(_ n: Int) -> String {
            if n == next { return "The short hand hasn't reached \(next) yet." }
            if n == longNum { return "That's where the long hand points." }
            return "Find the short hand. Which number has it just passed?"
        }
        public func dragged(_ n: Int) -> String {
            "That's \(n). The hand is \(Ms3.plural(abs(M - n), "mark", "marks")) \(n < M ? "further" : "back")."
        }
        public func turned(_ n: Int) -> String {
            let d = abs(M - n)
            return n > M ? "That's \(H):\(Ms3.two(n)). Back \(Ms3.plural(d, "minute", "minutes"))." : "That's \(H):\(Ms3.two(n)). \(Ms3.plural(d, "more minute", "more minutes"))."
        }
        public var slips: [(Int?, Int?, String)] {
            var s: [(Int?, Int?, String)] = [(next, nil, "The short hand hasn't reached \(next) yet, so the hour is \(H)."),
                                             (longNum, nil, "That's where the long hand points. The short hand gives the hour.")]
            if M >= 10 && M % 5 != 0 { s.append((H, M / 5, "Each number is 5 minutes. Count by 5s, then 1s.")) }
            s.append((H, M - 1, "That's one mark off. Count the marks again."))
            s.append((H, M + 1, "That's one mark off. Count the marks again."))
            return s.filter { !($0.0 == H && $0.1 == nil) }
        }
        public static let plain = "Not quite. The hour the short hand has passed, then the minutes."
        public var why: String { setting ? "As the minutes go by, the short hand creeps toward \(next)." : "Past \(H), and \(Ms3.plural(M, "minute", "minutes"))." }
    }

    /// The preview's: early, reading with the long hand just past a number (5n + 1 or 2); then set on odd problems, read on
    /// even; m any, a multiple of 5 one time in five (never 0); problem 4 not a multiple of 5; problem 6 45 or more.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let set = i >= 3 && i % 2 == 1, h = Ms3.r(1, 12, &rng)
        var m: Int
        if i < 3 { m = 5 * Ms3.r(0, 11, &rng) + Ms3.r(1, 2, &rng) }
        else if i == 6 { m = Ms3.r(45, 59, &rng) }
        else if i != 4 && Ms3.chance(0.2, &rng) { m = 5 * Ms3.r(1, 11, &rng) }
        else { repeat { m = Ms3.r(1, 59, &rng) } while m % 5 == 0 }
        return numbers(set: set, h: h, m: m)
    }

    public static let spec = LessonSpec(id: "g3-clock", title: "Time to the minute", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("What time is it?")] },
        idea: { _ in "The short hand gives the hour; each mark the long hand passes is a minute." },
        depends: ["g2-time5"],
        check: [CheckItem(3), CheckItem(4, when: { Parts($0).M % 5 != 0 }), CheckItem(5), CheckItem(6)]) { x in
        let P = Parts(x)
        if P.setting {
            let hint = "Go round from 12, a minute a mark."
            let turn = LessonStep(StepWords(say: "Turn the long hand to \(P.time).", hint: hint, action: "Check"),
                answer: Ms3.hand("t", P.M, hint: hint, explain: "\(P.time).", said: { P.turned($0) }),
                picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [turn, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 6])]
        }
        let hourHint = "The short hand is the short, thick one."
        let hour = LessonStep(StepWords(say: "Tap the hour.", hint: hourHint, action: "Check"),
            answer: Ms3.hand("h", P.H, hint: hourHint, explain: "The short hand has passed \(P.H).", said: { P.tapped($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let dragHint = "Drag along the line until the ghost hand lies on the long hand."
        let drag = LessonStep(StepWords(say: "Drag to the long hand.", hint: dragHint, action: "Check"),
            answer: Ms3.hand("n", P.M, hint: dragHint, explain: "\(Ms3.plural(P.M, "minute", "minutes")).", said: { P.dragged($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write the time.", hint: Parts.plain, action: "Check"),
            answer: Ms3.pair([.box("x"), .op(":"), .box("y")], "x", "y", P.H, P.M, P.slips, plain: Parts.plain, hint: Parts.plain,
                             explain: "\(P.time).", incomplete: "Write the hour and the minutes."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [hour, drag, write, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])]
    }
}

// MARK: - Elapsed time

/// Elapsed time (the web's g3-elapsed; 3.MD.A.1). One square is 5 minutes, so an hour is 12 squares: a timeline from the
/// o'clock before the start to the o'clock after the end. Hop to the next o'clock ("20 min"), hop the whole hours ("1 h"),
/// hop the minutes left, then write `20 min + 1 h + 15 min = [1] h [35] min`; when the two minute hops make 60 or more they
/// slide together under the line and 60 of them close into an hour. When does it end (from problem 4, one in three): hop to
/// the o'clock ("15 min · 35 to go"), hop the rest, write `[4]:[35] p.m.`.
///
/// "kind" 0 how long, 1 when it ends; "start", "end" (minutes after midnight) or "start", "len", "ev". "at": 0 to the
/// o'clock, 1 the hours, 2 the minutes left, 3 write, 4 done; ends: 0 to the o'clock, 1 the rest, 2 write, 3 done. Boxes:
/// "a" the first hop's minutes, "b" the hours hopped, "c" the last hop's minutes; "h" "m" the time in all, "x" "y" the end.
public enum Elapsed3 {
    public static let events = ["Practice", "Swim class", "The movie", "Art club", "The bus ride", "Piano lesson"]
    public static func numbers(start: Int, end: Int) -> Numbers { ["kind": 0, "start": Double(start), "end": Double(end)] }
    public static func ends(start: Int, len: Int, ev: Int = 0) -> Numbers { ["kind": 1, "start": Double(start), "len": Double(len), "ev": Double(ev)] }
    public struct Parts: Sendable {
        public let ends: Bool, start: Int, end: Int, ev: Int
        public init(_ x: Numbers) {
            ends = Ms3.int(x, "kind") == 1
            start = max(0, Ms3.int(x, "start", 9 * 60 + 40))
            end = ends ? start + max(5, Ms3.int(x, "len", 50)) : max(start + 65, Ms3.int(x, "end", 11 * 60 + 15))
            ev = max(0, min(Elapsed3.events.count - 1, Ms3.int(x, "ev")))
        }
        public var len: Int { end - start }
        /// The timeline's o'clocks: before the start, after the end; its width in squares.
        public var T0: Int { start / 60 * 60 }
        public var T3: Int { (end + 59) / 60 * 60 }
        public var W: Int { (T3 - T0) / 5 }
        public func X(_ t: Int) -> Int { (t - T0) / 5 }
        public var H1: Int { (start + 59) / 60 }
        public var H2: Int { end / 60 }
        /// The minutes to the o'clock, the whole hours, the minutes left.
        public var m1: Int { H1 * 60 - start }
        public var h: Int { H2 - H1 }
        public var m3: Int { end - H2 * 60 }
        public var th: Int { len / 60 }
        public var tm: Int { len % 60 }
        public var trade: Bool { m1 + m3 >= 60 }
        /// Ends: the minutes left after the o'clock, and the end as a clock writes it.
        public var rest: Int { len - m1 }
        public var EH: Int { Ms3.h12(end / 60) }
        public var EM: Int { end % 60 }
        public var story: String { "\(Elapsed3.events[ev]) starts at \(Ms3.clk(start)) \(Ms3.ampm(start)) It lasts \(len) minutes. When does it end?" }

        public func toSaid(_ x: Int) -> String { "That's \(Ms3.clk(start + x)). Hop to \(Ms3.clk(H1 * 60))." }
        public func hoursSaid(_ n: Int) -> String { n > h ? "That's past \(Ms3.clk(end))." : "That's \(Ms3.clk((H1 + n) * 60)). Hop to \(Ms3.clk(H2 * 60))." }
        public func afterSaid(_ x: Int) -> String { "That's \(Ms3.clk(H2 * 60 + x)). Hop to \(Ms3.clk(end))." }
        public func restSaid(_ x: Int) -> String { "That's \(m1 + x) minutes in all. It lasts \(len)." }
        public var totalSlips: [(Int?, Int?, String)] {
            var s: [(Int?, Int?, String)] = []
            if trade {
                s.append((h, m1 + m3, "\(m1 + m3) minutes is \(m1 + m3 == 60 ? "a whole hour" : "more than an hour"). Trade 60 of them for 1 more hour."))
                s.append((h, m1 + m3 - 60, "You traded 60 minutes for an hour. Add that hour to the \(Ms3.plural(h, "hour", "hours"))."))
            }
            s.append((h, abs(m3 - m1), "Add the minutes before and after: \(m1) + \(m3)."))
            return s.filter { !($0.0 == th && $0.1 == tm) }
        }
        public var totalPlain: String {
            "Not quite. Add the whole hours. Then add the minutes before the hour and the minutes after it." + (trade ? " 60 minutes make 1 more hour." : "")
        }
        public var endSlips: [(Int?, Int?, String)] {
            let sh = Ms3.h12(start / 60), raw = start % 60 + len
            let s: [(Int?, Int?, String)] = [(nil, raw, "There are only 60 minutes in an hour. Go past \(Ms3.clk(H1 * 60))."),
                                             (sh, EM, "It ends after \(Ms3.clk(H1 * 60)), so the hour is \(EH).")]
            return s.filter { !($0.1 == EM && ($0.0 == nil || $0.0 == EH)) }
        }
    }

    /// The preview's (web g3-elapsed): early quarter-hour times, 7–9 a.m. or 1–3 p.m., 1–2 hours, not across noon, the
    /// minutes before and after under 60; then any 5-minute times, sometimes across noon. When does it end, from problem 4
    /// one in three: 20–90 minutes that pass an o'clock.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 3 && (i - 3) % 3 == 0 {
            for _ in 0..<500 {
                let s = 60 * Ms3.r(7, 18, &rng) + 5 * Ms3.r(1, 11, &rng), len = 5 * Ms3.r(4, 18, &rng), e = s + len
                if s % 60 + len <= 60 || e % 60 == 0 || e > 21 * 60 { continue }
                return ends(start: s, len: len, ev: Ms3.r(0, events.count - 1, &rng))
            }
            return ends(start: 15 * 60 + 45, len: 50)
        }
        let early = i < 3
        for _ in 0..<500 {
            let h = early ? Ms3.pick([7, 8, 9, 13, 14, 15], &rng) : Ms3.chance(0.4, &rng) ? Ms3.r(9, 11, &rng) : Ms3.r(6, 17, &rng)
            let hours = Ms3.r(1, early ? 2 : 3, &rng)
            let a = early ? Ms3.pick([15, 30, 45], &rng) : 5 * Ms3.r(1, 11, &rng)
            let b = early ? Ms3.pick([15, 30, 45], &rng) : 5 * Ms3.r(1, 11, &rng)
            let start = h * 60 + a, end = (h + hours + 1) * 60 + b
            if early && (h < 12) != (h + hours + 1 < 12) { continue }
            if early && 60 - start % 60 + end % 60 >= 60 { continue }
            if start < 360 || start > 1200 || end > 21 * 60 + 55 { continue }
            if end / 60 - (start + 59) / 60 < 1 || (end + 59) / 60 - start / 60 > 5 { continue }
            return numbers(start: start, end: end)
        }
        return numbers(start: 9 * 60 + 40, end: 11 * 60 + 15)
    }

    public static let spec = LessonSpec(id: "g3-elapsed", title: "Elapsed time", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How long?")] },
        idea: { _ in "Hop to the o'clock, hop the whole hours, then hop the minutes left." },
        depends: ["g3-clock"],
        check: [CheckItem(2), CheckItem(4), CheckItem(5, when: { Parts($0).trade }), CheckItem(3, when: { Parts($0).ends })]) { x in
        let P = Parts(x)
        let toHint = "Count by 5s up to the o'clock."
        if P.ends {
            let to = LessonStep(StepWords(say: "Hop to the o'clock.", hint: toHint, action: "Check"),
                answer: Ms3.hand("a", P.m1, hint: toHint, explain: "\(P.m1) min.", said: { P.toSaid($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let restHint = "\(P.len) minutes in all: \(P.m1) are hopped."
            let rest = LessonStep(StepWords(say: "Hop the rest.", hint: restHint, action: "Check"),
                answer: Ms3.hand("c", P.rest, hint: restHint, explain: "\(P.rest) min.", said: { P.restSaid($0) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let plain = "Not quite. Read the time where the last hop lands."
            let write = LessonStep(StepWords(say: "Write when it ends.", hint: plain, action: "Check"),
                answer: Ms3.pair([.box("x"), .op(":"), .box("y")], "x", "y", P.EH, P.EM, P.endSlips, plain: plain, hint: plain,
                                 explain: "\(Ms3.clk(P.end)) \(Ms3.ampm(P.end))", incomplete: "Write the hour and the minutes."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [to, rest, write, LessonStep(StepWords(say: "To the o'clock, then the rest.", hint: "", action: "Next problem"), picture: ["at": 3])]
        }
        let to = LessonStep(StepWords(say: "Hop to the next o'clock.", hint: toHint, action: "Check"),
            answer: Ms3.hand("a", P.m1, hint: toHint, explain: "\(P.m1) min.", said: { P.toSaid($0) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hHint = "Each long hop is 1 hour. Stop at \(Ms3.clk(P.H2 * 60))."
        let hours = LessonStep(StepWords(say: "Hop the whole hours.", hint: hHint, action: "Check"),
            answer: Ms3.hand("b", P.h, hint: hHint, explain: "\(P.h) h.", said: { P.hoursSaid($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let aHint = "Count by 5s from \(Ms3.clk(P.H2 * 60)) to \(Ms3.clk(P.end))."
        let after = LessonStep(StepWords(say: "Hop the minutes left.", hint: aHint, action: "Check"),
            answer: Ms3.hand("c", P.m3, hint: aHint, explain: "\(P.m3) min.", said: { P.afterSaid($0) }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let say = P.trade ? "60 minutes make 1 hour. Write the time in all." : "Write the time in all."
        let total = LessonStep(StepWords(say: say, hint: P.totalPlain, action: "Check"),
            answer: Ms3.pair([.box("h"), .text("h"), .box("m"), .text("min")], "h", "m", P.th, P.tm, P.totalSlips, plain: P.totalPlain,
                             hint: P.totalPlain, explain: "\(P.th) h \(P.tm) min.", incomplete: "Write the hours and the minutes."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [to, hours, after, total, LessonStep(StepWords(say: "To the o'clock, the whole hours, then the minutes.", hint: "", action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: - The measuring stories (Grams and kilograms, Liters)

/// A measuring story (the web's _measure.ts): the story on the picture's top rows, "Pick what to do", then the amounts as
/// cells in rows of 10 (a cell is 10 g, 1 kg or 1 L): + slides the second amount in after the first; − slides it over from
/// the end; × drags down equal rows; ÷ deals the pile into rows. Then write the sum.
///
/// "op" 0 + 1 − 2 × 3 ÷; "a", "b", "who"; Grams and kilograms' "unit" 0 g, 1 kg. "at": 10 pick, 11 move, 12 write, 13 done.
/// Boxes: "o" the sign picked, "s" the slide (1000 landed, else the cells it covers), "e" the rows made, "k" the share's
/// columns, "v" the answer.
public enum MStory3 {
    public static let ops = ["+", "−", "×", "÷"]
    public static let opName = ["Add", "Subtract", "Multiply", "Divide"]
    public static let opSlip = [
        "Adding puts amounts together and makes more. Does this story put two amounts together?",
        "Subtracting takes some away and leaves less. Does anything go away in this story?",
        "Multiplying counts equal groups of the same amount. Are there equal groups here?",
        "Dividing shares an amount out equally. Is anything being shared out here?",
    ]
    public static let landed = 1000
    static func apply(_ o: Int, _ a: Int, _ b: Int) -> Int? {
        switch o {
        case 0: return a + b
        case 1: return a - b
        case 2: return a * b
        default: return b != 0 && a % b == 0 ? a / b : nil
        }
    }
    /// The story's numbers (web storyNumbers): + and − in steps of `round` up to `most`; × and ÷ inside the tables.
    static func numbers(_ o: Int, most: Int, round: Int, _ rng: inout SeededRandom) -> (Int, Int) {
        func r(_ lo: Int, _ hi: Int) -> Int { Ms3.r((lo + round - 1) / round, hi / round, &rng) * round }
        switch o {
        case 0: let a = r(round, most); return (a, r(round, most))
        case 1: let a = r(2 * round, most); return (a, r(round, a - round))
        case 2: let a = Ms3.r(2, 9, &rng); return (a, Ms3.r(2, 9, &rng))
        default: let b = Ms3.r(2, 9, &rng), q = Ms3.r(2, 9, &rng); return (b * q, b)
        }
    }

    public struct Parts: Sendable {
        public let op: Int, a: Int, b: Int, who: Int, u: String, cv: Int, story: String, groups: (String, String), shares: (String, String)
        public init(op: Int, a: Int, b: Int, who: Int, u: String, cv: Int, story: String, groups: (String, String), shares: (String, String)) {
            self.op = op; self.a = a; self.b = b; self.who = who; self.u = u; self.cv = cv; self.story = story; self.groups = groups; self.shares = shares
        }
        public var o: String { MStory3.ops[op] }
        public var ans: Int { MStory3.apply(op, a, b) ?? 0 }
        /// The amounts in cells.
        public var A: Int { a / cv }
        public var B: Int { b / cv }
        public var q: Int { b != 0 ? a / b : 0 }
        public var note: String { "1 cell is \(cv) \(u)." }
        public var moveSay: String {
            switch op {
            case 0: return "Slide \(Ms3.wc(b)) \(u) in."
            case 1: return "Slide \(Ms3.wc(b)) \(u) away."
            case 2: return "Drag down to make \(a) \(groups.1) of \(b) \(u)."
            default: return "Drag across to share it into \(b) \(shares.1)."
            }
        }
        public var why: String { ["Two amounts together: add.", "Some taken away: subtract.", "Equal groups: multiply.", "Shared out equally: divide."][op] }
        public func slid(_ cov: Int) -> String {
            op == 0 ? "That's \(Ms3.wc(cov * cv)) \(u) in. Slide all \(Ms3.wc(b)) \(u) in after the last one."
                : "That covers \(Ms3.wc(cov * cv)) \(u). Slide all \(Ms3.wc(b)) \(u) over the last ones."
        }
        public func shared(_ k: Int) -> Verdict {
            if k == q { return .right }
            if k > q { return .wrong("\(b) × \(k) = \(b * k). That's more than \(a) \(u).") }
            return .soft("\(b) × \(k) = \(b * k). \(a - b * k) \(u) left. Keep going.")
        }
        /// The solve step's slips: the other operations' answers and the starting amount (web solveStep).
        public var solveSlips: [(Int, String)] {
            func other(_ x: Int) -> Int? { MStory3.apply(x, a, b).flatMap { $0 > 0 ? $0 : nil } }
            var s: [(Int, String)] = []
            if op != 0, let v = other(0) { s.append((v, op == 1 ? "The story takes some away. Subtract." : op == 2 ? "Equal groups: multiply, don't add." : "Sharing equally means dividing.")) }
            if op != 1, let v = other(1) { s.append((v, op == 0 ? "The story puts amounts together. Add." : "Read the story again: it isn't taking away.")) }
            if op == 3, let v = other(2) { s.append((v, "The amount is shared out, so it gets smaller. Divide.")) }
            let start = op == 3 ? "\(Ms3.wc(a)) \(u) is the whole amount before it is shared. Share it into \(b) equal parts."
                : op == 2 ? "\(a) is how many groups there are. Each group is \(b) \(u), so multiply."
                : "\(Ms3.wc(a)) \(u) is where the story starts. \(MStory3.opName[op]) \(Ms3.wc(b)) to finish."
            s.append((a, start))
            return s.filter { $0.0 != ans }
        }
    }

    /// The story's steps: pick, move, write, done.
    static func steps(_ P: Parts) -> [LessonStep] {
        let pickHint = "Does it put together, take away, make equal groups or share out?"
        let want = P.op
        let pick = LessonStep(StepWords(say: "Pick what to do. \(P.note)", hint: pickHint, action: "Check"),
            answer: Ms3.hand("o", want, hint: pickHint, explain: "\(MStory3.opName[P.op]).", said: { i in MStory3.opSlip[max(0, min(3, i))] }),
            picture: ["at": 10], onMiss: ["ring": 1], hint2: ["spot": 1])
        let moveHint = "The readout counts as you go."
        let task: AnswerTask
        switch P.op {
        case 0, 1:
            task = Ms3.hand("s", MStory3.landed, hint: moveHint, explain: "\(Ms3.wc(P.ans)) \(P.u).", said: { P.slid($0) })
        case 2:
            let groups = P.groups.1, a = P.a
            task = Ms3.hand("e", P.a, hint: moveHint, explain: "\(P.a) \(groups).", said: { "That's \($0) \(groups). There are \(a)." })
        default:
            task = AnswerTask(prompt: [.box("k")], expected: ["k": Double(P.q)], hint: moveHint, explain: "\(P.q) \(P.u) in each.",
                              check: { v in P.shared(Int((v["k"] ?? 0).rounded())) }, byHand: true)
        }
        let move = LessonStep(StepWords(say: "\(P.moveSay) \(P.note)", hint: moveHint, action: "Check"), answer: task,
                              picture: ["at": 11], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wHint = "\(MStory3.opName[P.op]): \(Ms3.wc(P.a)) \(P.o) \(Ms3.wc(P.b))."
        let write = LessonStep(StepWords(say: "Write \(Ms3.wc(P.a)) \(P.o) \(Ms3.wc(P.b)).", hint: wHint, action: "Check"),
            answer: Ms3.typed("v", P.ans, P.solveSlips, hint: wHint, explain: "\(Ms3.wc(P.ans)) \(P.u)."),
            picture: ["at": 12], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [pick, move, write, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 13])]
    }
}

// MARK: - Grams and kilograms

/// Grams and kilograms (the web's g3-mass; 3.MD.A.2). Which unit: the thing, a kitchen scale marked g and a floor scale
/// marked kg; drag the thing onto the scale that fits, then tap about how heavy it is (three tags, light to heavy; the
/// needle swings to the one tapped). Read the scale: the dial laid straight, 20 marks 3 squares apart, labeled every 5
/// marks; hop from 0 to the first label and write what a mark is; hop from the label before the needle to it and write the
/// mass. A story: as MStory3, a cell 10 g or 1 kg.
///
/// "kind" 0 unit, 1 scale, 2 story. Unit: "thing"; "at" 0 drop, 1 guess, 2 done; boxes "s" (0 g, 1 kg), "g" the tag
/// (light to heavy). Scale: "unit", "step", "value"; "at" 0 first, 1 each, 2 past, 3 read, 4 done; boxes "f" "p" the hops,
/// "s" "v". Story: "unit", "op", "a", "b", "who".
public enum Mass3 {
    public struct Thing: Sendable { public let name: String, kg: Bool, v: Int }
    public static let things = [Thing(name: "paper clip", kg: false, v: 1), Thing(name: "grape", kg: false, v: 5), Thing(name: "coin", kg: false, v: 5),
                                Thing(name: "pencil", kg: false, v: 10), Thing(name: "key", kg: false, v: 20), Thing(name: "dog", kg: true, v: 30),
                                Thing(name: "bag of flour", kg: true, v: 2), Thing(name: "watermelon", kg: true, v: 5), Thing(name: "bike", kg: true, v: 15),
                                Thing(name: "backpack", kg: true, v: 5)]
    public static func unit(thing: Int) -> Numbers { ["kind": 0, "thing": Double(thing)] }
    public static func scale(kg: Bool = false, step: Int, value: Int) -> Numbers { ["kind": 1, "unit": kg ? 1 : 0, "step": Double(step), "value": Double(value)] }
    public static func story(op: Int, a: Int, b: Int, kg: Bool, who: Int = 0) -> Numbers {
        ["kind": 2, "op": Double(op), "a": Double(a), "b": Double(b), "unit": kg ? 1 : 0, "who": Double(who)]
    }
    static func grams(_ label: String) -> Int {
        let p = label.split(separator: " "), n = Int(p[0].replacingOccurrences(of: ",", with: "")) ?? 0
        return p.count > 1 && p[1] == "kg" ? n * 1000 : n
    }

    public struct Parts: Sendable {
        public let kind: Int, thing: Int, kg: Bool, step: Int, value: Int, op: Int, a: Int, b: Int, who: Int
        public init(_ x: Numbers) {
            kind = max(0, min(2, Ms3.int(x, "kind")))
            thing = max(0, min(Mass3.things.count - 1, Ms3.int(x, "thing")))
            kg = Ms3.int(x, "unit") == 1
            step = max(1, Ms3.int(x, "step", 10)); value = max(step, Ms3.int(x, "value", 130))
            op = max(0, min(3, Ms3.int(x, "op"))); a = Ms3.int(x, "a", 230); b = max(1, Ms3.int(x, "b", 150)); who = max(0, min(5, Ms3.int(x, "who")))
        }
        public var th: Thing { Mass3.things[thing] }
        public var u: String { kg ? "kg" : "g" }
        // which unit
        /// The three tags as the web orders them, and which is right, too light (a kg thing's grams), too heavy.
        public var labels: [String] {
            let v = th.v, vals = th.kg ? ["\(v) kg", "\(Ms3.wc(v * 10)) g", "\(Ms3.wc(v * 100)) kg"] : ["\(v) g", "\(Ms3.wc(v * 100)) g", "\(v) kg"]
            let k = thing % 3
            return (0..<3).map { vals[($0 + k) % 3] }
        }
        /// Index of the web's value i in `labels`.
        func at(_ i: Int) -> Int { let k = thing % 3; return (i - k + 3) % 3 }
        /// The tags light to heavy, as indices into `labels`.
        public var order: [Int] { let l = labels; return [0, 1, 2].sorted { Mass3.grams(l[$0]) < Mass3.grams(l[$1]) } }
        /// The tag (light to heavy) that's right.
        public var rightTag: Int { order.firstIndex(of: at(0)) ?? 0 }
        static func feels(_ label: String) -> String {
            let g = Mass3.grams(label)
            if g >= 1000 && label.hasSuffix(" kg") { return g == 1000 ? "a big bottle of water" : "\(Ms3.plural(g / 1000, "big bottle", "big bottles")) of water" }
            if g <= 2 { return "a paper clip" }
            if g <= 30 { return "a key" }
            if g <= 60 { return "a handful of coins" }
            if g <= 200 { return "an apple" }
            if g <= 600 { return "a few apples" }
            return "a big book"
        }
        /// What a wrong tag says (j light to heavy).
        public func guessed(_ j: Int) -> String {
            let i = order[max(0, min(2, j))], label = labels[i]
            if th.kg && i == at(1) { return "\(label) is about as light as \(Parts.feels(label)). A \(th.name) is much heavier than that." }
            if th.kg { return "\(label) is far too heavy for a \(th.name). A \(th.name) is much lighter than that." }
            return "\(label) is about as heavy as \(Parts.feels(label)). A \(th.name) is much lighter than that."
        }
        public var dropped: String {
            th.kg ? "A \(th.name) would be thousands of grams. Use kilograms." : "A kilogram is as heavy as a big bottle of water. A \(th.name) is much lighter: grams."
        }
        // read the scale
        public var marks: Int { value / step }
        public var lb: Int { marks / 5 * 5 }
        public var label: Int { lb * step }
        public var onLabel: Bool { marks % 5 == 0 }
        public var eachSlips: [(Int, String)] {
            (step != 1 ? [(1, "The marks jump by \(step) each, not 1. Look at the labels: 0 to \(Ms3.wc(5 * step)).")] : [])
                + [(5 * step, "\(Ms3.wc(5 * step)) is the label. There are 5 small spaces from 0 to \(Ms3.wc(5 * step)).")]
        }
        public var readSlips: [(Int, String)] {
            var s: [(Int, String)] = []
            if label != value { s.append((label, "The needle is past \(Ms3.wc(label)). Count on the small marks.")) }
            s.append((value - step, "The needle is one mark past that. Count the spaces from the label \(Ms3.wc(label)) right up to the needle."))
            s.append((value + step, "That mark is past the needle. Count the spaces from the label \(Ms3.wc(label)) and stop at the needle."))
            if step != 1 { s.append((label + marks % 5, "Each mark is \(step) \(u). Count on by \(step) from \(Ms3.wc(label)).")) }
            return s
        }
        public var readHint: String { label == value ? "Find the label the needle points straight at." : "Start at \(Ms3.wc(label)) and count on by \(step) to the needle." }
        public var why: String {
            switch kind {
            case 0: return th.kg ? "A \(th.name) is heavy: kilograms." : "A \(th.name) is light: grams."
            case 1: return onLabel ? "The needle points right at a label." : "\(Ms3.wc(label)), then \(Ms3.plural(marks % 5, "mark", "marks")) of \(Ms3.wc(step))."
            default: return story.why
            }
        }
        public var storyText: String {
            let w = Ms3.who[who], A = Ms3.wc(a), Bs = Ms3.wc(b)
            switch op {
            case 0: return "\(w) has a bag of rice of \(A) \(u) and a bag of beans of \(Bs) \(u). How heavy are the two bags together?"
            case 1: return "A box of books weighs \(A) \(u). \(w) takes out \(Bs) \(u) of books. How heavy is the box now?"
            case 2: return "\(w) stacks \(a) boxes. Each box weighs \(Bs) \(u). How heavy are all the boxes?"
            default: return "\(w) shares \(A) \(u) of sand equally into \(b) buckets. How much sand goes in each bucket?"
            }
        }
        public var story: MStory3.Parts {
            MStory3.Parts(op: op, a: a, b: b, who: who, u: u, cv: kg ? 1 : 10, story: storyText, groups: ("box", "boxes"), shares: ("bucket", "buckets"))
        }
    }

    /// The web's kinds by index (problems 1–3: unit, scale, unit; then index % 3); marks of 1, 10, 50 or 100 g and 1, 2 or 5
    /// kg (early: 1 or 10, the needle on a label; then between labels); stories (+ in either unit; −, × and ÷ in kg).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, kind = early ? i % 2 : i % 3
        if kind == 0 { return unit(thing: (i * 3 + Ms3.r(0, 2, &rng)) % things.count) }
        let kg = Ms3.r(0, 1, &rng) == 1
        if kind == 1 {
            let steps = (kg ? [1, 2, 5] : [1, 10, 50, 100]).filter { !early || $0 == 1 || $0 == 10 }, step = Ms3.pick(steps, &rng)
            var non5: [Int] = []
            for m in 1...19 where m % 5 != 0 { non5.append(m) }
            let marks = early ? 5 * Ms3.r(1, 4, &rng) : Ms3.pick(non5, &rng)
            return scale(kg: kg, step: step, value: marks * step)
        }
        let op = Ms3.r(0, 3, &rng), u = op == 0 ? kg : true
        let (a, b) = MStory3.numbers(op, most: u ? 50 : 500, round: u ? 1 : 10, &rng)
        return story(op: op, a: a, b: b, kg: u, who: Ms3.r(0, 5, &rng))
    }

    public static let spec = LessonSpec(id: "g3-mass", title: "Grams and kilograms", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How heavy?")] },
        idea: { _ in "Light things are weighed in grams, heavy things in kilograms: 1 kg is 1,000 g." },
        depends: ["g2-measure"],
        check: [CheckItem(3), CheckItem(4), CheckItem(5), CheckItem(7, when: { !Parts($0).onLabel })]) { x in
        let P = Parts(x)
        switch P.kind {
        case 0:
            let dHint = "A kilogram is as heavy as a big bottle of water."
            let drop = LessonStep(StepWords(say: "Drag the \(P.th.name) onto the scale that fits.", hint: dHint, action: "Check"),
                answer: Ms3.hand("s", P.th.kg ? 1 : 0, hint: dHint, explain: P.th.kg ? "Kilograms." : "Grams.", said: { _ in P.dropped }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let gHint = "Think of a big bottle of water: 1 kg."
            let guess = LessonStep(StepWords(say: "Tap about how heavy it is.", hint: gHint, action: "Check"),
                answer: Ms3.hand("g", P.rightTag, hint: gHint, explain: P.labels[P.at(0)], said: { P.guessed($0) }),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [drop, guess, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])]
        case 1:
            let L2 = Ms3.wc(5 * P.step)
            let fHint = "The first label is 5 marks from 0."
            let first = LessonStep(StepWords(say: "Hop from 0 to the first label.", hint: fHint, action: "Check"),
                answer: Ms3.hand("f", 5, hint: fHint, explain: "5 marks to \(L2).", said: { $0 > 5 ? "That's past the first label." : "Hop all the way to \(L2)." }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let eHint = "Find two labeled numbers. How many small spaces are between them?"
            let each = LessonStep(StepWords(say: "Write what each mark is.", hint: eHint, action: "Check"),
                answer: Ms3.typed("s", P.step, P.eachSlips, hint: eHint, explain: "5 marks make \(L2), so each is \(P.step) \(P.u)."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let read = LessonStep(StepWords(say: "Write the mass.", hint: P.readHint, action: "Check"),
                answer: Ms3.typed("v", P.value, P.readSlips, hint: P.readHint, explain: "\(Ms3.wc(P.value)) \(P.u)."),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
            let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
            if P.onLabel { return [first, each, read, done] }
            let pHint = "Count the marks from \(Ms3.wc(P.label)) to the needle."
            let past = LessonStep(StepWords(say: "Hop from \(Ms3.wc(P.label)) to the needle.", hint: pHint, action: "Check"),
                answer: Ms3.hand("p", P.marks % 5, hint: pHint, explain: "\(Ms3.plural(P.marks % 5, "mark", "marks")) past \(Ms3.wc(P.label)).",
                                 said: { $0 > P.marks % 5 ? "That's past the needle." : "Hop all the way to the needle." }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [first, each, past, read, done]
        default:
            return MStory3.steps(P.story)
        }
    }
}

// MARK: - Liters

/// Liters (the web's g3-liters; 3.MD.A.2). Read the jug: a tall clear box 20 squares wide, 40 tall (a liter 2, 4 or 8
/// squares), its marks on the left labeled as the web labels them, the water tinted to its level; hop up from 0 to the
/// first label, write what a mark is; hop up to the top of the water, write it. A story: as MStory3, a cell a liter. About
/// how much (problems 7, 13, …): a thing beside a one-liter bottle; tap one of three tags, ten times apart.
///
/// "kind" 0 jug, 1 story, 2 about how much. Jug: "cap", "step", "value"; "at" 0 first, 1 each, 2 up, 3 read, 4 done; boxes
/// "f" "u" the hops, "s" "v". Story: "op", "a", "b", "who". About: "t", "p" (which tag is right); "at" 0 guess, 1 done; box "g".
public enum Liters3 {
    public struct Thing: Sendable { public let name: String, v: Int }
    public static let things = [Thing(name: "watering can", v: 5), Thing(name: "bucket", v: 10), Thing(name: "sink", v: 20), Thing(name: "fish tank", v: 50),
                                Thing(name: "bathtub", v: 200)]
    static let feels: [Int: String] = [1: "1 L is one big bottle of water.", 2: "2 L is two big bottles of water.", 5: "5 L is about a watering can.",
                                       10: "10 L is about a bucket.", 20: "20 L is about a sink full.", 50: "50 L is about a fish tank.",
                                       100: "100 L is about half a bathtub.", 200: "200 L is about a bathtub.", 500: "500 L is more than two bathtubs.",
                                       1000: "1,000 L is five bathtubs.", 2000: "2,000 L is ten bathtubs."]
    public static func jug(cap: Int, step: Int, value: Int) -> Numbers { ["kind": 0, "cap": Double(cap), "step": Double(step), "value": Double(value)] }
    public static func story(op: Int, a: Int, b: Int, who: Int = 0) -> Numbers { ["kind": 1, "op": Double(op), "a": Double(a), "b": Double(b), "who": Double(who)] }
    public static func about(t: Int, p: Int) -> Numbers { ["kind": 2, "t": Double(t), "p": Double(p)] }

    public struct Parts: Sendable {
        public let kind: Int, cap: Int, step: Int, value: Int, op: Int, a: Int, b: Int, who: Int, t: Int, p: Int
        public init(_ x: Numbers) {
            kind = max(0, min(2, Ms3.int(x, "kind")))
            cap = [5, 10, 20].contains(Ms3.int(x, "cap")) ? Ms3.int(x, "cap") : 10
            step = max(1, Ms3.int(x, "step", 2)); value = max(step, min(cap, Ms3.int(x, "value", 8)))
            op = max(0, min(3, Ms3.int(x, "op"))); a = Ms3.int(x, "a", 20); b = max(1, Ms3.int(x, "b", 5)); who = max(0, min(5, Ms3.int(x, "who")))
            t = max(0, min(Liters3.things.count - 1, Ms3.int(x, "t", 1))); p = max(0, min(2, Ms3.int(x, "p", 1)))
        }
        // the jug
        public var n: Int { cap / step }
        /// The labels: every mark up to 10 marks, every other up to 20, else every fifth.
        public var every: Int { n <= 10 ? 1 : n <= 20 ? 2 : 5 }
        public var marks: Int { value / step }
        /// A liter's squares: the jug 40 tall.
        public var per: Int { cap == 20 ? 2 : cap == 10 ? 4 : 8 }
        public var note: String { "1 liter is \(Ms3.plural(per, "square", "squares")) tall here." }
        public var eachSlips: [(Int, String)] {
            var s: [(Int, String)] = []
            if step != 1 { s.append((1, "The marks jump by \(step) each, not 1. Look at the labels.")) }
            s.append((cap, "\(cap) is a label. Count the spaces from 0 to \(cap): each one is \(step) L."))
            if step != 1 { s.append((n, "There are \(n) marks up to \(cap), but the labels jump by \(step). Each mark is worth \(step) L.")) }
            return s
        }
        public var readSlips: [(Int, String)] {
            let below = value / (every * step) * every * step
            var s: [(Int, String)] = [(cap, "That's the top of the jug. Read where the water is.")]
            if below != value { s.append((below, "The water is past \(below). Count on the small marks.")) }
            s.append((value - step, "The water is one mark higher. Count up from the last label to the very top of the water."))
            s.append((value + step, "That mark is above the water. Stop at the top of the water."))
            if step != 1 { s.append((marks, "Each mark is \(step) L. Count by \(step)s.")) }
            return s
        }
        // the story
        public var story: MStory3.Parts {
            let w = Ms3.who[who]
            func lit(_ n: Int) -> String { "\(n) \(n == 1 ? "liter" : "liters")" }
            let text: String
            switch op {
            case 0: text = "\(w) pours \(lit(a)) of water into a tub, then \(b) more \(b == 1 ? "liter" : "liters"). How many liters are in the tub?"
            case 1: text = "A fish tank holds \(lit(a)). \(w) drains \(lit(b)) to clean it. How many liters are left?"
            case 2: text = "\(w) fills \(a) bottles with \(lit(b)) of juice each. How many liters is that in all?"
            default: text = "\(w) pours \(lit(a)) of lemonade equally into \(b) jugs. How many liters go in each jug?"
            }
            return MStory3.Parts(op: op, a: a, b: b, who: who, u: "L", cv: 1, story: text, groups: ("bottle", "bottles"), shares: ("jug", "jugs"))
        }
        // about how much
        public var th: Thing { Liters3.things[t] }
        public var vals: [Int] {
            var out: [Int] = []
            for j in 0..<3 { var v = th.v; if j > p { for _ in 0..<(j - p) { v *= 10 } } else { for _ in 0..<(p - j) { v /= 10 } }; out.append(v) }
            return out
        }
        public func guessed(_ j: Int) -> String {
            let v = vals[max(0, min(2, j))]
            return "\(Liters3.feels[v] ?? "\(Ms3.wc(v)) L.") A \(th.name) holds \(v < th.v ? "more" : "less")."
        }
    }

    /// The web's (problem 1 a 5 or 10 L jug marked every liter; problems 2–3 a 10 L jug marked every 2; then a jug when the
    /// index is even, a story when it's odd), with about how much at index % 6 = 0 from 6.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 || i % 2 == 0 {
            if i >= 6 && i % 6 == 0 {
                let t = Ms3.r(0, things.count - 1, &rng), v = things[t].v
                var ps: [Int] = []
                for p in 0...2 {
                    var d = 1, up = 1
                    for _ in 0..<p { d *= 10 }
                    for _ in 0..<(2 - p) { up *= 10 }
                    if v % d == 0 && v * up <= 2000 { ps.append(p) }
                }
                return about(t: t, p: Ms3.pick(ps, &rng))
            }
            let cap = i == 0 ? Ms3.pick([5, 10], &rng) : i < 3 ? 10 : Ms3.pick([5, 10, 20], &rng)
            let step = i == 0 ? 1 : i < 3 ? 2 : cap == 20 ? Ms3.pick([1, 2, 5], &rng) : cap == 10 ? Ms3.pick([1, 2], &rng) : 1
            return jug(cap: cap, step: step, value: step * Ms3.r(1, cap / step - 1, &rng))
        }
        let op = Ms3.r(0, 3, &rng), (a, b) = MStory3.numbers(op, most: 50, round: 1, &rng)
        return story(op: op, a: a, b: b, who: Ms3.r(0, 5, &rng))
    }

    public static let spec = LessonSpec(id: "g3-liters", title: "Liters", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How much water?")] },
        idea: { _ in "A liter is about one big bottle of water. Read a jug by what each mark is worth." },
        depends: ["g3-mass"],
        check: [CheckItem(2), CheckItem(3), CheckItem(4), CheckItem(6)]) { x in
        let P = Parts(x)
        switch P.kind {
        case 1: return MStory3.steps(P.story)
        case 2:
            let hint = "A liter is one big bottle of water."
            let guess = LessonStep(StepWords(say: "Tap about how much the \(P.th.name) holds.", hint: hint, action: "Check"),
                answer: Ms3.hand("g", P.p, hint: hint, explain: "\(Ms3.wc(P.th.v)) L.", said: { P.guessed($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [guess, LessonStep(StepWords(say: "About \(Ms3.plural(P.th.v, "big bottle", "big bottles")) of water.", hint: "", action: "Next problem"), picture: ["at": 1])]
        default:
            let first = P.every * P.step
            let fHint = "The first label is \(Ms3.plural(P.every, "mark", "marks")) up."
            let f = LessonStep(StepWords(say: "Hop up from 0 to the first label. \(P.note)", hint: fHint, action: "Check"),
                answer: Ms3.hand("f", P.every, hint: fHint, explain: "\(Ms3.plural(P.every, "mark", "marks")) to \(first).",
                                 said: { $0 > P.every ? "That's past the first label." : "Hop all the way to \(first)." }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let eHint = "Find two labeled marks. How many spaces are between them?"
            let each = LessonStep(StepWords(say: "Write what each mark is.", hint: eHint, action: "Check"),
                answer: Ms3.typed("s", P.step, P.eachSlips, hint: eHint, explain: "Each mark is \(P.step) L."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            let uHint = "Hop a mark at a time up to the top of the water."
            let up = LessonStep(StepWords(say: "Hop up to the top of the water.", hint: uHint, action: "Check"),
                answer: Ms3.hand("u", P.marks, hint: uHint, explain: Ms3.plural(P.marks, "mark", "marks"),
                                 said: { $0 > P.marks ? "That's past the top of the water." : "Hop all the way to the top of the water." }),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            let rHint = "Find the top of the water. Count up the marks by \(P.step)."
            let read = LessonStep(StepWords(say: "Write how much water.", hint: rHint, action: "Check"),
                answer: Ms3.typed("v", P.value, P.readSlips, hint: rHint, explain: "\(P.value) L."),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [f, each, up, read, LessonStep(StepWords(say: "\(Ms3.plural(P.marks, "mark", "marks")) of \(P.step) L.", hint: "", action: "Next problem"), picture: ["at": 4])]
        }
    }
}
