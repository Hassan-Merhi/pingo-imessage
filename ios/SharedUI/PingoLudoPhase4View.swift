import PingoCore
import SwiftUI

struct PingoLudoPhase4View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoExtraGameMove) -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    @State private var showResignConfirmation = false

    private var opponentIndex: Int { player == 0 ? 1 : 0 }
    private var localWon: Bool { match.winnerPlayerID == localProfile.id }
    private var opponent: PingoPlayerRef? { match.players.first(where: { $0.id != localProfile.id }) }
    private var die: Int { PingoExtraGameEngine.ludoDie(for: state) }
    private var localPieces: [Int] { positions(for: player) }
    private var opponentPieces: [Int] { positions(for: opponentIndex) }
    private var localHomeCount: Int { localPieces.filter { $0 >= 24 }.count }
    private var opponentHomeCount: Int { opponentPieces.filter { $0 >= 24 }.count }
    private var canContinueSeries: Bool {
        guard let series = match.series else { return false }
        return !series.completed && (match.status == .completed || match.status == .resigned)
    }

    var body: some View {
        ZStack {
            PingoLudoPhase3View(
                state: state,
                player: player,
                canMove: canMove && match.status == .active,
                onMove: { move in
                    PingoLudoFeedback.moveSubmitted(isPass: move.primary == -1)
                    onMove(move)
                }
            )

            VStack(spacing: 0) {
                statusRibbon
                    .padding(.horizontal, 18)
                    .padding(.top, 5)
                Spacer()
                if match.status == .active {
                    turnStrip
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
            }
            .allowsHitTesting(false)

            if match.status == .awaitingOpponent {
                centeredState(
                    symbol: "circle.grid.cross.fill",
                    eyebrow: "BOARD READY",
                    title: "Waiting for opponent",
                    detail: opponent.map { "@\($0.displayName) can open the newest Pingo card to join Ludo." } ?? "Your opponent can open the newest Pingo card to join Ludo."
                )
            } else if match.status == .active && !canMove {
                centeredState(
                    symbol: "hourglass",
                    eyebrow: "BOARD LOCKED",
                    title: "Opponent’s turn",
                    detail: "Your pieces stay locked until their move is submitted."
                )
            } else if match.status == .completed || match.status == .resigned {
                resultState
            }
        }
        .onAppear {
            PingoLudoFeedback.prepare()
        }
        .onChange(of: state.lastSummary) { summary in
            guard !summary.isEmpty else { return }
            PingoLudoFeedback.moveResolved(summary: summary)
        }
        .onChange(of: canMove) { isReady in
            if isReady && match.status == .active {
                PingoLudoFeedback.turnReady()
            }
        }
        .onChange(of: match.status) { status in
            if status == .completed || status == .resigned {
                PingoLudoFeedback.matchFinished(won: localWon)
            }
        }
        .confirmationDialog("Resign this Ludo match?", isPresented: $showResignConfirmation, titleVisibility: .visible) {
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
                Text(canMove ? "YOUR MOVE" : "OPPONENT’S MOVE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.9)
                Spacer(minLength: 6)
                Text("HOME \(localHomeCount)–\(opponentHomeCount)")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.68))
                Button { showResignConfirmation = true } label: {
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

    private var turnStrip: some View {
        HStack(spacing: 9) {
            Image(systemName: canMove ? "hand.tap.fill" : "hourglass")
                .font(.system(size: 12, weight: .bold))
            VStack(alignment: .leading, spacing: 1) {
                Text(turnTitle)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                Text(canMove ? "Move a legal piece using the roll shown on the board." : "Waiting for the opponent to finish their move.")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .opacity(0.68)
            }
            Spacer(minLength: 6)
            Text("ROLL \(die)")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .opacity(0.66)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(.black.opacity(0.76), in: Capsule())
    }

    private var turnTitle: String {
        if !state.lastSummary.isEmpty { return state.lastSummary.uppercased() }
        return canMove ? "MOVE YOUR PIECE" : "OPPONENT MOVING"
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
        .overlay { RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.09), lineWidth: 1) }
        .shadow(color: .black.opacity(0.30), radius: 12, y: 5)
    }

    private var resultState: some View {
        VStack(spacing: 10) {
            Text(match.status == .resigned ? "MATCH ENDED" : (match.winnerPlayerID == nil ? "DRAW" : (localWon ? "YOU WIN" : "YOU LOSE")))
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.56))
            Image(systemName: localWon ? "trophy.fill" : "circle.grid.cross.fill")
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background((localWon ? Color.green : Color.white).opacity(0.14), in: Circle())
            Text(resultTitle)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text("Pieces home: You \(localHomeCount) • Opponent \(opponentHomeCount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.54))
            if let series = match.series {
                Text("Series \(series.scoreText)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }
            Button(canContinueSeries ? "Next Game" : "Rematch", action: canContinueSeries ? onContinueSeries : onRematch)
                .buttonStyle(LudoPhase4PrimaryButtonStyle())
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1) }
        .shadow(color: .black.opacity(0.34), radius: 14, y: 6)
    }

    private var resultTitle: String {
        if match.status == .resigned { return localWon ? "Opponent resigned" : "Match resigned" }
        guard match.winnerPlayerID != nil else { return "Match tied" }
        return localWon ? "Ludo victory" : "Opponent brought both pieces home"
    }

    private func positions(for index: Int) -> [Int] {
        guard state.positions.indices.contains(index), state.positions[index].count == 2 else {
            return [-1, -1]
        }
        return state.positions[index]
    }
}

private struct LudoPhase4PrimaryButtonStyle: ButtonStyle {
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
