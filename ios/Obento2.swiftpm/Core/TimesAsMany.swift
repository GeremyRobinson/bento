import Foundation

/// Times as many (g4-times, 4.OA.1, 4.OA.2; design/grade4.md chapter 2, the preview design/prototype/grade4-ch2.html).
/// One square is a centimeter of ribbon. Red is r squares; Blue is m times as long (B = m × r), or, for "longer",
/// k squares longer (B = r + k). Four kinds: find the big one (drag out copies of Red), find the small one (cut Blue with
/// the ruler into equal parts; the first slides up into Red), how many times (hop Red along Blue), and longer or times
/// (drag Blue's end a square at a time). The first three problems are the first three kinds; after that they take turns.
///
/// Every step's picture has "at": 0 the question, 1 the move, 2 write it, 3 done.
public enum TimesAsMany {
    public static func numbers(kind: Int, r: Int, m: Int, k: Int = 0, longer: Bool = false) -> Numbers {
        ["kind": Double(kind), "r": Double(r), "m": Double(m), "k": Double(k), "lg": longer ? 1 : 0]
    }

    public struct Parts: Sendable {
        /// 0 the big one, 1 the small one, 2 how many times, 3 longer or times.
        public let kind: Int, r: Int, m: Int, k: Int
        /// Kind 3 asks "k cm longer" (else "m times as long").
        public let lg: Bool
        public init(_ n: Numbers) {
            kind = Int((n["kind"] ?? 0).rounded()); r = Int((n["r"] ?? 2).rounded()); m = Int((n["m"] ?? 2).rounded())
            k = Int((n["k"] ?? 0).rounded()); lg = (n["lg"] ?? 0) != 0
        }
        /// Blue's length.
        public var B: Int { lg ? r + k : m * r }
        /// What the box asks for: Red's length (the small one), how many times, or Blue's length.
        public var answer: Int { kind == 1 ? r : kind == 2 ? m : B }
        /// Blue is made of copies of Red.
        public var timesLike: Bool { kind == 0 || (kind == 3 && !lg) }
        /// The part sizes the ruler snaps to: every size that divides Blue (1 to B − 1).
        public var divisors: [Int] { (1..<max(2, B)).filter { B % $0 == 0 } }
        /// "half", "a third", "a fourth".
        public var part: String { m == 2 ? "half" : "a \(TimesAsMany.parts[m] ?? "part")" }

        /// The question (the preview's first line).
        public var question: String {
            switch kind {
            case 0: "Make Blue \(m) times as long as Red."
            case 1: "Blue is \(m) times as long as Red. Find Red."
            case 2: "How many times as long as Red is Blue?"
            default: lg ? "Make Blue \(k) cm longer than Red." : "Make Blue \(m) times as long as Red."
            }
        }
        /// What the hands do (the preview's second line, folded into the instruction).
        public var move: String {
            switch kind {
            case 0: "Drag out copies of Red."
            case 1: "Drag the ruler to cut Blue into equal parts."
            case 2: "Hop Red along Blue."
            default: "Drag Blue’s end a square at a time."
            }
        }
        /// The last words: why.
        public var why: String {
            switch kind {
            case 0: "\(m) copies of Red make Blue."
            case 1: "Blue is \(m) Reds, so Red is \(part) of it."
            case 2: "Red fits in Blue \(m) times."
            default: "Longer adds on; times makes copies."
            }
        }

        /// What a move let go at `x` says (the copies dragged out, the parts cut, the hops made, Blue's length): nil when
        /// it's right.
        public func moved(_ x: Int) -> String? {
            switch kind {
            case 0:
                if x == m { return nil }
                return x == 1 ? "That’s as long as Red. Blue needs \(m) copies of Red." : "That’s \(x) times as long. Blue needs \(m) copies of Red."
            case 1:
                return x == m ? nil : "That’s \(x) parts. Blue is \(m) times Red: \(m) parts."
            case 2:
                if x * r > B { return "That’s past \(B)." }
                return x == m ? nil : "\(B - x * r) left on Blue: hop on to its end."
            default:
                if x == B { return nil }
                let whole = x % r == 0, j = x / r
                if lg { return whole ? "That’s \(j) times Red. \(k) longer adds \(k) squares." : "That’s Red + \(x - r). \(k) longer adds \(k) squares." }
                return whole ? "That’s \(j) times Red. \(m) times as long makes \(m) copies." : "\(m) times as long makes \(m) copies."
            }
        }
    }
    static let parts = [2: "half", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 7: "seventh", 8: "eighth", 9: "ninth"]

    /// The preview's generator: Red 2–9; times 2–6 with Blue up to 30 for the first three, then 2–9 with Blue up to 60.
    /// The first three find the big one, the small one, then how many times; after that the four kinds take turns.
    /// "Longer" adds 3–12, never a whole number of Reds (then "longer" and "times" would land on the same length).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let kind = index < 3 ? index : index % 4
        let (mhi, most) = index < 3 ? (6, 30) : (9, 60)
        while true {
            let r = Int.random(in: 2...9, using: &rng), m = Int.random(in: 2...mhi, using: &rng)
            if kind == 3 && Bool.random(using: &rng) {
                let k = Int.random(in: 3...12, using: &rng)
                if k % r == 0 { continue }
                return numbers(kind: 3, r: r, m: 0, k: k, longer: true)
            }
            if m * r > most { continue }
            if kind == 3 && r + m == m * r { continue }
            return numbers(kind: kind, r: r, m: m)
        }
    }

    public static let spec = LessonSpec(id: "g4-times", title: "Times as many", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in
            let s = Parts(n)
            switch s.kind {
            case 1: return [.num(Double(s.B)), .op("÷"), .num(Double(s.m))]
            case 2: return [.num(Double(s.B)), .op("÷"), .num(Double(s.r))]
            default: return s.lg ? [.num(Double(s.r)), .op("+"), .num(Double(s.k))] : [.num(Double(s.m)), .op("×"), .num(Double(s.r))]
            }
        },
        idea: { _ in "Times as many makes copies; more than adds on." },
        depends: ["g3-facts", "g3-divfacts"],
        check: [CheckItem(0), CheckItem(1), CheckItem(2), CheckItem(3)]) { n in
        let s = Parts(n), m = s.m, r = s.r, k = s.k, B = s.B
        let ask = LessonStep(StepWords(say: s.question, hint: s.move, action: "Let’s find out"), picture: ["at": 0])

        // the move: its box is what it was let go at (copies, parts, hops, Blue's length)
        let hint = s.kind == 0 ? "Blue needs \(m) copies of Red." : s.kind == 1 ? "Blue is \(m) equal parts." : s.kind == 2 ? "Each hop is \(r)." : s.lg ? "\(k) longer adds \(k) squares." : "\(m) times as long makes \(m) copies."
        let move = LessonStep(StepWords(say: "\(s.question) \(s.move)", hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.kind == 3 ? B : m)], hint: hint,
                               explain: s.why,
                               check: { v in
                                   guard let x = v["x"] else { return .soft(s.move) }
                                   return s.moved(Int(x.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])

        // write it, with the preview's slips
        let ans = Double(s.answer)
        let prompt: MathLine, known: [(values: [String: Double], message: String)], generic: String, say: String, whint: String
        if s.timesLike {
            prompt = [.text("Blue"), .op("="), .num(Double(m)), .op("×"), .num(Double(r)), .op("="), .box("x")]
            known = BigNumbers.slips(ans, [(Double(m + r), "That’s \(m) + \(r). \(m) times as long makes \(m) copies of \(r)."),
                                           (Double((m - 1) * r), "That’s \(m - 1) copies. Blue is \(m) copies of \(r)."),
                                           (Double((m + 1) * r), "That’s \(m + 1) copies. Blue is \(m) copies of \(r).")])
            generic = "Count Blue’s squares: \(m) copies of \(r)."; say = "Write Blue’s length."; whint = "\(m) copies of \(r)."
        } else if s.kind == 1 {
            prompt = [.text("r"), .op("="), .num(Double(B)), .op("÷"), .num(Double(m)), .op("="), .box("x")]
            known = BigNumbers.slips(ans, [(Double(B - m), "That’s \(B) − \(m). Blue is \(m) equal parts: divide."),
                                           (Double(m), "That’s how many parts. Write one part’s length.")])
            generic = "Red is one of the \(m) parts. Count its squares."; say = "Write Red’s length. Red is one part."; whint = "Red is one part."
        } else if s.kind == 2 {
            prompt = [.num(Double(B)), .op("="), .box("x"), .op("×"), .num(Double(r))]
            known = BigNumbers.slips(ans, [(Double(B - r), "That’s \(B) − \(r). Count the hops."),
                                           (Double(B), "That’s Blue’s length. Write how many hops.")])
            generic = "Count the hops: each is \(r)."; say = "Write how many times. Count the hops."; whint = "Count the hops."
        } else {
            prompt = [.text("Blue"), .op("="), .num(Double(r)), .op("+"), .num(Double(k)), .op("="), .box("x")]
            known = BigNumbers.slips(ans, [(Double(k * r), "That’s \(k) times \(r). \(k) longer adds \(k).")])
            generic = "Count Blue’s squares: Red and \(k) more."; say = "Write Blue’s length."; whint = "Red and \(k) more."
        }
        let write = LessonStep(StepWords(say: say, hint: whint, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: ["x": ans], known: known, hint: whint, explain: s.why,
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.answer ? .right : .wrong(generic) },
                               incomplete: "Type the number in the box."),
            picture: ["at": 2])
        let done = LessonStep(StepWords(say: s.why, hint: "Times as many makes copies; more than adds on.", action: "Next problem"), picture: ["at": 3])
        return [ask, move, write, done]
    }
}
