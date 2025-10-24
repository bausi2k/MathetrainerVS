//
//  WrongAnswerRecord.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// WrongAnswerRecord.swift
import Foundation
import SwiftData

@Model
class WrongAnswerRecord {
    var questionText: String // Der Text der Frage, z.B. "5 + 3"
    var correctAnswer: Int   // Die korrekte Antwort
    var dateAdded: Date      // Wann diese Frage hinzugefügt wurde

    init(questionText: String, correctAnswer: Int, dateAdded: Date) {
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.dateAdded = dateAdded
    }
}
