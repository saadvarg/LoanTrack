import Foundation

final class AuthService {
    static let shared = AuthService()

    private let tokenKey = "loantrack.auth.token"

    private init() {}

    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func getToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
