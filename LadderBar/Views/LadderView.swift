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
            if viewModel.availableLadders.count > 1 {
                Picker("Format", selection: $viewModel.selectedLadderName) {
                    ForEach(viewModel.availableLadders) { ladder in
                        Text(ladder.name).tag(ladder.name)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if viewModel.isLoading && viewModel.selectedLadder == nil {
                Spacer()
                ProgressView("Loading ladder...")
                Spacer()
            } else if let ladder = viewModel.selectedLadder {
                LadderTableView(
                    ladder: ladder,
                    clubTeamIds: viewModel.clubTeamIds,
                    clubOrgIds: viewModel.clubOrgIds
                )
            } else {
                Spacer()
                Text("No ladder data available")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .navigationTitle(viewModel.gradeName)
        .task {
            await viewModel.load()
        }
    }
}
