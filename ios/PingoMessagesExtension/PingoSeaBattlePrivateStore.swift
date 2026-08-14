import Foundation
import PingoCore

@MainActor
final class PingoSeaBattlePrivateStore {
    static let shared = PingoSeaBattlePrivateStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let keyPrefix = "pingo.sea-battle.private-fleet."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ fleet: [PingoSeaBattlePlacement], matchID: UUID) throws {
        try PingoSeaBattle.validateFleet(fleet)
        defaults.set(try encoder.encode(fleet), forKey: key(for: matchID))
    }

    func load(matchID: UUID) -> [PingoSeaBattlePlacement]? {
        guard let data = defaults.data(forKey: key(for: matchID)),
              let fleet = try? decoder.decode([PingoSeaBattlePlacement].self, from: data)
        else {
            return nil
        }

        do {
            try PingoSeaBattle.validateFleet(fleet)
            return fleet
        } catch {
            return nil
        }
    }

    func remove(matchID: UUID) {
        defaults.removeObject(forKey: key(for: matchID))
    }

    private func key(for matchID: UUID) -> String {
        keyPrefix + matchID.uuidString.lowercased()
    }
}
