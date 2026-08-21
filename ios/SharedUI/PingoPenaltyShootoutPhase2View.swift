import PingoCore
import SwiftUI

struct PingoPenaltyShootoutPhase2View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var target = 2
    @State private var power = 72.0
    @State private var isAiming = false
    @State private var dragOriginTarget = 2

    var body: some View {
        VStack(spacing: 12) {
            header

            pitchStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusRibbon

            if canMove {
                instructionBar
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PENALTY SHOOTOUT")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.7)
                Text("FIVE-KICK DUEL")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.44))
            }

            Spacer()

            HStack(spacing: 8) {
                scoreChip(title: "YOU", score: score(player), attempts: attempts(player), emphasized: true)
                scoreChip(title: "THEM", score: score(1 - player), attempts: attempts(1 - player), emphasized: false)
            }
        }
        .foregroundStyle(.black.opacity(0.78))
    }

    private var pitchStage: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.24, blue: 0.18),
                                Color(red: 0.10, green: 0.48, blue: 0.24),
                                Color(red: 0.05, green: 0.30, blue: 0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.24), radius: 12, y: 6)

                grassStripes
                penaltyArea(size: size)
                goal(size: size)
                goalkeeper(size: size)
                aimGuide(size: size)
                penaltySpot(size: size)
                ball(size: size)

                VStack {
                    HStack {
                        kickBadge
                        Spacer()
                        aimReadout
                    }
                    Spacer()
                }
                .padding(22)
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .gesture(canMove ? kickGesture(in: size) : nil)
        }
    }

    private func kickGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                if !isAiming {
                    isAiming = true
                    dragOriginTarget = target
                }

                let horizontal = value.translation.width / max(1, size.width)
                let laneDelta = Int((horizontal * 7).rounded())
                target = min(4, max(0, dragOriginTarget + laneDelta))

                let upward = max(0, -value.translation.height)
                power = min(100, max(20, Double(upward / max(1, size.height)) * 190))
            }
            .onEnded { value in
                defer { isAiming = false }

                let upward = max(0, -value.translation.height)
                let minimumFlick = max(36, size.height * 0.09)
                guard upward >= minimumFlick else { return }

                onMove(.init(primary: target, secondary: Int(power.rounded())))
            }
    }

    private var grassStripes: some View {
        HStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.045 : 0.015))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .allowsHitTesting(false)
    }

    private func penaltyArea(size: CGSize) -> some View {
        ZStack {
            Path { path in
                let left = size.width * 0.14
                let right = size.width * 0.86
                let top = size.height * 0.10
                let bottom = size.height * 0.55
                path.move(to: CGPoint(x: left, y: top))
                path.addLine(to: CGPoint(x: left, y: bottom))
                path.addLine(to: CGPoint(x: right, y: bottom))
                path.addLine(to: CGPoint(x: right, y: top))
            }
            .stroke(Color.white.opacity(0.82), lineWidth: 3)

            Path { path in
                path.addArc(
                    center: CGPoint(x: size.width * 0.50, y: size.height * 0.43),
                    radius: size.width * 0.16,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: false
                )
            }
            .stroke(Color.white.opacity(0.52), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }

    private func goal(size: CGSize) -> some View {
        let width = size.width * 0.62
        let height = size.height * 0.30
        let center = CGPoint(x: size.width / 2, y: size.height * 0.23)

        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white.opacity(0.98), lineWidth: 6)
                .frame(width: width, height: height)

            ForEach(1..<6, id: \.self) { index in
                Path { path in
                    let x = center.x - width / 2 + width * CGFloat(index) / 6
                    path.move(to: CGPoint(x: x, y: center.y - height / 2))
                    path.addLine(to: CGPoint(x: x, y: center.y + height / 2))
                }
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }

            ForEach(1..<4, id: \.self) { index in
                Path { path in
                    let y = center.y - height / 2 + height * CGFloat(index) / 4
                    path.move(to: CGPoint(x: center.x - width / 2, y: y))
                    path.addLine(to: CGPoint(x: center.x + width / 2, y: y))
                }
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .position(center)
        .allowsHitTesting(false)
    }

    private func goalkeeper(size: CGSize) -> some View {
        VStack(spacing: -2) {
            Circle()
                .fill(Color(red: 0.93, green: 0.70, blue: 0.22))
                .frame(width: 22, height: 22)
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 0.93, green: 0.70, blue: 0.22))
                .frame(width: 42, height: 48)
                .overlay {
                    HStack(spacing: 34) {
                        Capsule().fill(Color.white.opacity(0.9)).frame(width: 10, height: 34)
                        Capsule().fill(Color.white.opacity(0.9)).frame(width: 10, height: 34)
                    }
                }
            HStack(spacing: 8) {
                Capsule().fill(Color.black.opacity(0.72)).frame(width: 12, height: 32)
                Capsule().fill(Color.black.opacity(0.72)).frame(width: 12, height: 32)
            }
        }
        .shadow(color: .black.opacity(0.28), radius: 4, y: 3)
        .position(x: size.width / 2, y: size.height * 0.29)
        .accessibilityHidden(true)
    }

    private func aimGuide(size: CGSize) -> some View {
        let point = targetPoint(size: size)
        let ballPoint = CGPoint(x: size.width / 2, y: size.height * 0.79)

        return ZStack {
            Path { path in
                path.move(to: ballPoint)
                path.addLine(to: point)
            }
            .stroke(
                isAiming ? Color.pingoPrimary.opacity(0.96) : Color.white.opacity(0.70),
                style: StrokeStyle(lineWidth: isAiming ? 3 : 2, lineCap: .round, dash: [6, 7])
            )

            Circle()
                .stroke(isAiming ? Color.pingoPrimary : Color.white.opacity(0.90), lineWidth: isAiming ? 3 : 2)
                .frame(width: isAiming ? 56 : 48, height: isAiming ? 56 : 48)
                .position(point)

            Circle()
                .fill(Color.pingoPrimary.opacity(0.88))
                .frame(width: 10, height: 10)
                .position(point)
        }
        .allowsHitTesting(false)
    }

    private func penaltySpot(size: CGSize) -> some View {
        Circle()
            .fill(Color.white.opacity(0.92))
            .frame(width: 8, height: 8)
            .position(x: size.width / 2, y: size.height * 0.70)
    }

    private func ball(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.84)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 34
                    )
                )
            Image(systemName: "soccerball")
                .font(.system(size: 31, weight: .regular))
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(width: 62, height: 62)
        .shadow(color: .black.opacity(0.34), radius: 6, y: 4)
        .scaleEffect(isAiming ? 1.06 : 1)
        .offset(y: isAiming ? -min(14, CGFloat(power / 100) * 14) : 0)
        .position(x: size.width / 2, y: size.height * 0.79)
        .accessibilityLabel("Penalty ball. Drag sideways to aim and flick upward to kick.")
    }

    private var kickBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "soccerball")
                .font(.system(size: 10, weight: .black))
            Text("KICK \(min(5, attempts(player) + 1))")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.32), in: Capsule())
    }

    private var aimReadout: some View {
        HStack(spacing: 6) {
            Text(targetLabel(for: target).uppercased())
            Text("P \(Int(power.rounded()))")
        }
        .font(.system(size: 9, weight: .black, design: .rounded).monospacedDigit())
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.black.opacity(0.34), in: Capsule())
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Image(systemName: "scope")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.pingoPrimary)

            VStack(alignment: .leading, spacing: 1) {
                Text(state.lastSummary.isEmpty ? (canMove ? "YOUR KICK" : "GOAL READY") : state.lastSummary.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.64))
                Text(canMove ? "Drag sideways to pick a spot, then flick upward to shoot." : "Waiting for the next turn.")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.38))
            }

            Spacer()

            Text("\(attempts(player))/5")
                .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.42))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var instructionBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw.fill")
                .foregroundStyle(Color.pingoPrimary)
            Text("DRAG TO AIM • FLICK UP TO SHOOT")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.4)
            Spacer()
            Image(systemName: "arrow.up")
                .font(.system(size: 12, weight: .black))
        }
        .foregroundStyle(.black.opacity(0.56))
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(.white.opacity(0.64), in: Capsule())
    }

    private func scoreChip(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.5)
            Text("\(score)")
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
            Text("\(attempts)/5")
                .font(.system(size: 7, weight: .bold, design: .rounded).monospacedDigit())
                .opacity(0.55)
        }
        .foregroundStyle(emphasized ? Color.pingoPrimary : .black.opacity(0.62))
        .frame(width: 54, height: 48)
        .background(.white.opacity(emphasized ? 0.76 : 0.50), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func targetPoint(size: CGSize) -> CGPoint {
        let xs: [CGFloat] = [0.26, 0.36, 0.50, 0.64, 0.74]
        let ys: [CGFloat] = [0.18, 0.30, 0.17, 0.30, 0.18]
        let index = min(4, max(0, target))
        return CGPoint(x: size.width * xs[index], y: size.height * ys[index])
    }

    private func targetLabel(for lane: Int) -> String {
        switch lane {
        case 0: return "Lower left"
        case 1: return "Left"
        case 2: return "Center"
        case 3: return "Right"
        default: return "Lower right"
        }
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }
}
