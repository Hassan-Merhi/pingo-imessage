import Foundation

public struct PingoProgressionSnapshot: Codable, Sendable {
    public var xp: Int
    public var wins: Int
    public var losses: Int
    public var draws: Int
    public var currentStreak: Int
    public var bestStreak: Int
    public var achievements: Set<PingoAchievementID>
    public var gameCounts: [String: Int]
    public var opponentRecords: [PingoOpponentRecord]
    public var history: [PingoMatchHistoryEntry]
    public var processedMatchIDs: Set<UUID>
    public var updatedAt: Date

    public init(
        xp: Int,
        wins: Int,
        losses: Int,
        draws: Int,
        currentStreak: Int,
        bestStreak: Int,
        achievements: Set<PingoAchievementID>,
        gameCounts: [String: Int],
        opponentRecords: [PingoOpponentRecord],
        history: [PingoMatchHistoryEntry],
        processedMatchIDs: Set<UUID>,
        updatedAt: Date
    ) {
        self.xp = max(0, xp)
        self.wins = max(0, wins)
        self.losses = max(0, losses)
        self.draws = max(0, draws)
        self.currentStreak = max(0, currentStreak)
        self.bestStreak = max(0, bestStreak)
        self.achievements = achievements
        self.gameCounts = gameCounts
        self.opponentRecords = opponentRecords
        self.history = history
        self.processedMatchIDs = processedMatchIDs
        self.updatedAt = updatedAt
    }
}

public struct PingoProgressionState: Codable, Sendable {
    public var xp: Int
    public var wins: Int
    public var losses: Int
    public var draws: Int
    public var currentStreak: Int
    public var bestStreak: Int
    public var achievements: Set<PingoAchievementID>
    public var gameCounts: [String: Int]
    public var opponentRecords: [PingoOpponentRecord]
    public var history: [PingoMatchHistoryEntry]
    public var processedMatchIDs: Set<UUID>
    public var entitlements: Set<PingoEntitlementID>
    public var ownedCosmetics: Set<String>
    public var equippedCosmetics: [PingoCosmeticSlot: String]
    public var updatedAt: Date

    public init(
        xp: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        draws: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        achievements: Set<PingoAchievementID> = [],
        gameCounts: [String: Int] = [:],
        opponentRecords: [PingoOpponentRecord] = [],
        history: [PingoMatchHistoryEntry] = [],
        processedMatchIDs: Set<UUID> = [],
        entitlements: Set<PingoEntitlementID> = [],
        ownedCosmetics: Set<String> = PingoCosmeticCatalog.freeIDs,
        equippedCosmetics: [PingoCosmeticSlot: String] = [
            .avatar: "avatar.ping",
            .theme: "theme.classic",
            .cue: "cue.classic",
            .darts: "darts.classic",
            .golfBall: "golf.classic",
            .cup: "cup.classic",
            .basketball: "basketball.classic"
        ],
        updatedAt: Date = Date()
    ) {
        self.xp = max(0, xp)
        self.wins = max(0, wins)
        self.losses = max(0, losses)
        self.draws = max(0, draws)
        self.currentStreak = max(0, currentStreak)
        self.bestStreak = max(0, bestStreak)
        self.achievements = achievements
        self.gameCounts = gameCounts
        self.opponentRecords = opponentRecords
        self.history = history
        self.processedMatchIDs = processedMatchIDs
        self.entitlements = entitlements
        self.ownedCosmetics = ownedCosmetics.union(PingoCosmeticCatalog.freeIDs)
        self.equippedCosmetics = equippedCosmetics
        self.updatedAt = updatedAt
    }

    public var gamesPlayed: Int { wins + losses + draws }
    public var level: Int { PingoProgression.level(forXP: xp) }
    public var xpIntoLevel: Int { xp % PingoProgression.xpPerLevel }
    public var xpNeededForNextLevel: Int { PingoProgression.xpPerLevel - xpIntoLevel }

    public func snapshot() -> PingoProgressionSnapshot {
        PingoProgressionSnapshot(
            xp: xp,
            wins: wins,
            losses: losses,
            draws: draws,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            achievements: achievements,
            gameCounts: gameCounts,
            opponentRecords: opponentRecords,
            history: history,
            processedMatchIDs: processedMatchIDs,
            updatedAt: updatedAt
        )
    }
}

public enum PingoProgressionError: Error, Equatable, Sendable {
    case playerNotInMatch
    case matchNotFinished
    case cosmeticNotOwned
    case cosmeticSlotMismatch
}

