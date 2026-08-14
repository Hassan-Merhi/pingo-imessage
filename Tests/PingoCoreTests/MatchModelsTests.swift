import Foundation
import Testing
@testable import PingoCore

@Suite("Match envelope")
struct MatchModelsTests {
    @Test("Match payload round-trips through the stable codec")
    func roundTrip() throws {
        let player = PingoPlayerRef(id: UUID(), displayName: "Player One")
        let match = PingoMatchEnvelope(
            gameID: .ticTacToe,
            status: .active,
            turnNumber: 3,
            currentPlayerID: player.id,
            players: [player],
            gameState: Data("state-v1".utf8)
        )

        let encoded = try PingoMatchCodec.encode(match)
        let decoded = try PingoMatchCodec.decode(encoded)

        #expect(decoded == match)
        #expect(decoded.schemaVersion == PingoMatchEnvelope.currentSchemaVersion)
    }
}
