import Foundation

/// A lesson's problems after its How to (G 19 Oct): 3 done together, then 6 on their own, then the lesson's test.
/// - Together: the paper points to every move, and help builds with each miss (the hint, the picture lit, Show me).
///   When the last together problem still needed Show me, one more together problem comes (at most 2 more).
/// - On their own: steps named, no hints until a miss. A problem with a miss is replaced by a fresh one aimed at the
///   step that went wrong, which starts that step with what the child was told; the same slip twice means that part is
///   taught again (shown first) when the fresh problem gets there.
/// - The test unlocks once 6 own problems are right with no miss: 12 problems, no help, one try. 10 right passes and the
///   lesson is learned; it can always be taken again.
public struct LessonPlan: Codable, Equatable, Sendable {
    public enum Part: String, Codable, Sendable { case together, own }

    /// A problem aimed at a step the child slipped on: the step, what they were told, and whether to show it first.
    public struct Focus: Codable, Equatable, Sendable {
        public var step: Int
        public var said: String
        public var teach: Bool
    }

    public struct Item: Codable, Equatable, Sendable {
        public var part: Part
        public var numbers: Numbers
        public var story: Bool
        public var focus: Focus?
    }

    public static let together = 3, moreTogether = 2, own = 6, test = 12, pass = 10

    public private(set) var items: [Item]
    /// How many times each slip (Slip.key) happened in the own problems.
    public private(set) var slips: [String: Int] = [:]
    public private(set) var extra = 0
    /// Own problems made so far, for the generator (later ones are harder) and every third one told as a story.
    private var made = 0

    public init(_ spec: LessonSpec, using rng: inout SeededRandom) {
        items = (0..<Self.together).map { i in Item(part: .together, numbers: spec.generate(&rng, i), story: false) }
        for _ in 0..<Self.own { items.append(Self.ownItem(spec, made, using: &rng)); made += 1 }
    }

    private static func ownItem(_ spec: LessonSpec, _ k: Int, focus: Focus? = nil, using rng: inout SeededRandom) -> Item {
        // a problem aimed at a slip is told plainly, so its steps line up with the one that went wrong
        Item(part: .own, numbers: spec.generate(&rng, Self.together + min(k, 6)), story: focus == nil && spec.story != nil && k % 3 == 2, focus: focus)
    }

    /// The run for item `i`: together problems guided with every hint, own ones with the first hint only after a miss.
    public func run(_ spec: LessonSpec, _ i: Int) -> LessonRun {
        let it = items[i]
        var r = LessonRun(spec, numbers: it.numbers, story: it.story)
        r.guided = it.part == .together
        r.hintCap = it.part == .together ? 3 : 1
        r.skipAsk()
        return r
    }

    /// Own problems solved with no miss.
    public func ownRight(_ runs: [LessonRun]) -> Int {
        zip(items, runs).filter { $0.0.part == .own && $0.1.isLast && !$0.1.missedAny }.count
    }
    public func testOpen(_ runs: [LessonRun]) -> Bool { ownRight(runs) >= Self.own }

    /// Problem `i` was solved: returns the problems this added to the end (none, one more together, or a fresh own
    /// problem aimed at what went wrong).
    @discardableResult
    public mutating func solved(_ i: Int, _ run: LessonRun, _ spec: LessonSpec, using rng: inout SeededRandom) -> [Int] {
        guard items.indices.contains(i) else { return [] }
        switch items[i].part {
        case .together:
            let together = items.indices.filter { items[$0].part == .together }
            guard i == together.last, !run.shown.isEmpty, extra < Self.moreTogether else { return [] }
            extra += 1
            let at = (together.last ?? 0) + 1
            items.insert(Item(part: .together, numbers: spec.generate(&rng, 1), story: false), at: at)
            return [at]
        case .own:
            guard run.missedAny, let first = run.slips.first else { return [] }
            for s in run.slips { slips[s.key, default: 0] += 1 }
            // the slip seen most often is the one to aim at
            let worst = run.slips.max { (slips[$0.key] ?? 0) < (slips[$1.key] ?? 0) } ?? first
            let focus = Focus(step: worst.step, said: worst.said, teach: (slips[worst.key] ?? 0) >= 2)
            items.append(Self.ownItem(spec, made, focus: focus, using: &rng)); made += 1
            return [items.count - 1]
        }
    }

    /// A fresh test: 12 problems from the lesson's own check recipe, no help and one try each.
    public static func testRuns(_ spec: LessonSpec, using rng: inout SeededRandom) -> [LessonRun] {
        (0..<test).map { k in
            let item = spec.check.isEmpty ? CheckItem(3) : spec.check[k % spec.check.count]
            var r = LessonRun(spec, numbers: item.draw(spec, using: &rng), story: item.story && spec.story != nil)
            r.helps = false; r.oneTry = true
            r.skipAsk()
            return r
        }
    }

    /// A finished test: how many were right with no miss, and its score 0–4 (10 or more right passes: 3 or 4).
    public static func testScore(_ runs: [LessonRun]) -> (right: Int, level: Int)? {
        guard !runs.isEmpty, runs.allSatisfy(\.isLast) else { return nil }
        let right = runs.filter { !$0.missedAny }.count
        return (right, level(right, of: runs.count))
    }
    public static func level(_ right: Int, of n: Int) -> Int {
        let k = Double(right) / Double(max(1, n))
        return right == n ? 4 : k >= Double(pass) / Double(test) ? 3 : k >= 0.6 ? 2 : k >= 0.3 ? 1 : 0
    }
}
