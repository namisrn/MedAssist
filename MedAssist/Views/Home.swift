//
//  Home.swift
//  MediHub
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

/// `Home` ist die Hauptansicht der MediHub-Anwendung.
/// Sie enthält eine TabView mit verschiedenen Tabs, einschließlich des Chat-Archivs, der neuen Chat-Ansicht und der Einstellungen.
/// Diese Ansicht verwaltet die Navigation zwischen den Tabs und stellt sicher, dass die Eingabe im neuen Chat zurückgesetzt wird, wenn der Nutzer den Tab verlässt.
struct Home: View {
    /// Zustand zur Steuerung der Präsentation der Chat-Ansicht als Sheet.
    @State private var isChatViewActive = false
    /// Zustand, der den aktuellen Benutzereingang im Chat speichert.
    @State private var currentInput = ""
    /// Zustand zur Verfolgung des aktuell ausgewählten Tabs.
    @State private var selectedTab: Tab = .chatview
    
    /// Enumeration zur Darstellung der verschiedenen Tabs in der Anwendung.
    enum Tab: Hashable {
        case archive, medikamente, chatview, apotheken, einstellung
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Tab für das Chat-Archiv
                ChatArchive()
                    .tabItem {
                        Label("Archive", systemImage: "archivebox.fill")
                    }
                    .tag(Tab.archive)
                
//                MedReminder()
//                    .tabItem {
//                        Label("Medikamente", systemImage: "pills.fill")
//                    }
//                    .tag(Tab.medikamente)
                
                // Tab für den neuen Chat
                // Durch die Verwendung der `.id`-Modifikator wird die ChatView jedes Mal neu erstellt, wenn der Tab ausgewählt wird.
                // Dies stellt sicher, dass alle Zustände innerhalb der ChatView zurückgesetzt werden.
                ChatView()
                    .id(selectedTab == .chatview ? UUID() : UUID())
                    .tabItem {
                        Label("New Chat", systemImage: "bubble.left.and.text.bubble.right.fill")

                    }
                    .tag(Tab.chatview)


//                ApoFinder()
//                    .tabItem {
//                        Label("Apotheken", systemImage: "cross")
//                    }
//                    .tag(Tab.apotheken)
                
                // Tab für Einstellungen
                Setting()
                    .tabItem {
                        Label("Einstellung", systemImage: "gearshape")

                    }
                    .tag(Tab.einstellung)
//                    .safeAreaInset(edge: .bottom) {
//                        CustomBottomSheet()
//                    }
            }
            // Handler, der auf Änderungen des ausgewählten Tabs reagiert.
            // Wenn der Nutzer den Chat-Tab verlässt, wird der aktuelle Eingabewert zurückgesetzt.
            .onChange(of: selectedTab) {
                if selectedTab != .chatview {
                    currentInput = ""
                }
            }
            .accentColor(AppColors.primary) // Setzt die Farbe der aktiven Tabs

        }
        // Festlegung des Navigations-Titels für die gesamte Ansicht.
        .navigationTitle("New Chat")
//        .sheet(isPresented: $isChatViewActive) {
//            ChatView(conversation: nil, initialInput: $currentInput)
//                .presentationDetents([.large])
//                .presentationDragIndicator(.visible)
//                .padding(.top)
//                .background(AppColors.background)
//        }
    }
    
    // MARK: - Alte UI
    
    /*
    /// Benutzerdefinierte untere Bereichsansicht (Bottom Sheet).
    @ViewBuilder
    private func CustomBottomSheet() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)
            
            HStack {
                TextField("Hier kannst du deine Fragen schreiben!", text: $currentInput)
                    .font(.system(size: 18))
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 6)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isChatViewActive = true
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 55)
        .offset(y: -60)
    }
    */
    
    /*
    /// Präsentiert die Chat-Ansicht als modales Sheet.
    .sheet(isPresented: $isChatViewActive) {
        ChatView(conversation: nil, initialInput: $currentInput)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .padding(.top)
            .background(AppColors.background)
    }
    */
}

#Preview {
    Home()
}
