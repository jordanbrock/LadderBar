import SwiftUI

struct ClubSectionView: View {
    let club: ClubModel
    let dataManager: DataManager
    @Binding var navigationPath: NavigationPath
    @State private var isExpanded = true
    @State private var hoveredGradeId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Club header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)

                    clubLogo(url: club.logoURL, size: 24)

                    Text(club.name)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(club.shortName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                        )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if isExpanded {
                let grades = dataManager.gradesForClub(orgId: club.organisationGuid)
                if grades.isEmpty {
                    Text("Loading teams…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 54)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(grades) { grade in
                            Button {
                                navigationPath.append(GradeDestination(gradeId: grade.id, gradeName: grade.name))
                            } label: {
                                HStack(spacing: 6) {
                                    Text(grade.name)
                                        .font(.caption)
                                        .lineLimit(1)
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
                                .padding(.vertical, 5)
                                .padding(.leading, 54)
                                .padding(.trailing, 12)
                                .contentShape(Rectangle())
                                .background(
                                    hoveredGradeId == grade.id
                                        ? Color.accentColor.opacity(0.08)
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)
                            .onHover { isHovered in
                                hoveredGradeId = isHovered ? grade.id : nil
                            }
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func clubLogo(url: String?, size: CGFloat) -> some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "shield")
                        .font(.system(size: size * 0.5))
                        .foregroundStyle(.tertiary)
                default:
                    Color.clear
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Image(systemName: "shield")
                .font(.system(size: size * 0.5))
                .foregroundStyle(.tertiary)
                .frame(width: size, height: size)
        }
    }
}
