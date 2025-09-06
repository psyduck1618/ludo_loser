import SwiftUI

struct ContentView: View {
    @EnvironmentObject var game: Game

    var body: some View {
        VStack(spacing: 16) {
            Text("Ludo Loser")
                .font(.largeTitle)
                .bold()

            Text("Variant: Last to finish wins")
                .foregroundStyle(.secondary)

            Divider()

            VStack(spacing: 8) {
                Text("Current Player: \(game.currentPlayer.displayName)")
                if let lastRoll = game.lastRoll {
                    Text("Last Roll: \(lastRoll)")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button(action: { game.rollDice() }) {
                    Label("Roll Dice", systemImage: "die.face.\(min(max(game.lastRoll ?? 1, 1), 6))")
                }
                .buttonStyle(.borderedProminent)
                .disabled(game.isGameOver)

                Button("End Turn") { game.endTurnIfAllowed() }
                    .buttonStyle(.bordered)
                    .disabled(game.isGameOver || !game.canEndTurn)
            }

            List {
                Section("Players") {
                    ForEach(game.players) { player in
                        HStack {
                            Text(player.displayName)
                            Spacer()
                            Text("Home: \(player.homeCount)/\(game.tokensPerPlayer)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let winner = game.winner {
                    Section("Winner") {
                        Text("\(winner.displayName) — the last to finish! 🏆")
                            .font(.headline)
                    }
                }
            }

            Spacer()

            Button("Reset Game") { game.reset() }
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView().environmentObject(Game(numberOfPlayers: 4, tokensPerPlayer: 4))
}

