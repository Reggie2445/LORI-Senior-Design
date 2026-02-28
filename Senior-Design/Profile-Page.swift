import SwiftUI

struct ProfileView: View {
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
    }
}

#Preview {
    ProfileView()
}
