import SwiftUI

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
            dateText: "Sunday, December 14, 2025 • 20:00",
            locationText: "Sky Lounge, Downtown LA",
            peopleGoing: 6,
            isRSVPed: false,
            imageName: nil,
            avatarName: nil
        )
    ]

    func toggleRSVP(eventId: UUID) {
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }

        if events[index].isRSVPed {
            events[index].isRSVPed = false
            events[index].peopleGoing = max(0, events[index].peopleGoing - 1)
        } else {
            events[index].isRSVPed = true
            events[index].peopleGoing += 1
        }
    }

    func event(by id: UUID) -> Event? {
        events.first(where: { $0.id == id })
    }
}

// MARK: - Main Page (List)

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
            .navigationBarHidden(true) // keep your "no nav bar look"
        }
    }
}

// MARK: - Event Detail Page (RSVP Screen)

struct EventDetailView: View {
    @EnvironmentObject private var vm: EventsViewModel
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    var body: some View {
        // Fallback safety
        if let event = vm.event(by: eventId) {
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Hero image + back button
                        ZStack(alignment: .topLeading) {
                            HeroImage(imageName: event.imageName)
                                .frame(height: 300)
                                .clipped()

                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.35))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 18)
                            .padding(.leading, 16)
                        }

                        // White content area
                        VStack(alignment: .leading, spacing: 18) {

                            // Hosted by row
                            HStack(spacing: 12) {
                                Avatar(imageName: event.avatarName)
                                    .frame(width: 44, height: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hosted by")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)

                                    Text(event.hostName)
                                        .font(.system(size: 18, weight: .bold))
                                }

                                Spacer()
                            }

                            // Title
                            Text(event.title)
                                .font(.system(size: 28, weight: .heavy))
                                .lineLimit(2)

                            // Date & Time card
                            InfoCard(
                                icon: "calendar",
                                title: "Date & Time",
                                mainText: event.dateText
                            )

                            // Location card
                            InfoCard(
                                icon: "mappin.circle",
                                title: "Location",
                                mainText: event.locationText
                            )

                            // People going card (optional)
                            InfoCard(
                                icon: "person.2",
                                title: "Going",
                                mainText: "\(event.peopleGoing) people going"
                            )

                            Spacer().frame(height: 90) // space for sticky button
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 18)
                        .padding(.bottom, 24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .offset(y: -22)
                    }
                }

                // RSVP Button (sticky bottom)
                Button {
                    vm.toggleRSVP(eventId: eventId)
                } label: {
                    Text(event.isRSVPed ? "Cancel RSVP" : "RSVP to Event")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.85), Color.orange.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
                .buttonStyle(.plain)
            }
            .ignoresSafeArea(edges: .top)
        } else {
            Text("Event not found")
        }
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

                    //show "GOING" badge if RSVPed
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

// MARK: - Preview

#Preview {
    EventsPageView()
}
