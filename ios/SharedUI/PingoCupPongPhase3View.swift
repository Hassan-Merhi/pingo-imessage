import PingoCore
import SwiftUI

struct PingoCupPongPhase3View: View {
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
    @State private var shotInFlight = false
    @State private var flightProgress = 0.0
    @State private var bounceOffset = CGSize.zero
    @State private var ballScale = 1.0
    @State private var resultText: String?
    @State private var resultIcon = "circle.fill"

    private var opponentIndex: Int { player == 0 ? 1 : 0 }

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

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

                if let resultText {
                    resultBanner(resultText)
                        .transition(.scale.combined(with: .opacity))
                } else if let lastCup = state.lastCup {
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
            if !newValue && !shotInFlight {
                isTargeting = false
                isFlicking = false
            }
        }
        .onChange(of: state.turns) { _ in
            if !shotInFlight { resultText = nil }
        }
    }

    private var matchHeader: some View {
        HStack(spacing: 10) {
            playerBadge(ref: opponentPlayer, label: "OPPONENT", remaining: remaining(opponentIndex), local: false)
            Spacer(minLength: 6)
            VStack(spacing: 3) {
                Text("CUP PONG")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.15)
                    .foregroundStyle(.white)
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(0.65)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            Spacer(minLength: 6)
            playerBadge(ref: localPlayer, label: "YOU", remaining: remaining(player), local: true)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.095), Color.white.opacity(0.03)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.075), lineWidth: 1) }
    }

    private var statusText: String {
        if shotInFlight { return "BALL IN FLIGHT" }
        if !canMove { return "OPPONENT’S THROW" }
        if isFlicking { return "RELEASE TO THROW" }
        if isTargeting { return "AIMING" }
        return "YOUR THROW"
    }

    private var statusColor: Color {
        if shotInFlight { return .yellow.opacity(0.95) }
        return canMove ? .green.opacity(0.95) : .white.opacity(0.30)
    }

    private func playerBadge(ref: PingoPlayerRef?, label: String, remaining: Int, local: Bool) -> some View {
        HStack(spacing: 7) {
            Circle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.98), Color.white.opacity(0.76)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay { Image(systemName: "person.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(.black.opacity(0.72)) }
                .frame(width: 31, height: 31)
                .overlay { Circle().stroke(local && canMove ? Color.white.opacity(0.92) : Color.white.opacity(0.16), lineWidth: local && canMove ? 2 : 1) }

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
                    Image(systemName: "cup.and.saucer.fill").font(.system(size: 7, weight: .bold))
                    Text("\(remaining)").font(.system(size: 10, weight: .black, design: .monospaced))
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
            let start = CGPoint(x: tableRect.midX, y: tableRect.maxY - tableRect.height * 0.19)
            let target = landingPoint(in: tableRect)
            let animated = flightPoint(from: start, to: target, tableRect: tableRect)

            ZStack {
                Ellipse()
                    .fill(Color.cyan.opacity(0.12))
                    .blur(radius: 28)
                    .frame(width: size.width * 0.78, height: size.height * 0.28)
                    .position(x: size.width / 2, y: size.height * 0.55)

                Phase3PongTableShape()
                    .fill(LinearGradient(colors: [Color(red: 0.06, green: 0.36, blue: 0.54), Color(red: 0.035, green: 0.23, blue: 0.39), Color(red: 0.02, green: 0.12, blue: 0.23)], startPoint: .top, endPoint: .bottom))
                    .frame(width: tableRect.width, height: tableRect.height)
                    .position(x: tableRect.midX, y: tableRect.midY)
                    .shadow(color: .black.opacity(0.60), radius: 16, y: 11)

                Phase3PongTableShape()
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.42), Color.white.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                    .frame(width: tableRect.width - 7, height: tableRect.height - 7)
                    .position(x: tableRect.midX, y: tableRect.midY)

                Capsule().fill(Color.white.opacity(0.14)).frame(width: tableRect.width * 0.62, height: 2).position(x: tableRect.midX, y: tableRect.midY)

                cupRack(cups: cups(for: opponentIndex), positions: topCupPositions, tableRect: tableRect, mirrored: true)
                cupRack(cups: cups(for: player), positions: bottomCupPositions, tableRect: tableRect, mirrored: false)

                if canMove && !shotInFlight {
                    trajectory(from: start, to: target, tableRect: tableRect)
                    targetReticle(at: target)
                }

                pongBall(at: shotInFlight ? animated : start, shadowOnTable: !shotInFlight || flightProgress > 0.82)
                    .offset(bounceOffset)
                    .scaleEffect(ballScale)

                VStack(spacing: 2) {
                    Text("\(remaining(opponentIndex))").font(.system(size: 22, weight: .black, design: .rounded))
                    Text("CUPS LEFT").font(.system(size: 7, weight: .heavy, design: .rounded)).tracking(1)
                }
                .foregroundStyle(.white.opacity(0.18))
                .position(x: tableRect.midX, y: tableRect.midY - 16)
            }
            .contentShape(Rectangle())
            .gesture(aimGesture(in: tableRect))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cup Pong table. You have \(remaining(player)) cups. Opponent has \(remaining(opponentIndex)) cups.")
        .accessibilityValue(shotInFlight ? "Ball in flight" : "Aim \(Int(aim.rounded())) degrees, power \(Int((power * 100).rounded())) percent")
    }

    private func aimGesture(in tableRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard canMove && !shotInFlight else { return }
                isTargeting = true
                updateShotTarget(from: value.location, in: tableRect)
            }
            .onEnded { _ in isTargeting = false }
    }

    private func updateShotTarget(from point: CGPoint, in tableRect: CGRect) {
        let x = (point.x - tableRect.minX) / max(1, tableRect.width)
        aim = clamp(Double((x - 0.5) / 0.30) * 30, -30, 30)
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
        return CGPoint(x: tableRect.midX + horizontal * tableRect.width * 0.30, y: tableRect.minY + tableRect.height * y)
    }

    private func flightPoint(from start: CGPoint, to target: CGPoint, tableRect: CGRect) -> CGPoint {
        let t = CGFloat(flightProgress)
        let apex = CGPoint(x: (start.x + target.x) / 2, y: min(start.y, target.y) - tableRect.height * (0.14 + CGFloat(power) * 0.10))
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * apex.x + t * t * target.x,
            y: inverse * inverse * start.y + 2 * inverse * t * apex.y + t * t * target.y
        )
    }

    private func trajectory(from start: CGPoint, to target: CGPoint, tableRect: CGRect) -> some View {
        let apex = CGPoint(x: (start.x + target.x) / 2, y: min(start.y, target.y) - tableRect.height * (0.14 + CGFloat(power) * 0.10))
        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: target, control: apex)
        }
        .stroke(Color.white.opacity(0.50), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [5, 6]))
    }

    private func targetReticle(at point: CGPoint) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08)).frame(width: 36, height: 36)
            Circle().stroke(Color.white.opacity(isTargeting ? 0.90 : 0.58), lineWidth: 1.6).frame(width: 27, height: 27)
            Circle().fill(Color.white.opacity(0.90)).frame(width: 5, height: 5)
        }
        .shadow(color: .white.opacity(isTargeting ? 0.28 : 0.10), radius: 6)
        .position(point)
    }

    private func pongBall(at point: CGPoint, shadowOnTable: Bool) -> some View {
        ZStack {
            if shadowOnTable {
                Ellipse().fill(.black.opacity(0.30)).frame(width: 30, height: 10).blur(radius: 2).offset(y: 13)
            }
            Circle()
                .fill(RadialGradient(colors: [.white, Color(white: 0.88)], center: .topLeading, startRadius: 1, endRadius: 17))
                .overlay { Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.8) }
                .frame(width: 27, height: 27)
                .shadow(color: .white.opacity(0.18), radius: 6)
        }
        .position(point)
    }

    private func cupRack(cups: [Bool], positions: [CGPoint], tableRect: CGRect, mirrored: Bool) -> some View {
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { index, normalized in
                let active = cups.indices.contains(index) ? cups[index] : false
                let perspective = mirrored ? (0.72 + normalized.y * 0.26) : (1.02 - normalized.y * 0.22)
                Phase3PremiumPongCup(active: active, mirrored: mirrored)
                    .frame(width: 42 * perspective, height: 45 * perspective)
                    .position(x: tableRect.minX + tableRect.width * normalized.x, y: tableRect.minY + tableRect.height * normalized.y)
            }
        }
    }

    private var throwDeck: some View {
        VStack(spacing: 7) {
            HStack {
                Text("AIM \(Int(aim.rounded()))°")
                Spacer()
                Text("POWER \(Int((power * 100).rounded()))%")
            }
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundStyle(.white.opacity(0.54))

            ZStack {
                Capsule().fill(Color.white.opacity(0.08)).frame(height: 48)
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                    Text(shotInFlight ? "SHOT IN FLIGHT" : "FLICK UP TO THROW")
                        .font(.system(size: 10, weight: .black, design: .rounded)).tracking(0.9)
                    Image(systemName: "arrow.up")
                }
                .foregroundStyle(.white.opacity(shotInFlight ? 0.40 : 0.88))
            }
            .contentShape(Rectangle())
            .gesture(flickGesture)
        }
        .padding(10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 1) }
    }

    private var flickGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard canMove && !shotInFlight else { return }
                isFlicking = true
                aim = clamp(aim + Double(value.translation.width) * 0.025, -30, 30)
                let upward = max(0, -value.translation.height)
                power = clamp(0.15 + Double(upward / 145) * 0.85, 0.15, 1)
            }
            .onEnded { value in
                guard canMove && !shotInFlight else { return }
                isFlicking = false
                let upward = -value.translation.height
                guard upward >= 24 else { return }
                launchShot()
            }
    }

    private func launchShot() {
        let shot = PingoAimShot(angleDegrees: aim, power: power)
        let outcome = localOutcome(for: shot)
        shotInFlight = true
        resultText = nil
        flightProgress = 0
        bounceOffset = .zero
        ballScale = 1

        Task { @MainActor in
            withAnimation(.timingCurve(0.20, 0.72, 0.24, 1, duration: 0.72)) {
                flightProgress = 1
                ballScale = 0.84
            }
            try? await Task.sleep(nanoseconds: 740_000_000)

            switch outcome {
            case .sunk(let cup):
                withAnimation(.easeIn(duration: 0.16)) {
                    ballScale = 0.20
                    bounceOffset = CGSize(width: 0, height: 10)
                }
                resultIcon = "sparkles"
                resultText = "CUP \(cup + 1) SUNK"
                try? await Task.sleep(nanoseconds: 230_000_000)

            case .rim:
                withAnimation(.spring(response: 0.24, dampingFraction: 0.48)) {
                    bounceOffset = CGSize(width: aim >= 0 ? 18 : -18, height: -18)
                    ballScale = 0.92
                }
                resultIcon = "arrow.uturn.backward.circle.fill"
                resultText = "RIM OUT"
                try? await Task.sleep(nanoseconds: 300_000_000)

            case .miss:
                withAnimation(.easeOut(duration: 0.24)) {
                    bounceOffset = CGSize(width: aim >= 0 ? 28 : -28, height: 22)
                    ballScale = 0.82
                }
                resultIcon = "xmark.circle.fill"
                resultText = "MISS"
                try? await Task.sleep(nanoseconds: 260_000_000)
            }

            onMove(.cupPong(shot))
            shotInFlight = false
            flightProgress = 0
            bounceOffset = .zero
            ballScale = 1
        }
    }

    private enum LocalOutcome {
        case sunk(Int)
        case rim
        case miss
    }

    private func localOutcome(for shot: PingoAimShot) -> LocalOutcome {
        let centers = [
            PingoVector2(x: -0.36, y: 0.82), PingoVector2(x: 0, y: 0.82), PingoVector2(x: 0.36, y: 0.82),
            PingoVector2(x: -0.18, y: 0.58), PingoVector2(x: 0.18, y: 0.58), PingoVector2(x: 0, y: 0.34)
        ]
        let landing = PingoVector2(x: shot.angleDegrees / 30.0, y: shot.power)
        let opponentCups = cups(for: opponentIndex)
        var nearest: (index: Int, distance: Double)?
        for index in centers.indices where opponentCups.indices.contains(index) && opponentCups[index] {
            let distance = landing.distance(to: centers[index])
            if nearest == nil || distance < nearest!.distance { nearest = (index, distance) }
        }
        guard let nearest else { return .miss }
        if nearest.distance <= 0.17 { return .sunk(nearest.index) }
        if nearest.distance <= 0.27 { return .rim }
        return .miss
    }

    private func resultBanner(_ text: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: resultIcon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 9, weight: .black, design: .rounded)).tracking(0.9)
        }
        .foregroundStyle(.white.opacity(0.90))
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.09), in: Capsule())
        .overlay { Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1) }
    }

    private func sunkBanner(cup: Int) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkles").font(.system(size: 10, weight: .bold))
            Text("CUP \(cup + 1) SUNK").font(.system(size: 9, weight: .black, design: .rounded)).tracking(0.9)
        }
        .foregroundStyle(.white.opacity(0.88))
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var lockedFooter: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
            Text("TABLE LOCKED UNTIL YOUR TURN").font(.system(size: 8, weight: .heavy, design: .rounded)).tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.38))
        .padding(.vertical, 9)
    }

    private var topCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.36, y: 0.24), CGPoint(x: 0.50, y: 0.24), CGPoint(x: 0.64, y: 0.24),
            CGPoint(x: 0.43, y: 0.18), CGPoint(x: 0.57, y: 0.18), CGPoint(x: 0.50, y: 0.13)
        ]
    }

    private var bottomCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.36, y: 0.76), CGPoint(x: 0.50, y: 0.76), CGPoint(x: 0.64, y: 0.76),
            CGPoint(x: 0.43, y: 0.82), CGPoint(x: 0.57, y: 0.82), CGPoint(x: 0.50, y: 0.87)
        ]
    }

    private func cups(for index: Int) -> [Bool] {
        guard state.cups.indices.contains(index) else { return Array(repeating: false, count: 6) }
        return state.cups[index]
    }

    private func remaining(_ index: Int) -> Int { cups(for: index).filter { $0 }.count }

    private func clamp<T: Comparable>(_ value: T, _ lower: T, _ upper: T) -> T {
        min(upper, max(lower, value))
    }
}

private struct Phase3PongTableShape: Shape {
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

private struct Phase3PremiumPongCup: View {
    let active: Bool
    let mirrored: Bool

    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(active ? 0.26 : 0.10)).frame(width: 34, height: 10).offset(y: 16).blur(radius: 1.6)
            Phase3PongCupBodyShape()
                .fill(LinearGradient(colors: active ? [Color(red: 0.96, green: 0.12, blue: 0.17), Color(red: 0.60, green: 0.03, blue: 0.08)] : [Color.white.opacity(0.12), Color.white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 34, height: 37)
                .offset(y: 4)
            Ellipse().fill(active ? Color.white.opacity(0.93) : Color.white.opacity(0.08)).frame(width: 34, height: 10).offset(y: -13)
            Ellipse().fill(active ? Color(red: 0.22, green: 0.025, blue: 0.035) : Color.black.opacity(0.12)).frame(width: 27, height: 6).offset(y: -13)
            if active { Ellipse().stroke(Color.white.opacity(0.42), lineWidth: 1).frame(width: 34, height: 10).offset(y: -13) }
        }
        .opacity(active ? 1 : 0.28)
        .scaleEffect(y: mirrored ? 0.94 : 1.02)
        .animation(.spring(response: 0.34, dampingFraction: 0.68), value: active)
    }
}

private struct Phase3PongCupBodyShape: Shape {
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
