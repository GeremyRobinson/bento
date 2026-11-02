import Foundation

/// Points on a grid (g5-coord, 5.G.1–2; design/grade5.md "Added 1 Nov 2026", the preview G approved on 1 Nov:
/// design/prototype/new5-lessons.html, dCoord). One step is one block (5 squares): the paper's own strong lines are the
/// coordinate grid, 10 across and 7 up, only the two edges drawn with their numbers.
///
/// Numbers: a (across, 1 to 10), b (up, 1 to 7), never the same, so a swap is always caught; "kind" (0 plot, 1 read),
/// the two kinds taking turns down a run (the How to and the first problem plot, the next reads, and so on); "name"
/// (which letter names the point, an index into `letters`).
///
/// **Plot** `A (a, b)`, written in the record: 1. drag the dot from 0 along the bottom (it snaps to the squares, the
/// count lit under it, "4 across"), let go on a; 2. drag it up, "2 up", let go on b. A count of the other number says
/// so ("That's 3 across. The first number, 5, is how far across."); any other count says how far it went.
/// **Read** a point A: 1. drag A straight down, a dashed line following it to the bottom numbers (it lights a); 2. drag
/// it across to the side (it lights b); 3. write `A ( [a] , [b] )`, the swap caught first.
///
/// Picture keys: "at", the stage: plot 0 the question, 1 across, 2 up, 3 done; read 0 the question, 1 down, 2 across to
/// the side, 3 write, 4 done. A hint lights "ring" (the number to reach, ringed).
public enum PointsOnGrid {
    /// The letters a point is named by (none that reads like a number or another letter: no I, J, L, O, Q, S…).
    public static let letters = Array("ABCDEFGHKMPRT").map(String.init)
    /// The grid: 10 across, 7 up.
    public static let across = 10, up = 7

    public static func numbers(a: Int, b: Int, read: Bool, name: Int = 0) -> Numbers {
        ["a": Double(a), "b": Double(b), "kind": read ? 1 : 0, "name": Double(name)]
    }

    /// A problem's parts, all from its numbers.
    public struct Parts: Sendable {
        public let a: Int, b: Int, read: Bool, name: String
        public init(_ n: Numbers) {
            a = min(across, max(0, Int((n["a"] ?? 1).rounded())))
            b = min(up, max(0, Int((n["b"] ?? 2).rounded())))
            read = (n["kind"] ?? 0) >= 0.5
            let i = Int((n["name"] ?? 0).rounded())
            name = letters[min(letters.count - 1, max(0, i))]
        }
        /// "(5, 3)"
        public var pair: String { "(\(a), \(b))" }
    }

    /// What letting the dot go `n` across says (plot, step 1): right at a; the other number caught first.
    public static func acrossVerdict(_ x: Double?, _ p: Parts) -> Verdict {
        guard let x, x > 0 else { return .soft("Drag the dot along the bottom.") }
        let n = Int(x.rounded())
        if n == p.a { return .right }
        if n == p.b { return .wrong("That’s \(p.b) across. The first number, \(p.a), is how far across.") }
        return .wrong("That’s \(n) across. Count \(p.a) along the bottom.")
    }

    /// What letting it go `n` up says (plot, step 2).
    public static func upVerdict(_ y: Double?, _ p: Parts) -> Verdict {
        guard let y, y > 0 else { return .soft("Now drag it up.") }
        let n = Int(y.rounded())
        if n == p.b { return .right }
        if n == p.a { return .wrong("That’s \(p.a) up. The second number, \(p.b), is how far up.") }
        return .wrong("That’s \(n) up. Count \(p.b) up.")
    }

    /// What the written pair says (read, step 3): the swap first, then whichever number is off.
    public static func pairVerdict(_ v: [String: Double], _ p: Parts) -> Verdict {
        guard let x = v["x"], let y = v["y"] else { return .soft("Fill in both boxes.") }
        let X = Int(x.rounded()), Y = Int(y.rounded())
        if x == x.rounded(), y == y.rounded(), X == p.a, Y == p.b { return .right }
        if X == p.b && Y == p.a { return .wrong("Across comes first: the number under it, then the one beside it.") }
        if X != p.a || x != x.rounded() { return .wrong("\(p.name) is above \(p.a) on the bottom line.") }
        return .wrong("\(p.name) is level with \(p.b) on the side.")
    }

    public static let spec = LessonSpec(id: "g5-coord", title: "Points on a grid", master: "grid", generate: { rng, index in
        // the two kinds take turns down a run: plot first
        var a = 1, b = 1
        repeat { a = Int.random(in: 1...across, using: &rng); b = Int.random(in: 1...up, using: &rng) } while a == b
        return numbers(a: a, b: b, read: index % 2 == 1, name: Int.random(in: 0..<letters.count, using: &rng))
    }, display: { n in
        let p = Parts(n)
        // a point to read is asked, never given away on its card
        if p.read { return [.text("Where is \(p.name)?")] }
        return [.text(p.name), .text("("), .num(Double(p.a)), .text(","), .num(Double(p.b)), .text(")")]
    },
    idea: { _ in "The first number is how far across, the second how far up. Across always comes first." },
    depends: ["g4-lines"],
    check: [CheckItem(4), CheckItem(3), CheckItem(4, when: { Parts($0).a > Parts($0).b }), CheckItem(3, when: { Parts($0).a < Parts($0).b })]) { n in
        let p = Parts(n), a = p.a, b = p.b, A = p.name
        let why = "Across always comes first."

        if !p.read {
            // plot A (a, b): the pair is written in the record; the dot walks along the bottom, then up
            let ask = LessonStep(StepWords(say: "Put \(A) at \(p.pair).", hint: "The first number is how far across.", action: "Let’s find out"),
                                 picture: ["at": 0])
            let first = LessonStep(StepWords(say: "Put \(A) at \(p.pair). Drag the dot along the bottom. The first number is how far across.",
                                             hint: "Count \(a) along the bottom.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(a)],
                                   hint: "The first number, \(a), is how far across.", explain: "\(a) across, along the bottom.",
                                   check: { v in acrossVerdict(v["x"], p) }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1])
            let second = LessonStep(StepWords(say: "Now drag it up. The second number is how far up.", hint: "Count \(b) up.", action: "Check"),
                answer: AnswerTask(prompt: [.box("y")], expected: ["y": Double(b)],
                                   hint: "The second number, \(b), is how far up.", explain: "\(b) up, from \(a) on the bottom.",
                                   check: { v in upVerdict(v["y"], p) }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1])
            let done = LessonStep(StepWords(say: "\(a) across, then \(b) up. \(why)",
                                            hint: "The first number is how far across, the second how far up.", action: "Next problem"),
                                  picture: ["at": 3])
            return [ask, first, second, done]
        }

        // read A: dragged down to the bottom numbers, then across to the side, then written as a pair
        let ask = LessonStep(StepWords(say: "Where is \(A)?", hint: "Drag \(A) down to the numbers.", action: "Let’s find out"),
                             picture: ["at": 0])
        let down = LessonStep(StepWords(say: "Where is \(A)? Drag \(A) straight down to the numbers.", hint: "Slide it all the way to the bottom line.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 0],
                               hint: "The number under \(A) is how far across.", explain: "Under \(A) is \(a).",
                               check: { v in (v["x"] ?? 1) < 0.4 ? .right : .soft("Drag it all the way down to the numbers.") }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])
        let side = LessonStep(StepWords(say: "Now drag \(A) across to the side.", hint: "Slide it all the way to the side line.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": 0],
                               hint: "The number beside \(A) is how far up.", explain: "Beside \(A) is \(b).",
                               check: { v in (v["x"] ?? 1) < 0.4 ? .right : .soft("Drag it all the way across to the numbers.") }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1])
        let write = LessonStep(StepWords(say: "Write where it is. Across first, then up.", hint: "The number under it, then the one beside it.", action: "Check"),
            answer: AnswerTask(prompt: [.text(A), .text("("), .box("x"), .text(","), .box("y"), .text(")")], expected: ["x": Double(a), "y": Double(b)],
                               hint: "The number under it, then the one beside it.", explain: "\(A) is \(a) across and \(b) up.",
                               check: { v in pairVerdict(v, p) }, incomplete: "Fill in both boxes."),
            picture: ["at": 3], onMiss: ["ring": 1])
        let done = LessonStep(StepWords(say: "\(A) is \(a) across and \(b) up. \(why)",
                                        hint: "The first number is how far across, the second how far up.", action: "Next problem"),
                              picture: ["at": 4])
        return [ask, down, side, write, done]
    }
}
