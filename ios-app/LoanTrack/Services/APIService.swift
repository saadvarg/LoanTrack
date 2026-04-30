import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .unauthorized:
            return "Unauthorized."
        case .serverError(let message):
            return message
        case .decodingFailed:
            return "Failed to decode server response."
        }
    }
}


final class APIService {
    static let shared = APIService()

    private init() {}
    
    func adminFetchAllUsers() async throws -> AllUsersEnvelope {
        let response: AllUsersEnvelope = try await request(
            path: "/api/admin/users/all",
            method: "GET",
            requiresAuth: true
        )
        return response
    }

    func adminApproveUser(userId: String, role: String) async throws {
        let body = ["role": role]
        let _: AdminActionResponse = try await request(
            path: "/api/admin/users/\(userId)/approve",
            method: "PUT",
            body: body,
            requiresAuth: true
        )
    }

    func adminSuspendUser(userId: String) async throws {
        let _: AdminActionResponse = try await request(
            path: "/api/admin/users/\(userId)/suspend",
            method: "PUT",
            requiresAuth: true
        )
    }
    // MARK: - Admin

    func adminFetchUsers() async throws -> [AdminUser] {
        let response: AdminUsersEnvelope = try await request(
            path: "/api/admin/users",
            method: "GET",
            requiresAuth: true
        )
        return response.data
    }

    func adminFetchStats() async throws -> AdminStats {
        let response: AdminStatsEnvelope = try await request(
            path: "/api/admin/stats",
            method: "GET",
            requiresAuth: true
        )
        return response.data
    }

    func adminCreateUser(
        fullName: String,
        email: String,
        password: String,
        role: String
    ) async throws {
        let body = [
            "fullName": fullName,
            "email": email,
            "password": password,
            "role": role,
        ]
        let _: AdminActionResponse = try await request(
            path: "/api/admin/users",
            method: "POST",
            body: body,
            requiresAuth: true
        )
    }

    func adminUpdateUserRole(userId: String, role: String) async throws {
        let body = ["role": role]
        let _: AdminActionResponse = try await request(
            path: "/api/admin/users/\(userId)/role",
            method: "PUT",
            body: body,
            requiresAuth: true
        )
    }

    func login(email: String, password: String) async throws -> AuthSession {
        let body = [
            "email": email,
            "password": password
        ]

        let response: AuthEnvelope = try await request(
            path: "/api/auth/login",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        return AuthSession(token: response.token, user: response.user)
    }

    func register(
        fullName: String,
        email: String,
        password: String,
        company: String?,
        role: String = "agent"  // ← add this
    ) async throws -> AuthSession {
        let body: [String: String?] = [
            "fullName": fullName,
            "email": email,
            "password": password,
            "company": company,
            "role": role  // ← add this
        ]

        let response: AuthEnvelope = try await request(
            path: "/api/auth/register",
            method: "POST",
            body: body,
            requiresAuth: false
        )
        return AuthSession(token: response.token, user: response.user)
    }

    func fetchCurrentUser() async throws -> User {
        let response: CurrentUserEnvelope = try await request(
            path: "/api/auth/me",
            method: "GET",
            requiresAuth: true
        )
        return response.user
    }

    func fetchLeads() async throws -> [Lead] {
        let response: LeadsResponse = try await request(
            path: "/api/leads",
            method: "GET",
            requiresAuth: true
        )
        return response.leads ?? response.data ?? []
    }

    func createLead(
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        loanAmount: Double?,
        income: Double?,
        debt: Double?,
        creditScore: Int?,
        employmentStatus: String,
        notes: String
    ) async throws -> Lead {
        let body = LeadUpsertRequest(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            loanAmount: loanAmount,
            status: "new",
            notes: notes.isEmpty ? nil : notes,
            income: income,
            debt: debt,
            creditScore: creditScore,
            employmentStatus: employmentStatus
        )

        let response: LeadResponse = try await request(
            path: "/api/leads",
            method: "POST",
            body: body,
            requiresAuth: true
        )

        guard let lead = response.lead ?? response.data else {
            throw APIError.invalidResponse
        }

        return lead
    }

    func updateLead(_ lead: Lead) async throws -> Lead {
        let body = LeadUpsertRequest(
            firstName: lead.firstName,
            lastName: lead.lastName,
            email: lead.email,
            phone: lead.phone,
            loanAmount: lead.loanAmount,
            status: lead.status,
            notes: lead.notes,
            income: lead.income,
            debt: lead.debt,
            creditScore: lead.creditScore,
            employmentStatus: lead.employmentStatus ?? "employed"
        )

        let response: LeadResponse = try await request(
            path: "/api/leads/\(lead.id)",
            method: "PUT",
            body: body,
            requiresAuth: true
        )

        guard let updatedLead = response.lead ?? response.data else {
            throw APIError.invalidResponse
        }

        return updatedLead
    }

    func deleteLead(id: String) async throws {
        let _: DeleteResponse = try await request(
            path: "/api/leads/\(id)",
            method: "DELETE",
            requiresAuth: true
        )
    }

    func fetchDashboardEnvelope() async throws -> AnalyticsDashboardEnvelope {
        let response: AnalyticsDashboardEnvelope = try await request(
            path: "/api/analytics/dashboard",
            method: "GET",
            requiresAuth: true
        )
        return response
    }

    func scoreLead(id: String) async throws -> LeadScoringResult {
        let response: ScoringEnvelope = try await request(
            path: "/api/scoring/score-lead/\(id)",
            method: "POST",
            body: EmptyRequest(),
            requiresAuth: true
        )
        return response.data
    }
    // MARK: - PDF Export
    // MARK: - PDF Export
    func downloadLeadPDF(leadId: String) async throws -> Data {
        guard let url = URL(string: Constants.baseURL + "/pdf/lead/\(leadId)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError("Failed to generate PDF")
        }

        return data
    }

    func fetchLeadActivities(leadId: String) async throws -> [LeadActivity] {
        let response: ActivitiesEnvelope = try await request(
            path: "/api/activities/lead/\(leadId)",
            method: "GET",
            requiresAuth: true
        )
        return response.data
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        requiresAuth: Bool
    ) async throws -> T {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decodeResponse(data: data, response: response)
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body,
        requiresAuth: Bool
    ) async throws -> T {
        guard let url = URL(string: Constants.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = AuthService.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        return try decodeResponse(data: data, response: response)
    }

    private func decodeResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
                throw APIError.serverError(apiError.message)
            }
            throw APIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}

struct AuthSession {
    let token: String
    let user: User
}

struct LeadScoringResult: Decodable {
    let leadId: String
    let leadName: String
    let score: Int
    let riskLabel: String
    let riskColor: String
    let recommendation: String
    let loanRecommendation: LoanRecommendation
    let breakdown: [ScoreBreakdown]
    let flags: [String]
    let metrics: ScoreMetrics
}

struct LoanRecommendation: Decodable {
    let type: String
    let reason: String
    let suggestedRate: String
}
private struct AdminUsersEnvelope: Decodable {
    let success: Bool
    let data: [AdminUser]
}

private struct AdminStatsEnvelope: Decodable {
    let success: Bool
    let data: AdminStats
}

private struct AdminActionResponse: Decodable {
    let success: Bool
    let message: String?
}

struct ScoreBreakdown: Decodable, Identifiable {
    let factor: String
    let points: Int
    let note: String

    var id: String { factor }
}

struct ScoreMetrics: Decodable {
    let dti: Double
    let lti: Double
    let creditScore: Int
    let monthlyIncome: Double
}

private struct LeadUpsertRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let loanAmount: Double?
    let status: String
    let notes: String?
    let income: Double?
    let debt: Double?
    let creditScore: Int?
    let employmentStatus: String
}

private struct EmptyRequest: Encodable {}

private struct AuthEnvelope: Decodable {
    let success: Bool
    let message: String
    let token: String
    let user: User
}

private struct CurrentUserEnvelope: Decodable {
    let success: Bool
    let user: User
}

private struct ErrorEnvelope: Decodable {
    let success: Bool
    let message: String
}

private struct LeadsResponse: Decodable {
    let success: Bool?
    let leads: [Lead]?
    let data: [Lead]?
}

private struct LeadResponse: Decodable {
    let success: Bool?
    let message: String?
    let lead: Lead?
    let data: Lead?
}



private struct DeleteResponse: Decodable {
    let success: Bool?
    let message: String?
}

private struct ScoringEnvelope: Decodable {
    let success: Bool
    let message: String
    let data: LeadScoringResult
}

private struct ActivitiesEnvelope: Decodable {
    let success: Bool
    let data: [LeadActivity]
}
