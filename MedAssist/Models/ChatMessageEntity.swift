//
//  ChatMessageEntity.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 29.12.24.
//

import Foundation
import SwiftData

/// `ChatMessageEntity` repräsentiert eine einzelne Nachricht innerhalb einer Chat-Konversation.
/// Diese Klasse ist ein SwiftData-Modell und enthält Informationen über den Inhalt, den Absender und den Zeitpunkt der Nachricht.
@Model
final class ChatMessageEntity {
    /// Eindeutige Kennung der Nachricht.
    var id: UUID
    /// Der Inhalt der Nachricht.
    var content: String
    /// Gibt an, ob die Nachricht vom Nutzer (`true`) oder vom System (`false`) stammt.
    var isUser: Bool
    /// Der Zeitpunkt, zu dem die Nachricht erstellt wurde.
    var timestamp: Date
    
    /// Verweis auf die zugehörige `ChatConversation`.
    var conversation: ChatConversation?
    
    /// Initialisiert eine neue Instanz von `ChatMessageEntity`.
    ///
    /// - Parameters:
    ///   - content: Der Inhalt der Nachricht.
    ///   - isUser: Ein Boolean-Wert, der angibt, ob die Nachricht vom Nutzer stammt.
    ///   - timestamp: Der Zeitpunkt der Erstellung der Nachricht. Standardmäßig ist dies die aktuelle Zeit.
    ///   - conversation: Die zugehörige `ChatConversation`, falls vorhanden.
    init(
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        conversation: ChatConversation? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.conversation = conversation
    }
}
