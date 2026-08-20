import PingoCore
import SwiftUI

struct PingoDartsPhase4View: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    @State private var showResignConfirmation = false

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

    private var localRemaining: Int { remaining(player) }
    private var opponentRemaining: Int { remaining(opponentIndex) }

    var body: some View {
        ZStack {
            PingoDartsPhase3View(
                state: state,
                player: player,
                canMove: canMove && match.status == .active,
                onMove: onMove
            )

            VStack(spacing: 0) {
                statusRibbon
                    .padding(.horizontal, 18)
                    .padding(.top, 5)

                Spacer()

                if match.status == .active {
                    checkoutStrip
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
            }
            .allowsHitTesting(false)

            if match.status == .awaitingOpponent {
                centeredState(
                    symbol: "hourglass",
                    eyebrow: "CHALLENGE SENT",
                    title: "Waiting for opponent",
                    detail: opponent.map { "@\($0.displayName) can open the newest Pingo card to join the 301 match." } ?? "Your opponent can open the newest Pingo card to join the 301 match."
                )
            } else if match.status == .active && !canMove {
                centeredState(
                    symbol: "scope",
                    eyebrow: "OCHE LOCKED",
                    title: "Opponent’s visit",
                    detail: "Your board and throw controls stay locked until their three-dart visit is complete."
                )
            } else if match.status == .completed || match.status == .resigned {
                resultState
            }
        }
        .confirmationDialog(
            "Resign this Darts match?",
            isPresented: $showResignConfirmation,
            titleVisibility: .visible
        ) {
            Button("Resign Match", role: .destructive, action: onResign)
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("The other player will be awarded the match.")
        }
    }

    @ViewBuilder
    private var statusRibbon: some View {
        if match.status == .active {
            HStack(spacing: 8) {
                Circle()
                    .fill(canMove ? Color.green.opacity(0.92) : Color.white.opacity(0.34))
                    .frame(width: 7, height: 7)

                Text(canMove ? "YOUR VISIT" : "OPPONENT’S VISIT")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)

                Spacer(minLength: 6)

                Text("YOU \(localRemaining) • THEM \(opponentRemaining)")
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

    private var checkoutStrip: some View {
        HStack(spacing: 9) {
            Image(systemName: localRemaining <= 170 ? "scope" : "arrow.down.right.circle.fill")
                .font(.system(size: 12, weight: .bold))

            VStack(alignment: .leading, spacing: 1) {
                Text(checkoutTitle)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))

                Text(checkoutDetail)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.68)
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.black.opacity(0.76), in: Capsule())
    }

    private var checkoutTitle: String {
        if localRemaining == 0 { return "CHECKOUT COMPLETE" }
        if localRemaining <= 170 { return "CHECKOUT RANGE • \(localRemaining)" }
        return "RACE TO ZERO • \(localRemaining) LEFT"
    }

    private var checkoutDetail: String {
        if localRemaining == 0 { return "You closed the leg." }
        if canMove {
            return localRemaining <= 170
                ? "A three-dart checkout is mathematically possible."
                : "Your visit is live — throw all three darts."
        }
        return "Opponent has \(opponentRemaining) remaining. Your controls will unlock on return."
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

                Image(systemName: localWon ? "trophy.fill" : "scope")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(resultTitle)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Final: You \(localRemaining) • Opponent \(opponentRemaining)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))

            if let series = match.series {
                Text("Series \(series.scoreText)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            if canContinueSeries {
                Button("Next Game", action: onContinueSeries)
                    .buttonStyle(DartsPhase4PrimaryButtonStyle())
            } else {
                Button("Rematch", action: onRematch)
                    .buttonStyle(DartsPhase4PrimaryButtonStyle())
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
        if localRemaining == opponentRemaining {
            return "Leg complete"
        }
        return localWon ? "You checked out first" : "Opponent checked out first"
    }

    private func remaining(_ index: Int) -> Int {
        state.remaining.indices.contains(index) ? state.remaining[index] : 301
    }
}

private struct DartsPhase4PrimaryButtonStyle: ButtonStyle {
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
