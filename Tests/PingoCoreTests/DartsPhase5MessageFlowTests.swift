import Foundation
import XCTest
@testable import PingoCore

final class DartsPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverDartsFlowRoundTripsThroughCheckout() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            username: "darts_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            username: "darts_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .darts, creator: host, now: now)
        let decodedChallenge = try roundTrip(PingoMessagePayload(action: .challenge, sender: host, match: challenge))
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .darts)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)

        let triple20 = PingoDartPoint(x: 0, y: -0.55)
        let hostFirst = try PingoPhysicsGameEngine.submit(
            move: .darts(.init(darts: [triple20, triple20, triple20])),
            to: current,
            actorID: host.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(2)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: hostFirst)).match
        var state = try PingoPhysicsGameEngine.dartsState(from: current.gameState)
        XCTAssertEqual(state.remaining[0], 121)
        XCTAssertEqual(state.lastVisitScore, 180)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let miss = PingoDartPoint(x: 1.2, y: 1.2)
        let guestResult = try PingoPhysicsGameEngine.submit(
            move: .darts(.init(darts: [miss, miss, miss])),
            to: current,
            actorID: guest.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(3)
        )
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guestResult)).match
        state = try PingoPhysicsGameEngine.dartsState(from: current.gameState)
        XCTAssertEqual(state.remaining[1], 301)
        XCTAssertEqual(state.lastVisitScore, 0)
        XCTAssertEqual(current.currentPlayerID, host.id)

        let triple19 = PingoDartPoint(x: -0.1699593469, y: 0.5230810840)
        let double2 = PingoDartPoint(x: 0.5290067271, y: 0.7281152949)
        let hostCheckout = try PingoPhysicsGameEngine.submit(
            move: .darts(.init(darts: [triple20, triple19, double2])),
            to: current,
            actorID: host.id,
            expectedRevision: current.revision,
            now: now.addingTimeInterval(4)
        )
        current = try roundTrip(PingoMessagePayload(action: .completed, sender: host, match: hostCheckout)).match

        XCTAssertEqual(current.status, .completed)
        XCTAssertEqual(current.winnerPlayerID, host.id)
        XCTAssertNil(current.currentPlayerID)
        state = try PingoPhysicsGameEngine.dartsState(from: current.gameState)
        XCTAssertEqual(state.remaining, [0, 301])
        XCTAssertEqual(state.visits, [2, 1])
        XCTAssertEqual(state.lastVisitScore, 121)
    }

    func testDartsTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "darts_host")
        let guest = PingoPublicProfile(username: "darts_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .darts, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let triple20 = PingoDartPoint(x: 0, y: -0.55)
        let moved = try PingoPhysicsGameEngine.submit(
            move: .darts(.init(darts: [triple20, triple20, triple20])),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleDartsMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "darts_host")
        let guest = PingoPublicProfile(username: "darts_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .darts, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let triple20 = PingoDartPoint(x: 0, y: -0.55)
        let visit = PingoDartsVisit(darts: [triple20, triple20, triple20])

        let latest = try PingoPhysicsGameEngine.submit(
            move: .darts(visit),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoPhysicsGameEngine.submit(
                move: .darts(visit),
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
