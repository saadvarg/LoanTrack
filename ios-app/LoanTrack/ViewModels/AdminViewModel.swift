//
//  AdminViewModel.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 26/4/2026.
//

import Foundation
import SwiftUI
import Combine

struct AdminUser: Identifiable, Codable {
    let id: String
    let email: String
    let fullName: String
    let role: String
    let status: String
    let company: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, role, status, company
        case fullName = "full_name"
        case createdAt = "created_at"
    }

    var statusColor: Color {
        switch status {
        case "active":    return .green
        case "pending":   return .orange
        case "suspended": return .red
        default:          return .gray
        }
    }

    var roleColor: Color {
        switch role {
        case "superadmin": return .purple
        case "admin":      return .blue
        case "agent":      return .green
        case "viewer":     return .orange
        default:           return .gray
        }
    }

    var roleIcon: String {
        switch role {
        case "superadmin": return "crown.fill"
        case "admin":      return "shield.fill"
        case "agent":      return "person.fill"
        case "viewer":     return "eye.fill"
        default:           return "person.fill"
        }
    }
}

struct AdminStats: Codable {
    let totalTeamMembers: Int
    let totalLeads: Int
    let closedLeads: Int
    let totalPipeline: Double
    let conversionRate: Double
    let agentStats: [AgentStat]
}

struct AgentStat: Codable {
    let userId: String
    let name: String
    let role: String
    let totalLeads: Int
    let closedLeads: Int
    let pipelineValue: Double
    let conversionRate: Double
}

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var users: [AdminUser] = []
    @Published var pendingUsers: [AdminUser] = []
    @Published var groupedUsers: GroupedUsers?
    @Published var stats: AdminStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let allTask   = APIService.shared.adminFetchAllUsers()
            async let statsTask = APIService.shared.adminFetchStats()
            let (all, fetchedStats) = try await (allTask, statsTask)
            users        = all.data
            pendingUsers = all.grouped.pending
            groupedUsers = all.grouped
            stats        = fetchedStats
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approveUser(userId: String, role: String) async throws {
        try await APIService.shared.adminApproveUser(userId: userId, role: role)
        await load()
    }

    func suspendUser(userId: String) async throws {
        try await APIService.shared.adminSuspendUser(userId: userId)
        await load()
    }

    func updateRole(userId: String, role: String) async throws {
        try await APIService.shared.adminUpdateUserRole(userId: userId, role: role)
        await load()
    }
}

struct GroupedUsers: Codable {
    let superadmin: [AdminUser]
    let admin: [AdminUser]
    let agent: [AdminUser]
    let viewer: [AdminUser]
    let pending: [AdminUser]
}

struct AllUsersEnvelope: Codable {
    let success: Bool
    let total: Int
    let grouped: GroupedUsers
    let data: [AdminUser]
}
