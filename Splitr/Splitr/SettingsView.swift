//
//  SettingsView.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/26/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataModel: DataModel
    
    var body: some View {
        ZStack {
            Color("cream3")
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("black"))
                    .padding()
                
                Spacer()
                
                Button(action: {
                    FirebaseManager.shared.logout { result in
                        switch result {
                        case .success:
                            dataModel.currentUser = nil
                            dataModel.groups.removeAll()
                            UserDefaults.standard.set(nil, forKey: "userID")
                            presentationMode.wrappedValue.dismiss()
                            dismiss()
                        case .failure(let error):
                            print("Logout failed: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Logout")
                        .foregroundColor(Color("black"))
                        .padding()
                        .background(Color("cream2"))
                        .cornerRadius(10)
                        .shadow(color: Color("black").opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
                
                Spacer()
            }
        }
    }
}


#Preview {
    SettingsView()
        .environmentObject(DataModel())
}
