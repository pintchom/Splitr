//
//  HomeView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var dataModel = DataModel()
    @State private var showCreateGroupSheet = false
    @State private var showJoinGroupSheet = false
    @State private var groupName = ""
    @State private var groupCode = ""
    @State private var joinGroupCode = ""

    var body: some View {
        NavigationStack {
            VStack {
                if let user = dataModel.currentUser {
                    Text("User ID: \(user.id)")
                    Text("Name: \(user.name)")
                    Text("Email: \(user.email)")
                    Text("Group IDs: \(user.groupIDs.joined(separator: ", "))")
                
                } else {
                    Text("No user data available")
                }
                Text("TODO CHANGE ALL ID'S TO NAMES")
                Text("TODO ADD VENMO TO SIGNUP FOR EVERY MEMBER")
                
                List(dataModel.groups) { group in
                    NavigationLink(destination: GroupView(group: group)) {
                        VStack(alignment: .leading) {
                            Text("Group Name: \(group.groupName)")
                            Text("Group Code: \(group.groupCode)")
                            Text("Creator ID: \(group.creatorID)")
                            Text("User IDs: \(group.userIDs.joined(separator: ", "))")
                        }
                    }
                }
                
                HStack {
                    Button("Create Group") {
                        showCreateGroupSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Button("Join Group") {
                        showJoinGroupSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.leading)
                .padding(.trailing)
            }
            .sheet(isPresented: $showCreateGroupSheet) {
                VStack {
                    TextField("Group Name", text: $groupName)
                    TextField("Group Code", text: $groupCode)
                    
                    Button("Create") {
                        createGroup()
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showJoinGroupSheet) {
                VStack {
                    TextField("Group Code", text: $joinGroupCode)
                    
                    Button("Join") {
                        joinGroup()
                    }
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            if let userID = UserDefaults.standard.string(forKey: "userID") {
                dataModel.fetchUserData(userID: userID)
            }
        }
    }
    
    private func createGroup() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("No user ID found")
            return
        }
        
        FirebaseManager.shared.createGroup(groupName: groupName, groupCode: groupCode, userID: userID) { result in
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
        
        FirebaseManager.shared.joinGroup(userID: userID, groupCode: joinGroupCode) { result in
            switch result {
            case .success:
                print("Joined group successfully")
                showJoinGroupSheet = false
                dataModel.fetchUserData(userID: userID)
            case .failure(let error):
                print("Error joining group: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    HomeView()
}
