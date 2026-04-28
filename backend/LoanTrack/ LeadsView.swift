import SwiftUI

struct LeadsView: View {
    @EnvironmentObject var store: LeadStore
    @State private var showAddLead = false
    @State private var searchText = ""
    
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
    var filteredLeads: [Lead] {
        if searchText.isEmpty {
            return store.leads
        }
        return store.leads.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if store.leads.isEmpty {
                    EmptyLeadsView(showAddLead: $showAddLead, tealColor: tealColor)
                } else {
                    List {
                        ForEach(filteredLeads) { lead in
                            NavigationLink(destination: LeadDetailView(lead: lead)) {
                                LeadRowView(lead: lead)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search leads...")
                }
            }
            .navigationTitle("Leads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddLead = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(tealColor)
                    }
                }
            }
            .sheet(isPresented: $showAddLead) {
                AddLeadView()
            }
        }
    }
}

// MARK: - Lead Row
struct LeadRowView: View {
    let lead: Lead
    
    var statusColor: Color {
        switch lead.status {
        case .new:       return .blue
        case .contacted: return .orange
        case .qualified: return .purple
        case .closed:    return .green
        case .lost:      return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            
            // Avatar circle
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(lead.initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(lead.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(lead.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status + Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(lead.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(8)
                
                Text(lead.loanAmount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct EmptyLeadsView: View {
    @Binding var showAddLead: Bool
    let tealColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Leads Yet")
                .font(.title2)
                .fontWeight(.bold)
            Text("Add your first lead to start\ntracking mortgage opportunities.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showAddLead = true }) {
                Label("Add First Lead", systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(tealColor)
                    .cornerRadius(14)
            }
        }
        .padding()
    }
}
