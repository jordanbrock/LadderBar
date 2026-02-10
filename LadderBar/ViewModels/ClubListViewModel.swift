import Foundation
import SwiftData

@Observable
@MainActor
final class ClubListViewModel {
    private let modelContext: ModelContext
    let dataManager: DataManager

    var clubs: [ClubModel] = []

    init(modelContext: ModelContext, dataManager: DataManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        fetchClubs()
    }

    func fetchClubs() {
        let descriptor = FetchDescriptor<ClubModel>(sortBy: [SortDescriptor(\.dateAdded)])
        clubs = (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteClub(_ club: ClubModel) {
        dataManager.clubTeams.removeValue(forKey: club.organisationGuid)
        dataManager.clubSeasons.removeValue(forKey: club.organisationGuid)
        modelContext.delete(club)
        try? modelContext.save()
        fetchClubs()
    }

    func loadAll() async {
        fetchClubs()
        await dataManager.loadAllClubs()
    }
}
