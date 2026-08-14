import Foundation

public struct PingoVector2: Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }

    public func distance(to other: PingoVector2) -> Double {
        let dx = x - other.x, dy = y - other.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

public struct PingoAimShot: Hashable, Codable, Sendable {
    public let angleDegrees: Double
    public let power: Double
    public init(angleDegrees: Double, power: Double) {
        self.angleDegrees = angleDegrees
        self.power = power
    }
}

public struct PingoDartPoint: Hashable, Codable, Sendable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct PingoDartsVisit: Hashable, Codable, Sendable {
    public let darts: [PingoDartPoint]
    public init(darts: [PingoDartPoint]) { self.darts = darts }
}

public enum PingoPhysicsMove: Hashable, Codable, Sendable {
    case eightBall(PingoAimShot)
    case cupPong(PingoAimShot)
    case basketball(PingoAimShot)
    case darts(PingoDartsVisit)
    case miniGolf(PingoAimShot)
}

public struct PingoPoolBall: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public var position: PingoVector2
    public var pocketed: Bool
    public init(id: Int, position: PingoVector2, pocketed: Bool = false) {
        self.id = id; self.position = position; self.pocketed = pocketed
    }
}

public struct PingoEightBallState: Hashable, Codable, Sendable {
    public var balls: [PingoPoolBall]
    /// 0 = unassigned, 1 = solids, 2 = stripes.
    public var groups: [Int]
    public var shotCount: Int
    public var lastPocketed: [Int]
    public var lastScratch: Bool

    public init(
        balls: [PingoPoolBall] = PingoEightBall.initialRack(),
        groups: [Int] = [0, 0],
        shotCount: Int = 0,
        lastPocketed: [Int] = [],
        lastScratch: Bool = false
    ) {
        self.balls = balls
        self.groups = groups
        self.shotCount = shotCount
        self.lastPocketed = lastPocketed
        self.lastScratch = lastScratch
    }
}

public enum PingoEightBall {
    private static let radius = 0.018
    private static let pockets = [
        PingoVector2(x: 0.035, y: 0.055), PingoVector2(x: 0.5, y: 0.045), PingoVector2(x: 0.965, y: 0.055),
        PingoVector2(x: 0.035, y: 0.945), PingoVector2(x: 0.5, y: 0.955), PingoVector2(x: 0.965, y: 0.945)
    ]

    public static func initialRack() -> [PingoPoolBall] {
        var balls = [PingoPoolBall(id: 0, position: .init(x: 0.25, y: 0.5))]
        var id = 1
        let spacing = radius * 2.12
        for row in 0..<5 {
            for slot in 0...row {
                let x = 0.68 + Double(row) * spacing * 0.88
                let y = 0.5 + (Double(slot) - Double(row) / 2.0) * spacing
                let ballID: Int
                if row == 2 && slot == 1 { ballID = 8 }
                else {
                    while id == 8 { id += 1 }
                    ballID = id; id += 1
                }
                balls.append(.init(id: ballID, position: .init(x: x, y: y)))
            }
        }
        return balls.sorted { $0.id < $1.id }
    }

    public struct Result: Sendable {
        public let state: PingoEightBallState
        public let samePlayerContinues: Bool
        public let winner: Int?
    }

    public static func apply(_ shot: PingoAimShot, player: Int, to state: PingoEightBallState) throws -> Result {
        guard (0...1).contains(player), shot.power >= 0.05, shot.power <= 1.0, shot.angleDegrees.isFinite else {
            throw PingoGameRuleError.invalidMove
        }
        guard state.balls.count == 16, let cueIndex = state.balls.firstIndex(where: { $0.id == 0 }) else {
            throw PingoGameRuleError.invalidState
        }

        var next = state
        next.lastPocketed = []
        next.lastScratch = false
        let beforePocketed = Set(next.balls.filter(\.pocketed).map(\.id))
        var velocity = Array(repeating: PingoVector2(x: 0, y: 0), count: next.balls.count)
        let radians = shot.angleDegrees * .pi / 180
        let speed = 0.038 * shot.power
        velocity[cueIndex] = .init(x: cos(radians) * speed, y: sin(radians) * speed)
        var firstHit: Int?

        for _ in 0..<360 {
            var moving = false
            for index in next.balls.indices where !next.balls[index].pocketed {
                if abs(velocity[index].x) + abs(velocity[index].y) > 0.00008 { moving = true }
                next.balls[index].position.x += velocity[index].x
                next.balls[index].position.y += velocity[index].y

                if pockets.contains(where: { next.balls[index].position.distance(to: $0) < 0.034 }) {
                    next.balls[index].pocketed = true
                    velocity[index] = .init(x: 0, y: 0)
                    continue
                }

                if next.balls[index].position.x < 0.045 || next.balls[index].position.x > 0.955 {
                    next.balls[index].position.x = min(0.955, max(0.045, next.balls[index].position.x))
                    velocity[index].x *= -0.9
                }
                if next.balls[index].position.y < 0.065 || next.balls[index].position.y > 0.935 {
                    next.balls[index].position.y = min(0.935, max(0.065, next.balls[index].position.y))
                    velocity[index].y *= -0.9
                }
            }

            for i in next.balls.indices where !next.balls[i].pocketed {
                for j in next.balls.indices where j > i && !next.balls[j].pocketed {
                    let dx = next.balls[j].position.x - next.balls[i].position.x
                    let dy = next.balls[j].position.y - next.balls[i].position.y
                    let distanceSquared = dx * dx + dy * dy
                    let diameter = radius * 2
                    guard distanceSquared > 0.0000001, distanceSquared < diameter * diameter else { continue }
                    let distance = distanceSquared.squareRoot()
                    let nx = dx / distance, ny = dy / distance
                    let relative = (velocity[i].x - velocity[j].x) * nx + (velocity[i].y - velocity[j].y) * ny
                    guard relative > 0 else { continue }
                    if firstHit == nil {
                        if next.balls[i].id == 0 { firstHit = next.balls[j].id }
                        else if next.balls[j].id == 0 { firstHit = next.balls[i].id }
                    }
                    let impulse = relative * 0.96
                    velocity[i].x -= impulse * nx
                    velocity[i].y -= impulse * ny
                    velocity[j].x += impulse * nx
                    velocity[j].y += impulse * ny
                    let overlap = diameter - distance
                    next.balls[i].position.x -= nx * overlap * 0.5
                    next.balls[i].position.y -= ny * overlap * 0.5
                    next.balls[j].position.x += nx * overlap * 0.5
                    next.balls[j].position.y += ny * overlap * 0.5
                }
            }

            for index in velocity.indices {
                velocity[index].x *= 0.982
                velocity[index].y *= 0.982
            }
            if !moving { break }
        }

        let newlyPocketed = next.balls.filter { $0.pocketed && !beforePocketed.contains($0.id) }.map(\.id).sorted()
        next.lastPocketed = newlyPocketed
        next.shotCount += 1
        let scratch = newlyPocketed.contains(0)
        next.lastScratch = scratch

        if scratch, let index = next.balls.firstIndex(where: { $0.id == 0 }) {
            next.balls[index].pocketed = false
            next.balls[index].position = .init(x: 0.25, y: 0.5)
        }

        if next.groups == [0, 0], let assignment = newlyPocketed.first(where: { (1...7).contains($0) || (9...15).contains($0) }) {
            let group = (1...7).contains(assignment) ? 1 : 2
            next.groups[player] = group
            next.groups[1 - player] = group == 1 ? 2 : 1
        }

        let ownGroup = next.groups[player]
        let firstHitLegal: Bool = {
            guard let firstHit else { return false }
            if ownGroup == 0 { return firstHit != 8 }
            let remainingOwn = next.balls.contains { !$0.pocketed && belongs($0.id, to: ownGroup) }
            if remainingOwn { return belongs(firstHit, to: ownGroup) }
            return firstHit == 8
        }()

        if newlyPocketed.contains(8) {
            let ownRemaining = next.balls.contains { !$0.pocketed && belongs($0.id, to: ownGroup) }
            let legalEight = ownGroup != 0 && !ownRemaining && !scratch && firstHit == 8
            return Result(state: next, samePlayerContinues: false, winner: legalEight ? player : 1 - player)
        }

        let pocketedOwn = newlyPocketed.contains { belongs($0, to: next.groups[player]) }
        return Result(state: next, samePlayerContinues: !scratch && firstHitLegal && pocketedOwn, winner: nil)
    }

    private static func belongs(_ ball: Int, to group: Int) -> Bool {
        group == 1 ? (1...7).contains(ball) : group == 2 ? (9...15).contains(ball) : false
    }
}

public struct PingoCupPongState: Hashable, Codable, Sendable {
    public var cups: [[Bool]]
    public var lastCup: Int?
    public var turns: Int
    public init(cups: [[Bool]] = [Array(repeating: true, count: 6), Array(repeating: true, count: 6)], lastCup: Int? = nil, turns: Int = 0) {
        self.cups = cups; self.lastCup = lastCup; self.turns = turns
    }
}

public enum PingoCupPong {
    private static let centers: [PingoVector2] = [
        .init(x: -0.36, y: 0.82), .init(x: 0, y: 0.82), .init(x: 0.36, y: 0.82),
        .init(x: -0.18, y: 0.58), .init(x: 0.18, y: 0.58), .init(x: 0, y: 0.34)
    ]

    public static func apply(_ shot: PingoAimShot, player: Int, to state: PingoCupPongState) throws -> (PingoCupPongState, winner: Int?) {
        guard (0...1).contains(player), (-30...30).contains(shot.angleDegrees), (0.15...1).contains(shot.power), state.cups.count == 2 else {
            throw PingoGameRuleError.invalidMove
        }
        var next = state
        let opponent = 1 - player
        let landing = PingoVector2(x: shot.angleDegrees / 30.0, y: shot.power)
        var nearest: (index: Int, distance: Double)?
        for index in centers.indices where next.cups[opponent][index] {
            let distance = landing.distance(to: centers[index])
            if nearest == nil || distance < nearest!.distance { nearest = (index, distance) }
        }
        next.lastCup = nil
        if let nearest, nearest.distance <= 0.17 {
            next.cups[opponent][nearest.index] = false
            next.lastCup = nearest.index
        }
        next.turns += 1
        return (next, next.cups[opponent].contains(true) ? nil : player)
    }
}

public struct PingoBasketballState: Hashable, Codable, Sendable {
    public var scores: [Int]
    public var attempts: [Int]
    public var lastPoints: Int
    public let attemptsPerPlayer: Int
    public init(scores: [Int] = [0, 0], attempts: [Int] = [0, 0], lastPoints: Int = 0, attemptsPerPlayer: Int = 5) {
        self.scores = scores; self.attempts = attempts; self.lastPoints = lastPoints; self.attemptsPerPlayer = attemptsPerPlayer
    }
}

public enum PingoBasketball {
    public static func apply(_ shot: PingoAimShot, player: Int, to state: PingoBasketballState) throws -> (PingoBasketballState, finished: Bool) {
        guard (0...1).contains(player), (30...75).contains(shot.angleDegrees), (0.2...1).contains(shot.power), state.attempts[player] < state.attemptsPerPlayer else {
            throw PingoGameRuleError.invalidMove
        }
        var next = state
        let angleError = abs(shot.angleDegrees - 52.0) / 23.0
        let powerError = abs(shot.power - 0.72) / 0.52
        let error = angleError * 0.55 + powerError * 0.45
        let points = error < 0.075 ? 3 : error < 0.19 ? 2 : 0
        next.scores[player] += points
        next.attempts[player] += 1
        next.lastPoints = points
        return (next, next.attempts.allSatisfy { $0 >= next.attemptsPerPlayer })
    }
}

public struct PingoDartsState: Hashable, Codable, Sendable {
    public var remaining: [Int]
    public var visits: [Int]
    public var lastVisitScore: Int
    public init(remaining: [Int] = [301, 301], visits: [Int] = [0, 0], lastVisitScore: Int = 0) {
        self.remaining = remaining; self.visits = visits; self.lastVisitScore = lastVisitScore
    }
}

public enum PingoDarts {
    private static let sectors = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    public static func score(_ dart: PingoDartPoint) -> Int {
        let r = (dart.x * dart.x + dart.y * dart.y).squareRoot()
        guard r <= 1 else { return 0 }
        if r <= 0.055 { return 50 }
        if r <= 0.11 { return 25 }
        var angle = atan2(dart.x, -dart.y)
        if angle < 0 { angle += 2 * .pi }
        let sector = sectors[Int((angle + .pi / 20) / (.pi / 10)) % 20]
        if r >= 0.86 { return sector * 2 }
        if r >= 0.50 && r <= 0.59 { return sector * 3 }
        return sector
    }

    public static func apply(_ visit: PingoDartsVisit, player: Int, to state: PingoDartsState) throws -> (PingoDartsState, winner: Int?) {
        guard (0...1).contains(player), visit.darts.count == 3 else { throw PingoGameRuleError.invalidMove }
        var next = state
        let start = next.remaining[player]
        var remaining = start
        var scored = 0
        for dart in visit.darts {
            guard dart.x.isFinite, dart.y.isFinite else { throw PingoGameRuleError.invalidMove }
            let value = score(dart)
            if remaining - value < 0 {
                remaining = start
                scored = 0
                break
            }
            remaining -= value
            scored += value
            if remaining == 0 { break }
        }
        next.remaining[player] = remaining
        next.visits[player] += 1
        next.lastVisitScore = scored
        return (next, remaining == 0 ? player : nil)
    }
}

public struct PingoMiniGolfState: Hashable, Codable, Sendable {
    public var holeIndex: Int
    public var positions: [PingoVector2]
    public var holed: [Bool]
    public var holeStrokes: [Int]
    public var totals: [Int]
    public var lastAutoFinished: Bool

    public init(
        holeIndex: Int = 0,
        positions: [PingoVector2]? = nil,
        holed: [Bool] = [false, false],
        holeStrokes: [Int] = [0, 0],
        totals: [Int] = [0, 0],
        lastAutoFinished: Bool = false
    ) {
        self.holeIndex = holeIndex
        let start = PingoMiniGolf.course[min(max(holeIndex, 0), 8)].start
        self.positions = positions ?? [start, start]
        self.holed = holed
        self.holeStrokes = holeStrokes
        self.totals = totals
        self.lastAutoFinished = lastAutoFinished
    }
}

public struct PingoMiniGolfCourse: Hashable, Sendable {
    public let start: PingoVector2
    public let hole: PingoVector2
    public let obstacles: [PingoMiniGolfRect]
}

public struct PingoMiniGolfRect: Hashable, Sendable {
    public let minX: Double, maxX: Double, minY: Double, maxY: Double
    public init(_ minX: Double, _ maxX: Double, _ minY: Double, _ maxY: Double) {
        self.minX = minX; self.maxX = maxX; self.minY = minY; self.maxY = maxY
    }
    public func contains(_ point: PingoVector2) -> Bool {
        point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY
    }
}

public enum PingoMiniGolf {
    public static let course: [PingoMiniGolfCourse] = [
        .init(start: .init(x: 0.15, y: 0.50), hole: .init(x: 0.85, y: 0.50), obstacles: []),
        .init(start: .init(x: 0.12, y: 0.82), hole: .init(x: 0.86, y: 0.18), obstacles: [.init(0.43, 0.57, 0.28, 0.72)]),
        .init(start: .init(x: 0.15, y: 0.20), hole: .init(x: 0.85, y: 0.80), obstacles: [.init(0.25, 0.72, 0.46, 0.54)]),
        .init(start: .init(x: 0.10, y: 0.50), hole: .init(x: 0.90, y: 0.50), obstacles: [.init(0.34, 0.42, 0.08, 0.67), .init(0.58, 0.66, 0.33, 0.92)]),
        .init(start: .init(x: 0.50, y: 0.88), hole: .init(x: 0.50, y: 0.12), obstacles: [.init(0.18, 0.43, 0.42, 0.50), .init(0.57, 0.82, 0.42, 0.50)]),
        .init(start: .init(x: 0.12, y: 0.15), hole: .init(x: 0.88, y: 0.85), obstacles: [.init(0.30, 0.37, 0.18, 0.73), .init(0.62, 0.69, 0.27, 0.82)]),
        .init(start: .init(x: 0.88, y: 0.18), hole: .init(x: 0.12, y: 0.82), obstacles: [.init(0.39, 0.61, 0.38, 0.62)]),
        .init(start: .init(x: 0.50, y: 0.90), hole: .init(x: 0.50, y: 0.10), obstacles: [.init(0.15, 0.35, 0.57, 0.64), .init(0.65, 0.85, 0.36, 0.43)]),
        .init(start: .init(x: 0.10, y: 0.85), hole: .init(x: 0.90, y: 0.15), obstacles: [.init(0.25, 0.32, 0.20, 0.75), .init(0.48, 0.55, 0.25, 0.80), .init(0.71, 0.78, 0.20, 0.75)])
    ]

    public struct Result: Sendable {
        public let state: PingoMiniGolfState
        public let nextPlayer: Int
        public let winner: Int?
        public let draw: Bool
    }

    public static func apply(_ shot: PingoAimShot, player: Int, to state: PingoMiniGolfState) throws -> Result {
        guard (0...1).contains(player), state.holeIndex < course.count, !state.holed[player], shot.power >= 0.05, shot.power <= 1, shot.angleDegrees.isFinite else {
            throw PingoGameRuleError.invalidMove
        }
        var next = state
        let layout = course[state.holeIndex]
        let radians = shot.angleDegrees * .pi / 180
        var position = next.positions[player]
        var velocity = PingoVector2(x: cos(radians) * shot.power * 0.035, y: sin(radians) * shot.power * 0.035)
        next.holeStrokes[player] += 1
        next.lastAutoFinished = false

        for _ in 0..<340 {
            let previous = position
            position.x += velocity.x
            position.y += velocity.y
            if position.x < 0.04 || position.x > 0.96 {
                position.x = min(0.96, max(0.04, position.x)); velocity.x *= -0.82
            }
            if position.y < 0.04 || position.y > 0.96 {
                position.y = min(0.96, max(0.04, position.y)); velocity.y *= -0.82
            }
            if layout.obstacles.contains(where: { $0.contains(position) }) {
                position = previous
                let testX = PingoVector2(x: previous.x + velocity.x, y: previous.y)
                if layout.obstacles.contains(where: { $0.contains(testX) }) { velocity.x *= -0.8 }
                else { velocity.y *= -0.8 }
            }
            let speed = (velocity.x * velocity.x + velocity.y * velocity.y).squareRoot()
            if position.distance(to: layout.hole) < 0.038 && speed < 0.011 {
                position = layout.hole
                next.holed[player] = true
                break
            }
            velocity.x *= 0.978
            velocity.y *= 0.978
            if speed < 0.00008 { break }
        }
        next.positions[player] = position
        if next.holeStrokes[player] >= 8 && !next.holed[player] {
            next.holed[player] = true
            next.holeStrokes[player] = 9
            next.positions[player] = layout.hole
            next.lastAutoFinished = true
        }

        if next.holed == [true, true] {
            next.totals[0] += next.holeStrokes[0]
            next.totals[1] += next.holeStrokes[1]
            if next.holeIndex == course.count - 1 {
                if next.totals[0] == next.totals[1] { return Result(state: next, nextPlayer: 1 - player, winner: nil, draw: true) }
                return Result(state: next, nextPlayer: 1 - player, winner: next.totals[0] < next.totals[1] ? 0 : 1, draw: false)
            }
            next.holeIndex += 1
            let start = course[next.holeIndex].start
            next.positions = [start, start]
            next.holed = [false, false]
            next.holeStrokes = [0, 0]
            return Result(state: next, nextPlayer: 0, winner: nil, draw: false)
        }

        let opponent = 1 - player
        let nextPlayer = next.holed[opponent] ? player : opponent
        return Result(state: next, nextPlayer: nextPlayer, winner: nil, draw: false)
    }
}

public enum PingoPhysicsGameEngine {
    public static let supportedGames: Set<PingoGameID> = [.eightBall, .cupPong, .basketball, .darts, .miniGolf]

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private static let decoder = JSONDecoder()

    public static func initialStateData(for gameID: PingoGameID) -> Data {
        switch gameID {
        case .eightBall: return (try? encoder.encode(PingoEightBallState())) ?? Data()
        case .cupPong: return (try? encoder.encode(PingoCupPongState())) ?? Data()
        case .basketball: return (try? encoder.encode(PingoBasketballState())) ?? Data()
        case .darts: return (try? encoder.encode(PingoDartsState())) ?? Data()
        case .miniGolf: return (try? encoder.encode(PingoMiniGolfState())) ?? Data()
        default: return Data()
        }
    }

    public static func submit(
        move: PingoPhysicsMove,
        to match: PingoMatchEnvelope,
        actorID: UUID,
        expectedRevision: Int,
        now: Date = Date()
    ) throws -> PingoMatchEnvelope {
        guard match.status == .active else { throw PingoMatchTransitionError.invalidStatus }
        guard match.revision == expectedRevision else { throw PingoMatchTransitionError.staleRevision }
        guard match.currentPlayerID == actorID else { throw PingoMatchTransitionError.notActorsTurn }
        guard let actorIndex = match.players.firstIndex(where: { $0.id == actorID }), match.players.count == 2 else {
            throw PingoMatchTransitionError.actorNotInMatch
        }
        let opponentIndex = 1 - actorIndex
        let source = match.gameState.isEmpty ? initialStateData(for: match.gameID) : match.gameState

        switch (match.gameID, move) {
        case (.eightBall, .eightBall(let shot)):
            let result = try PingoEightBall.apply(shot, player: actorIndex, to: try decode(PingoEightBallState.self, source))
            let data = try encoder.encode(result.state)
            if let winner = result.winner { return try complete(match, actorID, expectedRevision, winner, data, now) }
            let next = result.samePlayerContinues ? actorIndex : opponentIndex
            return try advance(match, actorID, expectedRevision, next, data, now)

        case (.cupPong, .cupPong(let shot)):
            let result = try PingoCupPong.apply(shot, player: actorIndex, to: try decode(PingoCupPongState.self, source))
            let data = try encoder.encode(result.0)
            if let winner = result.winner { return try complete(match, actorID, expectedRevision, winner, data, now) }
            return try advance(match, actorID, expectedRevision, opponentIndex, data, now)

        case (.basketball, .basketball(let shot)):
            let result = try PingoBasketball.apply(shot, player: actorIndex, to: try decode(PingoBasketballState.self, source))
            let data = try encoder.encode(result.0)
            if result.finished {
                let winner = result.0.scores[0] == result.0.scores[1] ? nil : (result.0.scores[0] > result.0.scores[1] ? 0 : 1)
                return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision, winnerPlayerID: winner.map { match.players[$0].id }, gameState: data, now: now)
            }
            return try advance(match, actorID, expectedRevision, opponentIndex, data, now)

        case (.darts, .darts(let visit)):
            let result = try PingoDarts.apply(visit, player: actorIndex, to: try decode(PingoDartsState.self, source))
            let data = try encoder.encode(result.0)
            if let winner = result.winner { return try complete(match, actorID, expectedRevision, winner, data, now) }
            return try advance(match, actorID, expectedRevision, opponentIndex, data, now)

        case (.miniGolf, .miniGolf(let shot)):
            let result = try PingoMiniGolf.apply(shot, player: actorIndex, to: try decode(PingoMiniGolfState.self, source))
            let data = try encoder.encode(result.state)
            if let winner = result.winner { return try complete(match, actorID, expectedRevision, winner, data, now) }
            if result.draw { return try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: expectedRevision, winnerPlayerID: nil, gameState: data, now: now) }
            return try advance(match, actorID, expectedRevision, result.nextPlayer, data, now)

        default:
            throw PingoGameRuleError.unsupportedGame
        }
    }

    public static func eightBallState(from data: Data) throws -> PingoEightBallState { try decodeOrInitial(PingoEightBallState.self, data, .eightBall) }
    public static func cupPongState(from data: Data) throws -> PingoCupPongState { try decodeOrInitial(PingoCupPongState.self, data, .cupPong) }
    public static func basketballState(from data: Data) throws -> PingoBasketballState { try decodeOrInitial(PingoBasketballState.self, data, .basketball) }
    public static func dartsState(from data: Data) throws -> PingoDartsState { try decodeOrInitial(PingoDartsState.self, data, .darts) }
    public static func miniGolfState(from data: Data) throws -> PingoMiniGolfState { try decodeOrInitial(PingoMiniGolfState.self, data, .miniGolf) }

    private static func advance(_ match: PingoMatchEnvelope, _ actorID: UUID, _ revision: Int, _ nextIndex: Int, _ data: Data, _ now: Date) throws -> PingoMatchEnvelope {
        try PingoMatchReducer.submitTurn(match, actorID: actorID, expectedRevision: revision, nextPlayerID: match.players[nextIndex].id, gameState: data, now: now)
    }

    private static func complete(_ match: PingoMatchEnvelope, _ actorID: UUID, _ revision: Int, _ winner: Int, _ data: Data, _ now: Date) throws -> PingoMatchEnvelope {
        try PingoMatchReducer.completeTurn(match, actorID: actorID, expectedRevision: revision, winnerPlayerID: match.players[winner].id, gameState: data, now: now)
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ data: Data) throws -> T {
        do { return try decoder.decode(type, from: data) }
        catch { throw PingoGameRuleError.invalidState }
    }

    private static func decodeOrInitial<T: Decodable>(_ type: T.Type, _ data: Data, _ gameID: PingoGameID) throws -> T {
        try decode(type, data.isEmpty ? initialStateData(for: gameID) : data)
    }
}

public enum PingoPlayableGameRegistry {
    public static let supportedGames = PingoBoardGameEngine.supportedGames.union(PingoPhysicsGameEngine.supportedGames)
}
