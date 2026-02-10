import SwiftUI

struct LadderTableView: View {
    let ladder: Ladder
    let clubTeamIds: Set<String>
    let clubOrgIds: Set<String>

    // Show a subset of key columns to keep the table readable
    private var displayColumns: [LadderColumn] {
        let preferredOrder = ["played", "competitionPoints", "quotient", "netRunRate",
                              "won", "lost", "ties", "noResults", "drawn",
                              "winOutright", "winFirstInnings", "drawFirstInnings",
                              "byes", "forfeits", "adjustments",
                              "runsFor", "oversFaced", "wicketsLost",
                              "runsAgainst", "oversBowled", "wicketsTaken"]
        return ladder.columns.sorted { a, b in
            let ai = preferredOrder.firstIndex(of: a.id) ?? preferredOrder.count
            let bi = preferredOrder.firstIndex(of: b.id) ?? preferredOrder.count
            return ai < bi
        }
    }

    private var allTeams: [TeamStanding] {
        ladder.pools.flatMap(\.teams).sorted { $0.rank < $1.rank }
    }

    private func isHighlighted(_ team: TeamStanding) -> Bool {
        clubTeamIds.contains(team.id) ||
        (team.owningOrganisation.map { clubOrgIds.contains($0.id) } ?? false)
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(spacing: 0) {
                headerRow
                Divider()
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(allTeams) { team in
                            teamRow(team)
                            Divider()
                        }
                    }
                }
            }
        }
        .font(.system(.caption, design: .monospaced))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 24, alignment: .trailing)
            Text("Team")
                .frame(width: 160, alignment: .leading)
                .padding(.leading, 6)
            ForEach(displayColumns) { col in
                Text(col.heading)
                    .frame(width: columnWidth(for: col), alignment: .trailing)
                    .help(col.description ?? col.heading)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .font(.system(.caption, design: .monospaced).weight(.bold))
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func teamRow(_ team: TeamStanding) -> some View {
        let highlighted = isHighlighted(team)
        return HStack(spacing: 0) {
            Text("\(team.rank)")
                .frame(width: 24, alignment: .trailing)
            Text(team.displayName)
                .frame(width: 160, alignment: .leading)
                .padding(.leading, 6)
                .lineLimit(1)
            ForEach(displayColumns) { col in
                let value = team.ladderData.first(where: { $0.id == col.id })
                Text(value?.val.displayString ?? "-")
                    .frame(width: columnWidth(for: col), alignment: .trailing)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(highlighted ? Color.accentColor.opacity(0.15) : Color.clear)
        .fontWeight(highlighted ? .semibold : .regular)
    }

    private func columnWidth(for col: LadderColumn) -> CGFloat {
        switch col.id {
        case "quotient", "netRunRate": return 50
        case "runsFor", "runsAgainst": return 44
        case "oversFaced", "oversBowled": return 44
        default: return 36
        }
    }
}
