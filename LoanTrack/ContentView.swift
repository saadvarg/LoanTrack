import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            CalculatorView()
                .tabItem {
                    Label("Calculator", systemImage: "percent")
                }

            LeadsView()
                .tabItem {
                    Label("Leads", systemImage: "person.2.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
