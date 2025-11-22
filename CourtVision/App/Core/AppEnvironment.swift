import Foundation

/// Simple container for runtime configuration and feature flags.
struct AppEnvironment {
    var apiBaseURL: URL? = nil
    var enableMockShotGeneration: Bool = true
    var environmentName: String = "Development"
}
