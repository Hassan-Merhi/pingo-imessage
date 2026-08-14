import Foundation

public enum PingoBoardGameEngine {
    public static let supportedGames: Set<PingoGameID> = [.ticTacToe, .connectFour, .checkers, .chess, .seaBattle]

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private static let decoder = JSONDecoder()

    public static func initialStateData(for gameID: PingoGameID) -> Data {
        switch gameID {
        case .ticTacToe: return (try? encoder.encode(PingoTicTacToeState())) ?? Data()
        case .connectFour: return (try? encoder.encode(PingoConnectFourState())) ?? Data()
        case .checkers: return (try? encoder.encode(PingoCheckersState())) ?? Data()
        case .chess: return (try? encoder.encode(PingoChessState())) ?? Data()
        case .seaBattle: return (try? PingoSeaBattleWireCodec.encode(PingoSeaBattleState())) ?? Data()
        default: return Data()
        }
    }

    public static func submit(
        move: PingoGameMove,
        to match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.currentPlayerID == actorID else { throw PingoMatchTransitionError.notActorsTurn }
        guard let actorIndex = match.players.firstIndex(where: { $0.id == actorID }), match.players.count == 2 else {
            throw PingoMatchTransitionError.actorNotInMatch
        }
        let opponentIndex = 1 - actorIndex
        let opponentID = match.players[opponentIndex].id

        switch (match.gameID, move) {
        case (.ticTacToe, .ticTacToe(let point)):
            let state = try decode(PingoTicTacToeState.self, data: match.gameState)
            let result = try PingoTicTacToe.apply(point, player: actorIndex, to: state)
            let data = try encoder.encode(result.0)
            if let winner = result.winner {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: match.players[winner].id, gameState: data, now: now)
            }
            if result.draw {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: nil, gameState: data, now: now)
            }
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: opponentID, gameState: data, now: now)

        case (.connectFour, .connectFour(let column)):
            let state = try decode(PingoConnectFourState.self, data: match.gameState)
            let result = try PingoConnectFour.apply(column: column, player: actorIndex, to: state)
            let data = try encoder.encode(result.0)
            if let winner = result.winner {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: match.players[winner].id, gameState: data, now: now)
            }
            if result.draw {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: nil, gameState: data, now: now)
            }
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: opponentID, gameState: data, now: now)

        case (.checkers, .checkers(let from, let to)):
            let state = try decode(PingoCheckersState.self, data: match.gameState)
            let result = try PingoCheckers.apply(from: from, to: to, player: actorIndex, to: state)
            let data = try encoder.encode(result.0)
            if let winner = result.winner {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: match.players[winner].id, gameState: data, now: now)
            }
            let nextPlayerID = result.samePlayerContinues ? actorID : opponentID
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: nextPlayerID, gameState: data, now: now)

        case (.chess, .chess(let from, let to, let promotion)):
            let state = try decode(PingoChessState.self, data: match.gameState)
            let result = try PingoChess.apply(from: from, to: to, player: actorIndex, promotion: promotion, to: state)
            let data = try encoder.encode(result.state)
            if let winner = result.winner {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: match.players[winner].id, gameState: data, now: now)
            }
            if result.draw {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: nil, gameState: data, now: now)
            }
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: opponentID, gameState: data, now: now)

        case (.seaBattle, .seaBattleLockFleet(let fleet)):
            let state = try PingoSeaBattleWireCodec.decode(match.gameState)
            let next = try PingoSeaBattle.lockFleet(player: actorIndex, placements: fleet, in: state)
            let data = try PingoSeaBattleWireCodec.encode(next)
            let nextPlayerID = next.fleetReady == [true, true] ? match.players[0].id : opponentID
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: nextPlayerID, gameState: data, now: now)

        case (.seaBattle, .seaBattleResolvePending(let fleet)):
            let state = try PingoSeaBattleWireCodec.decode(match.gameState)
            let result = try PingoSeaBattle.resolvePending(defender: actorIndex, fleet: fleet, in: state)
            let data = try PingoSeaBattleWireCodec.encode(result.0)
            if let winner = result.winner {
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                          winnerPlayerID: match.players[winner].id, gameState: data, now: now)
            }
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: actorID, gameState: data, now: now)

        case (.seaBattle, .seaBattleFire(let point)):
            let state = try PingoSeaBattleWireCodec.decode(match.gameState)
            let next = try PingoSeaBattle.fire(at: point, player: actorIndex, in: state)
            let data = try PingoSeaBattleWireCodec.encode(next)
            return try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: expectedRevision,
                                                     nextPlayerID: opponentID, gameState: data, now: now)

        default:
            throw PingoGameRuleError.unsupportedGame
        }
    }

    public static func ticTacToeState(from data: Data) throws -> PingoTicTacToeState { try decode(PingoTicTacToeState.self, data: data) }
    public static func connectFourState(from data: Data) throws -> PingoConnectFourState { try decode(PingoConnectFourState.self, data: data) }
    public static func checkersState(from data: Data) throws -> PingoCheckersState { try decode(PingoCheckersState.self, data: data) }
    public static func chessState(from data: Data) throws -> PingoChessState { try decode(PingoChessState.self, data: data) }
    public static func seaBattleState(from data: Data) throws -> PingoSeaBattleState { try PingoSeaBattleWireCodec.decode(data) }
    public static func seaBattleStateData(_ state: PingoSeaBattleState) throws -> Data { try PingoSeaBattleWireCodec.encode(state) }

    private static func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T {
        guard !data.isEmpty else { throw PingoGameRuleError.invalidState }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw PingoGameRuleError.invalidState }
    }
}
