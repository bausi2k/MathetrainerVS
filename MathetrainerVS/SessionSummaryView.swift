//
//  SessionSummaryView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// SessionSummaryView.swift
import SwiftUI

struct SessionSummaryView: View {
    
    // Daten, die vom PracticeView übergeben werden
    let totalQuestions: Int
    let correctAnswers: Int
    let wronglyAnswered: [Question]
    
    // Zugriff auf die "Schließen"-Funktion dieses Sheets
    @Environment(\.dismiss) private var dismissSheet
    
    // Berechnete Werte
    var wrongAnswers: Int {
        totalQuestions - correctAnswers
    }
    
    var scorePercentage: Double {
        totalQuestions > 0 ? (Double(correctAnswers) / Double(totalQuestions)) * 100 : 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Übung beendet!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Ergebnis-Kreis (Score)
                ZStack {
                    Circle()
                        .stroke(lineWidth: 15.0)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(scorePercentage / 100.0))
                        .stroke(style: StrokeStyle(lineWidth: 15.0, lineCap: .round, lineJoin: .round))
                        .foregroundColor(scorePercentage > 75 ? .green : (scorePercentage > 40 ? .orange : .red))
                        .rotationEffect(Angle(degrees: 270.0)) // Startet oben
                    
                    Text(String(format: "%.0f%%", scorePercentage))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(width: 150, height: 150)
                .padding()
                
                Text("Du hattest \(correctAnswers) von \(totalQuestions) richtig.")
                    .font(.title2)
                
                // Liste der falschen Antworten (nur wenn es welche gab)
                if !wronglyAnswered.isEmpty {
                    List {
                        Section(header: Text("Hier musst du noch üben:")) {
                            // Geht alle falschen Fragen durch
                            ForEach(wronglyAnswered, id: \.text) { question in
                                HStack {
                                    Text(question.text.replacingOccurrences(of: "?", with: ""))
                                        .strikethrough(color: .red) // Durchgestrichen
                                    Text("\(question.answer)")
                                        .foregroundColor(.green)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Button zum Schließen
                Button(action: {
                    dismissSheet() // Schließt das Sheet
                }) {
                    Text("Fertig")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}
