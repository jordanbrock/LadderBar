import SwiftUI
import SwiftData

struct MenuBarContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clubListVM: ClubListViewModel?
    @State private var dataManager: DataManager?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        Group {
            if let clubListVM, let dataManager {
                if clubListVM.clubs.isEmpty {
                    EmptyStateView()
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
        .frame(width: 600, height: 500)
        .task {
            let dm = DataManager(modelContext: modelContext)
            dataManager = dm
            let vm = ClubListViewModel(modelContext: modelContext, dataManager: dm)
            clubListVM = vm
            await vm.loadAll()
            dm.startPeriodicRefresh()
        }
    }

    private func clubListView(clubListVM: ClubListViewModel, dataManager: DataManager) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
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
                    }
                    .buttonStyle(.borderless)
                    SettingsLink {
                        Image(systemName: "gear")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if let error = dataManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                ForEach(clubListVM.clubs) { club in
                    ClubSectionView(
                        club: club,
                        dataManager: dataManager,
                        navigationPath: $navigationPath
                    )
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct GradeDestination: Hashable {
    let gradeId: String
    let gradeName: String
}
