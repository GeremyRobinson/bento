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
        along(a, b, glide(t), screen: screen)
    }
    /// The same at `k` of the way (already shaped by its curve).
    public static func along(_ a: PaperCamera, _ b: PaperCamera, _ k: Double, screen: Size) -> PaperCamera {
        let z = a.zoom * pow(b.zoom / a.zoom, k)
        let ca = a.toPaper(Point(screen.width / 2, screen.height / 2)), cb = b.toPaper(Point(screen.width / 2, screen.height / 2))
        let c = Point(ca.x + (cb.x - ca.x) * k, ca.y + (cb.y - ca.y) * k)
        return PaperCamera(x: screen.width / 2 - c.x * z, y: screen.height / 2 - c.y * z, zoom: z)
    }
}

/// How long camera moves take. Tapping a lesson is a slow, gentle glide; other moves fly a little quicker.
public enum CameraTiming {
    // snappier, G 17 Oct (was 0.7 and 1.1)
    public static let fly: Double = 0.5
    public static let glide: Double = 0.75
    /// The paper let go mid-pan coasts for `coastSpan` of these (about a second), each one slowing it to about a
    /// third. A pan let go slower than `coastFrom` points a second just stops.
    public static let coastTime: Double = 0.26
    public static let coastSpan: Double = 4
    public static let coastFrom: Double = 120
    /// Tapping a lesson on the map glides to this zoom, the same however many are tapped one after another (G 17 Oct:
    /// 100%, now the frames are 3 blocks by 2; was 125%).
    public static let selectMax: Double = 1.0
    /// A lesson frames what it shows and may come this close: the same as the tap, so Start doesn't move the camera
    /// (G 17 Oct: 125% for the focus and the target).
    public static let lessonMax: Double = 1.25

    /// Tapping a lesson on the map glides to this zoom (G 26 Oct: 100% was "a little too close"): the lesson with its
    /// neighbours around it.
    public static let tapZoom: Double = 0.85
    /// The zoom a tap on a lesson glides to: 85%, unless the lesson wouldn't fit.
    public static func selectZoom(current: Double, overview: Double, fit: Double) -> Double { min(fit, tapZoom) }
}

/// A camera move in progress, read at any moment: a glide (to a place, a lesson, a step), or a coast (the paper let
/// go mid-pan, carrying on at the finger's speed).
public struct CameraFlight: Sendable {
    public enum Curve: Sendable { case glide, coast }
    public let from: PaperCamera, to: PaperCamera, start: Double, duration: Double, curve: Curve
    public init(from: PaperCamera, to: PaperCamera, start: Double, duration: Double, curve: Curve = .glide) {
        self.from = from; self.to = to; self.start = start; self.duration = duration; self.curve = curve
    }
    /// Let go mid-pan at `velocity` (points a second): the paper slides on the way it was going and slows to a stop.
    /// Nil when it was let go too slowly to move on.
    public static func coast(from: PaperCamera, velocity: Point, start: Double) -> CameraFlight? {
        var v = velocity, speed = (v.x * v.x + v.y * v.y).squareRoot()
        guard speed >= CameraTiming.coastFrom else { return nil }
        // a hard flick goes far, never across the whole sheet at once
        if speed > 5000 { v = Point(v.x * 5000 / speed, v.y * 5000 / speed); speed = 5000 }
        let tau = CameraTiming.coastTime, d = tau * (1 - exp(-CameraTiming.coastSpan))
        return CameraFlight(from: from, to: from.panned(by: v.x * d, v.y * d), start: start,
                            duration: CameraTiming.coastSpan * tau, curve: .coast)
    }
    public func camera(at time: Double, screen: Size) -> PaperCamera {
        guard duration > 0 else { return to }
        let t = (time - start) / duration
        return PaperCamera.along(from, to, curve == .coast ? coastCurve(t) : glide(t), screen: screen)
    }
    public func done(at time: Double) -> Bool { time - start >= duration }
}
