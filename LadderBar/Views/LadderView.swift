import SwiftUI

struct LadderView: View {
    @State private var viewModel: LadderViewModel

    init(gradeId: String, gradeName: String, dataManager: DataManager) {
        _viewModel = State(initialValue: LadderViewModel(
            gradeId: gradeId,
            gradeName: gradeName,
            dataManager: dataManager
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Grade header
            VStack(spacing: 2) {
                Text(viewModel.gradeName)
                    .font(.subheadline.weight(.semibold))
                if let orgName = viewModel.laddersResponse?.grade.organisation?.name {
                    Text(orgName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) { Divider() }

            if viewModel.availableLadders.count > 1 {
                Picker("Format", selection: $viewModel.selectedLadderName) {
                    ForEach(viewModel.availableLadders) { ladder in
                        Text(ladder.name).tag(ladder.name)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            ZStack(alignment: .top) {
                if let ladder = viewModel.selectedLadder {
                    LadderTableView(
                        ladder: ladder,
                        clubTeamIds: viewModel.clubTeamIds,
                        clubOrgIds: viewModel.clubOrgIds
                    )
                } else if !viewModel.isLoading {
                    Spacer()
                    Text("No ladder data available")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                }

                // Inline loading indicator
                if viewModel.isLoading {
                    if viewModel.selectedLadder == nil {
                        VStack {
                            Spacer()
                            ProgressView("Loading ladder…")
                                .font(.caption)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Refreshing…")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle(viewModel.gradeName)
        .task {
            await viewModel.load()
        }
    }
}
