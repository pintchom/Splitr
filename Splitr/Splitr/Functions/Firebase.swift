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
    
    func signUp(name: String, email: String, password: String, payment: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(.failure(error))
            } else if let user = authResult?.user {
                self.createUser(id: user.uid, name: name, email: email, payment: payment) { result in
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
    
    private func createUser(id: String, name: String, email: String, payment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "payment": payment,
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
        
        // First, fetch the user's name and payment info
        db.collection("users").document(userID).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let userName = document.data()?["name"] as? String,
                  let userPayment = document.data()?["payment"] as? String else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found or data not available"])
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
                "userNames": [userID: userName],
                "userPayments": [userID: userPayment],
                "balances": [userID: [:]],
                "paymentHistory": [] // Initialize payment history
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
    
    func retrieveUser(userID: String, completion: @escaping (Result<(name: String, email: String, payment: String, groupIDs: [String]), Error>) -> Void) {
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
                let payment = data?["payment"] as? String ?? ""
                let groupIDs = data?["groupIDs"] as? [String] ?? []
                
                completion(.success((name: name, email: email, payment: payment, groupIDs: groupIDs)))
            } else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                completion(.failure(error))
            }
        }
    }
    
    func retrieveGroup(groupCode: String, completion: @escaping (Result<(groupName: String, creatorID: String, userIDs: [String], purchases: [Purchase], userNames: [String: String], userPayments: [String: String], balances: [String: [String: Double]], paymentHistory: [[String: Any]]), Error>) -> Void) {
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
                let userPayments = data?["userPayments"] as? [String: String] ?? [:]
                let balances = data?["balances"] as? [String: [String: Double]] ?? [:]
                print("balances from retrieveGroup: \(balances)")
                let paymentHistory = data?["paymentHistory"] as? [[String: Any]] ?? []
                
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
                
                completion(.success((groupName: groupName, creatorID: creatorID, userIDs: userIDs, purchases: purchases, userNames: userNames, userPayments: userPayments, balances: balances, paymentHistory: paymentHistory)))
            } else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                completion(.failure(error))
            }
        }
    }
    
    func joinGroup(userID: String, groupCode: String, groupName: String, completion: @escaping (Result<Void, Error>) -> Void) {
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
            
            guard let userData = userDocument.data(), userDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard var groupData = groupDocument.data(), groupDocument.exists else {
                let error = NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            guard let existingGroupName = groupData["groupName"] as? String, existingGroupName == groupName else {
                let error = NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Group name does not match"])
                errorPointer?.pointee = error
                return nil
            }
            
            let userName = userData["name"] as? String ?? "Unknown User"
            let userPayment = userData["payment"] as? String ?? ""
            var userNames = groupData["userNames"] as? [String: String] ?? [:]
            var userPayments = groupData["userPayments"] as? [String: String] ?? [:]
            userNames[userID] = userName
            userPayments[userID] = userPayment
            
            var balances = groupData["balances"] as? [String: [String: Double]] ?? [:]
            balances[userID] = [:]
            
            var paymentHistory = groupData["paymentHistory"] as? [[String: Any]] ?? []
            
            transaction.updateData(["groupIDs": FieldValue.arrayUnion([groupCode])], forDocument: userRef)
            transaction.updateData([
                "userIDs": FieldValue.arrayUnion([userID]),
                "userNames": userNames,
                "userPayments": userPayments,
                "balances": balances,
                "paymentHistory": paymentHistory
            ], forDocument: groupRef)
            
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
            
            // Update balances
            var balances = groupData["balances"] as? [String: [String: Double]] ?? [:]
            for (userID, percentage) in percentages {
                print(userID, percentage)
                let amountOwed = cost * (percentage / 100)
                print(amountOwed)
                if userID != purchaser {
                    balances[userID, default: [:]][purchaser, default: 0] += amountOwed
                    balances[purchaser, default: [:]][userID, default: 0] -= amountOwed
                }
            }
            
            transaction.updateData([
                "purchases": FieldValue.arrayUnion([newPurchase]),
                "purchaseCounter": newCounter,
                "balances": balances
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
            var balances = groupData["balances"] as? [String: [String: Double]] ?? [:]
            
            if let purchaseIndex = purchases.firstIndex(where: { ($0["id"] as? Int) == purchaseId }) {
                let purchase = purchases[purchaseIndex]
                let cost = purchase["cost"] as? Double ?? 0
                let purchaser = purchase["purchaser"] as? String ?? ""
                let percentages = purchase["percentages"] as? [String: Double] ?? [:]
                
                // Reverse the balances
                for (userID, percentage) in percentages {
                    let amountOwed = cost * percentage
                    if userID != purchaser {
                        balances[userID, default: [:]][purchaser, default: 0] -= amountOwed
                        balances[purchaser, default: [:]][userID, default: 0] += amountOwed
                    }
                }
                
                purchases.remove(at: purchaseIndex)
            }
            
            transaction.updateData([
                "purchases": purchases,
                "balances": balances
            ], forDocument: groupRef)
            
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

    func payoff(groupCode: String, payer: String, receiver: String, amount: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        print("MAKING PAYMENT IN FIREBASE")
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
            
            var balances = groupData["balances"] as? [String: [String: Double]] ?? [:]
            var paymentHistory = groupData["paymentHistory"] as? [[String: Any]] ?? []
            
            // Update balances
            balances[payer, default: [:]][receiver, default: 0] -= amount
            balances[receiver, default: [:]][payer, default: 0] += amount
            
            // Clean up zero balances
            if balances[payer]?[receiver] == 0 {
                balances[payer]?.removeValue(forKey: receiver)
            }
            if balances[receiver]?[payer] == 0 {
                balances[receiver]?.removeValue(forKey: payer)
            }
            
            print("balances post changes \(balances)")
            
            // Add to payment history
            let payment: [String: Any] = [
                "payer": payer,
                "receiver": receiver,
                "amount": amount,
                "timestamp": Timestamp(date: Date()) // Use Timestamp instead of FieldValue.serverTimestamp()
            ]
            paymentHistory.append(payment)
            print("history post changes \(paymentHistory)")
            transaction.updateData([
                "balances": balances,
                "paymentHistory": paymentHistory
            ], forDocument: groupRef)
            
            return nil
        }) { (_, error) in
            if let error = error {
                print("Error processing payoff: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Payoff processed successfully")
                completion(.success(()))
            }
        }
    }
}
