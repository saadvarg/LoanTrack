import SwiftUI

struct AddLeadView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LeadViewModel

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var loanAmount = ""
    @State private var income = ""
    @State private var debt = ""
    @State private var creditScore = ""
    @State private var employmentStatus = "employed"
    @State private var notes = ""
    @State private var isSubmitting = false

    private let employmentOptions = ["employed", "self-employed", "unemployed"]

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

                Section("Financial") {
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
            .navigationTitle("New Lead")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveLead()
                        }
                    }
                    .disabled(isSubmitting || firstName.isEmpty || lastName.isEmpty || email.isEmpty)
                }
            }
        }
    }

    private func saveLead() async {
        isSubmitting = true
        defer { isSubmitting = false }

        let didSave = await viewModel.addLead(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            loanAmount: Double(loanAmount),
            income: Double(income),
            debt: Double(debt),
            creditScore: Int(creditScore),
            employmentStatus: employmentStatus,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if didSave {
            dismiss()
        }
    }
}

#Preview {
    AddLeadView(viewModel: LeadViewModel())
}
