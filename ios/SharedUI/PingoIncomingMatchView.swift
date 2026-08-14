import PingoCore
import SwiftUI

struct PingoIncomingMatchView: View {
    let payload: PingoMessagePayload
    let localProfile: PingoPublicProfile
    let entitlements: Set<PingoEntitlementID>
    let onAccept: () -> Void
    let onMoves: ([PingoGameMove]) -> Void
    let onPhysicsMove: (PingoPhysicsMove) -> Void
    let onContinueSeries: () -> Void
    let onResign: () -> Void
    let onOpenStore: () -> Void
    let onClose: () -> Void

    private var game: PingoGameDescriptor? {
        PingoGameCatalog.launch.first(where: { $0.id == payload.match.gameID })
    }

    private var localIsPlayer: Bool {
        payload.match.players.contains(where: { $0.id == localProfile.id })
    }

    private var hasPlayableGame: Bool {
        PingoPlayableGameRegistry.supportedGames.contains(payload.match.gameID)
    }

    private var localCanPlay: Bool {
        PingoAccessPolicy.canPlay(payload.match.gameID, entitlements: entitlements)
    }

    private var isPhysicsGame: Bool {
        PingoPhysicsGameEngine.supportedGames.contains(payload.match.gameID)
    }

    private var localIsSeriesHost: Bool {
        payload.match.createdByPlayerID == localProfile.id
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    Text(game?.symbol ?? "🎮")
                        .font(.system(size: 48))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game?.name ?? "Pingo Match")
                            .font(.title2.bold())
                        Text(matchSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !localCanPlay {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                statusCard
                if payload.match.series != nil { seriesCard }
                if hasPlayableGame,
                   localCanPlay,
                   localIsPlayer,
                   payload.match.status == .active || payload.match.status == .completed {
                    if isPhysicsGame {
                        PingoPhysicsGameView(match: payload.match, localProfile: localProfile, onMove: onPhysicsMove)
                    } else {
                        PingoBoardGameView(match: payload.match, localProfile: localProfile, onMoves: onMoves)
                    }
                }
                playerList
                actions
                Button("Back to games", action: onClose)
                    .buttonStyle(.bordered)
            }
            .padding(18)
        }
        .background(Color.pingoSurface.ignoresSafeArea())
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 6) {
            if !localCanPlay {
                Text("Premium Game").font(.headline)
                Text("Unlock the Premium Game Pack to accept or continue this match.")
                    .foregroundStyle(.secondary)
            } else {
                switch payload.match.status {
                case .awaitingOpponent:
                    if payload.sender.id == localProfile.id {
                        Text("Challenge ready").font(.headline)
                        Text("Waiting for someone in this chat to accept.").foregroundStyle(.secondary)
                    } else {
                        Text("@\(payload.sender.username) challenged you").font(.headline)
                        Text("Accept to join this Pingo match.").foregroundStyle(.secondary)
                    }
                case .active:
                    Text(payload.match.currentPlayerID == localProfile.id ? "Your turn" : "Opponent's turn")
                        .font(.headline)
                    Text(turnText).foregroundStyle(.secondary)
                case .resigned:
                    Text("Match ended").font(.headline)
                    Text(resultText).foregroundStyle(.secondary)
                case .completed:
                    Text("Match complete").font(.headline)
                    Text(resultText).foregroundStyle(.secondary)
                case .expired:
                    Text("Challenge expired").font(.headline)
                    Text("Start a new challenge from the game list.").foregroundStyle(.secondary)
                case .draft:
                    Text("Preparing match").font(.headline)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var seriesCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(payload.match.series?.format.title ?? "Series")
                    .font(.headline)
                Spacer()
                Text(seriesGameLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(payload.match.players.first?.displayName ?? "Player 1")
                        .font(.caption)
                        .lineLimit(1)
                    Text("\(seriesScore(at: 0))")
                        .font(.title2.bold())
                }
                Text("–").font(.headline).foregroundStyle(.secondary)
                VStack(spacing: 2) {
                    Text(payload.match.players.count > 1 ? payload.match.players[1].displayName : "Player 2")
                        .font(.caption)
                        .lineLimit(1)
                    Text("\(seriesScore(at: 1))")
                        .font(.title2.bold())
                }
            }
            if let series = payload.match.series, series.completed, let winnerIndex = series.winnerPlayerIndex,
               payload.match.players.indices.contains(winnerIndex) {
                Text("@\(payload.match.players[winnerIndex].displayName) won the series")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.pingoPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var playerList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Players").font(.headline)
            ForEach(Array(payload.match.players.enumerated()), id: \.element.id) { index, player in
                HStack {
                    Image(systemName: player.id == localProfile.id ? "person.crop.circle.fill" : "person.crop.circle")
                    VStack(alignment: .leading, spacing: 1) {
                        Text("@\(player.displayName)")
                        if payload.match.gameID == .chess {
                            Text(index == 0 ? "White" : "Black").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if player.id == payload.match.currentPlayerID {
                        Text("Turn")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.pingoPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var actions: some View {
        if !localCanPlay {
            Button("Unlock Premium Game Pack", action: onOpenStore)
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        } else if payload.match.status == .awaitingOpponent,
                  payload.sender.id != localProfile.id,
                  !localIsPlayer {
            Button("Accept Challenge", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        } else if payload.match.status == .active, localIsPlayer {
            Button("Resign Match", role: .destructive, action: onResign)
                .buttonStyle(.bordered)
        } else if (payload.match.status == .completed || payload.match.status == .resigned),
                  let series = payload.match.series,
                  !series.completed,
                  localIsPlayer {
            if localIsSeriesHost {
                Button("Continue \(series.format.title)", action: onContinueSeries)
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
            } else {
                Text("Waiting for the series host to send the next game.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }


    private func seriesScore(at index: Int) -> Int {
        guard let wins = payload.match.series?.wins, wins.indices.contains(index) else { return 0 }
        return wins[index]
    }

    private var matchSubtitle: String {
        if payload.match.series != nil { return "\(seriesGameLabel) • \(payload.match.series?.format.title ?? "Series")" }
        switch payload.match.status {
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

    private var turnText: String {
        guard hasPlayableGame else { return "This game's engine is not enabled in this build." }
        if payload.match.currentPlayerID == localProfile.id {
            if payload.match.gameID == .seaBattle,
               let state = try? PingoBoardGameEngine.seaBattleState(from: payload.match.gameState),
               let index = payload.match.players.firstIndex(where: { $0.id == localProfile.id }) {
                let ready = state.fleetReady.indices.contains(index) && state.fleetReady[index]
                if !ready { return "Place your fleet, then lock it in and send the setup." }
                if let pending = state.pendingShot, pending.shooter != index {
                    return "Resolve their shot and choose your return shot; Pingo sends both in one updated card."
                }
            }
            if isPhysicsGame { return "Set your aim and power, simulate the shot, then send the updated Pingo card." }
            return "Make your move, then send the updated Pingo card."
        }
        return "Open the newest Pingo card when your opponent sends their move."
    }

    private var resultText: String {
        guard let winner = payload.match.winnerPlayerID else { return "The match ended in a draw." }
        return winner == localProfile.id ? "You won this match." : "The other player won this match."
    }
}
