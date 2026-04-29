import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: LeadStore
    
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ── HERO HEADER ──────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greetingText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Saad El Mouataz")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Here's your pipeline overview")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 4)
                        
                        // Total pipeline value
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Pipeline Value")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .textCase(.uppercase)
                            Text(store.totalLoanValue.formatted(
                                .currency(code: "USD").precision(.fractionLength(0))
                            ))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [navyBlue, tealColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    
                    // ── STATS GRID ───────────────────────────────
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 14) {
                        StatCard(
                            title: "Total Leads",
                            value: "\(store.totalLeads)",
                            icon: "person.2.fill",
                            color: navyBlue
                        )
                        StatCard(
                            title: "New",
                            value: "\(store.newLeads)",
                            icon: "star.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Qualified",
                            value: "\(store.qualifiedLeads)",
                            icon: "checkmark.seal.fill",
                            color: .purple
                        )
                        StatCard(
                            title: "Closed",
                            value: "\(store.closedLeads)",
                            icon: "trophy.fill",
                            color: .green
                        )
                    }
                    
                    // ── RECENT LEADS ─────────────────────────────
                    if !store.leads.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Recent Leads")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(store.totalLeads) total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ForEach(store.leads.prefix(3)) { lead in
                                NavigationLink(destination: LeadDetailView(lead: lead)) {
                                    RecentLeadRow(lead: lead)
                                }
                                .buttonStyle(.plain)
                                
                                if lead.id != store.leads.prefix(3).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6)
                    }
                    
                    // ── QUICK TIPS ───────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Quick Tips", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        TipRow(text: "Follow up with Contacted leads within 24 hours for best conversion rates.")
                        Divider()
                        TipRow(text: "Qualified leads are 3x more likely to close when contacted within the same day.")
                        Divider()
                        TipRow(text: "Use the Calculator to show clients their exact monthly payment before pitching.")
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6)
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }
}

// MARK: - Recent Lead Row
struct RecentLeadRow: View {
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Text(lead.initials)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(lead.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(lead.status.rawValue)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            Text(lead.loanAmount.formatted(
                .currency(code: "USD").precision(.fractionLength(0))
            ))
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.orange.opacity(0.7))
                .font(.caption)
                .padding(.top, 3)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(LeadStore())
}
