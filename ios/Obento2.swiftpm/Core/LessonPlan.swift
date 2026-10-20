import Foundation

/// A lesson's problems after its How to (G 19 Oct): 3 done together, then 6 on their own, then the lesson's test.
/// - Together: the paper points to every move, and help builds with each miss (the hint, the picture lit, Show me).
///   When the last together problem still needed Show me, one more together problem comes (at most 2 more).
/// - On their own: steps named, no hints until a miss. A problem with a miss is replaced by a fresh one aimed at the
///   step that went wrong, which starts that step with what the child was told; the same slip twice means that part is
///   taught again (shown first) when the fresh problem gets there. A problem Show me helped with is done, but not right
///   on their own (G 20 Oct): a fresh one comes for it too.
/// - The test unlocks once 6 own problems are right with no miss and no Show me: 12 problems, no help, one try. 10
///   right passes and the lesson is learned; it can always be taken again.
/// - Every test is scored the same way (G 20 Oct): problems right, 12 problems, 10 to pass: a lesson's, a chapter's
///   and the grade's. A learned lesson that comes due is rechecked with its 4-problem skill check first.
public struct LessonPlan: Codable, Equatable, Sendable {
    public enum Part: String, Codable, Sendable { case together, own }

    /// A problem aimed at a step the child slipped on: the step, what to keep in mind there (that step's own advice for
    /// this problem's numbers, so it never speaks of the problem that went wrong), and whether to show it first.
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
    /// A due lesson's recheck: its skill check, 4 problems (LESSONS.md §7).
    public static let recheck = 4
    /// The page's hints for its own problems (G 20 Oct): about one for every two problems, the web's rule.
    public static let hints = 5

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
        let n = spec.generate(&rng, Self.together + min(k, 6))
        return Item(part: .own, numbers: n, story: focus == nil && spec.story != nil && k % 3 == 2,
                    focus: focus.map { Focus(step: $0.step, said: advice(spec, n, step: $0.step), teach: $0.teach) })
    }

    /// What to keep in mind at step `step` of the problem with these numbers: its own hint, worked out from them (the
    /// words the child was told last time were about other numbers).
    static func advice(_ spec: LessonSpec, _ n: Numbers, step: Int) -> String {
        let steps = spec.steps(n)
        guard steps.indices.contains(step) else { return "" }
        let s = steps[step]
        return [s.answer?.hint, s.words.hint, s.look].compactMap { $0 }.first { !$0.isEmpty } ?? ""
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

    /// Item `i` with fresh numbers, told plainly: its saved work no longer fits the lesson (it changed since), so the
    /// problem starts again.
    public mutating func renew(_ i: Int, _ spec: LessonSpec, using rng: inout SeededRandom) {
        guard items.indices.contains(i) else { return }
        let k = items[...i].filter { $0.part == items[i].part }.count - 1
        let n = spec.generate(&rng, items[i].part == .together ? min(k, Self.together - 1) : Self.together + min(k, 6))
        items[i].numbers = n
        items[i].story = false
        items[i].focus = items[i].focus.map { Focus(step: $0.step, said: Self.advice(spec, n, step: $0.step), teach: $0.teach) }
    }

    /// Own problems right on their own: no miss, and no Show me (G 20 Oct).
    public func ownRight(_ runs: [LessonRun]) -> Int {
        zip(items, runs).filter { $0.0.part == .own && $0.1.clean }.count
    }
    public func testOpen(_ runs: [LessonRun]) -> Bool { ownRight(runs) >= Self.own }

    /// Problem `i` was solved: returns the problems this added to the end (none, one more together, or a fresh own
    /// problem: aimed at what went wrong after a miss, a plain one after Show me).
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
            if run.missedAny, let first = run.slips.first {
                for s in run.slips { slips[s.key, default: 0] += 1 }
                // the slip seen most often is the one to aim at
                let worst = run.slips.max { (slips[$0.key] ?? 0) < (slips[$1.key] ?? 0) } ?? first
                let focus = Focus(step: worst.step, said: worst.said, teach: (slips[worst.key] ?? 0) >= 2)
                items.append(Self.ownItem(spec, made, focus: focus, using: &rng)); made += 1
                return [items.count - 1]
            }
            // done with Show me (or a miss with nothing said about it): it doesn't count, so another takes its place
            guard run.missedAny || !run.shown.isEmpty else { return [] }
            items.append(Self.ownItem(spec, made, using: &rng)); made += 1
            return [items.count - 1]
        }
    }

    // MARK: hints

    /// What the bar's Hint does for a problem now (G 20 Oct): nothing (off), a free hint (together problems, up to the run's
    /// cap of hinted steps), or one of the page's hints (own problems, only once the step has had a miss). One hint a
    /// step; none in tests and rechecks, or once the problem is done.
    public enum HintUse: Equatable, Sendable { case off, free, spend }
    public static func hint(_ run: LessonRun, part: Part?, left: Int) -> HintUse {
        guard let part, run.helps, !run.oneTry, !run.isLast, run.step.answer != nil || run.step.task != nil,
              !run.hinted.contains(run.index) else { return .off }
        switch part {
        case .together: return run.hinted.count < run.hintCap ? .free : .off
        case .own: return run.misses > 0 && left > 0 ? .spend : .off
        }
    }
    /// The hints the bar shows as left: a together problem's own free ones, else the page's.
    public static func hintsLeft(_ run: LessonRun, part: Part?, left: Int) -> Int? {
        guard let part, run.helps, !run.oneTry else { return nil }
        return part == .together ? max(0, run.hintCap - run.hinted.count) : max(0, left)
    }

    // MARK: tests and rechecks

    /// A fresh test of `count` problems, no help and one try each, from the lessons' own check recipes, the lessons
    /// taken in turn: a lesson's test (one lesson), a chapter's (its lessons) or the grade's.
    public static func testRuns(_ specs: [LessonSpec], count: Int = test, using rng: inout SeededRandom) -> [LessonRun] {
        (0..<count).compactMap { testRun(specs, $0, using: &rng) }
    }
    /// A lesson's own test: 12 of its problems.
    public static func testRuns(_ spec: LessonSpec, using rng: inout SeededRandom) -> [LessonRun] { testRuns([spec], using: &rng) }

    /// Problem `i` of a test of these lessons: from lesson `i` in turn, the next item of its check recipe.
    public static func testRun(_ specs: [LessonSpec], _ i: Int, using rng: inout SeededRandom) -> LessonRun? {
        guard !specs.isEmpty else { return nil }
        let spec = specs[i % specs.count], k = i / specs.count
        let item = spec.check.isEmpty ? CheckItem(3) : spec.check[k % spec.check.count]
        var r = LessonRun(spec, numbers: item.draw(spec, using: &rng), story: item.story && spec.story != nil)
        r.helps = false; r.oneTry = true
        r.skipAsk()
        return r
    }

    /// A due lesson's recheck: its 4-problem skill check, no help, one try each.
    public static func recheckRuns(_ spec: LessonSpec, using rng: inout SeededRandom) -> [LessonRun] {
        testRuns([spec], count: recheck, using: &rng)
    }

    /// A finished test: how many were right with no miss, and its score 0–4 (10 or more of 12 right passes: 3 or 4).
    public static func testScore(_ runs: [LessonRun]) -> (right: Int, level: Int)? {
        guard !runs.isEmpty, runs.allSatisfy(\.isLast) else { return nil }
        let right = runs.filter { !$0.missedAny }.count
        return (right, level(right, of: runs.count))
    }
    /// A finished recheck: 4 problems, its score the number right (3 or 4 keeps the lesson learned, LESSONS.md §7).
    public static func recheckScore(_ runs: [LessonRun]) -> (right: Int, level: Int)? {
        guard !runs.isEmpty, runs.allSatisfy(\.isLast) else { return nil }
        let right = runs.filter { !$0.missedAny }.count
        return (right, min(4, right * 4 / runs.count))
    }
    /// 0–4 from problems right: all of them 4; 10 of 12 (or the same share) 3, a pass; 60% 2; 30% 1.
    public static func level(_ right: Int, of n: Int) -> Int {
        let k = Double(right) / Double(max(1, n))
        return right == n ? 4 : k >= Double(pass) / Double(test) ? 3 : k >= 0.6 ? 2 : k >= 0.3 ? 1 : 0
    }
    /// A test of `n` problems is passed with this many right: 10 of 12.
    public static func passMark(_ n: Int) -> Int { Int((Double(n) * Double(pass) / Double(test)).rounded(.up)) }
}
