import PingoCore
import SwiftUI

struct PingoAirHockeyPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isAnimatingShot = false
    @State private var shotProgress = 0.0
    @State private var impactPulse = false
    @State private var goalFlash = false
    @State private var pendingMove: PingoExtraGameMove?

    var body: some View {
        ZStack {
            PingoAirHockeyPhase1View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingShot,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingShot)

            if isAnimatingShot {
                GeometryReader { proxy in
                    ZStack {
                        shotTrail(size: proxy.size)
                        animatedPuck(size: proxy.size)

                        if impactPulse {
                            Circle()
                                .stroke(Color.white.opacity(0.94), lineWidth: 4)
                                .frame(width: 54, height: 54)
                                .position(impactPoint(size: proxy.size))
                                .transition(.scale.combined(with: .opacity))
                        }

                        if goalFlash {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cyan.opacity(0.28))
                                .frame(width: 20, height: proxy.size.height * 0.23)
                                .position(x: proxy.size.width * 0.91, y: impactPoint(size: proxy.size).y)
                                .transition(.opacity)
                        }

                        VStack(spacing: 3) {
                            Text(shotProgress > 0.88 ? "PUCK IMPACT" : "PUCK IN MOTION")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            Text(shotProgress > 0.88 ? "RESULT LOCKED • SENDING TURN" : "TRACK THE SHOT")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.7)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.72), in: Capsule())
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.66)
                        .opacity(shotProgress > 0.36 ? 1 : 0)
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
        .animation(.easeInOut(duration: 0.16), value: isAnimatingShot)
    }

    private func intercept(_ move: PingoExtraGameMove) {
        guard !isAnimatingShot else { return }

        pendingMove = move
        isAnimatingShot = true
        shotProgress = 0
        impactPulse = false
        goalFlash = false

        let normalizedPower = min(1, max(0.2, Double(move.secondary) / 100))
        let duration = 0.58 + (1.0 - normalizedPower) * 0.24

        withAnimation(.timingCurve(0.16, 0.74, 0.18, 1.0, duration: duration)) {
            shotProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.80) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.58)) {
                impactPulse = true
                goalFlash = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.26) {
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

    private func animatedPuck(size: CGSize) -> some View {
        let start = startPoint(size: size)
        let end = impactPoint(size: size)
        let t = CGFloat(shotProgress)
        let curve = sin(t * .pi) * size.height * 0.035
        let point = CGPoint(
            x: start.x + (end.x - start.x) * t,
            y: start.y + (end.y - start.y) * t - curve
        )

        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.92))
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 2)
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 10, height: 10)
                .offset(x: -5, y: -5)
        }
        .frame(width: 30, height: 30)
        .rotationEffect(.degrees(shotProgress * 1_080))
        .shadow(color: .black.opacity(0.38), radius: 5, y: 3)
        .position(point)
    }

    private func shotTrail(size: CGSize) -> some View {
        let start = startPoint(size: size)
        let end = impactPoint(size: size)
        let control = CGPoint(
            x: (start.x + end.x) * 0.5,
            y: min(start.y, end.y) - size.height * 0.06
        )

        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .trim(from: 0, to: min(1, shotProgress))
        .stroke(
            Color.white.opacity(0.48),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 7])
        )
    }

    private func startPoint(size: CGSize) -> CGPoint {
        let move = pendingMove ?? .init(primary: 50, secondary: 70)
        let normalizedLane = CGFloat(min(100, max(0, move.primary))) / 100
        return CGPoint(
            x: size.width * 0.42,
            y: size.height * (0.24 + normalizedLane * 0.52)
        )
    }

    private func impactPoint(size: CGSize) -> CGPoint {
        let move = pendingMove ?? .init(primary: 50, secondary: 70)
        let normalizedLane = CGFloat(min(100, max(0, move.primary))) / 100
        let centerY = size.height * (0.24 + normalizedLane * 0.52)
        let powerBias = CGFloat(min(100, max(0, move.secondary))) / 100
        let verticalDeflection = (powerBias - 0.5) * size.height * 0.08
        return CGPoint(x: size.width * 0.90, y: centerY - verticalDeflection)
    }

    private func resetAnimation() {
        isAnimatingShot = false
        shotProgress = 0
        impactPulse = false
        goalFlash = false
        pendingMove = nil
    }
}
