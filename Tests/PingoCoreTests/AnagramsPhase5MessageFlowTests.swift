import Foundation
import XCTest
@testable import PingoCore

final class AnagramsPhase5MessageFlowTests: XCTestCase {
    private let baseURL = URL(string: "https://pingo.example/messages")!

    func testSenderReceiverAnagramsTurnExchangeRoundTrips() throws {
        let now = Date(timeIntervalSince1970: 1_787_200_000)
        let host = PingoPublicProfile(id: UUID(), username: "anagram_host", createdAt: now, updatedAt: now)
        let guest = PingoPublicProfile(id: UUID(), username: "anagram_guest", createdAt: now, updatedAt: now)
        let challenge = PingoMatchReducer.challenge(gameID: .anagrams, creator: host, now: now)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision, now: now.addingTimeInterval(1))
        var current = try roundTrip(PingoMessagePayload(action: .accepted, sender: guest, match: accepted)).match

        let firstAnswer = answer(for: current)
        let first = try PingoExtraGameEngine.submit(move: .init(text: firstAnswer), to: current, actorID: host.id, expectedRevision: current.revision, now: now.addingTimeInterval(2))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: host, match: first)).match
        var state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .anagrams, matchID: current.id)
        XCTAssertEqual(state.attempts[0], 1)
        XCTAssertEqual(current.currentPlayerID, guest.id)

        let secondAnswer = answer(for: current)
        let second = try PingoExtraGameEngine.submit(move: .init(text: secondAnswer), to: current, actorID: guest.id, expectedRevision: current.revision, now: now.addingTimeInterval(3))
        current = try roundTrip(PingoMessagePayload(action: .turn, sender: guest, match: second)).match
        state = try PingoExtraGameEngine.state(from: current.gameState, gameID: .anagrams, matchID: current.id)
        XCTAssertEqual(state.attempts[1], 1)
        XCTAssertEqual(current.currentPlayerID, host.id)
        XCTAssertEqual(current.revision, accepted.revision + 2)
    }

    func testAnagramsTurnPayloadStaysInsideMessageURLBudget() throws {
        let host = PingoPublicProfile(username: "anagram_host")
        let guest = PingoPublicProfile(username: "anagram_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .anagrams, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let moved = try PingoExtraGameEngine.submit(move: .init(text: answer(for: accepted)), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        let payload = PingoMessagePayload(action: .turn, sender: host, match: moved)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url), payload)
    }

    func testStaleAnagramsMessageCannotReplayOldTurn() throws {
        let host = PingoPublicProfile(username: "anagram_host")
        let guest = PingoPublicProfile(username: "anagram_guest")
        let challenge = PingoMatchReducer.challenge(gameID: .anagrams, creator: host)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: guest, expectedRevision: challenge.revision)
        let latest = try PingoExtraGameEngine.submit(move: .init(text: answer(for: accepted)), to: accepted, actorID: host.id, expectedRevision: accepted.revision)
        XCTAssertThrowsError(try PingoExtraGameEngine.submit(move: .init(text: answer(for: latest)), to: latest, actorID: guest.id, expectedRevision: accepted.revision)) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    private func answer(for match: PingoMatchEnvelope) -> String {
        let state = (try? PingoExtraGameEngine.state(from: match.gameState, gameID: .anagrams, matchID: match.id)) ?? PingoExtraGameState()
        let index = (state.attempts[0] + state.attempts[1]) % PingoExtraGameEngine.anagramPuzzles.count
        return PingoExtraGameEngine.anagramPuzzles[index].answer
    }

    private func roundTrip(_ payload: PingoMessagePayload) throws -> PingoMessagePayload {
        try PingoMessageTransport.decode(url: PingoMessageTransport.makeURL(payload: payload, baseURL: baseURL))
    }
}
