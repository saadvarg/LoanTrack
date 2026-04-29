import Foundation
import Combine

@MainActor
final class LeadViewModel: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var lastScoringResult: LeadScoringResult?
    @Published var leadActivities: [LeadActivity] = []

    private func notifyLeadDataChanged() {
        NotificationCenter.default.post(name: .leadDataDidChange, object: nil)
    }

    func loadLeads() async {
        isLoading = true
        defer { isLoading = false }

        do {
            leads = try await APIService.shared.fetchLeads()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load leads."
        }
    }

    func addLead(
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
    ) async -> Bool {
        do {
            let newLead = try await APIService.shared.createLead(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone,
                loanAmount: loanAmount,
                income: income,
                debt: debt,
                creditScore: creditScore,
                employmentStatus: employmentStatus,
                notes: notes
            )
            leads.insert(newLead, at: 0)
            errorMessage = nil
            successMessage = "Lead created successfully."
            notifyLeadDataChanged()
            return true
        } catch {
            if case let APIError.serverError(message) = error {
                errorMessage = message
            } else {
                errorMessage = "Failed to create lead."
            }
            return false
        }
    }

    func updateLead(_ lead: Lead) async -> Bool {
        do {
            let updatedLead = try await APIService.shared.updateLead(lead)
            if let index = leads.firstIndex(where: { $0.id == updatedLead.id }) {
                leads[index] = updatedLead
            }
            errorMessage = nil
            successMessage = "Lead updated successfully."
            notifyLeadDataChanged()
            return true
        } catch {
            if case let APIError.serverError(message) = error {
                errorMessage = message
            } else {
                errorMessage = "Failed to update lead."
            }
            return false
        }
    }

    func deleteLead(id: String) async -> Bool {
        do {
            try await APIService.shared.deleteLead(id: id)
            leads.removeAll { $0.id == id }
            errorMessage = nil
            successMessage = "Lead deleted successfully."
            notifyLeadDataChanged()
            return true
        } catch {
            if case let APIError.serverError(message) = error {
                errorMessage = message
            } else {
                errorMessage = "Failed to delete lead."
            }
            return false
        }
    }

    func scoreLead(_ lead: Lead) async -> Bool {
        do {
            let result = try await APIService.shared.scoreLead(id: lead.id)
            if let index = leads.firstIndex(where: { $0.id == lead.id }) {
                leads[index].riskScore = Double(result.score)
                leads[index].riskLabel = result.riskLabel
            }
            lastScoringResult = result
            errorMessage = nil
            successMessage = "AI insights generated."
            notifyLeadDataChanged()
            return true
        } catch {
            if case let APIError.serverError(message) = error {
                errorMessage = message
            } else {
                errorMessage = "Failed to score lead."
            }
            return false
        }
    }

    func loadActivities(for leadId: String) async {
        do {
            leadActivities = try await APIService.shared.fetchLeadActivities(leadId: leadId)
        } catch {
            leadActivities = []
        }
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}

extension Notification.Name {
    static let leadDataDidChange = Notification.Name("leadDataDidChange")
}
