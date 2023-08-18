//
//  TimeBlockView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/18/23.
//

import SwiftUI
import SwiftData
import RegexBuilder

struct TimeBlockView: View {
    @Environment(\.locale) var locale
    @Environment(\.modelContext) var modelContext
    
    let rootTimeBlock: TimeBlock
// TODO: timeBlockName: [TimeBlock: String] = [:] with onChange(of: timeBlockPath)
    @State var timeBlockName: String = ""
    @State var subBlockPath: [TimeBlock] = []
    
    var startTimeFormatted: String {
        rootTimeBlock.startTime.formatted(.dateTime.hour(.defaultDigits(amPM: .wide)).minute(.twoDigits).locale(locale))
    }
    
    var endTimeFormatted: String {
        (rootTimeBlock.endTime ?? Date.now).formatted(.dateTime.hour(.defaultDigits(amPM: .wide)).minute(.twoDigits).locale(locale))
    }
    
    var isEnded: Bool {
        rootTimeBlock.endTime != nil
    }
    
    var body: some View {
        NavigationStack(path: $subBlockPath) {
            VStack {
                List {
                    HStack {
                        Text(" ")
                        Spacer()
                        Text("\(startTimeFormatted) 시작")
                            .bold()
                    }
                    .listRowSeparator(.hidden, edges: .top)
                    
                    let comparator = KeyPathComparator<TimeBlock>(\.startTime)
                    if let subBlocks = rootTimeBlock.subBlocks?.sorted(using: comparator) {
                        ForEach(subBlocks) { subBlock in
                            let name = subBlock.name
                            let duration = subBlock.duration
                                .formatted(.components(style: .narrow, fields: [.hour, .minute]))
                            
                            NavigationLink(value: subBlock) {
                                HStack {
                                    Text(name)
                                    Spacer()
                                    Text(duration)
                                }
                            }
                        }
                    }
                    HStack {
                        Spacer()
                        let text = if isEnded { "\(endTimeFormatted) 끝" }
                                   else { "현재 \(endTimeFormatted)까지 진행중" }
                        
                        Text(text)
                            .bold()
                    }
                    .listRowSeparator(.hidden, edges: .bottom)
                }
                .listStyle(.inset)
                
                GroupBox {
                    HStack {
                        Text("합계")
                        Spacer()
                        let duration = rootTimeBlock.duration
                            .formatted(.components(style: .narrow, fields: [.hour, .minute]))
                        Text(duration)
                    }
                    .font(.headline)
                }
            }
            .safeAreaPadding()
            .navigationTitle($timeBlockName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TimeBlock.self) { timeBlock in
                Text(timeBlock.name)
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
    }
}

extension TimeBlockView {
    func endTimeBlock() {
        let comparator = KeyPathComparator<TimeBlock>(\.startTime)
        let orderedSubBlocks = rootTimeBlock.subBlocks!.sorted(using: comparator)
        
        let lastSubBlock = orderedSubBlocks.last!
        lastSubBlock.endTime = Date.now
        rootTimeBlock.endTime = lastSubBlock.endTime
    }
    
    func lapSubBlock(_ timeBlock: TimeBlock) {
        let comparator = KeyPathComparator<TimeBlock>(\.startTime)
        let orderedBlocks = timeBlock.subBlocks!.sorted(using: comparator)
        
        let oldSubBlock = orderedBlocks.last!
        oldSubBlock.endTime = Date.now
        
        let newSubBlock = TimeBlock.preview
        modelContext.insert(newSubBlock)
        
        // deciding subBlock name
        let ordinalSuffix = "번째"
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
        
        let (_, count, description) = orderedBlocks.compactMap {
            try! regex.firstMatch(in: $0.name)
        }.last?.output ?? ("", 0, "판")
        
        timeBlock.subBlocks!.append(newSubBlock)
        newSubBlock.name = String(count+1) + ordinalSuffix
        if let description {
            newSubBlock.name.append(" " + description)
        }
//        newSubBlock.subBlocks = nil
    }
}

extension TimeBlockView {
    var bottomButtonSet: ToolbarItem<(), some View> {
        ToolbarItem(placement: .bottomBar) {
            if isEnded {
                Button {} label: {
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
}

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

#Preview {
    TimeBlockPreview()
        .modelContainer(PreviewSwiftData.container)
        .environment(\.locale, .init(identifier: "ko.kr"))
}
