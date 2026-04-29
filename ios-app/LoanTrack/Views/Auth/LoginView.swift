//
//  LoginView.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 20/4/2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("LoanTrack")
                    .font(.largeTitle.bold())

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("Login") {
                    Task {
                        await login()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)

                NavigationLink("Create an account", destination: RegisterView())

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
    }

    private func login() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await session.login(email: email, password: password)
            errorMessage = nil
        } catch
        {
            if error.localizedDescription.contains("pending") ||
               error.localizedDescription.contains("ACCOUNT_PENDING") {
                errorMessage = "⏳ Your account is pending approval. An admin will activate your account shortly."
            } else if error.localizedDescription.contains("suspended") {
                errorMessage = "🚫 Your account has been suspended. Contact your administrator."
            } else {
                errorMessage = error.localizedDescription
            }
            errorMessage = "Login failed."
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionViewModel())
}
