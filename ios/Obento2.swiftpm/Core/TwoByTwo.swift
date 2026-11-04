import Foundation

/// Two-digit times two-digit (the web app's g4-mult2x2, 4.NBT.5; design/grade4.md chapter 2, the preview
/// grade4-ch2.html): a × b, the bigger across and the smaller down, neither a whole ten, so all four parts exist. The
/// web's maths: its generator, its four parts, its slips, its story (a theater's seats).
///
/// On the paper: 5th grade's rectangle, one square a seat, every ten bold, cut both ways. Cut down where the across
/// number's tens end (a handle over the top edge), then across where the down number's tens end (a handle beside the left
/// side); the four parts part a square. Each lights in turn and is written, tens × tens first; then the four are added.
///
/// Every step's picture has "at": 0 the question, 1 the cut down, 2 the cut across, 3 a part ("k" 0–3: tens × tens,
/// tens × ones, ones × tens, ones × ones, across × down), 4 the sum, 5 done.
public enum TwoByTwo {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public static let names = ["tens × tens", "tens × ones", "ones × tens", "ones × ones"]

    public struct Parts: Sendable {
        /// Across (the bigger) and down.
        public let a: Int, b: Int
        public init(_ n: Numbers) { a = Int((n["a"] ?? 12).rounded()); b = Int((n["b"] ?? 11).rounded()) }
        public var t: Int { a / 10 }
        public var u: Int { a % 10 }
        public var s: Int { b / 10 }
        public var v: Int { b % 10 }
        /// Where the cuts go: the tens of each.
        public var T: Int { 10 * t }
        public var S: Int { 10 * s }
        public var total: Int { a * b }
        /// The four parts' sides (across, down) and squares.
        public var sides: [(Int, Int)] { [(T, S), (T, v), (u, S), (u, v)] }
        public var values: [Int] { sides.map { $0.0 * $0.1 } }
        /// What each part holds, counted: "6 hundreds", "18 tens", "24 ones".
        public var counts: [String] {
            [t * s == 1 ? "1 hundred" : "\(t * s) hundreds", TwoByTwo.tens(t * v), TwoByTwo.tens(u * s), u * v == 1 ? "1 one" : "\(u * v) ones"]
        }
        public var story: String { "A theater has \(b) rows of \(a) seats. How many seats are there?" }
    }
    static func tens(_ n: Int) -> String { n == 1 ? "1 ten" : "\(n) tens" }

    /// How big the preview shows a × b on the iPad's screen (its planMult2): the record beside the rectangle or under it,
    /// its words once or twice as big (k 1 or 2), whichever shows the rectangle biggest with its words at least 20
    /// points. The biggest problems are drawn again when that's under 55% (it drops some of 9_ × 4_).
    public static func shown(a: Int, b: Int) -> Double {
        let total = a * b, nd = Double(String(total).count)
        // the iPad's landscape screen, clear of the bar (the preview's viewScale), in squares
        let W = (1180.0 - 64) / 20, H = (820.0 - 166) / 20
        var best: [(s: Double, pt: Double)] = []
        for K in [1.0, 2.0] {
            for beside in [true, false] {
                let x0 = 5 * K, top = 10 * K, recW = (3 + 2 * nd + 2 + 11) * K, recH = 14 * K
                var right: Double, bottom: Double
                if beside {
                    let rx = ((x0 + Double(a) + 1 + 3 * K) / 5).rounded(.up) * 5
                    right = rx + recW; bottom = max(top + Double(b) + 2, top + recH)
                } else {
                    right = max(x0 + Double(a) + 1 + 2 * K, recW); bottom = top + Double(b) + 1 + 3 * K + recH
                }
                right = max(right, 34 * 0.75 * K)
                let s = min(W / (right + 4), H / (bottom + 3), 1.25)
                best.append((s, 28 * K * s))
            }
        }
        if let ok = best.filter({ $0.pt >= 20 }).max(by: { $0.s < $1.s }) { return ok.s }
        return best.max { $0.pt < $1.pt }!.s
    }

    /// The web's generator: index < 3 a 11–29 and b 11–19, then 12–99 and 12–49, never a whole ten; the bigger goes
    /// across; drawn again while the preview would show it smaller than 55%.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        func nt(_ lo: Int, _ hi: Int) -> Int { while true { let v = Int.random(in: lo...hi, using: &rng); if v % 10 != 0 { return v } } }
        while true {
            let (x, y) = index < 3 ? (nt(11, 29), nt(11, 19)) : (nt(12, 99), nt(12, 49))
            let a = max(x, y), b = min(x, y)
            if shown(a: a, b: b) >= 0.55 { return numbers(a: a, b: b) }
        }
    }

    public static let spec = LessonSpec(id: "g4-mult2x2", title: "Two-digit times two-digit", master: "area-model",
        generate: { rng, index in make(&rng, index) },
        display: { n in let s = Parts(n); return [.num(Double(s.a)), .op("×"), .num(Double(s.b))] },
        idea: { _ in "Each number is tens plus ones, so the big rectangle cuts into four easy pieces." },
        story: { n in Parts(n).story },
        storyOp: { _ in "×" },
        depends: ["g4-partial", "g3-mult10"],
        check: [CheckItem(0), CheckItem(3), CheckItem(3, when: { Parts($0).u >= 5 && Parts($0).v >= 5 }), CheckItem(3, story: true)]) { n in
        let s = Parts(n), t = s.t, u = s.u, sv = s.s, v = s.v
        var steps = [LessonStep(StepWords(say: "How many squares in the rectangle?", hint: "Cut where the tens end.", action: "Let’s find out"), picture: ["at": 0])]
        // the two cuts: each box is where it was let go
        steps.append(LessonStep(StepWords(say: "Cut down where the tens end. Drag the handle along the top.", hint: "\(s.a) is \(s.T) + \(u).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.T)], hint: "\(s.a) is \(s.T) + \(u).", explain: "\(s.a) is \(s.T) + \(u).",
                               check: { v in
                                   guard let x = v["x"] else { return .soft("Drag the handle along the top.") }
                                   return Int(x.rounded()) == s.T ? .right : .wrong("Cut where the tens end.")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1]))
        steps.append(LessonStep(StepWords(say: "Cut across where the tens end. Drag the handle down the side.", hint: "\(s.b) is \(s.S) + \(v).", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.S)], hint: "\(s.b) is \(s.S) + \(v).", explain: "\(s.b) is \(s.S) + \(v).",
                               check: { x in
                                   guard let y = x["x"] else { return .soft("Drag the handle down the side.") }
                                   return Int(y.rounded()) == s.S ? .right : .wrong("Cut across where the tens end.")
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1]))
        // the four parts, with the web's slips
        let P = s.values, ts = t * sv
        let slips: [[(Double, String)]] = [
            [(Double(ts * 10), "Tens times tens makes hundreds: \(t) × \(sv) = \(ts), so \(BigNumbers.commas(P[0]))."),
             (Double(ts), "That’s \(t) × \(sv). Both are tens, so put two zeros on it.")],
            [(Double(t * v), "\(s.T) is \(tens(t)). \(BigNumbers.cap(tens(t))) × \(v) is \(tens(t * v)): \(P[1]).")],
            [(Double(u * sv), "\(s.S) is \(tens(sv)). \(u) × \(tens(sv)) is \(tens(u * sv)): \(P[2]).")],
            [(Double(u + v), "This one is times, not plus."), (Double(P[3] - 1), "You’re 1 away. Skip-count by \(v)s, \(u) times."),
             (Double(P[3] + 1), "You’re 1 away. Skip-count by \(v)s, \(u) times."), (Double(u * (v - 1)), "That’s \(u) × \(v - 1). Skip-count by \(v)s, \(u) times."),
             (Double(u * (v + 1)), "That’s \(u) × \(v + 1). Skip-count by \(v)s, \(u) times.")],
        ]
        let lead = ["Write each part.", "Write the next part.", "Write the next part.", "Write the last part."]
        let look = ["Each bold square is a hundred.", "Each bold strip is ten.", "Each bold strip is ten.", "Count its squares."]
        let hints = ["\(t) × \(sv) = \(ts), and tens times tens is hundreds.", "\(t) × \(v), then one zero.", "\(u) × \(sv), then one zero.",
                     u == 1 ? "Times 1 leaves a number as it is." : "\(u) groups of \(v): skip-count by \(v)s."]
        for k in 0..<4 {
            let (x, y) = s.sides[k], want = P[k], generic = "Count the part: \(s.counts[k])."
            steps.append(LessonStep(StepWords(say: "\(lead[k]) \(look[k])", hint: hints[k], action: "Check"),
                answer: AnswerTask(prompt: [.num(Double(x)), .op("×"), .num(Double(y)), .op("="), .box("x")], expected: ["x": Double(want)],
                                   known: BigNumbers.slips(Double(want), slips[k]), hint: hints[k],
                                   explain: "\(x) × \(y) = \(BigNumbers.commas(want)).",
                                   check: { val in Int((val["x"] ?? -1).rounded()) == want ? .right : .wrong(generic) },
                                   incomplete: "Type the number in the box."),
                picture: ["at": 3, "k": Double(k)]))
        }
        // the sum: the corners only, or a part left out
        let sumSlips = [(Double(P[0] + P[3]), "That’s only the two corners. Add the middle parts too.")]
            + P.enumerated().map { i, x in (Double(s.total - x), "Four parts, four numbers to add. Did you add the \(names[i]) part, \(BigNumbers.commas(x))?") }
        steps.append(LessonStep(StepWords(say: "Add the four parts.", hint: "Line them up by place and add all four.", action: "Check"),
            answer: AnswerTask(prompt: P.enumerated().flatMap { i, x in (i > 0 ? [Math.op("+")] : []) + [.num(Double(x))] } + [.op("="), .box("x")],
                               expected: ["x": Double(s.total)], known: BigNumbers.slips(Double(s.total), sumSlips), hint: "Line them up by place and add all four.",
                               explain: P.map { BigNumbers.commas($0) }.joined(separator: " + ") + " = \(BigNumbers.commas(s.total)).",
                               check: { x in Int((x["x"] ?? -1).rounded()) == s.total ? .right : .wrong("Line them up by place and add all four.") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 4]))
        steps.append(LessonStep(StepWords(say: "Four parts fill the rectangle: \(BigNumbers.commas(s.total)).",
                                          hint: "Each number is tens plus ones, so the big rectangle cuts into four easy pieces.", action: "Next problem"),
                                picture: ["at": 5]))
        return steps
    }
}
