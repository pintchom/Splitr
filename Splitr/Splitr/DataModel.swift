//
//  DataModel.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import Foundation

class UserData: ObservableObject, Identifiable {
    let id: String
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var groupIDs: [String] = []
    
    init(id: String) {
        self.id = id
    }
    
    func updateUser(name: String, email: String, groupIDs: [String]) {
        self.name = name
        self.email = email
        self.groupIDs = groupIDs
    }
}

struct Purchase: Identifiable {
    let id: Int
    let purchaser: String
    let cost: Double
    let description: String
    let percentages: [String: Double]
}

class GroupData: ObservableObject, Identifiable {
    var groupCode: String
    @Published var groupName: String
    @Published var creatorID: String
    @Published var userIDs: [String]
    @Published var purchases: [Purchase]
    @Published var userNames: [String: String]
    
    var id: String { groupCode }
    
    init(groupCode: String, groupName: String, creatorID: String, userIDs: [String], purchases: [Purchase] = [], userNames: [String: String] = [:]) {
        self.groupCode = groupCode
        self.groupName = groupName
        self.creatorID = creatorID
        self.userIDs = userIDs
        self.purchases = purchases
        self.userNames = userNames
    }
}

class DataModel: ObservableObject {
    @Published var currentUser: UserData?
    @Published var groups: [GroupData] = []
    
    func fetchUserData(userID: String) {
        FirebaseManager.shared.retrieveUser(userID: userID) { result in
            switch result {
            case .success(let userData):
                DispatchQueue.main.async {
                    if self.currentUser == nil {
                        self.currentUser = UserData(id: userID)
                    }
                    self.currentUser?.updateUser(name: userData.name, email: userData.email, groupIDs: userData.groupIDs)
                    self.fetchGroupsData(groupIDs: userData.groupIDs)
                }
            case .failure(let error):
                print("Failed to retrieve user data: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchGroupsData(groupIDs: [String]) {
        self.groups.removeAll()
        for groupID in groupIDs {
            FirebaseManager.shared.retrieveGroup(groupCode: groupID) { result in
                switch result {
                case .success(let groupData):
                    DispatchQueue.main.async {
                        let newGroup = GroupData(groupCode: groupID, 
                                                 groupName: groupData.groupName, 
                                                 creatorID: groupData.creatorID, 
                                                 userIDs: groupData.userIDs, 
                                                 purchases: groupData.purchases,
                                                 userNames: groupData.userNames)
                        self.groups.append(newGroup)
                        self.fetchUserNames(for: newGroup)
                    }
                case .failure(let error):
                    print("Failed to retrieve group data for group \(groupID): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchUserNames(for group: GroupData) {
        for userID in group.userIDs {
            if group.userNames[userID] == nil {
                FirebaseManager.shared.retrieveUser(userID: userID) { result in
                    switch result {
                    case .success(let userData):
                        DispatchQueue.main.async {
                            group.userNames[userID] = userData.name
                        }
                    case .failure(let error):
                        print("Failed to retrieve user name for user \(userID): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func removePurchase(groupCode: String, purchaseID: Int) {
        FirebaseManager.shared.removePurchase(groupCode: groupCode, purchaseId: purchaseID) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if let currentUser = self.currentUser {
                        self.fetchGroupsData(groupIDs: currentUser.groupIDs)
                    }
                }
            case .failure(let error):
                print("Failed to remove purchase: \(error.localizedDescription)")
            }
        }
    }
}
