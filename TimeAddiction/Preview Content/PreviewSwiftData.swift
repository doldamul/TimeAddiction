//
//  PreviewSwiftData.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import Foundation
import SwiftData

actor PreviewSwiftData {
    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([DayBlock.self])
        let configuration = ModelConfiguration(inMemory: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        var dayBlock = DayBlock.preview
        var timeBlock = TimeBlock.preview
        var subBlock = TimeBlock.preview
        let sampleData: [any PersistentModel] = [
            timeBlock, dayBlock, subBlock
        ]
        
        sampleData.forEach {
            container.mainContext.insert($0)
        }
        
        dayBlock.timeBlocks.append(timeBlock)
        timeBlock.subBlocks = [subBlock]
        subBlock.name = "1번째 판"
        return container
    }()
}

extension TimeBlock {
    static var preview: TimeBlock {
        TimeBlock("TimeBlock Preview Title", startTime: Date.now)
    }
}

extension DayBlock {
    static var preview: DayBlock {
        DayBlock(Calendar.current.startOfDay(for: Date.now))
    }
}
