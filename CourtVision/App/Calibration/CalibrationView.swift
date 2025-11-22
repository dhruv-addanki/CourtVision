import SwiftUI

struct CalibrationView: View {
    @ObservedObject var viewModel: CalibrationViewModel
    @ObservedObject var sessionViewModel: ShootSessionViewModel
    @ObservedObject var cameraService: CameraService
    let aiInsightsService: any AIInsightsProviding

    @State private var navigateToSession = false
    @State private var showPermissionAlert = false

    var body: some View {
        ZStack {
            if cameraService.isCameraAvailable {
                CameraPreviewView(session: cameraService.session)
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.12))
            } else {
                Color.black.ignoresSafeArea()
            }

            CalibrationEditorOverlay(calibration: $viewModel.calibration, selectedTool: $viewModel.selectedTool)
                .ignoresSafeArea()

            if !cameraService.isCameraAvailable {
                CameraUnavailableOverlay(
                    title: "Camera unavailable",
                    message: "Use a physical device or enable camera access to see the live preview."
                )
            }

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Align overlays to your hoop and court")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Drag shapes to match the rim, backboard, and a reference line. Switch tools below.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                Spacer()
                controlPanel
            }
            .padding()
        }
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    viewModel.reset()
                }
                .tint(.yellow)
            }
        }
        .task {
            await sessionViewModel.requestCameraAccessIfNeeded()
            showPermissionAlert = sessionViewModel.cameraAccessDenied
            if !sessionViewModel.cameraAccessDenied {
                cameraService.startRunning()
            }
        }
        .alert("Camera access needed", isPresented: $showPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable camera access in Settings to calibrate the hoop.")
        }
        .background(
            NavigationLink(
                destination: ShootSessionView(
                    viewModel: sessionViewModel,
                    aiInsightsService: aiInsightsService
                ),
                isActive: $navigateToSession
            ) {
                EmptyView()
            }
            .hidden()
        )
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            Picker("Tool", selection: $viewModel.selectedTool) {
                ForEach(CalibrationTool.allCases) { tool in
                    Text(tool.title).tag(tool)
                }
            }
            .pickerStyle(.segmented)

            Button {
                guard viewModel.isValid else { return }
                sessionViewModel.startSession(with: viewModel.calibration)
                navigateToSession = true
            } label: {
                Text("Save & Start Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!viewModel.isValid)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Overlay Editor

private struct CalibrationEditorOverlay: View {
    @Binding var calibration: CourtCalibration
    @Binding var selectedTool: CalibrationTool

    @State private var rimDragStart: CGPoint?
    @State private var rimRadiusStart: CGFloat?
    @State private var rectOriginStart: CGPoint?
    @State private var rectSizeStart: CGSize?
    @State private var lineStartPoint: CGPoint?
    @State private var lineEndPoint: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                backboardLayer(size: size)
                rimLayer(size: size)
                lineLayer(size: size)
            }
        }
    }

    private func rimLayer(size: CGSize) -> some View {
        let center = point(from: calibration.rim.center, in: size)
        let radius = calibration.rim.radius * min(size.width, size.height)
        let selected = selectedTool == .rim

        return Circle()
            .stroke(selected ? Color.green : Color.white.opacity(0.8), lineWidth: selected ? 4 : 2)
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .gesture(
                selected ?
                DragGesture()
                    .onChanged { value in
                        if rimDragStart == nil {
                            rimDragStart = calibration.rim.center
                        }
                        guard let start = rimDragStart else { return }
                        let delta = normalizedDelta(from: value.translation, in: size)
                        calibration.rim.center = clamp(point: CGPoint(x: start.x + delta.x, y: start.y + delta.y))
                    }
                    .onEnded { _ in
                        rimDragStart = nil
                    }
                : nil
            )
            .overlay(
                Group {
                    Circle()
                        .fill(selected ? Color.green : Color.white)
                        .frame(width: 16, height: 16)
                        .position(CGPoint(x: center.x + radius, y: center.y))
                        .gesture(
                            selected ?
                            DragGesture()
                                .onChanged { value in
                                    if rimRadiusStart == nil {
                                        rimRadiusStart = calibration.rim.radius
                                    }
                                    guard let start = rimRadiusStart else { return }
                                    let delta = value.translation.width / min(size.width, size.height)
                                    let newRadius = max(0.02, start + delta)
                                    calibration.rim.radius = min(newRadius, 0.5)
                                }
                                .onEnded { _ in
                                    rimRadiusStart = nil
                                }
                            : nil
                        )
                }
            )
    }

    private func backboardLayer(size: CGSize) -> some View {
        let rect = CGRect(
            x: calibration.backboard.origin.x * size.width,
            y: calibration.backboard.origin.y * size.height,
            width: calibration.backboard.size.width * size.width,
            height: calibration.backboard.size.height * size.height
        )
        let selected = selectedTool == .backboard

        return Rectangle()
            .stroke(selected ? Color.orange : Color.white.opacity(0.9), lineWidth: selected ? 4 : 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .gesture(
                selected ?
                DragGesture()
                    .onChanged { value in
                        if rectOriginStart == nil {
                            rectOriginStart = calibration.backboard.origin
                        }
                        guard let start = rectOriginStart else { return }
                        let delta = normalizedDelta(from: value.translation, in: size)
                        let newOrigin = clamp(point: CGPoint(x: start.x + delta.x, y: start.y + delta.y))
                        calibration.backboard.origin = newOrigin
                    }
                    .onEnded { _ in
                        rectOriginStart = nil
                    }
                : nil
            )
            .overlay(
                Group {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selected ? Color.orange : Color.white)
                        .frame(width: 16, height: 16)
                        .position(CGPoint(x: rect.maxX, y: rect.maxY))
                        .gesture(
                            selected ?
                            DragGesture()
                                .onChanged { value in
                                    if rectSizeStart == nil {
                                        rectSizeStart = calibration.backboard.size
                                    }
                                    guard let start = rectSizeStart else { return }
                                    let delta = normalizedDelta(from: value.translation, in: size)
                                    let newSize = CGSize(
                                        width: max(0.1, start.width + delta.x),
                                        height: max(0.05, start.height + delta.y)
                                    )
                                    calibration.backboard.size = CGSize(
                                        width: min(newSize.width, 1.0 - calibration.backboard.origin.x),
                                        height: min(newSize.height, 1.0 - calibration.backboard.origin.y)
                                    )
                                }
                                .onEnded { _ in
                                    rectSizeStart = nil
                                }
                            : nil
                        )
                }
            )
    }

    private func lineLayer(size: CGSize) -> some View {
        guard let line = calibration.referenceLine else { return AnyView(EmptyView()) }
        let startPoint = point(from: line.start, in: size)
        let endPoint = point(from: line.end, in: size)
        let selected = selectedTool == .line

        return AnyView(
            ZStack {
                Path { path in
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                .stroke(selected ? Color.cyan : Color.white.opacity(0.8), style: StrokeStyle(lineWidth: selected ? 4 : 2, lineCap: .round, dash: selected ? [] : [6, 6]))

                circleHandle(at: startPoint, color: selected ? .cyan : .white)
                    .gesture(
                        selected ?
                        DragGesture()
                            .onChanged { value in
                                if lineStartPoint == nil {
                                    lineStartPoint = calibration.referenceLine?.start
                                }
                                guard let start = lineStartPoint else { return }
                                let delta = normalizedDelta(from: value.translation, in: size)
                                calibration.referenceLine?.start = clamp(point: CGPoint(x: start.x + delta.x, y: start.y + delta.y))
                            }
                            .onEnded { _ in
                                lineStartPoint = nil
                            }
                        : nil
                    )

                circleHandle(at: endPoint, color: selected ? .cyan : .white)
                    .gesture(
                        selected ?
                        DragGesture()
                            .onChanged { value in
                                if lineEndPoint == nil {
                                    lineEndPoint = calibration.referenceLine?.end
                                }
                                guard let start = lineEndPoint else { return }
                                let delta = normalizedDelta(from: value.translation, in: size)
                                calibration.referenceLine?.end = clamp(point: CGPoint(x: start.x + delta.x, y: start.y + delta.y))
                            }
                            .onEnded { _ in
                                lineEndPoint = nil
                            }
                        : nil
                    )
            }
        )
    }

    private func circleHandle(at point: CGPoint, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 16, height: 16)
            .position(point)
    }

    private func point(from normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    private func normalizedDelta(from translation: CGSize, in size: CGSize) -> CGPoint {
        CGPoint(x: translation.width / size.width, y: translation.height / size.height)
    }

    private func clamp(point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
    }
}
