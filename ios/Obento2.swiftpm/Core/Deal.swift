import Foundation

/// Sharing disks out, a place at a time (design/grade4.md chapter 2, the preview grade4-ch2.html): what Dividing with
/// remainders (g4-divide) and Dividing big numbers (g4-share) share. The place chart, the number's disks in frames on
/// top, dv rows under them (a row is a friend). From the biggest place down: a place with fewer than dv opens (tap each
/// disk: it opens into a frame of ten of the next place); a place with enough is dealt (drag it down: one to each row,
/// round after round); what's left opens. The ones left after their deal are the remainder.
public enum Deal {
    /// What the hands do, in order.
    public enum Phase: Equatable, Sendable {
        /// Open place p's disks: `cant`, there were too few to go round at all (none dealt).
        case open(Int, cant: Bool)
        /// Deal place p's disks, round after round.
        case deal(Int)
        public var place: Int { switch self { case .open(let p, _), .deal(let p): p } }
    }
    /// A line of the record: place p dealt s each from `part` there (s is 0 when it couldn't go round).
    public struct Entry: Equatable, Sendable { public let p: Int, s: Int, part: Int }

    public struct Plan: Sendable {
        public let n: Int, dv: Int
        /// The chart's columns (2 at least).
        public let D: Int
        public let phases: [Phase]
        /// Each column's disks on top before phase k (k = phases.count: after the last).
        public let before: [[Int]]
        /// Each place's share (a row's disks there) once dealt.
        public let shares: [Int]
        /// The record's lines (Dividing big numbers writes those that couldn't go round too), and how many phases are
        /// done when each is written.
        public let log: [Entry], logAt: [Int]
        /// The most disks a column holds at any time (sets the frames' band).
        public let most: Int

        public init(n: Int, dv: Int, zeros: Bool) {
            self.n = n; self.dv = dv
            let D = max(2, BigNumbers.length(n)); self.D = D
            var cols = (0..<D).map { BigNumbers.digit(n, $0) }, shares = Array(repeating: 0, count: D)
            var phases: [Phase] = [], before: [[Int]] = [], log: [Entry] = [], logAt: [Int] = []
            var most = cols.max() ?? 0
            func push(_ ph: Phase) { before.append(cols); phases.append(ph) }
            var p = D - 1
            while true {
                let c = cols[p]
                if c >= dv {
                    push(.deal(p))
                    shares[p] = c / dv; cols[p] = c % dv
                    log.append(Entry(p: p, s: c / dv, part: c)); logAt.append(phases.count)
                    if cols[p] > 0 && p > 0 { push(.open(p, cant: false)); cols[p - 1] += 10 * cols[p]; cols[p] = 0 }
                } else if p > 0 && c > 0 {
                    if zeros && !log.isEmpty { log.append(Entry(p: p, s: 0, part: c)); logAt.append(phases.count) }
                    push(.open(p, cant: true)); cols[p - 1] += 10 * c; cols[p] = 0
                } else if p > 0 && zeros && !log.isEmpty {
                    log.append(Entry(p: p, s: 0, part: 0)); logAt.append(phases.count)
                }
                if p > 0 { most = max(most, cols[p - 1]) }
                if p == 0 { break }
                p -= 1
            }
            before.append(cols)
            self.phases = phases; self.before = before; self.shares = shares; self.log = log; self.logAt = logAt; self.most = most
        }
        public var q: Int { n / dv }
        public var r: Int { n % dv }
    }

    /// What dragging a place's disks down says when they must open instead (the preview's): too few left after a deal,
    /// too few to go round at all, or too few in the middle of the number (0 of that place each).
    public static func cantDeal(_ plan: Plan, _ k: Int) -> String {
        guard case .open(let p, let cant) = plan.phases[k] else { return "" }
        let c = plan.before[k][p], P = BigNumbers.place(p, c), it = c == 1 ? "it" : "them"
        if !cant { return "Only \(c) \(P) left: not enough for \(plan.dv) rows. Open \(it)." }
        let dealt = plan.phases[..<k].contains { if case .deal = $0 { true } else { false } }
        if dealt { return "\(c) \(P) can’t go to \(plan.dv) rows: that’s 0 \(BigNumbers.places[p]) each. Open \(it)." }
        return "\(c) \(P) can’t go to \(plan.dv) rows. Open \(it)."
    }

    /// The hand phases as steps: open (its box 1 once every disk is open, 2 for a drag down instead), deal (its box the
    /// rounds dealt so far; 0 a tap with no drag). Every step's picture has "at" 1 and "ph" the phase.
    static func workSteps(_ plan: Plan, opener: String) -> [LessonStep] {
        plan.phases.enumerated().map { k, ph in
            let p = ph.place, P = BigNumbers.places, c = plan.before[k][p], dv = plan.dv
            var say: String, hint: String
            let task: AnswerTask
            switch ph {
            case .deal:
                let share = plan.shares[p]
                say = "Deal the \(P[p]). Drag the \(P[p]) down: one to each row, round after round."
                hint = "One to each row, round after round."
                task = AnswerTask(prompt: [.box("x")], expected: ["x": Double(share)], hint: hint, explain: "\(share) each.",
                                  check: { v in
                                      let x = Int((v["x"] ?? 0).rounded())
                                      if x == share { return .right }
                                      if x <= 0 { return .soft("There are enough \(P[p]) for every row. Drag them down.") }
                                      let left = c - x * dv
                                      return .wrong("\(left) \(BigNumbers.place(p, left)) left: enough for another round.")
                                  }, byHand: true)
                if k == 0 { say = "\(opener) Drag the \(P[p]) down: one to each row, round after round." }
            case .open(_, let cant):
                say = cant ? "Open the \(P[p]). \(c) \(BigNumbers.place(p, c)) can’t go round. Tap each: it opens into ten \(P[p - 1])."
                    : "Open the \(P[p]) left. Tap each: it opens into ten \(P[p - 1])."
                hint = "Each \(BigNumbers.place1[p]) opens into ten \(P[p - 1])."
                if k == 0 { say = "\(opener) \(c) \(BigNumbers.place(p, c)) can’t go round. Tap each: it opens into ten \(P[p - 1])." }
                let msg = cantDeal(plan, k)
                task = AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint, explain: "\(c) \(BigNumbers.place(p, c)) open into \(10 * c) \(P[p - 1]).",
                                  check: { v in
                                      let x = Int((v["x"] ?? 0).rounded())
                                      return x == 1 ? .right : x == 2 ? .wrong(msg) : .soft("Tap each: it opens into ten \(P[p - 1]).")
                                  }, byHand: true)
            }
            return LessonStep(StepWords(say: say, hint: hint, action: "Check"), answer: task, picture: ["at": 1, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
    }

    /// The answer typed over the bracket: q, and R when anything's left (always, for Dividing with remainders).
    static func writeStep(_ plan: Plan, needR: Bool, wrongQ: @escaping @Sendable (Int) -> String) -> LessonStep {
        let q = plan.q, r = plan.r, dv = plan.dv
        let say = needR ? "Write the answer and what’s left. Read across one row. What’s left stays on top." : "Write the answer. Read across one row."
        let prompt: MathLine = [.text(BigNumbers.commas(plan.n)), .op("÷"), .num(Double(dv)), .op("="), .box("Q")] + (needR ? [.text("R"), .box("R")] : [])
        return LessonStep(StepWords(say: say, hint: "Read across one row.", action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: needR ? ["Q": Double(q), "R": Double(r)] : ["Q": Double(q)], hint: "Read across one row.",
                               explain: "\(BigNumbers.commas(plan.n)) ÷ \(dv) = \(BigNumbers.commas(q))" + (needR ? " R \(r)" : ""),
                               check: { v in
                                   let vQ = Int((v["Q"] ?? -1).rounded()), vR = needR ? Int((v["R"] ?? -1).rounded()) : 0
                                   if vQ != q { return .wrong(wrongQ(vQ)) }
                                   if vR != r { return .wrong(vR >= dv ? "\(vR) left is enough for another round of \(dv)." : "Count the ones left on top.") }
                                   return .right
                               },
                               incomplete: needR ? "Type the answer, and what’s left in the R box." : "Type the answer in the box."),
            picture: ["at": 2])
    }
}

/// Dividing with remainders (the web app's g4-divide, 4.NBT.6, 4.OA.3): n ÷ dv = q R r, dv 3–9, q 12–99 never a whole
/// ten. The web's maths (its generator ignores the index; the check's `where`s do the work), with the fold: from the
/// fourth problem, odd ones are stories that ask one of four things, and a last step writes the story's answer.
///
/// Every step's picture has "at": 0 the question, 1 a hand phase ("ph"), 2 write the answer, 3 the story's answer, 4 done.
public enum DivideRemainders {
    /// `sk`: the story's question, 0 none, 1 each friend's share, 2 what's left, 3 full bags, 4 bags needed.
    public static func numbers(dv: Int, q: Int, r: Int, story sk: Int = 0) -> Numbers { ["dv": Double(dv), "q": Double(q), "r": Double(r), "sk": Double(sk)] }

    public struct Parts: Sendable {
        public let dv: Int, q: Int, r: Int, sk: Int
        public init(_ x: Numbers) {
            dv = Int((x["dv"] ?? 3).rounded()); q = Int((x["q"] ?? 12).rounded()); r = Int((x["r"] ?? 0).rounded()); sk = Int((x["sk"] ?? 0).rounded())
        }
        public var n: Int { dv * q + r }
        public var plan: Deal.Plan { Deal.Plan(n: n, dv: dv, zeros: false) }
        /// The story's words, its answer and the word written after it.
        public var story: (text: String, answer: Int, unit: String)? {
            switch sk {
            case 1: ("\(n) stickers are shared equally by \(dv) friends. How many does each friend get?", q, "each")
            case 2: ("\(n) stickers are shared equally by \(dv) friends. How many are left over?", r, "left over")
            case 3: ("\(n) apples are packed in bags of \(dv). How many bags are full?", q, "full bags")
            case 4: ("\(n) apples are packed in bags of \(dv). How many bags are needed for all of them?", q + (r > 0 ? 1 : 0), "bags")
            default: nil
            }
        }
        /// What a wrong share says.
        public func wrongQ(_ v: Int) -> String {
            let qt = q / 10, qo = q % 10
            if v == qt + qo { return "Each row has \(qt == 1 ? "a ten" : "\(qt) tens") and \(qo == 1 ? "a one" : "\(qo) ones"): \(q)." }
            return "Read across one row: its tens and its ones."
        }
        /// What a wrong story answer says.
        public func wrongStory(_ v: Int) -> String {
            if sk == 4 && v == q { return "\(q) bags hold \(q * dv). The \(r) left need a bag too." }
            if sk == 1 && r > 0 && v == q + 1 { return "Each friend gets \(q). The \(r) left aren’t shared." }
            if sk == 2 && v == q { return "That’s each friend’s share. The ones left over are on top." }
            if sk == 3 && r > 0 && v == q + 1 { return "The \(r) left don’t fill a bag." }
            return "Read the story again: what does it ask?"
        }
        public var why: String {
            r > 0 ? "\(r) is less than \(dv), so \(r) \(r == 1 ? "is" : "are") left over." : "Nothing is left: \(dv) rows of \(q)."
        }
    }

    /// The web's generator (the index ignored), with the fold's stories: from index 3 the odd problems ask one of the four
    /// questions in turn (left over, full bags, bags needed, each friend's), and from index 11 any of them. A story asking
    /// what's left, or how many bags are needed, always has some left.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let dv = Int.random(in: 3...9, using: &rng)
        var q = 0
        repeat { q = Int.random(in: 12...99, using: &rng) } while q % 10 == 0
        let sk = index >= 3 && index % 2 == 1 ? (index >= 11 ? Int.random(in: 1...4, using: &rng) : [1, 2, 3, 4][(index / 2) % 4]) : 0
        let r = sk == 2 || sk == 4 ? Int.random(in: 1...(dv - 1), using: &rng) : Int.random(in: 0...(dv - 1), using: &rng)
        return numbers(dv: dv, q: q, r: r, story: sk)
    }

    public static let spec = LessonSpec(id: "g4-divide", title: "Dividing with remainders", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.num(Double(s.n)), .op("÷"), .num(Double(s.dv))] },
        idea: { _ in "Share a place at a time; what's too few for a round is left over." },
        depends: ["g3-divfacts", "g3-mult10"],
        check: [CheckItem(0, when: { Parts($0).r == 0 }), CheckItem(0, when: { Parts($0).r > 0 && Parts($0).q >= 20 }),
                CheckItem(0, when: { Parts($0).r > 0 }), CheckItem(11, when: { Parts($0).sk > 0 })]) { x in
        let s = Parts(x), plan = s.plan
        let opener = s.story?.text ?? "Share them into \(s.dv) rows."
        var steps = [LessonStep(StepWords(say: opener, hint: "Share a place at a time, the biggest first.", action: "Let’s find out"), picture: ["at": 0])]
        steps += Deal.workSteps(plan, opener: opener)
        steps.append(Deal.writeStep(plan, needR: true, wrongQ: { s.wrongQ($0) }))
        if let st = s.story {
            let ask = st.text.components(separatedBy: ". ").dropFirst().joined(separator: ". ")
            steps.append(LessonStep(StepWords(say: "\(ask) Write the story’s answer.", hint: "What does the story ask?", action: "Check"),
                answer: AnswerTask(prompt: [.box("S"), .text(st.unit)], expected: ["S": Double(st.answer)], hint: "What does the story ask?",
                                   explain: "\(st.answer) \(st.unit)",
                                   check: { v in Int((v["S"] ?? -1).rounded()) == st.answer ? .right : .wrong(s.wrongStory(Int((v["S"] ?? -1).rounded()))) },
                                   incomplete: "Type the number in the box."),
                picture: ["at": 3]))
        }
        steps.append(LessonStep(StepWords(say: s.why, hint: "Share a place at a time; what's too few for a round is left over.", action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}

/// Dividing big numbers (g4-share, 4.NBT.6; new): Dividing with remainders' deal, with thousands, a three-digit share and
/// zeros in it. dv 3–9, q 100–999, r 0 to dv − 1, n = dv × q + r up to 9,999. The record is the long division as school
/// writes it.
///
/// Every step's picture has "at": 0 the question, 1 a hand phase ("ph"), 2 write the answer, 4 done.
public enum DivideBig {
    public static func numbers(dv: Int, q: Int, r: Int, story: Bool = false) -> Numbers { ["dv": Double(dv), "q": Double(q), "r": Double(r), "st": story ? 1 : 0] }

    public struct Parts: Sendable {
        public let dv: Int, q: Int, r: Int, story: Bool
        public init(_ x: Numbers) {
            dv = Int((x["dv"] ?? 3).rounded()); q = Int((x["q"] ?? 100).rounded()); r = Int((x["r"] ?? 0).rounded()); story = (x["st"] ?? 0) != 0
        }
        public var n: Int { dv * q + r }
        public var plan: Deal.Plan { Deal.Plan(n: n, dv: dv, zeros: true) }
        public var opener: String {
            story ? "\(BigNumbers.commas(n)) seeds are shared equally by \(dv) gardens. How many seeds does each garden get?" : "Share them into \(dv) rows."
        }
        /// What a wrong share says (the preview's): a 0 left out, the opened disks forgotten, or read it again.
        public func wrongQ(_ v: Int) -> String {
            let plan = self.plan, P = BigNumbers.places
            if v != q, String(q).replacingOccurrences(of: "0", with: "") == String(v), let z = plan.log.first(where: { $0.s == 0 && $0.p > 0 }) {
                return "\(dv) can’t go into \(z.part) \(BigNumbers.place(z.p, z.part)): write 0 \(P[z.p])."
            }
            let naive = (0..<plan.D).reduce(0) { $0 + BigNumbers.digit(n, $1) / dv * BigNumbers.pow10($1) }
            if v == naive, let lf = plan.log.first(where: { $0.p > 0 && $0.part - $0.s * dv > 0 }) {
                let l = lf.part - lf.s * dv
                return "The \(l) \(BigNumbers.place(lf.p, l)) left \(l == 1 ? "is" : "are") \(l * 10) \(P[lf.p - 1]) more."
            }
            return "Read across one row, from the biggest place."
        }
    }

    /// The preview's generator: index < 3 three-digit n, its first digit at least dv, no 0 in q; then four-digit n whose
    /// first digit is under dv (opened first), a 0 in q now and then. From index 6 the odd ones are told about seeds.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        while true {
            let dv = Int.random(in: 3...9, using: &rng), r = Int.random(in: 0...(dv - 1), using: &rng)
            if index < 3 {
                let hi = (999 - r) / dv
                guard hi >= 100 else { continue }
                let q = Int.random(in: 100...hi, using: &rng), n = dv * q + r
                if n > 999 || BigNumbers.digit(n, 2) < dv || String(q).contains("0") { continue }
                return numbers(dv: dv, q: q, r: r)
            }
            let q = Int.random(in: 100...999, using: &rng), n = dv * q + r
            if n < 1000 || n > 9999 || BigNumbers.digit(n, 3) >= dv { continue }
            return numbers(dv: dv, q: q, r: r, story: index >= 6 && index % 2 == 1)
        }
    }

    public static let spec = LessonSpec(id: "g4-share", title: "Dividing big numbers", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { x in let s = Parts(x); return [.text(BigNumbers.commas(s.n)), .op("÷"), .num(Double(s.dv))] },
        idea: { _ in "Share the biggest place first, then open what's left." },
        depends: ["g4-divide", "g4-tentimes"],
        check: [CheckItem(0), CheckItem(3, when: { String(Parts($0).q).contains("0") }), CheckItem(6), CheckItem(7, when: { Parts($0).story })]) { x in
        let s = Parts(x), plan = s.plan
        var steps = [LessonStep(StepWords(say: s.opener, hint: "Share the biggest place first.", action: "Let’s find out"), picture: ["at": 0])]
        steps += Deal.workSteps(plan, opener: s.opener)
        steps.append(Deal.writeStep(plan, needR: s.r > 0, wrongQ: { s.wrongQ($0) }))
        steps.append(LessonStep(StepWords(say: "Share the biggest place first, then open what’s left.", hint: "Share the biggest place first, then open what's left.",
                                          action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
