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
}

/// The one ease every camera move uses: slow start, slow finish.
public func ease(_ t: Double) -> Double {
    let t = min(1, max(0, t))
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}
