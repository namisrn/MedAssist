//
//  Home.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

struct Home: View {
    @State private var isChatViewActive = false // Zustand für Navigation
    @State private var currentInput = "" // Gemeinsamer Zustand für das Eingabefeld
    @State private var selectedTab: Tab = .apotheken // Standard-Tab
    
    enum Tab: Hashable {
        case archive, medikamente, apotheken, einstellung
    }
    
    var body: some View {
        /// Tab View mit Auswahl
        TabView(selection: $selectedTab) {
            /// Archive Tab
            SampleTab("Archive", "archivebox.fill")
                .tabItem {
                    Image(systemName: "archivebox.fill")
                    Text("Archive")
                }
                .tag(Tab.archive)
            
            /// Medikamente Tab
            SampleTab("Medikamente", "pills.fill")
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("Medikamente")
                }
                .tag(Tab.medikamente)
            
            /// Apotheken Tab (mit ApoFinder)
            ApoFinder()
                .tabItem {
                    Image(systemName: "cross")
                    Text("Apotheken")
                }
                .tag(Tab.apotheken)
            
            /// Einstellung Tab
            Setting()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Einstellung")
                }
                .tag(Tab.einstellung)
        }
        /// Tab-Farben anpassen
        .tint(AppColors.primary)
        
        /// Custom Bottom Sheet
        .safeAreaInset(edge: .bottom) {
            CustomBottomSheet()
        }
        /// Navigation für ChatView
        .fullScreenCover(isPresented: $isChatViewActive) {
            NavigationView {
                ChatView(initialInput: $currentInput) // Übergabe des Textzustands
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Schließen") {
                                isChatViewActive = false
                            }
                        }
                    }
            }
        }
    }
    
    /// Custom Bottom Sheet
    @ViewBuilder
    func CustomBottomSheet() -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .cornerRadius(20) // Ecken abrunden

                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.primary, lineWidth: 1)
                    
                    HStack(spacing: 12) {
                        // Eingabefeld
                        TextField("Wie kann ich Dir helfen?", text: $currentInput)
                            .padding(12)
                            .multilineTextAlignment(.leading)
                            .background(AppColors.background)
                            .cornerRadius(20)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 20)
//                                    .stroke(AppColors.primary.opacity(0.6), lineWidth: 1)
//                            )
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.tertiary)
                        
                        // Senden-Button
                        Button(action: {
                            isChatViewActive = true // Öffnet ChatView
                        }) {
                            Text("Senden")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 45)
                                .background(AppColors.primary)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                    
                    //.padding(.bottom, 5)
                }
                .offset(y: -5)

                .padding(.horizontal,5)

            
            // Overlay für Tap-Geste
            Color.clear
                .contentShape(Rectangle()) // Macht den gesamten Bereich interaktiv
                .onTapGesture {
                    isChatViewActive = true // Öffnet ChatView
                }
        }
        .frame(height: 60)
        /// Seperator Line
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .fill(AppColors.tertiary.opacity(0.3))
                .frame(height: 1)
        })
        /// 49: Default Tab bar Height
        .offset(y: -49)
    }
    
    /// Sample Tabs
    @ViewBuilder
    func SampleTab(_ title: String, _ icon: String) -> some View {
        Text(title)
            .tabItem {
                Image(systemName: icon)
                Text(title)
            }
        /// Changing Tab Background Color
        //.toolbarBackground(.visible, for: .tabBar)
        //.toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

#Preview {
    Home()
}
