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
    var memo: String = ""
    var startTime: Date
    var endTime: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \TimeBlock.parent)
    var subBlocks: [TimeBlock] = []
    var parent: TimeBlock?
    
    var parentDay: DayBlock?
    
    init(_ name: String, startTime: Date) {
        self.name = name
        self.startTime = startTime
    }
}

extension TimeBlock {
    @Transient
    var duration: Range<Date> {
        startTime ..< (endTime ?? Date.now)
    }
}

extension TimeBlock {
    /// cannot call TimeBlock.init at swiftui view file; seems like a bug - workaround
    static func new(_ name: String, _ startTime: Date) -> TimeBlock {
        self.init(name, startTime: startTime)
    }
}

extension Date {
    static var today: Date {
        Calendar.current.startOfDay(for: Date.now)
    }
}
