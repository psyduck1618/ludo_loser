import SwiftUI

struct TutorialView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GroupBox(label: Label("Goal", systemImage: "flag.checkered")) {
                        Text("Last to finish wins: the first player to bring all tokens home actually loses — the other player is the winner.")
                    }
                    GroupBox(label: Label("Turns", systemImage: "clock")) {
                        Text("Alternate turns. 30s per turn. If you can’t move, the turn ends automatically. Some tiles can skip your next turn.")
                    }
                    GroupBox(label: Label("Core Ludo", systemImage: "die.face.6")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Roll a 6 to leave the yard.")
                            Text("• Blocks: two same‑color tokens on a tile block movement.")
                            Text("• Safe tiles (★): landing here prevents captures.")
                            Text("• Exact count to reach home, now via an extended zig‑zag lane.")
                        }
                    }
                    GroupBox(label: Label("Board Effects", systemImage: "sparkles")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Boost (+1): small hop forward.")
                            Text("• Jump +5 / −5: big move forward/back.")
                            Text("• Portal: warp from blue entry to mint exit.")
                            Text("• Trap: skip your next turn.")
                        }
                    }
                    GroupBox(label: Label("Tips", systemImage: "lightbulb")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Because the first to finish loses, sometimes delaying is smart.")
                            Text("• Portals and +5 jumps can backfire if they set you up for capture.")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("How To Play")
        }
    }
}

#Preview { TutorialView() }

