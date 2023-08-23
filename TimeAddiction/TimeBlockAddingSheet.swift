//
//  TimeBlockAddingSheet.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/17/23.
//

import SwiftUI
import SwiftData

struct TimeBlockAddingSheet: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @FocusState var fieldFocus
    @Binding var title: String
    
    var dayBlock: DayBlock
    @Binding var timeBlocks: [TimeBlock]
    
    var body: some View {
        NavigationStack {
            TextField(text: $title, prompt: Text("새 타임블록")) {
                Text("title")
            }
            .font(.title)
            .onSubmit() {
                addTimeBlock(name: title)
            }
            .submitLabel(.done)
            .focused($fieldFocus)
            .safeAreaPadding()
        }
        .presentationDetents([.fraction(0.1)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .presentationContentInteraction(.resizes)
        .presentationBackgroundInteraction(.disabled)
        .onAppear {
            fieldFocus = true
        }
        .onDisappear {
            if title.filter({$0 != " "}).isEmpty {
                title = ""
            }
        }
        .onChange(of: fieldFocus) {
            if !fieldFocus {
                dismiss()
            }
        }
    }
    
    func addTimeBlock(name: String) {
        if name.isEmpty || name.filter({$0 != " "}).isEmpty {
            title = ""
            dismiss()
            return
        }
                
        let now = Date.now
        let newRootBlock = TimeBlock.new(name, now)
        let newSubBlock = TimeBlock.new("1번째 판", now)
        modelContext.insert(newRootBlock)
        modelContext.insert(newSubBlock)
        dayBlock.timeBlocks.append(newRootBlock)
        newRootBlock.subBlocks.append(newSubBlock)
        
        timeBlocks.append(newRootBlock)
        title = ""
        dismiss()
    }
}

// MARK: Preview
struct TimeBlockAddingSheetPreview: View {
    @Environment(\.modelContext) var modelContext
    
    @State var isTimeBlockAddingSheet = false
    @Query var dayBlocks: [DayBlock]
    @State var timeBlocks: [TimeBlock] = []
    
    @State var timeBlockSheetTempTitle = ""
    
    var body: some View {
        VStack {
            Button {
                isTimeBlockAddingSheet = true
            } label: {
                Label("타임블록 추가", systemImage: "plus")
                    .symbolVariant(.circle.fill)
                    .labelStyle(.titleAndIcon)
            }
            List {
                if let timeBlocks = dayBlocks.first?.timeBlocks {
                    ForEach(timeBlocks) { timeBlock in
                        Text(timeBlock.name)
                    }
                } else {
                    Text("no TimeBlock")
                }
            }
        }
        .sheet(isPresented: $isTimeBlockAddingSheet) {
            TimeBlockAddingSheet(title: $timeBlockSheetTempTitle, dayBlock: dayBlocks.first!, timeBlocks: $timeBlocks)
        }
    }
}

#Preview("TimeBlock Adding Sheet") {
    TimeBlockAddingSheetPreview()
        .modelContainer(PreviewSwiftData.container)
}
