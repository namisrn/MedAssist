//
//  CacheManager.swift
//  MedAssist
//
//  Created by Sasan Rafat Nami on 30.12.24.
//

import Foundation

/// `CacheManager` ist eine Singleton-Klasse, die das Caching von Antworten verwaltet.
/// Sie ermöglicht das Speichern, Abrufen und Löschen von zwischengespeicherten Antworten basierend auf einem Schlüssel.
final class CacheManager {
    /// Die gemeinsame Instanz von `CacheManager`, die im gesamten Anwendungskontext verwendet wird.
    static let shared = CacheManager()
    
    /// Das interne Cache als Dictionary, das Schlüssel-Wert-Paare speichert.
    private var cache: [String: String] = [:]

    /// Privater Initialisierer verhindert die Instanziierung weiterer `CacheManager`-Objekte.
    private init() {}
    
    /// Ruft eine gespeicherte Antwort für einen gegebenen Schlüssel ab, falls vorhanden.
    ///
    /// - Parameter key: Der Schlüssel, der zur Identifizierung der gespeicherten Antwort verwendet wird.
    /// - Returns: Die gespeicherte Antwort als `String`, oder `nil`, wenn keine Antwort für den Schlüssel existiert.
    func getResponse(for key: String) -> String? {
        return cache[key]
    }
    
    /// Speichert eine Antwort für einen gegebenen Schlüssel im Cache.
    ///
    /// - Parameters:
    ///   - response: Die Antwort, die gespeichert werden soll.
    ///   - key: Der Schlüssel, unter dem die Antwort gespeichert wird.
    func saveResponse(_ response: String, for key: String) {
        cache[key] = response
    }
    
    /// Löscht den gesamten Cache.
    /// Diese Methode ist optional und kann für zukünftige Erweiterungen oder zur Speicherbereinigung verwendet werden.
    func clearCache() {
        cache.removeAll()
    }
}
