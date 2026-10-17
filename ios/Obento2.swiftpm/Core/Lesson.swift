import Foundation

/// What the paper shows for one step of a lesson: the question, a short hint under it, and the main action.
public struct StepWords: Equatable, Sendable {
    public var say: String
    public var hint: String
    public var action: String
    public init(say: String, hint: String, action: String) { self.say = say; self.hint = hint; self.action = action }
}

/// A small, repeatable random source, so a lesson can be replayed exactly in tests and screenshots.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    var state: UInt64
    public init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
