import AVFoundation
import Foundation

/// Describes a computer-vision pipeline that consumes frames and emits shot events.
protocol CVPipeline: AnyObject {
    var onShotEvent: ((ShotEvent) -> Void)? { get set }

    func startSession(calibration: CourtCalibration)
    func stopSession()
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, calibration: CourtCalibration)
}
