//
//  ConversationDetailView.swift
//  MediHub
//
//  Created by Sasan Rafat Nami on 29.12.24.
//

import SwiftUI
import SwiftData

/// `ConversationDetailView` zeigt die Details einer spezifischen Chat-Konversation.
/// Hierbei wird der gesamte Chat-Verlauf angezeigt, jedoch ohne ein Eingabefeld für neue Nachrichten.
struct ConversationDetailView: View {
    
    /// Die spezifische `ChatConversation`, deren Details angezeigt werden.
    let conversation: ChatConversation

    var body: some View {
        ChatView(
            conversation: conversation,
            initialInput: .constant("")
        )
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
