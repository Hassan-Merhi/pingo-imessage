import Foundation
import XCTest
@testable import PingoCore

final class PenaltyShootoutPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverPenaltyShootoutTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_100_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!,
            username: "penalty_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!,
            username: "penalty_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .penaltyShootout, creator: host, now: now)
        let decodedChallenge = try roundTrip(PingoMessagePayload(action: .challenge, sender: host, match: challenge))
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .penaltyShootout)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)

        let hostKick = try PingoExtraGameEngine.submit(
            move: .init(primary: 2, secondary: 84),
            to: current,
            actorID: host.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(2)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: hostKick)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .penaltyShootout, matchID: current.id)
        XCTAssertEqual(state.attempts[0], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let guestKick = try PingoExtraGameEngine.submit(
            move: .init(primary: 1, secondary: 78),
            to: current,
            actorID: guest.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(3)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guestKick)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .penaltyShootout, matchID: current.id)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testPenaltyShootoutTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "penalty_host")
        let guest = PingoPublicProfile(username: "penalty_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .penaltyShootout, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let moved = try PingoExtraGameEngine.submit(
            move: .init(primary: 3, secondary: 86),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStalePenaltyShootoutMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "penalty_host")
        let guest = PingoPublicProfile(username: "penalty_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .penaltyShootout, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let kick = PingoExtraGameMove(primary: 2, secondary: 84)

        let latest = try PingoExtraGameEngine.submit(
            move: kick,
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoExtraGameEngine.submit(
                move: kick,
                to: latest,
                actorID: guest.id,
                expectedRevision: accepted.revision
            )
        ) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        return try PingoMessageTransport.decode(url: url)
    }
}
