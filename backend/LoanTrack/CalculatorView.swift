import SwiftUI

struct CalculatorView: View {
    
    // MARK: - Input State
    @State private var loanAmount: String = ""
    @State private var interestRate: String = ""
    @State private var loanTermYears: String = ""
    @State private var downPayment: String = ""
    
    // MARK: - Result State
    @State private var monthlyPayment: Double = 0
    @State private var totalPayment: Double = 0
    @State private var totalInterest: Double = 0
    @State private var showResults: Bool = false
    
    // MARK: - Colors
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // ── HEADER CARD ──────────────────────────────
                    VStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                        Text("Mortgage Calculator")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Calculate your monthly payments")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(navyBlue)
                    .cornerRadius(16)
                    
                    // ── INPUT FIELDS ─────────────────────────────
                    VStack(spacing: 16) {
                        
                        InputField(
                            title: "Loan Amount",
                            placeholder: "e.g. 300000",
                            icon: "dollarsign.circle.fill",
                            text: $loanAmount,
                            suffix: "USD"
                        )
                        
                        InputField(
                            title: "Down Payment",
                            placeholder: "e.g. 60000",
                            icon: "arrow.down.circle.fill",
                            text: $downPayment,
                            suffix: "USD"
                        )
                        
                        InputField(
                            title: "Annual Interest Rate",
                            placeholder: "e.g. 6.5",
                            icon: "percent",
                            text: $interestRate,
                            suffix: "%"
                        )
                        
                        InputField(
                            title: "Loan Term",
                            placeholder: "e.g. 30",
                            icon: "calendar",
                            text: $loanTermYears,
                            suffix: "Years"
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    
                    // ── CALCULATE BUTTON ─────────────────────────
                    Button(action: calculateMortgage) {
                        HStack {
                            Image(systemName: "function")
                                .font(.title3)
                            Text("Calculate Payment")
                                .fontWeight(.semibold)
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tealColor)
                        .cornerRadius(14)
                    }
                    
                    // ── RESULTS ──────────────────────────────────
                    if showResults {
                        ResultsCard(
                            monthlyPayment: monthlyPayment,
                            totalPayment: totalPayment,
                            totalInterest: totalInterest,
                            navyBlue: navyBlue,
                            tealColor: tealColor
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Calculation Logic
    func calculateMortgage() {
        guard
            let principal = Double(loanAmount),
            let down = Double(downPayment),
            let annualRate = Double(interestRate),
            let years = Double(loanTermYears),
            principal > 0, annualRate > 0, years > 0
        else { return }
        
        let loanPrincipal = principal - down
        let monthlyRate = (annualRate / 100) / 12
        let numberOfPayments = years * 12
        
        // Standard mortgage formula
        let payment = loanPrincipal *
            (monthlyRate * pow(1 + monthlyRate, numberOfPayments)) /
            (pow(1 + monthlyRate, numberOfPayments) - 1)
        
        let total = payment * numberOfPayments
        let interest = total - loanPrincipal
        
        withAnimation(.spring()) {
            monthlyPayment = payment
            totalPayment = total
            totalInterest = interest
            showResults = true
        }
    }
}

// MARK: - Input Field Component
struct InputField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    let suffix: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 22)
                
                TextField(placeholder, text: $text)
                    .keyboardType(.decimalPad)
                    .font(.body)
                
                Text(suffix)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Results Card Component
struct ResultsCard: View {
    let monthlyPayment: Double
    let totalPayment: Double
    let totalInterest: Double
    let navyBlue: Color
    let tealColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Monthly Payment — Hero Number
            VStack(spacing: 6) {
                Text("Monthly Payment")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                Text(monthlyPayment.formatted(.currency(code: "USD")))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(navyBlue)
            .cornerRadius(16)
            
            // Breakdown Row
            HStack(spacing: 12) {
                ResultStatCard(
                    label: "Total Payment",
                    value: totalPayment.formatted(.currency(code: "USD")),
                    icon: "creditcard.fill",
                    color: tealColor
                )
                ResultStatCard(
                    label: "Total Interest",
                    value: totalInterest.formatted(.currency(code: "USD")),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Result Stat Card
struct ResultStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    CalculatorView()
}
