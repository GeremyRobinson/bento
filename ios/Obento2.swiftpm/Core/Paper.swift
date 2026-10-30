import Foundation

/// The paper is the whole app. Everything is drawn on its grid and measured in its cells.
public enum Paper {
    /// One cell of the grid, in points at 100% zoom.
    public static let cell: Double = 20
    /// A strong line every this many cells.
    public static let major = 5
    /// One big square (5 x 5 cells). In 3D lessons one cube sits on one big square.
    public static let unit: Double = cell * Double(major)
    public static let minZoom: Double = 0.25
    public static let maxZoom: Double = 2.5

    /// Snaps a paper coordinate to the nearest grid line.
    public static func snap(_ v: Double, to step: Double = cell) -> Double { (v / step).rounded() * step }
}

public struct Point: Equatable, Sendable {
    public var x: Double, y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
}

public struct Size: Equatable, Sendable {
    public var width: Double, height: Double
    public init(_ width: Double, _ height: Double) { self.width = width; self.height = height }
}

public struct Rect: Equatable, Sendable {
    public var x: Double, y: Double, width: Double, height: Double
    public init(x: Double, y: Double, width: Double, height: Double) { self.x = x; self.y = y; self.width = width; self.height = height }
    public var mid: Point { Point(x + width / 2, y + height / 2) }
    /// The smallest rect holding both.
    public func union(_ o: Rect) -> Rect {
        let x0 = min(x, o.x), y0 = min(y, o.y)
        return Rect(x: x0, y: y0, width: max(x + width, o.x + o.width) - x0, height: max(y + height, o.y + o.height) - y0)
    }
}

/// The ease drawing uses (lines stroking on, words fading in): slow start, slow finish.
public func ease(_ t: Double) -> Double {
    let t = min(1, max(0, t))
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}

/// The path every camera glide follows (G 29 Oct: moves that feel real, not digital): a critically damped spring's.
/// It sets off at once and comes to rest softly, the way something with weight does, instead of a timer's curve that
/// creeps off and creeps in. Scaled to land exactly at t = 1 (where the spring has a few hundredths of its speed left).
public func glide(_ t: Double) -> Double {
    let t = min(1, max(0, t)), w = 7.5
    func x(_ t: Double) -> Double { 1 - (1 + w * t) * exp(-w * t) }
    return x(t) / x(1)
}

/// The path of the paper let go mid-pan: it leaves at the finger's speed and slows evenly to a stop, like a sheet
/// slid across a table (its speed falling by the same share each moment). Scaled to stop exactly at t = 1.
public func coastCurve(_ t: Double) -> Double {
    let t = min(1, max(0, t)), k = CameraTiming.coastSpan
    return (1 - exp(-k * t)) / (1 - exp(-k))
}
