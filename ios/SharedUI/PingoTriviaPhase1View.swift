import PingoCore
import SwiftUI

struct PingoTriviaPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    private var opponent: Int { 1 - player }

    private var question: PingoTriviaQuestion {
        PingoExtraGameEngine.triviaQuestion(for: state)
    }

    private var totalAttempts: Int {
        state.attempts.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 12) {
            scoreStrip
            questionCard
            answerGrid
            statusRibbon
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            scoreChip(label: "YOU", score: score(player), highlighted: canMove)

            VStack(spacing: 2) {
                Text("QUESTION")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.black.opacity(0.34))
                Text("\(min(10, totalAttempts + 1)) / 10")
                    .font(.system(size: 16, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.black.opacity(0.68))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            scoreChip(label: "RIVAL", score: score(opponent), highlighted: false)
        }
    }

    private var questionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.20, blue: 0.42),
                            Color(red: 0.26, green: 0.18, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.16), radius: 10, y: 5)

            VStack(spacing: 13) {
                HStack(spacing: 7) {
                    Image(systemName: "brain.head.profile")
                    Text("GENERAL KNOWLEDGE")
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.05)
                .foregroundStyle(.white.opacity(0.64))

                Text(question.prompt)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 18)

                HStack(spacing: 6) {
                    ForEach(0..<10, id: \.self) { index in
                        Capsule()
                            .fill(index < totalAttempts ? Color.white.opacity(0.72) : Color.white.opacity(0.16))
                            .frame(maxWidth: .infinity)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 176)
    }

    private var answerGrid: some View {
        VStack(spacing: 9) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    guard canMove else { return }
                    onMove(.init(primary: index))
                } label: {
                    HStack(spacing: 12) {
                        Text(letter(for: index))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(answerAccent(index), in: Circle())

                        Text(option)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(canMove ? 0.76 : 0.42))
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.black.opacity(canMove ? 0.22 : 0.10))
                    }
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.94), Color.white.opacity(0.72)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(canMove ? 0.08 : 0.03), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(!canMove)
            }
        }
    }

    @ViewBuilder
    private var statusRibbon: some View {
        if !state.lastSummary.isEmpty {
            HStack(spacing: 7) {
                Image(systemName: state.lastScore > 0 ? "checkmark.seal.fill" : "questionmark.circle.fill")
                Text(state.lastSummary.uppercased())
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(.black.opacity(0.46))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.white.opacity(0.48), in: Capsule())
        } else {
            Text(canMove ? "CHOOSE YOUR ANSWER" : "WAITING FOR THE NEXT TURN")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(.black.opacity(0.34))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func scoreChip(label: String, score: Int, highlighted: Bool) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.black.opacity(0.34))
            Text("\(score)")
                .font(.system(size: 24, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.72))
        }
        .frame(width: 76)
        .padding(.vertical, 7)
        .background(highlighted ? Color.pingoPrimary.opacity(0.16) : Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func letter(for index: Int) -> String {
        String(Character(UnicodeScalar(65 + index)!))
    }

    private func answerAccent(_ index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.39, green: 0.29, blue: 0.80)
        case 1: return Color(red: 0.12, green: 0.53, blue: 0.72)
        case 2: return Color(red: 0.88, green: 0.43, blue: 0.20)
        default: return Color(red: 0.34, green: 0.65, blue: 0.34)
        }
    }
}
