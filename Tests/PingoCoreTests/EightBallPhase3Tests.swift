import XCTest
@testable import PingoCore

final class EightBallPhase3Tests: XCTestCase {
    func testPlaybackIsDeterministic() throws {
        let state = PingoEightBallState()
        let shot = PingoAimShot(angleDegrees: 0, power: 0.9)
        let first = try PingoEightBallPlayback.frames(for: shot, from: state)
        let second = try PingoEightBallPlayback.frames(for: shot, from: state)

        XCTAssertEqual(first, second)
        XCTAssertGreaterThan(first.count, 8)
        XCTAssertEqual(first.first?.balls, state.balls)
    }

    func testPlaybackKeepsVisibleBallsInsidePlayableBounds() throws {
        let frames = try PingoEightBallPlayback.frames(
            for: .init(angleDegrees: 17, power: 1),
            from: PingoEightBallState()
        )

        for frame in frames {
            for ball in frame.balls where !ball.pocketed {
                XCTAssertGreaterThanOrEqual(ball.position.x, 0.045 - 0.000001)
                XCTAssertLessThanOrEqual(ball.position.x, 0.955 + 0.000001)
                XCTAssertGreaterThanOrEqual(ball.position.y, 0.065 - 0.000001)
                XCTAssertLessThanOrEqual(ball.position.y, 0.935 + 0.000001)
            }
        }
    }

    func testPlaybackSeparatesCollidingBalls() throws {
        let frames = try PingoEightBallPlayback.frames(
            for: .init(angleDegrees: 0, power: 0.95),
            from: PingoEightBallState()
        )
        let last = try XCTUnwrap(frames.last)
        let visible = last.balls.filter { !$0.pocketed }

        for i in visible.indices {
            for j in visible.indices where j > i {
                XCTAssertGreaterThanOrEqual(
                    visible[i].position.distance(to: visible[j].position),
                    0.0350,
                    "Balls \(visible[i].id) and \(visible[j].id) finished overlapped"
                )
            }
        }
    }

    func testPlaybackSettlesOnAuthoritativeTurnResult() throws {
        let state = PingoEightBallState()
        let shot = PingoAimShot(angleDegrees: 8, power: 0.77)
        let playbackFinal = try PingoEightBallPlayback.settledBalls(for: shot, player: 0, from: state)
        let authoritative = try PingoEightBall.apply(shot, player: 0, to: state)

        XCTAssertEqual(playbackFinal, authoritative.state.balls)
    }

    func testInvalidPlaybackShotIsRejected() {
        XCTAssertThrowsError(
            try PingoEightBallPlayback.frames(
                for: .init(angleDegrees: 0, power: 0.01),
                from: PingoEightBallState()
            )
        )
    }
}
