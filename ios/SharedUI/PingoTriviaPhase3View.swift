import PingoCore
import SwiftUI

struct PingoTriviaPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var resolvingAnswer: Int?
    @State private var feedbackScale: CGFloat = 0.88
    @State private var feedbackOpacity: Double = 0

    private var isResolving: Bool { resolvingAnswer != nil }

    var body: some View {
        ZStack {
            PingoTriviaPhase1View(
                state: state,
                player: player,
                canMove: canMove && !isResolving,
                onMove: resolve
            )
            .scaleEffect(isResolving ? 0.992 : 1)
            .animation(.easeOut(duration: 0.16), value: isResolving)

            if let answer = resolvingAnswer {
                feedbackOverlay(answer: answer)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onChange(of: state.attempts.reduce(0, +)) { _ in
            resolvingAnswer = nil
            feedbackOpacity = 0
            feedbackScale = 0.88
        }
    }

    private func resolve(_ move: PingoExtraGameMove) {
        guard canMove, !isResolving else { return }
        let answer = move.primary

        resolvingAnswer = answer
        feedbackScale = 0.88
        feedbackOpacity = 0

        withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
            feedbackScale = 1
            feedbackOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            guard resolvingAnswer == answer else { return }
            onMove(move)
        }
    }

    private func feedbackOverlay(answer: Int) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent(answer).opacity(0.18))
                    .frame(width: 88, height: 88)
                    .scaleEffect(feedbackScale * 1.08)

                Circle()
                    .fill(accent(answer))
                    .frame(width: 62, height: 62)
                    .shadow(color: accent(answer).opacity(0.34), radius: 12, y: 5)

                Text(letter(for: answer))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("ANSWER LOCKED")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(.black.opacity(0.78))

            Text("Checking your answer…")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.44))
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
        .accessibilityLabel("Answer locked. Checking answer.")
    }

    private func letter(for index: Int) -> String {
        guard (0..<26).contains(index), let scalar = UnicodeScalar(65 + index) else { return "?" }
        return String(Character(scalar))
    }

    private func accent(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.39, green: 0.29, blue: 0.80)
        case 1: return Color(red: 0.12, green: 0.53, blue: 0.72)
        case 2: return Color(red: 0.88, green: 0.43, blue: 0.20)
        default: return Color(red: 0.34, green: 0.65, blue: 0.34)
        }
    }
}
