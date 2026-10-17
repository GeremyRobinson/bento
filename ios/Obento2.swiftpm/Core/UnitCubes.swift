import Foundation

/// Unit cubes: how many cubes fill a box? The child covers the box's floor with squares on the paper,
/// the paper tilts, the squares rise into one layer of cubes, then layers stack until the box is full.
/// Every problem is fresh: the box's size comes from the generator.
public struct UnitCubes: Sendable {
    public struct Box: Equatable, Sendable {
        public let length: Int, width: Int, height: Int
        public init(length: Int, width: Int, height: Int) { self.length = length; self.width = width; self.height = height }
        public var floor: Int { length * width }
        public var volume: Int { floor * height }
    }

    public enum Step: Equatable, Sendable {
        case ask
        case coverFloor
        /// `layers` cubes high so far (1 after the floor rises).
        case stack(layers: Int)
        case done
    }

    public enum Outcome: Equatable, Sendable {
        case moved(Step)
        /// Check pressed with squares still empty.
        case notYet(empty: Int)
        case newProblem
    }

    public let box: Box
    public private(set) var step: Step = .ask
    /// Squares the child has covered, as (x, z) inside the box.
    public private(set) var covered: Set<Cell> = []

    public struct Cell: Hashable, Sendable, Comparable {
        public let x: Int, z: Int
        public init(_ x: Int, _ z: Int) { self.x = x; self.z = z }
        public static func < (a: Cell, b: Cell) -> Bool { (a.z, a.x) < (b.z, b.x) }
    }

    public init(box: Box) { self.box = box }

    /// A fresh box: 2-5 long, 2-4 wide, 2-3 tall, never a cube-shaped floor so length and width read apart.
    public static func generate<R: RandomNumberGenerator>(using rng: inout R) -> UnitCubes {
        var l = 0, w = 0
        repeat { l = Int.random(in: 2...5, using: &rng); w = Int.random(in: 2...4, using: &rng) } while l == w
        return UnitCubes(box: Box(length: max(l, w), width: min(l, w), height: Int.random(in: 2...3, using: &rng)))
    }

    public var layers: Int {
        switch step { case .ask, .coverFloor: 0; case .stack(let n): n; case .done: box.height }
    }

    public var words: StepWords {
        let b = box
        switch step {
        case .ask:
            return StepWords(say: "How many cubes fill this box?", hint: "It is \(b.length) long, \(b.width) wide and \(b.height) tall.", action: "Let’s find out")
        case .coverFloor:
            return StepWords(say: "Cover the floor with squares.", hint: "Tap each square inside the box.", action: "Check")
        case .stack(1):
            return StepWords(say: "One layer: \(b.floor) cubes.", hint: "The box is \(b.height) tall. Add the next layer.", action: "Add a layer")
        case .stack(let n):
            return StepWords(say: "\(n) layers of \(b.floor) is \(n * b.floor).", hint: "Add the next layer.", action: "Add a layer")
        case .done:
            return StepWords(say: "\(b.height) layers of \(b.floor) is \(b.volume).", hint: "Volume = \(b.length) × \(b.width) × \(b.height) = \(b.volume) cubes.", action: "Next problem")
        }
    }

    /// The count under the box while the child covers the floor.
    public var countLine: String { "\(covered.count) of \(box.floor) squares" }

    public func inside(_ c: Cell) -> Bool { c.x >= 0 && c.z >= 0 && c.x < box.length && c.z < box.width }

    /// Tapping a square covers it, tapping again uncovers it. Only while covering the floor.
    @discardableResult
    public mutating func tap(_ c: Cell) -> Bool {
        guard step == .coverFloor, inside(c) else { return false }
        if covered.contains(c) { covered.remove(c) } else { covered.insert(c) }
        return true
    }

    /// The squares still empty, in reading order: what "Show me" fills, one by one.
    public var empty: [Cell] {
        var out: [Cell] = []
        for z in 0..<box.width { for x in 0..<box.length where !covered.contains(Cell(x, z)) { out.append(Cell(x, z)) } }
        return out
    }

    public mutating func showMe() -> [Cell] {
        guard step == .coverFloor else { return [] }
        let e = empty; covered.formUnion(e); return e
    }

    public mutating func reset() { if step == .coverFloor { covered = [] } }

    /// The main action on the paper.
    public mutating func go() -> Outcome {
        switch step {
        case .ask: step = .coverFloor
        case .coverFloor:
            let left = box.floor - covered.count
            guard left == 0 else { return .notYet(empty: left) }
            step = .stack(layers: 1)
        case .stack(let n): step = n + 1 >= box.height ? .done : .stack(layers: n + 1)
        case .done: return .newProblem
        }
        return .moved(step)
    }

    public static func notYetLine(_ empty: Int) -> String {
        "Not yet. \(empty) \(empty == 1 ? "square is" : "squares are") still empty."
    }
}
