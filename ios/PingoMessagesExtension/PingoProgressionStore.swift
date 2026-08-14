import Foundation
import PingoCore

struct PingoProgressionStore {
    private let defaults = UserDefaults.standard
    private let key = "pingo.progression.v1"

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }

    func load() -> PingoProgressionState {
        guard let data = defaults.data(forKey: key),
              let state = try? decoder.decode(PingoProgressionState.self, from: data) else {
            return PingoProgressionState()
        }
        return state
    }

    func save(_ state: PingoProgressionState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}
