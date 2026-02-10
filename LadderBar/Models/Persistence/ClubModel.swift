import Foundation
import SwiftData

@Model
final class ClubModel {
    @Attribute(.unique) var organisationGuid: String
    var name: String
    var shortName: String
    var logoURL: String?
    var dateAdded: Date

    init(organisationGuid: String, name: String, shortName: String, logoURL: String? = nil) {
        self.organisationGuid = organisationGuid
        self.name = name
        self.shortName = shortName
        self.logoURL = logoURL
        self.dateAdded = Date()
    }
}
