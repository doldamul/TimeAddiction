//
//  TimeBlockView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/18/23.
//

import SwiftUI
import SwiftData
import RegexBuilder

struct TimeBlockViewWrapper: View {
    @Binding var rootTimeBlock: TimeBlock?
    @State var subBlocksFetchDescriptor: FetchDescriptor<TimeBlock> = {
        FetchDescriptor(sortBy: [.init(\TimeBlock.startTime)])
    }()
    
    var body: some View {
        TimeBlockView(subBlocksFetchDescriptor, rootTimeBlock: $rootTimeBlock)
            .onChange(of: rootTimeBlock, initial: true) {
                subBlocksFetchDescriptor.predicate = subBlocksPredicate
            }
    }
}

extension TimeBlockViewWrapper {
    var subBlocksPredicate: Predicate<TimeBlock> {
        if let parentBlockID = self.rootTimeBlock?.persistentModelID {
            #Predicate { timeBlock in
                timeBlock.parent.flatMap { parentBlock in
                    parentBlockID == parentBlock.persistentModelID
                } == true
            }
        } else {
            Predicate.false
        }
    }
}

// MARK: TimeBlock RootView & SubView Navigation Container
struct TimeBlockView: View {
    @Environment(\.isLandscape) var isLandscape
    @Environment(\.locale) var locale
    @Environment(\.modelContext) var modelContext
    
    @Binding var rootTimeBlock: TimeBlock?
    @Query var subBlocks: [TimeBlock]
    
    init(_ fetchDescriptor: FetchDescriptor<TimeBlock>, rootTimeBlock: Binding<TimeBlock?>) {
        _rootTimeBlock = rootTimeBlock
        _subBlocks = Query(fetchDescriptor)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let rootTimeBlock {
                    RootBlockDetailView(rootTimeBlock: rootTimeBlock, subBlocks: subBlocks)
                } else {
                    Self.rootBlockUnavailable
                }
            }
            .navigationTitle(Binding($rootTimeBlock)?.name ?? Binding.constant(""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: TimeBlock.self) { timeBlock in
                SubBlockDetailView(subBlock: timeBlock)
                    .toolbar(.visible, for: .bottomBar)
            }
            .toolbar {
                title
                titleMenu
                bottomButtonSet
            }
        }
    }
}

// MARK: logic extension
extension TimeBlockView {
    private var isEnded: Bool {
        rootTimeBlock?.endTime != nil
    }
    
    func endTimeBlock() {
        let lastSubBlock = subBlocks.last!
        let now = Date.now
        lastSubBlock.endTime = now
        rootTimeBlock!.endTime = now
    }
    
    func lapSubBlock() {
        let now = Date.now
        let oldSubBlock = subBlocks.last!
        oldSubBlock.endTime = now
         
        // deciding subBlock name
        let (_, count, description) = subBlocks.compactMap {
            try! regex.firstMatch(in: $0.name)
        }.last?.output ?? ("", 0, "판")
        
        var name = String(count+1) + "번째"
        if let description {
            name.append(" " + description)
        }
        
        let newSubBlock = TimeBlock.new(name, now)
        modelContext.insert(newSubBlock)
        rootTimeBlock!.subBlocks.append(newSubBlock)
        try? modelContext.save()
    }
    
    private var regex : Regex<(Substring, Int, Substring?)> {
        let regex = Regex {
            Capture {
                OneOrMore(.digit)
            } transform: {
                Int($0)!
            }
            "번째"
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
    var title: ToolbarItem<(), some View> {
        .init(placement: .principal) {
            Label {
                let hasName = rootTimeBlock != nil
                Text(rootTimeBlock?.name ?? "타임블록")
                    .bold(hasName)
                    .opacity(hasName ? 1 : 0.4)
            } icon: {
                let isOngoing = !isEnded && rootTimeBlock != nil
                Text(isOngoing ? "진행중" : "")
                    .font(.footnote)
                    .padding(3)
                    .background {
                        if isOngoing {
                            Capsule(style: .continuous)
                                .stroke(.green, lineWidth: 1)
                        }
                    }
            }
            .labelStyle(.titleAndIcon)
            .id(isLandscape)
        }
    }

    var titleMenu: ToolbarTitleMenu<some View> {
        .init {
            let hasName = rootTimeBlock?.name.isEmpty == false
            if hasName {
                RenameButton()
            } else {
                Text("타임블록 없음")
            }
        }
    }

    var bottomButtonSet: ToolbarItem<(), some View> {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                if rootTimeBlock != nil {
                    if isEnded {
                        Button(action: {}) {
                            Label("종료됨", systemImage: "checkmark.seal.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .disabled(true)
                    } else {
                        Button {
                            endTimeBlock()
                        } label: {
                            Label("끝내기", systemImage: "stopwatch")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        Button {
                            lapSubBlock()
                        } label: {
                            Label("기록 추가", systemImage: "plus")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
            .id(isLandscape)
        }
    }
    
    static var subBlockUnavailable: some View {
        ContentUnavailableView {
            Label("이전 기록 없음", systemImage: "tray.fill")
        } description: {
            Text("새 기록을 추가해주세요.")
        }
    }
    
    static var rootBlockUnavailable: some View {
        ContentUnavailableView {
            Label("선택되지 않음", systemImage: "filemenu.and.cursorarrow")
        } description: {
            Text("사이드바에서 타임블록을 선택해 주세요.")
        }
        .allowsHitTesting(false)
    }
}

// MARK: Preview
fileprivate struct TimeBlockPreview: View {
    @Query(filter: #Predicate<TimeBlock> { $0.parentDay != nil }) 
    var timeBlocks: [TimeBlock]
    @State var timeBlock: TimeBlock?
    
    var body: some View {
        TimeBlockViewWrapper(rootTimeBlock: $timeBlock)
        .onAppear {
            timeBlock = timeBlocks.first
        }
    }
}

#Preview("TimeBlock Detail") {
    TimeBlockPreview()
        .modelContainer(PreviewSwiftData.container)
        .environment(\.locale, .init(identifier: "ko_KR"))
}
