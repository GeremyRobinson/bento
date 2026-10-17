import Foundation

/// A problem's numbers, by name ("a", "p", "length"...). The picture, the words and the answers are all read from them.
public typealias Numbers = [String: Int]

/// A lesson as data: a generator makes fresh numbers, and the steps are worked out from those numbers.
/// One engine (LessonRun) plays every lesson; a picture master draws it, flat or 3D.
public struct LessonSpec: Sendable {
    public let id: String
    public let title: String
    /// Which picture master draws it: "cubes", "bars".
    public let master: String
    public let generate: @Sendable (inout SeededRandom) -> Numbers
    public let steps: @Sendable (Numbers) -> [LessonStep]

    public init(id: String, title: String, master: String,
                generate: @escaping @Sendable (inout SeededRandom) -> Numbers,
                steps: @escaping @Sendable (Numbers) -> [LessonStep]) {
        self.id = id; self.title = title; self.master = master; self.generate = generate; self.steps = steps
    }
}

public enum StepCamera: Sendable { case flat, tilted }

/// One step: what the paper says, what the child does on the picture, and how the picture and camera look.
public struct LessonStep: Sendable {
    public var words: StepWords
    public var task: MarkTask?
    public var camera: StepCamera
    /// What the picture shows at this step, read by its master ("layers": 2, "match": 1...).
    public var picture: Numbers
    /// Added to the picture after a wrong check (a guide line, say).
    public var onMiss: Numbers
    /// The words that go with `onMiss` ("The fourth ends here").
    public var look: String?

    public init(_ words: StepWords, task: MarkTask? = nil, camera: StepCamera = .flat, picture: Numbers = [:], onMiss: Numbers = [:], look: String? = nil) {
        self.words = words; self.task = task; self.camera = camera; self.picture = picture; self.onMiss = onMiss; self.look = look
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
    public let steps: [LessonStep]
    public private(set) var index = 0
    /// Each marked cell, and the step that marked it.
    public private(set) var marks: [Int: Int] = [:]
    /// A wrong check happened on this step.
    public private(set) var missed = false

    public init(_ spec: LessonSpec, numbers: Numbers) {
        self.spec = spec; self.numbers = numbers; steps = spec.steps(numbers)
    }

    public static func fresh(_ spec: LessonSpec, using rng: inout SeededRandom) -> LessonRun { LessonRun(spec, numbers: spec.generate(&rng)) }

    public var step: LessonStep { steps[index] }
    public var words: StepWords { step.words }
    public var isLast: Bool { index == steps.count - 1 }
    /// The picture as it stands: this step's, plus what a wrong check shows.
    public var picture: Numbers { missed ? step.picture.merging(step.onMiss) { $1 } : step.picture }
    public subscript(_ name: String) -> Int { numbers[name] ?? 0 }

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
        let had = marked
        for c in had where !t.showMe.contains(c) { marks[c] = nil }
        var fresh: [Int] = []
        for c in t.showMe where marks[c] == nil { marks[c] = index; fresh.append(c) }
        return fresh
    }

    public mutating func reset() { for c in marked { marks[c] = nil } }

    /// The main action: check this step's marks, then move on.
    public mutating func go() -> Outcome {
        if let t = step.task {
            let n = marked.count
            let wrong: Mistake.When? = n == 0 && t.want > 0 ? .noneMarked : n < t.want ? .tooFew : n > t.want ? .tooMany : nil
            if let wrong {
                missed = true
                let m = t.mistakes.first { $0.when == wrong } ?? t.mistakes.first { $0.when == .tooFew && wrong == .noneMarked }
                return .notYet(m?.message(n, t.want) ?? "Not yet.")
            }
            if let snap = t.snap { reset(); for c in snap { marks[c] = index } }
        }
        guard !isLast else { return .newProblem }
        index += 1; missed = false
        return .moved(index)
    }
}

/// Every lesson the app can play, by id. The map opens whatever is here; its picture master draws it.
public enum Lessons {
    public static let all: [LessonSpec] = [UnitCubes.spec, AddFractions.spec]
    public static func spec(_ id: String) -> LessonSpec? { all.first { $0.id == id } }
}
