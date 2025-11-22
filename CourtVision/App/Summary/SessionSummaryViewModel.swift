import Foundation

/// Loads AI feedback for a completed session and exposes stats for presentation.
@MainActor
final class SessionSummaryViewModel: ObservableObject {
    @Published var stats: SessionStats
    @Published var events: [ShotEvent]
    @Published var insights: String = "Loading AI feedback..."
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService: any AIInsightsProviding

    init(stats: SessionStats, events: [ShotEvent], aiService: any AIInsightsProviding) {
        self.stats = stats
        self.events = events
        self.aiService = aiService
    }

    func loadInsights() {
        Task {
            await fetchInsights()
        }
    }

    private func fetchInsights() async {
        isLoading = true
        errorMessage = nil
        do {
            let text = try await aiService.fetchInsights(for: stats)
            insights = text
        } catch {
            errorMessage = "Unable to load AI feedback right now."
        }
        isLoading = false
    }
}
