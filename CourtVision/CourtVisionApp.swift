import SwiftUI

@main
struct CourtVisionApp: App {
    private let appEnvironment = AppEnvironment()
    private let cvPipeline: CVPipeline
    private let aiInsightsService: any AIInsightsProviding

    @StateObject private var cameraService: CameraService
    @StateObject private var sessionViewModel: ShootSessionViewModel

    init() {
        let cameraService = CameraService()
        let pipeline = MockCVPipeline()
        let environment = AppEnvironment()
        _cameraService = StateObject(wrappedValue: cameraService)
        _sessionViewModel = StateObject(
            wrappedValue: ShootSessionViewModel(
                cameraService: cameraService,
                cvPipeline: pipeline,
                environment: environment
            )
        )
        self.cvPipeline = pipeline
        self.aiInsightsService = MockAIInsightsService()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(
                    sessionViewModel: sessionViewModel,
                    cameraService: cameraService,
                    aiInsightsService: aiInsightsService,
                    environment: appEnvironment
                )
            }
        }
    }
}
