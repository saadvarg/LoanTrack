import SwiftUI

struct EditLeadView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: LeadViewModel
    let lead: Lead
    let onSave: (Lead) -> Void

    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var loanAmount: String
    @State private var income: String
    @State private var debt: String
    @State private var creditScore: String
    @State private var employmentStatus: String
    @State private var notes: String
    @State private var status: String
    @State private var isSubmitting = false

    private let employmentOptions = ["employed", "self-employed", "unemployed"]
    private let statusOptions = ["new", "contacted", "qualified", "closed", "lost"]

    init(viewModel: LeadViewModel, lead: Lead, onSave: @escaping (Lead) -> Void) {
        self.viewModel = viewModel
        self.lead = lead
        self.onSave = onSave
        _firstName = State(initialValue: lead.firstName)
        _lastName = State(initialValue: lead.lastName)
        _email = State(initialValue: lead.email)
        _phone = State(initialValue: lead.phone ?? "")
        _loanAmount = State(initialValue: lead.loanAmount.map { String($0) } ?? "")
        _income = State(initialValue: lead.income.map { String($0) } ?? "")
        _debt = State(initialValue: lead.debt.map { String($0) } ?? "")
        _creditScore = State(initialValue: lead.creditScore.map { String($0) } ?? "")
        _employmentStatus = State(initialValue: lead.employmentStatus ?? "employed")
        _notes = State(initialValue: lead.notes ?? "")
        _status = State(initialValue: lead.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Lead Details") {
                    TextField("Loan Amount", text: $loanAmount)
                        .keyboardType(.decimalPad)
                    TextField("Income", text: $income)
                        .keyboardType(.decimalPad)
                    TextField("Debt", text: $debt)
                        .keyboardType(.decimalPad)
                    TextField("Credit Score", text: $creditScore)
                        .keyboardType(.numberPad)

                    Picker("Employment Status", selection: $employmentStatus) {
                        ForEach(employmentOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(statusOptions, id: \.self) { option in
                            Text(option.capitalized).tag(option)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit Lead")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSubmitting || firstName.isEmpty || lastName.isEmpty || email.isEmpty)
                }
            }
        }
    }

    private func saveChanges() async {
        isSubmitting = true
        defer { isSubmitting = false }

        var updatedLead = lead
        updatedLead.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedLead.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedLead.email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedLead.phone = trimmedPhone.isEmpty ? nil : trimmedPhone

        updatedLead.loanAmount = Double(loanAmount)
        updatedLead.income = Double(income)
        updatedLead.debt = Double(debt)
        updatedLead.creditScore = Int(creditScore)
        updatedLead.employmentStatus = employmentStatus

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedLead.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        updatedLead.status = status

        let didSave = await viewModel.updateLead(updatedLead)
        if didSave {
            onSave(updatedLead)
            dismiss()
        }
    }
}

#Preview {
    EditLeadView(
        viewModel: LeadViewModel(),
        lead: Lead(
            id: "1",
            userId: nil,
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah@example.com",
            phone: "555",
            loanAmount: 350000,
            status: "new",
            notes: nil,
            income: 90000,
            debt: 15000,
            creditScore: 710,
            riskScore: nil,
            riskLabel: nil,
            dateAdded: nil,
            updatedAt: nil,
            employmentStatus: "employed"
        ),
        onSave: { _ in }
    )
}
