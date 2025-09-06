import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Route {
        case menu
        case localGame
        case onlineLobby
    }

    @Published var route: Route = .menu
    @Published var game: Game

    init() {
        // Restrict to 2 players for now
        self.game = Game(numberOfPlayers: 2, tokensPerPlayer: 4)
    }

    func startLocalGame() {
        game.resetToTwoPlayers()
        route = .localGame
    }

    func showMenu() { route = .menu }
}

