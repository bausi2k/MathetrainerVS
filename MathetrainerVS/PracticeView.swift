//
//  PracticeView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// PracticeView.swift
import SwiftUI
import SwiftData

struct PracticeView: View {
    
    // MARK: - Properties
    
    // EINGEHENDE DATEN: Die Einstellungen, die vom SettingsView übergeben wurden.
    let settings: SessionSettings // KEIN @State hier, da von außen übergeben

    // UMGEBUNGS-VARIABLEN
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismissView
    
    // DATENBANK-ABFRAGEN
    // Diese @Query-Variablen werden AUTOMATISCH von SwiftData initialisiert
    // und dürfen NICHT im benutzerdefinierten init() angefasst werden.
    @Query private var allWrongAnswerRecords: [WrongAnswerRecord]
    @Query private var gamificationRecords: [GamificationRewards]
    
    // Computed Property für GamificationRewards für einfachen Zugriff
    private var rewards: GamificationRewards? {
        gamificationRecords.first
    }
    
    // STATE-VARIABLEN (Der Zustand der Übung) - Alle mit Initialwerten
    @State private var currentQuestion: Question?
    @State private var userAnswer: String = ""
    @State private var currentQuestionIndex: Int = 0
    @State private var correctAnswers: Int = 0
    @State private var wronglyAnswered: [Question] = [] // Für die Zusammenfassung am Ende
    
    // UI-STEUERUNG
    @State private var showResultToast: Bool = false
    @State private var wasLastAnswerCorrect: Bool = false
    @State private var isSessionFinished: Bool = false
    @State private var isTimerRunning: Bool = false

    // TIMER-PROPERTIES
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining: Double = 0.0
    @State private var totalTime: Double = 1.0 // Initialwert > 0 für Division durch Null Schutz

    // SPEZIELLE LOGIK FÜR FALSCHE RECHNUNGEN
    @State private var currentWrongAnswerStack: [WrongAnswerRecord] = []
    @State private var askedWrongAnswerCount: Int = 0
    
    // Zähler für Gamification-Logik (werden pro Session zurückgesetzt)
    @State private var correctAnswersSinceLastUnicorn: Int = 0
    @State private var wrongAnswersSinceLastBanana: Int = 0
    
    // MARK: - Initializer
    // DIESER INITIALIZER IST NUR FÜR DEN "settings"-PARAMETER NOTWENDIG.
    // Alle @State-Variablen MÜSSEN direkt bei der Deklaration einen initialen Wert erhalten.
    init(settings: SessionSettings) {
        self.settings = settings
        // SwiftData initialisiert @Query automatisch.
        // Die @State-Variablen werden entweder direkt oben initialisiert
        // oder in 'startGame()' zurückgesetzt, das in '.onAppear' aufgerufen wird.
    }

    // MARK: - UI Body
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("Frage \(currentQuestionIndex + 1) von \(settings.numberOfQuestions)")
                .font(.headline)
                .padding(.top)
            
            Spacer()
            
            if let question = currentQuestion {
                Text(question.text)
                    .font(.system(size: 48, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                ProgressView() // Zeigt einen Ladeindikator, wenn Frage noch nicht da ist
            }
            
            TextField("Deine Antwort", text: $userAnswer)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
            
            Button(action: checkAnswer) {
                Text("Bestätigen")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(userAnswer.isEmpty)
            
            Spacer()
            
            if settings.useTimer {
                TimerBar(timeRemaining: timeRemaining, totalTime: totalTime)
            }
        }
        .padding()
        .navigationTitle("Übung")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        
        // Beim ersten Erscheinen der View starten wir das Spiel.
        .onAppear {
            startGame()
        }
        
        .onReceive(timer) { _ in
            guard settings.useTimer && isTimerRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                endSession()
            }
        }
        
        // Das ToastView wird als Overlay angezeigt
        .overlay(
            ToastView(
                message: wasLastAnswerCorrect ? "Richtig! 🦄" : "Falsch! 🍌",
                isShowing: $showResultToast,
                isCorrect: wasLastAnswerCorrect
            )
        )
        
        // Das SessionSummaryView wird als Sheet angezeigt, wenn die Session beendet ist
        .sheet(isPresented: $isSessionFinished, onDismiss: {
            dismissView() // Geht zurück zum Start- oder Einstellungsbildschirm
        }) {
            SessionSummaryView(
                totalQuestions: currentQuestionIndex + 1, // Tatsächlich gestellte Fragen
                correctAnswers: correctAnswers,
                wronglyAnswered: wronglyAnswered
            )
        }
    }
    
    // MARK: - Game Logic Functions
    
    // Initialisiert oder setzt den Zustand für ein neues Spiel zurück
    func startGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        wronglyAnswered = []
        userAnswer = ""
        askedWrongAnswerCount = 0
        correctAnswersSinceLastUnicorn = 0
        wrongAnswersSinceLastBanana = 0
        
        if settings.useTimer {
            totalTime = Double(settings.timeLimitInMinutes * 60)
            timeRemaining = totalTime
            isTimerRunning = true
        } else {
            isTimerRunning = false // Timer nicht laufen lassen, wenn nicht verwendet
        }
        
        // Vorbereitung der falsch beantworteten Fragen für diese Session
        if settings.isWrongAnswersOnlySession || settings.includeWronglyAnswered {
            currentWrongAnswerStack = allWrongAnswerRecords.shuffled()
            
            if settings.isWrongAnswersOnlySession && currentWrongAnswerStack.count > settings.numberOfQuestions {
                currentWrongAnswerStack = Array(currentWrongAnswerStack.prefix(settings.numberOfQuestions))
            }
        } else {
            currentWrongAnswerStack = [] // Leeren, wenn nicht benötigt
        }
        
        generateQuestion() // Generiert die erste Frage
    }
    
    // Generiert die nächste Frage basierend auf den Einstellungen
    func generateQuestion() {
        var questionFromWrongAnswers: WrongAnswerRecord?
        
        // Priorität 1: Nur falsch beantwortete Rechnungen, wenn in diesem Modus
        if settings.isWrongAnswersOnlySession && !currentWrongAnswerStack.isEmpty {
            questionFromWrongAnswers = currentWrongAnswerStack.removeFirst()
            askedWrongAnswerCount += 1
        }
        // Priorität 2: Falsche Rechnungen einstreuen, wenn aktiviert und verfügbar
        else if settings.includeWronglyAnswered && !currentWrongAnswerStack.isEmpty {
            // Mit einer gewissen Wahrscheinlichkeit (z.B. 30%) eine falsche Frage einstreuen
            if Int.random(in: 1...100) <= 30 {
                questionFromWrongAnswers = currentWrongAnswerStack.removeFirst()
            }
        }
        
        // Wenn eine falsche Frage gefunden wurde, verwenden wir diese
        if let wrongQuestion = questionFromWrongAnswers {
            self.currentQuestion = Question(text: wrongQuestion.questionText + " = ?", answer: wrongQuestion.correctAnswer)
        } else {
            // Ansonsten generieren wir eine normale neue Frage
            var availableOps: [String] = []
            if settings.useAddition { availableOps.append("+") }
            if settings.useSubtraction { availableOps.append("-") }
            if settings.useMultiplication { availableOps.append("x") }
            if settings.useDivision { availableOps.append("÷") }
            
            // Wenn keine Rechenarten ausgewählt sind, aber auch keine falschen Fragen zur Verfügung standen,
            // ist dies ein Fehlerzustand oder die Session sollte nicht startbar sein.
            guard let operation = availableOps.randomElement() else {
                // Dies sollte nicht passieren, wenn der Start-Button in SettingsView korrekt disabled ist.
                self.currentQuestion = Question(text: "Fehler: Keine Operationen", answer: 0)
                return
            }
            
            var num1 = 0, num2 = 0, num3 = 0
            var answer = 0
            var questionText = ""
            
            let useThree = settings.useThreeOperands
            
            switch operation {
                case "+":
                    if useThree {
                        num1 = Int.random(in: 0...100)
                        num2 = Int.random(in: 0...(100 - num1))
                        num3 = Int.random(in: 0...(100 - num1 - num2))
                        answer = num1 + num2 + num3
                        questionText = "\(num1) + \(num2) + \(num3)"
                    } else {
                        num1 = Int.random(in: 0...100)
                        num2 = Int.random(in: 0...(100 - num1))
                        answer = num1 + num2
                        questionText = "\(num1) + \(num2)"
                    }
                    
                case "-":
                    if useThree {
                        num1 = Int.random(in: 0...100)
                        num2 = Int.random(in: 0...num1)
                        num3 = Int.random(in: 0...(num1 - num2))
                        answer = num1 - num2 - num3
                        questionText = "\(num1) - \(num2) - \(num3)"
                    } else {
                        num1 = Int.random(in: 0...100)
                        num2 = Int.random(in: 0...num1)
                        answer = num1 - num2
                        questionText = "\(num1) - \(num2)"
                    }
                    
                case "x":
                    num2 = Int.random(in: 0...10)
                    if num2 == 0 {
                        num1 = Int.random(in: 0...100)
                    } else {
                        num1 = Int.random(in: 0...(100 / num2))
                    }
                    answer = num1 * num2
                    questionText = "\(num1) x \(num2)"
                    
                case "÷":
                    num2 = Int.random(in: 1...10) // Divisor nicht Null
                    answer = Int.random(in: 0...(100 / num2))
                    num1 = num2 * answer // Sicherstellen, dass das Ergebnis ganzzahlig ist
                    questionText = "\(num1) ÷ \(num2)"
                    
                default:
                    questionText = "Fehler"
                    answer = 0
            }
            
            self.currentQuestion = Question(text: questionText + " = ?", answer: answer)
        }
    }
    
    // Überprüft die Benutzerantwort und aktualisiert den Zustand
    func checkAnswer() {
        guard let answerInt = Int(userAnswer) else { return }
        guard let question = currentQuestion else { return }

        if answerInt == question.answer {
            wasLastAnswerCorrect = true
            correctAnswers += 1
            correctAnswersSinceLastUnicorn += 1
            
            // Wenn eine falsch beantwortete Frage richtig gelöst wurde, aus Datenbank löschen
            if let recordToDelete = allWrongAnswerRecords.first(where: { $0.questionText + " = ?" == question.text && $0.correctAnswer == question.answer }) {
                modelContext.delete(recordToDelete)
                
                // Banane reduzieren, wenn eine alte falsche Frage richtig gelöst wird
                if let r = rewards {
                    if r.bananas > 0 {
                        r.bananas -= 1
                    }
                    r.lastUpdated = Date()
                }
            }
            
        } else {
            wasLastAnswerCorrect = false
            wronglyAnswered.append(question)
            wrongAnswersSinceLastBanana += 1
            
            // Wenn eine *neue* Frage falsch beantwortet wurde, zur Datenbank hinzufügen
            // (oder wenn eine bereits falsch beantwortete Frage erneut falsch beantwortet wurde,
            // aber nicht durch den currentWrongAnswerStack kam, wird sie als neu hinzugefügt.)
            let questionTextWithoutEquals = question.text.replacingOccurrences(of: " = ?", with: "")
            let isAlreadyWrongAnswer = allWrongAnswerRecords.contains(where: { $0.questionText == questionTextWithoutEquals && $0.correctAnswer == question.answer })
            
            if !isAlreadyWrongAnswer {
                let newWrongAnswer = WrongAnswerRecord(
                    questionText: questionTextWithoutEquals,
                    correctAnswer: question.answer,
                    dateAdded: Date()
                )
                modelContext.insert(newWrongAnswer)
            }
            
            // Wenn eine Banane dazukommt, wird automatisch ein Einhorn weggenommen
            if let r = rewards {
                if r.unicorns > 0 {
                    r.unicorns -= 1
                }
                r.lastUpdated = Date()
            }
        }
        
        // Gamification-Belohnungen prüfen und anwenden
        applyGamificationRewards()
        
        // UI Feedback und nächste Frage
        showResultToast = true
        isTimerRunning = false // Timer kurz anhalten für Feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showResultToast = false
            nextQuestion()
            if settings.useTimer { isTimerRunning = true } // Timer wieder starten
        }
    }
    
    // Logik für das Sammeln von Einhörnern und Bananen
    private func applyGamificationRewards() {
        guard let r = rewards else {
            // Sollte dank ensureGamificationRewardsExist in StartView nicht passieren,
            // aber zur Sicherheit.
            print("Fehler: GamificationRewards-Objekt nicht gefunden.")
            return
        }
        
        // Einhörner sammeln (für alle 10 richtigen Antworten)
        while correctAnswersSinceLastUnicorn >= 10 {
            r.unicorns += 1
            correctAnswersSinceLastUnicorn -= 10
            print("Ein Einhorn gesammelt! Aktuell: \(r.unicorns) Einhörner")
        }
        
        // Bananen sammeln (für alle 10 falschen Antworten)
        while wrongAnswersSinceLastBanana >= 10 {
            r.bananas += 1
            wrongAnswersSinceLastBanana -= 10
            print("Eine Banane gesammelt! Aktuell: \(r.bananas) Bananen")
            
            // Wenn eine Banane dazu kommt, wird automatisch ein Einhorn weggenommen
            if r.unicorns > 0 {
                r.unicorns -= 1
                print("Ein Einhorn für eine Banane geopfert. Aktuell: \(r.unicorns) Einhörner")
            }
        }
        
        r.lastUpdated = Date() // Letzte Aktualisierung speichern
    }
    
    // Geht zur nächsten Frage oder beendet die Session
    func nextQuestion() {
        userAnswer = "" // Eingabefeld leeren
        
        let totalQuestionsAsked = currentQuestionIndex + 1
        let shouldEndDueToCount = totalQuestionsAsked >= settings.numberOfQuestions

        let shouldEndDueToWrongAnswersDepleted: Bool
        if settings.isWrongAnswersOnlySession {
            shouldEndDueToWrongAnswersDepleted = askedWrongAnswerCount >= settings.numberOfQuestions
        } else {
            shouldEndDueToWrongAnswersDepleted = false
        }
        
        if shouldEndDueToCount || shouldEndDueToWrongAnswersDepleted {
            endSession()
        } else {
            currentQuestionIndex += 1
            generateQuestion()
        }
    }
    
    // Beendet die aktuelle Übungssitzung
    func endSession() {
        isTimerRunning = false
        isSessionFinished = true
        
        // SessionRecord speichern
        let newRecord = SessionRecord(
            date: Date(),
            totalQuestions: currentQuestionIndex + 1, // Tatsächlich gestellte Fragen
            correctAnswers: correctAnswers
        )
        modelContext.insert(newRecord)
        
        // Sicherstellen, dass alle ausstehenden Rewards angewendet werden,
        // bevor die Session beendet und die View geschlossen wird.
        applyGamificationRewards()
    }
}
