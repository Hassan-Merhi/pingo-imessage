import PingoCore
import SwiftUI

struct PingoBowlingPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isAnimatingRoll = false
    @State private var rollProgress = 0.0
    @State private var impactPulse = false
    @State private var pinScatter = false
    @State private var pendingMove: PingoExtraGameMove?

    var body: some View {
        ZStack {
            PingoBowlingPhase2View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingRoll,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingRoll)

            if isAnimatingRoll {
                GeometryReader { proxy in
                    ZStack {
                        rollTrail(size: proxy.size)
                        animatedBall(size: proxy.size)
                        animatedPins(size: proxy.size)

                        if impactPulse {
                            Circle()
                                .stroke(Color.white.opacity(0.92), lineWidth: 4)
                                .frame(width: 58, height: 58)
                                .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.25)
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 3) {
                            Text(rollProgress > 0.88 ? "PIN IMPACT" : "BALL IN MOTION")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            Text(rollProgress > 0.88 ? "RESULT LOCKED • SENDING TURN" : "WATCH THE LINE")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.7)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.72), in: Capsule())
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.59)
                        .opacity(rollProgress > 0.42 ? 1 : 0)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 44)
                .padding(.bottom, 82)
                .allowsHitTesting(false)
                .transition(.opacity)
                .zIndex(4)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isAnimatingRoll)
    }

    private func intercept(_ move: PingoExtraGameMove) {
        guard !isAnimatingRoll else { return }

        pendingMove = move
        isAnimatingRoll = true
        rollProgress = 0
        impactPulse = false
        pinScatter = false

        let normalizedPower = min(1, max(0.2, Double(move.secondary) / 100))
        let duration = 0.72 + (1.0 - normalizedPower) * 0.24

        withAnimation(.timingCurve(0.14, 0.72, 0.20, 1.0, duration: duration)) {
            rollProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.78) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.56)) {
                impactPulse = true
                pinScatter = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.28) {
            guard let pendingMove else {
                resetAnimation()
                return
            }
            onMove(pendingMove)
            withAnimation(.easeOut(duration: 0.16)) {
                resetAnimation()
            }
        }
    }

    private func animatedBall(size: CGSize) -> some View {
        let move = pendingMove ?? .init(primary: 50, secondary: 70)
        let t = CGFloat(rollProgress)
        let normalizedLine = CGFloat(min(100, max(0, move.primary))) / 100
        let startX = size.width * (0.17 + normalizedLine * 0.66)
        let endX = size.width * (0.42 + normalizedLine * 0.16)
        let startY = size.height * 0.82
        let endY = size.height * 0.25
        let point = CGPoint(
            x: startX + (endX - startX) * t,
            y: startY + (endY - startY) * t
        )
        let scale = max(0.38, 1 - t * 0.54)

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.30, green: 0.33, blue: 0.52), Color(red: 0.08, green: 0.09, blue: 0.16), .black],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 34
                    )
                )
            HStack(spacing: 3) {
                Circle().fill(.black.opacity(0.72)).frame(width: 5, height: 5)
                VStack(spacing: 2) {
                    Circle().fill(.black.opacity(0.72)).frame(width: 4, height: 4)
                    Circle().fill(.black.opacity(0.72)).frame(width: 4, height: 4)
                }
            }
            .offset(x: 6, y: -6)
        }
        .frame(width: 66, height: 66)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rollProgress * 1_080))
        .shadow(color: .black.opacity(0.38), radius: 5, y: 4)
        .position(point)
    }

    private func rollTrail(size: CGSize) -> some View {
        let move = pendingMove ?? .init(primary: 50, secondary: 70)
        let normalizedLine = CGFloat(min(100, max(0, move.primary))) / 100
        let start = CGPoint(x: size.width * (0.17 + normalizedLine * 0.66), y: size.height * 0.82)
        let end = CGPoint(x: size.width * (0.42 + normalizedLine * 0.16), y: size.height * 0.25)

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .trim(from: 0, to: min(1, rollProgress))
        .stroke(
            Color.white.opacity(0.46),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 7])
        )
    }

    private func animatedPins(size: CGSize) -> some View {
        let centerX = size.width * 0.5
        let baseY = size.height * 0.25
        let xStep = size.width * 0.035
        let yStep = size.height * 0.023
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
                        .frame(width: 13, height: 28)
                    Rectangle()
                        .fill(Color.red.opacity(0.88))
                        .frame(width: 11, height: 3)
                        .offset(y: -4)
                }
                .rotationEffect(.degrees(pinScatter ? Double((index % 2 == 0 ? -1 : 1) * (18 + index * 5)) : 0))
                .offset(
                    x: pinScatter ? CGFloat((index % 3) - 1) * CGFloat(10 + index * 2) : 0,
                    y: pinScatter ? CGFloat(10 + (index % 4) * 4) : 0
                )
                .opacity(pinScatter ? 0.72 : 1)
                .position(position)
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
    }

    private func resetAnimation() {
        isAnimatingRoll = false
        rollProgress = 0
        impactPulse = false
        pinScatter = false
        pendingMove = nil
    }
}
