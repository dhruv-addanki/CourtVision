import Foundation

struct SessionStats: Identifiable, Codable {
    let id: UUID
    var totalAttempts: Int
    var totalMakes: Int
    var threePointAttempts: Int
    var threePointMakes: Int
    var freeThrowAttempts: Int
    var freeThrowMakes: Int

    init(
        id: UUID = UUID(),
        totalAttempts: Int = 0,
        totalMakes: Int = 0,
        threePointAttempts: Int = 0,
        threePointMakes: Int = 0,
        freeThrowAttempts: Int = 0,
        freeThrowMakes: Int = 0
    ) {
        self.id = id
        self.totalAttempts = totalAttempts
        self.totalMakes = totalMakes
        self.threePointAttempts = threePointAttempts
        self.threePointMakes = threePointMakes
        self.freeThrowAttempts = freeThrowAttempts
        self.freeThrowMakes = freeThrowMakes
    }

    var fieldGoalPercentage: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(totalMakes) / Double(totalAttempts)
    }

    mutating func record(event: ShotEvent) {
        totalAttempts += 1
        if event.result == .make {
            totalMakes += 1
        }

        switch event.distanceClass {
        case .threePoint:
            threePointAttempts += 1
            if event.result == .make {
                threePointMakes += 1
            }
        case .freeThrow:
            freeThrowAttempts += 1
            if event.result == .make {
                freeThrowMakes += 1
            }
        case .twoPoint, .unknown:
            break
        }
    }
}
