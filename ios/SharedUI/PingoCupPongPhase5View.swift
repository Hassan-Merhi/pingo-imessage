import PingoCore
import SwiftUI

struct PingoCupPongPhase5View: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void
    let onResign: () -> Void
    let onContinueSeries: () -> Void
    let onRematch: () -> Void

    @State private var isRefreshingTurn = false
    @State private var refreshTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            PingoCupPongPhase4View(
                state: state,
                player: player,
                canMove: canMove,
                match: match,
                localProfile: localProfile,
                onMove: onMove,
                onResign: onResign,
                onContinueSeries: onContinueSeries,
                onRematch: onRematch
            )

            if isRefreshingTurn && match.status == .active {
                VStack(spacing: 7) {
                    ProgressView()
                        .tint(.white)
                    Text("UPDATING TABLE")
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
        .onAppear {
            PingoCupPongFeedback.prepare()
            if match.status == .completed || match.status == .resigned {
                PingoCupPongFeedback.matchFinished(won: match.winnerPlayerID == localProfile.id)
            }
        }
        .onChange(of: state.turns) { _ in
            guard state.turns > 0 else { return }
            if state.lastCup != nil {
                PingoCupPongFeedback.cupSunk()
            } else {
                PingoCupPongFeedback.rimOrMiss()
            }
            pulseRefresh()
        }
        .onChange(of: canMove) { newValue in
            if newValue && match.status == .active {
                PingoCupPongFeedback.turnReady()
            }
        }
        .onChange(of: match.revision) { _ in
            pulseRefresh()
        }
        .onChange(of: match.status) { newStatus in
            if newStatus == .completed || newStatus == .resigned {
                PingoCupPongFeedback.matchFinished(won: match.winnerPlayerID == localProfile.id)
            }
        }
        .onDisappear {
            refreshTask?.cancel()
        }
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
