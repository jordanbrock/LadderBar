import Foundation

@Observable
@MainActor
final class LadderViewModel {
    private let dataManager: DataManager

    let gradeId: String
    let gradeName: String
    var selectedLadderName: String = "Overall"
    var isLoading = false

    init(gradeId: String, gradeName: String, dataManager: DataManager) {
        self.gradeId = gradeId
        self.gradeName = gradeName
        self.dataManager = dataManager
    }

    var laddersResponse: LaddersResponse? {
        dataManager.ladderCache[gradeId]
    }

    var availableLadders: [Ladder] {
        laddersResponse?.ladders ?? []
    }

    var selectedLadder: Ladder? {
        availableLadders.first(where: { $0.name == selectedLadderName }) ?? availableLadders.first
    }

    var clubTeamIds: Set<String> {
        dataManager.allClubTeamIds()
    }

    var clubOrgIds: Set<String> {
        dataManager.allClubOrgIds()
    }

    func load() async {
        isLoading = true
        await dataManager.loadLadder(gradeId: gradeId)
        isLoading = false
    }
}
