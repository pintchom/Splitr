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
                    ZStack {
                        Color("cream3")
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text("Welcome to Splitr")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color("black"))
                                .padding()
                                .background(Color("cream2"))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                            VStack(spacing: 15) {
                                TextField("Email", text: $email)
                                    .foregroundColor(Color("black"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                                
                                SecureField("Password", text: $pass)
                                    .foregroundColor(Color("black"))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    loginUser()
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color("black")))
                                    } else {
                                        Text("Login")
                                            .foregroundColor(Color("black"))
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(Color("cream1"))
                                            .cornerRadius(10)
                                    }
                                }
                                .disabled(isLoading)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                
                                Text(loginResult)
                                    .foregroundColor(Color("black"))
                                    .padding()
                                
                                Button(action: {
                                    showSignUp = true
                                }) {
                                    Text("Don't have an account? Sign up!")
                                        .foregroundColor(Color("black"))
                                        .underline()
                                }
                                .padding(.top)
                            }
                            .padding()
                            .background(Color("cream2"))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        .padding()
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
            guard let userID = UserDefaults.standard.string(forKey: "userID") else {
                print("NO USER ID ")
                isLoggedIn = false
                loginResult = ""
                email = ""
                pass = ""
                pass2 = ""
                return
            }
            retrieveUserData(userID: userID)
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
