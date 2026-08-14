import Foundation

public enum PingoSeaBattleWireCodec {
    private struct WireState: Codable {
        let r: [Bool]
        let s: [[Int]]
        let p: [Int]?
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder = JSONDecoder()

    public static func encode(_ state: PingoSeaBattleState) throws -> Data {
        let wire = WireState(
            r: state.fleetReady,
            s: state.shots.map { $0.map(pack) },
            p: state.pendingShot.map { [$0.shooter, $0.cell] }
        )
        return try encoder.encode(wire)
    }

    public static func decode(_ data: Data) throws -> PingoSeaBattleState {
        let wire = try decoder.decode(WireState.self, from: data)
        guard wire.r.count == 2, wire.s.count == 2 else {
            throw PingoGameRuleError.invalidState
        }

        let pending: PingoSeaBattlePendingShot?
        if let p = wire.p {
            guard p.count == 2, (0...1).contains(p[0]), (0..<100).contains(p[1]) else {
                throw PingoGameRuleError.invalidState
            }
            pending = .init(shooter: p[0], cell: p[1])
        } else {
            pending = nil
        }

        let shots = try wire.s.map { packedShots in
            try packedShots.map(unpack)
        }
        return PingoSeaBattleState(fleetReady: wire.r, shots: shots, pendingShot: pending)
    }

    private static func pack(_ shot: PingoSeaBattleShot) -> Int {
        var packed = shot.cell
        if shot.hit { packed |= 1 << 7 }
        if let sunk = shot.sunk,
           let index = PingoSeaBattleShip.allCases.firstIndex(of: sunk) {
            packed |= (index + 1) << 8
        }
        return packed
    }

    private static func unpack(_ packed: Int) throws -> PingoSeaBattleShot {
        let cell = packed & 0x7F
        guard (0..<100).contains(cell) else { throw PingoGameRuleError.invalidState }
        let hit = (packed & (1 << 7)) != 0
        let sunkCode = (packed >> 8) & 0x07
        let sunk: PingoSeaBattleShip?
        if sunkCode == 0 {
            sunk = nil
        } else {
            let index = sunkCode - 1
            guard PingoSeaBattleShip.allCases.indices.contains(index) else {
                throw PingoGameRuleError.invalidState
            }
            sunk = PingoSeaBattleShip.allCases[index]
        }
        return .init(cell: cell, hit: hit, sunk: sunk)
    }
}
