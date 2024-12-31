//
//  ApoFinder.swift
//  MediHub
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI
import MapKit
import CoreLocation

struct ApoFinder: View {
    @StateObject private var viewModel = ApoFinderViewModel()
    @State private var enteredPLZ: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                inputSection
                if viewModel.isLoading {
                    ProgressView("Lade Apotheken...")
                        .padding()
                } else {
                    mapSection
                }
                apothekenListSection
            }
            .navigationTitle("Apothekenfinder")
            .onAppear {
                viewModel.requestLocationPermission()
            }
        }
    }
    
    // Eingabebereich für PLZ und Standort
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                plzTextField
                locationButton
            }
            
            Text("Zeigt Apotheken basierend auf Ihrer PLZ oder Ihrem Standort an.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
    }
    
    // Eigene View für das PLZ-Textfeld
    private var plzTextField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("PLZ eingeben", text: $enteredPLZ)
                .keyboardType(.numberPad)
                .onSubmit {
                    viewModel.fetchApothekes(for: enteredPLZ)
                }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
    
    // Eigene View für den Standort-Button
    private var locationButton: some View {
        Button(action: {
            viewModel.fetchApothekesForCurrentLocation()
        }) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                Text("Standort verwenden")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(height: 44)
            .background(AppColors.primary)
            .cornerRadius(8)
            .shadow(radius: 3)
        }
        .buttonStyle(.plain)
    }
    
    // Kartenbereich
    private var mapSection: some View {
        Map(
            coordinateRegion: $viewModel.region,
            showsUserLocation: true,
            annotationItems: viewModel.apothekes
        ) { apotheke in
            MapAnnotation(coordinate: apotheke.coordinate) {
                mapAnnotationView(for: apotheke)
            }
        }
        .frame(height: 300)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    // Einzelne Annotation auf der Karte
    private func mapAnnotationView(for apotheke: Apotheke) -> some View {
        VStack(spacing: 4) {
            Text(apotheke.name)
                .font(.caption2)
                .bold()
                .padding(4)
                .background(AppColors.background)
                .cornerRadius(6)
                .shadow(radius: 2)
            
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.red)
        }
    }
    
    // Liste der Apotheken
    private var apothekenListSection: some View {
        Group {
            if viewModel.apothekes.isEmpty {
                emptyStateView
            } else {
                apothekenListView
            }
        }
        .padding(.horizontal)
    }
    
    // View für den leeren Zustand
    private var emptyStateView: some View {
        Group {
            if !viewModel.isLoading {
                Text("Keine Apotheken gefunden.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
    
    // Liste der Apotheken mit eigenen Zellen
    private var apothekenListView: some View {
        List(viewModel.apothekes) { apotheke in
            ApothekeRow(apotheke: apotheke)
                .listRowSeparator(.hidden)
        }
        .listStyle(.inset)
    }
    
    // Einzelne Zeile für eine Apotheke
    private struct ApothekeRow: View {
        let apotheke: Apotheke
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(apotheke.name)
                    .font(.headline)
                Text(apotheke.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

#Preview {
    ApoFinder()
}

final class ApoFinderViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.6781, longitude: 7.8226), // Hamm, NRW
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var apothekes: [Apotheke] = []
    @Published var isLoading: Bool = false
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        loadMockData()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func loadMockData() {
        apothekes = [
            Apotheke(name: "City Apotheke Hamm", address: "Bahnhofstraße 20, 59065 Hamm", coordinate: CLLocationCoordinate2D(latitude: 51.6781, longitude: 7.8225)),
            Apotheke(name: "Linden Apotheke", address: "Ostring 12, 59063 Hamm", coordinate: CLLocationCoordinate2D(latitude: 51.6750, longitude: 7.8350)),
            Apotheke(name: "Westfalen Apotheke", address: "Weststraße 50, 59065 Hamm", coordinate: CLLocationCoordinate2D(latitude: 51.6800, longitude: 7.8180))
        ]
    }

    func fetchApothekes(for plz: String) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockData()
            self.isLoading = false
        }
    }

    func fetchApothekesForCurrentLocation() {
        guard let location = locationManager.location else {
            print("Standort nicht verfügbar.")
            return
        }
        region.center = location.coordinate
        fetchApothekes(for: "59065") // Mock für Hamm
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fehler beim Abrufen des Standorts: \(error.localizedDescription)")
    }
}

struct Apotheke: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}
