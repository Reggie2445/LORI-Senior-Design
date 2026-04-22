//
//  SettingsView.swift
//  Senior-Design
//
//  Created by Reggie Easton on 1/29/26.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogoutError = false
    @AppStorage("appAppearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Account section
                    Text("Account")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    SettingsCard {
                        SettingsRow(icon: "person.circle", title: "Edit Profile", subtitle: "Name, photo, bio") {
                            // placeholder
                        }
                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "lock.circle", title: "Privacy", subtitle: "Visibility, blocks") {
                            // placeholder
                        }
                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "bell.circle", title: "Notifications", subtitle: "Reminders, updates") {
                            // placeholder
                        }
                    }

                    // Preferences section
                    Text("Preferences")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    SettingsCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 22))
                                    .frame(width: 34, height: 34)
                                    .foregroundStyle(Color(.systemGray))
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Appearance")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    Text("System, light, or dark")
                                        .font(.footnote)
                                        .foregroundStyle(Color(.systemGray))
                                }
                            }

                            Picker("Appearance", selection: $appAppearance) {
                                Text("System").tag(0)
                                Text("Light").tag(1)
                                Text("Dark").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)

                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "globe", title: "Language", subtitle: "English (US)") {
                            // placeholder
                        }
                    }

                    // Support section
                    Text("Support")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    SettingsCard {
                        SettingsRow(icon: "questionmark.circle", title: "Help Center", subtitle: "FAQs and guides") {
                            // placeholder
                        }
                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "envelope.circle", title: "Contact Us", subtitle: "Send feedback") {
                            // placeholder
                        }
                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "doc.text", title: "Terms & Privacy", subtitle: "Legal") {
                            // placeholder
                        }
                    }

                    // Danger section
                    Text("Account Actions")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    SettingsCard {
                        SettingsRow(icon: "arrow.right.square", title: "Log Out", subtitle: nil, titleColor: .red) {
                            authVM.signOut()
                            showLogoutError = !authVM.errorMessage.isEmpty
                        }
                        Divider().padding(.leading, 52)

                        SettingsRow(icon: "trash.circle", title: "Delete Account", subtitle: "This cannot be undone", titleColor: .red) {
                            // placeholder
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.top, 4)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Could Not Log Out", isPresented: $showLogoutError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authVM.errorMessage)
            }
        }
    }
}

// MARK: - Components

private struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var titleColor: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(Color(.systemGray))
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(titleColor)

                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Color(.systemGray))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(Color(.systemGray2))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
