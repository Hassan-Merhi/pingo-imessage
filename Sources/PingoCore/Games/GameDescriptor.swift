import Foundation

public enum PingoGameID: String, CaseIterable, Codable, Sendable {
    case eightBall
    case cupPong
    case basketball
    case darts
    case miniGolf
    case seaBattle
    case chess
    case checkers
    case connectFour
    case ticTacToe

    // Wave 6 expansion games
    case bowling
    case penaltyShootout
    case archery
    case airHockey
    case drawAndGuess
    case wordHunt
    case anagrams
    case trivia
    case crazyEights
    case ludo
    case miniRacing
    case reactionBattle
}

public enum PingoGameFamily: String, Codable, Sendable {
    case precision
    case arcade
    case board
    case strategy
    case word
    case party
    case cards
    case racing
}

public struct PingoGameDescriptor: Identifiable, Hashable, Codable, Sendable {
    public let id: PingoGameID
    public let name: String
    public let symbol: String
    public let family: PingoGameFamily
    public let isFreeAtLaunch: Bool
    public let minimumPlayers: Int
    public let maximumPlayers: Int

    public init(
        id: PingoGameID,
        name: String,
        symbol: String,
        family: PingoGameFamily,
        isFreeAtLaunch: Bool = true,
        minimumPlayers: Int = 2,
        maximumPlayers: Int = 2
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.family = family
        self.isFreeAtLaunch = isFreeAtLaunch
        self.minimumPlayers = minimumPlayers
        self.maximumPlayers = maximumPlayers
    }
}
