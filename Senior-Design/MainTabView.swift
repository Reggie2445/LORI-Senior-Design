//
//  MainTabView.swift
//  Senior-Design
//
//  Created by Nguyen,Leo on 2/27/26.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            EventsPageView()
                .tabItem { Label("Events", systemImage: "calendar") }

            CreateEventPage()
                .tabItem { Label("Create", systemImage: "plus") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
