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
    @State private var showPaySheet: Bool = false
    @State private var payAmount: String = ""
    @State private var selectedCreditor: String = ""
    @EnvironmentObject var dataModel: DataModel
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    if let currentUserBalances = balances[currentUserID] {
                        Group {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your Debts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("black"))
                                    .padding(.bottom, 5)
                                ForEach(currentUserBalances.sorted(by: { $0.value > $1.value }), id: \.key) { otherUserID, amount in
                                    if amount > 0 {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("YOU owe \(group.userNames[otherUserID] ?? "Unknown")")
                                                    .foregroundColor(Color("black"))
                                                Text(group.userPayments[otherUserID] ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text("$\(String(format: "%.2f", amount))")
                                                .foregroundColor(.red)
                                                .fontWeight(.semibold)
                                            Button(action: {
                                                selectedCreditor = otherUserID
                                                showPaySheet = true
                                            }) {
                                                Text("Pay")
                                                    .foregroundColor(.blue)
                                            }
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
                                        VStack(alignment: .leading) {
                                            Text("\(group.userNames[userID] ?? "Unknown") owes \(group.userNames[otherUserID] ?? "Unknown")")
                                                .foregroundColor(Color("black"))
                                            Text(group.userPayments[otherUserID] ?? "NONE FOUND")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .onAppear {
                                            print(group.userPayments)
                                        }
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Payment History")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("black"))
                            .padding(.bottom, 5)
                        ForEach(group.paymentHistory.indices, id: \.self) { index in
                            let payment = group.paymentHistory[index]
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(group.userNames[payment["payer"] as? String ?? ""] ?? "Unknown") paid \(group.userNames[payment["receiver"] as? String ?? ""] ?? "Unknown")")
                                        .foregroundColor(Color("black"))
                                    Text(group.userPayments[payment["receiver"] as? String ?? ""] ?? "")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("$\(String(format: "%.2f", payment["amount"] as? Double ?? 0.0))")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color("cream2"))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding()
                    .background(Color("cream1"))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding()
            }
            if showPaySheet {
                VStack {
                    Text("Pay Amount")
                        .font(.headline)
                        .padding()
                    
                    TextField("Enter amount", text: $payAmount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color("cream2"))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        .padding()
                    
                    Button(action: {
                        if let amount: Double = Double(payAmount), amount > 0, amount <= (balances[currentUserID]?[selectedCreditor] ?? 0) {
                            payOffDebt(to: selectedCreditor, amount: amount)
                            showPaySheet = false
                        }
                    }) {
                        Text("Submit")
                            .fontWeight(.bold)
                            .foregroundColor(Color("cream3"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("black"))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding()
                    
                    Button(action: {
                        showPaySheet = false
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                    .padding()
                }
                .padding()
                .background(Color("cream3"))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.8), radius: 10, x: 0, y: 7)
            }

        }
        .onAppear(perform: calculateBalances)
    }
    
    private func calculateBalances() {
        print(group.balances)
        balances = group.balances
        print(balances)
        
        // Simplify balances
        for (debtor, creditors) in balances {
            for (creditor, amount) in creditors {
                if amount > 0 {
                    balances[debtor]?[creditor] = amount
                    balances[creditor]?[debtor] = -(amount)
                }
            }
        }
    }
    
    private func payOffDebt(to creditor: String, amount: Double) -> Void {
        print("ATTEMPING TO PAY OFF \(amount)")
        dataModel.makePayment(groupCode: group.groupCode, payerID: currentUserID, receiverID: creditor, amount: amount)
        DispatchQueue.main.async {
            // Update the balances and payment history in the view
            if let currentAmount = balances[currentUserID]?[creditor] {
                let newAmount = currentAmount - amount
                balances[currentUserID]?[creditor] = newAmount
                balances[creditor]?[currentUserID] = -newAmount
            }
            group.paymentHistory.append(["payer": currentUserID, "receiver": creditor, "amount": amount, "timestamp": Date()])
        }
        return
    }
    
}

#Preview {
    WhoOwesWhatView(group: GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1", "user2", "user3"], purchases: [
        Purchase(id: 1, purchaser: "user1", cost: 100.0, description: "Groceries", percentages: ["user1": 50.0, "user2": 25.0, "user3": 25.0]),
        Purchase(id: 2, purchaser: "user2", cost: 60.0, description: "Dinner", percentages: ["user1": 33.33, "user2": 33.33, "user3": 33.33])
    ], userNames: ["user1": "Alice", "user2": "Bob", "user3": "Charlie"], userPayments: ["user1": "@alice", "user2": "@bob", "user3": "@charlie"], paymentHistory: [
        ["payer": "user2", "receiver": "user1", "amount": 20.0, "timestamp": Date()],
        ["payer": "user3", "receiver": "user1", "amount": 15.0, "timestamp": Date()]
    ]))
    .environmentObject(DataModel())
}
