import AVFoundation
import Foundation

/// Mock pipeline that ignores frame content and periodically emits fake shot events.
final class MockCVPipeline: CVPipeline {
    var onShotEvent: ((ShotEvent) -> Void)?

    private var timer: Timer?
    private var isActive = false

    func startSession(calibration: CourtCalibration) {
        isActive = true
        startRandomEmitter()
    }

    func stopSession() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }

    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, calibration: CourtCalibration) {
        guard isActive else { return }
        // In a real implementation, Vision/CoreML would inspect the buffer here.
    }

    private func startRandomEmitter() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            guard let self, self.isActive else { return }
            let make = Bool.random()
            let distance: DistanceClass = [.twoPoint, .threePoint, .freeThrow].randomElement() ?? .unknown
            let event = ShotEvent(result: make ? .make : .miss, distanceClass: distance)
            Logging.log("Mock pipeline emitting shot: \(event.result.rawValue)")
            DispatchQueue.main.async {
                self.onShotEvent?(event)
            }
        }
    }
}
