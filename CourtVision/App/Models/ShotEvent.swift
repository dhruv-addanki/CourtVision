import Foundation

enum ShotResult: String, Codable {
    case make
    case miss
}

struct ShotEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let result: ShotResult
    let distanceClass: DistanceClass

    init(id: UUID = UUID(), timestamp: Date = Date(), result: ShotResult, distanceClass: DistanceClass = .unknown) {
        self.id = id
        self.timestamp = timestamp
        self.result = result
        self.distanceClass = distanceClass
    }
}
