//
//  ChatViewModel.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import Foundation

/// Ein einzelner Chat-Nachrichteneintrag.
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

/// ViewModel für die Chat-Komponente der Anwendung.
final class ChatViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    
    /// Ruft die Antwort von der OpenAI-API ab und aktualisiert die Konversation.
    func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        // Fügt die Benutzereingabe zur Konversation hinzu.
        let userMessage = ChatMessage(content: userInput, isUser: true)
        messages.append(userMessage)
        
        // Eingabefeld leeren
        DispatchQueue.main.async {
            self.userInput = ""
        }
        isLoading = true
        
        // Konversationshistorie vorbereiten
        let conversationHistory = messages.map { message in
            [
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ]
        }
        
        // Anfrage an OpenAI-API senden
        OpenAIService.shared.fetchChatResponse(prompt: userMessage.content, conversationHistory: conversationHistory) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    // Fügt die Antwort zur Konversation hinzu.
                    let botMessage = ChatMessage(content: response, isUser: false)
                    self?.messages.append(botMessage)
                case .failure(let error):
                    let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false)
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
}
