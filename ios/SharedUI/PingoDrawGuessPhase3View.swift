import PingoCore
import SwiftUI

struct PingoDrawGuessPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var resolving = false
    @State private var feedbackScale: CGFloat = 0.88
    @State private var feedbackOpacity: Double = 0
    @State private var feedbackRotation: Double = -4

    var body: some View {
        ZStack {
            PingoDrawGuessPhase1View(
                state: state,
                player: player,
                canMove: canMove && !resolving,
                onMove: resolve
            )
            .scaleEffect(resolving ? 0.992 : 1)
            .saturation(resolving ? 0.92 : 1)
            .animation(.easeOut(duration: 0.16), value: resolving)

            if resolving {
                feedbackOverlay
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onChange(of: state.phase) { _ in
            resetFeedback()
        }
        .onChange(of: state.attempts.reduce(0, +)) { _ in
            resetFeedback()
        }
    }

    private func resolve(_ move: PingoExtraGameMove) {
        guard canMove, !resolving else { return }

        resolving = true
        feedbackScale = 0.88
        feedbackOpacity = 0
        feedbackRotation = state.phase == 0 ? -4 : 4

        withAnimation(.spring(response: 0.3, dampingFraction: 0.68)) {
            feedbackScale = 1
            feedbackOpacity = 1
            feedbackRotation = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            guard resolving else { return }
            onMove(move)
        }
    }

    private var feedbackOverlay: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 94, height: 94)
                    .scaleEffect(feedbackScale * 1.08)

                Circle()
                    .fill(accent)
                    .frame(width: 66, height: 66)
                    .shadow(color: accent.opacity(0.34), radius: 12, y: 5)

                Image(systemName: state.phase == 0 ? "paperplane.fill" : "text.bubble.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(feedbackRotation))
            }

            Text(state.phase == 0 ? "DRAWING SENT" : "GUESS LOCKED")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.black.opacity(0.78))

            Text(state.phase == 0 ? "Handing the sketch to your opponent…" : "Checking your answer…")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.44))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .scaleEffect(feedbackScale)
        .opacity(feedbackOpacity)
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state.phase == 0 ? "Drawing sent." : "Guess locked. Checking answer.")
    }

    private var accent: Color {
        state.phase == 0
            ? Color(red: 0.58, green: 0.28, blue: 0.78)
            : Color(red: 0.14, green: 0.55, blue: 0.78)
    }

    private func resetFeedback() {
        resolving = false
        feedbackOpacity = 0
        feedbackScale = 0.88
        feedbackRotation = 0
    }
}
