import Foundation

public enum PingoMessageAction: String, Codable, Sendable {
    case challenge
    case accepted
    case turn
    case resigned
    case completed
    case rematch
}

public struct PingoMessagePayload: Hashable, Codable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let action: PingoMessageAction
    public let sender: PingoPublicProfile
    public let match: PingoMatchEnvelope

    public init(
        schemaVersion: Int = currentSchemaVersion,
        action: PingoMessageAction,
        sender: PingoPublicProfile,
        match: PingoMatchEnvelope
    ) {
        self.schemaVersion = schemaVersion
        self.action = action
        self.sender = sender
        self.match = match
    }
}

public enum PingoMessageTransportError: Error, Equatable, Sendable {
    case invalidBaseURL
    case missingPayload
    case invalidPayload
    case payloadTooLarge
    case unsupportedSchema
}

public enum PingoMessageTransport {
    public static let maximumURLLength = 4_800

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()

    public static func makeURL(payload: PingoMessagePayload, baseURL: URL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              ["http", "https"].contains(components.scheme?.lowercased() ?? "")
        else {
            throw PingoMessageTransportError.invalidBaseURL
        }

        let data = try encoder.encode(payload)
        components.queryItems = [URLQueryItem(name: "p", value: base64URLEncode(data))]

        guard let url = components.url else {
            throw PingoMessageTransportError.invalidBaseURL
        }
        guard url.absoluteString.count <= maximumURLLength else {
            throw PingoMessageTransportError.payloadTooLarge
        }
        return url
    }

    public static func decode(url: URL) throws -> PingoMessagePayload {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encoded = components.queryItems?.first(where: { $0.name == "p" })?.value
        else {
            throw PingoMessageTransportError.missingPayload
        }
        guard let data = base64URLDecode(encoded) else {
            throw PingoMessageTransportError.invalidPayload
        }

        let payload: PingoMessagePayload
        do {
            payload = try decoder.decode(PingoMessagePayload.self, from: data)
        } catch {
            throw PingoMessageTransportError.invalidPayload
        }

        guard payload.schemaVersion == PingoMessagePayload.currentSchemaVersion,
              payload.match.schemaVersion <= PingoMatchEnvelope.currentSchemaVersion
        else {
            throw PingoMessageTransportError.unsupportedSchema
        }
        return payload
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            base64.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: base64)
    }
}
