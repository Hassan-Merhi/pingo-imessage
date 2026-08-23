import PingoCore
import SwiftUI

struct PingoReactionBattlePhase3View: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isResolvingReaction = false
    @State private var feedbackScale = 0.72
    @State private var feedbackOpacity = 0.0
    @State private var ringExpansion = 0.55
    @State private var pendingMove: PingoExtraGameMove?

    var body: some View {
        ZStack {
            PingoReactionBattlePhase1View(
                match: match,
                localProfile: localProfile,
                state: state,
                canMove: canMove && !isResolvingReaction,
                onMove: intercept
            )
            .allowsHitTesting(!isResolvingReaction)

            if isResolvingReaction, let pendingMove {
                feedbackOverlay(milliseconds: pendingMove.primary)
                    .transition(.opacity)
                    .zIndex(4)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isResolvingReaction)
        .onChange(of: match.revision) { _ in
            resetFeedback()
        }
    }

    private func intercept(_ move: PingoExtraGameMove) {
        guard !isResolvingReaction else { return }

        pendingMove = move
        isResolvingReaction = true
        feedbackScale = 0.72
        feedbackOpacity = 0
        ringExpansion = 0.55

        withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) {
            feedbackScale = 1
            feedbackOpacity = 1
            ringExpansion = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            guard let pendingMove else {
                resetFeedback()
                return
            }
            onMove(pendingMove)
            withAnimation(.easeOut(duration: 0.16)) {
                feedbackOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                resetFeedback()
            }
        }
    }

    private func feedbackOverlay(milliseconds: Int) -> some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.34)

                Circle()
                    .stroke(feedbackColor(milliseconds: milliseconds).opacity(0.55), lineWidth: 4)
                    .frame(width: 170, height: 170)
                    .scaleEffect(ringExpansion)
                    .opacity(feedbackOpacity)

                Circle()
                    .fill(feedbackColor(milliseconds: milliseconds).opacity(0.14))
                    .frame(width: 132, height: 132)
                    .scaleEffect(feedbackScale)

                VStack(spacing: 7) {
                    Image(systemName: feedbackIcon(milliseconds: milliseconds))
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(feedbackColor(milliseconds: milliseconds))

                    Text("\(milliseconds) ms")
                        .font(.system(size: 34, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)

                    Text(feedbackTitle(milliseconds: milliseconds))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(feedbackColor(milliseconds: milliseconds))

                    Text("RESULT LOCKED • SENDING TURN")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(.white.opacity(0.68))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(feedbackColor(milliseconds: milliseconds).opacity(0.35), lineWidth: 1)
                )
                .scaleEffect(feedbackScale)
                .opacity(feedbackOpacity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reaction time \(milliseconds) milliseconds. \(feedbackTitle(milliseconds: milliseconds)).")
    }

    private func feedbackTitle(milliseconds: Int) -> String {
        switch milliseconds {
        case ..<180:
            return "LIGHTNING FAST"
        case 180..<250:
            return "SHARP REACTION"
        case 250..<350:
            return "SOLID RESPONSE"
        default:
            return "REACTION LOGGED"
        }
    }

    private func feedbackIcon(milliseconds: Int) -> String {
        milliseconds < 250 ? "bolt.fill" : milliseconds < 350 ? "timer" : "checkmark.circle.fill"
    }

    private func feedbackColor(milliseconds: Int) -> Color {
        if milliseconds < 180 { return .yellow }
        if milliseconds < 250 { return .green }
        if milliseconds < 350 { return .cyan }
        return .white
    }

    private func resetFeedback() {
        isResolvingReaction = false
        feedbackScale = 0.72
        feedbackOpacity = 0
        ringExpansion = 0.55
        pendingMove = nil
    }
}
