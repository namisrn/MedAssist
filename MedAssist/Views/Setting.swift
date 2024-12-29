//
//  Setting.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

struct Setting: View {
    var body: some View {
        NavigationView {
            List {
                // Profilbereich
                Section(header: Text("Profil")) {
                    NavigationLink(destination: Text("Profil bearbeiten")) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.blue)
                            Text("Profil bearbeiten")
                        }
                    }
                }
                
                // Benachrichtigungseinstellungen
                Section(header: Text("Benachrichtigungen")) {
                    Toggle("Push-Benachrichtigungen", isOn: .constant(true))
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    NavigationLink(destination: Text("Erinnerungseinstellungen")) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.orange)
                            Text("Erinnerungseinstellungen")
                        }
                    }
                }
                
                // Datenschutzbereich
                Section(header: Text("Datenschutz")) {
                    NavigationLink(destination: Text("Datenschutzbestimmungen")) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.red)
                            Text("Datenschutzbestimmungen")
                        }
                    }
                    
                    NavigationLink(destination: Text("App-Berechtigungen")) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.purple)
                            Text("App-Berechtigungen")
                        }
                    }
                }
                
                // App-Informationen
                Section(header: Text("Über die App")) {
                    NavigationLink(destination: Info()) { // Hier wird der Info-View integriert
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.green)
                            Text("Informationsquellen")
                        }
                    }
                    
                    NavigationLink(destination: Text("Kontakt")) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.blue)
                            Text("Kontakt")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    Setting()
}
