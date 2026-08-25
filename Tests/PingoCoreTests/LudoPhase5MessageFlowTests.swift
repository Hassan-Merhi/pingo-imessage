import Foundation
import XCTest
@testable import PingoCore

final class LudoPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverLudoTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_700_000)
        let host = PingoPublicProfile(id: UUID(), username: "ludo_host", createdAt: now, updatedAt: now)
        let guest = PingoPublicProfile(id: UUID(), username: "ludo_guest", createdAt: now, updatedAt: now)
        let challenge = PingoMatchReducer.challenge(gameID: .ludo, creator: host, now: now)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision, now: now.addingTimeInterval(1))
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match

        let hostState = try PingoExtraGameEngine.state(from: current.gameState, gameID: .ludo, matchID: current.id)
        let hostMove = legalMove(for: 0, state: hostState)
        let first = try PingoExtraGameEngine.submit(move: hostMove, to: current, actorID: host.id, expectedRevision: current.revision, now: now.addingTimeInterval(2))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: first)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .ludo, matchID: current.id)
        XCTAssertEqual(state.attempts[0], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let guestMove = legalMove(for: 1, state: state)
        let second = try PingoExtraGameEngine.submit(move: guestMove, to: current, actorID: guest.id, expectedRevision: current.revision, now: now.addingTimeInterval(3))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: second)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .ludo, matchID: current.id)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testLudoTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "ludo_host")
        let guest = PingoPublicProfile(username: "ludo_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .ludo, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let state = try PingoExtraGameEngine.state(from: accepted.gameState, gameID: .ludo, matchID: accepted.id)
        let moved = try PingoExtraGameEngine.submit(move: legalMove(for: 0, state: state), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleLudoMessageCannotReplayOldTurn() throws {
        let host = PingoPublicProfile(username: "ludo_host")
        let guest = PingoPublicProfile(username: "ludo_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .ludo, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let state = try PingoExtraGameEngine.state(from: accepted.gameState, gameID: .ludo, matchID: accepted.id)
        let latest = try PingoExtraGameEngine.submit(move: legalMove(for: 0, state: state), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let guestState = try PingoExtraGameEngine.state(from: latest.gameState, gameID: .ludo, matchID: latest.id)
        XCTAssertThrowsError(try PingoExtraGameEngine.submit(move: legalMove(for: 1, state: guestState), to: latest, actorID: guest.id, expectedRevision: accepted.revision)) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    private func legalMove(for player: Int, state: PingoExtraGameState) -> PingoExtraGameMove {
        let die = PingoExtraGameEngine.ludoDie(for: state)
        guard state.positions.indices.contains(player) else { return .init(primary: -1) }
        let positions = state.positions[player]
        if let piece = positions.indices.first(where: { index in
            let position = positions[index]
            return position < 24 && (position >= 0 || die == 6)
        }) {
            return .init(primary: piece)
        }
        return .init(primary: -1)
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        try PingoMessageTransport.decode(url: PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL))
    }
}
