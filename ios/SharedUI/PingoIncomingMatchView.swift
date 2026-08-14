import PingoCore
import SwiftUI

struct PingoIncomingMatchView: View {
    let payload: PingoMessagePayload
    let localProfile: PingoPublicProfile
    let onAccept: () -> Void
    let onMoves: ([PingoGameMove]) -> Void
    let onResign: () -> Void
    let onClose: () -> Void

    private var game: PingoGameDescriptor? {
        PingoGameCatalog.launch.first(where: { $0.id == payload.match.gameID })
    }

    private var localIsPlayer: Bool {
        payload.match.players.contains(where: { $0.id == localProfile.id })
    }

    private var hasPlayableWave3Game: Bool {
        PingoBoardGameEngine.supportedGames.contains(payload.match.gameID)
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
                }
                statusCard
                if hasPlayableWave3Game,
                   localIsPlayer,
                   payload.match.status == .active || payload.match.status == .completed {
                    PingoBoardGameView(match: payload.match, localProfile: localProfile, onMoves: onMoves)
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
        .multilineTextAlignment(.center)
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
        if payload.match.status == .awaitingOpponent,
           payload.sender.id != localProfile.id,
           !localIsPlayer {
            Button("Accept Challenge", action: onAccept)
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        } else if payload.match.status == .active, localIsPlayer {
            Button("Resign Match", role: .destructive, action: onResign)
                .buttonStyle(.bordered)
        }
    }

    private var matchSubtitle: String {
        switch payload.match.status {
        case .active: "Move \(payload.match.turnNumber + 1)"
        case .completed, .resigned: "Final result"
        case .awaitingOpponent: "Challenge"
        default: "Pingo match"
        }
    }

    private var turnText: String {
        guard hasPlayableWave3Game else { return "This game's engine arrives in a later wave." }
        if payload.match.currentPlayerID == localProfile.id {
            if payload.match.gameID == .seaBattle,
               let state = try? PingoBoardGameEngine.seaBattleState(from: payload.match.gameState),
               let index = payload.match.players.firstIndex(where: { $0.id == localProfile.id }) {
                let ready = state.fleetReady.indices.contains(index) && state.fleetReady[index]
                if !ready {
                    return "Place your fleet, then lock it in and send the setup."
                }
                if let pending = state.pendingShot, pending.shooter != index {
                    return "Resolve their shot and choose your return shot; Pingo sends both in one updated card."
                }
            }
            return "Make your move, then send the updated Pingo card."
        }
        return "Open the newest Pingo card when your opponent sends their move."
    }

    private var resultText: String {
        guard let winner = payload.match.winnerPlayerID else { return "The match ended in a draw." }
        return winner == localProfile.id ? "You won this match." : "The other player won this match."
    }
}
