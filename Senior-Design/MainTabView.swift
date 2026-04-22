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
                .tag(0)
                .tabItem { Label("Events", systemImage: "calendar") }

            CreateEventPage {
                selectedTab = 0
            }
                .tag(1)
                .tabItem { Label("Create", systemImage: "plus") }

            ProfileView()
                .tag(2)
                .tabItem { Label("Profile", systemImage: "person") }

            SettingsView()
                .tag(3)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
