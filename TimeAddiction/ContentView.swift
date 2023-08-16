//
//  ContentView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import SwiftUI
import SwiftData

// TODO: change to Date.today or not
fileprivate var today: Date {
    Calendar.current.startOfDay(for: Date.now)
}

struct ContentView: View {
    @State var selectedDate: Date = today
    @State var fetchDescriptor: FetchDescriptor<DayBlock> = {
        let predicate = #Predicate<DayBlock> { today == $0.date }
        var fetchDescriptor = FetchDescriptor<DayBlock>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        fetchDescriptor.relationshipKeyPathsForPrefetching = [\DayBlock.timeBlocks]
        return fetchDescriptor
    }()

    var body: some View {
        DayBlockView(fetchDescriptor, selectedDate: $selectedDate)
            .onChange(of: selectedDate) { (_, newDate) in
                fetchDescriptor.predicate = #Predicate<DayBlock> { newDate == $0.date }
            }
    }
}

fileprivate struct DayBlockView: View {
    @Environment(\.modelContext) var modelContext
    @Query var dayBlocks: [DayBlock]
    @State var value: Int?
    @State var selectedTimeBlock: TimeBlock?
    @Binding var selectedDate: Date
    
    var navTitle: String {
        selectedDate.formatted(.dateTime.day().month())
    }
    
    init(_ fetchDescriptor: FetchDescriptor<DayBlock>, selectedDate: Binding<Date>) {
        self._dayBlocks = Query(fetchDescriptor)
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        NavigationSplitView {
            Group {
                if let dayBlock = dayBlocks.first {
                    List(selection: $selectedTimeBlock) {
                        ForEach(dayBlock.timeBlocks) { timeBlock in
                            NavigationLink(timeBlock.name, value: timeBlock)
                        }
                    }
                    .overlay {
                        Self.timeBlockUnavailable
                            .opacity(dayBlock.timeBlocks.isEmpty ? 1 : 0)
                    }
                } else {
                    Self.dayBlockUnavailable
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                titleMenu
                bottomBarItem
            }
        } detail: {
            if let timeBlock = selectedTimeBlock {
                Text("preview 시작 시각: \(timeBlock.startTime.formatted(.dateTime))")
            } else {
                // TODO: ContentUnavailableView
                Text("not selected")
            }
        }
        .onChange(of: selectedDate) { (_, newDate) in
            if dayBlocks.isEmpty && newDate == today {
                let newBlock = DayBlock(today)
                modelContext.insert(newBlock)
            }
        }
    }
    
    var titleMenu: ToolbarTitleMenu<some View> {
        .init {
            Button {} label: {
                Label("공유", systemImage: "square.and.arrow.up.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.indigo)
            }
            Button {} label: {
                Label("통계 보기", systemImage: "chart.pie")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue)
            }
            Button {} label: {
                Label("날짜 선택", systemImage: "calendar")
                    .symbolRenderingMode(.palette)
            }
            Button {} label: {
                Label("오늘로 이동", systemImage: "star.fill")
                    .symbolRenderingMode(.palette)
            }
        }
    }
    
    var bottomBarItem: ToolbarItem<(), some View> {
        .init(placement: .status) {
            Button {} label: {
                Label("타임블록 추가", systemImage: "plus")
                    .symbolVariant(.circle.fill)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
    }
    
    static var dayBlockUnavailable: some View {
        ContentUnavailableView {
            Label("비어있음", systemImage: "tray")
        } description: {
            Text("타임블록은 당일에만 생성할 수 있습니다.")
        }
    }
    
    static var timeBlockUnavailable: some View {
        ContentUnavailableView {
            Label("비어있음", systemImage: "note")
        } description: {
            Text("오늘은 놀지 않으셨군요!")
        }
        .allowsHitTesting(false)
    }
}

#Preview("Unavailable") {
    TabView {
        DayBlockView.dayBlockUnavailable
        DayBlockView.timeBlockUnavailable
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .background(.regularMaterial)
}

#Preview("Main") {
    ContentView()
        .modelContainer(PreviewSwiftData.container)
}
