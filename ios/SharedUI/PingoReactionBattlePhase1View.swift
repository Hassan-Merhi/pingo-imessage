import PingoCore
import SwiftUI

struct PingoReactionBattlePhase1View: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var reactionPhase = 0
    @State private var readyAt: Date?

    private var localIndex: Int {
        match.players.firstIndex(where: { $0.id == localProfile.id }) ?? 0
    }

    private var opponentIndex: Int { 1 - localIndex }

    private var localAttempts: Int {
        state.attempts.indices.contains(localIndex) ? state.attempts[localIndex] : 0
    }

    private var opponentAttempts: Int {
        state.attempts.indices.contains(opponentIndex) ? state.attempts[opponentIndex] : 0
    }

    private var localScore: Int {
        state.scores.indices.contains(localIndex) ? state.scores[localIndex] : 0
    }

    private var opponentScore: Int {
        state.scores.indices.contains(opponentIndex) ? state.scores[opponentIndex] : 0
    }

    var body: some View {
        VStack(spacing: 14) {
            scoreboard
            arena
            roundStrip
            if !state.lastSummary.isEmpty {
                lastResult
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.96), Color.pingoPrimary.opacity(0.24), Color.black.opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onChange(of: match.revision) { _ in
            resetReactionState()
        }
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            scoreBlock(
                label: "YOU",
                name: localName,
                score: localScore,
                attempts: localAttempts,
                emphasized: canMove
            )
            Text("VS")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.55))
            scoreBlock(
                label: "RIVAL",
                name: opponentName,
                score: opponentScore,
                attempts: opponentAttempts,
                emphasized: !canMove && match.status == .active
            )
        }
    }

    private var arena: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.64))

            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(Color.white.opacity(0.05 + Double(index) * 0.025), lineWidth: 1)
                    .frame(width: CGFloat(76 + index * 46), height: CGFloat(76 + index * 46))
            }

            VStack(spacing: 12) {
                Text(arenaEyebrow)
                    .font(.caption2.bold())
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.55))

                reactionLight

                Text(arenaTitle)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(arenaSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)

                arenaAction
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .frame(minHeight: 285)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(lightColor.opacity(reactionPhase == 2 ? 0.8 : 0.22), lineWidth: reactionPhase == 2 ? 2 : 1)
        )
    }

    private var reactionLight: some View {
        ZStack {
            Circle()
                .fill(lightColor.opacity(0.16))
                .frame(width: 112, height: 112)
            Circle()
                .stroke(lightColor.opacity(0.38), lineWidth: 8)
                .frame(width: 88, height: 88)
            Circle()
                .fill(lightColor)
                .frame(width: 58, height: 58)
                .shadow(color: lightColor.opacity(reactionPhase == 2 ? 0.8 : 0.3), radius: reactionPhase == 2 ? 22 : 8)
            Image(systemName: reactionPhase == 2 ? "bolt.fill" : reactionPhase == 1 ? "hourglass" : "hand.tap.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(reactionPhase == 2 ? Color.black : Color.white)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var arenaAction: some View {
        if match.status != .active {
            statusPill("MATCH COMPLETE")
        } else if !canMove {
            statusPill("WAITING FOR OPPONENT")
        } else if reactionPhase == 0 {
            Button("ARM REACTION TEST") {
                startReaction()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pingoPrimary)
            .controlSize(.large)
        } else if reactionPhase == 1 {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                Text("HOLD…")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.08), in: Capsule())
        } else {
            Button {
                finishReaction()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    Text("TAP NOW")
                }
                .font(.title3.black())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .foregroundStyle(.black)
            .controlSize(.large)
        }
    }

    private var roundStrip: some View {
        HStack(spacing: 8) {
            metric(title: "ROUND", value: "\(min(5, localAttempts + 1))/5")
            metric(title: "LAST", value: state.lastTarget > 0 ? "\(state.lastTarget) ms" : "—")
            metric(title: "BEST TARGET", value: "< 250 ms")
        }
    }

    private var lastResult: some View {
        HStack(spacing: 10) {
            Image(systemName: state.lastTarget > 0 && state.lastTarget < 250 ? "bolt.circle.fill" : "timer")
                .font(.title3)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("LAST REACTION")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.5))
                Text(state.lastSummary)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(11)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func scoreBlock(label: String, name: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(emphasized ? Color.yellow : Color.white.opacity(0.48))
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)
            Text("\(score)")
                .font(.title2.black().monospacedDigit())
                .foregroundStyle(.white)
            Text("\(min(5, attempts))/5 runs")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.46))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(Color.white.opacity(emphasized ? 0.10 : 0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func statusPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .tracking(1.1)
            .foregroundStyle(.white.opacity(0.72))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var localName: String {
        match.players.indices.contains(localIndex) ? "@\(match.players[localIndex].displayName)" : "You"
    }

    private var opponentName: String {
        match.players.indices.contains(opponentIndex) ? "@\(match.players[opponentIndex].displayName)" : "Opponent"
    }

    private var arenaEyebrow: String {
        if match.status != .active { return "REACTION BATTLE" }
        if !canMove { return "OPPONENT RUN" }
        if reactionPhase == 1 { return "SIGNAL ARMED" }
        if reactionPhase == 2 { return "SIGNAL LIVE" }
        return "YOUR RUN"
    }

    private var arenaTitle: String {
        if match.status != .active { return "FINAL RESULT" }
        if !canMove { return "Stand By" }
        if reactionPhase == 1 { return "Don’t Tap Yet" }
        if reactionPhase == 2 { return "GO!" }
        return "Ready?"
    }

    private var arenaSubtitle: String {
        if match.status != .active { return "The five-run reaction duel has finished." }
        if !canMove { return "Your opponent is completing their reaction run." }
        if reactionPhase == 1 { return "Wait for the signal. Tapping early does not submit a run." }
        if reactionPhase == 2 { return "Hit the signal as fast as you can." }
        return "Arm the test, wait for the random signal, then tap instantly."
    }

    private var lightColor: Color {
        if match.status != .active || !canMove { return .gray }
        if reactionPhase == 1 { return .red }
        if reactionPhase == 2 { return .yellow }
        return .pingoPrimary
    }

    private func startReaction() {
        guard canMove, reactionPhase == 0 else { return }
        reactionPhase = 1
        readyAt = nil
        let delay = PingoExtraGameEngine.reactionDelayMilliseconds(for: state)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) / 1000.0) {
            guard reactionPhase == 1 else { return }
            readyAt = Date()
            reactionPhase = 2
        }
    }

    private func finishReaction() {
        guard canMove, reactionPhase == 2, let readyAt else { return }
        let measured = Int(Date().timeIntervalSince(readyAt) * 1000.0)
        let clamped = min(1_500, max(80, measured))
        resetReactionState()
        onMove(.init(primary: clamped))
    }

    private func resetReactionState() {
        reactionPhase = 0
        readyAt = nil
    }
}
