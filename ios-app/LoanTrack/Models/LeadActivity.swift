//
//  LeadActivity.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 22/4/2026.
//

import Foundation

struct LeadActivity: Codable, Identifiable {
    let id: String
    let leadId: String
    let userId: String
    let action: String
    let note: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case leadId = "lead_id"
        case userId = "user_id"
        case action
        case note
        case createdAt = "created_at"
    }
}
