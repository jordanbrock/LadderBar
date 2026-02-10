import SwiftUI

struct EmptyStateView: View {
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.cricket")
                .font(.system(size: 48))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.green, .teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("No Clubs Added")
                .font(.headline)
            Text("Add a cricket club in Settings to start\ntracking ladder standings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
