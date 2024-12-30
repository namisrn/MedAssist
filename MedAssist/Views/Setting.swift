//
//  Setting.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI
import SwiftData

/// Die `Setting`-View zeigt die Einstellungen der MedAssist-App an.
/// Sie enthält verschiedene Abschnitte wie Profil, Datenschutz, App-Informationen
/// und eine Funktion zum Löschen gespeicherter Daten.
struct Setting: View {
    // Zugriff auf den Datenbank-Kontext
    @Environment(\.modelContext) private var context
    
    // Abfrage aller gespeicherten Konversationen
    @Query private var allConversations: [ChatConversation]
    
    // State-Variable zur Steuerung des Alerts
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                // Profilbereich: Ermöglicht das Bearbeiten des Nutzerprofils.
                Section(header: Text("Profil").font(.headline)) {
                    NavigationLink(destination: ProfileView()) {
                        SettingRow(icon: "person.crop.circle.fill", title: "Profil bearbeiten", color: .blue)
                    }
                }

                // Datenschutzbereich: Zugriff auf Datenschutzrichtlinien und Berechtigungen.
                Section(header: Text("Datenschutz").font(.headline)) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingRow(icon: "lock.fill", title: "Datenschutzbestimmungen", color: .red)
                    }
                }

                // App-Informationen: Anzeigen von Kontaktinformationen und Quellen.
                Section(header: Text("Über die App").font(.headline)) {
                    NavigationLink(destination: InfoView()) {
                        SettingRow(icon: "info.circle.fill", title: "Informationsquellen", color: .green)
                    }

                    NavigationLink(destination: ContactView()) {
                        SettingRow(icon: "envelope.fill", title: "Kontakt", color: .blue)
                    }
                }

                // Daten löschen: Funktionalität zum Löschen aller gespeicherten Konversationen.
                Section(header: Text("Datenverwaltung").font(.headline)) {
                    Button(action: { showDeleteAlert = true }) {
                        SettingRow(icon: "trash.fill", title: "Alle Konversationen löschen", color: .red)
                    }
                }
                
                // App-Version: Anzeige der aktuellen App-Version am unteren Rand.
                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Text("MedAssist") // Name der App
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Version 1.0.0") // Aktuelle Version
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped) // Modernes Listen-Layout
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline) // Titel wird in der Toolbar angezeigt
            .alert("Konversationen löschen", isPresented: $showDeleteAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive, action: deleteAllConversations)
            } message: {
                Text("Möchten Sie wirklich alle gespeicherten Konversationen löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
        }
    }

    /// Löscht alle gespeicherten Konversationen aus der Datenbank.
    private func deleteAllConversations() {
        withAnimation {
            // Löschen aller Konversationen im Datenbank-Kontext
            allConversations.forEach(context.delete(_:))

            // Speichern der Änderungen im Datenbank-Kontext
            do {
                try context.save()
                print("Alle Konversationen wurden erfolgreich gelöscht.")
            } catch {
                print("Fehler beim Löschen: \(error.localizedDescription)")
            }
        }
    }
}

/// Eine wiederverwendbare Komponente für Zeilen in der Einstellungsliste.
/// Stellt eine Zeile mit einem Symbol, einem Titel und einer Farbe dar.
struct SettingRow: View {
    let icon: String // Name des Symbols
    let title: String // Titel der Zeile
    let color: Color // Farbe des Symbols

    var body: some View {
        HStack {
            Image(systemName: icon) // Symbolanzeige
                .font(.system(size: 25))
                .foregroundColor(color) // Farbliche Hervorhebung
            Text(title) // Titel der Zeile
                .font(.body)
                .foregroundColor(.primary) // Standardfarbe für Text
        }
        .padding(5) // Innenabstand für eine saubere Darstellung
    }
}

// Beispiel-Views für Navigation (Platzhalter mit minimalem Inhalt).
struct ProfileView: View { var body: some View { Text("Profil bearbeiten Ansicht") } }
struct ReminderSettingsView: View { var body: some View { Text("Erinnerungseinstellungen Ansicht") } }
struct PrivacyPolicyView: View { var body: some View { Text("Datenschutzbestimmungen Ansicht") } }
struct PermissionsView: View { var body: some View { Text("App-Berechtigungen Ansicht") } }
struct InfoView: View { var body: some View { Text("Informationsquellen Ansicht") } }
struct ContactView: View { var body: some View { Text("Kontakt Ansicht") } }

#Preview {
    Setting()
}
