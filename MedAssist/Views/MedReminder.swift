//
//  MedReminder.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import SwiftUI

struct MedReminder: View {
    var body: some View {
        NavigationView {
            VStack {
                if isDummyDataAvailable {
                    List(dummyMedications, id: \.id) { medication in
                        NavigationLink(destination: MedicationDetailView(medication: medication)) {
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 40, height: 40)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(medication.name)
                                        .font(.headline)
                                    Text("Erinnerung: \(medication.reminderTime)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "pills.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("Keine Medikamente gespeichert")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Hier kannst du deine Medikamente und Erinnerungen hinzufügen.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Medikamenten")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addNewMedication) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Medikament hinzufügen")
                }
            }
        }
    }
    
    // Dummy-Daten verfügbar?
    private var isDummyDataAvailable: Bool {
        !dummyMedications.isEmpty
    }
    
    // Aktion für das Hinzufügen eines neuen Medikaments
    private func addNewMedication() {
        print("Neues Medikament hinzufügen")
    }
}

#Preview {
    MedReminder()
}

// MARK: - Dummy Daten
struct Medication: Identifiable {
    let id = UUID()
    let name: String
    let reminderTime: String
    let dosage: String
}

let dummyMedications: [Medication] = [
    Medication(name: "Ibuprofen", reminderTime: "08:00 Uhr", dosage: "400 mg"),
    Medication(name: "Paracetamol", reminderTime: "12:00 Uhr", dosage: "500 mg"),
    Medication(name: "Aspirin", reminderTime: "18:00 Uhr", dosage: "100 mg"),
    Medication(name: "Vitamin D3", reminderTime: "20:00 Uhr", dosage: "1.000 IE")
]

// MARK: - Detailansicht für ein Medikament
struct MedicationDetailView: View {
    let medication: Medication
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(medication.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Dosierung: \(medication.dosage)")
                .font(.headline)
            
            Text("Nächste Erinnerung: \(medication.reminderTime)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Medikamenten-Detail")
    }
}
