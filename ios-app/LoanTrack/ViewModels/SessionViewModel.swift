import Foundation
import Combine
import AuthenticationServices

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = true

    var isAuthenticated: Bool {
        currentUser != nil
    }

    init() {
        Task {
            await restoreSession()
        }
    }

    func restoreSession() async {
        guard AuthService.shared.getToken() != nil else {
            isLoading = false
            return
        }

        do {
            currentUser = try await APIService.shared.fetchCurrentUser()
        } catch {
            AuthService.shared.clearToken()
            currentUser = nil
        }

        isLoading = false
    }

    func login(email: String, password: String) async throws {
        let session = try await APIService.shared.login(
            email: email,
         password: password
        )
        if session.user.status == "pending" {
                throw APIError.serverError("Your account is pending approval. An admin will activate your account shortly.")
            }
            
            if session.user.status == "suspended" {
                throw APIError.serverError("Your account has been suspended. Contact your administrator.")
            }
        AuthService.shared.saveToken(session.token)
        currentUser = session.user
       
    }

    func register(fullName: String, email: String, password: String, company: String?, role: String)
    async throws {
        let session = try await APIService.shared.register(
            fullName: fullName,
                    email: email,
                    password: password,
                    company: company,
                    role: role
            
        )
        AuthService.shared.saveToken(session.token)
        currentUser = session.user
    }
    
    

    func logout() {
        AuthService.shared.clearToken()
        currentUser = nil
    }
}
