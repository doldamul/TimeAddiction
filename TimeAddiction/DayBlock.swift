//
//  DayBlock.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import Foundation
import SwiftData

@Model
final class DayBlock {
    @Attribute(.unique) let date: Date
    var memo: String = ""
    var goalMinute: Int?
    
    @Relationship(deleteRule: .cascade, inverse: \TimeBlock.parentDay)
    var timeBlocks: [TimeBlock] = []
    
    init(_ date: Date) {
        self.date = date
    }
}
