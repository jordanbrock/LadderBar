import SwiftUI

struct ClubSectionView: View {
    let club: ClubModel
    let dataManager: DataManager
    @Binding var navigationPath: NavigationPath
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 12)
                    Text(club.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(club.shortName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            if isExpanded {
                let grades = dataManager.gradesForClub(orgId: club.organisationGuid)
                if grades.isEmpty {
                    Text("Loading teams...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 28)
                } else {
                    ForEach(grades) { grade in
                        Button {
                            navigationPath.append(GradeDestination(gradeId: grade.id, gradeName: grade.name))
                        } label: {
                            HStack {
                                Text(grade.name)
                                    .font(.caption)
                                Spacer()
                                if let org = grade.owningOrganisation {
                                    Text(org.shortName ?? "")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 28)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()
                .padding(.horizontal)
        }
    }
}
