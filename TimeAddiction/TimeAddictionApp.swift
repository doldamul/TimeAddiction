//
//  TimeAddictionApp.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/16/23.
//

import SwiftUI
import SwiftData

@main
struct TimeAddictionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: DayBlock.self)
                .environment(\.locale, Locale.current)
        }
    }
}
