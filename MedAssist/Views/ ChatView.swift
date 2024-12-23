//
//  ChatView.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import SwiftUI

/// Die Hauptansicht für die Chat-Komponente.
/// Zeigt eine Konversationsansicht und ermöglicht die Eingabe neuer Nachrichten.
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // App-Titel
            Text("MedAssist")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primary)
                .padding(.top, 20)
            // Nachrichtenanzeige
            ChatMessagesView(messages: viewModel.messages)
                .background(AppColors.background)
                .cornerRadius(16)
                .shadow(color: AppColors.text.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            
            // Eingabefeld und Senden-Button
            HStack(spacing: 12) {
                // Eingabefeld
                TextField("Wie kann ich Dir helfen?", text: $viewModel.userInput)
                    .padding(16)
                    .background(AppColors.background)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.primary.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: AppColors.text.opacity(0.1), radius: 2, x: 0, y: 1)
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray) // Eingabefeld-Text auf Grau (Tertiary Color) einstellen
                    .tint(AppColors.primary) // Cursor auf Primärfarbe setzen
                    .frame(minHeight: 50)
                    .accessibilityHint("Eingabefeld für Deine Nachricht.")
                
                // Senden-Button
                Button(action: viewModel.sendMessage) {
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Senden")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 100, height: 50) // Feste Breite und Höhe
                    .background(AppColors.primary)
                    .cornerRadius(12)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(viewModel.userInput.isEmpty)
                .opacity(viewModel.userInput.isEmpty ? 0.6 : 1.0)
                .accessibilityHint("Sendet die Nachricht.")
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

        }
        .background(AppColors.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    ChatView()
}

/// Die Nachrichtenansicht, die die gesamte Konversation darstellt.
struct ChatMessagesView: View {
    let messages: [ChatMessage]
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        HStack(alignment: .top) {
                            if message.isUser {
                                Spacer()
                                Text(message.content)
                                    .padding(12)
                                    .background(AppColors.primary.opacity(0.2))
                                    .cornerRadius(12)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundStyle(AppColors.primary)
                                    .font(.system(size: 16))
                                    .accessibilityHint("Deine Nachricht.")
                                    .contextMenu{
                                        Button(action: {
                                            UIPasteboard.general.string = message.content
                                        }){
                                            Label("Copy", systemImage: "doc.fill")
                                        }
                                    }
                            } else {
                                Text(message.content)
                                    .padding(12)
                                    .background(AppColors.tertiary.opacity(0.2)) // Antwort auf Grau (Tertiary Color) setzen
                                    .cornerRadius(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(AppColors.tertiary) // Textfarbe ebenfalls auf Grau
                                    .font(.system(size: 16))
                                    .accessibilityHint("Antwort von MedAssist.")
                                    .contextMenu{
                                        Button(action: {
                                            UIPasteboard.general.string = message.content
                                        }){
                                            Label("Copy", systemImage: "doc.fill")
                                        }
                                    }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _, _ in
                guard let lastMessageId = messages.last?.id else { return }
                withAnimation {
                    scrollView.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
        }
    }
}
