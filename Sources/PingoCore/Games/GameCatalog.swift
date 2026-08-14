import Foundation

public enum PingoGameCatalog {
    public static let launch: [PingoGameDescriptor] = [
        .init(id: .eightBall, name: "8-Ball", symbol: "🎱", family: .precision),
        .init(id: .cupPong, name: "Cup Pong", symbol: "🏓", family: .arcade),
        .init(id: .basketball, name: "Basketball", symbol: "🏀", family: .arcade),
        .init(id: .darts, name: "Darts", symbol: "🎯", family: .precision),
        .init(id: .miniGolf, name: "Mini Golf", symbol: "⛳️", family: .precision, isFreeAtLaunch: false),
        .init(id: .seaBattle, name: "Sea Battle", symbol: "⚓️", family: .strategy, isFreeAtLaunch: false),
        .init(id: .chess, name: "Chess", symbol: "♟️", family: .board, isFreeAtLaunch: false),
        .init(id: .checkers, name: "Checkers", symbol: "🔴", family: .board, isFreeAtLaunch: false),
        .init(id: .connectFour, name: "Connect Four", symbol: "🔵", family: .board, isFreeAtLaunch: false),
        .init(id: .ticTacToe, name: "Tic-Tac-Toe", symbol: "❌", family: .board),

        .init(id: .bowling, name: "Bowling", symbol: "🎳", family: .arcade, isFreeAtLaunch: false),
        .init(id: .penaltyShootout, name: "Penalty Shootout", symbol: "⚽️", family: .arcade, isFreeAtLaunch: false),
        .init(id: .archery, name: "Archery", symbol: "🏹", family: .precision, isFreeAtLaunch: false),
        .init(id: .airHockey, name: "Air Hockey", symbol: "🏒", family: .arcade, isFreeAtLaunch: false),
        .init(id: .drawAndGuess, name: "Draw & Guess", symbol: "🎨", family: .party, isFreeAtLaunch: false),
        .init(id: .wordHunt, name: "Word Hunt", symbol: "🔤", family: .word, isFreeAtLaunch: false),
        .init(id: .anagrams, name: "Anagrams", symbol: "🔀", family: .word, isFreeAtLaunch: false),
        .init(id: .trivia, name: "Trivia", symbol: "🧠", family: .party, isFreeAtLaunch: false),
        .init(id: .crazyEights, name: "Crazy Eights", symbol: "🃏", family: .cards, isFreeAtLaunch: false),
        .init(id: .ludo, name: "Ludo", symbol: "🎲", family: .board, isFreeAtLaunch: false),
        .init(id: .miniRacing, name: "Mini Racing", symbol: "🏎️", family: .racing, isFreeAtLaunch: false),
        .init(id: .reactionBattle, name: "Reaction Battle", symbol: "⚡️", family: .arcade, isFreeAtLaunch: false)
    ]

    public static let wave6: [PingoGameDescriptor] = Array(launch.dropFirst(10))

    public static func game(id: PingoGameID) -> PingoGameDescriptor? {
        launch.first { $0.id == id }
    }
}
