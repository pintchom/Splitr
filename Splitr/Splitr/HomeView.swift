//
//  HomeView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataModel = DataModel()
    @State private var showCreateGroupSheet = false
    @State private var showJoinGroupSheet = false
    @State private var showSettingsSheet = false
    @State private var groupName = ""
    @State private var groupCode = ""
    @State private var joinGroupCode = ""
    @State private var joinGroupName = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("cream3")
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if let user = dataModel.currentUser {
                        HStack {
                            Image("splitr")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                            Spacer()
                            Text("Welcome, \(user.name)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color("black"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        Text("No user data available")
                            .foregroundColor(Color("black"))
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(dataModel.groups) { group in
                                NavigationLink(destination: GroupView(group: group)) {
                                    GroupCard(group: group)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 20) {
//                        Button(action: {
//                            showSettingsSheet = true
//                        }) {
//                            Image(systemName: "gear")
//                                .foregroundColor(Color("black"))
//                                .font(.system(size: 24))
//                                .padding()
//                                .background(Color("cream2"))
//                                .clipShape(Circle())
//                                .shadow(color: Color("black").opacity(0.2), radius: 5, x: 0, y: 2)
//                        }
                        Button("Create Group") {
                            showCreateGroupSheet = true
                        }
                        .buttonStyle(CustomButtonStyle())
                        Spacer()
                        Button("Join Group") {
                            showJoinGroupSheet = true
                        }
                        .buttonStyle(CustomButtonStyle())
                        
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                CreateGroupSheet(groupName: $groupName, groupCode: $groupCode, createGroup: createGroup)
            }
            .sheet(isPresented: $showJoinGroupSheet) {
                JoinGroupSheet(showAlertError: $showErrorAlert, errorMessage: $errorMessage, joinGroupCode: $joinGroupCode, joinGroupName: $joinGroupName, joinGroup: joinGroup)
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView()
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            guard let userID = UserDefaults.standard.string(forKey: "userID") else {
                dismiss()
                return
            }
            dataModel.fetchUserData(userID: userID)
        }
    }
    
    private func createGroup() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("No user ID found")
            return
        }
        
        let trimmedGroupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        FirebaseManager.shared.createGroup(groupName: trimmedGroupName, groupCode: groupCode, userID: userID) { result in
            switch result {
            case .success:
                print("Group created successfully")
                showCreateGroupSheet = false
                dataModel.fetchUserData(userID: userID)
            case .failure(let error):
                print("Error creating group: \(error.localizedDescription)")
            }
        }
    }
    
    private func joinGroup() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("No user ID found")
            return
        }
        
        FirebaseManager.shared.joinGroup(userID: userID, groupCode: joinGroupCode, groupName: joinGroupName) { result in
            switch result {
            case .success:
                print("Joined group successfully")
                showJoinGroupSheet = false
                dataModel.fetchUserData(userID: userID)
            case .failure(let error):
                print("Error joining group: \(error.localizedDescription)")
                errorMessage = "Failed to join group: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}

struct GroupCard: View {
    let group: GroupData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.groupName)
                .font(.headline)
                .foregroundColor(Color("black"))
            Text("Code: \(group.groupCode)")
                .font(.subheadline)
                .foregroundColor(Color("black").opacity(0.8))
            Text("Creator: \(group.userNames[group.creatorID] ?? "ID NOT FOUND")")
                .font(.subheadline)
                .foregroundColor(Color("black").opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("cream1"))
        .cornerRadius(10)
        .shadow(color: Color("black").opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color("cream2"))
            .foregroundColor(Color("black"))
            .cornerRadius(10)
            .shadow(color: Color("black").opacity(0.1), radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct CreateGroupSheet: View {
    @Binding var groupName: String
    @Binding var groupCode: String
    let createGroup: () -> Void
    
    var body: some View {
        
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Create a New Group")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Group Name", text: $groupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Group Code", text: $groupCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Create") {
                    createGroup()
                }
                .buttonStyle(CustomButtonStyle())
                .disabled(groupName.isEmpty || groupCode.isEmpty)
            }
            .padding()
            .background(Color("cream3"))
        }
    }
}

struct JoinGroupSheet: View {
    @Binding var showAlertError: Bool
    @Binding var errorMessage: String
    @Binding var joinGroupCode: String
    @Binding var joinGroupName: String
    let joinGroup: () -> Void
    
    var body: some View {
        
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Join a Group")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("Group Name", text: $joinGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Group Code", text: $joinGroupCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Join") {
                    joinGroup()
                }
                .buttonStyle(CustomButtonStyle())
                .disabled(joinGroupName.isEmpty || joinGroupCode.isEmpty)
            }
            .padding()
            .background(Color("cream3"))
        }
        .alert(isPresented: $showAlertError) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}


#Preview {
    HomeView()
}

// Make this screen prettier using the following colors
// #000000 (black) #F4DFC8 (cream1) #F4EAE0 (cream2) #FAF6F0 (cream3)
// the names next to each hex are what i have them saved as so you can do Color("black") for example. add shadows and stuff as well
