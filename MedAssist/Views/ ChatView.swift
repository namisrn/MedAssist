//
//  ChatView.swift
//  MediHub
//
//  Created by Beispiel on 14.12.24.
//

import SwiftUI
import SwiftData

/**
 Eine benutzerfreundliche Chat-Ansicht, die Nachrichten aus einer `ChatConversation`, die auf SwiftData basiert, anzeigt.
 Sie ermöglicht es dem Benutzer, neue Nachrichten zu senden, sofern dies gewünscht ist.
 
 ## Eigenschaften
 
 - **conversation**: Eine optionale vorhandene Konversation, beispielsweise aus einem Archiv.
   Wenn diese `nil` ist, wird bei der ersten gesendeten Nachricht automatisch eine neue Konversation erstellt.
 - **initialInput**: Ein Binding-String, der initialen Text im Eingabefeld setzt.
   sodass nur die Lesemodus-Ansicht angezeigt wird.
 */
struct ChatView: View {
    
    // MARK: - SwiftData Context
    
    /// Der SwiftData-Kontext, der zum Erstellen und Speichern neuer Objekte verwendet wird.
    @Environment(\.modelContext) private var context
    
    // MARK: - Konversation
    
    /// Eine optionale Instanz einer bestehenden Chat-Konversation.
    let conversation: ChatConversation?
    
    // MARK: - Zustände
    
    /// Der aktuelle Text, den der Benutzer im Eingabefeld eingegeben hat.
    @State private var userInput: String
    
    /// Steuerung des Fokuszustands des Eingabefeldes, um die Tastatur anzuzeigen oder auszublenden.
    @FocusState private var isKeyboardFocused: Bool
    
    /// Zeigt an, ob derzeit eine Anfrage an den OpenAI-Dienst ausgeführt wird.
    @State private var isLoading: Bool = false
    
    /**
     Verwendet, um eine lokale Konversation zu verwalten, falls beim ersten Senden
     einer Nachricht keine bestehende Konversation vorhanden ist.
     */
    @State private var localConversation: ChatConversation?
    
    /// Optionales Fehlernachrichtenfeld zur Anzeige von Fehlermeldungen im UI.
    @State private var errorMessage: String?
    
    // MARK: - Initializer
    
    /**
     Initialisiert eine neue Instanz von `ChatView`.
     
     - Parameters:
       - conversation: Eine optionale vorhandene Chat-Konversation. Standardwert ist `nil`.
       - initialInput: Ein Binding-String für den initialen Text im Eingabefeld. Standardwert ist ein leerer String.
     */
    init(
        conversation: ChatConversation? = nil,
        initialInput: Binding<String> = .constant("")
    ) {
        self.conversation = conversation
        self._userInput = State(initialValue: initialInput.wrappedValue)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            if currentConversation.messages.isEmpty {
                // Leere Ansicht mit Begrüßungstext
                Spacer()
                Text("Hallo Sasan")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                Spacer()
            } else {
                // Scrollbare Ansicht mit Konversationsnachrichten
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(
                                currentConversation.messages.sorted(by: { $0.timestamp < $1.timestamp }),
                                id: \.id
                            ) { message in
                                MessageRowView(message: message)
                            }
                        }
                        .onChange(of: currentConversation.messages) { _ in
                            scrollToLatest(in: scrollView)
                        }
                    }
                }
                .backgroundStyle(AppColors.background)
                .cornerRadius(16)
                .shadow(color: AppColors.text.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }

            // Eingabebereich für Nachrichten
            inputArea
        }
        .background(AppColors.background.ignoresSafeArea())
        .onTapGesture {
            isKeyboardFocused = false
        }
        .onAppear {
            if let conversation {
                self.localConversation = conversation
            }
        }
    }
    // MARK: - Private Views
    
    /**
     Der Eingabebereich, bestehend aus einem Textfeld für die Benutzereingabe und einem Senden-Button.
     Dieser Bereich hat einen abgerundeten Hintergrund und ist optisch hervorgehoben.
     */
    @ViewBuilder
    private var inputArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppColors.primary.opacity(0.6), lineWidth: 2)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
            
            HStack(spacing: 12) {
                // Textfeld für die Eingabe der Benutzer-Nachricht
                TextField("Wie kann ich Dir helfen?", text: $userInput)
                    .padding(12)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 18))
                    .focused($isKeyboardFocused)
                
                // Senden-Button, der während des Ladens einen Ladeindikator anzeigt
                Button(action: {
                    sendMessage()
                }) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Senden")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        // Anzeige von Fehlermeldungen innerhalb des Buttons, falls vorhanden
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .frame(width: 80, height: 45)
                    .background(AppColors.primary)
                    .cornerRadius(20)
                }
                .disabled(userInput.isEmpty || isLoading) // Deaktivieren des Buttons bei leerem Input oder während des Ladens
                .opacity(userInput.isEmpty ? 0.3 : 1.0) // Visuelle Rückmeldung über die Aktivierung des Buttons
            }
            .padding(.horizontal, 5)
        }
        .padding(.horizontal, 16)
        .frame(height: 55)
        .offset(y: -10)
    }
    
    // MARK: - Computed Properties
    
    /**
     Bestimmt die aktuell zu verwendende Konversation.
     Wenn eine lokale Konversation existiert, wird diese bevorzugt verwendet.
     Ansonsten wird die übergebene Konversation genutzt.
     Sollte keine vorhanden sein, wird eine neue temporäre Konversation erstellt.
     */
    private var currentConversation: ChatConversation {
        localConversation ?? conversation ?? ChatConversation(title: "Neue Konversation")
    }
    
    // MARK: - Private Funktionen
    
    /**
     Scrollt die ScrollView automatisch zum neuesten Nachrichten-Eintrag.
     
     - Parameter scrollView: Der Proxy der aktuellen ScrollView, der das Scrollen ermöglicht.
     */
    private func scrollToLatest(in scrollView: ScrollViewProxy) {
        guard let lastId = currentConversation.messages.last?.id else { return }
        withAnimation {
            scrollView.scrollTo(lastId, anchor: .bottom)
        }
    }
    
    /**
     Verarbeitet das Senden einer neuen Nachricht durch den Benutzer.
     - Erstellt bei Bedarf eine neue Konversation.
     - Fügt die Benutzer-Nachricht zur aktuellen Konversation hinzu.
     - Überprüft, ob eine Antwort im Cache vorhanden ist und verwendet diese.
     - Falls nicht, wird eine Anfrage an die OpenAI-API gesendet und die Antwort verarbeitet.
     - Fehler werden entsprechend behandelt und angezeigt.
     */
    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        // 1) Neue Konversation erstellen, falls keine existiert
        if localConversation == nil && conversation == nil {
            let newConv = ChatConversation(title: "Chat vom \(Date().formatted())")
            context.insert(newConv)
            localConversation = newConv
        }
        
        // 2) Erstellen der Benutzer-Nachricht
        let userMessage = ChatMessageEntity(
            content: userInput,
            isUser: true,
            conversation: currentConversation
        )
        
        // Hinzufügen der Nachricht zur aktuellen Konversation
        currentConversation.messages.append(userMessage)
        
        // Sortieren der Nachrichten nach Zeitstempel
        currentConversation.messages.sort { $0.timestamp < $1.timestamp }
        
        // 3) Zurücksetzen des Eingabefelds und Anzeigen der Tastatur
        userInput = ""
        isKeyboardFocused = false
        isLoading = true
        
        // 4) Überprüfen, ob eine Antwort im Cache vorhanden ist
        if let cachedResponse: String = CacheManager.shared.getResponse(for: userMessage.content) {
            // Verwendung der zwischengespeicherten Antwort
            let cachedMessage = ChatMessageEntity(
                content: cachedResponse,
                isUser: false,
                conversation: currentConversation
            )
            currentConversation.messages.append(cachedMessage)
            isLoading = false
            return
        }

        
        // 5) Senden der Anfrage an die OpenAI-API, wenn keine Antwort im Cache vorhanden ist
        let conversationHistory = currentConversation.messages.map { message in
            [
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ]
        }
        
        Task {
            do {
                let responseText = try await OpenAIService.shared.fetchChatResponse(prompt: userMessage.content, conversationHistory: conversationHistory)
                
                // Speichern der erhaltenen Antwort im Cache
                CacheManager.shared.saveResponse(responseText, for: userMessage.content)
                
                // Erstellen und Hinzufügen der Bot-Nachricht zur Konversation
                let botMessage = ChatMessageEntity(
                    content: responseText,
                    isUser: false,
                    conversation: self.currentConversation
                )
                self.currentConversation.messages.append(botMessage)
                
                // Speichern der Änderungen im SwiftData-Kontext
                do {
                    try self.context.save()
                } catch {
                    self.errorMessage = "Speicherfehler: \(error.localizedDescription)"
                }
                
            } catch {
                // Behandlung von Fehlern und Anzeige der Fehlermeldung im UI
                self.errorMessage = "Fehler: \(error.localizedDescription)"
                let errorMessage = ChatMessageEntity(
                    content: "Error: \(error.localizedDescription)",
                    isUser: false,
                    conversation: self.currentConversation
                )
                self.currentConversation.messages.append(errorMessage)
            }
            
            // Setzt den Ladezustand zurück
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Untergeordnete Views

/**
 Darstellung einer einzelnen Chat-Nachricht in einer Zeile.
 Die Ausrichtung der Nachricht richtet sich danach, ob sie vom Benutzer oder vom Assistenten stammt.
 */
struct MessageRowView: View {
    let message: ChatMessageEntity

    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
                MessageView(content: message.content, isUser: true)
            } else {
                MessageView(content: message.content, isUser: false)
                Spacer()
            }
        }
    }
}

/// Eine parametrische Ansicht für die Darstellung von Nachrichten mit spezifischem Stil.
struct MessageView: View {
    let content: String
    let isUser: Bool

    var body: some View {
        Text(content)
            .modifier(MessageStyle(
                backgroundColor: isUser ? AppColors.primary.opacity(0.2) : AppColors.tertiary.opacity(0.2),
                textColor: isUser ? AppColors.primary : AppColors.tertiary,
                alignment: isUser ? .trailing : .leading
            ))
            .contextMenu {
                // Kontextmenü mit Optionen zum Kopieren und Vorlesen der Nachricht
                CopyButton(content: content)
                Button {
                    TextToSpeech().speak(text: content)
                } label: {
                    Label("Vorlesen", systemImage: "speaker.wave.2.fill")
                }
            }
    }
}

/**
 Ein `ViewModifier`, der das einheitliche Erscheinungsbild von Nachrichtenblasen definiert.
 */
struct MessageStyle: ViewModifier {
    let backgroundColor: Color
    let textColor: Color
    let alignment: Alignment
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(backgroundColor)
            )
            .frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(textColor)
            .font(.system(size: 17, weight: .regular))
            .lineSpacing(6)
    }
}

/**
 Eine Kontextmenü-Schaltfläche, die es ermöglicht, den Inhalt einer Nachricht in die Zwischenablage zu kopieren.
 */
struct CopyButton: View {
    let content: String
    
    var body: some View {
        Button {
            UIPasteboard.general.string = content
        } label: {
            Label("Kopieren", systemImage: "doc.on.doc")
        }
    }
}

// MARK: - Vorschau

#Preview {
    ChatView(
        conversation: nil,
        initialInput: .constant("")
    )
    .preferredColorScheme(.dark)
}

