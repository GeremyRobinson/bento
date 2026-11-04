import Foundation

/// Add and subtract big numbers (the web app's g4-addsub, 4.NBT.4; design/grade4.md, the preview grade4-ch1.html):
/// a + b or a − b, four or five digits, the column way, ones first. The web's maths: its generator (one carry or
/// trade, never a trade across a 0, a difference of 1,000 or more), its slips and its stories.
///
/// On the paper: the place chart, a's disks in its top band, b's (striped) a square under them. A column at a time
/// from the ones (then the thousands and up together): slide the striped disks up. Adding, they snap in after the top's;
/// ten or more, tap the full ten and it closes into one disk that slides into the next column (the carried 1). Taking
/// away, each lands on one of the top's and crosses it out; too few on top, open a ten from the next column first (it
/// opens into a full frame). The hands write the ones, tens and hundreds in the record; the thousands and up are typed.
///
/// Every step's picture has "at" (0 the question, 1 slide, 2 close a ten, 3 write, 4 done) and "ph", how many of the
/// problem's moves (`Parts.phases`) are done before it.
public enum AddSubBig {
    public static func numbers(a: Int, b: Int, sub: Bool) -> Numbers { ["a": Double(a), "b": Double(b), "sub": sub ? 1 : 0] }

    /// One column's working: its digits, what came in from the column before, whether it carries or trades, the digit
    /// written under it.
    public struct Column: Equatable, Sendable { public let top: Int, bottom: Int, carryIn: Int, regroup: Bool, write: Int }
    /// What the hands do, in order: slide a column's striped disks up (or the thousands and up together), or close a
    /// full ten.
    public enum Phase: Equatable, Sendable { case slide([Int]), close(Int) }

    public struct Parts: Sendable {
        public let a: Int, b: Int, sub: Bool
        public var R: Int { sub ? a - b : a + b }
        public var sign: String { sub ? "−" : "+" }
        public var length: Int { max(BigNumbers.length(a), BigNumbers.length(b)) }
        public init(_ n: Numbers) { a = Int((n["a"] ?? 1000).rounded()); b = Int((n["b"] ?? 1000).rounded()); sub = (n["sub"] ?? 0) != 0 }

        /// The column working (the web's columnWork), ones first.
        public var columns: [Column] { AddSubBig.work(a, b, sub) }
        /// The column that carries or trades (there's one).
        public var at: Int { columns.firstIndex { $0.regroup } ?? 0 }
        /// The hands' moves: each of the ones, tens and hundreds with something to slide, its full ten closed when it
        /// carries; then the thousands and up together, and their full ten when they carry.
        public var phases: [Phase] {
            var out: [Phase] = []
            for c in 0..<3 where BigNumbers.digit(b, c) != 0 {
                out.append(.slide([c]))
                if !sub && c == at { out.append(.close(c)) }
            }
            out.append(.slide(Array(3..<length).filter { BigNumbers.digit(b, $0) != 0 || BigNumbers.digit(a, $0) != 0 }))
            if !sub && at >= 3 { out.append(.close(at)) }
            return out
        }
        /// The digits the hands have written under the ones, tens and hundreds once `k` moves are done.
        public func written(after k: Int) -> [Int: Int] {
            var out: [Int: Int] = [:]
            let done = Array(phases.prefix(k))
            for c in 0..<3 {
                // a column is written once its slide (and its close, when it carries) is done; one with nothing to slide
                // as soon as the column before it is
                let slid = done.contains(.slide([c])) || (BigNumbers.digit(b, c) == 0 && (c == 0 || out[c - 1] != nil))
                let closed = sub || c != at || done.contains(.close(c))
                if slid && closed { out[c] = BigNumbers.digit(R, c) } else { break }
            }
            return out
        }
        /// What a wrong typed answer says (the preview's and the web's slips): the box holds the thousands and up.
        public func typed(_ x: Int) -> String {
            let v = x * 1000 + R % 1000
            let cols = columns
            if !sub {
                let noCarry = cols.enumerated().reduce(0) { $0 + (($1.element.top + $1.element.bottom) % 10) * BigNumbers.pow10($1.offset) }
                if v == R - BigNumbers.pow10(at + 1) { return "You carried 1 from the \(BigNumbers.places[at]). Add it to the \(BigNumbers.places[at + 1]) too." }
                if v == noCarry { return "When a column makes 10 or more, write the ones digit and carry the 1 to the next place." }
            } else {
                let smallFromBig = cols.enumerated().reduce(0) { $0 + abs(BigNumbers.digit(a, $1.offset) - $1.element.bottom) * BigNumbers.pow10($1.offset) }
                if v == smallFromBig { return "In each column take the bottom digit from the top one. When the top is smaller, trade a ten first." }
                if v == R + BigNumbers.pow10(at + 1) { return "When a place trades a ten away, it has 1 less. Cross it out and write the new digit." }
            }
            return "Read each column’s disks, from the left."
        }
        /// The story (the web's).
        public var story: String {
            let c = BigNumbers.commas
            return sub ? "A stadium has \(c(a)) seats. \(c(b)) of them are full. How many seats are empty?"
                : "A library has \(c(a)) books. It gets \(c(b)) more. How many books does it have now?"
        }
    }

    /// The web's columnWork: each column's digits, the carry or trade coming in, and the digit written.
    public static func work(_ a: Int, _ b: Int, _ sub: Bool) -> [Column] {
        let L = max(BigNumbers.length(a), BigNumbers.length(b))
        var out: [Column] = [], carry = 0
        for i in 0..<L {
            let top = BigNumbers.digit(a, i), bottom = BigNumbers.digit(b, i)
            if !sub {
                let s = top + bottom + carry
                out.append(Column(top: top, bottom: bottom, carryIn: carry, regroup: s >= 10, write: s % 10)); carry = s >= 10 ? 1 : 0
            } else {
                let t = top - carry, rg = t < bottom
                out.append(Column(top: t, bottom: bottom, carryIn: carry, regroup: rg, write: t + (rg ? 10 : 0) - bottom)); carry = rg ? 1 : 0
            }
        }
        return out
    }

    /// The web's generator, as the preview makes it: four digits for the first four problems, then five; adding or
    /// subtracting at random; exactly one carry or trade, never a trade across a 0, a difference of 1,000 or more.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let d = index < 4 ? 4 : 5, sub = Bool.random(using: &rng), lo = BigNumbers.pow10(d - 1), hi = BigNumbers.pow10(d) - 1
        while true {
            let a: Int, b: Int
            if !sub { a = Int.random(in: lo...hi, using: &rng); b = Int.random(in: lo...hi, using: &rng) }
            else { a = Int.random(in: (2 * lo)...hi, using: &rng); b = Int.random(in: lo...(a - 1000), using: &rng) }
            let rg = work(a, b, sub).indices.filter { work(a, b, sub)[$0].regroup }
            guard rg.count == 1 else { continue }
            if sub && BigNumbers.digit(a, rg[0] + 1) == 0 { continue }
            return numbers(a: a, b: b, sub: sub)
        }
    }

    public static let spec = LessonSpec(id: "g4-addsub", title: "Add and subtract big numbers", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text(BigNumbers.commas(s.a)), .op(s.sign), .text(BigNumbers.commas(s.b))] },
        idea: { _ in "Ten in one place make 1 in the next." },
        story: { n in Parts(n).story },
        storyOp: { n in Parts(n).sign },
        depends: ["g3-addsub"],
        check: [CheckItem(0, when: { Parts($0).sub }), CheckItem(4, when: { !Parts($0).sub }), CheckItem(4, when: { Parts($0).sub }), CheckItem(4, story: true)]) { n in
        let s = Parts(n), phases = s.phases, P = BigNumbers.places, P1 = BigNumbers.place1
        var steps = [LessonStep(StepWords(say: s.sub ? "Take away, a column at a time." : "Add, a column at a time.",
                                          hint: "Ones first.", action: "Let’s find out"), picture: ["at": 0, "ph": 0])]
        for (k, ph) in phases.enumerated() {
            switch ph {
            case .slide(let cols):
                let c = cols.first ?? 3, rest = c >= 3, name = rest ? "thousands and up" : P[c]
                // the column taking away more than it has: a ten is opened from the next one first
                let trade = s.sub ? cols.first { $0 == s.at } : nil
                let say = rest ? "Slide the rest up together." : "Slide the striped \(name) up."
                let hint = s.sub ? (trade != nil ? "Too few on top? Open a \(P1[s.at + 1]) first." : "Each one takes away a disk it lands on.")
                    : (c == 0 ? "Ones first: they snap in after the top’s." : rest ? "The thousands and up, all at once." : "Now the \(name).")
                steps.append(LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: hint, explain: hint,
                                       check: { v in
                                           let x = Int((v["x"] ?? 0).rounded())
                                           switch x {
                                           case 1: return .right
                                           case 2:
                                               // slid with too few on top
                                               let t = trade ?? c, top = BigNumbers.digit(s.a, t) - (s.at == t - 1 ? 1 : 0), bottom = BigNumbers.digit(s.b, t)
                                               return .wrong("\(top) \(BigNumbers.place(t, top)) can’t take away \(bottom). Open a ten.")
                                           case 3: return .wrong("There are enough \(rest ? P[cols.first ?? 3] : name). Take away first.")
                                           case 4: return .soft("Open a \(P1[s.at + 1]).")
                                           case 5: return .soft(rest ? "Slide the rest together." : "Start with the \(name).")
                                           default: return .soft(say)
                                           }
                                       }, byHand: true),
                    picture: ["at": 1, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case .close(let c):
                let n = BigNumbers.digit(s.a, c) + BigNumbers.digit(s.b, c) + (s.columns[c].carryIn)
                steps.append(LessonStep(StepWords(say: "Tap the full ten.", hint: "10 \(P[c]) make 1 \(P1[c + 1]).", action: "Check"),
                    answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: "10 \(P[c]) make 1 \(P1[c + 1]).", explain: "10 \(P[c]) make 1 \(P1[c + 1]).",
                                       check: { v in
                                           let x = Int((v["x"] ?? 0).rounded())
                                           if x == 1 { return .right }
                                           if x == 5 { return .soft("\(n) \(BigNumbers.place(c, n)): tap the full ten first.") }
                                           return .soft("Tap the full frame of ten.")
                                       }, byHand: true),
                    picture: ["at": 2, "ph": Double(k)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            }
        }
        // the thousands and up, typed; the hands wrote the rest
        let x = s.R / 1000, low = s.R % 1000
        func asBox(_ v: Int) -> Double? { v >= 0 && v % 1000 == low ? Double(v / 1000) : nil }
        var known: [(values: [String: Double], message: String)] = []
        var seen: Set<Double> = [Double(x)]
        let slips: [Int] = s.sub
            ? [s.columns.enumerated().reduce(0) { $0 + abs(BigNumbers.digit(s.a, $1.offset) - $1.element.bottom) * BigNumbers.pow10($1.offset) }, s.R + BigNumbers.pow10(s.at + 1)]
            : [s.R - BigNumbers.pow10(s.at + 1), s.columns.enumerated().reduce(0) { $0 + (($1.element.top + $1.element.bottom) % 10) * BigNumbers.pow10($1.offset) }]
        for v in slips { if let bx = asBox(v), !seen.contains(bx) { seen.insert(bx); known.append((["x": bx], s.typed(Int(bx)))) } }
        steps.append(LessonStep(StepWords(say: "Write the rest of the answer.", hint: "Read the thousands and up from the chart.", action: "Check"),
            answer: AnswerTask(prompt: [.text(BigNumbers.commas(s.a)), .op(s.sign), .text(BigNumbers.commas(s.b)), .op("="), .box("x")],
                               expected: ["x": Double(x)], known: known, hint: "Read the thousands and up from the chart.",
                               explain: "\(BigNumbers.commas(s.a)) \(s.sign) \(BigNumbers.commas(s.b)) = \(BigNumbers.commas(s.R))",
                               check: { v in
                                   let t = Int((v["x"] ?? -1).rounded())
                                   return t == x ? .right : .wrong(s.typed(t))
                               }),
            picture: ["at": 3, "ph": Double(phases.count)]))
        steps.append(LessonStep(StepWords(say: "Ten in one place make 1 in the next.", hint: "Ten in one place make 1 in the next.", action: "Next problem"),
                                picture: ["at": 4, "ph": Double(phases.count)]))
        return steps
    }
}
