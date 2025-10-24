//
//  StatisticsView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// StatisticsView.swift
import SwiftUI
import SwiftData

struct StatisticsView: View {
    
    // 1. DIE DATENBANK-ABFRAGE
    // @Query ist der "magische" Befehl von SwiftData.
    // Er holt alle 'SessionRecord'-Objekte aus der Datenbank.
    // Wir sortieren sie direkt, und zwar nach Datum (date)
    // in umgekehrter Reihenfolge (reverse), damit die Neuesten oben stehen.
    @Query(sort: \SessionRecord.date, order: .reverse) private var sessionRecords: [SessionRecord]
    
    // 2. BERECHNETE LANGZEIT-STATISTIK
    // Diese Eigenschaften (Properties) werden "live" aus den
    // Datenbank-Ergebnissen berechnet.
    
    // Zählt alle "totalQuestions" aus allen Einträgen zusammen
    var totalCalculations: Int {
        // .reduce(0) startet bei 0 und addiert
        // $1.totalQuestions (Wert des Eintrags) zu $0 (bisherige Summe)
        sessionRecords.reduce(0) { $0 + $1.totalQuestions }
    }
    
    // Zählt alle korrekten Antworten zusammen
    var totalCorrect: Int {
        sessionRecords.reduce(0) { $0 + $1.correctAnswers }
    }
    
    // Berechnet die Gesamtzahl der falschen Antworten
    var totalWrong: Int {
        totalCalculations - totalCorrect
    }
    
    // Berechnet die Gesamt-Quote
    var overallRatio: Double {
        // Schutz vor Division durch Null, falls noch nie gespielt wurde
        if totalCalculations > 0 {
            return (Double(totalCorrect) / Double(totalCalculations)) * 100
        } else {
            return 0
        }
    }
    
    // 3. DIE BENUTZEROBERFLÄCHE (UI)
    var body: some View {
        // Eine Liste eignet sich hervorragend für Statistiken
        List {
            // Sektion 1: Die Gesamt-Übersicht
            Section(header: Text("Gesamtstatistik")) {
                // LabeledContent ist ein schöner Stil für "Label: Wert"
                LabeledContent("Alle Rechnungen", value: "\(totalCalculations)")
                LabeledContent("Insgesamt Richtig", value: "\(totalCorrect)")
                    .foregroundColor(.green)
                LabeledContent("Insgesamt Falsch", value: "\(totalWrong)")
                    .foregroundColor(.red)
                
                // Formatieren der Quote auf eine Nachkommastelle
                LabeledContent("Quote", value: String(format: "%.1f%%", overallRatio))
            }
            
            // Sektion 2: Der Verlauf der einzelnen Übungen
            Section(header: Text("Verlauf der Übungen")) {
                // Prüfen, ob überhaupt schon Einträge vorhanden sind
                if sessionRecords.isEmpty {
                    Text("Du hast noch keine Übung abgeschlossen.")
                        .italic()
                } else {
                    // Wir gehen jeden einzelnen Eintrag (record) durch...
                    ForEach(sessionRecords) { record in
                        // ...und zeigen eine Zeile dafür an
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                // Zeigt Datum und Uhrzeit an (z.B. "23.10.25, 23:10")
                                Text(record.date.formatted(date: .numeric, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Score: \(record.correctAnswers) / \(record.totalQuestions)")
                                    .fontWeight(.medium)
                            }
                            
                            Spacer() // Schiebt das Folgende nach rechts
                            
                            // Zeigt die Prozentzahl für diese eine Session an
                            Text(String(format: "%.0f%%", record.scorePercentage))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(record.scorePercentage > 75 ? .green : (record.scorePercentage > 40 ? .orange : .red))
                        }
                        .padding(.vertical, 4) // Etwas mehr Platz nach oben/unten
                    }
                }
            }
        }
        .navigationTitle("Meine Statistik")
    }
}

// Vorschau für Xcode
#Preview {
    // Wir brauchen einen NavigationStack, damit der Titel angezeigt wird
    NavigationStack {
        StatisticsView()
            // WICHTIG: Für die Vorschau müssen wir SwiftData "simulieren"
            // und Beispieldaten bereitstellen, sonst ist die Liste leer.
            .modelContainer(for: SessionRecord.self, inMemory: true)
    }
}
