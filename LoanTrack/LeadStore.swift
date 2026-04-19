import Foundation
import Combine
import SwiftUI

class LeadStore: ObservableObject {
    @Published var leads: [Lead] = []
    
    private let saveKey = "SavedLeads"
    
    init() {
        load()
    }
    
    // Add a new lead
    func add(_ lead: Lead) {
        leads.append(lead)
        save()
    }
    
    // Delete leads
    func delete(at offsets: IndexSet) {
        leads.remove(atOffsets: offsets)
        save()
    }
    
    // Update a lead
    func update(_ lead: Lead) {
        if let index = leads.firstIndex(where: { $0.id == lead.id }) {
            leads[index] = lead
            save()
        }
    }
    
    // Save to device storage
    private func save() {
        if let encoded = try? JSONEncoder().encode(leads) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // Load from device storage
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Lead].self, from: data) {
            leads = decoded
        }
    }
    
    // Stats for dashboard
    var totalLeads: Int { leads.count }
    var newLeads: Int { leads.filter { $0.status == .new }.count }
    var qualifiedLeads: Int { leads.filter { $0.status == .qualified }.count }
    var closedLeads: Int { leads.filter { $0.status == .closed }.count }
    var totalLoanValue: Double { leads.reduce(0) { $0 + $1.loanAmount } }
}
