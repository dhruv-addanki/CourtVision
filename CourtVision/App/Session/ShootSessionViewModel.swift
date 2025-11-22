import AVFoundation
import Foundation

/// Manages the active shootaround session, piping camera frames to CV, handling shot events, and aggregating stats.
@MainActor
final class ShootSessionViewModel: ObservableObject {
    @Published var calibration: CourtCalibration
    @Published var stats = SessionStats()
    @Published var events: [ShotEvent] = []
    @Published var isSessionActive = false
    @Published var pastSessions: [SessionRecord] = []
    @Published var cameraAccessDenied = false

    private let cameraService: CameraService
    private let cvPipeline: CVPipeline
    private let environment: AppEnvironment

    init(
        cameraService: CameraService,
        cvPipeline: CVPipeline,
        environment: AppEnvironment,
        calibration: CourtCalibration = CourtCalibration()
    ) {
        self.cameraService = cameraService
        self.cvPipeline = cvPipeline
        self.environment = environment
        self.calibration = calibration
        super.init()
        bindPipeline()
    }

    var cameraSession: AVCaptureSession {
        cameraService.session
    }

    func requestCameraAccessIfNeeded() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await cameraService.requestAccess()
            cameraAccessDenied = !granted
        } else if status != .authorized {
            cameraAccessDenied = true
        } else {
            cameraAccessDenied = false
        }
    }

    func startSession(with calibration: CourtCalibration) {
        guard calibration.isValid else {
            Logging.log("Calibration invalid; refusing to start session", level: .warning)
            return
        }

        self.calibration = calibration
        stats = SessionStats()
        events = []
        isSessionActive = true
        cvPipeline.startSession(calibration: calibration)
        cameraService.startRunning()
    }

    func endSession() {
        guard isSessionActive else { return }
        isSessionActive = false
        cvPipeline.stopSession()
        cameraService.stopRunning()
        archiveCurrentSession()
    }

    func registerManualShot(result: ShotResult, distance: DistanceClass = .unknown) {
        handle(event: ShotEvent(result: result, distanceClass: distance))
    }

    private func bindPipeline() {
        cameraService.onSampleBuffer = { [weak self] buffer in
            guard let self else { return }
            Task.detached(priority: .userInitiated) {
                self.cvPipeline.processSampleBuffer(buffer, calibration: self.calibration)
            }
        }

        cvPipeline.onShotEvent = { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                self.handle(event: event)
            }
        }
    }

    private func handle(event: ShotEvent) {
        stats.record(event: event)
        events.append(event)
    }

    private func archiveCurrentSession() {
        guard stats.totalAttempts > 0 else { return }
        let record = SessionRecord(stats: stats, events: events)
        pastSessions.insert(record, at: 0)
    }
}
