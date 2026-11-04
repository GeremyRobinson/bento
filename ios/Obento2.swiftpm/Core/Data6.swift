import Foundation

/// What 6th grade's Data chapter shares (design/grade6.md chapter 8, the preview design/prototype/grade6-ch8.html): data
/// is drawn on a line or as bars, one square for one of what was counted, so every middle and every spread can be counted
/// on the paper. Every data problem starts from its question and its unit (6.SP.5b). A problem's answers are kept as
/// "N" (how many) and "v0", "v1"… in the order they're given.
public enum Data6 {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = -9999) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }
    /// The answers, in the order they're given.
    public static func values(_ x: Numbers) -> [Int] { (0..<max(0, int(x, "N", 0))).map { int(x, "v\($0)", 0) } }
    static func put(_ v: [Int], _ x: inout Numbers) { x["N"] = Double(v.count); for (j, u) in v.enumerated() { x["v\(j)"] = Double(u) } }
    /// The middle of a sorted list: one number, or halfway between the middle two.
    public static func mid(_ s: [Int]) -> Double {
        guard !s.isEmpty else { return 0 }
        return s.count % 2 == 1 ? Double(s[s.count / 2]) : Double(s[s.count / 2 - 1] + s[s.count / 2]) / 2
    }
    /// "4 minutes", "1 pet".
    static func plural(_ v: Int, _ u: (String, String)) -> String { "\(v) \(v == 1 ? u.0 : u.1)" }
    /// A number as the paper writes it, to one place: 14.2.
    public static func dec1(_ x: Double) -> String { fmt((x * 10).rounded() / 10) }
}

// MARK: - Dot plots

/// Dot plots (g6-dotplot, 6.SP.1, 6.SP.2, 6.SP.4, 6.SP.5a, 6.SP.5b): the answers to a question with many answers, one dot
/// (a 2 × 2 cell) for each, stacked over a line 0–10 four squares a one; the answers wait as cards under it. Pick the
/// question with many answers (problems 1–3), put each card on the line, write how many, tap the tallest stack, drag a
/// bracket from the least answer to the greatest.
///
/// "at": 0 the question, 1 pick, 2 stack, 3 how many, 4 the tallest, 5 the spread, 6 done.
public enum DotPlot6 {
    public struct Question: Sendable {
        public let one, many: String
        public let unit: (String, String)
        /// "Most read 4 minutes".
        public let most: @Sendable (String) -> String
    }
    public static let questions: [Question] = [
        Question(one: "How old is Mia?", many: "How old are the kids at the park?", unit: ("year", "years"), most: { "Most are \($0) old" }),
        Question(one: "How many minutes did Mia read today?", many: "How many minutes do the kids in Mia’s class read a day?", unit: ("minute", "minutes"), most: { "Most read \($0)" }),
        Question(one: "How many pets does Sam have?", many: "How many pets do the kids in Sam’s class have?", unit: ("pet", "pets"), most: { "Most have \($0)" }),
        Question(one: "How many goals did the team score last game?", many: "How many goals did the team score in each game?", unit: ("goal", "goals"), most: { "Most games had \($0)" }),
        Question(one: "How many books did Leo read this month?", many: "How many books did the kids in Leo’s class read this month?", unit: ("book", "books"), most: { "Most read \($0)" }),
    ]
    /// The set's one feature: a cluster, a gap, or one far-off answer.
    public enum Feature: Int, Sendable { case cluster, gap, far }

    /// `po`: the pick's order (0: the one-answer question first).
    public static func numbers(q: Int, data: [Int], feat: Feature = .cluster, pick: Bool = false, po: Int = 1) -> Numbers {
        var x: Numbers = ["q": Double(q), "feat": Double(feat.rawValue), "pick": pick ? 1 : 0, "po": Double(po)]
        Data6.put(data, &x)
        return x
    }

    public struct Parts: Sendable {
        public let data: [Int], q: Int, feat: Feature, pick: Bool, po: Int
        public init(_ x: Numbers) {
            data = Data6.values(x); q = min(questions.count - 1, max(0, Data6.int(x, "q", 0)))
            feat = Feature(rawValue: Data6.int(x, "feat", 0)) ?? .cluster; pick = Data6.int(x, "pick", 0) == 1; po = Data6.int(x, "po", 1)
        }
        public var Q: Question { questions[q] }
        public var n: Int { data.count }
        /// How many answered each number 0–10.
        public var counts: [Int] { (0...10).map { u in data.filter { $0 == u }.count } }
        public var tallest: Int { counts.max() ?? 0 }
        public var peak: Int { counts.firstIndex(of: tallest) ?? 0 }
        public var least: Int { data.min() ?? 0 }
        public var most: Int { data.max() ?? 0 }
        /// The pick's two questions in their order, and which is the one with many answers.
        public var choices: [String] { po == 0 ? [Q.one, Q.many] : [Q.many, Q.one] }
        public var manyAt: Int { po == 0 ? 1 : 0 }

        public let pickSay = "Pick the question with many answers."
        public let stackSay = "Put each answer on the line. Tap its number on the line, or drag the card there."
        public let countSay = "Write how many answers."
        public let peakSay = "Tap where most answers are."
        public let spreadSay = "From least to most: drag a bracket from the least answer to the greatest."
        public var why: String { "\(Q.most(Data6.plural(peak, Q.unit))), and the answers spread from \(least) to \(most)." }

        public func placed(_ card: Int, _ u: Int) -> String? { data.indices.contains(card) && data[card] != u ? "That card says \(data[card])." : nil }
        public func counted(_ x: Int) -> String? {
            if x == n { return nil }
            return x == n - 1 ? "One is missed: count every dot." : "Count the dots: one dot is one answer."
        }
        public func tapped(_ u: Int) -> String? {
            let k = (0...10).contains(u) ? counts[u] : 0
            if k == tallest { return nil }
            return k > 0 ? "That stack has \(k). Find the tallest." : "No dots there. Find the tallest stack."
        }
        /// The bracket let go from `a` to `b` (nil: right).
        public func spread(_ a: Int, _ b: Int) -> String? {
            let lo = min(a, b), hi = max(a, b)
            if lo == least && hi == most { return nil }
            if lo > least || hi < most {
                let m = lo > least ? least : most
                return counts[m] > 1 ? "The dots at \(m) are left out." : "The dot at \(m) is left out."
            }
            return "No one answered \(lo < least ? lo : hi)."
        }
    }

    static func ok(_ v: [Int], _ f: Feature, hi: Int) -> Bool {
        guard v.allSatisfy({ (0...hi).contains($0) }) else { return false }
        let p = Parts(numbers(q: 0, data: v)), c = p.counts
        guard c.filter({ $0 == p.tallest }).count == 1, p.tallest <= 6, p.tallest >= 3 else { return false }
        let gaps = (p.least + 1..<max(p.least + 1, p.most)).filter { c[$0] == 0 }
        let lone = v.filter { x in v.filter { abs($0 - x) < 3 }.count == 1 }
        switch f {
        case .cluster: return gaps.isEmpty && p.most - p.least <= 4
        case .far: return lone.count == 1
        case .gap: return gaps.count >= 1 && lone.isEmpty
        }
    }

    /// The preview's generator: problems 1–3 eight answers 0–6 with the question pick (a cluster, a gap, a far-off
    /// answer); then 10–15 answers 0–10, any feature. One tallest stack, 3 to 6 high.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let early = i < 3, n = early ? 8 : r(10, 15), hi = early ? 6 : 10
        let feat: Feature = early ? [.cluster, .gap, .far][i] : Data6.pick([.cluster, .gap, .far], &rng)
        let q = r(0, questions.count - 1), po = r(0, 1)
        for _ in 0..<2000 {
            let p = r(1, hi - 1)
            var v: [Int]
            switch feat {
            case .cluster: v = (0..<n).map { _ in p + Data6.pick([-2, -1, -1, 0, 0, 0, 1, 1, 2], &rng) }
            case .gap:
                let q2 = p + Data6.pick([3, 4], &rng) * Data6.pick([1, -1], &rng), nb = max(2, Int((Double(n) / 3).rounded()))
                v = (0..<(n - nb)).map { _ in p + Data6.pick([-1, 0, 0, 1], &rng) } + (0..<nb).map { _ in q2 + Data6.pick([-1, 0, 1], &rng) }
            case .far:
                v = (0..<(n - 1)).map { _ in p + Data6.pick([-1, -1, 0, 0, 0, 1, 1], &rng) }
                v.append(p + Data6.pick([1, -1], &rng) * r(4, 6))
            }
            if ok(v, feat, hi: hi) { return numbers(q: q, data: v.shuffled(using: &rng), feat: feat, pick: early, po: po) }
        }
        return numbers(q: q, data: [3, 4, 4, 2, 4, 3, 5, 4], feat: .cluster, pick: early, po: po)
    }

    public static let spec = LessonSpec(id: "g6-dotplot", title: "Dot plots", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).Q.many)] },
        idea: { _ in "A dot plot puts one dot over each answer, so you can see where most are and how far they spread." },
        depends: ["g4-lineplot"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).feat == .cluster }), CheckItem(4, when: { Parts($0).feat == .gap }),
                CheckItem(5, when: { Parts($0).feat == .far })]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x)
        var out: [LessonStep] = []
        if s.pick {
            let hint = "A question with many answers asks lots of people, or about lots of times."
            out.append(LessonStep(StepWords(say: s.pickSay, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [], expected: ["c": Double(s.manyAt)], hint: hint, explain: s.Q.many,
                                   check: { v in Data6.int(v, "c") == s.manyAt ? .right : .wrong("Everyone gives the same answer to that one.") },
                                   choices: s.choices),
                picture: ["at": 1]))
        }
        let stackHint = "Find the card’s number under the line."
        out.append(LessonStep(StepWords(say: s.stackSay, hint: stackHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c"), .box("u")], expected: ["c": -1, "u": 0], hint: stackHint, explain: "Every answer has its dot.",
                               check: { v in
                                   let c = Data6.int(v, "c"), u = Data6.int(v, "u")
                                   if c < 0 { return .right }
                                   return s.placed(c, u).map { .wrong($0) } ?? .soft("Now the next card.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let countHint = "One dot is one answer: count them all."
        out.append(LessonStep(StepWords(say: s.countSay, hint: countHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("n"), .text("answers")], expected: ["n": Double(s.n)], hint: countHint, explain: "\(s.n) answers.",
                               check: { v in
                                   guard let n = v["n"] else { return .soft("Write the number.") }
                                   return s.counted(Int(n.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let peakHint = "The tallest stack has the most dots."
        out.append(LessonStep(StepWords(say: s.peakSay, hint: peakHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.peak)], hint: peakHint, explain: "Most at \(s.peak).",
                               check: { v in s.tapped(Data6.int(v, "x")).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let spreadHint = "Start at the dot farthest left, end at the dot farthest right."
        out.append(LessonStep(StepWords(say: s.spreadSay, hint: spreadHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("a"), .box("b")], expected: ["a": Double(s.least), "b": Double(s.most)], hint: spreadHint,
                               explain: "From \(s.least) to \(s.most).",
                               check: { v in s.spread(Data6.int(v, "a"), Data6.int(v, "b")).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
        return [LessonStep(StepWords(say: out[0].words.say, hint: out[0].words.hint, action: "Let’s find out"), picture: ["at": 0])] + out
            + [LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 6])]
    }
}

// MARK: - Histograms

/// Histograms (g6-histogram, 6.SP.4): 10–15 answers 0–49 counted into five equal stretches of 10, one square across for
/// one unit (a stretch is 10 squares) and two squares up for a count. Put each card in its stretch (its bar rises a
/// count), tap the stretches the question asks for, write how many.
///
/// "at": 0 the question, 1 stack, 2 tap the stretches, 3 write, 4 done.
public enum Histogram6 {
    public struct Question: Sendable {
        public let q, unit, who: String
        public let ask: @Sendable (String) -> String
    }
    public static let questions: [Question] = [
        Question(q: "How many minutes do you read a day?", unit: "minutes", who: "kids", ask: { "How many read \($0)?" }),
        Question(q: "How many minutes is your walk to school?", unit: "minutes", who: "kids", ask: { "How many walk \($0)?" }),
        Question(q: "How many points did the team score in each game?", unit: "points", who: "games", ask: { "In how many games did they score \($0)?" }),
    ]
    public enum Ask: Int, Sendable { case one, more, fewer, tallest }
    public enum Shape: Int, Sendable { case hump, right, left }
    public static func stretch(_ s: Int) -> String { "\(10 * s)–\(10 * s + 9)" }

    public static func numbers(q: Int, data: [Int], ask: Ask, t: Int = 0, s1: Int = 0, shape: Shape = .hump) -> Numbers {
        var x: Numbers = ["q": Double(q), "ask": Double(ask.rawValue), "t": Double(t), "s1": Double(s1), "shape": Double(shape.rawValue)]
        Data6.put(data, &x)
        return x
    }

    public struct Parts: Sendable {
        public let data: [Int], q: Int, ask: Ask, t: Int, s1: Int
        public init(_ x: Numbers) {
            data = Data6.values(x); q = min(questions.count - 1, max(0, Data6.int(x, "q", 0)))
            ask = Ask(rawValue: Data6.int(x, "ask", 0)) ?? .one; t = Data6.int(x, "t", 20); s1 = min(4, max(0, Data6.int(x, "s1", 0)))
        }
        public var Q: Question { questions[q] }
        public var n: Int { data.count }
        public func of(_ v: Int) -> Int { min(4, max(0, v / 10)) }
        public var counts: [Int] { (0..<5).map { s in data.filter { of($0) == s }.count } }
        public var tallest: Int { counts.max() ?? 0 }
        /// The stretches the question asks for, and how many land in them.
        public var want: [Int] {
            switch ask {
            case .one: return [s1]
            case .more: return (0..<5).filter { 10 * $0 >= t }
            case .fewer: return (0..<5).filter { 10 * $0 < t }
            case .tallest: return [counts.firstIndex(of: tallest) ?? 0]
            }
        }
        public var answer: Int { want.reduce(0) { $0 + counts[$1] } }
        /// The question about the stretches ("How many read 30 minutes or more?").
        public var asked: String {
            switch ask {
            case .one: return Q.ask("\(10 * s1) to \(10 * s1 + 9) \(Q.unit)")
            case .more: return Q.ask("\(t) \(Q.unit) or more")
            case .fewer: return Q.ask("fewer than \(t) \(Q.unit)")
            case .tallest: return "How many \(Q.who) are in the tallest stretch?"
            }
        }
        public let stackSay = "Put each answer in its stretch. Tap the stretch, or drag the card in."
        public var askSay: String { "\(asked) Tap the stretches it asks for." }
        public var writeSay: String { "\(asked) Write how many." }
        public let why = "A histogram counts how many land in each equal stretch."

        public func placed(_ card: Int, _ s: Int) -> String? {
            guard data.indices.contains(card) else { return nil }
            return of(data[card]) == s ? nil : "\(data[card]) goes in \(Histogram6.stretch(of(data[card])))."
        }
        /// The stretches lit (bits) when Check is tapped (nil: right).
        public func lit(_ mask: Int) -> String? {
            let on = (0..<5).filter { mask & (1 << $0) != 0 }, w = want
            if let e = on.first(where: { !w.contains($0) }) {
                switch ask {
                case .one: return "The question asks for \(Histogram6.stretch(s1))."
                case .more: return "\(Histogram6.stretch(e)) is less than \(t)."
                case .fewer: return "\(Histogram6.stretch(e)) is not fewer than \(t)."
                case .tallest: return "\(Histogram6.stretch(e)) has \(counts[e]). Find the tallest."
                }
            }
            if let m = w.first(where: { !on.contains($0) }) {
                switch ask {
                case .more: return "\(Histogram6.stretch(m)) is \(t) or more too."
                case .fewer: return "\(Histogram6.stretch(m)) is fewer than \(t) too."
                default: return "Tap the stretch it asks for."
                }
            }
            return nil
        }
        public func written(_ x: Int) -> String? {
            if x == answer { return nil }
            if want.count > 1 && x == want.count { return "Count the heights, not the bars." }
            if want.count > 1 { return "Add the heights: \(want.map { "\(counts[$0])" }.joined(separator: " + "))." }
            return "Read the bar’s height up the side."
        }
    }

    static func shaped(_ c: [Int], _ shape: Shape) -> Bool {
        guard let top = c.max(), let m = c.firstIndex(of: top), c.filter({ $0 == top }).count == 1 else { return false }
        switch shape {
        case .hump: return m >= 1 && m <= 3 && c.indices.allSatisfy { k in k < m ? c[k] <= c[k + 1] : k > m ? c[k] <= c[k - 1] : true }
        case .right: return m >= 3 && c.indices.allSatisfy { k in k < m ? c[k] <= c[k + 1] : true }
        case .left: return m <= 1 && c.indices.allSatisfy { k in k > m ? c[k] <= c[k - 1] : true }
        }
    }

    /// The preview's generator: one stretch, "or more", "fewer than" and the tallest in turn for problems 1–4, then any;
    /// 10–15 answers in one hump or leaning one way, at most 6 in a stretch; a stretch asked about always has answers.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let shape = Data6.pick([Shape.hump, .right, .left], &rng)
        let ask: Ask = i < 4 ? [.one, .more, .fewer, .tallest][i] : Data6.pick([.one, .more, .fewer, .tallest], &rng)
        let W = [Shape.hump: [1, 3, 5, 3, 1], .right: [1, 2, 3, 5, 6], .left: [6, 5, 3, 2, 1]][shape]!, tot = W.reduce(0, +)
        let q = r(0, questions.count - 1)
        for _ in 0..<2000 {
            let n = r(10, 15)
            var c = [0, 0, 0, 0, 0]
            for _ in 0..<n { var k = r(1, tot), s = 0; while k > W[s] { k -= W[s]; s += 1 }; c[s] += 1 }
            guard (c.max() ?? 0) <= 6, shaped(c, shape) else { continue }
            let t = ask == .more || ask == .fewer ? Data6.pick([20, 30], &rng) : 0
            let want = ask == .more ? (0..<5).filter { 10 * $0 >= t } : ask == .fewer ? (0..<5).filter { 10 * $0 < t } : []
            if want.contains(where: { c[$0] == 0 }) { continue }
            let ones = (0..<5).filter { c[$0] >= 2 }
            guard !ones.isEmpty else { continue }
            let s1 = ask == .one ? Data6.pick(ones, &rng) : 0
            let v = c.enumerated().flatMap { s, k in (0..<k).map { _ in r(10 * s, 10 * s + 9) } }.shuffled(using: &rng)
            return numbers(q: q, data: v, ask: ask, t: t, s1: s1, shape: shape)
        }
        return numbers(q: q, data: [12, 25, 21, 33, 8, 27, 19, 24, 31, 15], ask: ask, t: 30, s1: 2)
    }

    public static let spec = LessonSpec(id: "g6-histogram", title: "Histograms", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).Q.q)] },
        idea: { _ in "A histogram counts how many land in each equal stretch." },
        depends: ["g6-dotplot"],
        check: [CheckItem(0), CheckItem(1), CheckItem(2), CheckItem(3)]) { x in
        let s = Parts(x)
        let stackHint = "Find the stretch its number is in, under the bars."
        let stack = LessonStep(StepWords(say: s.stackSay, hint: stackHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c"), .box("u")], expected: ["c": -1, "u": 0], hint: stackHint, explain: "Every answer counted in its stretch.",
                               check: { v in
                                   let c = Data6.int(v, "c"), u = Data6.int(v, "u")
                                   if c < 0 { return .right }
                                   return s.placed(c, u).map { .wrong($0) } ?? .soft("Now the next card.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let mask = s.want.reduce(0) { $0 | (1 << $1) }
        let askHint = "Read the stretches’ names under the bars."
        let lit = LessonStep(StepWords(say: s.askSay, hint: askHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(mask)], hint: askHint, explain: s.want.map(Histogram6.stretch).joined(separator: " and "),
                               check: { v in s.lit(Data6.int(v, "x", 0)).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = s.want.count > 1 ? "Add the lit bars’ heights." : "Read the lit bar’s height up the side."
        let total: MathLine = s.want.count > 1 ? s.want.enumerated().flatMap { k, w -> MathLine in (k > 0 ? [.op("+")] : []) + [.num(Double(s.counts[w]))] } + [.op("=")] : []
        let write = LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: total + [.box("a"), .text(s.Q.who)], expected: ["a": Double(s.answer)], hint: writeHint, explain: "\(s.answer) \(s.Q.who).",
                               check: { v in
                                   guard let a = v["a"] else { return .soft("Write the number.") }
                                   return s.written(Int(a.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [LessonStep(StepWords(say: s.stackSay, hint: stackHint, action: "Let’s find out"), picture: ["at": 0]), stack, lit, write,
                LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: - Find the mean

/// Find the mean (the web app's g6-mean, 6.SP.3, 6.SP.5c): the numbers as bars, one square a one. Level the bars by hand
/// (squares slide from a tall bar onto a short one); once every bar is level the mean shows; then write
/// (3 + 5 + 7 + 9) ÷ 4 = [24] ÷ [4] = 6.
///
/// "at": 0 the question, 1 level, 2 the total, 3 the count, 4 done.
public enum Mean6 {
    public static func numbers(_ v: [Int]) -> Numbers { var x: Numbers = [:]; Data6.put(v, &x); return x }

    public struct Parts: Sendable {
        public let v: [Int]
        public init(_ x: Numbers) { v = Data6.values(x) }
        public var n: Int { v.count }
        public var total: Int { v.reduce(0, +) }
        public var mean: Int { n == 0 ? 0 : total / n }
        public var tallest: Int { v.max() ?? 0 }
        public let levelSay = "Level the bars. Drag squares from a tall bar onto a short one."
        public let writeSay = "Write it down. Add them up and count them."
        public var why: String { "Shared out equally, every bar is \(mean): the mean is \(mean)." }
        public static let tooTall = "Too tall: put them on a short bar."
        public func summed(_ x: Int) -> String? {
            if x == total { return nil }
            return x == total - (v.last ?? 0) ? "Add every number in the list, the last one too." : "Add all the numbers."
        }
        public func counted(_ x: Int) -> String? {
            if x == n { return nil }
            return x == total ? "Count how many numbers there are, not what they add up to." : x == n - 1 ? "Count every number in the list." : "Count the numbers in the list."
        }
        /// (3 + 5 + 7 + 9) ÷ 4
        public var lead: MathLine {
            [.text("(")] + v.enumerated().flatMap { j, u -> MathLine in (j > 0 ? [.op("+")] : []) + [.num(Double(u))] } + [.text(")"), .op("÷"), .num(Double(n))]
        }
    }

    /// The web's generator: 4–6 numbers 1–20 whose total shares out evenly (no easy start); never all the same, so there's
    /// something to level.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let n = Int.random(in: 4...6, using: &rng)
        for _ in 0..<2000 {
            let v = (0..<n).map { _ in Int.random(in: 1...20, using: &rng) }
            if v.reduce(0, +) % n == 0, Set(v).count > 1 { return numbers(v) }
        }
        return numbers([3, 5, 7, 9])
    }

    public static let spec = LessonSpec(id: "g6-mean", title: "Find the mean", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in Parts(x).v.enumerated().flatMap { j, u -> MathLine in (j > 0 ? [.text(",")] : []) + [.num(Double(u))] } },
        idea: { _ in "The mean is what each would get if the total were shared out equally." },
        depends: ["g4-divide"],
        check: [CheckItem(0, when: { Parts($0).n == 4 }), CheckItem(0, when: { Parts($0).n == 5 }), CheckItem(0, when: { Parts($0).n == 6 }), CheckItem(0)]) { x in
        let s = Parts(x), M = Double(s.mean)
        let levelHint = "Take squares off the tallest bar and put them on the shortest."
        let level = LessonStep(StepWords(say: s.levelSay, hint: levelHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("m")], expected: ["m": M], hint: levelHint, explain: "Every bar is \(s.mean).",
                               check: { v in
                                   guard let m = v["m"] else { return .soft(s.levelSay) }
                                   return Data6.near(m, M) ? .right : .wrong(Parts.tooTall)
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let sumHint = "Add all the numbers."
        let sum = LessonStep(StepWords(say: s.writeSay, hint: sumHint, action: "Check"),
            answer: AnswerTask(prompt: s.lead + [.op("="), .box("T")], expected: ["T": Double(s.total)], hint: sumHint, explain: "\(s.total) in all.",
                               check: { v in
                                   guard let t = v["T"] else { return .soft("Write the number.") }
                                   return s.summed(Int(t.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Count the numbers in the list."
        let count = LessonStep(StepWords(say: s.writeSay, hint: countHint, action: "Check"),
            answer: AnswerTask(prompt: s.lead + [.op("="), .num(Double(s.total)), .op("÷"), .box("c")], expected: ["c": Double(s.n)], hint: countHint,
                               explain: "\(s.n) numbers to share it between.",
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Write the number.") }
                                   return s.counted(Int(c.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [LessonStep(StepWords(say: s.levelSay, hint: levelHint, action: "Let’s find out"), picture: ["at": 0]), level, sum, count,
                LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 4])]
    }
}

// MARK: - Mean absolute deviation

/// Mean absolute deviation (g6-mad, 6.SP.5c, 6.SP.3): Find the mean's bars and a level line across them. Drag the line
/// to where the squares over it match the gaps under it (the mean); tap each bar to measure it from the line; the
/// distances slide into a row of their own and level out; write (3 + 1 + 0 + 2 + 4 + 2) ÷ 6 = [12] ÷ 6 = [2].
///
/// "at": 0 the question, 1 balance, 2 measure, 3 the distances' total, 4 shared out, 5 done.
public enum Mad6 {
    /// `l0`: where the line starts (2 to 4 from the mean).
    public static func numbers(_ v: [Int], l0: Int) -> Numbers { var x: Numbers = ["l0": Double(l0)]; Data6.put(v, &x); return x }

    public struct Parts: Sendable {
        public let v: [Int], l0: Int
        public init(_ x: Numbers) { v = Data6.values(x); l0 = Data6.int(x, "l0", 0) }
        public var n: Int { v.count }
        public var mean: Int { n == 0 ? 0 : v.reduce(0, +) / n }
        public var tallest: Int { v.max() ?? 0 }
        public var d: [Int] { v.map { abs($0 - mean) } }
        public var dTotal: Int { d.reduce(0, +) }
        public var mad: Int { n == 0 ? 0 : dTotal / n }
        /// The squares over a line at `l` and the gaps under it.
        public func ab(_ l: Int) -> (above: Int, below: Int) { (v.reduce(0) { $0 + max(0, $1 - l) }, v.reduce(0) { $0 + max(0, l - $1) }) }
        public let balanceSay = "Find where they balance. Drag the line."
        public let measureSay = "Tap each bar to measure it from the line."
        public let writeSay = "Now share the distances out equally. Add them, then share them out."
        public var why: String { "On average each answer is \(mad) from the mean." }
        /// The line let go at `l` (nil: right).
        public func balanced(_ l: Int) -> String? {
            let (a, b) = ab(l)
            return a == b ? nil : "\(a) above, \(b) below: move it \(a > b ? "up" : "down")."
        }
        public func summed(_ x: Int) -> String? {
            if x == dTotal { return nil }
            if x == 0, let j = v.firstIndex(where: { $0 < mean }) { return "\(d[j]) below is \(d[j]) away." }
            return "Add every distance."
        }
        public func shared(_ x: Int) -> String? { x == mad ? nil : "Share \(dTotal) out equally: \(dTotal) ÷ \(n)." }
        /// (3 + 1 + 0 + 2) ÷ 4
        public var lead: MathLine {
            [.text("(")] + d.enumerated().flatMap { j, u -> MathLine in (j > 0 ? [.op("+")] : []) + [.num(Double(u))] } + [.text(")"), .op("÷"), .num(Double(n))]
        }
    }

    /// Problems 1–3: four or five numbers close together (within 4 of one); then 4–8 numbers 1–20. Redrawn until the mean and
    /// the MAD are whole (and not 0). The line starts 2 to 4 from the mean.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        for _ in 0..<5000 {
            var v: [Int]
            if i < 3 { let k = r(4, 5), m = r(5, 15); v = (0..<k).map { _ in m + r(-4, 4) } }
            else { v = (0..<r(4, 8)).map { _ in r(1, 20) } }
            let n = v.count, T = v.reduce(0, +)
            guard T % n == 0, v.allSatisfy({ (1...20).contains($0) }) else { continue }
            let M = T / n, D = v.reduce(0) { $0 + abs($1 - M) }
            guard D % n == 0, D > 0 else { continue }
            let l0 = min(v.max() ?? 1, max(1, M + Data6.pick([-1, 1], &rng) * r(2, 4)))
            return numbers(v, l0: l0 == M ? (M > 1 ? M - 1 : M + 1) : l0)
        }
        return numbers([4, 6, 8, 6], l0: 9)
    }

    public static let spec = LessonSpec(id: "g6-mad", title: "Mean absolute deviation", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in Parts(x).v.enumerated().flatMap { j, u -> MathLine in (j > 0 ? [.text(",")] : []) + [.num(Double(u))] } },
        idea: { _ in "The mean absolute deviation is how far the answers are from the mean, on average." },
        depends: ["g6-mean"],
        check: [CheckItem(4, when: { Parts($0).n == 4 }), CheckItem(4, when: { Parts($0).n == 5 }), CheckItem(4, when: { Parts($0).n == 6 }),
                CheckItem(4, when: { p in let s = Parts(p); return s.v.contains(s.mean) })]) { x in
        let s = Parts(x)
        let balanceHint = "The line balances where the squares over it fill the gaps under it."
        let balance = LessonStep(StepWords(say: s.balanceSay, hint: balanceHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("l")], expected: ["l": Double(s.mean)], hint: balanceHint, explain: "They balance at \(s.mean): the mean.",
                               check: { v in
                                   guard let l = v["l"] else { return .soft(s.balanceSay) }
                                   return s.balanced(Int(l.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let measureHint = "A bar over the line is as far as the part over it; under it, as far as the gap."
        let measure = LessonStep(StepWords(say: s.measureSay, hint: measureHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("t")], expected: ["t": Double(s.n)], hint: measureHint, explain: "Every bar measured.",
                               check: { v in Data6.int(v, "t") == s.n ? .right : .soft(s.measureSay) }, byHand: true),
            picture: ["at": 2])
        let sumHint = "Add every distance: they’re all how far, never less than 0."
        let sum = LessonStep(StepWords(say: s.writeSay, hint: sumHint, action: "Check"),
            answer: AnswerTask(prompt: s.lead + [.op("="), .box("T")], expected: ["T": Double(s.dTotal)], hint: sumHint, explain: "\(s.dTotal) in all.",
                               check: { v in
                                   guard let t = v["T"] else { return .soft("Write the number.") }
                                   return s.summed(Int(t.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let shareHint = "Share the total out equally: divide by how many."
        let share = LessonStep(StepWords(say: s.writeSay, hint: shareHint, action: "Check"),
            answer: AnswerTask(prompt: s.lead + [.op("="), .num(Double(s.dTotal)), .op("÷"), .num(Double(s.n)), .op("="), .box("A")], expected: ["A": Double(s.mad)],
                               hint: shareHint, explain: "\(s.dTotal) ÷ \(s.n) = \(s.mad).",
                               check: { v in
                                   guard let a = v["A"] else { return .soft("Write the number.") }
                                   return s.shared(Int(a.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [LessonStep(StepWords(say: s.balanceSay, hint: balanceHint, action: "Let’s find out"), picture: ["at": 0]), balance, measure, sum, share,
                LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 5])]
    }
}

// MARK: - Find the median

/// Find the median (g6-median, 6.SP.5c, 6.SP.3, 6.SP.5d; the maths of the web's g9-median): the numbers as bars, one
/// square a one, up to 30 tall. Sort them by hand (drag a bar to its place, the others make room; they number themselves
/// 1 to n), cross them off a pair at a time from both ends, write the middle spot and the median (or the halfway between
/// the middle two), then make the tallest taller: the mean runs after it, the median stays.
///
/// "at": 0 the question, 1 sort, 2 cross off, 3 the middle spot (odd), 4 the median, 5 grow, 6 done.
public enum Median6 {
    public static func numbers(_ v: [Int]) -> Numbers { var x: Numbers = [:]; Data6.put(v, &x); return x }
    /// How far the tallest can grow (squares).
    public static let room = 4, grows = 3

    public struct Parts: Sendable {
        public let v: [Int]
        public init(_ x: Numbers) { v = Data6.values(x) }
        public var n: Int { v.count }
        public var sorted: [Int] { v.sorted() }
        public var odd: Bool { n % 2 == 1 }
        public var median: Double { Data6.mid(sorted) }
        public var spot: Int { (n + 1) / 2 }
        public var total: Int { v.reduce(0, +) }
        public var tallest: Int { v.max() ?? 0 }
        /// The middle two (an even count).
        public var pair: (Int, Int) { let s = sorted; return n >= 2 ? (s[n / 2 - 1], s[n / 2]) : (0, 0) }
        public let sortSay = "Put them in order. Drag a bar to its place."
        public let crossSay = "Cross them off from both ends. Tap the shortest and the tallest left."
        public var writeSay: String { odd ? "Write the middle spot and the median." : "Write the halfway between the middle two." }
        public let growSay = "Make the tallest taller. Drag its top up."
        public let why = "The middle stays when the tallest grows. The mean moves."
        public static let crossMiss = "Cross off the shortest and the tallest left."
        public func spotted(_ x: Double) -> String? {
            if Data6.near(x, Double(spot)) { return nil }
            return Data6.near(x, Double(n) / 2) ? "Add 1 before halving: (\(n) + 1) ÷ 2." : "The middle spot has as many before it as after."
        }
        public func found(_ x: Double) -> String? {
            if Data6.near(x, median) { return nil }
            if odd { return "The median is the bar left standing." }
            let (a, b) = pair
            return Data6.near(x, Double(a + b)) ? "Halve it: (\(a) + \(b)) ÷ 2." : "Halfway between \(a) and \(b)."
        }
    }

    /// The tallest a number gets: the web g9-median's 1–30 would need bars 30 squares tall, and under the words (with room
    /// for the tallest to grow) a problem that tall shows at 68%; 25 shows at 75% or more.
    public static let most = 25
    /// Problems 1–3 five numbers, 4–6 five or seven (the web g9-median's, 1–25), then six or eight (halfway between the
    /// middle two, whole or .5). Never already in order.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let n = i < 3 ? 5 : i < 6 ? Data6.pick([5, 7], &rng) : Data6.pick([6, 8], &rng)
        for _ in 0..<1000 {
            let v = (0..<n).map { _ in Int.random(in: 1...most, using: &rng) }
            if v != v.sorted() { return numbers(v) }
        }
        return numbers([7, 2, 9, 4, 5])
    }

    public static let spec = LessonSpec(id: "g6-median", title: "Find the median", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in Parts(x).v.enumerated().flatMap { j, u -> MathLine in (j > 0 ? [.text(",")] : []) + [.num(Double(u))] } },
        idea: { _ in "The median is the middle number once the list is in order." },
        depends: ["g6-mean"],
        check: [CheckItem(0),
                CheckItem(4, when: { p in let s = Parts(p); return s.n == 7 && s.v[3] != s.sorted[3] }),
                CheckItem(4, when: { p in Set(Parts(p).v).count < Parts(p).n }),
                CheckItem(7)]) { x in
        let s = Parts(x)
        let sortHint = "The shortest bar goes first, the tallest last."
        let sort = LessonStep(StepWords(say: s.sortSay, hint: sortHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 1], hint: sortHint, explain: "In order: \(s.sorted.map(String.init).joined(separator: ", ")).",
                               check: { v in Data6.int(v, "s") == 1 ? .right : .soft(s.sortSay) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let crossHint = "Cross off one from each end, then the next two."
        let cross = LessonStep(StepWords(say: s.crossSay, hint: crossHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: crossHint, explain: s.odd ? "The middle bar is left." : "The middle two are left.",
                               check: { v in Data6.int(v, "x") == 1 ? .right : .wrong(Parts.crossMiss) }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        var out = [LessonStep(StepWords(say: s.sortSay, hint: sortHint, action: "Let’s find out"), picture: ["at": 0]), sort, cross]
        let med = s.median
        if s.odd {
            let spotHint = "The middle spot has as many before it as after."
            out.append(LessonStep(StepWords(say: s.writeSay, hint: spotHint, action: "Check"),
                answer: AnswerTask(prompt: [.text("("), .num(Double(s.n)), .op("+"), .num(1), .text(")"), .op("÷"), .num(2), .op("="), .box("s")],
                                   expected: ["s": Double(s.spot)], hint: spotHint, explain: "Spot \(s.spot) is the middle.",
                                   check: { v in
                                       guard let x = v["s"] else { return .soft("Write the number.") }
                                       return s.spotted(x).map { .wrong($0) } ?? .right
                                   }, incomplete: "Write the number."),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let medHint = s.odd ? "The median is the bar left standing." : "Halfway between the middle two: add them and halve it."
        let lead: MathLine = s.odd ? [.text("median"), .op("=")] : [.text("("), .num(Double(s.pair.0)), .op("+"), .num(Double(s.pair.1)), .text(")"), .op("÷"), .num(2), .op("=")]
        out.append(LessonStep(StepWords(say: s.writeSay, hint: medHint, action: "Check"),
            answer: AnswerTask(prompt: lead + [.box("m")], expected: ["m": med], hint: medHint, explain: "The median is \(fmt(med)).",
                               check: { v in
                                   guard let x = v["m"] else { return .soft("Write the number.") }
                                   return s.found(x).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let growHint = "Drag the tallest bar’s top up three squares or more."
        out.append(LessonStep(StepWords(say: s.growSay, hint: growHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("g")], expected: ["g": Double(grows)], hint: growHint, explain: "The mean moves, the median stays.",
                               check: { v in Data6.int(v, "g", 0) >= grows ? .right : .soft("Drag it higher.") }, byHand: true),
            picture: ["at": 5]))
        return out + [LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 6])]
    }
}

// MARK: - Box plots

/// Box plots (g6-boxplot, 6.SP.4, 6.SP.5c): 11–15 answers 0–20 already stacked as a dot plot, two squares a one, and a
/// strip under it for the box. Tap the middle answer, then the middle of each half (the median left out of both halves,
/// the school way); the box draws from one middle to the other, the whiskers out to the least and the greatest; write
/// IQR = 12 − 6 = [6].
///
/// "at": 0 the question, 1 the middle, 2 the halves' middles, 3 write, 4 done.
public enum BoxPlot6 {
    public struct Question: Sendable { public let q, unit: String }
    public static let questions = [
        Question(q: "How many minutes does each kid take to eat lunch?", unit: "minutes"),
        Question(q: "How many push-ups can each kid in the class do?", unit: "push-ups"),
        Question(q: "How many pages did each kid read last night?", unit: "pages"),
    ]
    public static func numbers(q: Int, data: [Int], far: Bool = false) -> Numbers {
        var x: Numbers = ["q": Double(q), "far": far ? 1 : 0]
        Data6.put(data, &x)
        return x
    }

    public struct Parts: Sendable {
        public let data: [Int], q: Int, far: Bool
        public init(_ x: Numbers) { data = Data6.values(x); q = min(questions.count - 1, max(0, Data6.int(x, "q", 0))); far = Data6.int(x, "far", 0) == 1 }
        public var Q: Question { questions[q] }
        public var s: [Int] { data.sorted() }
        public var n: Int { data.count }
        /// How many in each half (the median left out of both when the count is odd).
        public var h: Int { n / 2 }
        public var median: Double { Data6.mid(s) }
        public var q1: Double { Data6.mid(Array(s.prefix(h))) }
        public var q3: Double { Data6.mid(Array(s.suffix(h))) }
        /// The halves' middles with the median counted in them (the slip).
        public var q1w: Double { Data6.mid(Array(s.prefix(n - h))) }
        public var q3w: Double { Data6.mid(Array(s.suffix(n - h))) }
        public var least: Int { s.first ?? 0 }
        public var most: Int { s.last ?? 0 }
        public var iqr: Double { q3 - q1 }
        public var counts: [Int] { (0...20).map { u in data.filter { $0 == u }.count } }
        /// The middle of a run of `k` sorted answers from index `a`: one index, or the two either side of halfway.
        public static func mids(_ a: Int, _ k: Int) -> [Int] { k % 2 == 1 ? [a + (k - 1) / 2] : [a + k / 2 - 1, a + k / 2] }
        public let midSay = "Tap the middle answer. As many answers below it as above."
        public let halvesSay = "Now the middle of each half. Tap the middle of the lower half and of the upper half."
        public let writeSay = "The box goes from one middle to the other. Write how wide it is."
        public var why: String { "The box holds the middle half of the answers: \(fmt(iqr)) wide." }
        /// The answer at sorted index `k` tapped as the middle (nil: right).
        public func middle(_ k: Int) -> String? {
            guard s.indices.contains(k) else { return nil }
            if Parts.mids(0, n).contains(where: { s[$0] == s[k] }) { return nil }
            return "That one has \(k) below and \(n - 1 - k) above."
        }
        /// Which half's middle the answer at sorted index `k` is (0 lower, 1 upper), or what's wrong with it.
        public func half(_ k: Int) -> (side: Int?, miss: String?) {
            guard s.indices.contains(k) else { return (nil, nil) }
            let lo = k < h, hi = k >= n - h
            if !lo && !hi { return (nil, "That’s the middle of them all. Find the middle of each half.") }
            let a = lo ? 0 : n - h
            if Parts.mids(a, h).contains(where: { s[$0] == s[k] }) { return (lo ? 0 : 1, nil) }
            // the middle of a half counted with the middle answer in it
            if n % 2 == 1 && Parts.mids(lo ? 0 : h, h + 1).contains(where: { s[$0] == s[k] }) { return (nil, "Leave the middle answer out of both halves.") }
            return (nil, "That one has \(k - a) below and \(a + h - 1 - k) above in its half.")
        }
        public func written(_ x: Double) -> String? {
            if Data6.near(x, iqr) { return nil }
            return Data6.near(x, Double(most - least)) ? "That’s from the least to the greatest. The box holds the middle half." : "The box runs from \(fmt(q1)) to \(fmt(q3))."
        }
    }

    /// Problems 1–3 11 or 15 answers (the halves are 5 or 7, so the quarter points are answers); then 12–14 (halfway
    /// points), problem 5 and a third of those after with a far-off answer (a long whisker). At most 4 on a number; the
    /// median and the halves' middles all different.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        let n = i < 3 ? Data6.pick([11, 15], &rng) : r(12, 14), far = i == 4 || (i >= 6 && r(0, 2) == 0)
        let q = r(0, questions.count - 1)
        for _ in 0..<5000 {
            let c = r(5, 15), sp = r(3, 5)
            var v = (0..<(far ? n - 1 : n)).map { _ in c + r(-sp, sp) }
            if far { v.append(r(0, 1) == 1 ? (v.max() ?? 0) + r(5, 8) : (v.min() ?? 0) - r(5, 8)) }
            guard v.allSatisfy({ (0...20).contains($0) }) else { continue }
            let p = Parts(numbers(q: q, data: v))
            guard (p.counts.max() ?? 0) <= 4, p.q1 != p.q3, p.q1 != p.median, p.q3 != p.median else { continue }
            return numbers(q: q, data: v.shuffled(using: &rng), far: far)
        }
        return numbers(q: q, data: [4, 5, 6, 6, 7, 8, 9, 10, 11, 12, 14], far: false)
    }

    public static let spec = LessonSpec(id: "g6-boxplot", title: "Box plots", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).Q.q)] },
        idea: { _ in "The box holds the middle half of the answers." },
        depends: ["g6-median", "g6-dotplot"],
        check: [CheckItem(0, when: { Parts($0).n % 2 == 1 }), CheckItem(3, when: { Parts($0).n % 2 == 0 }), CheckItem(4), CheckItem(5)]) { x in
        let s = Parts(x)
        let midHint = "Count in from both ends until you meet."
        let mid = LessonStep(StepWords(say: s.midSay, hint: midHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k")], expected: ["k": Double(Parts.mids(0, s.n)[0])], hint: midHint, explain: "The middle is \(fmt(s.median)).",
                               check: { v in s.middle(Data6.int(v, "k", 0)).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let halvesHint = "Each half is the answers on one side of the middle: find each half’s own middle."
        let halves = LessonStep(StepWords(say: s.halvesSay, hint: halvesHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k")], expected: ["k": -1], hint: halvesHint, explain: "The halves’ middles are \(fmt(s.q1)) and \(fmt(s.q3)).",
                               check: { v in
                                   let k = Data6.int(v, "k", 0)
                                   if k == -1 { return .right }
                                   return s.half(k).miss.map { .wrong($0) } ?? .soft(s.halvesSay)
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Take the lower middle from the upper middle."
        let write = LessonStep(StepWords(say: s.writeSay, hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.text("IQR"), .op("="), .num(s.q3), .op("−"), .num(s.q1), .op("="), .box("A")], expected: ["A": s.iqr], hint: writeHint,
                               explain: "\(fmt(s.q3)) − \(fmt(s.q1)) = \(fmt(s.iqr)).",
                               check: { v in
                                   guard let a = v["A"] else { return .soft("Write the number.") }
                                   return s.written(a).map { .wrong($0) } ?? .right
                               }, incomplete: "Write the number."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [LessonStep(StepWords(say: s.midSay, hint: midHint, action: "Let’s find out"), picture: ["at": 0]), mid, halves, write,
                LessonStep(StepWords(say: s.why, hint: s.why, action: "Next problem"), picture: ["at": 4])]
    }
}
