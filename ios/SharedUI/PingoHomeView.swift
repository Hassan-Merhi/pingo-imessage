import PingoCore
import SwiftUI

struct PingoHomeView: View {
    let progression: PingoProgressionState
    let onChallenge: (PingoGameID, PingoSeriesFormat) -> Void
    let onOpenStore: () -> Void
    @State private var selectedGame: PingoGameDescriptor?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero
                quickPlay
                Text("Original Collection")
                    .font(.headline)
                gameGrid(Array(PingoGameCatalog.launch.prefix(10)))
                Text("Wave 6 Expansions")
                    .font(.headline)
                    .padding(.top, 2)
                gameGrid(PingoGameCatalog.wave6)
                footer
            }
            .padding(16)
        }
        .background(Color.pingoSurface.ignoresSafeArea())
        .sheet(item: $selectedGame) { game in
            ChallengeGameView(game: game) { format in
                onChallenge(game.id, format)
                selectedGame = nil
            }
        }
    }

    @ViewBuilder
    private func gameGrid(_ games: [PingoGameDescriptor]) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(games) { game in
                let unlocked = PingoAccessPolicy.canPlay(game.id, entitlements: progression.entitlements)
                Button {
                    if unlocked {
                        selectedGame = game
                    } else {
                        onOpenStore()
                    }
                } label: {
                    GameTile(game: game, unlocked: unlocked)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 12) {
            PingoMark(size: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pick a game")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.pingoInk)
                Text("Level \(progression.level) • \(progression.xp) XP")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.pingoPrimary)
                ProgressView(value: Double(progression.xpIntoLevel), total: Double(PingoProgression.xpPerLevel))
                    .tint(.pingoPrimary)
                Text("Challenge someone in this chat.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickPlay: some View {
        HStack(spacing: 10) {
            Button {
                let seed = UInt64.random(in: UInt64.min...UInt64.max)
                guard let gameID = PingoRandomGame.pick(entitlements: progression.entitlements, seed: seed),
                      let game = PingoGameCatalog.game(id: gameID) else { return }
                selectedGame = game
            } label: {
                Label("Random Game", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pingoPrimary)

            Button(action: onOpenStore) {
                Label("Store", systemImage: "bag")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var footer: some View {
        Text("22 games • 5 free • 4 one-time game packs • Single, Best of 3 & Best of 5")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

private struct GameTile: View {
    let game: PingoGameDescriptor
    let unlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Text(game.symbol)
                    .font(.system(size: 32))
                Spacer()
                Text(unlocked ? (game.isFreeAtLaunch ? "FREE" : "OWNED") : "PACK")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(unlocked ? Color.pingoPrimary : .secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }
            Text(game.name)
                .font(.headline)
                .foregroundStyle(Color.pingoInk)
            HStack(spacing: 4) {
                Text(game.family.rawValue.capitalized)
                if !unlocked { Image(systemName: "lock.fill") }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.pingoPrimary.opacity(unlocked ? 0.2 : 0.08))
        }
        .opacity(unlocked ? 1 : 0.78)
        .contentShape(Rectangle())
    }
}

private struct ChallengeGameView: View {
    let game: PingoGameDescriptor
    let onChallenge: (PingoSeriesFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var seriesFormat: PingoSeriesFormat = .single

    var body: some View {
        VStack(spacing: 16) {
            Text(game.symbol)
                .font(.system(size: 64))
            Text(game.name)
                .font(.title.bold())
            Text(PingoAccessPolicy.packTitle(for: game.id) ?? "Free game")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.pingoPrimary)
            Text("Send a Pingo challenge in this iMessage conversation. Your friend taps the card to accept, play, and send turns back.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Picker("Series", selection: $seriesFormat) {
                ForEach(PingoSeriesFormat.allCases, id: \.self) { format in
                    Text(format.title).tag(format)
                }
            }
            .pickerStyle(.segmented)

            Button(seriesFormat == .single ? "Send Challenge" : "Start \(seriesFormat.title)") {
                onChallenge(seriesFormat)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pingoPrimary)

            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
