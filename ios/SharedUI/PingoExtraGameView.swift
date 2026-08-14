import PingoCore
import SwiftUI

struct PingoExtraGameView: View {
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoExtraGameMove) -> Void

    private var state: PingoExtraGameState? {
        try? PingoExtraGameEngine.state(from: match.gameState, gameID: match.gameID, matchID: match.id)
    }

    private var playerIndex: Int? {
        match.players.firstIndex(where: { $0.id == localProfile.id })
    }

    private var canMove: Bool {
        match.status == .active && match.currentPlayerID == localProfile.id && playerIndex != nil
    }

    var body: some View {
        VStack(spacing: 14) {
            if let state {
                PingoExtraScoreHeader(match: match, state: state)
                PingoExtraLastResult(state: state)
                controls(state: state)
            } else {
                Text("This game state could not be opened.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func controls(state: PingoExtraGameState) -> some View {
        if !canMove {
            Text(match.status == .active ? "Waiting for your opponent's move." : "Final game state")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let playerIndex {
            switch match.gameID {
            case .bowling:
                PingoAimPowerControl(
                    title: "Line up your roll",
                    primaryLabel: "Aim",
                    secondaryLabel: "Power",
                    primaryRange: 0...100,
                    secondaryRange: 0...100,
                    primaryDefault: 50,
                    secondaryDefault: 82,
                    buttonTitle: "Roll",
                    onSubmit: { onMove(.init(primary: $0, secondary: $1)) }
                )
            case .penaltyShootout:
                PingoPenaltyControl(onMove: onMove)
            case .archery:
                PingoAimPowerControl(
                    title: "Aim at the target",
                    primaryLabel: "Horizontal",
                    secondaryLabel: "Vertical",
                    primaryRange: 0...100,
                    secondaryRange: 0...100,
                    primaryDefault: 50,
                    secondaryDefault: 50,
                    buttonTitle: "Shoot Arrow",
                    onSubmit: { onMove(.init(primary: $0, secondary: $1)) }
                )
            case .airHockey:
                PingoAimPowerControl(
                    title: "Shoot the puck",
                    primaryLabel: "Lane",
                    secondaryLabel: "Power",
                    primaryRange: 0...100,
                    secondaryRange: 0...100,
                    primaryDefault: 50,
                    secondaryDefault: 75,
                    buttonTitle: "Shoot Puck",
                    onSubmit: { onMove(.init(primary: $0, secondary: $1)) }
                )
            case .miniRacing:
                PingoAimPowerControl(
                    title: "Set your racing input",
                    primaryLabel: "Throttle",
                    secondaryLabel: "Steering",
                    primaryRange: 0...100,
                    secondaryRange: 0...100,
                    primaryDefault: 82,
                    secondaryDefault: 50,
                    buttonTitle: "Race Turn",
                    onSubmit: { onMove(.init(primary: $0, secondary: $1)) }
                )
            case .reactionBattle:
                PingoReactionControl(state: state, onMove: onMove)
            case .drawAndGuess:
                PingoDrawGuessControl(state: state, onMove: onMove)
            case .wordHunt:
                PingoWordHuntControl(state: state, onMove: onMove)
            case .anagrams:
                PingoAnagramControl(state: state, onMove: onMove)
            case .trivia:
                PingoTriviaControl(state: state, onMove: onMove)
            case .crazyEights:
                PingoCrazyEightsControl(state: state, playerIndex: playerIndex, onMove: onMove)
            case .ludo:
                PingoLudoControl(state: state, playerIndex: playerIndex, onMove: onMove)
            default:
                Text("This Wave 6 game is not available here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PingoExtraScoreHeader: View {
    let match: PingoMatchEnvelope
    let state: PingoExtraGameState

    var body: some View {
        HStack(spacing: 12) {
            score(player: 0)
            Text("VS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            score(player: 1)
        }
    }

    private func score(player: Int) -> some View {
        VStack(spacing: 2) {
            Text(match.players.indices.contains(player) ? "@\(match.players[player].displayName)" : "Player")
                .font(.caption)
                .lineLimit(1)
            Text("\(state.scores.indices.contains(player) ? state.scores[player] : 0)")
                .font(.title2.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PingoExtraLastResult: View {
    let state: PingoExtraGameState

    var body: some View {
        if !state.lastSummary.isEmpty {
            Text(state.lastSummary)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.pingoPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.pingoPrimary.opacity(0.08), in: Capsule())
        }
    }
}

private struct PingoAimPowerControl: View {
    let title: String
    let primaryLabel: String
    let secondaryLabel: String
    let primaryRange: ClosedRange<Double>
    let secondaryRange: ClosedRange<Double>
    let primaryDefault: Double
    let secondaryDefault: Double
    let buttonTitle: String
    let onSubmit: (Int, Int) -> Void

    @State private var primary: Double
    @State private var secondary: Double

    init(
        title: String,
        primaryLabel: String,
        secondaryLabel: String,
        primaryRange: ClosedRange<Double>,
        secondaryRange: ClosedRange<Double>,
        primaryDefault: Double,
        secondaryDefault: Double,
        buttonTitle: String,
        onSubmit: @escaping (Int, Int) -> Void
    ) {
        self.title = title
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
        self.primaryRange = primaryRange
        self.secondaryRange = secondaryRange
        self.primaryDefault = primaryDefault
        self.secondaryDefault = secondaryDefault
        self.buttonTitle = buttonTitle
        self.onSubmit = onSubmit
        _primary = State(initialValue: primaryDefault)
        _secondary = State(initialValue: secondaryDefault)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            slider(label: primaryLabel, value: $primary, range: primaryRange)
            slider(label: secondaryLabel, value: $secondary, range: secondaryRange)
            Button(buttonTitle) {
                onSubmit(Int(primary.rounded()), Int(secondary.rounded()))
            }
            .buttonStyle(.borderedProminent)
            .tint(.pingoPrimary)
            .frame(maxWidth: .infinity)
        }
    }

    private func slider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(value.wrappedValue.rounded()))")
                    .font(.caption.monospacedDigit())
            }
            Slider(value: value, in: range, step: 1)
                .tint(.pingoPrimary)
        }
    }
}

private struct PingoPenaltyControl: View {
    let onMove: (PingoExtraGameMove) -> Void
    @State private var lane = 2
    @State private var power = 75.0

    var body: some View {
        VStack(spacing: 10) {
            Text("Pick a corner and power").font(.headline)
            Picker("Target", selection: $lane) {
                Text("↙︎").tag(0)
                Text("⬅︎").tag(1)
                Text("⬆︎").tag(2)
                Text("➡︎").tag(3)
                Text("↘︎").tag(4)
            }
            .pickerStyle(.segmented)
            HStack {
                Text("Power").font(.caption.weight(.semibold))
                Slider(value: $power, in: 0...100, step: 1).tint(.pingoPrimary)
                Text("\(Int(power))").font(.caption.monospacedDigit())
            }
            Button("Take Penalty") { onMove(.init(primary: lane, secondary: Int(power))) }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        }
    }
}

private struct PingoReactionControl: View {
    let state: PingoExtraGameState
    let onMove: (PingoExtraGameMove) -> Void
    @State private var phase = 0
    @State private var readyAt: Date?

    var body: some View {
        VStack(spacing: 12) {
            Text("Reaction Battle").font(.headline)
            if phase == 0 {
                Text("Start, then tap only when GO appears.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Start Reaction") { start() }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
            } else if phase == 1 {
                ProgressView()
                Text("Get ready…").font(.subheadline.weight(.semibold))
            } else {
                Button("GO — TAP!") { finish() }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
                    .font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func start() {
        phase = 1
        readyAt = nil
        let delay = PingoExtraGameEngine.reactionDelayMilliseconds(for: state)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) / 1000.0) {
            readyAt = Date()
            phase = 2
        }
    }

    private func finish() {
        guard let readyAt else { return }
        let measured = Int(Date().timeIntervalSince(readyAt) * 1000.0)
        let clamped = min(1_500, max(80, measured))
        phase = 0
        self.readyAt = nil
        onMove(.init(primary: clamped))
    }
}

private struct PingoDrawGuessControl: View {
    let state: PingoExtraGameState
    let onMove: (PingoExtraGameMove) -> Void
    @State private var drawing: [PingoExtraPoint] = []
    @State private var guess = ""

    var body: some View {
        VStack(spacing: 10) {
            if state.phase == 0 {
                Text("Draw: \(PingoExtraGameEngine.drawPrompt(for: state).uppercased())")
                    .font(.headline)
                PingoDrawingPad(points: $drawing)
                HStack {
                    Button("Clear") { drawing.removeAll() }
                        .buttonStyle(.bordered)
                    Button("Send Drawing") {
                        onMove(.init(points: drawing))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
                    .disabled(drawing.count < 2)
                }
            } else {
                Text("Guess the drawing").font(.headline)
                PingoDrawingPreview(points: state.drawing)
                TextField("Your guess", text: $guess)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                Button("Send Guess") { onMove(.init(text: guess)) }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
                    .disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct PingoDrawingPad: View {
    @Binding var points: [PingoExtraPoint]

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.stroke(path(points: points, size: size), with: .color(.primary), lineWidth: 3)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard points.count < 160 else { return }
                        let x = min(1000, max(0, Int(value.location.x / max(1, proxy.size.width) * 1000)))
                        let y = min(1000, max(0, Int(value.location.y / max(1, proxy.size.height) * 1000)))
                        points.append(.init(x: x, y: y))
                    }
            )
        }
        .frame(height: 180)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func path(points: [PingoExtraPoint], size: CGSize) -> Path {
        PingoDrawingPath.make(points: points, size: size)
    }
}

private struct PingoDrawingPreview: View {
    let points: [PingoExtraPoint]

    var body: some View {
        Canvas { context, size in
            context.stroke(PingoDrawingPath.make(points: points, size: size), with: .color(.primary), lineWidth: 3)
        }
        .frame(height: 180)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

private enum PingoDrawingPath {
    static func make(points: [PingoExtraPoint], size: CGSize) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: CGFloat(first.x) / 1000 * size.width, y: CGFloat(first.y) / 1000 * size.height))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: CGFloat(point.x) / 1000 * size.width, y: CGFloat(point.y) / 1000 * size.height))
        }
        return path
    }
}

private struct PingoWordHuntControl: View {
    let state: PingoExtraGameState
    let onMove: (PingoExtraGameMove) -> Void
    @State private var word = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        let board = PingoExtraGameEngine.wordHuntBoard(for: state)
        VStack(spacing: 10) {
            Text("Find a word").font(.headline)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(board.letters.enumerated()), id: \.offset) { _, letter in
                    Text(String(letter))
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Color.pingoPrimary.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            if !state.usedWords.isEmpty {
                Text("Used: \(state.usedWords.map { $0.uppercased() }.joined(separator: " • "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            TextField("Word", text: $word)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
            Button("Submit Word") { onMove(.init(text: word)) }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

private struct PingoAnagramControl: View {
    let state: PingoExtraGameState
    let onMove: (PingoExtraGameMove) -> Void
    @State private var answer = ""

    var body: some View {
        VStack(spacing: 10) {
            Text("Unscramble").font(.headline)
            Text(PingoExtraGameEngine.anagramPrompt(for: state))
                .font(.title.bold().monospaced())
                .kerning(4)
            TextField("Answer", text: $answer)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
            Button("Submit Answer") { onMove(.init(text: answer)) }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
                .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

private struct PingoTriviaControl: View {
    let state: PingoExtraGameState
    let onMove: (PingoExtraGameMove) -> Void

    var body: some View {
        let question = PingoExtraGameEngine.triviaQuestion(for: state)
        VStack(alignment: .leading, spacing: 10) {
            Text(question.prompt).font(.headline)
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    onMove(.init(primary: index))
                } label: {
                    Text(option)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct PingoCrazyEightsControl: View {
    let state: PingoExtraGameState
    let playerIndex: Int
    let onMove: (PingoExtraGameMove) -> Void

    var body: some View {
        let localHand = state.hands.indices.contains(playerIndex) ? state.hands[playerIndex] : []
        let opponent = 1 - playerIndex
        let opponentCount = state.hands.indices.contains(opponent) ? state.hands[opponent].count : 0
        VStack(spacing: 10) {
            HStack {
                Text("Top: \(PingoExtraGameEngine.cardLabel(state.topCard))")
                    .font(.title3.bold())
                Spacer()
                Text("Opponent: \(opponentCount) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(localHand, id: \.self) { card in
                        Button(PingoExtraGameEngine.cardLabel(card)) {
                            onMove(.init(primary: card))
                        }
                        .buttonStyle(.bordered)
                        .disabled(!PingoExtraGameEngine.isPlayableCard(card, on: state.topCard))
                    }
                }
            }
            Button("Draw Card") { onMove(.init(primary: -1)) }
                .buttonStyle(.borderedProminent)
                .tint(.pingoPrimary)
        }
    }
}

private struct PingoLudoControl: View {
    let state: PingoExtraGameState
    let playerIndex: Int
    let onMove: (PingoExtraGameMove) -> Void

    var body: some View {
        let die = PingoExtraGameEngine.ludoDie(for: state)
        let pieces = state.positions.indices.contains(playerIndex) ? state.positions[playerIndex] : [-1, -1]
        let legal = pieces.indices.filter { index in
            let position = pieces[index]
            return position < 24 && (position >= 0 || die == 6)
        }
        VStack(spacing: 10) {
            Text("🎲 \(die)").font(.system(size: 40, weight: .bold))
            Text("Rolls are deterministic for the shared match state.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(pieces.indices, id: \.self) { index in
                    Button("Piece \(index + 1) • \(positionText(pieces[index]))") {
                        onMove(.init(primary: index))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!legal.contains(index))
                }
            }
            if legal.isEmpty {
                Button("No Move — Pass") { onMove(.init(primary: -1)) }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
            }
        }
    }

    private func positionText(_ position: Int) -> String {
        if position < 0 { return "Yard" }
        if position >= 24 { return "Home" }
        return "\(position)/24"
    }
}
