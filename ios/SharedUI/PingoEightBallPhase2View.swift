import PingoCore
import SwiftUI

struct PingoEightBallPhase2View: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 0.0
    @State private var power = 0.58
    @State private var contact = CGSize.zero
    @State private var pullDistance: CGFloat = 0
    @State private var isAiming = false

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    var body: some View {
        VStack(spacing: 9) {
            playerBar

            HStack(alignment: .center, spacing: 8) {
                powerRail

                Phase2PoolTable(
                    state: state,
                    angle: $angle,
                    power: power,
                    canAim: canMove,
                    isAiming: $isAiming,
                    pullDistance: pullDistance
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(0.51, contentMode: .fit)

                contactControl
            }
            .frame(maxHeight: .infinity)

            if canMove {
                cuePullControl
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .onChange(of: canMove) { newValue in
            if !newValue {
                pullDistance = 0
                isAiming = false
            }
        }
    }

    private var playerBar: some View {
        HStack(spacing: 8) {
            playerChip(opponentPlayer, index: player == 0 ? 1 : 0, local: false)
            Spacer(minLength: 4)

            VStack(spacing: 2) {
                Text(state.groups == [0, 0] ? "OPEN TABLE" : "8 BALL")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                Text(canMove ? (isAiming ? "AIMING" : "YOUR TURN") : "MATCH IN PROGRESS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(canMove ? Color(red: 0.72, green: 0.95, blue: 0.86) : .white.opacity(0.52))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.82), in: Capsule())

            Spacer(minLength: 4)
            playerChip(localPlayer, index: player, local: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.94), Color.black.opacity(0.78)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08)) }
    }

    private func playerChip(_ ref: PingoPlayerRef?, index: Int, local: Bool) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(.white.opacity(0.94))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black.opacity(0.76))
                }
                .overlay {
                    Circle().stroke(local && canMove ? .white : .white.opacity(0.18), lineWidth: local && canMove ? 2 : 1)
                }
                .frame(width: 34, height: 34)

            Text(ref.map { "@\($0.displayName)" } ?? "Waiting…")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
                .frame(maxWidth: 78)

            groupBadge(index)
        }
        .frame(width: 78)
    }

    @ViewBuilder
    private func groupBadge(_ index: Int) -> some View {
        let group = state.groups.indices.contains(index) ? state.groups[index] : 0
        if group == 0 {
            Text("OPEN")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
        } else {
            HStack(spacing: 2) {
                ForEach(group == 1 ? Array(1...3) : Array(9...11), id: \.self) { id in
                    Phase2PoolBall(id: id).frame(width: 11, height: 11)
                }
            }
        }
    }

    private var powerRail: some View {
        VStack(spacing: 7) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.black.opacity(0.46))

            GeometryReader { proxy in
                let track = proxy.size.height
                ZStack(alignment: .bottom) {
                    Capsule().fill(Color.black.opacity(0.11)).frame(width: 11)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.92, green: 0.18, blue: 0.17), Color(red: 0.98, green: 0.73, blue: 0.18)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 11, height: max(12, track * power))
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.22), radius: 3, y: 1)
                        .frame(width: 24, height: 24)
                        .offset(y: -(track * power) + 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard canMove else { return }
                            let normalized = 1 - min(1, max(0, value.location.y / max(1, track)))
                            power = min(1, max(0.05, normalized))
                        }
                )
            }
            .frame(width: 34, height: 180)

            Text("\(Int((power * 100).rounded()))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.black.opacity(0.56))
        }
        .frame(width: 38)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shot power")
        .accessibilityValue("\(Int((power * 100).rounded())) percent")
    }

    private var contactControl: some View {
        VStack(spacing: 7) {
            Text("CONTACT")
                .font(.system(size: 7, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.42))

            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [.white, Color(white: 0.88)], center: .topLeading, startRadius: 1, endRadius: radius))
                        .shadow(color: .black.opacity(0.16), radius: 3, y: 2)
                    Circle().stroke(Color.black.opacity(0.11), lineWidth: 1)
                    Path { path in
                        path.move(to: CGPoint(x: radius, y: 7))
                        path.addLine(to: CGPoint(x: radius, y: radius * 2 - 7))
                        path.move(to: CGPoint(x: 7, y: radius))
                        path.addLine(to: CGPoint(x: radius * 2 - 7, y: radius))
                    }
                    .stroke(Color.black.opacity(0.10), lineWidth: 0.7)
                    Circle()
                        .fill(Color(red: 0.86, green: 0.15, blue: 0.14))
                        .frame(width: 9, height: 9)
                        .offset(contact)
                }
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard canMove else { return }
                            let dx = value.location.x - radius
                            let dy = value.location.y - radius
                            let limit = radius - 7
                            let length = max(0.001, sqrt(dx * dx + dy * dy))
                            let scale = min(1, limit / length)
                            contact = CGSize(width: dx * scale, height: dy * scale)
                        }
                )
            }
            .frame(width: 46, height: 46)

            Button("RESET") { contact = .zero }
                .font(.system(size: 7, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.46))
                .buttonStyle(.plain)
                .disabled(!canMove)
        }
        .frame(width: 48)
        .accessibilityElement(children: .contain)
    }

    private var cuePullControl: some View {
        VStack(spacing: 5) {
            HStack(spacing: 9) {
                Image(systemName: "scope")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black.opacity(0.50))

                Text("\(Int(normalizedAngle.rounded()))°")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.58))
                    .frame(width: 38)

                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.10)).frame(height: 7)
                    Capsule()
                        .fill(Color.black.opacity(0.72))
                        .frame(width: max(12, min(150, 150 * power)), height: 7)
                }
                .frame(maxWidth: .infinity)

                Text("PULL")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.52))
            }

            ZStack {
                Capsule()
                    .fill(.white.opacity(0.76))
                    .overlay { Capsule().stroke(Color.black.opacity(0.06)) }
                    .frame(height: 42)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.82, blue: 0.58), Color(red: 0.63, green: 0.37, blue: 0.16)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 118, height: 7)
                        .offset(x: min(58, pullDistance * 0.48))

                    Circle()
                        .fill(Color.black.opacity(0.86))
                        .overlay { Image(systemName: "chevron.down").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white) }
                        .frame(width: 29, height: 29)
                        .offset(y: min(10, pullDistance * 0.08))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { value in
                        let drag = max(0, value.translation.height)
                        pullDistance = min(125, drag)
                        if drag > 2 {
                            power = min(1, max(0.05, 0.05 + Double(drag / 125) * 0.95))
                        }
                    }
                    .onEnded { _ in
                        let charged = pullDistance
                        pullDistance = 0
                        guard charged >= 24 else { return }
                        shoot()
                    }
            )

            Text("Drag on the table to aim • Pull the cue down and release to shoot")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.43))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05)) }
    }

    private var normalizedAngle: Double {
        let value = angle.truncatingRemainder(dividingBy: 360)
        return value >= 0 ? value : value + 360
    }

    private func shoot() {
        guard canMove else { return }
        onMove(.eightBall(.init(angleDegrees: normalizedAngle, power: power)))
    }
}

private struct Phase2PoolTable: View {
    let state: PingoEightBallState
    @Binding var angle: Double
    let power: Double
    let canAim: Bool
    @Binding var isAiming: Bool
    let pullDistance: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rail = max(18.0, min(28.0, size.width * 0.085))
            let felt = CGRect(x: rail, y: rail, width: max(1, size.width - rail * 2), height: max(1, size.height - rail * 2))
            let ballSize = max(14.0, min(21.0, felt.width * 0.075))

            ZStack {
                RoundedRectangle(cornerRadius: 29)
                    .fill(LinearGradient(colors: [Color(red: 0.19, green: 0.075, blue: 0.04), Color(red: 0.45, green: 0.21, blue: 0.10), Color(red: 0.22, green: 0.085, blue: 0.045)], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 6)

                RoundedRectangle(cornerRadius: 22)
                    .stroke(LinearGradient(colors: [Color(red: 0.70, green: 0.42, blue: 0.20), Color(red: 0.15, green: 0.055, blue: 0.03)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 7)
                    .padding(8)

                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(red: 0.035, green: 0.51, blue: 0.43), Color(red: 0.012, green: 0.37, blue: 0.33), Color(red: 0.025, green: 0.46, blue: 0.39)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(rail)
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.25), lineWidth: 3).padding(rail - 1) }

                pockets(felt: felt, ballSize: ballSize)

                if canAim, let cue = state.balls.first(where: { $0.id == 0 && !$0.pocketed }) {
                    cueGuide(cue.position, felt: felt, ballSize: ballSize)
                }

                ForEach(state.balls.filter { !$0.pocketed }) { ball in
                    Phase2PoolBall(id: ball.id)
                        .frame(width: ballSize, height: ballSize)
                        .shadow(color: .black.opacity(0.30), radius: 2, x: 1, y: 2)
                        .position(tablePoint(ball.position, felt: felt))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 29))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard canAim, let cue = state.balls.first(where: { $0.id == 0 && !$0.pocketed }) else { return }
                        isAiming = true
                        let start = tablePoint(cue.position, felt: felt)
                        let dx = value.location.x - start.x
                        let dy = value.location.y - start.y
                        guard abs(dx) + abs(dy) > 4 else { return }
                        let radians = atan2(Double(dx), Double(-dy))
                        var degrees = radians * 180 / .pi
                        if degrees < 0 { degrees += 360 }
                        angle = degrees
                    }
                    .onEnded { _ in isAiming = false }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("8 Ball pool table")
    }

    @ViewBuilder
    private func pockets(felt: CGRect, ballSize: CGFloat) -> some View {
        let size = max(22, ballSize * 1.65)
        ForEach(Array(pocketPoints.enumerated()), id: \.offset) { _, p in
            Circle()
                .fill(RadialGradient(colors: [.black, Color(red: 0.07, green: 0.05, blue: 0.04)], center: .center, startRadius: 1, endRadius: size / 2))
                .frame(width: size, height: size)
                .position(tablePoint(p, felt: felt))
        }
    }

    @ViewBuilder
    private func cueGuide(_ cue: PingoVector2, felt: CGRect, ballSize: CGFloat) -> some View {
        let start = tablePoint(cue, felt: felt)
        let radians = angle * .pi / 180
        let dx = CGFloat(sin(radians))
        let dy = CGFloat(-cos(radians))
        let guideLength = max(felt.width, felt.height) * 0.74
        let cueBack = 42 + pullDistance * 0.42
        let lineEnd = CGPoint(x: start.x + dx * guideLength, y: start.y + dy * guideLength)
        let cueStart = CGPoint(x: start.x - dx * cueBack, y: start.y - dy * cueBack)
        let cueEnd = CGPoint(x: start.x - dx * (ballSize * 0.65), y: start.y - dy * (ballSize * 0.65))

        Path { path in
            path.move(to: start)
            path.addLine(to: lineEnd)
        }
        .stroke(.white.opacity(0.78), style: StrokeStyle(lineWidth: 1.7, dash: [6, 5]))

        Path { path in
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + dx * 52, y: start.y + dy * 52))
        }
        .stroke(.white.opacity(0.96), lineWidth: 2.2)

        Circle()
            .stroke(.white.opacity(0.82), lineWidth: 1.2)
            .frame(width: ballSize + 5, height: ballSize + 5)
            .position(lineEnd)

        Path { path in
            path.move(to: cueStart)
            path.addLine(to: cueEnd)
        }
        .stroke(LinearGradient(colors: [Color(red: 0.48, green: 0.25, blue: 0.10), Color(red: 0.95, green: 0.82, blue: 0.58)], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }

    private func tablePoint(_ p: PingoVector2, felt: CGRect) -> CGPoint {
        CGPoint(x: felt.minX + felt.width * p.y, y: felt.minY + felt.height * (1 - p.x))
    }

    private var pocketPoints: [PingoVector2] {
        [
            .init(x: 0.035, y: 0.055), .init(x: 0.5, y: 0.045), .init(x: 0.965, y: 0.055),
            .init(x: 0.035, y: 0.945), .init(x: 0.5, y: 0.955), .init(x: 0.965, y: 0.945)
        ]
    }
}

private struct Phase2PoolBall: View {
    let id: Int

    var body: some View {
        ZStack {
            Circle().fill(baseColor)
            if id >= 9 {
                Capsule().fill(.white).frame(height: 7)
            }
            if id != 0 {
                Circle().fill(id == 8 ? .black : .white).frame(width: 9, height: 9)
                Text("\(id)")
                    .font(.system(size: 5.2, weight: .heavy, design: .rounded))
                    .foregroundStyle(id == 8 ? .white : .black)
            }
            Circle()
                .fill(.white.opacity(0.34))
                .frame(width: 4, height: 4)
                .offset(x: -3, y: -3)
        }
        .overlay { Circle().stroke(Color.black.opacity(0.20), lineWidth: 0.6) }
    }

    private var baseColor: Color {
        switch id {
        case 0: return .white
        case 1, 9: return .yellow
        case 2, 10: return .blue
        case 3, 11: return .red
        case 4, 12: return .purple
        case 5, 13: return .orange
        case 6, 14: return .green
        case 7, 15: return Color(red: 0.48, green: 0.10, blue: 0.10)
        case 8: return .black
        default: return .gray
        }
    }
}