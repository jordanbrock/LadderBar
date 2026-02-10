import Foundation

struct OrganisationResponse: Codable, Sendable {
    let organisationGuid: String
    let name: String
    let shortName: String?
    let logoURL: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case organisationGuid
        case name
        case shortName
        case logoURL
        case description
    }
}
