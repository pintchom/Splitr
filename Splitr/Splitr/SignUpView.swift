//
//  SignUpView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct SignUpView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var password2: String = ""
    @State private var isLoading: Bool = false
    @State private var signUpResult: String = ""
    @Binding var isLoggedIn: Bool
    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Confirm Password", text: $password2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if password != password2 {
                Text("Passwords don't match")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                signUp()
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign Up")
                }
            }
            .disabled(password != password2 || isLoading)
            .padding()
            
            Text(signUpResult)
        }
    }
    
    private func signUp() {
        isLoading = true
        FirebaseManager.shared.signUp(name: name, email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success(let user):
                signUpResult = "Sign up successful. User ID: \(user.uid)"
                UserDefaults.standard.set(user.uid, forKey: "userID")
                isLoggedIn = true
            case .failure(let error):
                signUpResult = "Sign up failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SignUpView(isLoggedIn: .constant(false))
}
