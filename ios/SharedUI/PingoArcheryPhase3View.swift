import Foundation
import PingoCore
import SwiftUI

struct PingoArcheryPhase3View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var isAnimatingShot = false
    @State private var flightProgress: CGFloat = 0
    @State private var impactPulse = false
    @State private var pendingMove: PingoExtraGameMove?
    @State private var feedbackText = ""

    var body: some View {
        ZStack {
            PingoArcheryPhase1View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingShot,
                onMove: intercept
            )
            .allowsHitTesting(!isAnimatingShot)

            if isAnimatingShot {
                GeometryReader { proxy in
                    ZStack {
                        flightTrail(size: proxy.size)
                        animatedArrow(size: proxy.size)

                        if impactPulse {
                            Circle()
                                .stroke(Color.white.opacity(0.94), lineWidth: 4)
                                .frame(width: 64, height: 64)
                                .position(targetPoint(size: proxy.size))
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 3) {
                            Text(feedbackText.isEmpty ? "ARROW IN FLIGHT" : feedbackText)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                            Text(flightProgress > 0.88 ? "IMPACT LOCKED • SENDING TURN" : "WATCH THE TARGET")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.7)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.72), in: Capsule())
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.62)
                        .opacity(flightProgress > 0.34 ? 1 : 0)
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
        guard canMove, !isAnimatingShot else { return }

        pendingMove = move
        isAnimatingShot = true
        flightProgress = 0
        impactPulse = false
        feedbackText = ""

        let duration = 0.72
        withAnimation(.timingCurve(0.16, 0.76, 0.22, 1.0, duration: duration)) {
            flightProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.82) {
            guard isAnimatingShot else { return }
            feedbackText = impactFeedback(for: move)
            withAnimation(.spring(response: 0.24, dampingFraction: 0.56)) {
                impactPulse = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.30) {
            guard let pendingMove, isAnimatingShot else {
                resetAnimation()
                return
            }
            onMove(pendingMove)
            withAnimation(.easeOut(duration: 0.16)) {
                resetAnimation()
            }
        }
    }

    private func animatedArrow(size: CGSize) -> some View {
        let start = startPoint(size: size)
        let end = targetPoint(size: size)
        let control = controlPoint(start: start, end: end, size: size)
        let point = quadraticPoint(t: flightProgress, start: start, control: control, end: end)
        let angle = atan2(Double(end.y - start.y), Double(end.x - start.x)) * 180 / .pi
        let scale = max(0.72, 1 - flightProgress * 0.18)

        return PingoAnimatedArcheryArrow()
            .scaleEffect(scale)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.38), radius: 4, y: 3)
            .position(point)
    }

    private func flightTrail(size: CGSize) -> some View {
        let start = startPoint(size: size)
        let end = targetPoint(size: size)
        let control = controlPoint(start: start, end: end, size: size)

        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .trim(from: max(0, flightProgress - 0.34), to: min(1, flightProgress))
        .stroke(
            LinearGradient(
                colors: [.white.opacity(0.05), .white.opacity(0.72)],
                startPoint: .bottom,
                endPoint: .top
            ),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
        )
    }

    private func startPoint(size: CGSize) -> CGPoint {
        CGPoint(x: size.width * 0.5, y: size.height * 0.88)
    }

    private func targetPoint(size: CGSize) -> CGPoint {
        let move = pendingMove ?? .init(primary: 50, secondary: 50)
        let diameter = min(size.width * 0.58, size.height * 0.57)
        let radius = diameter * 0.42
        let horizontal = CGFloat(min(100, max(0, move.primary)) - 50) / 50
        let vertical = CGFloat(min(100, max(0, move.secondary)) - 50) / 50
        return CGPoint(
            x: size.width / 2 + horizontal * radius,
            y: size.height * 0.39 + vertical * radius
        )
    }

    private func controlPoint(start: CGPoint, end: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * 0.48,
            y: min(start.y, end.y) - size.height * 0.13
        )
    }

    private func impactFeedback(for move: PingoExtraGameMove) -> String {
        let dx = Double(min(100, max(0, move.primary)) - 50) / 50
        let dy = Double(min(100, max(0, move.secondary)) - 50) / 50
        let radius = (dx * dx + dy * dy).squareRoot()

        if radius <= 0.12 { return "BULLSEYE" }
        if radius <= 0.28 { return "GOLD RING" }
        if radius <= 0.46 { return "RED RING" }
        if radius <= 0.64 { return "BLUE RING" }
        if radius <= 0.84 { return "OUTER RING" }
        return "EDGE HIT"
    }

    private func quadraticPoint(t: CGFloat, start: CGPoint, control: CGPoint, end: CGPoint) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y
        )
    }

    private func resetAnimation() {
        isAnimatingShot = false
        flightProgress = 0
        impactPulse = false
        pendingMove = nil
        feedbackText = ""
    }
}

private struct PingoAnimatedArcheryArrow: View {
    var body: some View {
        HStack(spacing: -1) {
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 10))
                    path.addLine(to: CGPoint(x: 13, y: 2))
                    path.addLine(to: CGPoint(x: 13, y: 10))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.86, green: 0.12, blue: 0.12))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 10))
                    path.addLine(to: CGPoint(x: 13, y: 18))
                    path.addLine(to: CGPoint(x: 13, y: 10))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.22, green: 0.34, blue: 0.76))
            }
            .frame(width: 13, height: 20)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.60, green: 0.62, blue: 0.66)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 36, height: 4)

            ArcheryArrowTip()
                .fill(Color.white.opacity(0.92))
                .frame(width: 11, height: 9)
        }
        .frame(width: 60, height: 20)
    }
}

private struct ArcheryArrowTip: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
