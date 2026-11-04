import Foundation

/// Reading and writing big numbers (g4-readwrite, 4.NBT.2; design/grade4.md, the preview grade4-ch1.html). A number N
/// from 1,000 to 999,999. Two kinds take turns: A gives its name ("forty thousand, six hundred five") and the child
/// builds it in the place chart; B gives its digits (305,280) and the child writes it in expanded form.
///
/// On the paper: the whole place chart, six columns. A: tap a column to put a disk in (a disk is one of its column's
/// place), tap a disk to take it out; the number built is named under the chart; Check. B: the digits under their disks;
/// pull each digit down out of the chart: zeros follow it from every place to its right, and it lands in the record as
/// its value (300,000 + 5,000 + 200 + 80).
///
/// Every step's picture has "at": 0 the question, 1 the move, 2 done.
public enum ReadWriteBig {
    public static func numbers(kind: Int, N: Int) -> Numbers { ["kind": Double(kind), "N": Double(N)] }

    public struct Parts: Sendable {
        /// 0: A (name to number), 1: B (number to expanded form).
        public let kind: Int, N: Int
        public var a: Bool { kind == 0 }
        public var length: Int { BigNumbers.length(N) }
        public func digit(_ k: Int) -> Int { BigNumbers.digit(N, k) }
        /// The places with a digit that isn't 0, from the biggest: the parts of the expanded form.
        public var parts: [Int] { (0..<length).reversed().filter { digit($0) != 0 } }
        /// A part's value: 300,000.
        public func value(_ k: Int) -> Int { digit(k) * BigNumbers.pow10(k) }
        /// The expanded form: 300,000 + 5,000 + 200 + 80.
        public var expanded: String { parts.map { BigNumbers.commas(value($0)) }.joined(separator: " + ") }
        public var name: String { BigNumbers.name(N) }
        public init(_ n: Numbers) { kind = Int((n["kind"] ?? 0).rounded()); N = Int((n["N"] ?? 1000).rounded()) }

        /// What a wrong build is told (the preview's): what it reads, and the first place that's off. The number built is
        /// `b`.
        public func built(_ b: Int) -> String {
            let reads = "That reads \(BigNumbers.name(b))."
            if let k = (0..<6).reversed().first(where: { BigNumbers.digit(b, $0) != digit($0) && digit($0) != 0 }) {
                let d = digit(k)
                return "\(reads) \(BigNumbers.cap(BigNumbers.name(d * BigNumbers.pow10(k)))) is \(d) \(BigNumbers.place(k, d))."
            }
            let k = (0..<6).reversed().first { BigNumbers.digit(b, $0) != digit($0) } ?? 0
            return "\(reads) \(BigNumbers.cap(name)) has no \(BigNumbers.places[k])."
        }
    }

    /// The preview's generator: A and B take turns; the first three have four digits and no 0; then five or six digits,
    /// half the time with a 0 inside (40,605: the traps are 4,605 and 400,605).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index % 2, L = index < 3 ? 4 : Int.random(in: 5...6, using: &rng)
        let zero = index >= 3 && Bool.random(using: &rng)
        while true {
            var d = (0..<L).map { _ in Int.random(in: 1...9, using: &rng) }
            if zero {
                for _ in 0..<Int.random(in: 1...2, using: &rng) { d[Int.random(in: 1...(L - 1), using: &rng)] = 0 }
                // a 0 inside the number, not only at its end
                guard d[1..<(L - 1)].contains(0) else { continue }
            }
            return numbers(kind: kind, N: d.reduce(0) { $0 * 10 + $1 })
        }
    }

    /// A 0 inside the number (not counting its ones).
    public static func zeroInside(_ N: Int) -> Bool { let s = Array(String(N)); return s.count > 2 && s[1..<(s.count - 1)].contains("0") }

    public static let spec = LessonSpec(id: "g4-readwrite", title: "Reading and writing big numbers", master: "place-chart",
        generate: { rng, index in make(&rng, index) },
        display: { n in
            let s = Parts(n)
            // a name is too long for a problem's card (up to three rows): the card says what to do, the name is on the paper
            return s.a ? [.text("Build the number")] : [.text(BigNumbers.commas(s.N)), .op("="), .text("?")]
        },
        idea: { _ in "Each digit is worth its place, and an empty place still needs its 0." },
        depends: ["g4-tentimes"],
        check: [CheckItem(4, when: { zeroInside(Parts($0).N) }), CheckItem(3, when: { Parts($0).length == 6 }),
                CheckItem(4, when: { Parts($0).length == 6 }), CheckItem(5, when: { zeroInside(Parts($0).N) })]) { n in
        let s = Parts(n)
        let ask = LessonStep(StepWords(say: s.a ? "Build the number." : "Write it as its parts.",
                                       hint: s.a ? "Tap a column to put a disk in." : "Each digit is worth its place.", action: "Let’s find out"),
                             picture: ["at": 0])
        let move: LessonStep
        if s.a {
            // the build: the box holds the number built; Check checks it
            move = LessonStep(StepWords(say: "Build the number. Tap a column to put a disk in.", hint: "Tap a disk to take it out.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.N)], hint: "Tap a disk to take it out.",
                                   explain: "\(BigNumbers.cap(s.name)) is \(BigNumbers.commas(s.N)).",
                                   check: { v in
                                       let b = Int((v["x"] ?? 0).rounded())
                                       if b <= 0 { return .soft("Tap a column to put a disk in.") }
                                       return b == s.N ? .right : .wrong(s.built(b))
                                   }, incomplete: "Tap a column to put a disk in.", byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        } else {
            // each digit pulled: the box counts them; a 0 won't come, and one let go too soon goes back
            let want = s.parts.count
            move = LessonStep(StepWords(say: "Pull each digit down, out of the chart.", hint: "It brings its zeros.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(want)], hint: "It brings its zeros.",
                                   explain: "\(BigNumbers.commas(s.N)) = \(s.expanded)",
                                   check: { v in
                                       let x = Int((v["x"] ?? 0).rounded())
                                       if x == want { return .right }
                                       if x == -100 { return .soft("Drag it down, below the chart.") }
                                       if x < 0, -x - 1 < 6 { return .soft("0 \(BigNumbers.places[-x - 1]) is nothing. Leave it.") }
                                       return .soft("Pull each digit down.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let done = LessonStep(StepWords(say: s.a ? "An empty place still needs its 0." : "Each digit is worth its place.",
                                        hint: "Each digit is worth its place, and an empty place still needs its 0.", action: "Next problem"),
                              picture: ["at": 2])
        return [ask, move, done]
    }
}
