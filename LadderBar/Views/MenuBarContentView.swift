import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clubListVM: ClubListViewModel?
    @State private var dataManager: DataManager?
    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false

    var body: some View {
        Group {
            if let clubListVM, let dataManager {
                if showingSettings {
                    inlineSettingsView(clubListVM: clubListVM)
                } else if clubListVM.clubs.isEmpty {
                    EmptyStateView(onOpenSettings: { showingSettings = true })
                } else {
                    NavigationStack(path: $navigationPath) {
                        clubListView(clubListVM: clubListVM, dataManager: dataManager)
                            .navigationDestination(for: GradeDestination.self) { dest in
                                LadderView(
                                    gradeId: dest.gradeId,
                                    gradeName: dest.gradeName,
                                    dataManager: dataManager
                                )
                            }
                    }
                }
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 650, height: 500)
        .task {
            let dm = DataManager(modelContext: modelContext)
            dataManager = dm
            let vm = ClubListViewModel(modelContext: modelContext, dataManager: dm)
            clubListVM = vm
            await vm.loadAll()
            dm.startPeriodicRefresh()
        }
    }

    private func inlineSettingsView(clubListVM: ClubListViewModel) -> some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                Button {
                    showingSettings = false
                    Task { await clubListVM.loadAll() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("Back")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.borderless)
                Spacer()
                Text("Settings")
                    .font(.headline)
                Spacer()
                // Invisible spacer to balance the back button
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                    Text("Back")
                        .font(.subheadline)
                }
                .hidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider()

            SettingsView()
        }
    }

    private func clubListView(clubListVM: ClubListViewModel, dataManager: DataManager) -> some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                Image(systemName: "figure.cricket")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("LadderBar")
                    .font(.headline)
                Spacer()
                if dataManager.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Button {
                    Task { await clubListVM.loadAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("Refresh")
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let error = dataManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }

                    ForEach(clubListVM.clubs) { club in
                        ClubSectionView(
                            club: club,
                            dataManager: dataManager,
                            navigationPath: $navigationPath
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // Footer bar
            HStack {
                if let lastUpdated = dataManager.lastUpdated {
                    Text("Updated \(lastUpdated, format: .relative(presentation: .named))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Loading…")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
        }
    }
}

struct GradeDestination: Hashable {
    let gradeId: String
    let gradeName: String
}
