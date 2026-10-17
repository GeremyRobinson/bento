import Foundation

/// Where the paper sits on the screen: screen = paper * zoom + offset.
/// The grid is drawn from the same camera, so grid and paper always move as one sheet.
public struct PaperCamera: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var zoom: Double

    public init(x: Double = 0, y: Double = 0, zoom: Double = 1) { self.x = x; self.y = y; self.zoom = zoom }

    public func toScreen(_ p: Point) -> Point { Point(p.x * zoom + x, p.y * zoom + y) }
    public func toPaper(_ s: Point) -> Point { Point((s.x - x) / zoom, (s.y - y) / zoom) }

    /// Pinch or scroll: the paper point under the fingers stays under the fingers.
    public func zoomed(by factor: Double, at s: Point) -> PaperCamera {
        let z = min(Paper.maxZoom, max(Paper.minZoom, zoom * factor)), f = z / zoom
        return PaperCamera(x: s.x - (s.x - x) * f, y: s.y - (s.y - y) * f, zoom: z)
    }

    public func panned(by dx: Double, _ dy: Double) -> PaperCamera { PaperCamera(x: x + dx, y: y + dy, zoom: zoom) }

    /// The camera that shows `rect` whole and centred, with `pad` points around it, never closer than `maxZoom`.
    public static func framing(_ rect: Rect, in screen: Size, pad: Double = 40, maxZoom: Double = Paper.maxZoom) -> PaperCamera {
        let z = min(maxZoom, max(Paper.minZoom, min((screen.width - 2 * pad) / rect.width, (screen.height - 2 * pad) / rect.height)))
        let c = rect.mid
        return PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z)
    }

    /// Between two cameras. Zoom moves in log space so a 2x zoom feels the same speed all the way through,
    /// and the point at the screen centre travels in a straight line on the paper.
    public static func between(_ a: PaperCamera, _ b: PaperCamera, _ t: Double, screen: Size) -> PaperCamera {
        let k = ease(t), z = a.zoom * pow(b.zoom / a.zoom, k)
        let ca = a.toPaper(Point(screen.width / 2, screen.height / 2)), cb = b.toPaper(Point(screen.width / 2, screen.height / 2))
        let c = Point(ca.x + (cb.x - ca.x) * k, ca.y + (cb.y - ca.y) * k)
        return PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z)
    }
}

/// How long camera moves take. Tapping a lesson is a slow, gentle glide; other moves fly a little quicker.
public enum CameraTiming {
    public static let fly: Double = 0.7
    public static let glide: Double = 1.1
    /// Tapping a lesson zooms in a little, not a lot.
    public static let glideZoom: Double = 1.3
}

/// A camera move in progress, read at any moment.
public struct CameraFlight: Sendable {
    public let from: PaperCamera, to: PaperCamera, start: Double, duration: Double
    public init(from: PaperCamera, to: PaperCamera, start: Double, duration: Double) {
        self.from = from; self.to = to; self.start = start; self.duration = duration
    }
    public func camera(at time: Double, screen: Size) -> PaperCamera {
        duration <= 0 ? to : PaperCamera.between(from, to, (time - start) / duration, screen: screen)
    }
    public func done(at time: Double) -> Bool { time - start >= duration }
}
