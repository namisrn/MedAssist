//
//  TextToSpeech.swift
//  MediHub
//
//  Created by Rafat Nami, Sasan on 27.12.24.
//

import Foundation
import AVFoundation

class TextToSpeech {
    private let speechSynthesizer = AVSpeechSynthesizer()

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE") // Deutsche Sprache
        speechSynthesizer.speak(utterance)
    }
}
