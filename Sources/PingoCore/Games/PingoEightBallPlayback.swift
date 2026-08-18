import Foundation

public struct PingoEightBallPlaybackFrame: Hashable, Sendable {
    public let balls: [PingoPoolBall]
    public let progress: Double

    public init(balls: [PingoPoolBall], progress: Double) {
        self.balls = balls
        self.progress = progress
    }
}

/// Local deterministic playback for an 8 Ball shot.
///
/// Match state remains compact and authoritative through `PingoEightBall.apply`; this
/// simulator exists to render the shot before the turn payload is sent. It uses smaller
/// substeps, collision separation, rail restitution and rolling resistance so the local
/// animation does not teleport directly from one turn state to the next.
public enum PingoEightBallPlayback {
    private static let radius = 0.018
    private static let diameter = radius * 2
    private static let pocketRadius = 0.034
    private static let pockets = [
        PingoVector2(x: 0.035, y: 0.055), PingoVector2(x: 0.5, y: 0.045), PingoVector2(x: 0.965, y: 0.055),
        PingoVector2(x: 0.035, y: 0.945), PingoVector2(x: 0.5, y: 0.955), PingoVector2(x: 0.965, y: 0.945)
    ]

    public static func frames(
        for shot: PingoAimShot,
        from state: PingoEightBallState,
        maximumFrames: Int = 54
    ) throws -> [PingoEightBallPlaybackFrame] {
        guard shot.power >= 0.05, shot.power <= 1, shot.angleDegrees.isFinite,
              state.balls.count == 16,
              let cueIndex = state.balls.firstIndex(where: { $0.id == 0 && !$0.pocketed }) else {
            throw PingoGameRuleError.invalidMove
        }

        var balls = state.balls
        var velocity = Array(repeating: PingoVector2(x: 0, y: 0), count: balls.count)
        let radians = shot.angleDegrees * .pi / 180
        let initialSpeed = 0.030 + 0.020 * shot.power
        velocity[cueIndex] = .init(x: cos(radians) * initialSpeed, y: sin(radians) * initialSpeed)

        var output = [PingoEightBallPlaybackFrame(balls: balls, progress: 0)]
        let substepsPerFrame = 4
        let maxFrames = max(12, min(72, maximumFrames))

        for frameIndex in 1...maxFrames {
            var anyMoving = false

            for _ in 0..<substepsPerFrame {
                for index in balls.indices where !balls[index].pocketed {
                    let speed = hypot(velocity[index].x, velocity[index].y)
                    if speed > 0.000035 { anyMoving = true }

                    balls[index].position.x += velocity[index].x / Double(substepsPerFrame)
                    balls[index].position.y += velocity[index].y / Double(substepsPerFrame)

                    if pockets.contains(where: { balls[index].position.distance(to: $0) <= pocketRadius }) {
                        balls[index].pocketed = true
                        velocity[index] = .init(x: 0, y: 0)
                        continue
                    }

                    if balls[index].position.x < 0.045 || balls[index].position.x > 0.955 {
                        balls[index].position.x = min(0.955, max(0.045, balls[index].position.x))
                        velocity[index].x *= -0.86
                    }
                    if balls[index].position.y < 0.065 || balls[index].position.y > 0.935 {
                        balls[index].position.y = min(0.935, max(0.065, balls[index].position.y))
                        velocity[index].y *= -0.86
                    }
                }

                resolveCollisions(balls: &balls, velocity: &velocity)

                for index in velocity.indices where !balls[index].pocketed {
                    velocity[index].x *= 0.986
                    velocity[index].y *= 0.986
                    if hypot(velocity[index].x, velocity[index].y) < 0.000035 {
                        velocity[index] = .init(x: 0, y: 0)
                    }
                }
            }

            output.append(.init(balls: balls, progress: Double(frameIndex) / Double(maxFrames)))
            if !anyMoving && frameIndex >= 8 { break }
        }

        if output.last?.progress != 1 {
            output.append(.init(balls: balls, progress: 1))
        }
        return output
    }

    public static func settledBalls(
        for shot: PingoAimShot,
        player: Int,
        from state: PingoEightBallState
    ) throws -> [PingoPoolBall] {
        try PingoEightBall.apply(shot, player: player, to: state).state.balls
    }

    private static func resolveCollisions(balls: inout [PingoPoolBall], velocity: inout [PingoVector2]) {
        for i in balls.indices where !balls[i].pocketed {
            for j in balls.indices where j > i && !balls[j].pocketed {
                let dx = balls[j].position.x - balls[i].position.x
                let dy = balls[j].position.y - balls[i].position.y
                let distanceSquared = dx * dx + dy * dy
                guard distanceSquared > 0.00000001, distanceSquared < diameter * diameter else { continue }

                let distance = distanceSquared.squareRoot()
                let nx = dx / distance
                let ny = dy / distance
                let overlap = diameter - distance

                // Separate first so dense racks cannot remain interpenetrating and jitter.
                balls[i].position.x -= nx * overlap * 0.505
                balls[i].position.y -= ny * overlap * 0.505
                balls[j].position.x += nx * overlap * 0.505
                balls[j].position.y += ny * overlap * 0.505

                let relative = (velocity[i].x - velocity[j].x) * nx + (velocity[i].y - velocity[j].y) * ny
                guard relative > 0 else { continue }

                // Equal-mass billiard collision with a little energy loss.
                let impulse = relative * 0.94
                velocity[i].x -= impulse * nx
                velocity[i].y -= impulse * ny
                velocity[j].x += impulse * nx
                velocity[j].y += impulse * ny
            }
        }
    }
}
