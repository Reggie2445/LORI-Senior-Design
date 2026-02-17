//
//  CreateEventPage.swift
//  Senior-Design
//
//  Created by Lize S. on 1/23/26.
//
//
//  CreateEventPage.swift
//  Senior-Design
//
//  Created by Lize S. on 1/23/26.
//
import SwiftUI
import PhotosUI
import UIKit

struct CreateEventPage: View {
    @Environment(\.dismiss) private var dismiss

    @State private var eventTitle: String = ""
    @State private var descriptionText: String = ""
    @State private var location: String = ""
    @State private var isCreating: Bool = false
    @State private var date: String = ""
    @State private var time: String = ""
    @State private var eventDate = Date()

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                // Event Photo Selector From Apple Library
                    
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            // Selected image (if any)
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .clipped()
                            } else {
                                // Placeholder background
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.gray.opacity(0.06))
                                    .frame(height: 180)

                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Text("Add Event Photo")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            // Dashed border overlay
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundStyle(.gray.opacity(0.3))
                                .frame(height: 180)
                        }
                        
                    }
                    
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: selectedItem) { newItem in
                        guard let newItem else {
                            selectedImageData = nil
                            return
                        }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    selectedImageData = data
                                }
                            }
                        }
                    }

                    // Event Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Event Title")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Summer Rooftop Party", text: $eventTitle)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ZStack(alignment: .topLeading) {
                            if descriptionText.isEmpty {
                                Text("Tell people what makes this event special...")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                            }
                            TextEditor(text: $descriptionText)
                                .frame(minHeight: 120)
                                .padding(4)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.gray.opacity(0.3))
                        )
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("e.g., 123 Main St, New York, NY", text: $location)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                    }
                    
                    // Date & Time (side by side)
                    HStack(alignment: .top, spacing: 12) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            DatePicker("Select date",
                                       selection: $eventDate,
                                       displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3))
                            )
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Time")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            DatePicker("Select time",
                                       selection: $eventDate,
                                       displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3))
                            )
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Create Event button
                    Button(action: createEvent) {
                        ZStack {
                            LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                                .frame(height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Event")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .disabled(isCreateDisabled)
                    .opacity(isCreateDisabled ? 0.6 : 1)
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var isCreateDisabled: Bool {
        eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        isCreating
    }

    private func createEvent() {
        guard !isCreateDisabled else { return }
        isCreating = true

        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Event created:")
            print("Title:", eventTitle)
            print("Description:", descriptionText)
            print("Location:", location)
            print("Has photo:", selectedImageData != nil)

            isCreating = false
            dismiss()
        }
    }
}

// Lightweight wrapper to avoid breaking any existing references to CreatePostView
struct CreatePostView: View {
    var body: some View {
        CreateEventPage()
    }
}

#Preview {
    CreateEventPage()
}
