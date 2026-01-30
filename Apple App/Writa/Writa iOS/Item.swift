//
//  Item.swift
//  Writa iOS
//
//  Created by Josh Orr on 30/1/2026.
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
