//
//  ChatArchive.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI
import SwiftData

/// `ChatArchive` ist eine SwiftUI-View, die alle gespeicherten Chat-Konversationen anzeigt.
/// Nutzer können Konversationen auswählen, um Details einzusehen oder sie mittels Swipe-to-Delete löschen.
struct ChatArchive: View {
    
    /// Der aktuelle Kontext des SwiftData-Modells, ermöglicht das Lesen und Schreiben von Daten.
    @Environment(\.modelContext) private var context
    
    /// Abfrage aller vorhandenen `ChatConversation`-Modelle aus der Datenbank.
    /// Die Konversationen werden nach ihrem Erstellungsdatum absteigend sortiert, sodass die neuesten Konversationen zuerst angezeigt werden.
    @Query(sort: \ChatConversation.createdAt, order: .reverse)
    private var allConversations: [ChatConversation]
    
    var body: some View {
        NavigationView {
            VStack {
                if allConversations.isEmpty {
                    // Anzeige einer leeren Archivansicht, wenn keine Konversationen vorhanden sind.
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "archivebox.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("Keine gespeicherten Konversationen")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Hier werden später alle gespeicherten Konversationen angezeigt.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // Anzeige der Liste aller vorhandenen Konversationen.
                    List {
                        // Integration von `ForEach` in die `List` ermöglicht die Swipe-to-Delete-Funktionalität.
                        ForEach(allConversations) { conversation in
                            NavigationLink(destination: ConversationDetailView(conversation: conversation)) {
                                HStack {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(conversation.title)
                                            .font(.headline)
                                        
                                        // Anzeige der letzten Nachricht als Vorschau, falls vorhanden.
                                        if let lastMessage = conversation.messages.last?.content {
                                            Text(lastMessage)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        } else {
                                            Text("Noch keine Nachrichten")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        // Ermöglicht das Löschen von Konversationen mittels Swipe-Geste.
                        .onDelete(perform: deleteConversations)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Archiv")
        }
    }
    
    /// Löscht ausgewählte Konversationen aus der Datenbank.
    /// Diese Methode wird durch die Swipe-to-Delete-Geste in der Liste aufgerufen.
    ///
    /// - Parameter offsets: Die Indizes der zu löschenden Konversationen.
    private func deleteConversations(at offsets: IndexSet) {
        withAnimation {
            // Bestimmung der zu löschenden Konversationen basierend auf den übergebenen Indizes.
            offsets.map { allConversations[$0] }
                   .forEach(context.delete(_:))   // Entfernen aus dem SwiftData-Kontext
            
            // Versuch, die Änderungen im Kontext zu speichern.
            do {
                try context.save()
            } catch {
                // Fehlerbehandlung: Ausgabe einer Fehlermeldung in der Konsole.
                print("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ChatArchive()
}
