import Foundation

enum PingoConfiguration {
    static var apiBaseURL: URL {
        URL(string: Bundle.main.object(forInfoDictionaryKey: "PingoAPIBaseURL") as? String ?? "https://api.pingo.invalid/v1")!
    }

    static var messageBaseURL: URL {
        URL(string: Bundle.main.object(forInfoDictionaryKey: "PingoMessageBaseURL") as? String ?? "https://pingo.invalid/match")!
    }

    static var backendEnabled: Bool {
        guard let host = apiBaseURL.host else { return false }
        return !host.hasSuffix(".invalid")
    }
}
