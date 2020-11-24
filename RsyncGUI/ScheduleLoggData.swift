//
//  ScheduleLoggData.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 23/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
//  Object for sorting and holding logg data about all tasks.
//  Detailed logging must be set on if logging data.
//
// swiftlint:disable trailing_comma line_length

import Foundation

enum Sortandfilter {
    case offsitecatalog
    case localcatalog
    case profile
    case offsiteserver
    case task
    case backupid
    case numberofdays
    case executedate
    case none
}

final class ScheduleLoggData: SetConfigurations, SetSchedules, Sorting {
    var loggdata: [NSMutableDictionary]?
    private var scheduleConfiguration: [ConfigurationSchedule]?

    func filter(search: String?, filterby: Sortandfilter?) {
        globalDefaultQueue.async { () -> Void in
            let valueforkey = self.filterbystring(filterby: filterby ?? Optional.none)
            self.loggdata = self.loggdata?.filter {
                ($0.value(forKey: valueforkey) as? String ?? "").contains(search ?? "")
            }
        }
    }

    private func readandsortallloggdata(hiddenID: Int?, sortascending: Bool) {
        var data = [NSMutableDictionary]()
        if let input: [ConfigurationSchedule] = self.schedules?.getSchedule() {
            for i in 0 ..< input.count {
                for j in 0 ..< (input[i].logrecords?.count ?? 0) {
                    if let hiddenID = self.schedules?.getSchedule()?[i].hiddenID {
                        var date: String?
                        if let stringdate = input[i].logrecords?[j].dateExecuted {
                            if stringdate.isEmpty == false {
                                date = stringdate
                            }
                        }
                        let logdetail: NSMutableDictionary = [
                            DictionaryStrings.localCatalog.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .localCatalog) ?? "",
                            DictionaryStrings.remoteCatalog.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .offsiteCatalog) ?? "",
                            DictionaryStrings.offsiteServer.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .offsiteServer) ?? "",
                            DictionaryStrings.task.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .task) ?? "",
                            DictionaryStrings.backupID.rawValue: self.configurations?.getResourceConfiguration(hiddenID, resource: .backupid) ?? "",
                            DictionaryStrings.dateExecuted.rawValue: date ?? "",
                            DictionaryStrings.resultExecuted.rawValue: input[i].logrecords?[j].resultExecuted ?? "",
                            DictionaryStrings.deleteCellID.rawValue: self.loggdata?[j].value(forKey: DictionaryStrings.deleteCellID.rawValue) as? Int ?? 0,
                            DictionaryStrings.hiddenID.rawValue: hiddenID,
                            "snapCellID": 0,
                            DictionaryStrings.parent.rawValue: i,
                            DictionaryStrings.sibling.rawValue: j,
                        ]
                        data.append(logdetail)
                    }
                }
            }
        }
        if hiddenID != nil {
            data = data.filter { ($0.value(forKey: DictionaryStrings.hiddenID.rawValue) as? Int) == hiddenID }
        }
        self.loggdata = self.sortbydate(notsortedlist: data, sortdirection: sortascending)
    }

    let compare: (NSMutableDictionary, NSMutableDictionary) -> Bool = { number1, number2 in
        if number1.value(forKey: DictionaryStrings.sibling.rawValue) as? Int == number2.value(forKey: DictionaryStrings.sibling.rawValue) as? Int,
           number1.value(forKey: DictionaryStrings.parent.rawValue) as? Int == number2.value(forKey: DictionaryStrings.parent.rawValue) as? Int
        {
            return true
        } else {
            return false
        }
    }

    init(sortascending: Bool) {
        if self.loggdata == nil {
            self.readandsortallloggdata(hiddenID: nil, sortascending: sortascending)
        }
    }

    init(hiddenID: Int, sortascending: Bool) {
        if self.loggdata == nil {
            self.readandsortallloggdata(hiddenID: hiddenID, sortascending: sortascending)
        }
    }
}
