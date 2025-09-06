import SwiftUI

struct GameView: View {
    @ObservedObject var game: Game
    var onExit: () -> Void
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            header
            boardArea
            controls
            footer
        }
        .padding()
        .background(
            LinearGradient(colors: [.black, Theme.boardWood.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            game.tick()
        }
    }

    private var header: some View {
        HStack {
            Button(action: onExit) {
                Label("Menu", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .tint(.white)
            Spacer()
            Text("Ludo Loser")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            Button(action: { game.resetToTwoPlayers() }) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    private var boardArea: some View {
        GeometryReader { proxy in
            let s = min(proxy.size.width, proxy.size.height) - 32
            VStack(spacing: 16) {
                LudoBoardView(game: game, size: s)
                scoreboard
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxHeight: 520)
    }

    private func playerStack(playerIndex: Int) -> some View {
        let player = game.players[playerIndex]
        let isBlack = playerIndex == 0
        return HStack(spacing: 6) {
            ForEach(0..<game.tokensPerPlayer, id: \.self) { i in
                let filled = i < player.homeCount
                TokenChip(style: isBlack ? .black : .white)
                    .overlay(
                        Circle().stroke(filled ? Theme.accent : Color.clear, lineWidth: filled ? 2 : 0)
                    )
                    .accessibilityLabel("\(player.displayName) token \(i+1) \(filled ? "home" : "in play")")
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Text("Current: \(game.currentPlayer.displayName) · \(game.turnSecondsRemaining)s")
                    .foregroundStyle(.white.opacity(0.95))
                // Subtle time progress bar
                ProgressView(value: Double(30 - game.turnSecondsRemaining), total: 30)
                    .tint(Theme.accent)
                    .progressViewStyle(.linear)
            }
            HStack(spacing: 14) {
                GlassDiceView(value: Binding(get: { game.lastRoll }, set: { _ in }), size: Theme.diceSize) {
                    game.rollDice()
                }
                .grayscale(0.1)
                .disabled(game.hasRolledThisTurn || game.isGameOver)

                VStack(spacing: 8) {
                    if let last = game.lastRoll { Text("Last: \(last)") }
                    Text(game.hasRolledThisTurn ? "Tap a highlighted token to move" : "Roll to play")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                    // Small spinner to replace big pulsing circle on board
                    if !game.isGameOver && !game.hasRolledThisTurn {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Theme.accent)
                    }
                    if let msg = game.statusMessage {
                        Text(msg)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var scoreboard: some View {
        HStack(spacing: 12) {
            ForEach(Array(game.players.enumerated()), id: \.offset) { idx, p in
                VStack {
                    Text(p.displayName)
                        .font(.headline)
                        .foregroundStyle(idx == 0 ? Theme.boardLight : Theme.boardDark)
                        .padding(.bottom, 2)
                    ProgressView(value: Double(p.homeCount), total: Double(game.tokensPerPlayer))
                        .tint(Theme.accent)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var footer: some View {
        Group {
            if let winner = game.winner {
                Text("Winner: \(winner.displayName) — last to finish!")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GameView(game: Game(numberOfPlayers: 2, tokensPerPlayer: 4)) { }
}
