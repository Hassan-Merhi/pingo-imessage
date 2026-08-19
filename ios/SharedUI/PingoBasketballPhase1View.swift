import PingoCore
import SwiftUI

// Stable Basketball route. Phase 2 replaces Phase 1's sliders/button with a direct
// flick-to-shoot gesture while preserving the existing deterministic move contract.
struct PingoBasketballPhase1View: View {
    let state: PingoBasketballState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var angle = 52.0
    @State private var power = 0.72
    @State private var dragTranslation: CGSize = .zero
    @State private var isAiming = false

    var body: some View {
        VStack(spacing: 10) {
            scoreboard

            GeometryReader { proxy in
                ZStack {
                    arenaBackground
                    courtGlow(size: proxy.size)
                    backboard(size: proxy.size)
                    hoop(size: proxy.size)
                    net(size: proxy.size)
                    floor(size: proxy.size)
                    if canMove { trajectory(size: proxy.size) }
                    ball(size: proxy.size)
                    resultBanner(size: proxy.size)
                    attemptDots(size: proxy.size)
                    if canMove { gestureHint(size: proxy.size) }
                }
                .contentShape(Rectangle())
                .gesture(canMove ? shotGesture(size: proxy.size) : nil)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(isAiming ? 0.26 : 0.12), lineWidth: isAiming ? 2 : 1)
                }
                .shadow(color: .black.opacity(0.30), radius: 14, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if canMove { shotReadout }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var scoreboard: some View {
        HStack(spacing: 10) {
            scoreSide(title: "YOU", score: score(player), attempts: attempts(player), emphasized: canMove)
            VStack(spacing: 2) {
                Text("BASKETBALL")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white)
                Text("5-SHOT SHOOTOUT")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .frame(maxWidth: .infinity)
            scoreSide(title: "THEM", score: score(1 - player), attempts: attempts(1 - player), emphasized: false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1) }
    }

    private func scoreSide(title: String, score: Int, attempts: Int, emphasized: Bool) -> some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(emphasized ? Color.orange : .white.opacity(0.48))
                Text("\(attempts)/\(state.attemptsPerPlayer)")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.38))
            }
            Text("\(score)")
                .font(.system(size: 25, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(minWidth: 70)
    }

    private var arenaBackground: some View {
        LinearGradient(
            colors: [Color(red: 0.055, green: 0.055, blue: 0.075), Color(red: 0.10, green: 0.055, blue: 0.025), Color(red: 0.19, green: 0.085, blue: 0.025)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func courtGlow(size: CGSize) -> some View {
        ZStack {
            Ellipse()
                .fill(Color.orange.opacity(0.22))
                .blur(radius: 34)
                .frame(width: size.width * 0.82, height: size.height * 0.34)
                .position(x: size.width * 0.52, y: size.height * 0.63)
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == 2 ? 0.20 : 0.09))
                    .frame(width: size.width * 0.12, height: 3)
                    .blur(radius: 1.5)
                    .position(x: size.width * (0.16 + Double(index) * 0.17), y: size.height * 0.10)
            }
        }
    }

    private func backboard(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.10))
                .overlay { RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.92), lineWidth: 5) }
                .frame(width: size.width * 0.42, height: size.height * 0.25)
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.white.opacity(0.72), lineWidth: 3)
                .frame(width: size.width * 0.15, height: size.height * 0.09)
                .offset(y: size.height * 0.035)
        }
        .position(x: size.width * 0.72, y: size.height * 0.23)
    }

    private func hoop(size: CGSize) -> some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.92, green: 0.20, blue: 0.08))
                .frame(width: size.width * 0.25, height: 8)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            Ellipse()
                .stroke(Color(red: 1.0, green: 0.28, blue: 0.08), lineWidth: 4)
                .frame(width: size.width * 0.25, height: 15)
                .offset(y: -2)
        }
        .position(x: size.width * 0.72, y: size.height * 0.37)
    }

    private func net(size: CGSize) -> some View {
        Path { path in
            let cx = size.width * 0.72
            let top = size.height * 0.385
            let bottom = size.height * 0.49
            let wide = size.width * 0.11
            let narrow = size.width * 0.055
            for step in 0...4 {
                let t = CGFloat(step) / 4
                let y = top + (bottom - top) * t
                let w = wide + (narrow - wide) * t
                path.move(to: CGPoint(x: cx - w, y: y))
                path.addLine(to: CGPoint(x: cx + w, y: y))
            }
            for step in 0...4 {
                let t = CGFloat(step) / 4
                path.move(to: CGPoint(x: cx - wide + wide * 2 * t, y: top))
                path.addLine(to: CGPoint(x: cx - narrow + narrow * 2 * t, y: bottom))
            }
        }
        .stroke(Color.white.opacity(0.68), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
    }

    private func floor(size: CGSize) -> some View {
        ZStack {
            Path { path in
                let horizon = size.height * 0.63
                path.move(to: CGPoint(x: 0, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(red: 0.58, green: 0.24, blue: 0.055), Color(red: 0.31, green: 0.11, blue: 0.025)], startPoint: .top, endPoint: .bottom))

            Path { path in
                let horizon = size.height * 0.64
                path.move(to: CGPoint(x: 0, y: horizon))
                path.addLine(to: CGPoint(x: size.width, y: horizon))
                path.move(to: CGPoint(x: size.width * 0.50, y: horizon))
                path.addLine(to: CGPoint(x: size.width * 0.50, y: size.height))
                path.move(to: CGPoint(x: size.width * 0.18, y: size.height))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.82, y: size.height), control: CGPoint(x: size.width * 0.50, y: size.height * 0.72))
            }
            .stroke(Color.white.opacity(0.36), lineWidth: 2)
        }
    }

    private func trajectory(size: CGSize) -> some View {
        let start = CGPoint(x: size.width * 0.27, y: size.height * 0.72)
        let end = CGPoint(x: size.width * 0.72, y: size.height * 0.37)
        let lift = size.height * CGFloat(0.18 + power * 0.20)
        let angleShift = size.width * CGFloat((angle - 52) / 45) * 0.15
        let control = CGPoint(x: (start.x + end.x) / 2 + angleShift, y: min(start.y, end.y) - lift)
        return Path { path in
            path.move(to: start)
            path.addQuadCurve(to: end, control: control)
        }
        .stroke(Color.white.opacity(isAiming ? 0.86 : 0.34), style: StrokeStyle(lineWidth: isAiming ? 2.5 : 1.5, lineCap: .round, dash: [5, 7]))
    }

    private func ball(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(red: 1.0, green: 0.50, blue: 0.10), Color(red: 0.74, green: 0.20, blue: 0.025)], center: .topLeading, startRadius: 1, endRadius: 34))
            Circle().stroke(Color.black.opacity(0.50), lineWidth: 2)
            Path { path in
                path.move(to: CGPoint(x: 4, y: 28)); path.addQuadCurve(to: CGPoint(x: 52, y: 28), control: CGPoint(x: 28, y: 5))
                path.move(to: CGPoint(x: 4, y: 28)); path.addQuadCurve(to: CGPoint(x: 52, y: 28), control: CGPoint(x: 28, y: 51))
                path.move(to: CGPoint(x: 28, y: 2)); path.addLine(to: CGPoint(x: 28, y: 54))
            }
            .stroke(Color.black.opacity(0.52), lineWidth: 1.6)
        }
        .frame(width: isAiming ? 62 : 56, height: isAiming ? 62 : 56)
        .shadow(color: .black.opacity(0.42), radius: 7, y: 5)
        .position(x: size.width * 0.27 + dragTranslation.width * 0.08, y: size.height * 0.72 + min(0, dragTranslation.height) * 0.06)
        .animation(.easeOut(duration: 0.12), value: isAiming)
    }

    private func resultBanner(size: CGSize) -> some View {
        VStack(spacing: 3) {
            Text(isAiming ? "RELEASE TO SHOOT" : lastResult)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .tracking(0.5)
            Text(isAiming ? "FLICK UP • SLIDE SIDEWAYS TO AIM" : "ATTEMPT \(min(attempts(player) + 1, state.attemptsPerPlayer)) OF \(state.attemptsPerPlayer)")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.white.opacity(0.54))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.62), in: Capsule())
        .position(x: size.width * 0.48, y: size.height * 0.54)
    }

    private func attemptDots(size: CGSize) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<state.attemptsPerPlayer, id: \.self) { index in
                Circle()
                    .fill(index < attempts(player) ? Color.orange : Color.white.opacity(0.20))
                    .frame(width: 8, height: 8)
                    .overlay { Circle().stroke(Color.white.opacity(0.18), lineWidth: 1) }
            }
        }
        .position(x: size.width * 0.50, y: size.height * 0.91)
    }

    private func gestureHint(size: CGSize) -> some View {
        VStack(spacing: 3) {
            Image(systemName: "arrow.up")
                .font(.system(size: 15, weight: .black))
            Text("FLICK")
                .font(.system(size: 7, weight: .black, design: .rounded))
                .tracking(1)
        }
        .foregroundStyle(.white.opacity(isAiming ? 0 : 0.46))
        .position(x: size.width * 0.27, y: size.height * 0.87)
    }

    private var shotReadout: some View {
        HStack(spacing: 12) {
            Label("\(Int(angle.rounded()))°", systemImage: "scope")
            Spacer()
            Text(isAiming ? "RELEASE TO SHOOT" : "FLICK UP TO SHOOT")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.8)
            Spacer()
            Label("\(Int((power * 100).rounded()))%", systemImage: "bolt.fill")
        }
        .font(.caption.monospacedDigit().bold())
        .foregroundStyle(.white.opacity(0.70))
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Color.black.opacity(0.50), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Release angle \(Int(angle.rounded())) degrees, power \(Int((power * 100).rounded())) percent. Flick up to shoot.")
    }

    private func shotGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                isAiming = true
                dragTranslation = value.translation
                let horizontal = Double(value.translation.width / max(size.width, 1))
                let upward = Double(max(0, -value.translation.height) / max(size.height * 0.55, 1))
                angle = min(75, max(30, 52 + horizontal * 70))
                power = min(1, max(0.2, 0.2 + upward * 0.8))
            }
            .onEnded { value in
                let upward = -value.translation.height
                let shouldShoot = upward >= max(34, size.height * 0.10)
                if shouldShoot {
                    onMove(.basketball(.init(angleDegrees: angle, power: power)))
                }
                withAnimation(.easeOut(duration: 0.18)) {
                    isAiming = false
                    dragTranslation = .zero
                }
            }
    }

    private func score(_ index: Int) -> Int {
        state.scores.indices.contains(index) ? state.scores[index] : 0
    }

    private func attempts(_ index: Int) -> Int {
        state.attempts.indices.contains(index) ? state.attempts[index] : 0
    }

    private var lastResult: String {
        if state.attempts.reduce(0, +) == 0 { return "READY" }
        if state.lastPoints == 3 { return "SWISH +3" }
        if state.lastPoints == 2 { return "BUCKET +2" }
        return "MISS"
    }
}
