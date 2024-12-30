//
//  Info.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

/// `Info` ist eine SwiftUI-View, die eine Liste von Informationsquellen sowie einen wichtigen Hinweis zur Nutzung von KI-generierten Inhalten anzeigt.
/// Diese Ansicht dient dazu, Transparenz über die verwendeten Datenquellen zu schaffen und den Nutzer auf mögliche Fehlerquellen bei KI-generierten Informationen hinzuweisen.
struct Info: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Anzeige eines wichtigen Hinweises bezüglich KI-generierter Inhalte.
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

                // Anzeige der Liste der genutzten Informationsquellen.
                List {
                    Section(header: Text("Verwendete Quellen").font(.headline)) {
                        InfoSourceRow(number: 1, name: "OpenFDA", description: NSLocalizedString("info_source_description_openfda", comment: "Description for OpenFDA database."))
                        InfoSourceRow(number: 2, name: "EMA", description: NSLocalizedString("info_source_description_ema", comment: "Description for EMA database."))
                        InfoSourceRow(number: 3, name: "ABDA-Datenbank", description: NSLocalizedString("info_source_description_abda", comment: "Description for ABDA database."))
                        InfoSourceRow(number: 4, name: "WHO UMC", description: NSLocalizedString("info_source_description_who_umc", comment: "Description for WHO UMC database."))
                        InfoSourceRow(number: 5, name: "Embryotox", description: NSLocalizedString("info_source_description_embryotox", comment: "Description for Embryotox portal."))
                        InfoSourceRow(number: 6, name: "Kinderformularium", description: NSLocalizedString("info_source_description_kinderformularium", comment: "Description for children's medication database."))
                        InfoSourceRow(number: 7, name: "Gelbe Liste", description: NSLocalizedString("info_source_description_gelbe_liste", comment: "Description for Gelbe Liste directory."))
                        InfoSourceRow(number: 8, name: "Fachinfo.de", description: NSLocalizedString("info_source_description_fachinfo", comment: "Description for Fachinfo portal."))
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Informationsquellen")
        }
    }
}

/// `InfoSourceRow` ist eine SwiftUI-View, die eine einzelne Informationsquelle darstellt.
/// Sie zeigt die Nummer, den Namen und eine kurze Beschreibung der Quelle an.
struct InfoSourceRow: View {
    /// Die Reihenfolge der Informationsquelle in der Liste.
    let number: Int
    /// Der Name der Informationsquelle.
    let name: String
    /// Eine kurze Beschreibung der Informationsquelle.
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
