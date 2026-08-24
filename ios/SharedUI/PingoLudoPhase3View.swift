import PingoCore
import SwiftUI

struct PingoLudoPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isResolving = false
    @State private var pendingMove: PingoExtraGameMove?
    @State private var feedbackTitle = ""
    @State private var feedbackDetail = ""
    @State private var feedbackSymbol = "circle.grid.cross.fill"
    @State private var travelProgress: CGFloat = 0
    @State private var pulse = false

    private var die: Int {
        PingoExtraGameEngine.ludoDie(for: state)
    }

    private var effectiveCanMove: Bool {
        canMove && !isResolving
    }

    var body: some View {
        ZStack {
            PingoLudoPhase1View(
                state: state,
                player: player,
                canMove: effectiveCanMove,
                onMove: beginResolution
            )
            .allowsHitTesting(!isResolving)
            .scaleEffect(isResolving ? 0.994 : 1)
            .animation(.easeInOut(duration: 0.18), value: isResolving)

            if isResolving {
                resolutionOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isResolving)
    }

    private var resolutionOverlay: some View {
        VStack(spacing: 12) {
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 122, height: 12)

                GeometryReader { proxy in
                    Circle()
                        .fill(Color.pingoPrimary)
                        .overlay {
                            Circle().stroke(.white, lineWidth: 2)
                        }
                        .frame(width: 30, height: 30)
                        .shadow(color: Color.pingoPrimary.opacity(0.32), radius: 7, y: 3)
                        .position(
                            x: 15 + (proxy.size.width - 30) * travelProgress,
                            y: proxy.size.height / 2
                        )
                }
                .frame(width: 122, height: 36)
            }

            ZStack {
                Circle()
                    .fill(Color.pingoPrimary.opacity(0.17))
                    .frame(width: 66, height: 66)
                    .scaleEffect(pulse ? 1.20 : 0.88)
                    .opacity(pulse ? 0.08 : 0.70)

                Circle()
                    .fill(.white.opacity(0.95))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.13), radius: 7, y: 3)

                Image(systemName: feedbackSymbol)
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(Color.pingoPrimary)
            }

            Text(feedbackTitle)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.black.opacity(0.78))

            Text(feedbackDetail)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.50))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.68), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        .onAppear {
            travelProgress = 0
            pulse = false
            withAnimation(.easeInOut(duration: 0.58)) {
                travelProgress = 1
            }
            withAnimation(.easeOut(duration: 0.52).repeatCount(2, autoreverses: true)) {
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
            feedbackTitle = "TURN PASSED"
            feedbackDetail = "No legal piece can move on roll \(die)."
            feedbackSymbol = "arrow.turn.up.right"
        } else {
            let pieceNumber = move.primary + 1
            feedbackTitle = "PIECE \(pieceNumber) MOVING"
            feedbackDetail = die == 6
                ? "Rolling a six — advancing piece \(pieceNumber)."
                : "Advancing piece \(pieceNumber) by \(die) spaces."
            feedbackSymbol = die == 6 ? "dice.fill" : "circle.grid.cross.fill"
        }

        travelProgress = 0
        pulse = false
        withAnimation(.spring(response: 0.26, dampingFraction: 0.80)) {
            isResolving = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.78) {
            guard let moveToSend = pendingMove else { return }
            pendingMove = nil
            withAnimation(.easeOut(duration: 0.18)) {
                isResolving = false
            }
            onMove(moveToSend)
        }
    }
}
