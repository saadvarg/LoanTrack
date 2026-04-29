import Foundation

struct MortgageResult: Codable, Identifiable {
    let id: UUID
    let principal: Double
    let annualRate: Double
    let termYears: Double
    let monthlyPayment: Double
    let createdAt: Date

    init(
        id: UUID = UUID(),
        principal: Double,
        annualRate: Double,
        termYears: Double,
        monthlyPayment: Double,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.principal = principal
        self.annualRate = annualRate
        self.termYears = termYears
        self.monthlyPayment = monthlyPayment
        self.createdAt = createdAt
    }
}
