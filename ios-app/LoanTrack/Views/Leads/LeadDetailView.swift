import SwiftUI
import UIKit

struct LeadDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
        let navyBlue  = Color(red: 0.04, green: 0.15, blue: 0.27)

    @ObservedObject var viewModel: LeadViewModel
    @State private var lead: Lead
    @State private var showingEditLead = false
    @State private var isDeleting = false
    @State private var isScoring = false
    @State private var showingDeleteConfirmation = false
    @State private var completedTaskIDs: Set<String> = []
    @State private var reminderText = ""
    @State private var reminderDate = Date()
    @State private var showPDF = false
    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false

    init(lead: Lead, viewModel: LeadViewModel) {
        self.viewModel = viewModel
        _lead = State(initialValue: lead)
    }

    var body: some View {
        List {
            Section("Overview") {
                Text("Name: \(lead.fullName)")
                Text("Email: \(lead.email)")
                Text("Phone: \(lead.phone ?? "Not provided")")
                Text("Status: \(lead.status.capitalized)")
            }

            Section("Financials") {
                if let loanAmount = lead.loanAmount {
                    Text("Loan Amount: \(loanAmount.currencyFormatted)")
                }
                if let income = lead.income {
                    Text("Income: \(income.currencyFormatted)")
                }
                if let debt = lead.debt {
                    Text("Debt: \(debt.currencyFormatted)")
                }
                if let creditScore = lead.creditScore {
                    Text("Credit Score: \(creditScore)")
                }
                if let employmentStatus = lead.employmentStatus {
                    Text("Employment: \(employmentStatus.capitalized)")
                }
            }

            Section("Missing Docs Checklist") {
                ForEach(missingChecklistItems, id: \.self) { item in
                    Label(item, systemImage: "doc.badge.plus")
                        .foregroundStyle(.secondary)
                }
            }

            if let notes = lead.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section("Follow-Up Reminder") {
                TextField("Reminder note", text: $reminderText)
                DatePicker("When", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])

                Button("Save Reminder") {
                    saveReminder()
                }

                if let savedReminder = savedReminderSummary {
                    Text(savedReminder)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Activity Timeline") {
                if viewModel.leadActivities.isEmpty {
                    Text("No activity yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.leadActivities) { activity in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.action)
                                .font(.subheadline.weight(.semibold))

                            if let note = activity.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let createdAt = activity.createdAt {
                                Text(createdAt)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Smart Action Queue") {
                if automationTasks.isEmpty {
                    Text("Score this lead or add more profile details to generate action items.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(automationTasks) { task in
                        Button {
                            toggleTask(task.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: completedTaskIDs.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(completedTaskIDs.contains(task.id) ? Color.green : Color.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .foregroundStyle(.primary)
                                        .strikethrough(completedTaskIDs.contains(task.id))
                                    Text(task.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(task.priority)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(priorityBadgeColor(task.priority).opacity(0.16))
                                    .foregroundStyle(priorityBadgeColor(task.priority))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let riskLabel = lead.riskLabel, let riskScore = lead.riskScore {
                Section("Risk Score") {
                    Text("Score: \(Int(riskScore))/100")
                    Text("Label: \(riskLabel)")
                        .foregroundStyle(riskColor(for: riskLabel))
                }
            }

            if let scoringResult = viewModel.lastScoringResult, scoringResult.leadId == lead.id {
                Section("AI Assistant") {
                    aiSummaryCard(for: scoringResult)
                    aiNextStepCard(for: scoringResult)
                    aiFollowUpCard(for: scoringResult)
                    communicationCenter(for: scoringResult)
                    aiBreakdownCard(for: scoringResult)
                }
            } else {
                Section("AI Assistant") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Run scoring to unlock smart recommendations, suggested next steps, and a ready-to-use follow-up message.")
                            .foregroundStyle(.secondary)

                        Button("Generate AI Insights") {
                            Task {
                                await scoreLead()
                            }
                        }
                        .disabled(isScoring)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Lead Details")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Score") {
                    Task {
                        await scoreLead()
                    }
                }
                .disabled(isScoring)

                Button("Edit") {
                    showingEditLead = true
                }
                Button(action: generatePDF) {
                    if isGeneratingPDF {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Export PDF", systemImage: "arrow.down.doc.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(tealColor)
                .disabled(isGeneratingPDF)

                // Add this sheet
                .sheet(isPresented: $showPDF) {
                    if let data = pdfData {
                        PDFViewer(data: data)
                    }
                }


                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .disabled(isDeleting)
            }
        }
        .sheet(isPresented: $showingEditLead) {
            EditLeadView(viewModel: viewModel, lead: lead) { updatedLead in
                lead = updatedLead
            }
        }
        .alert("Delete Lead?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteLead()
                }
            }
        } message: {
            Text("This will permanently remove \(lead.fullName) and cannot be undone.")
        }
        .safeAreaInset(edge: .bottom) {
            if let successMessage = viewModel.successMessage {
                ToastBanner(message: successMessage, tint: .green)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.clearSuccessMessage()
                        }
                    }
            }
        }
        .task {
            await viewModel.loadActivities(for: lead.id)
            loadTaskState()
            loadReminder()
        }
    }
    
    func generatePDF() {
        isGeneratingPDF = true
        Task {
            do {
                let data = try await APIService.shared.downloadLeadPDF(leadId: lead.id)
                await MainActor.run {
                    pdfData = data
                    showPDF = true
                    isGeneratingPDF = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingPDF = false
                }
            }
        }
    }

    private var automationTasks: [LeadAutomationTask] {
        var tasks: [LeadAutomationTask] = []

        if lead.phone == nil || lead.phone?.isEmpty == true {
            tasks.append(
                LeadAutomationTask(
                    id: "collect-phone",
                    title: "Collect primary phone number",
                    detail: "Get a direct phone number so follow-up can move faster.",
                    priority: "Medium"
                )
            )
        }

        if lead.income == nil {
            tasks.append(
                LeadAutomationTask(
                    id: "collect-income",
                    title: "Request proof of income",
                    detail: "Income is missing and blocks accurate qualification and scoring.",
                    priority: "High"
                )
            )
        }

        if lead.creditScore == nil {
            tasks.append(
                LeadAutomationTask(
                    id: "collect-credit-score",
                    title: "Verify credit score",
                    detail: "Credit score is needed to unlock a stronger product recommendation.",
                    priority: "High"
                )
            )
        }

        if lead.riskScore == nil {
            tasks.append(
                LeadAutomationTask(
                    id: "run-ai-score",
                    title: "Run AI lead scoring",
                    detail: "Generate underwriting guidance and next-step recommendations.",
                    priority: "High"
                )
            )
        }

        if lead.status.lowercased() == "new" {
            tasks.append(
                LeadAutomationTask(
                    id: "first-call",
                    title: "Schedule first qualification call",
                    detail: "Reach out while the lead is still fresh.",
                    priority: "Medium"
                )
            )
        }

        if let riskScore = lead.riskScore, riskScore >= 80 {
            tasks.append(
                LeadAutomationTask(
                    id: "fast-track",
                    title: "Fast-track document collection",
                    detail: "This lead looks strong. Move quickly to maintain momentum.",
                    priority: "High"
                )
            )
        }

        if let riskScore = lead.riskScore, riskScore < 60 {
            tasks.append(
                LeadAutomationTask(
                    id: "improvement-plan",
                    title: "Prepare improvement plan",
                    detail: "Review debt, score, and affordability constraints before next call.",
                    priority: "High"
                )
            )
        }

        return tasks
    }

    private var missingChecklistItems: [String] {
        var items: [String] = []
        if lead.income == nil { items.append("Proof of income") }
        if lead.creditScore == nil { items.append("Credit score verification") }
        if lead.debt == nil { items.append("Debt obligations summary") }
        if lead.loanAmount == nil { items.append("Target loan amount") }
        if lead.phone == nil || lead.phone?.isEmpty == true { items.append("Primary phone number") }
        if lead.employmentStatus == nil { items.append("Employment status confirmation") }
        return items.isEmpty ? ["No critical documents missing"] : items
    }

    private func aiSummaryCard(for scoringResult: LeadScoringResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(priorityLabel(for: scoringResult.score))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(priorityColor(for: scoringResult.score).opacity(0.16))
                    .foregroundStyle(priorityColor(for: scoringResult.score))
                    .clipShape(Capsule())

                Spacer()

                Text("\(scoringResult.score)/100")
                    .font(.headline)
            }

            Text(scoringResult.recommendation)
                .font(.subheadline)

            Divider()

            Text("Recommended Product: \(scoringResult.loanRecommendation.type)")
                .font(.subheadline.weight(.semibold))

            Text(scoringResult.loanRecommendation.reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Suggested Rate: \(scoringResult.loanRecommendation.suggestedRate)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func aiNextStepCard(for scoringResult: LeadScoringResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next Best Action")
                .font(.headline)

            Text(nextStepText(for: scoringResult))
                .font(.subheadline)

            if !scoringResult.flags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Watchouts")
                        .font(.subheadline.weight(.semibold))

                    ForEach(scoringResult.flags, id: \.self) { flag in
                        Text("• \(flag)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func aiFollowUpCard(for scoringResult: LeadScoringResult) -> some View {
        let draft = followUpMessage(for: scoringResult)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Follow-Up Draft")
                    .font(.headline)
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = draft
                }
                .font(.caption.weight(.semibold))
            }

            Text(draft)
                .font(.subheadline)
                .textSelection(.enabled)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.vertical, 4)
    }

    private func communicationCenter(for scoringResult: LeadScoringResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Communication Center")
                .font(.headline)

            CommunicationDraftCard(
                title: "Email Draft",
                content: emailDraft(for: scoringResult)
            )

            CommunicationDraftCard(
                title: "SMS Draft",
                content: followUpMessage(for: scoringResult)
            )

            CommunicationDraftCard(
                title: "Call Prep",
                content: callPrep(for: scoringResult)
            )
        }
        .padding(.vertical, 4)
    }

    private func aiBreakdownCard(for scoringResult: LeadScoringResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Underwriting Breakdown")
                .font(.headline)

            ForEach(scoringResult.breakdown) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.factor)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("+\(item.points)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteLead() async {
        isDeleting = true
        defer { isDeleting = false }

        let didDelete = await viewModel.deleteLead(id: lead.id)
        if didDelete {
            dismiss()
        }
    }

    private func scoreLead() async {
        isScoring = true
        defer { isScoring = false }

        let didScore = await viewModel.scoreLead(lead)
        guard didScore, let scoringResult = viewModel.lastScoringResult else { return }

        lead.riskScore = Double(scoringResult.score)
        lead.riskLabel = scoringResult.riskLabel
        await viewModel.loadActivities(for: lead.id)
    }

    private func emailDraft(for scoringResult: LeadScoringResult) -> String {
        """
        Subject: Next steps for your mortgage options

        Hi \(lead.firstName),

        I reviewed your profile and based on the information we have so far, \(scoringResult.loanRecommendation.type) looks like the most relevant option to discuss next.

        \(scoringResult.recommendation)

        I’d like to walk you through the next steps, answer questions, and confirm the documents we still need.

        Best,
        \(lead.firstName)'s Loan Advisor
        """
    }

    private func callPrep(for scoringResult: LeadScoringResult) -> String {
        let watchouts = scoringResult.flags.prefix(3).joined(separator: "\n• ")
        let flagBlock = watchouts.isEmpty ? "• Confirm timeline, goals, and target monthly payment." : "• \(watchouts)"

        return """
        1. Confirm borrowing timeline and purchase/refinance goal.
        2. Position \(scoringResult.loanRecommendation.type) as the current best-fit product.
        3. Review key watchouts:
        \(flagBlock)
        4. Ask for missing documents and set the next follow-up date.
        """
    }

    private func loadTaskState() {
        let saved = UserDefaults.standard.stringArray(forKey: taskStorageKey) ?? []
        completedTaskIDs = Set(saved)
    }

    private func toggleTask(_ id: String) {
        if completedTaskIDs.contains(id) {
            completedTaskIDs.remove(id)
        } else {
            completedTaskIDs.insert(id)
        }
        UserDefaults.standard.set(Array(completedTaskIDs), forKey: taskStorageKey)
    }

    private var taskStorageKey: String {
        "loantrack.tasks.\(lead.id)"
    }

    private var reminderStorageKey: String {
        "loantrack.reminder.\(lead.id)"
    }

    private var savedReminderSummary: String? {
        let saved = UserDefaults.standard.dictionary(forKey: reminderStorageKey)
        guard
            let note = saved?["note"] as? String,
            let timestamp = saved?["date"] as? TimeInterval
        else {
            return nil
        }

        let date = Date(timeIntervalSince1970: timestamp)
        return "\(note) • \(date.formatted(date: .abbreviated, time: .shortened))"
    }

    private func saveReminder() {
        let note = reminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }

        UserDefaults.standard.set(
            [
                "note": note,
                "date": reminderDate.timeIntervalSince1970
            ],
            forKey: reminderStorageKey
        )

        viewModel.successMessage = "Reminder saved."
    }

    private func loadReminder() {
        guard
            let saved = UserDefaults.standard.dictionary(forKey: reminderStorageKey),
            let note = saved["note"] as? String,
            let timestamp = saved["date"] as? TimeInterval
        else {
            return
        }

        reminderText = note
        reminderDate = Date(timeIntervalSince1970: timestamp)
    }

    private func priorityLabel(for score: Int) -> String {
        switch score {
        case 80...: return "High Priority"
        case 60...79: return "Review Soon"
        case 40...59: return "Needs Attention"
        default: return "High Risk"
        }
    }

    private func priorityColor(for score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 60...79: return .orange
        default: return .red
        }
    }

    private func nextStepText(for scoringResult: LeadScoringResult) -> String {
        switch scoringResult.score {
        case 80...:
            return "Call this lead today, confirm documents, and move them toward application intake immediately."
        case 60...79:
            return "Schedule a qualification call and focus on the flagged items before presenting final loan options."
        case 40...59:
            return "Review affordability constraints with the lead and position a safer product or improvement path."
        default:
            return "Do a credit and affordability coaching conversation before pushing toward a formal mortgage application."
        }
    }

    private func followUpMessage(for scoringResult: LeadScoringResult) -> String {
        let firstName = lead.firstName
        let product = scoringResult.loanRecommendation.type

        switch scoringResult.score {
        case 80...:
            return "Hi \(firstName), I reviewed your profile and you look like a strong fit for \(product). I'd like to walk you through the next steps and the documents we need so we can move quickly. Let me know a good time today or tomorrow for a short call."
        case 60...79:
            return "Hi \(firstName), I reviewed your profile and there are some solid options available, especially around \(product). I'd like to go over a few details with you and talk through the next best step. Let me know when you're available for a quick call."
        case 40...59:
            return "Hi \(firstName), I reviewed your profile and I think we should talk through the best mortgage path carefully before moving forward. There are a few areas we can improve or work around, and I can help outline the best option for you. Let me know when you're free for a quick call."
        default:
            return "Hi \(firstName), I reviewed your profile and before we move into standard mortgage options, I'd like to help you assess the strongest path forward. There are a few areas we should improve first, and I can walk you through practical next steps. Let me know a good time to connect."
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

    private func priorityBadgeColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
}

private struct ToastBanner: View {
    let message: String
    let tint: Color

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CommunicationDraftCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = content
                }
                .font(.caption.weight(.semibold))
            }

            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct LeadAutomationTask: Identifiable {
    let id: String
    let title: String
    let detail: String
    let priority: String
}

#Preview {
    NavigationStack {
        LeadDetailView(
            lead: Lead(
                id: "1",
                userId: nil,
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah@example.com",
                phone: "555",
                loanAmount: 350000,
                status: "new",
                notes: "Interested in a quick closing timeline.",
                income: 90000,
                debt: 15000,
                creditScore: 710,
                riskScore: nil,
                riskLabel: nil,
                dateAdded: nil,
                updatedAt: nil,
                employmentStatus: "employed"
            ),
            viewModel: LeadViewModel()
        )
    }
}
