//
//  Item.swift
//  TravelSpend
//
//  Created by sebastian alberto clark valenzuela on 09/08/26.
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
