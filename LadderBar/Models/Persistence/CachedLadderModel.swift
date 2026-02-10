import Foundation
import SwiftData

@Model
final class CachedLadderModel {
    @Attribute(.unique) var gradeId: String
    var gradeName: String
    var jsonData: Data
    var lastFetched: Date

    init(gradeId: String, gradeName: String, jsonData: Data) {
        self.gradeId = gradeId
        self.gradeName = gradeName
        self.jsonData = jsonData
        self.lastFetched = Date()
    }
}
