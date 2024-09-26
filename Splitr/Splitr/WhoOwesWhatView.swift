//
//  WhoOwesWhatView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/25/24.
//

import SwiftUI

struct WhoOwesWhatView: View {
    let group: GroupData
    @State private var balances: [String: [String: Double]] = [:]
    @State private var currentUserID: String = UserDefaults.standard.string(forKey: "userID") ?? ""
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    if let currentUserBalances = balances[currentUserID] {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Debts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("black"))
                                .padding(.bottom, 5)
                            ForEach(currentUserBalances.sorted(by: { $0.value > $1.value }), id: \.key) { otherUserID, amount in
                                if amount > 0 {
                                    HStack {
                                        Text("YOU owe \(group.userNames[otherUserID] ?? "Unknown")")
                                            .foregroundColor(Color("black"))
                                        Spacer()
                                        Text("$\(String(format: "%.2f", amount))")
                                            .foregroundColor(.red)
                                            .fontWeight(.semibold)
                                    }
                                    .padding()
                                    .background(Color("cream2"))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                        .background(Color("cream1"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    
                    ForEach(group.userIDs.filter { $0 != currentUserID }, id: \.self) { userID in
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(group.userNames[userID] ?? "Unknown")'s Debts")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color("black"))
                                .padding(.bottom, 5)
                            ForEach(group.userIDs.filter { $0 != userID }, id: \.self) { otherUserID in
                                if let amount = balances[userID]?[otherUserID], amount > 0 {
                                    HStack {
                                        Text("\(group.userNames[userID] ?? "Unknown") owes \(group.userNames[otherUserID] ?? "Unknown")")
                                            .foregroundColor(Color("black"))
                                        Spacer()
                                        Text("$\(String(format: "%.2f", amount))")
                                            .foregroundColor(.red)
                                            .fontWeight(.semibold)
                                    }
                                    .padding()
                                    .background(Color("cream2"))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                        .background(Color("cream1"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                }
                .padding()
            }
        }
        .onAppear(perform: calculateBalances)
    }
    
    private func calculateBalances() {
        var tempBalances: [String: [String: Double]] = [:]
        
        for purchase in group.purchases {
            let purchaser = purchase.purchaser
            
            for (userID, percentage) in purchase.percentages {
                let amount = purchase.cost * percentage / 100
                
                if userID != purchaser {
                    tempBalances[userID, default: [:]][purchaser, default: 0] += amount
                    tempBalances[purchaser, default: [:]][userID, default: 0] -= amount
                }
            }
        }
        
        // Simplify balances
        for (debtor, creditors) in tempBalances {
            for (creditor, amount) in creditors {
                if amount > 0 {
                    tempBalances[debtor]?[creditor] = amount
                    tempBalances[creditor]?[debtor] = 0
                }
            }
        }
        
        balances = tempBalances
    }
}

#Preview {
    WhoOwesWhatView(group: GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1", "user2", "user3"], purchases: [
        Purchase(id: 1, purchaser: "user1", cost: 100.0, description: "Groceries", percentages: ["user1": 50.0, "user2": 25.0, "user3": 25.0]),
        Purchase(id: 2, purchaser: "user2", cost: 60.0, description: "Dinner", percentages: ["user1": 33.33, "user2": 33.33, "user3": 33.33])
    ], userNames: ["user1": "Alice", "user2": "Bob", "user3": "Charlie"]))
}
