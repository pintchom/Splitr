//
//  Firebase.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}
    
    func signUp(name: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(error))
            } else if let user = authResult?.user {
                self.createUser(id: user.uid, name: name, email: email) { result in
                    switch result {
                    case .success:
                        completion(.success(user))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    private func createUser(id: String, name: String, email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "groupIDs": []
        ]
        
        db.collection("users").document(id).setData(userData, merge: true) { error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User created successfully")
                completion(.success(()))
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        print(email, password)
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(error))
            } else if let user = authResult?.user {
                completion(.success(user))
            }
        }
    }
    
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func createGroup(groupName: String, groupCode: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        
        // First, fetch the user's name
        db.collection("users").document(userID).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let userName = document.data()?["name"] as? String else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found or name not available"])
                completion(.failure(error))
                return
            }
            
            let groupData: [String: Any] = [
                "groupName": groupName,
                "groupCode": groupCode,
                "creatorID": userID,
                "userIDs": [userID],
                "purchases": [],
                "purchaseCounter": 0,
                "userNames": [userID: userName]
            ]
            
            db.collection("groups").document(groupCode).setData(groupData) { error in
                if let error = error {
                    print("Error creating group: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    // Update the user's groupIDs
                    let userRef = db.collection("users").document(userID)
                    userRef.updateData([
                        "groupIDs": FieldValue.arrayUnion([groupCode])
                    ]) { error in
                        if let error = error {
                            print("Error updating user's groupIDs: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("Group created and user updated successfully")
                            completion(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    func retrieveUser(userID: String, completion: @escaping (Result<(name: String, email: String, groupIDs: [String]), Error>) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error retrieving user: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, document.exists {
                let data = document.data()
                let name = data?["name"] as? String ?? ""
                let email = data?["email"] as? String ?? ""
                let groupIDs = data?["groupIDs"] as? [String] ?? []
                
                completion(.success((name: name, email: email, groupIDs: groupIDs)))
            } else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                completion(.failure(error))
            }
        }
    }
    
    func retrieveGroup(groupCode: String, completion: @escaping (Result<(groupName: String, creatorID: String, userIDs: [String], purchases: [Purchase], userNames: [String: String]), Error>) -> Void) {
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupCode)
        
        groupRef.getDocument { (document, error) in
            if let error = error {
                print("Error retrieving group: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, document.exists {
                let data = document.data()
                let groupName = data?["groupName"] as? String ?? ""
                let creatorID = data?["creatorID"] as? String ?? ""
                let userIDs = data?["userIDs"] as? [String] ?? []
                let purchasesData = data?["purchases"] as? [[String: Any]] ?? []
                let userNames = data?["userNames"] as? [String: String] ?? [:]
                
                let purchases = purchasesData.compactMap { purchaseData -> Purchase? in
                    guard let id = purchaseData["id"] as? Int,
                          let purchaser = purchaseData["purchaser"] as? String,
                          let cost = purchaseData["cost"] as? Double,
                          let description = purchaseData["description"] as? String,
                          let percentages = purchaseData["percentages"] as? [String: Double] else {
                        return nil
                    }
                    return Purchase(id: id, purchaser: purchaser, cost: cost, description: description, percentages: percentages)
                }
                
                completion(.success((groupName: groupName, creatorID: creatorID, userIDs: userIDs, purchases: purchases, userNames: userNames)))
            } else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                completion(.failure(error))
            }
        }
    }
    
    func joinGroup(userID: String, groupCode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        let groupRef = db.collection("groups").document(groupCode)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            let groupDocument: DocumentSnapshot
            
            do {
                try userDocument = transaction.getDocument(userRef)
                try groupDocument = transaction.getDocument(groupRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let _ = userDocument.data(), userDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard let _ = groupDocument.data(), groupDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["groupIDs": FieldValue.arrayUnion([groupCode])], forDocument: userRef)
            transaction.updateData(["userIDs": FieldValue.arrayUnion([userID])], forDocument: groupRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error joining group: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User joined group successfully")
                completion(.success(()))
            }
        }
    }
    
    func addPurchase(groupCode: String, purchaser: String, cost: Double, description: String, percentages: [String: Double], completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupCode)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let groupDocument: DocumentSnapshot
            
            do {
                try groupDocument = transaction.getDocument(groupRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var groupData = groupDocument.data(), groupDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            let currentCounter = groupData["purchaseCounter"] as? Int ?? 0
            let newCounter = currentCounter + 1
            
            let newPurchase: [String: Any] = [
                "id": newCounter,
                "purchaser": purchaser,
                "cost": cost,
                "description": description,
                "percentages": percentages
            ]
            
            transaction.updateData([
                "purchases": FieldValue.arrayUnion([newPurchase]),
                "purchaseCounter": newCounter
            ], forDocument: groupRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error adding purchase: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Purchase added successfully")
                completion(.success(()))
            }
        }
    }
    
    func removePurchase(groupCode: String, purchaseId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupCode)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let groupDocument: DocumentSnapshot
            
            do {
                try groupDocument = transaction.getDocument(groupRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var groupData = groupDocument.data(), groupDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var purchases = groupData["purchases"] as? [[String: Any]] ?? []
            purchases.removeAll { ($0["id"] as? Int) == purchaseId }
            
            transaction.updateData(["purchases": purchases], forDocument: groupRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error removing purchase: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Purchase removed successfully")
                completion(.success(()))
            }
        }
    }
}
