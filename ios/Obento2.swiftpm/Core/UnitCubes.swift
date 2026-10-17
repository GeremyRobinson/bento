import Foundation

/// Unit cubes: how many cubes fill a box? The child covers the box's floor with squares on the paper,
/// the paper tilts, the squares rise into one layer of cubes, then layers stack until the box is full.
/// Numbers: length, width, height. Floor cells are numbered across, then down: z * length + x.
public enum UnitCubes {
    public struct Box: Equatable, Sendable {
        public let length: Int, width: Int, height: Int
        public init(length: Int, width: Int, height: Int) { self.length = length; self.width = width; self.height = height }
        public init(_ n: Numbers) { self.init(length: n["length"] ?? 0, width: n["width"] ?? 0, height: n["height"] ?? 0) }
        public var floor: Int { length * width }
        public var volume: Int { floor * height }
        public var numbers: Numbers { ["length": length, "width": width, "height": height] }
    }

    /// A floor square, as (x, z) inside the box.
    public struct Cell: Hashable, Sendable {
        public let x: Int, z: Int
        public init(_ x: Int, _ z: Int) { self.x = x; self.z = z }
    }

    public static func cell(_ c: Cell, in b: Box) -> Int? { c.x >= 0 && c.z >= 0 && c.x < b.length && c.z < b.width ? c.z * b.length + c.x : nil }
    public static func cell(_ i: Int, in b: Box) -> Cell { Cell(i % b.length, i / b.length) }

    /// A fresh box: 2-5 long, 2-4 wide, 2-3 tall, never a square floor so length and width read apart.
    public static func generate(using rng: inout SeededRandom) -> Box {
        var l = 0, w = 0
        repeat { l = Int.random(in: 2...5, using: &rng); w = Int.random(in: 2...4, using: &rng) } while l == w
        return Box(length: max(l, w), width: min(l, w), height: Int.random(in: 2...3, using: &rng))
    }

    public static let spec = LessonSpec(id: "uc", title: "Unit cubes", master: "cubes", generate: { generate(using: &$0).numbers }) { n in
        let b = Box(n)
        let ask = LessonStep(StepWords(say: "How many cubes fill this box?", hint: "It is \(b.length) long, \(b.width) wide and \(b.height) tall.", action: "Let’s find out"))
        let floor = Array(0..<b.floor)
        let cover = LessonStep(StepWords(say: "Cover the floor with squares.", hint: "Tap each square inside the box.", action: "Check"),
            task: MarkTask(cells: Set(floor), want: b.floor, showMe: floor,
                           mistakes: [Mistake(.tooFew) { m, w in let e = w - m; return "Not yet. \(e) \(e == 1 ? "square is" : "squares are") still empty." }],
                           count: { "\($0) of \(b.floor) squares" }))
        let stack = (1..<b.height).map { k in
            LessonStep(k == 1 ? StepWords(say: "One layer: \(b.floor) cubes.", hint: "The box is \(b.height) tall. Add the next layer.", action: "Add a layer")
                              : StepWords(say: "\(k) layers of \(b.floor) is \(k * b.floor).", hint: "Add the next layer.", action: "Add a layer"),
                       camera: .tilted, picture: ["layers": k])
        }
        let done = LessonStep(StepWords(say: "\(b.height) layers of \(b.floor) is \(b.volume).", hint: "Volume = \(b.length) × \(b.width) × \(b.height) = \(b.volume) cubes.", action: "Next problem"),
                              camera: .tilted, picture: ["layers": b.height, "height": 1])
        return [ask, cover] + stack + [done]
    }
}
