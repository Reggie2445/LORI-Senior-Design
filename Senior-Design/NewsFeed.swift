import SwiftUI
import UIKit

// MARK: - Data Model

struct Event: Identifiable {
    let id: String
    let hostName: String
    let title: String
    let description: String
    let dateText: String
    let locationText: String
    let imageURL: URL?
    let startDate: Date?

    var peopleGoing: Int
    var isRSVPed: Bool
    let avatarName: String?
}

private struct APIEvent: Decodable {
    let Event_ID: String
    let Event_Title: String
    let Event_Description: String
    let Event_Date: String
    let Event_Time: String
    let Event_Location: String
    let Event_Attendance: [String]
}

// MARK: - ViewModel

@MainActor
final class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let eventDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let eventTime24HourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private let eventTime24HourSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private let eventTime12HourInputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private let eventTimeStandardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: "http://127.0.0.1:8080/events") else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let apiEvents = try JSONDecoder().decode([APIEvent].self, from: data)
            let now = Date()

            events = apiEvents.compactMap { item in
                let startDate = parseEventStartDate(date: item.Event_Date, time: item.Event_Time)
                if let startDate, startDate < now {
                    return nil
                }

                let encodedID = item.Event_ID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? item.Event_ID
                return Event(
                    id: item.Event_ID,
                    hostName: "Host",
                    title: item.Event_Title,
                    description: item.Event_Description,
                    dateText: "\(item.Event_Date) at \(formatStandardTime(item.Event_Time))",
                    locationText: item.Event_Location,
                    imageURL: URL(string: "http://127.0.0.1:8080/events/\(encodedID)/photo"),
                    startDate: startDate,
                    peopleGoing: item.Event_Attendance.count,
                    isRSVPed: false,
                    avatarName: nil
                )
            }.sorted { lhs, rhs in
                switch (lhs.startDate, rhs.startDate) {
                case let (left?, right?):
                    return left < right
                case (.some, nil):
                    return true
                case (nil, .some):
                    return false
                case (nil, nil):
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }

            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Could not load events."
            print("Failed to fetch events:", error)
        }
    }

    private func parseEventStartDate(date: String, time: String) -> Date? {
        guard let day = eventDateFormatter.date(from: date) else { return nil }
        let parsedTime = eventTime24HourFormatter.date(from: time)
            ?? eventTime24HourSecondsFormatter.date(from: time)
            ?? eventTime12HourInputFormatter.date(from: time)
        guard let parsedTime else { return nil }

        let calendar = Calendar.current
        let dayParts = calendar.dateComponents([.year, .month, .day], from: day)
        let timeParts = calendar.dateComponents([.hour, .minute], from: parsedTime)
        return calendar.date(from: DateComponents(
            year: dayParts.year,
            month: dayParts.month,
            day: dayParts.day,
            hour: timeParts.hour,
            minute: timeParts.minute
        ))
    }

    private func formatStandardTime(_ time: String) -> String {
        if let date = eventTime24HourFormatter.date(from: time)
            ?? eventTime24HourSecondsFormatter.date(from: time)
            ?? eventTime12HourInputFormatter.date(from: time) {
            return eventTimeStandardFormatter.string(from: date)
        }
        return time
    }
}

// MARK: - Events Page

struct EventsPageView: View {
    @StateObject private var vm = EventsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Events")
                        .font(.system(size: 34, weight: .bold))
                        .padding(.top, 12)

                    if vm.isLoading {
                        ProgressView("Loading events...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if let error = vm.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if vm.events.isEmpty {
                        Text("No events found.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(vm.events) { event in
                            NavigationLink {
                                EventDetailView(eventId: event.id)
                                    .environmentObject(vm)
                            } label: {
                                EventCardView(event: event)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 16)
            }
        }
        .task {
            await vm.loadEvents()
        }
    }
}

// MARK: - Event Detail (Stub so the file compiles)

// MARK: - Event Detail View
// Drop this in to replace the existing EventDetailView stub in your project.
// It matches the screenshot: hero image, host row, title, info cards, RSVP button.

import SwiftUI

struct EventDetailView: View {
    let eventId: String
    @EnvironmentObject var vm: EventsViewModel
    @Environment(\.dismiss) private var dismiss

    // RSVP state
    @State private var rsvpState: RSVPState = .idle
    @State private var localPeopleGoing: Int? = nil

    private var event: Event? {
        vm.events.first { $0.id == eventId }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // HERO IMAGE
                    heroSection

                    // CONTENT
                    VStack(alignment: .leading, spacing: 20) {

                        // Host row
                        if let event {
                            HStack(spacing: 10) {
                                Avatar(imageName: event.avatarName)
                                    .frame(width: 40, height: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Hosted by")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text(event.hostName)
                                        .font(.system(size: 16, weight: .semibold))
                                }

                                Spacer()

                                // Attendance badge
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 12))
                                    Text("\(localPeopleGoing ?? event.peopleGoing) going")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            }

                            // Title
                            Text(event.title)
                                .font(.system(size: 28, weight: .bold))

                            // Description
                            if !event.description.isEmpty {
                                Text(event.description)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(4)
                            }

                            // Info cards
                            VStack(spacing: 10) {
                                InfoCard(
                                    icon: "calendar",
                                    title: "Date & Time",
                                    mainText: event.dateText
                                )
                                InfoCard(
                                    icon: "mappin.and.ellipse",
                                    title: "Location",
                                    mainText: event.locationText
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // space for the fixed RSVP button
                }
            }
            .ignoresSafeArea(edges: .top)

            // FIXED RSVP BUTTON
            rsvpButton
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let event {
                localPeopleGoing = event.peopleGoing
                rsvpState = event.isRSVPed ? .confirmed : .idle
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            if let event {
                HeroImage(imageURL: event.photoURL)
                    .frame(height: 320)
                    .clipped()
            }

            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)
        }
    }

    // MARK: - RSVP Button

    private var rsvpButton: some View {
        VStack(spacing: 0) {
            // Subtle fade above button
            LinearGradient(
                colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)

            Button {
                Task { await handleRSVP() }
            } label: {
                HStack(spacing: 8) {
                    if rsvpState == .loading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.9)
                    } else if rsvpState == .confirmed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(rsvpState.label)
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(rsvpState.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.orange.opacity(rsvpState == .confirmed ? 0 : 0.35), radius: 12, x: 0, y: 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: rsvpState)
            }
            .disabled(rsvpState == .loading || rsvpState == .confirmed)
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - RSVP Logic

    private func handleRSVP() async {
        guard let event, rsvpState == .idle else { return }
        rsvpState = .loading

        // --- POST to your Lambda RSVP endpoint ---
        // Update the URL below to your actual RSVP Lambda endpoint.
        // Expected body: { "Event_ID": "<id>", "User_ID": "<userId>" }
        let rsvpURLString = "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/default/EventRSVPLambda"

        guard let url = URL(string: rsvpURLString) else {
            rsvpState = .idle
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "Event_ID": event.id,
            "User_ID": "current_user" // Replace with your actual auth user ID
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            if (200...299).contains(statusCode) {
                // Success — update local state
                localPeopleGoing = (localPeopleGoing ?? event.peopleGoing) + 1
                rsvpState = .confirmed

                // Sync back into the ViewModel so the card shows "GOING"
                if let idx = vm.events.firstIndex(where: { $0.id == eventId }) {
                    vm.events[idx].isRSVPed = true
                    vm.events[idx].peopleGoing += 1
                }
            } else {
                rsvpState = .idle
            }
        } catch {
            rsvpState = .idle
        }
    }
}

// MARK: - RSVP State

enum RSVPState: Equatable {
    case idle, loading, confirmed

    var label: String {
        switch self {
        case .idle:      return "RSVP to Event"
        case .loading:   return "Saving..."
        case .confirmed: return "You're Going! 🎉"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .idle, .loading:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.45, blue: 0.3), Color(red: 1.0, green: 0.25, blue: 0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .confirmed:
            return LinearGradient(
                colors: [Color.green, Color(red: 0.1, green: 0.75, blue: 0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventDetailView(eventId: "preview-1")
            .environmentObject({
                let vm = EventsViewModel()
                vm.events = [
                    Event(
                        id: "preview-1",
                        hostName: "Sarah Chen",
                        title: "Summer Rooftop Party",
                        description: "Join us for an unforgettable night under the stars with great music, drinks, and vibes.",
                        dateText: "Sunday, December 14, 2025 at 20:00",
                        locationText: "Sky Lounge, Downtown LA",
                        peopleGoing: 42,
                        isRSVPed: false,
                        photoURL: nil,
                        avatarName: nil
                    )
                ]
                return vm
            }())
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeroImage(imageURL: event.imageURL)
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

// MARK: - Reusable Pieces

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
    let imageURL: URL?

    var body: some View {
        ZStack {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
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

#Preview {
    EventsPageView()
}
