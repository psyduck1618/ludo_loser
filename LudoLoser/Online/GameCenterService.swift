import Foundation

#if canImport(GameKit) && false
import GameKit

final class GameCenterService: NSObject, OnlineMatchService, GKMatchDelegate {
    private var match: GKMatch?
    var onReceive: ((OnlineMessage) -> Void)?

    func startHosting() async throws {
        try await authenticate()
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 2
        let vc = GKMatchmakerViewController(matchRequest: request)
        vc?.matchmakerDelegate = self
        // Presenting VC is expected to be handled by the app; stub only.
    }

    func join() async throws { try await startHosting() }

    func send(_ message: OnlineMessage) async throws {
        guard let match else { return }
        let data = try JSONEncoder().encode(message)
        try match.sendData(toAllPlayers: data, with: .reliable)
    }

    private func authenticate() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            GKLocalPlayer.local.authenticateHandler = { vc, error in
                if let error { cont.resume(throwing: error); return }
                if let vc { /* present vc in app later */ return }
                cont.resume()
            }
        }
    }

    // GKMatchDelegate
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        if let msg = try? JSONDecoder().decode(OnlineMessage.self, from: data) {
            onReceive?(msg)
        }
    }
}

extension GameCenterService: GKMatchmakerViewControllerDelegate {
    func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {}
    func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
        self.match = match
        match.delegate = self
    }
}

#else

/// Fallback stub to keep the app compiling without GameKit capability.
final class GameCenterService: OnlineMatchService {
    var onReceive: ((OnlineMessage) -> Void)?
    func startHosting() async throws {}
    func join() async throws {}
    func send(_ message: OnlineMessage) async throws {}
}

#endif
