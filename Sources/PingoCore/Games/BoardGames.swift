import Foundation

public struct PingoGridPoint: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int
    public init(row: Int, column: Int) { self.row = row; self.column = column }
    public var index8: Int { row * 8 + column }
    public var index10: Int { row * 10 + column }
}

public enum PingoChessPromotion: String, Codable, CaseIterable, Sendable {
    case queen, rook, bishop, knight
}

public enum PingoSeaBattleShip: String, Codable, CaseIterable, Sendable {
    case carrier, battleship, cruiser, submarine, destroyer
    public var length: Int {
        switch self {
        case .carrier: 5
        case .battleship: 4
        case .cruiser, .submarine: 3
        case .destroyer: 2
        }
    }
    public var title: String { rawValue.capitalized }
}

public enum PingoSeaBattleOrientation: String, Codable, CaseIterable, Sendable { case horizontal, vertical }

public enum PingoGameMove: Hashable, Codable, Sendable {
    case ticTacToe(PingoGridPoint)
    case connectFour(column: Int)
    case checkers(from: PingoGridPoint, to: PingoGridPoint)
    case chess(from: PingoGridPoint, to: PingoGridPoint, promotion: PingoChessPromotion?)
    case seaBattlePlace(ship: PingoSeaBattleShip, start: PingoGridPoint, orientation: PingoSeaBattleOrientation)
    case seaBattleFire(PingoGridPoint)
}

public enum PingoGameRuleError: Error, Equatable, Sendable {
    case unsupportedGame
    case invalidState
    case invalidMove
    case occupied
    case outOfBounds
    case wrongPiece
    case captureRequired
    case shipAlreadyPlaced
    case shipsOverlap
    case fleetNotReady
    case alreadyTargeted
}

public struct PingoTicTacToeState: Hashable, Codable, Sendable {
    public var cells: [Int]
    public init(cells: [Int] = Array(repeating: 0, count: 9)) { self.cells = cells }
    public func owner(at point: PingoGridPoint) -> Int? {
        guard (0..<3).contains(point.row), (0..<3).contains(point.column) else { return nil }
        let value = cells[point.row * 3 + point.column]
        return value == 0 ? nil : value - 1
    }
}

public enum PingoTicTacToe {
    public static func apply(_ point: PingoGridPoint, player: Int, to state: PingoTicTacToeState) throws -> (PingoTicTacToeState, winner: Int?, draw: Bool) {
        guard (0..<3).contains(point.row), (0..<3).contains(point.column) else { throw PingoGameRuleError.outOfBounds }
        var next = state
        let index = point.row * 3 + point.column
        guard next.cells[index] == 0 else { throw PingoGameRuleError.occupied }
        next.cells[index] = player + 1
        let winner = winnerIndex(in: next)
        return (next, winner, winner == nil && !next.cells.contains(0))
    }

    public static func winnerIndex(in state: PingoTicTacToeState) -> Int? {
        let lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
        for line in lines {
            let a = state.cells[line[0]]
            if a != 0, state.cells[line[1]] == a, state.cells[line[2]] == a { return a - 1 }
        }
        return nil
    }
}

public struct PingoConnectFourState: Hashable, Codable, Sendable {
    public var cells: [Int]
    public init(cells: [Int] = Array(repeating: 0, count: 42)) { self.cells = cells }
    public func owner(row: Int, column: Int) -> Int? {
        guard (0..<6).contains(row), (0..<7).contains(column) else { return nil }
        let value = cells[row * 7 + column]
        return value == 0 ? nil : value - 1
    }
}

public enum PingoConnectFour {
    public static func apply(column: Int, player: Int, to state: PingoConnectFourState) throws -> (PingoConnectFourState, winner: Int?, draw: Bool, landedRow: Int) {
        guard (0..<7).contains(column) else { throw PingoGameRuleError.outOfBounds }
        var next = state
        var row: Int?
        for candidate in stride(from: 5, through: 0, by: -1) where next.cells[candidate * 7 + column] == 0 {
            row = candidate
            break
        }
        guard let row else { throw PingoGameRuleError.invalidMove }
        next.cells[row * 7 + column] = player + 1
        let winner = winnerIndex(in: next)
        return (next, winner, winner == nil && !next.cells.contains(0), row)
    }

    public static func winnerIndex(in state: PingoConnectFourState) -> Int? {
        let directions = [(0,1),(1,0),(1,1),(1,-1)]
        for row in 0..<6 { for col in 0..<7 {
            let value = state.cells[row * 7 + col]
            guard value != 0 else { continue }
            for (dr, dc) in directions {
                var ok = true
                for step in 1..<4 {
                    let r = row + dr * step, c = col + dc * step
                    if !(0..<6).contains(r) || !(0..<7).contains(c) || state.cells[r * 7 + c] != value { ok = false; break }
                }
                if ok { return value - 1 }
            }
        }}
        return nil
    }
}

public struct PingoCheckersState: Hashable, Codable, Sendable {
    public var cells: [Int]
    public var forcedFrom: Int?
    public init(cells: [Int] = PingoCheckers.initialBoard(), forcedFrom: Int? = nil) { self.cells = cells; self.forcedFrom = forcedFrom }
    public func piece(at point: PingoGridPoint) -> Int? {
        guard (0..<8).contains(point.row), (0..<8).contains(point.column) else { return nil }
        let value = cells[point.index8]
        return value == 0 ? nil : value
    }
}

public enum PingoCheckers {
    public static func initialBoard() -> [Int] {
        var cells = Array(repeating: 0, count: 64)
        for row in 0..<3 { for col in 0..<8 where (row + col) % 2 == 1 { cells[row * 8 + col] = 3 } }
        for row in 5..<8 { for col in 0..<8 where (row + col) % 2 == 1 { cells[row * 8 + col] = 1 } }
        return cells
    }

    public static func owner(of code: Int) -> Int? { code == 1 || code == 2 ? 0 : (code == 3 || code == 4 ? 1 : nil) }
    public static func isKing(_ code: Int) -> Bool { code == 2 || code == 4 }

    public static func legalMoves(in state: PingoCheckersState, player: Int) -> [(from: PingoGridPoint, to: PingoGridPoint)] {
        if let forced = state.forcedFrom {
            let point = PingoGridPoint(row: forced / 8, column: forced % 8)
            return captures(from: point, in: state, player: player)
        }
        var capturesAll: [(PingoGridPoint, PingoGridPoint)] = []
        var normal: [(PingoGridPoint, PingoGridPoint)] = []
        for index in 0..<64 where owner(of: state.cells[index]) == player {
            let from = PingoGridPoint(row: index / 8, column: index % 8)
            capturesAll += captures(from: from, in: state, player: player)
            normal += steps(from: from, in: state, player: player)
        }
        return capturesAll.isEmpty ? normal : capturesAll
    }

    public static func apply(from: PingoGridPoint, to: PingoGridPoint, player: Int, to state: PingoCheckersState) throws -> (PingoCheckersState, samePlayerContinues: Bool, winner: Int?) {
        guard valid(from), valid(to) else { throw PingoGameRuleError.outOfBounds }
        let legal = legalMoves(in: state, player: player)
        guard legal.contains(where: { $0.from == from && $0.to == to }) else {
            if legal.contains(where: { abs($0.from.row - $0.to.row) == 2 }) { throw PingoGameRuleError.captureRequired }
            throw PingoGameRuleError.invalidMove
        }
        var next = state
        let fromIndex = from.index8, toIndex = to.index8
        var piece = next.cells[fromIndex]
        guard owner(of: piece) == player else { throw PingoGameRuleError.wrongPiece }
        next.cells[fromIndex] = 0
        if abs(from.row - to.row) == 2 {
            let middle = PingoGridPoint(row: (from.row + to.row) / 2, column: (from.column + to.column) / 2)
            next.cells[middle.index8] = 0
        }
        if !isKing(piece), (player == 0 && to.row == 0 || player == 1 && to.row == 7) { piece = player == 0 ? 2 : 4 }
        next.cells[toIndex] = piece
        next.forcedFrom = nil

        if abs(from.row - to.row) == 2 {
            let more = captures(from: to, in: next, player: player)
            if !more.isEmpty {
                next.forcedFrom = toIndex
                return (next, true, nil)
            }
        }
        let opponent = 1 - player
        let opponentHasPiece = next.cells.contains(where: { owner(of: $0) == opponent })
        let opponentHasMove = !legalMoves(in: next, player: opponent).isEmpty
        return (next, false, (!opponentHasPiece || !opponentHasMove) ? player : nil)
    }

    private static func valid(_ p: PingoGridPoint) -> Bool { (0..<8).contains(p.row) && (0..<8).contains(p.column) }
    private static func directions(code: Int, player: Int) -> [(Int,Int)] {
        if isKing(code) { return [(-1,-1),(-1,1),(1,-1),(1,1)] }
        return player == 0 ? [(-1,-1),(-1,1)] : [(1,-1),(1,1)]
    }
    private static func steps(from: PingoGridPoint, in state: PingoCheckersState, player: Int) -> [(PingoGridPoint,PingoGridPoint)] {
        let code = state.cells[from.index8]
        return directions(code: code, player: player).compactMap { dr, dc in
            let to = PingoGridPoint(row: from.row + dr, column: from.column + dc)
            return valid(to) && state.cells[to.index8] == 0 ? (from, to) : nil
        }
    }
    private static func captures(from: PingoGridPoint, in state: PingoCheckersState, player: Int) -> [(PingoGridPoint,PingoGridPoint)] {
        let code = state.cells[from.index8]
        return directions(code: code, player: player).compactMap { dr, dc in
            let mid = PingoGridPoint(row: from.row + dr, column: from.column + dc)
            let to = PingoGridPoint(row: from.row + dr * 2, column: from.column + dc * 2)
            guard valid(mid), valid(to), state.cells[to.index8] == 0,
                  let owner = owner(of: state.cells[mid.index8]), owner != player else { return nil }
            return (from, to)
        }
    }
}

public struct PingoSeaBattlePlacement: Hashable, Codable, Sendable {
    public let ship: PingoSeaBattleShip
    public let start: PingoGridPoint
    public let orientation: PingoSeaBattleOrientation
    public init(ship: PingoSeaBattleShip, start: PingoGridPoint, orientation: PingoSeaBattleOrientation) { self.ship = ship; self.start = start; self.orientation = orientation }
    public var cells: [Int] {
        (0..<ship.length).map { offset in
            let row = start.row + (orientation == .vertical ? offset : 0)
            let col = start.column + (orientation == .horizontal ? offset : 0)
            return row * 10 + col
        }
    }
}

public struct PingoSeaBattleState: Hashable, Codable, Sendable {
    public var placements: [[PingoSeaBattlePlacement]]
    public var shots: [[Int]]
    public init(placements: [[PingoSeaBattlePlacement]] = [[],[]], shots: [[Int]] = [[],[]]) { self.placements = placements; self.shots = shots }
    public func fleetReady(player: Int) -> Bool { Set(placements[player].map(\.ship)) == Set(PingoSeaBattleShip.allCases) }
    public func occupiedCells(player: Int) -> Set<Int> { Set(placements[player].flatMap(\.cells)) }
}

public enum PingoSeaBattle {
    public static func place(ship: PingoSeaBattleShip, start: PingoGridPoint, orientation: PingoSeaBattleOrientation, player: Int, in state: PingoSeaBattleState) throws -> PingoSeaBattleState {
        guard (0..<10).contains(start.row), (0..<10).contains(start.column) else { throw PingoGameRuleError.outOfBounds }
        switch orientation {
        case .horizontal:
            guard start.column + ship.length <= 10 else { throw PingoGameRuleError.outOfBounds }
        case .vertical:
            guard start.row + ship.length <= 10 else { throw PingoGameRuleError.outOfBounds }
        }
        var next = state
        guard !next.placements[player].contains(where: { $0.ship == ship }) else { throw PingoGameRuleError.shipAlreadyPlaced }
        let placement = PingoSeaBattlePlacement(ship: ship, start: start, orientation: orientation)
        let existing = next.occupiedCells(player: player)
        guard Set(placement.cells).isDisjoint(with: existing) else { throw PingoGameRuleError.shipsOverlap }
        next.placements[player].append(placement)
        return next
    }

    public static func fire(at point: PingoGridPoint, player: Int, in state: PingoSeaBattleState) throws -> (PingoSeaBattleState, hit: Bool, sunk: PingoSeaBattleShip?, winner: Int?) {
        guard (0..<10).contains(point.row), (0..<10).contains(point.column) else { throw PingoGameRuleError.outOfBounds }
        guard state.fleetReady(player: 0), state.fleetReady(player: 1) else { throw PingoGameRuleError.fleetNotReady }
        var next = state
        let cell = point.index10
        guard !next.shots[player].contains(cell) else { throw PingoGameRuleError.alreadyTargeted }
        next.shots[player].append(cell)
        let opponent = 1 - player
        let occupied = next.occupiedCells(player: opponent)
        let hit = occupied.contains(cell)
        let fired = Set(next.shots[player])
        let sunk = next.placements[opponent].first(where: { Set($0.cells).isSubset(of: fired) && $0.cells.contains(cell) })?.ship
        let winner = occupied.isSubset(of: fired) ? player : nil
        return (next, hit, sunk, winner)
    }
}
