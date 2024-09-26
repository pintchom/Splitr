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
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Sign Up")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("black"))
                    .padding()
                    .background(Color("cream2"))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 15) {
                    CustomTextField(placeholder: "Name", text: $name)
                    CustomTextField(placeholder: "Email", text: $email)
                    CustomSecureField(placeholder: "Password", text: $password)
                    CustomSecureField(placeholder: "Confirm Password", text: $password2)
                }
                .padding()
                .background(Color("cream1"))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                if password != password2 {
                    Text("Passwords don't match")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    signUp()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("black")))
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(Color("cream3"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("black"))
                            .cornerRadius(10)
                    }
                }
                .disabled(password != password2 || isLoading || (password == "" && password2 == ""))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                Text(signUpResult)
                    .foregroundColor(Color("black"))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
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

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(Color("cream2"))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        SecureField(placeholder, text: $text)
            .padding()
            .background(Color("cream2"))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    SignUpView(isLoggedIn: .constant(false))
}
