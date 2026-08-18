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

                    HStack {
                        Text("GAMES")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.52))
                        Spacer()
                        Text("\(PingoGameCatalog.launch.count)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.white.opacity(0.32))
                    }

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
        Text("Choose a game, set the match format, then send it directly into this conversation.")
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

    private var palette: PingoGamePalette { .palette(for: game.id) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: palette.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            tileTexture

            Text(game.symbol)
                .font(.system(size: 42))
                .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -9)

            LinearGradient(
                colors: [.clear, .black.opacity(0.46)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(game.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                HStack(spacing: 4) {
                    if !unlocked {
                        Image(systemName: "lock.fill")
                    }
                    Text(unlocked ? "PLAY" : "PACK")
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            }
            .padding(10)
        }
        .aspectRatio(0.92, contentMode: .fit)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: palette.colors.last?.opacity(0.20) ?? .clear, radius: 7, y: 3)
        .saturation(unlocked ? 1 : 0.35)
        .opacity(unlocked ? 1 : 0.58)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var tileTexture: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: 2)
                    .frame(width: proxy.size.width * 0.78)
                    .offset(x: proxy.size.width * 0.34, y: -proxy.size.height * 0.30)

                Circle()
                    .fill(.white.opacity(0.06))
                    .frame(width: proxy.size.width * 0.52)
                    .offset(x: -proxy.size.width * 0.34, y: proxy.size.height * 0.32)

                Capsule()
                    .fill(.white.opacity(0.08))
                    .frame(width: proxy.size.width * 0.64, height: 8)
                    .rotationEffect(.degrees(-28))
                    .offset(x: proxy.size.width * 0.26, y: proxy.size.height * 0.10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ChallengeGameView: View {
    let game: PingoGameDescriptor
    let onChallenge: (PingoSeriesFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var seriesFormat: PingoSeriesFormat = .single

    private var palette: PingoGamePalette { .palette(for: game.id) }

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
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 1) {
                        Text(game.name)
                            .font(.headline)
                        Text("NEW CHALLENGE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.42))
                    }

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
                    gameArtwork

                    VStack(spacing: 12) {
                        settingCard(title: "GAME MODE", value: game.name)

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

                Text("Tap the blue arrow to add the challenge card to your iMessage composer.")
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

    private var gameArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: palette.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 3)
                .frame(width: 128, height: 128)
                .offset(x: 48, y: -48)

            Text(game.symbol)
                .font(.system(size: 62))
                .shadow(color: .black.opacity(0.20), radius: 5, y: 3)
        }
        .frame(width: 154, height: 154)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Text("CUSTOMIZE")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(10)
        }
    }

    private func settingCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PingoGamePalette {
    let colors: [Color]

    static func palette(for gameID: PingoGameID) -> PingoGamePalette {
        switch gameID {
        case .eightBall:
            return .init(colors: [Color(red: 0.04, green: 0.55, blue: 0.48), Color(red: 0.01, green: 0.26, blue: 0.31)])
        case .cupPong:
            return .init(colors: [Color(red: 0.13, green: 0.62, blue: 0.90), Color(red: 0.08, green: 0.25, blue: 0.58)])
        case .basketball:
            return .init(colors: [Color(red: 0.98, green: 0.58, blue: 0.18), Color(red: 0.82, green: 0.22, blue: 0.10)])
        case .darts:
            return .init(colors: [Color(red: 0.15, green: 0.52, blue: 0.30), Color(red: 0.08, green: 0.20, blue: 0.14)])
        case .miniGolf:
            return .init(colors: [Color(red: 0.34, green: 0.74, blue: 0.31), Color(red: 0.10, green: 0.42, blue: 0.22)])
        case .seaBattle:
            return .init(colors: [Color(red: 0.12, green: 0.46, blue: 0.76), Color(red: 0.04, green: 0.16, blue: 0.36)])
        case .chess:
            return .init(colors: [Color(red: 0.45, green: 0.42, blue: 0.50), Color(red: 0.16, green: 0.15, blue: 0.19)])
        case .checkers:
            return .init(colors: [Color(red: 0.88, green: 0.24, blue: 0.25), Color(red: 0.42, green: 0.08, blue: 0.12)])
        case .connectFour:
            return .init(colors: [Color(red: 0.16, green: 0.48, blue: 0.93), Color(red: 0.12, green: 0.21, blue: 0.65)])
        case .ticTacToe:
            return .init(colors: [Color(red: 0.62, green: 0.45, blue: 0.96), Color(red: 0.31, green: 0.19, blue: 0.66)])
        case .bowling:
            return .init(colors: [Color(red: 0.87, green: 0.30, blue: 0.46), Color(red: 0.39, green: 0.12, blue: 0.31)])
        case .penaltyShootout:
            return .init(colors: [Color(red: 0.22, green: 0.67, blue: 0.30), Color(red: 0.06, green: 0.32, blue: 0.18)])
        case .archery:
            return .init(colors: [Color(red: 0.95, green: 0.42, blue: 0.16), Color(red: 0.62, green: 0.10, blue: 0.14)])
        case .airHockey:
            return .init(colors: [Color(red: 0.08, green: 0.78, blue: 0.91), Color(red: 0.25, green: 0.24, blue: 0.75)])
        case .drawAndGuess:
            return .init(colors: [Color(red: 0.96, green: 0.37, blue: 0.66), Color(red: 0.48, green: 0.20, blue: 0.72)])
        case .wordHunt:
            return .init(colors: [Color(red: 0.25, green: 0.65, blue: 0.95), Color(red: 0.12, green: 0.32, blue: 0.72)])
        case .anagrams:
            return .init(colors: [Color(red: 0.52, green: 0.49, blue: 0.96), Color(red: 0.24, green: 0.20, blue: 0.66)])
        case .trivia:
            return .init(colors: [Color(red: 0.95, green: 0.49, blue: 0.24), Color(red: 0.62, green: 0.18, blue: 0.54)])
        case .crazyEights:
            return .init(colors: [Color(red: 0.19, green: 0.62, blue: 0.38), Color(red: 0.08, green: 0.31, blue: 0.22)])
        case .ludo:
            return .init(colors: [Color(red: 0.95, green: 0.42, blue: 0.26), Color(red: 0.83, green: 0.18, blue: 0.35)])
        case .miniRacing:
            return .init(colors: [Color(red: 0.96, green: 0.68, blue: 0.10), Color(red: 0.84, green: 0.23, blue: 0.08)])
        case .reactionBattle:
            return .init(colors: [Color(red: 0.98, green: 0.78, blue: 0.12), Color(red: 0.68, green: 0.26, blue: 0.55)])
        }
    }
}
