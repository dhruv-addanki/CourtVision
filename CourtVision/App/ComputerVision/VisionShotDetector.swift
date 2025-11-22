import AVFoundation
import Foundation
import Vision

/// Placeholder for Vision/Core ML powered detection.
/// Insert actual detection of ball/rim/backboard here in a future iteration.
final class VisionShotDetector {
    func detectShot(in sampleBuffer: CMSampleBuffer, calibration: CourtCalibration) -> ShotEvent? {
        // Stub: return nil for now. Later this will run a VNCoreMLRequest or similar.
        _ = calibration
        _ = sampleBuffer
        return nil
    }
}
