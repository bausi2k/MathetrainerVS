//
//  SessionSettings.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// SessionSettings.swift
// SessionSettings.swift
import Foundation

struct SessionSettings {
    // ... (bestehende Variablen bleiben gleich) ...
    var useAddition: Bool = true
    var useSubtraction: Bool = false
    var useMultiplication: Bool = false
    var useDivision: Bool = false
    
    var numberOfQuestions: Int = 15
    
    var useTimer: Bool = false
    var timeLimitInMinutes: Int = 5
    
    var useThreeOperands: Bool = false
    
    // NEU: Soll die Session falsch beantwortete Rechnungen einstreuen?
    var includeWronglyAnswered: Bool = false
    
    // NEU: Ist dies eine spezielle Session NUR für falsch beantwortete Rechnungen?
    var isWrongAnswersOnlySession: Bool = false
}
