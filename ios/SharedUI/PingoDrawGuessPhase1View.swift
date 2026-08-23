import PingoCore
import SwiftUI

struct PingoDrawGuessPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var drawing: [PingoExtraPoint] = []
    @State private var guess = ""

    private var localScore: Int {
        state.scores.indices.contains(player) ? state.scores[player] : 0
    }

    private var opponentScore: Int {
        let opponent = 1 - player
        return state.scores.indices.contains(opponent) ? state.scores[opponent] : 0
    }

    var body: some View {
        VStack(spacing: 12) {
            scoreStrip
            roundBanner

            if state.phase == 0 {
                drawingStage
            } else {
                guessingStage
            }

            if !state.lastSummary.isEmpty {
                Text(state.lastSummary.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.black.opacity(0.42))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.58), in: Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.90, blue: 0.98),
                    Color(red: 0.91, green: 0.95, blue: 1.00),
                    Color(red: 0.98, green: 0.95, blue: 0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.78), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            scoreChip(title: "YOU", score: localScore, symbol: "paintbrush.pointed.fill")
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                Text("DRAW & GUESS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1)
                Text(state.phase == 0 ? "ARTIST TURN" : "GUESSER TURN")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }
            .foregroundStyle(.black.opacity(0.76))
            Spacer(minLength: 8)
            scoreChip(title: "RIVAL", score: opponentScore, symbol: "person.fill")
        }
    }

    private func scoreChip(title: String, score: Int, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.38))
                Text("\(score)")
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
            }
        }
        .foregroundStyle(.black.opacity(0.72))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var roundBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: state.phase == 0 ? "scribble.variable" : "eye.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.pingoPrimary)
            VStack(alignment: .leading, spacing: 1) {
                Text(state.phase == 0 ? "YOUR PROMPT" : "NAME THE DRAWING")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.38))
                Text(state.phase == 0 ? PingoExtraGameEngine.drawPrompt(for: state).uppercased() : "WHAT DO YOU SEE?")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.74))
                    .lineLimit(1)
            }
            Spacer()
            Text(canMove ? "YOUR TURN" : "WATCH")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(canMove ? Color.pingoPrimary : .black.opacity(0.34))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.white.opacity(0.68), in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var drawingStage: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                DrawGuessCanvas(points: $drawing, enabled: canMove)

                HStack(spacing: 6) {
                    Label("INK", systemImage: "pencil.tip")
                    Text("\(drawing.count)/160")
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.38))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(.white.opacity(0.86), in: Capsule())
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if canMove {
                HStack(spacing: 9) {
                    Button {
                        drawing.removeAll()
                    } label: {
                        Label("Clear", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .frame(height: 44)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(drawing.isEmpty)

                    Button {
                        onMove(.init(points: drawing))
                    } label: {
                        Label("Send Drawing", systemImage: "paperplane.fill")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pingoPrimary)
                    .disabled(drawing.count < 2)
                }
            }
        }
    }

    private var guessingStage: some View {
        VStack(spacing: 10) {
            DrawGuessPreview(points: state.drawing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if canMove {
                HStack(spacing: 8) {
                    Image(systemName: "text.cursor")
                        .foregroundStyle(Color.pingoPrimary)
                    TextField("Type your guess", text: $guess)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Button {
                        onMove(.init(text: guess))
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Color.pingoPrimary, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct DrawGuessCanvas: View {
    @Binding var points: [PingoExtraPoint]
    let enabled: Bool

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                drawPaperGrid(context: &context, size: size)
                context.stroke(DrawGuessPath.make(points: points, size: size), with: .color(.black.opacity(0.82)), lineWidth: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.pingoPrimary.opacity(0.20), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard enabled, points.count < 160 else { return }
                        let width = max(1, proxy.size.width)
                        let height = max(1, proxy.size.height)
                        let x = min(1000, max(0, Int(value.location.x / width * 1000)))
                        let y = min(1000, max(0, Int(value.location.y / height * 1000)))
                        points.append(.init(x: x, y: y))
                    }
            )
        }
    }

    private func drawPaperGrid(context: inout GraphicsContext, size: CGSize) {
        var grid = Path()
        let step: CGFloat = 28
        var x: CGFloat = step
        while x < size.width {
            grid.move(to: CGPoint(x: x, y: 0))
            grid.addLine(to: CGPoint(x: x, y: size.height))
            x += step
        }
        var y: CGFloat = step
        while y < size.height {
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: size.width, y: y))
            y += step
        }
        context.stroke(grid, with: .color(Color.pingoPrimary.opacity(0.055)), lineWidth: 0.8)
    }
}

private struct DrawGuessPreview: View {
    let points: [PingoExtraPoint]

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            context.stroke(DrawGuessPath.make(points: points, size: size), with: .color(.black.opacity(0.82)), lineWidth: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.pingoPrimary.opacity(0.20), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
    }
}

private enum DrawGuessPath {
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
