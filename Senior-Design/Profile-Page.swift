import SwiftUI
import FirebaseAuth

private struct ProfileEvent: Decodable, Identifiable {
    let Event_ID: String
    let User_UID: String?
    let Event_Title: String
    let Event_Date: String
    let Event_Time: String
    let Event_Location: String
    let Event_Description: String
    let Event_Attendance: [String]

    var id: String { Event_ID }
}

struct ProfileView: View {
    @State private var createdEvents: [ProfileEvent] = []
    @State private var isLoadingCreatedEvents = false
    @State private var createdEventsError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // Profile Header
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
                            Text("\(createdEvents.count)")
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
                            Text("0")
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

                    if isLoadingCreatedEvents {
                        ProgressView("Loading your events...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if let createdEventsError {
                        Text(createdEventsError)
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else if createdEvents.isEmpty {
                        Text("You haven't created any events yet")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(createdEvents) { event in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(event.Event_Title)
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("\(event.Event_Date) at \(event.Event_Time)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text(event.Event_Location)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text("Attending")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 20)

                    Text("You're not attending any events yet")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }

                Spacer(minLength: 30)
            }
        }
        .background(Color.white)
        .task {
            await loadCreatedEvents()
        }
    }

    private func loadCreatedEvents() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                createdEvents = []
                createdEventsError = "Sign in to view your events."
            }
            return
        }

        await MainActor.run {
            isLoadingCreatedEvents = true
            createdEventsError = nil
        }

        do {
            guard let encodedUID = uid.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let url = URL(string: "http://127.0.0.1:8080/events/user/\(encodedUID)") else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let events = try JSONDecoder().decode([ProfileEvent].self, from: data)
            await MainActor.run {
                createdEvents = events
                isLoadingCreatedEvents = false
            }
        } catch {
            await MainActor.run {
                createdEvents = []
                isLoadingCreatedEvents = false
                createdEventsError = "Could not load your events."
            }
            print("Failed to fetch user events:", error)
        }
    }
}

#Preview {
    ProfileView()
}
