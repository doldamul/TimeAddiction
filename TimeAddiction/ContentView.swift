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
    @State var isLandscape: Bool = false
    @State var selectedDate: Date = .today
    @State var dayBlockFetchDescriptor: FetchDescriptor<DayBlock> = {
        let today = Date.today
        var fetchDescriptor = FetchDescriptor<DayBlock>()
        fetchDescriptor.fetchLimit = 1
        fetchDescriptor.relationshipKeyPathsForPrefetching = [\DayBlock.timeBlocks]
        return fetchDescriptor
    }()
    
    @State var timeBlockFetchDescriptor: FetchDescriptor<TimeBlock> = {
        let today = Date.today
        let sortDescriptor = SortDescriptor<TimeBlock>(\.startTime)
        let fetchDescriptor = FetchDescriptor<TimeBlock>(sortBy: [sortDescriptor])
        return fetchDescriptor
    }()

    var body: some View {
        DayBlockView(dayBlockFetchDescriptor, timeBlockFetchDescriptor, selectedDate: $selectedDate)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                if selectedDate != Date.today { selectedDate = Date.today }
            }
            .onChange(of: selectedDate, initial: true) {
                dayBlockFetchDescriptor.predicate = dayBlockPredicate
                timeBlockFetchDescriptor.predicate = timeBlockPredicate
            }
            .onRotate { orientation in
                isLandscape = orientation.isLandscape
            }
            .environment(\.isLandscape, isLandscape)
    }
}

extension ContentView {
    var dayBlockPredicate: Predicate<DayBlock> {
        #Predicate<DayBlock> { selectedDate == $0.date }
    }
    
    var timeBlockPredicate: Predicate<TimeBlock> {
        #Predicate<TimeBlock> {
            $0.parentDay.flatMap { dayBlock in
                dayBlock.date == selectedDate
            } == true
        }
    }
}

// MARK: Main View
fileprivate struct DayBlockView: View {
    @Environment(\.isLandscape) var isLandscape
    @Environment(\.locale) var locale
    @Environment(\.modelContext) var modelContext
    
    @Binding var selectedDate: Date
    @Query var dayBlockContainer: [DayBlock]
    var dayBlock: DayBlock? { dayBlockContainer.first }
    @Query var timeBlocks: [TimeBlock]
    
    @State var selectedTimeBlock: TimeBlock?
    @State var isDatePickerSheet: Bool = false
    @State var isTimeBlockAddingSheet: Bool = false
    @State var timeBlockSheetTempTitle: String = ""
    
    init(_ dayBlockfetchDescriptor: FetchDescriptor<DayBlock>, 
         _ timeBlockfetchDescriptor: FetchDescriptor<TimeBlock>,
         selectedDate: Binding<Date>) {
        self._dayBlockContainer = Query(dayBlockfetchDescriptor)
        self._timeBlocks = Query(timeBlockfetchDescriptor)
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTimeBlock) {
                ForEach(timeBlocks) {
                    navigationItem(timeBlock: $0)
                }
            }
            .overlay {
                if dayBlock == nil || dayBlock!.timeBlocks.isEmpty == true {
                    if selectedDate == .today {
                        Self.todayTimeBlockUnavailable
                    } else {
                        Self.otherDayTimeBlockUnavailable
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(titleFormatted)
            .toolbar {
                title
                titleMenu
                bottomBarItem
            }
        } detail: {
            TimeBlockView(rootTimeBlock: $selectedTimeBlock)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedDate, initial: true) {
            checkAndAddDayBlock(date: selectedDate)
        }
        .sheet(isPresented: $isDatePickerSheet) {
            DatePickerSheet(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $isTimeBlockAddingSheet) {
            TimeBlockAddingSheet(title: $timeBlockSheetTempTitle, dayBlock: dayBlock!)
        }
    }
}

// MARK: logic extension
extension DayBlockView {
    var titleFormatted: String {
        selectedDate.formatted(.dateTime.day().month().locale(locale))
    }
    
    func checkAndAddDayBlock(date: Date) {
        if dayBlock == nil && date == Date.today {
            let newBlock = DayBlock(date)
            modelContext.insert(newBlock)
        }
    }
    
    func endTimeBlock(_ timeBlock: TimeBlock) {
        let comparator = KeyPathComparator<TimeBlock>(\.startTime)
        let lastSubBlock = timeBlock.subBlocks.sorted(using: comparator).last!
        let now = Date.now
        lastSubBlock.endTime = now
        timeBlock.endTime = now
    }
    
    func deleteTimeBlock(_ timeBlock: TimeBlock) {
        modelContext.delete(timeBlock)
        try? modelContext.save()
    }
}

// MARK: View extension
extension DayBlockView {
    @ViewBuilder
    func navigationItem(timeBlock: TimeBlock) -> some View {
        NavigationLink(value: timeBlock) {
            HStack {
                Text(timeBlock.name)
                Spacer()
                if timeBlock.endTime == nil {
                    Text("진행중")
                        .font(.footnote)
                        .padding(3)
                        .background {
                            Capsule(style: .continuous)
                                .stroke(.green, lineWidth: 1)
                        }
                    TimelineView(.periodic(from: timeBlock.startTime, by: 1.0)) { _ in
                        let duration = timeBlock.duration.durationFormatted(locale)
                        Text(duration)
                    }
                } else {
                    let duration = timeBlock.duration.durationFormatted(locale)
                    Text(duration)
                }
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteTimeBlock(timeBlock)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
    
    var title: ToolbarItem<(), some View> {
        .init(placement: .principal) {
            Label {
                Text(titleFormatted)
            } icon: {
                if selectedDate == Date.today {
                    Image(systemName: "star.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.yellow)
                        .font(.footnote)
                }
            }
            .labelStyle(.titleAndIcon)
            .id(isLandscape)
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
                Label("오늘로 이동", systemImage: "star")
                    .symbolRenderingMode(.palette)
                    .symbolVariant(selectedDate == Date.today ? .none : .fill)
            }
            .disabled(selectedDate == Date.today)
        }
    }
    
    var bottomBarItem: ToolbarItem<(), some View> {
        .init(placement: .status) {
            if let focusedTimeBlock = timeBlocks.last, 
                focusedTimeBlock.endTime == nil {
                Button {
                    endTimeBlock(focusedTimeBlock)
                } label: {
                    Label("타임블록 종료", systemImage: "timer")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .id(isLandscape)
            } else {
                Button { isTimeBlockAddingSheet = true } label: {
                    Label("타임블록 추가", systemImage: "plus")
                        .symbolVariant(.circle.fill)
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(selectedDate != Date.today)
                .id(isLandscape)
            }
        }
    }
    
    static var otherDayTimeBlockUnavailable: some View {
        ContentUnavailableView {
            Label("비어있음", systemImage: "tray")
        } description: {
            Text("타임블록은 당일에만 생성할 수 있습니다.")
        }
        .allowsHitTesting(false)
    }
    
    static var todayTimeBlockUnavailable: some View {
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
        .environment(\.locale, Locale(identifier: "ko_KR"))
}
