//
//  DatePickerSheet.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/17/23.
//

import Foundation
import SwiftUI

struct DatePickerSheet: View {
    @Environment(\.locale) var locale
    @Environment(\.dismiss) var dismiss

    @State var previousDate: Date = Date(timeIntervalSinceReferenceDate: 0)
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: [.date])
                .environment(\.locale, locale)
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

// MARK: Preview
fileprivate struct DatePickerSheetPreview: View {
    @Environment(\.locale) var locale
    @State var isDatePickerSheet: Bool = false
    @State var selectedDate: Date = Date.now
    
    var selectedDateString: String {
        selectedDate.formatted(.dateTime.year().month().day().locale(locale))
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

#Preview("DatePicker Sheet") {
    DatePickerSheetPreview()
        .environment(\.locale, Locale(identifier: "ko_KR"))
}
