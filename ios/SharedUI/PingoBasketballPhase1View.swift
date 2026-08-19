import PingoCore
import SwiftUI

struct PingoBasketballPhase1View: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 52.0
    @State private var power = 0.72

    var body: some View {
        VStack(spacing: 10) {
            scoreboard

            GeometryReader { proxy in
                ZStack {
                    arenaBackground
                    courtGlow(size: proxy.size)
                    backboard(size: proxy.size)
                    hoop(size: proxy.size)
                    net(size: proxy.size)
                    floor(size: proxy.size)
                    ball(size: proxy.size)
                    resultBanner(size: proxy.size)
                    attemptDots(size: proxy.size)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.30), radius: 14, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if canMove {
                controls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            scoreSide(title: "YOU", score: score(player), attempts: attempts(player), emphasized: canMove)

            VStack(spacing: 2) {
                Text("BASKETBALL")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Text("5-SHOT SHOOTOUT")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .frame(maxWidth: .infinity)

            scoreSide(title: "THEM", score: score(1 - player), attempts: attempts(1 - player), emphasized: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func scoreSide(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(emphasized ? Color.orange : .white.opacity(0.48))
                Text("\(attempts)/\(state.attemptsPerPlayer)")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }
            Text("\(score)")
                .font(.system(size: 25, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(minWidth: 70)
    }

    private var arenaBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.055, green: 0.055, blue: 0.075),
                Color(red: 0.10, green: 0.055, blue: 0.025),
                Color(red: 0.19, green: 0.085, blue: 0.025)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func courtGlow(size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.orange.opacity(0.22))
                .blur(radius: 34)
                .frame(width: size.width * 0.82, height: size.height * 0.34)
                .position(x: size.width * 0.52, y: size.height * 0.63)

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == 2 ? 0.20 : 0.09))
                    .frame(width: size.width * 0.12, height: 3)
                    .blur(radius: 1.5)
                    .position(
                        x: size.width * (0.16 + Double(index) * 0.17),
                        y: size.height * 0.10
                    )
            }
        }
    }

    private func backboard(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.white.opacity(0.92), lineWidth: 5)
                }
                .frame(width: size.width * 0.42, height: size.height * 0.25)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 3)
                .frame(width: size.width * 0.15, height: size.height * 0.09)
                .offset(y: size.height * 0.035)
        }
        .position(x: size.width * 0.72, y: size.height * 0.23)
    }

    private func hoop(size: CGSize) -> some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.92, green: 0.20, blue: 0.08))
                .frame(width: size.width * 0.25, height: 8)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)

            Ellipse()
                .stroke(Color(red: 1.0, green: 0.28, blue: 0.08), lineWidth: 4)
                .frame(width: size.width * 0.25, height: 15)
                .offset(y: -2)
        }
        .position(x: size.width * 0.72, y: size.height * 0.37)
    }

    private func net(size: CGSize) -> some View {
        Path { path in
            let centerX = size.width * 0.72
            let topY = size.height * 0.385
            let halfWidth = size.width * 0.11
            let bottomY = size.height * 0.49
            let bottomHalf = size.width * 0.055

            path.move(to: CGPoint(x: centerX - halfWidth, y: topY))
            path.addLine(to: CGPoint(x: centerX - bottomHalf, y: bottomY))
            path.move(to: CGPoint(x: centerX + halfWidth, y: topY))
            path.addLine(to: CGPoint(x: centerX + bottomHalf, y: bottomY))

            for step in 0...4 {
                let fraction = CGFloat(step) / 4
                let y = topY + (bottomY - topY) * fraction
                let width = halfWidth + (bottomHalf - halfWidth) * fraction
                path.move(to: CGPoint(x: centerX - width, y: y))
                path.addLine(to: CGPoint(x: centerX + width, y: y))
            }

            for step in 0...4 {
                let fraction = CGFloat(step) / 4
                let topX = centerX - halfWidth + halfWidth * 2 * fraction
                let bottomX = centerX - bottomHalf + bottomHalf * 2 * fraction
                path.move(to: CGPoint(x: topX, y: topY))
                path.addLine(to: CGPoint(x: bottomX, y: bottomY))
            }
        }
        .stroke(Color.white.opacity(0.68), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
    }

    private func floor(size: CGSize) -> some View {
        ZStack {
            Path { path in
                let horizon = size.height * 0.63
                path.move(to: CGPoint(x: 0, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.24, blue: 0.055),
                        Color(red: 0.31, green: 0.11, blue: 0.025)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Path { path in
                let horizon = size.height * 0.64
                path.move(to: CGPoint(x: 0, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: horizon))
                path.move(to: CGPoint(x: size.width * 0.50, y: horizon))
                path.addLine(to: CGPoint(x: size.width * 0.50, y: size.height))
                path.move(to: CGPoint(x: size.width * 0.18, y: size.height))
                path.addQuadCurve(
                    to: CGPoint(x: size.width * 0.82, y: size.height),
                    control: CGPoint(x: size.width * 0.50, y: size.height * 0.72)
                )
            }
            .stroke(Color.white.opacity(0.36), lineWidth: 2)
        }
    }

    private func ball(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.50, blue: 0.10), Color(red: 0.74, green: 0.20, blue: 0.025)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 34
                    )
                )
            Circle().stroke(Color.black.opacity(0.50), lineWidth: 2)
            Path { path in
                path.move(to: CGPoint(x: 4, y: 28))
                path.addQuadCurve(to: CGPoint(x: 52, y: 28), control: CGPoint(x: 28, y: 5))
                path.move(to: CGPoint(x: 4, y: 28))
                path.addQuadCurve(to: CGPoint(x: 52, y: 28), control: CGPoint(x: 28, y: 51))
                path.move(to: CGPoint(x: 28, y: 2))
                path.addLine(to: CGPoint(x: 28, y: 54))
            }
            .stroke(Color.black.opacity(0.52), lineWidth: 1.6)
        }
        .frame(width: 56, height: 56)
        .shadow(color: .black.opacity(0.42), radius: 7, y: 5)
        .position(x: size.width * 0.27, y: size.height * 0.72)
    }

    private func resultBanner(size: CGSize) -> some View {
        VStack(spacing: 3) {
            Text(lastResult)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .tracking(0.5)
            Text("ATTEMPT \(min(attempts(player) + 1, state.attemptsPerPlayer)) OF \(state.attemptsPerPlayer)")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.54))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.62), in: Capsule())
        .position(x: size.width * 0.48, y: size.height * 0.54)
    }

    private func attemptDots(size: CGSize) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<state.attemptsPerPlayer, id: \.self) { index in
                Circle()
                    .fill(index < attempts(player) ? Color.orange : Color.white.opacity(0.20))
                    .frame(width: 8, height: 8)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    }
            }
        }
        .position(x: size.width * 0.50, y: size.height * 0.91)
    }

    private var controls: some View {
        VStack(spacing: 7) {
            controlRow(title: "Release", value: Int(angle.rounded()), suffix: "°") {
                Slider(value: $angle, in: 30...75)
                    .tint(.orange)
            }
            controlRow(title: "Power", value: Int((power * 100).rounded()), suffix: "%") {
                Slider(value: $power, in: 0.2...1)
                    .tint(.orange)
            }
            Button {
                onMove(.basketball(.init(angleDegrees: angle, power: power)))
            } label: {
                Label("SHOOT", systemImage: "basketball.fill")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.orange, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shoot and send")
        }
        .padding(.horizontal, 2)
    }

    private func controlRow<Content: View>(
        title: String,
        value: Int,
        suffix: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        HStack(spacing: 9) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.52))
                .frame(width: 50, alignment: .leading)
            control()
            Text("\(value)\(suffix)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.white.opacity(0.70))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(Color.black.opacity(0.50), in: Capsule())
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
