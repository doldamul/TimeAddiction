//
//  TimeBlockView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/18/23.
//

import SwiftUI
import SwiftData
import RegexBuilder

// MARK: TimeBlock Detail View
struct TimeBlockView: View {
    @Environment(\.locale) var locale
    @Environment(\.modelContext) var modelContext
    let comparator = KeyPathComparator<TimeBlock>(\.startTime)
    
    @Bindable var rootTimeBlock: TimeBlock
    @State var subBlocks: [TimeBlock] = []
    
// TODO: timeBlockName: [TimeBlock: String] = [:] with onChange(of: timeBlockPath)
    @State var timeBlockName: String = ""
    @State var subBlockPath: [TimeBlock] = []
    
    var body: some View {
        NavigationStack(path: $subBlockPath) {
            VStack {
                GeometryReader { proxy in
                    List {
                        listHeader
                            .listRowSeparator(.hidden, edges: .top)
                        
                        let subBlocks = subBlocks.dropLast()
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
            .navigationTitle($timeBlockName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TimeBlock.self) { timeBlock in
                SubBlockDetailView(subBlock: timeBlock)
            }
            .toolbar {
                bottomButtonSet
            }
        }
        .onAppear {
            timeBlockName = rootTimeBlock.name
        }
        .onChange(of: timeBlockName) {
            // TODO: save old timeBlock.name temporarily while typing/searching name
            rootTimeBlock.name = timeBlockName
        }
        .onChange(of: rootTimeBlock.subBlocks, initial: true) {
            refreshSubBlocks()
        }
    }
}

// MARK: logic extension
extension TimeBlockView {
    private var isEnded: Bool {
        rootTimeBlock.endTime != nil
    }
    
    func refreshSubBlocks() {
        self.subBlocks = rootTimeBlock.subBlocks.sorted(using: comparator)
    }
    
    func endTimeBlock() {
        let lastSubBlock = subBlocks.last!
        let now = Date.now
        lastSubBlock.endTime = now
        rootTimeBlock.endTime = now
    }
    
    func lapSubBlock(_ timeBlock: TimeBlock) {
       let oldSubBlock = subBlocks.last!
        oldSubBlock.endTime = Date.now
        
        let newSubBlock = TimeBlock.preview
        modelContext.insert(newSubBlock)
        
        // deciding subBlock name
        let (_, count, description) = subBlocks.compactMap {
            try! regex.firstMatch(in: $0.name)
        }.last?.output ?? ("", 0, "판")
        
        timeBlock.subBlocks.append(newSubBlock)
        newSubBlock.name = String(count+1) + ordinalSuffix
        if let description {
            newSubBlock.name.append(" " + description)
        }
    }
    
    private var ordinalSuffix: String { "번째" }
    private var regex : Regex<(Substring, Int, Substring?)> {
        let regex = Regex {
            Capture {
                OneOrMore(.digit)
            } transform: {
                Int($0)!
            }
            ordinalSuffix
            ZeroOrMore { " " }
            Optionally {
                Capture {
                    OneOrMore(.any)
                }
            }
        }
        return regex
    }
}

// MARK: View extension
extension TimeBlockView {
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
    
    var bottomButtonSet: ToolbarItem<(), some View> {
        ToolbarItem(placement: .bottomBar) {
            if isEnded {
                Button { /* empty */ } label: {
                    Label("종료됨", systemImage: "checkmark.seal.fill")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .disabled(true)
            } else {
                HStack {
                    Button {
                        endTimeBlock()
                    } label: {
                        Label("끝내기", systemImage: "stopwatch")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    
                    Button {
                        let timeBlock = subBlockPath.last ?? rootTimeBlock
                        lapSubBlock(timeBlock)
                    } label: {
                        Label("기록 추가", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
            }
        }
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
fileprivate struct TimeBlockPreview: View {
    @Query(filter: #Predicate<TimeBlock> { $0.parentDay != nil }) 
    var timeBlocks: [TimeBlock]
    
    var body: some View {
        if let timeBlock = timeBlocks.first {
            TimeBlockView(rootTimeBlock: timeBlock)
        } else {
            Text("empty")
        }
    }
}

#Preview("TimeBlock Detail") {
    TimeBlockPreview()
        .modelContainer(PreviewSwiftData.container)
        .environment(\.locale, .init(identifier: "ko_KR"))
}

#Preview("Unavailable") {
    TimeBlockView.subBlockUnavailable
}
