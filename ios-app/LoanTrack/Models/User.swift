//
//  User.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 20/4/2026.
//

import Foundation

struct User: Codable {
    let id: String
    let email: String
    let fullName: String
    let company: String?
    let role: String?
    let createdAt: String?
}
