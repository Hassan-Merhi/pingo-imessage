import Foundation
import XCTest
@testable import PingoCore

final class Wave6Tests: XCTestCase {
    private let a = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    private let b = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!

    private var alpha: PingoPublicProfile { .init(id: a, username: "alpha") }
    private var bravo: PingoPublicProfile { .init(id: b, username: "bravo") }

    private func activeExtraMatch(_ game: PingoGameID, id: UUID = UUID()) throws -> PingoMatchEnvelope {
        let challenge = PingoMatchEnvelope(
            id: id,
            gameID: game,
            status: .awaitingOpponent,
            revision: 0,
            createdByPlayerID: a,
            players: [.init(id: a, displayName: "alpha")]
        )
        return try PingoMatchReducer.accept(challenge, opponent: bravo, expectedRevision: 0)
    }

    func testCatalogContainsTwentyTwoGamesAndTwelveWaveSixGames() {
        XCTAssertEqual(PingoGameCatalog.launch.count, 22)
        XCTAssertEqual(PingoGameCatalog.wave6.count, 12)
        XCTAssertEqual(Set(PingoGameCatalog.wave6.map(\.id)), PingoExtraGameEngine.supportedGames)
    }

    func testExpansionEntitlementsAreSeparated() {
        XCTAssertTrue(PingoAccessPolicy.canPlay(.miniGolf, entitlements: [.premiumGames]))
        XCTAssertFalse(PingoAccessPolicy.canPlay(.bowling, entitlements: [.premiumGames]))
        XCTAssertTrue(PingoAccessPolicy.canPlay(.bowling, entitlements: [.arcadeExpansion]))
        XCTAssertFalse(PingoAccessPolicy.canPlay(.trivia, entitlements: [.arcadeExpansion]))
        XCTAssertTrue(PingoAccessPolicy.canPlay(.trivia, entitlements: [.wordPartyExpansion]))
        XCTAssertFalse(PingoAccessPolicy.canPlay(.ludo, entitlements: [.wordPartyExpansion]))
        XCTAssertTrue(PingoAccessPolicy.canPlay(.ludo, entitlements: [.classicsExpansion]))
        XCTAssertEqual(PingoAccessPolicy.packTitle(for: .crazyEights), "Classics Expansion")
    }

    func testExtraChallengeAcceptInitializesStateAndFitsTransport() throws {
        let challenge = PingoMatchReducer.challenge(gameID: .bowling, creator: alpha, seriesFormat: .bestOf3)
        let accepted = try PingoMatchReducer.accept(challenge, opponent: bravo, expectedRevision: challenge.revision)
        XCTAssertFalse(accepted.gameState.isEmpty)
        let state = try PingoExtraGameEngine.state(from: accepted.gameState, gameID: .bowling, matchID: accepted.id)
        XCTAssertEqual(state.scores, [0, 0])

        let payload = PingoMessagePayload(action: .accepted, sender: bravo, match: accepted)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: URL(string: "https://pingo.invalid/match")!)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
        XCTAssertEqual(try PingoMessageTransport.decode(url: url).match.gameID, .bowling)
    }

    func testBowlingFinishesAfterFiveThrowsEach() throws {
        var match = try activeExtraMatch(.bowling)
        for _ in 0..<10 where match.status == .active {
            let actor = try XCTUnwrap(match.currentPlayerID)
            match = try PingoExtraGameEngine.submit(
                move: .init(primary: 50, secondary: 82),
                to: match,
                actorID: actor,
                expectedRevision: match.revision
            )
        }
        XCTAssertEqual(match.status, .completed)
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .bowling, matchID: match.id)
        XCTAssertEqual(state.attempts, [5, 5])
    }

    func testPenaltyResolutionIsDeterministic() throws {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let match = try activeExtraMatch(.penaltyShootout, id: id)
        let move = PingoExtraGameMove(primary: 2, secondary: 80)
        let first = try PingoExtraGameEngine.submit(move: move, to: match, actorID: a, expectedRevision: match.revision)
        let second = try PingoExtraGameEngine.submit(move: move, to: match, actorID: a, expectedRevision: match.revision)
        XCTAssertEqual(first.gameState, second.gameState)
    }

    func testArcheryBullseyeScoresTen() throws {
        let match = try activeExtraMatch(.archery)
        let next = try PingoExtraGameEngine.submit(
            move: .init(primary: 50, secondary: 50),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        let state = try PingoExtraGameEngine.state(from: next.gameState, gameID: .archery, matchID: match.id)
        XCTAssertEqual(state.scores[0], 10)
        XCTAssertEqual(state.lastScore, 10)
    }

    func testDrawAndGuessSwapsRoleAndScoresCorrectGuess() throws {
        var match = try activeExtraMatch(.drawAndGuess)
        match = try PingoExtraGameEngine.submit(
            move: .init(points: [.init(x: 100, y: 100), .init(x: 800, y: 800)]),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        var state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .drawAndGuess, matchID: match.id)
        XCTAssertEqual(state.phase, 1)
        XCTAssertEqual(match.currentPlayerID, b)

        let answer = PingoExtraGameEngine.drawPrompt(for: state)
        match = try PingoExtraGameEngine.submit(
            move: .init(text: answer),
            to: match,
            actorID: b,
            expectedRevision: match.revision
        )
        state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .drawAndGuess, matchID: match.id)
        XCTAssertEqual(state.scores, [1, 2])
        XCTAssertEqual(state.phase, 0)
        XCTAssertEqual(match.currentPlayerID, b)
    }

    func testWordHuntRejectsAlreadyUsedWord() throws {
        var match = try activeExtraMatch(.wordHunt)
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .wordHunt, matchID: match.id)
        let word = try XCTUnwrap(PingoExtraGameEngine.wordHuntBoard(for: state).acceptedWords.sorted().first)
        match = try PingoExtraGameEngine.submit(
            move: .init(text: word),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        XCTAssertThrowsError(
            try PingoExtraGameEngine.submit(
                move: .init(text: word),
                to: match,
                actorID: b,
                expectedRevision: match.revision
            )
        ) { error in
            XCTAssertEqual(error as? PingoGameRuleError, .invalidMove)
        }
    }

    func testAnagramCorrectAnswerScoresWordLength() throws {
        let match = try activeExtraMatch(.anagrams)
        let answer = PingoExtraGameEngine.anagramPuzzles[0].answer
        let next = try PingoExtraGameEngine.submit(
            move: .init(text: answer),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        let state = try PingoExtraGameEngine.state(from: next.gameState, gameID: .anagrams, matchID: match.id)
        XCTAssertEqual(state.scores[0], answer.count)
    }

    func testTriviaCorrectAnswerScoresPoint() throws {
        let match = try activeExtraMatch(.trivia)
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .trivia, matchID: match.id)
        let question = PingoExtraGameEngine.triviaQuestion(for: state)
        let next = try PingoExtraGameEngine.submit(
            move: .init(primary: question.correctIndex),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        let updated = try PingoExtraGameEngine.state(from: next.gameState, gameID: .trivia, matchID: match.id)
        XCTAssertEqual(updated.scores[0], 1)
    }

    func testCrazyEightsPlaysLegalCardOrDraws() throws {
        let match = try activeExtraMatch(.crazyEights)
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .crazyEights, matchID: match.id)
        let hand = state.hands[0]
        let playable = hand.first(where: { PingoExtraGameEngine.isPlayableCard($0, on: state.topCard) })
        let move = PingoExtraGameMove(primary: playable ?? -1)
        let next = try PingoExtraGameEngine.submit(move: move, to: match, actorID: a, expectedRevision: match.revision)
        let updated = try PingoExtraGameEngine.state(from: next.gameState, gameID: .crazyEights, matchID: match.id)
        if playable != nil {
            XCTAssertEqual(updated.hands[0].count, hand.count - 1)
        } else {
            XCTAssertGreaterThanOrEqual(updated.hands[0].count, hand.count)
        }
        XCTAssertEqual(updated.hands[1].count, state.hands[1].count)
    }

    func testLudoDeterministicDieAndLegalMoveOrPass() throws {
        let match = try activeExtraMatch(.ludo)
        let state = try PingoExtraGameEngine.state(from: match.gameState, gameID: .ludo, matchID: match.id)
        let die = PingoExtraGameEngine.ludoDie(for: state)
        let move = PingoExtraGameMove(primary: die == 6 ? 0 : -1)
        let next = try PingoExtraGameEngine.submit(move: move, to: match, actorID: a, expectedRevision: match.revision)
        let updated = try PingoExtraGameEngine.state(from: next.gameState, gameID: .ludo, matchID: match.id)
        XCTAssertEqual(updated.attempts[0], 1)
        XCTAssertEqual(updated.positions[0][0], die == 6 ? 0 : -1)
    }

    func testMiniRacingAdvancesDeterministically() throws {
        let match = try activeExtraMatch(.miniRacing)
        let next = try PingoExtraGameEngine.submit(
            move: .init(primary: 82, secondary: 50),
            to: match,
            actorID: a,
            expectedRevision: match.revision
        )
        let state = try PingoExtraGameEngine.state(from: next.gameState, gameID: .miniRacing, matchID: match.id)
        XCTAssertGreaterThan(state.positions[0][0], 0)
        XCTAssertEqual(state.scores[0], state.positions[0][0])
    }

    func testReactionFasterResponseScoresMore() throws {
        let id = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!
        let match = try activeExtraMatch(.reactionBattle, id: id)
        let fast = try PingoExtraGameEngine.submit(
            move: .init(primary: 250), to: match, actorID: a, expectedRevision: match.revision
        )
        let slow = try PingoExtraGameEngine.submit(
            move: .init(primary: 900), to: match, actorID: a, expectedRevision: match.revision
        )
        let fastState = try PingoExtraGameEngine.state(from: fast.gameState, gameID: .reactionBattle, matchID: id)
        let slowState = try PingoExtraGameEngine.state(from: slow.gameState, gameID: .reactionBattle, matchID: id)
        XCTAssertGreaterThan(fastState.scores[0], slowState.scores[0])
    }

    func testRandomGameHonorsExpansionEntitlements() {
        let arcadeOnly = Set([PingoEntitlementID.arcadeExpansion])
        for seed in 0..<500 {
            let game = PingoRandomGame.pick(entitlements: arcadeOnly, seed: UInt64(seed))
            XCTAssertNotNil(game)
            if let game {
                XCTAssertTrue(PingoAccessPolicy.freeGames.contains(game) || PingoAccessPolicy.arcadeExpansionGames.contains(game))
                XCTAssertFalse(PingoAccessPolicy.wordPartyExpansionGames.contains(game))
                XCTAssertFalse(PingoAccessPolicy.classicsExpansionGames.contains(game))
            }
        }
    }

    func testExtraBestOfContinuationGetsFreshSeededState() throws {
        let challenge = PingoMatchReducer.challenge(gameID: .bowling, creator: alpha, seriesFormat: .bestOf3)
        var match = try PingoMatchReducer.accept(challenge, opponent: bravo, expectedRevision: challenge.revision)
        match = try PingoMatchReducer.completeTurn(
            match,
            actorID: a,
            expectedRevision: match.revision,
            winnerPlayerID: a,
            gameState: match.gameState
        )
        let next = try PingoMatchReducer.continueSeries(match, actorID: a)
        XCTAssertNotEqual(next.id, match.id)
        XCTAssertNotEqual(next.gameState, match.gameState)
        XCTAssertEqual(next.series?.wins, [1, 0])
        XCTAssertEqual(next.currentPlayerID, b)
    }

    func testStoreProductIdentifiersMapExpansionEntitlements() {
        XCTAssertEqual(PingoStoreProduct.product(for: "com.pingo.games.arcade")?.entitlement, .arcadeExpansion)
        XCTAssertEqual(PingoStoreProduct.product(for: "com.pingo.games.wordparty")?.entitlement, .wordPartyExpansion)
        XCTAssertEqual(PingoStoreProduct.product(for: "com.pingo.games.classics")?.entitlement, .classicsExpansion)
    }
}
