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
        now: Date = Date()
    ) -> PingoMatchEnvelope {
        PingoMatchEnvelope(
            gameID: gameID,
            status: .awaitingOpponent,
            createdAt: now,
            updatedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: now),
            revision: 0,
            createdByPlayerID: creator.id,
            players: [.init(id: creator.id, displayName: creator.username)]
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
            gameState: match.gameState
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
        guard nextPlayerID != actorID,
              match.players.contains(where: { $0.id == nextPlayerID })
        else {
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
            gameState: gameState
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
        guard match.players.contains(where: { $0.id == actorID }) else {
            throw PingoMatchTransitionError.actorNotInMatch
        }

        let winner = match.players.first(where: { $0.id != actorID })?.id
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
            gameState: match.gameState
        )
    }
}
