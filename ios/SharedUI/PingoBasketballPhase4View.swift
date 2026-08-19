import PingoCore
import SwiftUI

struct PingoBasketballPhase4View: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    @State private var showResignConfirmation = false
    @State private var isRefreshingTurn = false
    @State private var refreshTask: Task<Void, Never>?

    private var opponentIndex: Int { player == 0 ? 1 : 0 }

    private var localWon: Bool {
        match.winnerPlayerID == localProfile.id
    }

    private var opponent: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    private var canContinueSeries: Bool {
        guard let series = match.series else { return false }
        return !series.completed && (match.status == .completed || match.status == .resigned)
    }

    private var localScore: Int { score(player) }
    private var opponentScore: Int { score(opponentIndex) }
    private var localAttempts: Int { attempts(player) }
    private var opponentAttempts: Int { attempts(opponentIndex) }

    var body: some View {
        ZStack {
            PingoBasketballPhase3View(
                state: state,
                player: player,
                canMove: canMove && match.status == .active,
                onMove: handleMove
            )

            VStack(spacing: 0) {
                statusRibbon
                    .padding(.horizontal, 18)
                    .padding(.top, 5)

                Spacer()

                if match.status == .active && state.attempts.reduce(0, +) > 0 {
                    lastShotNotice
                        .padding(.bottom, 10)
                }
            }
            .allowsHitTesting(false)

            if match.status == .awaitingOpponent {
                centeredState(
                    symbol: "hourglass",
                    eyebrow: "CHALLENGE SENT",
                    title: "Waiting for opponent",
                    detail: opponent.map { "@\($0.displayName) can open the newest Pingo card to join the shootout." } ?? "Your opponent can open the newest Pingo card to join the shootout."
                )
            } else if match.status == .active && !canMove {
                centeredState(
                    symbol: "hand.raised.fill",
                    eyebrow: "COURT LOCKED",
                    title: "Opponent’s shot",
                    detail: "Your shot controls stay locked until the turn comes back."
                )
            } else if match.status == .completed || match.status == .resigned {
                resultState
            }

            if isRefreshingTurn && match.status == .active {
                VStack(spacing: 7) {
                    ProgressView()
                        .tint(.white)
                    Text("UPDATING COURT")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 17)
                .padding(.vertical, 12)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .confirmationDialog(
            "Resign this Basketball match?",
            isPresented: $showResignConfirmation,
            titleVisibility: .visible
        ) {
            Button("Resign Match", role: .destructive, action: onResign)
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("The other player will be awarded the match.")
        }
        .onAppear {
            PingoBasketballFeedback.prepare()
            if match.status == .completed || match.status == .resigned {
                PingoBasketballFeedback.matchFinished(won: localWon)
            }
        }
        .onChange(of: state.attempts.reduce(0, +)) { _ in
            guard state.attempts.reduce(0, +) > 0 else { return }
            if state.lastPoints > 0 {
                PingoBasketballFeedback.basket(points: state.lastPoints)
            } else {
                PingoBasketballFeedback.miss()
            }
            pulseRefresh()
        }
        .onChange(of: canMove) { newValue in
            if newValue && match.status == .active {
                PingoBasketballFeedback.turnReady()
            }
        }
        .onChange(of: match.revision) { _ in
            pulseRefresh()
        }
        .onChange(of: match.status) { newStatus in
            if newStatus == .completed || newStatus == .resigned {
                PingoBasketballFeedback.matchFinished(won: localWon)
            }
        }
        .onDisappear {
            refreshTask?.cancel()
        }
    }

    private func handleMove(_ move: PingoPhysicsMove) {
        PingoBasketballFeedback.shotReleased()
        onMove(move)
    }

    @ViewBuilder
    private var statusRibbon: some View {
        if match.status == .active {
            HStack(spacing: 8) {
                Circle()
                    .fill(canMove ? Color.green.opacity(0.92) : Color.white.opacity(0.34))
                    .frame(width: 7, height: 7)

                Text(canMove ? "YOUR SHOT" : "OPPONENT’S SHOT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)

                Spacer(minLength: 6)

                Text("YOU \(localScore) • THEM \(opponentScore)")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.68))

                Button {
                    showResignConfirmation = true
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Resign match")
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.leading, 11)
            .padding(.trailing, 5)
            .padding(.vertical, 5)
            .background(.black.opacity(0.76), in: Capsule())
        }
    }

    private var lastShotNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: state.lastPoints > 0 ? "basketball.fill" : "xmark.circle.fill")
                .font(.system(size: 11, weight: .bold))

            VStack(alignment: .leading, spacing: 1) {
                Text(lastShotTitle)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))

                Text(lastShotDetail)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.68)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.black.opacity(0.76), in: Capsule())
    }

    private var lastShotTitle: String {
        switch state.lastPoints {
        case 3: return "SWISH +3"
        case 2: return "BUCKET +2"
        default: return "MISS"
        }
    }

    private var lastShotDetail: String {
        let next = canMove ? "You’re back on the line." : "The turn moved to your opponent."
        return "Attempts: You \(localAttempts)/\(state.attemptsPerPlayer) • Them \(opponentAttempts)/\(state.attemptsPerPlayer). \(next)"
    }

    private func centeredState(symbol: String, eyebrow: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white.opacity(0.88))

            Text(eyebrow)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.52))

            Text(title)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 17)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 12, y: 5)
    }

    private var resultState: some View {
        VStack(spacing: 10) {
            Text(match.status == .resigned ? "MATCH ENDED" : (localWon ? "YOU WIN" : "YOU LOSE"))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.56))

            ZStack {
                Circle()
                    .fill(localWon ? Color.green.opacity(0.18) : Color.white.opacity(0.08))
                    .frame(width: 54, height: 54)

                Image(systemName: localWon ? "trophy.fill" : "basketball.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(resultTitle)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Final score: You \(localScore) • Opponent \(opponentScore)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))

            if let series = match.series {
                Text("Series \(series.scoreText)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            if canContinueSeries {
                Button("Next Game", action: onContinueSeries)
                    .buttonStyle(BasketballPhase4PrimaryButtonStyle())
            } else {
                Button("Rematch", action: onRematch)
                    .buttonStyle(BasketballPhase4PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.34), radius: 14, y: 6)
    }

    private var resultTitle: String {
        if match.status == .resigned {
            return localWon ? "Opponent resigned" : "Match resigned"
        }
        if localScore == opponentScore {
            return "Shootout complete"
        }
        return localWon ? "You took the shootout" : "Opponent took the shootout"
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }

    private func pulseRefresh() {
        refreshTask?.cancel()
        withAnimation(.easeOut(duration: 0.12)) {
            isRefreshingTurn = true
        }
        refreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.14)) {
                isRefreshingTurn = false
            }
        }
    }
}

private struct BasketballPhase4PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.white.opacity(configuration.isPressed ? 0.72 : 0.96), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
