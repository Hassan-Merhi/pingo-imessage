import Foundation

public enum PingoMatchTransitionError: Error, Equatable, Sendable {
    case staleRevision
    case invalidStatus
    case actorNotInMatch
    case notActorsTurn
    case matchFull
    case actorAlreadyJoined
    case invalidNextPlayer
}

public enum PingoMatchReducer {
    public static func challenge(
        gameID: PingoGameID,
        creator: PingoPublicProfile,
        seriesFormat: PingoSeriesFormat = .single,
        now: Date = Date()
    ) -> PingoMatchEnvelope {
        let series = seriesFormat == .single ? nil : PingoSeriesState(format: seriesFormat)
        return PingoMatchEnvelope(
            gameID: gameID,
            status: .awaitingOpponent,
            createdAt: now,
            updatedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: now),
            revision: 0,
            createdByPlayerID: creator.id,
            players: [.init(id: creator.id, displayName: creator.username)],
            series: series
        )
    }

    public static func accept(
        _ match: PingoMatchEnvelope,
        opponent: PingoPublicProfile,
        expectedRevision: Int,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.status == .awaitingOpponent else { throw PingoMatchTransitionError.invalidStatus }
        guard match.players.count == 1 else { throw PingoMatchTransitionError.matchFull }
        guard !match.players.contains(where: { $0.id == opponent.id }) else {
            throw PingoMatchTransitionError.actorAlreadyJoined
        }

        let players = match.players + [.init(id: opponent.id, displayName: opponent.username)]
        let initialState = PingoBoardGameEngine.initialStateData(for: match.gameID)
        return PingoMatchEnvelope(
            id: match.id,
            gameID: match.gameID,
            status: .active,
            createdAt: match.createdAt,
            updatedAt: now,
            expiresAt: match.expiresAt,
            revision: match.revision + 1,
            turnNumber: 0,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: match.createdByPlayerID,
            players: players,
            gameState: initialState.isEmpty ? match.gameState : initialState,
            series: match.series
        )
    }

    public static func submitTurn(
        _ match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        nextPlayerID: UUID,
        gameState: Data,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard match.players.contains(where: { $0.id == actorID }) else {
            throw PingoMatchTransitionError.actorNotInMatch
        }
        guard match.currentPlayerID == actorID else { throw PingoMatchTransitionError.notActorsTurn }
        guard match.players.contains(where: { $0.id == nextPlayerID }) else {
            throw PingoMatchTransitionError.invalidNextPlayer
        }

        return PingoMatchEnvelope(
            id: match.id,
            gameID: match.gameID,
            status: .active,
            createdAt: match.createdAt,
            updatedAt: now,
            expiresAt: match.expiresAt,
            revision: match.revision + 1,
            turnNumber: match.turnNumber + 1,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: nextPlayerID,
            players: match.players,
            gameState: gameState,
            series: match.series
        )
    }

    public static func completeTurn(
        _ match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        winnerPlayerID: UUID?,
        gameState: Data,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard match.players.contains(where: { $0.id == actorID }) else {
            throw PingoMatchTransitionError.actorNotInMatch
        }
        guard match.currentPlayerID == actorID else { throw PingoMatchTransitionError.notActorsTurn }
        if let winnerPlayerID,
           !match.players.contains(where: { $0.id == winnerPlayerID }) {
            throw PingoMatchTransitionError.invalidNextPlayer
        }

        let winnerIndex = winnerPlayerID.flatMap { id in match.players.firstIndex(where: { $0.id == id }) }
        let updatedSeries = match.series?.recording(winnerIndex: winnerIndex)
        return PingoMatchEnvelope(
            id: match.id,
            gameID: match.gameID,
            status: .completed,
            createdAt: match.createdAt,
            updatedAt: now,
            expiresAt: match.expiresAt,
            revision: match.revision + 1,
            turnNumber: match.turnNumber + 1,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: nil,
            winnerPlayerID: winnerPlayerID,
            players: match.players,
            gameState: gameState,
            series: updatedSeries
        )
    }

    public static func resign(
        _ match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard let actorIndex = match.players.firstIndex(where: { $0.id == actorID }) else {
            throw PingoMatchTransitionError.actorNotInMatch
        }

        let winnerIndex = match.players.count == 2 ? 1 - actorIndex : nil
        let winner = winnerIndex.map { match.players[$0].id }
        let updatedSeries = match.series?.recording(winnerIndex: winnerIndex)
        return PingoMatchEnvelope(
            id: match.id,
            gameID: match.gameID,
            status: .resigned,
            createdAt: match.createdAt,
            updatedAt: now,
            expiresAt: match.expiresAt,
            revision: match.revision + 1,
            turnNumber: match.turnNumber,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: nil,
            winnerPlayerID: winner,
            players: match.players,
            gameState: match.gameState,
            series: updatedSeries
        )
    }

    public static func continueSeries(
        _ match: PingoMatchEnvelope,
        actorID: UUID,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.status == .completed || match.status == .resigned,
              let series = match.series,
              !series.completed,
              match.players.count == 2 else {
            throw PingoMatchTransitionError.invalidStatus
        }
        guard match.players.contains(where: { $0.id == actorID }) else {
            throw PingoMatchTransitionError.actorNotInMatch
        }
        guard match.createdByPlayerID == actorID else {
            throw PingoMatchTransitionError.notActorsTurn
        }

        let starterIndex = max(0, series.gameNumber - 1) % 2
        let boardState = PingoBoardGameEngine.initialStateData(for: match.gameID)
        let initialState = boardState.isEmpty ? PingoPhysicsGameEngine.initialStateData(for: match.gameID) : boardState
        return PingoMatchEnvelope(
            gameID: match.gameID,
            status: .active,
            createdAt: now,
            updatedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: now),
            revision: 0,
            turnNumber: 0,
            createdByPlayerID: match.createdByPlayerID,
            currentPlayerID: match.players[starterIndex].id,
            players: match.players,
            gameState: initialState,
            series: series
        )
    }
}
