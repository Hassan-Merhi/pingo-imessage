import XCTest
@testable import PingoCore

final class Wave4Tests: XCTestCase {
    private func match(_ game: PingoGameID) -> (PingoMatchEnvelope, UUID, UUID) {
        let a = UUID(), b = UUID()
        return (
            PingoMatchEnvelope(
                gameID: game,
                status: .active,
                revision: 4,
                createdByPlayerID: a,
                currentPlayerID: a,
                players: [.init(id: a, displayName: "alpha"), .init(id: b, displayName: "bravo")],
                gameState: PingoPhysicsGameEngine.initialStateData(for: game)
            ), a, b
        )
    }

    func testAllTenOriginalGamesRemainPlayable() {
        let originalGames: Set<PingoGameID> = [
            .eightBall, .cupPong, .basketball, .darts, .miniGolf,
            .seaBattle, .chess, .checkers, .connectFour, .ticTacToe
        ]
        XCTAssertEqual(PingoPlayableGameRegistry.supportedGames, originalGames)
    }

    func testEightBallDeterministicBreakAdvancesState() throws {
        let initial = PingoEightBallState()
        let resultA = try PingoEightBall.apply(.init(angleDegrees: 0, power: 0.9), player: 0, to: initial)
        let resultB = try PingoEightBall.apply(.init(angleDegrees: 0, power: 0.9), player: 0, to: initial)
        XCTAssertEqual(resultA.state, resultB.state)
        XCTAssertEqual(resultA.state.shotCount, 1)
        XCTAssertNotEqual(resultA.state.balls, initial.balls)
    }

    func testCupPongPerfectCupRemovesTarget() throws {
        let state = PingoCupPongState()
        let result = try PingoCupPong.apply(.init(angleDegrees: 0, power: 0.34), player: 0, to: state)
        XCTAssertFalse(result.0.cups[1][5])
        XCTAssertEqual(result.0.lastCup, 5)
    }

    func testBasketballIdealReleaseScoresThree() throws {
        let result = try PingoBasketball.apply(.init(angleDegrees: 52, power: 0.72), player: 0, to: PingoBasketballState())
        XCTAssertEqual(result.0.scores[0], 3)
        XCTAssertEqual(result.0.attempts[0], 1)
        XCTAssertFalse(result.finished)
    }

    func testDartsBullAndVisitScoring() throws {
        XCTAssertEqual(PingoDarts.score(.init(x: 0, y: 0)), 50)
        let visit = PingoDartsVisit(darts: [.init(x: 0, y: 0), .init(x: 0, y: 0), .init(x: 0, y: 0)])
        let result = try PingoDarts.apply(visit, player: 0, to: PingoDartsState())
        XCTAssertEqual(result.0.remaining[0], 151)
        XCTAssertEqual(result.0.lastVisitScore, 150)
    }

    func testDartsBustRestoresVisitStart() throws {
        let state = PingoDartsState(remaining: [20, 301])
        let visit = PingoDartsVisit(darts: [.init(x: 0, y: 0), .init(x: 0, y: 0), .init(x: 0, y: 0)])
        let result = try PingoDarts.apply(visit, player: 0, to: state)
        XCTAssertEqual(result.0.remaining[0], 20)
        XCTAssertEqual(result.0.lastVisitScore, 0)
    }

    func testMiniGolfCanSinkLowSpeedPutt() throws {
        let layout = PingoMiniGolf.course[0]
        let state = PingoMiniGolfState(
            holeIndex: 0,
            positions: [.init(x: layout.hole.x - 0.05, y: layout.hole.y), layout.start]
        )
        let result = try PingoMiniGolf.apply(.init(angleDegrees: 0, power: 0.05), player: 0, to: state)
        XCTAssertTrue(result.state.holed[0])
        XCTAssertEqual(result.state.holeStrokes[0], 1)
        XCTAssertEqual(result.nextPlayer, 1)
    }

    func testPhysicsEngineRejectsStaleRevision() throws {
        let (m, a, _) = match(.basketball)
        XCTAssertThrowsError(try PingoPhysicsGameEngine.submit(
            move: .basketball(.init(angleDegrees: 52, power: 0.72)),
            to: m,
            actorID: a,
            expectedRevision: m.revision - 1
        )) { error in
            XCTAssertEqual(error as? PingoMatchTransitionError, .staleRevision)
        }
    }

    func testPhysicsEngineSubmitsTurnAndPersistsState() throws {
        let (m, a, b) = match(.cupPong)
        let next = try PingoPhysicsGameEngine.submit(
            move: .cupPong(.init(angleDegrees: 0, power: 0.34)),
            to: m,
            actorID: a,
            expectedRevision: m.revision
        )
        XCTAssertEqual(next.revision, m.revision + 1)
        XCTAssertEqual(next.currentPlayerID, b)
        let state = try PingoPhysicsGameEngine.cupPongState(from: next.gameState)
        XCTAssertFalse(state.cups[1][5])
    }

    func testInitialPhysicsPayloadsFitInsideMessagesLimit() throws {
        let sender = PingoPublicProfile(username: "physics_test")
        let opponent = PingoPublicProfile(username: "opponent")
        let baseURL = URL(string: "https://pingo.invalid/m")!
        for game in PingoPhysicsGameEngine.supportedGames {
            let match = PingoMatchEnvelope(
                gameID: game,
                status: .active,
                revision: 1,
                createdByPlayerID: sender.id,
                currentPlayerID: sender.id,
                players: [.init(id: sender.id, displayName: sender.username), .init(id: opponent.id, displayName: opponent.username)],
                gameState: PingoPhysicsGameEngine.initialStateData(for: game)
            )
            let url = try PingoMessageTransport.makeURL(payload: .init(action: .turn, sender: sender, match: match), baseURL: baseURL)
            XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength, "\(game) payload is too large")
        }
    }

    func testEightBallPayloadStillFitsAfterBreak() throws {
        let sender = PingoPublicProfile(username: "physics_test")
        let opponent = PingoPublicProfile(username: "opponent")
        let a = sender.id, b = opponent.id
        var match = PingoMatchEnvelope(
            gameID: .eightBall,
            status: .active,
            revision: 1,
            createdByPlayerID: a,
            currentPlayerID: a,
            players: [.init(id: a, displayName: sender.username), .init(id: b, displayName: opponent.username)],
            gameState: PingoPhysicsGameEngine.initialStateData(for: .eightBall)
        )
        match = try PingoPhysicsGameEngine.submit(move: .eightBall(.init(angleDegrees: 0, power: 0.9)), to: match, actorID: a, expectedRevision: match.revision)
        let url = try PingoMessageTransport.makeURL(payload: .init(action: .turn, sender: sender, match: match), baseURL: URL(string: "https://pingo.invalid/m")!)
        XCTAssertLessThanOrEqual(url.absoluteString.count, PingoMessageTransport.maximumURLLength)
    }
}
