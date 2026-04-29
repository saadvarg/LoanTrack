import SwiftUI
import Foundation
import Combine

@main
struct LoanTrackApp: App {
    @StateObject private var session = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoading {
                    ProgressView("Loading...")
                } else if session.isAuthenticated {
                    DashboardView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
        }
    }
}
