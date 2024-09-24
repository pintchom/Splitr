//
//  PurchaseView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct PurchaseView: View {
    let group: GroupData
    @State private var cost: String = ""
    @State private var description: String = ""
    @State private var selectedUsers: [String: Bool] = [:]
    @State private var percentages: [String: String] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataModel: DataModel
    
    init(group: GroupData) {
        self.group = group
        _selectedUsers = State(initialValue: Dictionary(uniqueKeysWithValues: group.userIDs.map { ($0, false) }))
        _percentages = State(initialValue: Dictionary(uniqueKeysWithValues: group.userIDs.map { ($0, "") }))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Purchase Details")) {
                TextField("Cost", text: $cost)
                    .keyboardType(.decimalPad)
                TextField("Description", text: $description)
            }
            
            Section(header: Text("Split Between")) {
                ForEach(group.userIDs, id: \.self) { userID in
                    HStack {
                        Button(action: {
                            selectedUsers[userID]?.toggle()
                        }) {
                            Image(systemName: selectedUsers[userID] ?? false ? "circle.fill" : "circle")
                        }
                        Text(userID)
                        if selectedUsers[userID] ?? false {
                            TextField("Percentage", text: Binding(
                                get: { percentages[userID] ?? "" },
                                set: { percentages[userID] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                        }
                    }
                }
            }
            
            Section {
                Button("Submit Purchase") {
                    submitPurchase()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Purchase Submission"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func submitPurchase() {
        guard let costDouble = Double(cost), costDouble > 0 else {
            alertMessage = "Please enter a valid cost."
            showAlert = true
            return
        }
        
        guard !description.isEmpty else {
            alertMessage = "Please enter a description."
            showAlert = true
            return
        }
        
        let selectedPercentages = percentages.filter { selectedUsers[$0.key] == true }
        guard !selectedPercentages.isEmpty else {
            alertMessage = "Please select at least one user and enter their percentage."
            showAlert = true
            return
        }
        
        let percentagesDouble = selectedPercentages.mapValues { Double($0) ?? 0 }
        guard percentagesDouble.values.reduce(0, +) == 100 else {
            alertMessage = "The sum of percentages must equal 100."
            showAlert = true
            return
        }
        
        let purchaser = UserDefaults.standard.string(forKey: "userID") ?? ""
        
        FirebaseManager.shared.addPurchase(
            groupCode: group.groupCode,
            purchaser: purchaser,
            cost: costDouble,
            description: description,
            percentages: percentagesDouble
        ) { result in
            switch result {
            case .success:
                alertMessage = "Purchase added successfully."
                showAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Update the DataModel with the new purchase
                    if let index = self.dataModel.groups.firstIndex(where: { $0.id == self.group.id }) {
                        let newPurchase = Purchase(id: self.dataModel.groups[index].purchases.count + 1,
                                                   purchaser: purchaser,
                                                   cost: costDouble,
                                                   description: description,
                                                   percentages: percentagesDouble)
                        self.dataModel.groups[index].purchases.append(newPurchase)
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
            case .failure(let error):
                alertMessage = "Error adding purchase: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    PurchaseView(group: GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1", "user2", "user3"]))
        .environmentObject(DataModel())
}
