import AVFoundation
import Combine
import Foundation

/// Wraps `AVCaptureSession` configuration, permissions, and frame delivery.
final class CameraService: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var isCameraAvailable = true

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.courtvision.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    /// Called on `sampleBufferQueue` for each captured frame.
    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    private lazy var sampleBufferQueue = DispatchQueue(
        label: "com.courtvision.camera.samplebuffer",
        qos: .userInitiated
    )

    override init() {
        super.init()
        configureSession()
    }

    var session: AVCaptureSession {
        captureSession
    }

    func requestAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        return granted
    }

    func startRunning() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isCameraAvailable else {
                Logging.log("Camera unavailable; start ignored", level: .warning)
                return
            }
            guard self.authorizationStatus == .authorized else {
                Logging.log("Camera access not authorized; start ignored", level: .warning)
                return
            }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func configureSession() {
        guard !isConfigured else { return }
        isConfigured = true
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.captureSession.canAddInput(input) else {
                Logging.log("Unable to create camera input", level: .error)
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                }
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(input)

            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sampleBufferQueue)

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            } else {
                Logging.log("Unable to add video data output", level: .error)
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                }
            }

            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
            }

            self.captureSession.commitConfiguration()
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }
}
