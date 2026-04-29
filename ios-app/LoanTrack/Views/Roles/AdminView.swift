import SwiftUI
import Combine

// ── ADMIN VIEW ───────────────────────────────────────────────────────────────

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var showCreateUser = false
    @State private var selectedUser: AdminUser?
    @State private var selectedTab = 0

    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── PENDING BADGE ────────────────────────────
                if !viewModel.pendingUsers.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.pendingUsers.count) user(s) waiting for approval")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Review") { selectedTab = 1 }
                            .font(.subheadline.bold())
                            .foregroundColor(tealColor)
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.10))
                }

                // ── TAB PICKER ───────────────────────────────
                Picker("Section", selection: $selectedTab) {
                    Text("Team").tag(0)
                    Text("Pending (\(viewModel.pendingUsers.count))").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()

                // ── CONTENT ──────────────────────────────────
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case 0: teamSection
                        case 1: pendingSection
                        case 2: statsSection
                        default: teamSection
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateUser = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(tealColor)
                            .font(.title3)
                    }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showCreateUser) {
                CreateUserView { Task { await viewModel.load() } }
            }
            .sheet(item: $selectedUser) { user in
                EditUserRoleView(user: user) {
                    Task { await viewModel.load() }
                }
            }
        }
    }

    // ── TEAM SECTION ─────────────────────────────────────────────────────────

    @ViewBuilder
    var teamSection: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(40)
        } else if let grouped = viewModel.groupedUsers {
            VStack(spacing: 20) {
                userGroup(title: "Super Admins", icon: "crown.fill",   color: .purple, users: grouped.superadmin)
                userGroup(title: "Admins",       icon: "shield.fill",  color: .blue,   users: grouped.admin)
                userGroup(title: "Agents",       icon: "person.fill",  color: .green,  users: grouped.agent)
                userGroup(title: "Viewers",      icon: "eye.fill",     color: .orange, users: grouped.viewer)
            }
        } else {
            ContentUnavailableView(
                "No Team Data",
                systemImage: "person.3",
                description: Text("Pull down to refresh.")
            )
        }
    }

    func userGroup(title: String, icon: String, color: Color, users: [AdminUser]) -> some View {
        Group {
            if !users.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text(title)
                            .font(.headline)
                            .foregroundColor(navyBlue)
                        Text("(\(users.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    ForEach(users) { user in
                        AdminUserRow(user: user, tealColor: tealColor, navyBlue: navyBlue) {
                            selectedUser = user
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 6)
            }
        }
    }

    // ── PENDING SECTION ──────────────────────────────────────────────────────

    @ViewBuilder
    var pendingSection: some View {
        if viewModel.pendingUsers.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.green)
                Text("No Pending Approvals")
                    .font(.title3.bold())
                Text("All users have been reviewed.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Awaiting Approval")
                    .font(.headline)
                    .foregroundColor(navyBlue)

                ForEach(viewModel.pendingUsers) { user in
                    PendingUserCard(
                        user: user,
                        tealColor: tealColor,
                        onApprove: { role in
                            Task { try? await viewModel.approveUser(userId: user.id, role: role) }
                        },
                        onReject: {
                            Task { try? await viewModel.suspendUser(userId: user.id) }
                        }
                    )
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6)
        }
    }

    // ── STATS SECTION ────────────────────────────────────────────────────────

    @ViewBuilder
    var statsSection: some View {
        if let stats = viewModel.stats {
            VStack(spacing: 16) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12) {
                    AdminStatCard(title: "Team",   value: "\(stats.totalTeamMembers)", icon: "person.3.fill",             color: navyBlue)
                    AdminStatCard(title: "Leads",  value: "\(stats.totalLeads)",       icon: "doc.text.fill",             color: tealColor)
                    AdminStatCard(title: "Closed", value: "\(stats.closedLeads)",      icon: "trophy.fill",               color: .green)
                }

                if !stats.agentStats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Agent Performance")
                            .font(.headline)
                            .foregroundColor(navyBlue)
                        ForEach(stats.agentStats, id: \.userId) { agent in
                            AgentPerformanceRow(agent: agent, tealColor: tealColor)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.04), radius: 6)
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(40)
        }
    }
}

// ── PENDING USER CARD ────────────────────────────────────────────────────────

struct PendingUserCard: View {
    let user: AdminUser
    let tealColor: Color
    let onApprove: (String) -> Void
    let onReject: () -> Void

    @State private var selectedRole = "agent"
    let roles = ["agent", "viewer", "admin", "superadmin"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Text(String(user.fullName.prefix(2)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(user.fullName)
                        .font(.subheadline.bold())
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let company = user.company, !company.isEmpty {
                        Text(company)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("Pending")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Assign Role:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Role", selection: $selectedRole) {
                    ForEach(roles, id: \.self) { role in
                        Text(role.capitalized).tag(role)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 12) {
                Button(action: onReject) {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.10))
                        .cornerRadius(10)
                }
                Button(action: { onApprove(selectedRole) }) {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(tealColor)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
}

// ── ADMIN USER ROW ───────────────────────────────────────────────────────────

struct AdminUserRow: View {
    let user: AdminUser
    let tealColor: Color
    let navyBlue: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(user.roleColor.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: user.roleIcon)
                        .foregroundColor(user.roleColor)
                        .font(.system(size: 16))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(user.fullName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(user.role.capitalized)
                        .font(.caption.bold())
                        .foregroundColor(user.roleColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(user.roleColor.opacity(0.12))
                        .cornerRadius(8)
                    Text(user.status.capitalized)
                        .font(.caption2)
                        .foregroundColor(user.statusColor)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

// ── ADMIN STAT CARD ──────────────────────────────────────────────────────────

struct AdminStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6)
    }
}

// ── AGENT PERFORMANCE ROW ────────────────────────────────────────────────────

struct AgentPerformanceRow: View {
    let agent: AgentStat
    let tealColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.subheadline.bold())
                Text("\(agent.totalLeads) leads · \(agent.closedLeads) closed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(agent.conversionRate, specifier: "%.1f")%")
                    .font(.subheadline.bold())
                    .foregroundColor(tealColor)
                Text("conversion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// ── PREVIEW ──────────────────────────────────────────────────────────────────

#Preview {
    AdminView()
}
