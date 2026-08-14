import Foundation

public enum PingoSeriesFormat: String, Codable, CaseIterable, Sendable {
    case single
    case bestOf3
    case bestOf5

    public var winsRequired: Int {
        switch self {
        case .single: 1
        case .bestOf3: 2
        case .bestOf5: 3
        }
    }

    public var maximumGames: Int {
        switch self {
        case .single: 1
        case .bestOf3: 3
        case .bestOf5: 5
        }
    }

    public var title: String {
        switch self {
        case .single: "Single Game"
        case .bestOf3: "Best of 3"
        case .bestOf5: "Best of 5"
        }
    }
}

public struct PingoSeriesState: Hashable, Codable, Sendable {
    public let id: UUID
    public let format: PingoSeriesFormat
    public var wins: [Int]
    public var gameNumber: Int
    public var winnerPlayerIndex: Int?
    public var completed: Bool

    public init(
        id: UUID = UUID(),
        format: PingoSeriesFormat,
        wins: [Int] = [0, 0],
        gameNumber: Int = 1,
        winnerPlayerIndex: Int? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.format = format
        self.wins = wins.count == 2 ? wins : [0, 0]
        self.gameNumber = max(1, gameNumber)
        self.winnerPlayerIndex = winnerPlayerIndex
        self.completed = completed
    }

    public func recording(winnerIndex: Int?) -> PingoSeriesState {
        var next = self
        if let winnerIndex, next.wins.indices.contains(winnerIndex) {
            next.wins[winnerIndex] += 1
            if next.wins[winnerIndex] >= format.winsRequired {
                next.completed = true
                next.winnerPlayerIndex = winnerIndex
            }
        }
        if !next.completed {
            next.gameNumber += 1
        }
        return next
    }

    public var scoreText: String { "\(wins[0])–\(wins[1])" }
}

public enum PingoMatchResult: String, Codable, Sendable {
    case win
    case loss
    case draw
}

public struct PingoMatchHistoryEntry: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let gameID: PingoGameID
    public let opponentID: UUID
    public let opponentName: String
    public let result: PingoMatchResult
    public let playedAt: Date
    public let seriesID: UUID?

    public init(
        id: UUID,
        gameID: PingoGameID,
        opponentID: UUID,
        opponentName: String,
        result: PingoMatchResult,
        playedAt: Date,
        seriesID: UUID? = nil
    ) {
        self.id = id
        self.gameID = gameID
        self.opponentID = opponentID
        self.opponentName = opponentName
        self.result = result
        self.playedAt = playedAt
        self.seriesID = seriesID
    }
}

public enum PingoAchievementID: String, Codable, CaseIterable, Sendable {
    case firstWin
    case hatTrick
    case hotFive
    case tenGames
    case fiveGameExplorer
    case seriesWinner
    case collector

    public var title: String {
        switch self {
        case .firstWin: "First Win"
        case .hatTrick: "Hat Trick"
        case .hotFive: "On Fire"
        case .tenGames: "Regular"
        case .fiveGameExplorer: "Game Explorer"
        case .seriesWinner: "Series Winner"
        case .collector: "Collector"
        }
    }

    public var symbol: String {
        switch self {
        case .firstWin: "🏆"
        case .hatTrick: "3️⃣"
        case .hotFive: "🔥"
        case .tenGames: "🎮"
        case .fiveGameExplorer: "🧭"
        case .seriesWinner: "👑"
        case .collector: "✨"
        }
    }
}

public enum PingoEntitlementID: String, Codable, CaseIterable, Sendable {
    case premiumGames = "premium_games"
    case neonCosmetics = "cosmetics_neon"
    case spaceCosmetics = "cosmetics_space"
    case classicCosmetics = "cosmetics_classic"
}

public enum PingoStoreProduct: String, Codable, CaseIterable, Sendable {
    case premiumGames = "com.pingo.premiumgames"
    case neonCosmetics = "com.pingo.cosmetics.neon"
    case spaceCosmetics = "com.pingo.cosmetics.space"
    case classicCosmetics = "com.pingo.cosmetics.classic"

    public var entitlement: PingoEntitlementID {
        switch self {
        case .premiumGames: .premiumGames
        case .neonCosmetics: .neonCosmetics
        case .spaceCosmetics: .spaceCosmetics
        case .classicCosmetics: .classicCosmetics
        }
    }

    public static func product(for identifier: String) -> PingoStoreProduct? {
        PingoStoreProduct(rawValue: identifier)
    }
}

public enum PingoCosmeticSlot: String, Codable, CaseIterable, Sendable {
    case avatar
    case theme
    case cue
    case darts
    case golfBall
    case cup
    case basketball
}

public struct PingoCosmeticDescriptor: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let symbol: String
    public let slot: PingoCosmeticSlot
    public let entitlement: PingoEntitlementID?

    public init(id: String, name: String, symbol: String, slot: PingoCosmeticSlot, entitlement: PingoEntitlementID? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.slot = slot
        self.entitlement = entitlement
    }
}

public enum PingoCosmeticCatalog {
    public static let all: [PingoCosmeticDescriptor] = [
        .init(id: "avatar.ping", name: "Pingo", symbol: "🎮", slot: .avatar),
        .init(id: "theme.classic", name: "Classic", symbol: "◻️", slot: .theme),
        .init(id: "cue.classic", name: "Classic Cue", symbol: "🎱", slot: .cue),
        .init(id: "darts.classic", name: "Classic Darts", symbol: "🎯", slot: .darts),
        .init(id: "golf.classic", name: "Classic Ball", symbol: "⚪️", slot: .golfBall),
        .init(id: "cup.classic", name: "Classic Cups", symbol: "🥤", slot: .cup),
        .init(id: "basketball.classic", name: "Classic Ball", symbol: "🏀", slot: .basketball),

        .init(id: "theme.neon", name: "Neon Arena", symbol: "🌈", slot: .theme, entitlement: .neonCosmetics),
        .init(id: "cue.neon", name: "Neon Cue", symbol: "💫", slot: .cue, entitlement: .neonCosmetics),
        .init(id: "darts.neon", name: "Neon Darts", symbol: "⚡️", slot: .darts, entitlement: .neonCosmetics),

        .init(id: "theme.space", name: "Deep Space", symbol: "🌌", slot: .theme, entitlement: .spaceCosmetics),
        .init(id: "golf.space", name: "Moon Ball", symbol: "🌕", slot: .golfBall, entitlement: .spaceCosmetics),
        .init(id: "basketball.space", name: "Orbit Ball", symbol: "🪐", slot: .basketball, entitlement: .spaceCosmetics),

        .init(id: "avatar.crown", name: "Crown", symbol: "👑", slot: .avatar, entitlement: .classicCosmetics),
        .init(id: "cup.gold", name: "Gold Cups", symbol: "🏆", slot: .cup, entitlement: .classicCosmetics),
        .init(id: "cue.gold", name: "Gold Cue", symbol: "✨", slot: .cue, entitlement: .classicCosmetics)
    ]

    public static var freeIDs: Set<String> {
        Set(all.filter { $0.entitlement == nil }.map(\.id))
    }

    public static func unlockedIDs(for entitlements: Set<PingoEntitlementID>) -> Set<String> {
        Set(all.filter { descriptor in
            descriptor.entitlement == nil || descriptor.entitlement.map(entitlements.contains) == true
        }.map(\.id))
    }

    public static func descriptor(id: String) -> PingoCosmeticDescriptor? {
        all.first(where: { $0.id == id })
    }
}

public enum PingoAccessPolicy {
    public static let freeGames: Set<PingoGameID> = [
        .eightBall, .cupPong, .basketball, .darts, .ticTacToe
    ]

    public static let premiumGames: Set<PingoGameID> = Set(PingoGameID.allCases).subtracting(freeGames)

    public static func canPlay(_ gameID: PingoGameID, entitlements: Set<PingoEntitlementID>) -> Bool {
        freeGames.contains(gameID) || entitlements.contains(.premiumGames)
    }

    public static func accessibleGames(entitlements: Set<PingoEntitlementID>) -> [PingoGameID] {
        PingoGameCatalog.launch.map(\.id).filter { canPlay($0, entitlements: entitlements) }
    }
}

public enum PingoRandomGame {
    public static func pick(entitlements: Set<PingoEntitlementID>, seed: UInt64) -> PingoGameID? {
        let available = PingoAccessPolicy.accessibleGames(entitlements: entitlements)
        guard !available.isEmpty else { return nil }
        let mixed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return available[Int(mixed % UInt64(available.count))]
    }
}

