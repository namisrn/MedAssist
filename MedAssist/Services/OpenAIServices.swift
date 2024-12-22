//
//  OpenAIService.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import Foundation

/// Modell zur Decodierung der OpenAI API-Antwort.
struct OpenAIResponse: Codable {
    /// Eine einzelne Wahloption in der Antwort.
    struct Choice: Codable {
        /// Die Nachricht, die von der API zurückgegeben wird.
        struct Message: Codable {
            let content: String // Der Inhalt der Antwort.
        }
        let message: Message
    }
    let choices: [Choice]
}

/// Service zur Kommunikation mit der OpenAI API.
/// Dieser Service ist als Singleton implementiert, um zentralen Zugriff zu ermöglichen.
final class OpenAIService {
    // MARK: - Singleton
    static let shared = OpenAIService()
    
    // MARK: - Private Eigenschaften
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    /// Der API-Schlüssel wird sicher aus den Umgebungsvariablen geladen.
    private let apiKey = SecretsManager.getAPIKey() ?? ""
    
    private let urlSession = URLSession.shared

    /// Initialisierung privat, um das Singleton-Muster zu erzwingen.
    private init() {}
    
    // MARK: - API-Aufruf
    /// Sendet eine Anfrage an die OpenAI API, um eine Antwort auf eine pharmazeutische Frage zu erhalten.
    /// - Parameters:
    ///   - prompt: Die Benutzeranfrage, die beantwortet werden soll.
    ///   - conversationHistory: Die Historie der bisherigen Konversation.
    ///   - completion: Ein Callback mit dem Ergebnis (`String` bei Erfolg, `Error` bei Fehler).
    func fetchChatResponse(prompt: String, conversationHistory: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        var messages = [
            [
                "role": "system",
                "content": """
                Du bist ein freundlicher und hilfsbereiter pharmazeutischer Assistent, der ausschließlich Fragen zu Medikamenten und deren Anwendung beantwortet. Bitte formuliere Deine Antworten im Du-Stil, um eine persönliche und freundliche Atmosphäre zu schaffen. Analysiere jede Anfrage individuell und stelle sicher, dass die Antwort direkt auf die gestellte Frage eingeht. Falls eine Anfrage unklar ist, bitte gezielt um eine präzisere Formulierung. Falls eine Nachfrage gestellt wird (z. B. 'Kannst du mir präzisere Details geben?'), beziehe Dich direkt auf die vorherige Frage oder Antwort und liefere die angeforderten Details. Deine Antworten dürfen ausschließlich die folgenden Themen abdecken:\n\n1. **Einnahmezeitpunkte**: Klare Anweisungen, wann ein Medikament eingenommen werden soll (z. B. vor/nach dem Essen, morgens/abends, etc.).\n2. **Nebenwirkungen**: Mit Häufigkeitsangaben wie sehr häufig, häufig, gelegentlich, selten, sehr selten, nicht bekannt.\n3. **Wechselwirkungen**: Informationen zu Wechselwirkungen mit anderen Medikamenten oder Nahrungsmitteln.\n4. **Allgemeine pharmazeutische Informationen**: Erklärungen zur Wirkung, Anwendung oder Dosierung von Medikamenten.\n5. **Kontraindikationen**: Warnungen und Vorsichtsmaßnahmen bei der Einnahme von Medikamenten (z. B. bei bestimmten Vorerkrankungen oder Schwangerschaft).\n6. **Medikamentenvorschläge**: Empfehlungen für geeignete Medikamente und deren Stärken, einschließlich pflanzlicher Präparate oder Nahrungsergänzungsmittel.\n7. **Anwendungsgebiete**: Beschreibung, bei welchen Erkrankungen oder Beschwerden ein Medikament eingesetzt werden kann.\n8. **Dosisanpassungen**: Hinweise zur Anpassung der Dosierung bei besonderen Bedingungen wie Nieren- oder Leberinsuffizienz oder bei Kindern.\n9. **Notfallsituationen**: Klare, allgemeine Anweisungen, was bei einer möglichen Überdosierung oder falschen Einnahme zu tun ist (z. B. sofort den Arzt oder die Giftnotrufzentrale kontaktieren).\n10. **Vergleich von Medikamenten**: Erklärungen zu Unterschieden zwischen zwei Medikamenten, einschließlich Wirkung, Nebenwirkungen oder Anwendung (z. B. Omeprazol vs. Pantoprazol).\n\n### Umgang mit Nachfragen:\n- Wenn eine Nachfrage gestellt wird (z. B. 'Kannst du mir präzisere Details geben?'), beziehe Dich explizit auf die ursprüngliche Anfrage und liefere spezifische Details. Falls dies nicht möglich ist, frage gezielt nach weiteren Details, um die Anfrage präziser beantworten zu können.\n- Beispiel:\n  - Ursprüngliche Frage: 'Welche Schmerzmittel darf ich in der Schwangerschaft einnehmen?'\n  - Nachfrage: 'Kannst du mir präzisere Details geben?'\n  - Antwort: 'In der Schwangerschaft werden Paracetamol als das sicherste Schmerzmittel angesehen. Es sollte in der niedrigsten wirksamen Dosis und nur für kurze Zeit eingenommen werden. Ibuprofen sollte in den ersten beiden Trimestern nur nach Rücksprache mit einem Arzt angewendet werden, ist jedoch im dritten Trimester kontraindiziert.Bei Nachfrage Infos über: Laktosefreie Alternative bei laktoseintoleranz , Pharmakolinetik, Pharmakodynamik und Info zur Bestandteilen. Bitte konsultiere einen Arzt für spezifische Empfehlungen.'\n\nFalls eine Anfrage nicht in den oben genannten Themen passt, antworte ausschließlich mit: 'Diese Anfrage fällt nicht in den pharmazeutischen Bereich. Bitte stelle eine pharmazeutische Frage.'\n\n### Wichtige Hinweise:\n- Verwende eine einfache, klare Sprache und verzichte auf unnötig komplizierte Fachbegriffe, um sicherzustellen, dass die Antwort für alle Altersgruppen verständlich ist.\n- Deine Informationen dienen ausschließlich der Orientierung und ersetzen keine medizinische Beratung. Betone stets, dass bei Unsicherheiten ein Arzt oder Apotheker konsultiert werden sollte.
                """
            ]
        ]
        
        // Konversationshistorie und aktuelle Benutzeranfrage hinzufügen
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": prompt])
        
        // Request-Body definieren
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.3,   // Präzision und Konsistenz
            "max_tokens": 500,    // Maximale Antwortlänge
            "top_p": 0.8          // Variabilität reduzieren
        ]
        
        // API-URL überprüfen
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        // API-Anfrage erstellen
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // JSON-Body setzen
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // API-Aufruf durchführen
        urlSession.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "API Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Daten erhalten"])))
                return
            }
            // Antwort dekodieren
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decodedResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "API Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine gültige Antwort erhalten"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}



