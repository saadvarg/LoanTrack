import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: SessionViewModel

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var company = ""
    @State private var selectedRole = "agent"
    @State private var isLoading = false
    @State private var errorMessage: String?

    let navyBlue = Color(red: 0.04, green: 0.15, blue: 0.27)
    let tealColor = Color(red: 0.05, green: 0.45, blue: 0.47)

    let availableRoles: [(value: String, label: String, icon: String, description: String)] = [
        ("agent",  "Agent",  "person.fill",         "Manage your own leads and pipeline"),
        ("viewer", "Viewer", "eye.fill",             "Read-only access to view leads"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── HEADER ───────────────────────────────────
                    VStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 48))
                            .foregroundColor(tealColor)
                        Text("Create Account")
                            .font(.title.bold())
                            .foregroundColor(navyBlue)
                        Text("Join LoanTrack to manage your pipeline")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // ── PERSONAL INFO ─────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)
                            .foregroundColor(navyBlue)

                        RegisterField(
                            icon: "person.fill",
                            placeholder: "Full Name",
                            text: $fullName
                        )
                        RegisterField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        RegisterField(
                            icon: "lock.fill",
                            placeholder: "Password (min 6 chars)",
                            text: $password,
                            isSecure: true
                        )
                        RegisterField(
                            icon: "building.2.fill",
                            placeholder: "Company (optional)",
                            text: $company
                        )
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8)

                    // ── ROLE SELECTION ────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Type")
                            .font(.headline)
                            .foregroundColor(navyBlue)

                        Text("Select your role. Admins can upgrade your access later.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(availableRoles, id: \.value) { role in
                            RoleCard(
                                role: role,
                                isSelected: selectedRole == role.value,
                                tealColor: tealColor,
                                navyBlue: navyBlue
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedRole = role.value
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8)

                    // ── ERROR ─────────────────────────────────────
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                    }

                    // ── REGISTER BUTTON ───────────────────────────
                    Button(action: register) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? tealColor : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(!isFormValid || isLoading)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && password.count >= 6
    }

    func register() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await session.register(
                    fullName: fullName,
                    email: email,
                    password: password,
                    company: company.isEmpty ? nil : company,
                    role: selectedRole
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// ── ROLE CARD ────────────────────────────────────────────────────────────────

struct RoleCard: View {
    let role: (value: String, label: String, icon: String, description: String)
    let isSelected: Bool
    let tealColor: Color
    let navyBlue: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tealColor : Color(.systemGray5))
                        .frame(width: 44, height: 44)
                    Image(systemName: role.icon)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(role.label)
                        .font(.subheadline.bold())
                        .foregroundColor(isSelected ? navyBlue : .primary)
                    Text(role.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? tealColor : .secondary)
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected
                        ? tealColor.opacity(0.08)
                        : Color(.systemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? tealColor : Color(.systemGray4),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// ── REGISTER FIELD ───────────────────────────────────────────────────────────

struct RegisterField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RegisterView()
        .environmentObject(SessionViewModel())
}
