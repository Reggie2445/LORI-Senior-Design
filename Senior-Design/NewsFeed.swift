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

    // RSVP State
    var peopleGoing: Int
    var isRSVPed: Bool

    /// Remote image from Lambda response ("Photo_URL").
    let photoURL: URL?

    /// If you put avatar images in Assets.xcassets, set this to that asset name
    let avatarName: String?
}

private struct APIEvent: Decodable {
    let eventID: String
    let eventDate: String
    let eventDescription: String
    let eventLocation: String
    let eventTime: String
    let eventTitle: String
    let photoURL: String?
    let attendanceCount: Int

    enum CodingKeys: String, CodingKey {
        case eventID = "Event_ID"
        case eventDate = "Event_Date"
        case eventDescription = "Event_Description"
        case eventLocation = "Event_Location"
        case eventTime = "Event_Time"
        case eventTitle = "Event_Title"
        case photoURL = "Photo_URL"
        case eventAttendance = "Event_Attendance"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventID = APIEvent.decodeString(container, forKey: .eventID) ?? UUID().uuidString
        eventDate = APIEvent.decodeString(container, forKey: .eventDate) ?? ""
        eventDescription = APIEvent.decodeString(container, forKey: .eventDescription) ?? ""
        eventLocation = APIEvent.decodeString(container, forKey: .eventLocation) ?? ""
        eventTime = APIEvent.decodeString(container, forKey: .eventTime) ?? ""
        eventTitle = APIEvent.decodeString(container, forKey: .eventTitle) ?? "Untitled Event"
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)

        if let attendees = try? container.decode([String].self, forKey: .eventAttendance) {
            attendanceCount = attendees.count
        } else if let attendees = try? container.decode([Int].self, forKey: .eventAttendance) {
            attendanceCount = attendees.count
        } else if let count = try? container.decode(Int.self, forKey: .eventAttendance) {
            attendanceCount = count
        } else if let countString = try? container.decode(String.self, forKey: .eventAttendance),
                  let count = Int(countString) {
            attendanceCount = count
        } else {
            attendanceCount = 0
        }
    }

    private static func decodeString(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }

    func toEvent() -> Event {
        Event(
            id: eventID,
            hostName: "LORI",
            title: eventTitle,
            description: eventDescription,
            dateText: "\(eventDate) at \(eventTime)",
            locationText: eventLocation,
            peopleGoing: attendanceCount,
            isRSVPed: false,
            photoURL: photoURL.flatMap(URL.init(string:)),
            avatarName: nil
        )
    }
}

// MARK: - ViewModel (shared state)

@MainActor
final class EventsViewModel: ObservableObject {
    private let eventsAPIURLs: [String] = [
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/default/EventReadLambda",
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/EventReadLambda",
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/default",
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/default/events",
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/default/Events",
        "https://gbzolouzcg.execute-api.us-east-1.amazonaws.com/events"
    ]

    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var hasLoaded = false

    func loadEventsIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await loadEvents()
    }

    func refreshEntireFeed() async {
        await loadEvents()
    }

    func loadEvents() async {
        if Task.isCancelled {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        var attempts: [String] = []

        for urlString in eventsAPIURLs {
            if Task.isCancelled {
                isLoading = false
                return
            }

            guard let url = URL(string: urlString) else { continue }

            do {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                var items = components?.queryItems ?? []
                items.append(URLQueryItem(name: "_ts", value: String(Int(Date().timeIntervalSince1970))))
                components?.queryItems = items
                let requestURL = components?.url ?? url

                var request = URLRequest(url: requestURL, cachePolicy: .reloadIgnoringLocalCacheData)
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                let (data, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

                guard (200...299).contains(statusCode) else {
                    let serverText = String(data: data, encoding: .utf8) ?? "No response body"
                    attempts.append("\(url.path): HTTP \(statusCode) \(serverText)")
                    continue
                }

                let decodedEvents = try decodeEvents(from: data)
                let sortedEvents = sortChronologically(decodedEvents)
                events = sortedEvents.map { $0.toEvent() }
                isLoading = false
                return
            } catch is CancellationError {
                isLoading = false
                return
            } catch {
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    isLoading = false
                    return
                }
                attempts.append("\(url.path): \(error.localizedDescription)")
            }
        }

        if Task.isCancelled {
            isLoading = false
            return
        }

        errorMessage = "Failed to load events. " + attempts.joined(separator: " | ")
        isLoading = false
    }

    private func decodeEvents(from data: Data) throws -> [APIEvent] {
        let decoder = JSONDecoder()

        if let events = try? decoder.decode([APIEvent].self, from: data) {
            return events
        }

        if let event = try? decoder.decode(APIEvent.self, from: data) {
            return [event]
        }

        if let envelope = try? decoder.decode(LambdaProxyEnvelope.self, from: data),
           let body = envelope.body,
           let bodyData = body.data(using: .utf8) {
            if let events = try? decoder.decode([APIEvent].self, from: bodyData) {
                return events
            }
            if let event = try? decoder.decode(APIEvent.self, from: bodyData) {
                return [event]
            }
        }

        let preview = String(data: data, encoding: .utf8) ?? "Unable to decode response body"
        throw NSError(domain: "EventsDecode", code: 1, userInfo: [NSLocalizedDescriptionKey: preview])
    }

    private func sortChronologically(_ apiEvents: [APIEvent]) -> [APIEvent] {
        apiEvents.sorted { lhs, rhs in
            let lhsDate = parsedDate(for: lhs)
            let rhsDate = parsedDate(for: rhs)

            switch (lhsDate, rhsDate) {
            case let (left?, right?):
                return left < right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.eventID < rhs.eventID
            }
        }
    }

    private func parsedDate(for event: APIEvent) -> Date? {
        let date = event.eventDate.trimmingCharacters(in: .whitespacesAndNewlines)
        let time = event.eventTime.trimmingCharacters(in: .whitespacesAndNewlines)

        let combinedFormats = [
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd h:mm a",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy h:mm a",
            "MMM d, yyyy HH:mm",
            "MMM d, yyyy h:mm a",
            "MMMM d, yyyy HH:mm",
            "MMMM d, yyyy h:mm a"
        ]

        let dateOnlyFormats = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "MMM d, yyyy",
            "MMMM d, yyyy"
        ]

        for format in combinedFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = format

            if let parsed = formatter.date(from: "\(date) \(time)") {
                return parsed
            }
        }

        for format in dateOnlyFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = format

            if let parsed = formatter.date(from: date) {
                return parsed
            }
        }

        return nil
    }
}

private struct LambdaProxyEnvelope: Decodable {
    let body: String?
}

// MARK: - Events Page (Main View)

struct EventsPageView: View {
    @StateObject private var vm = EventsViewModel()
    @State private var selectedEventId = ""
    @State private var isShowingDetail = false

    var body: some View {
        NavigationStack {
            List {
                Text("Events")
                    .font(.system(size: 34, weight: .bold))
                    .padding(.top, 12)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))

                if vm.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading events...")
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }

                ForEach(vm.events) { event in
                    Button {
                        selectedEventId = event.id
                        isShowingDetail = true
                    } label: {
                        EventCardView(event: event)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .task {
                await vm.loadEventsIfNeeded()
            }
            .refreshable {
                await vm.refreshEntireFeed()
            }
            .navigationDestination(isPresented: $isShowingDetail) {
                EventDetailView(eventId: selectedEventId)
                    .environmentObject(vm)
                    .navigationBarBackButtonHidden(true)
            }

            // Bottom tab bar (like the screenshot)
        }
    }
}

// MARK: - Event Detail (Stub so the file compiles)

struct EventDetailView: View {
    let eventId: String
    @EnvironmentObject var vm: EventsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // Simple placeholder: shows the selected event title if found
        let event = vm.events.first { $0.id == eventId }

        VStack(alignment: .leading, spacing: 12) {
            Button {
                dismiss()
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

            HeroImage(imageURL: event.photoURL)
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

// MARK: - Bottom Tab Bar



// MARK: - Preview

#Preview {
    EventsPageView()
}
