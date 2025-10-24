//
//  MathetrainerVSApp.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// MathetrainerVSApp.swift
import SwiftUI
import SwiftData

@main
struct MathetrainerVSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // HIER ANGEPASST: Fügt GamificationRewards zu den verwalteten Modellen hinzu
        .modelContainer(for: [SessionRecord.self, WrongAnswerRecord.self, GamificationRewards.self])
    }
}
