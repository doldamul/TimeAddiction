//
//  TimeBlock.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import Foundation
import SwiftData

@Model
final class TimeBlock {
    var name: String
    var memo: String
    var startTime: Date
    var endTime: Date?
    
    @Relationship(inverse: \TimeBlock.parent)
    var subBlocks: [TimeBlock]?
    var parent: TimeBlock?
    
    var parentDay: DayBlock?
    
    init(_ name: String, startTime: Date, endTime: Date? = nil, subSpace: Bool = true) {
        self.name = name
        self.memo = ""
        self.startTime = startTime
        self.endTime = endTime
        self.subBlocks = subSpace ? [] : nil
        self.parent = nil
    }
}

extension TimeBlock {
    @Transient
    var duration: ClosedRange<Date> {
        startTime...(endTime ?? Date.now)
    }
}
