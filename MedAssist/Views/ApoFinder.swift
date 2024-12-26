//
//  ApoFinder.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 26.12.24.
//

import SwiftUI
import MapKit

struct ApoFinder: View {
    var body: some View {
        
        Map {
            Annotation("Seattle", coordinate: .seattle) {
                Image(systemName: "mappin")
                    .foregroundStyle(.black)
                    .padding()
                    .background(.red)
                    .clipShape(Circle())
            }
            
            Marker(coordinate: .newYork) {
                Label("New York", systemImage: "mappin")
            }
            
            Marker("San Francisco", monogram: Text("SF"), coordinate: .sanFrancisco)
        }
    }
}

#Preview {
    ApoFinder()
}
extension CLLocationCoordinate2D {
    static let newYork: Self = .init(
        latitude: 40.730610,
        longitude: -73.935242
    )
    
    static let seattle: Self = .init(
        latitude: 47.608013,
        longitude: -122.335167
    )
    
    static let sanFrancisco: Self = .init(
        latitude: 37.733795,
        longitude: -122.446747
    )
}
