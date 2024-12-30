//
//  MedAssistApp.swift
//  MediHub
//
//  Created by Beispiel on 14.12.24.
//

import SwiftUI
import SwiftData

@main
struct MedAssistApp: App {
    /// SwiftData-Container, in dem unsere Modelle gespeichert werden.
    @State private var container = {
        do {
            // Falls du Konfiguration brauchst:
            // let config = ModelConfiguration(...)
            // return try ModelContainer(for: ChatConversation.self, ChatMessageEntity.self, configurations: [config])

            return try ModelContainer(for: ChatConversation.self, ChatMessageEntity.self)
        } catch {
            fatalError("Fehler beim Erstellen des ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Home()
                // SwiftData-Container wird per Environment weitergegeben:
                .modelContainer(container)
        }
    }
}

