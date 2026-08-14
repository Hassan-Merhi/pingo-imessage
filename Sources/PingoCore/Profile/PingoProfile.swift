import Foundation

public enum PingoAvatarKind: String, Codable, Sendable {
    case preset
    case emoji
}

public struct PingoAvatar: Hashable, Codable, Sendable {
    public let kind: PingoAvatarKind
    public let value: String
    public let background: String

    public init(kind: PingoAvatarKind = .preset, value: String = "ping", background: String = "mint") {
        self.kind = kind
        self.value = value
        self.background = background
    }
}

public struct PingoStats: Hashable, Codable, Sendable {
    public var wins: Int
    public var losses: Int
    public var draws: Int
    public var currentStreak: Int
    public var bestStreak: Int

    public init(wins: Int = 0, losses: Int = 0, draws: Int = 0, currentStreak: Int = 0, bestStreak: Int = 0) {
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
    }

    public var gamesPlayed: Int { wins + losses + draws }
    public var winRate: Double { gamesPlayed == 0 ? 0 : Double(wins) / Double(gamesPlayed) }
}

public struct PingoPublicProfile: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var username: String
    public var avatar: PingoAvatar
    public var stats: PingoStats
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        username: String,
        avatar: PingoAvatar = .init(),
        stats: PingoStats = .init(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.avatar = avatar
        self.stats = stats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct PingoOpponentRecord: Hashable, Codable, Sendable {
    public let opponentID: UUID
    public var wins: Int
    public var losses: Int
    public var draws: Int
    public var currentStreak: Int
    public var bestStreak: Int
    public var lastPlayedAt: Date?

    public init(
        opponentID: UUID,
        wins: Int = 0,
        losses: Int = 0,
        draws: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastPlayedAt: Date? = nil
    ) {
        self.opponentID = opponentID
        self.wins = wins
        self.losses = losses
        self.draws = draws
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastPlayedAt = lastPlayedAt
    }
}

public enum PingoUsernameValidationError: Error, Equatable, Sendable {
    case tooShort
    case tooLong
    case invalidCharacters
    case reserved
}

public enum PingoProfileValidator {
    public static let minimumUsernameLength = 3
    public static let maximumUsernameLength = 20

    private static let reserved = Set([
        "admin", "administrator", "pingo", "support", "system", "moderator", "official"
    ])

    public static func canonicalUsername(_ value: String) throws -> String {
        let canonical = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard canonical.count >= minimumUsernameLength else { throw PingoUsernameValidationError.tooShort }
        guard canonical.count <= maximumUsernameLength else { throw PingoUsernameValidationError.tooLong }
        guard canonical.unicodeScalars.allSatisfy({
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_").contains($0)
        }) else {
            throw PingoUsernameValidationError.invalidCharacters
        }
        guard !reserved.contains(canonical) else { throw PingoUsernameValidationError.reserved }
        return canonical
    }

    public static func validatedAvatar(_ avatar: PingoAvatar) -> PingoAvatar {
        let allowedBackgrounds = Set(["mint", "blue", "purple", "orange", "pink", "slate"])
        let background = allowedBackgrounds.contains(avatar.background) ? avatar.background : "mint"

        switch avatar.kind {
        case .preset:
            let allowed = Set(["ping", "orbit", "bolt", "star", "rocket", "smile", "trophy", "wave"])
            return .init(
                kind: .preset,
                value: allowed.contains(avatar.value) ? avatar.value : "ping",
                background: background
            )
        case .emoji:
            let clipped = String(avatar.value.prefix(4))
            return .init(kind: .emoji, value: clipped.isEmpty ? "🙂" : clipped, background: background)
        }
    }
}
