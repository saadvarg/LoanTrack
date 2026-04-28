// Add this to your ViewModel or wherever you handle the PDF button tap

import SwiftUI
import Foundation

class PDFService {
    static let shared = PDFService()
    // Update this with your actual API URL.
    // Use localhost for the simulator, but use your machine LAN IP for a physical device.
    private let baseURL = "http://localhost:3000/api" // Simulator
    // private let baseURL = "http://192.168.1.100:3000/api" // Device

    func fetchPDF(for leadId: String, authToken: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/pdf/lead/\(leadId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30 // Increase timeout

        print("🔍 PDF Request URL: \(url.absoluteString)")
        print("🔑 Auth Token present: \(!authToken.isEmpty)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("📡 Response Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Error Response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }

        print("✅ PDF data received: \(data.count) bytes")
        return data
    }
}

// In your SwiftUI view where the PDF button is:

struct LeadDetailView: View {
    let leadId: String
    @State private var showingPDF = false
    @State private var pdfData: Data?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 16) {
            // Your existing UI...

            if isLoading {
                ProgressView("Generating PDF...")
            }

            Button(action: {
                Task {
                    await loadPDF()
                }
            }) {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("View PDF Report")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding()
        .sheet(isPresented: $showingPDF) {
            if let data = pdfData {
                PDFViewer(data: data)
            } else {
                Text("No PDF available")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func loadPDF() async {
        isLoading = true
        errorMessage = nil
        showErrorAlert = false

        print("🚀 Starting PDF load for lead: \(leadId)")

        do {
            // Get auth token from your auth storage
            guard let authToken = getAuthToken() else {
                errorMessage = "Not authenticated - please log in again"
                showErrorAlert = true
                print("❌ No auth token found")
                isLoading = false
                return
            }

            print("🔐 Auth token retrieved successfully")

            pdfData = try await PDFService.shared.fetchPDF(for: leadId, authToken: authToken)
            showingPDF = true
            print("✅ PDF loaded and displayed successfully")

        } catch {
            let errorMsg = "Failed to load PDF: \(error.localizedDescription)"
            errorMessage = errorMsg
            showErrorAlert = true
            print("❌ PDF Load Error: \(error)")
        }

        isLoading = false
    }

    private func getAuthToken() -> String? {
        // Check multiple possible storage locations
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            return token
        }
        if let token = UserDefaults.standard.string(forKey: "jwtToken") {
            return token
        }
        // Add other storage methods if you use Keychain
        return nil
    }
}</content>
<parameter name="filePath">/Users/saadel/loantrack-api/PDFIntegrationExample.swift