//
//  SinglePurchaseView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct SinglePurchaseView: View {
    let purchase: Purchase
    let groupCode: String
    let group: GroupData
    @EnvironmentObject var dataModel: DataModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                Text(purchase.description)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("black"))
                    .padding()
                    .background(Color("cream2"))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 15) {
                    InfoRow(title: "Cost", value: "$\(String(format: "%.2f", purchase.cost))")
                    InfoRow(title: "Purchaser", value: group.userNames[purchase.purchaser] ?? "ERROR ID NOT IN GROUP")
                    
                    Text("Breakdown:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("black"))
                        .padding(.top, 5)
                    
                    ForEach(Array(purchase.percentages.keys.sorted()), id: \.self) { user in
                        if let percentage = purchase.percentages[user] {
                            let amount = purchase.cost * percentage / 100
                            HStack {
                                Text("\(group.userNames[user] ?? "ERROR USER ID NOT FOUND"):")
                                Spacer()
                                Text("\(Int(percentage))% - $\(String(format: "%.2f", amount))")
                            }
                            .font(.subheadline)
                            .foregroundColor(Color("black"))
                        }
                    }
                }
                .padding()
                .background(Color("cream1"))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                if UserDefaults.standard.string(forKey: "userID") == purchase.purchaser {
                    Button(action: {
                        dataModel.removePurchase(groupCode: groupCode, purchaseID: purchase.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Remove Purchase")
                            .fontWeight(.semibold)
                            .foregroundColor(Color("cream3"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("black"))
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("black"))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color("black"))
        }
    }
}

#Preview {
    SinglePurchaseView(purchase: Purchase(id: 1, purchaser: "John", cost: 100.0, description: "Dinner", percentages: ["John": 50.0, "Alice": 50.0]), groupCode: "0", group: GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1", "user2", "user3"], userNames: ["John": "John", "Alice": "Alice"]))
        .environmentObject(DataModel())
}
