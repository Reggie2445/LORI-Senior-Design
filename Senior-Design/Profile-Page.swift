import SwiftUI

private struct ProfileAPIEvent: Decodable {
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

        eventID = try container.decodeIfPresent(String.self, forKey: .eventID) ?? UUID().uuidString
        eventDate = try container.decodeIfPresent(String.self, forKey: .eventDate) ?? ""
        eventDescription = try container.decodeIfPresent(String.self, forKey: .eventDescription) ?? ""
        eventLocation = try container.decodeIfPresent(String.self, forKey: .eventLocation) ?? ""
        eventTime = try container.decodeIfPresent(String.self, forKey: .eventTime) ?? ""
        eventTitle = try container.decodeIfPresent(String.self, forKey: .eventTitle) ?? "Untitled Event"
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)

        if let count = try? container.decode(Int.self, forKey: .eventAttendance) {
            attendanceCount = count
        } else if let countString = try? container.decode(String.self, forKey: .eventAttendance),
                  let count = Int(countString) {
            attendanceCount = count
        } else {
            attendanceCount = 0
        }
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
            isRSVPed: true,
            photoURL: photoURL.flatMap(URL.init(string:)),
            avatarName: nil
        )
    }
}

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var attendingEvents: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .clipShape(Circle())

                    Text("You")
                        .font(.system(size: 32, weight: .bold))

                    HStack(spacing: 0) {
                        VStack(spacing: 8) {
                            Text("0")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))

                            Text("Events Created")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 60)

                        VStack(spacing: 8) {
                            Text("\(attendingEvents.count)")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))

                            Text("Events Attending")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Your Events")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                    Text("You haven't created any events yet")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
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
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else if attendingEvents.isEmpty {
                        Text("You're not attending any events yet")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
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
        .background(Color.white)
        .task {
            await loadAttendingEvents()
        }
    }

    private func loadAttendingEvents() async {
        guard let userID = authVM.currentUserID else {
            errorMessage = "No logged-in user found"
            return
        }

        guard let url = URL(string: "http://127.0.0.1:8080/users/\(userID)/attending") else {
            errorMessage = "Invalid URL"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

            guard (200...299).contains(statusCode) else {
                errorMessage = "Failed to load attending events"
                isLoading = false
                return
            }

            let decoded = try JSONDecoder().decode([ProfileAPIEvent].self, from: data)
            attendingEvents = decoded.map { $0.toEvent() }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
