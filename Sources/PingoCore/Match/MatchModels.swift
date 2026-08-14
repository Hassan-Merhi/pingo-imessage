import Foundation

public enum PingoMatchStatus: String, Codable, Sendable {
    case draft
    case awaitingOpponent
    case active
    case completed
    case resigned
    case expired
}

public struct PingoPlayerRef: Hashable, Codable, Sendable {
    public let id: UUID
    public let displayName: String

    public init(id: UUID, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

public struct PingoMatchEnvelope: Identifiable, Hashable, Codable, Sendable {
    public static let currentSchemaVersion = 1

    public let id: UUID
    public let schemaVersion: Int
    public let gameID: PingoGameID
    public let status: PingoMatchStatus
    public let createdAt: Date
    public let updatedAt: Date
    public let turnNumber: Int
    public let currentPlayerID: UUID?
    public let players: [PingoPlayerRef]
    public let gameState: Data

    public init(
        id: UUID = UUID(),
        schemaVersion: Int = currentSchemaVersion,
        gameID: PingoGameID,
        status: PingoMatchStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        turnNumber: Int = 0,
        currentPlayerID: UUID? = nil,
        players: [PingoPlayerRef] = [],
        gameState: Data = Data()
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.gameID = gameID
        self.status = status
        self.createdAt = Self.canonicalTimestamp(createdAt)
        self.updatedAt = Self.canonicalTimestamp(updatedAt)
        self.turnNumber = turnNumber
        self.currentPlayerID = currentPlayerID
        self.players = players
        self.gameState = gameState
    }

    private static func canonicalTimestamp(_ date: Date) -> Date {
        let milliseconds = (date.timeIntervalSince1970 * 1_000).rounded()
        return Date(timeIntervalSince1970: milliseconds / 1_000)
    }
}

public enum PingoMatchCodec {
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    public static func encode(_ match: PingoMatchEnvelope) throws -> Data {
        try encoder.encode(match)
    }

    public static func decode(_ data: Data) throws -> PingoMatchEnvelope {
        try decoder.decode(PingoMatchEnvelope.self, from: data)
    }
}
