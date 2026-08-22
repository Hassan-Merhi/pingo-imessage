import PingoCore
import SwiftUI

struct PingoWordHuntPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var selectedIndices: [Int] = []

    private let gridSpacing: CGFloat = 8

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

            submitBar(board)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .onChange(of: state.challengeIndex) { _ in
            selectedIndices = []
        }
        .onChange(of: canMove) { newValue in
            if !newValue {
                selectedIndices = []
            }
        }
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            scoreChip(title: "YOU", score: score(player), highlighted: true)

            VStack(spacing: 2) {
                Text("WORD HUNT")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("Trace letters on the 4×4 grid")
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
            Image(systemName: "hand.draw.fill")
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
        GeometryReader { proxy in
            let tileSize = max(1, (proxy.size.width - gridSpacing * 3) / 4)

            ZStack(alignment: .topLeading) {
                ForEach(Array(board.letters.enumerated()), id: \.offset) { index, letter in
                    let row = index / 4
                    let column = index % 4
                    let isSelected = selectedIndices.contains(index)
                    let selectionOrder = selectedIndices.firstIndex(of: index)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: isSelected
                                        ? [Color.pingoPrimary.opacity(0.95), Color.pingoPrimary.opacity(0.72)]
                                        : [Color.white, Color(red: 0.90, green: 0.94, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(
                                        isSelected ? Color.white.opacity(0.9) : Color.pingoPrimary.opacity(0.13),
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            }
                            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 5 : 3, y: 2)

                        Text(String(letter))
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(isSelected ? .white : .black.opacity(0.74))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if let selectionOrder {
                            Text("\(selectionOrder + 1)")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(Color.pingoPrimary)
                                .frame(width: 18, height: 18)
                                .background(Color.white.opacity(0.95), in: Circle())
                                .padding(5)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 7, weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.18))
                                .padding(6)
                        }
                    }
                    .frame(width: tileSize, height: tileSize)
                    .offset(
                        x: CGFloat(column) * (tileSize + gridSpacing),
                        y: CGFloat(row) * (tileSize + gridSpacing)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectTile(index)
                    }
                    .accessibilityLabel("Letter \(letter), tile \(index + 1)\(isSelected ? ", selected" : "")")
                    .accessibilityHint(canMove ? "Tap to add this letter to your word" : "Waiting for your turn")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.width)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        guard canMove,
                              let index = tileIndex(at: value.location, width: proxy.size.width)
                        else { return }
                        selectTile(index)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
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
    private func submitBar(_ board: PingoWordHuntBoard) -> some View {
        if canMove {
            let word = selectedWord(board)
            let canonical = word.lowercased()
            let isValid = board.acceptedWords.contains(canonical) && !state.usedWords.contains(canonical)

            VStack(spacing: 7) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(word.isEmpty ? "TRACE A WORD" : word)
                            .font(.headline.weight(.black))
                            .foregroundStyle(word.isEmpty ? .black.opacity(0.35) : .black.opacity(0.78))
                            .lineLimit(1)

                        Text(word.isEmpty ? "Drag across letters or tap them in order" : (isValid ? "Valid word — ready to send" : "Keep tracing a valid board word"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isValid ? Color.pingoPrimary : .black.opacity(0.38))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        selectedIndices = []
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline.bold())
                            .frame(width: 42, height: 42)
                            .background(Color.black.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black.opacity(0.55))
                    .disabled(selectedIndices.isEmpty)
                    .accessibilityLabel("Clear selected word")

                    Button {
                        guard isValid else { return }
                        onMove(.init(text: word))
                        selectedIndices = []
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 46)
                            .background(isValid ? Color.pingoPrimary : Color.black.opacity(0.16), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                    .accessibilityLabel("Submit selected word")
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 54)
                .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

    private func selectTile(_ index: Int) {
        guard canMove, (0..<16).contains(index) else { return }
        if selectedIndices.last == index { return }

        if let existing = selectedIndices.firstIndex(of: index) {
            selectedIndices = Array(selectedIndices.prefix(existing + 1))
        } else {
            selectedIndices.append(index)
        }
    }

    private func tileIndex(at location: CGPoint, width: CGFloat) -> Int? {
        guard location.x >= 0, location.y >= 0, location.x <= width, location.y <= width else { return nil }
        let tileSize = max(1, (width - gridSpacing * 3) / 4)
        let stride = tileSize + gridSpacing
        let column = Int(location.x / stride)
        let row = Int(location.y / stride)
        guard (0..<4).contains(column), (0..<4).contains(row) else { return nil }

        let localX = location.x - CGFloat(column) * stride
        let localY = location.y - CGFloat(row) * stride
        guard localX <= tileSize, localY <= tileSize else { return nil }
        return row * 4 + column
    }

    private func selectedWord(_ board: PingoWordHuntBoard) -> String {
        selectedIndices.compactMap { index in
            board.letters.indices.contains(index) ? String(board.letters[index]) : nil
        }.joined().uppercased()
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }
}
