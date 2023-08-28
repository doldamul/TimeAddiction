//
//  TimeBlockRootView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/24/23.
//

import SwiftUI
import SwiftData

struct RootBlockDetailView: View {
    @Environment(\.locale) var locale
    @Environment(\.modelContext) var modelContext
    let comparator = KeyPathComparator<TimeBlock>(\.startTime)
    
    @Bindable var rootTimeBlock: TimeBlock
    @Binding var subBlocks: [TimeBlock]
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                List {
                    listHeader
                        .listRowSeparator(.hidden, edges: .top)
                    
                    let subBlocks = isEnded ? subBlocks : subBlocks.dropLast()
                    ForEach(subBlocks) {
                        pastSubBlockItem($0)
                    }
                    
                    if !subBlocks.isEmpty {
                        listFooter
                            .listRowSeparator(.hidden, edges: .bottom)
                    } else {
                        Self.subBlockUnavailable
                            .listRowSeparator(.hidden, edges: .bottom)
                            .frame(height: proxy.size.height * 0.85)
                    }
                }
                .listStyle(.inset)
            }
            
            GroupBox {
                // subBlock.last! is failed at before onAppear called
                if !isEnded, let subBlock = subBlocks.last {
                    currentSubBlockItem(subBlock)
                    Divider()
                        .padding(.bottom, 5)
                }
                
                timeSummary
            }
            .safeAreaPadding()
        }
        .onChange(of: rootTimeBlock.subBlocks, initial: true) {
            refreshSubBlocks()
        }
        .onDisappear {
            self.subBlocks = []
        }
    }
}

// MARK: Logic extension
extension RootBlockDetailView {
    private var isEnded: Bool {
        rootTimeBlock.endTime != nil
    }
    
    func refreshSubBlocks() {
        self.subBlocks = rootTimeBlock.subBlocks.sorted(using: comparator)
    }
}

// MARK: View extension
extension RootBlockDetailView {
    @ViewBuilder
    func currentSubBlockItem(_ subBlock: TimeBlock) -> some View {
        NavigationLink(value: subBlock) {
            HStack {
                VStack {
                    HStack {
                        Text("현재 진행중")
                            .bold()
                        Spacer()
                    }
                    .padding(.bottom, 1)
                    
                    HStack {
                        Text(subBlock.name)
                        Spacer()
                        TimelineView(.periodic(from: subBlock.startTime, by: 1.0)) { _ in
                            let duration = subBlock.duration.durationFormatted(locale, containSecond: true)
                            Text(duration)
                        }
                    }
                }
                .foregroundStyle(Color(UIColor.label))
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(.gray)
                    .padding(.leading)
            }
        }
    }
    
    @ViewBuilder
    func pastSubBlockItem(_ subBlock: TimeBlock) -> some View {
        let name = subBlock.name
        let duration = subBlock.duration.durationFormatted(locale)
        
        NavigationLink(value: subBlock) {
            HStack {
                Text(name)
                Spacer()
                Text(duration)
            }
        }
    }
    
    @ViewBuilder
    var listHeader: some View {
        let startTime = rootTimeBlock.startTime.timeFormatted(locale)
        HStack {
            Text("")
            Spacer()
            Text("\(startTime) 시작")
                .bold()
        }
    }
    
    @ViewBuilder
    var listFooter: some View {
        HStack {
            Spacer()
            if isEnded {
                let endTime = rootTimeBlock.endTime!.timeFormatted(locale)
                Text("\(endTime) 끝")
                    .bold()
            } else {
                TimelineView(.everyMinute) { _ in
                    let now = Date.now.timeFormatted(locale)
                    Text("\(now) 현재까지 진행중")
                }
            }
        }
    }
    
    @ViewBuilder
    var timeSummary: some View {
        HStack {
            Text("합계")
            Spacer()
            TimelineView(.periodic(from: rootTimeBlock.startTime, by: 60.0)) { _ in
                let duration = rootTimeBlock.duration.durationFormatted(locale)
                Text(duration)
            }
        }
        .font(.headline)
    }
    
    static var subBlockUnavailable: some View {
        ContentUnavailableView {
            Label("이전 기록 없음", systemImage: "tray.fill")
        } description: {
            Text("새 기록을 추가해주세요.")
        }
    }
}

// MARK: Preview
fileprivate struct TimeBlockRootPreview: View {
    @Query(filter: #Predicate<TimeBlock> { $0.parentDay != nil })
    var timeBlocks: [TimeBlock]
    @State var subBlocks: [TimeBlock] = []
    
    var body: some View {
        Group {
            if let timeBlock = timeBlocks.first {
                RootBlockDetailView(rootTimeBlock: timeBlock, subBlocks: $subBlocks)
            } else {
                Text("empty")
            }
        }
    }
}

#Preview("RootBlockDetail") {
    TimeBlockRootPreview()
        .modelContainer(PreviewSwiftData.container)
        .environment(\.locale, Locale(identifier: "ko_KR"))
}

#Preview("Unavailable") {
    RootBlockDetailView.subBlockUnavailable
}
