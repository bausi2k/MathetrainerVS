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
    
    // Wir holen alle Belohnungen, erwarten aber, dass es nur eine gibt.
    @Query private var gamificationRewards: [GamificationRewards]
    
    // Die computed property bleibt gleich, da sie nur den aktuell ersten Eintrag zurückgibt.
    private var rewards: GamificationRewards {
        gamificationRewards.first ?? GamificationRewards() // Falls noch keine existiert
    }
    
    // Benötigen den ModelContext für ensureGamificationRewardsExist
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("MathetrainerVS 🧮")
                .font(.largeTitle)
                .fontWeight(.bold)
            
// In StartView.swift im body:
            HStack(spacing: 20) {
                // Einhorn-Anzeige
                Text("🦄 \(rewards.unicorns)") // Emoji direkt vor der Zahl
                    .font(.title2)
                    .foregroundColor(.purple) // Farbe ist hier immer noch relevant für den Text

                // Bananen-Anzeige
                Text("🍌 \(rewards.bananas)") // Emoji direkt vor der Zahl
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 10)
            
            NavigationLink(destination: SettingsView(isWrongAnswersOnlySession: false)) {
                Text("Neue Übung starten")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
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
        .onAppear(perform: ensureGamificationRewardsExist)
    }
    
    private func ensureGamificationRewardsExist() {
        // Nur ein Objekt des Typs GamificationRewards soll existieren.
        // Wenn keines da ist, erstellen wir eins.
        if gamificationRewards.isEmpty {
            let newRewards = GamificationRewards()
            modelContext.insert(newRewards)
            // SwiftData speichert normalerweise automatisch. Ein explizites save() ist hier nicht zwingend,
            // aber schadet auch nicht, um sicherzustellen.
            // try? modelContext.save()
        }
    }
}
