import Foundation
import Combine

@MainActor
final class CalculatorViewModel: ObservableObject {
    @Published var savedScenarios: [MortgageResult] = []
    @Published var principal = ""
    @Published var annualRate = ""
    @Published var termYears = ""
    @Published var result: MortgageResult?
    @Published var errorMessage: String?

    private let savedScenariosKey = "loantrack.saved.mortgage.scenarios"

    init() {
        loadSavedScenarios()
    }

    func calculate() {
        guard
            let principalValue = Double(principal),
            let annualRateValue = Double(annualRate),
            let termYearsValue = Double(termYears)
        else {
            errorMessage = "Please enter valid numbers."
            return
        }

        let monthlyRate = annualRateValue / 100 / 12
        let totalPayments = termYearsValue * 12

        let monthlyPayment: Double

        if monthlyRate == 0 {
            monthlyPayment = principalValue / totalPayments
        } else {
            let factor = pow(1 + monthlyRate, totalPayments)
            monthlyPayment = principalValue * monthlyRate * factor / (factor - 1)
        }

        result = MortgageResult(
            principal: principalValue,
            annualRate: annualRateValue,
            termYears: termYearsValue,
            monthlyPayment: monthlyPayment
        )
        errorMessage = nil
    }

    func saveCurrentScenario() {
        guard let result else { return }
        savedScenarios.insert(result, at: 0)
        persistSavedScenarios()
    }

    func deleteScenario(id: UUID) {
        savedScenarios.removeAll { $0.id == id }
        persistSavedScenarios()
    }

    private func loadSavedScenarios() {
        guard
            let data = UserDefaults.standard.data(forKey: savedScenariosKey),
            let scenarios = try? JSONDecoder().decode([MortgageResult].self, from: data)
        else {
            return
        }

        savedScenarios = scenarios.sorted { $0.createdAt > $1.createdAt }
    }

    private func persistSavedScenarios() {
        guard let data = try? JSONEncoder().encode(savedScenarios) else { return }
        UserDefaults.standard.set(data, forKey: savedScenariosKey)
    }
}
