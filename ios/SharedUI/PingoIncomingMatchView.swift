import PingoCore
import SwiftUI

struct PingoIncomingMatchView: View {
    let payload: PingoMessagePayload
    let localProfile: PingoPublicProfile
    let onAccept: () -> Void
    let onOpenGame: () -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                matchCard
                seriesCard
                actions
            }
            .padding(20)
        }
        .background(Color.pingoBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(PingoGameCatalog.game(id: payload.match.gameID)?.symbol ?? "🎮")
                .font(.system(size: 52))
            Text(PingoGameCatalog.game(id: payload.match.gameID)?.name ?? "Pingo")
                .font(.title2.bold())
            Text(matchSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private var matchCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                playerColumn(player: primaryPlayer, scoreIndex: 0)
                Text("VS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                playerColumn(player: secondaryPlayer, scoreIndex: 1)
            }

            statusDetail
        }
        .padding(18)
        .background(Color.pingoCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var statusDetail: some View {
        switch payload.match.status {
        case .awaitingOpponent:
            if payload.match.createdByPlayerID == localProfile.id {
                Label("Waiting for opponent", systemImage: "clock")
                    .foregroundStyle(.secondary)
            } else {
                Label("@\(payload.sender.username) challenged you", systemImage: "bolt.fill")
                    .foregroundStyle(Color.pingoPrimary)
            }
        case .active:
            if payload.match.currentPlayerID == localProfile.id {
                Label("Your turn", systemImage: "hand.tap.fill")
                    .foregroundStyle(Color.pingoPrimary)
            } else {
                Label("Waiting for opponent's move", systemImage: "clock")
                    .foregroundStyle(.secondary)
            }
        case .completed, .resigned:
            resultLabel
        case .expired:
            Label("This match expired", systemImage: "clock.badge.xmark")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultLabel: some View {
        if let winnerID = payload.match.winnerPlayerID {
            if winnerID == localProfile.id {
                Label("You won!", systemImage: "trophy.fill")
                    .foregroundStyle(Color.pingoPrimary)
            } else {
                Label("@\(winnerName(for: winnerID)) won", systemImage: "flag.checkered")
                    .foregroundStyle(.secondary)
            }
        } else {
            Label("Draw", systemImage: "equal.circle")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var seriesCard: some View {
        if let series = payload.match.series {
            VStack(spacing: 10) {
                HStack {
                    Label(series.format.title, systemImage: "list.number")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(series.scoreText)
                        .font(.title3.monospacedDigit().bold())
                }

                if series.completed, let winnerIndex = series.winnerPlayerIndex {
                    let winner = seriesPlayer(at: winnerIndex)
                    Label("Series winner: @\(winner?.displayName ?? "player")", systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.pingoPrimary)
                } else {
                    Text("\(seriesGameLabel) of up to \(series.format.maximumGames)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color.pingoPrimary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 10) {
            switch payload.match.status {
            case .awaitingOpponent:
                if payload.match.createdByPlayerID != localProfile.id {
                    Button("Accept Challenge", action: onAccept)
                        .buttonStyle(PingoPrimaryButtonStyle())
                }
            case .active:
                Button(payload.match.currentPlayerID == localProfile.id ? "Play Your Turn" : "Open Match", action: onOpenGame)
                    .buttonStyle(PingoPrimaryButtonStyle())
                Button("Resign", role: .destructive, action: onResign)
                    .font(.subheadline.weight(.semibold))
            case .completed, .resigned:
                completedActions
            case .expired:
                Button("Start a New Game", action: onRematch)
                    .buttonStyle(PingoPrimaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var completedActions: some View {
        if let series = payload.match.series, !series.completed {
            if payload.match.createdByPlayerID == localProfile.id {
                Button("Send \(nextSeriesGameLabel)", action: onContinueSeries)
                    .buttonStyle(PingoPrimaryButtonStyle())
            } else {
                Text("Waiting for the series host to send the next game.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else {
            Button("Rematch", action: onRematch)
                .buttonStyle(PingoPrimaryButtonStyle())
        }
    }

    private var primaryPlayer: PingoPlayerRef? {
        seriesPlayer(at: 0) ?? payload.match.players.first
    }

    private var secondaryPlayer: PingoPlayerRef? {
        seriesPlayer(at: 1) ?? payload.match.players.dropFirst().first
    }

    private func seriesPlayer(at index: Int) -> PingoPlayerRef? {
        guard payload.match.players.count == 2 else { return payload.match.players.indices.contains(index) ? payload.match.players[index] : nil }
        if index == 0 {
            return payload.match.players.first(where: { $0.id == payload.match.createdByPlayerID })
        }
        return payload.match.players.first(where: { $0.id != payload.match.createdByPlayerID })
    }

    private func playerColumn(player: PingoPlayerRef?, scoreIndex: Int) -> some View {
        VStack(spacing: 4) {
            Text(player?.id == localProfile.id ? "You" : "@\(player?.displayName ?? "player")")
                .font(.subheadline.bold())
                .lineLimit(1)
            if payload.match.series != nil {
                Text("\(seriesScore(at: scoreIndex))")
                    .font(.title.bold().monospacedDigit())
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func winnerName(for id: UUID) -> String {
        payload.match.players.first(where: { $0.id == id })?.displayName ?? payload.sender.username
    }

    private var nextSeriesGameLabel: String {
        guard let series = payload.match.series else { return "Next Game" }
        return "Game \(series.gameNumber)"
    }

    private func seriesScore(at index: Int) -> Int {
        guard let wins = payload.match.series?.wins, wins.indices.contains(index) else { return 0 }
        return wins[index]
    }

    private var matchSubtitle: String {
        if payload.match.series != nil { return "\(seriesGameLabel) • \(payload.match.series?.format.title ?? "Series")" }
        return switch payload.match.status {
        case .active: "Move \(payload.match.turnNumber + 1)"
        case .completed, .resigned: "Final result"
        case .awaitingOpponent: "Challenge"
        default: "Pingo match"
        }
    }

    private var seriesGameLabel: String {
        guard let series = payload.match.series else { return "Single Game" }
        let game: Int
        if payload.match.status == .completed || payload.match.status == .resigned {
            game = series.completed ? series.gameNumber : max(1, series.gameNumber - 1)
        } else {
            game = series.gameNumber
        }
        return "Game \(game)"
    }
}
