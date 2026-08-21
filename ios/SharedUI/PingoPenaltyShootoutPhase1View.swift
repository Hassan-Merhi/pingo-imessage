import PingoCore
import SwiftUI

struct PingoPenaltyShootoutPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var target = 2
    @State private var power = 75.0

    var body: some View {
        VStack(spacing: 12) {
            header

            pitchStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            resultRibbon

            if canMove {
                controls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PENALTY SHOOTOUT")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.7)
                Text("FIVE-KICK DUEL")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.44))
            }

            Spacer()

            HStack(spacing: 8) {
                scoreChip(title: "YOU", score: score(player), attempts: attempts(player), emphasized: true)
                scoreChip(title: "THEM", score: score(1 - player), attempts: attempts(1 - player), emphasized: false)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
    }

    private var pitchStage: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.24, blue: 0.18),
                                Color(red: 0.10, green: 0.48, blue: 0.24),
                                Color(red: 0.05, green: 0.30, blue: 0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.24), radius: 12, y: 6)

                stadiumGlow
                grassStripes(size: size)
                penaltyArea(size: size)
                goal(size: size)
                goalkeeper(size: size)
                targetGuide(size: size)
                penaltySpot(size: size)
                ball(size: size)

                VStack {
                    HStack {
                        kickBadge
                        Spacer()
                    }
                    Spacer()
                }
                .padding(22)
            }
        }
    }

    private var stadiumGlow: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.white.opacity(0.16), Color.pingoPrimary.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 92)
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func grassStripes(size: CGSize) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.045 : 0.015))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .allowsHitTesting(false)
    }

    private func penaltyArea(size: CGSize) -> some View {
        ZStack {
            Path { path in
                let left = size.width * 0.14
                let right = size.width * 0.86
                let top = size.height * 0.10
                let bottom = size.height * 0.55
                path.move(to: CGPoint(x: left, y: top))
                path.addLine(to: CGPoint(x: left, y: bottom))
                path.addLine(to: CGPoint(x: right, y: bottom))
                path.addLine(to: CGPoint(x: right, y: top))
            }
            .stroke(Color.white.opacity(0.82), lineWidth: 3)

            Path { path in
                let rect = CGRect(
                    x: size.width * 0.34,
                    y: size.height * 0.43,
                    width: size.width * 0.32,
                    height: size.height * 0.20
                )
                path.addArc(
                    center: CGPoint(x: rect.midX, y: rect.minY),
                    radius: rect.width / 2,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: false
                )
            }
            .stroke(Color.white.opacity(0.52), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }

    private func goal(size: CGSize) -> some View {
        let width = size.width * 0.62
        let height = size.height * 0.30
        let center = CGPoint(x: size.width / 2, y: size.height * 0.23)

        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white.opacity(0.98), lineWidth: 6)
                .frame(width: width, height: height)

            ForEach(1..<6, id: \.self) { index in
                Path { path in
                    let x = center.x - width / 2 + width * CGFloat(index) / 6
                    path.move(to: CGPoint(x: x, y: center.y - height / 2))
                    path.addLine(to: CGPoint(x: x, y: center.y + height / 2))
                }
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }

            ForEach(1..<4, id: \.self) { index in
                Path { path in
                    let y = center.y - height / 2 + height * CGFloat(index) / 4
                    path.move(to: CGPoint(x: center.x - width / 2, y: y))
                    path.addLine(to: CGPoint(x: center.x + width / 2, y: y))
                }
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .position(center)
        .allowsHitTesting(false)
    }

    private func goalkeeper(size: CGSize) -> some View {
        VStack(spacing: -2) {
            Circle()
                .fill(Color(red: 0.93, green: 0.70, blue: 0.22))
                .frame(width: 22, height: 22)
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 0.93, green: 0.70, blue: 0.22))
                .frame(width: 42, height: 48)
                .overlay {
                    HStack(spacing: 34) {
                        Capsule().fill(Color.white.opacity(0.9)).frame(width: 10, height: 34)
                        Capsule().fill(Color.white.opacity(0.9)).frame(width: 10, height: 34)
                    }
                }
            HStack(spacing: 8) {
                Capsule().fill(Color.black.opacity(0.72)).frame(width: 12, height: 32)
                Capsule().fill(Color.black.opacity(0.72)).frame(width: 12, height: 32)
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
        .position(x: size.width / 2, y: size.height * 0.29)
        .accessibilityHidden(true)
    }

    private func targetGuide(size: CGSize) -> some View {
        let point = targetPoint(size: size)

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.92), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .frame(width: 48, height: 48)
                .position(point)

            Circle()
                .fill(Color.pingoPrimary.opacity(0.84))
                .frame(width: 10, height: 10)
                .position(point)

            Path { path in
                path.move(to: CGPoint(x: size.width / 2, y: size.height * 0.76))
                path.addLine(to: point)
            }
            .stroke(Color.white.opacity(0.66), style: StrokeStyle(lineWidth: 2, dash: [6, 7]))
        }
        .allowsHitTesting(false)
    }

    private func penaltySpot(size: CGSize) -> some View {
        Circle()
            .fill(Color.white.opacity(0.92))
            .frame(width: 8, height: 8)
            .position(x: size.width / 2, y: size.height * 0.70)
    }

    private func ball(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.84)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 34
                    )
                )
            Image(systemName: "soccerball")
                .font(.system(size: 31, weight: .regular))
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(width: 62, height: 62)
        .shadow(color: .black.opacity(0.34), radius: 6, y: 4)
        .position(x: size.width / 2, y: size.height * 0.79)
        .accessibilityLabel("Penalty ball")
    }

    private var kickBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "soccerball")
                .font(.system(size: 10, weight: .black))
            Text("KICK \(min(5, attempts(player) + 1))")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.32), in: Capsule())
    }

    private var resultRibbon: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(canMove ? Color.pingoPrimary : Color.black.opacity(0.20))
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.black.opacity(0.58))
            Spacer()
            if !state.lastSummary.isEmpty {
                Text(state.lastSummary.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 4)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                ForEach(0..<5, id: \.self) { lane in
                    Button {
                        target = lane
                    } label: {
                        Text(symbol(for: lane))
                            .font(.headline)
                            .foregroundStyle(target == lane ? .white : .black.opacity(0.62))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                target == lane ? Color.pingoPrimary : Color.white.opacity(0.52),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(targetLabel(for: lane))
                }
            }

            HStack(spacing: 10) {
                Text("Power")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.56))
                    .frame(width: 48, alignment: .leading)
                Slider(value: $power, in: 0...100, step: 1)
                    .tint(Color.pingoPrimary)
                Text("\(Int(power.rounded()))")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.black.opacity(0.50))
                    .frame(width: 34, alignment: .trailing)
            }

            Button {
                onMove(.init(primary: target, secondary: Int(power.rounded())))
            } label: {
                Label("Take Penalty", systemImage: "soccerball")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pingoPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func scoreChip(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(.black.opacity(0.44))
            HStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                Text("/ \(attempts)")
                    .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.black.opacity(0.40))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            emphasized ? Color.pingoPrimary.opacity(0.12) : Color.black.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func targetPoint(size: CGSize) -> CGPoint {
        let xs: [CGFloat] = [0.26, 0.36, 0.50, 0.64, 0.74]
        let ys: [CGFloat] = [0.18, 0.30, 0.17, 0.30, 0.18]
        let index = min(4, max(0, target))
        return CGPoint(x: size.width * xs[index], y: size.height * ys[index])
    }

    private func symbol(for lane: Int) -> String {
        switch lane {
        case 0: return "↙︎"
        case 1: return "⬅︎"
        case 2: return "⬆︎"
        case 3: return "➡︎"
        default: return "↘︎"
        }
    }

    private func targetLabel(for lane: Int) -> String {
        switch lane {
        case 0: return "Lower left target"
        case 1: return "Left target"
        case 2: return "Center target"
        case 3: return "Right target"
        default: return "Lower right target"
        }
    }

    private var statusText: String {
        canMove ? "YOUR KICK — PICK YOUR SPOT" : "WAITING FOR THE NEXT KICK"
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }
}
