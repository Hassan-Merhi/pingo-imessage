import Foundation
import XCTest
@testable import PingoCore

final class DrawGuessPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverDrawGuessTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_500_000)
        let host = PingoPublicProfile(id: UUID(), username: "draw_host", createdAt: now, updatedAt: now)
        let guest = PingoPublicProfile(id: UUID(), username: "draw_guest", createdAt: now, updatedAt: now)
        let challenge = PingoMatchReducer.challenge(gameID: .drawAndGuess, creator: host, now: now)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision, now: now.addingTimeInterval(1))
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match

        let initial = try PingoExtraGameEngine.state(from: current.gameState, gameID: .drawAndGuess, matchID: current.id)
        let prompt = PingoExtraGameEngine.drawPrompt(for: initial)
        let drawing = [
            PingoExtraPoint(x: 120, y: 180),
            PingoExtraPoint(x: 420, y: 520),
            PingoExtraPoint(x: 780, y: 340)
        ]
        let drawn = try PingoExtraGameEngine.submit(move: .init(points: drawing), to: current, actorID: host.id, expectedRevision: current.revision, now: now.addingTimeInterval(2))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: drawn)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .drawAndGuess, matchID: current.id)
        XCTAssertEqual(state.phase, 1)
        XCTAssertEqual(state.drawing, drawing)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let guessed = try PingoExtraGameEngine.submit(move: .init(text: prompt), to: current, actorID: guest.id, expectedRevision: current.revision, now: now.addingTimeInterval(3))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: guessed)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .drawAndGuess, matchID: current.id)
        XCTAssertEqual(state.phase, 0)
        XCTAssertTrue(state.drawing.isEmpty)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testDrawGuessTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "draw_host")
        let guest = PingoPublicProfile(username: "draw_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .drawAndGuess, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let drawing = [PingoExtraPoint(x: 100, y: 100), PingoExtraPoint(x: 500, y: 500), PingoExtraPoint(x: 900, y: 300)]
        let moved = try PingoExtraGameEngine.submit(move: .init(points: drawing), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleDrawGuessMessageCannotReplayOldTurn() throws {
        let host = PingoPublicProfile(username: "draw_host")
        let guest = PingoPublicProfile(username: "draw_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .drawAndGuess, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let move = PingoExtraGameMove(points: [PingoExtraPoint(x: 100, y: 100), PingoExtraPoint(x: 500, y: 500)])
        let latest = try PingoExtraGameEngine.submit(move: move, to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        XCTAssertThrowsError(try PingoExtraGameEngine.submit(move: .init(text: "guess"), to: latest, actorID: guest.id, expectedRevision: accepted.revision)) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        try PingoMessageTransport.decode(url: PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL))
    }
}
