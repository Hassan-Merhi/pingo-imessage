import PingoCore
import SwiftUI

struct PingoIncomingMatchView: View {
    let payload: PingoMessagePayload
    let localProfile: PingoPublicProfile
    let entitlements: Set<PingoEntitlementID>
    let onAccept: () -> Void
    let onMoves: ([PingoGameMove]) -> Void
    let onPhysicsMove: (PingoPhysicsMove) -> Void
    let onExtraMove: (PingoExtraGameMove) -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void
    let onResign: () -> Void
    let onOpenStore: () -> Void
    let onClose: () -> Void

    private var game: PingoGameDescriptor? {
        PingoGameCatalog.game(id: payload.match.gameID)
    }

    private var localIsPlayer: Bool {
        payload.match.players.contains(where: { $0.id == localProfile.id })
    }

    private var localPlayerIndex: Int? {
        payload.match.players.firstIndex(where: { $0.id == localProfile.id })
    }

    private var localCanMove: Bool {
        payload.match.status == .active && payload.match.currentPlayerID == localProfile.id
    }

    private var hasPlayableGame: Bool {
        PingoPlayableGameRegistry.supportedGames.contains(payload.match.gameID)
            || PingoExtraGameEngine.supportedGames.contains(payload.match.gameID)
    }

    private var localCanPlay: Bool {
        PingoAccessPolicy.canPlay(payload.match.gameID, entitlements: entitlements)
    }

    private var localIsSeriesHost: Bool {
        payload.match.createdByPlayerID == localProfile.id
    }

    private var requiredPackTitle: String {
        PingoAccessPolicy.packTitle(for: payload.match.gameID) ?? "game pack"
    }

    private var shouldShowGame: Bool {
        hasPlayableGame
            && localCanPlay
            && localIsPlayer
            && (payload.match.status == .awaitingOpponent
                || payload.match.status == .active
                || payload.match.status == .completed
                || payload.match.status == .resigned)
    }

    private var isEightBall: Bool { payload.match.gameID == .eightBall }
    private var isCupPong: Bool { payload.match.gameID == .cupPong }
    private var isBasketball: Bool { payload.match.gameID == .basketball }
    private var isDarts: Bool { payload.match.gameID == .darts }
    private var isMiniGolf: Bool { payload.match.gameID == .miniGolf }
    private var isBowling: Bool { payload.match.gameID == .bowling }
    private var isPenaltyShootout: Bool { payload.match.gameID == .penaltyShootout }
    private var isArchery: Bool { payload.match.gameID == .archery }
    private var isAirHockey: Bool { payload.match.gameID == .airHockey }
    private var isMiniRacing: Bool { payload.match.gameID == .miniRacing }
    private var isWordHunt: Bool { payload.match.gameID == .wordHunt }
    private var isAnagrams: Bool { payload.match.gameID == .anagrams }
    private var isReactionBattle: Bool { payload.match.gameID == .reactionBattle }
    private var isTrivia: Bool { payload.match.gameID == .trivia }
    private var isDrawGuess: Bool { payload.match.gameID == .drawAndGuess }
    private var isCrazyEights: Bool { payload.match.gameID == .crazyEights }
    private var isLudo: Bool { payload.match.gameID == .ludo }

    private var hasDedicatedMatchFlow: Bool {
        isEightBall || isCupPong || isBasketball || isDarts || isMiniGolf || isBowling || isPenaltyShootout || isArchery || isAirHockey || isMiniRacing || isWordHunt || isAnagrams || isReactionBattle || isTrivia || isDrawGuess || isCrazyEights || isLudo
    }

    var body: some View {
        ZStack {
            Color.pingoGameBackdrop.ignoresSafeArea()

            if shouldShowGame {
                if isEightBall, let index = localPlayerIndex {
                    let state = (try? PingoPhysicsGameEngine.eightBallState(from: payload.match.gameState)) ?? PingoEightBallState()
                    PingoEightBallPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onPhysicsMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isCupPong, let index = localPlayerIndex {
                    let state = (try? PingoPhysicsGameEngine.cupPongState(from: payload.match.gameState)) ?? PingoCupPongState()
                    PingoCupPongPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onPhysicsMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isBasketball, let index = localPlayerIndex {
                    let state = (try? PingoPhysicsGameEngine.basketballState(from: payload.match.gameState)) ?? PingoBasketballState()
                    PingoBasketballPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onPhysicsMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isDarts, let index = localPlayerIndex {
                    let state = (try? PingoPhysicsGameEngine.dartsState(from: payload.match.gameState)) ?? PingoDartsState()
                    PingoDartsPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onPhysicsMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isMiniGolf, let index = localPlayerIndex {
                    let state = (try? PingoPhysicsGameEngine.miniGolfState(from: payload.match.gameState)) ?? PingoMiniGolfState()
                    PingoMiniGolfPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onPhysicsMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isBowling, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoBowlingPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isPenaltyShootout, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoPenaltyShootoutPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isArchery, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoArcheryPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isAirHockey, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoAirHockeyPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isMiniRacing, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoMiniRacingPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isWordHunt, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoWordHuntPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isAnagrams, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoAnagramsPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isReactionBattle, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoReactionBattlePhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isTrivia, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoTriviaPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isDrawGuess, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoDrawGuessPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isCrazyEights, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoCrazyEightsPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else if isLudo, let index = localPlayerIndex {
                    let state = (try? PingoExtraGameEngine.state(from: payload.match.gameState, gameID: payload.match.gameID, matchID: payload.match.id)) ?? PingoExtraGameState()
                    PingoLudoPhase4View(state: state, player: index, canMove: localCanMove, match: payload.match, localProfile: localProfile, onMove: onExtraMove, onResign: onResign, onContinueSeries: onContinueSeries, onRematch: onRematch)
                        .padding(.top, 66)
                } else {
                    PingoImmersiveGameView(match: payload.match, localProfile: localProfile, onMoves: onMoves, onPhysicsMove: onPhysicsMove, onExtraMove: onExtraMove)
                        .padding(.top, 66)
                }
            } else {
                nonGameState
                    .padding(.top, 66)
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomAction
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 14)

            if !hasDedicatedMatchFlow && (payload.match.status == .completed || payload.match.status == .resigned) {
                resultOverlay
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.46), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to games")

            VStack(spacing: 1) {
                Text(game?.name ?? "Pingo")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(matchSubtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.60))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.46), in: Capsule())

            Spacer()

            Menu {
                if !localCanPlay {
                    Button("Unlock \(requiredPackTitle)", action: onOpenStore)
                }

                if !hasDedicatedMatchFlow && payload.match.status == .active && localIsPlayer {
                    Button("Resign Match", role: .destructive, action: onResign)
                }

                if !hasDedicatedMatchFlow && canContinueSeries {
                    Button("Continue \(payload.match.series?.format.title ?? "Series")", action: onContinueSeries)
                }

                Button("Back to Games", action: onClose)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.black.opacity(0.46), in: Circle())
            }
            .accessibilityLabel("Match options")
        }
    }

    @ViewBuilder
    private var nonGameState: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(LinearGradient(colors: [Color.pingoPrimary, Color.pingoSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(game?.symbol ?? "🎮")
                    .font(.system(size: 84))
            }
            .frame(width: 190, height: 190)
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)

            if !localCanPlay {
                Text("GAME PACK REQUIRED")
                    .font(.title3.bold())
                    .foregroundStyle(.black.opacity(0.78))
                Text("Unlock the \(requiredPackTitle) to play this match.")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.52))
                    .multilineTextAlignment(.center)
            } else if payload.match.status == .awaitingOpponent {
                if payload.sender.id == localProfile.id {
                    Text("WAITING FOR OPPONENT.")
                        .font(.title3.bold())
                        .foregroundStyle(.black.opacity(0.78))
                    Text("The challenge is ready. The other person can open the newest Pingo card to join the race.")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.52))
                        .multilineTextAlignment(.center)
                } else {
                    Text("@\(payload.sender.username) CHALLENGED YOU")
                        .font(.title3.bold())
                        .foregroundStyle(.black.opacity(0.78))
                    Text("Accept to open the table and start the match.")
                        .font(.subheadline)
                        .foregroundStyle(.black.opacity(0.52))
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("THIS MATCH CAN'T OPEN")
                    .font(.title3.bold())
                    .foregroundStyle(.black.opacity(0.78))
                Text("Open the newest Pingo game card in this conversation.")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.52))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var bottomAction: some View {
        if !localCanPlay {
            Button("Unlock \(requiredPackTitle)", action: onOpenStore)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.pingoPrimary)
        } else if payload.match.status == .awaitingOpponent,
                  payload.sender.id != localProfile.id,
                  !localIsPlayer {
            Button("Accept Challenge", action: onAccept)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.pingoPrimary)
        } else if !hasDedicatedMatchFlow && canContinueSeries {
            Button("Continue \(payload.match.series?.format.title ?? "Series")", action: onContinueSeries)
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.pingoPrimary)
        }
    }

    private var resultOverlay: some View {
        VStack(spacing: 5) {
            Text(payload.match.status == .completed ? "MATCH COMPLETE" : "MATCH ENDED")
                .font(.caption.bold())
                .tracking(1)
            Text(resultText)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.pingoGameOverlay, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .shadow(radius: 8, y: 4)
    }

    private var canContinueSeries: Bool {
        guard (payload.match.status == .completed || payload.match.status == .resigned),
              let series = payload.match.series,
              !series.completed,
              localIsPlayer,
              localIsSeriesHost else {
            return false
        }
        return true
    }

    private var matchSubtitle: String {
        if let series = payload.match.series {
            return "\(seriesGameLabel) • \(series.format.title)"
        }

        switch payload.match.status {
        case .active:
            return payload.match.currentPlayerID == localProfile.id ? "Your turn" : "Opponent's turn"
        case .completed, .resigned:
            return "Final result"
        case .awaitingOpponent:
            return "Challenge"
        case .expired:
            return "Expired"
        case .draft:
            return "Preparing"
        }
    }

    private var seriesGameLabel: String {
        guard let series = payload.match.series else { return "Single Game" }
        let gameNumber: Int
        if payload.match.status == .completed || payload.match.status == .resigned {
            gameNumber = series.completed ? series.gameNumber : max(1, series.gameNumber - 1)
        } else {
            gameNumber = series.gameNumber
        }
        return "Game \(gameNumber)"
    }

    private var resultText: String {
        guard let winner = payload.match.winnerPlayerID else { return "Draw" }
        return winner == localProfile.id ? "You won" : "Opponent won"
    }
}
