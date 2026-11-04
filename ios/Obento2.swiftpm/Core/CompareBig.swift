import Foundation

/// Comparing big numbers (g4-compare, 4.NBT.2; design/grade4.md, the preview grade4-ch1.html). Two numbers from 1,000
/// to 999,999, A and B: (a) the same length, differing in the first place; (b) the same length and first digit,
/// differing in a middle place; (c) different lengths, the shorter with the bigger first digit; (d) equal, now and then.
///
/// On the paper: the place chart with as many columns as the longer number, A's disks and digits on top, B's (striped)
/// under them. When the lengths differ, B starts written under A's first digit, as children write it: slide it a column
/// at a time until ones are under ones. Tap the first place that differs, from the left. Tap <, = or >.
///
/// Every step's picture has "at": 0 the question, 1 slide, 2 tap the place, 3 the sign, 4 done.
public enum CompareBig {
    public static func numbers(A: Int, B: Int, kind: Int) -> Numbers { ["A": Double(A), "B": Double(B), "kind": Double(kind)] }

    public struct Parts: Sendable {
        public let A: Int, B: Int
        /// 0 (a), 1 (b), 2 (c), 3 (d).
        public let kind: Int
        public var lA: Int { BigNumbers.length(A) }
        public var lB: Int { BigNumbers.length(B) }
        /// The chart's columns: the longer number's length.
        public var n: Int { max(lA, lB) }
        /// The first place that differs, from the left (nil when they're equal).
        public var first: Int? { (0..<n).reversed().first { BigNumbers.digit(A, $0) != BigNumbers.digit(B, $0) } }
        /// < = >, as 0, 1, 2.
        public var sign: Int { A < B ? 0 : A == B ? 1 : 2 }
        public static let signs = ["<", "=", ">"]
        public var signText: String { Self.signs[sign] }
        /// Where B's first digit starts, in the chart's columns from the left: under A's first digit, and where it belongs.
        public var start: Int { n - lA }
        public var aligned: Int { n - lB }
        public var slides: Bool { lA != lB }
        public init(_ n: Numbers) { A = Int((n["A"] ?? 1000).rounded()); B = Int((n["B"] ?? 1000).rounded()); kind = Int((n["kind"] ?? 0).rounded()) }

        /// What a slide let go at column `at` (B's first digit's column) says: where its ones digit is.
        public func slid(_ at: Int) -> String {
            let pw = n - 1 - (at + lB - 1), d = BigNumbers.digit(B, 0)
            return pw >= 0 ? "The \(d) is under the \(BigNumbers.places[pw]). Ones go under ones." : "The \(d) is past the ones. Ones go under ones."
        }
        /// What a tap on place `pw` says when it isn't the first that differs.
        public func tapped(_ pw: Int) -> String {
            guard let fd = first else { return "Every place has the same digit." }
            if pw < fd { return "The \(BigNumbers.places[fd]) differ first: \(BigNumbers.digit(A, fd)) and \(BigNumbers.digit(B, fd))." }
            let a = BigNumbers.digit(A, pw)
            return "Both have \(a) \(BigNumbers.place(pw, a)). Look further right."
        }
        /// What a wrong sign says (the preview's): compared the first digits, turned it round, or called them equal.
        public func signed(_ s: Int) -> String {
            if sign == 1 { return "Every place has the same digit." }
            let fd = first ?? 0
            if s == 1 { return "The \(BigNumbers.places[fd]) differ: \(BigNumbers.digit(A, fd)) and \(BigNumbers.digit(B, fd))." }
            if lA != lB {
                let lng = lA > lB ? A : B, sht = lng == A ? B : A, k = BigNumbers.length(lng) - 1, d = BigNumbers.digit(lng, k)
                return "\(BigNumbers.commas(lng)) has \(d == 1 ? "a" : "\(d)") \(BigNumbers.place(k, d)). \(BigNumbers.commas(sht)) has none."
            }
            return "\(BigNumbers.commas(max(A, B))) is bigger: \(BigNumbers.commas(A)) \(signText) \(BigNumbers.commas(B))."
        }
    }

    /// The preview's generator: the first three (a) with four digits; then any kind, with five and six digits.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index < 3 ? 0 : Int.random(in: 0..<10, using: &rng) == 0 ? 3 : Int.random(in: 0...2, using: &rng)
        let L = index < 3 ? 4 : Int.random(in: 5...6, using: &rng)
        func digs(_ n: Int, _ first: Int? = nil) -> [Int] { [first ?? Int.random(in: 1...9, using: &rng)] + (1..<n).map { _ in Int.random(in: 0...9, using: &rng) } }
        func num(_ d: [Int]) -> Int { d.reduce(0) { $0 * 10 + $1 } }
        var a: [Int], b: [Int]
        switch kind {
        case 0:
            a = digs(L); b = digs(L)
            while b[0] == a[0] { b[0] = Int.random(in: 1...9, using: &rng) }
        case 1:
            let k = Int.random(in: 1...(L - 2), using: &rng)
            a = digs(L); b = a
            repeat { b[k] = Int.random(in: 0...9, using: &rng) } while b[k] == a[k]
            for j in (k + 1)..<L { b[j] = Int.random(in: 0...9, using: &rng) }
        case 2:
            let long = digs(L, Int.random(in: 1...8, using: &rng)), short = digs(L - 1, Int.random(in: (long[0] + 1)...9, using: &rng))
            (a, b) = Bool.random(using: &rng) ? (long, short) : (short, long)
        default:
            a = digs(L); b = a
        }
        return numbers(A: num(a), B: num(b), kind: kind)
    }

    public static let spec = LessonSpec(id: "g4-compare", title: "Comparing big numbers", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.text(BigNumbers.commas(s.A)), .text("or"), .text(BigNumbers.commas(s.B))] },
        idea: { _ in "Line them up by place. The first place that differs, from the left, decides." },
        depends: ["g4-readwrite"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).kind == 1 }), CheckItem(3, when: { Parts($0).kind == 2 }),
                CheckItem(3, when: { Parts($0).kind == 2 && Parts($0).n == 6 })]) { n in
        let s = Parts(n), As = BigNumbers.commas(s.A), Bs = BigNumbers.commas(s.B)
        var steps = [LessonStep(StepWords(say: "Which is bigger, \(As) or \(Bs)?", hint: "Line them up by place.", action: "Let’s find out"), picture: ["at": 0])]
        if s.slides {
            // slide the second number until ones are under ones: the box is the column its first digit is let go in
            steps.append(LessonStep(StepWords(say: "Line them up. Slide the second number until ones are under ones.", hint: "Ones go under ones.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.aligned)], hint: "Ones go under ones.",
                                   explain: "Ones under ones: \(Bs) moves \(abs(s.aligned - s.start)) column\(abs(s.aligned - s.start) == 1 ? "" : "s").",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Slide the second number.") }
                                       let at = Int(x.rounded())
                                       return at == s.aligned ? .right : .wrong(s.slid(at))
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        if let fd = s.first {
            // tap the first place that differs: the box is the place tapped
            let a = BigNumbers.digit(s.A, fd), b = BigNumbers.digit(s.B, fd)
            steps.append(LessonStep(StepWords(say: "Tap the first place that differs.", hint: "Start from the left.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(fd)], hint: "Start from the left.",
                                   explain: "\(a) \(BigNumbers.place(fd, a)) and \(b) \(BigNumbers.place(fd, b)).",
                                   check: { v in
                                       guard let x = v["x"] else { return .soft("Tap the first place that differs.") }
                                       let pw = Int(x.rounded())
                                       return pw == fd ? .right : .wrong(s.tapped(pw))
                                   }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        // the sign: <, = or >
        let hint = s.first.map { fd in
            let a = BigNumbers.digit(s.A, fd), b = BigNumbers.digit(s.B, fd)
            return "\(a) \(BigNumbers.place(fd, a)) and \(b) \(BigNumbers.place(fd, b))."
        } ?? "Look at each place, from the left."
        steps.append(LessonStep(StepWords(say: "Tap <, = or >.", hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.text(As), .box("s"), .text(Bs)], expected: ["s": Double(s.sign)], hint: hint,
                               explain: "\(As) \(s.signText) \(Bs)",
                               check: { v in
                                   guard let x = v["s"] else { return .soft("Tap <, = or >.") }
                                   let k = Int(x.rounded())
                                   return k == s.sign ? .right : .wrong(s.signed(k))
                               }, byHand: true),
            picture: ["at": 3]))
        steps.append(LessonStep(StepWords(say: s.first == nil ? "Every place matches, so they’re equal." : "The first place that differs decides.",
                                          hint: "Line them up by place. The first place that differs, from the left, decides.", action: "Next problem"),
                                picture: ["at": 4]))
        return steps
    }
}
