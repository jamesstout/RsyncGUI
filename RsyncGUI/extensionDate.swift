//
//  extension Date
//  RsyncGUI
//
//  Created by Thomas Evensen on 08/12/2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

extension Date {
    func weekday(date _: Date) -> Int {
        let calendar = Calendar.current
        let dateComponent = (calendar as NSCalendar).components(.weekday, from: self)
        return dateComponent.weekday!
    }

    func numberOfDaysInMonth() -> Int {
        let calendar = Calendar.current
        let days = (calendar as NSCalendar).range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: self)
        return days.length
    }

    func dateByAddingMonths(_ months: Int) -> Date {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.month = months
        return (calendar as NSCalendar).date(byAdding: dateComponent, to: self, options: NSCalendar.Options.matchNextTime)!
    }

    func dateByAddingDays(_ days: Int) -> Date {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.day = days
        return (calendar as NSCalendar).date(byAdding: dateComponent, to: self, options: NSCalendar.Options.matchNextTime)!
    }

    func day() -> Int {
        let calendar = Calendar.current
        let dateComponent = (calendar as NSCalendar).components(.day, from: self)
        return dateComponent.day!
    }

    func isSaturday() -> Bool {
        return (self.getWeekday() == 7)
    }

    func isSunday() -> Bool {
        return getWeekday() == 1
    }

    func isWeekday() -> Bool {
        return getWeekday() != 1
    }

    func getWeekday() -> Int {
        let calendar = Calendar.current
        return (calendar as NSCalendar).components(.weekday, from: self).weekday!
    }

    func monthNameFull() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM YYYY"
        return dateFormatter.string(from: self)
    }

    func month() -> Int {
        let calendar = Calendar.current
        let dateComponent = (calendar as NSCalendar).components(.month, from: self)
        return dateComponent.month!
    }

    func year() -> Int {
        let calendar = Calendar.current
        let dateComponent = (calendar as NSCalendar).components(.year, from: self)
        return dateComponent.year!
    }

    static func == (lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == ComparisonResult.orderedSame
    }

    static func < (lhs: Date, rhs: Date) -> Bool {
        return lhs.compare(rhs) == ComparisonResult.orderedAscending
    }

    static func > (lhs: Date, rhs: Date) -> Bool {
        return rhs.compare(lhs) == ComparisonResult.orderedAscending
    }

    init(year: Int, month: Int, day: Int) {
        let calendar = Calendar.current
        var dateComponent = DateComponents()
        dateComponent.year = year
        dateComponent.month = month
        dateComponent.day = day
        self = calendar.date(from: dateComponent)!
    }
}

extension String {
    var en_us_date_from_string: Date {
        let dateformatter = DateFormatter()
        dateformatter.locale = Locale(identifier: "en_US")
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateformatter.date(from: self) ?? Date()
    }

    var localized_date_from_string: Date {
        let dateformatter = DateFormatter()
        dateformatter.formatterBehavior = .behavior10_4
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        return dateformatter.date(from: self) ?? Date()
    }

    var setdatesuffixbackupstring: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "-yyyy-MM-dd"
        return self + formatter.string(from: Date())
    }
}
