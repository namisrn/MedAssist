//
//  AudioRecorder.swift
//  MedAssist
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation
import AVFoundation

/// Klasse zur Aufnahme von Audiodaten.
/// Unterstützt Starten und Stoppen der Aufnahme sowie den Zugriff auf die aufgenommenen Daten.
class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")

    /// Startet die Audioaufnahme mit den definierten Einstellungen.
    func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC, // Verwenden Sie das AAC-Format
            AVSampleRateKey: 44100,              // Abtastrate: 44.1 kHz
            AVNumberOfChannelsKey: 1,            // Mono-Audio
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.record()
        } catch {
            print("Fehler beim Starten der Aufnahme: \(error)")
        }
    }

    /// Stoppt die Audioaufnahme und gibt die aufgenommenen Daten zurück.
    /// - Returns: Die Audioaufnahme als `Data`, oder `nil`, falls ein Fehler aufgetreten ist.
    func stopRecording() -> Data? {
        audioRecorder?.stop()
        if let data = try? Data(contentsOf: recordingURL) {
            print("Audioaufnahme erfolgreich: \(data.count) Bytes") // Debug-Ausgabe
            return data
        } else {
            print("Fehler: Keine gültigen Audiodaten gefunden.") // Debug-Ausgabe
            return nil
        }
    }
}
