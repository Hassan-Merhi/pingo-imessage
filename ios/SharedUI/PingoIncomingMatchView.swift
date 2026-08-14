import PingoCore
import SwiftUI

struct PingoIncomingMatchView: View {
    let payload: PingoMessagePayload
    let localProfile: PingoPublicProfile
    let onAccept: () -> Void
    let onResign: () -> Void
    let onClose: () -> Void

    private var game: PingoGameDescriptor? {
        PingoGameCatalog.launch.first(where: { $0.id == payload.match.gameID })
    }

    private var localIsPlayer: Bool {
        payload.match.players.contains(where: { $0.id == localProfile.id })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(game?.symbol ?? "🎮")
                    .font(.system(size: 68))
                Text(game?.name ?? "Pingo Match")
                    .font(.title.bold())
                statusCard
                playerList
                actions
                Button("Back to games", action: onClose)
                    .buttonStyle(.bordered)
            }
            .padding(22)
        }
        .background(Color.pingoSurface.ignoresSafeArea())
    }

    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 6) {
            switch payload.match.status {
            case .awaitingOpponent:
                if payload.sender.id == localProfile.id {
                    Text("Challenge ready")
                        .font(.headline)
                    Text("Waiting for someone in this chat to accept.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("@\(payload.sender.username) challenged you")
                        .font(.headline)
                    Text("Accept to join this Pingo match.")
                        .foregroundStyle(.secondary)
                }
            case .active:
                Text("Match connected")
                    .font(.headline)
                Text(turnText)
                    .foregroundStyle(.secondary)
            case .resigned:
                Text("Match ended")
                    .font(.headline)
                Text(resultText)
                    .foregroundStyle(.secondary)
            case .completed:
                Text("Match complete")
                    .font(.headline)
                Text(resultText)
                    .foregroundStyle(.secondary)
            case .expired:
                Text("Challenge expired")
                    .font(.headline)
                Text("Start a new challenge from the game list.")
                    .foregroundStyle(.secondary)
            case .draft:
                Text("Preparing match")
                    .font(.headline)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var playerList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Players").font(.headline)
            ForEach(payload.match.players, id: \.id) { player in
                HStack {
                    Image(systemName: player.id == localProfile.id ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("@\(player.displayName)")
                    Spacer()
                    if player.id == payload.match.currentPlayerID {
                        Text("Turn")
                            .font(.caption)
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
            VStack(spacing: 10) {
                Text("Gameplay for this title plugs into the connected match in its game build wave.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Resign Match", role: .destructive, action: onResign)
                    .buttonStyle(.bordered)
            }
        }
    }

    private var turnText: String {
        if payload.match.currentPlayerID == localProfile.id {
            return "Your turn is ready."
        }
        return "Waiting for the other player."
    }

    private var resultText: String {
        guard let winner = payload.match.winnerPlayerID else { return "The match ended in a draw." }
        return winner == localProfile.id ? "You won this match." : "The other player won this match."
    }
}
