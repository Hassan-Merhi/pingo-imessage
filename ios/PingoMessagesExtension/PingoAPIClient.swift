import Foundation
import PingoCore

actor PingoAPIClient {
    struct BootstrapResponse: Decodable {
        let accessToken: String
        let profile: PingoPublicProfile
    }

    private struct ProfileResponse: Decodable {
        let profile: PingoPublicProfile
    }

    private struct BootstrapRequest: Encodable {
        let playerID: UUID
        let username: String
        let avatar: PingoAvatar
    }

    private struct ProfilePatchRequest: Encodable {
        let username: String
        let avatar: PingoAvatar
    }

    enum ClientError: Error {
        case invalidResponse
        case server(Int)
    }

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = PingoConfiguration.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

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

    func bootstrap(profile: PingoPublicProfile) async throws -> BootstrapResponse {
        let requestBody = BootstrapRequest(playerID: profile.id, username: profile.username, avatar: profile.avatar)
        var request = URLRequest(url: baseURL.appendingPathComponent("bootstrap"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(requestBody)
        let data = try await perform(request)
        return try decoder.decode(BootstrapResponse.self, from: data)
    }

    func updateProfile(_ profile: PingoPublicProfile, token: String) async throws -> PingoPublicProfile {
        let requestBody = ProfilePatchRequest(username: profile.username, avatar: profile.avatar)
        var request = URLRequest(url: baseURL.appendingPathComponent("me"))
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(requestBody)
        let data = try await perform(request)
        return try decoder.decode(ProfileResponse.self, from: data).profile
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw ClientError.server(http.statusCode) }
        return data
    }
}
