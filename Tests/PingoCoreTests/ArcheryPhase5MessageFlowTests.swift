import Foundation
import XCTest
@testable import PingoCore

final class ArcheryPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverArcheryTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_200_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            username: "archery_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            username: "archery_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .archery, creator: host, now: now)
        let decodedChallenge = try roundTrip(PingoMessagePayload(action: .challenge, sender: host, match: challenge))
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .archery)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)

        let hostArrow = try PingoExtraGameEngine.submit(
            move: .init(primary: 50, secondary: 50),
            to: current,
            actorID: host.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(2)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: hostArrow)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .archery, matchID: current.id)
        XCTAssertEqual(state.attempts[0], 1)
        XCTAssertEqual(state.scores[0], 10)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let guestArrow = try PingoExtraGameEngine.submit(
            move: .init(primary: 58, secondary: 50),
            to: current,
            actorID: guest.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(3)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guestArrow)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .archery, matchID: current.id)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(state.scores[1], 8)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testArcheryTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "archery_host")
        let guest = PingoPublicProfile(username: "archery_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .archery, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let moved = try PingoExtraGameEngine.submit(
            move: .init(primary: 50, secondary: 50),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleArcheryMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "archery_host")
        let guest = PingoPublicProfile(username: "archery_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .archery, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let arrow = PingoExtraGameMove(primary: 50, secondary: 50)

        let latest = try PingoExtraGameEngine.submit(
            move: arrow,
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoExtraGameEngine.submit(
                move: arrow,
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
