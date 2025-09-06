import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var appState: AppState

    @State private var showSettings = false
    @State private var showTutorial = false
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.boardWood.opacity(0.95), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Ludo Loser")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                    Text("Chess-themed · Last to finish wins")
                        .foregroundStyle(.white.opacity(0.7))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .stroke(Theme.accent.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)

                    VStack(spacing: 16) {
                        Button {
                            appState.startLocalGame()
                        } label: {
                            Label("Local Match (2 Players)", systemImage: "figure.2.arms.open")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            appState.route = .onlineLobby
                        } label: {
                            Label("Online Match", systemImage: "network")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)

                        HStack(spacing: 16) {
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gear")
                            }

                            Button {
                                showTutorial = true
                            } label: {
                                Label("How To Play", systemImage: "questionmark.circle")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.9))
                    }
                    .padding(20)
                }
                .frame(maxWidth: 480)
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 60)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showTutorial) { TutorialView() }
    }
}

#Preview {
    MainMenuView().environmentObject(AppState())
}
