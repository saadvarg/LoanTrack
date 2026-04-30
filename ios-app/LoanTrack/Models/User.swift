import SwiftUI
import Foundation
import Combine

struct User: Decodable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let company: String?
    let role: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case full_name
        case company
        case role
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)

        if let camelCase = try container.decodeIfPresent(String.self, forKey: .fullName) {
            fullName = camelCase
        } else {
            fullName = try container.decode(String.self, forKey: .full_name)
        }

        company = try container.decodeIfPresent(String.self, forKey: .company)
        role = try container.decodeIfPresent(String.self, forKey: .role)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    var roleLabel: String {
        switch role?.lowercased() {
        case "superadmin": return "Super Admin"
        case "admin": return "Admin"
        case "agent": return "Agent"
        case "viewer": return "Viewer"
        default: return "User"
        }
    }

    var roleColor: Color {
        switch role?.lowercased() {
        case "superadmin": return .purple
        case "admin": return .blue
        case "agent": return .green
        case "viewer": return .orange
        default: return .gray
        }
    }

    var roleIcon: String {
        switch role?.lowercased() {
        case "superadmin": return "crown.fill"
        case "admin": return "shield.fill"
        case "agent": return "person.fill"
        case "viewer": return "eye.fill"
        default: return "person.fill"
        }
    }

    var roleBadgeColor: Color { roleColor }
}
