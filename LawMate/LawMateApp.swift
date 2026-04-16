//
//  LawMateApp.swift
//  LawMate
//
//  Created by COBSCCOMP242P-030 on 2026-04-07.
//

import SwiftUI
import FirebaseCore

@main
struct LawMateApp: App {
    @UIApplicationDelegateAdaptor(LawMateAppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light) // LawMate uses a light theme
        }
    }
}
