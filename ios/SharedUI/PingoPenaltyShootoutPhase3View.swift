import PingoCore
import SwiftUI

struct PingoPenaltyShootoutPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isAnimatingKick = false
    @State private var kickProgress = 0.0
    @State private var keeperDiveProgress = 0.0
    @State private var goalPulse = false
    @State private var pendingMove: PingoExtraGameMove?

    var body: some View {
        ZStack {
            PingoPenaltyShootoutPhase2View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingKick,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingKick)

            if isAnimatingKick {
                GeometryReader { proxy in
                    ZStack {
                        shotTrail(size: proxy.size)
                        animatedKeeper(size: proxy.size)
                        animatedBall(size: proxy.size)

                        if goalPulse {
                            Circle()
                                .stroke(Color.white.opacity(0.94), lineWidth: 4)
                                .frame(width: 74, height: 74)
                                .position(targetPoint(size: proxy.size))
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 3) {
                            Text(kickProgress > 0.88 ? "SHOT COMPLETE" : "BALL IN FLIGHT")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            Text(kickProgress > 0.88 ? "RESULT LOCKED • SENDING TURN" : "WATCH THE FINISH")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.7)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.72), in: Capsule())
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.60)
                        .opacity(kickProgress > 0.32 ? 1 : 0)
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
        .animation(.easeInOut(duration: 0.16), value: isAnimatingKick)
    }

    private func intercept(_ move: PingoExtraGameMove) {
        guard !isAnimatingKick else { return }

        pendingMove = move
        isAnimatingKick = true
        kickProgress = 0
        keeperDiveProgress = 0
        goalPulse = false

        let normalizedPower = min(1, max(0.2, Double(move.secondary) / 100))
        let duration = 0.58 + (1.0 - normalizedPower) * 0.26

        withAnimation(.timingCurve(0.18, 0.72, 0.22, 1.0, duration: duration)) {
            kickProgress = 1
        }

        withAnimation(.easeOut(duration: duration * 0.82)) {
            keeperDiveProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.82) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
                goalPulse = true
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
        let t = CGFloat(kickProgress)
        let start = CGPoint(x: size.width * 0.5, y: size.height * 0.79)
        let end = targetPoint(size: size)
        let control = CGPoint(
            x: start.x + (end.x - start.x) * 0.52,
            y: min(start.y, end.y) - size.height * 0.18
        )
        let point = quadraticPoint(t: t, start: start, control: control, end: end)
        let scale = max(0.48, 1 - t * 0.46)

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.84)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 30
                    )
                )
            Image(systemName: "soccerball")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.black.opacity(0.84))
        }
        .frame(width: 58, height: 58)
        .scaleEffect(scale)
        .rotationEffect(.degrees(kickProgress * 720))
        .shadow(color: .black.opacity(0.34), radius: 5, y: 3)
        .position(point)
    }

    private func animatedKeeper(size: CGSize) -> some View {
        let move = pendingMove ?? .init(primary: 2, secondary: 72)
        let target = min(4, max(0, move.primary))
        let direction: CGFloat
        switch target {
        case 0, 1:
            direction = -1
        case 3, 4:
            direction = 1
        default:
            direction = 0
        }

        let progress = CGFloat(keeperDiveProgress)
        let travel = size.width * 0.15 * direction * progress
        let rotation = Double(direction * progress * 28)

        return VStack(spacing: -2) {
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
        .rotationEffect(.degrees(rotation))
        .offset(x: travel, y: -abs(travel) * 0.08)
        .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
        .position(x: size.width * 0.5, y: size.height * 0.29)
    }

    private func shotTrail(size: CGSize) -> some View {
        let start = CGPoint(x: size.width * 0.5, y: size.height * 0.79)
        let end = targetPoint(size: size)
        let control = CGPoint(
            x: start.x + (end.x - start.x) * 0.52,
            y: min(start.y, end.y) - size.height * 0.18
        )

        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .trim(from: 0, to: min(1, kickProgress))
        .stroke(
            Color.white.opacity(0.46),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 7])
        )
    }

    private func targetPoint(size: CGSize) -> CGPoint {
        let move = pendingMove ?? .init(primary: 2, secondary: 72)
        let xs: [CGFloat] = [0.26, 0.36, 0.50, 0.64, 0.74]
        let ys: [CGFloat] = [0.18, 0.30, 0.17, 0.30, 0.18]
        let index = min(4, max(0, move.primary))
        return CGPoint(x: size.width * xs[index], y: size.height * ys[index])
    }

    private func quadraticPoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y
        )
    }

    private func resetAnimation() {
        isAnimatingKick = false
        kickProgress = 0
        keeperDiveProgress = 0
        goalPulse = false
        pendingMove = nil
    }
}
