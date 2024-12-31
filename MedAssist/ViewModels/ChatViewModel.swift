//
//  ChatViewModel.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import Foundation
import Combine
import os

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
    
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.medihub", category: "ChatViewModel")
    private let debounceInterval: RunLoop.SchedulerTimeType.Stride = .milliseconds(300)
    private let maxConversationHistory: Int = 20 // Beispiel: Max 20 Nachrichten
    
    /// Initializer
    init() {
        // Optional: Implement Combine pipelines for userInput debouncing if necessary
    }
    
    /// Ruft die Antwort von der OpenAI-API ab und aktualisiert die Konversation.
    func sendMessage() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        // Throttling: Prevent sending messages too quickly
        guard !isLoading else {
            logger.warning("SendMessage called while loading.")
            return
        }
        
        // Fügt die Benutzereingabe zur Konversation hinzu.
        let userMessage = ChatMessage(content: input, isUser: true)
        appendMessage(userMessage)
        
        // Eingabefeld leeren
        self.userInput = ""
        isLoading = true
        
        Task {
            do {
                // Konversationshistorie vorbereiten
                let conversationHistory = prepareConversationHistory()
                
                // Überprüfen des Caches vor dem Senden der Anfrage
                if let cachedResponse: String = CacheManager.shared.getResponse(for: cacheKey(for: input, history: conversationHistory)) {
                    let botMessage = ChatMessage(content: cachedResponse, isUser: false)
                    appendMessage(botMessage)
                } else {
                    // Anfrage an OpenAI-API senden
                    let response = try await OpenAIService.shared.fetchChatResponse(prompt: input, conversationHistory: conversationHistory)
                    
                    // Speichern der Antwort im Cache
                    CacheManager.shared.saveResponse(response, for: cacheKey(for: input, history: conversationHistory))
                    
                    // Fügt die Antwort zur Konversation hinzu.
                    let botMessage = ChatMessage(content: response, isUser: false)
                    appendMessage(botMessage)
                }
            } catch {
                // Fehlerbehandlung
                let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false)
                appendMessage(errorMessage)
                logger.error("Error in sendMessage: \(error.localizedDescription)")
            }
            
            // Setzt den Ladezustand zurück
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    /// Fügt eine Nachricht zur Konversation hinzu und verwaltet die maximale Historie.
    private func appendMessage(_ message: ChatMessage) {
        DispatchQueue.main.async {
            self.messages.append(message)
            // Optimierung: Begrenze die Anzahl der Nachrichten
            if self.messages.count > self.maxConversationHistory {
                self.messages.removeFirst(self.messages.count - self.maxConversationHistory)
            }
        }
    }
    
    /// Bereitet die Konversationshistorie für die API-Anfrage vor.
    private func prepareConversationHistory() -> [[String: String]] {
        return messages.map { message in
            [
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ]
        }
    }
    
    /// Generiert einen eindeutigen Cache-Schlüssel basierend auf dem Prompt und der Historie.
    private func cacheKey(for prompt: String, history: [[String: String]]) -> String {
        let historyString = history.map { "\($0["role"] ?? ""):\($0["content"] ?? "")" }.joined(separator: "|")
        return "\(historyString)|user:\(prompt)"
    }
}
