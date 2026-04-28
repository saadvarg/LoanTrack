import SwiftUI

@main
struct LoanTrackApp: SwiftUI.App {
    @StateObject var store = LeadStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
