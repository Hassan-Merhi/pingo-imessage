import PingoCore
import SwiftUI

struct PingoCupPongPhase2View: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    @State private var aim = 0.0
    @State private var power = 0.58
    @State private var isTargeting = false
    @State private var isFlicking = false
    @State private var flickDistance: CGFloat = 0
    @State private var flickStartAim = 0.0

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    private var opponentIndex: Int { player == 0 ? 1 : 0 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.04, blue: 0.065),
                    Color(red: 0.055, green: 0.075, blue: 0.105),
                    Color(red: 0.018, green: 0.028, blue: 0.045)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 9) {
                matchHeader

                pongStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let lastCup = state.lastCup {
                    sunkBanner(cup: lastCup)
                }

                if canMove {
                    throwDeck
                } else {
                    lockedFooter
                }
            }
            .padding(.horizontal, 9)
            .padding(.top, 2)
            .padding(.bottom, 4)
        }
        .onChange(of: canMove) { newValue in
            if !newValue {
                isTargeting = false
                isFlicking = false
                flickDistance = 0
            }
        }
    }

    private var matchHeader: some View {
        HStack(spacing: 10) {
            playerBadge(
                ref: opponentPlayer,
                label: "OPPONENT",
                remaining: remaining(opponentIndex),
                local: false
            )

            Spacer(minLength: 6)

            VStack(spacing: 3) {
                Text("CUP PONG")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Circle()
                        .fill(canMove ? Color.green.opacity(0.95) : Color.white.opacity(0.30))
                        .frame(width: 6, height: 6)
                    Text(canMove ? statusText : "OPPONENT’S THROW")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(0.65)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }

            Spacer(minLength: 6)

            playerBadge(
                ref: localPlayer,
                label: "YOU",
                remaining: remaining(player),
                local: true
            )
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.095), Color.white.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        }
    }

    private var statusText: String {
        if isFlicking { return "RELEASE TO THROW" }
        if isTargeting { return "AIMING" }
        return "YOUR THROW"
    }

    private func playerBadge(ref: PingoPlayerRef?, label: String, remaining: Int, local: Bool) -> some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.98), Color.white.opacity(0.76)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 31, height: 31)

                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.72))
            }
            .overlay {
                Circle()
                    .stroke(local && canMove ? Color.white.opacity(0.92) : Color.white.opacity(0.16), lineWidth: local && canMove ? 2 : 1)
            }

            VStack(alignment: local ? .trailing : .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.42))

                Text(ref.map { "@\($0.displayName)" } ?? "Waiting…")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(1)

                HStack(spacing: 3) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 7, weight: .bold))
                    Text("\(remaining)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.66))
            }
        }
        .frame(maxWidth: 112, alignment: local ? .trailing : .leading)
    }

    private var pongStage: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let horizontalInset = max(18, size.width * 0.07)
            let verticalInset = max(12, size.height * 0.035)
            let tableRect = CGRect(
                x: horizontalInset,
                y: verticalInset,
                width: max(1, size.width - horizontalInset * 2),
                height: max(1, size.height - verticalInset * 2)
            )
            let ballStart = CGPoint(
                x: tableRect.midX,
                y: tableRect.maxY - tableRect.height * 0.19
            )
            let target = landingPoint(in: tableRect)

            ZStack {
                arenaGlow(size: size)

                Phase2PongTableShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.36, blue: 0.54),
                                Color(red: 0.035, green: 0.23, blue: 0.39),
                                Color(red: 0.02, green: 0.12, blue: 0.23)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: tableRect.width, height: tableRect.height)
                    .position(x: tableRect.midX, y: tableRect.midY)
                    .shadow(color: .black.opacity(0.60), radius: 16, y: 11)

                Phase2PongTableShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.42), Color.white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: tableRect.width - 7, height: tableRect.height - 7)
                    .position(x: tableRect.midX, y: tableRect.midY)

                centerLine(tableRect: tableRect)
                tableShine(tableRect: tableRect)

                cupRack(
                    cups: cups(for: opponentIndex),
                    positions: topCupPositions,
                    tableRect: tableRect,
                    mirrored: true
                )

                cupRack(
                    cups: cups(for: player),
                    positions: bottomCupPositions,
                    tableRect: tableRect,
                    mirrored: false
                )

                if canMove {
                    trajectory(from: ballStart, to: target, tableRect: tableRect)
                    targetReticle(at: target)
                }

                pongBall(at: ballStart)

                VStack(spacing: 2) {
                    Text("\(remaining(opponentIndex))")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Text("CUPS LEFT")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(.white.opacity(0.18))
                .position(x: tableRect.midX, y: tableRect.midY - 16)

                if canMove {
                    Text(isTargeting ? "DRAG TO PLACE LANDING" : "DRAG TABLE TO AIM")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(isTargeting ? 0.72 : 0.36))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.28), in: Capsule())
                        .position(x: tableRect.midX, y: tableRect.maxY - 16)
                }
            }
            .contentShape(Rectangle())
            .gesture(aimGesture(in: tableRect))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cup Pong table. You have \(remaining(player)) cups. Opponent has \(remaining(opponentIndex)) cups.")
        .accessibilityValue(canMove ? "Aim \(Int(aim.rounded())) degrees, power \(Int((power * 100).rounded())) percent" : "Waiting for opponent")
    }

    private func aimGesture(in tableRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard canMove else { return }
                isTargeting = true
                updateShotTarget(from: value.location, in: tableRect)
            }
            .onEnded { _ in
                isTargeting = false
            }
    }

    private func updateShotTarget(from point: CGPoint, in tableRect: CGRect) {
        let x = (point.x - tableRect.minX) / max(1, tableRect.width)
        let xOffset = (x - 0.5) / 0.30
        aim = clamp(Double(xOffset) * 30, -30, 30)

        let y = (point.y - tableRect.minY) / max(1, tableRect.height)
        if y <= 0.48 {
            let normalized = clamp(Double((0.36 - y) / 0.25), 0, 1)
            power = 0.15 + normalized * 0.85
        }
    }

    private func landingPoint(in tableRect: CGRect) -> CGPoint {
        let horizontal = CGFloat(aim / 30)
        let powerNormalized = CGFloat((power - 0.15) / 0.85)
        let y = 0.36 - powerNormalized * 0.25
        return CGPoint(
            x: tableRect.midX + horizontal * tableRect.width * 0.30,
            y: tableRect.minY + tableRect.height * y
        )
    }

    private func trajectory(from start: CGPoint, to target: CGPoint, tableRect: CGRect) -> some View {
        let apex = CGPoint(
            x: (start.x + target.x) / 2,
            y: min(start.y, target.y) - tableRect.height * (0.12 + CGFloat(power) * 0.08)
        )

        return ZStack {
            Path { path in
                path.move(to: start)
                path.addQuadCurve(to: target, control: apex)
            }
            .stroke(
                Color.white.opacity(isFlicking ? 0.82 : 0.48),
                style: StrokeStyle(lineWidth: isFlicking ? 2.4 : 1.7, lineCap: .round, dash: [5, 6])
            )

            ForEach(1..<5, id: \.self) { step in
                let t = CGFloat(step) / 5
                Circle()
                    .fill(Color.white.opacity(0.35 + Double(step) * 0.08))
                    .frame(width: 4 + CGFloat(step), height: 4 + CGFloat(step))
                    .position(quadPoint(start: start, control: apex, end: target, t: t))
            }
        }
    }

    private func quadPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * end.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * end.y
        )
    }

    private func targetReticle(at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 36, height: 36)
            Circle()
                .stroke(Color.white.opacity(isTargeting ? 0.90 : 0.58), lineWidth: 1.6)
                .frame(width: 27, height: 27)
            Circle()
                .fill(Color.white.opacity(0.90))
                .frame(width: 5, height: 5)
        }
        .shadow(color: .white.opacity(isTargeting ? 0.28 : 0.10), radius: 6)
        .position(point)
    }

    private func pongBall(at point: CGPoint) -> some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.30))
                .frame(width: 30, height: 10)
                .blur(radius: 2)
                .offset(y: 13)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.88)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 17
                    )
                )
                .overlay { Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.8) }
                .frame(width: 27, height: 27)
                .shadow(color: .white.opacity(0.18), radius: 6)
                .scaleEffect(isFlicking ? 1.08 : 1)
        }
        .position(x: point.x + min(38, flickDistance * 0.12) * CGFloat(aim / 30), y: point.y + min(12, flickDistance * 0.04))
    }

    private func arenaGlow(size: CGSize) -> some View {
        Ellipse()
            .fill(Color.cyan.opacity(0.12))
            .blur(radius: 28)
            .frame(width: size.width * 0.78, height: size.height * 0.28)
            .position(x: size.width / 2, y: size.height * 0.55)
    }

    private func centerLine(tableRect: CGRect) -> some View {
        Capsule()
            .fill(Color.white.opacity(0.14))
            .frame(width: tableRect.width * 0.62, height: 2)
            .position(x: tableRect.midX, y: tableRect.midY)
    }

    private func tableShine(tableRect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: tableRect.width * 0.62, height: tableRect.height * 0.70)
            .rotationEffect(.degrees(-7))
            .position(x: tableRect.midX - tableRect.width * 0.10, y: tableRect.midY - tableRect.height * 0.03)
            .mask {
                Phase2PongTableShape()
                    .frame(width: tableRect.width, height: tableRect.height)
            }
    }

    private func cupRack(cups: [Bool], positions: [CGPoint], tableRect: CGRect, mirrored: Bool) -> some View {
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { index, normalized in
                let active = cups.indices.contains(index) ? cups[index] : false
                let perspective = mirrored ? (0.72 + normalized.y * 0.26) : (1.02 - normalized.y * 0.22)

                Phase2PremiumPongCup(active: active, mirrored: mirrored)
                    .frame(width: 42 * perspective, height: 45 * perspective)
                    .position(
                        x: tableRect.minX + tableRect.width * normalized.x,
                        y: tableRect.minY + tableRect.height * normalized.y
                    )
            }
        }
    }

    private var topCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.39, y: 0.14), CGPoint(x: 0.50, y: 0.14), CGPoint(x: 0.61, y: 0.14),
            CGPoint(x: 0.445, y: 0.205), CGPoint(x: 0.555, y: 0.205),
            CGPoint(x: 0.50, y: 0.27)
        ]
    }

    private var bottomCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.39, y: 0.86), CGPoint(x: 0.50, y: 0.86), CGPoint(x: 0.61, y: 0.86),
            CGPoint(x: 0.445, y: 0.795), CGPoint(x: 0.555, y: 0.795),
            CGPoint(x: 0.50, y: 0.73)
        ]
    }

    private func sunkBanner(cup: Int) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
            Text("CUP \(cup + 1) SUNK")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.9)
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay { Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1) }
    }

    private var throwDeck: some View {
        VStack(spacing: 7) {
            HStack(spacing: 12) {
                shotMetric(title: "AIM", value: "\(signedAim)°", icon: "scope")
                shotMetric(title: "POWER", value: "\(Int((power * 100).rounded()))%", icon: "bolt.fill")
            }

            GeometryReader { proxy in
                let travel = min(112, max(1, proxy.size.height - 24))
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.065))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(isFlicking ? 0.18 : 0.075), lineWidth: 1)

                    VStack(spacing: 5) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .black))
                        Text(isFlicking ? "RELEASE" : "FLICK UP TO THROW")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.9)
                    }
                    .foregroundStyle(.white.opacity(isFlicking ? 0.90 : 0.42))
                    .offset(y: -24)

                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 8, height: travel)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.white.opacity(0.82)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 8, height: max(6, travel * CGFloat((power - 0.15) / 0.85)))
                        .frame(height: travel, alignment: .bottom)

                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 31, height: 31)
                            .shadow(color: .black.opacity(0.30), radius: 5, y: 3)
                        Circle()
                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                            .frame(width: 31, height: 31)
                    }
                    .offset(
                        x: min(48, max(-48, CGFloat(aim / 30) * 48)),
                        y: min(26, 30 - flickDistance * 0.70)
                    )
                }
                .contentShape(Rectangle())
                .gesture(flickGesture)
            }
            .frame(height: 108)

            Text("Drag on the table to choose a landing point • Flick upward and release")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.34))
                .multilineTextAlignment(.center)
        }
        .padding(9)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(Color.white.opacity(0.065), lineWidth: 1)
        }
    }

    private var flickGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                guard canMove else { return }
                if !isFlicking {
                    isFlicking = true
                    flickStartAim = aim
                }

                let upward = max(0, -value.translation.height)
                flickDistance = min(135, upward)

                if upward > 2 {
                    power = clamp(0.15 + Double(upward / 135) * 0.85, 0.15, 1)
                    let horizontalAdjustment = Double(value.translation.width) * 0.12
                    aim = clamp(flickStartAim + horizontalAdjustment, -30, 30)
                }
            }
            .onEnded { _ in
                let charged = flickDistance
                isFlicking = false
                flickDistance = 0
                guard charged >= 26 else { return }
                throwBall()
            }
    }

    private func shotMetric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.38))
                Text(value)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.045), in: Capsule())
    }

    private var lockedFooter: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .bold))
            Text("TABLE LOCKED UNTIL YOUR TURN")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.38))
        .padding(.vertical, 9)
    }

    private var signedAim: String {
        let rounded = Int(aim.rounded())
        return rounded > 0 ? "+\(rounded)" : "\(rounded)"
    }

    private func throwBall() {
        guard canMove else { return }
        onMove(.cupPong(.init(angleDegrees: clamp(aim, -30, 30), power: clamp(power, 0.15, 1))))
    }

    private func cups(for index: Int) -> [Bool] {
        guard state.cups.indices.contains(index) else { return Array(repeating: false, count: 6) }
        return state.cups[index]
    }

    private func remaining(_ index: Int) -> Int {
        cups(for: index).filter { $0 }.count
    }

    private func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        min(upper, max(lower, value))
    }
}

private struct Phase2PongTableShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.13
        let bottomInset = rect.width * 0.035
        path.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + bottomInset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct Phase2PremiumPongCup: View {
    let active: Bool
    let mirrored: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(active ? 0.26 : 0.10))
                .frame(width: 34, height: 10)
                .offset(y: mirrored ? 16 : 17)
                .blur(radius: 1.6)

            Phase2PongCupBodyShape()
                .fill(
                    LinearGradient(
                        colors: active
                            ? [Color(red: 0.96, green: 0.12, blue: 0.17), Color(red: 0.60, green: 0.03, blue: 0.08)]
                            : [Color.white.opacity(0.12), Color.white.opacity(0.035)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34, height: 37)
                .offset(y: 4)

            Ellipse()
                .fill(active ? Color.white.opacity(0.93) : Color.white.opacity(0.08))
                .frame(width: 34, height: 10)
                .offset(y: -13)

            Ellipse()
                .fill(active ? Color(red: 0.22, green: 0.025, blue: 0.035) : Color.black.opacity(0.12))
                .frame(width: 27, height: 6)
                .offset(y: -13)

            if active {
                Ellipse()
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)
                    .frame(width: 34, height: 10)
                    .offset(y: -13)
            }
        }
        .opacity(active ? 1 : 0.28)
        .scaleEffect(y: mirrored ? 0.94 : 1.02)
    }
}

private struct Phase2PongCupBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.23, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.23, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
