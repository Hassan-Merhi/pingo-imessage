import PingoCore
import SwiftUI
import UIKit

struct PingoEightBallPhase4View: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    @State private var showResignConfirmation = false

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

    private var groupWasAssigned: Bool {
        state.groups.count == 2 && state.groups != [0, 0]
    }

    var body: some View {
        ZStack {
            PingoEightBallPhase3View(
                state: state,
                player: player,
                canMove: canMove && match.status == .active,
                match: match,
                localProfile: localProfile,
                onMove: { move in
                    PingoEightBallFeedback.shotCommitted()
                    onMove(move)
                }
            )

            VStack(spacing: 0) {
                phase4StatusRibbon
                    .padding(.horizontal, 18)
                    .padding(.top, 5)

                Spacer()

                if match.status == .active && state.lastScratch {
                    scratchNotice
                        .padding(.bottom, 11)
                }

                if match.status == .active && groupWasAssigned {
                    groupLegend
                        .padding(.bottom, 8)
                }
            }
            .allowsHitTesting(false)

            if match.status == .awaitingOpponent {
                centeredState(
                    symbol: "hourglass",
                    eyebrow: "CHALLENGE SENT",
                    title: "Waiting for opponent",
                    detail: opponent.map { "@\($0.displayName) can open the latest Pingo card to join." } ?? "Your opponent can open the latest Pingo card to join."
                )
            } else if match.status == .active && !canMove {
                centeredState(
                    symbol: "ellipsis",
                    eyebrow: "THE TABLE IS LOCKED",
                    title: "Opponent’s turn",
                    detail: "You’ll be able to aim as soon as their shot comes back."
                )
            } else if match.status == .completed || match.status == .resigned {
                resultState
            }
        }
        .onAppear {
            if match.status == .active && canMove {
                PingoEightBallFeedback.turnReady()
            } else if match.status == .completed {
                PingoEightBallFeedback.result(won: localWon)
            }
        }
        .onChange(of: canMove) { newValue in
            if newValue && match.status == .active {
                PingoEightBallFeedback.turnReady()
            }
        }
        .onChange(of: match.status) { newValue in
            if newValue == .completed {
                PingoEightBallFeedback.result(won: localWon)
            }
        }
        .confirmationDialog(
            "Resign this 8 Ball match?",
            isPresented: $showResignConfirmation,
            titleVisibility: .visible
        ) {
            Button("Resign Match", role: .destructive) {
                PingoEightBallFeedback.destructiveAction()
                onResign()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("The other player will be awarded the match.")
        }
    }

    @ViewBuilder
    private var phase4StatusRibbon: some View {
        if match.status == .active {
            HStack(spacing: 8) {
                Circle()
                    .fill(canMove ? Color.green.opacity(0.9) : Color.white.opacity(0.34))
                    .frame(width: 7, height: 7)

                Text(canMove ? "YOUR TURN" : "OPPONENT’S TURN")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)

                Spacer(minLength: 6)

                if state.lastScratch {
                    Text("SCRATCH")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.red.opacity(0.92))
                }

                Button {
                    PingoEightBallFeedback.selection()
                    showResignConfirmation = true
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 28, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Resign match")
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.leading, 11)
            .padding(.trailing, 5)
            .padding(.vertical, 5)
            .background(.black.opacity(0.74), in: Capsule())
            .allowsHitTesting(true)
        }
    }

    private var scratchNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
            VStack(alignment: .leading, spacing: 1) {
                Text("SCRATCH")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                Text(canMove ? "Cue ball reset — your turn." : "Cue ball reset — turn passes over.")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.68)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.black.opacity(0.78), in: Capsule())
    }

    private var groupLegend: some View {
        HStack(spacing: 7) {
            Text(groupName(for: player))
                .foregroundStyle(.white)
            Text("YOU")
                .foregroundStyle(.white.opacity(0.48))
            Text("•")
                .foregroundStyle(.white.opacity(0.28))
            Text(groupName(for: player == 0 ? 1 : 0))
                .foregroundStyle(.white)
            Text("OPPONENT")
                .foregroundStyle(.white.opacity(0.48))
        }
        .font(.system(size: 9, weight: .heavy, design: .rounded))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.68), in: Capsule())
    }

    private func groupName(for index: Int) -> String {
        guard state.groups.indices.contains(index) else { return "OPEN" }
        switch state.groups[index] {
        case 1: return "SOLIDS"
        case 2: return "STRIPES"
        default: return "OPEN"
        }
    }

    private func centeredState(symbol: String, eyebrow: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white.opacity(0.86))

            Text(eyebrow)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.52))

            Text(title)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(detail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 245)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 17)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 12, y: 5)
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
                    .frame(width: 52, height: 52)
                Image(systemName: localWon ? "trophy.fill" : "8.circle.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(resultTitle)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            if let series = match.series {
                Text("Series \(series.scoreText)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            HStack(spacing: 9) {
                if canContinueSeries {
                    Button("Next Game") {
                        PingoEightBallFeedback.selection()
                        onContinueSeries()
                    }
                    .buttonStyle(Phase4PrimaryButtonStyle())
                } else {
                    Button("Rematch") {
                        PingoEightBallFeedback.selection()
                        onRematch()
                    }
                    .buttonStyle(Phase4PrimaryButtonStyle())
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 14, y: 6)
    }

    private var resultTitle: String {
        if match.status == .resigned {
            return localWon ? "Opponent resigned" : "Match resigned"
        }
        return localWon ? "Table cleared" : "Opponent cleared the table"
    }
}

@MainActor
private enum PingoEightBallFeedback {
    static func shotCommitted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func turnReady() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func result(won: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(won ? .success : .warning)
    }

    static func destructiveAction() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

private struct Phase4PrimaryButtonStyle: ButtonStyle {
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
