//
//  MainTabView.swift
//  Senior-Design
//
//  Created by Nguyen,Leo on 2/27/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EventsPageView()
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(0)

            CreateEventPage {
                selectedTab = 0
            }
                .tabItem { Label("Create", systemImage: "plus") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
    }
}
