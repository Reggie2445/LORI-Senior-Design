import SwiftUI

// MARK: - Data Model

struct Event: Identifiable {
    let id = UUID()
    let hostName: String
    let title: String
    let description: String
    let dateText: String
    let locationText: String
    let goingText: String

    /// If you put images in Assets.xcassets, set this to that asset name
    let imageName: String?

    /// If you put avatar images in Assets.xcassets, set this to that asset name
    let avatarName: String?
}

// MARK: - Main Page

struct EventsPageView: View {

    // Sample data (replace with real API / DB later)
    private let events: [Event] = [
        Event(
            hostName: "Janhi Ong",
            title: "Test Title",
            description: "This is a test description",
            dateText: "Fed 14, 2025 at 20:00",
            locationText: "Drexel CCI",
            goingText: "6 people going",
            imageName: nil,     // e.g. "partyHero"
            avatarName: nil     // e.g. "sarahAvatar"
        )
    ]

    // Simple tab state (so the bottom bar can highlight “Events”)
    @State private var selectedTab: Tab = .events

    var body: some View {
        VStack(spacing: 0) {

            // Top content (NO NavigationBar)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    // Page title
                    Text("Events")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top, 12)

                    // Event cards
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }

                    // Extra spacing so cards don't hide behind the bottom bar
                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 16)
            }

            // Bottom tab bar (like the screenshot)
            Divider()
            BottomTabBar(selectedTab: $selectedTab)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
        }
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top hero image
            HeroImage(imageName: event.imageName)
                .frame(height: 190)
                .clipped()

            // Card content
            VStack(alignment: .leading, spacing: 10) {

                // Host row (avatar + name)
                HStack(spacing: 10) {
                    Avatar(imageName: event.avatarName)
                        .frame(width: 28, height: 28)

                    Text(event.hostName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                // Title
                Text(event.title)
                    .font(.system(size: 22, weight: .bold))

                // Description (1–2 lines)
                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Details rows (date, location, going)
                VStack(alignment: .leading, spacing: 6) {
                    DetailRow(icon: "calendar", text: event.dateText)
                    DetailRow(icon: "mappin.and.ellipse", text: event.locationText)
                    DetailRow(icon: "person.2", text: event.goingText)
                }
                .padding(.top, 2)

            }
            .padding(14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}

// MARK: - Small Reusable Pieces

struct DetailRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

struct HeroImage: View {
    let imageName: String?

    var body: some View {
        ZStack {
            if let imageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder that still looks nice
                LinearGradient(
                    colors: [Color.black.opacity(0.25), Color.purple.opacity(0.25), Color.blue.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )
            }
        }
    }
}

struct Avatar: View {
    let imageName: String?

    var body: some View {
        ZStack {
            if let imageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.gray)
                    )
            }
        }
        .clipShape(Circle())
    }
}

// MARK: - Bottom Tab Bar

enum Tab: String {
    case events, create, profile
}

struct BottomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            TabButton(
                tab: .events,
                selectedTab: $selectedTab,
                icon: "calendar",
                label: "Events"
            )
            
            Spacer()
            
            NavigationLink(destination: CreateEventPage()) {
                TabButton(
                    tab: .create,
                    selectedTab: $selectedTab,
                    icon: "plus",
                    label: "Create"
                )
            }
            
            Spacer()
            
            NavigationLink(destination: ProfileView()) {
                TabButton(
                    tab: .profile,
                    selectedTab: $selectedTab,
                    icon: "person",
                    label: "Profile"
                )
            }
        }
        .padding(.horizontal, 28)
    }
}

struct TabButton: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    let icon: String
    let label: String

    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selectedTab == tab ? Color.red : Color.gray)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    EventsPageView()
}
