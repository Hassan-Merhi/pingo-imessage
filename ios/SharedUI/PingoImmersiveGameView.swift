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

            VStack(spacing: match.gameID == .cupPong ? 0 : 8) {
                if match.gameID != .cupPong {
                    playerStrip
                        .padding(.horizontal, 14)
                }

                gameStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.top, match.gameID == .cupPong ? 0 : 8)
            .padding(.bottom, match.gameID == .cupPong ? 0 : 10)

            if match.status == .awaitingOpponent || (match.status == .active && !localCanMove) {
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
                PingoEightBallPhase3View(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    match: match,
                    localProfile: localProfile,
                    onMove: onPhysicsMove
                )
                .padding(.horizontal, 8)

            case .cupPong:
                let state = (try? PingoPhysicsGameEngine.cupPongState(from: match.gameState)) ?? PingoCupPongState()
                PingoCupPongPhase2View(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    match: match,
                    localProfile: localProfile,
                    onMove: onPhysicsMove
                )

            case .basketball:
                let state = (try? PingoPhysicsGameEngine.basketballState(from: match.gameState)) ?? PingoBasketballState()
                PingoBasketballPhase3View(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .darts:
                let state = (try? PingoPhysicsGameEngine.dartsState(from: match.gameState)) ?? PingoDartsState()
                PingoDartsPhase3View(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .miniGolf:
                let state = (try? PingoPhysicsGameEngine.miniGolfState(from: match.gameState)) ?? PingoMiniGolfState()
                PingoMiniGolfPhase3View(
                    state: state,
                    player: index,
                    canMove: localCanMove,
                    onMove: onPhysicsMove
                )

            case .bowling:
                if let state = extraState {
                    PingoBowlingPhase3View(
                        state: state,
                        player: index,
                        canMove: localCanMove,
                        onMove: onExtraMove
                    )
                } else {
                    fallbackStage
                }

            case .penaltyShootout:
                if let state = extraState {
                    PingoPenaltyShootoutPhase3View(
                        state: state,
                        player: index,
                        canMove: localCanMove,
                        onMove: onExtraMove
                    )
                } else {
                    fallbackStage
                }

            case .archery:
                if let state = extraState {
                    PingoArcheryPhase1View(
                        state: state,
                        player: index,
                        canMove: localCanMove,
                        onMove: onExtraMove
                    )
                } else {
                    fallbackStage
                }

            case .airHockey:
                if let state = extraState {
                    PingoAirHockeyPhase1View(
                        state: state,
                        player: index,
                        canMove: localCanMove,
                        onMove: onExtraMove
                    )
                } else {
                    fallbackStage
                }

            case .miniRacing:
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

            case .reactionBattle, .drawAndGuess, .wordHunt, .anagrams, .trivia, .crazyEights, .ludo:
                if let state = extraState {
                    PingoImmersivePartyView(
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
            PingoImmersiveBoardStage(
                match: match,
                localProfile: localProfile,
                onMoves: onMoves
            )
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

    @ViewBuilder
    private var waitingOverlay: some View {
        if match.gameID == .cupPong {
            VStack(spacing: 7) {
                Image(systemName: match.status == .awaitingOpponent ? "hourglass" : "hand.raised.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))

                Text(match.status == .awaitingOpponent ? "WAITING FOR OPPONENT" : "OPPONENT’S THROW")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1)

                Text(match.status == .awaitingOpponent ? "The table is ready." : "Your cups are locked until the turn comes back.")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.36), radius: 12, y: 5)
            .accessibilityLabel(match.status == .awaitingOpponent ? "Waiting for opponent" : "Opponent's turn")
        } else {
            Text(match.status == .awaitingOpponent ? "WAITING FOR OPPONENT." : "OPPONENT'S TURN.")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 15)
                .background(Color.pingoGameOverlay, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(radius: 8, y: 4)
                .accessibilityLabel(match.status == .awaitingOpponent ? "Waiting for opponent" : "Opponent's turn")
        }
    }
}
