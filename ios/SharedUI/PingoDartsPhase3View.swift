import PingoCore
import SwiftUI

struct PingoDartsPhase3View: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var isAnimatingVisit = false
    @State private var animatedDarts: [PingoDartPoint] = []
    @State private var activeDartIndex = -1
    @State private var flightProgress: CGFloat = 0
    @State private var impactIndex = -1
    @State private var impactPulse = false
    @State private var feedbackText = ""

    var body: some View {
        ZStack {
            PingoDartsPhase2View(
                state: state,
                player: player,
                canMove: canMove && !isAnimatingVisit,
                onMove: beginAnimatedVisit
            )
            .allowsHitTesting(!isAnimatingVisit)

            if isAnimatingVisit {
                flightOverlay
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isAnimatingVisit)
        .onChange(of: state.remaining) { _ in
            resetAnimationState()
        }
    }

    private var flightOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.08)

                if animatedDarts.indices.contains(activeDartIndex) {
                    let target = targetPosition(for: animatedDarts[activeDartIndex], in: proxy.size)
                    let start = CGPoint(x: proxy.size.width * 0.50, y: proxy.size.height * 0.96)
                    let control = CGPoint(
                        x: (start.x + target.x) / 2 + CGFloat(animatedDarts[activeDartIndex].x) * 28,
                        y: min(start.y, target.y) - proxy.size.height * 0.14
                    )
                    let position = quadraticPoint(start: start, control: control, end: target, t: flightProgress)

                    PingoAnimatedDart()
                        .rotationEffect(.degrees(-14 + Double(animatedDarts[activeDartIndex].x) * 10))
                        .position(position)
                        .shadow(color: .black.opacity(0.42), radius: 4, y: 3)

                    Path { path in
                        path.move(to: start)
                        path.addQuadCurve(to: target, control: control)
                    }
                    .trim(from: max(0, flightProgress - 0.22), to: flightProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.05), .white.opacity(0.72)],
                            startPoint: .bottom,
                            endPoint: .top
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                }

                ForEach(Array(animatedDarts.enumerated()), id: \.offset) { index, dart in
                    if index <= impactIndex {
                        let position = targetPosition(for: dart, in: proxy.size)

                        PingoAnimatedDart()
                            .scaleEffect(0.88)
                            .rotationEffect(.degrees(-13 + Double(dart.x) * 9))
                            .position(position)

                        if index == impactIndex {
                            Circle()
                                .stroke(Color.white.opacity(0.78), lineWidth: 2)
                                .frame(width: impactPulse ? 58 : 18, height: impactPulse ? 58 : 18)
                                .opacity(impactPulse ? 0 : 0.9)
                                .position(position)
                        }
                    }
                }

                VStack(spacing: 4) {
                    Text(feedbackText.isEmpty ? "DARTS IN FLIGHT" : feedbackText)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(1)
                    Text("Visit locks while each dart lands")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.black.opacity(0.72), in: Capsule())
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(feedbackText.isEmpty ? "Darts in flight" : feedbackText)
    }

    private func beginAnimatedVisit(_ move: PingoPhysicsMove) {
        guard canMove, !isAnimatingVisit else { return }
        guard case .darts(let visit) = move, visit.darts.count == 3 else {
            onMove(move)
            return
        }

        animatedDarts = visit.darts
        activeDartIndex = 0
        impactIndex = -1
        flightProgress = 0
        feedbackText = ""
        isAnimatingVisit = true

        animateDart(index: 0, move: move)
    }

    private func animateDart(index: Int, move: PingoPhysicsMove) {
        guard animatedDarts.indices.contains(index) else {
            finishAnimatedVisit(move)
            return
        }

        activeDartIndex = index
        flightProgress = 0

        withAnimation(.easeIn(duration: 0.30)) {
            flightProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.31) {
            guard isAnimatingVisit else { return }
            impactIndex = index
            feedbackText = impactFeedback(for: animatedDarts[index])
            impactPulse = false
            withAnimation(.easeOut(duration: 0.34)) {
                impactPulse = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard isAnimatingVisit else { return }
                animateDart(index: index + 1, move: move)
            }
        }
    }

    private func finishAnimatedVisit(_ move: PingoPhysicsMove) {
        activeDartIndex = -1
        feedbackText = "VISIT SENT"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            guard isAnimatingVisit else { return }
            onMove(move)
            resetAnimationState()
        }
    }

    private func impactFeedback(for dart: PingoDartPoint) -> String {
        let radius = sqrt(dart.x * dart.x + dart.y * dart.y)
        if radius <= 0.055 { return "BULLSEYE • 50" }
        if radius <= 0.13 { return "OUTER BULL • 25" }
        if radius >= 0.78 && radius <= 0.90 { return "DOUBLE RING" }
        if radius >= 0.52 && radius <= 0.64 { return "TRIPLE RING" }
        if radius > 1 { return "MISS" }
        return "THUNK"
    }

    private func targetPosition(for dart: PingoDartPoint, in size: CGSize) -> CGPoint {
        let boardDiameter = min(size.width * 0.86, size.height * 0.58)
        let radius = boardDiameter / 2
        let center = CGPoint(x: size.width / 2, y: size.height * 0.38)
        return CGPoint(
            x: center.x + CGFloat(dart.x) * radius,
            y: center.y + CGFloat(dart.y) * radius
        )
    }

    private func quadraticPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y
        )
    }

    private func resetAnimationState() {
        isAnimatingVisit = false
        animatedDarts = []
        activeDartIndex = -1
        flightProgress = 0
        impactIndex = -1
        impactPulse = false
        feedbackText = ""
    }
}

private struct PingoAnimatedDart: View {
    var body: some View {
        HStack(spacing: -1) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addLine(to: CGPoint(x: 11, y: 3))
                path.addLine(to: CGPoint(x: 11, y: 13))
                path.closeSubpath()
            }
            .fill(Color(red: 0.86, green: 0.12, blue: 0.10))
            .frame(width: 11, height: 16)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.64, green: 0.67, blue: 0.70)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 25, height: 5)

            TriangleTip()
                .fill(Color.white.opacity(0.88))
                .frame(width: 9, height: 7)
        }
        .frame(width: 45, height: 18)
    }
}

private struct TriangleTip: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
