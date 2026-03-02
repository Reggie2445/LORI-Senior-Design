import SwiftUI
import UIKit

// MARK: - Data Model

struct Event: Identifiable {
    let id: UUID
    let hostName: String
    let title: String
    let description: String
    let dateText: String
    let locationText: String

    // RSVP State
    var peopleGoing: Int
    var isRSVPed: Bool

    /// If you put images in Assets.xcassets, set this to that asset name
    let imageName: String?

    /// If you put avatar images in Assets.xcassets, set this to that asset name
    let avatarName: String?
}

// MARK: - ViewModel (shared state)

final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = [
        Event(
            id: UUID(),
            hostName: "Janhi Ong",
            title: "Summer Rooftop Party",
            description: "This is a test description",
            dateText: "Feb 14, 2025 at 20:00",
            locationText: "Drexel CCI",
            peopleGoing: 6,
            isRSVPed: false,
            imageName: nil,     // e.g. "partyHero"
            avatarName: nil     // e.g. "sarahAvatar"
        )
    ]
}

// MARK: - Events Page (Main View)

struct EventsPageView: View {
    @StateObject private var vm = EventsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Events")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top, 12)

                    ForEach(vm.events) { event in
                        // Tap card -> go to detail page
                        NavigationLink {
                            EventDetailView(eventId: event.id)
                                .environmentObject(vm)
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            EventCardView(event: event)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 16)
            }

            // Bottom tab bar (like the screenshot)
        }
    }
}

// MARK: - Event Detail (Stub so the file compiles)

struct EventDetailView: View {
    let eventId: UUID
    @EnvironmentObject var vm: EventsViewModel

    var body: some View {
        // Simple placeholder: shows the selected event title if found
        let event = vm.events.first { $0.id == eventId }

        VStack(alignment: .leading, spacing: 12) {
            Button {
                // If you want a custom back button later, you can add @Environment(\.dismiss)
            } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(event?.title ?? "Event")
                .font(.system(size: 28, weight: .bold))

            Text(event?.description ?? "")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(16)
    }
}

// MARK: - Event Card (List)

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HeroImage(imageName: event.imageName)
                .frame(height: 190)
                .clipped()

            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 10) {
                    Avatar(imageName: event.avatarName)
                        .frame(width: 28, height: 28)

                    Text(event.hostName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Show "GOING" badge if RSVPed
                    if event.isRSVPed {
                        Text("GOING")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(Color.green)
                            .clipShape(Capsule())
                    }
                }

                Text(event.title)
                    .font(.system(size: 22, weight: .bold))

                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                VStack(alignment: .leading, spacing: 6) {
                    DetailRow(icon: "calendar", text: event.dateText)
                    DetailRow(icon: "mappin.and.ellipse", text: event.locationText)
                    DetailRow(icon: "person.2", text: "\(event.peopleGoing) people going")
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

struct InfoCard: View {
    let icon: String
    let title: String
    let mainText: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.red.opacity(0.85))
                .frame(width: 44, height: 44)
                .background(Color.red.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text(mainText)
                    .font(.system(size: 18, weight: .bold))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

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



// MARK: - Preview

#Preview {
    EventsPageView()
}
