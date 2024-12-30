//
//  ChatConversation.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 29.12.24.
//

import Foundation
import SwiftData

/// `ChatConversation` repräsentiert eine einzelne Chat-Konversation.
/// Diese Klasse ist ein SwiftData-Modell und enthält den Titel, das Erstellungsdatum und die zugehörigen Nachrichten der Konversation.
@Model
final class ChatConversation {
    /// Eindeutige Kennung der Konversation.
    var id: UUID
    /// Der Titel der Konversation, z.B. ein Thema oder eine Zusammenfassung.
    var title: String
    /// Das Datum und die Uhrzeit, zu der die Konversation erstellt wurde.
    var createdAt: Date
    
    /// Eine Liste von Nachrichten (`ChatMessageEntity`) die zur Konversation gehören.
    /// Diese Beziehung wird ohne ein spezielles Relationship-Attribut definiert.
    var messages: [ChatMessageEntity]
    
    /// Initialisiert eine neue Instanz von `ChatConversation`.
    ///
    /// - Parameters:
    ///   - title: Der Titel der Konversation.
    ///   - createdAt: Das Erstellungsdatum der Konversation. Standardmäßig ist dies die aktuelle Zeit.
    init(title: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.createdAt = createdAt
        self.messages = []
    }
}
