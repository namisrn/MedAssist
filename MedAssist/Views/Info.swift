//
//  Info.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

/// Zeigt eine Liste von Informationsquellen und einen Hinweis zur Nutzung von KI-generierten Inhalten.
struct Info: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Hinweis auf KI-Generierte Inhalte
                VStack(alignment: .leading, spacing: 10) {
                    Text("⚠️ Wichtiger Hinweis")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("""
                        Die vorliegende Information wird durch Künstliche Intelligenz (AI) evaluiert und anhand der unten aufgeführten Quellen präsentiert. Bitte beachte, dass AI Fehler machen kann. Überprüfe wichtige Informationen stets eigenständig oder konsultiere einen Experten.
                        """)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Liste der Informationsquellen
                List {
                    Section(header: Text("Verwendete Quellen").font(.headline)) {
                        InfoSourceRow(number: 1, name: "OpenFDA", description: "Datenbank der US-amerikanischen FDA (Food and Drug Administration).")
                        InfoSourceRow(number: 2, name: "EMA", description: "Europäische Arzneimittel-Agentur (European Medicines Agency).")
                        InfoSourceRow(number: 3, name: "ABDA-Datenbank", description: "Apotheken-Datenbank mit umfassenden Informationen zu Arzneimitteln.")
                        InfoSourceRow(number: 4, name: "WHO UMC", description: "Datenbank der Weltgesundheitsorganisation für Arzneimittelüberwachung.")
                        InfoSourceRow(number: 5, name: "Embryotox", description: "Wissenschaftliches Beratungsportal zu Medikamenten in Schwangerschaft und Stillzeit.")
                        InfoSourceRow(number: 6, name: "Kinderformularium", description: "Spezielle Datenbank zu Medikamenten für Kinder.")
                        InfoSourceRow(number: 7, name: "Gelbe Liste", description: "Arzneimittelverzeichnis für Deutschland.")
                        InfoSourceRow(number: 8, name: "Fachinfo.de", description: "Portal mit Fachinformationen zu Medikamenten.")
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Informationsquellen")
        }
    }
}

// Komponente für einzelne Informationsquellen
struct InfoSourceRow: View {
    let number: Int
    let name: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("\(number). \(name)")
                    .font(.headline)
                Spacer()
            }
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    Info()
}
