import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.route {
            case .menu:
                MainMenuView()
            case .localGame:
                GameView(game: appState.game) {
                    appState.showMenu()
                }
            case .onlineLobby:
                OnlineLobbyView()
            }
        }
    }
}

#Preview {
    RootView().environmentObject(AppState())
}

