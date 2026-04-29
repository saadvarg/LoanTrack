import Foundation
import Combine

// ── DASHBOARD METRICS ────────────────────────────────────────────────────────

struct DashboardMetrics: Codable {
    let totalLeads: Int
    let byStatus: LeadStatusSummary
    let totalPipelineValue: Double
    let closedValue: Double
    let conversionRate: Double
    let avgLoanValue: Double
    let avgRiskScore: Double?
    let recentLeads: [RecentLead]
}

struct LeadStatusSummary: Codable {
    let new: Int
    let contacted: Int
    let qualified: Int
    let closed: Int
    let lost: Int
}

struct RecentLead: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let status: String
    let loanAmount: Double
    let riskScore: Double?
    let riskLabel: String?
    let dateAdded: String

    // No CodingKeys needed — API now sends camelCase
}

// ── ANALYTICS ENVELOPE ───────────────────────────────────────────────────────

struct AnalyticsDashboardEnvelope: Codable {
    let success: Bool
    let role: String?
    let portal: String?
    let data: DashboardMetrics
}

// ── DASHBOARD VIEW MODEL ─────────────────────────────────────────────────────

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var metrics: DashboardMetrics?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var userRole: String = "agent"
    @Published var portal: String = "agent"

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let envelope = try await APIService.shared.fetchDashboardEnvelope()
            metrics = envelope.data
            userRole = envelope.role ?? "agent"
            portal = envelope.portal ?? "agent"
        } catch {
            print("DASHBOARD ERROR: \(error)")
            if let decodingError = error as? DecodingError {
                print("DECODING ERROR: \(decodingError)")
            }
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
        }
    }
}
