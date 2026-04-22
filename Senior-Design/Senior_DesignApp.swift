//
//  Senior_DesignApp.swift
//  Senior-Design
//
//  Created by Reggie Easton on 1/23/26.
//

import SwiftUI
import FirebaseCore

@main
struct Senior_DesignApp: App {

    @StateObject private var authVM = AuthViewModel()
    @AppStorage("appAppearance") private var appAppearance = 0

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authVM.user != nil {
                    MainTabView()
                } else {
                    AuthScreen()
                }
            }
            .environmentObject(authVM)
            .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appAppearance {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil
        }
    }
}
