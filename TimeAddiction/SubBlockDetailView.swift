//
//  SubBlockDetailView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/21/23.
//

import Foundation
import SwiftUI
import SwiftData

struct SubBlockDetailView: View {
    @Environment(\.locale) var locale
    @Bindable var subBlock: TimeBlock
    
    // view update at onAppear fix push/pop transition bug.
    @State var title: String = ""
    @State var memo: String = ""
    
    var body: some View {
        ZStack {
            TextEditor(text: $subBlock.memo)
                .overlay(alignment: .topLeading) {
                    Text("메모")
                        .foregroundStyle(.gray)
                        .opacity(subBlock.memo == "" ? 1 : 0)
                        .offset(x: 5, y: 8)
                }
            VStack {
                Spacer()
                GroupBox {
                    HStack {
                        Text("시작")
                            .font(.callout)
                        Spacer()
                        let text = subBlock.endTime == nil ? "현재" : "끝"
                        Text(text)
                            .font(.callout)
                    }
                    HStack {
                        let startTime = subBlock.startTime.timeFormatted(locale)
                        Text(startTime)
                        Spacer()
                        Text("-")
                        Spacer()
                        if let endTime = subBlock.endTime?.timeFormatted(locale) {
                            Text(endTime)
                        } else {
                            TimelineView(.everyMinute) { _ in
                                Text(Date.now.timeFormatted(locale))
                            }
                        }
                    }
                    Divider()
                        .padding(.bottom, 5)
                    HStack {
                        Text("진행시간")
                        Spacer()
                        TimelineView(.periodic(from: subBlock.startTime, by: 1.0)) { _ in
                            let duration = subBlock.duration.durationFormatted(locale, containSecond: true)
                            Text(duration)
                        }
                    }
                    .font(.headline)
                }
            }
        }
        .onAppear {
            self.title = subBlock.name
        }
        .onChange(of: title) {
            subBlock.name = title
        }
        .safeAreaPadding()
        .navigationTitle($subBlock.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

fileprivate struct TimeBlockPreview: View {
    @Query(filter: #Predicate<TimeBlock> { $0.parentDay != nil })
    var timeBlocks: [TimeBlock]
    
    var body: some View {
        NavigationStack {
            SubBlockDetailView(subBlock: timeBlocks.first!)
        }
    }
}

#Preview("SubBlock Detail") {
    TimeBlockPreview()
        .modelContainer(PreviewSwiftData.container)
        .environment(\.locale, .init(identifier: "ko_KR"))
}
