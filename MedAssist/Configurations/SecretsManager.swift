//
//  SecretsManager.swift
//  MediHub
//
//  Created by Sasan Rafat Nami on 21.12.24.
//

import Foundation

/// Manager zum sicheren Laden sensibler Daten aus der `Secrets.plist`.
struct SecretsManager {
    /// Lädt den API-Key aus der `Secrets.plist`.
    static func getAPIKey() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
            print("❌ Secrets.plist nicht gefunden.")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Konnte Secrets.plist nicht laden.")
            return nil
        }
        
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            print("❌ Konnte Secrets.plist nicht parsen.")
            return nil
        }
        
        return plist["OpenAI_API_Key"] as? String
    }
}
