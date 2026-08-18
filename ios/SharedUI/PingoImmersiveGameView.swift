import PingoCore
import SwiftUI

struct PingoImmersiveGameView: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMoves: ([PingoGameMove]) -> Void
    let onPhysicsMove: (PingoPhysicsMove) -> Void
    let onExtraMove: (PingoExtraGameMove) -> Void

    private var localPlayerIndex: Int? {
        match.players.firstIndex(where: { $0.id == localProfile.id })
    }

    private var localCanMove: Bool {
        match.status == .active && match.currentPlayerID == localProfile.id
    }

    private var isExtraGame: Bool {
        PingoExtraGameEngine.supportedGames.contains(match.gameID)
    }

    private var extraState: PingoExtraGameState? {
        try? PingoExtraGameEngine.state(from: match.gameState, gameID: match.gameID, matchID: match.id)
    }

    var body: some View {
        ZStack {
            Color.pingoGameBackdrop

            VStack(spacing: 8) {
                playerStrip
                    .padding(.horizontal, 14)

                gameStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, 8)
            .padding(.bottom, 10)

            if match.status == .active && !localCanMove {
                waitingOverlay
            }
        }
        .clipped()
    }

    @ViewBuilder
    private var gameStage: some View {
        if let index = localPlayerIndex {
            switch match.gameID {
            case .eightBall:
                let state = (try? PingoPhysicsGameEngine.eightBallState(from: match.gameState)) ?? PingoEightBallState()
                PingoImmersiveEightBallView(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )
                .padding(.horizontal, 8)

            case .cupPong:
                let state = (try? PingoPhysicsGameEngine.cupPongState(from: match.gameState)) ?? PingoCupPongState()
                PingoImmersiveCupPongView(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .basketball:
                let state = (try? PingoPhysicsGameEngine.basketballState(from: match.gameState)) ?? PingoBasketballState()
                PingoImmersiveBasketballView(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .darts:
                let state = (try? PingoPhysicsGameEngine.dartsState(from: match.gameState)) ?? PingoDartsState()
                PingoImmersiveDartsView(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .miniGolf:
                let state = (try? PingoPhysicsGameEngine.miniGolfState(from: match.gameState)) ?? PingoMiniGolfState()
                PingoImmersiveMiniGolfView(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .bowling, .penaltyShootout, .archery, .airHockey, .miniRacing:
                if let state = extraState {
                    PingoImmersiveArcadeView(
                        gameID: match.gameID,
                        state: state,
                        player: index,
                        canMove: localCanMove,
                        onMove: onExtraMove
                    )
                } else {
                    fallbackStage
                }

            default:
                fallbackStage
            }
        } else {
            fallbackStage
        }
    }

    @ViewBuilder
    private var fallbackStage: some View {
        if isExtraGame {
            ScrollView(showsIndicators: false) {
                PingoExtraGameView(match: match, localProfile: localProfile, onMove: onExtraMove)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .preferredColorScheme(.light)
        } else {
            PingoBoardGameView(match: match, localProfile: localProfile, onMoves: onMoves)
                .padding(.horizontal, 10)
                .padding(.vertical, 14)
                .preferredColorScheme(.light)
        }
    }

    private var playerStrip: some View {
        HStack(spacing: 10) {
            playerChip(player: opponentPlayer, label: "Opponent")
            Spacer(minLength: 6)
            playerChip(player: localPlayer, label: localCanMove ? "Your turn" : "You")
        }
    }

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    private func playerChip(player: PingoPlayerRef?, label: String) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.white.opacity(0.94))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color.pingoMessagesChrome)
                }
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(player.map { "@\($0.displayName)" } ?? "Waiting…")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .lineLimit(1)
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }
        }
    }

    private var waitingOverlay: some View {
        Text("WAITING FOR OPPONENT.")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 15)
            .background(Color.pingoGameOverlay, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .shadow(radius: 8, y: 4)
            .accessibilityLabel("Waiting for opponent")
    }
}

private struct PingoImmersiveEightBallView: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.58

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 7) {
                verticalPowerControl

                PingoPortraitPoolTable(state: state, angle: angle, showAim: canMove)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(0.48, contentMode: .fit)

                spinControl
            }
            .frame(maxHeight: .infinity)

            if canMove {
                HStack(spacing: 10) {
                    Image(systemName: "scope")
                        .foregroundStyle(.black.opacity(0.55))
                    Slider(value: $angle, in: 0...359)
                        .tint(.white)
                    Text("\(Int(angle.rounded()))°")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.black.opacity(0.64))
                        .frame(width: 42, alignment: .trailing)

                    Button {
                        onMove(.eightBall(.init(angleDegrees: angle, power: power)))
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 38)
                            .background(Color.pingoPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Shoot and send")
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var verticalPowerControl: some View {
        VStack(spacing: 6) {
            Text("POWER")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.48))

            Slider(value: $power, in: 0.05...1)
                .tint(.red.opacity(0.72))
                .rotationEffect(.degrees(-90))
                .frame(width: 170)
                .frame(width: 38, height: 180)
                .disabled(!canMove)

            Text("\(Int((power * 100).rounded()))")
                .font(.caption2.monospacedDigit().bold())
                .foregroundStyle(.black.opacity(0.52))
        }
        .frame(width: 40)
    }

    private var spinControl: some View {
        VStack(spacing: 7) {
            Circle()
                .fill(.white)
                .overlay {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                }
                .overlay {
                    Circle().stroke(.black.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                .frame(width: 42, height: 42)
            Text("SPIN")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.42))
        }
        .frame(width: 42)
    }
}

private struct PingoPortraitPoolTable: View {
    let state: PingoEightBallState
    let angle: Double
    let showAim: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.36, green: 0.18, blue: 0.16))
                    .shadow(color: .black.opacity(0.32), radius: 9, y: 5)

                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color(red: 0.00, green: 0.48, blue: 0.45))
                    .padding(17)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            .padding(17)
                    }

                ForEach(Array(pockets.enumerated()), id: \.offset) { _, pocket in
                    Circle()
                        .fill(.black)
                        .frame(width: 28, height: 28)
                        .position(
                            x: proxy.size.width * pocket.x,
                            y: proxy.size.height * pocket.y
                        )
                }

                if showAim, let cue = state.balls.first(where: { $0.id == 0 && !$0.pocketed }) {
                    aimGuide(cuePosition: cue.position, size: proxy.size)
                }

                ForEach(state.balls.filter { !$0.pocketed }) { ball in
                    ballView(id: ball.id)
                        .frame(width: ball.id == 0 ? 16 : 15, height: ball.id == 0 ? 16 : 15)
                        .position(rotatedPoint(ball.position, size: proxy.size))
                }
            }
        }
    }

    private var pockets: [CGPoint] {
        [
            CGPoint(x: 0.08, y: 0.035),
            CGPoint(x: 0.92, y: 0.035),
            CGPoint(x: 0.06, y: 0.50),
            CGPoint(x: 0.94, y: 0.50),
            CGPoint(x: 0.08, y: 0.965),
            CGPoint(x: 0.92, y: 0.965)
        ]
    }

    private func rotatedPoint(_ point: PingoVector2, size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * point.y,
            y: size.height * (1 - point.x)
        )
    }

    private func aimGuide(cuePosition: PingoVector2, size: CGSize) -> some View {
        let start = rotatedPoint(cuePosition, size: size)
        let radians = angle * .pi / 180
        let length = max(size.width, size.height) * 0.72
        let dx = CGFloat(sin(radians)) * length
        let dy = CGFloat(-cos(radians)) * length

        return Path { path in
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + dx, y: start.y + dy))
        }
        .stroke(.white.opacity(0.74), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
    }

    @ViewBuilder
    private func ballView(id: Int) -> some View {
        if id == 0 {
            Circle()
                .fill(.white)
                .overlay { Circle().stroke(.black.opacity(0.12), lineWidth: 1) }
        } else {
            ZStack {
                Circle().fill(ballColor(id))
                if id >= 9 {
                    Capsule()
                        .fill(.white)
                        .frame(height: 6)
                }
                Circle()
                    .fill(id == 8 ? .black : .white)
                    .frame(width: 8, height: 8)
                Text("\(id)")
                    .font(.system(size: 5, weight: .heavy, design: .rounded))
                    .foregroundStyle(id == 8 ? .white : .black)
            }
            .overlay { Circle().stroke(.black.opacity(0.18), lineWidth: 0.6) }
        }
    }

    private func ballColor(_ id: Int) -> Color {
        switch id {
        case 1, 9: return .yellow
        case 2, 10: return .blue
        case 3, 11: return .red
        case 4, 12: return .purple
        case 5, 13: return .orange
        case 6, 14: return .green
        case 7, 15: return Color(red: 0.48, green: 0.10, blue: 0.10)
        case 8: return .black
        default: return .gray
        }
    }
}
