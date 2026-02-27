import SwiftUI

// MARK: - Tabs

enum AppTab {
    case events, create, profile, settings
}

// MARK: - Root Container (always shows tab bar)

struct RootView: View {
    @State private var selectedTab: AppTab = .events

    var body: some View {
        VStack(spacing: 0) {
            // Main content (switches based on selected tab)
            Group {
                switch selectedTab {
                case .events:
                    NavigationStack { EventsPageView() }

                case .create:
                    NavigationStack { CreateEventPage() }

                case .profile:
                    NavigationStack { ProfileView() }

                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Always-visible custom tab bar
            TabBarView(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Custom Tab Bar UI

struct TabBarView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {

            TabBarItem(icon: "calendar", label: "Events", isSelected: selectedTab == .events)
                .onTapGesture { selectedTab = .events }

            TabBarItem(icon: "plus", label: "Create", isSelected: selectedTab == .create)
                .onTapGesture { selectedTab = .create }

            TabBarItem(icon: "person.fill", label: "Profile", isSelected: selectedTab == .profile)
                .onTapGesture { selectedTab = .profile }

            TabBarItem(icon: "gearshape", label: "Settings", isSelected: selectedTab == .settings)
                .onTapGesture { selectedTab = .settings }
        }
        .frame(height: 83)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? Color(red: 1.0, green: 0.4, blue: 0.4) : .gray)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? Color(red: 1.0, green: 0.4, blue: 0.4) : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
