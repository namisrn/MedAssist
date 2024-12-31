//
//  OpenAIService.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import Foundation
import NaturalLanguage
import os

/// Enum zur Darstellung spezifischer OpenAI API Fehler.
enum OpenAIServiceError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case apiError(String)
    case decodingError(Error)
    case rateLimited
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die URL ist ungültig."
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .apiError(let message):
            return "API-Fehler: \(message)"
        case .decodingError(let error):
            return "Decodierungsfehler: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate-Limit überschritten. Bitte versuchen Sie es später erneut."
        case .unknownError:
            return "Ein unbekannter Fehler ist aufgetreten."
        }
    }
}

/// Modell zur Decodierung der Antwort der OpenAI API.
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
    let error: APIError?
    
    struct APIError: Codable {
        let message: String
        let type: String
        let param: String?
        let code: String?
    }
}

/// Konfigurationsstruktur für OpenAIService.
struct OpenAIServiceConfig {
    let model: String
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    let rateLimit: Int // Max requests per minute
}

final class OpenAIService {
    // MARK: - Singleton
    /// Die gemeinsame Instanz von `OpenAIService`, die im gesamten Anwendungskontext verwendet wird.
    static let shared = OpenAIService()
    
    // MARK: - Private Eigenschaften
    /// Die URL der OpenAI API für Chat-Vervollständigungen.
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    /// Der API-Schlüssel für die Authentifizierung bei der OpenAI API.
    private let apiKey: String
    /// Die URLSession, die für die Netzwerkkommunikation verwendet wird.
    private let urlSession = URLSession.shared
    /// Konfigurationseinstellungen für den Service.
    private var config: OpenAIServiceConfig
    /// Logger für das Logging.
    private let logger = Logger(subsystem: "com.medihub", category: "OpenAIService")
    /// Rate Limiter
    private let rateLimiter: RateLimiter
    
    /// Privater Initialisierer verhindert die Instanziierung weiterer `OpenAIService`-Objekte.
    private init() {
        // Laden der API-Schlüssel
        self.apiKey = SecretsManager.getAPIKey() ?? ""
        // Standardkonfiguration
        self.config = OpenAIServiceConfig(
            model: "gpt-4",
            temperature: 0.3,
            maxTokens: 500,
            topP: 0.8,
            rateLimit: 60 // Beispiel: 60 Anfragen pro Minute
        )
        // Initialisieren des Rate Limiters
        self.rateLimiter = RateLimiter(maxRequests: config.rateLimit, per: 60)
    }
    
    /// Setzt die Konfiguration für den Service.
    func setConfig(_ config: OpenAIServiceConfig) {
        self.config = config
        self.rateLimiter.updateRateLimit(maxRequests: config.rateLimit, per: 60)
    }
    
    // MARK: - API-Aufruf
    
    /// Ruft eine Chat-Antwort von der OpenAI API ab.
    ///
    /// - Parameters:
    ///   - prompt: Die Benutzereingabe, auf die die API reagieren soll.
    ///   - conversationHistory: Die bisherige Konversationshistorie als Array von Dictionaries.
    /// - Returns: Die Antwort als `String`.
    func fetchChatResponse(prompt: String, conversationHistory: [[String: String]]) async throws -> String {
        // Rate Limiting
        guard rateLimiter.acquire() else {
            logger.warning("Rate limit exceeded.")
            throw OpenAIServiceError.rateLimited
        }
        
        // Erkennung der Sprache der Benutzeranfrage.
        let languageCode = detectLanguage(for: prompt) ?? "en"
        
        // Aufbau der initialen Nachrichten für die API-Anfrage, inklusive Entwicklerinstruktionen.
        var messages = [
            [
                "role": "developer",
                "content": """
                Du bist ein freundlicher, hilfsbereiter und sachkundiger pharmazeutischer Assistent, der ausschließlich Fragen zu Medikamenten und deren Anwendung beantwortet. 
                Wenn die Eingabe auf  \(languageCode) erfolgt, antworte auf \(languageCode).
                Bitte formuliere Deine Antworten im Du-Stil, um eine persönliche und freundliche Atmosphäre zu schaffen.

                ---
                ## Datenquellen & Quellenrichtlinie
                Du darfst nur auf folgende Datenquellen zurückgreifen und musst sicherstellen, dass alle Antworten mit diesen Quellen übereinstimmen:
                1. OpenFDA
                2. EMA (European Medicines Agency)
                3. ABDA-Datenbank
                4. WHO UMC
                5. Embryotox
                6. Kinderformularium
                7. Gelbeliste.de
                8. Fachinfo.de

                Hast Du in diesen Quellen keine Informationen gefunden, antworte: „Für diese Anfrage liegen in den angegebenen Quellen keine Informationen vor. Bitte konsultiere einen Arzt oder Apotheker.“

                ---
                ## Rolle & Einschränkungen
                - Beantworte ausschließlich pharmazeutische Fragen (z.B. Einnahmezeitpunkte, Nebenwirkungen, Wechselwirkungen, Kontraindikationen, Anwendungsgebiete usw.).
                - Stelle keine medizinischen Diagnosen oder Therapieempfehlungen, sondern liefere pharmazeutische Informationen.
                - Falls eine Anfrage außerhalb dieses Bereichs liegt oder nur ärztlich geklärt werden kann (z. B. Rezeptänderung, Diagnosen, tiefgehende Dosierungspläne ohne Kontext), antworte: „Diese Anfrage fällt nicht in den pharmazeutischen Bereich. Bitte stelle eine spezifische pharmazeutische Frage.“
                - Frage bei Unklarheiten (z.B. Gewicht, Alter, Schwangerschaft, Art der Erkrankung, Nieren-/Leberfunktion) **zuerst** nach, bevor Du eine Empfehlung aussprichst.
                - **Die Antwort muss immer auf der gleichen Sprache erfolgen wie die Anfrage.** Wenn z.B. eine Anfrage auf Deutsch gestellt wird, muss die Antwort auf Deutsch sein. Genauso für andere Sprachen wie Englisch, Persisch, Französisch oder jede andere Sprache.
                ---
                ## Richtlinien für Antworten
                1. **Präzision und Kürze**: Formuliere die Antworten möglichst klar und konkret.
                2. **Fachbegriffe**: Erkläre Fachbegriffe verständlich, damit Laien sie verstehen können.
                3. **Dosierungen**: Gehe nur darauf ein, wenn Du genügend Infos hast (z.B. Alter, Gewicht). Ansonsten verlange diese Infos oder verweise an den Arzt.
                4. **Nebenwirkungen / Wechselwirkungen**: Weisen die Quellen auf mögliche Probleme hin, nenne sie und verweise auf die jeweilige Quelle.
                5. **Zeitliche Aspekte**: Gib konkrete Zeitabstände an, wenn relevant (z.B. „mind. 2 Stunden Abstand ...“).
                6. **Schwangerschaft / Stillzeit**: Nutze vorrangig Embryotox oder Kinderformularium (bei Kindern) und kennzeichne es (z.B. „(lt. Embryotox)“).
                7. **Nicht-medikamentöse Alternativen**: Nenne sie, wenn es die Quellen empfehlen, aber kennzeichne sie als ergänzenden Hinweis. 
                8. **Keine ärztlichen Eingriffe**: Empfehle nicht das Absetzen oder Verschreiben eines Arzneimittels, verweise auf den Arzt.
                9. **Struktur**: Antworte klar gegliedert (z.B. „Dosierung“, „Wechselwirkungen“, „Fazit“).

                ---
                ## Wichtige Hinweise
                - Deine Informationen ersetzen keine ärztliche Beratung.
                - Bleibe höflich, freundlich und wertschätzend.
                - Wenn eine genaue Aussage nicht möglich ist, bitte um weitere Details oder verweise an Arzt/Apotheker.

                """
            ]
        ]
        
        // Hinzufügen der bisherigen Konversationshistorie und der aktuellen Benutzeranfrage zu den Nachrichten.
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": prompt])
        
        // Definition des Request-Bodies für die API-Anfrage.
        let requestBody: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "top_p": config.topP
        ]
        
        // Erstellung der URL-Instanz aus der API-URL.
        guard let url = URL(string: apiURL) else {
            logger.error("Invalid URL: \(self.apiURL)")
            throw OpenAIServiceError.invalidURL
        }
        
        // Aufbau der URLRequest mit den notwendigen Headern für die API-Anfrage.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            // Serialisierung des Request-Bodies in JSON-Format.
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            // Fehlerbehandlung bei der JSON-Serialisierung.
            logger.error("JSON Serialization Error: \(error.localizedDescription)")
            throw OpenAIServiceError.decodingError(error)
        }
        
        // Durchführung der API-Anfrage mit async/await
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // Überprüfung des HTTP-Statuscodes
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response")
                throw OpenAIServiceError.unknownError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    logger.warning("Rate limit exceeded with status code 429.")
                    throw OpenAIServiceError.rateLimited
                }
                // Versuche, die API-Fehlermeldung zu dekodieren
                if let apiError = try? JSONDecoder().decode(OpenAIResponse.APIError.self, from: data) {
                    logger.error("API Error: \(apiError.message)")
                    throw OpenAIServiceError.apiError(apiError.message)
                } else {
                    logger.error("Unexpected status code: \(httpResponse.statusCode)")
                    throw OpenAIServiceError.unknownError
                }
            }
            
            // Dekodierung der erhaltenen Daten in das `OpenAIResponse`-Modell.
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            if let content = decodedResponse.choices.first?.message.content {
                // Log die erfolgreiche Antwort
                logger.info("Received response from API.")
                return content
            } else {
                // Fehlerbehandlung, falls keine gültige Antwort empfangen wurde.
                logger.error("No valid response received.")
                throw OpenAIServiceError.unknownError
            }
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            logger.error("Network or decoding error: \(error.localizedDescription)")
            throw OpenAIServiceError.networkError(error)
        }
    }
    
    /// Ruft eine Audio-Antwort von der OpenAI API ab.
    ///
    /// - Parameters:
    ///   - audioData: Die Audiodaten, die zur Verarbeitung an die API gesendet werden.
    /// - Returns: Die Antwort als `String`.
    func fetchAudioResponse(audioData: Data) async throws -> String {
        // Rate Limiting
        guard rateLimiter.acquire() else {
            logger.warning("Rate limit exceeded.")
            throw OpenAIServiceError.rateLimited
        }
        
        // Kodierung der Audiodaten in Base64.
        let base64Audio = audioData.base64EncodedString()
        logger.debug("Base64-Daten für API: \(String(base64Audio.prefix(100)))...")
        
        let audioAPIURL = "https://api.openai.com/v1/audio/process" // Überprüfen Sie, ob dies der korrekte Endpunkt ist
        guard let url = URL(string: audioAPIURL) else {
            logger.error("Invalid URL: \(audioAPIURL)")
            throw OpenAIServiceError.invalidURL
        }
        
        // Aufbau der URLRequest mit den notwendigen Headern für die API-Anfrage.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Definition des Request-Bodies für die Audio-Verarbeitung.
        let requestBody: [String: Any] = [
            "audio": base64Audio,
            "model": "gpt-4-audio" // Stellen Sie sicher, dass dies das richtige Modell ist
        ]
        
        do {
            // Serialisierung des Request-Bodies in JSON-Format.
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            // Fehlerbehandlung bei der JSON-Serialisierung.
            logger.error("JSON Serialization Error: \(error.localizedDescription)")
            throw OpenAIServiceError.decodingError(error)
        }
        
        // Durchführung der API-Anfrage mit async/await
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            // Überprüfung des HTTP-Statuscodes
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response")
                throw OpenAIServiceError.unknownError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    logger.warning("Rate limit exceeded with status code 429.")
                    throw OpenAIServiceError.rateLimited
                }
                // Versuche, die API-Fehlermeldung zu dekodieren
                if let apiError = try? JSONDecoder().decode(OpenAIResponse.APIError.self, from: data) {
                    logger.error("API Error: \(apiError.message)")
                    throw OpenAIServiceError.apiError(apiError.message)
                } else {
                    logger.error("Unexpected status code: \(httpResponse.statusCode)")
                    throw OpenAIServiceError.unknownError
                }
            }
            
            // Dekodierung der erhaltenen Daten in das `OpenAIResponse`-Modell.
            let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            if let content = decodedResponse.choices.first?.message.content {
                // Log die erfolgreiche Antwort
                logger.info("Received audio response from API.")
                return content
            } else {
                // Fehlerbehandlung, falls keine gültige Antwort empfangen wurde.
                logger.error("No valid response received for audio.")
                throw OpenAIServiceError.unknownError
            }
        } catch let error as OpenAIServiceError {
            throw error
        } catch {
            logger.error("Network or decoding error: \(error.localizedDescription)")
            throw OpenAIServiceError.networkError(error)
        }
    }
    
    // MARK: - Helper zur Spracherkennung
    /// Erkennt die dominante Sprache eines gegebenen Textes.
    ///
    /// - Parameter text: Der zu analysierende Text.
    /// - Returns: Der ISO-Sprachcode der erkannten Sprache oder `nil`, falls keine Sprache erkannt wurde.
    private func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}

/// Klasse zur Implementierung eines einfachen Rate Limiters.
final class RateLimiter {
    private var maxRequests: Int
    private var per: TimeInterval
    private var requests: [Date] = []
    private let queue = DispatchQueue(label: "com.medihub.RateLimiterQueue")
    
    init(maxRequests: Int, per: TimeInterval) {
        self.maxRequests = maxRequests
        self.per = per
    }
    
    /// Aktualisiert die Rate Limit Konfiguration.
    func updateRateLimit(maxRequests: Int, per: TimeInterval) {
        queue.sync {
            self.maxRequests = maxRequests
            self.per = per
            self.requests = []
        }
    }
    
    /// Versucht, eine Anfrage durchzulassen. Gibt `true` zurück, wenn die Anfrage erlaubt ist, `false` andernfalls.
    func acquire() -> Bool {
        let now = Date()
        var allowed = false
        
        queue.sync {
            // Entferne alle Anfragen, die außerhalb des Zeitfensters liegen
            self.requests = self.requests.filter { now.timeIntervalSince($0) < self.per }
            if self.requests.count < self.maxRequests {
                allowed = true
                self.requests.append(now)
            }
        }
        
        return allowed
    }
}
