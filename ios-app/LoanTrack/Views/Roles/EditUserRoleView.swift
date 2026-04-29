//
//  EditUserRoleView.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 26/4/2026.
//

import SwiftUI

struct EditUserRoleView: View {
    @Environment(\.dismiss) var dismiss
    let user: AdminUser
    let onSuccess: () -> Void

    @State private var selectedRole: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)

    let roles: [(value: String, label: String, icon: String, description: String)] = [
        ("agent",      "Agent",       "person.fill",   "Manages own leads"),
        ("viewer",     "Viewer",      "eye.fill",       "Read-only access"),
        ("admin",      "Admin",       "shield.fill",    "Manages team"),
        ("superadmin", "Super Admin", "crown.fill",     "Full system access"),
    ]

    init(user: AdminUser, onSuccess: @escaping () -> Void) {
        self.user = user
        self.onSuccess = onSuccess
        _selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.fullName)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(user.role.capitalized)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }

                Section("Assign New Role") {
                    ForEach(roles, id: \.value) { role in
                        HStack(spacing: 14) {
                            Image(systemName: role.icon)
                                .foregroundColor(tealColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(role.label)
                                    .font(.subheadline.bold())
                                Text(role.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedRole == role.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(tealColor)
                            }
                        }
                        .padding(.vertical, 4)
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
                    }
                }
            }
            .navigationTitle("Edit Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { updateRole() }
                        .fontWeight(.semibold)
                        .foregroundColor(tealColor)
                        .disabled(selectedRole == user.role || isLoading)
                }
            }
        }
    }

    func updateRole() {
        isLoading = true
        Task {
            do {
                try await APIService.shared.adminUpdateUserRole(
                    userId: user.id,
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
