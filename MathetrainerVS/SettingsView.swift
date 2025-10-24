//
//  SettingsView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    
    var isWrongAnswersOnlySession: Bool = false
    
    @State private var settings = SessionSettings()
    
    @Query private var wrongAnswerRecords: [WrongAnswerRecord]
    
    private var availableWrongAnswersCount: Int {
        wrongAnswerRecords.count
    }

    private var isAtLeastOneOperationSelected: Bool {
        settings.useAddition || settings.useSubtraction || settings.useMultiplication || settings.useDivision
    }

    var body: some View {
        Form {
            Section(header: Text("Was möchtest du üben?")) {
                Toggle("Addieren (+)", isOn: $settings.useAddition)
                Toggle("Subtrahieren (-)", isOn: $settings.useSubtraction)
                Toggle("Multiplizieren (x)", isOn: $settings.useMultiplication)
                Toggle("Dividieren (÷)", isOn: $settings.useDivision)
            }
            .disabled(isWrongAnswersOnlySession)
            
            if !isWrongAnswersOnlySession && !wrongAnswerRecords.isEmpty {
                Section(header: Text("Zusätzliche Optionen")) {
                    Toggle("Falsche Rechnungen einstreuen (\(availableWrongAnswersCount) verfügbar)", isOn: $settings.includeWronglyAnswered)
                }
            }
            
            Section(header: Text("Wie viele Rechnungen?")) {
                // KORRIGIERT: Der 'in' Parameter des Steppers
                // Wenn 'isWrongAnswersOnlySession' aktiv ist, ist das Maximum
                // die Anzahl der verfügbaren falschen Rechnungen, mindestens aber 1 (oder 5, je nach Wunsch).
                // Ich setze hier auf 'max(1, availableWrongAnswersCount)' um sicherzustellen, dass
                // es mindestens eine Frage gibt, wenn der Button aktiv ist, und ansonsten 100.
                Stepper("Anzahl: \(settings.numberOfQuestions)",
                        value: $settings.numberOfQuestions,
                        in: 1...(isWrongAnswersOnlySession ? max(1, availableWrongAnswersCount) : 100), // <--- HIER KORREKTUR
                        step: 1) // Schrittweite 1 ist sinnvoller, da die Anzahl der falschen Rechnungen beliebig sein kann
                
                if isWrongAnswersOnlySession {
                    Text("Du kannst maximal \(availableWrongAnswersCount) falsch beantwortete Rechnungen üben.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Zeitlimit")) {
                Toggle("Zeitlimit verwenden?", isOn: $settings.useTimer.animation())
                
                if settings.useTimer {
                    Stepper("Minuten: \(settings.timeLimitInMinutes)",
                            value: $settings.timeLimitInMinutes,
                            in: 1...60,
                            step: 1)
                }
            }
            
            if settings.useAddition || settings.useSubtraction {
                Section(header: Text("Schwierigkeit (Addition/Subtraktion)")) {
                    Picker("Anzahl Zahlen", selection: $settings.useThreeOperands) {
                        Text("2 Zahlen (z.B. 5 + 3)").tag(false)
                        Text("3 Zahlen (z.B. 5 + 3 + 2)").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            NavigationLink(destination: PracticeView(settings: settings)) {
                Text("Übung starten!")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            // Deaktivierung anpassen: Der Button "Falsche Rechnungen üben" ist schon
            // in StartView deaktiviert, wenn keine vorhanden sind. Hier prüfen wir nur
            // ob bei einer normalen Session eine Rechenart ausgewählt ist.
            .disabled(!isAtLeastOneOperationSelected && !isWrongAnswersOnlySession)
            
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            // KORRIGIERT: Die Initialisierung bei isWrongAnswersOnlySession
            if isWrongAnswersOnlySession {
                settings.useAddition = false
                settings.useSubtraction = false
                settings.useMultiplication = false
                settings.useDivision = false
                settings.isWrongAnswersOnlySession = true
                // Setze die numberOfQuestions auf die Anzahl der tatsächlich verfügbaren,
                // um sicherzustellen, dass es nicht zu viele oder zu wenige sind.
                // Mindestens 1, falls es 0 falsche Rechnungen gibt (obwohl der Button dann deaktiviert wäre).
                settings.numberOfQuestions = max(1, availableWrongAnswersCount) // <--- HIER KORREKTUR
            }
        }
    }
}
