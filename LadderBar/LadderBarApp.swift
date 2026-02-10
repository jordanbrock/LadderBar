import SwiftUI
import SwiftData

@main
struct LadderBarApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ClubModel.self, CachedLadderModel.self])
            let config = ModelConfiguration("LadderBar", schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra("LadderBar", systemImage: "trophy") {
            MenuBarContentView()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }
    }
}
