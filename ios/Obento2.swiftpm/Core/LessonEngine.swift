import Foundation

/// A problem's numbers, by name ("a", "p", "length"...). The picture, the words and the answers are all read from them.
public typealias Numbers = [String: Double]

/// A number as the paper writes it: no trailing zeros, a real minus sign. 3.40 → "3.4", -2 → "−2".
public func fmt(_ x: Double) -> String {
    let r = (x * 1_000_000).rounded() / 1_000_000
    var s = r == r.rounded() ? String(Int(r)) : String(format: "%.6f", r)
    if s.contains(".") { while s.hasSuffix("0") { s.removeLast() }; if s.hasSuffix(".") { s.removeLast() } }
    return s.replacingOccurrences(of: "-", with: "−")
}

/// Math as it's written on the paper, with answer boxes in it.
public indirect enum Math: Equatable, Sendable {
    case num(Double)
    /// + − × ÷ =
    case op(String)
    case text(String)
    /// An answer box, by its id.
    case box(String)
    /// top over bottom
    case frac(Math, Math)
}
public typealias MathLine = [Math]

/// The child types numbers into the boxes of a line of math. Checked together, against the predictable slips first.
public struct AnswerTask: Sendable {
    public var prompt: MathLine
    /// What each box should hold, by id.
    public var expected: [String: Double]
    /// Predictable slips, checked in order: the typed values that trigger each, and what to say.
    public var known: [(values: [String: Double], message: String)]
    public var hint: String
    /// What "Show me" says after filling the answer in.
    public var explain: String
    /// For answers that can be written more than one way (any equivalent fraction, either order, lowest terms):
    /// decides instead of comparing with `expected`, after every box is filled.
    public var check: (@Sendable ([String: Double]) -> Verdict)?
    /// A pick-one step: the child taps one of these instead of typing. The choice goes in box "c" as its index;
    /// the prompt may leave the box out, and the finished line writes the choice's words.
    public var choices: [String]?

    public init(prompt: MathLine, expected: [String: Double], known: [(values: [String: Double], message: String)] = [], hint: String, explain: String? = nil,
                check: (@Sendable ([String: Double]) -> Verdict)? = nil, choices: [String]? = nil) {
        self.prompt = prompt; self.expected = expected; self.known = known; self.hint = hint; self.check = check; self.choices = choices
        self.explain = explain ?? "\(hint) That makes \(expected.count == 1 ? fmt(expected.values.first!) : "it")."
    }

    /// The boxes in the order they're written.
    public var boxes: [String] {
        func walk(_ m: Math) -> [String] {
            switch m { case .box(let id): [id]; case .frac(let a, let b): walk(a) + walk(b); default: [] }
        }
        let found = prompt.flatMap(walk)
        return choices != nil && found.isEmpty ? ["c"] : found
    }

    /// The line with every box filled in: the finished work that stays on the paper.
    public var work: MathLine {
        func fill(_ m: Math) -> Math {
            switch m {
            case .box(let id):
                if let c = choices, id == "c", let i = expected["c"].map({ Int($0) }), c.indices.contains(i) { .text(c[i]) } else { .num(expected[id] ?? 0) }
            case .frac(let a, let b): .frac(fill(a), fill(b))
            default: m
            }
        }
        let line = prompt.map(fill)
        // a pick-one step with no box in its prompt still writes its choice
        if let c = choices, !prompt.contains(.box("c")), let i = expected["c"].map({ Int($0) }), c.indices.contains(i) { return line + [.text(c[i])] }
        return line
    }
}

/// A lesson as data: a generator makes fresh numbers, and the steps are worked out from those numbers.
/// One engine (LessonRun) plays every lesson; a picture master draws it, flat or 3D.
/// The words follow the Curriculum team's specs (ios/specs/k12), the maths the web app's lessons.
public struct LessonSpec: Sendable {
    public let id: String
    public let title: String
    /// Which picture master draws it: "cubes", "bars", "shift"...
    public let master: String
    /// Fresh numbers for the problem at this place in a run (0 = the first; the first problems are easier).
    public let generate: @Sendable (inout SeededRandom, Int) -> Numbers
    /// The problem as the paper writes it above the picture ("3.47 × 100").
    public let display: @Sendable (Numbers) -> MathLine
    public let steps: @Sendable (Numbers) -> [LessonStep]
    /// The idea in one sentence, built from the same numbers.
    public let idea: @Sendable (Numbers) -> String
    /// The same problem told as a word problem, for lessons that have one.
    public let story: (@Sendable (Numbers) -> String)?
    /// The operation the story needs ("+", "−", "×", "÷"): what "Which operation solves it?" checks.
    public let storyOp: (@Sendable (Numbers) -> String)?
    /// The lessons a child needs first; the first is the main build-up.
    public let depends: [String]
    /// The lesson's own skill check: four problems, no hints, one try per step.
    public let check: [CheckItem]
    /// The whole problem as one step, for "final answer only" (help faded, G 18 Oct); nil keeps every step.
    public let finalStep: (@Sendable (Numbers) -> LessonStep)?

    public init(id: String, title: String, master: String,
                generate: @escaping @Sendable (inout SeededRandom, Int) -> Numbers,
                display: @escaping @Sendable (Numbers) -> MathLine = { _ in [] },
                idea: @escaping @Sendable (Numbers) -> String = { _ in "" },
                story: (@Sendable (Numbers) -> String)? = nil,
                storyOp: (@Sendable (Numbers) -> String)? = nil,
                depends: [String] = [], check: [CheckItem] = [],
                finalStep: (@Sendable (Numbers) -> LessonStep)? = nil,
                steps: @escaping @Sendable (Numbers) -> [LessonStep]) {
        self.id = id; self.title = title; self.master = master; self.generate = generate; self.display = display
        self.idea = idea; self.story = story; self.storyOp = storyOp; self.depends = depends; self.check = check; self.steps = steps
        self.finalStep = finalStep
    }
}

/// One problem of a skill check: `generate(rng, index)`, redrawn (up to 50 tries) until `when` holds;
/// `story` shows it as the lesson's word problem.
public struct CheckItem: Sendable {
    public let index: Int
    public let when: (@Sendable (Numbers) -> Bool)?
    public let story: Bool
    public init(_ index: Int, when: (@Sendable (Numbers) -> Bool)? = nil, story: Bool = false) { self.index = index; self.when = when; self.story = story }

    public func draw(_ spec: LessonSpec, using rng: inout SeededRandom) -> Numbers {
        var n = spec.generate(&rng, index)
        for _ in 0..<50 where !(when?(n) ?? true) { n = spec.generate(&rng, index) }
        return n
    }
}

/// What a custom answer check says about the typed values.
public enum Verdict: Sendable, Equatable {
    case right
    /// A real miss, with what to say.
    case wrong(String)
    /// Not checked yet (a box needs something first); doesn't count as a miss.
    case soft(String)
}

public enum StepCamera: Sendable { case flat, tilted }

/// The four beats of every lesson (LESSONS.md §2): Ask (the problem draws itself), Do (the child acts on the drawing),
/// See (the picture proves the step; hands off while it moves), Say (the answer is written under its proof).
public enum Beat: Sendable { case ask, `do`, see, say }

/// One step: what the paper says, what the child does on the picture, and how the picture and camera look.
public struct LessonStep: Sendable {
    public var words: StepWords
    public var task: MarkTask?
    public var answer: AnswerTask?
    public var camera: StepCamera
    /// What the picture shows at this step, read by its master ("layers": 2, "match": 1...).
    public var picture: Numbers
    /// Added to the picture after a wrong check (a guide line, say).
    public var onMiss: Numbers
    /// The words that go with `onMiss` ("The fourth ends here").
    public var look: String?
    /// The second hint, after a second miss: another small drawing step added to the picture (LESSONS.md §7).
    /// The first hint is `onMiss`; the third always points at Show me.
    public var hint2: Numbers
    /// Overrides the beat worked out from the step (a step with something to do is Do; the first is Ask, the last Say).
    public var beatOverride: Beat?

    public init(_ words: StepWords, task: MarkTask? = nil, answer: AnswerTask? = nil, camera: StepCamera = .flat, picture: Numbers = [:], onMiss: Numbers = [:], look: String? = nil,
                hint2: Numbers = [:], beat: Beat? = nil) {
        self.words = words; self.task = task; self.answer = answer; self.camera = camera; self.picture = picture; self.onMiss = onMiss; self.look = look
        self.hint2 = hint2; self.beatOverride = beat
    }
}

/// The child marks cells of the picture (squares on a floor, pieces of a bar) until the right number are marked.
/// Cells are numbered by the picture master; marks from earlier steps stay put.
public struct MarkTask: Sendable {
    /// The cells the child may tap.
    public var cells: Set<Int>
    public var want: Int
    /// What "Show me" marks, in order.
    public var showMe: [Int]
    /// After a right check the marks move to these, so they line up under what they match.
    public var snap: [Int]?
    /// Checked in order when the count is wrong.
    public var mistakes: [Mistake]
    /// The line under the picture while the child works, given how many are marked.
    public var count: @Sendable (Int) -> String
    /// How strongly the master fills this step's marks (1 = full, 2 = lighter).
    public var style: Int

    public init(cells: Set<Int>, want: Int, showMe: [Int], snap: [Int]? = nil, mistakes: [Mistake], style: Int = 1, count: @escaping @Sendable (Int) -> String) {
        self.cells = cells; self.want = want; self.showMe = showMe; self.snap = snap; self.mistakes = mistakes; self.style = style; self.count = count
    }
}

/// A predictable slip and what to say about it.
public struct Mistake: Sendable {
    public enum When: Sendable { case noneMarked, tooFew, tooMany }
    public let when: When
    /// Given how many are marked and how many are wanted.
    public let message: @Sendable (_ marked: Int, _ want: Int) -> String
    public init(_ when: When, _ message: @escaping @Sendable (_ marked: Int, _ want: Int) -> String) { self.when = when; self.message = message }
}

/// A lesson being played: its numbers, which step it's on, and what the child has marked.
public struct LessonRun: Sendable {
    public enum Outcome: Equatable, Sendable {
        case moved(Int)
        case notYet(String)
        case newProblem
    }

    public let spec: LessonSpec
    public let numbers: Numbers
    /// Told as the lesson's word problem.
    public let story: Bool
    /// The whole problem asked as one step (help faded); a miss brings the steps back.
    public let finalOnly: Bool
    public let steps: [LessonStep]
    public private(set) var index = 0
    /// Each marked cell, and the step that marked it.
    public private(set) var marks: [Int: Int] = [:]
    /// A wrong check happened on this step.
    public private(set) var missed = false
    /// Wrong checks on this step.
    public private(set) var misses = 0
    /// What the child has typed in each box of this step.
    public private(set) var typed: [String: String] = [:]
    /// The box the keypad types into.
    public var active: String?

    /// `story`: tell it as the lesson's word problem, with "Which operation solves it?" first (as the web's practice does).
    public init(_ spec: LessonSpec, numbers: Numbers, story: Bool = false, finalOnly: Bool = false) {
        self.spec = spec; self.numbers = numbers; self.story = story
        var s = spec.steps(numbers)
        // final answer only: the whole problem in one step, then its answer; lessons without one keep every step
        let final = finalOnly ? spec.finalStep?(numbers) : nil
        if let final, let last = s.last { s = [s[0], final, last] }
        self.finalOnly = final != nil
        var lead = 0
        if story, let first = Self.operationStep(spec, numbers, picture: s.first?.picture ?? [:]) { s.insert(first, at: 0); lead = 1 }
        self.lead = lead
        steps = s
        let ask = story && s.count > 1 && s[0].answer?.choices != nil ? 1 : 0
        askIndex = s.indices.contains(ask) && s[ask].task == nil && s[ask].answer == nil && ask < s.count - 1 ? ask : nil
        active = steps.first?.answer?.boxes.first
    }

    public static let ops = ["+", "−", "×", "÷"]
    static let opName = ["+": "Add", "−": "Subtract", "×": "Multiply", "÷": "Divide"]
    static let opWhy = [
        "+": "Putting amounts together means adding.",
        "−": "Taking away, or finding how much more, means subtracting.",
        "×": "Equal groups, or a part of a group, means multiplying.",
        "÷": "Sharing equally, or splitting into groups, means dividing.",
    ]

    /// "Read the story": the child picks the operation first. Its words and check are the web's.
    static func operationStep(_ spec: LessonSpec, _ n: Numbers, picture: Numbers) -> LessonStep? {
        guard let text = spec.story?(n), let op = spec.storyOp?(n), let k = ops.firstIndex(of: op) else { return nil }
        let why = opWhy[op]!
        return LessonStep(StepWords(say: text, hint: "Pick what to do.", action: "Check"),
            answer: AnswerTask(prompt: spec.display(n), expected: ["c": Double(k)], hint: why, explain: why,
                               check: { v in v["c"] == Double(k) ? .right : .wrong("Read it again. What happens to the amounts?") },
                               choices: ops.map { "\($0) \(opName[$0]!)" }),
            picture: picture)
    }

    /// What earlier steps' boxes held: a wrong answer equal to one of them reused it.
    var earlierAnswers: [Double] { steps[..<index].compactMap { $0.answer }.flatMap { $0.expected.values } }

    /// A fresh problem at this place in a run.
    public static func fresh(_ spec: LessonSpec, using rng: inout SeededRandom, index: Int = 3) -> LessonRun { LessonRun(spec, numbers: spec.generate(&rng, index)) }

    public var step: LessonStep { steps[index] }
    /// This step's beat.
    public var beat: Beat {
        if let b = step.beatOverride { return b }
        if step.task != nil || step.answer != nil { return .do }
        return index == 0 ? .ask : isLast ? .say : .see
    }
    /// The lesson's opening question with nothing to do but "Let’s find out" (after a story's operation step, if any).
    public let askIndex: Int?
    /// On a lesson's page the child goes straight into solving: the opening question is passed by (G 17 Oct).
    public private(set) var skipsAsk = false
    public mutating func skipAsk() {
        skipsAsk = true
        if index == askIndex { index += 1; active = step.answer?.boxes.first }
    }

    /// Done together (G 18 Oct): the paper points to every move from the start (the right pieces outlined).
    public var guided = false
    /// The strongest hint a miss can bring (3: up to Show me; 1: the first hint only, for less help).
    public var hintCap = 3
    /// Each work step's misses, and the steps where a hint was opened or Show me was used: what the points count.
    public private(set) var stepMisses: [Int: Int] = [:]
    public private(set) var hinted: Set<Int> = []
    public private(set) var shown: Set<Int> = []
    /// The kind of each unknown slip, for the grown-up's report.
    public private(set) var mistakeKinds: [Diagnose.Kind] = []
    /// Every wrong check: which step (counted in the lesson's own steps, before a story's first question), what kind of
    /// slip it was, and what the child was told. Two of the same slip bring that part's teaching back (LessonPlan).
    public private(set) var slips: [Slip] = []
    /// A story's operation question goes before the lesson's own steps: 1 when it's there.
    public private(set) var lead = 0
    /// A hint was opened on this step.
    public mutating func usedHint() { hinted.insert(index) }

    /// Points for the work, the web's rule: each step 1 on the first try (½ after a hint), ½ after one miss,
    /// ¼ after more, 0 if shown. Out of `workSteps`.
    public var points: Double {
        steps.indices.filter { steps[$0].task != nil || steps[$0].answer != nil }.reduce(0) { sum, i in
            if shown.contains(i) { return sum }
            let m = stepMisses[i] ?? 0
            return sum + (m == 0 ? (hinted.contains(i) ? 0.5 : 1) : m == 1 ? 0.5 : 0.25)
        }
    }

    /// Hints and Show me are off in the skill check (LESSONS.md §7).
    public var helps = true
    /// One try per step, as in the skill check: a wrong check shows the answer and the problem counts as missed.
    public var oneTry = false
    /// A step of this problem was missed.
    public var missedAny: Bool { !missedSteps.isEmpty }
    /// The steps of this problem that were missed at least once.
    public private(set) var missedSteps: Set<Int> = []
    /// The steps with something to do: what a skill check scores.
    public var workSteps: Int { steps.filter { $0.task != nil || $0.answer != nil }.count }
    /// How many hints the picture shows: one per miss, at most three; none when helps are off.
    public var hintLevel: Int { helps ? min(misses, hintCap) : 0 }
    public var display: MathLine { spec.display(numbers) }
    public var words: StepWords { step.words }
    public var isLast: Bool { index == steps.count - 1 }
    /// The picture as it stands: this step's, plus the hints the misses have earned (the child's answer drawn beside the
    /// real one, then a second drawing step, then Show me pointed at).
    public var picture: Numbers {
        var p = step.picture
        if hintLevel >= 1 { p.merge(step.onMiss) { $1 } }
        if hintLevel >= 2 || (guided && step.task != nil) { p.merge(step.hint2) { $1 } }
        if hintLevel >= 3 { p["showMe"] = 1 }
        return p
    }
    public subscript(_ name: String) -> Double { numbers[name] ?? 0 }
    public func int(_ name: String) -> Int { Int((numbers[name] ?? 0).rounded()) }

    /// The cells marked on this step.
    public var marked: Set<Int> { Set(marks.filter { $0.value == index }.keys) }
    public func marked(on step: Int) -> Set<Int> { Set(marks.filter { $0.value == step }.keys) }
    public var countLine: String? { step.task.map { $0.count(marks.count) } }

    /// Tapping a cell marks it, tapping again clears it. Marks from earlier steps can't change.
    @discardableResult
    public mutating func tap(_ cell: Int) -> Bool {
        guard let t = step.task, t.cells.contains(cell) else { return false }
        if let by = marks[cell] {
            guard by == index else { return false }
            marks[cell] = nil
        } else { marks[cell] = index }
        return true
    }

    /// Marks what "Show me" marks; returns the cells that weren't marked before, in order.
    public mutating func showMe() -> [Int] {
        guard let t = step.task else { return [] }
        if helps { shown.insert(index) }
        let had = marked
        for c in had where !t.showMe.contains(c) { marks[c] = nil }
        var fresh: [Int] = []
        for c in t.showMe where marks[c] == nil { marks[c] = index; fresh.append(c) }
        return fresh
    }

    public mutating func reset() {
        for c in marked { marks[c] = nil }
        typed = [:]; active = step.answer?.boxes.first
    }

    /// A keypad press: a digit, ".", or "del". Goes into the active box; a box holds at most 7 characters.
    public mutating func type(_ key: String) {
        guard let a = step.answer, let box = active ?? a.boxes.first else { return }
        active = box
        var t = typed[box] ?? ""
        switch key {
        case "del": if !t.isEmpty { t.removeLast() }
        case ".": if !t.contains(".") && t.count < 7 { t += t.isEmpty ? "0." : "." }
        default: if t.count < 7 { t = t == "0" ? key : t + key }
        }
        typed[box] = t.isEmpty ? nil : t
    }

    /// A pick-one step: the child taps choice `i`.
    public mutating func choose(_ i: Int) {
        guard step.answer?.choices != nil else { return }
        typed["c"] = String(i)
    }

    /// "Show me" on a typed step: fills in the answer and returns what to say about it.
    public mutating func showAnswer() -> String? {
        guard let a = step.answer else { return nil }
        if helps && !oneTry { shown.insert(index) }
        for (id, v) in a.expected { typed[id] = fmt(v).replacingOccurrences(of: "−", with: "-") }
        return a.explain
    }

    /// The main action: check this step's marks, then move on.
    public mutating func go() -> Outcome {
        if let a = step.answer {
            if a.boxes.contains(where: { (typed[$0] ?? "").isEmpty }) { return .notYet("Fill in every box.") }
            let values = typed.compactMapValues { Double($0) }
            let same = { (want: [String: Double]) in want.allSatisfy { abs((values[$0.key] ?? .nan) - $0.value) < 1e-9 } }
            if let check = a.check {
                switch check(values) {
                case .right: break
                case .soft(let line): return .notYet(line)
                case .wrong(let line):
                    missed = true; misses += 1; missedSteps.insert(index); stepMisses[index, default: 0] += 1
                    let k = a.known.firstIndex { same($0.values) }
                    let said = k.map { a.known[$0].message } ?? line
                    slips.append(Slip(step: index - lead, kind: k.map { "k\($0)" } ?? "wrong", said: said))
                    if oneTry { _ = showAnswer() }
                    return .notYet(said)
                }
            } else if !same(a.expected) {
                missed = true; misses += 1; missedSteps.insert(index); stepMisses[index, default: 0] += 1
                let kind = Diagnose.kind(values, a.expected, earlier: earlierAnswers)
                if let kind { mistakeKinds.append(kind) }
                // the lesson's own words teach best (the web's order); the kind of slip speaks when it has none
                let k = a.known.firstIndex { same($0.values) }
                let said = k.map { a.known[$0].message }
                    ?? (a.hint.isEmpty ? kind.flatMap { Diagnose.say[$0] }.map { "Not quite. \($0)" } : nil) ?? "Not quite. \(a.hint)"
                slips.append(Slip(step: index - lead, kind: k.map { "k\($0)" } ?? kind?.rawValue ?? "other", said: said))
                if oneTry { _ = showAnswer() }
                return .notYet(said)
            }
        }
        if let t = step.task {
            let n = marked.count
            let wrong: Mistake.When? = n == 0 && t.want > 0 ? .noneMarked : n < t.want ? .tooFew : n > t.want ? .tooMany : nil
            if let wrong {
                missed = true; misses += 1; missedSteps.insert(index); stepMisses[index, default: 0] += 1
                let m = t.mistakes.first { $0.when == wrong } ?? t.mistakes.first { $0.when == .tooFew && wrong == .noneMarked }
                slips.append(Slip(step: index - lead, kind: "\(wrong)", said: m?.message(n, t.want) ?? "Not yet."))
                if oneTry { _ = showMe() }
                return .notYet(m?.message(n, t.want) ?? "Not yet.")
            }
            if let snap = t.snap { reset(); for c in snap { marks[c] = index } }
        }
        guard !isLast else { return .newProblem }
        index += 1; missed = false; misses = 0; typed = [:]
        if skipsAsk, index == askIndex, !isLast { index += 1 }
        active = step.answer?.boxes.first
        return .moved(index)
    }
}

/// Every lesson the app can play, by id. The map opens whatever is here; its picture master draws it.
public enum Lessons {
    public static let all: [LessonSpec] = [
        UnitCubes.spec, AddFractions.spec, PowersOfTen.spec,
        AddingFractions.spec, SubtractingFractions.spec, AddAndSubtract.spec, MixedToImproper.spec,
        FractionOf.spec, MultiplyFractions.spec, DivideByUnitFraction.spec,
        VolumeOfBox.spec, ConvertUnits.spec,
        MultiplyTwoDigit.spec, LongDivision.spec, OrderOfOperations.spec,
        RoundDecimals.spec, AddDecimals.spec, MultiplyDecimals.spec, DivideByDecimal.spec,
    ]
    public static func spec(_ id: String) -> LessonSpec? { all.first { $0.id == id } }
}

/// A child's run through one lesson (LESSONS.md §7): the first problem teaches, then 6 practice problems, then the
/// 4-problem skill check (no hints, no Show me, one try per step). Learned = 3 or 4 of the check right.
public struct LessonSession: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        case learn
        /// practice problem n (1...6)
        case practice(Int)
        /// check problem n (1...4), with how many were right so far
        case check(Int, right: Int)
        /// the check is over
        case done(learned: Bool)
    }
    public static let practice = 6, check = 4, pass = 3
    public private(set) var phase: Phase = .learn
    public init(phase: Phase = .learn) { self.phase = phase }

    public var helps: Bool { if case .check = phase { false } else { true } }
    public var oneTry: Bool { !helps }
    /// What the paper says about where the child is ("Practice 2 of 6").
    public var label: String? {
        switch phase {
        case .learn: nil
        case .practice(let n): "Practice \(n) of \(Self.practice)"
        case .check(let n, _): "Skill check \(n) of \(Self.check)"
        case .done(let learned): learned ? "Learned" : "Not yet learned: more practice"
        }
    }
    /// The problem's place in the run, for the generator (the first problems are easier).
    public var index: Int {
        switch phase { case .learn: 0; case .practice(let n): n; case .check: 3; case .done: Self.practice + 1 }
    }

    /// Step points so far in the check: one per step right on its one try.
    public private(set) var points = 0, steps = 0
    /// The check's score, 0 to 4, once it's over.
    public private(set) var level: Int?

    /// A problem was worked to the end; `right` = no step of it was missed. Returns the phase the next problem is in.
    @discardableResult
    public mutating func finished(right: Bool) -> Phase { finished(right: right, points: right ? 1 : 0, of: 1) }

    /// A problem was worked to the end: the check scores its steps (Mastery.level of the share right).
    @discardableResult
    public mutating func finished(_ run: LessonRun) -> Phase {
        finished(right: !run.missedAny, points: run.workSteps - run.missedSteps.count, of: run.workSteps)
    }

    private mutating func finished(right: Bool, points p: Int, of n: Int) -> Phase {
        switch phase {
        case .learn: phase = .practice(1)
        case .practice(let k): phase = k < Self.practice ? .practice(k + 1) : .check(1, right: 0)
        case .check(let k, let r):
            points += p; steps += n
            if k < Self.check { phase = .check(k + 1, right: r + (right ? 1 : 0)) }
            else {
                let l = Mastery.level(steps == 0 ? 0 : Double(points) / Double(steps))
                level = l; phase = .done(learned: l >= Mastery.pass)
            }
        case .done(let learned): phase = learned ? .done(learned: true) : .practice(1)
        }
        return phase
    }

    /// A recheck: a learned lesson that's due back goes straight to its skill check.
    public static var recheck: LessonSession { LessonSession(phase: .check(1, right: 0)) }

    /// Every third practice problem is told as a story, as on the web (problems 2 and 5).
    public var story: Bool { if case .practice(let n) = phase { n % 3 == 2 } else { false } }

    /// The next problem for this phase: fresh numbers at the right place in the run, told as a story where it should be,
    /// and in the skill check drawn from the lesson's own recipe. Hints and tries follow the phase.
    public func makeRun(_ spec: LessonSpec, using rng: inout SeededRandom) -> LessonRun {
        var n = spec.generate(&rng, index), told = story
        if case .check(let k, _) = phase, !spec.check.isEmpty {
            let item = spec.check[(k - 1) % spec.check.count]
            n = item.draw(spec, using: &rng); told = item.story
        }
        var run = LessonRun(spec, numbers: n, story: told && spec.story != nil)
        run.helps = helps; run.oneTry = oneTry
        return run
    }

    /// The check just ended in learning the lesson.
    public var justLearned: Bool { phase == .done(learned: true) }
}

/// A lesson's page (G 17 Oct): after the How to, every problem is on the paper at once and the child works them in
/// any order, right where they are. 16 problems from easy to hard (the run's index), every third practice problem told
/// as a story, and the last row of 4 the skill check (no hints, no Show me, one try), which decides learned.
/// A problem's work, saved so the child can stop anywhere and come back to it exactly as they left it.
public struct RunSnapshot: Codable, Equatable, Sendable {
    public var numbers: Numbers
    public var story: Bool
    public var index: Int
    public var marks: [Int: Int]
    public var typed: [String: String]
    public var misses: Int
    public var missed: Bool
    public var missedSteps: [Int]
    public var helps: Bool
    public var oneTry: Bool
    public var skipsAsk: Bool
    public var guided = false
    public var hintCap = 3
    public var finalOnly = false
    public var stepMisses: [Int: Int] = [:]
    public var hinted: [Int] = []
    public var shown: [Int] = []
    public var slips: [Slip] = []
}

/// One wrong check: the step (in the lesson's own steps), the kind of slip ("k0" = the lesson's first known slip for
/// that step, or a Diagnose kind), and what the child was told.
public struct Slip: Codable, Equatable, Sendable {
    public var step: Int
    public var kind: String
    public var said: String
    public var key: String { "\(step):\(kind)" }
}

extension LessonRun {
    public var snapshot: RunSnapshot {
        RunSnapshot(numbers: numbers, story: story, index: index, marks: marks, typed: typed, misses: misses, missed: missed,
                    missedSteps: missedSteps.sorted(), helps: helps, oneTry: oneTry, skipsAsk: skipsAsk,
                    guided: guided, hintCap: hintCap, finalOnly: finalOnly, stepMisses: stepMisses, hinted: hinted.sorted(), shown: shown.sorted(), slips: slips)
    }

    /// The run as it was saved: the same numbers make the same steps, and the child's work goes back on them.
    public init(_ spec: LessonSpec, restoring s: RunSnapshot) {
        self.init(spec, numbers: s.numbers, story: s.story, finalOnly: s.finalOnly)
        helps = s.helps; oneTry = s.oneTry; guided = s.guided; hintCap = s.hintCap
        stepMisses = s.stepMisses; hinted = Set(s.hinted); shown = Set(s.shown); slips = s.slips
        if s.skipsAsk { skipAsk() }
        index = min(max(0, s.index), steps.count - 1)
        marks = s.marks; typed = s.typed; misses = s.misses; missed = s.missed; missedSteps = Set(s.missedSteps)
        active = step.answer?.boxes.first
    }
}

public enum LessonPage {
    public static let count = 16, checks = 4, columns = 4

    public struct Problem: Sendable {
        public let numbers: Numbers
        public let story: Bool
        public let isCheck: Bool
    }

    /// The page's problems, fresh from the lesson's generator; the check row follows the lesson's own recipe.
    public static func problems(_ spec: LessonSpec, using rng: inout SeededRandom) -> [Problem] {
        (0..<count).map { i in
            if i >= count - checks {
                let k = i - (count - checks)
                if !spec.check.isEmpty {
                    let item = spec.check[k % spec.check.count]
                    return Problem(numbers: item.draw(spec, using: &rng), story: item.story && spec.story != nil, isCheck: true)
                }
                return Problem(numbers: spec.generate(&rng, 3), story: false, isCheck: true)
            }
            return Problem(numbers: spec.generate(&rng, i), story: spec.story != nil && i % 3 == 2, isCheck: false)
        }
    }

    /// The run for one problem on the page: hints and tries follow whether it's part of the check.
    public static func run(_ spec: LessonSpec, _ p: Problem) -> LessonRun {
        var r = LessonRun(spec, numbers: p.numbers, story: p.story)
        r.helps = !p.isCheck; r.oneTry = p.isCheck
        r.skipAsk()
        return r
    }

    /// A test's score, 0 to 4: the share of all its problems' steps right on their one try; nil until every one is done.
    public static func testLevel(_ runs: [LessonRun]) -> Int? {
        guard !runs.isEmpty, runs.allSatisfy(\.isLast) else { return nil }
        let steps = runs.reduce(0) { $0 + $1.workSteps }, right = runs.reduce(0) { $0 + $1.workSteps - $1.missedSteps.count }
        return Mastery.level(steps == 0 ? 0 : Double(right) / Double(steps))
    }

    /// The check's score, 0 to 4, from the share of its steps right on their one try; nil until all its problems are done.
    public static func checkLevel(_ runs: [LessonRun]) -> Int? {
        guard runs.count == checks, runs.allSatisfy(\.isLast) else { return nil }
        let steps = runs.reduce(0) { $0 + $1.workSteps }, right = runs.reduce(0) { $0 + $1.workSteps - $1.missedSteps.count }
        return Mastery.level(steps == 0 ? 0 : Double(right) / Double(steps))
    }
}

/// Wrong typed answers sorted into what probably went wrong, with the web's words for each (engine/diagnosis).
/// Tried only when the step's own known slips don't match.
public enum Diagnose {
    public enum Kind: String, Sendable { case sign, swap, reuse, place, off1, digits, close }

    public static let say: [Kind: String] = [
        .sign: "The size is right. Check the sign.",
        .swap: "The right numbers, in the wrong boxes.",
        .reuse: "That's the answer to an earlier step. What does this step ask?",
        .place: "The digits are right. Check where the point goes.",
        .off1: "You're 1 away. Count again.",
        .digits: "The right digits in the wrong order.",
        .close: "Close. Do the math again.",
    ]

    public static func kind(_ typed: [String: Double], _ want: [String: Double], earlier: [Double] = []) -> Kind? {
        guard !want.isEmpty, want.keys.allSatisfy({ typed[$0] != nil }) else { return nil }
        if want.count > 1 {
            let t = want.keys.sorted().map { typed[$0]! }, w = want.keys.sorted().map { want[$0]! }
            if t.sorted() == w.sorted() { return .swap }
            if zip(t, w).allSatisfy({ abs($0 + $1) < 1e-9 }) { return .sign }
            return nil
        }
        let (k, w) = want.first!, a = typed[k]!
        let eq = { (x: Double, y: Double) in abs(x - y) < 1e-9 }
        if eq(a, -w), w != 0 { return .sign }
        if earlier.contains(where: { eq($0, a) }), !eq(a, w) { return .reuse }
        for f in [10.0, 100, 1000, 0.1, 0.01, 0.001] where eq(a, w * f) { return .place }
        if eq(abs(a - w), 1) { return .off1 }
        if abs(a) >= 10, abs(w) >= 10, String(String(Int(abs(a).rounded())).sorted()) == String(String(Int(abs(w).rounded())).sorted()), a == a.rounded(), w == w.rounded() { return .digits }
        if w != 0, abs(a - w) / abs(w) <= 0.1 { return .close }
        return nil
    }

    public static func say(_ typed: [String: Double], _ want: [String: Double], earlier: [Double] = []) -> String? {
        kind(typed, want, earlier: earlier).flatMap { say[$0] }
    }
}
