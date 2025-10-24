//
//  SessionRecord.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// SessionRecord.swift
// Importiert das SwiftData-Framework
import Foundation
import SwiftData

// @Model sagt SwiftData, dass es diese Klasse in der Datenbank speichern soll
@Model
class SessionRecord {
    // Ein Zeitstempel, wann die Übung stattgefunden hat
    var date: Date
    // Wie viele Fragen insgesamt gestellt wurden
    var totalQuestions: Int
    // Wie viele davon richtig waren
    var correctAnswers: Int
    
    // Der "Initialisierer", um ein neues Objekt zu erstellen
    init(date: Date, totalQuestions: Int, correctAnswers: Int) {
        self.date = date
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
    }
    
    // Eine berechnete Eigenschaft für die falschen Antworten
    var wrongAnswers: Int {
        return totalQuestions - correctAnswers
    }
    
    // Eine berechnete Eigenschaft für das Verhältnis (Score)
    var scorePercentage: Double {
        // Wir prüfen, ob totalQuestions > 0 ist, um eine Division durch Null zu vermeiden
        return totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions)) * 100 : 0
    }
}
