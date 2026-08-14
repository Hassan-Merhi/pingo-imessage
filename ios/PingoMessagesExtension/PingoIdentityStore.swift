import Foundation
import PingoCore
import Security

struct PingoIdentityStore {
    private let defaults = UserDefaults.standard
    private let profileKey = "pingo.profile.v1"
    private let keychainService = "com.pingo.identity"
    private let keychainAccount = "backend-token"

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

    func loadOrCreateProfile() -> PingoPublicProfile {
        if let data = defaults.data(forKey: profileKey),
           let profile = try? decoder.decode(PingoPublicProfile.self, from: data) {
            return profile
        }

        let id = UUID()
        let suffix = id.uuidString.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        let profile = PingoPublicProfile(id: id, username: "pingo_\(suffix)")
        save(profile: profile)
        return profile
    }

    func save(profile: PingoPublicProfile) {
        guard let data = try? encoder.encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    func loadAccessToken() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveAccessToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let lookup: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount
        ]
        let update: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(lookup as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var add = lookup
            add[kSecValueData] = data
            add[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    func deleteAccessToken() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
