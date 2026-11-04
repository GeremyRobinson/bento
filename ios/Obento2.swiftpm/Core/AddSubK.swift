import Foundation

/// What Kindergarten's Add and take away chapter shares (design/gradeK.md chapter 4, the preview
/// design/prototype/gradeK-ch4.html): one block is one cube (or one thing in a story, a counter), the ten track is K's
/// number line, the second amount is striped, and every number is tapped on the number row (0–10), never typed. Every
/// line here is also spoken (App's Voice).
public enum AddSubK {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// The first wrong-answer line that fits (the web's slips, in order: never the answer, 0–10 only), else `other`.
    static func slip(_ v: Int, _ ans: Int, _ list: [(Int, String)], _ other: String) -> String {
        list.first { $0.0 == v && $0.0 != ans && (0...10).contains($0.0) }?.1 ?? other
    }
    /// The slips a step names for the number row (what the engine checks first): the ones that can be tapped.
    static func known(_ ans: Int, _ list: [(Int, String)]) -> [(Int, String)] {
        var seen: Set<Int> = []
        return list.filter { $0.0 != ans && (0...10).contains($0.0) && seen.insert($0.0).inserted }
    }
    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : .wrong(said(x)) }, byHand: true)
    }
}

// MARK: - Adding within 10

/// Adding within 10 (the web's k-add, K.OA.A.1, 2, 5). One block is one cube. The ten track with a train of a cubes
/// from the start line, named at its right end; above it on the right a striped train of b. Slide the striped train on
/// right after the first; count on from a (a hop over each new cube, the a on the first train's last cube); write
/// a + b on the number row.
///
/// "at": 0 slide, 1 count on, 2 write, 3 done. The count step's box: b once every new cube is counted, or a code for a
/// tap that's wrong (−1 a cube of the first train, −2 one counted already, −3 one out of order).
public enum AddK {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(1, min(9, AddSubK.int(x, "a", 1))); b = max(1, min(10 - a, AddSubK.int(x, "b", 1))) }
        public var sum: Int { a + b }
        public var slid: String { "Put them right after the \(a)." }
        public func counted(_ code: Int) -> String {
            switch code {
            case -1: "Start after the \(a): tap the striped cubes."
            case -2: "You counted that one."
            default: "Count them in order, from the \(a)."
            }
        }
        public var slips: [(Int, String)] {
            [(sum + 1, "One too many. Start after \(a): say \(a + 1) for the first new cube."), (sum - 1, "One short. Count every new cube once.")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, sum, slips, "That’s \(v). Start at \(a) and count on \(b).") }
        public var why: String { "Start at \(a) and count on, one number for each new cube." }
    }
    /// The web's generator as it is (a 1–5, b 1–5, a + b 10 at most; the first three a 1–3 and b 1–2).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let a = i < 3 ? Int.random(in: 1...3, using: &rng) : Int.random(in: 1...5, using: &rng)
        return numbers(a: a, b: Int.random(in: 1...(i < 3 ? 2 : min(5, 10 - a)), using: &rng))
    }

    public static let spec = LessonSpec(id: "k-add", title: "Adding within 10", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("+"), .num(Double(P.b))] },
        idea: { _ in "To add, start with the first group and count on." },
        depends: ["gk-onemore", "gk-count10"],
        check: [CheckItem(3, when: { Parts($0).b >= 3 }), CheckItem(3, when: { Parts($0).a < Parts($0).b }),
                CheckItem(3, when: { Parts($0).sum >= 7 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let slide = LessonStep(StepWords(say: "Slide them on.", hint: P.slid, action: "Check"),
            answer: AnswerTask(prompt: [.box("l")], expected: ["l": 0], hint: P.slid, explain: "They go right after the \(P.a).",
                               check: { v in Int((v["l"] ?? 9).rounded()) == 0 ? .right : .wrong(P.slid) }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Say \(P.a + 1) for the first striped cube."
        let count = LessonStep(StepWords(say: "Count on.", hint: countHint, action: "Check"),
            answer: AddSubK.hand("n", P.b, hint: countHint, explain: "\(P.a), then \((P.a + 1...P.sum).map(String.init).joined(separator: ", ")).", said: P.counted),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "The last number you said is how many in all."
        let write = LessonStep(StepWords(say: "Write how many in all.", hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.sum, known: AddSubK.known(P.sum, P.slips), other: { P.wrote($0) }, hint: writeHint, explain: "\(P.a) + \(P.b) = \(P.sum)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [slide, count, write, done]
    }
}

// MARK: - Taking away within 10

/// Taking away within 10 (the web's k-sub, K.OA.A.1, 2, 5). One block is one cube. The ten track with a train of a
/// cubes, named at its right end; 2 blocks under it an empty strip. Each tap takes the train's last cube: it drops into
/// the strip under its block, crossed out. Count what's left (none left: said with the write); write a − b.
///
/// "at": 0 take, 1 count, 2 write, 3 done. The count step's box: what's left once each is counted, or −1 one counted
/// already, −2 a crossed-out one tapped.
public enum TakeAwayK {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(1, min(10, AddSubK.int(x, "a", 2))); b = max(1, min(a, AddSubK.int(x, "b", 1))) }
        public var left: Int { a - b }
        public var takeSay: String { "Take \(b) away." }
        public func took(_ n: Int) -> String { "That’s \(n) away. Take \(b)." }
        public func counted(_ code: Int) -> String { code == -2 ? "That one is taken away." : "You counted that one." }
        public var writeSay: String { left == 0 ? "None left. Write how many are left." : "Write how many are left." }
        public var slips: [(Int, String)] {
            [(a + b, "That’s \(a) and \(b) put together. Taking away leaves fewer than \(a)."),
             (b, "\(b) is how many you took away. Count the cubes still on the track."),
             (a, "That’s how many you started with."),
             (left + 1, "One too many. Skip the crossed-out cubes when you count."),
             (left - 1, "One short. Count every cube still on the track.")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, left, slips, "That’s \(v). Count the cubes still on the track.") }
        public static let why = "Taking away leaves fewer: count only what's still there."
    }
    /// The web's generator as it is (the first three a 2–5, b 1 to a − 1, so at least one is left; after that a 4–10, b
    /// 1 to a, so none left can come up).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let a = Int.random(in: (i < 3 ? 2 : 4)...(i < 3 ? 5 : 10), using: &rng)
        return numbers(a: a, b: Int.random(in: 1...(i < 3 ? a - 1 : a), using: &rng))
    }

    public static let spec = LessonSpec(id: "k-sub", title: "Taking away within 10", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("−"), .num(Double(P.b))] },
        idea: { _ in "To take away, cross some out and count the rest." },
        depends: ["k-add", "gk-count10"],
        check: [CheckItem(3, when: { Parts($0).b >= 4 }), CheckItem(3, when: { (1...2).contains(Parts($0).left) }),
                CheckItem(3, when: { Parts($0).left == 0 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let takeHint = "Tap the train \(P.b == 1 ? "once" : "\(P.b) times")."
        let take = LessonStep(StepWords(say: P.takeSay, hint: takeHint, action: "Check"),
            answer: AddSubK.hand("t", P.b, hint: takeHint, explain: "\(P.b) taken away.", said: P.took),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Tap each cube still on the track."
        let count = LessonStep(StepWords(say: "Count what's left.", hint: countHint, action: "Check"),
            answer: AddSubK.hand("n", P.left, hint: countHint, explain: "\(P.left) left.", said: P.counted),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Count only the cubes still on the track."
        let write = LessonStep(StepWords(say: P.writeSay, hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.left, known: AddSubK.known(P.left, P.slips), other: { P.wrote($0) }, hint: writeHint, explain: "\(P.a) − \(P.b) = \(P.left)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return P.left == 0 ? [take, write, done] : [take, count, write, done]
    }
}

// MARK: - Story problems within 10

/// Story problems within 10 (the web's k-story, K.OA.A.2; put together folded in). One block is one thing in the story,
/// a counter on the ten track. The story's sentences are the instructions: the first two together (the counters go on
/// as the first is read), with "More than 5" and "Fewer than 5" under the track; then the second while the hand acts it
/// out (tap them off, or slide the striped ones on); then the third, and the sentence is written on the number row.
///
/// "at": 0 pick, 1 act, 2 write, 3 done. Tale 0 "Mia has 5 apples.", 1 "5 apples are on the table.", 2 put together
/// ("Leo has 2 apples.", the next name, adding only).
public enum StoryK {
    public static let names = ["Mia", "Leo", "Ava", "Sam", "Zoe", "Ben"]
    public static let things: [(one: String, many: String)] = [("apple", "apples"), ("crayon", "crayons"), ("sticker", "stickers"),
                                                               ("shell", "shells"), ("block", "blocks"), ("cookie", "cookies")]
    public static func numbers(a: Int, b: Int, take: Bool, who: Int = 0, what: Int = 0, tale: Int = 0) -> Numbers {
        ["a": Double(a), "b": Double(b), "take": take ? 1 : 0, "who": Double(who), "what": Double(what), "tale": Double(tale)]
    }
    public struct Parts: Sendable {
        public let a: Int, b: Int, take: Bool, who: Int, what: Int, tale: Int
        public init(_ x: Numbers) {
            take = AddSubK.int(x, "take") == 1
            a = max(take ? 2 : 1, min(take ? 10 : 9, AddSubK.int(x, "a", 3)))
            b = max(1, min(take ? a - 1 : 10 - a, AddSubK.int(x, "b", 1)))
            who = max(0, min(5, AddSubK.int(x, "who"))); what = max(0, min(5, AddSubK.int(x, "what")))
            tale = take ? min(1, max(0, AddSubK.int(x, "tale"))) : max(0, min(2, AddSubK.int(x, "tale")))
        }
        public var end: Int { take ? a - b : a + b }
        public var name: String { StoryK.names[who] }
        public var name2: String { StoryK.names[(who + 1) % StoryK.names.count] }
        public var many: String { StoryK.things[what].many }
        func n(_ k: Int) -> String { "\(k) \(k == 1 ? StoryK.things[what].one : many)" }
        /// The story's three sentences.
        public var lines: [String] {
            let start = tale == 1 ? "\(n(a)) are on the table." : "\(name) has \(n(a))."
            if take { return [start, tale == 1 ? "\(name) takes \(b) away." : "\(name) gives \(b) away.", "How many \(many) are left?"] }
            if tale == 2 { return [start, "\(name2) has \(n(b)).", "How many \(many) in all?"] }
            return [start, tale == 1 ? "\(name) puts on \(b) more." : "\(name) gets \(b) more.", "How many \(many) now?"]
        }
        /// The two blocks: 0 more, 1 fewer.
        public var choices: [String] { ["More than \(a)", "Fewer than \(a)"] }
        public var want: Int { take ? 1 : 0 }
        public var picked: String {
            take ? "Some \(many) go away, so there will be fewer than \(a)."
                : tale == 2 ? "\(name2)’s \(many) join \(name)’s, so there will be more than \(a)." : "More \(many) come, so there will be more than \(a)."
        }
        public var slid: String { "Put them right after the \(a)." }
        public func took(_ k: Int) -> String { "That’s \(k) away. Take \(b)." }
        var way: String { take ? "back" : "on" }
        public var slips: [(Int, String)] {
            [(take ? a + b : a - b, take ? "Some go away, so the answer is fewer than \(a). Take away \(b)."
                : tale == 2 ? "Put together, the answer is more than \(a). Add \(b)." : "More come, so the answer is more than \(a). Add \(b)."),
             (b, tale == 2 ? "That’s how many \(name2) has. Start at \(a) and count on \(b)." : "That’s how many \(take ? "go away" : "come"). Start at \(a) and count \(way) \(b)."),
             (a, tale == 2 ? "\(a) is how many \(name) has. Now count on \(b)." : "\(a) is the start. Now count \(way) \(b)."),
             (end + 1, "One too many. Count \(way) exactly \(b)."),
             (end - 1, "One short. Count \(way) exactly \(b).")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, end, slips, "That’s \(v). Count the \(many) on the track.") }
        public var why: String { take ? "Some go away, so take away." : tale == 2 ? "Put together, so add." : "More come, so add." }
        public var sign: String { take ? "−" : "+" }
    }
    /// The web's generator as it is (take 0 or 1, two tellings; the first three 6 at most with changes of 3 at most).
    /// New: tale 2, put together (a 2–9, b 1 to 10 − a; the second person is the next name), 1 in 3 of the adding stories
    /// from index 3.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let take = Bool.random(using: &rng), top = i < 3 ? 6 : 10
        let a = take ? Int.random(in: 3...top, using: &rng) : Int.random(in: 2...(top - 1), using: &rng)
        let b = take ? Int.random(in: 1...min(a - 1, i < 3 ? 3 : 10), using: &rng) : Int.random(in: 1...min(top - a, i < 3 ? 3 : 10), using: &rng)
        let who = Int.random(in: 0...5, using: &rng), what = Int.random(in: 0...5, using: &rng), tale = Int.random(in: 0...1, using: &rng)
        if !take && i >= 3 && Int.random(in: 1...3, using: &rng) == 1 {
            let a2 = Int.random(in: 2...9, using: &rng)
            return numbers(a: a2, b: Int.random(in: 1...(10 - a2), using: &rng), take: false, who: who, what: what, tale: 2)
        }
        return numbers(a: a, b: b, take: take, who: who, what: what, tale: tale)
    }

    public static let spec = LessonSpec(id: "k-story", title: "Story problems within 10", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .text("and"), .num(Double(P.b))] },
        idea: { _ in "More coming means add, and some going away means take away." },
        depends: ["k-add", "k-sub"],
        check: [CheckItem(3, when: { !Parts($0).take && Parts($0).tale == 2 }), CheckItem(3, when: { Parts($0).take }),
                CheckItem(3, when: { Parts($0).take && Parts($0).b >= 3 }), CheckItem(3, when: { !Parts($0).take && Parts($0).tale == 1 })]) { x in
        let P = Parts(x), L = P.lines
        let pickHint = P.take ? "Do the \(P.many) come or go away?" : "Do more \(P.many) come, or do some go away?"
        let pick = LessonStep(StepWords(say: "\(L[0]) \(L[1])", hint: pickHint, action: "Check"),
            answer: AddSubK.hand("c", P.want, hint: pickHint, explain: P.take ? "Some go away, so there will be fewer." : "More come, so there will be more.",
                                 said: { _ in P.picked }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let actHint = P.take ? "Tap them \(P.b == 1 ? "once" : "\(P.b) times")." : "Slide them so they start right after the \(P.a)."
        let act = LessonStep(StepWords(say: L[1], hint: actHint, action: "Check"),
            answer: P.take ? AddSubK.hand("t", P.b, hint: actHint, explain: "\(P.b) taken away.", said: P.took)
                : AddSubK.hand("l", 0, hint: actHint, explain: "They go right after the \(P.a).", said: { _ in P.slid }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = P.take ? "Start at \(P.a) and count back \(P.b)." : "Start at \(P.a) and count on \(P.b)."
        let write = LessonStep(StepWords(say: L[2], hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.end, known: AddSubK.known(P.end, P.slips), other: { P.wrote($0) }, hint: writeHint,
                                 explain: "\(P.a) \(P.sign) \(P.b) = \(P.end)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [pick, act, write, done]
    }
}

// MARK: - Number bonds

/// Number bonds (the web's k-bonds, K.OA.A.3; another way folded in). One block is one cube. The bond: the whole's
/// circle over the middle, the parts' circles lower at each side, lines between; the whole's number in its circle, the
/// other part's circle dashed with "?". Under it the train of the whole. Cut it after the first part (the pieces part a
/// square, the other striped); write the other part (it fills the dashed circle); then the pieces join and a cut in
/// another place writes a second way.
///
/// "at": 0 cut, 1 write, 2 another, 3 done. The cut steps' boxes hold where the cut was let go (0 to the whole).
public enum BondsK {
    public static func numbers(whole: Int, part: Int) -> Numbers { ["whole": Double(whole), "part": Double(part)] }
    public struct Parts: Sendable {
        public let whole: Int, part: Int
        public init(_ x: Numbers) { whole = max(2, min(10, AddSubK.int(x, "whole", 5))); part = max(0, min(whole - 1, AddSubK.int(x, "part", 2))) }
        public var rest: Int { whole - part }
        public var cutSay: String { part > 0 ? "Cut after \(part)." : "Cut at the start." }
        public func cut(_ k: Int) -> String { part > 0 ? "That’s \(k). Cut after \(part)." : "That’s \(k). Cut at the start." }
        public var again: String { "That’s \(part) and \(rest) again. Try another place." }
        /// Show me's other place: one along (or one back from the end).
        public var other: Int { part < whole ? part + 1 : part - 1 }
        public var slips: [(Int, String)] {
            [(part, "That’s the first group again. Count the other group."), (whole, "That’s the whole. The other group is smaller."),
             (whole + part, "The parts are smaller than the whole. Count only the other group.")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, rest, slips, "That’s \(v). Count only the striped cubes.") }
        public var why: String { "Cut it anywhere: the two parts make \(whole) again." }
    }
    /// The web's generator as it is (whole 3–5 for the first three, then 4–10; part 1 to whole − 1, and from index 6 a
    /// part of 0 one time in 6).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let whole = i < 3 ? Int.random(in: 3...5, using: &rng) : Int.random(in: 4...10, using: &rng)
        return numbers(whole: whole, part: i >= 6 && Int.random(in: 0...5, using: &rng) == 0 ? 0 : Int.random(in: 1...(whole - 1), using: &rng))
    }

    public static let spec = LessonSpec(id: "k-bonds", title: "Number bonds", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.whole)), .text("is"), .num(Double(P.part)), .text("and ?")] },
        idea: { _ in "A number can break into two parts that make the whole again." },
        depends: ["k-add"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).whole >= 7 }), CheckItem(3, when: { Parts($0).whole >= 7 }),
                CheckItem(3, when: { Parts($0).part > Parts($0).rest })]) { x in
        let P = Parts(x)
        let cutHint = P.part > 0 ? "Count \(P.part) cubes from the start, then cut." : "The cut goes on the start line."
        let cut = LessonStep(StepWords(say: P.cutSay, hint: cutHint, action: "Check"),
            answer: AddSubK.hand("k", P.part, hint: cutHint, explain: "\(P.part) and the rest.", said: P.cut),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Count only the striped cubes."
        let write = LessonStep(StepWords(say: "Write the other part.", hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.rest, known: AddSubK.known(P.rest, P.slips), other: { P.wrote($0) }, hint: writeHint,
                                 explain: "\(P.whole) = \(P.part) + \(P.rest)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let anotherHint = "Cut in a place you haven’t cut."
        let another = LessonStep(StepWords(say: "Find another way.", hint: anotherHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k2")], expected: ["k2": Double(P.other)], hint: anotherHint, explain: "\(P.whole) = \(P.other) + \(P.whole - P.other).",
                               check: { v in let k = Int((v["k2"] ?? -1).rounded()); return k == P.part ? .wrong(P.again) : (0...P.whole).contains(k) ? .right : .wrong(anotherHint) },
                               byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [cut, write, another, done]
    }
}

// MARK: - Make 10

/// Make 10 (the web's k-make10, K.OA.A.4). One cell is 2 × 2 blocks: a big ten frame, its dots 6 squares across in the
/// middle of their cells. Count the dots; fill the frame (a striped dot drops into each empty cell, numbered 1, 2, 3);
/// write have + [ ] = 10.
///
/// "at": 0 count, 1 fill, 2 write, 3 done. The count step's box: have once each is counted, or −1 an empty box, −2 one
/// counted already; the fill step's: how many more once full, or −1 a box with a dot.
public enum MakeTenK {
    public static func numbers(have: Int) -> Numbers { ["have": Double(have)] }
    public struct Parts: Sendable {
        public let have: Int
        public init(_ x: Numbers) { have = max(1, min(9, AddSubK.int(x, "have", 7))) }
        public var need: Int { 10 - have }
        public func counted(_ code: Int) -> String { code == -1 ? "That box is empty. Count the dots." : "You counted that one." }
        public static let full = "That box has a dot."
        public var slips: [(Int, String)] {
            [(10, "10 is the full frame. How many more dots does it need?"), (have, "That’s the dots already there. Count the empty boxes."),
             (need - 1, "Touch every empty box."), (need + 1, "Touch each empty box only once.")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, need, slips, "That’s \(v). Count the striped dots.") }
        public static let why = "The frame holds 10, so the empty boxes are how many more."
    }
    /// The web's generator as it is (have 1–9; the first three 6–9).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers { numbers(have: Int.random(in: (i < 3 ? 6 : 1)...9, using: &rng)) }

    public static let spec = LessonSpec(id: "k-make10", title: "Make 10", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).have)), .op("+"), .text("?"), .op("="), .num(10)] },
        idea: { _ in "A ten frame holds 10, so the empty boxes show how many more you need." },
        depends: ["k-bonds"],
        check: [CheckItem(3, when: { Parts($0).have <= 4 }), CheckItem(3, when: { (5...7).contains(Parts($0).have) }),
                CheckItem(3, when: { Parts($0).have >= 8 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let countHint = "Tap each dot once."
        let count = LessonStep(StepWords(say: "Count the dots.", hint: countHint, action: "Check"),
            answer: AddSubK.hand("c", P.have, hint: countHint, explain: "\(P.have) dots.", said: P.counted),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let fillHint = "Tap each empty box."
        let fill = LessonStep(StepWords(say: "Fill the frame.", hint: fillHint, action: "Check"),
            answer: AddSubK.hand("f", P.need, hint: fillHint, explain: "\(P.need) more.", said: { _ in Parts.full }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Count the striped dots."
        let write = LessonStep(StepWords(say: "Write how many more.", hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.need, known: AddSubK.known(P.need, P.slips), other: { P.wrote($0) }, hint: writeHint,
                                 explain: "\(P.have) + \(P.need) = 10."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [count, fill, write, done]
    }
}

// MARK: - Facts to 5

/// Facts to 5 (gk-five, new; K.OA.A.5, K.OA.A.1 with fingers). One finger is one block wide, a block apart: a hand in
/// blocks, a palm and five fingers (up: 4 blocks tall and filled; down: folded to 1 block and outlined; the thumb on the
/// left a block shorter). The fact is the record from the start, its first number the fingers already up. Help fades
/// across the page: index 0–2 the hand first (tap fingers up or down), then the write; 3–5 the write first, then the hand
/// shows it; 6+ the fact alone, the hand drawn only after the answer.
///
/// "mode": 0 hand, 1 write first, 2 the fact alone. "at": 0 tap, 1 write, 2 done. The tap step's box: b once that many
/// fingers have changed, −1 a finger already up tapped (for +), −2 one already down (for −), or how many changed past b.
public enum FactsToFive {
    public static func numbers(a: Int, b: Int, plus: Bool, mode: Int = 0) -> Numbers {
        ["a": Double(a), "b": Double(b), "plus": plus ? 1 : 0, "mode": Double(mode)]
    }
    public struct Parts: Sendable {
        public let a: Int, b: Int, plus: Bool, mode: Int
        public init(_ x: Numbers) {
            plus = AddSubK.int(x, "plus", 1) == 1
            a = max(0, min(5, AddSubK.int(x, "a", 3)))
            b = max(0, min(plus ? 5 - a : a, AddSubK.int(x, "b", 1)))
            mode = max(0, min(2, AddSubK.int(x, "mode")))
        }
        public var c: Int { plus ? a + b : a - b }
        public var sign: String { plus ? "+" : "−" }
        /// The fingers the move changes, in the order the hand shows them: raised from the first one down, folded from the
        /// last one up.
        public var moves: [Int] { (0..<b).map { plus ? a + $0 : a - 1 - $0 } }
        public var tapSay: String { plus ? "Raise \(b)." : "Fold \(b)." }
        public var writeSay: String { mode == 0 ? "Write how many are up." : "Write the answer." }
        public func tapped(_ code: Int) -> String {
            switch code {
            case -1: "That finger is already up."
            case -2: "That finger is already down."
            default: plus ? "That’s \(code) more. Raise \(b)." : "That’s \(code) folded. Fold \(b)."
            }
        }
        public var slips: [(Int, String)] {
            plus ? [(a - b, "That’s \(a) take away \(b). + means more fingers go up."), (b, "\(b) is how many went up. Count every finger that’s up."),
                    (a, "That’s how many were up to start.")]
                : [(a + b, "That’s \(a) and \(b) more. − means \(b == 1 ? "a finger folds" : "fingers fold") down."),
                   (b, "\(b) is how many folded. Count the fingers still up."), (a, "That’s how many were up to start.")]
        }
        public func wrote(_ v: Int) -> String { AddSubK.slip(v, c, slips, "Count the fingers that are up: one number for each.") }
        public var why: String {
            plus ? (c == 5 ? "Every finger is up: a whole hand, every time." : "Fingers go up, so add: the same every time.") : "Fingers fold down, so take away: the same every time."
        }
        /// The last words: written first, the hand shows the fact after it ("Watch the hand.").
        public var doneSay: String { mode == 0 ? why : "Watch the hand. \(why)" }
    }
    /// Easy first: index 0–2 + with answers up to 4, no 0; 3–5 + or −, no 0; 6+ any fact with numbers and answers 0–5,
    /// a 0 now and then (1 in 3 of the draws that have one are kept).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        while true {
            let plus = i < 3 ? true : Bool.random(using: &rng)
            let a = Int.random(in: 0...5, using: &rng), b = Int.random(in: 0...5, using: &rng), c = plus ? a + b : a - b
            if c < 0 || c > 5 { continue }
            if i < 3 && (a < 1 || b < 1 || c > 4) { continue }
            if i >= 3 && i < 6 && (a < 1 || b < 1 || c < 1) { continue }
            if i >= 6 && (a == 0 || b == 0 || c == 0) && Int.random(in: 1...3, using: &rng) > 1 { continue }
            return numbers(a: a, b: b, plus: plus, mode: i < 3 ? 0 : i < 6 ? 1 : 2)
        }
    }

    public static let spec = LessonSpec(id: "gk-five", title: "Facts to 5", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op(P.sign), .num(Double(P.b))] },
        idea: { _ in "Fingers go up to add and fold down to take away: the same every time." },
        depends: ["k-add", "k-sub"],
        check: [CheckItem(3, when: { !Parts($0).plus }), CheckItem(3, when: { Parts($0).c == 5 }),
                CheckItem(6, when: { let P = Parts($0); return P.a == 0 || P.b == 0 || P.c == 0 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let writeHint = P.plus ? "Count every finger that’s up." : "Count the fingers still up."
        let write = LessonStep(StepWords(say: P.writeSay, hint: writeHint, action: "Check"),
            answer: CountK.write("x", P.c, known: AddSubK.known(P.c, P.slips), other: { P.wrote($0) }, hint: writeHint,
                                 explain: "\(P.a) \(P.sign) \(P.b) = \(P.c)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.doneSay, hint: "", action: "Next problem"), picture: ["at": 2])
        guard P.mode == 0 else { return [write, done] }
        let tapHint = P.plus ? "Tap a finger that’s down." : "Tap a finger that’s up."
        let tap = LessonStep(StepWords(say: P.tapSay, hint: tapHint, action: "Check"),
            answer: AddSubK.hand("f", P.b, hint: tapHint, explain: "\(P.a) \(P.sign) \(P.b).", said: P.tapped),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [tap, write, done]
    }
}
