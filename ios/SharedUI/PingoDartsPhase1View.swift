import PingoCore
import SwiftUI

struct PingoDartsPhase1View: View {
    let state: PingoDartsState
    let player: Int
    let canMove: Bool
    let onMove: (PingoPhysicsMove) -> Void

    @State private var darts: [PingoDartPoint] = []

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
                Button {
                    guard darts.count == 3 else { return }
                    onMove(.darts(.init(darts: darts)))
                    darts.removeAll()
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
        .onChange(of: state.remaining) { _, _ in
            darts.removeAll()
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
                Text("301 • BEST CHECKOUT")
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
                LinearGradient(
                    colors: [.white.opacity(0.11), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
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

            PingoPhase1DartBoard(darts: darts, enabled: canMove && darts.count < 3) { point in
                darts.append(point)
            }
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
                Text(canMove ? "Tap the board • \(darts.count)/3 darts" : "Board locked")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.84))
            }

            Spacer()

            if canMove && !darts.isEmpty {
                Button {
                    darts.removeAll()
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

    private func remaining(_ index: Int) -> Int {
        state.remaining.indices.contains(index) ? state.remaining[index] : 301
    }
}

private struct PingoPhase1DartBoard: View {
    let darts: [PingoDartPoint]
    let enabled: Bool
    let onTap: (PingoDartPoint) -> Void

    private let numbers = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let outerRadius = size / 2

            ZStack {
                Circle()
                    .fill(Color(red: 0.055, green: 0.05, blue: 0.045))

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

                Circle()
                    .stroke(Color.black.opacity(0.72), lineWidth: 2)
                    .padding(size * 0.065)

                Circle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    .padding(size * 0.19)

                Circle()
                    .fill(Color(red: 0.10, green: 0.45, blue: 0.25))
                    .frame(width: size * 0.13, height: size * 0.13)
                Circle()
                    .fill(Color(red: 0.76, green: 0.07, blue: 0.07))
                    .frame(width: size * 0.055, height: size * 0.055)

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
                    PingoPhase1DartMarker(index: index)
                        .position(
                            x: proxy.size.width * CGFloat(dart.x / 2 + 0.5),
                            y: proxy.size.height * CGFloat(dart.y / 2 + 0.5)
                        )
                }
            }
            .overlay {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0).onEnded { value in
                    guard enabled, proxy.size.width > 0, proxy.size.height > 0 else { return }
                    let nx = Double((value.location.x / proxy.size.width - 0.5) * 2)
                    let ny = Double((value.location.y / proxy.size.height - 0.5) * 2)
                    guard nx * nx + ny * ny <= 1 else { return }
                    onTap(.init(x: nx, y: ny))
                }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Dartboard")
        .accessibilityHint(enabled ? "Tap a target to place a dart" : "Waiting for opponent")
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

private struct PingoPhase1DartMarker: View {
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
