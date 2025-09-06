Ludo Loser (iOS)

Overview
- Variant of Ludo where the loser is the winner: the last player to finish (i.e., to get all tokens into home) is declared the winner. All other Ludo mechanics remain the same.

Project
- SwiftUI iOS app with a basic game model scaffold and placeholder UI.
- Xcode project located at `ludo_loser/LudoLoser.xcodeproj`.

Run
1. Open `ludo_loser/LudoLoser.xcodeproj` in Xcode.
2. Select an iOS Simulator and run.
3. No signing is needed for Simulator; set your team for device builds.

Status
- Production-ready 2‑player Ludo Loser with extended routes and effects.
- Clear board: ring tiles, inner spiral detour, zig‑zag home lanes.
- Online scaffold included (Game Center stubs) — safe message encoding.

Next Steps (suggested)
- Implement full Ludo board, paths, safe squares, captures; wire to UI.
- Fair dice for online: commit-reveal or shared-seed PRNG on start.
- Hook up Game Center UI (present GKMatchmakerViewController) and session flow.
- Add 3–4 player support and spectator-free, turn-synced networking.
- Settings: tokens per player, themes (brown vs black/white), SFX toggle.

Rules and effects
- Core Ludo: 6 to leave yard, blocks stop passing, safe tiles (★), exact to home.
- Variant: first to finish loses (opponent wins immediately).
- Effects on ring: Boost (+1), Jump (+5/−5), Portal (entry→exit), Trap (skip next turn), Detour (12‑step spiral → exit +6).
- 30s turns, strict alternation with automatic skip handling.

Online and security
- Messages are JSON-encoded with version + nonce. Use GKMatch (encrypted).
- Avoid arbitrary decoding; validate message type and size limits.
- Dice fairness: either host-authoritative rolls with broadcast, or commit-reveal.
- No third-party tracking; no analytics SDKs. Respect privacy settings.

Gameplay notes
- Variant: first to finish all tokens loses (the other wins immediately).
- No extra rolls for 6; turns always alternate. If you can’t move, end turn.
- Timer: 30 seconds per turn; if time runs out, turn auto-ends.

Contributing
- Branching: open PRs against `develop`. `main` is protected and tags releases.
- Issues: use “bug” and “feature” labels; include device + iOS version.
- Code style: Swift 5.9+, SwiftUI. Keep functions small, documented, and side‑effect scoped.
- Testing: prefer deterministic seeds when adding rules; avoid flakiness.

Quick start for contributors
1. Fork and clone.
2. Create a topic branch from `develop`: `git checkout -b feature/your-feature`.
3. Run on iOS 15+ simulator. No signing needed for Simulator.
4. Submit PR with screenshots and a short test plan.
