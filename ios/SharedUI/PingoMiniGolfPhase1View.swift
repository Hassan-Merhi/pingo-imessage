import Foundation
import PingoCore
import SwiftUI

struct PingoMiniGolfPhase1View: View {
    let state: PingoMiniGolfState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.45
    @State private var isAiming = false
    @State private var flickLift: CGFloat = 0
    @State private var flickPower = 0.45

    private var course: PingoMiniGolfCourse {
        let index = min(max(state.holeIndex, 0), PingoMiniGolf.course.count - 1)
        return PingoMiniGolf.course[index]
    }

    var body: some View {
        VStack(spacing: 10) {
            header
            courseStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusRibbon

            if canMove && !isHoled(player) {
                puttDeck
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MINI GOLF")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("HOLE \(state.holeIndex + 1)  •  DIRECT PUTT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.44))
            }

            Spacer()

            HStack(spacing: 8) {
                scoreChip(title: "YOU", value: total(player), emphasized: true)
                scoreChip(title: "THEM", value: total(1 - player), emphasized: false)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
    }

    private var courseStage: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let localPosition = state.positions.indices.contains(player) ? state.positions[player] : course.start
            let localBall = CGPoint(
                x: size.width * CGFloat(localPosition.x),
                y: size.height * CGFloat(localPosition.y)
            )
            let holePoint = CGPoint(
                x: size.width * CGFloat(course.hole.x),
                y: size.height * CGFloat(course.hole.y)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.055, green: 0.22, blue: 0.16),
                                Color(red: 0.075, green: 0.34, blue: 0.19),
                                Color(red: 0.035, green: 0.16, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.28), radius: 12, y: 6)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.19, green: 0.66, blue: 0.32),
                                Color(red: 0.11, green: 0.52, blue: 0.24)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(13)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 2)
                            .padding(13)
                    }

                fairwayStripes(size: size)

                ForEach(Array(course.obstacles.enumerated()), id: \.offset) { index, obstacle in
                    obstacleView(obstacle: obstacle, index: index, size: size)
                }

                cupAndFlag(at: holePoint)

                if canMove && !isHoled(player) {
                    aimGuide(from: localBall)
                }

                ball(index: 1 - player, size: size, isLocal: false)
                ball(index: player, size: size, isLocal: true)

                VStack {
                    HStack {
                        Label("HOLE \(state.holeIndex + 1)", systemImage: "flag.fill")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.94))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.26), in: Capsule())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(22)
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .gesture(canMove && !isHoled(player) ? aimGesture(size: size, ballPoint: localBall) : nil)
        }
    }

    private func fairwayStripes(size: CGSize) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.025 : 0.055))
            }
        }
        .padding(13)
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .allowsHitTesting(false)
    }

    private func obstacleView(obstacle: PingoRect, index: Int, size: CGSize) -> some View {
        let width = size.width * CGFloat(obstacle.maxX - obstacle.minX)
        let height = size.height * CGFloat(obstacle.maxY - obstacle.minY)
        let centerX = size.width * CGFloat((obstacle.minX + obstacle.maxX) / 2)
        let centerY = size.height * CGFloat((obstacle.minY + obstacle.maxY) / 2)

        return RoundedRectangle(cornerRadius: min(width, height) * 0.22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.37, green: 0.23, blue: 0.11),
                        Color(red: 0.20, green: 0.11, blue: 0.055)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: min(width, height) * 0.20, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .padding(2)
            }
            .frame(width: max(width, 8), height: max(height, 8))
            .position(x: centerX, y: centerY)
            .shadow(color: .black.opacity(0.26), radius: 3, y: 2)
            .accessibilityLabel("Course obstacle \(index + 1)")
    }

    private func cupAndFlag(at point: CGPoint) -> some View {
        ZStack(alignment: .bottomLeading) {
            Ellipse()
                .fill(.black.opacity(0.72))
                .frame(width: 24, height: 13)
            Rectangle()
                .fill(Color.white.opacity(0.93))
                .frame(width: 2.5, height: 58)
                .offset(x: 10, y: -5)
            Path { path in
                path.move(to: CGPoint(x: 12, y: -61))
                path.addLine(to: CGPoint(x: 43, y: -51))
                path.addLine(to: CGPoint(x: 12, y: -40))
                path.closeSubpath()
            }
            .fill(Color(red: 0.95, green: 0.19, blue: 0.19))
        }
        .position(x: point.x, y: point.y)
        .allowsHitTesting(false)
    }

    private func ball(index: Int, size: CGSize, isLocal: Bool) -> some View {
        let position = state.positions.indices.contains(index) ? state.positions[index] : course.start
        let diameter: CGFloat = isLocal ? 20 : 15

        return Circle()
            .fill(
                RadialGradient(
                    colors: isLocal
                        ? [.white, Color.white.opacity(0.76)]
                        : [Color(white: 0.76), Color(white: 0.43)],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: diameter
                )
            )
            .overlay {
                Circle()
                    .stroke(isLocal ? Color.pingoPrimary.opacity(0.88) : Color.black.opacity(0.30), lineWidth: isLocal ? 2.2 : 1.4)
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.30), radius: 3, y: 2)
            .position(
                x: size.width * CGFloat(position.x),
                y: size.height * CGFloat(position.y)
            )
            .allowsHitTesting(false)
    }

    private func aimGuide(from start: CGPoint) -> some View {
        let radians = angle * .pi / 180
        let length = 52.0 + power * 94.0
        let end = CGPoint(
            x: start.x + CGFloat(cos(radians) * length),
            y: start.y + CGFloat(sin(radians) * length)
        )

        return ZStack {
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(
                Color.white.opacity(isAiming ? 0.96 : 0.76),
                style: StrokeStyle(lineWidth: isAiming ? 3 : 2, lineCap: .round, dash: [5, 6])
            )

            Circle()
                .stroke(Color.white.opacity(0.90), lineWidth: 2)
                .frame(width: isAiming ? 25 : 20, height: isAiming ? 25 : 20)
                .position(end)
        }
        .animation(.easeOut(duration: 0.12), value: isAiming)
        .allowsHitTesting(false)
    }

    private func aimGesture(size: CGSize, ballPoint: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let dx = value.location.x - ballPoint.x
                let dy = value.location.y - ballPoint.y
                guard abs(dx) + abs(dy) > 4 else { return }

                var degrees = atan2(Double(dy), Double(dx)) * 180 / .pi
                if degrees < 0 { degrees += 360 }
                angle = degrees

                let distance = hypot(dx, dy)
                let scale = max(90, min(size.width, size.height) * 0.45)
                power = min(1, max(0.08, Double(distance / scale)))
                isAiming = true
            }
            .onEnded { _ in
                isAiming = false
            }
    }

    private var puttDeck: some View {
        VStack(spacing: 7) {
            HStack {
                Label("Drag on the green to aim", systemImage: "scope")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Spacer()
                Text("\(Int(angle.rounded()))°  •  \(Int((power * 100).rounded()))%")
                    .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
            }
            .foregroundStyle(.black.opacity(0.54))

            ZStack {
                Capsule()
                    .fill(Color.pingoPrimary.opacity(0.11))
                    .overlay {
                        Capsule().stroke(Color.pingoPrimary.opacity(0.24), lineWidth: 1)
                    }

                VStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .black))
                    Text("FLICK UP TO PUTT")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.8)
                }
                .foregroundStyle(Color.pingoPrimary)
                .offset(y: -flickLift * 0.22)
            }
            .frame(height: 54)
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        flickLift = max(0, -value.translation.height)
                        flickPower = min(1, max(0.08, Double(flickLift / 120)))
                    }
                    .onEnded { value in
                        defer { flickLift = 0 }
                        guard value.translation.height < -28 else { return }

                        var releaseAngle = angle + Double(value.translation.width) * 0.25
                        while releaseAngle < 0 { releaseAngle += 360 }
                        while releaseAngle >= 360 { releaseAngle -= 360 }

                        let releasePower = max(power, flickPower)
                        onMove(.miniGolf(.init(angleDegrees: releaseAngle, power: releasePower)))
                    }
            )

            Text("Swipe farther for more power. Sideways motion fine-tunes the release angle.")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.38))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: isHoled(player) ? "checkmark.circle.fill" : "scope")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isHoled(player) ? Color.green : Color.pingoPrimary)

            Text(isHoled(player) ? "In the cup — waiting for your opponent" : "Aim directly on the course, then flick to putt")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))

            Spacer()

            Text("STROKE \(currentStroke)")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.38))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func scoreChip(title: String, value: Int, emphasized: Bool) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.5)
            Text("\(value)")
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
        }
        .foregroundStyle(emphasized ? Color.pingoPrimary : .black.opacity(0.62))
        .frame(width: 52, height: 42)
        .background(.white.opacity(emphasized ? 0.76 : 0.50), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func total(_ index: Int) -> Int {
        guard state.totals.indices.contains(index), state.holeStrokes.indices.contains(index) else { return 0 }
        return state.totals[index] + state.holeStrokes[index]
    }

    private func isHoled(_ index: Int) -> Bool {
        state.holed.indices.contains(index) ? state.holed[index] : false
    }

    private var currentStroke: Int {
        guard state.holeStrokes.indices.contains(player) else { return 1 }
        return state.holeStrokes[player] + (isHoled(player) ? 0 : 1)
    }
}
