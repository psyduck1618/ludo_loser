import SwiftUI

struct OnlineLobbyView: View {
    // Placeholder UI for online — wiring to Game Center presentation requires hosting VC.
    @State private var status: String = "Invite a friend via Game Center"

    var body: some View {
        VStack(spacing: 16) {
            Text("Online Match")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text(status)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                Button { status = "Hosting… (stub)" } label: { Label("Host", systemImage: "antenna.radiowaves.left.and.right") }
                    .buttonStyle(.borderedProminent)
                Button { status = "Joining… (stub)" } label: { Label("Join", systemImage: "person.2.fill") }
                    .buttonStyle(.bordered)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.black, Theme.boardWood.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .padding()
    }
}

#Preview {
    OnlineLobbyView()
}

