import Foundation

enum DistanceClass: String, Codable, CaseIterable, Identifiable {
    case unknown
    case twoPoint
    case threePoint
    case freeThrow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .twoPoint:
            return "2PT"
        case .threePoint:
            return "3PT"
        case .freeThrow:
            return "FT"
        }
    }
}
