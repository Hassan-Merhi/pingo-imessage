import Foundation
import XCTest
@testable import PingoCore

final class WordHuntPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverWordHuntTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_200_000)
        let host = PingoPublicProfile(id: UUID(), username: "word_host", createdAt: now, updatedAt: now)
        let guest = PingoPublicProfile(id: UUID(), username: "word_guest", createdAt: now, updatedAt: now)
        let challenge = PingoMatchReducer.challenge(gameID: .wordHunt, creator: host, now: now)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision, now: now.addingTimeInterval(1))
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match

        let firstWord = try availableWord(in: current)
        let first = try PingoExtraGameEngine.submit(move: .init(text: firstWord), to: current, actorID: host.id, expectedRevision: current.revision, now: now.addingTimeInterval(2))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: first)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .wordHunt, matchID: current.id)
        XCTAssertEqual(state.attempts[0], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)
        XCTAssertTrue(state.usedWords.contains(firstWord))

        let secondWord = try availableWord(in: current)
        let second = try PingoExtraGameEngine.submit(move: .init(text: secondWord), to: current, actorID: guest.id, expectedRevision: current.revision, now: now.addingTimeInterval(3))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: second)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .wordHunt, matchID: current.id)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
        XCTAssertTrue(state.usedWords.contains(secondWord))
    }

    func testWordHuntTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "word_host")
        let guest = PingoPublicProfile(username: "word_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .wordHunt, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let word = try availableWord(in: accepted)
        let moved = try PingoExtraGameEngine.submit(move: .init(text: word), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleWordHuntMessageCannotReplayOldTurn() throws {
        let host = PingoPublicProfile(username: "word_host")
        let guest = PingoPublicProfile(username: "word_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .wordHunt, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let firstWord = try availableWord(in: accepted)
        let latest = try PingoExtraGameEngine.submit(move: .init(text: firstWord), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let secondWord = try availableWord(in: latest)
        XCTAssertThrowsError(try PingoExtraGameEngine.submit(move: .init(text: secondWord), to: latest, actorID: guest.id, expectedRevision: accepted.revision)) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    private func availableWord(in match: PingoMatchEnvelope) throws -> String {
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .wordHunt, matchID: match.id)
        let board = PingoExtraGameEngine.wordHuntBoard(for: state)
        guard let word = board.acceptedWords.sorted().first(where: { !state.usedWords.contains($0) }) else { throw PingoGameRuleError.invalidMove }
        return word
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        try PingoMessageTransport.decode(url: PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL))
    }
}
