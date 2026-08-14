import Foundation

public struct PingoChessState: Hashable, Codable, Sendable {
    public var cells: [Int]
    public var castlingRights: Int
    public var enPassantTarget: Int?
    public var halfmoveClock: Int
    public var fullmoveNumber: Int

    public init(
        cells: [Int] = PingoChess.initialBoard(), castlingRights: Int = 15,
        enPassantTarget: Int? = nil, halfmoveClock: Int = 0, fullmoveNumber: Int = 1
    ) {
        self.cells = cells
        self.castlingRights = castlingRights
        self.enPassantTarget = enPassantTarget
        self.halfmoveClock = halfmoveClock
        self.fullmoveNumber = fullmoveNumber
    }
}

public struct PingoChessMoveResult: Hashable, Codable, Sendable {
    public let state: PingoChessState
    public let check: Bool
    public let checkmate: Bool
    public let draw: Bool
    public let winner: Int?
}

public enum PingoChess {
    public static func initialBoard() -> [Int] {
        var cells = Array(repeating: 0, count: 64)
        cells[0..<8] = [10, 8, 9, 11, 12, 9, 8, 10]
        for i in 8..<16 { cells[i] = 7 }
        for i in 48..<56 { cells[i] = 1 }
        cells[56..<64] = [4, 2, 3, 5, 6, 3, 2, 4]
        return cells
    }

    public static func owner(of code: Int) -> Int? {
        guard code != 0 else { return nil }
        return code <= 6 ? 0 : 1
    }

    public static func kind(of code: Int) -> Int { code == 0 ? 0 : ((code - 1) % 6) + 1 }
    public static func code(kind: Int, player: Int) -> Int { kind + (player == 0 ? 0 : 6) }

    public static func legalDestinations(from: PingoGridPoint, player: Int, in state: PingoChessState) -> [PingoGridPoint] {
        guard valid(from), owner(of: state.cells[from.index8]) == player else { return [] }
        return pseudoDestinations(from: from, player: player, state: state).filter { to in
            guard let next = try? applyUnchecked(from: from, to: to, player: player, promotion: nil, state: state) else { return false }
            return !isKingInCheck(player: player, state: next)
        }
    }

    public static func allLegalMoves(player: Int, in state: PingoChessState) -> [(from: PingoGridPoint, to: PingoGridPoint)] {
        var moves: [(PingoGridPoint, PingoGridPoint)] = []
        for index in 0..<64 where owner(of: state.cells[index]) == player {
            let from = point(index)
            moves += legalDestinations(from: from, player: player, in: state).map { (from, $0) }
        }
        return moves
    }

    public static func apply(
        from: PingoGridPoint, to: PingoGridPoint, player: Int,
        promotion: PingoChessPromotion?, to state: PingoChessState
    ) throws -> PingoChessMoveResult {
        guard valid(from), valid(to) else { throw PingoGameRuleError.outOfBounds }
        guard owner(of: state.cells[from.index8]) == player else { throw PingoGameRuleError.wrongPiece }
        guard legalDestinations(from: from, player: player, in: state).contains(to) else { throw PingoGameRuleError.invalidMove }
        let next = try applyUnchecked(from: from, to: to, player: player, promotion: promotion, state: state)
        let opponent = 1 - player
        let check = isKingInCheck(player: opponent, state: next)
        let opponentMoves = allLegalMoves(player: opponent, in: next)
        let checkmate = check && opponentMoves.isEmpty
        let stalemate = !check && opponentMoves.isEmpty
        let fiftyMove = next.halfmoveClock >= 100
        let materialDraw = insufficientMaterial(next)
        return PingoChessMoveResult(
            state: next,
            check: check,
            checkmate: checkmate,
            draw: stalemate || fiftyMove || materialDraw,
            winner: checkmate ? player : nil
        )
    }

    public static func isKingInCheck(player: Int, state: PingoChessState) -> Bool {
        guard let king = state.cells.firstIndex(of: code(kind: 6, player: player)) else { return true }
        return isSquareAttacked(king, by: 1 - player, state: state)
    }

    public static func isSquareAttacked(_ index: Int, by attacker: Int, state: PingoChessState) -> Bool {
        let target = point(index)
        let pawnDirection = attacker == 0 ? -1 : 1
        for dc in [-1, 1] {
            let source = PingoGridPoint(row: target.row - pawnDirection, column: target.column - dc)
            if valid(source), state.cells[source.index8] == code(kind: 1, player: attacker) { return true }
        }
        for (dr, dc) in [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)] {
            let source = PingoGridPoint(row: target.row + dr, column: target.column + dc)
            if valid(source), state.cells[source.index8] == code(kind: 2, player: attacker) { return true }
        }
        if rayAttacked(target: target, attacker: attacker, state: state, directions: [(-1,-1),(-1,1),(1,-1),(1,1)], kinds: [3,5]) { return true }
        if rayAttacked(target: target, attacker: attacker, state: state, directions: [(-1,0),(1,0),(0,-1),(0,1)], kinds: [4,5]) { return true }
        for dr in -1...1 { for dc in -1...1 where !(dr == 0 && dc == 0) {
            let source = PingoGridPoint(row: target.row + dr, column: target.column + dc)
            if valid(source), state.cells[source.index8] == code(kind: 6, player: attacker) { return true }
        }}
        return false
    }

    private static func pseudoDestinations(from: PingoGridPoint, player: Int, state: PingoChessState) -> [PingoGridPoint] {
        let piece = state.cells[from.index8]
        switch kind(of: piece) {
        case 1: return pawnMoves(from: from, player: player, state: state)
        case 2: return jumpMoves(from: from, player: player, state: state, deltas: [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)])
        case 3: return slidingMoves(from: from, player: player, state: state, directions: [(-1,-1),(-1,1),(1,-1),(1,1)])
        case 4: return slidingMoves(from: from, player: player, state: state, directions: [(-1,0),(1,0),(0,-1),(0,1)])
        case 5: return slidingMoves(from: from, player: player, state: state, directions: [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)])
        case 6: return kingMoves(from: from, player: player, state: state)
        default: return []
        }
    }

    private static func pawnMoves(from: PingoGridPoint, player: Int, state: PingoChessState) -> [PingoGridPoint] {
        var moves: [PingoGridPoint] = []
        let dr = player == 0 ? -1 : 1
        let startRow = player == 0 ? 6 : 1
        let one = PingoGridPoint(row: from.row + dr, column: from.column)
        if valid(one), state.cells[one.index8] == 0 {
            moves.append(one)
            let two = PingoGridPoint(row: from.row + 2 * dr, column: from.column)
            if from.row == startRow, valid(two), state.cells[two.index8] == 0 { moves.append(two) }
        }
        for dc in [-1, 1] {
            let to = PingoGridPoint(row: from.row + dr, column: from.column + dc)
            guard valid(to) else { continue }
            if let targetOwner = owner(of: state.cells[to.index8]), targetOwner != player { moves.append(to) }
            else if state.enPassantTarget == to.index8 { moves.append(to) }
        }
        return moves
    }

    private static func jumpMoves(from: PingoGridPoint, player: Int, state: PingoChessState, deltas: [(Int,Int)]) -> [PingoGridPoint] {
        deltas.compactMap { dr, dc in
            let to = PingoGridPoint(row: from.row + dr, column: from.column + dc)
            guard valid(to), owner(of: state.cells[to.index8]) != player else { return nil }
            return to
        }
    }

    private static func slidingMoves(from: PingoGridPoint, player: Int, state: PingoChessState, directions: [(Int,Int)]) -> [PingoGridPoint] {
        var moves: [PingoGridPoint] = []
        for (dr, dc) in directions {
            var row = from.row + dr, col = from.column + dc
            while (0..<8).contains(row), (0..<8).contains(col) {
                let to = PingoGridPoint(row: row, column: col)
                if state.cells[to.index8] == 0 { moves.append(to) }
                else {
                    if owner(of: state.cells[to.index8]) != player { moves.append(to) }
                    break
                }
                row += dr; col += dc
            }
        }
        return moves
    }

    private static func kingMoves(from: PingoGridPoint, player: Int, state: PingoChessState) -> [PingoGridPoint] {
        var moves = jumpMoves(from: from, player: player, state: state,
                              deltas: [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)])
        let homeRow = player == 0 ? 7 : 0
        guard from == PingoGridPoint(row: homeRow, column: 4), !isKingInCheck(player: player, state: state) else { return moves }
        let kingRight = player == 0 ? 1 : 4
        let queenRight = player == 0 ? 2 : 8
        if state.castlingRights & kingRight != 0,
           state.cells[homeRow * 8 + 5] == 0, state.cells[homeRow * 8 + 6] == 0,
           state.cells[homeRow * 8 + 7] == code(kind: 4, player: player),
           !isSquareAttacked(homeRow * 8 + 5, by: 1-player, state: state),
           !isSquareAttacked(homeRow * 8 + 6, by: 1-player, state: state) {
            moves.append(PingoGridPoint(row: homeRow, column: 6))
        }
        if state.castlingRights & queenRight != 0,
           state.cells[homeRow * 8 + 1] == 0, state.cells[homeRow * 8 + 2] == 0, state.cells[homeRow * 8 + 3] == 0,
           state.cells[homeRow * 8] == code(kind: 4, player: player),
           !isSquareAttacked(homeRow * 8 + 3, by: 1-player, state: state),
           !isSquareAttacked(homeRow * 8 + 2, by: 1-player, state: state) {
            moves.append(PingoGridPoint(row: homeRow, column: 2))
        }
        return moves
    }

    private static func applyUnchecked(
        from: PingoGridPoint, to: PingoGridPoint, player: Int,
        promotion: PingoChessPromotion?, state: PingoChessState
    ) throws -> PingoChessState {
        var next = state
        let fromIndex = from.index8, toIndex = to.index8
        let moving = next.cells[fromIndex]
        let movingKind = kind(of: moving)
        let captured = next.cells[toIndex]
        var isCapture = captured != 0
        next.cells[fromIndex] = 0

        if movingKind == 1, next.enPassantTarget == toIndex, captured == 0, from.column != to.column {
            let capturedRow = to.row + (player == 0 ? 1 : -1)
            let capturedIndex = capturedRow * 8 + to.column
            if next.cells[capturedIndex] == code(kind: 1, player: 1-player) {
                next.cells[capturedIndex] = 0
                isCapture = true
            }
        }

        var finalPiece = moving
        if movingKind == 1, to.row == (player == 0 ? 0 : 7) {
            let selected: Int
            switch promotion ?? .queen {
            case .queen: selected = 5
            case .rook: selected = 4
            case .bishop: selected = 3
            case .knight: selected = 2
            }
            finalPiece = code(kind: selected, player: player)
        }
        next.cells[toIndex] = finalPiece

        if movingKind == 6, abs(to.column - from.column) == 2 {
            let rookFromCol = to.column == 6 ? 7 : 0
            let rookToCol = to.column == 6 ? 5 : 3
            let rookFrom = from.row * 8 + rookFromCol
            let rookTo = from.row * 8 + rookToCol
            next.cells[rookTo] = next.cells[rookFrom]
            next.cells[rookFrom] = 0
        }

        next.castlingRights = updatedCastlingRights(next.castlingRights, moving: moving, from: fromIndex, captured: captured, at: toIndex)
        next.enPassantTarget = nil
        if movingKind == 1, abs(to.row - from.row) == 2 { next.enPassantTarget = ((to.row + from.row) / 2) * 8 + from.column }
        next.halfmoveClock = movingKind == 1 || isCapture ? 0 : next.halfmoveClock + 1
        if player == 1 { next.fullmoveNumber += 1 }
        return next
    }

    private static func updatedCastlingRights(_ rights: Int, moving: Int, from: Int, captured: Int, at to: Int) -> Int {
        var result = rights
        if kind(of: moving) == 6 { result &= owner(of: moving) == 0 ? ~3 : ~12 }
        if kind(of: moving) == 4 {
            if from == 56 { result &= ~2 }; if from == 63 { result &= ~1 }
            if from == 0 { result &= ~8 }; if from == 7 { result &= ~4 }
        }
        if kind(of: captured) == 4 {
            if to == 56 { result &= ~2 }; if to == 63 { result &= ~1 }
            if to == 0 { result &= ~8 }; if to == 7 { result &= ~4 }
        }
        return result
    }

    private static func rayAttacked(target: PingoGridPoint, attacker: Int, state: PingoChessState, directions: [(Int,Int)], kinds: Set<Int>) -> Bool {
        for (dr, dc) in directions {
            var row = target.row + dr, col = target.column + dc
            while (0..<8).contains(row), (0..<8).contains(col) {
                let code = state.cells[row * 8 + col]
                if code != 0 {
                    if owner(of: code) == attacker && kinds.contains(kind(of: code)) { return true }
                    break
                }
                row += dr; col += dc
            }
        }
        return false
    }

    private static func insufficientMaterial(_ state: PingoChessState) -> Bool {
        let pieces = state.cells.enumerated().filter { kind(of: $0.element) != 0 && kind(of: $0.element) != 6 }
        if pieces.isEmpty { return true }
        if pieces.count == 1, let only = pieces.first, [2,3].contains(kind(of: only.element)) { return true }
        if pieces.count == 2,
           pieces.allSatisfy({ kind(of: $0.element) == 3 }),
           owner(of: pieces[0].element) != owner(of: pieces[1].element) {
            let a = point(pieces[0].offset), b = point(pieces[1].offset)
            return (a.row + a.column) % 2 == (b.row + b.column) % 2
        }
        return false
    }

    private static func valid(_ point: PingoGridPoint) -> Bool { (0..<8).contains(point.row) && (0..<8).contains(point.column) }
    private static func point(_ index: Int) -> PingoGridPoint { PingoGridPoint(row: index / 8, column: index % 8) }
}
