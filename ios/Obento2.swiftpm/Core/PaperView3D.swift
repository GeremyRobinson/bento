import Foundation

public struct Vec3: Equatable, Sendable {
    public var x: Double, y: Double, z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
    public static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x + b.x, a.y + b.y, a.z + b.z) }
    public static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x - b.x, a.y - b.y, a.z - b.z) }
    public static func * (a: Vec3, k: Double) -> Vec3 { Vec3(a.x * k, a.y * k, a.z * k) }
    public func dot(_ b: Vec3) -> Double { x * b.x + y * b.y + z * b.z }
    public func cross(_ b: Vec3) -> Vec3 { Vec3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x) }
    public var length: Double { sqrt(dot(self)) }
    public var normalized: Vec3 { self * (1 / length) }
    public func lerp(_ b: Vec3, _ k: Double) -> Vec3 { self + (b - self) * k }
}

/// The 3D view of the paper. The paper is the floor (y = 0); paper x is world x, paper y is world z,
/// and one world unit is one big square. Straight above (elevation ~90) it lines up with the flat paper exactly.
public struct PaperView3D: Equatable, Sendable {
    /// Degrees above the paper. 89.9 = looking straight down (90 itself has no "up").
    public var elevation: Double
    /// Degrees of turn around the up axis.
    public var azimuth: Double
    /// Screen points per world unit.
    public var scale: Double
    /// The world point at the centre of the screen.
    public var target: Vec3

    public static let flat: Double = 89.9
    public static let tilted = (elevation: 52.0, azimuth: -28.0)

    public init(elevation: Double = PaperView3D.flat, azimuth: Double = 0, scale: Double = Paper.unit, target: Vec3 = Vec3(0, 0, 0)) {
        self.elevation = elevation; self.azimuth = azimuth; self.scale = scale; self.target = target
    }

    /// `dir` points from the target toward the camera; `right` and `up` are the screen's axes in the world.
    public var axes: (dir: Vec3, right: Vec3, up: Vec3) {
        let e = elevation * .pi / 180, a = azimuth * .pi / 180
        let dir = Vec3(cos(e) * sin(a), sin(e), cos(e) * cos(a))
        let right = Vec3(0, 1, 0).cross(dir).normalized
        return (dir, right, dir.cross(right).normalized)
    }

    /// The same view as the flat paper camera, so the hand-over from 2D to 3D doesn't move a single line.
    public static func matching(_ cam: PaperCamera, screen: Size) -> PaperView3D {
        let c = cam.toPaper(Point(screen.width / 2, screen.height / 2))
        return PaperView3D(scale: cam.zoom * Paper.unit, target: Vec3(c.x / Paper.unit, 0, c.y / Paper.unit))
    }

    /// The flat paper camera for this view, used to hand back after tilting flat again.
    public func paperCamera(screen: Size) -> PaperCamera {
        let floor = floorPoint(under: target)
        let z = scale / Paper.unit
        return PaperCamera(x: screen.width / 2 - floor.x * Paper.unit * z, y: screen.height / 2 - floor.z * Paper.unit * z, zoom: z)
    }

    public func project(_ p: Vec3, screen: Size) -> Point {
        let (_, r, u) = axes, d = p - target
        return Point(screen.width / 2 + d.dot(r) * scale, screen.height / 2 - d.dot(u) * scale)
    }

    /// The point on the paper under a screen point (for taps).
    public func unproject(_ s: Point, screen: Size) -> Vec3 {
        let (_, r, u) = axes
        let q = target + r * ((s.x - screen.width / 2) / scale) + u * ((screen.height / 2 - s.y) / scale)
        return floorPoint(under: q)
    }

    /// The point on the paper at the centre of the screen.
    public var floorTarget: Vec3 { floorPoint(under: target) }

    /// Slides a point along the view direction down onto the paper.
    func floorPoint(under q: Vec3) -> Vec3 { q - axes.dir * (q.y / axes.dir.y) }

    public static func between(_ a: PaperView3D, _ b: PaperView3D, _ t: Double) -> PaperView3D {
        let k = ease(t)
        return PaperView3D(elevation: a.elevation + (b.elevation - a.elevation) * k,
                           azimuth: a.azimuth + (b.azimuth - a.azimuth) * k,
                           scale: a.scale * pow(b.scale / a.scale, k),
                           target: a.target.lerp(b.target, k))
    }

    /// Screen width a set of world points takes up.
    public func width(of points: [Vec3]) -> Double {
        let r = axes.right, xs = points.map { $0.dot(r) }
        return ((xs.max() ?? 0) - (xs.min() ?? 0)) * scale
    }
}
