import PingoCore
import SwiftUI

struct PingoHomeView: View {
    let progression: PingoProgressionState
    let onChallenge: (PingoGameID, PingoSeriesFormat) -> Void
    let onOpenStore: () -> Void
    @State private var selectedGame: PingoGameDescriptor?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.pingoMessagesChrome.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    Text("GAMES")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.52))

                    gameGrid(PingoGameCatalog.launch)

                    footer
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .sheet(item: $selectedGame) { game in
            ChallengeGameView(game: game) { format in
                onChallenge(game.id, format)
                selectedGame = nil
            }
            .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
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

    private var header: some View {
        HStack(spacing: 12) {
            PingoMark(size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pingo")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Level \(progression.level)  •  \(progression.xp) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.54))
            }
            Spacer()
        }
        .padding(.trailing, 92)
    }

    private var footer: some View {
        Text("Pick a game, choose a match format, then send the challenge into this conversation.")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.46))
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

private struct GameTile: View {
    let game: PingoGameDescriptor
    let unlocked: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.pingoPrimary.opacity(0.95), Color.pingoSecondary.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(game.symbol)
                .font(.system(size: 40))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -9)

            VStack(alignment: .leading, spacing: 3) {
                Text(game.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                    }
                    Text(unlocked ? "PLAY" : "PACK")
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
            }
            .padding(10)
        }
        .aspectRatio(0.92, contentMode: .fit)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .opacity(unlocked ? 1 : 0.56)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct ChallengeGameView: View {
    let game: PingoGameDescriptor
    let onChallenge: (PingoSeriesFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var seriesFormat: PingoSeriesFormat = .single

    var body: some View {
        ZStack {
            Color.pingoMessagesChrome.ignoresSafeArea()

            VStack(spacing: 18) {
                Capsule()
                    .fill(.white.opacity(0.24))
                    .frame(width: 42, height: 5)
                    .padding(.top, 8)

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(game.name)
                        .font(.headline)

                    Spacer()

                    Button {
                        onChallenge(seriesFormat)
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 36)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Send challenge")
                }

                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.pingoPrimary, Color.pingoSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(game.symbol)
                            .font(.system(size: 56))
                    }
                    .frame(width: 154, height: 154)
                    .overlay(alignment: .bottomLeading) {
                        Text("CUSTOMIZE")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(10)
                    }

                    VStack(spacing: 12) {
                        settingCard(title: "GAME", value: game.name)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("MATCH FORMAT")
                                .font(.caption2.bold())
                                .foregroundStyle(.white.opacity(0.7))

                            Picker("Match Format", selection: $seriesFormat) {
                                ForEach(PingoSeriesFormat.allCases, id: \.self) { format in
                                    Text(format.title).tag(format)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Text("The challenge will be inserted into the iMessage composer so you can send it like a normal game card.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.46))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 18)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func settingCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
