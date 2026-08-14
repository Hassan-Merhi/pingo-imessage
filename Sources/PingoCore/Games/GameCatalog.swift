import Foundation

public enum PingoGameCatalog {
    public static let launch: [PingoGameDescriptor] = [
        .init(id: .eightBall, name: "8-Ball", symbol: "🎱", family: .precision),
        .init(id: .cupPong, name: "Cup Pong", symbol: "🏓", family: .arcade),
        .init(id: .basketball, name: "Basketball", symbol: "🏀", family: .arcade),
        .init(id: .darts, name: "Darts", symbol: "🎯", family: .precision),
        .init(id: .miniGolf, name: "Mini Golf", symbol: "⛳️", family: .precision),
        .init(id: .seaBattle, name: "Sea Battle", symbol: "⚓️", family: .strategy),
        .init(id: .chess, name: "Chess", symbol: "♟️", family: .board),
        .init(id: .checkers, name: "Checkers", symbol: "🔴", family: .board),
        .init(id: .connectFour, name: "Connect Four", symbol: "🔵", family: .board),
        .init(id: .ticTacToe, name: "Tic-Tac-Toe", symbol: "❌", family: .board)
    ]

    public static func game(id: PingoGameID) -> PingoGameDescriptor? {
        launch.first { $0.id == id }
    }
}
