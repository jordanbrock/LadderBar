import Foundation

struct ClubSearchResponse: Codable, Sendable {
    let clubs: ClubSearchResults?
}

struct ClubSearchResults: Codable, Sendable {
    let pageInfo: ClubSearchPageInfo
    let items: [ClubSearchItem]
}

struct ClubSearchPageInfo: Codable, Sendable {
    let page: Int
    let numPages: Int
    let pageSize: Int
    let numEntries: Int
}

struct ClubSearchItem: Codable, Sendable, Identifiable {
    var id: String { organisationGuid }
    let organisationGuid: String
    let name: String
    let shortName: String?
    let stateName: String?
    let logoURL: String?
}
