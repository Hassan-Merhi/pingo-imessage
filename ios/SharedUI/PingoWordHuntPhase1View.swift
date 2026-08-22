import PingoCore
import SwiftUI

struct PingoWordHuntPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var word = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        let board = PingoExtraGameEngine.wordHuntBoard(for: state)

        VStack(spacing: 12) {
            scoreStrip
            challengeBanner

            VStack(spacing: 10) {
                boardGrid(board)

                if !state.usedWords.isEmpty {
                    usedWords
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.97, blue: 1.0),
                        Color(red: 0.86, green: 0.92, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
            .frame(maxHeight: .infinity)

            submitBar
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            scoreChip(title: "YOU", score: score(player), highlighted: true)

            VStack(spacing: 2) {
                Text("WORD HUNT")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("Find valid words in the 4×4 grid")
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

    private var challengeBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "character.book.closed.fill")
                .font(.caption.bold())
            Text("BOARD \(state.challengeIndex + 1)")
                .font(.caption2.weight(.black))
                .tracking(0.8)
            Spacer()
            Text("\(state.usedWords.count) FOUND")
                .font(.caption2.weight(.black).monospacedDigit())
        }
        .foregroundStyle(.black.opacity(0.54))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.58), in: Capsule())
    }

    private func boardGrid(_ board: PingoWordHuntBoard) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(board.letters.enumerated()), id: \.offset) { index, letter in
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color(red: 0.90, green: 0.94, blue: 1.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color.pingoPrimary.opacity(0.13), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)

                    Text(String(letter))
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.74))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text("\(index + 1)")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.18))
                        .padding(6)
                }
                .aspectRatio(1, contentMode: .fit)
                .accessibilityLabel("Letter \(letter), tile \(index + 1)")
            }
        }
    }

    private var usedWords: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(state.usedWords, id: \.self) { used in
                    Text(used.uppercased())
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.78), in: Capsule())
                        .foregroundStyle(.black.opacity(0.50))
                }
            }
        }
        .accessibilityLabel("Previously found words")
    }

    @ViewBuilder
    private var submitBar: some View {
        if canMove {
            HStack(spacing: 8) {
                TextField("ENTER WORD", text: $word)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.white.opacity(0.92), in: Capsule())

                Button {
                    let submitted = word.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !submitted.isEmpty else { return }
                    onMove(.init(text: submitted))
                    word = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 46)
                        .background(Color.pingoPrimary, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Submit word")
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                Text("Waiting for the next Word Hunt turn")
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
