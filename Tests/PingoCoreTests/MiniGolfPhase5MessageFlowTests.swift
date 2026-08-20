import Foundation
import XCTest
@testable import PingoCore

final class MiniGolfPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverMiniGolfTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            username: "golf_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            username: "golf_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .miniGolf, creator: host, now: now)
        let decodedChallenge = try roundTrip(PingoMessagePayload(action: .challenge, sender: host, match: challenge))
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .miniGolf)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)

        let hostPutt = try PingoPhysicsGameEngine.submit(
            move: .miniGolf(.init(angleDegrees: 0, power: 0.35)),
            to: current,
            actorID: host.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(2)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: hostPutt)).match
        var state = try PingoPhysicsGameEngine.miniGolfState(from: current.gameState)
        XCTAssertEqual(state.holeStrokes[0], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let guestPutt = try PingoPhysicsGameEngine.submit(
            move: .miniGolf(.init(angleDegrees: 0, power: 0.35)),
            to: current,
            actorID: guest.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(3)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guestPutt)).match
        state = try PingoPhysicsGameEngine.miniGolfState(from: current.gameState)
        XCTAssertEqual(state.holeStrokes[1], 1)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testMiniGolfTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "golf_host")
        let guest = PingoPublicProfile(username: "golf_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .miniGolf, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let moved = try PingoPhysicsGameEngine.submit(
            move: .miniGolf(.init(angleDegrees: 18, power: 0.42)),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleMiniGolfMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "golf_host")
        let guest = PingoPublicProfile(username: "golf_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .miniGolf, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let putt = PingoAimShot(angleDegrees: 0, power: 0.35)

        let latest = try PingoPhysicsGameEngine.submit(
            move: .miniGolf(putt),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoPhysicsGameEngine.submit(
                move: .miniGolf(putt),
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
