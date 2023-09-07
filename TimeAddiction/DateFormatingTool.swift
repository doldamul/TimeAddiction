//
//  DateFormating.swift
//  TimeAddiction
//
//  Created by 돌다물 on 8/21/23.
//

import Foundation

extension Date {
    func timeFormatted(_ locale: Locale) -> String {
        formatted(.dateTime.hour(.defaultDigits(amPM: .wide)).minute(.twoDigits).locale(locale))
    }
}

extension Range<Date> {
    func durationFormatted(_ locale: Locale, containSecond: Bool = false) -> String {
        var containSecond = containSecond
        if upperBound.timeIntervalSince(lowerBound) < 60 {
            containSecond = true
        }
        
        let fields : Set<Date.ComponentsFormatStyle.Field>
        fields = containSecond ? [.hour, .minute, .second] : [.hour, .minute]
        return formatted(.components(style: .narrow, fields: fields).locale(locale))
    }
}
