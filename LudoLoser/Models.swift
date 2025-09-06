import Foundation

enum PlayerColor: String, CaseIterable, Codable, Identifiable {
    case red, blue, green, yellow
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .yellow: return "Yellow"
        }
    }
}

final class Player: Identifiable, ObservableObject, Codable {
    let id: UUID
    let color: PlayerColor
    var name: String?
    @Published var homeCount: Int

    init(id: UUID = UUID(), color: PlayerColor, name: String? = nil, homeCount: Int = 0) {
        self.id = id
        self.color = color
        self.name = name
        self.homeCount = homeCount
    }

    var displayName: String { name ?? color.displayName }

    enum CodingKeys: CodingKey { case id, color, name, homeCount }
    convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let id = try c.decode(UUID.self, forKey: .id)
        let color = try c.decode(PlayerColor.self, forKey: .color)
        let name = try c.decodeIfPresent(String.self, forKey: .name)
        let home = try c.decode(Int.self, forKey: .homeCount)
        self.init(id: id, color: color, name: name, homeCount: home)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(color, forKey: .color)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encode(homeCount, forKey: .homeCount)
    }
}

/// Basic board coordinate types.
enum BoardPosition: Equatable, Hashable, Codable {
    case yard
    case mainTrack(index: Int) // 0..<(trackLength)
    case homeLane(index: Int)  // 0..<(tokensPerPlayer)
    case home
    case innerTrack(index: Int) // detour spiral visual path
}

struct Token: Identifiable, Codable, Hashable {
    let id: UUID
    let owner: PlayerColor
    var position: BoardPosition

    init(id: UUID = UUID(), owner: PlayerColor, position: BoardPosition = .yard) {
        self.id = id
        self.owner = owner
        self.position = position
    }
}
