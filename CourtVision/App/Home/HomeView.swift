import SwiftUI

struct HomeView: View {
    @ObservedObject var sessionViewModel: ShootSessionViewModel
    let cameraService: CameraService
    let aiInsightsService: any AIInsightsProviding
    let environment: AppEnvironment

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Court Vision")
                    .font(.largeTitle).bold()
                Text("Calibrate your hoop, track shots, and preview future AI feedback.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            NavigationLink {
                CalibrationView(
                    viewModel: CalibrationViewModel(calibration: sessionViewModel.calibration),
                    sessionViewModel: sessionViewModel,
                    cameraService: cameraService,
                    aiInsightsService: aiInsightsService
                )
            } label: {
                Text("Start New Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)

            NavigationLink {
                PastSessionsView(sessionViewModel: sessionViewModel)
            } label: {
                Text("View Past Sessions")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)

            Spacer()

            Text("Env: \(environment.environmentName)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

struct PastSessionsView: View {
    @ObservedObject var sessionViewModel: ShootSessionViewModel

    var body: some View {
        List {
            if sessionViewModel.pastSessions.isEmpty {
                Text("No past sessions yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sessionViewModel.pastSessions) { record in
                    VStack(alignment: .leading) {
                        Text(record.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text("Attempts: \(record.stats.totalAttempts) | Makes: \(record.stats.totalMakes)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Past Sessions")
    }
}
