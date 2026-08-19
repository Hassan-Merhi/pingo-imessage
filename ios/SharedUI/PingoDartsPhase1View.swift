import PingoCore
import SwiftUI

struct PingoDartsPhase2View: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var darts: [PingoDartPoint] = []
    @State private var aimPoint = PingoDartPoint(x: 0, y: 0)
    @State private var throwPower: CGFloat = 0
    @State private var isFlicking = false

    var body: some View {
        VStack(spacing: 12) {
            scoreHeader

            GeometryReader { proxy in
                ZStack {
                    arenaBackdrop
                    boardStage(size: proxy.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            visitTray

            if canMove {
                throwDeck

                Button {
                    guard darts.count == 3 else { return }
                    onMove(.darts(.init(darts: darts)))
                    darts.removeAll()
                    aimPoint = .init(x: 0, y: 0)
                } label: {
                    Label("Send Visit", systemImage: "scope")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.88, green: 0.16, blue: 0.12), Color(red: 0.62, green: 0.05, blue: 0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .disabled(darts.count != 3)
                .opacity(darts.count == 3 ? 1 : 0.42)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .onChange(of: state.remaining) { _ in
            darts.removeAll()
            aimPoint = .init(x: 0, y: 0)
            throwPower = 0
            isFlicking = false
        }
    }

    private var scoreHeader: some View {
        HStack(spacing: 10) {
            scoreCard(title: "YOU", value: remaining(player), highlighted: canMove)

            VStack(spacing: 2) {
                Text("DARTS")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                Text("301 • AIM + FLICK")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .frame(maxWidth: .infinity)

            scoreCard(title: "THEM", value: remaining(1 - player), highlighted: !canMove)
        }
        .padding(.horizontal, 2)
    }

    private func scoreCard(title: String, value: Int, highlighted: Bool) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(.white.opacity(0.5))
            Text("\(value)")
                .font(.system(size: 25, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(highlighted ? .white : .white.opacity(0.74))
        }
        .frame(width: 72, height: 48)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(highlighted ? Color.white.opacity(0.22) : Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var arenaBackdrop: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color(red: 0.18, green: 0.16, blue: 0.13), Color(red: 0.055, green: 0.055, blue: 0.055)],
                    center: .center,
                    startRadius: 30,
                    endRadius: 280
                )
            )
            .overlay(alignment: .top) {
                LinearGradient(colors: [.white.opacity(0.11), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.32), radius: 12, y: 6)
    }

    @ViewBuilder
    private func boardStage(size: CGSize) -> some View {
        let diameter = min(size.width * 0.91, size.height * 0.91)

        ZStack {
            Circle()
                .fill(.black.opacity(0.72))
                .frame(width: diameter + 26, height: diameter + 26)
                .shadow(color: .black.opacity(0.55), radius: 12, y: 7)

            PingoPhase2DartBoard(
                darts: darts,
                aimPoint: aimPoint,
                enabled: canMove && darts.count < 3,
                onAim: { aimPoint = $0 }
            )
            .frame(width: diameter, height: diameter)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var visitTray: some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    ZStack {
                        Circle()
                            .fill(index < darts.count ? Color(red: 0.85, green: 0.15, blue: 0.11) : .white.opacity(0.10))
                        Circle()
                            .stroke(.white.opacity(index < darts.count ? 0.45 : 0.14), lineWidth: 1)
                        if index < darts.count {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 27, height: 27)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(canMove ? "YOUR VISIT" : "OPPONENT'S VISIT")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.55))
                Text(canMove ? "Aim on board • flick to throw • \(darts.count)/3" : "Board locked")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
            }

            Spacer()

            if canMove && !darts.isEmpty {
                Button {
                    darts.removeAll()
                    throwPower = 0
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.09), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear darts")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
    }

    private var throwDeck: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.075))

                HStack(spacing: 12) {
                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(.white.opacity(0.10))
                            .frame(width: 8, height: 42)
                        Capsule()
                            .fill(Color(red: 0.88, green: 0.16, blue: 0.12))
                            .frame(width: 8, height: max(4, 42 * throwPower))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isFlicking ? "RELEASE TO THROW" : "FLICK UP TO THROW")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(.white)
                        Text("Drag on the board to move the sight. A small sideways flick fine-tunes the release.")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white.opacity(isFlicking ? 1 : 0.58))
                        .offset(y: isFlicking ? -8 : 0)
                }
                .padding(.horizontal, 14)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        guard darts.count < 3 else { return }
                        isFlicking = true
                        let upward = max(0, -value.translation.height)
                        throwPower = min(1, upward / 92)
                    }
                    .onEnded { value in
                        guard darts.count < 3 else {
                            resetThrowDeck()
                            return
                        }

                        let upward = max(0, -value.translation.height)
                        guard upward >= 42 else {
                            resetThrowDeck()
                            return
                        }

                        let horizontalNudge = Double(value.translation.width / width) * 0.34
                        let point = clampedDartPoint(
                            x: aimPoint.x + horizontalNudge,
                            y: aimPoint.y
                        )
                        darts.append(point)
                        aimPoint = point
                        resetThrowDeck()
                    }
            )
        }
        .frame(height: 66)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Dart throw control")
        .accessibilityHint("Swipe upward to throw at the current aim point")
    }

    private func resetThrowDeck() {
        throwPower = 0
        isFlicking = false
    }

    private func clampedDartPoint(x: Double, y: Double) -> PingoDartPoint {
        var px = max(-1, min(1, x))
        var py = max(-1, min(1, y))
        let radius = sqrt(px * px + py * py)
        if radius > 1 {
            px /= radius
            py /= radius
        }
        return .init(x: px, y: py)
    }

    private func remaining(_ index: Int) -> Int {
        state.remaining.indices.contains(index) ? state.remaining[index] : 301
    }
}

private struct PingoPhase2DartBoard: View {
    let darts: [PingoDartPoint]
    let aimPoint: PingoDartPoint
    let enabled: Bool
    let onAim: (PingoDartPoint) -> Void

    private let numbers = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let outerRadius = size / 2

            ZStack {
                Circle().fill(Color(red: 0.055, green: 0.05, blue: 0.045))

                ForEach(0..<20, id: \.self) { index in
                    let start = Double(index) * 18 - 99
                    let end = start + 18
                    let lightSector = index.isMultiple(of: 2)

                    PingoDartSector(startDegrees: start, endDegrees: end, innerFraction: 0.17, outerFraction: 0.87)
                        .fill(lightSector ? Color(red: 0.88, green: 0.84, blue: 0.68) : Color(red: 0.10, green: 0.095, blue: 0.085))
                    PingoDartSector(startDegrees: start, endDegrees: end, innerFraction: 0.54, outerFraction: 0.62)
                        .fill(lightSector ? Color(red: 0.10, green: 0.47, blue: 0.26) : Color(red: 0.76, green: 0.08, blue: 0.08))
                    PingoDartSector(startDegrees: start, endDegrees: end, innerFraction: 0.79, outerFraction: 0.87)
                        .fill(lightSector ? Color(red: 0.10, green: 0.47, blue: 0.26) : Color(red: 0.76, green: 0.08, blue: 0.08))
                }

                Circle().stroke(Color.black.opacity(0.72), lineWidth: 2).padding(size * 0.065)
                Circle().stroke(Color.white.opacity(0.16), lineWidth: 1).padding(size * 0.19)
                Circle().fill(Color(red: 0.10, green: 0.45, blue: 0.25)).frame(width: size * 0.13, height: size * 0.13)
                Circle().fill(Color(red: 0.76, green: 0.07, blue: 0.07)).frame(width: size * 0.055, height: size * 0.055)

                ForEach(0..<20, id: \.self) { index in
                    let angle = Double(index) * 18 - 90
                    let radians = angle * .pi / 180
                    Text("\(numbers[index])")
                        .font(.system(size: max(9, size * 0.043), weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .position(
                            x: center.x + cos(radians) * outerRadius * 0.935,
                            y: center.y + sin(radians) * outerRadius * 0.935
                        )
                }

                ForEach(Array(darts.enumerated()), id: \.offset) { index, dart in
                    PingoPhase2DartMarker(index: index)
                        .position(position(for: dart, in: proxy.size))
                }

                if enabled {
                    PingoDartAimSight()
                        .position(position(for: aimPoint, in: proxy.size))
                        .allowsHitTesting(false)
                }
            }
            .overlay { Circle().stroke(Color.white.opacity(0.12), lineWidth: 1) }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in updateAim(value.location, size: proxy.size) }
                    .onEnded { value in updateAim(value.location, size: proxy.size) }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Dartboard")
        .accessibilityHint(enabled ? "Drag across the board to aim, then flick upward below the board to throw" : "Waiting for opponent")
    }

    private func updateAim(_ location: CGPoint, size: CGSize) {
        guard enabled, size.width > 0, size.height > 0 else { return }
        var nx = Double((location.x / size.width - 0.5) * 2)
        var ny = Double((location.y / size.height - 0.5) * 2)
        let radius = sqrt(nx * nx + ny * ny)
        if radius > 1 {
            nx /= radius
            ny /= radius
        }
        onAim(.init(x: nx, y: ny))
    }

    private func position(for point: PingoDartPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * CGFloat(point.x / 2 + 0.5),
            y: size.height * CGFloat(point.y / 2 + 0.5)
        )
    }
}

private struct PingoDartAimSight: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.94), lineWidth: 1.5)
                .frame(width: 34, height: 34)
            Circle()
                .stroke(Color(red: 0.92, green: 0.16, blue: 0.12), lineWidth: 2)
                .frame(width: 18, height: 18)
            Rectangle().fill(.white.opacity(0.88)).frame(width: 1, height: 42)
            Rectangle().fill(.white.opacity(0.88)).frame(width: 42, height: 1)
            Circle().fill(Color(red: 0.92, green: 0.16, blue: 0.12)).frame(width: 5, height: 5)
        }
        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
    }
}

private struct PingoDartSector: Shape {
    let startDegrees: Double
    let endDegrees: Double
    let innerFraction: CGFloat
    let outerFraction: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let outer = radius * outerFraction
        let inner = radius * innerFraction
        let start = Angle.degrees(startDegrees)
        let end = Angle.degrees(endDegrees)

        var path = Path()
        path.addArc(center: center, radius: outer, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: inner, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }
}

private struct PingoPhase2DartMarker: View {
    let index: Int

    var body: some View {
        ZStack(alignment: .center) {
            Capsule()
                .fill(Color.white.opacity(0.95))
                .frame(width: 4, height: 29)
                .offset(y: -11)
                .rotationEffect(.degrees(38))

            Image(systemName: "triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(index.isMultiple(of: 2) ? Color(red: 0.92, green: 0.16, blue: 0.12) : Color(red: 0.12, green: 0.56, blue: 0.31))
                .rotationEffect(.degrees(128))
                .offset(x: 10, y: -12)

            Circle()
                .fill(Color(red: 0.92, green: 0.16, blue: 0.12))
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .frame(width: 13, height: 13)
                .shadow(color: .black.opacity(0.34), radius: 2, y: 1)
        }
        .frame(width: 38, height: 38)
    }
}
