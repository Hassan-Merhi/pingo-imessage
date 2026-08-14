import PingoCore
import SwiftUI

struct PingoHomeView: View {
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
            GameComingSoonView(game: game)
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
        Text("Wave 1 foundation • 10 launch games")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
}

private struct GameTile: View {
    let game: PingoGameDescriptor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(game.symbol)
                .font(.system(size: 32))
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
                .strokeBorder(Color.pingoPrimary.opacity(0.12))
        }
        .contentShape(Rectangle())
    }
}

private struct GameComingSoonView: View {
    let game: PingoGameDescriptor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(game.symbol)
                .font(.system(size: 64))
            Text(game.name)
                .font(.title.bold())
            Text("The game slot is wired into Pingo. Gameplay arrives in its dedicated build wave.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}
