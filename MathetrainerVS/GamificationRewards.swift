//
//  GamificationRewards.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//
// GamificationRewards.swift
import Foundation
import SwiftData

@Model
class GamificationRewards {
    var unicorns: Int
    var bananas: Int
    var lastUpdated: Date // Zum Tracken, wann zuletzt Änderungen vorgenommen wurden

    // Um sicherzustellen, dass es immer nur einen Eintrag gibt,
    // geben wir ihm eine feste ID (oder verlassen uns auf das Abfrageverhalten).
    // Für dieses Beispiel machen wir es einfach und holen immer den ersten Eintrag.
    
    init(unicorns: Int = 0, bananas: Int = 0, lastUpdated: Date = Date()) {
        self.unicorns = unicorns
        self.bananas = bananas
        self.lastUpdated = lastUpdated
    }
}
