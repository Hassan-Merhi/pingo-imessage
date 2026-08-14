import Foundation

extension PingoProgressionState {
    mutating func updateOpponentRecord(opponent: PingoPlayerRef, result: PingoMatchResult, playedAt: Date) {
        var record = opponentRecords.first(where: { $0.opponentID == opponent.id }) ?? PingoOpponentRecord(opponentID: opponent.id)
        switch result {
        case .win:
            record.wins += 1
            record.currentStreak += 1
            record.bestStreak = max(record.bestStreak, record.currentStreak)
        case .loss:
            record.losses += 1
            record.currentStreak = 0
        case .draw:
            record.draws += 1
            record.currentStreak = 0
        }
        record.lastPlayedAt = playedAt
        opponentRecords.removeAll(where: { $0.opponentID == opponent.id })
        opponentRecords.append(record)
        opponentRecords.sort { lhs, rhs in
            (lhs.lastPlayedAt ?? .distantPast) > (rhs.lastPlayedAt ?? .distantPast)
        }
    }

    mutating func evaluateAchievements(match: PingoMatchEnvelope, result: PingoMatchResult) {
        if wins >= 1 { achievements.insert(.firstWin) }
        if currentStreak >= 3 { achievements.insert(.hatTrick) }
        if currentStreak >= 5 { achievements.insert(.hotFive) }
        if gamesPlayed >= 10 { achievements.insert(.tenGames) }
        if gameCounts.values.filter({ $0 > 0 }).count >= 5 { achievements.insert(.fiveGameExplorer) }
        if result == .win, match.series?.completed == true { achievements.insert(.seriesWinner) }
        if ownedCosmetics.count >= 10 { achievements.insert(.collector) }
    }
}
