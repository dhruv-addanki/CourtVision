import Foundation

protocol AIInsightsProviding {
    func fetchInsights(for stats: SessionStats) async throws -> String
}

/// Stubbed service that simulates latency and returns a canned response.
struct MockAIInsightsService: AIInsightsProviding {
    func fetchInsights(for stats: SessionStats) async throws -> String {
        try await Task.sleep(nanoseconds: 400_000_000)
        let fg = String(format: "%.1f", stats.fieldGoalPercentage * 100)
        return """
        You attempted \(stats.totalAttempts) shots and made \(stats.totalMakes). FG%: \(fg)%.
        Expect richer AI-driven coaching tips here in a later release.
        """
    }
}
