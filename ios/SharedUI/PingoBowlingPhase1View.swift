import PingoCore
import SwiftUI

struct PingoBowlingPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var line = 50.0
    @State private var power = 82.0

    var body: some View {
        VStack(spacing: 12) {
            header

            laneStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusRibbon

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
                Text("BOWLING")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("FIVE-FRAME DUEL")
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

    private var laneStage: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let laneTop = size.height * 0.10
            let laneBottom = size.height * 0.96
            let laneLeftTop = size.width * 0.34
            let laneRightTop = size.width * 0.66
            let laneLeftBottom = size.width * 0.08
            let laneRightBottom = size.width * 0.92

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.045, green: 0.055, blue: 0.10),
                                Color(red: 0.10, green: 0.075, blue: 0.10),
                                Color(red: 0.04, green: 0.045, blue: 0.075)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.28), radius: 12, y: 6)

                crowdGlow

                laneShape(
                    topY: laneTop,
                    bottomY: laneBottom,
                    leftTop: laneLeftTop,
                    rightTop: laneRightTop,
                    leftBottom: laneLeftBottom,
                    rightBottom: laneRightBottom
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.82, blue: 0.58),
                            Color(red: 0.84, green: 0.61, blue: 0.35),
                            Color(red: 0.62, green: 0.37, blue: 0.19)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                laneBoards(
                    size: size,
                    topY: laneTop,
                    bottomY: laneBottom,
                    leftTop: laneLeftTop,
                    rightTop: laneRightTop,
                    leftBottom: laneLeftBottom,
                    rightBottom: laneRightBottom
                )

                gutters(
                    size: size,
                    topY: laneTop,
                    bottomY: laneBottom,
                    leftTop: laneLeftTop,
                    rightTop: laneRightTop,
                    leftBottom: laneLeftBottom,
                    rightBottom: laneRightBottom
                )

                pinDeck(size: size)

                approachDots(size: size)
                aimBoard(size: size)
                bowlingBall(size: size)

                VStack {
                    HStack {
                        laneBadge
                        Spacer()
                    }
                    Spacer()
                }
                .padding(22)
            }
        }
    }

    private var crowdGlow: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.pingoPrimary.opacity(0.22), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func laneShape(
        topY: CGFloat,
        bottomY: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat,
        leftBottom: CGFloat,
        rightBottom: CGFloat
    ) -> Path {
        Path { path in
            path.move(to: CGPoint(x: leftTop, y: topY))
            path.addLine(to: CGPoint(x: rightTop, y: topY))
            path.addLine(to: CGPoint(x: rightBottom, y: bottomY))
            path.addLine(to: CGPoint(x: leftBottom, y: bottomY))
            path.closeSubpath()
        }
    }

    private func laneBoards(
        size: CGSize,
        topY: CGFloat,
        bottomY: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat,
        leftBottom: CGFloat,
        rightBottom: CGFloat
    ) -> some View {
        ZStack {
            ForEach(1..<9, id: \.self) { index in
                let fraction = CGFloat(index) / 9
                Path { path in
                    let topX = leftTop + (rightTop - leftTop) * fraction
                    let bottomX = leftBottom + (rightBottom - leftBottom) * fraction
                    path.move(to: CGPoint(x: topX, y: topY))
                    path.addLine(to: CGPoint(x: bottomX, y: bottomY))
                }
                .stroke(Color.white.opacity(index.isMultiple(of: 2) ? 0.07 : 0.035), lineWidth: 1)
            }

            ForEach(1..<6, id: \.self) { index in
                let fraction = CGFloat(index) / 6
                let y = topY + (bottomY - topY) * fraction
                let t = (y - topY) / max(1, bottomY - topY)
                let left = leftTop + (leftBottom - leftTop) * t
                let right = rightTop + (rightBottom - rightTop) * t
                Path { path in
                    path.move(to: CGPoint(x: left, y: y))
                    path.addLine(to: CGPoint(x: right, y: y))
                }
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }

    private func gutters(
        size: CGSize,
        topY: CGFloat,
        bottomY: CGFloat,
        leftTop: CGFloat,
        rightTop: CGFloat,
        leftBottom: CGFloat,
        rightBottom: CGFloat
    ) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: leftTop - 8, y: topY))
                path.addLine(to: CGPoint(x: leftBottom - 14, y: bottomY))
            }
            .stroke(
                LinearGradient(colors: [Color.black.opacity(0.35), Color.black.opacity(0.78)], startPoint: .top, endPoint: .bottom),
                lineWidth: 14
            )

            Path { path in
                path.move(to: CGPoint(x: rightTop + 8, y: topY))
                path.addLine(to: CGPoint(x: rightBottom + 14, y: bottomY))
            }
            .stroke(
                LinearGradient(colors: [Color.black.opacity(0.35), Color.black.opacity(0.78)], startPoint: .top, endPoint: .bottom),
                lineWidth: 14
            )
        }
        .allowsHitTesting(false)
    }

    private func pinDeck(size: CGSize) -> some View {
        let centerX = size.width / 2
        let baseY = size.height * 0.19
        let xStep = size.width * 0.038
        let yStep = size.height * 0.027

        return ZStack {
            pin(position: CGPoint(x: centerX, y: baseY - yStep * 1.5), scale: 0.68)

            pin(position: CGPoint(x: centerX - xStep * 0.7, y: baseY - yStep * 0.5), scale: 0.72)
            pin(position: CGPoint(x: centerX + xStep * 0.7, y: baseY - yStep * 0.5), scale: 0.72)

            pin(position: CGPoint(x: centerX - xStep * 1.4, y: baseY + yStep * 0.5), scale: 0.76)
            pin(position: CGPoint(x: centerX, y: baseY + yStep * 0.5), scale: 0.76)
            pin(position: CGPoint(x: centerX + xStep * 1.4, y: baseY + yStep * 0.5), scale: 0.76)

            pin(position: CGPoint(x: centerX - xStep * 2.1, y: baseY + yStep * 1.5), scale: 0.80)
            pin(position: CGPoint(x: centerX - xStep * 0.7, y: baseY + yStep * 1.5), scale: 0.80)
            pin(position: CGPoint(x: centerX + xStep * 0.7, y: baseY + yStep * 1.5), scale: 0.80)
            pin(position: CGPoint(x: centerX + xStep * 2.1, y: baseY + yStep * 1.5), scale: 0.80)
        }
        .shadow(color: .black.opacity(0.30), radius: 3, y: 2)
    }

    private func pin(position: CGPoint, scale: CGFloat) -> some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white, Color(white: 0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 15, height: 31)

            Rectangle()
                .fill(Color.red.opacity(0.88))
                .frame(width: 13, height: 3)
                .offset(y: -5)
        }
        .scaleEffect(scale)
        .position(position)
    }

    private func approachDots(size: CGSize) -> some View {
        HStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.black.opacity(0.26))
                    .frame(width: 5, height: 5)
            }
        }
        .position(x: size.width / 2, y: size.height * 0.72)
    }

    private func aimBoard(size: CGSize) -> some View {
        let normalized = CGFloat(line / 100)
        let x = size.width * (0.17 + normalized * 0.66)
        let startY = size.height * 0.78
        let endX = size.width * (0.40 + normalized * 0.20)
        let endY = size.height * 0.33

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: x, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(
                Color.white.opacity(0.70),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 6])
            )

            Image(systemName: "triangle.fill")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color.pingoPrimary.opacity(0.88))
                .rotationEffect(.degrees(180))
                .position(x: endX, y: endY)
        }
        .allowsHitTesting(false)
    }

    private func bowlingBall(size: CGSize) -> some View {
        let x = size.width * CGFloat(0.17 + line / 100 * 0.66)

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.27, green: 0.30, blue: 0.46),
                            Color(red: 0.08, green: 0.09, blue: 0.16),
                            Color.black
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 42
                    )
                )

            HStack(spacing: 4) {
                Circle().fill(.black.opacity(0.70)).frame(width: 7, height: 7)
                VStack(spacing: 3) {
                    Circle().fill(.black.opacity(0.70)).frame(width: 6, height: 6)
                    Circle().fill(.black.opacity(0.70)).frame(width: 6, height: 6)
                }
            }
            .offset(x: 8, y: -8)
        }
        .frame(width: 72, height: 72)
        .overlay {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 7, y: 5)
        .position(x: x, y: size.height * 0.82)
        .accessibilityLabel("Bowling ball")
    }

    private var laneBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "figure.bowling")
                .font(.system(size: 10, weight: .black))
            Text("FRAME \(min(5, attempts(player) + 1))")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.30), in: Capsule())
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.pingoPrimary)

            VStack(alignment: .leading, spacing: 1) {
                Text(statusTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.64))
                Text(statusSubtitle)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.38))
            }

            Spacer()

            Text("\(attempts(player))/5")
                .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.42))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 10) {
            controlRow(title: "Line", value: $line)
            controlRow(title: "Power", value: $power)

            Button {
                onMove(.init(primary: Int(line.rounded()), secondary: Int(power.rounded())))
            } label: {
                Label("Roll", systemImage: "figure.bowling")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.pingoPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func controlRow(title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.black.opacity(0.56))
                .frame(width: 58, alignment: .leading)

            Slider(value: value, in: 0...100, step: 1)
                .tint(Color.pingoPrimary)

            Text("\(Int(value.wrappedValue.rounded()))")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.black.opacity(0.50))
                .frame(width: 34, alignment: .trailing)
        }
    }

    private func scoreChip(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.5)
            Text("\(score)")
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
            Text("\(attempts)/5")
                .font(.system(size: 7, weight: .bold, design: .rounded).monospacedDigit())
                .opacity(0.55)
        }
        .foregroundStyle(emphasized ? Color.pingoPrimary : .black.opacity(0.62))
        .frame(width: 54, height: 48)
        .background(.white.opacity(emphasized ? 0.76 : 0.50), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }

    private var statusTitle: String {
        if !state.lastSummary.isEmpty {
            return state.lastSummary.uppercased()
        }
        return canMove ? "YOUR ROLL" : "LANE READY"
    }

    private var statusSubtitle: String {
        if canMove {
            return "Set the line and power, then roll."
        }
        return "Waiting for the next turn."
    }

    private var statusIcon: String {
        state.lastScore == 10 ? "burst.fill" : "scope"
    }
}
