//
//  CreateUserView.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 26/4/2026.
//

import SwiftUI

struct CreateUserView: View {
    @Environment(\.dismiss) var dismiss
    let onSuccess: () -> Void

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = "LoanTrack123!"
    @State private var selectedRole = "agent"
    @State private var isLoading = false
    @State private var errorMessage: String?

    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)
    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)

    let roles: [(value: String, label: String, icon: String)] = [
        ("agent",      "Agent",       "person.fill"),
        ("viewer",     "Viewer",      "eye.fill"),
        ("admin",      "Admin",       "shield.fill"),
        ("superadmin", "Super Admin", "crown.fill"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("User Info") {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                        TextField("Full Name", text: $fullName)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.secondary)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        TextField("Temporary Password", text: $password)
                    }
                }

                Section("Role") {
                    ForEach(roles, id: \.value) { role in
                        HStack {
                            Image(systemName: role.icon)
                                .foregroundColor(tealColor)
                                .frame(width: 24)
                            Text(role.label)
                            Spacer()
                            if selectedRole == role.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(tealColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRole = role.value
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Create User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createUser() }
                        .fontWeight(.semibold)
                        .foregroundColor(tealColor)
                        .disabled(fullName.isEmpty || email.isEmpty || isLoading)
                }
            }
        }
    }

    func createUser() {
        isLoading = true
        Task {
            do {
                try await APIService.shared.adminCreateUser(
                    fullName: fullName,
                    email: email,
                    password: password,
                    role: selectedRole
                )
                onSuccess()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
