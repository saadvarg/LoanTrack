import Foundation

struct Lead: Identifiable, Codable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var loanAmount: Double
    var status: LeadStatus
    var notes: String
    var dateAdded: Date = Date()
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let f = firstName.prefix(1).uppercased()
        let l = lastName.prefix(1).uppercased()
        return "\(f)\(l)"
    }
}

enum LeadStatus: String, CaseIterable, Codable {
    case new = "New"
    case contacted = "Contacted"
    case qualified = "Qualified"
    case closed = "Closed"
    case lost = "Lost"
    
    var color: String {
        switch self {
        case .new:        return "blue"
        case .contacted:  return "orange"
        case .qualified:  return "purple"
        case .closed:     return "green"
        case .lost:       return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .new:        return "star.fill"
        case .contacted:  return "phone.fill"
        case .qualified:  return "checkmark.seal.fill"
        case .closed:     return "trophy.fill"
        case .lost:       return "xmark.circle.fill"
        }
    }
}
