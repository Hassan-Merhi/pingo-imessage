import Foundation
import XCTest
@testable import PingoCore

final class CupPongPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverCupPongFlowRoundTripsUntilLastCup() throws {
        let now = Date(timeIntervalSince1970: 1_787_000_000)
        let host = PingoPublicProfile(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            username: "pong_host",
            createdAt: now,
            updatedAt: now
        )
        let guest = PingoPublicProfile(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            username: "pong_guest",
            createdAt: now,
            updatedAt: now
        )

        let challenge = PingoMatchReducer.challenge(gameID: .cupPong, creator: host, now: now)
        let challengePayload = PingoMessagePayload(action: .challenge, sender: host, match: challenge)
        let decodedChallenge = try roundTrip(challengePayload)
        XCTAssertEqual(decodedChallenge.match.status, .awaitingOpponent)
        XCTAssertEqual(decodedChallenge.match.gameID, .cupPong)

        let accepted = try PingoMatchReducer.accept(
            decodedChallenge.match,
            opponent: guest,
            expectedRevision: decodedChallenge.match.revision,
            now: now.addingTimeInterval(1)
        )
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match
        XCTAssertEqual(current.status, .active)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertFalse(current.gameState.isEmpty)
        let initialState = try PingoPhysicsGameEngine.cupPongState(from: current.gameState)
        XCTAssertEqual(initialState.cups[0].filter { $0 }.count, 6)
        XCTAssertEqual(initialState.cups[1].filter { $0 }.count, 6)

        let cupShots: [PingoAimShot] = [
            .init(angleDegrees: -10.8, power: 0.82),
            .init(angleDegrees: 0, power: 0.82),
            .init(angleDegrees: 10.8, power: 0.82),
            .init(angleDegrees: -5.4, power: 0.58),
            .init(angleDegrees: 5.4, power: 0.58),
            .init(angleDegrees: 0, power: 0.34)
        ]

        for (index, hostShot) in cupShots.enumerated() {
            XCTAssertEqual(current.currentPlayerID, host.id)
            let hostResult = try PingoPhysicsGameEngine.submit(
                move: .cupPong(hostShot),
                to: current,
                actorID: host.id,
                expectedRevision: current.revision,
                now: now.addingTimeInterval(Double(index * 2 + 2))
            )
            let hostAction: PingoMessageAction = hostResult.status == .completed ? .completed : .turn
            current = try roundTrip(PingoMessagePayload(action: hostAction, sender: host, match: hostResult)).match

            let hostState = try PingoPhysicsGameEngine.cupPongState(from: current.gameState)
            XCTAssertEqual(hostState.cups[1].filter { $0 }.count, 5 - index)

            if current.status == .completed {
                XCTAssertEqual(index, cupShots.count - 1)
                break
            }

            XCTAssertEqual(current.currentPlayerID, guest.id)
            let guestMiss = try PingoPhysicsGameEngine.submit(
                move: .cupPong(.init(angleDegrees: 30, power: 0.15)),
                to: current,
                actorID: guest.id,
                expectedRevision: current.revision,
                now: now.addingTimeInterval(Double(index * 2 + 3))
            )
            current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guestMiss)).match
            XCTAssertEqual(current.currentPlayerID, host.id)
        }

        XCTAssertEqual(current.status, .completed)
        XCTAssertEqual(current.winnerPlayerID, host.id)
        XCTAssertNil(current.currentPlayerID)
        let finalState = try PingoPhysicsGameEngine.cupPongState(from: current.gameState)
        XCTAssertEqual(finalState.cups[1].filter { $0 }.count, 0)
        XCTAssertEqual(finalState.cups[0].filter { $0 }.count, 6)
    }

    func testCupPongTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "pong_host")
        let guest = PingoPublicProfile(username: "pong_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .cupPong, creator: host)
        let accepted = try PingoMatchReducer.accept(
            challenge,
            opponent: guest,
            expectedRevision: challenge.revision
        )
        let moved = try PingoPhysicsGameEngine.submit(
            move: .cupPong(.init(angleDegrees: 0, power: 0.34)),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)

        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleCupPongMessageCannotReplayAnOldTurn() throws {
        let host = PingoPublicProfile(username: "pong_host")
        let guest = PingoPublicProfile(username: "pong_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .cupPong, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)

        let latest = try PingoPhysicsGameEngine.submit(
            move: .cupPong(.init(angleDegrees: 0, power: 0.34)),
            to: accepted,
            actorID: host.id,
            expectedRevision: accepted.revision
        )

        XCTAssertThrowsError(
            try PingoPhysicsGameEngine.submit(
                move: .cupPong(.init(angleDegrees: 0, power: 0.34)),
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
