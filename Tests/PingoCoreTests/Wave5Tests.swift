import Foundation
import XCTest
@testable import PingoCore

final class Wave5Tests: XCTestCase {
    private let a = UUID()
    private let b = UUID()

    private func activeMatch(
        game: PingoGameID = .ticTacToe,
        series: PingoSeriesState? = nil
    ) -> PingoMatchEnvelope {
        PingoMatchEnvelope(
            gameID: game,
            status: .active,
            revision: 4,
            createdByPlayerID: a,
            currentPlayerID: a,
            players: [
                .init(id: a, displayName: "alpha"),
                .init(id: b, displayName: "bravo")
            ],
            gameState: PingoBoardGameEngine.initialStateData(for: game),
            series: series
        )
    }

    func testBestOfThreeCompletesAfterTwoWins() {
        var series = PingoSeriesState(format: .bestOf3)
        series = series.recording(winnerIndex: 0)
        XCTAssertFalse(series.completed)
        XCTAssertEqual(series.wins, [1, 0])
        XCTAssertEqual(series.gameNumber, 2)
        series = series.recording(winnerIndex: 0)
        XCTAssertTrue(series.completed)
        XCTAssertEqual(series.winnerPlayerIndex, 0)
        XCTAssertEqual(series.wins, [2, 0])
    }

    func testMatchCompletionRecordsSeriesScore() throws {
        let match = activeMatch(series: .init(format: .bestOf5))
        let completed = try PingoMatchReducer.completeTurn(
            match,
            actorID: a,
            expectedRevision: match.revision,
            winnerPlayerID: a,
            gameState: match.gameState
        )
        XCTAssertEqual(completed.series?.wins, [1, 0])
        XCTAssertEqual(completed.series?.gameNumber, 2)
        XCTAssertFalse(completed.series?.completed ?? true)
    }

    func testOnlySeriesHostCanContinue() throws {
        let match = activeMatch(series: .init(format: .bestOf3))
        let completed = try PingoMatchReducer.completeTurn(
            match,
            actorID: a,
            expectedRevision: match.revision,
            winnerPlayerID: a,
            gameState: match.gameState
        )
        XCTAssertThrowsError(try PingoMatchReducer.continueSeries(completed, actorID: b)) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .notActorsTurn)
        }
    }

    func testContinueSeriesStartsFreshGameAndAlternatesStarter() throws {
        let match = activeMatch(series: .init(format: .bestOf3))
        let completed = try PingoMatchReducer.completeTurn(
            match,
            actorID: a,
            expectedRevision: match.revision,
            winnerPlayerID: a,
            gameState: match.gameState
        )
        let next = try PingoMatchReducer.continueSeries(completed, actorID: a)
        XCTAssertNotEqual(next.id, completed.id)
        XCTAssertEqual(next.status, .active)
        XCTAssertEqual(next.currentPlayerID, b)
        XCTAssertEqual(next.series?.wins, [1, 0])
        XCTAssertEqual(next.series?.id, completed.series?.id)
        XCTAssertFalse(next.gameState.isEmpty)
    }

    func testProgressionAwardsXPStatsHistoryAndFriendRecordOnce() throws {
        let base = activeMatch()
        let finished = try PingoMatchReducer.completeTurn(
            base,
            actorID: a,
            expectedRevision: base.revision,
            winnerPlayerID: a,
            gameState: base.gameState
        )
        let first = try PingoProgression.applyingResult(from: finished, localPlayerID: a, to: .init())
        XCTAssertEqual(first.xp, 120)
        XCTAssertEqual(first.wins, 1)
        XCTAssertEqual(first.currentStreak, 1)
        XCTAssertEqual(first.history.count, 1)
        XCTAssertEqual(first.opponentRecords.first?.opponentID, b)
        XCTAssertEqual(first.opponentRecords.first?.wins, 1)
        XCTAssertTrue(first.achievements.contains(.firstWin))

        let second = try PingoProgression.applyingResult(from: finished, localPlayerID: a, to: first)
        XCTAssertEqual(second.xp, first.xp)
        XCTAssertEqual(second.gamesPlayed, first.gamesPlayed)
        XCTAssertEqual(second.history.count, 1)
    }

    func testStreakAchievementsUnlock() throws {
        var state = PingoProgressionState()
        for index in 0..<5 {
            let match = PingoMatchEnvelope(
                id: UUID(),
                gameID: PingoGameID.allCases[index],
                status: .completed,
                updatedAt: Date(timeIntervalSince1970: Double(index + 1)),
                winnerPlayerID: a,
                players: [.init(id: a, displayName: "alpha"), .init(id: b, displayName: "bravo")]
            )
            state = try PingoProgression.applyingResult(from: match, localPlayerID: a, to: state)
        }
        XCTAssertEqual(state.currentStreak, 5)
        XCTAssertTrue(state.achievements.contains(.hatTrick))
        XCTAssertTrue(state.achievements.contains(.hotFive))
        XCTAssertTrue(state.achievements.contains(.fiveGameExplorer))
        XCTAssertEqual(state.level, 2)
    }

    func testPremiumPackUnlocksOnlyPremiumGames() {
        for game in PingoAccessPolicy.freeGames {
            XCTAssertTrue(PingoAccessPolicy.canPlay(game, entitlements: []))
        }
        for game in PingoAccessPolicy.premiumGames {
            XCTAssertFalse(PingoAccessPolicy.canPlay(game, entitlements: []))
            XCTAssertTrue(PingoAccessPolicy.canPlay(game, entitlements: [.premiumGames]))
        }
    }

    func testRandomGameNeverSelectsLockedGame() {
        for seed in 0..<500 {
            let game = PingoRandomGame.pick(entitlements: [], seed: UInt64(seed))
            XCTAssertNotNil(game)
            if let game { XCTAssertTrue(PingoAccessPolicy.freeGames.contains(game)) }
        }
    }

    func testVerifiedCosmeticEntitlementReconcilesInventoryAndEquip() throws {
        var state = PingoProgression.replacingStoreEntitlements([.neonCosmetics], in: .init())
        XCTAssertTrue(state.ownedCosmetics.contains("theme.neon"))
        state = try PingoProgression.equip(cosmeticID: "theme.neon", in: state)
        XCTAssertEqual(state.equippedCosmetics[.theme], "theme.neon")

        state = PingoProgression.replacingStoreEntitlements([], in: state)
        XCTAssertFalse(state.ownedCosmetics.contains("theme.neon"))
        XCTAssertEqual(state.equippedCosmetics[.theme], "theme.classic")
    }

    func testLegacySchemaTwoMatchDecodesWithoutSeries() throws {
        struct LegacyV2: Encodable {
            let id: UUID
            let schemaVersion = 2
            let gameID = PingoGameID.ticTacToe
            let status = PingoMatchStatus.active
            let createdAt: Date
            let updatedAt: Date
            let expiresAt: Date? = nil
            let revision = 1
            let turnNumber = 0
            let createdByPlayerID: UUID
            let currentPlayerID: UUID
            let winnerPlayerID: UUID? = nil
            let players: [PingoPlayerRef]
            let gameState = Data()
        }
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let legacy = LegacyV2(
            id: UUID(),
            createdAt: date,
            updatedAt: date,
            createdByPlayerID: a,
            currentPlayerID: a,
            players: [.init(id: a, displayName: "alpha"), .init(id: b, displayName: "bravo")]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let decoded = try PingoMatchCodec.decode(encoder.encode(legacy))
        XCTAssertEqual(decoded.schemaVersion, 2)
        XCTAssertNil(decoded.series)
    }

    func testSeriesMetadataRoundTripsAndFitsMessageTransport() throws {
        let profile = PingoPublicProfile(id: a, username: "alpha")
        let challenge = PingoMatchReducer.challenge(gameID: .eightBall, creator: profile, seriesFormat: .bestOf5)
        let payload = PingoMessagePayload(action: .challenge, sender: profile, match: challenge)
        let url = try PingoMessageTransport.makeURL(payload: payload, baseURL: URL(string: "https://pingo.invalid/match")!)
        let decoded = try PingoMessageTransport.decode(url: url)
        XCTAssertEqual(decoded.match.series?.format, .bestOf5)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
    }

    func testStoreProductIdentifiersMapToEntitlements() {
        XCTAssertEqual(PingoStoreProduct.product(for: "com.pingo.premiumgames")?.entitlement, .premiumGames)
        XCTAssertEqual(PingoStoreProduct.product(for: "com.pingo.cosmetics.neon")?.entitlement, .neonCosmetics)
        XCTAssertNil(PingoStoreProduct.product(for: "com.example.unknown"))
    }
}
