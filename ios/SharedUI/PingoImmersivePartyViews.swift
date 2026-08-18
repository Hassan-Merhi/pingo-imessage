import PingoCore
import SwiftUI

struct PingoImmersivePartyView: View {
    let gameID: PingoGameID
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    var body: some View {
        VStack(spacing: 12) {
            header

            Group {
                switch gameID {
                case .reactionBattle:
                    PingoImmersiveReactionView(state: state, canMove: canMove, onMove: onMove)
                case .drawAndGuess:
                    PingoImmersiveDrawGuessView(state: state, canMove: canMove, onMove: onMove)
                case .wordHunt:
                    PingoImmersiveWordHuntView(state: state, canMove: canMove, onMove: onMove)
                case .anagrams:
                    PingoImmersiveAnagramView(state: state, canMove: canMove, onMove: onMove)
                case .trivia:
                    PingoImmersiveTriviaView(state: state, canMove: canMove, onMove: onMove)
                case .crazyEights:
                    PingoImmersiveCrazyEightsView(state: state, player: player, canMove: canMove, onMove: onMove)
                case .ludo:
                    PingoImmersiveLudoView(state: state, player: player, canMove: canMove, onMove: onMove)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.42))
            }
            Spacer()
            if gameID != .crazyEights && gameID != .ludo {
                Text("\(score(player))  –  \(score(1 - player))")
                    .font(.title2.bold().monospacedDigit())
            }
        }
        .foregroundStyle(.black.opacity(0.72))
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private var title: String {
        switch gameID {
        case .reactionBattle: return "REACTION BATTLE"
        case .drawAndGuess: return "DRAW & GUESS"
        case .wordHunt: return "WORD HUNT"
        case .anagrams: return "ANAGRAMS"
        case .trivia: return "TRIVIA"
        case .crazyEights: return "CRAZY EIGHTS"
        case .ludo: return "LUDO"
        default: return "PINGO"
        }
    }

    private var subtitle: String {
        switch gameID {
        case .reactionBattle: return "Fastest reactions win"
        case .drawAndGuess: return state.phase == 0 ? "Draw the prompt" : "Guess the drawing"
        case .wordHunt: return "Find words in the grid"
        case .anagrams: return "Unscramble the letters"
        case .trivia: return "Pick the correct answer"
        case .crazyEights: return "Match suit or rank"
        case .ludo: return "Race both pieces home"
        default: return "Your turn"
        }
    }
}

private struct PingoImmersiveReactionView: View {
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var phase = 0
    @State private var readyAt: Date?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.18), radius: 9, y: 4)

            VStack(spacing: 18) {
                Image(systemName: phase == 2 ? "bolt.fill" : "hand.tap.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white.opacity(0.94))

                Text(mainText)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if canMove {
                    Button(action: action) {
                        Text(buttonText)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(phase == 2 ? Color.black : .white)
                            .frame(maxWidth: 230)
                            .frame(height: 54)
                            .background(phase == 2 ? Color.white : Color.black.opacity(0.24), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(phase == 1)
                }

                if !state.lastSummary.isEmpty {
                    Text(state.lastSummary)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.66))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backgroundColor: Color {
        if phase == 2 { return Color(red: 0.28, green: 0.78, blue: 0.32) }
        if phase == 1 { return Color(red: 0.88, green: 0.35, blue: 0.20) }
        return Color(red: 0.40, green: 0.32, blue: 0.78)
    }

    private var mainText: String {
        switch phase {
        case 1: return "WAIT…"
        case 2: return "GO!"
        default: return "READY?"
        }
    }

    private var buttonText: String {
        switch phase {
        case 1: return "Get ready"
        case 2: return "TAP NOW"
        default: return "Start"
        }
    }

    private func action() {
        if phase == 0 {
            phase = 1
            readyAt = nil
            let delay = PingoExtraGameEngine.reactionDelayMilliseconds(for: state)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) / 1000.0) {
                guard phase == 1 else { return }
                readyAt = Date()
                phase = 2
            }
        } else if phase == 2, let readyAt {
            let measured = Int(Date().timeIntervalSince(readyAt) * 1000.0)
            let clamped = min(1_500, max(80, measured))
            phase = 0
            self.readyAt = nil
            onMove(.init(primary: clamped))
        }
    }
}

private struct PingoImmersiveDrawGuessView: View {
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var drawing: [PingoExtraPoint] = []
    @State private var guess = ""

    var body: some View {
        VStack(spacing: 12) {
            if state.phase == 0 {
                Text(PingoExtraGameEngine.drawPrompt(for: state).uppercased())
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.70))

                PingoImmersiveDrawingPad(points: $drawing, enabled: canMove)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if canMove {
                    HStack(spacing: 10) {
                        Button("Clear") { drawing.removeAll() }
                            .buttonStyle(.bordered)

                        Button {
                            onMove(.init(points: drawing))
                        } label: {
                            Label("Send Drawing", systemImage: "paperplane.fill")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.pingoPrimary)
                        .disabled(drawing.count < 2)
                    }
                }
            } else {
                PingoImmersiveDrawingPreview(points: state.drawing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if canMove {
                    HStack(spacing: 8) {
                        TextField("Your guess", text: $guess)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)

                        Button {
                            onMove(.init(text: guess))
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 38)
                                .background(Color.pingoPrimary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

private struct PingoImmersiveDrawingPad: View {
    @Binding var points: [PingoExtraPoint]
    let enabled: Bool

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                context.stroke(PingoImmersiveDrawingPath.make(points: points, size: size), with: .color(.black), lineWidth: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.black.opacity(0.10), lineWidth: 1) }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard enabled, points.count < 160 else { return }
                        let x = min(1000, max(0, Int(value.location.x / max(1, proxy.size.width) * 1000)))
                        let y = min(1000, max(0, Int(value.location.y / max(1, proxy.size.height) * 1000)))
                        points.append(.init(x: x, y: y))
                    }
            )
        }
    }
}

private struct PingoImmersiveDrawingPreview: View {
    let points: [PingoExtraPoint]

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            context.stroke(PingoImmersiveDrawingPath.make(points: points, size: size), with: .color(.black), lineWidth: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.black.opacity(0.10), lineWidth: 1) }
    }
}

private enum PingoImmersiveDrawingPath {
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

private struct PingoImmersiveWordHuntView: View {
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var word = ""
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 4)

    var body: some View {
        let board = PingoExtraGameEngine.wordHuntBoard(for: state)
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(Array(board.letters.enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.72))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            LinearGradient(
                                colors: [Color.white, Color(red: 0.88, green: 0.92, blue: 0.98)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                        .overlay(alignment: .topLeading) {
                            Text("\(index + 1)")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.black.opacity(0.22))
                                .padding(5)
                        }
                        .shadow(color: .black.opacity(0.09), radius: 3, y: 2)
                }
            }
            .frame(maxHeight: .infinity)

            if !state.usedWords.isEmpty {
                Text(state.usedWords.map { $0.uppercased() }.joined(separator: "  •  "))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black.opacity(0.38))
                    .lineLimit(2)
            }

            if canMove {
                HStack(spacing: 8) {
                    TextField("WORD", text: $word)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                    Button {
                        onMove(.init(text: word))
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 38)
                            .background(Color.pingoPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct PingoImmersiveAnagramView: View {
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var answer = ""

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text(PingoExtraGameEngine.anagramPrompt(for: state))
                .font(.system(size: 38, weight: .heavy, design: .monospaced))
                .kerning(5)
                .foregroundStyle(.black.opacity(0.72))
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
                .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.10), radius: 7, y: 3)

            if !state.lastSummary.isEmpty {
                Text(state.lastSummary)
                    .font(.caption.bold())
                    .foregroundStyle(.black.opacity(0.44))
            }

            Spacer()

            if canMove {
                HStack(spacing: 8) {
                    TextField("ANSWER", text: $answer)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                    Button {
                        onMove(.init(text: answer))
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 38)
                            .background(Color.pingoPrimary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct PingoImmersiveTriviaView: View {
    let state: PingoExtraGameState
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    var body: some View {
        let question = PingoExtraGameEngine.triviaQuestion(for: state)
        VStack(spacing: 14) {
            Text(question.prompt)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.74))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .frame(maxHeight: .infinity)

            VStack(spacing: 9) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard canMove else { return }
                        onMove(.init(primary: index))
                    } label: {
                        HStack(spacing: 10) {
                            Text(String(Character(UnicodeScalar(65 + index)!)))
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.pingoPrimary, in: Circle())
                            Text(option)
                                .font(.headline)
                                .foregroundStyle(.black.opacity(0.70))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMove)
                }
            }
        }
    }
}

private struct PingoImmersiveCrazyEightsView: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    private var hand: [Int] {
        state.hands.indices.contains(player) ? state.hands[player] : []
    }

    private var opponentCount: Int {
        let opponent = 1 - player
        return state.hands.indices.contains(opponent) ? state.hands[opponent].count : 0
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                cardBack
                Text("× \(opponentCount)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.black.opacity(0.52))
                Spacer()
                Text("TOP CARD")
                    .font(.caption2.bold())
                    .foregroundStyle(.black.opacity(0.38))
                playingCard(state.topCard, playable: false)
            }

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -12) {
                    ForEach(Array(hand.enumerated()), id: \.offset) { index, card in
                        let playable = PingoExtraGameEngine.isPlayableCard(card, on: state.topCard)
                        Button {
                            guard canMove, playable else { return }
                            onMove(.init(primary: card))
                        } label: {
                            playingCard(card, playable: playable)
                                .rotationEffect(.degrees(Double(index - hand.count / 2) * 2.2))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMove || !playable)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }

            Spacer()

            if canMove {
                Button {
                    onMove(.init(primary: -1))
                } label: {
                    Label("Draw Card", systemImage: "plus.square.on.square")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.pingoPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cardBack: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.pingoPrimary, Color.pingoSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay { RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.55), lineWidth: 2).padding(4) }
            .frame(width: 46, height: 66)
    }

    private func playingCard(_ card: Int, playable: Bool) -> some View {
        let label = PingoExtraGameEngine.cardLabel(card)
        let red = label.contains("♥") || label.contains("♦")
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white)
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.headline.bold())
                    .foregroundStyle(red ? Color.red : Color.black)
                    .padding(8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(playable ? Color.pingoPrimary.opacity(0.7) : .black.opacity(0.08), lineWidth: playable ? 2 : 1)
            }
            .frame(width: 74, height: 108)
            .shadow(color: .black.opacity(0.13), radius: 4, y: 2)
            .opacity(playable || !canMove ? 1 : 0.55)
    }
}

private struct PingoImmersiveLudoView: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    private var pieces: [Int] {
        state.positions.indices.contains(player) ? state.positions[player] : [-1, -1]
    }

    private var die: Int { PingoExtraGameEngine.ludoDie(for: state) }

    private var legal: [Int] {
        pieces.indices.filter { index in
            let position = pieces[index]
            return position < 24 && (position >= 0 || die == 6)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white.opacity(0.68))
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)

                LudoTrack(pieces: pieces)
                    .padding(18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                Text("🎲")
                    .font(.system(size: 34))
                Text("\(die)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.black.opacity(0.72))
                Spacer()

                if canMove {
                    if legal.isEmpty {
                        Button("Pass") { onMove(.init(primary: -1)) }
                            .buttonStyle(.borderedProminent)
                            .tint(.pingoPrimary)
                    } else {
                        ForEach(legal, id: \.self) { index in
                            Button("Piece \(index + 1)") { onMove(.init(primary: index)) }
                                .buttonStyle(.borderedProminent)
                                .tint(index == 0 ? .pingoPrimary : .pingoSecondary)
                        }
                    }
                }
            }
        }
    }
}

private struct LudoTrack: View {
    let pieces: [Int]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .stroke(Color.black.opacity(0.12), lineWidth: 22)
                    .padding(26)
                Circle()
                    .stroke(Color.pingoPrimary.opacity(0.28), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                    .padding(26)

                ForEach(0..<24, id: \.self) { step in
                    let angle = Double(step) / 24 * 360 - 90
                    Circle()
                        .fill(step % 6 == 0 ? Color.pingoHighlight : Color.white)
                        .overlay { Circle().stroke(.black.opacity(0.10), lineWidth: 1) }
                        .frame(width: 15, height: 15)
                        .position(point(step: step, size: proxy.size))
                        .overlay {
                            if step % 6 == 0 {
                                Text("")
                            }
                        }
                        .rotationEffect(.degrees(angle))
                }

                ForEach(pieces.indices, id: \.self) { index in
                    piece(index: index, position: pieces[index], size: proxy.size)
                }

                VStack(spacing: 2) {
                    Text("HOME")
                        .font(.caption2.bold())
                        .foregroundStyle(.black.opacity(0.34))
                    Image(systemName: "house.fill")
                        .foregroundStyle(Color.pingoPrimary)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func piece(index: Int, position: Int, size: CGSize) -> some View {
        if position < 0 {
            Circle()
                .fill(index == 0 ? Color.pingoPrimary : Color.pingoSecondary)
                .overlay { Text("\(index + 1)").font(.caption2.bold()).foregroundStyle(.white) }
                .frame(width: 30, height: 30)
                .position(x: size.width * (index == 0 ? 0.40 : 0.60), y: size.height * 0.84)
        } else if position >= 24 {
            Circle()
                .fill(index == 0 ? Color.pingoPrimary : Color.pingoSecondary)
                .overlay { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) }
                .frame(width: 30, height: 30)
                .position(x: size.width * (index == 0 ? 0.44 : 0.56), y: size.height * 0.50)
        } else {
            Circle()
                .fill(index == 0 ? Color.pingoPrimary : Color.pingoSecondary)
                .overlay { Text("\(index + 1)").font(.caption2.bold()).foregroundStyle(.white) }
                .frame(width: 30, height: 30)
                .position(point(step: position, size: size))
        }
    }

    private func point(step: Int, size: CGSize) -> CGPoint {
        let angle = Double(step) / 24 * Double.pi * 2 - Double.pi / 2
        let radius = min(size.width, size.height) * 0.37
        return CGPoint(
            x: size.width / 2 + CGFloat(cos(angle)) * radius,
            y: size.height / 2 + CGFloat(sin(angle)) * radius
        )
    }
}
