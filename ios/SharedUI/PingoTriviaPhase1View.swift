import PingoCore
import SwiftUI

struct PingoTriviaPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var selectedAnswer: Int?
    @State private var isDragging = false

    private let answerRowHeight: CGFloat = 58
    private let answerSpacing: CGFloat = 9

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
        .onChange(of: totalAttempts) { _ in
            selectedAnswer = nil
            isDragging = false
        }
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
                    Image(systemName: "hand.point.up.left.fill")
                    Text("PRESS, SLIDE & RELEASE")
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
        VStack(spacing: answerSpacing) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                answerRow(index: index, option: option)
            }
        }
        .contentShape(Rectangle())
        .gesture(answerDragGesture)
        .accessibilityHint("Tap an answer, or press and slide through the choices then release to submit")
    }

    private func answerRow(index: Int, option: String) -> some View {
        let isSelected = selectedAnswer == index

        return Button {
            submit(index)
        } label: {
            HStack(spacing: 12) {
                Text(letter(for: index))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(answerAccent(index), in: Circle())
                    .scaleEffect(isSelected ? 1.08 : 1)

                Text(option)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(canMove ? 0.76 : 0.42))
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(isSelected ? answerAccent(index) : .black.opacity(canMove ? 0.14 : 0.07))
            }
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
            .frame(height: answerRowHeight)
            .background(
                LinearGradient(
                    colors: isSelected
                        ? [answerAccent(index).opacity(0.20), Color.white.opacity(0.92)]
                        : [Color.white.opacity(0.94), Color.white.opacity(0.72)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? answerAccent(index).opacity(0.62) : .black.opacity(0.06), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: .black.opacity(isSelected ? 0.12 : (canMove ? 0.08 : 0.03)), radius: 4, y: 2)
            .scaleEffect(isSelected ? 1.015 : 1)
            .animation(.easeOut(duration: 0.12), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(!canMove)
    }

    private var answerDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard canMove else { return }
                isDragging = true
                selectedAnswer = answerIndex(for: value.location.y)
            }
            .onEnded { value in
                guard canMove else {
                    selectedAnswer = nil
                    isDragging = false
                    return
                }

                let index = answerIndex(for: value.location.y)
                isDragging = false
                selectedAnswer = index
                submit(index)
            }
    }

    @ViewBuilder
    private var statusRibbon: some View {
        if let selectedAnswer, isDragging, canMove {
            HStack(spacing: 7) {
                Image(systemName: "hand.draw.fill")
                Text("RELEASE FOR \(letter(for: selectedAnswer))")
            }
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(answerAccent(selectedAnswer))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(answerAccent(selectedAnswer).opacity(0.10), in: Capsule())
        } else if !state.lastSummary.isEmpty {
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
            Text(canMove ? "PRESS AN ANSWER • SLIDE TO CHANGE • RELEASE TO LOCK" : "WAITING FOR THE NEXT TURN")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.black.opacity(0.34))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    private func submit(_ index: Int) {
        guard canMove, question.options.indices.contains(index) else { return }
        selectedAnswer = index
        onMove(.init(primary: index))
    }

    private func answerIndex(for y: CGFloat) -> Int {
        let stride = answerRowHeight + answerSpacing
        let rawIndex = Int(max(0, y) / stride)
        return min(max(rawIndex, 0), max(question.options.count - 1, 0))
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
