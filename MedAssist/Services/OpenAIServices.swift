//
//  OpenAIService.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 14.12.24.
//

import Foundation
import NaturalLanguage
/// Modell zur Decodierung der OpenAI API-Antwort.
struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
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
    private let apiKey = SecretsManager.getAPIKey() ?? ""
    private let urlSession = URLSession.shared

    private init() {}
    
    // MARK: - API-Aufruf
    func fetchChatResponse(
        prompt: String,
        conversationHistory: [[String: String]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Sprache der Benutzeranfrage erkennen
        let languageCode = detectLanguage(for: prompt) ?? "en"
        
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
                - Frage bei Unklarheiten (z. B. Gewicht, Alter, Schwangerschaft, Art der Erkrankung, Nieren-/Leberfunktion) **zuerst** nach, bevor Du eine Empfehlung aussprichst.
                - **Die Antwort muss immer auf der gleichen Sprache erfolgen wie die Anfrage.** Wenn z. B. eine Anfrage auf Deutsch gestellt wird, muss die Antwort auf Deutsch sein. Genauso für andere Sprachen wie Englisch, Persisch, Französisch oder jede andere Sprache.
                ---
                ## Richtlinien für Antworten
                1. **Präzision und Kürze**: Formuliere die Antworten möglichst klar und konkret.
                2. **Fachbegriffe**: Erkläre Fachbegriffe verständlich, damit Laien sie verstehen können.
                3. **Dosierungen**: Gehe nur darauf ein, wenn Du genügend Infos hast (z. B. Alter, Gewicht). Ansonsten verlange diese Infos oder verweise an den Arzt.
                4. **Nebenwirkungen / Wechselwirkungen**: Weisen die Quellen auf mögliche Probleme hin, nenne sie und verweise auf die jeweilige Quelle.
                5. **Zeitliche Aspekte**: Gib konkrete Zeitabstände an, wenn relevant (z.B. „mind. 2 Stunden Abstand ...“).
                6. **Schwangerschaft / Stillzeit**: Nutze vorrangig Embryotox oder Kinderformularium (bei Kindern) und kennzeichne es (z. B. „(lt. Embryotox)“).
                7. **Nicht-medikamentöse Alternativen**: Nenne sie, wenn es die Quellen empfehlen, aber kennzeichne sie als ergänzenden Hinweis. 
                8. **Keine ärztlichen Eingriffe**: Empfehle nicht das Absetzen oder Verschreiben eines Arzneimittels, verweise auf den Arzt.
                9. **Struktur**: Antworte klar gegliedert (z. B. „Dosierung“, „Wechselwirkungen“, „Fazit“).

                ---
                ## Wichtige Hinweise
                - Deine Informationen ersetzen keine ärztliche Beratung.
                - Bleibe höflich, freundlich und wertschätzend.
                - Wenn eine genaue Aussage nicht möglich ist, bitte um weitere Details oder verweise an Arzt/Apotheker.

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
             "temperature": 0.3,
             "max_tokens": 500,
             "top_p": 0.8
         ]
         
         // API-Anfrage erstellen und senden
         guard let url = URL(string: apiURL) else {
             completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
             return
         }
         
         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
         
         do {
             request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
         } catch {
             completion(.failure(error))
             return
         }
         
         urlSession.dataTask(with: request) { data, _, error in
             if let error = error {
                 completion(.failure(error))
                 return
             }
             guard let data = data else {
                 completion(.failure(NSError(domain: "API Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received."])))
                 return
             }
             
             do {
                 let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                 if let content = decodedResponse.choices.first?.message.content {
                     completion(.success(content))
                 } else {
                     completion(.failure(NSError(domain: "API Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid response received."])))
                 }
             } catch {
                 completion(.failure(error))
             }
         }.resume()
     }
     
     // MARK: - Helper zur Spracherkennung
     private func detectLanguage(for text: String) -> String? {
         let recognizer = NLLanguageRecognizer()
         recognizer.processString(text)
         return recognizer.dominantLanguage?.rawValue
     }
 
    
    func fetchAudioResponse(audioData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let base64Audio = audioData.base64EncodedString()
        print("Base64-Daten für API: \(base64Audio.prefix(100))...") // Debug-Ausgabe

        let apiURL = "https://api.openai.com/v1/audio-process"
        guard let url = URL(string: apiURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "audio": base64Audio,
            "model": "gpt-4o-audio-preview"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        urlSession.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "API Error", code: 0, userInfo: nil)))
                return
            }
            do {
                let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let content = decodedResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "API Error", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
}



