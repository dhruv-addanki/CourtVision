import Foundation

struct SessionRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let stats: SessionStats
    let events: [ShotEvent]

    init(id: UUID = UUID(), date: Date = Date(), stats: SessionStats, events: [ShotEvent]) {
        self.id = id
        self.date = date
        self.stats = stats
        self.events = events
    }
}
