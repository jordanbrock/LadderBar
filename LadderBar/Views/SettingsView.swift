import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClubModel.dateAdded) private var clubs: [ClubModel]

    @State private var orgIdInput = ""
    @State private var pendingOrg: OrganisationResponse?
    @State private var isLookingUp = false
    @State private var lookupError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Clubs")
                .font(.title2.weight(.semibold))

            addClubSection
            Divider()
            savedClubsList
        }
        .padding(20)
        .frame(width: 450, height: 400)
    }

    @ViewBuilder
    private var addClubSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a Club")
                .font(.headline)

            HStack {
                TextField("Organisation ID", text: $orgIdInput)
                    .textFieldStyle(.roundedBorder)

                Button("Look Up") {
                    Task { await lookUpOrg() }
                }
                .disabled(orgIdInput.trimmingCharacters(in: .whitespaces).isEmpty || isLookingUp)
            }

            if isLookingUp {
                ProgressView("Looking up organisation...")
                    .controlSize(.small)
            }

            if let error = lookupError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let org = pendingOrg {
                HStack {
                    VStack(alignment: .leading) {
                        Text(org.name)
                            .font(.subheadline.weight(.semibold))
                        if let shortName = org.shortName {
                            Text(shortName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Add Club") {
                        addClub(org)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") {
                        pendingOrg = nil
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(.background))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
            }
        }
    }

    @ViewBuilder
    private var savedClubsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Clubs")
                .font(.headline)

            if clubs.isEmpty {
                Text("No clubs added yet. Enter an organisation ID above to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(clubs) { club in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(club.name)
                                    .font(.subheadline)
                                Text(club.organisationGuid)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                deleteClub(club)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .listStyle(.bordered)
            }
        }
    }

    private func lookUpOrg() async {
        let trimmed = orgIdInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLookingUp = true
        lookupError = nil
        pendingOrg = nil

        do {
            let org = try await CricketAPIService.shared.fetchOrganisation(orgId: trimmed)

            // Check if already added
            if clubs.contains(where: { $0.organisationGuid == org.organisationGuid }) {
                lookupError = "\(org.name) is already added."
            } else {
                pendingOrg = org
            }
        } catch {
            lookupError = "Could not find organisation: \(error.localizedDescription)"
        }

        isLookingUp = false
    }

    private func addClub(_ org: OrganisationResponse) {
        let club = ClubModel(
            organisationGuid: org.organisationGuid,
            name: org.name,
            shortName: org.shortName ?? "",
            logoURL: org.logoURL
        )
        modelContext.insert(club)
        try? modelContext.save()
        pendingOrg = nil
        orgIdInput = ""
    }

    private func deleteClub(_ club: ClubModel) {
        modelContext.delete(club)
        try? modelContext.save()
    }
}
