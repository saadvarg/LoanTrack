import SwiftUI

struct LeadDetailView: View {
    @EnvironmentObject var store: LeadStore
    let lead: Lead
    
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
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
        ScrollView {
            VStack(spacing: 20) {
                
                // ── HEADER ───────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                        Text(lead.initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(lead.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Label(lead.status.rawValue, systemImage: lead.status.icon)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(navyBlue)
                .cornerRadius(16)
                
                // ── LOAN AMOUNT ──────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Loan Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(lead.loanAmount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(tealColor)
                    }
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.system(size: 36))
                        .foregroundColor(tealColor.opacity(0.3))
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6)
                
                // ── CONTACT INFO ─────────────────────────
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Info")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ContactRow(icon: "envelope.fill", color: .blue, label: "Email", value: lead.email)
                    Divider()
                    ContactRow(icon: "phone.fill", color: .green, label: "Phone", value: lead.phone.isEmpty ? "—" : lead.phone)
                    Divider()
                    ContactRow(icon: "calendar", color: .orange, label: "Added", value: lead.dateAdded.formatted(date: .abbreviated, time: .omitted))
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 6)
                
                // ── NOTES ────────────────────────────────
                if !lead.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Notes", systemImage: "note.text")
                            .font(.headline)
                        Text(lead.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 6)
                }
                
                Spacer(minLength: 30)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lead Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
}
