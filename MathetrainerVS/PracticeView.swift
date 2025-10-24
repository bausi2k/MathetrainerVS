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
    
    let settings: SessionSettings

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismissView
    
    @Query private var allWrongAnswerRecords: [WrongAnswerRecord]
    // @Query private var allGamificationRecords: [GamificationRewards] ist hier nicht mehr nötig
    // da wir direkt den ModelContext verwenden, um die Belohnungen zu holen/upzudaten.
    
    // Die 'rewards' Computed Property ist jetzt überflüssig, da wir direkt auf die Instanz zugreifen.
    
    @State private var currentQuestion: Question?
    @State private var userAnswer: String = ""
    @State private var currentQuestionIndex: Int = 0
    @State private var correctAnswers: Int = 0
    @State private var wronglyAnswered: [Question] = []
    
    @State private var showResultToast: Bool = false
    @State private var wasLastAnswerCorrect: Bool = false
    @State private var isSessionFinished: Bool = false
    @State private var isTimerRunning: Bool = false
    @State private var showingAbortConfirmation: Bool = false

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining: Double = 0.0
    @State private var totalTime: Double = 1.0

    @State private var currentWrongAnswerStack: [WrongAnswerRecord] = []
    @State private var askedWrongAnswerCount: Int = 0
    
    @State private var correctAnswersSinceLastUnicorn: Int = 0
    @State private var wrongAnswersSinceLastBanana: Int = 0
    
    // MARK: - Initializer
    init(settings: SessionSettings) {
        self.settings = settings
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
                ProgressView()
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
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Abbrechen") {
                    showingAbortConfirmation = true
                }
            }
        }
        .confirmationDialog("Übung wirklich abbrechen?", isPresented: $showingAbortConfirmation) {
            Button("Abbrechen", role: .destructive) {
                endSession(aborted: true)
            }
            Button("Weiter", role: .cancel) {
                // Nichts tun, Dialog schließen
            }
        } message: {
            Text("Der aktuelle Fortschritt wird gespeichert.")
        }
        
        .onAppear {
            startGame()
        }
        
        .onReceive(timer) { _ in
            guard settings.useTimer && isTimerRunning else { return }
            
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                endSession(aborted: false)
            }
        }
        
        .overlay(
            ToastView(
                message: wasLastAnswerCorrect ? "Richtig! 🦄" : "Falsch! 🍌",
                isShowing: $showResultToast,
                isCorrect: wasLastAnswerCorrect
            )
        )
        
        .sheet(isPresented: $isSessionFinished, onDismiss: {
            dismissView()
        }) {
            SessionSummaryView(
                totalQuestions: currentQuestionIndex + 1,
                correctAnswers: correctAnswers,
                wronglyAnswered: wronglyAnswered
            )
        }
    }
    
    // MARK: - Game Logic Functions
    
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
            isTimerRunning = false
        }
        
        if settings.isWrongAnswersOnlySession || settings.includeWronglyAnswered {
            currentWrongAnswerStack = allWrongAnswerRecords.shuffled()
            
            if settings.isWrongAnswersOnlySession && currentWrongAnswerStack.count > settings.numberOfQuestions {
                currentWrongAnswerStack = Array(currentWrongAnswerStack.prefix(settings.numberOfQuestions))
            }
        } else {
            currentWrongAnswerStack = []
        }
        
        generateQuestion()
    }
    
    func generateQuestion() {
        var questionFromWrongAnswers: WrongAnswerRecord?
        
        if settings.isWrongAnswersOnlySession && !currentWrongAnswerStack.isEmpty {
            questionFromWrongAnswers = currentWrongAnswerStack.removeFirst()
            askedWrongAnswerCount += 1
        } else if settings.includeWronglyAnswered && !currentWrongAnswerStack.isEmpty {
            if Int.random(in: 1...100) <= 30 {
                questionFromWrongAnswers = currentWrongAnswerStack.removeFirst()
            }
        }
        
        if let wrongQuestion = questionFromWrongAnswers {
            self.currentQuestion = Question(text: wrongQuestion.questionText + " = ?", answer: wrongQuestion.correctAnswer)
        } else {
            var availableOps: [String] = []
            if settings.useAddition { availableOps.append("+") }
            if settings.useSubtraction { availableOps.append("-") }
            if settings.useMultiplication { availableOps.append("x") }
            if settings.useDivision { availableOps.append("÷") }
            
            guard let operation = availableOps.randomElement() else {
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
                    num1 = Int.random(in: 1...10)
                    num2 = Int.random(in: 1...10)
                    
                    answer = num1 * num2
                    questionText = "\(num1) ⋅ \(num2)"
                    
                case "÷":
                    num2 = Int.random(in: 1...10)
                    answer = Int.random(in: 0...10)
                    num1 = num2 * answer
                    questionText = "\(num1) ÷ \(num2)"
                    
                default:
                    questionText = "Fehler"
                    answer = 0
            }
            
            self.currentQuestion = Question(text: questionText + " = ?", answer: answer)
        }
    }
    
    func checkAnswer() {
        guard let answerInt = Int(userAnswer) else { return }
        guard let question = currentQuestion else { return }

        if answerInt == question.answer {
            wasLastAnswerCorrect = true
            correctAnswers += 1
            correctAnswersSinceLastUnicorn += 1
            
            if let recordToDelete = allWrongAnswerRecords.first(where: { $0.questionText + " = ?" == question.text && $0.correctAnswer == question.answer }) {
                modelContext.delete(recordToDelete)
                
                // Banane reduzieren, wenn eine alte falsche Frage richtig gelöst wird
                if let r = getGamificationRewards() { // NEU: Belohnungen über Funktion holen
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
            if let r = getGamificationRewards() { // NEU: Belohnungen über Funktion holen
                if r.unicorns > 0 {
                    r.unicorns -= 1
                }
                r.lastUpdated = Date()
            }
        }
        
        applyGamificationRewards()
        
        showResultToast = true
        isTimerRunning = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showResultToast = false
            nextQuestion()
            if settings.useTimer { isTimerRunning = true }
        }
    }
    
    private func applyGamificationRewards() {
        guard let r = getGamificationRewards() else { // NEU: Belohnungen über Funktion holen
            print("Fehler: GamificationRewards-Objekt nicht gefunden (in applyGamificationRewards).")
            return
        }
        
        while correctAnswersSinceLastUnicorn >= 10 {
            r.unicorns += 1
            correctAnswersSinceLastUnicorn -= 10
            print("Ein Einhorn gesammelt! Aktuell: \(r.unicorns) Einhörner")
        }
        
        while wrongAnswersSinceLastBanana >= 10 {
            r.bananas += 1
            wrongAnswersSinceLastBanana -= 10
            print("Eine Banane gesammelt! Aktuell: \(r.bananas) Bananen")
            
            if r.unicorns > 0 {
                r.unicorns -= 1
                print("Ein Einhorn für eine Banane geopfert. Aktuell: \(r.unicorns) Einhörner")
            }
        }
        
        r.lastUpdated = Date()
        // try? modelContext.save() // Explizites Speichern, wenn Änderungen sofort sichtbar sein sollen.
                               // Normalerweise nicht nötig, da SwiftData Änderungen automatisch nach einer Transaktion speichert.
    }
    
    // NEU: Hilfsfunktion, um das GamificationRewards-Objekt aus dem ModelContext zu holen
    private func getGamificationRewards() -> GamificationRewards? {
        do {
            let fetchDescriptor = FetchDescriptor<GamificationRewards>()
            let rewards = try modelContext.fetch(fetchDescriptor)
            return rewards.first // Wir erwarten nur ein Objekt
        } catch {
            print("Fehler beim Abrufen der GamificationRewards: \(error)")
            return nil
        }
    }
    
    func nextQuestion() {
        userAnswer = ""
        
        let totalQuestionsAsked = currentQuestionIndex + 1
        let shouldEndDueToCount = totalQuestionsAsked >= settings.numberOfQuestions

        let shouldEndDueToWrongAnswersDepleted: Bool
        if settings.isWrongAnswersOnlySession {
            shouldEndDueToWrongAnswersDepleted = askedWrongAnswerCount >= settings.numberOfQuestions
        } else {
            shouldEndDueToWrongAnswersDepleted = false
        }
        
        if shouldEndDueToCount || shouldEndDueToWrongAnswersDepleted {
            endSession(aborted: false)
        } else {
            currentQuestionIndex += 1
            generateQuestion()
        }
    }
    
    func endSession(aborted: Bool) {
        isTimerRunning = false
        isSessionFinished = true
        
        if currentQuestionIndex >= 0 {
            let newRecord = SessionRecord(
                date: Date(),
                totalQuestions: currentQuestionIndex + 1,
                correctAnswers: correctAnswers
            )
            modelContext.insert(newRecord)
        }
        
        applyGamificationRewards()
        
        if aborted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismissView()
            }
        }
    }
}
