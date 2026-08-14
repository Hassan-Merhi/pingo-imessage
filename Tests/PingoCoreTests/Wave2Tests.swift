import XCTest
@testable import PingoCore

final class Wave2Tests: XCTestCase {
    func testUsernameRules() throws {
        XCTAssertEqual(try PingoProfileValidator.canonicalUsername("  Player_01 "), "player_01")
        XCTAssertThrowsError(try PingoProfileValidator.canonicalUsername("ab"))
        XCTAssertThrowsError(try PingoProfileValidator.canonicalUsername("bad-name"))
        XCTAssertThrowsError(try PingoProfileValidator.canonicalUsername("admin"))
    }

    func testChallengeAcceptAndTurnRejectsStaleRevision() throws {
        let first = PingoPublicProfile(id: UUID(), username: "alpha")
        let second = PingoPublicProfile(id: UUID(), username: "bravo")
        let challenge = PingoMatchReducer.challenge(gameID: .ticTacToe, creator: first)
        let active = try PingoMatchReducer.accept(challenge, opponent: second, expectedRevision: 0)

        XCTAssertEqual(active.status, .active)
        XCTAssertEqual(active.currentPlayerID, first.id)

        let moved = try PingoMatchReducer.submitTurn(
            active,
            actorID: first.id,
            expectedRevision: 1,
            nextPlayerID: second.id,
            gameState: Data([1])
        )
        XCTAssertEqual(moved.revision, 2)
        XCTAssertEqual(moved.currentPlayerID, second.id)

        XCTAssertThrowsError(
            try PingoMatchReducer.submitTurn(
                moved,
                actorID: second.id,
                expectedRevision: 1,
                nextPlayerID: first.id,
                gameState: Data()
            )
        )
    }

    func testMessageTransportRoundTrip() throws {
        let profile = PingoPublicProfile(id: UUID(), username: "pingfan")
        let match = PingoMatchReducer.challenge(gameID: .connectFour, creator: profile)
        let payload = PingoMessagePayload(action: .challenge, sender: profile, match: match)
        let url = try PingoMessageTransport.makeURL(
            payload: payload,
            baseURL: URL(string: "https://pingo.invalid/match")!
        )

        XCTAssertLessThan(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testTransportRejectsOversizedState() throws {
        let profile = PingoPublicProfile(id: UUID(), username: "pingfan")
        let match = PingoMatchEnvelope(
            gameID: .eightBall,
            status: .active,
            players: [.init(id: profile.id, displayName: profile.username)],
            gameState: Data(repeating: 1, count: 5_000)
        )
        let payload = PingoMessagePayload(action: .turn, sender: profile, match: match)

        XCTAssertThrowsError(
            try PingoMessageTransport.makeURL(
                payload: payload,
                baseURL: URL(string: "https://pingo.invalid/match")!
            )
        )
    }
}
