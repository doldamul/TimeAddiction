//
//  ContentView.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import SwiftUI
import SwiftData

// MARK: FetchDescriptor Inject View
struct ContentView: View {
    @State var selectedDate: Date = .today
    @State var fetchDescriptor: FetchDescriptor<DayBlock> = {
        let today = Date.today
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

// MARK: Main View
fileprivate struct DayBlockView: View {
    @Environment(\.modelContext) var modelContext
    
    @Binding var selectedDate: Date
    @Query var dayBlocks: [DayBlock]
    @State var selectedTimeBlock: TimeBlock?
    @State var isDatePickerSheet: Bool = false
    @State var isTimeBlockAddingSheet: Bool = false
    @State var timeBlockSheetTempTitle: String = ""
    
    init(_ fetchDescriptor: FetchDescriptor<DayBlock>, selectedDate: Binding<Date>) {
        self._dayBlocks = Query(fetchDescriptor)
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTimeBlock) {
                if let dayBlock = dayBlocks.first {
                    ForEach(dayBlock.timeBlocks) {
                        navigationItem(timeBlock: $0)
                    }
                }
            }
            .overlay {
                if let dayBlock = dayBlocks.first {
                    if dayBlock.timeBlocks.isEmpty {
                        Self.timeBlockUnavailable
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
            Group {
                if let timeBlock = selectedTimeBlock {
                    Text("preview 시작 시각: \(timeBlock.startTime.formatted(.dateTime))")
                } else {
                    Self.detailUnavailable
                }
            }
        }
        .onChange(of: selectedDate) { (_, newDate) in
            checkAndAddDayBlock(date: newDate)
        }
        .sheet(isPresented: $isDatePickerSheet) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $isTimeBlockAddingSheet) {
            TimeBlockAddingSheet(title: $timeBlockSheetTempTitle, dayBlock: dayBlocks.first!)
        }
    }
}

extension Date {
    static var today: Date {
        Calendar.current.startOfDay(for: Date.now)
    }
}

// MARK: logic extension
extension DayBlockView {
    var navTitle: String {
        selectedDate.formatted(.dateTime.day().month())
    }
    
    func checkAndAddDayBlock(date: Date) {
        if dayBlocks.isEmpty && date == Date.today {
            let newBlock = DayBlock(date)
            modelContext.insert(newBlock)
        }
    }
}

// MARK: View extension
extension DayBlockView {
    @ViewBuilder
    func navigationItem(timeBlock: TimeBlock) -> some View {
        let name = timeBlock.name
        let duration = timeBlock.duration
            .formatted(.components(style: .narrow, fields: [.hour, .minute]))
        
        NavigationLink(value: timeBlock) {
            HStack {
                Text(name)
                Spacer()
                Text(duration)
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
            Button { isDatePickerSheet = true } label: {
                Label("날짜 선택", systemImage: "calendar")
                    .symbolRenderingMode(.palette)
            }
            Button { selectedDate = Date.today } label: {
                Label("오늘로 이동", systemImage: "star.fill")
                    .symbolRenderingMode(.palette)
            }
        }
    }
    
    var bottomBarItem: ToolbarItem<(), some View> {
        .init(placement: .status) {
            Button { isTimeBlockAddingSheet = true } label: {
                Label("타임블록 추가", systemImage: "plus")
                    .symbolVariant(.circle.fill)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(selectedDate != Date.today)
        }
    }
    
    static var dayBlockUnavailable: some View {
        ContentUnavailableView {
            Label("비어있음", systemImage: "tray")
        } description: {
            Text("타임블록은 당일에만 생성할 수 있습니다.")
        }
        .allowsHitTesting(false)
    }
    
    static var timeBlockUnavailable: some View {
        ContentUnavailableView {
            Label("비어있음", systemImage: "note")
        } description: {
            Text("오늘은 놀지 않으셨군요!")
        }
        .allowsHitTesting(false)
    }
    
    static var detailUnavailable: some View {
        ContentUnavailableView {
            Label("선택되지 않음", systemImage: "filemenu.and.cursorarrow")
        } description: {
            Text("타임블록을 선택해 주세요.")
        }
        .allowsHitTesting(false)
    }
}

// MARK: Preview
#Preview("Main") {
    ContentView()
        .modelContainer(PreviewSwiftData.container)
}

#Preview("Unavailable") {
    TabView {
        DayBlockView.dayBlockUnavailable
        DayBlockView.timeBlockUnavailable
        DayBlockView.detailUnavailable
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .background(.regularMaterial)
}
