import PingoCore
import SwiftUI

struct PingoArcheryPhase1View: View {
    let state: PingoExtraGameState
    let player: Int
    let canMove: Bool
    let onMove: (PingoExtraGameMove) -> Void

    @State private var horizontal = 50.0
    @State private var vertical = 50.0
    @State private var hasLockedAim = false
    @State private var isAiming = false

    var body: some View {
        VStack(spacing: 12) {
            header

            rangeStage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            statusRibbon

            if canMove {
                controls
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARCHERY")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(0.8)
                Text("FIVE-ARROW DUEL")
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

    private var rangeStage: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.77, green: 0.88, blue: 0.94),
                                Color(red: 0.86, green: 0.90, blue: 0.72),
                                Color(red: 0.43, green: 0.65, blue: 0.33)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.22), radius: 12, y: 6)

                skyGlow(size: size)
                rangeLines(size: size)
                targetStand(size: size)
                targetFace(size: size)
                aimingGuide(size: size)
                archerLane(size: size)

                VStack {
                    HStack {
                        arrowBadge
                        Spacer()
                    }
                    Spacer()
                }
                .padding(22)
            }
            .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .gesture(archeryGesture(size: size))
        }
    }

    private func skyGlow(size: CGSize) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.white.opacity(0.34), Color.white.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: max(80, size.height * 0.34))
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .allowsHitTesting(false)
    }

    private func rangeLines(size: CGSize) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: size.width * 0.06, y: size.height * 0.86))
                path.addLine(to: CGPoint(x: size.width * 0.39, y: size.height * 0.42))
                path.move(to: CGPoint(x: size.width * 0.94, y: size.height * 0.86))
                path.addLine(to: CGPoint(x: size.width * 0.61, y: size.height * 0.42))
            }
            .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))

            ForEach(0..<4, id: \.self) { index in
                let y = size.height * (0.58 + CGFloat(index) * 0.085)
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.12, y: y))
                    path.addLine(to: CGPoint(x: size.width * 0.88, y: y))
                }
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }

    private func targetStand(size: CGSize) -> some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.35, green: 0.20, blue: 0.10))
                .frame(width: 14, height: size.height * 0.28)
                .rotationEffect(.degrees(17))
                .offset(x: -30)

            Capsule()
                .fill(Color(red: 0.35, green: 0.20, blue: 0.10))
                .frame(width: 14, height: size.height * 0.28)
                .rotationEffect(.degrees(-17))
                .offset(x: 30)

            Capsule()
                .fill(Color(red: 0.29, green: 0.16, blue: 0.08))
                .frame(width: size.width * 0.24, height: 12)
                .offset(y: size.height * 0.12)
        }
        .position(x: size.width / 2, y: size.height * 0.43)
        .allowsHitTesting(false)
    }

    private func targetFace(size: CGSize) -> some View {
        let diameter = min(size.width * 0.58, size.height * 0.57)
        return ZStack {
            targetRing(color: .white, diameter: diameter)
            targetRing(color: Color.black.opacity(0.82), diameter: diameter * 0.82)
            targetRing(color: Color(red: 0.18, green: 0.47, blue: 0.80), diameter: diameter * 0.64)
            targetRing(color: Color(red: 0.91, green: 0.18, blue: 0.18), diameter: diameter * 0.46)
            targetRing(color: Color(red: 0.98, green: 0.79, blue: 0.15), diameter: diameter * 0.28)
            targetRing(color: Color(red: 1.00, green: 0.88, blue: 0.26), diameter: diameter * 0.13)

            Circle()
                .stroke(Color.black.opacity(0.18), lineWidth: 1)
                .frame(width: diameter, height: diameter)
        }
        .position(x: size.width / 2, y: size.height * 0.39)
        .shadow(color: .black.opacity(0.22), radius: 7, y: 5)
        .accessibilityLabel("Archery target")
    }

    private func targetRing(color: Color, diameter: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
    }

    private func aimingGuide(size: CGSize) -> some View {
        let point = aimPoint(size: size)
        return ZStack {
            Path { path in
                path.move(to: CGPoint(x: size.width / 2, y: size.height * 0.87))
                path.addLine(to: point)
            }
            .stroke(Color.white.opacity(hasLockedAim || isAiming ? 0.72 : 0.42), style: StrokeStyle(lineWidth: 2, dash: [6, 7]))

            Circle()
                .stroke(Color.white.opacity(0.95), lineWidth: isAiming ? 3 : 2)
                .frame(width: isAiming ? 48 : 42, height: isAiming ? 48 : 42)
                .position(point)

            Path { path in
                path.move(to: CGPoint(x: point.x - 26, y: point.y))
                path.addLine(to: CGPoint(x: point.x + 26, y: point.y))
                path.move(to: CGPoint(x: point.x, y: point.y - 26))
                path.addLine(to: CGPoint(x: point.x, y: point.y + 26))
            }
            .stroke(Color.white.opacity(0.82), lineWidth: 1.5)

            Circle()
                .fill(Color.pingoPrimary)
                .frame(width: isAiming ? 11 : 9, height: isAiming ? 11 : 9)
                .position(point)
        }
        .animation(.easeOut(duration: 0.12), value: isAiming)
        .allowsHitTesting(false)
    }

    private func archerLane(size: CGSize) -> some View {
        VStack(spacing: 3) {
            Image(systemName: "figure.archery")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.28), radius: 4, y: 3)

            Capsule()
                .fill(Color.white.opacity(0.54))
                .frame(width: 88, height: 4)
        }
        .position(x: size.width / 2, y: size.height * 0.86)
        .accessibilityHidden(true)
    }

    private var arrowBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "scope")
                .font(.system(size: 10, weight: .black))
            Text("ARROW \(min(5, attempts(player) + 1))")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
        }
        .foregroundStyle(.white.opacity(0.96))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.28), in: Capsule())
    }

    private var statusRibbon: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(canMove ? Color.pingoPrimary : Color.black.opacity(0.20))
                .frame(width: 8, height: 8)

            Text(canMove ? "YOUR SHOT" : "WAITING FOR OPPONENT")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.black.opacity(0.58))

            Spacer()

            if !state.lastSummary.isEmpty {
                Text(state.lastSummary.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 4)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Image(systemName: hasLockedAim ? "arrow.up.circle.fill" : "scope")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.pingoPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(hasLockedAim ? "FLICK UP TO SHOOT" : "DRAG ON THE TARGET TO AIM")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.45)
                    .foregroundStyle(.black.opacity(0.66))
                Text(hasLockedAim ? "Drag again anytime to refine your aim." : "Release to lock the reticle, then flick upward.")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.42))
            }

            Spacer()

            if hasLockedAim {
                Text("\(Int(horizontal.rounded())) · \(Int(vertical.rounded()))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.44))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.white.opacity(0.46), in: Capsule())
    }

    private func archeryGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard canMove else { return }
                isAiming = true

                // Once the user commits to an upward release, preserve the locked
                // reticle instead of dragging it away from the intended target.
                if value.translation.height > -28 {
                    updateAim(location: value.location, size: size)
                }
            }
            .onEnded { value in
                guard canMove else {
                    isAiming = false
                    return
                }

                let isReleaseFlick = value.translation.height <= -36
                if isReleaseFlick, hasLockedAim {
                    isAiming = false
                    onMove(
                        .init(
                            primary: Int(horizontal.rounded()),
                            secondary: Int(vertical.rounded())
                        )
                    )
                    return
                }

                updateAim(location: value.location, size: size)
                hasLockedAim = true
                isAiming = false
            }
    }

    private func updateAim(location: CGPoint, size: CGSize) {
        let diameter = min(size.width * 0.58, size.height * 0.57)
        let radius = max(1, diameter * 0.42)
        let center = CGPoint(x: size.width / 2, y: size.height * 0.39)

        let x = min(max(location.x, center.x - radius), center.x + radius)
        let y = min(max(location.y, center.y - radius), center.y + radius)

        horizontal = min(max(50 + Double((x - center.x) / radius) * 50, 0), 100)
        vertical = min(max(50 + Double((y - center.y) / radius) * 50, 0), 100)
    }

    private func aimPoint(size: CGSize) -> CGPoint {
        let diameter = min(size.width * 0.58, size.height * 0.57)
        let radius = diameter * 0.42
        let x = size.width / 2 + CGFloat((horizontal - 50) / 50) * radius
        let y = size.height * 0.39 + CGFloat((vertical - 50) / 50) * radius
        return CGPoint(x: x, y: y)
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }

    private func scoreChip(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.6)
            Text("\(score)")
                .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
            Text("\(attempts)/5")
                .font(.system(size: 8, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.black.opacity(0.40))
        }
        .foregroundStyle(.black.opacity(emphasized ? 0.78 : 0.58))
        .frame(width: 50)
        .padding(.vertical, 5)
        .background(
            emphasized ? Color.pingoPrimary.opacity(0.13) : Color.white.opacity(0.38),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}
