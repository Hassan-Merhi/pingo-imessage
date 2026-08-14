import XCTest
@testable import PingoCore

final class Wave3Tests: XCTestCase {
    private func match(_ game: PingoGameID) -> (PingoMatchEnvelope, UUID, UUID) {
        let a = UUID(), b = UUID()
        return (
            PingoMatchEnvelope(
                gameID: game,
                status: .active,
                revision: 1,
                createdByPlayerID: a,
                currentPlayerID: a,
                players: [.init(id: a, displayName: "alpha"), .init(id: b, displayName: "bravo")],
                gameState: PingoBoardGameEngine.initialStateData(for: game)
            ), a, b
        )
    }

    func testTicTacToeCompletesOnThreeInARow() throws {
        var (m, a, b) = match(.ticTacToe)
        m = try PingoBoardGameEngine.submit(move: .ticTacToe(.init(row: 0, column: 0)), to: m, actorID: a, expectedRevision: m.revision)
        m = try PingoBoardGameEngine.submit(move: .ticTacToe(.init(row: 1, column: 0)), to: m, actorID: b, expectedRevision: m.revision)
        m = try PingoBoardGameEngine.submit(move: .ticTacToe(.init(row: 0, column: 1)), to: m, actorID: a, expectedRevision: m.revision)
        m = try PingoBoardGameEngine.submit(move: .ticTacToe(.init(row: 1, column: 1)), to: m, actorID: b, expectedRevision: m.revision)
        m = try PingoBoardGameEngine.submit(move: .ticTacToe(.init(row: 0, column: 2)), to: m, actorID: a, expectedRevision: m.revision)
        XCTAssertEqual(m.status, .completed)
        XCTAssertEqual(m.winnerPlayerID, a)
        XCTAssertNil(m.currentPlayerID)
    }

    func testConnectFourHorizontalWin() throws {
        var (m, a, b) = match(.connectFour)
        for column in 0..<3 {
            m = try PingoBoardGameEngine.submit(move: .connectFour(column: column), to: m, actorID: a, expectedRevision: m.revision)
            m = try PingoBoardGameEngine.submit(move: .connectFour(column: column), to: m, actorID: b, expectedRevision: m.revision)
        }
        m = try PingoBoardGameEngine.submit(move: .connectFour(column: 3), to: m, actorID: a, expectedRevision: m.revision)
        XCTAssertEqual(m.status, .completed)
        XCTAssertEqual(m.winnerPlayerID, a)
    }

    func testCheckersMandatoryCaptureAndMultiJump() throws {
        var cells = Array(repeating: 0, count: 64)
        cells[5 * 8] = 1
        cells[4 * 8 + 1] = 3
        cells[2 * 8 + 3] = 3
        cells[5 * 8 + 4] = 1
        let state = PingoCheckersState(cells: cells)
        XCTAssertThrowsError(try PingoCheckers.apply(from: .init(row: 5, column: 4), to: .init(row: 4, column: 5), player: 0, to: state))
        let first = try PingoCheckers.apply(from: .init(row: 5, column: 0), to: .init(row: 3, column: 2), player: 0, to: state)
        XCTAssertTrue(first.samePlayerContinues)
        XCTAssertEqual(first.0.forcedFrom, 3 * 8 + 2)
        let second = try PingoCheckers.apply(from: .init(row: 3, column: 2), to: .init(row: 1, column: 4), player: 0, to: first.0)
        XCTAssertFalse(second.samePlayerContinues)
        XCTAssertEqual(second.winner, 0)
    }

    func testCheckersPromotesToKing() throws {
        var cells = Array(repeating: 0, count: 64)
        cells[1 * 8 + 2] = 1
        cells[7 * 8] = 3
        let result = try PingoCheckers.apply(from: .init(row: 1, column: 2), to: .init(row: 0, column: 1), player: 0, to: .init(cells: cells))
        XCTAssertEqual(result.0.cells[1], 2)
    }

    func testChessFoolsMateDetected() throws {
        var state = PingoChessState()
        state = try PingoChess.apply(from: .init(row: 6, column: 5), to: .init(row: 5, column: 5), player: 0, promotion: nil, to: state).state
        state = try PingoChess.apply(from: .init(row: 1, column: 4), to: .init(row: 3, column: 4), player: 1, promotion: nil, to: state).state
        state = try PingoChess.apply(from: .init(row: 6, column: 6), to: .init(row: 4, column: 6), player: 0, promotion: nil, to: state).state
        let mate = try PingoChess.apply(from: .init(row: 0, column: 3), to: .init(row: 4, column: 7), player: 1, promotion: nil, to: state)
        XCTAssertTrue(mate.checkmate)
        XCTAssertEqual(mate.winner, 1)
    }

    func testChessCastlingMovesRookAndKing() throws {
        var cells = PingoChess.initialBoard()
        cells[61] = 0
        cells[62] = 0
        let state = PingoChessState(cells: cells)
        XCTAssertTrue(PingoChess.legalDestinations(from: .init(row: 7, column: 4), player: 0, in: state).contains(.init(row: 7, column: 6)))
        let result = try PingoChess.apply(from: .init(row: 7, column: 4), to: .init(row: 7, column: 6), player: 0, promotion: nil, to: state)
        XCTAssertEqual(result.state.cells[62], 6)
        XCTAssertEqual(result.state.cells[61], 4)
        XCTAssertEqual(result.state.cells[63], 0)
    }

    func testChessEnPassant() throws {
        var state = PingoChessState()
        state = try PingoChess.apply(from: .init(row: 6, column: 4), to: .init(row: 4, column: 4), player: 0, promotion: nil, to: state).state
        state = try PingoChess.apply(from: .init(row: 1, column: 0), to: .init(row: 2, column: 0), player: 1, promotion: nil, to: state).state
        state = try PingoChess.apply(from: .init(row: 4, column: 4), to: .init(row: 3, column: 4), player: 0, promotion: nil, to: state).state
        state = try PingoChess.apply(from: .init(row: 1, column: 3), to: .init(row: 3, column: 3), player: 1, promotion: nil, to: state).state
        XCTAssertTrue(PingoChess.legalDestinations(from: .init(row: 3, column: 4), player: 0, in: state).contains(.init(row: 2, column: 3)))
        let result = try PingoChess.apply(from: .init(row: 3, column: 4), to: .init(row: 2, column: 3), player: 0, promotion: nil, to: state)
        XCTAssertEqual(result.state.cells[3 * 8 + 3], 0)
        XCTAssertEqual(result.state.cells[2 * 8 + 3], 1)
    }

    func testChessPromotionDefaultsToQueen() throws {
        var cells = Array(repeating: 0, count: 64)
        cells[7 * 8 + 4] = 6
        cells[4] = 12
        cells[8] = 1
        let state = PingoChessState(cells: cells, castlingRights: 0)
        let result = try PingoChess.apply(from: .init(row: 1, column: 0), to: .init(row: 0, column: 0), player: 0, promotion: nil, to: state)
        XCTAssertEqual(result.state.cells[0], 5)
    }

    func testSeaBattlePlacementRejectsOverlapAndCompletesFleet() throws {
        var state = PingoSeaBattleState()
        state = try PingoSeaBattle.place(ship: .carrier, start: .init(row: 0, column: 0), orientation: .horizontal, player: 0, in: state)
        XCTAssertThrowsError(try PingoSeaBattle.place(ship: .destroyer, start: .init(row: 0, column: 2), orientation: .vertical, player: 0, in: state))
        state = try PingoSeaBattle.place(ship: .battleship, start: .init(row: 1, column: 0), orientation: .horizontal, player: 0, in: state)
        state = try PingoSeaBattle.place(ship: .cruiser, start: .init(row: 2, column: 0), orientation: .horizontal, player: 0, in: state)
        state = try PingoSeaBattle.place(ship: .submarine, start: .init(row: 3, column: 0), orientation: .horizontal, player: 0, in: state)
        state = try PingoSeaBattle.place(ship: .destroyer, start: .init(row: 4, column: 0), orientation: .horizontal, player: 0, in: state)
        XCTAssertTrue(state.fleetReady(player: 0))
    }

    func testSeaBattleWinAfterLastShipCellHit() throws {
        func readyFleet(player: Int, state: PingoSeaBattleState) throws -> PingoSeaBattleState {
            var state = state
            state = try PingoSeaBattle.place(ship: .carrier, start: .init(row: 0, column: 0), orientation: .horizontal, player: player, in: state)
            state = try PingoSeaBattle.place(ship: .battleship, start: .init(row: 1, column: 0), orientation: .horizontal, player: player, in: state)
            state = try PingoSeaBattle.place(ship: .cruiser, start: .init(row: 2, column: 0), orientation: .horizontal, player: player, in: state)
            state = try PingoSeaBattle.place(ship: .submarine, start: .init(row: 3, column: 0), orientation: .horizontal, player: player, in: state)
            state = try PingoSeaBattle.place(ship: .destroyer, start: .init(row: 4, column: 0), orientation: .horizontal, player: player, in: state)
            return state
        }
        var state = try readyFleet(player: 0, state: .init())
        state = try readyFleet(player: 1, state: state)
        let occupied = state.occupiedCells(player: 1).sorted()
        var winner: Int?
        for cell in occupied {
            let result = try PingoSeaBattle.fire(at: .init(row: cell / 10, column: cell % 10), player: 0, in: state)
            state = result.0
            winner = result.winner
        }
        XCTAssertEqual(winner, 0)
    }

    func testBoardStatePayloadsStaySmallEnoughForIMessage() {
        for game in PingoBoardGameEngine.supportedGames {
            XCTAssertLessThan(PingoBoardGameEngine.initialStateData(for: game).count, 1_000)
        }
    }
}
