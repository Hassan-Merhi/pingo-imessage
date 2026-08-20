import PingoCore
import SwiftUI

struct PingoMiniGolfPhase3View: View {
    let state: PingoMiniGolfState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var isAnimatingPutt = false
    @State private var rollProgress = 0.0
    @State private var pendingEnd: PingoVector2?
    @State private var pendingHoled = false
    @State private var pendingAutoFinished = false
    @State private var pendingShot: PingoAimShot?
    @State private var impactPulse = false

    var body: some View {
        ZStack {
            PingoMiniGolfPhase1View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingPutt,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingPutt)

            if isAnimatingPutt {
                GeometryReader { proxy in
                    ZStack {
                        puttTrail(size: proxy.size)
                        animatedBall(size: proxy.size)

                        if impactPulse {
                            Circle()
                                .stroke(pendingHoled ? Color.green.opacity(0.95) : Color.white.opacity(0.88), lineWidth: 4)
                                .frame(width: pendingHoled ? 46 : 34, height: pendingHoled ? 46 : 34)
                                .position(endPoint(size: proxy.size))
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 3) {
                            Text(resultTitle)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                            Text(resultSubtitle)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.7)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.70), in: Capsule())
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.58)
                        .opacity(rollProgress > 0.80 ? 1 : 0)
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
        .animation(.easeInOut(duration: 0.16), value: isAnimatingPutt)
    }

    private func intercept(_ move: PingoPhysicsMove) {
        guard case .miniGolf(let shot) = move, !isAnimatingPutt else {
            onMove(move)
            return
        }

        guard let result = try? PingoMiniGolf.apply(shot, player: player, to: state),
              result.state.positions.indices.contains(player) else {
            onMove(move)
            return
        }

        pendingShot = shot
        pendingEnd = result.state.positions[player]
        pendingHoled = result.state.holed.indices.contains(player) && result.state.holed[player]
        pendingAutoFinished = result.state.lastAutoFinished
        isAnimatingPutt = true
        rollProgress = 0
        impactPulse = false

        let duration = 0.76 + (0.34 * shot.power)
        withAnimation(.timingCurve(0.18, 0.72, 0.22, 1.0, duration: duration)) {
            rollProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.78) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.58)) {
                impactPulse = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.25) {
            onMove(move)
            withAnimation(.easeOut(duration: 0.16)) {
                isAnimatingPutt = false
                rollProgress = 0
                impactPulse = false
            }
            pendingEnd = nil
            pendingShot = nil
            pendingHoled = false
            pendingAutoFinished = false
        }
    }

    private func animatedBall(size: CGSize) -> some View {
        let point = animatedPoint(size: size)
        let spin = Angle.degrees(rollProgress * 860)
        let scale = pendingHoled ? max(0.42, 1.0 - rollProgress * 0.58) : 1.0

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color.white.opacity(0.72)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 13
                    )
                )
            Circle()
                .stroke(Color.pingoPrimary.opacity(0.92), lineWidth: 2.2)
            Circle()
                .fill(Color.black.opacity(0.14))
                .frame(width: 3, height: 3)
                .offset(x: 4, y: -3)
        }
        .frame(width: 21, height: 21)
        .scaleEffect(scale)
        .rotationEffect(spin)
        .shadow(color: .black.opacity(0.32), radius: 4, y: 3)
        .position(point)
    }

    private func puttTrail(size: CGSize) -> some View {
        Path { path in
            let start = startPoint(size: size)
            let control = controlPoint(size: size)
            let end = endPoint(size: size)
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .trim(from: 0, to: min(1, rollProgress))
        .stroke(
            Color.white.opacity(0.48),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
        )
    }

    private func animatedPoint(size: CGSize) -> CGPoint {
        quadraticPoint(
            t: CGFloat(rollProgress),
            start: startPoint(size: size),
            control: controlPoint(size: size),
            end: endPoint(size: size)
        )
    }

    private func startPoint(size: CGSize) -> CGPoint {
        let course = currentCourse
        let position = state.positions.indices.contains(player) ? state.positions[player] : course.start
        return CGPoint(x: size.width * CGFloat(position.x), y: size.height * CGFloat(position.y))
    }

    private func endPoint(size: CGSize) -> CGPoint {
        let end = pendingEnd ?? (state.positions.indices.contains(player) ? state.positions[player] : currentCourse.start)
        return CGPoint(x: size.width * CGFloat(end.x), y: size.height * CGFloat(end.y))
    }

    private func controlPoint(size: CGSize) -> CGPoint {
        let start = startPoint(size: size)
        let end = endPoint(size: size)
        let midpoint = CGPoint(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let bend = min(26, max(8, CGFloat((pendingShot?.power ?? 0.4) * 22)))
        return CGPoint(
            x: midpoint.x - (dy / length) * bend,
            y: midpoint.y + (dx / length) * bend
        )
    }

    private var currentCourse: PingoMiniGolfCourse {
        let index = min(max(state.holeIndex, 0), PingoMiniGolf.course.count - 1)
        return PingoMiniGolf.course[index]
    }

    private var resultTitle: String {
        if pendingAutoFinished { return "HOLE COMPLETE" }
        if pendingHoled { return "IN THE CUP!" }
        return "BALL SETTLED"
    }

    private var resultSubtitle: String {
        if pendingAutoFinished { return "STROKE LIMIT REACHED • TURN SENDS NEXT" }
        if pendingHoled { return "CLEAN FINISH • TURN SENDS NEXT" }
        return "ROLL COMPLETE • TURN SENDS NEXT"
    }

    private func quadraticPoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }
}
