//
//  Item.swift
//  BrainLog
//
//  Created by 橋本純一 on 2026/01/29.
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
