import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Game state and rules engine for the 2‑player "Ludo Loser" variant.
///
/// Rules summary (high‑level):
/// - Standard Ludo movement (6 to leave yard, exact to home, captures, blocks, safe tiles)
/// - Variant win condition: the FIRST to finish all tokens LOSES (the other player wins)
/// - Effects on ring landing: boost(+1), jump(+5/−5), portal(entry→exit), trap(skip next turn), detour(spiral)
/// - Strict alternating turns, 30s timer, auto‑end when no moves
@MainActor
final class Game: ObservableObject {
    // MARK: Config
    let numberOfPlayers: Int
    let tokensPerPlayer: Int
    /// Number of cells around the outer ring
    private let trackLength = 52
    /// Steps in the inner lane from edge to center
    private let homeLaneLength = 6
    private let boostSquares: Set<Int> = [2, 9, 20, 31, 42]   // ring indexes → +1 step
    private let trapSquares: Set<Int>  = [5, 17, 29, 36, 48]  // ring indexes → skip next turn
    private let jumpPlusSquares: Set<Int> = [3, 15, 28, 41]    // +5 forward
    private let jumpMinusSquares: Set<Int> = [7, 23, 35, 49]   // -5 backward
    private let portalMap: [Int:Int] = [11:19, 37:45]          // warp pairs
    private let detourSquares: Set<Int> = [12, 25, 38, 50]     // enter inner spiral and exit +6
    private let detourExitOffset: Int = 6

    // MARK: State
    @Published private(set) var players: [Player] = []
    @Published private(set) var tokens: [Token] = []
    @Published private(set) var currentPlayerIndex: Int = 0
    @Published private(set) var lastRoll: Int? = nil
    @Published private(set) var hasRolledThisTurn: Bool = false
    @Published private(set) var didMoveThisTurn: Bool = false
    @Published private(set) var canEndTurn: Bool = false
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var selectableTokenIDs: Set<UUID> = []
    @Published private(set) var moveTargets: [UUID: BoardPosition] = [:]
    @Published private(set) var turnSecondsRemaining: Int = 30
    @Published var selectedTokenID: UUID? = nil
    @Published var statusMessage: String? = nil

    private var nonSixCounters: [Int] = [0, 0]
    private var autoEndWorkItem: DispatchWorkItem?
    private var skipTurns: [Int] = [0, 0]
    private var turnDeadline: Date? = nil

    var currentPlayer: Player { players[currentPlayerIndex] }
    var winner: Player? { isGameOver ? determineLoserWinner() : nil }

    // MARK: Init
    init(numberOfPlayers: Int = 2, tokensPerPlayer: Int = 4) {
        self.numberOfPlayers = 2
        self.tokensPerPlayer = max(1, tokensPerPlayer)
        setup()
    }

    // MARK: Setup / Reset
    func setup() {
        // Two players: Black and White, mapped to .red and .blue internally
        let p1 = Player(color: .red, name: "Black")
        let p2 = Player(color: .blue, name: "White")
        self.players = [p1, p2]
        self.tokens = []
        for (idx, p) in players.enumerated() {
            for _ in 0..<tokensPerPlayer {
                tokens.append(Token(owner: p.color, position: .yard))
            }
            players[idx].homeCount = 0
        }
        currentPlayerIndex = 0
        lastRoll = nil
        hasRolledThisTurn = false
        didMoveThisTurn = false
        canEndTurn = false
        isGameOver = false
        nonSixCounters = [0, 0]
        selectableTokenIDs = []
        moveTargets = [:]
        skipTurns = [0, 0]
        startTurnTimer()
    }

    func reset() { setup() }

    func resetToTwoPlayers() { setup() }

    // MARK: Turn Timer
    /// (Re)starts the 30s turn timer
    private func startTurnTimer() {
        turnDeadline = Date().addingTimeInterval(30)
        turnSecondsRemaining = 30
    }

    func tick() {
        guard let deadline = turnDeadline, !isGameOver else { return }
        let remain = max(0, Int(deadline.timeIntervalSinceNow.rounded(.down)))
        if remain != turnSecondsRemaining { turnSecondsRemaining = remain }
        if remain == 0 {
            autoEndTurn()
        }
    }

    // MARK: Dice & Turn Flow
    /// Rolls dice once per turn, computes movable tokens and handles pity‑six
    func rollDice() {
        guard !isGameOver, !hasRolledThisTurn else { return }
        var roll = Int.random(in: 1...6)
        let c = nonSixCounters[currentPlayerIndex]
        if c >= 10 { roll = 6 } // pity six after 10 non-six turns
        lastRoll = roll
        hasRolledThisTurn = true
        if roll == 6 { nonSixCounters[currentPlayerIndex] = 0 } else { nonSixCounters[currentPlayerIndex] += 1 }
        Sound.dice()

        computeSelectableTokens(for: roll)
        if selectableTokenIDs.isEmpty {
            canEndTurn = true
            scheduleAutoEnd(after: 0.8)
        }
        if selectableTokenIDs.count == 1, let only = selectableTokenIDs.first { selectedTokenID = only }
    }

    func endTurnIfAllowed() {
        guard !isGameOver else { return }
        guard hasRolledThisTurn || turnSecondsRemaining == 0 else { return }
        // one move per turn rule
        advancePlayer()
    }

    func autoEndTurn() {
        guard !isGameOver else { return }
        advancePlayer()
    }

    /// Advances to next player, honoring any accumulated skip‑turns
    private func advancePlayer() {
        hasRolledThisTurn = false
        didMoveThisTurn = false
        canEndTurn = false
        selectableTokenIDs = []
        moveTargets = [:]
        selectedTokenID = nil
        lastRoll = nil
        // Compute next turn from current player, then apply skip logic
        var next = (currentPlayerIndex + 1) % players.count
        while skipTurns[next] > 0 {
            skipTurns[next] -= 1
            next = (next + 1) % players.count
        }
        currentPlayerIndex = next
        statusMessage = nil
        startTurnTimer()
    }

    // MARK: Moves
    /// Executes the selected move with step‑by‑step animation and landing effects
    func selectAndMove(tokenID: UUID) {
        guard hasRolledThisTurn, !didMoveThisTurn, let target = moveTargets[tokenID] else { return }
        guard let idx = tokens.firstIndex(where: { $0.id == tokenID }) else { return }
        let tok = tokens[idx]
        // Light haptic for feedback
        #if canImport(UIKit)
        if Settings.sfxEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        #endif
        // Step animation along computed path
        let pathSeq = path(for: tok, to: target)
        didMoveThisTurn = true
        canEndTurn = false
        selectableTokenIDs = []
        moveTargets = [:]
        Task { @MainActor in
            for stepPos in pathSeq {
                if let j = tokens.firstIndex(where: { $0.id == tokenID }) {
                    withAnimation(.easeInOut(duration: 0.12)) { tokens[j].position = stepPos }
                    Sound.step()
                }
                try? await Task.sleep(nanoseconds: 140_000_000)
            }
            // Capture check at final landing
            if case let .mainTrack(newIndex) = target {
                if let oppIndex = tokens.firstIndex(where: { $0.owner != tok.owner && $0.position == .mainTrack(index: newIndex) }) {
                    if !safeSquares().contains(newIndex) {
                        tokens[oppIndex].position = .yard
                        Sound.capture()
                    }
                }
            }
            if let j = tokens.firstIndex(where: { $0.id == tokenID }) {
                withAnimation(.easeInOut(duration: 0.10)) { tokens[j].position = target }
            }
            selectedTokenID = nil

            updateHomeCounts()
            if case .home = target { Sound.home() }

            // Landing effects to make play more dynamic
            applyLandingEffects(tokenID: tokenID)

            canEndTurn = true
            if checkEndIfOnlyOneUnfinished() { isGameOver = true }
            scheduleAutoEnd(after: 0.9)
        }
    }

    /// Single‑tap move UX: after rolling, tap a highlighted token to move immediately
    func handleTap(tokenID: UUID) {
        guard hasRolledThisTurn else { return }
        guard selectableTokenIDs.contains(tokenID) else { return }
        // Move immediately on tap for fast play
        selectAndMove(tokenID: tokenID)
    }

    /// Enumerates legal moves for current player and caches target tiles per token
    private func computeSelectableTokens(for roll: Int) {
        selectableTokenIDs = []
        moveTargets = [:]
        let mine = tokens.enumerated().filter { $0.element.owner == players[currentPlayerIndex].color }
        for (_, token) in mine.map({ ($0.offset, $0.element) }) {
            if let target = targetPosition(for: token, roll: roll) {
                selectableTokenIDs.insert(token.id)
                moveTargets[token.id] = target
            }
        }
    }

    /// Computes the landing tile for a token given a rolled value (no effects)
    private func targetPosition(for token: Token, roll: Int) -> BoardPosition? {
        let pIndex = indexFor(color: token.owner)
        switch token.position {
        case .yard:
            if roll == 6 {
                let start = startIndex(for: pIndex)
                // Can't land on a block (two of same color)
                if isBlocked(at: start) { return nil }
                return .mainTrack(index: start)
            }
            return nil
        case let .mainTrack(index):
            let entry = entryIndex(for: pIndex)
            let stepsToEntry = (entry - index + trackLength) % trackLength
            if roll <= stepsToEntry {
                let dest = (index + roll) % trackLength
                // Can't pass through any block, or land on a block (two tokens)
                if blocksOnPath(from: index, steps: roll) { return nil }
                if isBlocked(at: dest) { return nil }
                // Capture allowed only if not safe
                return .mainTrack(index: dest)
            } else {
                let rem = roll - stepsToEntry - 1
                if rem < 0 { return nil }
                if rem < homeLaneLength { return .homeLane(index: rem) }
                if rem == homeLaneLength { return .home }
                return nil
            }
        case let .homeLane(idx):
            let new = idx + roll
            if new < homeLaneLength { return .homeLane(index: new) }
            if new == homeLaneLength { return .home }
            return nil
        case .home:
            return nil
        case .innerTrack:
            // Inner spiral is effect-driven only; not a dice target
            return nil
        }
    }

    // MARK: Helpers
    /// Start ring index for each player (spawn when rolling a 6)
    private func startIndex(for playerIndex: Int) -> Int { playerIndex == 0 ? 0 : 27 }
    /// Entry ring index to inner lane alignment
    private func entryIndex(for playerIndex: Int) -> Int { playerIndex == 0 ? 6 : 32 }
    var portalEntrances: [Int] { Array(portalMap.keys) }
    var portalExits: [Int] { Array(portalMap.values) }
    var jumpPlus: [Int] { Array(jumpPlusSquares) }
    var jumpMinus: [Int] { Array(jumpMinusSquares) }
    private func indexFor(color: PlayerColor) -> Int { players.firstIndex(where: { $0.color == color }) ?? 0 }
    private func safeSquares() -> Set<Int> {
        // Safe squares tuned to our board geometry: starts and entry points + side centers
        return Set([startIndex(for: 0), entryIndex(for: 0), 13, startIndex(for: 1), entryIndex(for: 1), 39])
    }

    private func tokensAtMainIndex(_ idx: Int) -> [Token] {
        tokens.filter {
            if case let .mainTrack(i) = $0.position { return i == idx } else { return false }
        }
    }

    private func isBlocked(at idx: Int) -> Bool {
        let ts = tokensAtMainIndex(idx)
        let groups = Dictionary(grouping: ts, by: { $0.owner })
        return groups.values.contains(where: { $0.count >= 2 })
    }
    private func ownsBlock(at idx: Int, owner: PlayerColor) -> Bool {
        let ts = tokensAtMainIndex(idx).filter { $0.owner == owner }
        return ts.count >= 2
    }

    private func blocksOnPath(from index: Int, steps: Int) -> Bool {
        if steps <= 0 { return false }
        for s in 1..<steps { // intermediate tiles only
            let idx = (index + s) % trackLength
            if isBlocked(at: idx) { return true }
        }
        return false
    }

    /// Returns true if only one player remains unfinished (opponent wins)
    private func checkEndIfOnlyOneUnfinished() -> Bool {
        let unfinished = players.filter { p in p.homeCount < tokensPerPlayer }
        return unfinished.count <= 1
    }

    private func determineLoserWinner() -> Player? {
        // If one player finished, the other wins immediately
        let unfinished = players.filter { $0.homeCount < tokensPerPlayer }
        if unfinished.count == 1 { return unfinished.first }
        if unfinished.isEmpty { return players[(currentPlayerIndex + 1) % players.count] }
        return nil
    }

    // MARK: - Auto end helpers
    private func scheduleAutoEnd(after delay: TimeInterval) {
        autoEndWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.advancePlayer() }
        autoEndWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: - Path building for UI
    /// Builds a UI path (ordered tiles) from current position to target.
    /// Works like a deterministic shortest path on our board graph.
    func path(for token: Token, to target: BoardPosition) -> [BoardPosition] {
        var path: [BoardPosition] = []
        switch token.position {
        case .yard:
            if case let .mainTrack(i) = target { path.append(.mainTrack(index: i)) }
        case let .mainTrack(start):
            switch target {
            case let .mainTrack(dest):
                let steps = (dest - start + trackLength) % trackLength
                if steps > 0 {
                    for s in 1...steps { path.append(.mainTrack(index: (start + s) % trackLength)) }
                }
            case let .homeLane(destLane):
                let entry = entryIndex(for: indexFor(color: token.owner))
                let stepsToEntry = (entry - start + trackLength) % trackLength
                if stepsToEntry > 0 {
                    for s in 1...stepsToEntry { path.append(.mainTrack(index: (start + s) % trackLength)) }
                }
                for i in 0...destLane { path.append(.homeLane(index: i)) }
            case .home:
                let entry = entryIndex(for: indexFor(color: token.owner))
                let stepsToEntry = (entry - start + trackLength) % trackLength
                if stepsToEntry > 0 {
                    for s in 1...stepsToEntry { path.append(.mainTrack(index: (start + s) % trackLength)) }
                }
                for i in 0..<homeLaneLength { path.append(.homeLane(index: i)) }
                path.append(.home)
            case .yard:
                break
            case .innerTrack(_):
                // We never target innerTrack directly in normal moves
                break
            }
        case let .homeLane(cur):
            switch target {
            case let .homeLane(dest) where dest >= cur:
                for i in (cur+1)...dest { path.append(.homeLane(index: i)) }
            case .home:
                for i in (cur+1)...homeLaneLength { if i == homeLaneLength { path.append(.home) } else { path.append(.homeLane(index: i)) } }
            default:
                break
            }
        case .home:
            break
        case let .innerTrack(index):
            switch target {
            case let .innerTrack(dest) where dest >= index:
                for i in (index+1)...dest { path.append(.innerTrack(index: i)) }
            default:
                break
            }
        }
        return path
    }

    // MARK: - Landing effects
    /// Applies boost/portal/jump/trap/detour when a token finishes a move on the ring
    private func applyLandingEffects(tokenID: UUID) {
        guard let idx = tokens.firstIndex(where: { $0.id == tokenID }) else { return }
        let tok = tokens[idx]
        switch tok.position {
        case let .mainTrack(i):
            if detourSquares.contains(i) {
                statusMessage = "Detour +6!"
                Sound.boost()
                let dest = (i + detourExitOffset) % trackLength
                let seq: [BoardPosition] = (1...detourExitOffset).map { .mainTrack(index: (i + $0) % trackLength) }
                Task { @MainActor in
                    for stepPos in seq {
                        if let j = tokens.firstIndex(where: { $0.id == tok.id }) {
                            withAnimation(.easeInOut(duration: 0.10)) { tokens[j].position = stepPos }
                            Sound.step()
                        }
                        try? await Task.sleep(nanoseconds: 120_000_000)
                    }
                    // Capture on arrival
                    if let opp = tokens.firstIndex(where: { $0.owner != tok.owner && $0.position == .mainTrack(index: dest) }) {
                        if !safeSquares().contains(dest) {
                            tokens[opp].position = .yard
                            Sound.capture()
                        }
                    }
                    updateHomeCounts()
                }
                return
            }
            if boostSquares.contains(i) {
                statusMessage = "+1 boost!"
                Sound.boost()
                // try to advance 1
                if let next = targetPosition(for: tok, roll: 1) {
                    // animate a small extra step
                    let seq = path(for: tok, to: next)
                    Task { @MainActor in
                        for stepPos in seq {
                            if let j = tokens.firstIndex(where: { $0.id == tok.id }) {
                                withAnimation(.easeInOut(duration: 0.10)) { tokens[j].position = stepPos }
                                Sound.step()
                            }
                            try? await Task.sleep(nanoseconds: 120_000_000)
                        }
                        if let j = tokens.firstIndex(where: { $0.id == tok.id }) {
                            withAnimation(.easeInOut(duration: 0.08)) { tokens[j].position = next }
                        }
                    }
                }
            } else if let dest = portalMap[i] {
                statusMessage = "Portal!"
                Sound.boost()
                // Warp to mapped index
                withAnimation(.easeInOut(duration: 0.20)) {
                    tokens[idx].position = .mainTrack(index: dest)
                }
                // Capture on arrival if not safe
                if let opp = tokens.firstIndex(where: { $0.owner != tok.owner && $0.position == .mainTrack(index: dest) }) {
                    if !safeSquares().contains(dest) {
                        tokens[opp].position = .yard
                        Sound.capture()
                    }
                }
            } else if jumpPlusSquares.contains(i) {
                statusMessage = "+5 jump!"
                Sound.boost()
                let dest = (i + 5) % trackLength
                let seq: [BoardPosition] = (1...5).map { .mainTrack(index: (i + $0) % trackLength) }
                Task { @MainActor in
                    for stepPos in seq {
                        if let j = tokens.firstIndex(where: { $0.id == tok.id }) {
                            withAnimation(.easeInOut(duration: 0.10)) { tokens[j].position = stepPos }
                            Sound.step()
                        }
                        try? await Task.sleep(nanoseconds: 120_000_000)
                    }
                }
                // Capture on arrival
                if let opp = tokens.firstIndex(where: { $0.owner != tok.owner && $0.position == .mainTrack(index: dest) }) {
                    if !safeSquares().contains(dest) {
                        tokens[opp].position = .yard
                        Sound.capture()
                    }
                }
                updateHomeCounts()
            } else if jumpMinusSquares.contains(i) {
                statusMessage = "-5 jump!"
                Sound.trap()
                let dest = (i - 5 + trackLength) % trackLength
                withAnimation(.easeInOut(duration: 0.20)) {
                    tokens[idx].position = .mainTrack(index: dest)
                }
                if let opp = tokens.firstIndex(where: { $0.owner != tok.owner && $0.position == .mainTrack(index: dest) }) {
                    if !safeSquares().contains(dest) {
                        tokens[opp].position = .yard
                        Sound.capture()
                    }
                }
                updateHomeCounts()
            } else if trapSquares.contains(i) {
                statusMessage = "Skip next turn!"
                Sound.trap()
                skipTurns[currentPlayerIndex] += 1
            } else {
                statusMessage = nil
            }
        default:
            statusMessage = nil
        }
    }

    /// Recomputes per‑player home counts; call after any movement/effect that can reach home
    private func updateHomeCounts() {
        for (i, p) in players.enumerated() {
            let home = tokens.filter { $0.owner == p.color && $0.position == .home }.count
            players[i].homeCount = home
        }
    }

    private var innerTrackLength: Int { 12 }
}
