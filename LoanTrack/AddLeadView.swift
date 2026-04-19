import SwiftUI

struct AddLeadView: View {
    @EnvironmentObject var store: LeadStore
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var loanAmount = ""
    @State private var status: LeadStatus = .new
    @State private var notes = ""
    
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    
    var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Info") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Loan Details") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Loan Amount", text: $loanAmount)
                            .keyboardType(.decimalPad)
                    }
                    Picker("Status", selection: $status) {
                        ForEach(LeadStatus.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon)
                                .tag(s)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Lead")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLead()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? tealColor : .secondary)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    func saveLead() {
        let lead = Lead(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            loanAmount: Double(loanAmount) ?? 0,
            status: status,
            notes: notes
        )
        store.add(lead)
        dismiss()
    }
}
