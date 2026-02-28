//
//  AuthScreen.swift
//  Senior-Design
//
//  Created by Nguyen,Leo on 2/27/26.
//

import SwiftUI

struct AuthScreen: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            Circle()
                .scale(1.7)
                .foregroundColor(.white.opacity(0.15))

            Circle()
                .scale(1.35)
                .foregroundColor(.white)

            VStack(spacing: 14) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 6)

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(10)

                Button(isSignUp ? "Create Account" : "Login") {
                    Task {
                        if isSignUp {
                            await authVM.signUp(email: email, password: password)
                        } else {
                            await authVM.signIn(email: email, password: password)
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(width: 300, height: 50)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.top, 6)

                Button(isSignUp ? "Already have an account? Login" : "No account? Sign Up") {
                    authVM.errorMessage = ""
                    isSignUp.toggle()
                }
                .foregroundColor(.black.opacity(0.65))
                .padding(.top, 4)

                if !authVM.errorMessage.isEmpty {
                    Text(authVM.errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                        .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
