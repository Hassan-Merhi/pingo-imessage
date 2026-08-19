import PingoCore
import SwiftUI

struct PingoBasketballPhase3View: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var isAnimatingShot = false
    @State private var flightProgress = 0.0
    @State private var pendingPoints: Int?
    @State private var rimFlash = false
    @State private var netPulse = false

    var body: some View {
        ZStack {
            PingoBasketballPhase1View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingShot,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingShot)

            if isAnimatingShot {
                GeometryReader { proxy in
                    ZStack {
                        animatedBall(size: proxy.size)

                        if rimFlash {
                            Circle()
                                .stroke(Color.orange.opacity(0.9), lineWidth: 5)
                                .frame(width: 54, height: 18)
                                .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.37)
                                .transition(.opacity)
                        }

                        if netPulse {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 26, weight: .black))
                                .foregroundStyle(.white.opacity(0.85))
                                .position(x: proxy.size.width * 0.72, y: proxy.size.height * 0.45)
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 4) {
                            Text(resultTitle)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                            Text(resultSubtitle)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.8)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.68), in: Capsule())
                        .position(x: proxy.size.width * 0.50, y: proxy.size.height * 0.54)
                        .opacity(flightProgress > 0.82 ? 1 : 0)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 48)
                .padding(.bottom, 42)
                .allowsHitTesting(false)
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isAnimatingShot)
    }

    private func intercept(_ move: PingoPhysicsMove) {
        guard case .basketball(let shot) = move, !isAnimatingShot else {
            onMove(move)
            return
        }

        let points = (try? PingoBasketball.apply(shot, player: player, to: state).0.lastPoints) ?? 0
        pendingPoints = points
        isAnimatingShot = true
        flightProgress = 0
        rimFlash = false
        netPulse = false

        withAnimation(.timingCurve(0.20, 0.72, 0.30, 1.0, duration: 0.72)) {
            flightProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.54) {
            if points == 0 {
                withAnimation(.easeInOut(duration: 0.12)) { rimFlash = true }
            } else {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) { netPulse = true }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.92) {
            onMove(move)
            withAnimation(.easeOut(duration: 0.18)) {
                isAnimatingShot = false
                flightProgress = 0
                rimFlash = false
                netPulse = false
            }
            pendingPoints = nil
        }
    }

    private func animatedBall(size: CGSize) -> some View {
        let start = CGPoint(x: size.width * 0.27, y: size.height * 0.72)
        let hoop = CGPoint(x: size.width * 0.72, y: size.height * 0.37)
        let missOffset: CGFloat = pendingPoints == 0 ? 34 : 0
        let end = CGPoint(x: hoop.x + missOffset, y: hoop.y + (pendingPoints == 0 ? 12 : 58))
        let control = CGPoint(x: size.width * 0.50, y: size.height * 0.10)
        let point = quadraticPoint(t: CGFloat(flightProgress), start: start, control: control, end: end)
        let scale = 1.0 - 0.30 * flightProgress
        let spin = Angle.degrees(flightProgress * 520)

        return basketballGlyph
            .frame(width: 56, height: 56)
            .scaleEffect(scale)
            .rotationEffect(spin)
            .shadow(color: .black.opacity(0.38), radius: 6, y: 4)
            .position(point)
    }

    private var basketballGlyph: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.52, blue: 0.12), Color(red: 0.73, green: 0.19, blue: 0.025)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 34
                    )
                )
            Circle().stroke(Color.black.opacity(0.55), lineWidth: 2)
            Path { path in
                path.move(to: CGPoint(x: 3, y: 28))
                path.addQuadCurve(to: CGPoint(x: 53, y: 28), control: CGPoint(x: 28, y: 5))
                path.move(to: CGPoint(x: 3, y: 28))
                path.addQuadCurve(to: CGPoint(x: 53, y: 28), control: CGPoint(x: 28, y: 51))
                path.move(to: CGPoint(x: 28, y: 2))
                path.addLine(to: CGPoint(x: 28, y: 54))
            }
            .stroke(Color.black.opacity(0.55), lineWidth: 1.6)
        }
    }

    private var resultTitle: String {
        switch pendingPoints {
        case 3: return "SWISH +3"
        case 2: return "BUCKET +2"
        default: return "RIM OUT"
        }
    }

    private var resultSubtitle: String {
        pendingPoints == 0 ? "BALL SETTLES • TURN SENDS NEXT" : "CLEAN FINISH • TURN SENDS NEXT"
    }

    private func quadraticPoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }
}
