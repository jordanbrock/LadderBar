import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClubModel.dateAdded) private var clubs: [ClubModel]

    @State private var searchText = ""
    @State private var searchResults: [ClubSearchItem] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage Clubs")
                .font(.title2.weight(.semibold))

            addClubSection
            Divider()
            savedClubsList
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var addClubSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a Club")
                .font(.headline)

            HStack {
                TextField("Search for a club…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: searchText) { _, newValue in
                        scheduleSearch(newValue)
                    }

                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let error = searchError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !searchResults.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(searchResults) { item in
                            let alreadyAdded = clubs.contains { $0.organisationGuid == item.organisationGuid }
                            HStack(spacing: 10) {
                                clubLogo(url: item.logoURL, size: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        if let shortName = item.shortName, !shortName.isEmpty {
                                            Text(shortName)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let state = item.stateName {
                                            Text(state)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }

                                Spacer()

                                if alreadyAdded {
                                    Text("Added")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Button("Add") {
                                        addClub(item)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)

                            if item.id != searchResults.last?.id {
                                Divider().padding(.leading, 42)
                            }
                        }
                    }
                }
                .frame(maxHeight: 160)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor)))
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
                Text("No clubs added yet. Search for a club above to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(clubs) { club in
                        HStack(spacing: 10) {
                            clubLogo(url: club.logoURL, size: 20)

                            VStack(alignment: .leading) {
                                Text(club.name)
                                    .font(.subheadline)
                                if !club.shortName.isEmpty {
                                    Text(club.shortName)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
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

    private func scheduleSearch(_ term: String) {
        searchTask?.cancel()
        searchError = nil

        let trimmed = term.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        searchTask = Task {
            // Debounce: wait 300ms before firing
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            do {
                let response = try await CricketAPIService.shared.searchClubs(term: trimmed)
                guard !Task.isCancelled else { return }
                searchResults = response.clubs?.items ?? []
            } catch {
                guard !Task.isCancelled else { return }
                searchError = "Search failed: \(error.localizedDescription)"
                searchResults = []
            }
            isSearching = false
        }
    }

    private func addClub(_ item: ClubSearchItem) {
        let club = ClubModel(
            organisationGuid: item.organisationGuid,
            name: item.name,
            shortName: item.shortName ?? "",
            logoURL: item.logoURL
        )
        modelContext.insert(club)
        try? modelContext.save()
    }

    private func deleteClub(_ club: ClubModel) {
        modelContext.delete(club)
        try? modelContext.save()
    }
}
