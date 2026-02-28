//
//  AuthViewModel.swift
//  Senior-Design
//
//  Created by Nguyen,Leo on 2/27/26.
//

import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var user: User?
    @Published var errorMessage: String = ""

    init() {
        try? Auth.auth().signOut()   // 👈 add this temporarily
        self.user = Auth.auth().currentUser

        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }

    func signUp(email: String, password: String) async {
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = ""
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        errorMessage = ""
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
