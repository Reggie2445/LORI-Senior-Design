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

// MARK: - Event Detail

struct EventDetailView: View {
    let eventId: String
    @EnvironmentObject var vm: EventsViewModel

    var body: some View {
        let event = vm.events.first { $0.id == eventId }

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HeroImage(imageURL: event?.imageURL)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(event?.title ?? "Event")
                    .font(.system(size: 30, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(icon: "calendar", text: event?.dateText ?? "Date unavailable")
                    DetailRow(icon: "mappin.and.ellipse", text: event?.locationText ?? "Location unavailable")
                    DetailRow(icon: "person.2", text: "\(event?.peopleGoing ?? 0) people going")
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("About")
                    .font(.system(size: 20, weight: .semibold))

                Text(event?.description.isEmpty == false ? event?.description ?? "" : "No description provided.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
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
