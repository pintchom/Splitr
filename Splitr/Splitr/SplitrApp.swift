//
//  SplitrApp.swift
//  Splitr
//
//  Created by Max Pintchouk on 9/23/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    return true
  }
}

@main
struct SplitrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var dataModel = DataModel()
    
    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(dataModel)
        }
    }
}
