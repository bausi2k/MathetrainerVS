//
//  StartView.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// StartView.swift
import SwiftUI
import SwiftData

struct StartView: View {
    
    @Query private var wrongAnswerRecords: [WrongAnswerRecord]
    
    // NEU: Zugriff auf die GamificationRewards
    @Query private var gamificationRewards: [GamificationRewards]
    
    // Hilfsvariable für die Belohnungen (holt den ersten Eintrag oder erstellt einen Default)
    private var rewards: GamificationRewards {
        gamificationRewards.first ?? GamificationRewards()
    }
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("MathetrainerVS 🧮")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // NEUE ANZEIGE DER BELOHNUNGEN
            HStack(spacing: 20) {
                Label("\(rewards.unicorns)", systemImage: "sparkles") // Einhorn-Symbol
                    .font(.title2)
                    .foregroundColor(.purple)
                Label("\(rewards.bananas)", systemImage: "tropicalfish") // Bananen-Symbol (oder 'leaf.fill', 'square.fill' als Platzhalter)
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 10)
            
            // ... (Rest der Buttons bleiben gleich) ...
            
            // 1. Button (NavigationLink) zum Starten einer neuen Übung
            NavigationLink(destination: SettingsView(isWrongAnswersOnlySession: false)) {
                Text("Neue Übung starten")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // NEUER BUTTON: Falsche Rechnungen üben
            NavigationLink(destination: SettingsView(isWrongAnswersOnlySession: true)) {
                Text("Falsche Rechnungen üben")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(wrongAnswerRecords.isEmpty)
            
            // 3. Button (NavigationLink) zur Statistik
            NavigationLink(destination: StatisticsView()) {
                Text("Meine Statistik ansehen")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Start")
        .navigationBarHidden(true)
        .onAppear(perform: ensureGamificationRewardsExist) // NEU: Sicherstellen, dass ein Rewards-Objekt existiert
    }
    
    // NEUE FUNKTION: Sicherstellen, dass ein GamificationRewards-Objekt in der DB ist
    private func ensureGamificationRewardsExist() {
        if gamificationRewards.isEmpty {
            let newRewards = GamificationRewards()
            modelContext.insert(newRewards)
            // modelContext.save() ist normalerweise nicht nötig, da SwiftData Änderungen automatisch speichert.
        }
    }
    
    // NEU: Zugriff auf den ModelContext für ensureGamificationRewardsExist
    @Environment(\.modelContext) private var modelContext
}
