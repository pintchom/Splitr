//
//  LoginView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI
import Firebase

struct LoginView: View {
    @State private var email: String = ""
    @State private var pass: String = ""
    @State private var pass2: String = ""
    @State private var isLoading: Bool = false
    @State private var loginResult: String = ""
    @State private var showSignUp: Bool = false
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if UserDefaults.standard.string(forKey: "userID") != nil {
                    HomeView()
                } else {
                    VStack {
                        TextField("Email", text: $email)
                        SecureField("Password", text: $pass)
                        
                        Button(action: {
                            loginUser()
                        }) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Submit")
                            }
                        }
                        .disabled(isLoading)
                        
                        Text(loginResult)
                        
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Don't have an account? Sign up!")
                        }
                        .padding(.top)
                    }
                    .sheet(isPresented: $showSignUp) {
                        SignUpView(isLoggedIn: $isLoggedIn)
                    }
                    .navigationDestination(isPresented: $isLoggedIn) {
                        HomeView()
                    }
                }
            }
        }
        .onAppear {
            if let userID = UserDefaults.standard.string(forKey: "userID") {
                retrieveUserData(userID: userID)
            }
        }
    }
    
    private func loginUser() {
        isLoading = true
        FirebaseManager.shared.login(email: email, password: pass) { result in
            isLoading = false
            switch result {
            case .success(let user):
                loginResult = "Login successful. User ID: \(user.uid)"
                UserDefaults.standard.set(user.uid, forKey: "userID")
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
            case .failure(let error):
                loginResult = "Login failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func retrieveUserData(userID: String) {
        FirebaseManager.shared.retrieveUser(userID: userID) { result in
            switch result {
            case .success(let userData):
                print("User data retrieved: Name: \(userData.name), Email: \(userData.email), Group IDs: \(userData.groupIDs)")
                // You can store this data in UserDefaults or use it as needed
            case .failure(let error):
                print("Failed to retrieve user data: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    LoginView()
}
