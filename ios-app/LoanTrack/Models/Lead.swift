import Foundation

struct Lead: Codable, Identifiable {
    let id: String
    var userId: String?
    var firstName: String
    var lastName: String
    var email: String
    var phone: String?
    var loanAmount: Double?
    var status: String
    var notes: String?
    var income: Double?
    var debt: Double?
    var creditScore: Int?
    var riskScore: Double?
    var riskLabel: String?
    var dateAdded: String?
    var updatedAt: String?
    var employmentStatus: String?

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case loanAmount = "loan_amount"
        case status
        case notes
        case income
        case debt
        case creditScore = "credit_score"
        case riskScore = "risk_score"
        case riskLabel = "risk_label"
        case dateAdded = "date_added"
        case updatedAt = "updated_at"
        case employmentStatus = "employment_status"
    }
}
