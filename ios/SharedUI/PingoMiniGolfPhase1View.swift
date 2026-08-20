import PingoCore
import SwiftUI

struct PingoMiniGolfPhase1View: View {
    let state: PingoMiniGolfState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.45

    private var course: PingoMiniGolfCourse {
        let index = min(max(state.holeIndex, 0), PingoMiniGolf.course.count - 1)
        return PingoMiniGolf.course[index]
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            courseStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            statusRibbon

            if canMove && !isHoled(player) {
                controls
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
                Text("HOLE \(state.holeIndex + 1)  •  PAR COURSE")
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

                courseGlow
                    .padding(9)

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

                fairwayTexture
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                    .padding(13)

                courseBorder
                    .padding(13)

                ForEach(Array(course.obstacles.enumerated()), id: \.offset) { index, obstacle in
                    obstacleView(obstacle: obstacle, index: index, size: size)
                }

                cupAndFlag(at: holePoint)

                if canMove && !isHoled(player) {
                    aimGuide(size: size)
                }

                ball(index: 1 - player, size: size, isLocal: false)
                ball(index: player, size: size, isLocal: true)

                VStack {
                    HStack {
                        holeBadge
                        Spacer()
                    }
                    Spacer()
                }
                .padding(22)
            }
        }
    }

    private var courseGlow: some View {
        RoundedRectangle(cornerRadius: 25, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.26), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }

    private var fairwayTexture: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<7, id: \.self) { stripe in
                    Rectangle()
                        .fill(Color.white.opacity(stripe.isMultiple(of: 2) ? 0.025 : 0.055))
                        .frame(width: proxy.size.width / 7 + 1)
                        .position(
                            x: proxy.size.width * (CGFloat(stripe) + 0.5) / 7,
                            y: proxy.size.height / 2
                        )
                }

                RadialGradient(
                    colors: [Color.white.opacity(0.08), .clear],
                    center: .topLeading,
                    startRadius: 5,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.85
                )
            }
        }
    }

    private var courseBorder: some View {
        RoundedRectangle(cornerRadius: 21, style: .continuous)
            .stroke(Color.white.opacity(0.34), lineWidth: 3)
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
                    .padding(5)
            }
    }

    private func obstacleView(obstacle: PingoRect, index: Int, size: CGSize) -> some View {
        let width = size.width * CGFloat(obstacle.maxX - obstacle.minX)
        let height = size.height * CGFloat(obstacle.maxY - obstacle.minY)
        let centerX = size.width * CGFloat((obstacle.minX + obstacle.maxX) / 2)
        let centerY = size.height * CGFloat((obstacle.minY + obstacle.maxY) / 2)

        return ZStack {
            RoundedRectangle(cornerRadius: min(width, height) * 0.22, style: .continuous)
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

            RoundedRectangle(cornerRadius: min(width, height) * 0.20, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .padding(2)

            if width > height * 1.35 {
                HStack(spacing: 3) {
                    ForEach(0..<max(2, Int(width / 24)), id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.09))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
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
                .shadow(color: .black.opacity(0.30), radius: 4, y: 2)

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
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        }
        .position(x: point.x, y: point.y)
    }

    private func ball(index: Int, size: CGSize, isLocal: Bool) -> some View {
        let position = state.positions.indices.contains(index) ? state.positions[index] : course.start
        let diameter: CGFloat = isLocal ? 20 : 15

        return ZStack {
            Circle()
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
            Circle()
                .stroke(isLocal ? Color.pingoPrimary.opacity(0.88) : Color.black.opacity(0.30), lineWidth: isLocal ? 2.2 : 1.4)
            Circle()
                .fill(Color.white.opacity(0.52))
                .frame(width: diameter * 0.22, height: diameter * 0.22)
                .offset(x: -diameter * 0.18, y: -diameter * 0.18)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.30), radius: 3, y: 2)
        .position(
            x: size.width * CGFloat(position.x),
            y: size.height * CGFloat(position.y)
        )
        .accessibilityLabel(isLocal ? "Your golf ball" : "Opponent golf ball")
    }

    private func aimGuide(size: CGSize) -> some View {
        let position = state.positions.indices.contains(player) ? state.positions[player] : course.start
        let start = CGPoint(
            x: size.width * CGFloat(position.x),
            y: size.height * CGFloat(position.y)
        )
        let radians = angle * .pi / 180
        let length = 54.0 + power * 72.0
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
                Color.white.opacity(0.82),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 6])
            )

            Circle()
                .stroke(Color.white.opacity(0.82), lineWidth: 1.5)
                .frame(width: 20, height: 20)
                .position(end)
        }
        .allowsHitTesting(false)
    }

    private var holeBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flag.fill")
                .font(.system(size: 9, weight: .black))
            Text("HOLE \(state.holeIndex + 1)")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.26), in: Capsule())
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: isHoled(player) ? "checkmark.circle.fill" : "scope")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isHoled(player) ? Color.green : Color.pingoPrimary)

            Text(statusText)
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

    private var controls: some View {
        VStack(spacing: 10) {
            controlRow(title: "Aim", value: Int(angle.rounded()), suffix: "°") {
                Slider(value: $angle, in: 0...359)
            }
            controlRow(title: "Power", value: Int((power * 100).rounded()), suffix: "%") {
                Slider(value: $power, in: 0.05...1)
            }
            sendButton(title: "Putt", icon: "flag.fill") {
                onMove(.miniGolf(.init(angleDegrees: angle, power: power)))
            }
        }
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

    private var statusText: String {
        if isHoled(player) { return "In the cup — waiting for your opponent" }
        return "Line up the putt and read the course"
    }
}
