//
//  ChatView.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import SwiftUI

/// Die Hauptansicht für die Chat-Komponente.
///
/// Diese Ansicht zeigt die Konversation (Liste der Nachrichten) und enthält
/// ein Eingabefeld sowie einen Senden-Button für neue Nachrichten.
struct ChatView: View {
    /// ViewModel zur Verwaltung des Chat-Zustands, einschließlich der Nachrichten und der Eingabe.
    @StateObject private var viewModel = ChatViewModel()
    /// Steuert, ob das Eingabefeld fokussiert ist (z. B. wenn die Tastatur sichtbar ist).
    @FocusState private var isKeyboardFocused: Bool
    /// Initiale Eingabe, die aus einer anderen Ansicht übergeben werden kann.
    @Binding var initialInput: String

    var body: some View {
        VStack(spacing: 16) {
            // Nachrichtenanzeige
            ChatMessagesView(messages: viewModel.messages)
                .background(AppColors.background) // Hintergrundfarbe für die Nachrichtenanzeige
                .cornerRadius(16) // Abgerundete Ecken für die gesamte Nachrichtenansicht
                .shadow(color: AppColors.text.opacity(0.1), radius: 4, x: 0, y: 2) // Schatteneffekt
                .padding(.horizontal) // Abstand zu den Bildschirmrändern

            // Eingabebereich und Senden-Button
            ZStack {
                // Hintergrund und Rahmen für das Eingabefeld
                RoundedRectangle(cornerRadius: 25)
                    .stroke(AppColors.primary.opacity(0.6), lineWidth: 2)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 4)

                HStack(spacing: 12) {
                    // Eingabefeld für Benutzernachrichten
                    TextField("Wie kann ich Dir helfen?", text: $viewModel.userInput)
                        .padding(12) // Innenabstand im Textfeld
                        .multilineTextAlignment(.leading) // Linksbündiger Text
                        .font(.system(size: 18)) // Schriftgröße und Stil
                        .focused($isKeyboardFocused) // Fokussteuerung
                        .onAppear {
                            viewModel.userInput = initialInput // Vorherige Eingabe einfügen
                            isKeyboardFocused = true // Tastatur bei Anzeige öffnen
                        }
                    
                    /// Audio-Generation durch OpenAI-API -- momentan funktioniert nicht.
//                    Button(action: {
//                        let recorder = AudioRecorder()
//                        recorder.startRecording()
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // Aufnahmezeit
//                            if let data = recorder.stopRecording() {
//                                print("Audioaufnahme erfolgreich: \(data.count) Bytes") // Debugging
//                            } else {
//                                print("Fehler: Keine Audiodaten aufgezeichnet.") // Debugging
//                            }
//                        }
//                    }) {
//                        Image(systemName: "mic.fill")
//                            .foregroundColor(AppColors.primary)
//                            .clipShape(Circle())
//                    }
                    /// Ende der Audio-Generation

                    // Senden-Button mit Ladeindikator
                    Button(action: {
                        viewModel.sendMessage() // Nachricht senden
                        initialInput = "" // Eingabefeld zurücksetzen
                    }) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView() // Zeigt einen Ladeindikator
                                    .tint(.white)
                            } else {
//                                Image(systemName: "arrow.up.circle.fill")
//                                    .foregroundColor(AppColors.primary) // Weiße Schriftfarbe
                                    
                                Text("Senden") // Beschriftung des Senden-Buttons
                                    .font(.system(size: 16, weight: .semibold)) // Schriftgröße und Gewicht
                                    .foregroundColor(.white) // Weiße Schriftfarbe
                            }
                        }
                        .frame(width: 80, height: 45) // Feste Größe des Buttons
                        .background(AppColors.primary) // Hintergrundfarbe des Buttons
                        .cornerRadius(20) // Abgerundete Ecken des Buttons
                    }
                    .disabled(viewModel.userInput.isEmpty || viewModel.isLoading) // Deaktivieren bei leerem Eingabefeld oder während des Ladens
                    .opacity(viewModel.userInput.isEmpty ? 0.3 : 1.0) // Transparenz bei deaktiviertem Button
                }
                .padding(.horizontal, 5) // Abstand zwischen den Elementen
            }
            .padding(.horizontal, 16) // Abstand zu den Seiten des ZStacks
            .frame(height: 55) // Feste Höhe des Eingabebereichs
            .offset(y: -10)
        }
        .background(AppColors.background.ignoresSafeArea()) // Vollbild-Hintergrund
        .onTapGesture {
            isKeyboardFocused = false // Tastatur schließen, wenn außerhalb des Eingabebereichs getippt wird
        }
    }
}

#Preview {
    @Previewable @State var currentInput = "" // Lokale @State-Variable für Preview
    return ChatView(initialInput: $currentInput) // Übergabe der Bindung
        .preferredColorScheme(.dark) // Dunkles Farbschema für die Vorschau
}



/// Hauptansicht, die eine scrollbare Liste von Nachrichten darstellt.
///
/// Die Nachrichten können entweder von einem Benutzer oder einem System (z. B. einem Chatbot) stammen.
/// Diese Ansicht unterstützt dynamisches Scrollen zur neuesten Nachricht.
struct ChatMessagesView: View {
    /// Liste der anzuzeigenden Nachrichten.
    let messages: [ChatMessage]
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.messageSpacing) {
                    ForEach(messages) { message in
                        MessageRowView(message: message) // Zeigt jede Nachricht in einer eigenen Zeile.
                    }
                }
            }
            .onChange(of: messages.count) { _, _ in
                scrollToLatestMessage(using: scrollView) // Automatisch zum Ende scrollen, wenn neue Nachrichten hinzukommen.
            }
        }
    }
    
    /// Scrollt zur letzten Nachricht, wenn neue Nachrichten hinzugefügt werden.
    /// - Parameter scrollView: Ein ScrollViewProxy, der den Zugriff auf spezifische Elemente im ScrollView ermöglicht.
    private func scrollToLatestMessage(using scrollView: ScrollViewProxy) {
        guard let lastMessageId = messages.last?.id else { return }
        withAnimation {
            scrollView.scrollTo(lastMessageId, anchor: .bottom) // Scrollt zur neuesten Nachricht mit Animation.
        }
    }
}

/// Eine einzelne Zeile in der Nachrichtenliste.
///
/// Diese Ansicht unterscheidet zwischen Nachrichten von Benutzern und dem System
/// und zeigt sie entsprechend ihrer Ausrichtung (rechts für Benutzer, links für System) an.
struct MessageRowView: View {
    /// Die Nachricht, die in dieser Zeile angezeigt werden soll.
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer() // Nachricht wird rechtsbündig ausgerichtet.
                UserMessageView(content: message.content) // Darstellung für Benutzernachrichten.
            } else {
                SystemMessageView(content: message.content) // Darstellung für Systemnachrichten.
                Spacer() // Nachricht wird linksbündig ausgerichtet.
            }
        }
    }
}

/// Darstellung für Benutzernachrichten.
///
/// Diese Ansicht zeigt Nachrichten, die vom Benutzer gesendet wurden,
/// mit einem spezifischen Hintergrundstil und Kontextmenü.
struct UserMessageView: View {
    /// Der Inhalt der Nachricht.
    let content: String
    
    var body: some View {
        Text(content)
            .modifier(MessageStyle(backgroundColor: AppColors.primary.opacity(0.2),
                                   textColor: AppColors.primary,
                                   alignment: .trailing)) // Benutzerdefinierter Stil für Benutzernachrichten.
            .accessibilityHint("Deine Nachricht.") // Zugänglichkeitshinweis für VoiceOver.
            .contextMenu {
                CopyButton(content: content)
                Button(action: {
                    let tts = TextToSpeech()
                    tts.speak(text: content) // Text vorlesen
                }) {
                    Label("Vorlesen", systemImage: "speaker.wave.2.fill")
                }
            }
    }
}

/// Darstellung für Systemnachrichten.
///
/// Diese Ansicht zeigt Nachrichten, die vom System gesendet wurden (z. B. Antworten eines Chatbots),
/// mit einem spezifischen Hintergrundstil und Kontextmenü.
struct SystemMessageView: View {
    /// Der Inhalt der Nachricht.
    let content: String
    
    var body: some View {
        Text(content)
            .modifier(MessageStyle(backgroundColor: AppColors.tertiary.opacity(0.2),
                                   textColor: AppColors.tertiary,
                                   alignment: .leading)) // Benutzerdefinierter Stil für Systemnachrichten.
            .accessibilityHint("Antwort von MedAssist.") // Zugänglichkeitshinweis für VoiceOver.
            .contextMenu {
                CopyButton(content: content)
                Button(action: {
                    let tts = TextToSpeech()
                    tts.speak(text: content) // Text vorlesen
                }) {
                    Label("Vorlesen", systemImage: "speaker.wave.2.fill")
                }
            }
    }
}

/// Ein ViewModifier, der den Stil von Nachrichten vereinheitlicht.
///
/// Der Modifier umfasst Hintergrundfarbe, Textfarbe, Ausrichtung, Schriftart und Abstand.
struct MessageStyle: ViewModifier {
    /// Hintergrundfarbe der Nachricht.
    let backgroundColor: Color
    /// Textfarbe der Nachricht.
    let textColor: Color
    /// Textausrichtung innerhalb des Nachrichtenblocks.
    let alignment: Alignment
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous)) // Abgerundeter Hintergrund.
            .cornerRadius(12)
            .frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(textColor)
            .font(Constants.messageFont) // Einheitliche Schriftart.
            .lineSpacing(Constants.lineSpacing) // Zeilenabstand für besseren Lesefluss.
    }
}

/// Kontextmenü-Schaltfläche zum Kopieren von Nachrichten.
///
/// Wird als Teil des Kontextmenüs der Nachrichtenanzeige verwendet.
struct CopyButton: View {
    /// Der Inhalt der Nachricht, die kopiert werden soll.
    let content: String
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = content // Kopiert den Nachrichteninhalt in die Zwischenablage.
        }) {
            Label("Copy", systemImage: "doc.on.doc") // UI-Element mit Text und Symbol.
        }
    }
}

/// Zentralisierte Konstanten für die Ansicht.
///
/// Enthält häufig verwendete Werte wie Abstände und Schriftarten, um Konsistenz sicherzustellen.
private enum Constants {
    static let messageSpacing: CGFloat = 12 // Abstand zwischen Nachrichten.
    static let lineSpacing: CGFloat = 6 // Zeilenabstand innerhalb von Nachrichten.
    static let messageFont: Font = .system(size: 17, weight: .regular) // Standard-Schriftart für Nachrichten.
}
