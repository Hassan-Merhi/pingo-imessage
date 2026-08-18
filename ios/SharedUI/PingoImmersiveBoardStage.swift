import PingoCore
import SwiftUI

struct PingoImmersiveBoardStage: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMoves: ([PingoGameMove]) -> Void

    private var game: PingoGameDescriptor? {
        PingoGameCatalog.game(id: match.gameID)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                Text(game?.symbol ?? "🎮")
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 0) {
                    Text((game?.name ?? "Pingo").uppercased())
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.72))
                    Text(statusText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.42))
                }
                Spacer()
            }
            .padding(.horizontal, 6)

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: palette,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.18), radius: 9, y: 4)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.86))
                    .padding(10)

                PingoBoardGameView(match: match, localProfile: localProfile, onMoves: onMoves)
                    .padding(boardPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }

    private var statusText: String {
        switch match.status {
        case .active:
            return match.currentPlayerID == localProfile.id ? "Your move" : "Waiting for opponent"
        case .completed:
            return "Final board"
        case .resigned:
            return "Match ended"
        default:
            return "Match board"
        }
    }

    private var boardPadding: CGFloat {
        switch match.gameID {
        case .ticTacToe: return 24
        case .connectFour: return 14
        case .checkers, .chess: return 10
        case .seaBattle: return 8
        default: return 12
        }
    }

    private var palette: [Color] {
        switch match.gameID {
        case .ticTacToe:
            return [Color(red: 0.58, green: 0.45, blue: 0.92), Color(red: 0.28, green: 0.20, blue: 0.62)]
        case .connectFour:
            return [Color(red: 0.16, green: 0.51, blue: 0.94), Color(red: 0.09, green: 0.24, blue: 0.68)]
        case .checkers:
            return [Color(red: 0.83, green: 0.25, blue: 0.27), Color(red: 0.39, green: 0.09, blue: 0.12)]
        case .chess:
            return [Color(red: 0.48, green: 0.45, blue: 0.53), Color(red: 0.18, green: 0.17, blue: 0.21)]
        case .seaBattle:
            return [Color(red: 0.14, green: 0.50, blue: 0.78), Color(red: 0.05, green: 0.20, blue: 0.42)]
        default:
            return [Color.pingoPrimary, Color.pingoSecondary]
        }
    }
}
