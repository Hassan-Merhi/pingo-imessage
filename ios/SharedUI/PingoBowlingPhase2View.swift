import PingoCore
import SwiftUI

struct PingoBowlingPhase2View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var line = 50.0
    @State private var power = 70.0
    @State private var dragStartLine = 50.0
    @State private var isAiming = false

    var body: some View {
        VStack(spacing: 12) {
            header

            laneStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusRibbon

            if canMove {
                instructionBar
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
                    topY: laneTop,
                    bottomY: laneBottom,
                    leftTop: laneLeftTop,
                    rightTop: laneRightTop,
                    leftBottom: laneLeftBottom,
                    rightBottom: laneRightBottom
                )

                gutters(
                    topY: laneTop,
                    bottomY: laneBottom,
                    leftTop: laneLeftTop,
                    rightTop: laneRightTop,
                    leftBottom: laneLeftBottom,
                    rightBottom: laneRightBottom
                )

                pinDeck(size: size)
                aimGuide(size: size)
                bowlingBall(size: size)

                VStack {
                    HStack {
                        laneBadge
                        Spacer()
                        aimReadout
                    }
                    Spacer()
                }
                .padding(22)
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .gesture(canMove ? rollGesture(in: size) : nil)
        }
    }

    private func rollGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                if !isAiming {
                    isAiming = true
                    dragStartLine = line
                }

                let horizontal = Double(value.translation.width / max(1, size.width)) * 120
                line = min(100, max(0, dragStartLine + horizontal))

                let upward = max(0, -value.translation.height)
                power = min(100, max(10, Double(upward / max(1, size.height)) * 180))
            }
            .onEnded { value in
                defer { isAiming = false }

                let upward = max(0, -value.translation.height)
                let minimumFlick = max(34, size.height * 0.08)
                guard upward >= minimumFlick else { return }

                let releaseLine = Int(line.rounded())
                let releasePower = Int(power.rounded())
                onMove(.init(primary: releaseLine, secondary: releasePower))
            }
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
        }
        .allowsHitTesting(false)
    }

    private func gutters(
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
            .stroke(Color.black.opacity(0.62), lineWidth: 14)

            Path { path in
                path.move(to: CGPoint(x: rightTop + 8, y: topY))
                path.addLine(to: CGPoint(x: rightBottom + 14, y: bottomY))
            }
            .stroke(Color.black.opacity(0.62), lineWidth: 14)
        }
        .allowsHitTesting(false)
    }

    private func pinDeck(size: CGSize) -> some View {
        let centerX = size.width / 2
        let baseY = size.height * 0.19
        let xStep = size.width * 0.038
        let yStep = size.height * 0.027
        let positions = [
            CGPoint(x: centerX, y: baseY - yStep * 1.5),
            CGPoint(x: centerX - xStep * 0.7, y: baseY - yStep * 0.5),
            CGPoint(x: centerX + xStep * 0.7, y: baseY - yStep * 0.5),
            CGPoint(x: centerX - xStep * 1.4, y: baseY + yStep * 0.5),
            CGPoint(x: centerX, y: baseY + yStep * 0.5),
            CGPoint(x: centerX + xStep * 1.4, y: baseY + yStep * 0.5),
            CGPoint(x: centerX - xStep * 2.1, y: baseY + yStep * 1.5),
            CGPoint(x: centerX - xStep * 0.7, y: baseY + yStep * 1.5),
            CGPoint(x: centerX + xStep * 0.7, y: baseY + yStep * 1.5),
            CGPoint(x: centerX + xStep * 2.1, y: baseY + yStep * 1.5)
        ]

        return ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { index, position in
                ZStack {
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [.white, Color(white: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 15, height: 31)
                    Rectangle()
                        .fill(Color.red.opacity(0.88))
                        .frame(width: 13, height: 3)
                        .offset(y: -5)
                }
                .scaleEffect(index < 3 ? 0.72 : 0.80)
                .position(position)
            }
        }
        .shadow(color: .black.opacity(0.30), radius: 3, y: 2)
    }

    private func aimGuide(size: CGSize) -> some View {
        let normalized = CGFloat(line / 100)
        let startX = size.width * (0.17 + normalized * 0.66)
        let startY = size.height * 0.79
        let endX = size.width * (0.40 + normalized * 0.20)
        let endY = size.height * 0.30

        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(
                isAiming ? Color.pingoPrimary.opacity(0.92) : Color.white.opacity(0.70),
                style: StrokeStyle(lineWidth: isAiming ? 3 : 2, lineCap: .round, dash: [6, 6])
            )

            Circle()
                .stroke(Color.pingoPrimary.opacity(isAiming ? 0.95 : 0.55), lineWidth: 2)
                .frame(width: 28, height: 28)
                .position(x: endX, y: endY)
        }
        .allowsHitTesting(false)
    }

    private func bowlingBall(size: CGSize) -> some View {
        let x = size.width * CGFloat(0.17 + line / 100 * 0.66)
        let lift = isAiming ? min(14, CGFloat(power / 100) * 14) : 0

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.27, green: 0.30, blue: 0.46), Color(red: 0.08, green: 0.09, blue: 0.16), .black],
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
        .overlay { Circle().stroke(Color.white.opacity(0.12), lineWidth: 1) }
        .shadow(color: .black.opacity(0.42), radius: 7, y: 5)
        .scaleEffect(isAiming ? 1.05 : 1)
        .position(x: x, y: size.height * 0.82 - lift)
        .accessibilityLabel("Bowling ball. Drag sideways to aim and flick upward to roll.")
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

    private var aimReadout: some View {
        HStack(spacing: 6) {
            Text("L \(Int(line.rounded()))")
            Text("P \(Int(power.rounded()))")
        }
        .font(.system(size: 9, weight: .black, design: .rounded).monospacedDigit())
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.black.opacity(0.34), in: Capsule())
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: state.lastScore == 10 ? "burst.fill" : "scope")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.pingoPrimary)

            VStack(alignment: .leading, spacing: 1) {
                Text(state.lastSummary.isEmpty ? (canMove ? "YOUR ROLL" : "LANE READY") : state.lastSummary.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.64))
                Text(canMove ? "Drag sideways to aim, then flick upward to roll." : "Waiting for the next turn.")
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

    private var instructionBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw.fill")
                .foregroundStyle(Color.pingoPrimary)
            Text("SWIPE TO AIM • FLICK UP TO ROLL")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.4)
            Spacer()
            Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .black))
        }
        .foregroundStyle(.black.opacity(0.56))
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.white.opacity(0.64), in: Capsule())
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
}
