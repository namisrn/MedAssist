//
//  Home.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

struct Home: View {
    @State private var isChatViewActive = false // Zustand für das Bottom Sheet
    @State private var currentInput = "" // Zustand für das Eingabefeld
    @State private var selectedTab: Tab = .archive // Standard-Tab
    
    // Tabs für die Hauptnavigation
    enum Tab: Hashable {
        case archive, medikamente, apotheken, einstellung
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Archive-Tab
                ChatArchive()
                    .tabItem {
                        Label("Archive", systemImage: "archivebox.fill")
                    }
                    .tag(Tab.archive)
                
                // Medikamente-Tab
                MedReminder()
                    .tabItem {
                        Label("Medikamente", systemImage: "pills.fill")
                    }
                    .tag(Tab.medikamente)
                
                // Apotheken-Tab
                ApoFinder()
                    .tabItem {
                        Label("Apotheken", systemImage: "cross")
                    }
                    .tag(Tab.apotheken)
                
                // Einstellung-Tab
                Setting()
                    .tabItem {
                        Label("Einstellung", systemImage: "gearshape")
                    }
                    .tag(Tab.einstellung)
            }
            .tint(AppColors.primary) // Anpassung der Tab-Farben
            
            // Custom Bottom Sheet
            .safeAreaInset(edge: .bottom) {
                CustomBottomSheet()
            }
        }
        .sheet(isPresented: $isChatViewActive) {
            ChatView(initialInput: $currentInput)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .padding(.top)
                .background(AppColors.background)
        }
    }
    
    // MARK: - Custom Bottom Sheet
    @ViewBuilder
    private func CustomBottomSheet() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(AppColors.primary.opacity(0.6), lineWidth: 2)
                .fill(.ultraThinMaterial)
                .shadow(radius: 4)

            HStack {
                // Eingabefeld
                TextField("Hier Kannst du deine Fragen schreiben!", text: $currentInput)
                    .foregroundColor(AppColors.text)
                    .font(.system(size: 18))
                    .padding(.horizontal, 12)

            }
            .padding(.horizontal, 6)
            
            // Unsichtbare Ebene für Interaktion
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
}

#Preview {
    Home()
        .preferredColorScheme(.dark)
}
