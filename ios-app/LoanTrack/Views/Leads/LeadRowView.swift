import SwiftUI

struct LeadRowView: View {
    let lead: Lead

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lead.fullName)
                .font(.headline)
            Text(lead.email)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text(lead.status.capitalized)
                if let loanAmount = lead.loanAmount {
                    Text("• \(loanAmount.currencyFormatted)")
                }
            }
            .font(.caption)

            if let riskLabel = lead.riskLabel, let riskScore = lead.riskScore {
                Text("\(riskLabel) • \(Int(riskScore))/100")
                    .font(.caption2)
                    .foregroundStyle(riskColor(for: riskLabel))
            }
        }
        .padding(.vertical, 4)
    }

    private func riskColor(for label: String) -> Color {
        switch label.lowercased() {
        case "low risk":
            return .green
        case "moderate risk":
            return .orange
        case "high risk", "very high risk":
            return .red
        default:
            return .secondary
        }
    }
}

#Preview {
    LeadRowView(
        lead: Lead(
            id: "1",
            userId: nil,
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            phone: "555",
            loanAmount: 350000,
            status: "new",
            notes: nil,
            income: 90000,
            debt: 15000,
            creditScore: 710,
            riskScore: nil,
            riskLabel: nil,
            dateAdded: nil,
            updatedAt: nil,
            employmentStatus: "employed"
        )
    )
}
