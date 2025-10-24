//
//  Item.swift
//  MathetrainerVS
//
//  Created by Klaus Gruber on 24.10.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
