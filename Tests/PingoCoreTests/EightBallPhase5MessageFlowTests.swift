import Foundation
import XCTest
@testable import PingoCore

final class EightBallPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverEightBallFlowRoundTripsAcrossMessages() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            username: "host_player",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            username: "guest_player",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(
            gameID: .eightBall,
            creator: host,
            now: now
        )
        let challengePayload = PingoMessagePayload(action: .challenge, sender: host, match: challenge)
        let decodedChallenge = try roundTrip(challengePayload)

        XCTAssertEqual(decodedChallenge, challengePayload)
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.players.map(\.id), [host.id])

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        let acceptedPayload = PingoMessagePayload(action: .accepted, sender: guest, match: accepted)
        let decodedAccepted = try roundTrip(acceptedPayload)

        XCTAssertEqual(decodedAccepted.sender.id, guest.id)
        XCTAssertEqual(decodedAccepted.match.status, .active)
        XCTAssertEqual(decodedAccepted.match.currentPlayerID, host.id)
        XCTAssertEqual(decodedAccepted.match.players.map(\.id), [host.id, guest.id])
        XCTAssertFalse(decodedAccepted.match.gameState.isEmpty)

        let hostTurn = try PingoMatchReducer.submitTurn(
            decodedAccepted.match,
            actorID: host.id,
            expectedRevision: decodedAccepted.match.revision,
            nextPlayerID: guest.id,
            gameState: decodedAccepted.match.gameState,
            now: now.addingTimeInterval(2)
        )
        let hostTurnPayload = PingoMessagePayload(action: .turn, sender: host, match: hostTurn)
        let decodedHostTurn = try roundTrip(hostTurnPayload)

        XCTAssertEqual(decodedHostTurn.sender.id, host.id)
        XCTAssertEqual(decodedHostTurn.match.currentPlayerID, guest.id)
        XCTAssertEqual(decodedHostTurn.match.turnNumber, 1)
        XCTAssertEqual(decodedHostTurn.match.revision, 2)

        let guestTurn = try PingoMatchReducer.submitTurn(
            decodedHostTurn.match,
            actorID: guest.id,
            expectedRevision: decodedHostTurn.match.revision,
            nextPlayerID: host.id,
            gameState: decodedHostTurn.match.gameState,
            now: now.addingTimeInterval(3)
        )
        let guestTurnPayload = PingoMessagePayload(action: .turn, sender: guest, match: guestTurn)
        let decodedGuestTurn = try roundTrip(guestTurnPayload)

        XCTAssertEqual(decodedGuestTurn.sender.id, guest.id)
        XCTAssertEqual(decodedGuestTurn.match.currentPlayerID, host.id)
        XCTAssertEqual(decodedGuestTurn.match.turnNumber, 2)
        XCTAssertEqual(decodedGuestTurn.match.revision, 3)

        let completed = try PingoMatchReducer.completeTurn(
            decodedGuestTurn.match,
            actorID: host.id,
            expectedRevision: decodedGuestTurn.match.revision,
            winnerPlayerID: host.id,
            gameState: decodedGuestTurn.match.gameState,
            now: now.addingTimeInterval(4)
        )
        let completedPayload = PingoMessagePayload(action: .completed, sender: host, match: completed)
        let decodedCompleted = try roundTrip(completedPayload)

        XCTAssertEqual(decodedCompleted.match.status, .completed)
        XCTAssertEqual(decodedCompleted.match.winnerPlayerID, host.id)
        XCTAssertNil(decodedCompleted.match.currentPlayerID)
        XCTAssertEqual(decodedCompleted.match.turnNumber, 3)
    }

    func testEightBallTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "host_player")
        let guest = PingoPublicProfile(username: "guest_player")
        let challenge = PingoMatchReducer.challenge(gameID: .eightBall, creator: host)
        let accepted = try PingoMatchReducer.accept(
            challenge,
            opponent: guest,
            expectedRevision: challenge.revision
        )
        let payload = PingoMessagePayload(action: .accepted, sender: guest, match: accepted)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        return try PingoMessageTransport.decode(url: url)
    }
}
