import Foundation

struct TeamsResponse: Codable, Sendable {
    let teams: [Team]
}

struct Team: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let grade: TeamGrade?
    let grades: [TeamGrade]?
}

struct TeamGrade: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let isCurrent: Bool?
    let owningOrganisation: GradeOrganisation?
}

struct GradeOrganisation: Codable, Sendable {
    let id: String
    let name: String?
    let shortName: String?
    let logoUrl: String?
}
