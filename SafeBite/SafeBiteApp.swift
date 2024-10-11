//
//  SafeBiteApp.swift
//  SafeBite
//
//  Created by Prathyush Yeturi on 8/10/24.
//

import SwiftUI
import SwiftData

@main
struct SafeBiteApp: App {
    @StateObject private var vm = AppViewModel()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Product.self,
            ChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .modelContainer(sharedModelContainer)
        }
    }
}
