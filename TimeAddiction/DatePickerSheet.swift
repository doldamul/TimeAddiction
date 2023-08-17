//
//  DatePickerSheet.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/17/23.
//

import Foundation
import SwiftUI

struct DatePickerSheet: View {
    @Environment(\.dismiss) var dismiss

    @State var previousDate: Date = Date(timeIntervalSinceReferenceDate: 0)
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .navigationTitle("날짜 선택")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("확인") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소", role: .cancel) {
                            selectedDate = previousDate
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            previousDate = selectedDate
        }
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.visible)
    }
}

fileprivate struct DatePickerSheetPreview: View {
    @State var isDatePickerSheet: Bool = false
    @State var selectedDate: Date = Date.now
    
    var selectedDateString: String {
        selectedDate.formatted(.dateTime.year().month().day())
    }
    
    var body: some View {
        VStack {
            Spacer()
            Button("Selected Date = " + selectedDateString) {
                isDatePickerSheet = true
            }
            .sheet(isPresented: $isDatePickerSheet) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    DatePickerSheetPreview()
}
