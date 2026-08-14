import Foundation

public enum PingoProgression {
    public static let xpPerLevel = 500
    public static let maximumHistory = 100

    public static func level(forXP xp: Int) -> Int {
        max(1, min(100, 1 + max(0, xp) / xpPerLevel))
    }

    public static func xpAward(for result: PingoMatchResult) -> Int {
        switch result {
        case .win: 120
        case .draw: 60
        case .loss: 30
        }
    }

    public static func applyingResult(
        from match: PingoMatchEnvelope,
        localPlayerID: UUID,
        to state: PingoProgressionState,
        now: Date = Date()
    ) throws -> PingoProgressionState {
        guard match.status == .completed || match.status == .resigned else {
            throw PingoProgressionError.matchNotFinished
        }
        guard let localIndex = match.players.firstIndex(where: { $0.id == localPlayerID }),
              match.players.count == 2 else {
            throw PingoProgressionError.playerNotInMatch
        }
        if state.processedMatchIDs.contains(match.id) { return state }

        let opponent = match.players[1 - localIndex]
        let result: PingoMatchResult
        if let winner = match.winnerPlayerID {
            result = winner == localPlayerID ? .win : .loss
        } else {
            result = .draw
        }

        var next = state
        next.processedMatchIDs.insert(match.id)
        next.xp += xpAward(for: result)
        switch result {
        case .win:
            next.wins += 1
            next.currentStreak += 1
            next.bestStreak = max(next.bestStreak, next.currentStreak)
        case .loss:
            next.losses += 1
            next.currentStreak = 0
        case .draw:
            next.draws += 1
            next.currentStreak = 0
        }

        next.gameCounts[match.gameID.rawValue, default: 0] += 1
        next.updateOpponentRecord(opponent: opponent, result: result, playedAt: match.updatedAt)
        let entry = PingoMatchHistoryEntry(
            id: match.id,
            gameID: match.gameID,
            opponentID: opponent.id,
            opponentName: opponent.displayName,
            result: result,
            playedAt: match.updatedAt,
            seriesID: match.series?.id
        )
        next.history.removeAll(where: { $0.id == match.id })
        next.history.insert(entry, at: 0)
        if next.history.count > maximumHistory {
            next.history.removeLast(next.history.count - maximumHistory)
        }

        next.evaluateAchievements(match: match, result: result)
        next.updatedAt = now
        return next
    }

    public static func replacingStoreEntitlements(
        _ entitlements: Set<PingoEntitlementID>,
        in state: PingoProgressionState,
        now: Date = Date()
    ) -> PingoProgressionState {
        var next = state
        next.entitlements = entitlements
        next.ownedCosmetics = PingoCosmeticCatalog.unlockedIDs(for: entitlements)
        for slot in PingoCosmeticSlot.allCases {
            if let equipped = next.equippedCosmetics[slot], next.ownedCosmetics.contains(equipped) { continue }
            if let fallback = PingoCosmeticCatalog.all.first(where: { $0.slot == slot && $0.entitlement == nil }) {
                next.equippedCosmetics[slot] = fallback.id
            } else {
                next.equippedCosmetics.removeValue(forKey: slot)
            }
        }
        if next.ownedCosmetics.count >= 10 { next.achievements.insert(.collector) }
        next.updatedAt = now
        return next
    }

    public static func equip(
        cosmeticID: String,
        in state: PingoProgressionState,
        now: Date = Date()
    ) throws -> PingoProgressionState {
        guard state.ownedCosmetics.contains(cosmeticID) else { throw PingoProgressionError.cosmeticNotOwned }
        guard let descriptor = PingoCosmeticCatalog.descriptor(id: cosmeticID) else { throw PingoProgressionError.cosmeticNotOwned }
        var next = state
        next.equippedCosmetics[descriptor.slot] = cosmeticID
        next.updatedAt = now
        return next
    }

    public static func merging(local: PingoProgressionState, remote: PingoProgressionSnapshot) -> PingoProgressionState {
        var next = local

        // Reconcile only results that have an actual per-match record. Never union a remote
        // processed ID without its result, because doing so would make missing aggregate stats
        // permanently unrecoverable on the next sync.
        let remoteOnlyEntries = remote.history
            .filter { !next.processedMatchIDs.contains($0.id) }
            .sorted { $0.playedAt < $1.playedAt }

        for entry in remoteOnlyEntries {
            applySyncedHistoryEntry(entry, to: &next)
        }

        next.achievements.formUnion(remote.achievements)

        var historyByID = Dictionary(uniqueKeysWithValues: next.history.map { ($0.id, $0) })
        for entry in remote.history { historyByID[entry.id] = entry }
        next.history = historyByID.values.sorted(by: { $0.playedAt > $1.playedAt })
        if next.history.count > maximumHistory { next.history = Array(next.history.prefix(maximumHistory)) }

        next.currentStreak = currentWinStreak(in: next.history)
        next.bestStreak = max(max(next.bestStreak, remote.bestStreak), longestWinStreak(in: next.history))
        reconcileOpponentStreaks(in: &next)
        next.updatedAt = max(local.updatedAt, remote.updatedAt)
        return next
    }

    private static func applySyncedHistoryEntry(
        _ entry: PingoMatchHistoryEntry,
        to state: inout PingoProgressionState
    ) {
        guard !state.processedMatchIDs.contains(entry.id) else { return }

        state.processedMatchIDs.insert(entry.id)
        state.xp += xpAward(for: entry.result)
        switch entry.result {
        case .win:
            state.wins += 1
        case .loss:
            state.losses += 1
        case .draw:
            state.draws += 1
        }

        state.gameCounts[entry.gameID.rawValue, default: 0] += 1
        state.updateOpponentRecord(
            opponent: .init(id: entry.opponentID, displayName: entry.opponentName),
            result: entry.result,
            playedAt: entry.playedAt
        )
        state.history.removeAll(where: { $0.id == entry.id })
        state.history.append(entry)
    }

    private static func currentWinStreak(in history: [PingoMatchHistoryEntry]) -> Int {
        history
            .sorted(by: { $0.playedAt > $1.playedAt })
            .prefix(while: { $0.result == .win })
            .count
    }

    private static func longestWinStreak(in history: [PingoMatchHistoryEntry]) -> Int {
        var longest = 0
        var current = 0
        for entry in history.sorted(by: { $0.playedAt < $1.playedAt }) {
            if entry.result == .win {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    private static func reconcileOpponentStreaks(in state: inout PingoProgressionState) {
        for index in state.opponentRecords.indices {
            let opponentID = state.opponentRecords[index].opponentID
            let history = state.history
                .filter { $0.opponentID == opponentID }
                .sorted(by: { $0.playedAt > $1.playedAt })
            guard !history.isEmpty else { continue }

            state.opponentRecords[index].currentStreak = history.prefix(while: { $0.result == .win }).count
            state.opponentRecords[index].bestStreak = max(
                state.opponentRecords[index].bestStreak,
                longestWinStreak(in: history)
            )
            state.opponentRecords[index].lastPlayedAt = max(
                state.opponentRecords[index].lastPlayedAt ?? .distantPast,
                history[0].playedAt
            )
        }
        state.opponentRecords.sort {
            ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast)
        }
    }
}
