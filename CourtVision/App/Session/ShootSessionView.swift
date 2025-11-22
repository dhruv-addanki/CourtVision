import SwiftUI

struct ShootSessionView: View {
    @ObservedObject var viewModel: ShootSessionViewModel
    let aiInsightsService: any AIInsightsProviding

    @State private var navigateToSummary = false
    @State private var summaryStats: SessionStats?
    @State private var summaryEvents: [ShotEvent] = []

    var body: some View {
        ZStack {
            if viewModel.cameraUnavailable {
                Color.black.ignoresSafeArea()
            } else {
                CameraPreviewView(session: viewModel.cameraSession)
                    .ignoresSafeArea()
            }

            CalibrationOverlayDisplay(calibration: viewModel.calibration)
                .ignoresSafeArea()

            if viewModel.cameraUnavailable {
                CameraUnavailableOverlay(
                    title: "Camera unavailable",
                    message: "Use a physical device or enable camera access to see the live preview."
                )
            }

            VStack {
                statsHeader
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding()

                Spacer()

                Text("Tap for miss, double-tap for make to simulate shots.")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 8)

                HStack(spacing: 12) {
                    Button(action: {
                        if viewModel.isSessionActive {
                            summaryStats = viewModel.stats
                            summaryEvents = viewModel.events
                            viewModel.endSession()
                            navigateToSummary = true
                        } else {
                            viewModel.startSession(with: viewModel.calibration)
                        }
                    }) {
                        Text(viewModel.isSessionActive ? "End Session" : "Start Session")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.registerManualShot(result: .miss)
        }
        .onTapGesture(count: 2) {
            viewModel.registerManualShot(result: .make)
        }
        .navigationTitle("Shootaround")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !viewModel.isSessionActive {
                viewModel.startSession(with: viewModel.calibration)
            }
        }
        .background(
            NavigationLink(
                destination: summaryView,
                isActive: $navigateToSummary
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private var statsHeader: some View {
        HStack(spacing: 16) {
            statBlock(title: "Attempts", value: "\(viewModel.stats.totalAttempts)")
            statBlock(title: "Makes", value: "\(viewModel.stats.totalMakes)")
            let fgString = String(format: "%.0f%%", viewModel.stats.fieldGoalPercentage * 100)
            statBlock(title: "FG%", value: fgString)
        }
        .foregroundColor(.white)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.title2).bold()
            Text(title.uppercased())
                .font(.caption)
                .tracking(0.8)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var summaryView: some View {
        if let stats = summaryStats {
            let viewModel = SessionSummaryViewModel(stats: stats, events: summaryEvents, aiService: aiInsightsService)
            SessionSummaryView(viewModel: viewModel)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Overlay display

private struct CalibrationOverlayDisplay: View {
    let calibration: CourtCalibration

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                let rect = CGRect(
                    x: calibration.backboard.origin.x * size.width,
                    y: calibration.backboard.origin.y * size.height,
                    width: calibration.backboard.size.width * size.width,
                    height: calibration.backboard.size.height * size.height
                )
                Rectangle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                let rimCenter = CGPoint(
                    x: calibration.rim.center.x * size.width,
                    y: calibration.rim.center.y * size.height
                )
                let rimRadius = calibration.rim.radius * min(size.width, size.height)
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: rimRadius * 2, height: rimRadius * 2)
                    .position(rimCenter)

                if let line = calibration.referenceLine {
                    let start = CGPoint(x: line.start.x * size.width, y: line.start.y * size.height)
                    let end = CGPoint(x: line.end.x * size.width, y: line.end.y * size.height)
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
