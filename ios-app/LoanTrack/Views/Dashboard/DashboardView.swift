import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var session: SessionViewModel
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        TabView {
            dashboardContent
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }

            LeadsView()
                .tabItem {
                    Label("Leads", systemImage: "person.3")
                }

            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "number")
                }

            // Only show for admin and superadmin
            if viewModel.userRole == "admin" || viewModel.userRole == "superadmin" {
                AdminView()
                    .tabItem {
                        Label("Admin", systemImage: "shield.fill")
                    }
            }
        }
    }

    private var dashboardContent: some View {
        NavigationStack {
            Group {
                if let metrics = viewModel.metrics {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let user = session.currentUser {
                                dashboardHeader(for: user)
                            }

                            metricGrid(for: metrics)
                            prioritySection(for: metrics.recentLeads)
                            pipelineSection(for: metrics)
                            statusSection(for: metrics.byStatus)
                            chartsSection(for: metrics)
                            recentLeadsSection(for: metrics.recentLeads)
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadDashboard()
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Dashboard Unavailable",
                        systemImage: "chart.bar.xaxis",
                        description: Text(errorMessage)
                    )
                } else if viewModel.isLoading {
                    ProgressView("Loading Dashboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        "No Dashboard Data",
                        systemImage: "chart.bar.doc.horizontal",
                        description: Text("Create or score a few leads to unlock analytics.")
                    )
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                Button("Logout") {
                    session.logout()
                }
            }
            .task {
                await viewModel.loadDashboard()
            }
            .onReceive(NotificationCenter.default.publisher(for: .leadDataDidChange)) { _ in
                Task {
                    await viewModel.loadDashboard()
                }
            }
        }
    }

    private func dashboardHeader(for user: User) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(user.fullName)
                .font(.largeTitle.bold())
            Text(user.email)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.cyan.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func metricGrid(for metrics: DashboardMetrics) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardMetricCard(title: "Total Leads", value: "\(metrics.totalLeads)", tint: .blue)
            DashboardMetricCard(title: "Pipeline Value", value: metrics.totalPipelineValue.currencyFormatted, tint: .green)
            DashboardMetricCard(title: "Avg Loan", value: metrics.avgLoanValue.currencyFormatted, tint: .orange)
            DashboardMetricCard(title: "Conversion", value: String(format: "%.1f%%", metrics.conversionRate), tint: .purple)
        }
    }

    private func prioritySection(for leads: [RecentLead]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Priorities")
                .font(.headline)

            if topPriorityLeads(from: leads).isEmpty {
                Text("Score more leads to generate a smarter priority queue.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(topPriorityLeads(from: leads)) { lead in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(lead.firstName) \(lead.lastName)")
                                .font(.subheadline.weight(.semibold))
                            Text(priorityReason(for: lead))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let riskLabel = lead.riskLabel {
                            Text(riskLabel)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(riskColor(for: riskLabel).opacity(0.16))
                                .foregroundStyle(riskColor(for: riskLabel))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func pipelineSection(for metrics: DashboardMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pipeline Health")
                .font(.headline)
            DashboardInfoRow(label: "Closed Value", value: metrics.closedValue.currencyFormatted)
            DashboardInfoRow(label: "Average Risk Score", value: metrics.avgRiskScore.map { String(format: "%.1f / 100", $0) } ?? "Not scored yet")
            DashboardInfoRow(label: "Qualified Leads", value: "\(metrics.byStatus.qualified)")
            DashboardInfoRow(label: "Closed Leads", value: "\(metrics.byStatus.closed)")
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusSection(for status: LeadStatusSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lead Status")
                .font(.headline)
            DashboardStatusBar(label: "New", count: status.new, color: .blue)
            DashboardStatusBar(label: "Contacted", count: status.contacted, color: .orange)
            DashboardStatusBar(label: "Qualified", count: status.qualified, color: .green)
            DashboardStatusBar(label: "Closed", count: status.closed, color: .mint)
            DashboardStatusBar(label: "Lost", count: status.lost, color: .red)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func chartsSection(for metrics: DashboardMetrics) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Analytics")
                .font(.headline)

            Chart(statusChartData(for: metrics.byStatus)) { item in
                BarMark(
                    x: .value("Status", item.label),
                    y: .value("Count", item.value)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(6)
            }
            .frame(height: 180)

            Chart(riskGaugeData(for: metrics)) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.62),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 220)
            .chartLegend(position: .bottom)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func recentLeadsSection(for leads: [RecentLead]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Leads")
                .font(.headline)

            if leads.isEmpty {
                Text("No leads yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(leads) { lead in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(lead.firstName) \(lead.lastName)")
                                .font(.headline)
                            Spacer()
                            Text(lead.status.capitalized)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(statusColor(for: lead.status).opacity(0.16))
                                .foregroundStyle(statusColor(for: lead.status))
                                .clipShape(Capsule())
                        }

                        Text(lead.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(lead.loanAmount.currencyFormatted)
                            if let riskLabel = lead.riskLabel {
                                Text("• \(riskLabel)")
                                    .foregroundStyle(riskColor(for: riskLabel))
                            }
                        }
                        .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func topPriorityLeads(from leads: [RecentLead]) -> [RecentLead] {
        leads
            .sorted { left, right in
                priorityScore(for: left) > priorityScore(for: right)
            }
            .prefix(3)
            .map { $0 }
    }

    private func priorityScore(for lead: RecentLead) -> Double {
        let risk = lead.riskScore ?? 50
        let loanValue = (lead.loanAmount / 10000)
        let qualifiedBoost = lead.status.lowercased() == "qualified" ? 25.0 : 0
        let closedPenalty = lead.status.lowercased() == "closed" ? -100.0 : 0
        return risk + loanValue + qualifiedBoost + closedPenalty
    }

    private func priorityReason(for lead: RecentLead) -> String {
        if let riskLabel = lead.riskLabel {
            return "\(riskLabel) • \(lead.loanAmount.currencyFormatted) opportunity"
        }
        return "Needs scoring to unlock AI prioritization"
    }

    private func statusChartData(for status: LeadStatusSummary) -> [DashboardChartItem] {
        [
            DashboardChartItem(label: "New", value: Double(status.new), color: .blue),
            DashboardChartItem(label: "Contacted", value: Double(status.contacted), color: .orange),
            DashboardChartItem(label: "Qualified", value: Double(status.qualified), color: .green),
            DashboardChartItem(label: "Closed", value: Double(status.closed), color: .mint),
            DashboardChartItem(label: "Lost", value: Double(status.lost), color: .red)
        ]
    }

    private func riskGaugeData(for metrics: DashboardMetrics) -> [DashboardChartItem] {
        let score = metrics.avgRiskScore ?? 0
        let remaining = max(0, 100 - score)
        return [
            DashboardChartItem(label: "Avg Risk Score", value: score, color: .purple),
            DashboardChartItem(label: "Remaining", value: remaining, color: .gray.opacity(0.2))
        ]
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "new": return .blue
        case "contacted": return .orange
        case "qualified": return .green
        case "closed": return .mint
        case "lost": return .red
        default: return .secondary
        }
    }

    private func riskColor(for label: String) -> Color {
        switch label.lowercased() {
        case "low risk": return .green
        case "moderate risk": return .orange
        case "high risk", "very high risk": return .red
        default: return .secondary
        }
    }
}

private struct DashboardChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

#Preview {
    DashboardView()
        .environmentObject(SessionViewModel())
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DashboardInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

private struct DashboardStatusBar: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.14))
                .foregroundStyle(color)
                .clipShape(Capsule())
        }
    }
}
