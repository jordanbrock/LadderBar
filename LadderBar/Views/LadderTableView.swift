import SwiftUI

struct LadderTableView: View {
    let ladder: Ladder
    let clubTeamIds: Set<String>
    let clubOrgIds: Set<String>

    @State private var showAdvanced = false

    private static let basicColumnIds: Set<String> = [
        "played", "competitionPoints", "quotient", "netRunRate",
        "won", "lost", "ties"
    ]

    private static let preferredOrder = [
        "played", "competitionPoints", "quotient", "netRunRate",
        "won", "lost", "ties", "noResults", "drawn",
        "winOutright", "winFirstInnings", "drawFirstInnings",
        "byes", "forfeits", "adjustments",
        "runsFor", "oversFaced", "wicketsLost",
        "runsAgainst", "oversBowled", "wicketsTaken"
    ]

    private var displayColumns: [LadderColumn] {
        let sorted = ladder.columns.sorted { a, b in
            let ai = Self.preferredOrder.firstIndex(of: a.id) ?? Self.preferredOrder.count
            let bi = Self.preferredOrder.firstIndex(of: b.id) ?? Self.preferredOrder.count
            return ai < bi
        }
        if showAdvanced {
            return sorted
        }
        return sorted.filter { Self.basicColumnIds.contains($0.id) }
    }

    private var allTeams: [TeamStanding] {
        ladder.pools.flatMap(\.teams).sorted { $0.rank < $1.rank }
    }

    private func isHighlighted(_ team: TeamStanding) -> Bool {
        clubTeamIds.contains(team.id) ||
        (team.owningOrganisation.map { clubOrgIds.contains($0.id) } ?? false)
    }

    private func formattedValue(_ datum: LadderDatum?) -> String {
        guard let datum else { return "-" }
        return datum.val.displayString(forColumn: datum.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toggle row
            HStack {
                Spacer()
                Toggle("Advanced", isOn: $showAdvanced.animation(.easeInOut(duration: 0.15)))
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()

            if showAdvanced {
                advancedTable
            } else {
                basicTable
            }
        }
    }

    // MARK: - Basic table (fills width, no horizontal scroll)

    private var basicTable: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 32, alignment: .trailing)
                Text("Team")
                    .padding(.leading, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(displayColumns) { col in
                    Text(col.heading)
                        .frame(width: columnWidth(for: col), alignment: .trailing)
                        .help(col.description ?? col.heading)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .font(.system(.caption, design: .default).weight(.semibold))
            .foregroundStyle(.secondary)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(alignment: .bottom) { Divider() }

            // Rows
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(allTeams.enumerated()), id: \.element.id) { index, team in
                        basicTeamRow(team, index: index)
                    }
                }
            }
        }
    }

    private func basicTeamRow(_ team: TeamStanding, index: Int) -> some View {
        let highlighted = isHighlighted(team)
        let isEvenRow = index % 2 == 0
        return HStack(spacing: 0) {
            HStack(spacing: 4) {
                Spacer()
                if team.rank <= 3 {
                    rankBadge(team.rank)
                }
                Text("\(team.rank)")
            }
            .frame(width: 32)

            Text(team.displayName)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)

            ForEach(displayColumns) { col in
                let value = team.ladderData.first(where: { $0.id == col.id })
                Text(formattedValue(value))
                    .frame(width: columnWidth(for: col), alignment: .trailing)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .font(.system(.callout, design: .default))
        .fontWeight(highlighted ? .semibold : .regular)
        .background {
            rowBackground(highlighted: highlighted, isEvenRow: isEvenRow)
        }
    }

    // MARK: - Advanced table (horizontal scroll for many columns)

    private var advancedTable: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 32, alignment: .trailing)
                    Text("Team")
                        .frame(width: 180, alignment: .leading)
                        .padding(.leading, 8)
                    ForEach(displayColumns) { col in
                        Text(col.heading)
                            .frame(width: columnWidth(for: col), alignment: .trailing)
                            .help(col.description ?? col.heading)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .font(.system(.caption, design: .default).weight(.semibold))
                .foregroundStyle(.secondary)
                .background(Color(nsColor: .windowBackgroundColor))
                .overlay(alignment: .bottom) { Divider() }

                // Rows
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(allTeams.enumerated()), id: \.element.id) { index, team in
                            advancedTeamRow(team, index: index)
                        }
                    }
                }
            }
        }
    }

    private func advancedTeamRow(_ team: TeamStanding, index: Int) -> some View {
        let highlighted = isHighlighted(team)
        let isEvenRow = index % 2 == 0
        return HStack(spacing: 0) {
            HStack(spacing: 4) {
                Spacer()
                if team.rank <= 3 {
                    rankBadge(team.rank)
                }
                Text("\(team.rank)")
            }
            .frame(width: 32)

            Text(team.displayName)
                .frame(width: 180, alignment: .leading)
                .padding(.leading, 8)
                .lineLimit(1)

            ForEach(displayColumns) { col in
                let value = team.ladderData.first(where: { $0.id == col.id })
                Text(formattedValue(value))
                    .frame(width: columnWidth(for: col), alignment: .trailing)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .font(.system(.callout, design: .default))
        .fontWeight(highlighted ? .semibold : .regular)
        .background {
            rowBackground(highlighted: highlighted, isEvenRow: isEvenRow)
        }
    }

    // MARK: - Shared

    @ViewBuilder
    private func rowBackground(highlighted: Bool, isEvenRow: Bool) -> some View {
        if highlighted {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3)
                Color.accentColor.opacity(0.1)
            }
        } else if isEvenRow {
            Color(nsColor: .controlBackgroundColor).opacity(0.3)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private func rankBadge(_ rank: Int) -> some View {
        let color: Color = switch rank {
        case 1: Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: Color(red: 0.8, green: 0.5, blue: 0.2)
        default: Color.clear
        }
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
    }

    private func columnWidth(for col: LadderColumn) -> CGFloat {
        switch col.id {
        case "competitionPoints": return 46
        case "quotient", "netRunRate": return 62
        case "runsFor", "runsAgainst": return 52
        case "oversFaced", "oversBowled": return 52
        default: return 42
        }
    }
}
