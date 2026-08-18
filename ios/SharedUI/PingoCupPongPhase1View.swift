import PingoCore
import SwiftUI

struct PingoCupPongPhase1View: View {
    let state: PingoCupPongState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    @State private var aim = 0.0
    @State private var power = 0.58

    private var localPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id == localProfile.id })
    }

    private var opponentPlayer: PingoPlayerRef? {
        match.players.first(where: { $0.id != localProfile.id })
    }

    private var opponentIndex: Int {
        player == 0 ? 1 : 0
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.05, blue: 0.075),
                    Color(red: 0.055, green: 0.075, blue: 0.105),
                    Color(red: 0.025, green: 0.035, blue: 0.055)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                matchHeader

                pongStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let lastCup = state.lastCup {
                    sunkBanner(cup: lastCup)
                }

                if canMove {
                    legacyShotControls
                } else {
                    lockedFooter
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 2)
            .padding(.bottom, 4)
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

            Spacer(minLength: 8)

            VStack(spacing: 3) {
                Text("CUP PONG")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white)

                HStack(spacing: 5) {
                    Circle()
                        .fill(canMove ? Color.green.opacity(0.95) : Color.white.opacity(0.30))
                        .frame(width: 6, height: 6)
                    Text(canMove ? "YOUR THROW" : "OPPONENT’S THROW")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }

            Spacer(minLength: 8)

            playerBadge(
                ref: localPlayer,
                label: "YOU",
                remaining: remaining(player),
                local: true
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.035)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
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
            let tableRect = CGRect(
                x: max(18, size.width * 0.07),
                y: max(12, size.height * 0.035),
                width: max(1, size.width - max(36, size.width * 0.14)),
                height: max(1, size.height - max(24, size.height * 0.07))
            )

            ZStack {
                arenaGlow(size: size)

                PingoCupPongTableShape()
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

                PingoCupPongTableShape()
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

                pongBall(tableRect: tableRect)

                VStack(spacing: 2) {
                    Text("\(remaining(opponentIndex))")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                    Text("CUPS LEFT")
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(.white.opacity(0.20))
                .position(x: tableRect.midX, y: tableRect.midY - 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cup Pong table. You have \(remaining(player)) cups. Opponent has \(remaining(opponentIndex)) cups.")
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
                PingoCupPongTableShape()
                    .frame(width: tableRect.width, height: tableRect.height)
            }
    }

    private func cupRack(
        cups: [Bool],
        positions: [CGPoint],
        tableRect: CGRect,
        mirrored: Bool
    ) -> some View {
        ZStack {
            ForEach(Array(positions.enumerated()), id: \.offset) { index, normalized in
                let active = cups.indices.contains(index) ? cups[index] : false
                let perspective = mirrored ? (0.72 + normalized.y * 0.26) : (1.02 - normalized.y * 0.22)

                PingoPremiumPongCup(active: active, mirrored: mirrored)
                    .frame(width: 42 * perspective, height: 45 * perspective)
                    .position(
                        x: tableRect.minX + tableRect.width * normalized.x,
                        y: tableRect.minY + tableRect.height * normalized.y
                    )
            }
        }
    }

    private func pongBall(tableRect: CGRect) -> some View {
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
                .overlay {
                    Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.8)
                }
                .frame(width: 27, height: 27)
                .shadow(color: .white.opacity(0.18), radius: 6)
        }
        .position(
            x: tableRect.midX + CGFloat(aim / 30) * tableRect.width * 0.10,
            y: canMove ? tableRect.maxY - tableRect.height * 0.22 : tableRect.midY + tableRect.height * 0.04
        )
    }

    private var topCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.50, y: 0.13),
            CGPoint(x: 0.43, y: 0.18), CGPoint(x: 0.57, y: 0.18),
            CGPoint(x: 0.36, y: 0.24), CGPoint(x: 0.50, y: 0.24), CGPoint(x: 0.64, y: 0.24)
        ]
    }

    private var bottomCupPositions: [CGPoint] {
        [
            CGPoint(x: 0.50, y: 0.87),
            CGPoint(x: 0.43, y: 0.82), CGPoint(x: 0.57, y: 0.82),
            CGPoint(x: 0.36, y: 0.76), CGPoint(x: 0.50, y: 0.76), CGPoint(x: 0.64, y: 0.76)
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

    private var legacyShotControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                compactSlider(
                    title: "AIM",
                    value: Int(aim.rounded()),
                    suffix: "°",
                    slider: Slider(value: $aim, in: -30...30)
                )

                compactSlider(
                    title: "POWER",
                    value: Int((power * 100).rounded()),
                    suffix: "%",
                    slider: Slider(value: $power, in: 0.15...1)
                )
            }

            Button {
                onMove(.cupPong(.init(angleDegrees: aim, power: power)))
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("THROW")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.black.opacity(0.82))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(.white.opacity(0.94), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Throw ball")
        }
        .padding(10)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }

    private func compactSlider<S: View>(title: String, value: Int, suffix: String, slider: S) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 7, weight: .heavy, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                Text("\(value)\(suffix)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.76))
            }
            slider
                .tint(.white.opacity(0.84))
        }
        .frame(maxWidth: .infinity)
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

    private func cups(for index: Int) -> [Bool] {
        guard state.cups.indices.contains(index) else { return Array(repeating: false, count: 6) }
        return state.cups[index]
    }

    private func remaining(_ index: Int) -> Int {
        cups(for: index).filter { $0 }.count
    }
}

private struct PingoCupPongTableShape: Shape {
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

private struct PingoPremiumPongCup: View {
    let active: Bool
    let mirrored: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(active ? 0.26 : 0.10))
                .frame(width: 34, height: 10)
                .offset(y: mirrored ? 16 : 17)
                .blur(radius: 1.6)

            PingoPongCupBodyShape()
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

private struct PingoPongCupBodyShape: Shape {
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
