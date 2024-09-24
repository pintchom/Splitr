//
//  GroupView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct GroupView: View {
    @StateObject private var dataModel = DataModel()
    @State private var group: GroupData
    @State private var isPresentingPurchaseView = false
    @State private var selectedPurchase: Purchase?
    
    init(group: GroupData) {
        _group = State(initialValue: group)
    }
    
    var body: some View {
        VStack {
            Text("Group: \(group.groupName)")
                .font(.title)
                .padding()
            Text("TODO MAKE THIS UPDATE EVERY TIME ITS OPENED")
            Text("TODO ADD HOW MUCH CURRENT USER OWES EVERYONE")
            Text("TODO MAKE SURE PURCHASER IS NOT CHARGED FOR HIS OWN PURCHASES")

            Button {
                fetchGroupData()
            } label: {
                Text("Refresh")
            }

            
            List {
                ForEach(group.purchases) { purchase in
                    Button(action: {
                        selectedPurchase = purchase
                    }) {
                        VStack(alignment: .leading) {
                            Text(purchase.description)
                                .font(.headline)
                            Text("Cost: $\(String(format: "%.2f", purchase.cost))")
                            Text("Purchaser: \(purchase.purchaser)")
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            
            Button("Add Purchase") {
                isPresentingPurchaseView = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $isPresentingPurchaseView) {
            PurchaseView(group: group)
        }
        .sheet(item: $selectedPurchase) { purchase in
            SinglePurchaseView(purchase: purchase, groupCode: group.groupCode)
        }
        .onAppear {
            fetchGroupData()
        }
    }
    
    private func fetchGroupData() {
        let code = group.groupCode
        FirebaseManager.shared.retrieveGroup(groupCode: group.groupCode) { result in
            switch result {
            case .success(let groupData):
                DispatchQueue.main.async {
                    self.group = GroupData(groupCode: code,
                                           groupName: groupData.groupName,
                                           creatorID: groupData.creatorID,
                                           userIDs: groupData.userIDs,
                                           purchases: groupData.purchases)
                }
            case .failure(let error):
                print("Failed to retrieve group data: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    GroupView(group: GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1"], purchases: [
        Purchase(id: 1, purchaser: "user1", cost: 50.0, description: "Groceries", percentages: ["user1": 100.0]),
        Purchase(id: 2, purchaser: "user1", cost: 30.0, description: "Gas", percentages: ["user1": 100.0])
    ]))
}
