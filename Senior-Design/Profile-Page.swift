import SwiftUI

private struct ProfileAPIEvent: Decodable {
    let eventID: String
    let userUID: String
    let eventDate: String
    let eventDescription: String
    let eventLocation: String
    let eventTime: String
    let eventTitle: String
    let photoURL: String?
    let photoKey: String?
    let attendanceCount: Int

    enum CodingKeys: String, CodingKey {
        case eventID = "Event_ID"
        case userUID = "User_UID"
        case eventDate = "Event_Date"
        case eventDescription = "Event_Description"
        case eventLocation = "Event_Location"
        case eventTime = "Event_Time"
        case eventTitle = "Event_Title"
        case photoURL = "Photo_URL"
        case photoKey = "Photo_Key"
        case eventAttendance = "Event_Attendance"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        eventID = try container.decodeIfPresent(String.self, forKey: .eventID) ?? UUID().uuidString
        userUID = try container.decodeIfPresent(String.self, forKey: .userUID) ?? ""
        eventDate = try container.decodeIfPresent(String.self, forKey: .eventDate) ?? ""
        eventDescription = try container.decodeIfPresent(String.self, forKey: .eventDescription) ?? ""
        eventLocation = try container.decodeIfPresent(String.self, forKey: .eventLocation) ?? ""
        eventTime = try container.decodeIfPresent(String.self, forKey: .eventTime) ?? ""
        eventTitle = try container.decodeIfPresent(String.self, forKey: .eventTitle) ?? "Untitled Event"
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        photoKey = try container.decodeIfPresent(String.self, forKey: .photoKey)

        if let count = try? container.decode(Int.self, forKey: .eventAttendance) {
            attendanceCount = count
        } else if let countString = try? container.decode(String.self, forKey: .eventAttendance),
                  let count = Int(countString) {
            attendanceCount = count
        } else {
            attendanceCount = 0
        }
    }

    func toEvent(isAttending: Bool) -> Event {
        let resolvedPhotoURLString = photoURL ?? photoKey.map { "https://event-photos-test.s3.amazonaws.com/\($0)" }
        return Event(
            id: eventID,
            hostName: "LORI",
            title: eventTitle,
            description: eventDescription,
            dateText: "\(eventDate) at \(eventTime)",
            locationText: eventLocation,
            peopleGoing: attendanceCount,
            isRSVPed: isAttending,
            photoURL: resolvedPhotoURLString.flatMap(URL.init(string:)),
            avatarName: nil
        )
    }
}

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var createdEvents: [Event] = []
    @State private var attendingEvents: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(.secondary)
                            .clipShape(Circle())

                        Text("You")
                            .font(.system(size: 32, weight: .bold))

                        HStack(spacing: 0) {
                            VStack(spacing: 8) {
                                Text("\(createdEvents.count)")
                                    .font(.system(size: 34, weight: .regular))
                                    .foregroundStyle(Color.accentColor)

                                Text("Events Created")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(Color(.separator))
                                .frame(width: 1, height: 60)

                            VStack(spacing: 8) {
                                Text("\(attendingEvents.count)")
                                    .font(.system(size: 34, weight: .regular))
                                    .foregroundStyle(Color.accentColor)

                                Text("Events Attending")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 30)

                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Your Events")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        if isLoading && createdEvents.isEmpty {
                            ProgressView("Loading your events...")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if createdEvents.isEmpty {
                            Text("You haven't created any events yet")
                                .font(.system(size: 17))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(createdEvents) { event in
                                    EventCardView(event: event)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Attending")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal, 20)

                        if isLoading {
                            ProgressView("Loading attending events...")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else if attendingEvents.isEmpty {
                            Text("You're not attending any events yet")
                                .font(.system(size: 17))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(attendingEvents) { event in
                                    EventCardView(event: event)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 30)
                        }
                    }

                    Spacer(minLength: 30)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task {
                await loadProfileData()
            }
        }
    }

    private func loadProfileData() async {
        guard let userID = authVM.currentUserID else {
            errorMessage = "No logged-in user found"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            async let createdTask = fetchCreatedEvents(userID: userID)
            async let attendingTask = fetchAttendingEvents(userID: userID)
            createdEvents = try await createdTask
            attendingEvents = try await attendingTask

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchCreatedEvents(userID: String) async throws -> [Event] {
        guard let url = URL(string: "http://127.0.0.1:8080/events") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode([ProfileAPIEvent].self, from: data)
        let filtered = decoded.filter { $0.userUID == userID }
        let sorted = sortEventsChronologically(filtered)
        return sorted.map { $0.toEvent(isAttending: false) }
    }

    private func fetchAttendingEvents(userID: String) async throws -> [Event] {
        guard let url = URL(string: "http://127.0.0.1:8080/users/\(userID)/attending") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200...299).contains(statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode([ProfileAPIEvent].self, from: data)
        let sorted = sortEventsChronologically(decoded)
        return sorted.map { $0.toEvent(isAttending: true) }
    }

    private func sortEventsChronologically(_ events: [ProfileAPIEvent]) -> [ProfileAPIEvent] {
        events.sorted { lhs, rhs in
            let left = parsedDate(date: lhs.eventDate, time: lhs.eventTime)
            let right = parsedDate(date: rhs.eventDate, time: rhs.eventTime)

            switch (left, right) {
            case let (l?, r?): return l < r
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none): return lhs.eventID < rhs.eventID
            }
        }
    }

    private func parsedDate(date: String, time: String) -> Date? {
        let trimmedDate = date.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTime = time.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedDate.isEmpty {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = iso.date(from: trimmedDate) { return parsed }
            iso.formatOptions = [.withInternetDateTime]
            if let parsed = iso.date(from: trimmedDate) { return parsed }
        }

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
            if let parsed = formatter.date(from: "\(trimmedDate) \(trimmedTime)") { return parsed }
        }

        for format in dateOnlyFormats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = format
            if let parsed = formatter.date(from: trimmedDate) { return parsed }
        }

        if !trimmedDate.isEmpty,
           let timestamp = TimeInterval(trimmedDate) {
            return Date(timeIntervalSince1970: timestamp)
        }

        return nil
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
