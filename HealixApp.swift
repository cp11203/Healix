//
//  HealixApp.swift
//  Healix
//
//  Created by chaitanya prasad on 16/03/25.
//

import SwiftUI

@main
struct HealixApp: App {
    // Initialize persistence controller early and make it a let constant
    let persistenceController = PersistenceController.shared
    
    // Add this initializer to ensure model is loaded before views appear
    init() {
        // Force the container to load immediately
        _ = persistenceController.container.viewContext
    }

    var body: some Scene {
        WindowGroup {
            // Check if user is logged in
            if isUserLoggedIn() {
                NavigationStack {
                    MainView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            } else {
                NavigationStack {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
        }
    }
    
    // Check if user is logged in
    private func isUserLoggedIn() -> Bool {
        if let userIdString = UserDefaults.standard.string(forKey: "loggedInUserId"),
           UUID(uuidString: userIdString) != nil {
            return true
        }
        return false
    }
}
