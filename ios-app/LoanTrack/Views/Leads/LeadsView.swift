import SwiftUI

struct LeadsView: View {
    @StateObject private var viewModel = LeadViewModel()
    @State private var showingAddLead = false
    @State private var searchText = ""
    @State private var selectedStatus = "all"
    @State private var selectedSort = LeadSortOption.newestFirst
    @State private var displayMode = LeadsDisplayMode.list

    private let statusOptions = ["all", "new", "contacted", "qualified", "closed", "lost"]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.leads.isEmpty {
                    ProgressView("Loading Leads...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredLeads.isEmpty {
                    ContentUnavailableView(
                        "No Matching Leads",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(emptyStateMessage)
                    )
                } else {
                    if displayMode == .list {
                        List(filteredLeads) { lead in
                            NavigationLink(destination: LeadDetailView(lead: lead, viewModel: viewModel)) {
                                LeadRowView(lead: lead)
                            }
                        }
                        .refreshable {
                            await viewModel.loadLeads()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                pipelineBoard
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.loadLeads()
                        }
                    }
                }
            }
            .navigationTitle("Leads")
            .searchable(text: $searchText, prompt: "Search by name or email")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Picker("View", selection: $displayMode) {
                        ForEach(LeadsDisplayMode.allCases) { mode in
                            Image(systemName: mode.iconName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Menu {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(statusOptions, id: \.self) { status in
                                Text(status.capitalized).tag(status)
                            }
                        }

                        Picker("Sort", selection: $selectedSort) {
                            ForEach(LeadSortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        showingAddLead = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLead) {
                AddLeadView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadLeads()
            }
        }
    }

    private var filteredLeads: [Lead] {
        let filtered = viewModel.leads.filter { lead in
            let matchesSearch =
                searchText.isEmpty ||
                lead.fullName.localizedCaseInsensitiveContains(searchText) ||
                lead.email.localizedCaseInsensitiveContains(searchText)

            let matchesStatus =
                selectedStatus == "all" ||
                lead.status.lowercased() == selectedStatus.lowercased()

            return matchesSearch && matchesStatus
        }

        switch selectedSort {
        case .newestFirst:
            return filtered
        case .highestLoan:
            return filtered.sorted { ($0.loanAmount ?? 0) > ($1.loanAmount ?? 0) }
        case .highestRisk:
            return filtered.sorted { ($0.riskScore ?? -1) > ($1.riskScore ?? -1) }
        case .name:
            return filtered.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        }
    }

    private var emptyStateMessage: String {
        if let errorMessage = viewModel.errorMessage {
            return errorMessage
        }
        if !searchText.isEmpty {
            return "Try a different search term."
        }
        if selectedStatus != "all" {
            return "No leads found for the selected status."
        }
        return "Add your first lead to get started."
    }

    private var pipelineBoard: some View {
        ForEach(statusOptions.filter { $0 != "all" }, id: \.self) { status in
            let leadsForStatus = filteredLeads.filter { $0.status.lowercased() == status }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(status.capitalized)
                        .font(.headline)
                    Spacer()
                    Text("\(leadsForStatus.count)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor(for: status).opacity(0.14))
                        .foregroundStyle(statusColor(for: status))
                        .clipShape(Capsule())
                }

                if leadsForStatus.isEmpty {
                    Text("No leads in this stage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(leadsForStatus) { lead in
                        NavigationLink(destination: LeadDetailView(lead: lead, viewModel: viewModel)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lead.fullName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(lead.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    if let loanAmount = lead.loanAmount {
                                        Text(loanAmount.currencyFormatted)
                                    }
                                    if let riskLabel = lead.riskLabel {
                                        Text("• \(riskLabel)")
                                            .foregroundStyle(riskColor(for: riskLabel))
                                    }
                                }
                                .font(.caption2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
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

#Preview {
    LeadsView()
}

private enum LeadSortOption: String, CaseIterable, Identifiable {
    case newestFirst
    case highestLoan
    case highestRisk
    case name

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newestFirst:
            return "Newest"
        case .highestLoan:
            return "Highest Loan"
        case .highestRisk:
            return "Highest Risk"
        case .name:
            return "Name"
        }
    }
}

private enum LeadsDisplayMode: String, CaseIterable, Identifiable {
    case list
    case board

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .list: return "list.bullet"
        case .board: return "square.grid.2x2"
        }
    }
}
