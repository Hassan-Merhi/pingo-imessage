import PingoCore
import SwiftUI

struct PingoEightBallPhase3View: View {
    let state: PingoEightBallState
    let player: Int
    let canMove: Bool
    let match: PingoMatchEnvelope
    let localProfile: PingoPublicProfile
    let onMove: (PingoPhysicsMove) -> Void

    @State private var playbackBalls: [PingoPoolBall]?
    @State private var isPlayingShot = false
    @State private var pocketFlash = false

    var body: some View {
        ZStack {
            PingoEightBallPhase2View(
                state: state,
                player: player,
                canMove: canMove && !isPlayingShot,
                match: match,
                localProfile: localProfile,
                onMove: intercept
            )
            .opacity(isPlayingShot ? 0.06 : 1)
            .allowsHitTesting(!isPlayingShot)

            if let playbackBalls {
                Phase3ShotPlaybackSurface(
                    balls: playbackBalls,
                    pocketFlash: pocketFlash
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isPlayingShot)
        .onChange(of: state.shotCount) { _ in
            if !isPlayingShot {
                playbackBalls = nil
            }
        }
    }

    private func intercept(_ move: PingoPhysicsMove) {
        guard case .eightBall(let shot) = move, !isPlayingShot else {
            if !isPlayingShot { onMove(move) }
            return
        }

        let frames: [PingoEightBallPlaybackFrame]
        let settled: [PingoPoolBall]
        do {
            frames = try PingoEightBallPlayback.frames(for: shot, from: state)
            settled = try PingoEightBallPlayback.settledBalls(for: shot, player: player, from: state)
        } catch {
            onMove(move)
            return
        }

        isPlayingShot = true
        playbackBalls = state.balls
        pocketFlash = false

        Task { @MainActor in
            var previousPocketed = Set(state.balls.filter(\.pocketed).map(\.id))

            for frame in frames.dropFirst() {
                guard isPlayingShot else { return }
                let nowPocketed = Set(frame.balls.filter(\.pocketed).map(\.id))
                if nowPocketed.subtracting(previousPocketed).isEmpty == false {
                    pocketFlash = true
                }

                withAnimation(.linear(duration: 0.019)) {
                    playbackBalls = frame.balls
                }
                try? await Task.sleep(nanoseconds: 19_000_000)

                if pocketFlash {
                    pocketFlash = false
                }
                previousPocketed = nowPocketed
            }

            // Land on the exact authoritative deterministic result before sending.
            // This prevents any visual/server drift while keeping the wire state tiny.
            withAnimation(.easeOut(duration: 0.14)) {
                playbackBalls = settled
            }
            try? await Task.sleep(nanoseconds: 145_000_000)

            onMove(move)
            try? await Task.sleep(nanoseconds: 80_000_000)
            isPlayingShot = false
            playbackBalls = nil
        }
    }
}

private struct Phase3ShotPlaybackSurface: View {
    let balls: [PingoPoolBall]
    let pocketFlash: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 7, height: 7)
                Text("SHOT IN MOTION")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 7, height: 7)
            }
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(.black.opacity(0.78), in: Capsule())

            Phase3PlaybackTable(balls: balls, pocketFlash: pocketFlash)
                .aspectRatio(0.51, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.22))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pool balls moving")
    }
}

private struct Phase3PlaybackTable: View {
    let balls: [PingoPoolBall]
    let pocketFlash: Bool

    private let pockets = [
        CGPoint(x: 0.055, y: 0.035), CGPoint(x: 0.945, y: 0.035),
        CGPoint(x: 0.04, y: 0.50), CGPoint(x: 0.96, y: 0.50),
        CGPoint(x: 0.055, y: 0.965), CGPoint(x: 0.945, y: 0.965)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let rail = max(18.0, min(28.0, size.width * 0.085))
            let felt = CGRect(
                x: rail,
                y: rail,
                width: max(1, size.width - rail * 2),
                height: max(1, size.height - rail * 2)
            )
            let ballSize = max(14.0, min(21.0, felt.width * 0.075))

            ZStack {
                RoundedRectangle(cornerRadius: 29)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.19, green: 0.075, blue: 0.04),
                                Color(red: 0.45, green: 0.21, blue: 0.10),
                                Color(red: 0.22, green: 0.085, blue: 0.045)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.38), radius: 12, y: 7)

                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.70, green: 0.42, blue: 0.20), Color(red: 0.15, green: 0.055, blue: 0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 7
                    )
                    .padding(8)

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.035, green: 0.51, blue: 0.43), Color(red: 0.012, green: 0.37, blue: 0.33)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(rail)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.26), lineWidth: 3)
                            .padding(rail - 1)
                    }

                ForEach(Array(pockets.enumerated()), id: \.offset) { _, pocket in
                    ZStack {
                        Circle()
                            .fill(.black)
                            .frame(width: ballSize * 1.38, height: ballSize * 1.38)
                        if pocketFlash {
                            Circle()
                                .stroke(.white.opacity(0.55), lineWidth: 2)
                                .frame(width: ballSize * 1.72, height: ballSize * 1.72)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .position(
                        x: felt.minX + felt.width * pocket.x,
                        y: felt.minY + felt.height * pocket.y
                    )
                }

                ForEach(balls.filter { !$0.pocketed }) { ball in
                    Phase3PoolBall(id: ball.id)
                        .frame(width: ballSize, height: ballSize)
                        .shadow(color: .black.opacity(0.32), radius: 2, x: 1, y: 2)
                        .position(tablePoint(ball.position, felt: felt))
                }
            }
        }
    }

    private func tablePoint(_ point: PingoVector2, felt: CGRect) -> CGPoint {
        CGPoint(
            x: felt.minX + felt.width * point.y,
            y: felt.minY + felt.height * (1 - point.x)
        )
    }
}

private struct Phase3PoolBall: View {
    let id: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(baseFill)

            if id >= 9 {
                Capsule()
                    .fill(.white)
                    .frame(height: 7)
                    .padding(.horizontal, 1)
            }

            if id != 0 {
                Circle()
                    .fill(id == 8 ? .black : .white)
                    .frame(width: 9, height: 9)
                Text("\(id)")
                    .font(.system(size: 5.4, weight: .heavy, design: .rounded))
                    .foregroundStyle(id == 8 ? .white : .black)
            }

            Circle()
                .fill(.white.opacity(0.38))
                .frame(width: 4, height: 4)
                .offset(x: -4, y: -4)
        }
        .overlay { Circle().stroke(.black.opacity(0.20), lineWidth: 0.6) }
    }

    private var baseFill: Color {
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
