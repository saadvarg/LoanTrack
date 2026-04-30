//
//  ProfileView.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 29/4/2026.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionViewModel
    
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if let user = session.currentUser {
                        
                        // ── PROFILE CARD ─────────────────────────
                        VStack(spacing: 16) {
                            
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(user.roleColor.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                Text(String(user.fullName.prefix(2)).uppercased())
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(user.roleColor)
                            }
                            
                            // Name + Email
                            VStack(spacing: 4) {
                                Text(user.fullName)
                                    .font(.title2.bold())
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // ── ROLE BADGE ────────────────────────
                            HStack(spacing: 8) {
                                Image(systemName: user.roleIcon)
                                    .font(.system(size: 14))
                                Text(user.roleLabel)
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(user.roleColor)
                            .clipShape(Capsule())
                            
                            // Role description
                            Text(roleDescription(for : user.role ?? "viewer"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 8)
                        
                        // ── ACCOUNT INFO ──────────────────────────
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Account")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                            
                            ProfileRow(
                                icon: "person.fill",
                                color: tealColor,
                                label: "Full Name",
                                value: user.fullName
                            )
                            Divider().padding(.leading, 56)
                            ProfileRow(
                                icon: "envelope.fill",
                                color: .blue,
                                label: "Email",
                                value: user.email
                            )
                            Divider().padding(.leading, 56)
                            ProfileRow(
                                icon: "building.2.fill",
                                color: .orange,
                                label: "Company",
                                value: user.company ?? "—"
                            )
                            Divider().padding(.leading, 56)
                            ProfileRow(
                                icon: user.roleIcon,
                                color: user.roleColor,
                                label: "Role",
                                value: user.roleLabel
                            )
                            Divider().padding(.leading, 56)
                            ProfileRow(
                                icon: "checkmark.shield.fill",
                                color: .green,
                                label: "Status",
                                value: (user.status ?? "active").capitalized
                            )
                        }
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 8)
                        
                        // ── PERMISSIONS ───────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Permissions")
                                .font(.headline)
                            
                            PermissionRow(
                                label: "View Leads",
                                allowed: true
                            )
                            PermissionRow(
                                label: "Create & Edit Leads",
                                allowed: user.role != "viewer"
                            )
                            PermissionRow(
                                label: "Delete Leads",
                                allowed: user.role != "viewer"
                            )
                            PermissionRow(
                                label: "View All Team Leads",
                                allowed: user.role == "admin" || user.role == "superadmin"
                            )
                            PermissionRow(
                                label: "Manage Team Members",
                                allowed: user.role == "admin" || user.role == "superadmin"
                            )
                            PermissionRow(
                                label: "Approve New Users",
                                allowed: user.role == "admin" || user.role == "superadmin"
                            )
                            PermissionRow(
                                label: "Full System Access",
                                allowed: user.role == "superadmin"
                            )
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 8)
                        
                        // ── LOGOUT ────────────────────────────────
                        Button(action: { session.logout() }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(14)
                        }
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    func roleDescription(for role: String) -> String {
        switch role {
        case "superadmin": return "You have full system access including all users, leads, and settings."
        case "admin":      return "You can manage your team members, approve users, and view all team leads."
        case "agent":      return "You can create and manage your own leads and pipeline."
        case "viewer":     return "You have read-only access to view leads and analytics."
        default:           return ""
        }
    }
}

// ── PROFILE ROW ──────────────────────────────────────────────────────────────

struct ProfileRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// ── PERMISSION ROW ───────────────────────────────────────────────────────────

struct PermissionRow: View {
    let label: String
    let allowed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(allowed ? .green : .red.opacity(0.4))
            Text(label)
                .font(.subheadline)
                .foregroundColor(allowed ? .primary : .secondary)
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionViewModel())
}
