import PingoCore
import SwiftUI

struct PingoCrazyEightsPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isResolving = false
    @State private var pendingMove: PingoExtraGameMove?
    @State private var feedbackTitle = ""
    @State private var feedbackDetail = ""
    @State private var feedbackSymbol = "rectangle.stack.fill"
    @State private var pulse = false

    private var effectiveCanMove: Bool { canMove && !isResolving }

    var body: some View {
        ZStack {
            PingoCrazyEightsPhase1View(
                state: state,
                player: player,
                canMove: effectiveCanMove,
                onMove: beginResolution
            )
            .allowsHitTesting(!isResolving)
            .scaleEffect(isResolving ? 0.992 : 1)
            .animation(.easeInOut(duration: 0.18), value: isResolving)

            if isResolving {
                resolutionOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isResolving)
    }

    private var resolutionOverlay: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.pingoPrimary.opacity(0.18))
                    .frame(width: 74, height: 74)
                    .scaleEffect(pulse ? 1.18 : 0.88)
                    .opacity(pulse ? 0.10 : 0.72)

                Circle()
                    .fill(.white.opacity(0.94))
                    .frame(width: 54, height: 54)
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 4)

                Image(systemName: feedbackSymbol)
                    .font(.system(size: 23, weight: .black))
                    .foregroundStyle(Color.pingoPrimary)
                    .rotationEffect(.degrees(pulse ? 4 : -4))
            }

            Text(feedbackTitle)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.black.opacity(0.78))

            Text(feedbackDetail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.48))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: 250)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.68), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .onAppear {
            pulse = false
            withAnimation(.easeOut(duration: 0.58).repeatCount(2, autoreverses: true)) {
                pulse = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feedbackTitle). \(feedbackDetail)")
    }

    private func beginResolution(_ move: PingoExtraGameMove) {
        guard effectiveCanMove else { return }

        pendingMove = move
        if move.primary == -1 {
            feedbackTitle = "CARD DRAWN"
            feedbackDetail = "Adding a card to your hand…"
            feedbackSymbol = "plus.rectangle.on.rectangle"
        } else {
            let label = PingoExtraGameEngine.cardLabel(move.primary)
            feedbackTitle = label.contains("8") ? "WILD EIGHT" : "CARD PLAYED"
            feedbackDetail = label.contains("8") ? "Eight is wild — table is updating…" : "\(label) is landing on the discard pile…"
            feedbackSymbol = label.contains("8") ? "8.circle.fill" : "rectangle.stack.fill"
        }

        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
            isResolving = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            guard let moveToSend = pendingMove else { return }
            pendingMove = nil
            withAnimation(.easeOut(duration: 0.18)) {
                isResolving = false
            }
            onMove(moveToSend)
        }
    }
}
