import PingoCore
import SwiftUI

struct PingoEightBallPhase1View: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.58

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    var body: some View {
        VStack(spacing: 10) {
            poolPlayerBar

            HStack(alignment: .center, spacing: 8) {
                powerRail

                PingoPremiumPoolTable(state: state, angle: angle, showAim: canMove)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(0.51, contentMode: .fit)

                spinBadge
            }
            .frame(maxHeight: .infinity)

            if canMove {
                aimControls
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private var poolPlayerBar: some View {
        HStack(spacing: 8) {
            poolPlayerChip(
                playerRef: opponentPlayer,
                playerIndex: player == 0 ? 1 : 0,
                isLocal: false
            )

            Spacer(minLength: 4)

            VStack(spacing: 3) {
                Text(state.groups == [0, 0] ? "OPEN TABLE" : "8 BALL")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .tracking(0.8)

                Text(canMove ? "YOUR TURN" : "MATCH IN PROGRESS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(canMove ? Color(red: 0.73, green: 0.94, blue: 0.87) : .white.opacity(0.52))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.78), in: Capsule())

            Spacer(minLength: 4)

            poolPlayerChip(
                playerRef: localPlayer,
                playerIndex: player,
                isLocal: true
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.92), Color.black.opacity(0.76)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 7, y: 3)
    }

    private func poolPlayerChip(playerRef: PingoPlayerRef?, playerIndex: Int, isLocal: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)

                Image(systemName: "person.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.78))
            }
            .overlay {
                Circle()
                    .stroke(isLocal && canMove ? Color.white.opacity(0.92) : Color.white.opacity(0.18), lineWidth: isLocal && canMove ? 2 : 1)
            }

            Text(playerRef.map { "@\($0.displayName)" } ?? "Waiting…")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
                .frame(maxWidth: 82)

            groupIndicator(for: playerIndex)
        }
        .frame(width: 78)
    }

    @ViewBuilder
    private func groupIndicator(for playerIndex: Int) -> some View {
        let group = state.groups.indices.contains(playerIndex) ? state.groups[playerIndex] : 0
        if group == 0 {
            Text("OPEN")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        } else {
            HStack(spacing: 3) {
                ForEach(group == 1 ? 1...3 : 9...11, id: \.self) { id in
                    PingoPoolBallToken(id: id)
                        .frame(width: 11, height: 11)
                }
            }
        }
    }

    private var powerRail: some View {
        VStack(spacing: 8) {
            Text("POWER")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.46))
                .tracking(0.6)

            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: 8, height: 174)

                GeometryReader { proxy in
                    VStack {
                        Spacer(minLength: 0)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.96, green: 0.27, blue: 0.23), Color(red: 0.98, green: 0.72, blue: 0.18)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 8, height: max(10, proxy.size.height * power))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 8, height: 174)

                Slider(value: $power, in: 0.05...1)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 174)
                    .opacity(0.02)
                    .disabled(!canMove)
            }
            .frame(width: 30, height: 174)

            Text("\(Int((power * 100).rounded()))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.56))
        }
        .frame(width: 38)
    }

    private var spinBadge: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, Color(white: 0.90)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

                Circle()
                    .fill(Color(red: 0.86, green: 0.16, blue: 0.15))
                    .frame(width: 9, height: 9)
                    .offset(y: 2)
            }
            .overlay {
                Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
            }

            Text("SPIN")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.44))
                .tracking(0.6)
        }
        .frame(width: 44)
    }

    private var aimControls: some View {
        HStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.52))

            Slider(value: $angle, in: 0...359)
                .tint(Color.black.opacity(0.72))

            Text("\(Int(angle.rounded()))°")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(.black.opacity(0.62))
                .frame(width: 42, alignment: .trailing)

            Button {
                onMove(.eightBall(.init(angleDegrees: angle, power: power)))
            } label: {
                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 40)
                    .background(Color.black.opacity(0.88), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shoot and send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct PingoPremiumPoolTable: View {
    let state: PingoEightBallState
    let angle: Double
    let showAim: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rail = max(18.0, min(28.0, size.width * 0.085))
            let feltRect = CGRect(
                x: rail,
                y: rail,
                width: max(1, size.width - rail * 2),
                height: max(1, size.height - rail * 2)
            )
            let ballSize = max(14.0, min(21.0, feltRect.width * 0.075))

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.black.opacity(0.15))
                    .offset(y: 5)
                    .blur(radius: 5)

                woodCabinet
                railInlay
                feltSurface(rail: rail)
                railDiamonds(size: size, rail: rail)
                pocketLayer(feltRect: feltRect, ballSize: ballSize)

                if showAim, let cue = state.balls.first(where: { $0.id == 0 && !$0.pocketed }) {
                    cueAndAimLayer(cuePosition: cue.position, feltRect: feltRect)
                }

                ForEach(state.balls.filter { !$0.pocketed }) { ball in
                    PingoPoolBallToken(id: ball.id)
                        .frame(width: ballSize, height: ballSize)
                        .shadow(color: .black.opacity(0.30), radius: 2.2, x: 1.3, y: 2.2)
                        .position(tablePoint(ball.position, feltRect: feltRect))
                        .accessibilityLabel(ball.id == 0 ? "Cue ball" : "Ball \(ball.id)")
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private var woodCabinet: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.085, blue: 0.045),
                        Color(red: 0.43, green: 0.20, blue: 0.10),
                        Color(red: 0.24, green: 0.10, blue: 0.055)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.34), radius: 10, y: 6)
    }

    private var railInlay: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [Color(red: 0.66, green: 0.39, blue: 0.19), Color(red: 0.16, green: 0.065, blue: 0.035)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 7
            )
            .padding(8)
    }

    private func feltSurface(rail: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.50, blue: 0.42),
                        Color(red: 0.015, green: 0.39, blue: 0.34),
                        Color(red: 0.025, green: 0.46, blue: 0.39)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .padding(rail)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.24), lineWidth: 3)
                    .padding(rail - 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.035), lineWidth: 1)
                    .padding(rail + 3)
            }
    }

    @ViewBuilder
    private func railDiamonds(size: CGSize, rail: CGFloat) -> some View {
        let longFractions: [CGFloat] = [0.18, 0.34, 0.66, 0.82]
        let sideX = max(6, rail * 0.47)
        let diamondSize = max(3.5, rail * 0.18)

        ForEach(Array(longFractions.enumerated()), id: \.offset) { _, fraction in
            DiamondMark()
                .fill(Color.white.opacity(0.70))
                .frame(width: diamondSize, height: diamondSize)
                .position(x: sideX, y: size.height * fraction)

            DiamondMark()
                .fill(Color.white.opacity(0.70))
                .frame(width: diamondSize, height: diamondSize)
                .position(x: size.width - sideX, y: size.height * fraction)
        }

        DiamondMark()
            .fill(Color.white.opacity(0.70))
            .frame(width: diamondSize, height: diamondSize)
            .position(x: size.width * 0.5, y: sideX)

        DiamondMark()
            .fill(Color.white.opacity(0.70))
            .frame(width: diamondSize, height: diamondSize)
            .position(x: size.width * 0.5, y: size.height - sideX)
    }

    @ViewBuilder
    private func pocketLayer(feltRect: CGRect, ballSize: CGFloat) -> some View {
        let pocketSize = max(22.0, ballSize * 1.65)
        ForEach(Array(pocketCoordinates.enumerated()), id: \.offset) { _, pocket in
            let point = tablePoint(pocket, feltRect: feltRect)
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.42))
                    .frame(width: pocketSize + 6, height: pocketSize + 6)
                    .blur(radius: 1.5)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.black, Color(red: 0.07, green: 0.055, blue: 0.045)],
                            center: .center,
                            startRadius: 2,
                            endRadius: pocketSize * 0.5
                        )
                    )
                    .frame(width: pocketSize, height: pocketSize)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
            }
            .position(point)
        }
    }

    @ViewBuilder
    private func cueAndAimLayer(cuePosition: PingoVector2, feltRect: CGRect) -> some View {
        let start = tablePoint(cuePosition, feltRect: feltRect)
        let radians = angle * .pi / 180
        let dx = CGFloat(sin(radians))
        let dy = CGFloat(-cos(radians))
        let forwardLength = max(feltRect.width, feltRect.height) * 0.72
        let backLength = min(feltRect.height * 0.28, 150)
        let cueStart = CGPoint(x: start.x - dx * 10, y: start.y - dy * 10)
        let cueEnd = CGPoint(x: start.x - dx * backLength, y: start.y - dy * backLength)

        Path { path in
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + dx * forwardLength, y: start.y + dy * forwardLength))
        }
        .stroke(Color.white.opacity(0.78), style: StrokeStyle(lineWidth: 1.4, dash: [6, 6], dashPhase: 1))

        Path { path in
            path.move(to: cueStart)
            path.addLine(to: cueEnd)
        }
        .stroke(Color.black.opacity(0.32), style: StrokeStyle(lineWidth: 8, lineCap: .round))

        Path { path in
            path.move(to: cueStart)
            path.addLine(to: cueEnd)
        }
        .stroke(Color(red: 0.80, green: 0.62, blue: 0.34), style: StrokeStyle(lineWidth: 4.8, lineCap: .round))
    }

    private var pocketCoordinates: [PingoVector2] {
        [
            .init(x: 0.035, y: 0.055),
            .init(x: 0.500, y: 0.045),
            .init(x: 0.965, y: 0.055),
            .init(x: 0.035, y: 0.945),
            .init(x: 0.500, y: 0.955),
            .init(x: 0.965, y: 0.945)
        ]
    }

    private func tablePoint(_ point: PingoVector2, feltRect: CGRect) -> CGPoint {
        CGPoint(
            x: feltRect.minX + feltRect.width * CGFloat(point.y),
            y: feltRect.minY + feltRect.height * CGFloat(1 - point.x)
        )
    }
}

private struct PingoPoolBallToken: View {
    let id: Int

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                if id == 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, Color(white: 0.84)],
                                center: UnitPoint(x: 0.32, y: 0.26),
                                startRadius: 0,
                                endRadius: size * 0.72
                            )
                        )
                } else if id >= 9 {
                    Circle().fill(.white)
                    Capsule()
                        .fill(ballColor)
                        .frame(height: size * 0.48)
                        .clipShape(Circle())
                } else {
                    Circle().fill(ballColor)
                }

                if id != 0 {
                    Circle()
                        .fill(id == 8 ? Color.black.opacity(0.96) : .white)
                        .frame(width: size * 0.46, height: size * 0.46)

                    Text("\(id)")
                        .font(.system(size: max(5, size * 0.25), weight: .heavy, design: .rounded))
                        .foregroundStyle(id == 8 ? .white : .black)
                        .minimumScaleFactor(0.5)
                }

                Circle()
                    .fill(Color.white.opacity(id == 0 ? 0.46 : 0.34))
                    .frame(width: size * 0.24, height: size * 0.16)
                    .blur(radius: size * 0.025)
                    .offset(x: -size * 0.18, y: -size * 0.23)
            }
            .overlay {
                Circle().stroke(Color.black.opacity(0.22), lineWidth: max(0.5, size * 0.035))
            }
        }
    }

    private var ballColor: Color {
        switch id {
        case 1, 9: return Color(red: 0.96, green: 0.76, blue: 0.08)
        case 2, 10: return Color(red: 0.08, green: 0.28, blue: 0.82)
        case 3, 11: return Color(red: 0.84, green: 0.10, blue: 0.10)
        case 4, 12: return Color(red: 0.39, green: 0.16, blue: 0.62)
        case 5, 13: return Color(red: 0.95, green: 0.43, blue: 0.08)
        case 6, 14: return Color(red: 0.08, green: 0.48, blue: 0.18)
        case 7, 15: return Color(red: 0.46, green: 0.08, blue: 0.08)
        case 8: return Color.black
        default: return Color.gray
        }
    }
}

private struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}
