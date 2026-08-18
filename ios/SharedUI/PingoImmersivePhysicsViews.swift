import PingoCore
import SwiftUI

struct PingoImmersiveCupPongView: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var aim = 0.0
    @State private var power = 0.58

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                scorePill(title: "YOU", value: remaining(player))
                Spacer()
                Text("CUP PONG")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.70))
                Spacer()
                scorePill(title: "THEM", value: remaining(1 - player))
            }

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.07, green: 0.36, blue: 0.48), Color(red: 0.02, green: 0.19, blue: 0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.24), radius: 10, y: 5)

                VStack(spacing: 20) {
                    cupRack(cups: state.cups[1 - player], flipped: true)
                    Spacer()
                    Circle()
                        .fill(.white)
                        .overlay { Circle().stroke(.black.opacity(0.12), lineWidth: 1) }
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
                    Spacer()
                    cupRack(cups: state.cups[player], flipped: false)
                }
                .padding(.vertical, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let lastCup = state.lastCup {
                Text("Cup \(lastCup + 1) sunk")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.55))
            }

            if canMove {
                controlRow(title: "Aim", value: Int(aim.rounded()), suffix: "°") {
                    Slider(value: $aim, in: -30...30)
                }
                controlRow(title: "Power", value: Int((power * 100).rounded()), suffix: "%") {
                    Slider(value: $power, in: 0.15...1)
                }
                sendButton(title: "Throw", icon: "paperplane.fill") {
                    onMove(.cupPong(.init(angleDegrees: aim, power: power)))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func remaining(_ index: Int) -> Int {
        guard state.cups.indices.contains(index) else { return 0 }
        return state.cups[index].filter { $0 }.count
    }

    private func scorePill(title: String, value: Int) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 8, weight: .bold, design: .rounded))
            Text("\(value)").font(.headline.monospacedDigit())
        }
        .foregroundStyle(.black.opacity(0.62))
        .frame(width: 54, height: 42)
        .background(.white.opacity(0.56), in: Capsule())
    }

    private func cupRack(cups: [Bool], flipped: Bool) -> some View {
        VStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                let count = flipped ? row + 1 : 3 - row
                let start = flipped ? triangularStart(row: row) : triangularStart(row: 2 - row)
                HStack(spacing: 9) {
                    ForEach(0..<count, id: \.self) { slot in
                        let index = start + slot
                        cupView(active: cups.indices.contains(index) ? cups[index] : false)
                    }
                }
            }
        }
    }

    private func triangularStart(row: Int) -> Int {
        switch row {
        case 0: return 0
        case 1: return 1
        default: return 3
        }
    }

    private func cupView(active: Bool) -> some View {
        ZStack {
            Capsule()
                .fill(active ? Color.red : Color.white.opacity(0.14))
                .frame(width: 36, height: 28)
            Ellipse()
                .fill(active ? Color.white.opacity(0.88) : Color.white.opacity(0.12))
                .frame(width: 30, height: 9)
                .offset(y: -9)
        }
        .opacity(active ? 1 : 0.36)
    }
}

struct PingoImmersiveBasketballView: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 52.0
    @State private var power = 0.72

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("BASKETBALL")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text("5-shot shootout")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.44))
                }
                Spacer()
                Text("\(score(player))  –  \(score(1 - player))")
                    .font(.title2.bold().monospacedDigit())
            }
            .foregroundStyle(.black.opacity(0.72))

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.94, green: 0.62, blue: 0.27), Color(red: 0.82, green: 0.39, blue: 0.14)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Rectangle()
                        .fill(.white.opacity(0.14))
                        .frame(height: 3)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.72)

                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.88), lineWidth: 5)
                        .frame(width: 96, height: 70)
                        .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.25)

                    Capsule()
                        .fill(Color.red)
                        .frame(width: 58, height: 5)
                        .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.36)

                    Circle()
                        .fill(Color.orange)
                        .overlay {
                            Circle().stroke(.black.opacity(0.35), lineWidth: 2)
                        }
                        .frame(width: 44, height: 44)
                        .position(x: proxy.size.width * 0.28, y: proxy.size.height * 0.70)

                    VStack(spacing: 3) {
                        Text(lastResult)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                        Text("Attempt \(attempts(player) + 1) of \(state.attemptsPerPlayer)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.92))
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.48)
                }
            }
            .frame(maxHeight: .infinity)

            if canMove {
                controlRow(title: "Angle", value: Int(angle.rounded()), suffix: "°") {
                    Slider(value: $angle, in: 30...75)
                }
                controlRow(title: "Power", value: Int((power * 100).rounded()), suffix: "%") {
                    Slider(value: $power, in: 0.2...1)
                }
                sendButton(title: "Shoot", icon: "basketball.fill") {
                    onMove(.basketball(.init(angleDegrees: angle, power: power)))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }

    private var lastResult: String {
        if state.attempts.reduce(0, +) == 0 { return "READY" }
        if state.lastPoints == 3 { return "SWISH +3" }
        if state.lastPoints == 2 { return "BUCKET +2" }
        return "MISS"
    }
}

struct PingoImmersiveDartsView: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var darts: [PingoDartPoint] = []

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("DARTS 301")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text("3 darts per turn")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.44))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(remaining(player))")
                        .font(.title.bold().monospacedDigit())
                    Text("Opponent \(remaining(1 - player))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.44))
                }
            }
            .foregroundStyle(.black.opacity(0.72))

            PingoImmersiveDartBoard(darts: darts, enabled: canMove && darts.count < 3) { point in
                darts.append(point)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)

            HStack {
                Text("Darts \(darts.count)/3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.black.opacity(0.46))
                Spacer()
                if !darts.isEmpty {
                    Button("Clear") { darts.removeAll() }
                        .font(.caption.bold())
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.pingoPrimary)
                }
            }

            if canMove {
                sendButton(title: "Send Visit", icon: "scope") {
                    onMove(.darts(.init(darts: darts)))
                    darts.removeAll()
                }
                .disabled(darts.count != 3)
                .opacity(darts.count == 3 ? 1 : 0.45)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func remaining(_ index: Int) -> Int {
        state.remaining.indices.contains(index) ? state.remaining[index] : 301
    }
}

private struct PingoImmersiveDartBoard: View {
    let darts: [PingoDartPoint]
    let enabled: Bool
    let onTap: (PingoDartPoint) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                Circle().stroke(Color.white.opacity(0.84), lineWidth: 2).padding(proxy.size.width * 0.055)
                Circle().stroke(Color.red.opacity(0.90), lineWidth: 13).padding(proxy.size.width * 0.16)
                Circle().stroke(Color.green.opacity(0.92), lineWidth: 13).padding(proxy.size.width * 0.28)
                Circle().stroke(Color.white.opacity(0.55), lineWidth: 2).padding(proxy.size.width * 0.39)
                Circle().fill(Color.green).frame(width: 34, height: 34)
                Circle().fill(Color.red).frame(width: 16, height: 16)

                ForEach(0..<20, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.26))
                        .frame(width: 1, height: proxy.size.height * 0.43)
                        .offset(y: -proxy.size.height * 0.215)
                        .rotationEffect(.degrees(Double(index) * 18))
                }

                ForEach(Array(darts.enumerated()), id: \.offset) { _, dart in
                    ZStack {
                        Circle().fill(Color.pingoPrimary)
                        Circle().stroke(.white, lineWidth: 2)
                    }
                    .frame(width: 14, height: 14)
                    .position(
                        x: proxy.size.width * CGFloat(dart.x / 2 + 0.5),
                        y: proxy.size.height * CGFloat(dart.y / 2 + 0.5)
                    )
                }
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { value in
                    guard enabled, proxy.size.width > 0, proxy.size.height > 0 else { return }
                    let x = Double((value.location.x / proxy.size.width - 0.5) * 2)
                    let y = Double((value.location.y / proxy.size.height - 0.5) * 2)
                    onTap(.init(x: x, y: y))
                }
            )
        }
    }
}

struct PingoImmersiveMiniGolfView: View {
    let state: PingoMiniGolfState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.45

    private var layout: PingoMiniGolfCourse {
        PingoMiniGolf.course[min(max(state.holeIndex, 0), PingoMiniGolf.course.count - 1)]
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("MINI GOLF")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text("Hole \(state.holeIndex + 1) of \(PingoMiniGolf.course.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.black.opacity(0.44))
                }
                Spacer()
                Text("\(total(player))  –  \(total(1 - player))")
                    .font(.title2.bold().monospacedDigit())
            }
            .foregroundStyle(.black.opacity(0.72))

            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color(red: 0.20, green: 0.62, blue: 0.31))
                        .shadow(color: .black.opacity(0.20), radius: 9, y: 4)

                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.50), lineWidth: 5)
                        .padding(10)

                    ForEach(Array(layout.obstacles.enumerated()), id: \.offset) { _, obstacle in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(red: 0.36, green: 0.20, blue: 0.10))
                            .frame(
                                width: proxy.size.width * CGFloat(obstacle.maxX - obstacle.minX),
                                height: proxy.size.height * CGFloat(obstacle.maxY - obstacle.minY)
                            )
                            .position(
                                x: proxy.size.width * CGFloat((obstacle.minX + obstacle.maxX) / 2),
                                y: proxy.size.height * CGFloat((obstacle.minY + obstacle.maxY) / 2)
                            )
                    }

                    Circle()
                        .fill(.black)
                        .frame(width: 19, height: 19)
                        .position(
                            x: proxy.size.width * CGFloat(layout.hole.x),
                            y: proxy.size.height * CGFloat(layout.hole.y)
                        )

                    Text("⚑")
                        .font(.system(size: 26))
                        .position(
                            x: proxy.size.width * CGFloat(layout.hole.x) + 10,
                            y: proxy.size.height * CGFloat(layout.hole.y) - 18
                        )

                    ball(index: 1 - player, color: .gray, size: proxy.size)
                    ball(index: player, color: .white, size: proxy.size)

                    if canMove && !holed(player) {
                        aimGuide(size: proxy.size)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.black.opacity(0.48))

            if canMove && !holed(player) {
                controlRow(title: "Aim", value: Int(angle.rounded()), suffix: "°") {
                    Slider(value: $angle, in: 0...359)
                }
                controlRow(title: "Power", value: Int((power * 100).rounded()), suffix: "%") {
                    Slider(value: $power, in: 0.05...1)
                }
                sendButton(title: "Putt", icon: "flag.fill") {
                    onMove(.miniGolf(.init(angleDegrees: angle, power: power)))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func total(_ index: Int) -> Int {
        guard state.totals.indices.contains(index), state.holeStrokes.indices.contains(index) else { return 0 }
        return state.totals[index] + state.holeStrokes[index]
    }

    private func holed(_ index: Int) -> Bool {
        state.holed.indices.contains(index) ? state.holed[index] : false
    }

    private var statusText: String {
        if holed(player) { return "In the cup — waiting for the other player" }
        guard state.holeStrokes.indices.contains(player) else { return "Line up your putt" }
        return "Stroke \(state.holeStrokes[player] + 1)"
    }

    private func ball(index: Int, color: Color, size: CGSize) -> some View {
        let position = state.positions.indices.contains(index) ? state.positions[index] : layout.start
        return Circle()
            .fill(color)
            .overlay { Circle().stroke(.black.opacity(0.22), lineWidth: 1.5) }
            .frame(width: index == player ? 18 : 14, height: index == player ? 18 : 14)
            .position(
                x: size.width * CGFloat(position.x),
                y: size.height * CGFloat(position.y)
            )
    }

    private func aimGuide(size: CGSize) -> some View {
        let position = state.positions.indices.contains(player) ? state.positions[player] : layout.start
        let start = CGPoint(x: size.width * CGFloat(position.x), y: size.height * CGFloat(position.y))
        let radians = angle * .pi / 180
        let length = min(size.width, size.height) * 0.34
        let end = CGPoint(
            x: start.x + CGFloat(cos(radians)) * length,
            y: start.y + CGFloat(sin(radians)) * length
        )
        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(.white.opacity(0.78), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
    }
}

private func controlRow<Control: View>(
    title: String,
    value: Int,
    suffix: String,
    @ViewBuilder control: () -> Control
) -> some View {
    HStack(spacing: 10) {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.black.opacity(0.56))
            .frame(width: 48, alignment: .leading)
        control()
            .tint(Color.pingoPrimary)
        Text("\(value)\(suffix)")
            .font(.caption.monospacedDigit().weight(.bold))
            .foregroundStyle(.black.opacity(0.50))
            .frame(width: 48, alignment: .trailing)
    }
}

private func sendButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.pingoPrimary, in: Capsule())
    }
    .buttonStyle(.plain)
}
