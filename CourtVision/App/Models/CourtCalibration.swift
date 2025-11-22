import CoreGraphics
import Foundation

/// Describes the calibrated court geometry using normalized screen coordinates.
struct CourtCalibration: Codable, Equatable {
    var rim: CalibrationCircle
    var backboard: CalibrationRectangle
    var referenceLine: CalibrationLine?

    init(
        rim: CalibrationCircle = CalibrationCircle(center: CGPoint(x: 0.5, y: 0.3), radius: 0.08),
        backboard: CalibrationRectangle = CalibrationRectangle(origin: CGPoint(x: 0.35, y: 0.18), size: CGSize(width: 0.3, height: 0.08)),
        referenceLine: CalibrationLine? = CalibrationLine(start: CGPoint(x: 0.2, y: 0.7), end: CGPoint(x: 0.8, y: 0.7))
    ) {
        self.rim = rim
        self.backboard = backboard
        self.referenceLine = referenceLine
    }

    var isValid: Bool {
        rim.radius > 0.01 && backboard.size.width > 0.05 && backboard.size.height > 0.02
    }
}

struct CalibrationCircle: Codable, Equatable {
    var center: CGPoint
    /// Normalized radius relative to the minimum of width/height.
    var radius: CGFloat
}

struct CalibrationRectangle: Codable, Equatable {
    var origin: CGPoint
    var size: CGSize
}

struct CalibrationLine: Codable, Equatable {
    var start: CGPoint
    var end: CGPoint
}
