import Foundation
import SwiftData

@Observable
@MainActor
final class DataManager {
    private let api = CricketAPIService.shared
    private let modelContext: ModelContext

    var clubTeams: [String: [Team]] = [:]  // orgId -> teams
    var clubSeasons: [String: Season] = [:]  // orgId -> current season
    var ladderCache: [String: LaddersResponse] = [:]  // gradeId -> ladders
    var isLoading = false
    var error: String?
    var lastUpdated: Date?

    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 300  // 5 minutes

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCachedLadders()
    }

    func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshAll()
            }
        }
    }

    func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func loadAllClubs() async {
        let descriptor = FetchDescriptor<ClubModel>(sortBy: [SortDescriptor(\.dateAdded)])
        guard let clubs = try? modelContext.fetch(descriptor) else { return }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            for club in clubs {
                group.addTask { @MainActor in
                    await self.loadTeamsForClub(orgId: club.organisationGuid)
                }
            }
        }
        isLoading = false
        lastUpdated = Date()
    }

    func loadTeamsForClub(orgId: String) async {
        do {
            // Find current season
            if clubSeasons[orgId] == nil {
                let seasonsResponse = try await api.fetchSeasons(orgId: orgId)
                if let current = seasonsResponse.seasons.first(where: { $0.isCurrentSeason }) {
                    clubSeasons[orgId] = current
                } else if let latest = seasonsResponse.seasons.first {
                    clubSeasons[orgId] = latest
                }
            }

            guard let season = clubSeasons[orgId] else { return }

            let teamsResponse = try await api.fetchTeams(orgId: orgId, seasonId: season.id)
            clubTeams[orgId] = teamsResponse.teams
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadLadder(gradeId: String) async {
        do {
            let response = try await api.fetchLadders(gradeId: gradeId)
            ladderCache[gradeId] = response
            cacheLadder(gradeId: gradeId, gradeName: response.grade.name, response: response)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func teamIds(forClub orgId: String) -> Set<String> {
        guard let teams = clubTeams[orgId] else { return [] }
        return Set(teams.map(\.id))
    }

    func allClubTeamIds() -> Set<String> {
        var ids = Set<String>()
        for (_, teams) in clubTeams {
            ids.formUnion(teams.map(\.id))
        }
        return ids
    }

    func allClubOrgIds() -> Set<String> {
        let descriptor = FetchDescriptor<ClubModel>()
        guard let clubs = try? modelContext.fetch(descriptor) else { return [] }
        return Set(clubs.map(\.organisationGuid))
    }

    func gradesForClub(orgId: String) -> [TeamGrade] {
        guard let teams = clubTeams[orgId] else { return [] }
        var seen = Set<String>()
        var grades: [TeamGrade] = []
        for team in teams {
            let grade = team.grade ?? team.grades?.first(where: { $0.isCurrent == true }) ?? team.grades?.first
            if let grade, !seen.contains(grade.id) {
                seen.insert(grade.id)
                grades.append(grade)
            }
        }
        return grades.sorted { $0.name < $1.name }
    }

    private func refreshAll() async {
        let descriptor = FetchDescriptor<ClubModel>()
        guard let clubs = try? modelContext.fetch(descriptor) else { return }

        for club in clubs {
            await loadTeamsForClub(orgId: club.organisationGuid)
        }

        let gradeIds = Array(ladderCache.keys)
        for gradeId in gradeIds {
            await loadLadder(gradeId: gradeId)
        }
        lastUpdated = Date()
    }

    private func cacheLadder(gradeId: String, gradeName: String, response: LaddersResponse) {
        guard let data = try? JSONEncoder().encode(response) else { return }

        let descriptor = FetchDescriptor<CachedLadderModel>(
            predicate: #Predicate { $0.gradeId == gradeId }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.jsonData = data
            existing.lastFetched = Date()
        } else {
            let cached = CachedLadderModel(gradeId: gradeId, gradeName: gradeName, jsonData: data)
            modelContext.insert(cached)
        }
        try? modelContext.save()
    }

    private func loadCachedLadders() {
        let descriptor = FetchDescriptor<CachedLadderModel>()
        guard let cached = try? modelContext.fetch(descriptor) else { return }
        let decoder = JSONDecoder()
        for item in cached {
            if let response = try? decoder.decode(LaddersResponse.self, from: item.jsonData) {
                ladderCache[item.gradeId] = response
            }
        }
    }
}
