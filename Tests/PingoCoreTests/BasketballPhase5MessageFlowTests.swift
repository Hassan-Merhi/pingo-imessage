import Foundation
import XCTest
@testable import PingoCore

final class BasketballPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverBasketballFlowRoundTripsThroughShootout() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            username: "hoops_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            username: "hoops_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .basketball, creator: host, now: now)
        let decodedChallenge = try roundTrip(PingoMessagePayload(action: .challenge, sender: host, match: challenge))
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .basketball)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)

        for attempt in 0..<5 {
            XCTAssertEqual(current.currentPlayerID, host.id)
            let hostResult = try PingoPhysicsGameEngine.submit(
                move: .basketball(.init(angleDegrees: 52, power: 0.72)),
                to: current,
                actorID: host.id,
                expectedRevision: current.revision,
                now: now.addingTimeInterval(Double(attempt * 2 + 2))
            )
            current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: hostResult)).match
            let hostState = try PingoPhysicsGameEngine.basketballState(from: current.gameState)
            XCTAssertEqual(hostState.scores[0], (attempt + 1) * 3)
            XCTAssertEqual(hostState.attempts[0], attempt + 1)
            XCTAssertEqual(hostState.lastPoints, 3)
            XCTAssertEqual(current.currentPlayerID, guest.id)

            let guestResult = try PingoPhysicsGameEngine.submit(
                move: .basketball(.init(angleDegrees: 30, power: 0.2)),
                to: current,
                actorID: guest.id,
                expectedRevision: current.revision,
                now: now.addingTimeInterval(Double(attempt * 2 + 3))
            )
            let action: PingoMessageAction = guestResult.status == .completed ? .completed : .turn
            current = try roundTrip(PingoMessagePayload(action: action, sender: guest, match: guestResult)).match

            let guestState = try PingoPhysicsGameEngine.basketballState(from: current.gameState)
            XCTAssertEqual(guestState.scores[1], 0)
            XCTAssertEqual(guestState.attempts[1], attempt + 1)
            XCTAssertEqual(guestState.lastPoints, 0)

            if attempt < 4 {
                XCTAssertEqual(current.status, .active)
                XCTAssertEqual(current.currentPlayerID, host.id)
            }
        }

        XCTAssertEqual(current.status, .completed)
        XCTAssertEqual(current.winnerPlayerID, host.id)
        XCTAssertNil(current.currentPlayerID)
        let finalState = try PingoPhysicsGameEngine.basketballState(from: current.gameState)
        XCTAssertEqual(finalState.scores, [15, 0])
        XCTAssertEqual(finalState.attempts, [5, 5])
    }

    func testBasketballTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "hoops_host")
        let guest = PingoPublicProfile(username: "hoops_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .basketball, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let moved = try PingoPhysicsGameEngine.submit(
            move: .basketball(.init(angleDegrees: 52, power: 0.72)),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleBasketballMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "hoops_host")
        let guest = PingoPublicProfile(username: "hoops_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .basketball, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)

        let latest = try PingoPhysicsGameEngine.submit(
            move: .basketball(.init(angleDegrees: 52, power: 0.72)),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoPhysicsGameEngine.submit(
                move: .basketball(.init(angleDegrees: 30, power: 0.2)),
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
