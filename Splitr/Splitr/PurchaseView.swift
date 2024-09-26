//
//  PurchaseView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI

struct PurchaseView: View {
    @Binding var group: GroupData
    @State private var cost: String = ""
    @State private var description: String = ""
    @State private var selectedUsers: [String: Bool] = [:]
    @State private var percentages: [String: String] = [:]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataModel: DataModel
    
    init(group: Binding<GroupData>) {
        self._group = group
        _selectedUsers = State(initialValue: Dictionary(uniqueKeysWithValues: group.wrappedValue.userIDs.map { ($0, false) }))
        _percentages = State(initialValue: Dictionary(uniqueKeysWithValues: group.wrappedValue.userIDs.map { ($0, "") }))
    }
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    purchaseDetailsSection
                    splitBetweenSection
                    submitButton
                }
                .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Purchase Submission"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var purchaseDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Purchase Details")
                .font(.headline)
                .foregroundColor(Color("black"))
            
            TextField("Cost", text: $cost)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            TextField("Description", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding()
        .background(Color("cream2"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var splitBetweenSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Split Between")
                .font(.headline)
                .foregroundColor(Color("black"))
            
            ForEach(group.userIDs, id: \.self) { userID in
                HStack {
                    Button(action: {
                        selectedUsers[userID]?.toggle()
                    }) {
                        Image(systemName: selectedUsers[userID] ?? false ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(Color("black"))
                    }
                    Text(group.userNames[userID] ?? userID)
                        .foregroundColor(Color("black"))
                    if selectedUsers[userID] ?? false {
                        TextField("Percentage", text: Binding(
                            get: { percentages[userID] ?? "" },
                            set: { percentages[userID] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    }
                }
            }
        }
        .padding()
        .background(Color("cream1"))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var submitButton: some View {
        Button(action: submitPurchase) {
            Text("Submit Purchase")
                .fontWeight(.bold)
                .foregroundColor(Color("cream3"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("black"))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
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
                    // Create and add the new purchase to the group
                    let newPurchase = Purchase(id: self.group.purchases.count + 1,
                                               purchaser: purchaser,
                                               cost: costDouble,
                                               description: description,
                                               percentages: percentagesDouble)
                    self.group.purchases.append(newPurchase)
                    
                    // Update the DataModel with the new purchase
                    if let index = self.dataModel.groups.firstIndex(where: { $0.id == self.group.id }) {
                        self.dataModel.groups[index] = self.group
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
    PurchaseView(group: .constant(GroupData(groupCode: "123", groupName: "Sample Group", creatorID: "user1", userIDs: ["user1", "user2", "user3"])))
        .environmentObject(DataModel())
}
