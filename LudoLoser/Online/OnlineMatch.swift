import Foundation

enum OnlineMessageType: String, Codable { case hello, ready, state, roll, endTurn, reset }

struct OnlineMessage: Codable {
    let version: Int
    let type: OnlineMessageType
    let nonce: UUID
    let payload: Data?

    init(type: OnlineMessageType, payload: Data? = nil) {
        self.version = 1
        self.type = type
        self.nonce = UUID()
        self.payload = payload
    }

    private enum CodingKeys: String, CodingKey { case version, type, nonce, payload }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        self.type = try c.decode(OnlineMessageType.self, forKey: .type)
        self.nonce = try c.decode(UUID.self, forKey: .nonce)
        self.payload = try c.decodeIfPresent(Data.self, forKey: .payload)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(type, forKey: .type)
        try c.encode(nonce, forKey: .nonce)
        try c.encodeIfPresent(payload, forKey: .payload)
    }
}

protocol OnlineMatchService: AnyObject {
    func startHosting() async throws
    func join() async throws
    func send(_ message: OnlineMessage) async throws
    var onReceive: ((OnlineMessage) -> Void)? { get set }
}
