import PingoCore
import SwiftUI

struct PingoAnagramsPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var selectedIndices: [Int] = []
    @State private var isResolving = false
    @State private var rackPulse = false
    @State private var confirmationScale: CGFloat = 0.86
    @State private var resolutionMessage: String?

    var body: some View {
        let prompt = PingoExtraGameEngine.anagramPrompt(for: state)

        VStack(spacing: 12) {
            scoreStrip
            roundBanner

            VStack(spacing: 16) {
                Text("UNSCRAMBLE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2.2)
                    .foregroundStyle(.black.opacity(0.42))

                letterRack(prompt)
                    .scaleEffect(rackPulse ? 1.025 : 1)
                    .animation(.spring(response: 0.28, dampingFraction: 0.55), value: rackPulse)

                if let resolutionMessage {
                    HStack(spacing: 7) {
                        Image(systemName: "sparkles")
                        Text(resolutionMessage)
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color.pingoPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.88), in: Capsule())
                    .scaleEffect(confirmationScale)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Tap the letters in the order that spells your answer")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.42))
                        .multilineTextAlignment(.center)
                }

                if !state.lastSummary.isEmpty {
                    lastResult
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.97, blue: 0.89),
                        Color(red: 0.97, green: 0.89, blue: 0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        isResolving ? Color.pingoPrimary.opacity(0.55) : Color.white.opacity(0.88),
                        lineWidth: isResolving ? 2 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isResolving)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)

            answerBar(prompt)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .onChange(of: state.challengeIndex) { _ in
            selectedIndices.removeAll()
            isResolving = false
            resolutionMessage = nil
            rackPulse = false
        }
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            scoreChip(title: "YOU", score: score(player), highlighted: true)

            VStack(spacing: 2) {
                Text("ANAGRAMS")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("Unscramble the word before your rival")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }
            .frame(maxWidth: .infinity)

            scoreChip(title: "THEM", score: score(1 - player), highlighted: false)
        }
        .foregroundStyle(.black.opacity(0.78))
    }

    private func scoreChip(title: String, score: Int, highlighted: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.42))
            Text("\(score)")
                .font(.system(size: 22, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(highlighted ? Color.pingoPrimary : .black.opacity(0.68))
        }
        .frame(width: 58)
        .padding(.vertical, 6)
        .background(Color.white.opacity(highlighted ? 0.95 : 0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var roundBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: isResolving ? "hourglass.circle.fill" : "textformat.abc")
                .font(.caption.bold())
            Text(isResolving ? "CHECKING ANSWER" : "PUZZLE \(state.challengeIndex + 1)")
                .font(.caption2.weight(.black))
                .tracking(0.8)
            Spacer()
            Text("\(state.attempts.indices.contains(player) ? state.attempts[player] : 0) ATTEMPTS")
                .font(.caption2.weight(.black).monospacedDigit())
        }
        .foregroundStyle(isResolving ? Color.pingoPrimary : .black.opacity(0.54))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.58), in: Capsule())
        .animation(.easeInOut(duration: 0.2), value: isResolving)
    }

    private func letterRack(_ prompt: String) -> some View {
        let letters = Array(prompt.uppercased())
        return HStack(spacing: 7) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let selectionPosition = selectedIndices.firstIndex(of: index)
                Button {
                    guard canMove, !isResolving else { return }
                    if let selectionPosition {
                        if selectionPosition == selectedIndices.count - 1 {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                                selectedIndices.removeLast()
                            }
                        }
                    } else {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                            selectedIndices.append(index)
                        }
                    }
                } label: {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: selectionPosition == nil
                                        ? [Color.white, Color(red: 1.0, green: 0.93, blue: 0.78)]
                                        : [Color.pingoPrimary.opacity(0.92), Color.pingoPrimary.opacity(0.72)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(selectionPosition == nil ? Color.orange.opacity(0.18) : Color.white.opacity(0.8), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.09), radius: 3, y: 2)

                        Text(String(letter))
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(selectionPosition == nil ? .black.opacity(0.76) : .white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Text(selectionPosition.map { "\($0 + 1)" } ?? "")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(5)
                    }
                    .frame(maxWidth: 52)
                    .aspectRatio(0.82, contentMode: .fit)
                    .scaleEffect(selectionPosition == nil ? 1 : (isResolving ? 1.06 : 1.03))
                    .rotationEffect(.degrees(isResolving && selectionPosition != nil ? (index.isMultiple(of: 2) ? -2 : 2) : 0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selectionPosition)
                    .animation(.easeInOut(duration: 0.16).repeatCount(2, autoreverses: true), value: isResolving)
                }
                .buttonStyle(.plain)
                .disabled(!canMove || isResolving)
                .accessibilityLabel(selectionPosition == nil ? "Letter \(letter)" : "Letter \(letter), selected \((selectionPosition ?? 0) + 1)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var lastResult: some View {
        HStack(spacing: 8) {
            Image(systemName: state.lastScore > 0 ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
            Text(state.lastSummary)
                .lineLimit(2)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.black.opacity(0.56))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.64), in: Capsule())
    }

    @ViewBuilder
    private func answerBar(_ prompt: String) -> some View {
        if canMove {
            let letters = Array(prompt.uppercased())
            let answer = String(selectedIndices.compactMap { letters.indices.contains($0) ? letters[$0] : nil })

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        guard !isResolving else { return }
                        if !selectedIndices.isEmpty {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedIndices.removeLast()
                            }
                        }
                    } label: {
                        Image(systemName: "delete.left.fill")
                    }
                    .disabled(selectedIndices.isEmpty || isResolving)
                    .accessibilityLabel("Undo last letter")

                    Text(answer.isEmpty ? "TAP LETTERS" : answer)
                        .font(.headline.weight(.black))
                        .tracking(1.0)
                        .foregroundStyle(answer.isEmpty ? .black.opacity(0.28) : .black.opacity(0.74))
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())

                    Button {
                        guard !isResolving else { return }
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            selectedIndices.removeAll()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .disabled(selectedIndices.isEmpty || isResolving)
                    .accessibilityLabel("Clear answer")
                }
                .foregroundStyle(.black.opacity(0.52))
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(Color.white.opacity(0.92), in: Capsule())

                Button {
                    submit(answer)
                } label: {
                    Image(systemName: isResolving ? "sparkles" : "paperplane.fill")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 46)
                        .background(Color.pingoPrimary, in: Circle())
                        .scaleEffect(isResolving ? 1.08 : 1)
                        .animation(.easeInOut(duration: 0.18).repeatCount(2, autoreverses: true), value: isResolving)
                }
                .buttonStyle(.plain)
                .disabled(answer.isEmpty || isResolving)
                .accessibilityLabel(isResolving ? "Checking anagram answer" : "Submit anagram answer")
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                Text("Waiting for the next Anagrams turn")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.black.opacity(0.48))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white.opacity(0.56), in: Capsule())
        }
    }

    private func submit(_ answer: String) {
        guard canMove, !isResolving, !answer.isEmpty else { return }

        isResolving = true
        resolutionMessage = "ANSWER LOCKED"
        confirmationScale = 0.86

        withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) {
            rackPulse = true
            confirmationScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            onMove(.init(text: answer))
            selectedIndices.removeAll()
            withAnimation(.easeOut(duration: 0.18)) {
                rackPulse = false
                resolutionMessage = nil
                isResolving = false
            }
        }
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }
}
