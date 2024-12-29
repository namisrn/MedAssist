//
//  ChatArchive.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

struct ChatArchive: View {
    var body: some View {
        NavigationView {
            VStack {
                if isDummyDataAvailable {
                    List(dummyConversations, id: \.id) { conversation in
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
                                    Text(conversation.lastMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
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
                }
            }
            .navigationTitle("Archive")
        }
    }
    
    // Dummy-Daten verfügbar?
    private var isDummyDataAvailable: Bool {
        !dummyConversations.isEmpty
    }
}

#Preview {
    ChatArchive()
}

// MARK: - Dummy Daten
struct Conversation: Identifiable {
    let id = UUID()
    let title: String
    let lastMessage: String
}

let dummyConversations: [Conversation] = [
    Conversation(title: "Kopfschmerzen-Medikation", lastMessage: "Ibuprofen sollte nicht länger als 3 Tage eingenommen werden."),
    Conversation(title: "Schlaflosigkeit", lastMessage: "Melatonin kann kurzfristig helfen, sollte jedoch nicht überdosiert werden."),
    Conversation(title: "Wechselwirkungen", lastMessage: "Antibiotika können die Wirkung der Pille beeinträchtigen."),
    Conversation(title: "Allergiefragen", lastMessage: "Loratadin ist ein häufig verwendetes Antihistaminikum.")
]

// MARK: - Detailansicht für eine Konversation
struct ConversationDetailView: View {
    let conversation: Conversation
    
    var body: some View {
        VStack {
            Text(conversation.title)
                .font(.largeTitle)
                .padding()
            
            Text(conversation.lastMessage)
                .font(.body)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Detail")
    }
}
