//
//  CacheManager.swift
//  MediHub
//
//  Created by Sasan Rafat Nami on 30.12.24.
//

import Foundation
import os

/// `CacheManager` ist eine Singleton-Klasse, die das Caching von Antworten verwaltet.
/// Sie ermöglicht das Speichern, Abrufen und Löschen von zwischengespeicherten Antworten basierend auf einem Schlüssel.
/// Der Cache ist generisch, threadsicher und unterstützt LRU-Strategie sowie TTL-basierte Cache-Invalidierung.
final class CacheManager {
    /// Die gemeinsame Instanz von `CacheManager`, die im gesamten Anwendungskontext verwendet wird.
    static let shared = CacheManager()
    
    /// Ein generischer Cache-Eintrag, der den Wert und den Zeitpunkt des Hinzufügens speichert.
    private struct CacheEntry<Value> {
        let value: Value
        let timestamp: Date
    }
    
    /// Das interne Cache als Dictionary, das Schlüssel-Wert-Paare speichert.
    /// Verwendet eine Kombination aus Dictionary und Doubly Linked List für die LRU-Strategie.
    private var cache: [String: LinkedListNode<String, Any>] = [:]
    private var accessOrder = LinkedList<String, Any>()
    private let queue = DispatchQueue(label: "com.medihub.CacheManagerQueue", attributes: .concurrent)
    
    /// Maximale Anzahl der Cache-Einträge
    private let maxCacheSize: Int = 100
    
    /// Time-to-Live für Cache-Einträge in Sekunden
    private let ttl: TimeInterval = 60 * 60 // 1 Stunde
    
    /// Logger für das Logging.
    private let logger = Logger(subsystem: "com.medihub", category: "CacheManager")
    
    /// Privater Initialisierer verhindert die Instanziierung weiterer `CacheManager`-Objekte.
    private init() {}
    
    /// Ruft eine gespeicherte Antwort für einen gegebenen Schlüssel ab, falls vorhanden und nicht abgelaufen.
    ///
    /// - Parameter key: Der Schlüssel, der zur Identifizierung der gespeicherten Antwort verwendet wird.
    /// - Returns: Die gespeicherte Antwort als generischer Typ `T`, oder `nil`, wenn keine gültige Antwort für den Schlüssel existiert.
    func getResponse<T>(for key: String) -> T? {
        var result: T?
        queue.sync {
            if let node = cache[key],
               let entry = node.value as? CacheEntry<T>,
               !isExpired(entry.timestamp) {
                // Aktualisiere die Zugriffsreihenfolge
                accessOrder.moveToFront(node)
                result = entry.value
            } else {
                // Entferne den Eintrag, wenn er abgelaufen ist
                if let node = cache[key] {
                    accessOrder.remove(node)
                    cache.removeValue(forKey: key)
                    logger.debug("Cache entry expired and removed for key: \(key)")
                }
                result = nil
            }
        }
        return result
    }
    
    /// Speichert eine Antwort für einen gegebenen Schlüssel im Cache.
    ///
    /// - Parameters:
    ///   - response: Die Antwort, die gespeichert werden soll.
    ///   - key: Der Schlüssel, unter dem die Antwort gespeichert wird.
    func saveResponse<T>(_ response: T, for key: String) {
        queue.async(flags: .barrier) {
            if let node = self.cache[key] {
                // Update existing entry
                node.value = CacheEntry(value: response, timestamp: Date())
                self.accessOrder.moveToFront(node)
            } else {
                // Add new entry
                let entry = CacheEntry(value: response, timestamp: Date())
                let node = self.accessOrder.insertAtFront(key, value: entry)
                self.cache[key] = node
                
                // Überprüfen der Cache-Größe
                if self.cache.count > self.maxCacheSize, let leastUsed = self.accessOrder.removeLast() {
                    self.cache.removeValue(forKey: leastUsed.key)
                    self.logger.debug("Cache entry evicted for key: \(leastUsed.key)")
                }
            }
        }
    }
    
    /// Löscht den gesamten Cache.
    /// Diese Methode ist optional und kann für zukünftige Erweiterungen oder zur Speicherbereinigung verwendet werden.
    func clearCache() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.accessOrder.removeAll()
            self.logger.info("Cache cleared.")
        }
    }
    
    /// Überprüft, ob ein Eintrag abgelaufen ist.
    ///
    /// - Parameter timestamp: Der Zeitstempel des Eintrags.
    /// - Returns: `true`, wenn der Eintrag abgelaufen ist, sonst `false`.
    private func isExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

/// Einfache Implementierung eines doppelt verketteten Listen-Knotens.
class LinkedListNode<Key, Value> {
    let key: Key
    var value: Value
    var prev: LinkedListNode?
    var next: LinkedListNode?
    
    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

/// Einfache Implementierung einer doppelt verketteten Liste zur Unterstützung der LRU-Strategie.
class LinkedList<Key, Value> {
    private var head: LinkedListNode<Key, Value>?
    private var tail: LinkedListNode<Key, Value>?
    
    /// Fügt einen neuen Knoten am Anfang der Liste hinzu.
    @discardableResult
    func insertAtFront(_ key: Key, value: Value) -> LinkedListNode<Key, Value> {
        let node = LinkedListNode(key: key, value: value)
        node.next = head
        head?.prev = node
        head = node
        if tail == nil {
            tail = node
        }
        return node
    }
    
    /// Verschiebt einen vorhandenen Knoten an den Anfang der Liste.
    func moveToFront(_ node: LinkedListNode<Key, Value>) {
        guard head !== node else { return }
        
        // Entferne den Knoten aus seiner aktuellen Position
        node.prev?.next = node.next
        node.next?.prev = node.prev
        
        if tail === node {
            tail = node.prev
        }
        
        // Setze den Knoten an den Anfang
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
    }
    
    /// Entfernt den letzten Knoten der Liste.
    ///
    /// - Returns: Der entfernte Knoten, oder `nil`, wenn die Liste leer ist.
    @discardableResult
    func removeLast() -> LinkedListNode<Key, Value>? {
        guard let tailNode = tail else { return nil }
        if head === tail {
            head = nil
            tail = nil
        } else {
            tail = tailNode.prev
            tail?.next = nil
        }
        tailNode.prev = nil
        tailNode.next = nil
        return tailNode
    }
    
    /// Entfernt einen gegebenen Knoten aus der Liste.
    func remove(_ node: LinkedListNode<Key, Value>) {
        if head === node {
            head = node.next
        }
        if tail === node {
            tail = node.prev
        }
        node.prev?.next = node.next
        node.next?.prev = node.prev
        node.prev = nil
        node.next = nil
    }
    
    /// Entfernt alle Knoten aus der Liste.
    func removeAll() {
        head = nil
        tail = nil
    }
}
