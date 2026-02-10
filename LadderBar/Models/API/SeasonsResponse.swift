import Foundation

struct SeasonsResponse: Codable, Sendable {
    let seasons: [Season]
}

struct Season: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let startDate: String?
    let isCurrentSeason: Bool
}
