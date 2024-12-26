//
//  Info.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI

struct Info: View {
    var body: some View {
        List {
            Text("OpenFDA: Allgemeine Medikamenteninformationen, Nebenwirkungen und Wechselwirkungen.")
            Text("EMA: Europäische Zulassungsinformationen, Packungsbeilagen.")
            Text("ABDA-Datenbank: Informationen zum deutschen Markt.")
            Text("WHO UMC: Pharmakovigilanz und Nebenwirkungen.")
            Text("Embryotox: Schwangerschaft und Stillzeit.")
            Text("Kinderformularium: Pädiatrische Pharmakotherapie.")
        }
    }
}

#Preview {
    Info()
}
