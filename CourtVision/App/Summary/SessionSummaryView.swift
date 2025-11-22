import SwiftUI

struct SessionSummaryView: View {
    @StateObject var viewModel: SessionSummaryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Session Summary")
                    .font(.largeTitle).bold()

                statsGrid

                VStack(alignment: .leading, spacing: 8) {
                    Text("Shot Events")
                        .font(.headline)
                    if viewModel.events.isEmpty {
                        Text("No shots recorded.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.events) { event in
                            HStack {
                                Circle()
                                    .fill(event.result == .make ? Color.green : Color.red)
                                    .frame(width: 10, height: 10)
                                Text(event.result == .make ? "Make" : "Miss")
                                Spacer()
                                Text(event.distanceClass.displayName)
                                    .foregroundColor(.secondary)
                                Text(event.timestamp.formatted(date: .omitted, time: .standard))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Feedback (coming soon)")
                        .font(.headline)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    } else if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text(viewModel.insights)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadInsights()
        }
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                summaryCard(title: "Attempts", value: "\(viewModel.stats.totalAttempts)")
                summaryCard(title: "Makes", value: "\(viewModel.stats.totalMakes)")
            }
            HStack {
                summaryCard(title: "FG%", value: String(format: "%.0f%%", viewModel.stats.fieldGoalPercentage * 100))
                summaryCard(title: "3PT", value: "\(viewModel.stats.threePointMakes)/\(viewModel.stats.threePointAttempts)")
            }
            HStack {
                summaryCard(title: "FT", value: "\(viewModel.stats.freeThrowMakes)/\(viewModel.stats.freeThrowAttempts)")
                let shortId = String(viewModel.stats.id.uuidString.prefix(6)) + "…"
                summaryCard(title: "Record ID", value: shortId)
            }
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3).bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
