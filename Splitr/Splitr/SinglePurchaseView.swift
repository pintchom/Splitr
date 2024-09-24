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
    @EnvironmentObject var dataModel: DataModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(purchase.description)
                .font(.headline)
            
            Text("Cost: $\(String(format: "%.2f", purchase.cost))")
                .font(.subheadline)
            
            Text("Purchaser: \(purchase.purchaser)")
                .font(.subheadline)
            
            Text("Breakdown:")
                .font(.subheadline)
                .fontWeight(.bold)
            
            ForEach(Array(purchase.percentages.keys.sorted()), id: \.self) { user in
                if let percentage = purchase.percentages[user] {
                    let amount = purchase.cost * percentage / 100
                    HStack {
                        Text("\(user):")
                        Spacer()
                        Text("\(Int(percentage))% - $\(String(format: "%.2f", amount))")
                    }
                    .font(.caption)
                }
            }
            
            if UserDefaults.standard.string(forKey: "userID") == purchase.purchaser {
                Button(action: {
                    dataModel.removePurchase(groupCode: groupCode, purchaseID: purchase.id)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Remove Purchase")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .padding()
    }
}

#Preview {
    SinglePurchaseView(purchase: Purchase(id: 1, purchaser: "John", cost: 100.0, description: "Dinner", percentages: ["John": 50.0, "Alice": 50.0]), groupCode: "0")
        .environmentObject(DataModel())
}
