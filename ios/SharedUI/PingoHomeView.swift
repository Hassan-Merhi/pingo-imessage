import PingoCore
import SwiftUI

struct PingoHomeView: View {
    let onChallenge: (PingoGameID) -> Void
    @State private var selectedGame: PingoGameDescriptor?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(PingoGameCatalog.launch) { game in
                        Button {
                            selectedGame = game
                        } label: {
                            GameTile(game: game)
                        }
                        .buttonStyle(.plain)
                    }
                }
                footer
            }
            .padding(16)
        }
        .background(Color.pingoSurface.ignoresSafeArea())
        .sheet(item: $selectedGame) { game in
            ChallengeGameView(game: game) {
                onChallenge(game.id)
                selectedGame = nil
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 12) {
            PingoMark(size: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text("Pick a game")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.pingoInk)
                Text("Challenge someone in this chat.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        Text("10 playable launch games • board, strategy & physics • iMessage challenges")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
}

private struct GameTile: View {
    let game: PingoGameDescriptor

    private var isPlayable: Bool {
        PingoPlayableGameRegistry.supportedGames.contains(game.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Text(game.symbol)
                    .font(.system(size: 32))
                Spacer()
                Text(isPlayable ? "READY" : "SOON")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isPlayable ? Color.pingoPrimary : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }
            Text(game.name)
                .font(.headline)
                .foregroundStyle(Color.pingoInk)
            Text(game.family.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.pingoPrimary.opacity(isPlayable ? 0.2 : 0.08))
        }
        .contentShape(Rectangle())
    }
}

private struct ChallengeGameView: View {
    let game: PingoGameDescriptor
    let onChallenge: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var isPlayable: Bool {
        PingoPlayableGameRegistry.supportedGames.contains(game.id)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(game.symbol)
                .font(.system(size: 64))
            Text(game.name)
                .font(.title.bold())
            Text(isPlayable
                 ? "Send a Pingo challenge in this iMessage conversation. Your friend taps the card to accept, play, and send turns back."
                 : "This game is already in Pingo's catalog, but its gameplay engine is not enabled in this build.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            if isPlayable {
                Button("Send Challenge") {
                    onChallenge()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
            }
            Button(isPlayable ? "Cancel" : "Close") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
