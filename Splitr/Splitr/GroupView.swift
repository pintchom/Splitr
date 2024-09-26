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
    @State private var isPresentingWhoOwesWhatView = false
    
    init(group: GroupData) {
        _group = State(initialValue: group)
    }
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text(group.groupName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("black"))
                    .padding()
                    .background(Color("cream2"))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(group.purchases) { purchase in
                            Button(action: {
                                selectedPurchase = purchase
                            }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(purchase.description)
                                        .font(.headline)
                                        .foregroundColor(Color("black"))
                                    Text("Cost: $\(String(format: "%.2f", purchase.cost))")
                                        .foregroundColor(Color("black").opacity(0.8))
                                    Text("Purchaser: \(group.userNames[purchase.purchaser] ?? "Unknown")")
                                        .foregroundColor(Color("black").opacity(0.8))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color("cream1"))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 20) {
                    Button("Add Purchase") {
                        isPresentingPurchaseView = true
                    }
                    .buttonStyle(CustomButtonStyle())
                    
                    Button("Dues") {
                        isPresentingWhoOwesWhatView = true
                    }
                    .buttonStyle(CustomButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $isPresentingPurchaseView) {
            PurchaseView(group: $group)
                .onDisappear {
                    fetchGroupData()
                }
        }
        .sheet(item: $selectedPurchase) { purchase in
            SinglePurchaseView(purchase: purchase, groupCode: group.groupCode, group: group)
        }
        .sheet(isPresented: $isPresentingWhoOwesWhatView) {
            WhoOwesWhatView(group: group)
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
                                           purchases: groupData.purchases,
                                           userNames: groupData.userNames)
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
    ], userNames: ["user1": "John Doe"]))
}
