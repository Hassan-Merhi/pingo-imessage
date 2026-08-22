import PingoCore
import SwiftUI

struct PingoAnagramsPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var answer = ""

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

                Text("Rearrange every letter to solve the word")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
                    .multilineTextAlignment(.center)

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
                    .stroke(Color.white.opacity(0.88), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)

            answerBar
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
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
            Image(systemName: "textformat.abc")
                .font(.caption.bold())
            Text("PUZZLE \(state.challengeIndex + 1)")
                .font(.caption2.weight(.black))
                .tracking(0.8)
            Spacer()
            Text("\(state.attempts.indices.contains(player) ? state.attempts[player] : 0) ATTEMPTS")
                .font(.caption2.weight(.black).monospacedDigit())
        }
        .foregroundStyle(.black.opacity(0.54))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.58), in: Capsule())
    }

    private func letterRack(_ prompt: String) -> some View {
        let letters = Array(prompt.uppercased())
        return HStack(spacing: 7) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(red: 1.0, green: 0.93, blue: 0.78)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.09), radius: 3, y: 2)

                    Text(String(letter))
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.76))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text("\(index + 1)")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.16))
                        .padding(5)
                }
                .frame(maxWidth: 52)
                .aspectRatio(0.82, contentMode: .fit)
                .accessibilityLabel("Letter \(letter), tile \(index + 1)")
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
    private var answerBar: some View {
        if canMove {
            HStack(spacing: 8) {
                TextField("TYPE YOUR ANSWER", text: $answer)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.92), in: Capsule())

                Button {
                    let submitted = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !submitted.isEmpty else { return }
                    onMove(.init(text: submitted))
                    answer = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 46)
                        .background(Color.pingoPrimary, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Submit anagram answer")
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

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }
}
