import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Loan Details") {
                    TextField("Principal", text: $viewModel.principal)
                        .keyboardType(.decimalPad)

                    TextField("Annual Rate (%)", text: $viewModel.annualRate)
                        .keyboardType(.decimalPad)

                    TextField("Term (Years)", text: $viewModel.termYears)
                        .keyboardType(.decimalPad)
                }

                Button("Calculate") {
                    viewModel.calculate()
                }

                if let result = viewModel.result {
                    Section("Result") {
                        Text("Monthly Payment: \(result.monthlyPayment.currencyFormatted)")
                        Text("Principal: \(result.principal.currencyFormatted)")
                        Text("Rate: \(result.annualRate, specifier: "%.2f")%")
                        Text("Term: \(Int(result.termYears)) years")
                    }

                    Section("Scenario") {
                        Button("Save Scenario") {
                            viewModel.saveCurrentScenario()
                        }
                    }
                }

                if !viewModel.savedScenarios.isEmpty {
                    Section("Saved Scenarios") {
                        ForEach(viewModel.savedScenarios) { scenario in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Payment: \(scenario.monthlyPayment.currencyFormatted)")
                                    .font(.headline)

                                Text("Loan: \(scenario.principal.currencyFormatted) • \(scenario.annualRate, specifier: "%.2f")% • \(Int(scenario.termYears)) years")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(scenario.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let scenario = viewModel.savedScenarios[index]
                                viewModel.deleteScenario(id: scenario.id)
                            }
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Calculator")
        }
    }
}

#Preview {
    CalculatorView()
}
