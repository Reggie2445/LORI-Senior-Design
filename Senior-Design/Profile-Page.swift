//
//  ProfilePage.swift
//  Senior-Design
//
//  Created by Aryan Katakwar on 2/4/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
        VStack(spacing: 0) {
            // Profile Header
            VStack(spacing: 16) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
                
                // "You" Label
                Text("You")
                    .font(.system(size: 32, weight: .bold))
                
                // Stats Row
                HStack(spacing: 0) {
                    // Events Created
                    VStack(spacing: 8) {
                        Text("0")
                            .font(.system(size: 34, weight: .regular))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        
                        Text("Events Created")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 60)
                    
                    // Events Attending
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
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Events Section
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
            
            // Attending Section
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
            
            Spacer()
        }
        .background(Color.white)
        .overlay(alignment: .bottom) {
            // Bottom Tab Bar
            TabBarView()
        }
        }
    }
}

struct TabBarView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Events Tab
            NavigationLink(destination: EventsPageView()) {
                TabBarItem(
                    icon: "calendar",
                    label: "Events",
                    isSelected: false
                )
            }
            
            // Create Tab
            TabBarItem(
                icon: "plus",
                label: "Create",
                isSelected: false
            )
            
            // Profile Tab
            TabBarItem(
                icon: "person.fill",
                label: "Profile",
                isSelected: true
            )
            
            // Settings Tab
            NavigationLink(destination: SettingsView()) {
                TabBarItem(
                    icon: "gearshape",
                    label: "Settings",
                    isSelected: false
                )
            }
        }
        .frame(height: 83)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? Color(red: 1.0, green: 0.4, blue: 0.4) : .gray)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? Color(red: 1.0, green: 0.4, blue: 0.4) : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// Preview
#Preview {
    ProfileView()
}

