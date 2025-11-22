# Court Vision (v1 scaffold)

SwiftUI iOS scaffold for calibration, mock CV processing, and session tracking.

## Structure
- `CourtVisionApp.swift`: App entry, wires dependencies and navigation stack.
- `App/Core`: Environment + logging helpers.
- `App/Models`: Data models for calibration, stats, events, and session history.
- `App/Camera`: `CameraService` wraps `AVCaptureSession`; `CameraPreviewView` shows live video.
- `App/ComputerVision`: `CVPipeline` protocol, `MockCVPipeline` fake emitter, `VisionShotDetector` stub.
- `App/Calibration`: View + view model for rim/backboard/line overlays with drag/resize handles.
- `App/Session`: Session VM and SwiftUI view for live HUD, overlays, tap-to-simulate shots.
- `App/Summary`: Summary VM + view that lists shots, stats, and mock AI feedback.
- `App/Networking`: `APIClient` placeholder and `MockAIInsightsService`.
- `App/CommonUI`: Shared button styling.

## Flow
1. Home → "Start New Session" opens `CalibrationView` showing camera preview with overlays.
2. User drags/resizes rim circle, backboard rectangle, and reference line; Save starts a session.
3. `ShootSessionView` shows HUD + overlays, forwards camera frames to `MockCVPipeline`, and supports tap (miss) / double-tap (make) to simulate shots.
4. Ending the session navigates to `SessionSummaryView`, which shows stats, shot list, and loads canned AI feedback asynchronously.
5. Completed sessions are cached in-memory for the Past Sessions placeholder.

## Mocks and extension points
- Vision/CoreML: Implement real detection inside `VisionShotDetector` and call it from a concrete `CVPipeline`.
- AI feedback: Replace `MockAIInsightsService` with a network-backed type using `APIClient` (no keys are stored in the client).
- CV Pipeline: `CVPipeline` protocol isolates frame processing and shot event emission.
- Camera: `CameraService` exposes a callback for sample buffers and manages permissions.

## Notes
- Minimum target: iOS 16+. Uses Swift Concurrency and SwiftUI navigation.
- No external dependencies. All services are simple to swap in future releases. 
